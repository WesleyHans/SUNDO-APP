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
      'title1': 'A Cleaner Sipalay\nStarts with ',
      'title2': 'You',
      'accentColor': const Color(0xFF059669),
      'description':
          'Track garbage trucks, know collection schedules, receive alerts, and help keep our city clean.',
      'graphic': const WelcomeSceneGraphic(height: 180),
    },
    {
      'title1': 'Live GPS Tracking\nNever Miss a ',
      'title2': 'Truck',
      'accentColor': const Color(0xFF059669),
      'description':
          'Watch collection trucks approach your barangay in real-time with accurate distance meters and proximity sirens.',
      'graphic': const GpsTrackingSceneGraphic(height: 180),
    },
    {
      'title1': 'Report & Keep Track\nZero Waste ',
      'title2': 'Sipalay',
      'accentColor': const Color(0xFF059669),
      'description':
          'Snap photos of uncollected waste or illegal dumping, earn Eco-Points, and keep our coastlines pristine.',
      'graphic': const ReportCommunitySceneGraphic(height: 180),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Brand Header Row with Skip Clay Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Welcome to SUNDO',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onGetStarted,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: ClayTheme.buttonSecondary(radius: 12),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Interactive Swipeable Walkthrough Slides
              SizedBox(
                height: 405,
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
                        // Headline matching realistic mockup
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
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            slide['description'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: const Color(0xFF64748B),
                              height: 1.45,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 3D Elevated Clay Presentation Card holding the Scene Graphic
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            padding: const EdgeInsets.all(16),
                            decoration: ClayTheme.cardElevated(radius: 28),
                            child: Center(
                              child: slide['graphic'] as Widget,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // Carousel Dots Indicator (Mockup matching elongated active pill)
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
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 24 : 7,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // 1. Primary Inflated Clay Button: Get Started →
              GestureDetector(
                onTap: widget.onGetStarted,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: ClayTheme.buttonPrimary(radius: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. Secondary Inflated Clay Button: Log In
              GestureDetector(
                onTap: widget.onLogIn,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: ClayTheme.buttonSecondary(radius: 20),
                  child: Center(
                    child: Text(
                      'Log In',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 3. Text Link: Create an Account
              GestureDetector(
                onTap: widget.onCreateAccount,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    'Create an Account',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF059669),
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
