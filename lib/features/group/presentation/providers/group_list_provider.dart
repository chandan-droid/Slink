import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/entities/group.dart';

final groupListProvider = FutureProvider<List<Group>>((ref) {
  return ref.read(groupRepositoryProvider).getGroups();
});

