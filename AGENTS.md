# AGENTS.md · Red Vitalys

## Qué es la app

Red Vitalys es una red de salud colombiana con seis clínicas de alta complejidad, cuarenta centros ambulatorios y una cadena de laboratorios cuyos sistemas de historia clínica no se comunican entre sí. Hoy no se reconoce a un mismo paciente en distintas sedes ni se comparte su información a tiempo.

La app es el frontend para la Dirección Médica y el personal clínico. Con ella el usuario puede:

- Iniciar sesión con correo y contraseña, eligiendo la sede desde la que ingresa entre las que tiene asignadas.
- Consultar la historia clínica unificada de un paciente.
- Registrar una atención de un paciente.
- Ver el tablero de indicadores de calidad: reingreso hospitalario a 30 días, tiempo de espera, adherencia a protocolos clínicos y eventos adversos evitables, por sede.
- Registrar las mediciones mensuales de los indicadores de una sede.
- Ver el riesgo de reingreso de un paciente y la explicación de qué factores lo subieron o bajaron.
- Ver su perfil y lo que puede hacer según su rol (médico, administrativo, auditor).
- Revisar la auditoría de accesos: quién accedió, cuándo, a qué recurso, con qué resultado y con qué propósito.

El acceso depende del rol, de la sede desde la que se ingresa y del propósito declarado en cada consulta, y cada ingreso, consulta o registro sobre un paciente, medición y acción denegada queda registrado.

Equipo: Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco y Samuel Cardoso Martinez.
Materia: Seminario en Ingeniería de Software · Universidad Icesi.

## Estructura actual de lib/

Prototipo navegable (Entrega 2) con datos simulados en memoria. En la entrega 3 se conecta a Supabase: los paquetes externos son `supabase_flutter` y `image_picker` (selector de la foto de perfil) y la conexión ya está inicializada en `main.dart` (plan P-00), pero las pantallas siguen leyendo de memoria. La URL y la publishable key salen de `env.json` (en `.gitignore`; el ejemplo es `env.example.json`) y la secret key nunca va en el repo. Integra las pantallas de todo el equipo en una sola app y cubre los 38 requisitos funcionales: acceso en dos pasos, inicio del médico, pacientes en seguimiento, búsqueda de pacientes, declaración del propósito, historia clínica con el riesgo y sus factores, registro de una atención, datos básicos del administrativo, acceso denegado, tablero y detalle de indicadores, registro de una medición, auditoría de accesos y perfil.

```
lib/
├── main.dart            # arranca la app e inicializa Supabase (único punto)
├── config/              # entorno.dart: URL y publishable key de Supabase (--dart-define-from-file=env.json)
├── tema/                # colores, tema y breakpoint (900 px, contenido máx. 1200)
├── modelos/             # modelos.dart (sedes, usuarios, pacientes, propósitos, auditoría)
│                        # historia.dart (historia clínica, atenciones y factores del riesgo)
│                        # indicadores.dart (indicadores y mediciones)
├── datos/               # datos simulados: pacientes, eventos, historias y mediciones (hoy: 6 nov 2026)
│                        # fuente_de_datos.dart: único punto que elige la fuente de datos (AD-02; hoy, memoria)
├── repositorios/        # AuthRepositorio, AuditoriaRepositorio (agregar y listar) y FotoPerfilRepositorio
│                        # (descargar, subir, quitar), cada uno con su versión en memoria y la de Supabase;
│                        # selector_foto.dart abre el selector de imágenes (image_picker)
├── reglas/              # reglas de negocio puras: umbral 70, bloqueo, relación, propósitos, permisos,
│                        # indicadores (promedio, marca, cambio y validar una medición), búsqueda,
│                        # atencion.dart (validar una atención) y foto.dart (tipo y tamaño de la foto)
├── formato/             # fechas, horas y búsqueda sin tildes (RNF-05)
├── widgets/             # componentes de la galería, cada uno una sola vez: tarjeta.dart
│                        # (TarjetaVitalys, ChipVitalys, EstadoVacio), campo_dato, barra_volver,
│                        # foco (AnilloFoco), proposito(_partes) e indicadores/ (gráficas y tarjetas)
├── pages/               # Pages: solo muestran y avisan con callbacks
└── screens/             # app_screen.dart: la Screen anfitriona con todo el estado (setState);
                         # app_screen_paginas.dart: cómo se arma cada Page y las rutas
```

Ningún archivo de `lib/` pasa de 800 líneas. Antes de crear una tarjeta, chip, estado vacío o barra de volver, usa el de `widgets/`.

Reglas del enunciado: el estado vive en la Screen anfitriona, las Pages no guardan datos de la app (solo lo que se está escribiendo en un formulario) y los componentes de la galería se construyen una sola vez en `widgets/`. Antes de subir cambios: `dart format lib test`, `flutter analyze` y `flutter test`.

## Documentos

La carpeta `docs/` tiene los documentos que guían el desarrollo (Spec Driven Development), en este orden:

- `docs/prd.md`: el PRD, con el problema, los usuarios, los objetivos medibles y el alcance.
- `docs/requisitos.md`: los requisitos funcionales (RF) y no funcionales (RNF), numerados y ligados a un objetivo.
- `docs/architectural_spine.md`: la architectural spine, con el stack, el diagrama y las invariantes.
- `docs/plans/`: un plan por funcionalidad o pieza técnica (metadatos, enfoque, componentes y cambios), con el formato en `docs/plans/README.md`.
- `docs/tasks/`: las tareas de cada plan, con casilla `[ ]` y cómo se comprueba cada una (`docs/tasks/README.md`). Los commits citan el id: `feat(T-00.3): ...`.
- `docs/specs/`: una spec funcional por funcionalidad, con el índice en `docs/specs/README.md` y el reporte de la crítica en `docs/specs/reporte.md`.

Las skills que crean y revisan esos documentos están en `.agents/skills/`.

Después de cambiar cualquiera de esos documentos, corre `bash docs/verificar.sh`. Comprueba que el PRD, los requisitos, la spine y las specs sean coherentes entre sí (versiones, índice, dependencias, formato, reglas compartidas y reporte) y no modifica ningún archivo. Si una regla nueva se repite en varios documentos, agrégala a la sección *Reglas compartidas* del script.
