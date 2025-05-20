// ignore_for_file: avoid_print

import 'package:flutter/material.dart'; // For Color

/// Enum representing the different types of alerts the user can create or see.
enum AlertType {
  fire,
  crash,
  theft,
  dog,
  emergency,
  none,
}

/// Class holding display information and emergency contact details for each alert type.
class AlertInfo {
  final String title;
  final Color color;
  final String iconPath;
  final String emergencyNumber; 

  /// Constructor for AlertInfo.
  AlertInfo({
    required this.title,
    required this.color,
    required this.iconPath,
    required this.emergencyNumber,
  });
}

// Global map to easily access AlertInfo for a given AlertType.
// This is used throughout the app to get details like color, title, icon, and emergency number.
final Map<AlertType, AlertInfo> alertInfoMap = {
  AlertType.fire: AlertInfo(
    title: 'Fire Alert',
    color: Colors.orange,
    iconPath: 'assets/images/fire.png', // Ensure this asset exists
    emergencyNumber: '(044) 226495', // Example number
  ),
  AlertType.crash: AlertInfo(
    title: 'Crash Alert',
    color: Colors.blue,
    iconPath: 'assets/images/car.png', // Ensure this asset exists
    emergencyNumber: '(044) 484242', // Example number
  ),
  AlertType.theft: AlertInfo(
    title: 'Theft Alert',
    color: Colors.purple,
    iconPath: 'assets/images/theft.png', // Ensure this asset exists
    emergencyNumber: '(044) 250664', // Example number
  ),
  AlertType.dog: AlertInfo(
    title: 'Dog Alert',
    color: Colors.green,
    iconPath: 'assets/images/dog.png', // Ensure this asset exists
    emergencyNumber: '913684363', // Example number
  ),
  AlertType.emergency: AlertInfo(
    title: 'Emergency Alert',
    color: Colors.red.shade900,
    iconPath: 'assets/images/alert.png', // Ensure this asset exists
    emergencyNumber: '911', // Standard emergency number
  ),
};

/// Utility function to safely get [AlertInfo] from the [alertInfoMap].
AlertInfo? getAlertInfo(AlertType type) {
  if (type == AlertType.none) return null;
  return alertInfoMap[type];
}
