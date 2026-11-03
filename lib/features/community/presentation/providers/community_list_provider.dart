import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/entities/community.dart';

final communityListProvider = FutureProvider<List<Community>>((ref) {
  return ref.read(communityRepositoryProvider).getCommunities();
});

