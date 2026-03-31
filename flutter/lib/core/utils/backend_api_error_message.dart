import 'package:dio/dio.dart';

({String? code, String? message}) _parseErrorBody(DioException error) {
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
  return (code: code, message: message);
}

String backendApiErrorMessage(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final parsed = _parseErrorBody(error);
    final code = parsed.code;
    final message = parsed.message;

    if (status == 401) {
      return '未登录或登录已过期，请稍后再试';
    }

    if (status == 429 || code == 'TOO_MANY_REQUESTS') {
      return '请求过于频繁，请稍后再试';
    }

    if (code == 'NOT_FOUND' && (message?.contains('短码') ?? false)) {
      return '该好友短码不存在，请让对方核对 6 位短码后重试';
    }

    if (code == 'VALIDATION_ERROR' && (message?.contains('自己') ?? false)) {
      return message ?? '不能添加自己';
    }

    if (code == 'VALIDATION_ERROR' &&
        (message?.contains('query.code') ?? false) &&
        (message?.contains('6 character') ?? false)) {
      return '好友短码须为 6 位（字母 A–Z，数字 2–9，不含 0/1）';
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

/// GET /api/care/friend-lookup 专用（区分「不存在」与网络问题）。
String careLookupFriendCodeErrorMessage(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final parsed = _parseErrorBody(error);
    final code = parsed.code;
    if (status == 404 || code == 'NOT_FOUND') {
      return '该好友短码不存在，请让对方核对 6 位短码后重试';
    }
    if (status == 400 && code == 'VALIDATION_ERROR' && parsed.message != null) {
      return parsed.message!;
    }
    if (status == 429 || code == 'TOO_MANY_REQUESTS') {
      return '查询过于频繁，请一分钟后再试';
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return '网络不稳定，请稍后重试';
      default:
        break;
    }
    if (parsed.message != null && parsed.message!.isNotEmpty) {
      return parsed.message!;
    }
  }
  return backendApiErrorMessage(error);
}

/// POST /api/care/contacts 专用（创建关怀关系）。
String careCreateContactErrorMessage(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final parsed = _parseErrorBody(error);
    final code = parsed.code;
    final message = parsed.message;
    if (status == 400 && code == 'VALIDATION_ERROR' && message != null) {
      return message;
    }
    if (status == 404 || code == 'NOT_FOUND') {
      return '对方账号不可用，请稍后再试';
    }
    if (status == 409 || code == 'CONFLICT') {
      return message ?? '与服务器数据冲突，请下拉刷新后重试';
    }
    if (status == 429 || code == 'TOO_MANY_REQUESTS') {
      return '请求过于频繁，请稍后再试';
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return '网络不稳定，添加未完成，请重试';
      default:
        break;
    }
    if (message != null && message.isNotEmpty) {
      return message;
    }
  }
  return backendApiErrorMessage(error);
}

