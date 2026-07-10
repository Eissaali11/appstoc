import 'package:geolocator/geolocator.dart';

class GpsHelper {
  /// Request location permissions automatically on app startup.
  static Future<bool> requestPermission() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled with timeout.
      serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      if (!serviceEnabled) {
        return false;
      }

      permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 2),
        onTimeout: () => LocationPermission.denied,
      );
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 4),
          onTimeout: () => LocationPermission.denied,
        );
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch the current latitude and longitude coordinates.
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      // Return fallback/mock or null if failed
      return null;
    }
  }

  /// Generate a static map image URL for MapThumbnail.
  /// Uses a free static maps provider or a fallback mechanism.
  static String getStaticMapUrl(double latitude, double longitude) {
    // Yandex Static Map API (Free, no token required for basic tile/map requests)
    return 'https://static-maps.yandex.ru/1.x/?ll=$longitude,$latitude&z=15&l=map&size=450,200&pt=$longitude,$latitude,pm2rdm';
  }
}
