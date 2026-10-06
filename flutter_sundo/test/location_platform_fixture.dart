import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Render-only fixtures have no device GPS or location permission.
void mockUnavailableDeviceLocation() {
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (call) async {
    return switch (call.method) {
      'checkPermission' => 0,
      'isLocationServiceEnabled' => false,
      _ => throw StateError('Unexpected location request: ${call.method}'),
    };
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}
