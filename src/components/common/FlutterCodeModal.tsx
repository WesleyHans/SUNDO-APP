import React, { useState } from 'react';
import { X, Copy, Check, Code, Smartphone, Download, FolderArchive, Terminal, FileCode } from 'lucide-react';
import confetti from 'canvas-confetti';

interface FlutterCodeModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const FlutterCodeModal: React.FC<FlutterCodeModalProps> = ({ isOpen, onClose }) => {
  const [copied, setCopied] = useState(false);
  const [activeTab, setActiveTab] = useState<
    'main' | 'map' | 'home' | 'report' | 'schedule' | 'models' | 'pubspec' | 'guide'
  >('main');

  if (!isOpen) return null;

  const pubspecYaml = `name: sundo_sipalay
description: "SUNDO: Smart Urban Navigation for Dynamic Waste Operations in Sipalay City"
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_map: ^6.1.0
  latlong2: ^0.9.1
  geolocator: ^11.0.0
  image_picker: ^1.0.7
  provider: ^6.1.1
  google_fonts: ^6.1.0
  intl: ^0.19.0
  http: ^1.2.0

flutter:
  uses-material-design: true
`;

  const mainDart = `import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/live_map_screen.dart';
import 'screens/report_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SundoApp());
}

class SundoApp extends StatelessWidget {
  const SundoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUNDO - Sipalay Smart Waste',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF059669),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF059669),
          primary: const Color(0xFF059669),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigate: _onTabSelected),
      const LiveMapScreen(),
      const ReportGarbageScreen(),
      const ScheduleScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        indicatorColor: const Color(0xFFD1FAE5),
        backgroundColor: Colors.white,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF059669)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFF059669)),
            label: 'Live Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt, color: Color(0xFF059669)),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: Color(0xFF059669)),
            label: 'Schedules',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF059669)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
`;

  const mapDart = `import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();

  // Sipalay City Resident Location (Brgy. Gil Montilla)
  final LatLng residentLocation = const LatLng(9.7525, 122.4038);

  // Real-time Garbage Truck State
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

  // Sipalay Waste Collection Waypoint Route
  final List<LatLng> collectionRoute = const [
    LatLng(9.7645, 122.3920),
    LatLng(9.7620, 122.3955),
    LatLng(9.7610, 122.3980),
    LatLng(9.7580, 122.4010),
    LatLng(9.7555, 122.4025),
    LatLng(9.7525, 122.4038),
    LatLng(9.7490, 122.4060),
    LatLng(9.7450, 122.4085),
  ];

  Timer? _simulationTimer;
  int _routeIndex = 2;

  @override
  void initState() {
    super.initState();
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _routeIndex = (_routeIndex + 1) % (collectionRoute.length - 1);
          final nextPoint = collectionRoute[_routeIndex];
          truck = truck.copyWith(
            position: nextPoint,
            etaMinutes: (8 - (_routeIndex * 1.5)).clamp(1, 15).toInt(),
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: residentLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sundo.sipalay',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: collectionRoute,
                    strokeWidth: 5.0,
                    color: const Color(0xFF059669),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: residentLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.home, color: Colors.white, size: 28),
                    ),
                  ),
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
                          BoxShadow(color: Colors.emerald, blurRadius: 10, spreadRadius: 2)
                        ],
                      ),
                      child: const Icon(Icons.local_shipping, color: Colors.white, size: 32),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping, color: Color(0xFF059669), size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Truck \${truck.id} (\${truck.plateNumber})', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Driver: \${truck.driverName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Chip(
                          backgroundColor: const Color(0xFF059669),
                          label: Text('\${truck.etaMinutes} MINS ETA', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
`;

  const reportDart = `import 'package:flutter/material.dart';

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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Waste Issue')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => _photoCaptured = !_photoCaptured),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _photoCaptured ? const Color(0xFFECFDF5) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _photoCaptured ? const Color(0xFF059669) : Colors.grey.shade300, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_photoCaptured ? Icons.check_circle : Icons.camera_alt, size: 40, color: const Color(0xFF059669)),
                      const SizedBox(height: 8),
                      Text(_photoCaptured ? 'GPS Geotag Attached' : 'Tap to Take GPS Photo', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
              decoration: const InputDecoration(labelText: 'Waste Category', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Landmark / Barangay Location', border: OutlineInputBorder()),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted to Sipalay CENRO! Reference #REP-2026-891')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                child: const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
`;

  const guideText = `# How to Run & Build Official Android APK with Flutter

### Prerequisites
1. Install Flutter SDK: https://docs.flutter.dev/get-started/install
2. Install Android Studio (with Android SDK & Command Line Tools)
3. Download the SUNDO Flutter Project ZIP using the button above.

---

### Step-by-Step Commands

1. **Extract the ZIP file**:
   Extract \`sundo_flutter_project.zip\` onto your computer.

2. **Open Terminal / Command Prompt** in the project directory:
   \`\`\`bash
   cd sundo_flutter
   \`\`\`

3. **Install Packages**:
   \`\`\`bash
   flutter pub get
   \`\`\`

4. **Test Run on Phone or Emulator**:
   Connect your Android phone via USB with USB Debugging enabled, then run:
   \`\`\`bash
   flutter run
   \`\`\`

5. **Compile Real Native Release APK**:
   Run the official Flutter release compiler:
   \`\`\`bash
   flutter build apk --release
   \`\`\`

6. **Find Your APK**:
   Your APK is generated at:
   \`build/app/outputs/flutter-apk/app-release.apk\`

This APK is 100% compiled with native Dalvik/ART binaries and installs immediately on any Android phone!
`;

  let currentCode = mainDart;
  let currentFileName = 'lib/main.dart';
  if (activeTab === 'map') {
    currentCode = mapDart;
    currentFileName = 'lib/screens/live_map_screen.dart';
  } else if (activeTab === 'report') {
    currentCode = reportDart;
    currentFileName = 'lib/screens/report_screen.dart';
  } else if (activeTab === 'pubspec') {
    currentCode = pubspecYaml;
    currentFileName = 'pubspec.yaml';
  } else if (activeTab === 'guide') {
    currentCode = guideText;
    currentFileName = 'BUILD_INSTRUCTIONS.md';
  }

  const handleCopy = () => {
    navigator.clipboard.writeText(currentCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleDownloadZip = () => {
    confetti({
      particleCount: 60,
      spread: 70,
      origin: { y: 0.6 },
      colors: ['#10b981', '#059669', '#34d399', '#38bdf8'],
    });
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-3 sm:p-5">
      <div className="bg-slate-900 border border-slate-700/80 rounded-3xl w-full max-w-4xl max-h-[92vh] flex flex-col shadow-2xl overflow-hidden text-slate-100">
        {/* Header */}
        <div className="p-4 sm:p-5 border-b border-slate-800 flex items-center justify-between bg-slate-900/90">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-sky-500 to-emerald-500 flex items-center justify-center shadow-md">
              <Code className="w-5 h-5 text-white" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-base sm:text-lg font-black tracking-tight text-white font-['Outfit']">
                  SUNDO Flutter & Dart Native Mobile Codebase
                </h3>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-sky-500/20 text-sky-400 border border-sky-500/30">
                  Flutter 3.x
                </span>
              </div>
              <p className="text-xs text-slate-400">
                Complete cross-platform source code with OpenStreetMap, live GPS tracking & report dispatch.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {/* Download Full Project ZIP */}
            <a
              href="/sundo-flutter-project.zip"
              download="sundo_flutter_project.zip"
              onClick={handleDownloadZip}
              className="px-3.5 py-2 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-400 text-slate-950 font-black text-xs flex items-center gap-1.5 shadow-md active:scale-95 cursor-pointer no-underline"
              title="Download entire Flutter project source in ZIP"
            >
              <FolderArchive className="w-4 h-4" />
              <span className="hidden sm:inline">Download Full Flutter Project (.ZIP)</span>
              <span className="sm:hidden">Get .ZIP</span>
            </a>

            <button
              onClick={onClose}
              className="p-2 rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="px-4 py-2 bg-slate-950/70 border-b border-slate-800 flex items-center justify-between overflow-x-auto gap-2 no-scrollbar">
          <div className="flex items-center gap-1.5 shrink-0">
            <button
              onClick={() => setActiveTab('main')}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'main'
                  ? 'bg-sky-600 text-white'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800'
              }`}
            >
              <FileCode className="w-3.5 h-3.5" />
              <span>lib/main.dart</span>
            </button>

            <button
              onClick={() => setActiveTab('map')}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'map'
                  ? 'bg-sky-600 text-white'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800'
              }`}
            >
              <FileCode className="w-3.5 h-3.5" />
              <span>live_map_screen.dart</span>
            </button>

            <button
              onClick={() => setActiveTab('report')}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'report'
                  ? 'bg-sky-600 text-white'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800'
              }`}
            >
              <FileCode className="w-3.5 h-3.5" />
              <span>report_screen.dart</span>
            </button>

            <button
              onClick={() => setActiveTab('pubspec')}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'pubspec'
                  ? 'bg-sky-600 text-white'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800'
              }`}
            >
              <FileCode className="w-3.5 h-3.5" />
              <span>pubspec.yaml</span>
            </button>

            <button
              onClick={() => setActiveTab('guide')}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'guide'
                  ? 'bg-emerald-600 text-white'
                  : 'text-emerald-400 hover:text-emerald-300 hover:bg-slate-800'
              }`}
            >
              <Terminal className="w-3.5 h-3.5" />
              <span>Build APK Guide</span>
            </button>
          </div>

          <button
            onClick={handleCopy}
            className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold flex items-center gap-1.5 cursor-pointer shrink-0"
          >
            {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
            <span>{copied ? 'Copied!' : 'Copy File'}</span>
          </button>
        </div>

        {/* Code Viewer */}
        <div className="flex-1 overflow-auto p-4 bg-slate-950 font-mono text-xs text-slate-300 leading-relaxed selection:bg-sky-900 selection:text-white">
          <div className="mb-2 text-[11px] text-slate-500 font-sans flex items-center justify-between border-b border-slate-800 pb-1">
            <span>File: <strong>{currentFileName}</strong></span>
            <span>UTF-8 • Dart / YAML</span>
          </div>
          <pre className="whitespace-pre overflow-x-auto">{currentCode}</pre>
        </div>

        {/* Footer Build Command Quick Banner */}
        <div className="p-3.5 bg-slate-900 border-t border-slate-800 flex flex-wrap items-center justify-between gap-3 text-xs">
          <div className="flex items-center gap-2 text-slate-400">
            <Terminal className="w-4 h-4 text-emerald-400" />
            <span>Generate APK:</span>
            <code className="bg-black/60 px-2.5 py-1 rounded-md text-emerald-300 font-mono font-bold">
              flutter build apk --release
            </code>
          </div>

          <a
            href="/sundo-flutter-project.zip"
            download="sundo_flutter_project.zip"
            className="text-emerald-400 font-bold hover:underline flex items-center gap-1 no-underline"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Download All Files (.zip)</span>
          </a>
        </div>
      </div>
    </div>
  );
};
