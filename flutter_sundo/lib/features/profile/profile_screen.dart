import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;
import '../../repositories/mock_auth_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../core/storage/app_store.dart';
import '../../services/backend_service.dart';
import '../../services/push_notification_service.dart';
import '../../core/theme/clay_theme.dart';
import '../auth/widgets/auth_form_widgets.dart';
import '../../shared/widgets/weather_attribution.dart';
import '../../shared/widgets/weather_location_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/weather_repository.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const ProfileScreen({super.key, this.onLogout});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  String _name = 'Resident';
  String _email = '';
  String _phone = '';
  String _barangay = sipalayBarangays.first;
  String _street = '';
  String _zone = '';
  String _permissionLabel = 'Checking…';
  bool _locationAllowed = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _loadProfile() async {
    final values = await Future.wait([
      AppStore.getName(),
      AppStore.getEmail(),
      AppStore.getPhone(),
      AppStore.getBarangay(),
      AppStore.getStreet(),
      AppStore.getZone()
    ]);
    if (!mounted) return;
    setState(() {
      _name = values[0];
      _email = values[1];
      _phone = values[2];
      _barangay = values[3];
      _street = values[4];
      _zone = values[5];
    });
  }

  Future<void> _checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      final service = await Geolocator.isLocationServiceEnabled();
      final allowed = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (mounted) {
        setState(() {
          _locationAllowed = allowed && service;
          _permissionLabel = !service
              ? 'GPS off'
              : allowed
                  ? 'Allowed'
                  : permission == LocationPermission.deniedForever
                      ? 'Blocked'
                      : 'Not allowed';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationAllowed = false;
          _permissionLabel = 'Unavailable';
        });
      }
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(value)));

  Future<void> _permissionTap() async {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => WeatherLocationSettings(
            onManagePermission: _manageLocationPermission));
  }

  Future<void> _manageLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      } else {
        if (!mounted) return;
        final open = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                    title: const Text('Location Permission'),
                    content: Text(_locationAllowed
                        ? 'Location is allowed. SUNDO uses it for the map and, if enabled, local weather. You can change permission in phone settings.'
                        : 'Enable SUNDO location and phone GPS in settings. Your selected address remains available when permission is denied.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Close')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Open Settings'))
                    ]));
        if (open == true) {
          if (!await Geolocator.isLocationServiceEnabled()) {
            await Geolocator.openLocationSettings();
          } else {
            await Geolocator.openAppSettings();
          }
        }
      }
      await _checkPermission();
    } catch (_) {
      if (mounted) {
        _message(
            'Location permissions are available when running SUNDO on your phone.');
      }
    }
  }

  Future<void> _saveProfile(
      {required String name,
      required String phone,
      required String barangay,
      required String street,
      required String zone}) async {
    if (BackendService.live) {
      await BackendService.client.from('profiles').update({
        'name': name,
        'phone': phone,
        'barangay': barangay,
        'street': street,
        'zone': zone
      }).eq('id', BackendService.client.auth.currentUser!.id);
      await BackendService.loadProfile();
    } else {
      await MockAuthRepository.updateProfile(
          name: name,
          phone: phone,
          barangay: barangay,
          street: street,
          zone: zone);
    }
    await _loadProfile();
    if (mounted) {
      await ProviderScope.containerOf(context, listen: false)
          .read(sundoWeatherProvider.notifier)
          .refreshSavedArea();
    }
  }

  Future<void> _editProfile() async {
    final form = GlobalKey<FormState>();
    final name = TextEditingController(text: _name);
    final phone = TextEditingController(text: _phone);
    var busy = false;
    String? error;
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
                  child: SingleChildScrollView(
                      child: Form(
                          key: form,
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Edit Profile',
                                    style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 16),
                                SundoTextField(
                                    label: 'Full Name',
                                    controller: name,
                                    icon: Icons.person_outline,
                                    validator: validateName,
                                    enabled: !busy),
                                const SizedBox(height: 14),
                                SundoTextField(
                                    label: 'Mobile Number',
                                    controller: phone,
                                    icon: Icons.phone_android_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: validateMobile,
                                    enabled: !busy),
                                const SizedBox(height: 14),
                                Text('Sign-in email: $_email',
                                    style: const TextStyle(fontSize: 12)),
                                if (error != null)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(error!,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              fontSize: 12))),
                                const SizedBox(height: 20),
                                SundoPrimaryButton(
                                    label: busy ? 'Saving…' : 'Save Changes',
                                    busy: busy,
                                    onPressed: () async {
                                      if (!(form.currentState?.validate() ??
                                          false)) {
                                        return;
                                      }
                                      update(() {
                                        busy = true;
                                        error = null;
                                      });
                                      try {
                                        await _saveProfile(
                                            name: name.text.trim(),
                                            phone: phone.text.trim(),
                                            barangay: _barangay,
                                            street: _street,
                                            zone: _zone);
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      } on StateError catch (failure) {
                                        if (context.mounted) {
                                          update(() {
                                            busy = false;
                                            error = failure.message.toString();
                                          });
                                        }
                                      } catch (_) {
                                        if (context.mounted) {
                                          update(() {
                                            busy = false;
                                            error =
                                                'Could not save. Check your connection and try again.';
                                          });
                                        }
                                      }
                                    }),
                              ]))),
                )));
    name.dispose();
    phone.dispose();
  }

  Future<void> _editAddress() async {
    final form = GlobalKey<FormState>();
    final street = TextEditingController(text: _street);
    final zone = TextEditingController(text: _zone);
    var barangay = sipalayBarangays.contains(_barangay)
        ? _barangay
        : sipalayBarangays.first;
    var busy = false;
    String? error;
    await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
                  child: SingleChildScrollView(
                      child: Form(
                          key: form,
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Primary Address',
                                    style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                    initialValue: barangay,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Barangay'),
                                    items: sipalayBarangays
                                        .map((value) => DropdownMenuItem(
                                            value: value,
                                            child: Text(value,
                                                style: const TextStyle(
                                                    fontSize: 12))))
                                        .toList(),
                                    onChanged: busy
                                        ? null
                                        : (value) => update(() =>
                                            barangay = value ?? barangay)),
                                const SizedBox(height: 14),
                                SundoTextField(
                                    label: 'Zone / Purok',
                                    controller: zone,
                                    icon: Icons.signpost_outlined,
                                    enabled: !busy,
                                    validator: validateRequired),
                                const SizedBox(height: 14),
                                SundoTextField(
                                    label: 'Street / Sitio / Landmark',
                                    controller: street,
                                    icon: Icons.home_outlined,
                                    enabled: !busy),
                                if (error != null)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(error!,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              fontSize: 12))),
                                const SizedBox(height: 20),
                                SundoPrimaryButton(
                                    label: busy ? 'Saving…' : 'Save Address',
                                    busy: busy,
                                    onPressed: () async {
                                      if (!(form.currentState?.validate() ??
                                          false)) {
                                        return;
                                      }
                                      update(() {
                                        busy = true;
                                        error = null;
                                      });
                                      try {
                                        await _saveProfile(
                                            name: _name,
                                            phone: _phone,
                                            barangay: barangay,
                                            street: street.text.trim(),
                                            zone: zone.text.trim());
                                        // A changed address must not retain a GPS fix from a previous address.
                                        await AppStore.setResidentLocation();
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      } catch (_) {
                                        if (context.mounted) {
                                          update(() {
                                            busy = false;
                                            error =
                                                'Could not save this address. Try again.';
                                          });
                                        }
                                      }
                                    }),
                              ]))),
                )));
    street.dispose();
    zone.dispose();
  }

  Future<void> _addAddress() async {
    final form = GlobalKey<FormState>();
    final label = TextEditingController();
    final address = TextEditingController();
    await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Add Saved Address'),
              content: SingleChildScrollView(
                  child: Form(
                      key: form,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextFormField(
                            controller: label,
                            validator: validateRequired,
                            decoration: const InputDecoration(
                                labelText: 'Label (Home, Work…)')),
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: address,
                            validator: validateRequired,
                            decoration: const InputDecoration(
                                labelText: 'Address in Sipalay')),
                      ]))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () async {
                      if (!(form.currentState?.validate() ?? false)) return;
                      await AppStore.addSavedAddress(
                          label.text.trim(), address.text.trim());
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save'))
              ],
            ));
    label.dispose();
    address.dispose();
  }

  Future<void> _savedAddresses() async {
    var addresses = await AppStore.getSavedAddresses();
    if (!mounted) return;
    await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => FractionallySizedBox(
                heightFactor: 0.7,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text('Saved Addresses',
                                  style: GoogleFonts.outfit(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800))),
                          IconButton(
                              tooltip: 'Add saved address',
                              onPressed: () async {
                                await _addAddress();
                                final updated =
                                    await AppStore.getSavedAddresses();
                                if (context.mounted) {
                                  update(() => addresses = updated);
                                }
                              },
                              icon: const Icon(Icons.add_circle_outline))
                        ]),
                        const Text(
                            'These addresses are saved privately on this phone.',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 16),
                        Expanded(
                            child: addresses.isEmpty
                                ? const Center(
                                    child: Text(
                                        'No saved addresses yet. Tap + to add one.'))
                                : ListView.separated(
                                    itemCount: addresses.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(),
                                    itemBuilder: (context, index) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(
                                            Icons.location_on_outlined,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                        title: Text(
                                            addresses[index]['label'] ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700)),
                                        subtitle: Text(
                                            addresses[index]['address'] ?? ''),
                                        trailing: IconButton(
                                            tooltip: 'Remove saved address',
                                            icon: const Icon(
                                                Icons.delete_outline),
                                            onPressed: () async {
                                              await AppStore.removeSavedAddress(
                                                  index);
                                              final updated = await AppStore
                                                  .getSavedAddresses();
                                              if (context.mounted) {
                                                update(
                                                    () => addresses = updated);
                                              }
                                            })))),
                      ]),
                ))));
  }

  Future<void> _notificationSettings() async {
    final NotificationRepository notifications = BackendService.live
        ? LocalNotificationRepository.shared
        : MockNotificationRepository.shared;
    final categories = {
      'approaching': 'Truck Approaching',
      'route': 'Route Changes',
      'weekly': 'Collection Reminders'
    };
    final enabled = <String, bool>{};
    for (final category in categories.keys) {
      enabled[category] = category == 'approaching'
          ? await notifications.remindersEnabled()
          : await AppStore.notificationEnabled(category);
    }
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: const Text('Notification Settings'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    for (final entry in categories.entries)
                      SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(entry.value,
                              style: const TextStyle(fontSize: 13)),
                          value: enabled[entry.key]!,
                          onChanged: (value) =>
                              update(() => enabled[entry.key] = value)),
                    const Text(
                        'Preferences are stored on this phone. System push delivery needs configured Firebase and a city notification service.',
                        style: TextStyle(fontSize: 11, height: 1.5)),
                    TextButton(
                        onPressed: () async {
                          try {
                            if (BackendService.live &&
                                PushNotificationService.configured) {
                              final allowed = await PushNotificationService
                                  .requestPermissionAndRegister();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(allowed
                                        ? 'Push permission allowed and this device registered.'
                                        : 'Push registration is unavailable. Check phone permission and Firebase configuration.')));
                              }
                              return;
                            }
                            final result = await permissions
                                .Permission.notification
                                .request();
                            if (result.isPermanentlyDenied) {
                              await permissions.openAppSettings();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(result.isGranted
                                      ? 'Phone notification permission allowed.'
                                      : 'Notification permission has not been granted.')));
                            }
                          } catch (_) {
                            if (mounted) {
                              _message(
                                  'Notification permissions are available on your Android or iOS phone.');
                            }
                          }
                        },
                        child: const Text('Manage Phone Permission')),
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () async {
                          for (final entry in enabled.entries) {
                            if (entry.key == 'approaching') {
                              await notifications
                                  .setRemindersEnabled(entry.value);
                            } else {
                              await AppStore.setNotificationEnabled(
                                  entry.key, entry.value);
                            }
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Save Preferences'))
                  ],
                )));
  }

  Future<void> _info(String title, String content) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(content,
                  style: const TextStyle(fontSize: 13, height: 1.6)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ]));

  Future<void> _about() => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title: const Text('About SUNDO'),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        'Smart Urban Navigation for Dynamic Waste Operations\n\nA resident app for waste collection tracking, schedules and community notifications in Sipalay.\n\n${BackendService.live ? 'Connected to your configured Supabase city service.' : 'Development demo: trucks, schedules and notifications are sample data. Accounts, preferences and reports stay on this device.'}\n\nSUNDO is a project in development; city endorsement has not been verified.',
                        style: const TextStyle(fontSize: 13, height: 1.6)),
                    const SizedBox(height: 18),
                    const Text('Weather artwork',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    const Text(
                        'If you enable local weather, SUNDO sends approximate coordinates to Open-Meteo while the app is open. A reliable saved Sipalay area may be used when GPS is unavailable; that banner is labeled as saved-area weather. Weather is model-based and may differ from conditions on your street. Clear, cloudy, rain, drizzle and thunderstorms combine with local device time. Unavailable or stale data uses time-based scenery. Change this in Location Permission.',
                        style: TextStyle(fontSize: 12, height: 1.6)),
                    const SizedBox(height: 12),
                    const WeatherAttribution(compact: false),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close')),
              ]));

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await BackendService.logout();
      await MockAuthRepository.logout();
      if (mounted) widget.onLogout?.call();
    } catch (_) {
      if (mounted) {
        _message('Could not log out. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  String get _address => [_street, _zone, _barangay, 'Sipalay City']
      .where((value) => value.isNotEmpty)
      .join(', ');
  String get _initials => _name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join()
      .toUpperCase();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final night = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
          centerTitle: true,
          title: Text('Profile',
              style: GoogleFonts.outfit(
                  fontSize: 19, fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
                tooltip: 'Edit profile',
                onPressed: _editProfile,
                icon: const Icon(Icons.settings_outlined))
          ]),
      body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            InkWell(
                onTap: _editProfile,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      CircleAvatar(
                          radius: 30,
                          backgroundColor: colors.primaryContainer,
                          child: Text(_initials.isEmpty ? 'R' : _initials,
                              style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: colors.onPrimaryContainer))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(_name,
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: colors.onSurface)),
                            const SizedBox(height: 4),
                            Text(_email,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text(_phone,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant)),
                          ])),
                      const Icon(Icons.edit_outlined, size: 18),
                    ]))),
            const SizedBox(height: 20),
            Container(
                decoration: night
                    ? BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(18))
                    : ClayTheme.card(radius: 18),
                child: Column(children: [
                  SundoProfileMenuItem(
                      icon: Icons.location_on_outlined,
                      title: 'Address',
                      subtitle: _address,
                      onTap: _editAddress),
                  const Divider(height: 1, indent: 50),
                  SundoProfileMenuItem(
                      icon: Icons.bookmark_border_rounded,
                      title: 'Saved Addresses',
                      onTap: _savedAddresses),
                  const Divider(height: 1, indent: 50),
                  SundoProfileMenuItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notification Settings',
                      onTap: _notificationSettings),
                  const Divider(height: 1, indent: 50),
                  SundoProfileMenuItem(
                      icon: Icons.my_location_outlined,
                      title: 'Location Permission',
                      status: _permissionLabel,
                      statusColor:
                          _locationAllowed ? colors.primary : colors.error,
                      onTap: _permissionTap),
                  const Divider(height: 1, indent: 50),
                  SundoProfileMenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () => _info('Help & Support',
                          'Use Report Concern for missed collection or uncollected waste.\n\nThis development build has no verified city support hotline. Contact your local barangay office for official collection assistance.\n\nFor map location, enable phone GPS and SUNDO location permission.')),
                  const Divider(height: 1, indent: 50),
                  SundoProfileMenuItem(
                      icon: Icons.info_outline_rounded,
                      title: 'About SUNDO',
                      onTap: _about),
                ])),
            const SizedBox(height: 20),
            OutlinedButton.icon(
                onPressed: _loggingOut ? null : _logout,
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC3B3B),
                    backgroundColor: night
                        ? const Color(0xFF362327)
                        : const Color(0xFFFFF0EE),
                    side: const BorderSide(color: Color(0xFFF0C6C1)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.logout_rounded, size: 19),
                label: Text(_loggingOut ? 'Logging out…' : 'Logout',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
          ])),
    );
  }
}

class SundoProfileMenuItem extends StatelessWidget {
  const SundoProfileMenuItem(
      {super.key,
      required this.icon,
      required this.title,
      required this.onTap,
      this.subtitle,
      this.status,
      this.statusColor});
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? status;
  final Color? statusColor;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        onTap: onTap,
        minLeadingWidth: 24,
        leading: Icon(icon,
            size: 21, color: Theme.of(context).colorScheme.onSurfaceVariant),
        title: Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (status != null)
            ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 76),
                child: Text(status!,
                    style: TextStyle(fontSize: 11, color: statusColor),
                    overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right_rounded, size: 20),
        ]),
      ));
}
