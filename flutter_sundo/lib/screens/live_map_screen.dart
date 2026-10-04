import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../theme/clay_theme.dart';
import '../widgets/sundo_graphics.dart';
import 'truck_alert_modal.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Real GPS state
  LatLng _userLocation = const LatLng(9.7525, 122.4038); // Defaults to Sipalay, updated instantly by hardware GPS
  bool _isRealGpsActive = false;
  bool _hasInitialCentered = false;
  double _gpsAccuracyMeters = 0.0;
  String _gpsStatusText = 'Locating Real GPS...';
  StreamSubscription<Position>? _positionStream;

  // 3D Perspective Tilt state
  bool _is3DView = true;
  late AnimationController _tiltController;
  late Animation<double> _tiltAnimation;

  // Radar wave pulsing animation
  late AnimationController _radarController;

  // Truck smooth movement animation
  late AnimationController _truckMoveController;
  late Animation<double> _truckMoveAnimation;
  LatLng _truckStartPoint = const LatLng(9.7610, 122.3980);
  LatLng _truckTargetPoint = const LatLng(9.7580, 122.4010);
  LatLng _truckCurrentPos = const LatLng(9.7610, 122.3980);

  // Initial Truck state (Truck #02 Kuya Ronald)
  TruckData truck = TruckData(
    id: 'TRK-02',
    plateNumber: 'SMC-4921',
    driverName: 'Kuya Ronald Alcantara',
    routeName: 'Route 1 - Poblacion to Coastal Blvd',
    position: const LatLng(9.7610, 122.3980),
    speedKmh: 24.0,
    etaMinutes: 10,
    capacityPercent: 65,
    isCollecting: true,
  );

  // Sipalay Collection Route Waypoints
  final List<LatLng> _collectionRoute = const [
    LatLng(9.7660, 122.3900),
    LatLng(9.7635, 122.3940),
    LatLng(9.7610, 122.3980),
    LatLng(9.7580, 122.4010),
    LatLng(9.7555, 122.4025),
    LatLng(9.7525, 122.4038),
    LatLng(9.7490, 122.4060),
    LatLng(9.7460, 122.4075),
    LatLng(9.7430, 122.4090),
  ];

  // Sipalay 3D Eco-Stations (matching the screenshot markers)
  final List<Map<String, dynamic>> _stations = const [
    {
      'id': '1',
      'name': 'Poblacion Beach Station',
      'location': LatLng(9.7540, 122.3995),
      'time': '8:30 AM',
      'status': 'Collected Today',
    },
    {
      'id': '2',
      'name': 'Coastal Estuary Point',
      'location': LatLng(9.7460, 122.3965),
      'time': '9:15 AM',
      'status': 'Collecting Next',
    },
    {
      'id': '3',
      'name': 'Central Public Market',
      'location': LatLng(9.7510, 122.4045),
      'time': '10:00 AM',
      'status': 'Scheduled',
    },
    {
      'id': '4',
      'name': 'Nauhang Eco-Drop Hub',
      'location': LatLng(9.7610, 122.3950),
      'time': '10:45 AM',
      'status': 'Scheduled',
    },
  ];

  int _routeIndex = 2;
  Timer? _truckTimer;
  double _realDistanceKm = 1.2;

  // Map Tile Style (FOSSGIS Clean OSM matching screenshot OSRM/FOSSGIS attribution)
  int _tileStyleIndex = 0;
  final List<Map<String, String>> _tileStyles = const [
    {
      'name': 'FOSSGIS Clean OSM (3D)',
      'url': 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
    },
    {
      'name': 'Humanitarian Eco OSM',
      'url': 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    },
    {
      'name': 'OpenStreetMap Standard',
      'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    },
  ];

  @override
  void initState() {
    super.initState();

    // 1. Setup 3D Camera Rotation Controller
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _tiltAnimation = CurvedAnimation(
      parent: _tiltController,
      curve: Curves.easeInOutCubic,
    );
    _tiltAnimation.addListener(() {
      if (mounted) {
        try {
          _mapController.rotate(_tiltAnimation.value * 28.0);
        } catch (_) {}
      }
    });
    if (_is3DView) {
      _tiltController.value = 1.0;
    }

    // 2. Setup Radar Wave Pulse Controller (repeating)
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // 3. Setup Truck Smooth Movement Interpolation Controller
    _truckMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _truckMoveAnimation = CurvedAnimation(
      parent: _truckMoveController,
      curve: Curves.easeInOutSine,
    )..addListener(() {
        if (mounted) {
          final t = _truckMoveAnimation.value;
          final lat = _truckStartPoint.latitude + (_truckTargetPoint.latitude - _truckStartPoint.latitude) * t;
          final lng = _truckStartPoint.longitude + (_truckTargetPoint.longitude - _truckStartPoint.longitude) * t;
          setState(() {
            _truckCurrentPos = LatLng(lat, lng);
            truck = truck.copyWith(position: _truckCurrentPos);
            _updateRealDistance();
          });
        }
      });

    // 4. Start periodic truck waypoint advancement with smooth interpolation
    _truckTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _advanceTruckSmoothly();
      }
    });

    // 5. Initialize REAL Device GPS via Geolocator with instant centering
    _initRealGPS();
  }

  void _advanceTruckSmoothly() {
    _routeIndex = (_routeIndex + 1) % _collectionRoute.length;
    _truckStartPoint = _truckCurrentPos;
    _truckTargetPoint = _collectionRoute[_routeIndex];

    _truckMoveController.reset();
    _truckMoveController.forward();

    // Update telemetry
    final newCapacity = (truck.capacityPercent + 2 > 98) ? 60 : truck.capacityPercent + 2;
    final newSpeed = 18.0 + (math.Random().nextDouble() * 12.0);

    setState(() {
      truck = truck.copyWith(
        capacityPercent: newCapacity,
        speedKmh: double.parse(newSpeed.toStringAsFixed(1)),
      );
    });
  }

  // REAL Device GPS Location Fetching with Auto-Centering
  Future<void> _initRealGPS() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsStatusText = 'GPS Disabled (Tap Here)';
          _isRealGpsActive = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsStatusText = 'GPS Permission Denied';
            _isRealGpsActive = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsStatusText = 'GPS Permission Denied (Settings)';
          _isRealGpsActive = false;
        });
        return;
      }

      // 1. Instant zero-delay centering using last known position
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        _updateUserGPS(lastPos, autoCenter: true);
      }

      // 2. Fetch live high-precision GPS coordinates from hardware
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 10),
      );

      _updateUserGPS(position, autoCenter: !_hasInitialCentered);

      // 3. Continuous real-time GPS stream (updates on 2-meter movement)
      _positionStream?.cancel();
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
        ),
      ).listen((Position livePos) {
        _updateUserGPS(livePos, autoCenter: false);
      });
    } catch (e) {
      setState(() {
        _gpsStatusText = 'Using Sipalay Satellite GPS';
        _isRealGpsActive = false;
      });
    }
  }

  void _updateUserGPS(Position pos, {bool autoCenter = false}) {
    if (!mounted) return;
    final newLoc = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _userLocation = newLoc;
      _gpsAccuracyMeters = pos.accuracy;
      _isRealGpsActive = true;
      _gpsStatusText = 'REAL GPS: ACTIVE (±${pos.accuracy.toStringAsFixed(1)}m)';
      _updateRealDistance();
    });

    if (!_hasInitialCentered || autoCenter) {
      _hasInitialCentered = true;
      _mapController.move(newLoc, 16.8);
    }
  }

  // Tap handler to turn on GPS hardware or request permission
  Future<void> _handleGpsBadgeTap() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening Location Settings... Please turn ON Location/GPS.'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await Geolocator.openLocationSettings();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _initRealGPS();
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required for live GPS.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    _initRealGPS();
  }

  void _updateRealDistance() {
    double meters = Geolocator.distanceBetween(
      _truckCurrentPos.latitude,
      _truckCurrentPos.longitude,
      _userLocation.latitude,
      _userLocation.longitude,
    );
    _realDistanceKm = meters / 1000.0;
    // Calculate dynamic ETA based on speed
    int mins = ((meters / (truck.speedKmh * 1000 / 60))).round().clamp(1, 45);
    truck = truck.copyWith(etaMinutes: mins);
  }

  void _toggle3DView() {
    setState(() {
      _is3DView = !_is3DView;
      if (_is3DView) {
        _tiltController.forward();
      } else {
        _tiltController.reverse();
      }
    });
  }

  void _cycleTileStyle() {
    setState(() {
      _tileStyleIndex = (_tileStyleIndex + 1) % _tileStyles.length;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Map Style: ${_tileStyles[_tileStyleIndex]['name']}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _flyToRealGPS() async {
    if (!_isRealGpsActive) {
      await _handleGpsBadgeTap();
    }
    _mapController.move(_userLocation, 17.0);
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Centered on your accurate GPS (±${_gpsAccuracyMeters > 0 ? _gpsAccuracyMeters.toStringAsFixed(1) : "5"}m)',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _flyToSipalay() {
    _mapController.move(const LatLng(9.7525, 122.4038), 15.5);
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Viewing Sipalay City CENRO Operations',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
  }

  void _resetNorth() {
    setState(() {
      _is3DView = false;
    });
    _tiltController.reverse();
    try {
      _mapController.rotate(0.0);
    } catch (_) {}
  }

  void _flyToTruck() {
    _mapController.move(_truckCurrentPos, 16.5);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _truckTimer?.cancel();
    _tiltController.dispose();
    _radarController.dispose();
    _truckMoveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      body: Stack(
        children: [
          // 1. FULL-BLEED EDGE-TO-EDGE 3D MAP VIEWPORT (NO V-SHAPE / ZERO TRAPEZOID DISTORTION)
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userLocation,
                initialZoom: 15.8,
                initialRotation: _is3DView ? 28.0 : 0.0,
                maxZoom: 18.5,
                minZoom: 10.0,
              ),
              children: [
                // High-resolution Map Tiles with clean pastel styling (matching screenshot)
                TileLayer(
                  urlTemplate: _tileStyles[_tileStyleIndex]['url']!,
                  userAgentPackageName: 'com.sundo.sipalay',
                  maxZoom: 19,
                ),

                // Collection Route Polyline with 3D glowing emerald shadow
                PolylineLayer(
                  polylines: [
                    // Glow background polyline
                    Polyline(
                      points: _collectionRoute,
                      strokeWidth: 9.0,
                      color: const Color(0x5510B981),
                    ),
                    // Core route polyline
                    Polyline(
                      points: _collectionRoute,
                      strokeWidth: 5.0,
                      color: const Color(0xFF059669),
                    ),
                  ],
                ),

                // Real GPS Accuracy Circle
                if (_isRealGpsActive && _gpsAccuracyMeters > 0)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _userLocation,
                        radius: _gpsAccuracyMeters.clamp(8, 60),
                        useRadiusInMeter: true,
                        color: const Color(0x223B82F6),
                        borderColor: const Color(0xFF3B82F6),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),

                // Interactive 3D Animated Markers (Stations, Truck, and User Location)
                MarkerLayer(
                  markers: [
                    // 3D Isometric Eco-Stations (Matching the screenshot buildings with badges #1, #2...)
                    ..._stations.map((st) {
                      return Marker(
                        point: st['location'] as LatLng,
                        width: 80,
                        height: 94,
                        alignment: Alignment.bottomCenter,
                        child: IsometricStationBuilding(
                          number: st['id'] as String,
                          title: st['name'] as String,
                          size: 52,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${st['name']} • Collection: ${st['time']} (${st['status']})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                duration: const Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      );
                    }),

                    // REAL User Location Marker (Pulsing 3D Pin)
                    Marker(
                      point: _userLocation,
                      width: 80,
                      height: 85,
                      alignment: Alignment.bottomCenter,
                      child: AnimatedBuilder(
                        animation: _radarController,
                        builder: (context, _) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // You are here badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white, width: 1),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x30000000), blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Text(
                                  'You (Real GPS)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Beacon Head with pulse
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.scale(
                                    scale: 1.0 + (_radarController.value * 1.5),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF2563EB).withValues(
                                          alpha: (1.0 - _radarController.value) * 0.45,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x551D4ED8),
                                          offset: Offset(0, 6),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_pin_circle_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              // Ground shadow
                              Container(
                                width: 22,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Real-Time Moving Garbage Truck 3D Marker
                    Marker(
                      point: _truckCurrentPos,
                      width: 85,
                      height: 90,
                      alignment: Alignment.bottomCenter,
                      child: AnimatedBuilder(
                        animation: _radarController,
                        builder: (context, _) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Mini Badge: ETA overlay
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF34D399), width: 1),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x30000000), blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Text(
                                  '${truck.etaMinutes}m ETA',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Elevated 3D Truck Base Card
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.scale(
                                    scale: 1.0 + (_radarController.value * 1.6),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF10B981).withValues(
                                          alpha: (1.0 - _radarController.value) * 0.45,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF34D399), Color(0xFF059669)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x55059669),
                                          offset: Offset(0, 8),
                                          blurRadius: 14,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Center(
                                      child: SundoTruckGraphic(width: 34, height: 26),
                                    ),
                                  ),
                                ],
                              ),
                              // Ground shadow
                              Container(
                                width: 32,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. TOP FLOATING BAR: Sipalay / My Location Switcher + Real GPS Status Badge
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Location Viewport Switcher Pills (Matching "SIPALAY CITY" in screenshot)
                      Row(
                        children: [
                          // "SIPALAY CITY" Pill Button
                          GestureDetector(
                            onTap: _flyToSipalay,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x18000000),
                                    offset: Offset(0, 3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(
                                'SIPALAY CITY',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // "MY LOCATION" Pill Button (Flies to real GPS)
                          GestureDetector(
                            onTap: _flyToRealGPS,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isRealGpsActive ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x20059669),
                                    offset: Offset(0, 3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.my_location_rounded,
                                    size: 13,
                                    color: _isRealGpsActive ? Colors.white : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'MY LOCATION',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      color: _isRealGpsActive ? Colors.white : const Color(0xFF64748B),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Tile Layers Switcher Button
                      GestureDetector(
                        onTap: _cycleTileStyle,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: ClayTheme.buttonSecondary(radius: 16),
                          child: const Icon(Icons.layers_outlined, color: Color(0xFF059669), size: 20),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Real GPS Status Chip (Tappable to enable GPS)
                  GestureDetector(
                    onTap: _handleGpsBadgeTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x10000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isRealGpsActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _gpsStatusText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _isRealGpsActive ? const Color(0xFF065F46) : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. TOP-RIGHT MAP CONTROLS (+, -, Compass matching screenshot)
          Positioned(
            right: 14,
            top: 130,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x20000000),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Zoom In
                  IconButton(
                    onPressed: _zoomIn,
                    icon: const Icon(Icons.add, color: Color(0xFF334155), size: 20),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  Container(width: 24, height: 1, color: const Color(0xFFE2E8F0)),
                  // Zoom Out
                  IconButton(
                    onPressed: _zoomOut,
                    icon: const Icon(Icons.remove, color: Color(0xFF334155), size: 20),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  Container(width: 24, height: 1, color: const Color(0xFFE2E8F0)),
                  // Compass / North
                  IconButton(
                    onPressed: _resetNorth,
                    icon: const Icon(Icons.explore_outlined, color: Color(0xFF059669), size: 18),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

          // 4. BOTTOM-RIGHT FLOATING CONTROLS (Target Recenter & "2D View" Button matching screenshot)
          Positioned(
            right: 14,
            bottom: 185,
            child: Row(
              children: [
                // Target / Focus on User GPS Button (matching screenshot target icon)
                GestureDetector(
                  onTap: _flyToRealGPS,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20000000),
                          offset: Offset(0, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.filter_center_focus_rounded, color: Color(0xFF334155), size: 22),
                  ),
                ),
                const SizedBox(width: 8),

                // "2D view" / "3D view" Toggle Button (matching screenshot button)
                GestureDetector(
                  onTap: _toggle3DView,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20000000),
                          offset: Offset(0, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      _is3DView ? '2D view' : '3D view',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. BOTTOM ELEVATED 3D TELEMETRY CLAY CARD
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: ClayTheme.card(radius: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Truck Header & Status Pill
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: const Center(
                          child: SundoTruckGraphic(width: 32, height: 24),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Truck #02 (Kuya Ronald)',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: ClayTheme.badge(
                                    bgColor: const Color(0xFFECFDF5),
                                    borderColor: const Color(0xFFA7F3D0),
                                    radius: 10,
                                  ),
                                  child: Text(
                                    'Collecting Now',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF065F46),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              truck.routeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Real GPS Distance & Dynamic ETA Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: ClayTheme.insetBox(radius: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Live Speed
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${truck.speedKmh} km/h',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF059669),
                              ),
                            ),
                            Text(
                              'GPS Speed',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),

                        // Real GPS Distance
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _realDistanceKm < 1.0
                                  ? '${(_realDistanceKm * 1000).round()} meters'
                                  : '${_realDistanceKm.toStringAsFixed(2)} km',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            Text(
                              'Real GPS Dist',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),

                        // Dynamic ETA
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '~${truck.etaMinutes} mins',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                            Text(
                              'Arrival ETA',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 7),

                  // Animated Waste Capacity Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Truck Capacity Loaded',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          Text(
                            '${truck.capacityPercent}% Full',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: truck.capacityPercent > 80 ? const Color(0xFFEF4444) : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: truck.capacityPercent / 100.0,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            truck.capacityPercent > 80 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Proximity Alert & Dispatch Actions
                  Row(
                    children: [
                      // Trigger Proximity Siren/Alert Modal
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            TruckAlertModal.show(
                              context,
                              etaMinutes: truck.etaMinutes,
                              onViewTruck: _flyToTruck,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9.5),
                            decoration: ClayTheme.amberBadge(radius: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.notifications_active_rounded, color: Color(0xFF78350F), size: 15),
                                const SizedBox(width: 5),
                                Text(
                                  'Test 3D Alert',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF78350F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Re-center on Truck
                      Expanded(
                        child: GestureDetector(
                          onTap: _flyToTruck,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9.5),
                            decoration: ClayTheme.buttonPrimary(radius: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.navigation_rounded, color: Colors.white, size: 15),
                                const SizedBox(width: 5),
                                Text(
                                  'Follow Truck',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
