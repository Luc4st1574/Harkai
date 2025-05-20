// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../../modules/utils/app_models.dart';

/// A widget representing an individual alert button (e.g., for Fire, Crash, etc.).

class IndividualAlertButtonWidget extends StatelessWidget {
  /// The type of alert this button represents.
  final AlertType alertType;
  /// Whether this button is currently selected.
  final bool isSelected;
  /// Callback function triggered when the button is pressed.
  final VoidCallback onPressed;

  /// Creates an [IndividualAlertButtonWidget].
  const IndividualAlertButtonWidget({
    super.key,
    required this.alertType,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final AlertInfo? alertDetails = getAlertInfo(alertType);

    if (alertDetails == null) {
      print(
          "Warning: No AlertInfo found for AlertType.${alertType.name} in IndividualAlertButtonWidget. Rendering an empty container.");
      return const SizedBox.shrink(); // Or some placeholder widget
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: alertDetails.color, // Button background color from AlertInfo.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Rounded corners.
        ),
        padding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: 10), // Padding inside the button.
        // Apply a white border if the button is selected.
        side: isSelected
            ? const BorderSide(color: Colors.white, width: 2.5)
            : BorderSide.none,
        elevation: isSelected ? 4 : 2, // Slightly more elevation when selected
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Display the icon for the alert.
          Image.asset(
            alertDetails.iconPath, // Icon path from AlertInfo.
            height: 22, // Icon height.
            width: 22, // Icon width.
            color: Colors.white, // Tint icon to white for better contrast
            errorBuilder: (context, error, stackTrace) {
              // Fallback in case the icon asset fails to load.
              print(
                  "Error loading icon asset '${alertDetails.iconPath}': $error");
              return const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 22);
            },
          ),
          const SizedBox(width: 8), // Spacing between icon and text.
          // Display the title of the alert.
          Flexible( // Use Flexible to prevent text overflow
            child: Text(
              alertDetails.title, // Title from AlertInfo.
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13, // Adjusted for better fit
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis, // Handle long text
            ),
          ),
        ],
      ),
    );
  }
}
