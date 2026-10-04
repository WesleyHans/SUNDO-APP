import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../theme/clay_theme.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();

  // Sipalay City Center Coordinates
  final LatLng residentLocation = const LatLng(9.7525, 122.4038);

  // Initial Truck state (Truck #03 along Barangay Gil Montilla route)
  TruckData truck = TruckData(
    id: 'TRK-03',
    plateNumber: 'SMC-4921',
    driverName: 'Kuya Ronald Alcantara',
    routeName: 'Route A - Brgy. Gil Montilla Central',
    position: const LatLng(9.7610, 122.3980),
    speedKmh: 18.5,
    etaMinutes: 8,
    capacityPercent: 68,
    isCollecting: true,
  );

  // Waypoints for waste collection route in Sipalay City
  final List<LatLng> collectionRoute = const [
    LatLng(9.7645, 122.3920),
    LatLng(9.7620, 122.3955),
    LatLng(9.7610, 122.3980), // current truck location
    LatLng(9.7580, 122.4010),
    LatLng(9.7555, 122.4025),
    LatLng(9.7525, 122.4038), // resident location
    LatLng(9.7490, 122.4060),
    LatLng(9.7450, 122.4085), // CENRO Eco-Center
  ];

  Timer? _simulationTimer;
  int _routeIndex = 2;

  @override
  void initState() {
    super.initState();
    // Simulate real-time GPS telemetry movement every 3 seconds
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _routeIndex = (_routeIndex + 1) % (collectionRoute.length - 1);
          final nextPoint = collectionRoute[_routeIndex];
          final remainingMins = (8 - (_routeIndex * 1.5)).clamp(1, 15).toInt();
          truck = truck.copyWith(
            position: nextPoint,
            etaMinutes: remainingMins,
            capacityPercent: (truck.capacityPercent + 2).clamp(0, 100),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. OpenStreetMap Leaflet Engine
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: residentLocation,
              initialZoom: 15.0,
            ),
            children: [
              // High-resolution OpenStreetMap TileLayer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sundo.sipalay',
              ),

              // Collection Route Polyline
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: collectionRoute,
                    strokeWidth: 5.0,
                    color: const Color(0xFF059669),
                  ),
                ],
              ),

              // Interactive Markers: Truck & Resident Location
              MarkerLayer(
                markers: [
                  // Resident House Marker
                  Marker(
                    point: residentLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                      child: const Icon(Icons.home, color: Colors.white, size: 28),
                    ),
                  ),

                  // Real-time Moving Garbage Truck Marker
                  Marker(
                    point: truck.position,
                    width: 60,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66059669),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Header Bar: Status & Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: ClayTheme.badge(
                      bgColor: Colors.white,
                      borderColor: const Color(0xFFF1F5F9),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Sipalay CENRO GPS Live',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Re-center button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: ClayTheme.buttonSecondary(radius: 22),
                    child: IconButton(
                      icon: const Icon(Icons.my_location, color: Color(0xFF059669), size: 20),
                      onPressed: () {
                        _mapController.move(truck.position, 15.5);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom ETA & Vehicle Telemetry Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: ClayTheme.card(radius: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Color(0xFF059669),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Waste Truck ${truck.id} (${truck.plateNumber})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Driver: ${truck.driverName}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${truck.etaMinutes}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                height: 1,
                              ),
                            ),
                            const Text(
                              'MINS ETA',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _telemetryItem('Speed', '${truck.speedKmh.toStringAsFixed(1)} km/h'),
                      _telemetryItem('Load Capacity', '${truck.capacityPercent}% Full'),
                      _telemetryItem('Next Stop', 'Purok Mangga'),
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

  Widget _telemetryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
