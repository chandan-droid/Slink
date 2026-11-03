import '../entities/group.dart';

abstract class GroupRepository {
  Future<List<Group>> getGroups();
  Future<String> createGroup({
    required String title,
    required List<String> memberIds,
  });
  Future<void> addMember({
    required String chatId,
    required String userId,
  });
  Future<void> removeMember({
    required String chatId,
    required String userId,
  });
  Future<void> updateMemberRole({
    required String chatId,
    required String userId,
    required String role,
  });
}

