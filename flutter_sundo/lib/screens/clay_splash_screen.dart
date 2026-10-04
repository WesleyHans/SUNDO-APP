import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/sundo_graphics.dart';
import '../widgets/scenic_backdrop.dart';
import '../theme/clay_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const SplashScreen({super.key, required this.onContinue});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) widget.onContinue();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onContinue,
        child: Scaffold(
            body: Stack(fit: StackFit.expand, children: [
          Image.asset(clayHeroAsset, fit: BoxFit.cover),
          const DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.44, 0.7],
            colors: [Color(0xFFFAFFF2), Color(0xEEFAFFF2), Color(0x00FAFFF2)],
          ))),
          const Positioned(
              left: -22, top: 25, child: LeafSprig(size: 120, flipped: true)),
          const Positioned(right: -35, top: 100, child: LeafSprig(size: 85)),
          SafeArea(
              child: Column(children: [
            const SizedBox(height: 55),
            const SundoLogoGraphic(size: 135, showSubtitle: true),
            const Spacer(),
            Container(
                margin: const EdgeInsets.all(26),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: ClayTheme.card(radius: 28),
                child: Column(children: [
                  Text('Track. Prepare. Collect.',
                      style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF185632))),
                  const SizedBox(height: 8),
                  Text('Together for a cleaner Sipalay',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: const Color(0xFF567060))),
                ])),
          ])),
        ])),
      );
}
