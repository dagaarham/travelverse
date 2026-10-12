import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Shows a photo stored on the device (a file path on Android, a blob URL
/// on web).
class LocalPhoto extends StatelessWidget {
  const LocalPhoto({super.key, required this.path, this.height, this.width, this.radius = 12, this.fit = BoxFit.cover});

  final String path;
  final double? height;
  final double? width;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget broken(BuildContext c, Object e, StackTrace? s) => Container(
      height: height,
      width: width,
      color: Colors.grey.shade200,
      child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade500),
    );
    final image = kIsWeb
        ? Image.network(path, height: height, width: width, fit: fit, errorBuilder: broken)
        : Image.file(File(path), height: height, width: width, fit: fit, errorBuilder: broken);
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}
