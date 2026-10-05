import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/utils/resident_location.dart';

/// Weather needs an approximate area, rather than a resident's precise fix.
class WeatherLocation {
  const WeatherLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.isDeviceLocation,
  });

  final double latitude;
  final double longitude;
  final String label;
  final bool isDeviceLocation;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180;

  WeatherLocation get approximate => WeatherLocation(
        latitude: (latitude * 100).roundToDouble() / 100,
        longitude: (longitude * 100).roundToDouble() / 100,
        label: label,
        isDeviceLocation: isDeviceLocation,
      );

  @override
  bool operator ==(Object other) =>
      other is WeatherLocation &&
      latitude == other.latitude &&
      longitude == other.longitude &&
      label == other.label &&
      isDeviceLocation == other.isDeviceLocation;

  @override
  int get hashCode => Object.hash(latitude, longitude, label, isDeviceLocation);
}

enum EnvironmentLocationStatus {
  idle,
  checking,
  device,
  savedArea,
  denied,
  deniedForever,
  disabled,
  unavailable,
}

class EnvironmentLocationResult {
  const EnvironmentLocationResult(this.status, {this.location});
  final EnvironmentLocationStatus status;
  final WeatherLocation? location;
}

/// Foreground, one-shot location only; permission is requested by an explicit
/// user action. Coordinates are neither persisted nor reverse-geocoded.
class EnvironmentLocationService {
  EnvironmentLocationService({
    Future<bool> Function()? checkService,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Future<Position> Function()? fetchPosition,
    Future<bool> Function()? openLocationSettings,
    Future<bool> Function()? openAppSettings,
    DateTime Function()? clock,
    this.timeout = const Duration(seconds: 12),
  })  : _checkService = checkService ?? Geolocator.isLocationServiceEnabled,
        _checkPermission = checkPermission ?? Geolocator.checkPermission,
        _requestPermission = requestPermission ?? Geolocator.requestPermission,
        _fetchPosition = fetchPosition ??
            (() => Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.low,
                  timeLimit: const Duration(seconds: 12),
                )),
        _openLocationSettings =
            openLocationSettings ?? Geolocator.openLocationSettings,
        _openAppSettings = openAppSettings ?? Geolocator.openAppSettings,
        _clock = clock ?? DateTime.now;

  final Future<bool> Function() _checkService;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<Position> Function() _fetchPosition;
  final Future<bool> Function() _openLocationSettings;
  final Future<bool> Function() _openAppSettings;
  final DateTime Function() _clock;
  final Duration timeout;

  Future<bool> isLocationServiceEnabled() async {
    try {
      return await _checkService().timeout(timeout);
    } catch (_) {
      return false;
    }
  }

  Future<bool> openLocationSettings() => _openLocationSettings();
  Future<bool> openAppSettings() => _openAppSettings();

  Future<EnvironmentLocationStatus> deviceAccessStatus() async {
    try {
      final permission = await _checkPermission().timeout(timeout);
      if (permission == LocationPermission.deniedForever) {
        return EnvironmentLocationStatus.deniedForever;
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return EnvironmentLocationStatus.denied;
      }
      return await _checkService().timeout(timeout)
          ? EnvironmentLocationStatus.device
          : EnvironmentLocationStatus.disabled;
    } catch (_) {
      return EnvironmentLocationStatus.unavailable;
    }
  }

  Future<EnvironmentLocationResult> resolve(
      {required bool requestPermission, bool Function()? canContinue}) async {
    bool active() => canContinue?.call() ?? true;
    try {
      if (!active()) {
        return const EnvironmentLocationResult(
            EnvironmentLocationStatus.unavailable);
      }
      var permission = await _checkPermission().timeout(timeout);
      if (!active()) {
        return const EnvironmentLocationResult(
            EnvironmentLocationStatus.unavailable);
      }
      if (permission == LocationPermission.denied && requestPermission) {
        // The native permission dialog remains controlled by the user. Its
        // result is invalidated by the controller if the app is backgrounded.
        permission = await _requestPermission();
      }
      if (!active()) {
        return const EnvironmentLocationResult(
            EnvironmentLocationStatus.unavailable);
      }
      if (permission == LocationPermission.deniedForever) {
        return const EnvironmentLocationResult(
            EnvironmentLocationStatus.deniedForever);
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return const EnvironmentLocationResult(
            EnvironmentLocationStatus.denied);
      }
      // Permission and the phone's Location switch are separate. Requesting
      // consent first lets the user grant access even with Location turned off.
      if (!await _checkService().timeout(timeout)) {
        return const EnvironmentLocationResult(
            EnvironmentLocationStatus.disabled);
      }
      if (!active()) {
        return const EnvironmentLocationResult(
            EnvironmentLocationStatus.unavailable);
      }
      final position = await _fetchPosition().timeout(timeout);
      if (!active()) {
        return const EnvironmentLocationResult(
            EnvironmentLocationStatus.unavailable);
      }
      if (!position.latitude.isFinite ||
          !position.longitude.isFinite ||
          position.latitude.abs() > 90 ||
          position.longitude.abs() > 180 ||
          !position.accuracy.isFinite ||
          position.accuracy < 0 ||
          position.accuracy > 5000 ||
          !residentFixIsFresh(position.timestamp, _clock())) {
        return const EnvironmentLocationResult(
            EnvironmentLocationStatus.unavailable);
      }
      // Recheck after a slow fix: revoked permission must not initiate weather.
      final stillAllowed = await _checkPermission().timeout(timeout);
      if (!active()) {
        return const EnvironmentLocationResult(
            EnvironmentLocationStatus.unavailable);
      }
      if (stillAllowed != LocationPermission.always &&
          stillAllowed != LocationPermission.whileInUse) {
        return EnvironmentLocationResult(
            stillAllowed == LocationPermission.deniedForever
                ? EnvironmentLocationStatus.deniedForever
                : EnvironmentLocationStatus.denied);
      }
      if (!await _checkService().timeout(timeout)) {
        return const EnvironmentLocationResult(
            EnvironmentLocationStatus.disabled);
      }
      if (!active()) {
        return const EnvironmentLocationResult(
            EnvironmentLocationStatus.unavailable);
      }
      if (!residentFixIsFresh(position.timestamp, _clock())) {
        return const EnvironmentLocationResult(
            EnvironmentLocationStatus.unavailable);
      }
      return EnvironmentLocationResult(EnvironmentLocationStatus.device,
          location: WeatherLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            label: 'your location',
            isDeviceLocation: true,
          ).approximate);
    } catch (_) {
      return const EnvironmentLocationResult(
          EnvironmentLocationStatus.unavailable);
    }
  }

  /// The registration field is constrained to Sipalay barangays. No fabricated
  /// barangay centroid is used: this is explicitly city-level model weather.
  static WeatherLocation? savedAreaLocation(String? savedArea) {
    final area = (savedArea ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    const supported = {
      'barangay 1',
      'barangay 2',
      'barangay 3',
      'barangay 4',
      'barangay 5',
      'cabadiangan',
      'camindangan',
      'canturay',
      'cartagena',
      'cayhagan',
      'gil montilla',
      'mambaroto',
      'manlucahoc',
      'maricalum',
      'nabulao',
      'nauhang',
      'san jose',
      'sipalay city',
    };
    if (!supported.contains(area)) return null;
    return const WeatherLocation(
      latitude: 9.7525,
      longitude: 122.4038,
      label: 'Sipalay City (saved area)',
      isDeviceLocation: false,
    ).approximate;
  }
}

final environmentLocationServiceProvider =
    Provider<EnvironmentLocationService>((ref) => EnvironmentLocationService());
final environmentLocationStatusProvider = NotifierProvider<
    EnvironmentLocationStatusController,
    EnvironmentLocationStatus>(EnvironmentLocationStatusController.new);

class EnvironmentLocationStatusController
    extends Notifier<EnvironmentLocationStatus> {
  @override
  EnvironmentLocationStatus build() => EnvironmentLocationStatus.idle;
  void setStatus(EnvironmentLocationStatus status) => state = status;
}
