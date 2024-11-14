// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_maps_webservices/geocoding.dart';
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

  final GoogleMapsGeocoding _googleGeocoding = GoogleMapsGeocoding(apiKey: dotenv.env['MAPS_KEY']!);

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _determinePosition();
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

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationText = 'Location services are disabled';
      });
      return;
    }

    // Check and request location permission
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

    // Request current position with high accuracy
    try {
      print("Attempting to retrieve current position...");
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // Ensure high accuracy
      );
      _latitude = position.latitude;
      _longitude = position.longitude;

      // Debug prints to verify latitude and longitude
      print("Current Position - Latitude: $_latitude, Longitude: $_longitude");

      // Fetch address from Google Geocoding API
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
      
      final response = await _googleGeocoding.searchByLocation(Location(lat: latitude, lng: longitude));
      if (response.results.isEmpty) {
        setState(() {
          _locationText = 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
        });
        return;
      }

      final place = response.results.first;
      String? city;
      String? country;

      // Loop through address components to find city and country
      for (var component in place.addressComponents) {
        if (component.types.contains("locality")) {
          city = component.longName;
        } else if (component.types.contains("country")) {
          country = component.longName;
        }
      }

      print("Parsed Location - City: $city, Country: $country");

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
                    Expanded(child: _buildPlaceholder(context)),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/images/logo.png', height: 60),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Profile()),
                  );
                },
                child: Column(
                  children: [
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
                    const SizedBox(height: 4),
                    Text(
                      user != null
                          ? (user.displayName ?? user.email ?? 'User')
                          : 'Guest',
                      style: const TextStyle(color: Color(0xFF57D463), fontSize: 18),
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

  Widget _buildPlaceholder(BuildContext context) {
    return const SizedBox(
      height: 300,
      child: Center(
        child: Text(
          'Map Placeholder',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
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
      onPressed: () {
        setState(() {
          _selectedAlert = isSelected ? AlertType.none : alertType;
        });
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
