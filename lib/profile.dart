// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:harkai/services/auth_service.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  bool _obscurePassword = true;
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001F3F),
        title: const Text('User Profile', style: TextStyle(color: Color(0xFF57D463))),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF57D463)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Display Google profile picture if available, otherwise default icon
              user?.photoURL != null
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(user!.photoURL!),
                    )
                  : const CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFF57D463),
                      child: Icon(Icons.person, size: 50, color: Color(0xFF001F3F)),
                    ),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? 'User',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF57D463)),
              ),
              const SizedBox(height: 32),
              _buildInfoTile('Email', user?.email ?? 'N/A'),
              const SizedBox(height: 16),
              _buildPasswordTile(),
              const SizedBox(height: 32),

              // Align buttons in a single Column with Expanded for equal width
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildButton(
                      icon: Icons.lock,
                      label: 'Change Password',
                      onPressed: () {
                        _showPasswordResetDialog();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildButton(
                      icon: Icons.credit_card,
                      label: 'Block Cards',
                      onPressed: _handleBlockCard,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildButton(
                icon: Icons.logout,
                label: 'Logout',
                onPressed: () async {
                  final authService = AuthService();
                  await authService.signout(context); // Pass the context here for navigation
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF011935),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF57D463))),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPasswordTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF011935),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Password', style: TextStyle(color: Color(0xFF57D463))),
          Row(
            children: [
              Text(
                _obscurePassword ? '•••••••••••••••' : 'password hidden',
                style: const TextStyle(color: Colors.white),
              ),
              IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF57D463),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: const Color(0xFF001F3F)),
      label: Text(label, style: const TextStyle(color: Color(0xFF001F3F))),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF57D463),
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Future<void> _handleBlockCard() async {
    const emergencyNumber = '1820';
    final phoneNumber = Uri.encodeFull(emergencyNumber);
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

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
  }

  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: const Text('Are you sure you want to reset your password?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                if (user?.email != null) {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No email found!')),
                  );
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}