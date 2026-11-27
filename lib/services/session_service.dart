import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/services/lock_store.dart';

/// Counts failed sign-ins, locks the device and closes an idle session (AD-14).
class SessionService {
  SessionService({LockStore? store}) : _store = store ?? LockMemory();

  final LockStore _store;
  int _failures = 0;
  DateTime? _lockedSince;
  Timer? _timer;
  void Function()? _onTimeout;

  int get failures => _failures;

  /// Reads what the device kept, so a lock survives a reload (F-14). Only a
  /// lock is kept: loose failures are not, so they never expire into one. A
  /// lock that started here meanwhile is not overwritten.
  Future<void> restore() async {
    try {
      final state = await _store.read();
      final since = state?.lockedSince;
      if (since == null || _lockedSince != null) return;
      _lockedSince = since;
      _failures = intentosParaBloqueo;
    } catch (error) {
      debugPrint('Could not read the sign-in lock: $error');
    }
  }

  void _save() {
    unawaited(
      _store.write((failures: _failures, lockedSince: _lockedSince)).catchError(
        (Object error) {
          debugPrint('Could not save the sign-in lock: $error');
        },
      ),
    );
  }

  bool isLocked(DateTime now) {
    final since = _lockedSince;
    if (since == null) return false;
    if (now.isBefore(since.add(duracionBloqueo))) return true;
    _lockedSince = null;
    _failures = 0;
    _save();
    return false;
  }

  bool registerFailure(DateTime now) {
    if (isLocked(now)) return true;
    _failures++;
    if (_failures < intentosParaBloqueo) return false;
    _lockedSince = now;
    _save();
    return true;
  }

  void registerSuccess() => _failures = 0;

  void startInactivityTimer(void Function() onTimeout) {
    _onTimeout = onTimeout;
    _restartTimer();
  }

  void registerActivity() {
    if (_onTimeout == null) return;
    _restartTimer();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _onTimeout = null;
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer(limiteInactividad, () {
      final onTimeout = _onTimeout;
      stop();
      onTimeout?.call();
    });
  }
}
