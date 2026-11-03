import '../../../contacts/domain/entities/platform_user.dart';

abstract class SearchRepository {
  Future<List<PlatformUser>> searchUsers(String query);
}

