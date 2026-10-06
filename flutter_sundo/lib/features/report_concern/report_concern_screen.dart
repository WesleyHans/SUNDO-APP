import '../../shared/widgets/resident_content.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../repositories/concern_repository.dart';
import '../../core/storage/app_store.dart';
import '../../services/backend_service.dart';
import '../../core/theme/clay_theme.dart';
import '../../core/theme/time_theme.dart';
import '../../shared/widgets/schedule_notification_widgets.dart';

class ReportGarbageScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final ConcernRepository? repository;
  const ReportGarbageScreen({super.key, this.onBack, this.repository});
  @override
  State<ReportGarbageScreen> createState() => _ReportGarbageScreenState();
}

class _ReportGarbageScreenState extends State<ReportGarbageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _picker = ImagePicker();
  final List<String> _photos = [];
  late final ConcernRepository _repository;
  String _tab = 'New Report';
  String _concernType = 'Missed Collection';
  String _locationSummary = 'Finding your current location…';
  String _savedAddress = '';
  String? _ticket;
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _saving = false;
  bool _loadingHistory = true;
  String? _historyError;
  List<GarbageReportItem> _reports = [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        (BackendService.live
            ? SupabaseConcernRepository()
            : MockConcernRepository());
    _loadAddress();
    _fetchLocation();
    _loadReports();
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadAddress() async {
    final address = await AppStore.getAddress();
    if (mounted) {
      setState(() => _savedAddress = address);
    }
  }

  Future<void> _loadReports() async {
    try {
      final reports = await _repository.load();
      if (mounted) {
        setState(() {
          _reports = reports;
          _loadingHistory = false;
          _historyError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingHistory = false;
          _historyError = 'Could not load your reports. Please retry.';
        });
      }
    }
  }

  Future<void> _fetchLocation() async {
    if (_locating || _saving) return;
    setState(() {
      _locating = true;
      _latitude = null;
      _longitude = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        throw StateError(
            'Location services are off. Enable GPS to use your current location.');
      }
      var permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(
            'Location permission is off. Enable it in app settings to use GPS.');
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12));
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationSummary =
              '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)} · accuracy ±${position.accuracy.round()} m';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _locationSummary = error is StateError
            ? error.message.toString()
            : 'GPS is unavailable. Retry or use your saved address in demo mode.');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_saving) return;
    if (_photos.length >= 3) {
      _message('You can add up to 3 photos.');
      return;
    }
    try {
      final photo = await _picker.pickImage(
          source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (photo != null && mounted) setState(() => _photos.add(photo.path));
    } catch (_) {
      if (mounted) {
        _message(
            'Could not open the camera or gallery. Check its permission and try again.');
      }
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_locating) {
      _message('Please wait while your location is checked.');
      return;
    }
    if (_repository.requiresGps && (_latitude == null || _longitude == null)) {
      _message('Get your actual GPS location before submitting to the city.');
      return;
    }
    if (_latitude == null && _savedAddress.isEmpty) {
      _message('Save an address in your profile or enable GPS.');
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final id = 'SUNDO-${now.year}-${now.microsecondsSinceEpoch}';
    final copied = <File>[];
    try {
      final documents = await getApplicationDocumentsDirectory();
      final directory = Directory('${documents.path}/reports/$id');
      if (_photos.isNotEmpty) await directory.create(recursive: true);
      for (var index = 0; index < _photos.length; index++) {
        final photo = File(_photos[index]);
        final extension = photo.path.split('.').last;
        copied.add(await photo.copy('${directory.path}/$index.$extension'));
      }
      await _repository.submit(GarbageReportItem(
          id: id,
          concernType: _concernType,
          description: _description.text.trim(),
          photoPaths: copied.map((file) => file.path).toList(),
          latitude: _latitude,
          longitude: _longitude,
          locationAddress: _latitude == null ? _savedAddress : _locationSummary,
          createdAt: now,
          status: 'Pending'));
      await _loadReports();
      if (mounted) setState(() => _ticket = id);
    } catch (_) {
      for (final file in copied) {
        try {
          await file.delete();
        } catch (_) {}
      }
      if (mounted) {
        _message(
            'Could not save your report. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mood = SundoTimeScope.of(context);
    return SundoResidentContent(
      topClearance: MediaQuery.viewInsetsOf(context).bottom > 0
          ? (widget.onBack == null ? 20 : 68)
          : 120,
      actions: [
        if (widget.onBack != null)
          IconButton(
              tooltip: 'Back',
              onPressed: _saving ? null : widget.onBack,
              icon: Icon(Icons.chevron_left_rounded, color: mood.textColor))
      ],
      filters: _ticket == null
          ? Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: SundoSegmentedTabs(
                  labels: const ['New Report', 'My Reports'],
                  selected: _tab,
                  onSelected: (tab) {
                    if (!_saving) setState(() => _tab = tab);
                  }))
          : null,
      body: _ticket != null
          ? _success()
          : _tab == 'My Reports'
              ? _history()
              : _form(),
    );
  }

  Widget _heading(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: SundoTimeScope.of(context).textColor)));

  Widget _form() {
    final mood = SundoTimeScope.of(context);
    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
        child: Form(
            key: _formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _heading('Concern Type'),
              for (final type in [
                'Missed Collection',
                'Uncollected Waste',
                'Route Concern',
                'Other Concern'
              ])
                SundoConcernRadioOption(
                    label: type,
                    selected: _concernType == type,
                    onTap: () {
                      if (!_saving) setState(() => _concernType = type);
                    }),
              const SizedBox(height: 15),
              _heading('Description'),
              Container(
                  decoration: ClayTheme.input(radius: 14),
                  child: TextFormField(
                      controller: _description,
                      enabled: !_saving,
                      minLines: 4,
                      maxLines: 6,
                      maxLength: 300,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5, color: const Color(0xFF203528)),
                      validator: (text) => text == null || text.trim().isEmpty
                          ? 'Please describe your concern.'
                          : null,
                      decoration: InputDecoration(
                          hintText: 'Please describe your concern…',
                          hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: const Color(0xFF87938B)),
                          counterStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 10, color: const Color(0xFF627368)),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14)))),
              const SizedBox(height: 18),
              _heading('Add Photos (optional)'),
              Row(children: [
                _photoButton(
                    'Camera',
                    Icons.camera_alt_rounded,
                    () => _pickPhoto(ImageSource.camera),
                    const Color(0xFF2F80ED)),
                const SizedBox(width: 12),
                _photoButton(
                    'Gallery',
                    Icons.photo_library_outlined,
                    () => _pickPhoto(ImageSource.gallery),
                    const Color(0xFF789086)),
                const SizedBox(width: 14),
                Expanded(
                    child: Text('Up to 3 photos',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: mood.mutedTextColor)))
              ]),
              if (_photos.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _photos
                            .asMap()
                            .entries
                            .map((entry) => Stack(
                                  children: [
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(File(entry.value),
                                            width: 82,
                                            height: 82,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox(
                                                    width: 82,
                                                    height: 82,
                                                    child: Icon(Icons
                                                        .broken_image_outlined)))),
                                    Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton.filled(
                                            tooltip:
                                                'Remove photo ${entry.key + 1}',
                                            style: IconButton.styleFrom(
                                                backgroundColor: Colors.black54,
                                                foregroundColor: Colors.white),
                                            onPressed: _saving
                                                ? null
                                                : () => setState(() => _photos
                                                    .removeAt(entry.key)),
                                            icon: const Icon(
                                                Icons.close_rounded,
                                                size: 16)))
                                  ],
                                ))
                            .toList())),
              const SizedBox(height: 22),
              _heading('Incident Location'),
              Container(
                  decoration: ClayTheme.card(radius: 14),
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Row(children: [
                    const Icon(Icons.location_on_outlined,
                        color: Color(0xFF0B8F3E)),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              _latitude != null
                                  ? 'Current GPS location'
                                  : 'Location permission / saved address',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF25382D))),
                          const SizedBox(height: 4),
                          Text(_locationSummary,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: const Color(0xFF627368),
                                  height: 1.5)),
                          if (!_repository.requiresGps &&
                              _latitude == null &&
                              _savedAddress.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text('Saved address: $_savedAddress',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: const Color(0xFF07652E),
                                    height: 1.4)),
                          ],
                        ])),
                    _locating
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)))
                        : IconButton(
                            tooltip: 'Retry GPS location',
                            onPressed: _saving ? null : _fetchLocation,
                            icon: const Icon(Icons.my_location_rounded,
                                color: Color(0xFF2F80ED), size: 22))
                  ])),
              const SizedBox(height: 24),
              Container(
                  decoration: ClayTheme.buttonPrimary(radius: 14),
                  child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: TextButton(
                          onPressed: _saving ? null : _submit,
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text('Submit Report',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800))))),
              if (_repository.isDemo)
                Padding(
                    padding: const EdgeInsets.only(top: 13),
                    child: Text(
                        'Demo mode: your report and photos will be saved on this phone.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: mood.mutedTextColor,
                            height: 1.5))),
            ])));
  }

  Widget _photoButton(
      String label, IconData icon, VoidCallback onTap, Color color) {
    return Container(
        width: 64,
        constraints: const BoxConstraints(minHeight: 64),
        decoration: ClayTheme.input(radius: 12),
        child: TextButton(
            onPressed: _saving ? null : onTap,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 4),
                  Text(label,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 9, color: const Color(0xFF627368)))
                ])));
  }

  Widget _success() {
    final mood = SundoTimeScope.of(context);
    return SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(children: [
          const SizedBox(height: 40),
          const Icon(Icons.check_circle_rounded,
              size: 74, color: Color(0xFF25B84A)),
          const SizedBox(height: 20),
          Text(
              _repository.isDemo
                  ? 'Report Saved on Device'
                  : 'Report Submitted',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 23,
                  color: mood.textColor,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SelectableText('Ticket: $_ticket',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: mood.accent)),
          const SizedBox(height: 14),
          Text(
              _repository.isDemo
                  ? 'Your report and photos are saved on this phone. They have not been submitted to the city.'
                  : 'Your concern has been sent to the city. View your reports to follow its status.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: mood.mutedTextColor, height: 1.6)),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => setState(() {
                    _ticket = null;
                    _tab = 'My Reports';
                    _description.clear();
                    _photos.clear();
                  }),
              child: const Text('View My Reports')),
          TextButton(
              onPressed: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  setState(() {
                    _ticket = null;
                    _tab = 'New Report';
                    _description.clear();
                    _photos.clear();
                  });
                }
              },
              child: const Text('Done')),
        ]));
  }

  Widget _history() {
    final mood = SundoTimeScope.of(context);
    return RefreshIndicator(
        onRefresh: _loadReports,
        child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            children: [
              if (_loadingHistory)
                const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()))
              else if (_historyError != null)
                Center(
                    child: Column(children: [
                  Text(_historyError!, style: TextStyle(color: mood.textColor)),
                  TextButton(
                      onPressed: _loadReports, child: const Text('Retry'))
                ]))
              else if (_reports.isEmpty)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(children: [
                      Icon(Icons.assignment_outlined,
                          size: 42, color: mood.accent),
                      const SizedBox(height: 12),
                      Text('No reports yet',
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: mood.textColor)),
                      const SizedBox(height: 8),
                      Text('Your submitted concerns will appear here.',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: mood.mutedTextColor))
                    ]))
              else
                for (final report in _reports)
                  Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: ClayTheme.card(radius: 16),
                      padding: const EdgeInsets.all(15),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(report.concernType,
                                      style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF203528)))),
                              SundoStatusChip(status: report.status)
                            ]),
                            const SizedBox(height: 10),
                            Text(report.description,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF485C50),
                                    height: 1.5)),
                            const SizedBox(height: 12),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 15, color: Color(0xFF708175)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                      child: Text(report.locationAddress,
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              color: const Color(0xFF708175))))
                                ]),
                            const SizedBox(height: 8),
                            Text(
                                DateFormat('MMM d, yyyy · h:mm a')
                                    .format(report.createdAt),
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: const Color(0xFF708175))),
                            const SizedBox(height: 4),
                            Text(report.id,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: const Color(0xFF708175))),
                          ])),
            ]));
  }
}
