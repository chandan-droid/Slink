import '../entities/community.dart';

abstract class CommunityRepository {
  Future<List<Community>> getCommunities();
  Future<Community> getCommunityById(String id);
  Future<Community> createCommunity({
    required String name,
    String? description,
    String? avatarUrl,
  });
  Future<void> joinCommunity(String id);
  Future<void> leaveCommunity(String id);
  Future<String> startCommunityChat({
    required String communityId,
    String title,
  });
  Future<List<Map<String, dynamic>>> getCommunityChats(String communityId);
  Future<Map<String, dynamic>> createCommunityChat({
    required String communityId,
    required String title,
  });
}

