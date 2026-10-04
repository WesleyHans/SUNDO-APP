import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/clay_theme.dart';

class ReportGarbageScreen extends StatefulWidget {
  const ReportGarbageScreen({super.key});

  @override
  State<ReportGarbageScreen> createState() => _ReportGarbageScreenState();
}

class _ReportGarbageScreenState extends State<ReportGarbageScreen> {
  String _selectedCategory = 'Uncollected Waste';
  String _selectedBarangay = 'Barangay 1';
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
    'Barangay 1',
    'Barangay 2',
    'Barangay 3',
    'Barangay 4',
    'Barangay 5',
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle, color: Color(0xFF059669), size: 24),
                ),
                const SizedBox(width: 10),
                Text(
                  'Report Submitted',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              'Your waste report has been forwarded to Sipalay City CENRO dispatch. Reference Ticket: #REP-2026-891.',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF475569), fontSize: 13, height: 1.4),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Report Waste Concern',
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Clay Photo Capture Box
            GestureDetector(
              onTap: () {
                setState(() => _photoCaptured = !_photoCaptured);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 190,
                width: double.infinity,
                decoration: _photoCaptured
                    ? ClayTheme.cardMint(radius: 24)
                    : ClayTheme.card(radius: 24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _photoCaptured ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _photoCaptured ? Icons.check_circle : Icons.camera_alt_rounded,
                          size: 30,
                          color: _photoCaptured ? const Color(0xFF059669) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _photoCaptured
                            ? 'GPS Photo Attached'
                            : 'Tap to Take GPS-Tagged Photo',
                        style: GoogleFonts.outfit(
                          color: _photoCaptured ? const Color(0xFF059669) : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _photoCaptured
                            ? 'Sipalay GPS: 9.7548° N, 122.4038° E'
                            : 'Camera auto-tags location coordinates',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // 2. Category Selector (.clay-card)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: ClayTheme.card(radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ISSUE CATEGORY',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: ClayTheme.insetBox(radius: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Barangay Location (.clay-card)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: ClayTheme.card(radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BARANGAY LOCATION',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: ClayTheme.insetBox(radius: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedBarangay,
                        items: _barangays
                            .map((b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(b, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedBarangay = val!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Notes (.clay-card)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: ClayTheme.card(radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LANDMARK & DETAILS',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: ClayTheme.insetBox(radius: 14),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Near Purok Mangga Basketball court, behind the school...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Large Clay Submit Button (.clay-button-primary)
            GestureDetector(
              onTap: _isSubmitting ? null : _submitReport,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: ClayTheme.buttonPrimary(radius: 28),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'SUBMIT TO SIPALAY CENRO',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
