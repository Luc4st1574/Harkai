// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../modules/utils/app_models.dart'; // For AlertType

/// A widget that displays the Google Map with markers and user interaction.
class MapDisplayWidget extends StatelessWidget {
  /// The initial latitude for the map's camera.
  final double? initialLatitude;
  /// The initial longitude for the map's camera.
  final double? initialLongitude;
  /// A set of markers to display on the map.
  final Set<Marker> markers;
  /// The currently selected alert type. If not [AlertType.none], tapping the map
  final AlertType selectedAlert;
  /// Callback function triggered when the map is tapped and an [AlertType]
  final Function(LatLng) onMapTappedWithAlert;
  /// Optional callback function that is called when the map is created.
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
    // Show a loading indicator if initial coordinates are not yet available.
    if (initialLatitude == null || initialLongitude == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.35, // Consistent height
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

    // Get the available screen height for responsive map height.
    final double screenHeight = MediaQuery.of(context).size.height;

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
            height: screenHeight * 0.35, // You can adjust this percentage.
            width: double.infinity,
            child: GoogleMap(
              // A key can help Flutter identify and manage the widget's state correctly.
              key: const ValueKey("google_map_main_display"),
              initialCameraPosition: CameraPosition(
                target: LatLng(initialLatitude!, initialLongitude!),
                zoom: 16.0, // Default zoom level.
              ),
              markers: markers, // Set of markers to display.
              mapType: MapType.terrain, // Type of map tiles to display.
              myLocationEnabled: true, // Show the user's current location blue dot.
              myLocationButtonEnabled: true, // Show the button to center map on user's location.

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
