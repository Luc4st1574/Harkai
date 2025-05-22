// home/widgets/alert_buttons_widget.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../../modules/utils/alerts.dart'; // Only for AlertType enum

/// A widget that displays a grid of alert buttons.
class AlertButtonsGridWidget extends StatelessWidget {
  final AlertType selectedAlert;
  final Function(AlertType) onAlertButtonPressed;

  const AlertButtonsGridWidget({
    super.key,
    required this.selectedAlert,
    required this.onAlertButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Define the alert types for the grid directly here.
    final List<AlertType> alertTypesForGrid = [
      AlertType.fire,
      AlertType.crash,
      AlertType.theft,
      AlertType.dog,
    ];

    // Spacing for the grid
    const double gridSpacing = 12.0;

    return Padding(
      // Padding around the entire grid.
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // First row of alert buttons.
          Row(
            children: [
              Expanded(
                child: _IndividualAlertButton(
                  alertType: alertTypesForGrid[0], // Fire
                  isSelected: selectedAlert == alertTypesForGrid[0],
                  onPressed: () => onAlertButtonPressed(alertTypesForGrid[0]),
                ),
              ),
              const SizedBox(width: gridSpacing), // Spacing between buttons in a row.
              Expanded(
                child: _IndividualAlertButton(
                  alertType: alertTypesForGrid[1], // Crash
                  isSelected: selectedAlert == alertTypesForGrid[1],
                  onPressed: () => onAlertButtonPressed(alertTypesForGrid[1]),
                ),
              ),
            ],
          ),
          const SizedBox(height: gridSpacing), // Spacing between the two rows.
          // Second row of alert buttons.
          Row(
            children: [
              Expanded(
                child: _IndividualAlertButton(
                  alertType: alertTypesForGrid[2], // Theft
                  isSelected: selectedAlert == alertTypesForGrid[2],
                  onPressed: () => onAlertButtonPressed(alertTypesForGrid[2]),
                ),
              ),
              const SizedBox(width: gridSpacing), // Spacing between buttons in a row.
              Expanded(
                child: _IndividualAlertButton(
                  alertType: alertTypesForGrid[3], // Dog
                  isSelected: selectedAlert == alertTypesForGrid[3],
                  onPressed: () => onAlertButtonPressed(alertTypesForGrid[3]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// --- Individual Alert Button (Private to this file) ---
class _IndividualAlertButton extends StatelessWidget {
  final AlertType alertType;
  final bool isSelected;
  final VoidCallback onPressed;

  const _IndividualAlertButton({
    required this.alertType,
    required this.isSelected,
    required this.onPressed,
  });

  String _getButtonTitle() {
    // Titles are defined directly here for the buttons.
    switch (alertType) {
      case AlertType.fire:
        return 'Fire Alert';
      case AlertType.crash:
        return 'Crash Alert';
      case AlertType.theft:
        return 'Theft Alert';
      case AlertType.dog:
        return 'Dog Alert';
      default:
        return 'Alert'; // Fallback title
    }
  }

  Color _getButtonColor() {
    // Colors are defined directly here, matching the "before" image.
    // Ensure these colors match your desired theme.
    switch (alertType) {
      case AlertType.fire:
        return Colors.orange.shade700; // Example: A vibrant orange
      case AlertType.crash:
        return Colors.blue.shade700;   // Example: A clear blue
      case AlertType.theft:
        return Colors.purple.shade700; // Example: A distinct purple
      case AlertType.dog:
        return Colors.green.shade600;  // Example: A friendly green
      default:
        return Colors.grey; // Default color
    }
  }

  AssetImage _getButtonIcon() {
    // Icons are defined directly here.
    // Ensure these asset paths are correct and assets are in pubspec.yaml.
    // Also ensure the actual icon images are simple and will look good in white.
    String iconPath;
    switch (alertType) {
      case AlertType.fire:
        iconPath = 'assets/images/fire.png'; // Replace with your actual asset
        break;
      case AlertType.crash:
        iconPath = 'assets/images/car.png'; // Replace with your actual asset
        break;
      case AlertType.theft:
        iconPath = 'assets/images/theft.png'; // Replace with your actual asset
        break;
      case AlertType.dog:
        iconPath = 'assets/images/dog.png'; // Replace with your actual asset
        break;
      default:
        iconPath = 'assets/images/alert.png'; // Fallback icon
    }
    return AssetImage(iconPath);
  }

  @override
  Widget build(BuildContext context) {
    final String title = _getButtonTitle();
    final Color buttonColor = _getButtonColor();
    final AssetImage iconAsset = _getButtonIcon();

    // Define styles based on the "desired" image
    const double iconSize = 20.0; // Adjust to match desired image
    const double fontSize = 13.0; // Adjust to match desired image
    const FontWeight fontWeight = FontWeight.bold;
    const double buttonElevation = 5.0; // Consistent elevation for shadow
    const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 14, horizontal: 10); // Adjust for overall button size and internal spacing

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white, // For icon and text color
        shape: const StadiumBorder(),   // Pill shape
        padding: buttonPadding,
        elevation: isSelected ? buttonElevation + 2 : buttonElevation, // Slightly more elevation if selected
        side: isSelected
            ? const BorderSide(color: Colors.white, width: 2.0) // White border if selected
            : BorderSide.none,
        // You might not need minimumSize if padding and content define the size well.
        // If buttons are too small, you can add it back:
        // minimumSize: const Size(0, 48), // Example minimum height
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center content horizontally
        mainAxisSize: MainAxisSize.min, // Important for Row to not take excessive space if not Expanded
        children: [
          Image(
            image: iconAsset,
            height: iconSize,
            width: iconSize,
            color: Colors.white, // Ensure icon is white
            errorBuilder: (context, error, stackTrace) {
              print(
                  "Error loading icon asset for ${alertType.name} ('${iconAsset.assetName}'): $error");
              return Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: iconSize);
            },
          ),
          const SizedBox(width: 8), // Space between icon and text
          Flexible( // Use Flexible to allow text to wrap or ellipsis if too long
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1, // Prefer single line
            ),
          ),
        ],
      ),
    );
  }
}
