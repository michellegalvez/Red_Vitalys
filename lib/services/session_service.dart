import 'dart:async';

import 'package:red_vitalys/reglas/reglas.dart';

/// Counts failed sign-ins, locks the device and closes an idle session (AD-14).
class SessionService {
  int _failures = 0;
  DateTime? _lockedSince;
  Timer? _timer;
  void Function()? _onTimeout;

  int get failures => _failures;

  bool isLocked(DateTime now) {
    final since = _lockedSince;
    if (since == null) return false;
    if (now.isBefore(since.add(duracionBloqueo))) return true;
    _lockedSince = null;
    _failures = 0;
    return false;
  }

  bool registerFailure(DateTime now) {
    if (isLocked(now)) return true;
    _failures++;
    if (_failures < intentosParaBloqueo) return false;
    _lockedSince = now;
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
