import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/storage/app_store.dart';

/// Local development accounts only. This repository never authenticates a city
/// account, writes to Supabase, or stores passwords in SharedPreferences.
class MockAuthRepository {
  static const _accountsKey = 'sundo_demo_accounts_v1';
  static const _sessionKey = 'sundo_demo_session_v1';
  static FlutterSecureStorage _storage = const FlutterSecureStorage();

  @visibleForTesting
  static set secureStorage(FlutterSecureStorage storage) => _storage = storage;
  static String? _currentEmail;
  static bool get hasSession => _currentEmail != null;

  @visibleForTesting
  static void resetMemory() {
    _currentEmail = null;
    AppStore.setIdentity(null);
  }

  static Future<List<Map<String, dynamic>>> _accounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((account) => Map<String, dynamic>.from(account as Map))
        .toList();
  }

  static Future<void> _saveAccounts(List<Map<String, dynamic>> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_accountsKey, jsonEncode(accounts))) {
      throw StateError('Could not save this demo account on your device.');
    }
  }

  static String _credentialKey(String email) =>
      'sundo_demo_password_${base64Url.encode(utf8.encode(email))}';

  static String _phoneKey(String value) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    return digits.startsWith('63') ? '0${digits.substring(2)}' : digits;
  }

  static Future<void> register(
      {required String name,
      required String email,
      required String phone,
      required String barangay,
      required String street,
      required String zone,
      required String password}) async {
    final normalized = email.trim().toLowerCase();
    final phoneKey = _phoneKey(phone);
    if (name.trim().length < 2 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized) ||
        !RegExp(r'^09\d{9}$').hasMatch(phoneKey) ||
        password.length < 8 ||
        barangay.trim().isEmpty ||
        zone.trim().isEmpty) {
      throw StateError(
          'Enter a full name, valid email/mobile number, address and a password of at least 8 characters.');
    }
    final accounts = await _accounts();
    if (accounts.any((account) =>
        account['email'] == normalized || account['phoneKey'] == phoneKey)) {
      throw StateError(
          'A local demo account already uses that email or mobile number.');
    }
    final account = <String, dynamic>{
      'name': name.trim(),
      'email': normalized,
      'phone': phone.trim(),
      'phoneKey': phoneKey,
      'barangay': barangay,
      'street': street.trim(),
      'zone': zone.trim()
    };
    try {
      await _storage.write(key: _credentialKey(normalized), value: password);
    } catch (_) {
      throw StateError(
          'Secure device storage is unavailable. Please try again on your Android or iOS phone.');
    }
    try {
      accounts.add(account);
      await _saveAccounts(accounts);
    } catch (_) {
      await _storage.delete(key: _credentialKey(normalized));
      rethrow;
    }
    await _activate(account, remember: true);
  }

  static Future<void> login(String emailOrMobile, String password,
      {bool remember = true}) async {
    final identifier = emailOrMobile.trim().toLowerCase();
    final phone = _phoneKey(identifier);
    Map<String, dynamic>? account;
    for (final candidate in await _accounts()) {
      if (candidate['email'] == identifier ||
          (phone.isNotEmpty && candidate['phoneKey'] == phone)) {
        account = candidate;
        break;
      }
    }
    if (account == null) {
      throw StateError(
          'No local demo account found. Create an account on this phone first.');
    }
    String? storedPassword;
    try {
      storedPassword =
          await _storage.read(key: _credentialKey(account['email'] as String));
    } catch (_) {
      throw StateError(
          'Secure device storage is unavailable. Try again on your phone.');
    }
    if (storedPassword == null || storedPassword != password) {
      throw StateError('The email/mobile number or password is incorrect.');
    }
    await _activate(account, remember: remember);
  }

  static Future<void> _activate(Map<String, dynamic> account,
      {required bool remember}) async {
    _currentEmail = account['email'] as String;
    AppStore.setIdentity('demo:$_currentEmail');
    await AppStore.setName(account['name'] as String);
    await AppStore.setEmail(_currentEmail!);
    await AppStore.setPhone(account['phone'] as String);
    await AppStore.setBarangay(account['barangay'] as String);
    await AppStore.setStreet(account['street'] as String? ?? '');
    await AppStore.setZone(account['zone'] as String? ?? '');
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setString(_sessionKey, _currentEmail!);
    } else {
      await prefs.remove(_sessionKey);
    }
  }

  static Future<bool> restoreSession() async {
    final email =
        (await SharedPreferences.getInstance()).getString(_sessionKey);
    if (email == null) return false;
    for (final account in await _accounts()) {
      if (account['email'] == email) {
        await _activate(account, remember: true);
        return true;
      }
    }
    await logout();
    return false;
  }

  /// Contact changes keep the account identifier stable for subsequent login.
  static Future<void> updateProfile(
      {required String name,
      required String phone,
      required String barangay,
      required String street,
      required String zone}) async {
    final accounts = await _accounts();
    final phoneKey = _phoneKey(phone);
    if (name.trim().length < 2 ||
        !RegExp(r'^09\d{9}$').hasMatch(phoneKey) ||
        barangay.trim().isEmpty ||
        zone.trim().isEmpty) {
      throw StateError(
          'Enter a full name, valid mobile number and collection address.');
    }
    if (accounts.any((account) =>
        account['email'] != _currentEmail && account['phoneKey'] == phoneKey)) {
      throw StateError('Another local demo account uses that mobile number.');
    }
    for (final account in accounts) {
      if (account['email'] == _currentEmail) {
        account.addAll({
          'name': name,
          'phone': phone,
          'phoneKey': phoneKey,
          'barangay': barangay,
          'street': street,
          'zone': zone
        });
        break;
      }
    }
    await _saveAccounts(accounts);
    await AppStore.setName(name);
    await AppStore.setPhone(phone);
    await AppStore.setBarangay(barangay);
    await AppStore.setStreet(street);
    await AppStore.setZone(zone);
  }

  static Future<void> logout() async {
    _currentEmail = null;
    await (await SharedPreferences.getInstance()).remove(_sessionKey);
    AppStore.setIdentity(null);
  }
}
