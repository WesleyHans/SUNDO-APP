import 'package:flutter/material.dart';

/// Claymorphism Design System matching SUNDO web simulator CSS (.clay-card, .clay-card-mint, .clay-button-primary, etc.)
class ClayTheme {
  // 1. Standard Clay Card (.clay-card)
  static BoxDecoration card({double radius = 24}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2694A3B8), // rgba(148, 163, 184, 0.18)
          offset: Offset(8, 8),
          blurRadius: 20,
        ),
        BoxShadow(
          color: Colors.white,
          offset: Offset(-6, -6),
          blurRadius: 16,
        ),
      ],
    );
  }

  // 2. Mint Clay Card (.clay-card-mint)
  static BoxDecoration cardMint({double radius = 24}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF0FDF4), Color(0xFFE6FCF0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x386EE7B7), // rgba(110, 231, 183, 0.22)
          offset: Offset(8, 8),
          blurRadius: 20,
        ),
        BoxShadow(
          color: Colors.white,
          offset: Offset(-6, -6),
          blurRadius: 16,
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
      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55059669), // rgba(5, 150, 105, 0.35)
          offset: Offset(6, 6),
          blurRadius: 18,
        ),
        BoxShadow(
          color: Color(0x75FFFFFF),
          offset: Offset(-3, -3),
          blurRadius: 10,
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
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2894A3B8), // rgba(148, 163, 184, 0.2)
          offset: Offset(5, 5),
          blurRadius: 14,
        ),
        BoxShadow(
          color: Colors.white,
          offset: Offset(-4, -4),
          blurRadius: 10,
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
      border: Border.all(color: borderColor, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F94A3B8),
          offset: Offset(3, 3),
          blurRadius: 8,
        ),
        BoxShadow(
          color: Colors.white,
          offset: Offset(-2, -2),
          blurRadius: 6,
        ),
      ],
    );
  }

  // 6. Clay Status Chip
  static BoxDecoration statusChip({
    required Color bgColor,
    required Color borderColor,
    required Color shadowColor,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.15),
          offset: const Offset(3, 3),
          blurRadius: 8,
        ),
        const BoxShadow(
          color: Colors.white,
          offset: Offset(-2, -2),
          blurRadius: 6,
        ),
      ],
    );
  }

  // 7. Clay Inset Box
  static BoxDecoration insetBox({double radius = 16}) {
    return BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8), width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          offset: Offset(1, 1),
          blurRadius: 3,
        ),
      ],
    );
  }
}
