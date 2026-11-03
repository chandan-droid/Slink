import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../contacts/domain/entities/platform_user.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/repositories/search_repository.dart';

class SearchNotifier extends StateNotifier<AsyncValue<List<PlatformUser>>> {
  final SearchRepository _repo;
  Timer? _debounce;

  SearchNotifier(this._repo) : super(const AsyncValue.data([]));

  void search(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {   
      state = const AsyncValue.data([]);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      state = const AsyncValue.loading();
      try {
        final results = await _repo.searchUsers(query);
        if (mounted) state = AsyncValue.data(results);
      } catch (e, st) {
        if (mounted) state = AsyncValue.error(e, st);
      }
    });
  }

  void clear() {
    _debounce?.cancel();
    state = const AsyncValue.data([]);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider.autoDispose<SearchNotifier,
    AsyncValue<List<PlatformUser>>>((ref) {
  return SearchNotifier(ref.read(searchRepositoryProvider));
});

