import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/contacts_repository_impl.dart';
import '../../domain/entities/platform_user.dart';

/// Raw list of all platform users — presence overlay happens in the UI layer.
final usersProvider = FutureProvider<List<PlatformUser>>((ref) async {
  return ref.read(contactsRepositoryProvider).getUsers();
});

/// Current authenticated user's profile.
final currentUserProvider = FutureProvider<PlatformUser>((ref) {
  return ref.read(contactsRepositoryProvider).getCurrentUser();
});

