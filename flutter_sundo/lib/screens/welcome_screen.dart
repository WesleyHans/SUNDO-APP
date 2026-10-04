import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      'accentColor': const Color(0xFF65A30D),
      'description':
          'Track garbage trucks, know collection schedules, receive alerts, and help keep our city clean.',
      'graphic': const WelcomeSceneGraphic(height: 200),
    },
    {
      'title1': 'Live GPS Tracking\nNever Miss a ',
      'title2': 'Truck',
      'accentColor': const Color(0xFF059669),
      'description':
          'Watch collection trucks approach your barangay in real-time with accurate distance meters and proximity sirens.',
      'graphic': const GpsTrackingSceneGraphic(height: 200),
    },
    {
      'title1': 'Report & Keep Track\nZero Waste ',
      'title2': 'Sipalay',
      'accentColor': const Color(0xFF059669),
      'description':
          'Snap photos of uncollected waste or illegal dumping, earn Eco-Points, and keep our coastlines pristine.',
      'graphic': const ReportCommunitySceneGraphic(height: 200),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Interactive Swipeable Walkthrough Slides
              SizedBox(
                height: 380,
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
                        // Headline matching Mockup 2
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: 26,
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

                        const SizedBox(height: 10),

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

              const SizedBox(height: 14),

              // Carousel Dots Indicator (Mockup 2: 3 dots)
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
                      width: isActive ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // 1. Primary Button: Get Started →
              GestureDetector(
                onTap: widget.onGetStarted,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x35059669),
                        offset: Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
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

              // 2. Secondary Button: Log In
              GestureDetector(
                onTap: widget.onLogIn,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        offset: Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
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
