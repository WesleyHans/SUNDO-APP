import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/backend_service.dart';
import '../report_concern/report_concern_screen.dart';
import '../../core/theme/clay_theme.dart';
import '../../shared/widgets/scenic_backdrop.dart';
import '../../shared/widgets/sundo_graphics.dart';
import '../../app/screen_transitions.dart';

class OperationsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const OperationsScreen({super.key, required this.onLogout});
  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _reports = [], _trucks = [], _schedules = [];
  String? _error;
  int _tab = 0;
  bool _loading = false, _sharing = false, _publishing = false;
  Position? _lastPosition;
  StreamSubscription<Position>? _gps;
  Timer? _timer;
  Timer? _heartbeat;
  DateTime? _lastRefresh;
  String get _role => _profile?['role'] as String? ?? 'resident';

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _heartbeat?.cancel();
    _gps?.cancel();
    if (_lastPosition != null && _sharing) {
      BackendService.client.rpc('publish_position', params: {
        'lat': _lastPosition!.latitude,
        'lng': _lastPosition!.longitude,
        'speed': 0,
        'is_active': false,
      }).then((_) {}, onError: (_) {});
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    _loading = true;
    try {
      final client = BackendService.client;
      final profile = await BackendService.loadProfile();
      final trucks = await client.from('trucks').select().order('id');
      final reports = await client
          .from('reports')
          .select()
          .order('created_at', ascending: false);
      final schedules = await client
          .from('schedules')
          .select()
          .gte('pickup_at', DateTime.now().toUtc().toIso8601String())
          .order('pickup_at');
      if (mounted) {
        setState(() {
          _profile = profile;
          _trucks = trucks;
          _reports = reports;
          _schedules = schedules;
          _error = null;
          _lastRefresh = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Could not refresh city data. Check your connection and retry.');
      }
    } finally {
      _loading = false;
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _shareLocation() async {
    if (_sharing) {
      _heartbeat?.cancel();
      await _gps?.cancel();
      if (mounted) setState(() => _sharing = false);
      if (_lastPosition != null) await _publish(_lastPosition!, active: false);
      return;
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Enable location services first.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(
            'Location permission is required. Enable it in app settings.');
      }
      final position = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 15));
      await _publish(position, throwOnError: true);
      if (!mounted) return;
      setState(() => _sharing = true);
      _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) async {
        if (!_sharing) return;
        try {
          final freshPosition = await Geolocator.getCurrentPosition(
              timeLimit: const Duration(seconds: 8));
          if (mounted && _sharing) await _publish(freshPosition);
        } catch (_) {
          _message(
              'Could not refresh GPS. Your truck will show offline until updates resume.');
        }
      });
      _gps = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      )).listen((position) => _publish(position),
          onError: (_) =>
              _message('GPS stream interrupted. Stop and restart sharing.'));
    } catch (e) {
      _message(e.toString());
    }
  }

  Future<void> _publish(Position position,
      {bool active = true, bool throwOnError = false}) async {
    if (_publishing) return;
    _publishing = true;
    try {
      await BackendService.client.rpc('publish_position', params: {
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed < 0 ? 0 : position.speed * 3.6,
        'is_active': active,
        'heading_value': position.heading >= 0 && position.heading <= 360
            ? position.heading
            : null,
      });
      _lastPosition = position;
      if (mounted) setState(() {});
    } catch (e) {
      if (throwOnError) rethrow;
      _message('GPS update failed. Check your connection.');
    } finally {
      _publishing = false;
    }
  }

  Future<void> _review(Map<String, dynamic> report, String status,
      {String? truckId}) async {
    try {
      if (_role == 'driver') {
        await BackendService.client
            .rpc('complete_report', params: {'report_id': report['id']});
      } else {
        await BackendService.client.from('reports').update({
          'status': status,
          if (truckId != null) 'truck_id': truckId,
        }).eq('id', report['id']);
      }
      await _refresh();
      _message('Report updated.');
    } catch (_) {
      _message('Could not update the report. Please retry.');
    }
  }

  Future<void> _scheduleReport(Map<String, dynamic> report) async {
    if (_trucks.isEmpty) {
      _message('Add and assign a truck in the backend first.');
      return;
    }
    final truckId = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
              title: const Text('Assign collection truck'),
              children: _trucks
                  .map((truck) => SimpleDialogOption(
                        onPressed: () =>
                            Navigator.pop(context, truck['id'] as String),
                        child: Text('${truck['id']} — ${truck['route_name']}'),
                      ))
                  .toList(),
            ));
    if (truckId != null) await _review(report, 'Scheduled', truckId: truckId);
  }

  Future<void> _viewPhoto(String path) async {
    try {
      final url = await BackendService.client.storage
          .from('report-photos')
          .createSignedUrl(path, 120);
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (context) => Dialog(
                child: Image.network(url,
                    errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Photo unavailable.'))),
              ));
    } catch (_) {
      _message('Could not open this photo.');
    }
  }

  Future<void> _addSchedule() async {
    final barangay = TextEditingController();
    final waste = TextEditingController();
    final note = TextEditingController();
    try {
      final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Create collection schedule'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: barangay,
                      decoration: const InputDecoration(labelText: 'Barangay')),
                  TextField(
                      controller: waste,
                      decoration:
                          const InputDecoration(labelText: 'Waste type')),
                  TextField(
                      controller: note,
                      decoration: const InputDecoration(
                          labelText: 'Instructions (optional)')),
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        if (barangay.text.trim().isNotEmpty &&
                            waste.text.trim().isNotEmpty) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: const Text('Choose date'))
                ],
              ));
      if (accepted != true || !mounted) return;
      final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)));
      if (date == null || !mounted) return;
      final time = await showTimePicker(
          context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
      if (time == null) return;
      final pickup =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (!pickup.isAfter(DateTime.now())) {
        _message('Choose a future collection time.');
        return;
      }
      await BackendService.client.from('schedules').insert({
        'barangay': barangay.text.trim(),
        'waste_type': waste.text.trim(),
        'note': note.text.trim(),
        'pickup_at': pickup.toUtc().toIso8601String(),
      });
      await _refresh();
    } catch (_) {
      _message('Could not create the schedule.');
    } finally {
      barangay.dispose();
      waste.dispose();
      note.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Home', 'Live Map', 'Reports', 'Schedules', 'Profile'];
    return Scaffold(
      appBar: AppBar(
          flexibleSpace: const SundoHeaderLeaves(),
          title: Text('SUNDO · ${_profile?['name'] ?? 'Loading'}'),
          actions: [
            IconButton(
                tooltip: 'Refresh',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh)),
            IconButton(
                tooltip: 'Log out',
                onPressed: () async {
                  if (_sharing) await _shareLocation();
                  try {
                    await BackendService.logout();
                    if (mounted) widget.onLogout();
                  } catch (_) {
                    _message('Could not log out. Please retry.');
                  }
                },
                icon: const Icon(Icons.logout)),
          ]),
      body: Column(children: [
        if (_error != null)
          MaterialBanner(content: Text(_error!), actions: [
            TextButton(onPressed: _refresh, child: const Text('Retry'))
          ]),
        if (_profile == null && _error == null) const LinearProgressIndicator(),
        Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '${_role.toUpperCase()} · ${_lastRefresh == null ? "Connecting" : "Updated ${TimeOfDay.fromDateTime(_lastRefresh!).format(context)}"}',
            )),
        if (_role == 'driver')
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                FilledButton.icon(
                    onPressed: _shareLocation,
                    icon: Icon(_sharing ? Icons.stop : Icons.gps_fixed),
                    label: Text(_sharing
                        ? 'Stop sharing truck location'
                        : 'Start sharing truck location')),
                const Text(
                    'Keep this screen open during collection. Locations older than 2 minutes are marked offline.',
                    textAlign: TextAlign.center),
              ])),
        Expanded(
            child: _tab == 0
                ? _buildDashboard()
                : _tab == 1
                    ? _buildMap()
                    : _tab == 2
                        ? _buildReports()
                        : _tab == 3
                            ? _buildSchedules()
                            : _buildProfile()),
      ]),
      floatingActionButton: (_tab == 0 || _tab == 2) && _role == 'resident'
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                    context,
                    sundoScreenRoute<void>(
                        context,
                        (_) => ReportGarbageScreen(
                            onBack: () => Navigator.pop(context))));
                await _refresh();
              },
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Report waste'),
            )
          : _tab == 3 && _role == 'staff'
              ? FloatingActionButton(
                  onPressed: _addSchedule, child: const Icon(Icons.add))
              : null,
      bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.home_outlined), label: titles[0]),
            NavigationDestination(
                icon: const Icon(Icons.map_outlined), label: titles[1]),
            NavigationDestination(
                icon: const Icon(Icons.assignment_outlined), label: titles[2]),
            NavigationDestination(
                icon: const Icon(Icons.calendar_month), label: titles[3]),
            NavigationDestination(
                icon: const Icon(Icons.person_outline), label: titles[4]),
          ]),
    );
  }

  Widget _buildDashboard() {
    final pending =
        _reports.where((report) => report['status'] != 'Collected').length;
    final completed =
        _reports.where((report) => report['status'] == 'Collected').length;
    final activeTrucks = _trucks.where(_fresh).length;
    return ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        children: [
          Container(
              height: 160,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  image: const DecorationImage(
                      image: AssetImage(clayHeroAsset),
                      fit: BoxFit.cover,
                      alignment: Alignment(0, 0.15))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good day,',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: const Color(0xFF174F32))),
                    Text(
                        '${(_profile?['name'] as String? ?? 'Resident').split(' ').first}!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF174F32))),
                    const Spacer(),
                    const Text('Together for a cleaner Sipalay',
                        style: TextStyle(
                            color: Color(0xFF174F32),
                            fontWeight: FontWeight.w700)),
                  ])),
          const SizedBox(height: 20),
          Container(
              padding: const EdgeInsets.all(20),
              decoration: ClayTheme.card(),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Collection overview',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 14),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat('$pending', 'Open reports',
                              const Icon(Icons.assignment_outlined)),
                          _stat('$completed', 'Collected',
                              const Icon(Icons.check_circle_outline)),
                          _stat('$activeTrucks', 'Live trucks',
                              const SundoTruckGraphic(width: 24, height: 24)),
                        ]),
                  ])),
          const SizedBox(height: 18),
          Container(
              padding: const EdgeInsets.all(20),
              decoration: ClayTheme.cardMint(),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your next collection',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(_nextPickupText()),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                        onPressed: () => setState(() => _tab = 3),
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('View collection schedules')),
                  ])),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
                child: _quickAction('Live truck map', Icons.map_outlined, 1)),
            const SizedBox(width: 12),
            Expanded(
                child: _quickAction(
                    _role == 'resident' ? 'My reports' : 'Collection reports',
                    Icons.assignment_outlined,
                    2)),
          ]),
        ]);
  }

  Widget _stat(String number, String label, Widget icon) => Column(children: [
        IconTheme(
            data: const IconThemeData(color: Color(0xFF07853D)), child: icon),
        const SizedBox(height: 6),
        Text(number,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF174F32))),
        Text(label, style: const TextStyle(fontSize: 10)),
      ]);

  Widget _quickAction(String label, IconData icon, int index) => InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setState(() => _tab = index),
        child: Container(
            padding: const EdgeInsets.all(18),
            decoration: ClayTheme.card(),
            child: Column(children: [
              Icon(icon, color: const Color(0xFF07853D), size: 30),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700))
            ])),
      );

  String _nextPickupText() {
    final barangay = (_profile?['barangay'] as String? ?? '')
        .split(',')
        .first
        .trim()
        .toLowerCase();
    final matches = _schedules
        .where((schedule) =>
            _role != 'resident' ||
            (schedule['barangay'] as String)
                    .split(',')
                    .first
                    .trim()
                    .toLowerCase() ==
                barangay)
        .toList();
    if (matches.isEmpty) {
      return 'No upcoming collection has been published for your area.';
    }
    final schedule = matches.first;
    final pickup = DateTime.parse(schedule['pickup_at'] as String).toLocal();
    return '${schedule['waste_type']} · ${schedule['barangay']}\n${pickup.month}/${pickup.day}/${pickup.year} · ${TimeOfDay.fromDateTime(pickup).format(context)}';
  }

  Widget _buildProfile() =>
      ListView(padding: const EdgeInsets.all(20), children: [
        Container(
            padding: const EdgeInsets.all(24),
            decoration: ClayTheme.card(),
            child: Column(children: [
              const CircleAvatar(
                  radius: 35,
                  backgroundColor: Color(0xFFDBEFCB),
                  child:
                      Icon(Icons.person, color: Color(0xFF185632), size: 40)),
              const SizedBox(height: 14),
              Text(_profile?['name'] as String? ?? '',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(BackendService.client.auth.currentUser?.email ?? ''),
              const SizedBox(height: 8),
              Text(_role.toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFF07853D), fontWeight: FontWeight.w800)),
            ])),
        const SizedBox(height: 18),
        Container(
            decoration: ClayTheme.card(),
            child: Column(children: [
              ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: const Text('Barangay'),
                  subtitle: Text(_profile?['barangay'] as String? ?? '')),
              ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Phone'),
                  subtitle: Text(_profile?['phone'] as String? ?? '')),
              ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editProfile),
            ])),
        const SizedBox(height: 20),
        const Text(
            'SUNDO · Smart Urban Navigation for Dynamic Waste Operations\nSipalay City',
            textAlign: TextAlign.center),
      ]);

  Future<void> _editProfile() async {
    if (_profile == null) return;
    final name = TextEditingController(text: _profile!['name'] as String);
    final phone = TextEditingController(text: _profile!['phone'] as String);
    final barangay =
        TextEditingController(text: _profile!['barangay'] as String);
    try {
      final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Edit profile'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name')),
                  TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone')),
                  TextField(
                      controller: barangay,
                      decoration: const InputDecoration(labelText: 'Barangay')),
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        if (name.text.trim().isNotEmpty &&
                            barangay.text.trim().isNotEmpty) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: const Text('Save'))
                ],
              ));
      if (accepted != true) return;
      await BackendService.client.from('profiles').update({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'barangay': barangay.text.trim(),
      }).eq('id', BackendService.client.auth.currentUser!.id);
      await _refresh();
      _message('Profile updated.');
    } catch (_) {
      _message('Could not update your profile. Please retry.');
    } finally {
      name.dispose();
      phone.dispose();
      barangay.dispose();
    }
  }

  Widget _buildReports() {
    if (_reports.isEmpty) return const Center(child: Text('No reports yet.'));
    return ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
        children: _reports
            .map((report) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: ClayTheme.card(),
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${report['concern_type']} · ${report['status']}',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(report['description'] as String),
                            Text(report['location_address'] as String),
                            Text(
                                '${report['latitude']}, ${report['longitude']}'),
                            Text('Ticket: ${report['id']}'),
                            if (report['truck_id'] != null)
                              Text('Assigned truck: ${report['truck_id']}'),
                            Wrap(
                                children: List<String>.from(
                                        report['photo_paths'] as List)
                                    .asMap()
                                    .entries
                                    .map((entry) => TextButton.icon(
                                          onPressed: () =>
                                              _viewPhoto(entry.value),
                                          icon: const Icon(Icons.photo),
                                          label: Text('Photo ${entry.key + 1}'),
                                        ))
                                    .toList()),
                            if (_role == 'staff')
                              Wrap(spacing: 8, children: [
                                if (report['status'] == 'Pending')
                                  FilledButton(
                                      onPressed: () =>
                                          _review(report, 'Verified'),
                                      child: const Text('Verify')),
                                if (report['status'] == 'Verified' ||
                                    report['status'] == 'Scheduled')
                                  OutlinedButton(
                                      onPressed: () => _scheduleReport(report),
                                      child: const Text('Assign truck')),
                                if (report['status'] == 'Scheduled')
                                  FilledButton(
                                      onPressed: () =>
                                          _review(report, 'Collected'),
                                      child: const Text('Mark collected')),
                              ]),
                            if (_role == 'driver' &&
                                report['status'] == 'Scheduled')
                              FilledButton(
                                  onPressed: () => _review(report, 'Collected'),
                                  child: const Text('Mark collected')),
                          ])),
                ))
            .toList());
  }

  bool _fresh(Map<String, dynamic> truck) {
    final updated = DateTime.tryParse(truck['updated_at'] as String? ?? '');
    return truck['active'] == true &&
        updated != null &&
        DateTime.now().difference(updated).inSeconds < 120;
  }

  Widget _buildMap() {
    final located = _trucks
        .where(
            (truck) => truck['latitude'] != null && truck['longitude'] != null)
        .toList();
    return Column(children: [
      Expanded(
          child: FlutterMap(
              options: const MapOptions(
                  initialCenter: LatLng(9.7525, 122.4038), initialZoom: 13),
              children: [
            TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sundo.sipalay'),
            MarkerLayer(
                markers: located
                    .map((truck) => Marker(
                          point: LatLng((truck['latitude'] as num).toDouble(),
                              (truck['longitude'] as num).toDouble()),
                          width: 90,
                          height: 55,
                          child: Column(children: [
                            Opacity(
                                opacity: _fresh(truck) ? 1 : .55,
                                child: const SundoVehicleGraphic(
                                    mapView: true, width: 30, height: 30)),
                            Text(truck['id'] as String,
                                style: const TextStyle(
                                    backgroundColor: Colors.white)),
                          ]),
                        ))
                    .toList()),
            const RichAttributionWidget(attributions: [
              TextSourceAttribution('OpenStreetMap contributors')
            ]),
          ])),
      SizedBox(
          height: 110,
          child: _trucks.isEmpty
              ? const Center(child: Text('No trucks configured yet.'))
              : ListView(
                  children: _trucks
                      .map((truck) => ListTile(
                            leading: Opacity(
                                opacity: _fresh(truck) ? 1 : .55,
                                child: const SundoTruckGraphic(
                                    width: 24, height: 24)),
                            title:
                                Text('${truck['id']} · ${truck['route_name']}'),
                            subtitle: Text(_fresh(truck)
                                ? 'Live · ${(truck['speed_kmh'] as num).toStringAsFixed(1)} km/h'
                                : 'Offline · last known position'),
                          ))
                      .toList())),
    ]);
  }

  Widget _buildSchedules() {
    if (_schedules.isEmpty) {
      return const Center(child: Text('No upcoming collection schedules.'));
    }
    return ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: _schedules.map((schedule) {
          final pickup =
              DateTime.parse(schedule['pickup_at'] as String).toLocal();
          return ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text('${schedule['barangay']} · ${schedule['waste_type']}'),
            subtitle: Text(
                '${pickup.month}/${pickup.day}/${pickup.year} ${TimeOfDay.fromDateTime(pickup).format(context)}\n${schedule['note']}'),
            isThreeLine: true,
          );
        }).toList());
  }
}
