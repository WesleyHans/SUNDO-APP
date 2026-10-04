import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/live_map_screen.dart';
import 'screens/report_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SundoApp());
}

class SundoApp extends StatelessWidget {
  const SundoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUNDO - Sipalay Smart Waste',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF059669),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF059669),
          primary: const Color(0xFF059669),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigate: _onTabSelected),
      const LiveMapScreen(),
      const ReportGarbageScreen(),
      const ScheduleScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildClayBottomNav(),
    );
  }

  // Authentic 3D Claymorphic Bottom Navigation Bar matching web simulator BottomNav.tsx
  Widget _buildClayBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2894A3B8), // 0 -8px 25px rgba(148, 163, 184, 0.22)
            offset: Offset(0, -6),
            blurRadius: 20,
          ),
          BoxShadow(
            color: Color(0x1094A3B8),
            offset: Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),

              // 2. Live Map
              _buildNavItem(1, Icons.map_rounded, Icons.map_outlined, 'Live Map'),

              // 3. Elevated 3D Clay Report Button (+)
              _buildElevatedReportButton(),

              // 4. Schedules
              _buildNavItem(3, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Schedules'),

              // 5. Profile
              _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFECFDF5) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.8), width: 1)
              : null,
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x18059669),
                    offset: Offset(2, 3),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(-1, -1),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              size: 22,
              color: isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? const Color(0xFF065F46) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Elevated 3D Tactile Clay Report (+) Button
  Widget _buildElevatedReportButton() {
    final bool isReportActive = _currentIndex == 2;
    return GestureDetector(
      onTap: () => _onTabSelected(2),
      behavior: HitTestBehavior.opaque,
      child: Transform.translate(
        offset: const Offset(0, -14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF34D399), Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55059669), // rgba(5, 150, 105, 0.38)
                    offset: Offset(0, 8),
                    blurRadius: 18,
                  ),
                  BoxShadow(
                    color: Color(0x60FFFFFF),
                    offset: Offset(-2, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Report',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isReportActive ? const Color(0xFF065F46) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
