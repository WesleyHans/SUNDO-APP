import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GarbageReportItem {
  final String id;
  final String concernType;
  final String description;
  final List<String> photoPaths;
  final double? latitude;
  final double? longitude;
  final String locationAddress;
  final DateTime createdAt;
  final String status; // 'Pending', 'Verified', 'Scheduled', 'Collected'

  GarbageReportItem({
    required this.id,
    required this.concernType,
    required this.description,
    required this.photoPaths,
    this.latitude,
    this.longitude,
    required this.locationAddress,
    required this.createdAt,
    this.status = 'Pending',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'concernType': concernType,
        'description': description,
        'photoPaths': photoPaths,
        'latitude': latitude,
        'longitude': longitude,
        'locationAddress': locationAddress,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };

  factory GarbageReportItem.fromJson(Map<String, dynamic> map) =>
      GarbageReportItem(
        id: map['id'] as String? ?? 'SUNDO-000',
        concernType: map['concernType'] as String? ?? 'Missed Collection',
        description: map['description'] as String? ?? '',
        photoPaths: List<String>.from(map['photoPaths'] as List? ?? []),
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        locationAddress: map['locationAddress'] as String? ?? 'Sipalay City',
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        status: map['status'] as String? ?? 'Pending',
      );
}

class AppStore {
  static const String _keyProfileName = 'sundo_profile_name';
  static const String _keyProfileEmail = 'sundo_profile_email';
  static const String _keyProfilePhone = 'sundo_profile_phone';
  static const String _keyProfileBarangay = 'sundo_profile_barangay';
  static const String _keyProfileStreet = 'sundo_profile_street';
  static const String _keyProfileZone = 'sundo_profile_zone';
  static const String _keyResidentLocation = 'sundo_resident_location';
  static const String _keySavedAddresses = 'sundo_saved_addresses';
  static const String _keyReports = 'sundo_reports';
  static const String _keyReadNotifications = 'sundo_read_notifs';
  static const String _keyRemindersEnabled = 'sundo_reminders_enabled';

  static String _identity = 'guest';

  /// Only local data is scoped here. Cloud access is still enforced by Supabase.
  static void setIdentity(String? identity) {
    _identity = identity?.isNotEmpty == true ? identity! : 'guest';
  }

  static String get identity => _identity;
  static String _scope(String key) =>
      _identity == 'guest' ? key : '$key:$_identity';

  static Future<SharedPreferences> _getPrefs() =>
      SharedPreferences.getInstance();

  // Profile
  static Future<String> getName() async {
    final p = await _getPrefs();
    return p.getString(_scope(_keyProfileName)) ?? 'Juan Dela Cruz';
  }

  static Future<void> setName(String name) async {
    final p = await _getPrefs();
    await p.setString(_scope(_keyProfileName), name);
  }

  static Future<String> getEmail() async {
    final p = await _getPrefs();
    return p.getString(_scope(_keyProfileEmail)) ?? 'juan@example.com';
  }

  static Future<void> setEmail(String email) async {
    final p = await _getPrefs();
    await p.setString(_scope(_keyProfileEmail), email);
  }

  static Future<String> getPhone() async {
    final p = await _getPrefs();
    return p.getString(_scope(_keyProfilePhone)) ?? '0912 345 6789';
  }

  static Future<void> setPhone(String phone) async {
    final p = await _getPrefs();
    await p.setString(_scope(_keyProfilePhone), phone);
  }

  static Future<String> getBarangay() async {
    final p = await _getPrefs();
    return p.getString(_scope(_keyProfileBarangay)) ?? 'Barangay 1 (Poblacion)';
  }

  static Future<void> setBarangay(String barangay) async {
    final p = await _getPrefs();
    await p.setString(_scope(_keyProfileBarangay), barangay);
  }

  /// A weather fallback must come from an explicitly saved area, never the
  /// development profile's default barangay. Capture the account before I/O.
  static Future<String?> getSavedWeatherArea() async {
    final identity = _identity;
    final barangayKey = _scope(_keyProfileBarangay);
    final addressesKey = _scope(_keySavedAddresses);
    final p = await _getPrefs();
    if (_identity != identity) return null;
    final barangay = p.getString(barangayKey)?.trim();
    if (barangay?.isNotEmpty == true) return barangay;
    for (final raw in p.getStringList(addressesKey) ?? <String>[]) {
      try {
        final saved = jsonDecode(raw);
        final address = saved is Map ? saved['address'] : null;
        if (address is String &&
            RegExp(r'(^|[^a-z])sipalay city(?=$|[^a-z])', caseSensitive: false)
                .hasMatch(address)) {
          return 'Sipalay City';
        }
      } catch (_) {
        // An unreadable saved address cannot be used as a reliable fallback.
      }
    }
    return null;
  }

  static Future<String> getStreet() async {
    final p = await _getPrefs();
    return p.getString(_scope(_keyProfileStreet)) ?? '';
  }

  static Future<void> setStreet(String street) async {
    final p = await _getPrefs();
    await p.setString(_scope(_keyProfileStreet), street);
  }

  static Future<String> getZone() async =>
      (await _getPrefs()).getString(_scope(_keyProfileZone)) ?? '';

  static Future<void> setZone(String zone) async {
    await (await _getPrefs()).setString(_scope(_keyProfileZone), zone);
  }

  static Future<String> getAddress() async {
    final values = await Future.wait([getStreet(), getZone(), getBarangay()]);
    return [...values.where((value) => value.trim().isNotEmpty), 'Sipalay City']
        .join(', ');
  }

  /// Precise coordinates stay on this device and are never published to residents.
  static Future<void> setResidentLocation(
      {double? latitude, double? longitude, double? accuracy}) async {
    final p = await _getPrefs();
    if (latitude == null || longitude == null) {
      await p.remove(_scope(_keyResidentLocation));
      return;
    }
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw ArgumentError('Invalid resident coordinates.');
    }
    await p.setString(
        _scope(_keyResidentLocation),
        jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'recordedAt': DateTime.now().toIso8601String(),
        }));
  }

  static Future<Map<String, dynamic>?> getResidentLocation() async {
    final raw = (await _getPrefs()).getString(_scope(_keyResidentLocation));
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  // Saved Addresses
  static Future<List<Map<String, String>>> getSavedAddresses() async {
    final p = await _getPrefs();
    final raw = p.getStringList(_scope(_keySavedAddresses));
    if (raw == null || raw.isEmpty) {
      return [];
    }
    return raw
        .map((item) => Map<String, String>.from(jsonDecode(item) as Map))
        .toList();
  }

  static Future<void> addSavedAddress(String label, String address) async {
    final p = await _getPrefs();
    final list = await getSavedAddresses();
    list.add({'label': label, 'address': address});
    await p.setStringList(
        _scope(_keySavedAddresses), list.map((e) => jsonEncode(e)).toList());
  }

  static Future<void> removeSavedAddress(int index) async {
    final p = await _getPrefs();
    final list = await getSavedAddresses();
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await p.setStringList(
          _scope(_keySavedAddresses), list.map((e) => jsonEncode(e)).toList());
    }
  }

  // Reports
  static Future<List<GarbageReportItem>> getReports() async {
    final p = await _getPrefs();
    final raw = p.getStringList(_scope(_keyReports));
    if (raw == null || raw.isEmpty) return [];
    return raw
        .map((e) =>
            GarbageReportItem.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveReport(GarbageReportItem report) async {
    final p = await _getPrefs();
    final list = await getReports();
    list.insert(0, report);
    final saved = await p.setStringList(
        _scope(_keyReports), list.map((e) => jsonEncode(e.toJson())).toList());
    if (!saved) throw StateError('Unable to save your report on this device.');
  }

  // Read Notifications
  static Future<Set<String>> getReadNotifications() async {
    final p = await _getPrefs();
    final raw = p.getStringList(_scope(_keyReadNotifications));
    return raw != null ? raw.toSet() : <String>{};
  }

  static Future<void> markNotificationRead(String id) async {
    final p = await _getPrefs();
    final current = await getReadNotifications();
    current.add(id);
    await p.setStringList(_scope(_keyReadNotifications), current.toList());
  }

  static Future<void> markAllNotificationsRead(List<String> ids) async {
    final p = await _getPrefs();
    final current = await getReadNotifications();
    current.addAll(ids);
    await p.setStringList(_scope(_keyReadNotifications), current.toList());
  }

  // Reminders
  static Future<bool> areRemindersEnabled() async {
    final p = await _getPrefs();
    return p.getBool(_scope(_keyRemindersEnabled)) ?? true;
  }

  static Future<void> setRemindersEnabled(bool enabled) async {
    final p = await _getPrefs();
    await p.setBool(_scope(_keyRemindersEnabled), enabled);
  }

  static Future<bool> notificationEnabled(String category) async =>
      (await _getPrefs()).getBool(_scope('sundo_notification_$category')) ??
      true;

  static Future<void> setNotificationEnabled(
      String category, bool enabled) async {
    await (await _getPrefs())
        .setBool(_scope('sundo_notification_$category'), enabled);
    if (category == 'weekly') await setRemindersEnabled(enabled);
  }
}
