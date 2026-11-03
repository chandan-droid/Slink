import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

/// Singleton Dio instance with JWT Bearer interceptor.
class DioClient {
  DioClient._();
  static final DioClient _instance = DioClient._();
  factory DioClient() => _instance;

  late final Dio _dio;
  final SecureStorage _storage = SecureStorage();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Prefer devToken when set (dev bypass), otherwise read from SecureStorage
          final token = AppConfig.devToken.isNotEmpty
              ? AppConfig.devToken
              : await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['ngrok-skip-browser-warning'] = 'true';
          AppLogger.info(
            'Request: ${options.method} ${options.uri}\n'
            'Headers: ${options.headers}\n'
            'Query: ${options.queryParameters}\n'
            'Body: ${options.data}',
            tag: 'HTTP',
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.info(
            'Response [${response.statusCode}]: ${response.requestOptions.method} ${response.requestOptions.uri}\n'
            'Body: ${response.data}',
            tag: 'HTTP',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.error(
            'Error [${error.response?.statusCode}]: ${error.requestOptions.method} ${error.requestOptions.uri}\n'
            'Message: ${error.message}\n'
            'Body: ${error.response?.data}',
            tag: 'HTTP',
            error: error,
          );
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio {
    assert(_initialized, 'DioClient must be initialized before use');
    return _dio;
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final dioClientProvider = Provider<DioClient>((ref) => DioClient());
