import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../contacts/data/models/user_summary_dto.dart';
import '../../../contacts/domain/entities/platform_user.dart';
import '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final DioClient _dio;
  SearchRepositoryImpl(this._dio);

  @override
  Future<List<PlatformUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final res = await _dio.dio.get('/api/users', queryParameters: {'q': query});
    return (res.data as List)
        .map((e) {
          final dto = UserSummaryDto.fromJson(e as Map<String, dynamic>);
          return PlatformUser(
            id: dto.id,
            username: dto.username,
            phoneNumber: dto.phoneNumber,
            email: dto.email,
            onlineStatus: PlatformUser.parseStatus(dto.onlineStatus),
          );
        })
        .toList();
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(ref.read(dioClientProvider));
});

