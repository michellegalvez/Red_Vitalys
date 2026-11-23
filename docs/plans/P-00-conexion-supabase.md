---
id: P-00
titulo: Conexión con Supabase
version: 0.1.0
fecha: 2026-11-20
estado: hecho
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
specs: []
requisitos: []
invariantes: [AD-01, AD-02, AD-13]
tareas: T-00
---

# P-00 · Conexión con Supabase

## Objetivo

Dejar la app conectada a Supabase como base común para la entrega 3: el SDK instalado, las llaves fuera del código, Supabase inicializado en un solo punto y la elección de la fuente de datos en un solo punto. Al terminar, **ninguna pantalla ni dato cambia**: todo sigue en memoria y quien no tenga las llaves sigue trabajando igual que en la entrega 2.

Es un plan transversal: no implementa una spec ni un RF, habilita los planes de funcionalidad (P-01 en adelante).

## Enfoque técnico

- **Paquete.** `supabase_flutter`, el único que la spine permite (Stack, AD-01). No se agrega nada más.
- **Llaves.** Se leen con `String.fromEnvironment` y se pasan al compilar con `--dart-define-from-file=env.json` (AD-13). Así no hay que cargar archivos en tiempo de ejecución ni declarar assets, y funciona igual en web y en Android. `env.json` va en `.gitignore`; se sube `env.example.json` con los valores vacíos. Solo va la publishable key; la secret key nunca entra a la app ni al repositorio.
- **Sin llaves, la app sigue.** Si falta una de las dos variables, no se inicializa Supabase, la fuente es la de memoria y la consola avisa con un mensaje. Lo mismo si la inicialización falla (URL inválida, sin red): se captura, se avisa y se sigue en memoria. Así `flutter test` y las ramas de los compañeros no se rompen.
- **Un punto de inicialización.** `main()` es el único que llama a `Supabase.initialize`, antes de `runApp`.
- **Un punto de elección de fuente (AD-02).** Una función `elegirFuenteDeDatos` decide de dónde salen los datos. Hoy siempre devuelve `DatosSimulados.porDefecto`, aunque Supabase esté listo. Cuando existan los repositorios con Supabase, el cambio es solo ahí.

Alternativas descartadas:

| Alternativa | Por qué no |
|---|---|
| Paquete `flutter_dotenv` | Agrega un paquete (la spine solo permite uno) y mete el `.env` como asset, que se publica con la app. |
| Llaves escritas en un archivo `.dart` ignorado por git | Rompe la compilación de quien no lo tenga y es fácil de subir por error. |
| Inicializar Supabase dentro de `AppScreen` | Las Pages y la Screen no deben conocer el SDK (AD-03); y se inicializaría más de una vez en las pruebas. |

## Componentes

| Pieza | Ruta | Responsabilidad | |
|---|---|---|---|
| SDK | `pubspec.yaml` | Agregar `supabase_flutter` | cambia |
| Entorno | `lib/config/entorno.dart` | Lee `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` y dice si están completas | nuevo |
| Fuente de datos | `lib/datos/fuente_de_datos.dart` | `elegirFuenteDeDatos`: el único punto que decide memoria o Supabase | nuevo |
| Arranque | `lib/main.dart` | `main` asíncrono: inicializa Supabase si hay llaves y arma la app con la fuente elegida | cambia |
| Llaves de ejemplo | `env.example.json` | Las dos variables con valor vacío | nuevo |
| Ignorados | `.gitignore` | Agrega `env.json` | cambia |
| Guía | `README.md` | Sección de configuración y ejecución con las variables | cambia |
| Estructura | `AGENTS.md` | Agrega `config/` a la estructura de `lib/` y las carpetas `docs/plans` y `docs/tasks` | cambia |
| Pruebas | `test/entorno_test.dart`, `test/fuente_de_datos_test.dart` | Sin variables, no está configurado y la fuente es la de memoria | nuevo |

`env.json` tiene este contenido (los valores salen de *Project Settings → API* en Supabase):

```json
{
  "SUPABASE_URL": "",
  "SUPABASE_PUBLISHABLE_KEY": ""
}
```

## Cambios

**Se agrega:** el SDK, `lib/config/`, `fuente_de_datos.dart`, `env.example.json`, las dos pruebas y la documentación.

**Se modifica:** `main.dart` (pasa a `async` y `RedVitalysApp` recibe la fuente de datos), `pubspec.yaml`, `.gitignore`, `README.md` y `AGENTS.md`.

**No se toca:** pantallas (`pages/`, `screens/`), `widgets/`, `reglas/`, `modelos/`, `datos/datos_simulados.dart`, las pruebas existentes ni `docs/specs/`. `AppScreen` sigue recibiendo `DatosSimulados`.

## Riesgos y decisiones abiertas

- **Aún no hay interfaces de repositorio.** AD-02 las pide, pero hoy `AppScreen` recibe `DatosSimulados` directamente. Este plan solo fija el punto de elección; las interfaces y la implementación con Supabase son de los planes de funcionalidad. *Decisión abierta:* quién define las interfaces y en qué plan (propuesta: P-01).
- **`supabase_flutter` en las pruebas.** Importarlo en `main.dart` no debe afectar a `flutter test`, que no ejecuta `main`. Se confirma en T-00.5.
- **Versión del SDK.** Se fija la última estable compatible con Dart ^3.13.4 al correr `flutter pub add`; si no resuelve, se avisa antes de bajar la versión de Dart.
- **Sesión persistida.** `supabase_flutter` guarda la sesión en el dispositivo. Aún no se usa Auth, pero el plan de inicio de sesión debe decidir cómo convive con el cierre por inactividad (AD-14).
- **RLS** sigue diferido, como dice la spine. Mientras tanto, la publishable key da acceso a lo que las tablas permitan: no cargar datos reales.

## Verificación

- `flutter pub get`, `dart format lib test`, `flutter analyze` y `flutter test` pasan igual que antes.
- Sin `env.json` (`flutter run -d chrome`): la app abre con los datos simulados y la consola dice que Supabase no está configurado.
- Con `env.json` lleno (`flutter run -d chrome --dart-define-from-file=env.json`): la app abre con los datos simulados y la consola dice que Supabase se inicializó.
- `git status` no muestra `env.json` y `git ls-files` incluye `env.example.json`.
- No aparece ninguna URL ni llave en el código (`git grep -e vnmnxhqzunzivpcyhfqe -e sb_publishable_E` sin resultados).
- `bash docs/verificar.sh` sigue sin fallas.

## Historial

- 0.1.0 · 2026-11-20 · Primera versión.
