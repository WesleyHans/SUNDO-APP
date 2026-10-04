import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/clay_theme.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  final List<Map<String, String>> _schedules = const [
    {
      'barangay': 'Barangay 1 (Poblacion Central)',
      'days': 'Mon, Wed, Fri',
      'time': '7:00 AM - 10:30 AM',
      'type': 'Biodegradable & Household Waste',
      'truck': 'Truck 02 (Kuya Ronald)',
    },
    {
      'barangay': 'Barangay Gil Montilla',
      'days': 'Mon, Wed, Fri',
      'time': '7:00 AM - 10:30 AM',
      'type': 'Biodegradable & Household Waste',
      'truck': 'Truck #03 (SMC-4921)',
    },
    {
      'barangay': 'Barangay Poblacion (Market & Commercial)',
      'days': 'Daily (Mon - Sun)',
      'time': '5:00 AM - 8:00 AM & 5:00 PM',
      'type': 'Commercial & General Solid Waste',
      'truck': 'Truck #01 (SMC-3318)',
    },
    {
      'barangay': 'Barangay San Jose & Nauhang Coastal',
      'days': 'Tue, Thu, Sat',
      'time': '8:00 AM - 12:00 PM',
      'type': 'Recyclables & Dry Residuals',
      'truck': 'Truck #02 (SMC-2204)',
    },
    {
      'barangay': 'Barangay Cayhagan & Canturay',
      'days': 'Wed, Sat',
      'time': '1:00 PM - 5:00 PM',
      'type': 'Household Waste & Agriculture Residuals',
      'truck': 'Truck #04 (SMC-5091)',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Collection Schedules',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: _schedules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final s = _schedules[index];
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: ClayTheme.card(radius: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s['barangay']!,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: ClayTheme.badge(
                        bgColor: const Color(0xFFECFDF5),
                        borderColor: const Color(0xFFA7F3D0),
                      ),
                      child: Text(
                        s['days']!,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF065F46),
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Text(
                      s['time']!,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.recycling_rounded, size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s['type']!,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: ClayTheme.insetBox(radius: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping, size: 14, color: Color(0xFF059669)),
                      const SizedBox(width: 6),
                      Text(
                        'Assigned: ${s['truck']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
