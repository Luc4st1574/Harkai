// ignore_for_file: avoid_print, deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' show Position; // Only import Position

// Services
import '../../modules/services/location_service.dart';
import '../../modules/services/firestore_service.dart';
import '../../modules/services/phone_service.dart';

// Utils (Models and Map Utilities)
import '../../modules/utils/alerts.dart';
import '../../modules/utils/map_utils.dart';

// Widgets for this screen
import 'widgets/header.dart';
import 'widgets/location_info.dart';
import 'widgets/map.dart';
import 'widgets/alert_buttons.dart';
import 'widgets/bottom_butons.dart';
import 'widgets/description_modal.dart'; // For showDescriptionInputDialog

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState(); 
}

class _HomeState extends State<Home> { 
  // State Variables
  AlertType _selectedAlert = AlertType.none;
  String _locationText = 'Loading location...';
  double? _latitude;
  double? _longitude;
  Set<Marker> _markers = {};
  User? _currentUser;

  // Service Instances
  late final LocationService _locationService;
  late final FirestoreService _firestoreService;
  late final PhoneService _phoneService;
  // late final PermissionService _permissionService; // If needed for other permissions

  // Stream Subscriptions
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<List<HeatPointData>>? _heatPointsSubscription;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    print("Initializing Home screen..."); // Kept print for consistency

    // Initialize services
    _locationService = LocationService();
    _firestoreService = FirestoreService();
    _phoneService = PhoneService();
    // _permissionService = PermissionService();

    _initializeScreenData();
  }

  /// Asynchronously initializes data needed for the screen.
  Future<void> _initializeScreenData() async {
    _listenToAuthChanges();
    // Request initial location permission. Phone permission is handled by PhoneService.
    await _locationService.requestLocationPermission(openSettingsOnError: true);
    await _fetchInitialLocationAndAddress();
    _setupLocationUpdatesListener();
    _setupHeatPointListener();
    _firestoreService.removeExpiredHeatPoints(); // Run in background
  }

  /// Listens to Firebase authentication state changes.
  void _listenToAuthChanges() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  /// Fetches the initial device location and corresponding address.
  Future<void> _fetchInitialLocationAndAddress() async {
    if (!mounted) return;

    setState(() {
      _locationText = 'Fetching location...';
    });

    final initialPosResult = await _locationService.getInitialPosition();

    if (initialPosResult.success && initialPosResult.data != null) {
      _latitude = initialPosResult.data!.latitude;
      _longitude = initialPosResult.data!.longitude;
      print(
          "Initial Position - Latitude: $_latitude, Longitude: $_longitude");

      final addressResult = await _locationService.getAddressFromCoordinates(
          _latitude!, _longitude!);
      if (mounted) {
        setState(() {
          _locationText = addressResult.success
              ? 'You are in ${addressResult.data!}'
              : addressResult.errorMessage ?? 'Could not fetch address';
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _locationText =
              initialPosResult.errorMessage ?? 'Failed to get initial location';
        });
      }
    }
  }

  /// Sets up a listener for continuous location updates.
  Future<void> _setupLocationUpdatesListener() async {
    bool serviceEnabled = await _locationService.isLocationServiceEnabled();
    // Re-check permission or rely on initial request. For robustness, can check again.
    bool permGranted = await _locationService.requestLocationPermission();

    if (!serviceEnabled || !permGranted) {
      print(
          "Cannot setup location updates: Service/permission issue. Location updates disabled.");
      if (mounted) {
        // Optionally update UI to inform user that live location isn't working
        // setState(() { _locationText = "Live location updates disabled."; });
      }
      return;
    }

    _positionStreamSubscription =
        _locationService.getPositionStream().listen((Position position) {
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          // Optionally, update _locationText with new address, but be mindful of API usage.
          // For now, we only update coordinates from the stream.
        });
        print(
            "Live Update - Latitude: $_latitude, Longitude: $_longitude");
      }
    }, onError: (error) {
      print("Error in location stream: $error");
      // Handle stream errors, e.g., update UI
    });
  }

  /// Sets up a listener for real-time updates from the Firestore 'HeatPoints' collection.
  void _setupHeatPointListener() {
    _heatPointsSubscription =
        _firestoreService.getHeatPointsStream().listen((List<HeatPointData> heatPoints) {
      if (mounted) {
        print(
            "Firestore snapshot received with ${heatPoints.length} heat points.");
        final newMarkers = <Marker>{};
        for (final heatPoint in heatPoints) {
          final alertInfoForMarker = getAlertInfo(heatPoint.type);
          final marker = Marker(
            markerId: MarkerId(heatPoint.id),
            position: LatLng(heatPoint.latitude, heatPoint.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                getMarkerHue(heatPoint.type)),
            infoWindow: InfoWindow(
              title: alertInfoForMarker?.title ?? heatPoint.type.name.capitalize(),
              snippet: heatPoint.description.isNotEmpty ? heatPoint.description : null,
            ),
          );
          newMarkers.add(marker);
        }
        setState(() {
          _markers = newMarkers;
        });
      }
    }, onError: (error) {
      print("Error in heat points stream: $error");
      // Handle stream errors
    });
  }

  @override
  void dispose() {
    print("Disposing Home screen..."); // Kept print for consistency
    _positionStreamSubscription?.cancel();
    _heatPointsSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  // --- Getters for dynamic UI text based on selected alert ---
  String get currentServiceName {
    if (_selectedAlert == AlertType.none || _selectedAlert == AlertType.emergency) {
      return 'Call Emergencies';
    }
    final alertInfo = getAlertInfo(_selectedAlert);
    return alertInfo != null ? 'Call ${alertInfo.title.replaceFirst(" Alert", "")}' : 'Call Emergencies';
  }

  String get currentEmergencyNumber {
    if (_selectedAlert == AlertType.none || _selectedAlert == AlertType.emergency) {
      return getAlertInfo(AlertType.emergency)?.emergencyNumber ?? '911';
    }
    return getAlertInfo(_selectedAlert)?.emergencyNumber ?? '911';
  }

  // --- Event Handlers ---

  /// Handles the press of one of the main four alert type buttons.
  Future<void> _handleAlertButtonPressed(AlertType alertType) async {
    if (!mounted) return;

    final bool wasSelected = _selectedAlert == alertType;
    setState(() {
      _selectedAlert = wasSelected ? AlertType.none : alertType;
    });

    if (!wasSelected && _selectedAlert != AlertType.none) {
      if (_latitude != null && _longitude != null) {
        final description = await showDescriptionInputDialog(
          context: context,
          alertType: _selectedAlert,
        );
        // Use current location for button-initiated alerts
        final success = await _firestoreService.addHeatPoint(
          type: _selectedAlert,
          latitude: _latitude!,
          longitude: _longitude!,
          description: description,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(success
                    ? '${getAlertInfo(_selectedAlert)?.title ?? "Alert"} marker added!'
                    : 'Failed to add marker.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to add marker: Location unknown.')),
        );
        // Revert selection if location is unknown
        setState(() { _selectedAlert = AlertType.none; });
      }
    } else if (wasSelected) {
        print("Alert type deselected: ${alertType.name}");
    }
  }

  /// Handles the press of the dedicated emergency button.
  Future<void> _handleEmergencyButtonPressed() async {
    if (!mounted) return;

    if (_latitude != null && _longitude != null) {
      final description = await showDescriptionInputDialog(
        context: context,
        alertType: AlertType.emergency,
      );
      final success = await _firestoreService.addHeatPoint(
        type: AlertType.emergency,
        latitude: _latitude!,
        longitude: _longitude!,
        description: description,
      );
      _resetToDefaultSelectedAlert(); // Reset selection after emergency
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Emergency marker added!' : 'Failed to add emergency marker.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to add emergency marker: Location unknown.')),
      );
    }
  }

  /// Handles the press of the phone call button.
  Future<void> _handlePhoneButtonPressed() async {
    if (!mounted) return;
    await _phoneService.makePhoneCall(
      phoneNumber: currentEmergencyNumber,
      context: context,
    );
  }

  /// Handles taps on the map, adding a marker if an alert type is selected.
  Future<void> _handleMapTapped(LatLng position) async {
    if (!mounted || _selectedAlert == AlertType.none) return;

    // For map taps, we typically don't ask for a description to keep it quick.
    // The original code also didn't ask for description on map tap.
    final success = await _firestoreService.addHeatPoint(
      type: _selectedAlert,
      latitude: position.latitude,
      longitude: position.longitude,
      // description: null, // Explicitly no description for map tap alerts
    );

    if (mounted) {
      final alertInfo = getAlertInfo(_selectedAlert);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(success
                ? '${alertInfo?.title ?? "Alert"} marker added at tapped location!'
                : 'Failed to add marker at tapped location.')),
      );
    }
    // Decide if _selectedAlert should be reset after a map tap.
    // For now, it remains selected, allowing multiple map tap markers.
    // To reset: _resetToDefaultSelectedAlert();
  }

  /// Resets the selected alert type to none.
  void _resetToDefaultSelectedAlert() {
    if (mounted) {
      setState(() {
        _selectedAlert = AlertType.none;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F), // Main background color
      body: SafeArea(
        child: Column(
          children: [
            HomeHeaderWidget(currentUser: _currentUser),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white, // Background for the main content area
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          LocationInfoWidget(locationText: _locationText),
                          MapDisplayWidget(
                            initialLatitude: _latitude,
                            initialLongitude: _longitude,
                            markers: _markers,
                            selectedAlert: _selectedAlert,
                            onMapTappedWithAlert: _handleMapTapped,
                            // onMapCreated: (controller) { /* Store controller if needed */ },
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: AlertButtonsGridWidget(
                          selectedAlert: _selectedAlert,
                          onAlertButtonPressed: _handleAlertButtonPressed,
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false, // Important for bottom alignment
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: BottomActionButtonsWidget(
                          currentServiceName: currentServiceName,
                          onEmergencyPressed: _handleEmergencyButtonPressed,
                          onPhonePressed: _handlePhoneButtonPressed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper extension for capitalizing strings (e.g., for enum names)
extension StringExtension on String {
    String capitalize() {
      if (isEmpty) return this;
      return "${this[0].toUpperCase()}${substring(1)}";
    }
}
