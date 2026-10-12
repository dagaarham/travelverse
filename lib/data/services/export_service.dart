import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

import 'dart:io' show File;

/// Writes exported text to a file in the app's documents folder and opens the
/// Android share sheet so the user can save or send it.
class ExportService {
  Future<String> saveAndShare({required String fileName, required String content, required String mimeType}) async {
    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(utf8.encode(content), mimeType: mimeType, name: fileName)],
          fileNameOverrides: [fileName],
          downloadFallbackEnabled: true,
        ),
      );
      return fileName;
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(content, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        subject: fileName,
      ),
    );
    return file.path;
  }
}
