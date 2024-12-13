import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider with ChangeNotifier {
  String _currentLocation = "Fetching location..."; // Initial location value
  String get currentLocation => _currentLocation;

  // Method to request location permission
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    // If permission is denied, request permission
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _currentLocation = "Location permission denied. Please grant permission.";
      notifyListeners();
      return;
    }
  }

  // Method to fetch the user's current location and convert to address format
  Future<void> getCurrentLocation() async {
    try {
      // Ensure location permission is granted
      await _requestLocationPermission();

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _currentLocation = "Location services are disabled. Please enable them.";
        notifyListeners();
        return;
      }

      // Fetch the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode the position to get a human-readable address
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentLocation = "${place.street}, ${place.locality}, ${place.country}";
      } else {
        _currentLocation = "Address not found.";
      }
    } catch (e) {
      _currentLocation = "Failed to get location. Error: $e";
    }

    // Notify listeners about the state change
    notifyListeners();
  }
}
