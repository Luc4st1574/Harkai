import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'profile.dart';
import 'chatbot.dart';

// Enum for alert types
enum AlertType {
  fire,
  crash,
  theft,
  dog,
  none
}

// Class to hold alert information
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

  // Map to store alert information
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

  // Get current emergency number based on selected alert
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
              Image.asset('assets/images/logo.png', height: 50),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Profile()),
                  );
                },
                child: Column(
                  children: [
                    const Icon(Icons.account_circle, color: Color(0xFF57D463), size: 30),
                    const SizedBox(height: 4),
                    Text(
                      user != null
                          ? (user.displayName ?? user.email ?? 'User')
                          : 'Guest',
                      style: const TextStyle(color: Color(0xFF57D463), fontSize: 16),
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
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are in Trujillo, Peru',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF57D463)),
          ),
          Text(
            'This is happening in your area',
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