import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_store.dart';

class BackendService {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get configured => url.isNotEmpty && key.isNotEmpty;
  static bool demoMode = true;
  static bool get live => configured && !demoMode;
  static SupabaseClient get client => Supabase.instance.client;
  static Future<void> initialize() async {
    if (configured) {
      await Supabase.initialize(url: url, publishableKey: key);
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool('sundo_remember_session') == false) {
        await client.auth.signOut(scope: SignOutScope.local);
      }
      demoMode = client.auth.currentSession == null;
    }
  }

  static void requireBackend() {
    if (!configured) {
      throw StateError(
          'City service is not configured. Use the demo or configure Supabase.');
    }
  }

  static Future<void> login(String email, String password, {bool remember = true}) async {
    requireBackend();
    await client.auth.signInWithPassword(email: email, password: password);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('sundo_remember_session', remember);
    demoMode = false;
    await loadProfile();
  }

  static Future<bool> register(String name, String email, String phone,
      String barangay, String password) async {
    requireBackend();
    final result = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone, 'barangay': barangay});
    if (result.session == null) return false;
    demoMode = false;
    await loadProfile();
    return true;
  }

  static Future<Map<String, dynamic>> loadProfile() async {
    final profile = await client
        .from('profiles')
        .select()
        .eq('id', client.auth.currentUser!.id)
        .single();
    await AppStore.setName(profile['name'] as String);
    await AppStore.setEmail(client.auth.currentUser!.email ?? '');
    await AppStore.setPhone(profile['phone'] as String);
    await AppStore.setBarangay(profile['barangay'] as String);
    return profile;
  }

  static Future<void> logout() async {
    if (configured) await client.auth.signOut();
    demoMode = true;
  }

  static Future<List<GarbageReportItem>> reports() async {
    final rows = await client
        .from('reports')
        .select()
        .order('created_at', ascending: false);
    return rows
        .map((row) => GarbageReportItem(
              id: row['id'] as String,
              concernType: row['concern_type'] as String,
              description: row['description'] as String,
              photoPaths: List<String>.from(row['photo_paths'] as List),
              latitude: (row['latitude'] as num).toDouble(),
              longitude: (row['longitude'] as num).toDouble(),
              locationAddress: row['location_address'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              status: row['status'] as String,
            ))
        .toList();
  }

  static Future<void> submitReport(GarbageReportItem report) async {
    final paths = <String>[];
    try {
      for (var i = 0; i < report.photoPaths.length; i++) {
        final file = File(report.photoPaths[i]);
        final bytes = await file.readAsBytes();
        if (bytes.length > 5242880) {
          throw StateError('Each photo must be below 5 MB.');
        }
        final png = bytes.length >= 4 &&
            bytes[0] == 137 &&
            bytes[1] == 80 &&
            bytes[2] == 78 &&
            bytes[3] == 71;
        final path =
            '${client.auth.currentUser!.id}/${report.id}/$i.${png ? "png" : "jpg"}';
        await client.storage.from('report-photos').uploadBinary(path, bytes,
            fileOptions:
                FileOptions(contentType: png ? 'image/png' : 'image/jpeg'));
        paths.add(path);
      }
      await client.from('reports').insert({
        'id': report.id,
        'resident_id': client.auth.currentUser!.id,
        'concern_type': report.concernType,
        'description': report.description,
        'photo_paths': paths,
        'latitude': report.latitude,
        'longitude': report.longitude,
        'location_address': report.locationAddress,
      });
    } catch (_) {
      if (paths.isNotEmpty) {
        try {
          await client.storage.from('report-photos').remove(paths);
        } catch (_) {}
      }
      rethrow;
    }
  }
}
