import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  final List<Map<String, String>> _schedules = const [
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
      appBar: AppBar(
        title: const Text('Collection Schedules', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _schedules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final s = _schedules[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s['barangay']!,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        s['days']!,
                        style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(s['time']!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(s['type']!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Assigned: ${s['truck']}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
