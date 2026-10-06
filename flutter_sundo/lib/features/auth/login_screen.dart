import '../../shared/widgets/scenic_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../repositories/mock_auth_repository.dart';
import '../../services/backend_service.dart';
import './widgets/auth_form_widgets.dart';
import '../../shared/widgets/sundo_graphics.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onCreateAccount;
  final VoidCallback? onBack;
  const LoginScreen(
      {super.key,
      required this.onLoginSuccess,
      required this.onCreateAccount,
      this.onBack});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  bool _remember = true;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      if (BackendService.configured) {
        if (validateEmail(_identifier.text) != null) {
          _message(
              'Use your email for city sign-in. Mobile sign-in needs an enabled phone-auth provider.');
          return;
        }
        await BackendService.login(_identifier.text.trim(), _password.text,
            remember: _remember);
      } else {
        await MockAuthRepository.login(_identifier.text, _password.text,
            remember: _remember);
        BackendService.demoMode = true;
      }
      if (mounted) widget.onLoginSuccess();
    } on StateError catch (error) {
      if (mounted) _message(error.message.toString());
    } catch (_) {
      if (mounted) {
        _message('Sign-in failed. Check your email, password and connection.');
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
          size: 76,
          child: SafeArea(
              child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: AutofillGroup(
                child: Form(
              key: _form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.onBack != null)
                      Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                              onPressed: _busy ? null : widget.onBack,
                              tooltip: 'Back',
                              icon: const Icon(Icons.chevron_left_rounded))),
                    const SizedBox(height: 4),
                    const Center(
                        child: SundoLogoGraphic(size: 86, showSubtitle: false)),
                    const SizedBox(height: 18),
                    Text('Welcome Back!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface)),
                    const SizedBox(height: 5),
                    Text('Log in to continue to a cleaner Sipalay.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: colors.onSurfaceVariant)),
                    const SizedBox(height: 20),
                    if (!BackendService.configured) ...[
                      const DemoAuthNotice(),
                      const SizedBox(height: 16),
                    ],
                    SundoTextField(
                        label: 'Email or Mobile Number',
                        controller: _identifier,
                        icon: Icons.person_outline_rounded,
                        hint: 'juan@example.com / 09…',
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        validator: (value) {
                          if (validateRequired(value) != null) {
                            return 'Enter your email or mobile number.';
                          }
                          if (validateEmail(value) != null &&
                              validateMobile(value) != null) {
                            return 'Enter a valid email or Philippine mobile number.';
                          }
                          return null;
                        }),
                    const SizedBox(height: 14),
                    SundoTextField(
                        label: 'Password',
                        controller: _password,
                        icon: Icons.lock_outline_rounded,
                        obscureText: !_showPassword,
                        enabled: !_busy,
                        validator: validateRequired,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        suffixIcon: IconButton(
                            tooltip: _showPassword
                                ? 'Hide password'
                                : 'Show password',
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20))),
                    const SizedBox(height: 6),
                    Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Checkbox(
                                value: _remember,
                                onChanged: _busy
                                    ? null
                                    : (value) => setState(
                                        () => _remember = value ?? true)),
                            Text('Remember me',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant)),
                          ]),
                          TextButton(
                              onPressed: () => _message(BackendService
                                      .configured
                                  ? 'Ask your city administrator for the enabled account-recovery process.'
                                  : 'Local demo accounts have no email recovery. Create another demo account to keep exploring.'),
                              child: const Text('Forgot Password?',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700))),
                        ]),
                    const SizedBox(height: 10),
                    SundoPrimaryButton(
                        label: _busy ? 'Logging in…' : 'Log In',
                        busy: _busy,
                        onPressed: _login),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: Divider(color: colors.outlineVariant)),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 12))),
                      Expanded(child: Divider(color: colors.outlineVariant))
                    ]),
                    const SizedBox(height: 14),
                    _socialButton(
                        'Continue with Google',
                        const Text('G',
                            style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4285F4))),
                        'Google'),
                    const SizedBox(height: 12),
                    _socialButton(
                        'Continue with Facebook',
                        const Icon(Icons.facebook,
                            color: Color(0xFF1877F2), size: 25),
                        'Facebook'),
                    const SizedBox(height: 18),
                    Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text("Don't have an account?",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant)),
                          TextButton(
                              onPressed: _busy ? null : widget.onCreateAccount,
                              child: const Text('Create Account',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)))
                        ]),
                  ]),
            )),
          ))),
    );
  }

  Widget _socialButton(String label, Widget icon, String provider) =>
      OutlinedButton(
        onPressed: () => _message(
            '$provider sign-in is not enabled. Use your email/password or a local demo account.'),
        style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          icon,
          const SizedBox(width: 10),
          Flexible(
              child: Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)))
        ]),
      );
}
