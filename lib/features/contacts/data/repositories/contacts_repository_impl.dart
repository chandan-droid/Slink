import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/platform_user.dart';
import '../../domain/repositories/contacts_repository.dart';
import '../models/user_summary_dto.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  final DioClient _dio;

  ContactsRepositoryImpl(this._dio);

  @override
  Future<List<PlatformUser>> getUsers() async {
    final res = await _dio.dio.get(AppConfig.usersEndpoint);
    final list = (res.data as List)
        .map((e) => UserSummaryDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return list
        .map((dto) => PlatformUser(
              id: dto.id,
              username: dto.username,
              phoneNumber: dto.phoneNumber,
              email: dto.email,
              onlineStatus: PlatformUser.parseStatus(dto.onlineStatus),
            ))
        .toList();
  }

  @override
  Future<PlatformUser> getCurrentUser() async {
    final res = await _dio.dio.get(AppConfig.currentUserEndpoint);
    final dto = UserSummaryDto.fromJson(res.data as Map<String, dynamic>);
    return PlatformUser(
      id: dto.id,
      username: dto.username,
      phoneNumber: dto.phoneNumber,
      email: dto.email,
      onlineStatus: PlatformUser.parseStatus(dto.onlineStatus),
    );
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return ContactsRepositoryImpl(ref.read(dioClientProvider));
});

