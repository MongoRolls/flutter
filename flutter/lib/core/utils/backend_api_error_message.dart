import 'package:dio/dio.dart';

String backendApiErrorMessage(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;

    String? code;
    String? message;
    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        code = err['code'] as String?;
        message = err['message'] as String?;
      }
    }

    if (status == 401) {
      return '未登录或登录已过期，请稍后再试';
    }

    if (code == 'NOT_FOUND' && (message?.contains('短码') ?? false)) {
      return '该好友短码不存在，请核对后重试';
    }

    if (code == 'VALIDATION_ERROR' && (message?.contains('自己') ?? false)) {
      return message ?? '不能添加自己';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return '网络连接异常，请检查网络后重试';
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        break;
    }

    if (message != null && message.isNotEmpty) {
      return message;
    }
  }

  return '操作失败，请稍后重试';
}

