import 'package:flutter/material.dart';

/// Sharp Claymorphism Design System matching SUNDO specifications
/// Clean, crisp, defined edges with ZERO blurry white halos or washed-out glowing overlays.
class ClayTheme {
  // 1. Standard Sharp Clay Card (.clay-card)
  static BoxDecoration card({double radius = 24}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x140F172A), // Crisp subtle ambient shadow
          offset: Offset(0, 8),
          blurRadius: 20,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Color(0x0A0F172A), // Crisp contact shadow
          offset: Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    );
  }

  // 2. Mint Sharp Clay Card (.clay-card-mint)
  static BoxDecoration cardMint({double radius = 24}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF0FDF4), Color(0xFFE6FCF0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18059669),
          offset: Offset(0, 8),
          blurRadius: 18,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Color(0x0A059669),
          offset: Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );
  }

  // 3. Primary Clay Button (.clay-button-primary)
  static BoxDecoration buttonPrimary({double radius = 9999}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFF34D399), width: 1.0),
      boxShadow: const [
        BoxShadow(
          color: Color(0x35059669),
          offset: Offset(0, 6),
          blurRadius: 14,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Color(0x15059669),
          offset: Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );
  }

  // 4. Secondary Clay Button (.clay-button-secondary)
  static BoxDecoration buttonSecondary({double radius = 18}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFF8FAFC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x120F172A),
          offset: Offset(0, 4),
          blurRadius: 10,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Color(0x080F172A),
          offset: Offset(0, 1),
          blurRadius: 3,
        ),
      ],
    );
  }

  // 5. Clay Badge (.clay-badge)
  static BoxDecoration badge({
    required Color bgColor,
    required Color borderColor,
    double radius = 9999,
  }) {
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0E0F172A),
          offset: Offset(0, 2),
          blurRadius: 5,
        ),
      ],
    );
  }

  // 6. Amber Clay Badge (.clay-amber-badge)
  static BoxDecoration amberBadge({double radius = 9999}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1AD97706),
          offset: Offset(0, 3),
          blurRadius: 8,
          spreadRadius: -1,
        ),
      ],
    );
  }

  // 7. Clay Status Chip
  static BoxDecoration statusChip({
    required Color bgColor,
    required Color borderColor,
    required Color shadowColor,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.14),
          offset: const Offset(0, 2),
          blurRadius: 5,
        ),
      ],
    );
  }

  // 8. Clay Inset Box
  static BoxDecoration insetBox({double radius = 16}) {
    return BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          offset: Offset(0, 1),
          blurRadius: 3,
        ),
      ],
    );
  }

  // 9. Clay Input Box (.clay-input)
  static BoxDecoration input({double radius = 16}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0F172A),
          offset: Offset(0, 2),
          blurRadius: 5,
        ),
      ],
    );
  }
}
