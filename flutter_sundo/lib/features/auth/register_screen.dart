import '../../shared/widgets/scenic_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../repositories/mock_auth_repository.dart';
import '../../core/storage/app_store.dart';
import '../../services/backend_service.dart';
import './widgets/auth_form_widgets.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onRegisterSuccess;
  final VoidCallback onGoToLogin;
  const RegisterScreen(
      {super.key,
      required this.onBack,
      required this.onRegisterSuccess,
      required this.onGoToLogin});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _street = TextEditingController();
  final _zone = TextEditingController();
  String _barangay = sipalayBarangays.first;
  bool _showPassword = false;
  bool _busy = false;
  bool _locationBusy = false;
  bool _useLocation = false;
  bool _agree = false;
  Position? _position;
  String _locationStatus =
      'Uses your selected barangay and address when location is off.';

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _email,
      _password,
      _confirm,
      _street,
      _zone
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _message(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _toggleLocation(bool enabled) async {
    if (!enabled) {
      setState(() {
        _useLocation = false;
        _position = null;
        _locationStatus =
            'Uses your selected barangay and address when location is off.';
      });
      return;
    }
    setState(() => _locationBusy = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          setState(() => _locationStatus =
              'Location services are off. Selected address will be used.');
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locationStatus = permission ==
                  LocationPermission.deniedForever
              ? 'Permission is blocked. Enable SUNDO location in phone settings, or use your selected address.'
              : 'Permission denied. Your selected address will be used.');
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20));
      if (mounted) {
        setState(() {
          _position = position;
          _useLocation = true;
          _locationStatus =
              'Location found • accuracy ±${position.accuracy.round()} m. Stored privately on this phone.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationStatus =
            'A GPS fix is unavailable. Your selected address will be used.');
      }
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  Future<void> _register() async {
    if (_busy || _locationBusy || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    if (!_agree) {
      _message('Please accept the privacy and demo information first.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      bool authenticated = true;
      if (BackendService.configured) {
        authenticated = await BackendService.register(_name.text.trim(),
            _email.text.trim(), _phone.text.trim(), _barangay, _password.text,
            zone: _zone.text.trim(), street: _street.text.trim());
      } else {
        await MockAuthRepository.register(
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            barangay: _barangay,
            street: _street.text,
            zone: _zone.text,
            password: _password.text);
        BackendService.demoMode = true;
      }
      if (!mounted) return;
      if (!authenticated) {
        _message(
            'Account created. Confirm the email from Supabase before logging in.');
        widget.onGoToLogin();
        return;
      }
      await AppStore.setResidentLocation(
          latitude: _useLocation ? _position?.latitude : null,
          longitude: _useLocation ? _position?.longitude : null,
          accuracy: _useLocation ? _position?.accuracy : null);
      if (mounted) widget.onRegisterSuccess();
    } on StateError catch (error) {
      if (mounted) _message(error.message.toString());
    } catch (_) {
      if (mounted) {
        _message(
            'Account creation failed. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SundoLeafFrame(
          size: 44,
          child: SafeArea(
              child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            child: AutofillGroup(
                child: Form(
              key: _form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                            onPressed: _busy ? null : widget.onBack,
                            tooltip: 'Back',
                            icon: const Icon(Icons.chevron_left_rounded))),
                    Text('Create Your Account',
                        style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface)),
                    const SizedBox(height: 5),
                    Text(
                        'Join SUNDO and be part of a\ncleaner and greener Sipalay.',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                            height: 1.5)),
                    const SizedBox(height: 18),
                    if (!BackendService.configured) ...[
                      const DemoAuthNotice(),
                      const SizedBox(height: 14)
                    ],
                    SundoTextField(
                        label: 'Full Name',
                        controller: _name,
                        icon: Icons.person_outline,
                        hint: 'Juan Dela Cruz',
                        enabled: !_busy,
                        validator: validateName,
                        autofillHints: const [AutofillHints.name]),
                    const SizedBox(height: 12),
                    SundoTextField(
                        label: 'Mobile Number',
                        controller: _phone,
                        icon: Icons.phone_android_outlined,
                        hint: '0912 345 6789',
                        enabled: !_busy,
                        validator: validateMobile,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber]),
                    const SizedBox(height: 12),
                    SundoTextField(
                        label: 'Email Address',
                        controller: _email,
                        icon: Icons.mail_outline,
                        hint: 'juan@example.com',
                        enabled: !_busy,
                        validator: validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email]),
                    const SizedBox(height: 12),
                    SundoTextField(
                        label: 'Password',
                        controller: _password,
                        icon: Icons.lock_outline,
                        obscureText: !_showPassword,
                        enabled: !_busy,
                        validator: validatePassword,
                        autofillHints: const [AutofillHints.newPassword],
                        suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            tooltip: _showPassword
                                ? 'Hide password'
                                : 'Show password',
                            icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20))),
                    const SizedBox(height: 12),
                    SundoTextField(
                        label: 'Confirm Password',
                        controller: _confirm,
                        icon: Icons.lock_outline,
                        obscureText: !_showPassword,
                        enabled: !_busy,
                        validator: (value) =>
                            value == _password.text && value?.isNotEmpty == true
                                ? null
                                : 'The passwords must match.'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                        initialValue: _barangay,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Barangay / Address',
                            prefixIcon:
                                Icon(Icons.location_on_outlined, size: 20)),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: colors.onSurface),
                        items: sipalayBarangays
                            .map((barangay) => DropdownMenuItem(
                                value: barangay, child: Text(barangay)))
                            .toList(),
                        onChanged: _busy
                            ? null
                            : (value) =>
                                setState(() => _barangay = value ?? _barangay)),
                    const SizedBox(height: 12),
                    SundoTextField(
                        label: 'Zone / Purok',
                        controller: _zone,
                        icon: Icons.signpost_outlined,
                        hint: 'Purok 2',
                        enabled: !_busy,
                        validator: validateRequired),
                    const SizedBox(height: 12),
                    SundoTextField(
                        label: 'Street / Sitio / Landmark',
                        controller: _street,
                        icon: Icons.home_outlined,
                        hint: 'Near the plaza',
                        enabled: !_busy),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Use my current location',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        secondary: Icon(Icons.my_location_rounded,
                            color: colors.primary, size: 21),
                        value: _useLocation,
                        onChanged:
                            _busy || _locationBusy ? null : _toggleLocation),
                    Text(
                        _locationBusy
                            ? 'Getting an accurate GPS fix…'
                            : _locationStatus,
                        style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: colors.onSurfaceVariant)),
                    if (_locationStatus.contains('blocked'))
                      const Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                              onPressed: Geolocator.openAppSettings,
                              child: Text('Open phone settings'))),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _agree,
                        onChanged: _busy
                            ? null
                            : (value) =>
                                setState(() => _agree = value ?? false),
                        title: const Text(
                            'I understand my address is used for collection updates and my precise location stays private.',
                            style: TextStyle(fontSize: 11, height: 1.4))),
                    const SizedBox(height: 14),
                    SundoPrimaryButton(
                        label: _busy ? 'Creating account…' : 'Create Account',
                        busy: _busy,
                        onPressed: _register),
                    const SizedBox(height: 16),
                    Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Already have an account?',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant)),
                          TextButton(
                              onPressed: _busy ? null : widget.onGoToLogin,
                              child: const Text('Log In',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)))
                        ]),
                  ]),
            )),
          ))),
    );
  }
}
