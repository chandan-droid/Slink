import '../entities/platform_user.dart';

abstract class ContactsRepository {
  Future<List<PlatformUser>> getUsers();
  Future<PlatformUser> getCurrentUser();
}

