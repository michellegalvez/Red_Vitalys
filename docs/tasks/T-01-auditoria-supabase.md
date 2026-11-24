---
id: T-01
titulo: Tareas de la auditoría en Supabase
version: 0.1.0
fecha: 2026-11-23
plan: P-01
estado: hecho
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
---

# T-01 · Auditoría en Supabase

Plan: [P-01](../plans/P-01-auditoria-supabase.md)

## Tareas

- [x] **T-01.1** · Crear las tablas comunes, la auditoría con su trigger de solo agregar y las políticas de acceso.
  - Toca: `supabase/migraciones/001_base_y_auditoria.sql`
  - Se comprueba: en *Table Editor* están las 6 tablas, `rol` tiene 3 filas y `sede` tiene 10.

- [x] **T-01.2** · Crear los 4 usuarios de prueba en Auth y cargarlos en `usuario` con sus sedes.
  - Toca: `supabase/migraciones/002_usuarios_de_prueba.sql`
  - Se comprueba: la consulta final devuelve `usuarios = 4` y `sedes_asignadas = 4`.

- [x] **T-01.3** · Crear la interfaz `AuditoriaRepositorio` (`agregar` y `listar`, sin editar ni borrar) y su implementación en memoria.
  - Toca: `lib/repositorios/auditoria_repositorio.dart`, `lib/repositorios/auditoria_memoria.dart`, `test/auditoria_repositorio_test.dart`
  - Se comprueba: `flutter test test/auditoria_repositorio_test.dart` pasa; agregar suma un evento y la interfaz no tiene métodos para editar ni borrar.

- [x] **T-01.4** · Crear la implementación con Supabase: traducir acciones, recursos y propósitos a los textos de la base, y los ids de usuario y sede.
  - Toca: `lib/repositorios/auditoria_supabase.dart`, `test/auditoria_repositorio_test.dart`
  - Se comprueba: las pruebas de traducción pasan (cada valor del enum tiene su texto y vuelve igual); `flutter analyze` sin avisos.

- [x] **T-01.5** · Crear la sesión puente: iniciar sesión en Supabase con el mismo correo y contraseña al validar el ingreso, y cerrarla al cerrar la sesión de la app.
  - Toca: `lib/repositorios/sesion_supabase.dart`, `lib/screens/app_screen.dart`
  - Se comprueba: con `env.json`, entrar como `marcela.ospina@vitalys.co` crea una sesión en Supabase; sin `env.json`, la app entra igual que antes.

- [x] **T-01.6** · Elegir el repositorio de auditoría en `fuente_de_datos.dart`: Supabase si está listo, memoria si no.
  - Toca: `lib/datos/fuente_de_datos.dart`, `test/fuente_de_datos_test.dart`
  - Se comprueba: `flutter test` pasa; sin Supabase, la fuente de auditoría es la de memoria.

- [x] **T-01.7** · Guardar el evento de ingreso por el repositorio, esperando el resultado: si no se guarda, la sesión no se abre. Los demás eventos se guardan también sin esperarlos.
  - Toca: `lib/screens/app_screen.dart`
  - Se comprueba: un ingreso exitoso y uno fallido aparecen en `evento_auditoria`; con la red cortada, la sesión no se abre y se ve el mensaje de falla (F-13 paso 5).

- [x] **T-01.8** · Hacer que la pantalla del auditor lea los eventos de Supabase, con estado de carga y de error con *Reintentar*.
  - Toca: `lib/screens/app_screen.dart`, `lib/screens/app_screen_paginas.dart`, `lib/pages/auditoria_page.dart`
  - Se comprueba: como Marcela se ven los eventos de la base; los filtros *Denegados* y *Emergencia* funcionan; al cerrar y abrir la app siguen ahí.

- [x] **T-01.9** · Comprobar que la auditoría es de solo agregar.
  - Toca: `supabase/migraciones/001_base_y_auditoria.sql` (solo si hay que corregir)
  - Se comprueba: en el SQL Editor, `update evento_auditoria set resultado = 'permitido'` y `delete from evento_auditoria` fallan con "La auditoría es de solo agregar"; un médico no puede leer la tabla.

- [x] **T-01.10** · Verificación final del plan.
  - Se comprueba: `dart format lib test` sin cambios, `flutter analyze` sin avisos, `flutter test` en verde, `bash docs/verificar.sh` sin fallas y las comprobaciones de *Verificación* de P-01. El caso de ingreso sin red no se probó a mano; el código lo cubre (la sesión no se abre si no se guarda el evento).
