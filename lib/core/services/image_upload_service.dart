import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../network/dio_client.dart';

/// Abstraction so data sources don't depend on a concrete image host.
abstract class ImageUploadService {
  /// Uploads the local file at [filePath] and returns its public HTTPS URL.
  Future<String> uploadImage({required String filePath, required String folder});
}

/// Uploads images to Cloudinary through its REST API using [Dio]
/// (unsigned upload preset — no API secret is ever stored in the app).
class CloudinaryImageUploadService implements ImageUploadService {
  final Dio _dio;

  CloudinaryImageUploadService(this._dio);

  @override
  Future<String> uploadImage({
    required String filePath,
    required String folder,
  }) async {
    if (CloudinaryConfig.cloudName == 'YOUR_CLOUD_NAME') {
      throw const ServerException(
        'لم يتم إعداد Cloudinary بعد — ضع اسم الـ Cloud في CloudinaryConfig',
      );
    }
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'upload_preset': CloudinaryConfig.uploadPreset,
        'folder': '${CloudinaryConfig.rootFolder}/$folder',
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '${CloudinaryConfig.baseUrl}/${CloudinaryConfig.cloudName}/image/upload',
        data: form,
      );

      final url = response.data?['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        throw const ServerException('فشل رفع الصورة: لم يتم استلام رابط الصورة');
      }
      return url;
    } on DioException catch (e) {
      throw DioClient.mapError(e);
    }
  }
}
