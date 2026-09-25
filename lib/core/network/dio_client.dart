import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Builds the app-wide [Dio] instance (registered as a singleton in GetIt).
class DioClient {
  DioClient._();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false, // multipart bodies are huge — skip them
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }
    return dio;
  }

  /// Converts a [DioException] into a [ServerException] with an Arabic message.
  static ServerException mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ServerException('انتهت مهلة الاتصال بالخادم، حاول مرة أخرى');
      case DioExceptionType.connectionError:
        return const ServerException('تحقق من اتصالك بالإنترنت');
      case DioExceptionType.cancel:
        return const ServerException('تم إلغاء الطلب');
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        String? serverMsg;
        if (data is Map && data['error'] is Map) {
          serverMsg = (data['error'] as Map)['message']?.toString();
        }
        return ServerException(
          'خطأ من الخادم ($status)${serverMsg != null ? ': $serverMsg' : ''}',
          statusCode: status,
        );
      default:
        return ServerException('حدث خطأ في الشبكة: ${e.message ?? ''}');
    }
  }
}
