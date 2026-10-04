import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/storage/app_store.dart';
import '../services/backend_service.dart';

class SundoNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String category;
  final String type;

  const SundoNotification(
      {required this.id,
      required this.title,
      required this.message,
      required this.createdAt,
      required this.category,
      required this.type});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'category': category,
        'type': type
      };
  factory SundoNotification.fromJson(Map<String, dynamic> json) =>
      SundoNotification(
          id: json['id'] as String,
          title: json['title'] as String,
          message: json['message'] as String,
          createdAt: DateTime.parse(json['createdAt'] as String),
          category: json['category'] as String,
          type: json['type'] as String);
}

abstract interface class NotificationRepository {
  bool get isDemo;
  ValueNotifier<int> get revision;
  Future<List<SundoNotification>> load();
  Future<Set<String>> readIds();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<bool> remindersEnabled();
  Future<void> setRemindersEnabled(bool enabled);
  Future<void> recordEvent(
      {required String id,
      required String title,
      required String message,
      required String type,
      String category = 'Alerts',
      DateTime? createdAt});
}

/// Shared across Home and Alerts so their unread counts stay in sync.
class MockNotificationRepository implements NotificationRepository {
  static final shared = MockNotificationRepository();
  final DateTime referenceDate;
  @override
  final revision = ValueNotifier<int>(0);
  MockNotificationRepository({DateTime? now})
      : referenceDate = now ?? DateTime.now();

  @override
  bool get isDemo => true;

  late final List<SundoNotification> items = [
    SundoNotification(
        id: 'demo-approaching',
        title: 'Truck Approaching',
        message: 'Garbage truck is 10 minutes away from your area.',
        createdAt: referenceDate.subtract(const Duration(minutes: 2)),
        category: 'Alerts',
        type: 'alert'),
    SundoNotification(
        id: 'demo-update',
        title: 'Collection Update',
        message: 'Truck is now in Barangay 1.',
        createdAt: referenceDate.subtract(const Duration(minutes: 30)),
        category: 'Alerts',
        type: 'update'),
    SundoNotification(
        id: 'demo-route',
        title: 'Route Changed',
        message: 'The collection route for Barangay 3 has been updated.',
        createdAt: referenceDate.subtract(const Duration(hours: 2)),
        category: 'Alerts',
        type: 'route'),
    SundoNotification(
        id: 'demo-completed',
        title: 'Collection Completed',
        message: 'Waste collection in your area is complete.',
        createdAt: referenceDate.subtract(const Duration(hours: 20)),
        category: 'Alerts',
        type: 'completed'),
    SundoNotification(
        id: 'demo-special',
        title: 'Special Collection',
        message: 'There will be a special collection this Saturday.',
        createdAt: referenceDate.subtract(const Duration(days: 2)),
        category: 'Announcements',
        type: 'special'),
  ];

  @override
  Future<List<SundoNotification>> load() async => List.unmodifiable(items);
  @override
  Future<Set<String>> readIds() => AppStore.getReadNotifications();
  Future<int> unreadCount() async {
    final read = await readIds();
    return items.where((item) => !read.contains(item.id)).length;
  }

  @override
  Future<void> markRead(String id) async {
    await AppStore.markNotificationRead(id);
    revision.value++;
  }

  @override
  Future<void> markAllRead() async {
    await AppStore.markAllNotificationsRead(
        items.map((item) => item.id).toList());
    revision.value++;
  }

  @override
  Future<bool> remindersEnabled() =>
      AppStore.notificationEnabled('approaching');
  @override
  Future<void> setRemindersEnabled(bool enabled) async {
    await AppStore.setNotificationEnabled('approaching', enabled);
    revision.value++;
  }

  @override
  Future<void> recordEvent(
      {required String id,
      required String title,
      required String message,
      required String type,
      String category = 'Alerts',
      DateTime? createdAt}) async {
    if (items.any((item) => item.id == id)) return;
    items.insert(
        0,
        SundoNotification(
            id: id,
            title: title,
            message: message,
            createdAt: createdAt ?? DateTime.now(),
            category: category,
            type: type));
    revision.value++;
  }
}

/// Actual events observed by this resident's device. Separate user keys keep
/// notices and read state private when an account on the phone changes.
class LocalNotificationRepository implements NotificationRepository {
  static final shared = LocalNotificationRepository();
  @override
  final revision = ValueNotifier<int>(0);
  @override
  bool get isDemo => false;
  Future<void> _pendingWrite = Future<void>.value();
  String get _key =>
      'sundo_notices_${BackendService.configured ? BackendService.client.auth.currentUser?.id ?? 'signed-out' : AppStore.identity}';

  @override
  Future<List<SundoNotification>> load() => _loadForKey(_key);

  Future<List<SundoNotification>> _loadForKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final rows = prefs.getStringList(key) ?? [];
    return rows
        .map((row) =>
            SundoNotification.fromJson(jsonDecode(row) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Set<String>> readIds() => _readForKey(_key);

  Future<Set<String>> _readForKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('${key}_read') ?? []).toSet();
  }

  Future<int> unreadCount() async {
    final key = _key;
    final notices = await _loadForKey(key);
    final read = await _readForKey(key);
    return notices.where((item) => !read.contains(item.id)).length;
  }

  @override
  Future<void> markRead(String id) async {
    final key = _key;
    final prefs = await SharedPreferences.getInstance();
    final ids = await _readForKey(key);
    ids.add(id);
    await prefs.setStringList('${key}_read', ids.toList());
    revision.value++;
  }

  @override
  Future<void> markAllRead() async {
    final key = _key;
    final prefs = await SharedPreferences.getInstance();
    final rows = await _loadForKey(key);
    await prefs.setStringList(
        '${key}_read', rows.map((item) => item.id).toList());
    revision.value++;
  }

  @override
  Future<bool> remindersEnabled() =>
      AppStore.notificationEnabled('approaching');

  @override
  Future<void> setRemindersEnabled(bool enabled) async {
    await AppStore.setNotificationEnabled('approaching', enabled);
    revision.value++;
  }

  @override
  Future<void> recordEvent(
      {required String id,
      required String title,
      required String message,
      required String type,
      String category = 'Alerts',
      DateTime? createdAt}) async {
    final key = _key;
    final time = createdAt ?? DateTime.now();
    _pendingWrite = _pendingWrite.catchError((Object _) {}).then((_) async {
      final rows = await _loadForKey(key);
      if (rows.any((item) => item.id == id)) return;
      rows.insert(
          0,
          SundoNotification(
              id: id,
              title: title,
              message: message,
              createdAt: time,
              category: category,
              type: type));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key,
          rows.take(100).map((item) => jsonEncode(item.toJson())).toList());
      revision.value++;
    });
    return _pendingWrite;
  }
}
