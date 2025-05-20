// ignore_for_file: avoid_print

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_models.dart'; // For AlertType and AlertInfo

/// A data class to represent a heat point retrieved from Firestore.
/// This simplifies handling marker data within the app.
class HeatPointData {
  final String id;
  final double latitude;
  final double longitude;
  final AlertType type;
  final String description;
  final Timestamp timestamp; // Keep as Timestamp for potential future use

  HeatPointData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.description,
    required this.timestamp,
  });

  /// Factory constructor to create a HeatPointData instance from a Firestore document.
  factory HeatPointData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HeatPointData(
      id: doc.id,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      type: AlertType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AlertType.none, // Default if type is unknown or missing
      ),
      description: data['description'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(), // Provide a default if null
    );
  }

  @override
  String toString() {
    return 'HeatPointData(id: $id, lat: $latitude, lng: $longitude, type: ${type.name}, desc: "$description")';
  }
}


/// Service class to manage interactions with the Firestore 'HeatPoints' collection.
class FirestoreService {
  final CollectionReference _heatPointsCollection =
      FirebaseFirestore.instance.collection('HeatPoints');

  /// Constructor for FirestoreService.
  FirestoreService() {
    print("FirestoreService initialized.");
  }

  /// Adds a new heat point (marker) to the Firestore collection.
  Future<bool> addHeatPoint({
    required AlertType type,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    if (type == AlertType.none) {
      print('Error: Cannot add a heat point with AlertType.none');
      return false;
    }
    try {
      print(
          'Adding heat point: Lat=$latitude, Lng=$longitude, Type=${type.name}, Description=${description ?? ""}');
      await _heatPointsCollection.add({
        'latitude': latitude,
        'longitude': longitude,
        'type': type.name, // Store the enum name as a string
        'description': description ?? '',
        'timestamp': FieldValue.serverTimestamp(), // Use server-side timestamp
      });
      print('Heat point successfully added to Firestore.');
      return true;
    } catch (e) {
      print('Error adding heat point to Firestore: $e');
      return false;
    }
  }

  /// Provides a stream of [HeatPointData] from the Firestore collection.
  Stream<List<HeatPointData>> getHeatPointsStream() {
    print("Setting up heat points stream from Firestore...");
    return _heatPointsCollection
        .orderBy('timestamp', descending: true) // Optional: order by timestamp
        .snapshots()
        .map((snapshot) {
      print(
          "Firestore snapshot received with ${snapshot.docs.length} documents for heat points.");
      return snapshot.docs.map((doc) {
        try {
          return HeatPointData.fromFirestore(doc);
        } catch (e) {
          print("Error parsing heat point document ${doc.id}: $e. Skipping this document.");
          return null; // Return null for problematic documents
        }
      }).whereType<HeatPointData>().toList(); // Filter out nulls
    }).handleError((error) {
      print("Error in heat points stream: $error");
      // Optionally, rethrow or return an empty list or a stream error event
      return <HeatPointData>[];
    });
  }

  /// Removes heat points from Firestore that are older than a specified duration.
  Future<int> removeExpiredHeatPoints(
      {Duration expiryDuration = const Duration(hours: 1)}) async {
    final DateTime cutoffTime = DateTime.now().subtract(expiryDuration);
    final Timestamp cutoffTimestamp = Timestamp.fromDate(cutoffTime);
    int deletedCount = 0;

    print(
        "Attempting to remove heat points older than: $cutoffTime (Timestamp: ${cutoffTimestamp.seconds})");

    try {
      final QuerySnapshot querySnapshot = await _heatPointsCollection
          .where('timestamp', isLessThan: cutoffTimestamp)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("No expired heat points found to remove.");
        return 0;
      }

      print(
          "Found ${querySnapshot.docs.length} expired heat points to remove.");


      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in querySnapshot.docs) {
        print('Marking expired heat point for deletion: ${doc.id}');
        batch.delete(doc.reference);
        deletedCount++;
        // Firestore limits batches to 500 operations.
        // If you expect more, you'll need to commit in chunks.
        if (deletedCount % 499 == 0 && deletedCount > 0) { // Commit just before hitting 500
            await batch.commit();
            print("Committed batch of $deletedCount deletions.");
            batch = FirebaseFirestore.instance.batch(); // Start a new batch
        }
      }
      if (deletedCount > 0 && (deletedCount % 499 != 0 || querySnapshot.docs.length < 499) ) {
          // Commit any remaining operations in the batch
          await batch.commit();
          print("Committed final batch of deletions. Total deleted: $deletedCount");
      }


      print('$deletedCount expired heat point(s) successfully removed.');
      return deletedCount;
    } catch (e) {
      print('Error removing expired heat points: $e');
      return 0; // Return 0 on error
    }
  }
}

