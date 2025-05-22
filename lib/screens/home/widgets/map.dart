// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../modules/utils/alerts.dart'; // For AlertType

/// A widget that displays the Google Map with markers and user interaction.
class MapDisplayWidget extends StatelessWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Set<Marker> markers;
  final AlertType selectedAlert;
  final Function(LatLng) onMapTappedWithAlert;
  final Function(GoogleMapController)? onMapCreated;

  /// Creates a [MapDisplayWidget].
  const MapDisplayWidget({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.markers,
    required this.selectedAlert,
    required this.onMapTappedWithAlert,
    this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    // New, larger height factor for the map and loading state
    const double mapHeightFactor = 0.40; // Changed from 0.35 to 0.55

    // Show a loading indicator if initial coordinates are not yet available.
    if (initialLatitude == null || initialLongitude == null) {
      return SizedBox(
        height: screenHeight * mapHeightFactor, // Use the new factor
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Loading map data..."),
            ],
          ),
        ),
      );
    }

    return Container(
      // Padding around the map container.
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Container(
        // Decoration for shadow and rounded corners.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.2 * 255).toInt()),
              spreadRadius: 3,
              blurRadius: 5,
              offset: const Offset(0, 2), // Shadow position.
            ),
          ],
        ),
        // ClipRRect to ensure the map itself has rounded corners.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: SizedBox(
            // Define the map's height relative to the screen height.
            height: screenHeight * mapHeightFactor, // Use the new factor
            width: double.infinity,
            child: GoogleMap(
              // A key can help Flutter identify and manage the widget's state correctly.
              key: const ValueKey("google_map_main_display"),
              initialCameraPosition: CameraPosition(
                target: LatLng(initialLatitude!, initialLongitude!),
                zoom: 16.0, // Default zoom level.
              ),
              markers: markers,
              mapType: MapType.terrain,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,

              // Explicitly enable all gesture recognizers for better interactivity.
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,

              // Callback when the map is created and controller is available.
              onMapCreated: (GoogleMapController controller) {
                debugPrint('GoogleMap created successfully in MapDisplayWidget.');
                onMapCreated?.call(controller);
              },
              // Callback when the map is tapped.
              onTap: (LatLng position) {
                if (selectedAlert != AlertType.none) {
                  onMapTappedWithAlert(position);
                } else {
                  debugPrint(
                      "Map tapped, but no alert type is selected. Ignoring tap for marker placement.");
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}