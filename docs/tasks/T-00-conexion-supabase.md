---
id: T-00
titulo: Tareas de la conexión con Supabase
version: 0.1.0
fecha: 2026-11-20
plan: P-00
estado: hecho
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
---

# T-00 · Conexión con Supabase

Plan: [P-00](../plans/P-00-conexion-supabase.md)

## Tareas

- [x] **T-00.1** · Agregar `supabase_flutter` al proyecto.
  - Toca: `pubspec.yaml`, `pubspec.lock`
  - Se comprueba: `flutter pub get` termina sin errores y `supabase_flutter` es el único paquete nuevo en `dependencies`.

- [x] **T-00.2** · Crear `lib/config/entorno.dart` con `supabaseUrl`, `supabasePublishableKey` y `configurado` (verdadero solo si ambas tienen valor).
  - Toca: `lib/config/entorno.dart`, `test/entorno_test.dart`
  - Se comprueba: `flutter test test/entorno_test.dart` pasa; sin `--dart-define`, `Entorno.configurado` es falso.

- [x] **T-00.3** · Dejar las llaves fuera del repositorio: ignorar `env.json` y subir `env.example.json` con los valores vacíos.
  - Toca: `.gitignore`, `env.example.json`
  - Se comprueba: crear un `env.json` de prueba y `git status` no lo lista; `git ls-files env.example.json` sí lo lista y sus dos valores son `""`.

- [x] **T-00.4** · Crear `lib/datos/fuente_de_datos.dart` con `elegirFuenteDeDatos`, que hoy siempre devuelve `DatosSimulados.porDefecto`.
  - Toca: `lib/datos/fuente_de_datos.dart`, `test/fuente_de_datos_test.dart`
  - Se comprueba: `flutter test test/fuente_de_datos_test.dart` pasa con Supabase listo y sin listo; en ambos casos devuelve los datos simulados.

- [x] **T-00.5** · Volver `main` asíncrono: inicializar Supabase una sola vez si `Entorno.configurado`, avisar en la consola si faltan las variables o si la inicialización falla, y pasar la fuente elegida a `RedVitalysApp`.
  - Toca: `lib/main.dart`
  - Se comprueba: `flutter run -d chrome` sin `env.json` abre la app y la consola dice que Supabase no está configurado; con `--dart-define-from-file=env.json` dice que se inicializó. En ambos casos las pantallas se ven igual, y `flutter test` sigue en verde.

- [x] **T-00.6** · Documentar la configuración y la ejecución en el README, con las variables de entorno.
  - Toca: `README.md`
  - Se comprueba: una persona que no conoce el proyecto copia `env.example.json` a `env.json`, lo llena y corre el comando del README sin preguntar nada.

- [x] **T-00.7** · Actualizar `AGENTS.md` con `config/`, `docs/plans/` y `docs/tasks/`, y registrar `supabase_flutter` como la única dependencia externa.
  - Toca: `AGENTS.md`
  - Se comprueba: la estructura de `lib/` de `AGENTS.md` coincide con las carpetas reales (`ls lib`).

- [x] **T-00.8** · Verificación final del plan.
  - Se comprueba: `dart format lib test` sin cambios, `flutter analyze` sin avisos, `flutter test` en verde, `bash docs/verificar.sh` sin fallas y `git grep -e vnmnxhqzunzivpcyhfqe -e sb_publishable_E` sin resultados (ni la URL real ni la llave están en el repo). Al pasar todo, el plan P-00 y este archivo pasan a `hecho`.
