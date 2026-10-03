# SUNDO - Smart Urban Navigation for Dynamic Waste Operations (Flutter + Dart)
Official Mobile Application for Sipalay City, Negros Occidental • CENRO

## Requirements
- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio or VS Code with Flutter extension
- Android Device or Android Emulator (API 26+)

## Getting Started

1. **Install Dependencies**:
```bash
flutter pub get
```

2. **Run in Development Mode (Live on Phone or Emulator)**:
```bash
flutter run
```

3. **Build Official Release APK**:
```bash
flutter build apk --release
```
Your compiled, signed native Android APK will be ready at:
`build/app/outputs/flutter-apk/app-release.apk`

4. **Install on Phone via USB**:
```bash
flutter install
```
or:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Features Included in Flutter Codebase
- **Live OpenStreetMap GPS Tracking**: Real-time waste collection vehicle movements on Leaflet OpenStreetMap with polyline routing.
- **Dynamic ETA Telemetry**: Instant calculations of vehicle distance, arrival minutes, speed, and compactor capacity.
- **Resident Garbage Reporting**: Camera capture, automatic GPS geotagging, categorization, and dispatch ticketing.
- **Barangay Schedules**: Full waste collection schedule for Gil Montilla, Poblacion, Nauhang, San Jose, Canturay, and Cayhagan.
- **Material 3 Design**: Fully responsive, high-contrast accessible layout for mobile screens.
