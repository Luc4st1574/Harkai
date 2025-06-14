// lib/core/services/background_tasks.dart
import 'package:background_fetch/background_fetch.dart';
import 'package:harkai/core/services/location_service.dart';
import 'package:harkai/core/managers/notification_manager.dart';
import 'package:harkai/features/home/utils/incidences.dart';
import 'package:harkai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class BackgroundTasks {
    //
    static Future<void> onBackgroundFetch(String taskId) async {
        await performBackgroundTask();
        BackgroundFetch.finish(taskId);
    }

    //
    static Future<void> performBackgroundTask() async {
        final locationService = LocationService();
        final firestoreService = FirestoreService();
        final localizations = await _getAppLocalizations(); // Helper to get localizations
        final notificationManager = NotificationManager(
            locationService: locationService,
            firestoreService: firestoreService,
            localizations: localizations,
        );

        final position = await locationService.getInitialPosition();
        if (position.success && position.data != null) {
            final incidents = await firestoreService.getIncidencesStream().first;
            await notificationManager.checkForNearbyIncidents(position.data!, incidents);
        }
    }

    //
    static Future<AppLocalizations> _getAppLocalizations() async {
        return lookupAppLocalizations(const Locale('es')); 
    }

    //
    static void configureBackgroundFetch() {
        BackgroundFetch.configure(
            BackgroundFetchConfig(
                minimumFetchInterval: 15, // Fetch interval in minutes
                stopOnTerminate: false,
                enableHeadless: true,
                startOnBoot: true,
                requiredNetworkType: NetworkType.ANY,
            ),
            onBackgroundFetch,
            (String taskId) async { // <-- Task timeout callback
                BackgroundFetch.finish(taskId);
            },
        );
    }
}