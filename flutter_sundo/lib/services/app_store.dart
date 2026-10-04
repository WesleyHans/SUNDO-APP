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

  factory GarbageReportItem.fromJson(Map<String, dynamic> map) => GarbageReportItem(
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
  static const String _keySavedAddresses = 'sundo_saved_addresses';
  static const String _keyReports = 'sundo_reports';
  static const String _keyReadNotifications = 'sundo_read_notifs';
  static const String _keyRemindersEnabled = 'sundo_reminders_enabled';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Profile
  static Future<String> getName() async {
    final p = await _getPrefs();
    return p.getString(_keyProfileName) ?? 'Juan Dela Cruz';
  }

  static Future<void> setName(String name) async {
    final p = await _getPrefs();
    await p.setString(_keyProfileName, name);
  }

  static Future<String> getEmail() async {
    final p = await _getPrefs();
    return p.getString(_keyProfileEmail) ?? 'juan@gmail.com';
  }

  static Future<void> setEmail(String email) async {
    final p = await _getPrefs();
    await p.setString(_keyProfileEmail, email);
  }

  static Future<String> getPhone() async {
    final p = await _getPrefs();
    return p.getString(_keyProfilePhone) ?? '0912 345 6789';
  }

  static Future<void> setPhone(String phone) async {
    final p = await _getPrefs();
    await p.setString(_keyProfilePhone, phone);
  }

  static Future<String> getBarangay() async {
    final p = await _getPrefs();
    return p.getString(_keyProfileBarangay) ?? 'Barangay 1';
  }

  static Future<void> setBarangay(String barangay) async {
    final p = await _getPrefs();
    await p.setString(_keyProfileBarangay, barangay);
  }

  static Future<String> getStreet() async {
    final p = await _getPrefs();
    return p.getString(_keyProfileStreet) ?? 'Poblacion Plaza Road';
  }

  static Future<void> setStreet(String street) async {
    final p = await _getPrefs();
    await p.setString(_keyProfileStreet, street);
  }

  // Saved Addresses
  static Future<List<Map<String, String>>> getSavedAddresses() async {
    final p = await _getPrefs();
    final raw = p.getStringList(_keySavedAddresses);
    if (raw == null || raw.isEmpty) {
      return [
        {'label': 'Home', 'address': 'Barangay 1, Poblacion, Sipalay City'},
        {'label': 'Store', 'address': 'Barangay 2, Public Market, Sipalay City'},
      ];
    }
    return raw.map((item) => Map<String, String>.from(jsonDecode(item) as Map)).toList();
  }

  static Future<void> addSavedAddress(String label, String address) async {
    final p = await _getPrefs();
    final list = await getSavedAddresses();
    list.add({'label': label, 'address': address});
    await p.setStringList(_keySavedAddresses, list.map((e) => jsonEncode(e)).toList());
  }

  static Future<void> removeSavedAddress(int index) async {
    final p = await _getPrefs();
    final list = await getSavedAddresses();
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await p.setStringList(_keySavedAddresses, list.map((e) => jsonEncode(e)).toList());
    }
  }

  // Reports
  static Future<List<GarbageReportItem>> getReports() async {
    final p = await _getPrefs();
    final raw = p.getStringList(_keyReports);
    if (raw == null || raw.isEmpty) {
      return [
        GarbageReportItem(
          id: 'SUNDO-2026-000120',
          concernType: 'Uncollected Waste',
          description: 'Recyclables accumulated at the corner of Poblacion Plaza Road.',
          photoPaths: [],
          latitude: 9.7525,
          longitude: 122.4038,
          locationAddress: 'Poblacion Plaza Road, Barangay 1',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          status: 'Scheduled',
        ),
      ];
    }
    return raw.map((e) => GarbageReportItem.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  static Future<void> saveReport(GarbageReportItem report) async {
    final p = await _getPrefs();
    final list = await getReports();
    list.insert(0, report);
    await p.setStringList(_keyReports, list.map((e) => jsonEncode(e.toJson())).toList());
  }

  // Read Notifications
  static Future<Set<String>> getReadNotifications() async {
    final p = await _getPrefs();
    final raw = p.getStringList(_keyReadNotifications);
    return raw != null ? raw.toSet() : <String>{};
  }

  static Future<void> markNotificationRead(String id) async {
    final p = await _getPrefs();
    final current = await getReadNotifications();
    current.add(id);
    await p.setStringList(_keyReadNotifications, current.toList());
  }

  static Future<void> markAllNotificationsRead(List<String> ids) async {
    final p = await _getPrefs();
    final current = await getReadNotifications();
    current.addAll(ids);
    await p.setStringList(_keyReadNotifications, current.toList());
  }

  // Reminders
  static Future<bool> areRemindersEnabled() async {
    final p = await _getPrefs();
    return p.getBool(_keyRemindersEnabled) ?? true;
  }

  static Future<void> setRemindersEnabled(bool enabled) async {
    final p = await _getPrefs();
    await p.setBool(_keyRemindersEnabled, enabled);
  }
}
