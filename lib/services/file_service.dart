import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileService {
  /// Saves binary buffer data as a local file in downloads or app document directories.
  /// 
  /// - On Android: saves to standard public `/storage/emulated/0/Download/`.
  /// - On iOS: saves to application documents directory (visible in Files App).
  /// - Returns absolute path of the written file.
  static Future<String> saveFileToDownloads(Uint8List bytes, String filename) async {
    Directory? targetDir;

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        // Standard public downloads directory path on Android
        final publicDownloadDir = Directory('/storage/emulated/0/Download');
        if (await publicDownloadDir.exists()) {
          targetDir = publicDownloadDir;
        } else {
          // Fallback to app external storage directories if public path is locked or unavailable
          targetDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // App Documents directory on iOS (visible via Files App when UIFileSharingEnabled is configured)
        targetDir = await getApplicationDocumentsDirectory();
      } else {
        // Fallback for Windows/macOS/Linux
        targetDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }
    } else {
      // Fallback for Flutter web
      throw UnsupportedError("File saving to local file system is not supported on Web target");
    }

    if (targetDir == null) {
      throw Exception("Could not find a valid directory to write presentation file.");
    }

    final String filePath = '${targetDir.path}/$filename';
    final File file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }
}
