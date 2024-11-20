// ignore_for_file: avoid_print, deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_maps_webservices/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'profile.dart';
import 'chatbot.dart';

enum AlertType {
  fire,
  crash,
  theft,
  dog,
  none,
}

class AlertInfo {
  final String title;
  final Color color;
  final String iconPath;
  final String emergencyNumber;

  AlertInfo({
    required this.title,
    required this.color,
    required this.iconPath,
    required this.emergencyNumber,
  });
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  AlertType _selectedAlert = AlertType.none;
  String _locationText = 'Loading location...';

  double? _latitude;
  double? _longitude;

  // Firestore Collection Reference
  final CollectionReference heatPointsCollection =
      FirebaseFirestore.instance.collection('HeatPoints');

  // Google Map markers
  final Set<Marker> _markers = {};

  final Map<AlertType, AlertInfo> alertInfoMap = {
    AlertType.fire: AlertInfo(
      title: 'Fire Alert',
      color: Colors.orange,
      iconPath: 'assets/images/fire.png',
      emergencyNumber: '(044) 594473',
    ),
    AlertType.crash: AlertInfo(
      title: 'Crash Alert',
      color: Colors.blue,
      iconPath: 'assets/images/car.png',
      emergencyNumber: '949418268',
    ),
    AlertType.theft: AlertInfo(
      title: 'Theft Alert',
      color: Colors.red,
      iconPath: 'assets/images/theft.png',
      emergencyNumber: '(044) 281374',
    ),
    AlertType.dog: AlertInfo(
      title: 'Dog Alert',
      color: Colors.green,
      iconPath: 'assets/images/dog.png',
      emergencyNumber: '913684363',
    ),
  };

  final GoogleMapsGeocoding _googleGeocoding = GoogleMapsGeocoding(apiKey: dotenv.env['GEOCODING_KEY']!);
  
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    print("Initializing Home screen...");
    _requestPermissions();
    _determinePosition(); // Perform geocoding on app start/restart
    _setupLocationUpdates(); // Start listening for location updates
    _setupHeatPointListener(); // Listen for Firestore updates
    _removeExpiredMarkers(); // Clean up old markers
  }

  Future<void> _requestPermissions() async {
    var locationStatus = await Permission.locationWhenInUse.status;
    if (!locationStatus.isGranted) {
      await Permission.locationWhenInUse.request();
    }

    var phoneStatus = await Permission.phone.status;
    if (!phoneStatus.isGranted) {
      await Permission.phone.request();
    }
  }

  Future<void> _setupLocationUpdates() async {
    // Ensure permissions are granted before starting the listener
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    if (!serviceEnabled || permission == LocationPermission.denied) {
      print("Location services or permissions are not enabled.");
      return;
    }

    // Start listening to location updates
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update if the user moves 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      print("Updated Position - Latitude: $_latitude, Longitude: $_longitude");
    });
  }

  @override
    void dispose() {
      // Cancel location listener when widget is disposed
      _positionStreamSubscription?.cancel();
      super.dispose();
    }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationText = 'Location services are disabled';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationText = 'Location permission denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationText = 'Location permissions are permanently denied';
      });
      return;
    }

    try {
      print("Attempting to retrieve current position...");
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      print("Initial Position - Latitude: $_latitude, Longitude: $_longitude");

      // Perform geocoding once when app starts/restarts
      await _getAddressFromCoordinates(_latitude!, _longitude!);
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _locationText = 'Failed to get location';
      });
    }
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      print("Fetching address for Latitude: $latitude, Longitude: $longitude");

      // Fetch response from the Geocoding API
      final response = await _googleGeocoding.searchByLocation(
        Location(lat: latitude, lng: longitude),
      );

      // Debug the full response for better visibility
      print("Full Geocoding Response: ${response.toJson()}");

      // Handle errors in the API response
      if (response.status != "OK") {
        print("Error from Geocoding API: ${response.status} - ${response.errorMessage}");
        setState(() {
          _locationText = response.errorMessage != null
              ? "Error fetching address: ${response.errorMessage}"
              : "Failed to fetch address";
        });
        return;
      }

      if (response.results.isEmpty) {
        setState(() {
          _locationText = 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
        });
        return;
      }

      // Parse the address components to find city and country
      final place = response.results.first;
      String? city;
      String? country;

      for (var component in place.addressComponents) {
        print("Component: ${component.longName}, Types: ${component.types}");
        if (component.types.contains("locality")) {
          city = component.longName;
        }
        if (component.types.contains("country")) {
          country = component.longName;
        }
      }

      print("Parsed Location - City: $city, Country: $country");

      // Update the location text
      setState(() {
        _locationText = city != null && country != null
            ? 'You are in $city, $country'
            : 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      print('Geocoding error: $e');
      setState(() {
        _locationText = 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
      });
    }
  }

  // Add a marker to Firestore
  Future<void> _addMarkerToFirestore(AlertType type) async {
    if (_latitude == null || _longitude == null) {
      print('Error: Missing location data');
      return;
    }

    try {
      print('Adding marker: Lat=$_latitude, Lng=$_longitude, Type=${type.name}');
      await heatPointsCollection.add({
        'latitude': _latitude!,
        'longitude': _longitude!,
        'type': type.name,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Marker successfully added to Firestore');
    } catch (e) {
      print('Error adding marker to Firestore: $e');
    }
  }

  
  // Fetch and display markers from Firestore in real-time
  void _setupHeatPointListener() {
    heatPointsCollection.snapshots().listen((snapshot) {
      print("Firestore snapshot received with ${snapshot.docs.length} documents.");
      setState(() {
        _markers.clear(); // Clear existing markers before adding new ones
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Debug: Log Firestore data
          print('Firestore Data: $data');

          // Ensure valid latitude and longitude
          if (data['latitude'] != null && data['longitude'] != null) {
            final markerType = AlertType.values.firstWhere(
              (type) => type.name == data['type'],
              orElse: () => AlertType.none,
            );

            // Log the marker type
            print('Adding marker of type: $markerType');

            // Create the marker
            final marker = Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(data['latitude'], data['longitude']),
              icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerColor(markerType)),
              infoWindow: InfoWindow(
                title: alertInfoMap[markerType]?.title ?? 'Alert',
              ),
            );

            _markers.add(marker);
          }
        }
      });
    });
  }


  // Clean up old markers from Firestore
  Future<void> _removeExpiredMarkers() async {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    try {
      final querySnapshot = await heatPointsCollection
          .where('timestamp', isLessThan: oneHourAgo)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
        print('Expired marker removed: ${doc.id}');
      }
    } catch (e) {
      print('Error removing expired markers: $e');
    }
  }



  // Get marker color based on type
  double _getMarkerColor(AlertType type) {
    switch (type) {
      case AlertType.fire:
        return BitmapDescriptor.hueOrange;
      case AlertType.crash:
        return BitmapDescriptor.hueBlue;
      case AlertType.theft:
        return BitmapDescriptor.hueRed;
      case AlertType.dog:
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueYellow;
    }
  }

  String get currentEmergencyNumber {
    return _selectedAlert == AlertType.none
        ? '911'
        : alertInfoMap[_selectedAlert]!.emergencyNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildLocationInfo(),
                    Expanded(child: _buildMap(context)),
                    _buildAlertButtons(),
                    _buildBottomButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Adjusted padding for better placement
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // App Logo
              Image.asset(
                'assets/images/logo.png',
                height: 60,
              ),

              // User Profile Section
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Profile()),
                  );
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // User Name
                    Text(
                      user != null
                          ? (user.displayName ?? user.email ?? 'User')
                          : 'Guest',
                      style: const TextStyle(
                        color: Color(0xFF57D463),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12), // Increased spacing between name and picture
                    // User Picture
                    user?.photoURL != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(user!.photoURL!),
                            radius: 25,
                          )
                        : const Icon(
                            Icons.account_circle,
                            color: Color(0xFF57D463),
                            size: 50,
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }




  Widget _buildLocationInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _locationText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF57D463),
            ),
          ),
          const Text(
            'This is happening in your area',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Color(0xFF57D463)),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    if (_latitude == null || _longitude == null) {
      // If coordinates are not yet available, show a loading indicator
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    try {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Shadow color
                spreadRadius: 6, // Spread radius
                blurRadius: 6, // Blur radius
                offset: const Offset(2, 4), // Shadow position
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.0), // Apply rounded corners
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(_latitude!, _longitude!),
                  zoom: 14.0,
                ),
                markers: _markers, // Updated to display dynamic markers
                mapType: MapType.terrain,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (GoogleMapController controller) {
                  print('GoogleMap created successfully');
                },
                onTap: (position) async {
                  // Add marker on map tap when an alert type is selected
                  if (_selectedAlert != AlertType.none) {
                    _latitude = position.latitude;
                    _longitude = position.longitude;
                    await _addMarkerToFirestore(_selectedAlert);
                  }
                },
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error rendering GoogleMap: $e');
      return const Center(
        child: Text(
          'Failed to load map. Please check your API key and permissions.',
          style: TextStyle(fontSize: 18, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }
  }



  Widget _buildAlertButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildAlertButton(AlertType.fire)),
              const SizedBox(width: 8),
              Expanded(child: _buildAlertButton(AlertType.crash)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildAlertButton(AlertType.theft)),
              const SizedBox(width: 8),
              Expanded(child: _buildAlertButton(AlertType.dog)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertButton(AlertType alertType) {
    final alertInfo = alertInfoMap[alertType]!;
    final isSelected = _selectedAlert == alertType;

    return ElevatedButton(
      onPressed: () async {
        setState(() {
          // Toggle the selected alert
          _selectedAlert = isSelected ? AlertType.none : alertType;
        });

        // If an alert type is selected, add the marker to Firestore
        if (_selectedAlert != AlertType.none && _latitude != null && _longitude != null) {
          print("Adding alert of type: $_selectedAlert at Lat=$_latitude, Lng=$_longitude");
          await _addMarkerToFirestore(_selectedAlert);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${alertInfo.title} marker added!')),
          );
        } else {
          print('Error: Missing location or alert type');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to add marker: Missing location or alert type')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: alertInfo.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: isSelected
            ? const BorderSide(color: Colors.white, width: 3)
            : BorderSide.none,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(alertInfo.iconPath, height: 24, width: 24),
          const SizedBox(width: 8),
          Text(alertInfo.title, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final phoneNumber = Uri.encodeFull(currentEmergencyNumber);
                final Uri launchUri = Uri(
                  scheme: 'tel',
                  path: phoneNumber,
                );

                var status = await Permission.phone.status;

                if (status.isGranted) {
                  try {
                    await url_launcher.launchUrl(
                      launchUri,
                      mode: url_launcher.LaunchMode.externalApplication,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error launching dialer: ${e.toString()}')),
                      );
                    }
                  }
                } else {
                  var result = await Permission.phone.request();

                  if (result.isGranted) {
                    try {
                      await url_launcher.launchUrl(
                        launchUri,
                        mode: url_launcher.LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error launching dialer: ${e.toString()}')),
                        );
                      }
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Permission denied to make calls')),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.phone, color: Colors.white),
              label: Text(
                'CALL $currentEmergencyNumber',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            alignment: Alignment.topLeft,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatBotScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(8),
                ),
                child: Image.asset('assets/images/bot.png', height: 40, width: 40),
              ),
              Positioned(
                top: -5,
                left: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat, size: 20, color: Color(0xFF57D463)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
