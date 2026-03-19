import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  static const defaultLat = 39.9042;
  static const defaultLon = 116.4074;

  static const ({double lat, double lon, bool isDefault}) _defaultLocation = (
    lat: defaultLat,
    lon: defaultLon,
    isDefault: true,
  );

  Future<({double lat, double lon, bool isDefault})> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _defaultLocation;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _defaultLocation;
      }
      if (permission == LocationPermission.deniedForever) return _defaultLocation;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (lat: position.latitude, lon: position.longitude, isDefault: false);
    } catch (_) {
      return _defaultLocation;
    }
  }
}
