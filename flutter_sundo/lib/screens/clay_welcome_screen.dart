import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/clay_theme.dart';
import '../widgets/scenic_backdrop.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted, onLogIn, onCreateAccount;
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
  static const _titles = [
    'A Cleaner Sipalay\nStarts with You',
    'Know Your Route.\nPlan Your Day.',
    'Small Actions.\nA Greener City.'
  ];
  static const _descriptions = [
    'Track garbage trucks, know collection schedules, and help keep our city clean.',
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
                      Image.asset(clayHeroAsset, fit: BoxFit.cover),
                      const DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Color(0x88EAF9FC), Color(0x00EAF9FC)],
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
                                  Text('SUNDO',
                                      style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF185632))),
                                  TextButton(
                                      onPressed: widget.onGetStarted,
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
                                        color: const Color(0xFF174F32))),
                                const SizedBox(height: 14),
                                Text(_descriptions[_slide],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        height: 1.6,
                                        color: const Color(0xFF294D41))),
                              ]),
                            )),
                        const Spacer(),
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(26, 20, 26, 16),
                            decoration: ClayTheme.cardElevated(radius: 34),
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
                              _button('Get Started', widget.onGetStarted,
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
  Widget _button(String label, VoidCallback action, {bool primary = false}) =>
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
