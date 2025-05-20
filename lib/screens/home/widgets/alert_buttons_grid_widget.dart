// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../../modules/utils/app_models.dart';
import './individual_alert_button.dart';

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

    final List<AlertType> alertTypesForGrid = [
      AlertType.fire,
      AlertType.crash,
      AlertType.theft,
      AlertType.dog,
    ];

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
                child: IndividualAlertButtonWidget(
                  alertType: alertTypesForGrid[0], // Fire
                  isSelected: selectedAlert == alertTypesForGrid[0],
                  onPressed: () => onAlertButtonPressed(alertTypesForGrid[0]),
                  // alertInfoMap is accessed within IndividualAlertButtonWidget
                ),
              ),
              const SizedBox(width: 12), // Spacing between buttons in a row.
              Expanded(
                child: IndividualAlertButtonWidget(
                  alertType: alertTypesForGrid[1], // Crash
                  isSelected: selectedAlert == alertTypesForGrid[1],
                  onPressed: () => onAlertButtonPressed(alertTypesForGrid[1]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Spacing between the two rows.
          // Second row of alert buttons.
          Row(
            children: [
              Expanded(
                child: IndividualAlertButtonWidget(
                  alertType: alertTypesForGrid[2], // Theft
                  isSelected: selectedAlert == alertTypesForGrid[2],
                  onPressed: () => onAlertButtonPressed(alertTypesForGrid[2]),
                ),
              ),
              const SizedBox(width: 12), // Spacing between buttons in a row.
              Expanded(
                child: IndividualAlertButtonWidget(
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
