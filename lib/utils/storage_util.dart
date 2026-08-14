import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageUtil {
  static bool? _hasSeenOnboardingCache;

  /// Checks if storage permission is already granted without requesting.
  static Future<bool> isPermissionGranted() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;
    if (await Permission.storage.isGranted) return true;
    return false;
  }

  /// Returns whether the user has completed onboarding.
  /// Checks memory cache, open Hive settings box, internal persistent marker, and public marker.
  static Future<bool> hasSeenOnboarding() async {
    if (_hasSeenOnboardingCache == true) return true;

    if (Hive.isBoxOpen('settings')) {
      final val = Hive.box('settings').get('hasSeenOnboarding', defaultValue: false);
      if (val == true) {
        _hasSeenOnboardingCache = true;
        return true;
      }
    }

    try {
      // Check internal app documents directory marker
      final internalDir = await getApplicationDocumentsDirectory();
      final markerFile = File('${internalDir.path}/.onboarding_done');
      if (await markerFile.exists()) {
        _hasSeenOnboardingCache = true;
        return true;
      }

      // Check public directory marker if available
      final publicBase = await getPublicDirectoryPath(request: false);
      if (publicBase != null) {
        final publicMarker = File('$publicBase/.onboarding_done');
        if (await publicMarker.exists()) {
          _hasSeenOnboardingCache = true;
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  /// Synchronous check for route redirects
  static bool hasSeenOnboardingSync() {
    if (_hasSeenOnboardingCache == true) return true;
    if (Hive.isBoxOpen('settings')) {
      final val = Hive.box('settings').get('hasSeenOnboarding', defaultValue: false);
      if (val == true) {
        _hasSeenOnboardingCache = true;
        return true;
      }
    }
    return false;
  }

  /// Sets onboarding completed across all storage layers (Hive, internal marker, public marker)
  static Future<void> setHasSeenOnboarding(bool value) async {
    _hasSeenOnboardingCache = value;

    if (Hive.isBoxOpen('settings')) {
      await Hive.box('settings').put('hasSeenOnboarding', value);
    }

    try {
      final internalDir = await getApplicationDocumentsDirectory();
      final markerFile = File('${internalDir.path}/.onboarding_done');
      if (value) {
        if (!await markerFile.exists()) {
          await markerFile.writeAsString('1');
        }
      } else {
        if (await markerFile.exists()) {
          await markerFile.delete();
        }
      }

      final publicBase = await getPublicDirectoryPath(request: false);
      if (publicBase != null) {
        final publicMarker = File('$publicBase/.onboarding_done');
        if (value) {
          if (!await publicMarker.exists()) {
            await publicMarker.writeAsString('1');
          }
        } else {
          if (await publicMarker.exists()) {
            await publicMarker.delete();
          }
        }
      }
    } catch (_) {}
  }

  /// Requests necessary permissions and returns the public directory path
  /// for storing database and images resilient to app data clears.
  static Future<String?> getPublicDirectoryPath({bool request = true}) async {
    // Request permissions
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        // Android 11+
      } else if (await Permission.storage.isGranted) {
        // Android 10 and below
      } else {
        if (!request) return null; // Don't prompt if not requested
        // Request storage first
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          // If storage is denied or restricted, try manageExternalStorage on Android 11+
          var manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            return null; // Permissions denied
          }
        }
      }
    }

    // Define the public path
    final dir = Directory('/storage/emulated/0/Documents/Aperlo');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Returns the specific path for the Hive Database
  static Future<String?> getDatabasePath({bool request = true}) async {
    final basePath = await getPublicDirectoryPath(request: request);
    if (basePath == null) return null;

    final dbDir = Directory('$basePath/db');
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    return dbDir.path;
  }

  /// Returns the specific path for storing images (thumbnails/screenshots)
  static Future<String?> getImagesPath() async {
    final basePath = await getPublicDirectoryPath();
    if (basePath == null) return null;

    final imgDir = Directory('$basePath/images');
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }
    
    // Prevent images from appearing in Android gallery
    final noMediaFile = File('${imgDir.path}/.nomedia');
    if (!await noMediaFile.exists()) {
      await noMediaFile.create();
    }
    
    return imgDir.path;
  }

  static Future<void> initHiveWithPermissions({bool request = true}) async {
    // Check if onboarding was already seen before re-init
    final wasOnboardingSeen = await hasSeenOnboarding();

    // Cache existing open box contents before closing if switching paths
    Map<dynamic, dynamic>? cachedSettings;
    if (Hive.isBoxOpen('settings')) {
      cachedSettings = Map<dynamic, dynamic>.from(Hive.box('settings').toMap());
    }

    final dbPath = await getDatabasePath(request: request);

    // If we are re-initializing (e.g. after granting permissions), we must close
    // the currently open boxes so they can be opened from the new path.
    if (Hive.isBoxOpen('collections')) await Hive.box('collections').close();
    if (Hive.isBoxOpen('screenshots')) await Hive.box('screenshots').close();
    if (Hive.isBoxOpen('settings')) await Hive.box('settings').close();
    if (Hive.isBoxOpen('template_discovery')) await Hive.box('template_discovery').close();

    if (dbPath != null) {
      Hive.init(dbPath);
    } else {
      // Fallback if permissions denied
      await Hive.initFlutter();
    }

    await Hive.openBox('collections');
    await Hive.openBox('screenshots');
    final settingsBox = await Hive.openBox('settings');
    await Hive.openBox('template_discovery');

    // Restore cached settings if new box doesn't have them
    if (cachedSettings != null) {
      for (final entry in cachedSettings.entries) {
        if (!settingsBox.containsKey(entry.key)) {
          await settingsBox.put(entry.key, entry.value);
        }
      }
    }

    // Ensure hasSeenOnboarding is strictly persisted in this box
    if (wasOnboardingSeen) {
      await settingsBox.put('hasSeenOnboarding', true);
      _hasSeenOnboardingCache = true;
    }

    // Record the first launch time of the app so we can compute template newness
    if (!settingsBox.containsKey('app_first_launch_time')) {
      await settingsBox.put('app_first_launch_time', DateTime.now().millisecondsSinceEpoch);
    }
  }
}
