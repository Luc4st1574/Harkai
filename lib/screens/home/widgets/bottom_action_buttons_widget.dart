// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../../modules/utils/app_models.dart'; // For AlertType, AlertInfo, alertInfoMap
import '../../chatbot.dart'; // For ChatBotScreen

/// A widget that displays the main action buttons at the bottom of the screen.
class BottomActionButtonsWidget extends StatelessWidget {
  final String currentServiceName;
  final VoidCallback onEmergencyPressed;
  final VoidCallback onPhonePressed;

  /// Creates a [BottomActionButtonsWidget].
  const BottomActionButtonsWidget({
    super.key,
    required this.currentServiceName,
    required this.onEmergencyPressed,
    required this.onPhonePressed,
  });

  @override
  Widget build(BuildContext context) {
    // Get the AlertInfo for the dedicated emergency button
    final AlertInfo? emergencyAlertDetails = alertInfoMap[AlertType.emergency];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0), // Added more bottom padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Emergency Button (Left side)
          ElevatedButton(
            onPressed: onEmergencyPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: emergencyAlertDetails?.color ?? Colors.red.shade900,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16), // Adjusted padding
              elevation: 8,
              side: const BorderSide(color: Colors.white, width: 2),
            ),
            child: Image.asset(
              emergencyAlertDetails?.iconPath ?? 'assets/images/alert.png', // Fallback path
              height: 30, // Adjusted size
              width: 30,  // Adjusted size
              errorBuilder: (context, error, stackTrace) {
                print("Error loading emergency button icon: $error");
                return const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30);
              },
            ),
          ),
          const SizedBox(width: 12),

          // Phone Button (Center, Expanded)
          Expanded(
            child: ElevatedButton(
              onPressed: onPhonePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A), // Dark blue color
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      currentServiceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14, // Good readable size
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis, // Handle long service names
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          Stack(
            alignment: Alignment.topLeft, // Align the chat bubble to the top-left of the main button
            children: [
              ElevatedButton(
                onPressed: () {
                  print("Chatbot button tapped. Navigating to ChatBotScreen.");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChatBotScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // White background
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(10), // Padding for the main bot image
                  elevation: 8,
                ),
                child: Image.asset(
                  'assets/images/bot.png', // Ensure this asset exists
                  height: 36, // Adjusted size
                  width: 36,  // Adjusted size
                  errorBuilder: (context, error, stackTrace) {
                    print("Error loading bot button icon: $error");
                    return Icon(Icons.support_agent, color: Colors.grey.shade700, size: 36);
                  },
                ),
              ),
              // Positioned chat bubble icon
              Positioned(
                top: -2, // Adjust for desired overlap
                left: -2, // Adjust for desired overlap
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white, // Background for the small icon
                    shape: BoxShape.circle,
                    boxShadow: [ // Optional: add a slight shadow to the bubble too
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0,1)
                      )
                    ]
                  ),
                  child: const Icon(
                    Icons.chat_bubble, // Using a built-in icon
                    size: 18, // Size of the chat bubble icon
                    color: Color(0xFF57D463), // Green color for the chat icon
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
