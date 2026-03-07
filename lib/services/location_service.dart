import 'package:geolocator/geolocator.dart';

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        return null;
      }

      // Check permission
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  // Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known position: $e');
      return null;
    }
  }

  // Stream of position updates
  Stream<Position>? getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  // Calculate distance between two positions
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Check if within valid range of customer location
  bool isWithinValidRange({
    required double workerLatitude,
    required double workerLongitude,
    required double customerLatitude,
    required double customerLongitude,
    double maxDistance = 100, // meters
  }) {
    final distance = calculateDistance(
      workerLatitude,
      workerLongitude,
      customerLatitude,
      customerLongitude,
    );
    return distance <= maxDistance;
  }

  // Get address from coordinates (reverse geocoding)
  // Note: This is a placeholder. You may need to use a geocoding service
  // like Google Maps Geocoding API or OpenStreetMap Nominatim
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    // TODO: Implement reverse geocoding using your preferred service
    // For now, return coordinates as string
    return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
  }

  // Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  // Validate location for attendance
  Future<Map<String, dynamic>> validateAttendanceLocation({
    double? customerLatitude,
    double? customerLongitude,
    double maxDistance = 100, // meters
  }) async {
    final position = await getCurrentPosition();
    
    if (position == null) {
      return {
        'valid': false,
        'message': 'Unable to get current location',
        'position': null,
      };
    }

    // If customer location is not provided, just return the position
    if (customerLatitude == null || customerLongitude == null) {
      return {
        'valid': true,
        'message': 'Location captured successfully',
        'position': position,
      };
    }

    // Check if within valid range
    final isValid = isWithinValidRange(
      workerLatitude: position.latitude,
      workerLongitude: position.longitude,
      customerLatitude: customerLatitude,
      customerLongitude: customerLongitude,
      maxDistance: maxDistance,
    );

    return {
      'valid': isValid,
      'message': isValid
          ? 'Location validated successfully'
          : 'You are too far from the customer location',
      'position': position,
      'distance': calculateDistance(
        position.latitude,
        position.longitude,
        customerLatitude,
        customerLongitude,
      ),
    };
  }
}
