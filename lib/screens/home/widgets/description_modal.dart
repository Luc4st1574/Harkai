// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../../modules/utils/alerts.dart';

/// Displays a modal dialog for the user to input a description.
Future<String?> showDescriptionInputDialog({
  required BuildContext context,
  required AlertType alertType,
}) async {
  String? description; // To hold the text entered by the user.
  final TextEditingController controller = TextEditingController();
  final AlertInfo? alertDetails = getAlertInfo(alertType);

  // Fallback color if alertDetails is null (e.g., for AlertType.none)
  final Color modalColor = alertDetails?.color ?? Colors.blueGrey;

  return await showDialog<String?>(
    context: context,
    barrierDismissible: false, // User must explicitly cancel or save.
    builder: (BuildContext dialogContext) {
      return Material(
        color: Colors.transparent, // Makes the background behind the dialog transparent.
        child: Center(
          // Center the dialog on the screen.
          child: SingleChildScrollView(
            // Ensures the dialog content is scrollable if it overflows (e.g., on small screens or when keyboard is up).
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(dialogContext).size.width * 0.05),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 500, // Max width for larger screens
                minWidth: MediaQuery.of(dialogContext).size.width *
                    0.8, // Min width relative to screen
              ),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: const Color(0xFF001F3F), // Dark background for the dialog.
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.3 * 255).toInt()),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: modalColor, width: 1.5), // Border with alert color
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Column takes minimum vertical space.
                children: [
                  // Modal Title
                  Text(
                    'Add Description (Optional)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: modalColor, // Use the alert-specific color.
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Row containing Cancel icon, TextField, and Send icon.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Cancel Icon Button
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent, size: 28),
                        tooltip: 'Cancel',
                        onPressed: () {
                          print("Description dialog cancelled.");
                          Navigator.pop(dialogContext, null); // Close dialog, return null.
                        },
                      ),
                      const SizedBox(width: 8),

                      // Description TextField
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true, // Automatically focus the text field.
                          style: const TextStyle(color: Colors.white),
                          cursorColor: modalColor, // Cursor color matches alert theme.
                          maxLines: 3, // Allow multi-line input.
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Enter a brief description...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: const Color(0xFF002B55), // Slightly lighter than dialog background
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                color: modalColor.withAlpha((0.7 * 255).toInt()),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                color: modalColor.withAlpha((0.7 * 255).toInt()),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                color: modalColor, // Use the alert-specific color for focus.
                                width: 2.0,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            description = value; // Update description as user types.
                          },
                          onSubmitted: (value) {
                            // Optionally submit on enter key
                            print("Description submitted via keyboard: $value");
                            Navigator.pop(dialogContext, value.trim().isNotEmpty ? value.trim() : null);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Send Icon Button
                      IconButton(
                        icon: Icon(Icons.send, color: modalColor, size: 28),
                        tooltip: 'Save Description',
                        onPressed: () {
                          final String? finalDescription =
                              description?.trim().isNotEmpty ?? false
                                  ? description?.trim()
                                  : null;
                          print("Description dialog saved with: $finalDescription");
                          Navigator.pop(dialogContext, finalDescription); // Close dialog, return description.
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
