// ignore_for_file: avoid_print

import 'package:permission_handler/permission_handler.dart' as perm_handler;

/// Service class to handle generic permission requests using the permission_handler package.
class PermissionService {
  /// Constructor for PermissionService.
  PermissionService() {
    print("PermissionService initialized.");
  }

  /// Requests a single specified permission.
  Future<bool> requestPermission(
    perm_handler.Permission permission, {
    bool openSettingsIfPermanentlyDenied = true,
  }) async {
    print("Requesting permission: ${permission.toString()}");
    var status = await permission.status;

    if (status.isGranted) {
      print("Permission ${permission.toString()} already granted.");
      return true;
    }

    if (status.isDenied || status.isRestricted || status.isLimited) {
      print(
          "Permission ${permission.toString()} is ${status.name}. Requesting...");
      status = await permission.request();
      if (status.isGranted) {
        print("Permission ${permission.toString()} granted after request.");
        return true;
      } else {
        print("Permission ${permission.toString()} denied after request.");
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
      print("Permission ${permission.toString()} is permanently denied.");
      if (openSettingsIfPermanentlyDenied) {
        print(
            "Attempting to open app settings for ${permission.toString()} permission...");
        await perm_handler.openAppSettings();
      }
    }
    return false;
  }

  /// Requests multiple permissions at once.
  Future<Map<perm_handler.Permission, perm_handler.PermissionStatus>>
      requestMultiplePermissions(
          List<perm_handler.Permission> permissions) async {
    if (permissions.isEmpty) {
      print("No permissions requested in requestMultiplePermissions.");
      return {};
    }
    print(
        "Requesting multiple permissions: ${permissions.map((p) => p.toString()).join(', ')}");
    Map<perm_handler.Permission, perm_handler.PermissionStatus> statuses =
        await permissions.request();

    statuses.forEach((permission, status) {
      print("Status for ${permission.toString()}: ${status.name}");
    });
    return statuses;
  }

  /// Checks the status of a single specified permission.

  Future<perm_handler.PermissionStatus> checkPermissionStatus(
      perm_handler.Permission permission) async {
    final status = await permission.status;
    print("Checked status for ${permission.toString()}: ${status.name}");
    return status;
  }
  /// Checks the status of multiple specified permissions.
  Future<bool> openAppSettings() async {
    print("Attempting to open app settings...");
    return await perm_handler.openAppSettings();
  }
}
