import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

class ImageHelper {
  static Future<File?> pickAndCompressImage({ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 85);

    if (image == null) return null;

    final dir = await getTemporaryDirectory();
    final targetPath = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      image.path,
      targetPath,
      quality: 85,
    );

    return compressedFile != null ? File(compressedFile.path) : null;
  }

  static Future<File?> compressVideo(File file) async {
    final info = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
    );
    return info?.file != null ? File(info!.file!.path) : null;
  }

  static Future<Uint8List?> compressImageBytes(Uint8List bytes, {int quality = 85}) async {
    return await FlutterImageCompress.compressWithList(
      bytes,
      quality: quality,
    );
  }

  static Future<void> cancelCompression() async {
    await VideoCompress.cancelCompression();
  }

  static void dispose() {
    VideoCompress.dispose();
  }
}
