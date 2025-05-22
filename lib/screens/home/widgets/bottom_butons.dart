// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../../modules/utils/alerts.dart'; // For AlertType, AlertInfo, alertInfoMap
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

  // --- Size control variables ---
  // For Alert Button
  static const double buttonDiameterAlert = 62.0; // Total diameter of the alert button
  static const double imageSizeAlert = 34.0;      // Size of the image/icon inside the alert button

  // For Bot Button
  static const double buttonDiameterBot = 62.0;   // Total diameter of the bot button
  static const double imageSizeBot = 40.0;        // Size of the image/icon inside the bot button
  // --- End of Size control variables ---

  @override
  Widget build(BuildContext context) {
    // Get the AlertInfo for the dedicated emergency button
    final AlertInfo? emergencyAlertDetails = alertInfoMap[AlertType.emergency];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0), // Ensure this padding is enough for shadows
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Emergency Button (Left side)
          SizedBox(
            width: buttonDiameterAlert,
            height: buttonDiameterAlert,
            child: ElevatedButton(
              onPressed: onEmergencyPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: emergencyAlertDetails?.color ?? Colors.red.shade900,
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                elevation: 8,
                side: const BorderSide(color: Colors.white, width: 2),
              ),
              child: Center(
                child: SizedBox(
                  width: imageSizeAlert,
                  height: imageSizeAlert,
                  child: Image.asset(
                    emergencyAlertDetails?.iconPath ?? 'assets/images/alert.png',
                    height: imageSizeAlert,
                    width: imageSizeAlert,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print("Error loading emergency button icon: $error");
                      return Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: imageSizeAlert,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Phone Button (Center, Expanded)
          Expanded(
            child: ElevatedButton(
              onPressed: onPhonePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Chatbot Button (Right side)
          Stack(
            alignment: Alignment.topLeft,
            clipBehavior: Clip.none, // <--- *** KEY CHANGE: Allow shadow to draw outside Stack bounds ***
            children: [
              SizedBox(
                width: buttonDiameterBot,
                height: buttonDiameterBot,
                child: ElevatedButton(
                  onPressed: () {
                    print("Chatbot button tapped. Navigating to ChatBotScreen.");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ChatBotScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    elevation: 12, // Keep this for visual prominence on white
                    shadowColor: Colors.black.withOpacity(0.45), // Keep for darker shadow on white
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: imageSizeBot,
                      height: imageSizeBot,
                      child: Image.asset(
                        'assets/images/bot.png',
                        height: imageSizeBot,
                        width: imageSizeBot,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print("Error loading bot button icon: $error");
                          return Icon(
                            Icons.support_agent,
                            color: Colors.grey.shade700,
                            size: imageSizeBot,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -2,
                left: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble,
                    size: 18,
                    color: Color(0xFF57D463),
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