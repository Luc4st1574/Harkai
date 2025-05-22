// ignore_for_file: avoid_print

import 'package:google_maps_flutter/google_maps_flutter.dart' show BitmapDescriptor;
import 'alerts.dart'; 

/// Utility functions related to map display and operations.

double getMarkerHue(AlertType type) {
  switch (type) {
    case AlertType.fire:
      return BitmapDescriptor.hueOrange;
    case AlertType.crash:
      return BitmapDescriptor.hueBlue;
    case AlertType.theft:
      return BitmapDescriptor.hueViolet; // Changed from huePurple as it's not a direct constant
    case AlertType.dog:
      return BitmapDescriptor.hueGreen;
    case AlertType.emergency:
      return BitmapDescriptor.hueRed;
    case AlertType.none: 
      print("Warning: Unknown or 'none' AlertType encountered in getMarkerHue. Defaulting to red.");
      return BitmapDescriptor.hueRed;
  }
}
