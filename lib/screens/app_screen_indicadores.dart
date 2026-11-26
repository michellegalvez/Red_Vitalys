part of 'app_screen.dart';

extension _IndicadoresRemotos on _AppScreenState {
  void _cerrarSesionDeAuth() {
    final auth = widget.auth;
    if (auth?.isRemote != true) return;
    unawaited(
      auth!.signOut().catchError((Object error) {
        debugPrint('No se pudo cerrar la sesión de Auth: $error');
      }),
    );
  }
}
