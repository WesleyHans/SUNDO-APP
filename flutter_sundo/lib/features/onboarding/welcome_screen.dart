import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/clay_theme.dart';
import '../../shared/widgets/sundo_graphics.dart';
import '../../core/theme/time_theme.dart';
import '../../shared/widgets/time_based_background.dart';
import '../../shared/widgets/scenic_backdrop.dart';

class WelcomeScreen extends StatefulWidget {
  final FutureOr<void> Function() onGetStarted;
  final VoidCallback onLogIn, onCreateAccount;
  const WelcomeScreen(
      {super.key,
      required this.onGetStarted,
      required this.onLogIn,
      required this.onCreateAccount});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _slide = 0;
  bool _startingDemo = false;

  Future<void> _getStarted() async {
    if (_startingDemo) return;
    setState(() => _startingDemo = true);
    try {
      await widget.onGetStarted();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Could not switch to the demo. Check your connection and try again.')));
      }
    } finally {
      if (mounted) setState(() => _startingDemo = false);
    }
  }

  static const _titles = [
    'A Cleaner Sipalay\nStarts with You',
    'Know Your Route.\nPlan Your Day.',
    'Small Actions.\nA Greener City.'
  ];
  static const _descriptions = [
    'Track garbage trucks, know collection schedules, receive alerts, and help keep our city clean.',
    'Follow collection trucks and check the next pickup in your barangay.',
    'Report uncollected waste with a photo and location. Follow every collection update.',
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
        body: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
                  child: SizedBox(
                    height: constraints.maxHeight.clamp(670, double.infinity),
                    child: Stack(fit: StackFit.expand, children: [
                      const SundoTimeBasedBackground(fullScene: true),
                      DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: SundoTimeScope.of(context).isNight
                            ? const [Color(0xCC153548), Color(0x00132C36)]
                            : const [Color(0x88EAF9FC), Color(0x00EAF9FC)],
                      ))),
                      SafeArea(
                          child: Column(children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 26, vertical: 10),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    const SundoBrandMark(width: 34),
                                    const SizedBox(width: 6),
                                    Text('SUNDO',
                                        style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: SundoTimeScope.of(context)
                                                .textColor)),
                                  ]),
                                  const Expanded(
                                      child:
                                          Center(child: LeafSprig(size: 40))),
                                  TextButton(
                                      onPressed:
                                          _startingDemo ? null : _getStarted,
                                      child: const Text('Explore demo')),
                                ])),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Column(key: ValueKey(_slide), children: [
                                Text(_titles[_slide],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                        fontSize: 32,
                                        height: 1.1,
                                        fontWeight: FontWeight.w800,
                                        color: SundoTimeScope.of(context)
                                            .textColor)),
                                const SizedBox(height: 14),
                                Text(_descriptions[_slide],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        height: 1.6,
                                        color: SundoTimeScope.of(context)
                                            .mutedTextColor)),
                              ]),
                            )),
                        const Spacer(),
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(26, 20, 26, 16),
                            decoration: SundoTimeScope.of(context).isNight
                                ? BoxDecoration(
                                    color: SundoTimeScope.of(context).surface,
                                    borderRadius: BorderRadius.circular(34))
                                : ClayTheme.cardElevated(radius: 34),
                            child: Column(children: [
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                      3,
                                      (index) => Semantics(
                                          label: 'Introduction ${index + 1}',
                                          selected: index == _slide,
                                          child: GestureDetector(
                                              onTap: () => setState(
                                                  () => _slide = index),
                                              child: Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 4),
                                                  height: 8,
                                                  width:
                                                      index == _slide ? 24 : 8,
                                                  decoration: BoxDecoration(
                                                      color: index == _slide
                                                          ? const Color(
                                                              0xFF07853D)
                                                          : const Color(
                                                              0xFFC4D9C8),
                                                      borderRadius:
                                                          BorderRadius.circular(8))))))),
                              const SizedBox(height: 18),
                              _button(
                                  _startingDemo
                                      ? 'Opening demo…'
                                      : 'Get Started',
                                  _startingDemo ? null : _getStarted,
                                  primary: true),
                              const SizedBox(height: 13),
                              _button('Log In', widget.onLogIn),
                              const SizedBox(height: 7),
                              TextButton(
                                  onPressed: widget.onCreateAccount,
                                  child: const Text('Create Account')),
                            ])),
                      ])),
                    ]),
                  ),
                )),
      );
  Widget _button(String label, VoidCallback? action, {bool primary = false}) =>
      Semantics(
        button: true,
        child: GestureDetector(
          onTap: action,
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: primary
                  ? ClayTheme.buttonPrimary(radius: 24)
                  : ClayTheme.buttonSecondary(radius: 24),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color:
                            primary ? Colors.white : const Color(0xFF17603A))),
                if (primary) ...[
                  const SizedBox(width: 14),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 19)
                ],
              ])),
        ),
      );
}
