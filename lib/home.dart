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
  emergency,
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
      emergencyNumber: '(044) 226495',
    ),
    AlertType.crash: AlertInfo(
      title: 'Crash Alert',
      color: Colors.blue,
      iconPath: 'assets/images/car.png',
      emergencyNumber: '(044) 484242',
    ),
    AlertType.theft: AlertInfo(
      title: 'Theft Alert',
      color: Colors.purple,
      iconPath: 'assets/images/theft.png',
      emergencyNumber: '(044) 250664',
    ),
    AlertType.dog: AlertInfo(
      title: 'Dog Alert',
      color: Colors.green,
      iconPath: 'assets/images/dog.png',
      emergencyNumber: '913684363',
    ),
    AlertType.emergency: AlertInfo(
    title: 'Emergency Alert', 
    color: Colors.red.shade900, 
    iconPath: 'assets/images/emergency.png', 
    emergencyNumber: '911', 
  ),
  };

  String get currentServiceName {
  switch (_selectedAlert) {
    case AlertType.fire:
      return 'Call Firefighters';
    case AlertType.crash:
      return 'Call Serenity';
    case AlertType.theft:
      return 'Call Police';
    case AlertType.dog:
      return 'Call Shelter';
    case AlertType.emergency:
      return 'Call Emergencies';
    default:
      return 'Call Emergencies';
  }
}

String get currentEmergencyNumber {
  switch (_selectedAlert) {
    case AlertType.fire:
      return alertInfoMap[AlertType.fire]!.emergencyNumber;
    case AlertType.crash:
      return alertInfoMap[AlertType.crash]!.emergencyNumber;
    case AlertType.theft:
      return alertInfoMap[AlertType.theft]!.emergencyNumber;
    case AlertType.dog:
      return alertInfoMap[AlertType.dog]!.emergencyNumber;
    case AlertType.emergency:
      return alertInfoMap[AlertType.emergency]!.emergencyNumber;
    default:
      return '911';
  }
}

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
  Future<void> _addMarkerToFirestore(AlertType type, [String? description]) async {
    if (_latitude == null || _longitude == null) {
      print('Error: Missing location data');
      return;
    }

    try {
      print('Adding marker: Lat=$_latitude, Lng=$_longitude, Type=${type.name}, Description=$description');
      await heatPointsCollection.add({
        'latitude': _latitude!,
        'longitude': _longitude!,
        'type': type.name, 
        'description': description ?? '', 
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Marker successfully added to Firestore');
    } catch (e) {
      print('Error adding marker to Firestore: $e');
    }
  }

  Future<String?> _showDescriptionModal(AlertType type) async {
    String? description;
    return await showDialog<String?>(
      context: context,
      builder: (BuildContext context) {
        return Material(
          color: Colors.transparent, // Keep the background transparent
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.9, // Improved width responsiveness
                      maxHeight: constraints.maxHeight * 0.5, // Improved height responsiveness
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF001F3F),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Modal Title
                        Text(
                          'Add Description (Optional)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: alertInfoMap[type]?.color ?? Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Row with Cancel Icon, TextField, and Send Icon
                        Row(
                          children: [
                            // Cancel Icon
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context, null); // Close dialog without saving
                              },
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: 'Cancel',
                              iconSize: 24,
                            ),
                            const SizedBox(width: 8),
                            // Description TextField
                            Expanded(
                              child: TextField(
                                style: const TextStyle(color: Colors.white),
                                cursorColor: Colors.blue,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF001F3F),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: alertInfoMap[type]?.color ?? Colors.blue,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: alertInfoMap[type]?.color ?? Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                  hintText: 'Enter a description...',
                                  hintStyle: const TextStyle(color: Colors.grey),
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onChanged: (value) {
                                  description = value;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Send Icon
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context, description); // Return the description
                              },
                              icon: Icon(Icons.send, color: alertInfoMap[type]?.color ?? Colors.blue),
                              tooltip: 'Save',
                              iconSize: 24,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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
                title: alertInfoMap[markerType]?.title ?? 'Alert', // Set the alert title here
                snippet: data['description'] ?? '', // Optional additional description
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
        return BitmapDescriptor.hueViolet;
      case AlertType.dog:
        return BitmapDescriptor.hueGreen;
      case AlertType.emergency:
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueRed;
    }
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
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildLocationInfo(),
                          _buildMap(context), // Updated with constraints
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildAlertButtons(),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildBottomButtons(context),
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    try {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: constraints.maxHeight, // Dynamically adapt to available height
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 6,
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_latitude!, _longitude!),
                    zoom: 16.0,
                  ),
                  markers: _markers.isEmpty ? {} : _markers,
                  mapType: MapType.terrain,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomGesturesEnabled: true, // Habilitar zoom con gestos
                  scrollGesturesEnabled: true, // Permitir desplazamiento
                  rotateGesturesEnabled: true, // Permitir rotación
                  tiltGesturesEnabled: true, // Permitir inclinación
                  onMapCreated: (GoogleMapController controller) {
                    debugPrint('GoogleMap created successfully');
                  },
                  onTap: (position) async {
                    if (_selectedAlert != AlertType.none) {
                      setState(() {
                        _latitude = position.latitude;
                        _longitude = position.longitude;
                      });
                      await _addMarkerToFirestore(_selectedAlert);
                    }
                  },
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('Error rendering GoogleMap: $e');
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

          // Show the description modal and get the entered description
          final description = await _showDescriptionModal(alertType);

          // Add marker with description
          await _addMarkerToFirestore(_selectedAlert, description);
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

  void _resetToDefault() {
    setState(() {
      _selectedAlert = AlertType.none; // Reset selected alert
    });
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Emergency Button (Left side)
          ElevatedButton(
            onPressed: () async {
              if (_latitude != null && _longitude != null) {
                print("Adding strong red marker for alert at Lat=$_latitude, Lng=$_longitude");

                // Show the description modal and get the entered description
                final description = await _showDescriptionModal(AlertType.emergency);

                // Add marker to Firestore with the description
                await heatPointsCollection.add({
                  'latitude': _latitude!,
                  'longitude': _longitude!,
                  'type': 'emergency',
                  'description': description ?? '',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                // Reset phone button to default values
                _resetToDefault();

                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency marker added!')),
                );
              } else {
                print('Error: Missing location data');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to add marker: Missing location')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900, // Emergency red
              shape: const CircleBorder(), // Circular design
              padding: const EdgeInsets.all(15), // Adjust padding for consistent size
              elevation: 8, // Add shadow for better visibility
              side: const BorderSide(color: Colors.white, width: 2), // Add subtle border
            ),
            child: Image.asset(
              'assets/images/alert.png',
              height: 28, // Slightly smaller image
              width: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Phone Button
          Expanded(
            child: ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Adjusted padding for responsiveness
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currentServiceName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14, // Adjusted font size for better fit
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis, // Ensures the text doesn't overflow
                        maxLines: 1, // Restrict to a single line
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),
          // Bot Button (Right side)
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