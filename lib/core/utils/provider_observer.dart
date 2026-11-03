import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logger.dart';

/// Riverpod Observer to log provider state transitions and updates.
class AppProviderObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    final name = provider.name ?? provider.runtimeType.toString();
    AppLogger.debug(
      'Provider initialized: $name\n'
      '   Initial Value: $value',
      tag: 'Riverpod',
    );
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    final name = provider.name ?? provider.runtimeType.toString();
    // Prevent excessive logging spam if value hasn't changed or is a status/stream subscription mapping
    if (previousValue == newValue) return;

    AppLogger.debug(
      'Provider state change: $name\n'
      '   Old: $previousValue\n'
      '   New: $newValue',
      tag: 'Riverpod',
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    final name = provider.name ?? provider.runtimeType.toString();
    AppLogger.debug(
      'Provider disposed: $name',
      tag: 'Riverpod',
    );
  }
}
