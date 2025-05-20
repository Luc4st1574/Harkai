// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

/// A widget that displays location information prominently.
class LocationInfoWidget extends StatelessWidget {
  final String locationText;

  const LocationInfoWidget({
    super.key,
    required this.locationText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Consistent padding as in the original _buildLocationInfo method
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            locationText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF57D463),
            ),
          ),
          const SizedBox(height: 4),

          const Text(
            'This is happening in your area',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF57D463),
            ),
          ),
        ],
      ),
    );
  }
}
