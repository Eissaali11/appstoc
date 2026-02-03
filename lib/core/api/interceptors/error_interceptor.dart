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
        switch (statusCode) {
          case 400:
            message = 'طلب غير صحيح';
            break;
          case 401:
            message = 'غير مصرح. يرجى تسجيل الدخول مرة أخرى';
            break;
          case 403:
            message = 'غير مسموح';
            break;
          case 404:
            message = 'غير موجود';
            break;
          case 500:
            message = 'خطأ في الخادم';
            break;
          default:
            message = err.response?.data?['message'] ?? 'حدث خطأ';
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
