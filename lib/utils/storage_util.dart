import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageUtil {
  /// Checks if storage permission is already granted without requesting.
  static Future<bool> isPermissionGranted() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;
    if (await Permission.storage.isGranted) return true;
    return false;
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
      // Fallback if permissions denied permanently
      await Hive.initFlutter();
    }

    await Hive.openBox('collections');
    await Hive.openBox('screenshots');
    final settingsBox = await Hive.openBox('settings');
    await Hive.openBox('template_discovery');

    // Record the first launch time of the app so we can compute template newness
    if (!settingsBox.containsKey('app_first_launch_time')) {
      await settingsBox.put('app_first_launch_time', DateTime.now().millisecondsSinceEpoch);
    }
  }
}
