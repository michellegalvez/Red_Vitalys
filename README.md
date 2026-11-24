# Red Vitalys

Prototipo navegable en Flutter para la Entrega 2 de Seminario en Ingeniería de Software · Universidad Icesi.

Es un build de depuración, solo de front-end: no tiene backend y todos los datos son simulados y viven en memoria. Al reiniciar la app, vuelven a su estado inicial.

## Qué es y qué problema atiende

Red Vitalys es una red de salud colombiana con seis clínicas de alta complejidad, cuarenta centros ambulatorios y una cadena de laboratorios. Sus sistemas de historia clínica no se comunican entre sí: hoy no se reconoce a un mismo paciente en distintas sedes ni se comparte su información a tiempo.

Esta app es el frontend para la Dirección Médica y el personal clínico. El acceso depende del rol, de la sede desde la que se ingresa y del propósito declarado en cada consulta, y cada acción queda registrada. El problema, los usuarios, los objetivos medibles y el alcance están en `docs/prd.md`.

## Qué cubre el prototipo

Cubre los 37 requisitos funcionales (23 specs, F-01 a F-23). Con el rol médico, el administrativo o el auditor se puede:

- **Todos los roles:** iniciar sesión en dos pasos (correo y contraseña, y luego la sede entre las asignadas), ver el perfil con lo que el rol puede hacer y cerrar sesión. La sesión se cierra tras 15 minutos sin uso y el inicio de sesión se bloquea 15 minutos tras 5 intentos fallidos.
- **Médico:** ver el inicio y los pacientes con alta reciente ordenados por riesgo de reingreso, buscar pacientes, declarar el propósito de la consulta, abrir la historia clínica unificada, ver el riesgo de reingreso con los factores que lo subieron o bajaron, registrar una atención y ver el tablero y el detalle de los indicadores.
- **Administrativo:** buscar pacientes y ver sus datos básicos (solo con el propósito *Revisión de calidad*), ver el tablero de indicadores y registrar la medición mensual de una sede. Si intenta algo que su rol no permite, ve el acceso denegado.
- **Auditor:** revisar la auditoría de accesos (quién, cuándo, a qué recurso, con qué resultado y propósito) y consultar el tablero y el detalle de los indicadores: reingreso a 30 días, tiempo de espera, adherencia a protocolos y eventos adversos evitables, por sede.

## Cómo ejecutarlo

Requisitos: Flutter con Dart 3.13 o superior (ver `pubspec.yaml`). Funciona en web (Chrome o Edge) y en Android 10 o superior.

```bash
flutter pub get
flutter run -d chrome     # en el navegador
flutter run               # en un emulador o un celular con Android 10+
flutter test              # corre las pruebas
```

## Configuración de Supabase

La entrega 3 conecta la app a Supabase (`supabase_flutter`). La URL y la publishable key **no están en el código** (AD-13): se pasan al compilar desde un archivo local.

1. Copia el ejemplo: `cp env.example.json env.json` (en Windows: `copy env.example.json env.json`).
2. Llena `env.json` con los valores de tu proyecto, en el panel de Supabase:

   | Variable | De dónde sale |
   |---|---|
   | `SUPABASE_URL` | *Settings → Data API*, «Project URL» (`https://<id>.supabase.co`) |
   | `SUPABASE_PUBLISHABLE_KEY` | *Settings → API Keys → Publishable key* (`sb_publishable_...`) |

3. Ejecuta pasando el archivo:

```bash
flutter run -d chrome --dart-define-from-file=env.json
flutter run --dart-define-from-file=env.json     # Android
flutter build web --dart-define-from-file=env.json
```

- `env.json` está en `.gitignore`: no lo subas. Solo se sube `env.example.json`, con los valores vacíos.
- **Nunca** pongas la secret key (`sb_secret_...`) en la app, en `env.json` ni en el repositorio.
- Sin `env.json` la app funciona igual, con los datos simulados, y la consola avisa «Supabase no está configurado». Con las llaves bien puestas dice «Supabase inicializado».
- Por ahora todos los datos siguen en memoria: la conexión está lista, pero ninguna pantalla lee de Supabase. La fuente de datos se elige en un solo punto, `lib/datos/fuente_de_datos.dart` (AD-02).

## Base de datos en Supabase

Los scripts están en `supabase/migraciones/`. Se corren en orden, una sola vez, en *SQL Editor → New query → Run* del proyecto (se pueden repetir sin dañar nada):

1. `001_base_y_auditoria.sql`: tablas comunes (`rol`, `sistema_origen`, `sede`, `usuario`, `usuario_sede`), la auditoría de solo agregar y leer, las políticas de acceso (RLS) y las sedes.
2. Crear los 4 correos de la tabla *Cuentas de prueba* en *Authentication → Users → Add user → Create new user*, con la contraseña `vitalys2026` y **Auto Confirm User** marcado.
3. `002_usuarios_de_prueba.sql`: carga esos usuarios con su rol y sus sedes. Debe terminar con `usuarios = 4` y `sedes_asignadas = 4`.

La auditoría (`evento_auditoria`) solo acepta agregar: un trigger rechaza editar o borrar, y la IP la pone la base. Si la app corre con `env.json`, los eventos se guardan ahí y el auditor los lee de Supabase; sin `env.json`, siguen en memoria.

> Temporal: mientras el inicio de sesión no use Supabase Auth, la app abre además una sesión en Supabase con el mismo correo y contraseña (`lib/repositorios/sesion_supabase.dart`).

## Cuentas de prueba

Son datos ficticios del prototipo; no corresponden a personas reales. La contraseña de todas las cuentas es `vitalys2026`. La fecha de «hoy» simulada es fija: el **6 de noviembre de 2026** (el último periodo cerrado de los indicadores es octubre).

| Correo | Nombre | Rol | Sedes asignadas |
|---|---|---|---|
| `camila.martinez@vitalys.co` | Dra. Camila Martínez | Médico | Clínica Vitalys Cali Norte, Centro Ambulatorio Cali Sur |
| `andres.ruiz@vitalys.co` | Andrés Felipe Ruiz | Administrativo | Clínica Vitalys Bogotá Usaquén |
| `marcela.ospina@vitalys.co` | Marcela Ospina | Auditor | Clínica Vitalys Cali Norte |
| `tomas.herrera@vitalys.co` | Dr. Tomás Herrera | Médico | Ninguna (caso de prueba: cuenta sin sedes asignadas, no puede entrar: ve «Su cuenta no tiene sedes asignadas») |

Los datos están en `lib/datos/datos_simulados.dart`.

## Estructura de lib/

```
lib/
├── main.dart            # arranca la app e inicializa Supabase (único punto)
├── config/              # entorno.dart: URL y publishable key de Supabase (--dart-define)
├── tema/                # colores, tema y breakpoint (900 px, contenido máx. 1200)
├── modelos/             # modelos.dart (sedes, usuarios, pacientes, propósitos, auditoría)
│                        # historia.dart (historia clínica, atenciones y factores del riesgo)
│                        # indicadores.dart (indicadores y mediciones)
├── datos/               # datos simulados: pacientes, eventos, historias y mediciones (hoy: 6 nov 2026)
│                        # fuente_de_datos.dart: el único punto que elige la fuente (hoy, memoria)
├── repositorios/        # auditoría: interfaz, versión en memoria y versión Supabase
├── reglas/              # reglas de negocio puras: umbral 70, bloqueo, relación, propósitos, permisos,
│                        # indicadores (promedio, marca, cambio y validar una medición) y búsqueda
├── formato/             # fechas, horas y búsqueda sin tildes (RNF-05)
├── widgets/             # componentes de la galería, cada uno una sola vez
├── pages/               # Pages: solo muestran y avisan con callbacks
└── screens/             # AppScreen: la Screen anfitriona con todo el estado (setState) y las rutas
```

## Reglas de arquitectura

- El estado de la app vive en la Screen anfitriona (`AppScreen`), con `setState`. No hay paquetes externos de estado ni de navegación.
- Las Pages no guardan datos de la app (solo lo que se está escribiendo en un formulario): muestran y avisan con callbacks.
- Los componentes de la galería se construyen una sola vez en `widgets/` y se reutilizan.
- Las reglas de negocio son funciones puras en `reglas/`, sin dependencias de Flutter.

## Cómo verificar

Antes de subir cambios:

```bash
dart format lib test
flutter analyze
flutter test
bash docs/verificar.sh    # coherencia entre PRD, requisitos, spine y specs (tarda cerca de 1,5 min; no modifica archivos)
```

## Documentos

La carpeta `docs/` guía el desarrollo (Spec Driven Development), en este orden:

- `docs/prd.md`: el PRD, con el problema, los usuarios, los objetivos medibles y el alcance.
- `docs/requisitos.md`: los requisitos funcionales (RF) y no funcionales (RNF).
- `docs/architectural_spine.md`: la architectural spine, con el stack, el diagrama y las invariantes.
- `docs/plans/`: un plan por funcionalidad o pieza técnica (cómo se construye), con el formato y el índice en `docs/plans/README.md`.
- `docs/tasks/`: las tareas de cada plan, con casilla y cómo se comprueba cada una (`docs/tasks/README.md`).
- `docs/specs/`: una spec funcional por funcionalidad, con el índice y el avance en `docs/specs/README.md` (incluye las excepciones del prototipo) y la crítica en `docs/specs/reporte.md`.

## Equipo

Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco y Samuel Cardoso Martinez.

Seminario en Ingeniería de Software · Universidad Icesi.
