import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clay_theme.dart';

const sipalayBarangays = <String>[
  'Barangay 1 (Poblacion)',
  'Barangay 2 (Poblacion)',
  'Barangay 3 (Poblacion)',
  'Barangay 4 (Poblacion)',
  'Barangay 5 (Poblacion)',
  'Cabadiangan',
  'Camindangan',
  'Canturay',
  'Cartagena',
  'Cayhagan',
  'Gil Montilla',
  'Mambaroto',
  'Manlucahoc',
  'Maricalum',
  'Nabulao',
  'Nauhang',
  'San Jose',
];

String? validateName(String? value) =>
    (value?.trim().length ?? 0) < 2 ? 'Enter your full name.' : null;
String? validateEmail(String? value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
        ? null
        : 'Enter a valid email address.';
String? validateMobile(String? value) => RegExp(r'^(09\d{9}|\+?639\d{9})$')
        .hasMatch((value ?? '').replaceAll(RegExp(r'[\s-]'), ''))
    ? null
    : 'Use a Philippine mobile number (09… or +639…).';
String? validatePassword(String? value) =>
    (value?.length ?? 0) < 8 ? 'Use at least 8 characters.' : null;
String? validateRequired(String? value) =>
    value?.trim().isEmpty != false ? 'This field is required.' : null;

class SundoTextField extends StatelessWidget {
  const SundoTextField(
      {super.key,
      required this.label,
      required this.controller,
      required this.icon,
      this.hint,
      this.validator,
      this.keyboardType,
      this.obscureText = false,
      this.suffixIcon,
      this.autofillHints,
      this.enabled = true,
      this.onSubmitted,
      this.textInputAction = TextInputAction.next});
  final String label;
  final String? hint;
  final TextEditingController controller;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final void Function(String)? onSubmitted;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final night = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: night
          ? BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant))
          : ClayTheme.input(radius: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w500, color: colors.onSurface),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.onSurfaceVariant),
          prefixIcon: Icon(icon, size: 20, color: colors.onSurfaceVariant),
          suffixIcon: suffixIcon,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.primary)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.error)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class SundoPrimaryButton extends StatelessWidget {
  const SundoPrimaryButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.busy = false,
      this.icon = Icons.arrow_forward_rounded});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: ClayTheme.buttonPrimary(radius: 18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: busy ? null : onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Flexible(
                      child: Text(label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Colors.white))),
                  const SizedBox(width: 12),
                  busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(icon, color: Colors.white, size: 20),
                ]),
              ),
            ),
          ),
        ),
      );
}

class DemoAuthNotice extends StatelessWidget {
  const DemoAuthNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF2D4),
            borderRadius: BorderRadius.circular(14)),
        child:
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.science_outlined, color: Color(0xFF95600C), size: 17),
          SizedBox(width: 8),
          Expanded(
              child: Text(
                  'LOCAL DEMO • Your account stays on this phone. City accounts and shared data need Supabase.',
                  style: TextStyle(
                      fontSize: 11, height: 1.4, color: Color(0xFF755010)))),
        ]),
      );
}
