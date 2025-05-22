// modules/utils/app_models.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart'; // For Color

/// Enum representing the different types of alerts the user can create or see.
enum AlertType {
  fire,
  crash,
  theft,
  dog,
  emergency, // For the dedicated emergency button and potentially other emergency contexts
  none,
}

/// Class holding display information and emergency contact details for each alert type.
class AlertInfo {
  final String title;
  final String emergencyNumber;
  final Color?
      color;
  final String?
      iconPath;

  /// Constructor for AlertInfo.
  AlertInfo({
    required this.title,
    required this.emergencyNumber,
    this.color,
    this.iconPath,
  });
}

// Global map to easily access AlertInfo for a given AlertType.
final Map<AlertType, AlertInfo> alertInfoMap = {
  AlertType.fire: AlertInfo(
    title: 'Fire Alert',
    emergencyNumber: '(044) 226495',
    color: Colors.orange, 
    iconPath: 'assets/images/fire.png',
  ),
  AlertType.crash: AlertInfo(
    title: 'Crash Alert',
    emergencyNumber: '(044) 484242',
    color: Colors.blue,
    iconPath: 'assets/images/car.png',
  ),
  AlertType.theft: AlertInfo(
    title: 'Theft Alert',
    emergencyNumber: '(044) 250664',
    color: Colors.purple,
    iconPath: 'assets/images/theft.png',
  ),
  AlertType.dog: AlertInfo(
    title: 'Dog Alert',
    emergencyNumber: '913684363',
    color: Colors.green,
    iconPath: 'assets/images/dog.png',
  ),
  AlertType.emergency: AlertInfo(
    title: 'Emergency',
    emergencyNumber: '911',
    color: Colors.red.shade900, 
    iconPath: 'assets/images/alert.png'
  ),
};

/// Utility function to safely get [AlertInfo] from the [alertInfoMap].
AlertInfo? getAlertInfo(AlertType type) {
  if (type == AlertType.none) return null;
  return alertInfoMap[type];
}