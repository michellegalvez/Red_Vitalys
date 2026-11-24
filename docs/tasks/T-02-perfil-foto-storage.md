---
id: T-02
titulo: Tareas de la foto de perfil en Storage
version: 0.1.0
fecha: 2026-11-24
plan: P-02
estado: hecho
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
---

# T-02 · Foto de perfil en Storage

Plan: [P-02](../plans/P-02-perfil-foto-storage.md)

## Tareas

- [x] **T-02.1** · Crear el bucket privado `fotos-perfil` (JPG y PNG, hasta 2 MB) y las políticas para que cada usuario solo toque su carpeta.
  - Toca: `supabase/migraciones/003_fotos_perfil.sql`
  - Se comprueba: en *Storage* está el bucket `fotos-perfil` y no es público; en *Storage → Policies* hay 4 políticas sobre `storage.objects`.

- [x] **T-02.2** · Escribir las reglas de la foto: extensión (JPG, JPEG, PNG), tamaño máximo y mensajes de rechazo.
  - Toca: `lib/reglas/foto.dart`, `test/foto_perfil_test.dart`
  - Se comprueba: `flutter test test/foto_perfil_test.dart` pasa; 2 MB justos se aceptan, un byte más se rechaza, un GIF se rechaza.

- [x] **T-02.3** · Crear la interfaz `FotoPerfilRepositorio` y su implementación en memoria.
  - Toca: `lib/repositorios/foto_repositorio.dart`, `lib/repositorios/foto_memoria.dart`, `test/foto_perfil_test.dart`
  - Se comprueba: las pruebas de subir, descargar y quitar en memoria pasan.

- [x] **T-02.4** · Crear la implementación con Supabase: subir a `<id_usuario>/foto.<ext>`, guardar la ruta en `usuario.foto_ruta`, descargar y quitar, y borrar el archivo anterior si cambia la extensión.
  - Toca: `lib/repositorios/foto_supabase.dart`
  - Se comprueba: `flutter analyze` sin avisos; la ruta es `<id>/foto.<ext>` (prueba de `rutaDeFoto`). El comportamiento contra Storage se comprueba en T-02.10.

- [x] **T-02.5** · Agregar el selector de imágenes con `image_picker`, detrás de la interfaz `SelectorFoto`.
  - Toca: `pubspec.yaml`, `lib/repositorios/selector_foto.dart`
  - Se comprueba: `flutter pub get` sin errores y `flutter analyze` sin avisos.

- [x] **T-02.6** · Elegir el repositorio de fotos en `fuente_de_datos.dart`: Supabase si está listo, memoria si no.
  - Toca: `lib/datos/fuente_de_datos.dart`, `lib/main.dart`, `test/foto_perfil_test.dart`
  - Se comprueba: sin Supabase, la fuente de fotos es la de memoria.

- [x] **T-02.7** · Guardar en la Screen el estado de la foto: traerla al abrir el perfil, subir una nueva con validación, quitarla y borrarla del estado al cerrar sesión.
  - Toca: `lib/screens/app_screen.dart`, `lib/screens/app_screen_foto.dart`, `lib/screens/app_screen_paginas.dart`
  - Se comprueba: las pruebas del flujo del perfil pasan (subir, quitar, tipo no válido, más de 2 MB, falla al guardar, cancelar).

- [x] **T-02.8** · Mostrar la foto en el perfil con sus botones y estados de carga, guardado y error con *Reintentar*.
  - Toca: `lib/widgets/foto_perfil.dart`, `lib/pages/perfil_page.dart`, `test/correcciones_test.dart`
  - Se comprueba: sin foto se ven las iniciales y *Subir foto*; con foto, *Cambiar foto* y *Quitar foto*; mientras guarda, el botón dice "Guardando…".

- [x] **T-02.9** · Dejar la foto en los documentos: RF-38, RNF-08, AD-16, F-22 con sus criterios, y el README y AGENTS al día.
  - Toca: `docs/prd.md`, `docs/requisitos.md`, `docs/architectural_spine.md`, `docs/specs/F-22-perfil-permisos.md`, `docs/specs/README.md`, `docs/specs/reporte.md`, `README.md`, `AGENTS.md`
  - Se comprueba: `bash docs/verificar.sh` termina sin fallas.

- [x] **T-02.10** · Verificación final del plan, con Supabase.
  - Se comprueba: `dart format lib test` sin cambios, `flutter analyze` sin avisos, `flutter test` en verde y las comprobaciones de *Verificación* de P-02, incluido que un usuario no puede leer la foto de otro.
