import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/notification_repository.dart';
import './backend_service.dart';

/// A sender must address a data-only payload to one resident. Notification
/// payloads are rejected because Android/iOS can display them before this check.
bool pushBelongsToResident(Map<String, dynamic> data, String? residentId,
        {bool hasNotificationPayload = false}) =>
    !hasNotificationPayload &&
    residentId != null &&
    residentId.isNotEmpty &&
    data['resident_id'] == residentId;

@pragma('vm:entry-point')
Future<void> sundoBackgroundPush(RemoteMessage message) async {
  if (!PushNotificationService.configured) return;
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: PushNotificationService.options);
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final resident = prefs.getString(PushNotificationService.bindingKey);
  if (!pushBelongsToResident(message.data, resident,
      hasNotificationPayload: message.notification != null)) {
    return;
  }
  final key = 'sundo_notices_$resident';
  final rows = prefs.getStringList(key) ?? [];
  final id =
      'push-${message.messageId ?? DateTime.now().microsecondsSinceEpoch}';
  if (rows.any((row) => (jsonDecode(row) as Map)['id'] == id)) return;
  final notice = SundoNotification(
      id: id,
      title: message.data['title'] ?? 'SUNDO Update',
      message:
          message.data['message'] ?? 'Open SUNDO for collection information.',
      createdAt: DateTime.now(),
      category: message.data['category'] ?? 'Alerts',
      type: message.data['type'] ?? 'update');
  await prefs.setStringList(
      key, [jsonEncode(notice.toJson()), ...rows].take(100).toList());
}

class PushNotificationService {
  static const bindingKey = 'sundo_push_bound_resident';
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static bool get configured =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _projectId.isNotEmpty;
  static FirebaseOptions get options => const FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _senderId,
      projectId: _projectId);
  static bool available = false;
  static bool _muting = false;
  static String? _boundResident;
  static StreamSubscription<RemoteMessage>? _foreground;
  static StreamSubscription<String>? _tokenChanges;
  static Future<void> initialize() async {
    if (!configured || available) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: options);
      final prefs = await SharedPreferences.getInstance();
      _boundResident = prefs.getString(bindingKey);
      final current = BackendService.configured
          ? BackendService.client.auth.currentUser?.id
          : null;
      if (_boundResident != current) {
        await FirebaseMessaging.instance.deleteToken();
        await prefs.remove(bindingKey);
        _boundResident = null;
      }
      FirebaseMessaging.onBackgroundMessage(sundoBackgroundPush);
      _foreground = FirebaseMessaging.onMessage
          .listen((message) => unawaited(_record(message)), onError: (_) {});
      _tokenChanges = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        if (!_muting &&
            BackendService.live &&
            _boundResident == BackendService.client.auth.currentUser?.id) {
          unawaited(_saveToken(token).catchError((Object _) {}));
        }
      }, onError: (_) {});
      available = true;
    } catch (_) {
      available = false;
    }
  }

  static Future<void> _record(RemoteMessage message) async {
    if (_muting || !BackendService.live) return;
    final resident = BackendService.client.auth.currentUser?.id;
    if (_boundResident != resident ||
        !pushBelongsToResident(message.data, resident,
            hasNotificationPayload: message.notification != null)) {
      return;
    }
    try {
      await LocalNotificationRepository.shared.recordEvent(
          id:
              'push-${message.messageId ?? DateTime.now().microsecondsSinceEpoch}',
          title: message.data['title'] ?? 'SUNDO Update',
          message: message.data['message'] ??
              'Open SUNDO for collection information.',
          type: message.data['type'] ?? 'update',
          category: message.data['category'] ?? 'Alerts');
    } catch (_) {/* The next refresh can load server collection data. */}
  }

  static Future<bool> requestPermissionAndRegister() async {
    if (!available || !BackendService.live) return false;
    final resident = BackendService.client.auth.currentUser!.id;
    if (_boundResident != resident) {
      await FirebaseMessaging.instance.deleteToken();
    }
    final permission = await FirebaseMessaging.instance.requestPermission();
    final allowed =
        permission.authorizationStatus == AuthorizationStatus.authorized ||
            permission.authorizationStatus == AuthorizationStatus.provisional;
    if (allowed) {
      _muting = false;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveToken(token);
        _boundResident = resident;
        await (await SharedPreferences.getInstance())
            .setString(bindingKey, resident);
      }
    }
    return allowed;
  }

  static Future<void> _saveToken(String token) async {
    if (_muting) return;
    final user = BackendService.client.auth.currentUser;
    if (user == null) return;
    await BackendService.client.from('device_push_tokens').upsert({
      'resident_id': user.id,
      'token': token,
      'updated_at': DateTime.now().toUtc().toIso8601String()
    }, onConflict: 'resident_id,token');
  }

  /// Remove the binding while the outgoing account still owns its database row.
  /// A failed removal keeps the account signed in so another user cannot inherit it.
  static Future<void> unregisterCurrentDevice() async {
    if (!configured) return;
    await initialize();
    if (!available) {
      throw StateError(
          'Could not disconnect device notifications. Check your connection and retry.');
    }
    _muting = true;
    final user = BackendService.client.auth.currentUser;
    final token = await FirebaseMessaging.instance.getToken();
    if (user != null && token != null) {
      await BackendService.client
          .from('device_push_tokens')
          .delete()
          .eq('resident_id', user.id)
          .eq('token', token);
    }
    await FirebaseMessaging.instance.deleteToken();
    _boundResident = null;
    await (await SharedPreferences.getInstance()).remove(bindingKey);
  }

  static Future<void> dispose() async {
    await _foreground?.cancel();
    await _tokenChanges?.cancel();
  }
}
