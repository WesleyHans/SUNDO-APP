import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/clay_theme.dart';
import '../widgets/sundo_graphics.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogIn;
  final VoidCallback onCreateAccount;

  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
    required this.onLogIn,
    required this.onCreateAccount,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title1': 'A Cleaner Sipalay\n',
      'title2': 'Starts with You',
      'accentColor': const Color(0xFF047857),
      'underlineColor': const Color(0xFF34D399),
      'description':
          'Track garbage trucks, know collection schedules, receive alerts, and help keep our city clean.',
      'graphic': const WelcomeSceneGraphic(height: 195),
    },
    {
      'title1': 'Live GPS Tracking\n',
      'title2': 'Never Miss a Truck',
      'accentColor': const Color(0xFF059669),
      'underlineColor': const Color(0xFF10B981),
      'description':
          'Watch collection trucks approach your barangay in real-time with accurate distance meters and proximity sirens.',
      'graphic': const GpsTrackingSceneGraphic(height: 195),
    },
    {
      'title1': 'Report & Keep Track\n',
      'title2': 'Zero Waste Sipalay',
      'accentColor': const Color(0xFF0D9488),
      'underlineColor': const Color(0xFF2DD4BF),
      'description':
          'Snap photos of uncollected waste or illegal dumping, earn Eco-Points, and keep our coastlines pristine.',
      'graphic': const ReportCommunitySceneGraphic(height: 195),
    },
  ];

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onGetStarted();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar: SUNDO Logo badge & Skip button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x20059669),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/sundo_logo.png',
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.recycling_rounded,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SUNDO',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _slides.length - 1)
                    GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          _slides.length - 1,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 28, width: 48),
                ],
              ),

              const SizedBox(height: 10),

              // Interactive Swipeable Walkthrough Slides
              SizedBox(
                height: 360,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Headline with custom underline
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              height: 1.25,
                            ),
                            children: [
                              TextSpan(text: slide['title1']),
                              TextSpan(
                                text: slide['title2'],
                                style: TextStyle(
                                  color: slide['accentColor'],
                                  decoration: TextDecoration.underline,
                                  decorationColor: slide['underlineColor'],
                                  decorationThickness: 3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            slide['description'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF475569),
                              height: 1.45,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Custom Scene Graphic for this slide
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: slide['graphic'] as Widget,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Interactive Claymorphic Pagination Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final bool isActive = _currentPage == index;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isActive
                            ? const [
                                BoxShadow(
                                  color: Color(0x40059669),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // 1. Primary Clay Button: Next / Get Started
              GestureDetector(
                onTap: _onNext,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: ClayTheme.buttonPrimary(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. Secondary Clay Button: Log In
              GestureDetector(
                onTap: widget.onLogIn,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: ClayTheme.buttonSecondary(),
                  child: Center(
                    child: Text(
                      'Log In',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Text Link: Create an Account
              GestureDetector(
                onTap: widget.onCreateAccount,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    'Create an Account',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF047857),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
