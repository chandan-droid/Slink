import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/community.dart';
import '../../domain/repositories/community_repository.dart';
import '../models/community_dto.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final DioClient _dio;
  CommunityRepositoryImpl(this._dio);

  Community _toEntity(CommunityDto dto) {
    return Community(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      avatarUrl: dto.avatarUrl,
      ownerId: dto.ownerId,
      createdAt: dto.createdAt,
      isPublic: dto.isPublic,
      memberCount: dto.memberCount,
    );
  }

  @override
  Future<List<Community>> getCommunities() async {
    final res = await _dio.dio.get(AppConfig.communitiesEndpoint);
    return (res.data as List)
        .map((e) => _toEntity(CommunityDto.fromJson(e as Map<String, dynamic>)))
        .toList();
  }

  @override
  Future<Community> getCommunityById(String id) async {
    final res = await _dio.dio.get('${AppConfig.communitiesEndpoint}/$id');
    return _toEntity(CommunityDto.fromJson(res.data as Map<String, dynamic>));
  }

  @override
  Future<Community> createCommunity({
    required String name,
    String? description,
    String? avatarUrl,
  }) async {
    final res = await _dio.dio.post(
      AppConfig.communitiesEndpoint,
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
    return _toEntity(CommunityDto.fromJson(res.data as Map<String, dynamic>));
  }

  @override
  Future<void> joinCommunity(String id) async {
    await _dio.dio.post('${AppConfig.communitiesEndpoint}/$id/join');
  }

  @override
  Future<void> leaveCommunity(String id) async {
    await _dio.dio.post('${AppConfig.communitiesEndpoint}/$id/leave');
  }

  @override
  Future<String> startCommunityChat({
    required String communityId,
    String title = 'General',
  }) async {
    final res = await _dio.dio.post(
      AppConfig.startCommunityChatEndpoint,
      queryParameters: {'communityId': communityId, 'title': title},
    );
    return (res.data as Map<String, dynamic>)['chatId']?.toString() ?? '';
  }

  @override
  Future<List<Map<String, dynamic>>> getCommunityChats(String communityId) async {
    final res = await _dio.dio.get('${AppConfig.communitiesEndpoint}/$communityId/chats');
    return (res.data as List).map((e) => e as Map<String, dynamic>).toList();
  }

  @override
  Future<Map<String, dynamic>> createCommunityChat({
    required String communityId,
    required String title,
  }) async {
    final res = await _dio.dio.post(
      '${AppConfig.communitiesEndpoint}/$communityId/chats',
      queryParameters: {'title': title},
    );
    return res.data as Map<String, dynamic>;
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepositoryImpl(ref.read(dioClientProvider));
});

