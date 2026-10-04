import 'package:flutter/material.dart';

/// Detailed & Realistic Claymorphism Design System matching SUNDO specifications
/// Multi-layered directional soft shadows, molded tactile depth, and crisp physical contours.
/// Zero blurry white halos or washed-out glowing overlays.
class ClayTheme {
  // 1. Standard Realistic Clay Card (.clay-card)
  static BoxDecoration card({double radius = 24}) {
    return BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF1F7ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      boxShadow: const [
        BoxShadow(
            color: Color(0xF0FFFFFF), offset: Offset(-4, -4), blurRadius: 12),
        BoxShadow(
          color: Color(0x180F172A), // Soft ambient depth shadow
          offset: Offset(0, 12),
          blurRadius: 26,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Color(0x0C0F172A), // Body directional shadow
          offset: Offset(0, 4),
          blurRadius: 10,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Color(0x060F172A), // Contact crease
          offset: Offset(0, 1),
          blurRadius: 3,
        ),
      ],
    );
  }

  // 2. Focal 3D Elevated Clay Card (for Hero Graphics & Major Modals)
  static BoxDecoration cardElevated({double radius = 28}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x200F172A), // Deep ambient drop
          offset: Offset(0, 18),
          blurRadius: 36,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Color(0x0E0F172A), // Mid-level body cast
          offset: Offset(0, 6),
          blurRadius: 14,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Color(0x080F172A), // Tight grounding shadow
          offset: Offset(0, 2),
          blurRadius: 5,
        ),
      ],
    );
  }

  // 3. Mint Realistic Clay Card (.clay-card-mint)
  static BoxDecoration cardMint({double radius = 24}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x20059669),
          offset: Offset(0, 12),
          blurRadius: 24,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Color(0x0E059669),
          offset: Offset(0, 4),
          blurRadius: 8,
          spreadRadius: -1,
        ),
      ],
    );
  }

  // 4. Inflated Primary Clay Button (.clay-button-primary)
  static BoxDecoration buttonPrimary({double radius = 20}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF23A54E), Color(0xFF07853D), Color(0xFF056D34)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
          color: const Color(0x5534D399), width: 1.2), // Tactile rim light
      boxShadow: const [
        BoxShadow(
            color: Color(0x66FFFFFF), offset: Offset(-2, -3), blurRadius: 5),
        BoxShadow(
          color: Color(0x4C059669), // Rich emerald downward cast shadow
          offset: Offset(0, 10),
          blurRadius: 20,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Color(0x22059669),
          offset: Offset(0, 4),
          blurRadius: 8,
        ),
      ],
    );
  }

  // 5. Inflated Secondary Clay Button (.clay-button-secondary)
  static BoxDecoration buttonSecondary({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x160F172A),
          offset: Offset(0, 8),
          blurRadius: 18,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Color(0x080F172A),
          offset: Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    );
  }

  // 6. Molded Clay Input Box (.clay-input)
  static BoxDecoration input({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x120F172A), // Molded depth shadow
          offset: Offset(0, 6),
          blurRadius: 16,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Color(0x060F172A),
          offset: Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );
  }

  // 7. Tactile Clay Badge (.clay-badge)
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
          color: Color(0x100F172A),
          offset: Offset(0, 3),
          blurRadius: 8,
          spreadRadius: -1,
        ),
      ],
    );
  }

  // 8. Amber Clay Badge (.clay-amber-badge)
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
          color: Color(0x22D97706),
          offset: Offset(0, 4),
          blurRadius: 10,
          spreadRadius: -2,
        ),
      ],
    );
  }

  // 9. Clay Status Chip
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
          color: shadowColor.withValues(alpha: 0.18),
          offset: const Offset(0, 3),
          blurRadius: 7,
          spreadRadius: -1,
        ),
      ],
    );
  }

  // 10. Clay Inset Box
  static BoxDecoration insetBox({double radius = 16}) {
    return BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
