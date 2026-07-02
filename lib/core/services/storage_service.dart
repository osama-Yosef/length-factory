import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../errors/app_exceptions.dart';

/// Handles image upload to Firebase Storage.
/// Note: Image compression is disabled on Windows (flutter_image_compress
/// doesn't support Windows desktop). Compression is active on Android/iOS.
class StorageService {
  final FirebaseStorage _storage;
  static const _uuid = Uuid();

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads an image and returns its public download URL.
  Future<String> uploadImage({
    required File file,
    required String folder,
  }) async {
    try {
      // Compress only on mobile platforms (not Windows/Linux/macOS desktop)
      final uploadFile = Platform.isAndroid || Platform.isIOS
          ? await _compressMobile(file)
          : file;

      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('$folder/$fileName');

      final uploadTask = await ref.putFile(
        uploadFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException('فشل رفع الصورة: ${e.message}', code: e.code);
    }
  }

  Future<void> deleteImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {
      // Non-fatal: ignore if already deleted or invalid URL
    }
  }

  /// Compression placeholder for mobile — will be wired to
  /// flutter_image_compress when the Android build is enabled.
  Future<File> _compressMobile(File file) async {
    // TODO: add flutter_image_compress back to pubspec for Android builds
    // and implement compression here.
    return file;
  }
}
