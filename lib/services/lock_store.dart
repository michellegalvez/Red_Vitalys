import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// What the device remembers about failed sign-ins (F-14).
typedef LockState = ({int failures, DateTime? lockedSince});

/// Keeps the sign-in lock of this device, so a reload does not clear it (F-14).
abstract interface class LockStore {
  Future<LockState?> read();

  Future<void> write(LockState state);
}

/// Keeps the lock while the app is open, for the tests.
class LockMemory implements LockStore {
  LockState? _state;

  @override
  Future<LockState?> read() async => _state;

  @override
  Future<void> write(LockState state) async => _state = state;
}

/// Keeps the lock in the device storage that the Supabase SDK already uses:
/// the browser's localStorage on the web and the app preferences on Android.
class LockDevice implements LockStore {
  final _storage = SharedPreferencesLocalStorage(
    persistSessionKey: 'red_vitalys_bloqueo',
  );
  Future<void>? _ready;

  Future<void> _init() {
    // If opening the storage fails, the next call tries again.
    return _ready ??= _storage.initialize().catchError((Object error) {
      _ready = null;
      throw error;
    });
  }

  @override
  Future<LockState?> read() async {
    await _init();
    final text = await _storage.accessToken();
    if (text == null) return null;
    final data = jsonDecode(text) as Map<String, dynamic>;
    final since = data['lockedSince'] as String?;
    return (
      failures: data['failures'] as int? ?? 0,
      lockedSince: since == null ? null : DateTime.parse(since),
    );
  }

  @override
  Future<void> write(LockState state) async {
    await _init();
    if (state.failures == 0 && state.lockedSince == null) {
      await _storage.removePersistedSession();
      return;
    }
    await _storage.persistSession(
      jsonEncode({
        'failures': state.failures,
        'lockedSince': state.lockedSince?.toIso8601String(),
      }),
    );
  }
}
