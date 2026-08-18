import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/fcm_service.dart';
import '../../utils/storage_util.dart';

/// Represents an individual app permission with extensible metadata and request handlers.
class AppPermissionItem {
  const AppPermissionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isRequired,
    required this.checkGranted,
    required this.requestPermission,
    required this.checkPermanentlyDenied,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isRequired;
  final Future<bool> Function() checkGranted;
  final Future<bool> Function() requestPermission;
  final Future<bool> Function() checkPermanentlyDenied;
}

/// Central registry of all app permissions.
/// Adding a new permission in the future (e.g. Camera, Photos, Biometrics)
/// only requires appending an [AppPermissionItem] to [items].
class AppPermissions {
  static final List<AppPermissionItem> items = [
    // 1. Storage & Files Permission
    AppPermissionItem(
      id: 'storage',
      title: 'Storage & Media',
      description:
          'Save your high-res exports to your gallery and access mockup screenshot assets on your device.',
      icon: LucideIcons.hardDrive,
      isRequired: true,
      checkGranted: () async {
        return await StorageUtil.isPermissionGranted();
      },
      requestPermission: () async {
        if (Platform.isAndroid) {
          final status = await Permission.storage.request();
          if (status.isGranted) {
            await StorageUtil.initHiveWithPermissions();
            return true;
          }
          final manageStatus = await Permission.manageExternalStorage.request();
          if (manageStatus.isGranted) {
            await StorageUtil.initHiveWithPermissions();
            return true;
          }
          return false;
        }
        return true;
      },
      checkPermanentlyDenied: () async {
        if (!Platform.isAndroid) return false;
        return await Permission.storage.isPermanentlyDenied ||
            await Permission.manageExternalStorage.isPermanentlyDenied;
      },
    ),

    // 2. Push Notifications Permission
    AppPermissionItem(
      id: 'notifications',
      title: 'Push Notifications',
      description:
          'Get instantly notified when new curated screenshot templates, devices, and design packs are released.',
      icon: LucideIcons.bellRing,
      isRequired: false,
      checkGranted: () async {
        return await FCMService.isNotificationPermissionGranted();
      },
      requestPermission: () async {
        return await FCMService.requestNotificationPermission();
      },
      checkPermanentlyDenied: () async {
        final status = await Permission.notification.status;
        return status.isPermanentlyDenied;
      },
    ),
  ];

  /// Checks if all required permissions have been granted.
  static Future<bool> areRequiredPermissionsGranted() async {
    for (final item in items) {
      if (item.isRequired) {
        final granted = await item.checkGranted();
        if (!granted) return false;
      }
    }
    return true;
  }

  /// Checks all permissions and returns a map of ID -> isGranted.
  static Future<Map<String, bool>> checkAllStatuses() async {
    final results = <String, bool>{};
    for (final item in items) {
      results[item.id] = await item.checkGranted();
    }
    return results;
  }

  /// Requests all permissions sequentially.
  static Future<Map<String, bool>> requestAll() async {
    final results = <String, bool>{};
    for (final item in items) {
      final isAlreadyGranted = await item.checkGranted();
      if (isAlreadyGranted) {
        results[item.id] = true;
      } else {
        results[item.id] = await item.requestPermission();
      }
    }
    return results;
  }
}
