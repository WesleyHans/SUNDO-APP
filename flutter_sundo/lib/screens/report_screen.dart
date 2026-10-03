import 'package:flutter/material.dart';

class ReportGarbageScreen extends StatefulWidget {
  const ReportGarbageScreen({super.key});

  @override
  State<ReportGarbageScreen> createState() => _ReportGarbageScreenState();
}

class _ReportGarbageScreenState extends State<ReportGarbageScreen> {
  String _selectedCategory = 'Uncollected Waste';
  String _selectedBarangay = 'Brgy. Gil Montilla';
  final TextEditingController _notesController = TextEditingController();
  bool _photoCaptured = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Uncollected Waste',
    'Overflowing Public Bin',
    'Illegal Dumping Site',
    'Hazardous / Medical Waste',
    'Bulky Furniture / Debris',
  ];

  final List<String> _barangays = [
    'Brgy. Gil Montilla',
    'Brgy. Poblacion',
    'Brgy. San Jose',
    'Brgy. Nauhang',
    'Brgy. Cayhagan',
    'Brgy. Canturay',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submitReport() {
    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isSubmitting = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Text('Report Submitted'),
              ],
            ),
            content: const Text(
              'Your report has been forwarded to Sipalay City CENRO dispatch. Reference Ticket: #REP-2026-891.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _photoCaptured = false;
                    _notesController.clear();
                  });
                },
                child: const Text('OK', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Waste Issue', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Photo Capture Box
            GestureDetector(
              onTap: () {
                setState(() => _photoCaptured = !_photoCaptured);
              },
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _photoCaptured ? const Color(0xFFECFDF5) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _photoCaptured ? const Color(0xFF059669) : Colors.grey.shade300,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _photoCaptured ? Icons.check_circle : Icons.camera_alt_outlined,
                        size: 48,
                        color: _photoCaptured ? const Color(0xFF059669) : Colors.grey.shade500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _photoCaptured
                            ? 'GPS Photo Attached (Sipalay Coordinates: 9.7548° N, 122.4038° E)'
                            : 'Tap to Take GPS-Tagged Photo',
                        style: TextStyle(
                          color: _photoCaptured ? const Color(0xFF059669) : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Category Selector
            const Text('Issue Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCategory,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Barangay
            const Text('Barangay Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedBarangay,
                  items: _barangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (val) => setState(() => _selectedBarangay = val!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Notes
            const Text('Additional Details / Landmark', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Near Purok Mangga Basketball court, behind the school...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit to Sipalay CENRO',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
