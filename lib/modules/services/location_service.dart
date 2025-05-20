// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as perm_handler;
import 'package:flutter_google_maps_webservices/geocoding.dart'
    as g_geocoding;

/// A data class to hold the result of a location operation,
/// including data, a success flag, and an optional error message.
class LocationResult<T> {
  final T? data;
  final bool success;
  final String? errorMessage;

  LocationResult({this.data, this.success = true, this.errorMessage});
}

/// Service class to handle all location-related operations.
/// This includes fetching current location, streaming location updates,
/// handling permissions, and geocoding coordinates to addresses.
class LocationService {
  late final g_geocoding.GoogleMapsGeocoding _googleGeocoding;

  /// Constructor for LocationService.
  /// Initializes the GoogleMapsGeocoding instance with the API key from .env.
  ///
  /// Throws an assertion error if 'GEOCODING_KEY' is not found in the .env file.
  LocationService() {
    final apiKey = dotenv.env['GEOCODING_KEY'];
    assert(apiKey != null,
        'GEOCODING_KEY not found in .env file. Please ensure it is set.');
    _googleGeocoding = g_geocoding.GoogleMapsGeocoding(apiKey: apiKey!);
    print("LocationService initialized.");
  }

  /// Checks if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Requests location permission from the user if not already granted.
  Future<bool> requestLocationPermission({bool openSettingsOnError = false}) async {
    print("Requesting location permission...");
    var status = await perm_handler.Permission.locationWhenInUse.status;
    if (status.isGranted) {
      print("Location permission already granted.");
      return true;
    }
    if (status.isDenied || status.isRestricted || status.isLimited) {
      print("Location permission is denied/restricted/limited. Requesting...");
      status = await perm_handler.Permission.locationWhenInUse.request();
      if (status.isGranted) {
        print("Location permission granted after request.");
        return true;
      } else {
        print("Location permission denied after request.");
        return false;
      }
    }
    // If permanently denied or other states, permission cannot be requested here.
    if (status.isPermanentlyDenied) {
      print("Location permission is permanently denied.");
      if (openSettingsOnError) {
        print("Attempting to open app settings for location permission...");
        await perm_handler.openAppSettings();
      }
    }
    return false;
  }

  /// Determines the current position of the device.
  ///
  /// This method checks for service availability and permissions before
  /// attempting to fetch the location.
  /// Returns a [LocationResult<Position>] which includes the position data
  /// on success, or an error message on failure.
  Future<LocationResult<Position>> getInitialPosition() async {
    print("Attempting to retrieve initial position...");

    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return LocationResult(
          success: false, errorMessage: 'Location services are disabled.');
    }

    bool permissionGranted = await requestLocationPermission(openSettingsOnError: true);
    if (!permissionGranted) {
      // Check the specific status to provide a more accurate message
      perm_handler.PermissionStatus status =
          await perm_handler.Permission.locationWhenInUse.status;
      String errorMessage = 'Location permission denied.';
      if (status.isPermanentlyDenied) {
        errorMessage =
            'Location permissions are permanently denied. Please enable them in app settings.';
      }
      print(errorMessage);
      return LocationResult(success: false, errorMessage: errorMessage);
    }

    try {
      print("Fetching current position with high accuracy...");
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      print(
          "Initial Position - Latitude: ${position.latitude}, Longitude: ${position.longitude}");
      return LocationResult(data: position);
    } catch (e) {
      print('Error getting initial location: $e');
      return LocationResult(
          success: false, errorMessage: 'Failed to get location: ${e.toString()}');
    }
  }

  /// Provides a stream of position updates.
  ///
  /// The stream emits a new [Position] whenever the device's location changes
  /// according to the specified [LocationSettings].
  ///
  /// It's crucial to handle permissions before calling this method.
  /// If permissions are not granted, this stream might not yield any data
  /// or could throw an error depending on the platform.
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // Update if the user moves 10 meters
  }) {
    print(
        "Setting up location updates stream with accuracy: $accuracy, distanceFilter: $distanceFilter");
    // The calling widget should ensure permissions are granted before subscribing to this stream.
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Fetches a human-readable address from geographic coordinates (latitude and longitude).
  ///
  /// Uses the Google Geocoding API.
  /// Returns a [LocationResult<String>] containing the formatted address (e.g., "City, Country")
  /// or an error message on failure.
  Future<LocationResult<String>> getAddressFromCoordinates(
      double latitude, double longitude) async {
    print(
        "Fetching address for Latitude: $latitude, Longitude: $longitude");
    try {
      final response = await _googleGeocoding.searchByLocation(
        g_geocoding.Location(lat: latitude, lng: longitude),
      );

      print("Full Geocoding Response Status: ${response.status}");
      if (response.results.isNotEmpty) {
        print("First Geocoding Result: ${response.results.first.toJson()}");
      }


      if (response.status != "OK") {
        print(
            "Error from Geocoding API: ${response.status} - ${response.errorMessage}");
        return LocationResult(
            success: false,
            errorMessage: response.errorMessage ?? "Failed to fetch address (API status not OK)");
      }

      if (response.results.isEmpty) {
        print("No address results found for the given coordinates.");
        return LocationResult(
            data:
                'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)} (No address found)');
      }

      final place = response.results.first;
      String? city;
      String? country;

      for (var component in place.addressComponents) {
        // print("Component: ${component.longName}, Types: ${component.types}");
        if (component.types.contains("locality")) {
          city = component.longName;
        }
        if (component.types.contains("administrative_area_level_1") && city == null) {
          // Fallback to administrative_area_level_1 if locality is not found
          city = component.longName;
        }
        if (component.types.contains("country")) {
          country = component.longName;
        }
      }

      print("Parsed Location - City: $city, Country: $country");

      if (city != null && country != null) {
        return LocationResult(data: '$city, $country');
      } else if (city != null) {
        return LocationResult(data: city);
      } else if (country != null) {
        return LocationResult(data: country);
      } else {
        // Fallback to formatted address if specific components are not found
        if (place.formattedAddress != null && place.formattedAddress!.isNotEmpty) {
            return LocationResult(data: place.formattedAddress);
        }
        return LocationResult(
            data:
                'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)} (Address components not found)');
      }
    } catch (e) {
      print('Geocoding error: $e');
      return LocationResult(
          success: false,
          errorMessage:
              'Geocoding error: ${e.toString()}');
    }
  }
}
