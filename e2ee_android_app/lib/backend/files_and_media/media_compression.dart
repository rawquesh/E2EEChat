import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';

class MediaCompression {
  static Future<Uint8List?> compressImage(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 85, // Suggestion: 80-90% quality
    );
    return result;
  }

  static Future<MediaInfo?> compressVideo(File file) async {
    // Suggestion: Medium quality provides a good balance of size and quality.
    final info = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false, // It's safer to not delete the original file
    );
    return info;
  }
}
