import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  final DioClient _dio;
  GroupRepositoryImpl(this._dio);

  @override
  Future<List<Group>> getGroups() async {
    // Return empty list as the backend manages lists locally / via Websocket.
    return [];
  }

  @override
  Future<String> createGroup({
    required String title,
    required List<String> memberIds,
  }) async {
    final res = await _dio.dio.post(
      '/api/chat/group/create',
      data: {
        'title': title,
        'memberIds': memberIds,
      },
    );
    // Parse the 'id' field from the returned Chat entity JSON
    return (res.data as Map<String, dynamic>)['id']?.toString() ?? '';
  }

  @override
  Future<void> addMember({
    required String chatId,
    required String userId,
  }) async {
    await _dio.dio.post(
      '/api/chat/$chatId/members',
      queryParameters: {'userId': userId},
    );
  }

  @override
  Future<void> removeMember({
    required String chatId,
    required String userId,
  }) async {
    await _dio.dio.delete('/api/chat/$chatId/members/$userId');
  }

  @override
  Future<void> updateMemberRole({
    required String chatId,
    required String userId,
    required String role,
  }) async {
    await _dio.dio.put(
      '/api/chat/$chatId/members/$userId/role',
      queryParameters: {'role': role.toUpperCase()},
    );
  }
}

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepositoryImpl(ref.read(dioClientProvider));
});
