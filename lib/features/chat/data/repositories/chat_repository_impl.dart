import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_response.dart';

class ChatRepositoryImpl implements ChatRepository {
  final DioClient _dio;
  ChatRepositoryImpl(this._dio);

  @override
  Future<String> startChat(String recipientId) async {
    try {
      final res = await _dio.dio.post(
        '${AppConfig.startChatEndpoint}?recipientId=$recipientId',
      );
      return ChatResponse.fromJson(res.data as Map<String, dynamic>).chatId;
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getChatDetails(String chatId) async {
    try {
      final res = await _dio.dio.get('/api/chat/$chatId');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.read(dioClientProvider));
});
