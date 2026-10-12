import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'app_exception.dart';

class FileService {
  /// Saves binary buffer data as a local file in downloads or app document directories.
  /// 
  /// - On Android: saves to standard public `/storage/emulated/0/Download/`.
  /// - On iOS: saves to application documents directory (visible in Files App).
  /// - Returns the saved filename.
  static Future<String> saveFileToDownloads(Uint8List bytes, String filename) async {
    Directory? targetDir;

    try {
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
        throw const AppException(
          title: "Download Notice",
          message: "Local file export is not supported in the web browser environment.",
          type: ErrorType.client,
        );
      }

      if (targetDir == null) {
        throw const AppException(
          title: "Storage Error",
          message: "Unable to locate a valid storage directory. Please check device permissions.",
          type: ErrorType.client,
        );
      }

      final String filePath = '${targetDir.path}/$filename';
      final File file = File(filePath);
      await file.writeAsBytes(bytes);
      return filename;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        title: "Download Error",
        message: "Unable to write presentation file to storage. Please check device permissions and free space.",
        type: ErrorType.client,
      );
    }
  }
}
