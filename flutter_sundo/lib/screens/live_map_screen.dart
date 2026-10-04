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
  StreamSubscription<Position>? _positionStream;

  // 3D Perspective Tilt state
  bool _is3DView = true;
  bool _isTruckCardExpanded = false;
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

  int _routeIndex = 2;
  Timer? _truckTimer;
  double _realDistanceKm = 1.2;

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
          _isRealGpsActive = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isRealGpsActive = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
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
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. FULL-BLEED EDGE-TO-EDGE MAP VIEWPORT (NO BLANK GREY SCREEN, ZERO CLIPPING)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userLocation,
                initialZoom: 15.6,
                initialRotation: _is3DView ? 28.0 : 0.0,
                maxZoom: 18.5,
                minZoom: 10.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sundo.sipalay',
                  maxZoom: 19,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _collectionRoute,
                      strokeWidth: 9.0,
                      color: const Color(0x5510B981),
                    ),
                    Polyline(
                      points: _collectionRoute,
                      strokeWidth: 5.0,
                      color: const Color(0xFF059669),
                    ),
                  ],
                ),
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
                MarkerLayer(
                  markers: [
                    // 1. User's Own Location 3D House Marker (Only this building shown on the map)
                    Marker(
                      point: _userLocation,
                      width: 92,
                      height: 96,
                      alignment: Alignment.bottomCenter,
                      child: IsometricHouseMarker(
                        label: 'My House',
                        size: 46,
                        radarAnimation: _radarController,
                        onTap: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.home_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'My House • Real GPS Location (±${_gpsAccuracyMeters > 0 ? _gpsAccuracyMeters.toStringAsFixed(1) : "5"}m)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),

                    // 2. Real-Time Moving Garbage Truck with 3D Elevation & Waves
                    Marker(
                      point: _truckCurrentPos,
                      width: 84,
                      height: 90,
                      alignment: Alignment.bottomCenter,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedBuilder(
                          animation: _radarController,
                          builder: (context, _) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Transform.scale(
                                      scale: 1.0 + (_radarController.value * 1.6),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF10B981).withValues(
                                            alpha: (1.0 - _radarController.value) * 0.45,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF34D399), Color(0xFF059669)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.5),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x55059669),
                                            offset: Offset(0, 6),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(3),
                                      child: const Center(
                                        child: SundoTruckGraphic(width: 30, height: 22),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 28,
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
                    ),
                  ],
                ),
              ],
            ),

            // 2. TOP FLOATING BAR: Clean "SIPALAY CITY" Pill (Matching Reference Screenshot)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _flyToSipalay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x15000000),
                                offset: Offset(0, 3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SIPALAY CITY',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: 0.8,
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
            ),

          // 3. TOP-RIGHT MAP CONTROLS (+, -, Compass matching screenshot)
          Positioned(
            right: 14,
            top: 110,
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
                  IconButton(
                    onPressed: _zoomIn,
                    icon: const Icon(Icons.add, color: Color(0xFF334155), size: 20),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  Container(width: 24, height: 1, color: const Color(0xFFE2E8F0)),
                  IconButton(
                    onPressed: _zoomOut,
                    icon: const Icon(Icons.remove, color: Color(0xFF334155), size: 20),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  Container(width: 24, height: 1, color: const Color(0xFFE2E8F0)),
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

          // 4. BOTTOM-LEFT SCALE BAR (matching ss-rose reference)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            left: 14,
            bottom: _isTruckCardExpanded ? 245 : 82,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x12000000), offset: Offset(0, 2), blurRadius: 6),
                ],
              ),
              child: Text(
                '300 m',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
          ),

          // 5. BOTTOM-RIGHT CONTROLS: Target Recenter & 2D/3D Toggle (Zero overlap)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            right: 14,
            bottom: _isTruckCardExpanded ? 245 : 82,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                          color: Color(0x18000000),
                          offset: Offset(0, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.filter_center_focus_rounded, color: Color(0xFF334155), size: 22),
                  ),
                ),
                const SizedBox(width: 8),
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
                          color: Color(0x18000000),
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

          // 6. BOTTOM NON-OVERLAPPING COLLAPSIBLE TRUCK CLAY CARD
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isTruckCardExpanded = !_isTruckCardExpanded;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: ClayTheme.card(radius: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Bar (always visible)
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: const Center(
                            child: SundoTruckGraphic(width: 30, height: 22),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Truck #02 (Kuya Ronald)',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: ClayTheme.badge(
                                      bgColor: const Color(0xFFECFDF5),
                                      borderColor: const Color(0xFFA7F3D0),
                                      radius: 8,
                                    ),
                                    child: Text(
                                      'Collecting',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF065F46),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${truck.etaMinutes}m ETA • ${_realDistanceKm < 1.0 ? "${(_realDistanceKm * 1000).round()}m" : "${_realDistanceKm.toStringAsFixed(1)}km"} away • ${truck.speedKmh} km/h',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Expand/Collapse Chevron Indicator
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isTruckCardExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: const Color(0xFF475569),
                            size: 18,
                          ),
                        ),
                      ],
                    ),

                    // Expandable Telemetry Details & Action Buttons
                    if (_isTruckCardExpanded) ...[
                      const SizedBox(height: 10),
                      // Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: ClayTheme.insetBox(radius: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${truck.speedKmh} km/h',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                                Text(
                                  'GPS Speed',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(height: 18, width: 1, color: const Color(0xFFE2E8F0)),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _realDistanceKm < 1.0
                                      ? '${(_realDistanceKm * 1000).round()} m'
                                      : '${_realDistanceKm.toStringAsFixed(2)} km',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                Text(
                                  'Real GPS Dist',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(height: 18, width: 1, color: const Color(0xFFE2E8F0)),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '~${truck.etaMinutes} mins',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                                Text(
                                  'Arrival ETA',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Capacity Progress Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Truck Capacity Loaded',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          Text(
                            '${truck.capacityPercent}% Full',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: truck.capacityPercent > 80 ? const Color(0xFFEF4444) : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: truck.capacityPercent / 100.0,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            truck.capacityPercent > 80 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Action Buttons
                      Row(
                        children: [
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
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: ClayTheme.amberBadge(radius: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.notifications_active_rounded, color: Color(0xFF78350F), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Test 3D Alert',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
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
                          Expanded(
                            child: GestureDetector(
                              onTap: _flyToTruck,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: ClayTheme.buttonPrimary(radius: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.navigation_rounded, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Follow Truck',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
