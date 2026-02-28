import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message = 'حدث خطأ غير متوقع';

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final body = err.response?.data;
        final serverMessage = body is Map ? body['message'] as String? : null;

        switch (statusCode) {
          case 400:
            message = serverMessage ?? 'طلب غير صحيح';
            break;
          case 401:
            message = serverMessage ?? 'غير مصرح. يرجى تسجيل الدخول مرة أخرى';
            break;
          case 403:
            message = serverMessage ?? 'غير مسموح';
            break;
          case 404:
            message = serverMessage ?? 'غير موجود';
            break;
          case 500:
            message = serverMessage ?? 'خطأ في الخادم';
            break;
          default:
            message = serverMessage ?? 'حدث خطأ';
        }
        break;
      case DioExceptionType.cancel:
        message = 'تم إلغاء الطلب';
        break;
      case DioExceptionType.unknown:
        message = 'لا يوجد اتصال بالإنترنت';
        break;
      default:
        message = 'حدث خطأ غير متوقع';
    }

    final error = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: message,
    );

    handler.next(error);
  }
}
