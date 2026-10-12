import 'package:geolocator/geolocator.dart';

import '../../core/app_exception.dart';

/// Wraps geolocator with permission handling and readable errors.
class LocationService {
  Future<Position> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AppException('Location is turned off. Please enable GPS and try again.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const AppException('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AppException('Location permission is blocked. Enable it from the app settings.');
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      throw const AppException('Could not get your location. Try again outdoors.');
    }
  }
}
