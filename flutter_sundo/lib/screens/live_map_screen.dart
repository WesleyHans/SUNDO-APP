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
  LatLng _userLocation = const LatLng(9.7525, 122.4038); // Defaults to Sipalay, updated by real GPS
  bool _isRealGpsActive = false;
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

  int _routeIndex = 2;
  Timer? _truckTimer;
  double _realDistanceKm = 1.2;

  // Map Tile Style (Street, Voyager 3D, Satellite)
  int _tileStyleIndex = 0;
  final List<Map<String, String>> _tileStyles = const [
    {
      'name': '3D Carto Voyager',
      'url': 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
    },
    {
      'name': 'OpenStreetMap Standard',
      'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    },
    {
      'name': 'Satellite Imagery',
      'url': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    },
  ];

  @override
  void initState() {
    super.initState();

    // 1. Setup 3D Tilt Controller
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _tiltAnimation = CurvedAnimation(
      parent: _tiltController,
      curve: Curves.easeInOutCubic,
    );
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

    // 5. Initialize REAL Device GPS via Geolocator
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

  // REAL Device GPS Location Fetching
  Future<void> _initRealGPS() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsStatusText = 'GPS Hardware Disabled';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsStatusText = 'Location Permission Denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsStatusText = 'GPS Permission Denied Forever';
        });
        return;
      }

      // Fetch Real GPS coordinates from hardware
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      _updateUserGPS(position);

      // Listen to continuous real GPS location stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3, // updates on 3m movement
        ),
      ).listen((Position livePos) {
        _updateUserGPS(livePos);
      });
    } catch (e) {
      setState(() {
        _gpsStatusText = 'Using Sipalay Satellite GPS';
        _isRealGpsActive = false;
      });
    }
  }

  void _updateUserGPS(Position pos) {
    if (!mounted) return;
    setState(() {
      _userLocation = LatLng(pos.latitude, pos.longitude);
      _gpsAccuracyMeters = pos.accuracy;
      _isRealGpsActive = true;
      _gpsStatusText = 'REAL GPS: ACTIVE (±${pos.accuracy.toStringAsFixed(1)}m)';
      _updateRealDistance();
    });
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
  }

  void _flyToRealGPS() {
    _mapController.move(_userLocation, 16.5);
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
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // 1. 3D PERSPECTIVE MAP VIEWPORT
          AnimatedBuilder(
            animation: _tiltAnimation,
            builder: (context, child) {
              // 3D perspective projection matrix (rotates map plane backward ~38 degrees)
              final tiltAngle = _tiltAnimation.value * 0.68;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0016) // Perspective depth vanishing point
                  ..rotateX(tiltAngle),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userLocation,
                initialZoom: 15.2,
                maxZoom: 18.5,
                minZoom: 10.0,
              ),
              children: [
                // High-resolution Map Tiles with user-selectable style
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
                        radius: _gpsAccuracyMeters.clamp(10, 80),
                        useRadiusInMeter: true,
                        color: const Color(0x223B82F6),
                        borderColor: const Color(0xFF3B82F6),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),

                // Interactive 3D Animated Markers (Truck & Real User Location)
                MarkerLayer(
                  markers: [
                    // REAL User Location Marker (Pulse Animated)
                    Marker(
                      point: _userLocation,
                      width: 90,
                      height: 90,
                      child: AnimatedBuilder(
                        animation: _radarController,
                        builder: (context, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing radar expanding circle
                              Transform.scale(
                                scale: 1.0 + (_radarController.value * 1.6),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF2563EB).withValues(alpha: (1.0 - _radarController.value) * 0.45),
                                  ),
                                ),
                              ),
                              // 3D Pin Head
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x551D4ED8),
                                      offset: Offset(0, 8),
                                      blurRadius: 14,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 26),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Real-Time Moving Garbage Truck 3D Marker
                    Marker(
                      point: _truckCurrentPos,
                      width: 100,
                      height: 100,
                      child: AnimatedBuilder(
                        animation: _radarController,
                        builder: (context, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing Green Emerald Waves
                              Transform.scale(
                                scale: 1.0 + (_radarController.value * 1.8),
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: (1.0 - _radarController.value) * 0.5),
                                  ),
                                ),
                              ),

                              // Elevated 3D Truck Base Card
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF34D399), Color(0xFF059669)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3.5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x66059669),
                                      offset: Offset(0, 10),
                                      blurRadius: 18,
                                    ),
                                    BoxShadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(5),
                                child: const Center(
                                  child: SundoTruckGraphic(width: 40, height: 32),
                                ),
                              ),

                              // Mini Badge: ETA overlay
                              Positioned(
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF34D399), width: 1),
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

          // 2. TOP FLOATING CLAY BAR: Real GPS Indicator & Map Viewport Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Real GPS Live Badge (.clay-card)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: ClayTheme.card(radius: 20),
                        child: Row(
                          children: [
                            // Blinking live radar green dot
                            AnimatedBuilder(
                              animation: _radarController,
                              builder: (context, _) {
                                return Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _isRealGpsActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isRealGpsActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                                            .withValues(alpha: 0.8),
                                        blurRadius: 6 * _radarController.value,
                                        spreadRadius: 2 * _radarController.value,
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _gpsStatusText,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Sipalay City CENRO Operations',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 3D Perspective Tilt Button & Map Style Button
                      Row(
                        children: [
                          // 3D / 2D Toggle Button
                          GestureDetector(
                            onTap: _toggle3DView,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: _is3DView
                                  ? ClayTheme.buttonPrimary(radius: 18)
                                  : ClayTheme.buttonSecondary(radius: 18),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.view_in_ar_rounded,
                                    color: _is3DView ? Colors.white : const Color(0xFF334155),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _is3DView ? '3D' : '2D',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: _is3DView ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Layers Tile Style Button
                          GestureDetector(
                            onTap: _cycleTileStyle,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: ClayTheme.buttonSecondary(radius: 18),
                              child: const Icon(Icons.layers_outlined, color: Color(0xFF059669), size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. FLOATING ACTION QUICK BUTTONS (Right Side)
          Positioned(
            right: 16,
            bottom: 240,
            child: Column(
              children: [
                // "Track Truck" Button
                GestureDetector(
                  onTap: _flyToTruck,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: ClayTheme.buttonSecondary(radius: 18),
                    child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF059669), size: 22),
                  ),
                ),
                const SizedBox(height: 10),

                // "Real GPS: My Location" Button
                GestureDetector(
                  onTap: _flyToRealGPS,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: ClayTheme.buttonPrimary(radius: 18),
                    child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // 4. BOTTOM ELEVATED 3D TELEMETRY CLAY CARD (Interactive Slide-up)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: ClayTheme.card(radius: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Truck Header & Status Pill
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Center(
                          child: SundoTruckGraphic(width: 38, height: 30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Truck #02 (Kuya Ronald)',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.5,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: ClayTheme.badge(
                                    bgColor: const Color(0xFFECFDF5),
                                    borderColor: const Color(0xFFA7F3D0),
                                    radius: 10,
                                  ),
                                  child: Text(
                                    'Collecting Now',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
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
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Real GPS Distance & Dynamic ETA Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: ClayTheme.insetBox(radius: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Live Speed
                        Column(
                          children: [
                            Text(
                              '${truck.speedKmh} km/h',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF059669),
                              ),
                            ),
                            Text(
                              'GPS Speed',
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),

                        // Real GPS Distance
                        Column(
                          children: [
                            Text(
                              _realDistanceKm < 1.0
                                  ? '${(_realDistanceKm * 1000).round()} meters'
                                  : '${_realDistanceKm.toStringAsFixed(2)} km',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            Text(
                              'Real GPS Dist',
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),

                        // Dynamic ETA
                        Column(
                          children: [
                            Text(
                              '~${truck.etaMinutes} mins',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                            Text(
                              'Arrival ETA',
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Animated Waste Capacity Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Truck Capacity Loaded',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          Text(
                            '${truck.capacityPercent}% Full',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: truck.capacityPercent > 80 ? const Color(0xFFEF4444) : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: truck.capacityPercent / 100.0,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            truck.capacityPercent > 80 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: ClayTheme.amberBadge(radius: 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.notifications_active_rounded, color: Color(0xFF78350F), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Test 3D Alert',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF78350F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Re-center on Truck
                      Expanded(
                        child: GestureDetector(
                          onTap: _flyToTruck,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: ClayTheme.buttonPrimary(radius: 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Follow Truck',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
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
