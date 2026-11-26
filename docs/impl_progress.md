# Avance de la implementación · Red Vitalys

Actualizado: 2026-11-24 · Hechas: 8 de 15

Lo escribe la skill `sdd-tecnicas` (tareas nuevas, `[ ]`) y lo marca la skill `sdd-implementar` (`[x]`). Una tarea se marca cuando pasa `flutter analyze` sin errores. La prueba a mano la haces tú: si falla, desmárcala y vuelve a pedirla.

Los ids siguen desde `T-03`: `T-00` a `T-02` ya se usaron en `docs/tasks/` (conexión a Supabase, auditoría y foto de perfil).

## TS-13 · Inicio de sesión con la sede asignada

- [x] **T-03** Servicio de autenticación: validar con Supabase Auth, leer rol y sedes de la base y devolver el resultado · CA-1, CA-2, CA-3, CA-4, CA-5, CA-9 · depende de: ninguna
  - Hecha: 2026-11-24
  - Archivos: `lib/models/sign_in_result.dart` (nuevo), `lib/services/auth_service.dart` (nuevo), `lib/services/auth_memory.dart` (nuevo), `lib/services/auth_supabase.dart` (nuevo), `lib/datos/fuente_de_datos.dart`, `lib/main.dart`, `lib/screens/app_screen.dart`, `lib/repositorios/sesion_supabase.dart` (borrado), `test/inicio_de_sesion_test.dart` (nuevo)
  - Notas: La interfaz tiene dos versiones, la de memoria (pruebas y sin configuración) y la de Supabase (AD-02). Reemplaza la sesión temporal de Michelle. Un usuario inactivo o sin perfil en `usuario` se trata como datos incorrectos (F-13 no lo define). Con Supabase, el saludo y las iniciales salen del usuario simulado del mismo correo, o se calculan del nombre. Verificada contra el proyecto `red-vitalys` de Supabase con una prueba temporal (no se sube): los 4 usuarios de prueba, los datos incorrectos, la cuenta sin sedes y la falta de red dan el resultado esperado. Falta la prueba a mano en la pantalla.
- [x] **T-04** Confirmar la sede y abrir la sesión: guardar la sede, crear el evento *Ingresar* y llevar a la pantalla inicial del rol · CA-10, CA-12, CA-13 · depende de: T-03
  - Hecha: 2026-11-24
  - Archivos: `lib/screens/app_screen.dart`, `test/inicio_de_sesion_test.dart`
  - Notas: El evento *Ingresar* antes de abrir la sesión ya existía (P-01 de Michelle). Esta tarea agrega que salir sin confirmar la sede cierre la sesión de Auth, y lo cubre con pruebas.
- [x] **T-05** Eventos de ingreso denegado: datos incorrectos, correo inexistente y cuenta sin sedes · CA-6, CA-7 · depende de: T-03
  - Hecha: 2026-11-24
  - Archivos: `test/inicio_de_sesion_test.dart`
  - Notas: Los eventos *Denegado* de datos incorrectos y de cuenta sin sedes ya salían de `_ingresar`. Se cubrió el comportamiento; la IP la pone la base y la política para guardar sin sesión está en `001_base_y_auditoria.sql`.
- [x] **T-06** Campos vacíos y usuarios de prueba: un usuario por rol, uno con 2 sedes y uno sin sedes · CA-8, CA-11 · depende de: T-03
  - Hecha: 2026-11-24
  - Archivos: `test/inicio_de_sesion_test.dart`
  - Notas: La validación de campos vacíos ya existía. Los usuarios de prueba (un usuario por rol, uno con 2 sedes y uno sin sedes) se comprobaron en los datos simulados; en Supabase hay que crearlos a mano.

## TS-14 · Bloqueo del inicio de sesión por intentos fallidos

- [ ] **T-07** Contador de fallos y bloqueo de 5 intentos por 15 minutos · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-9, CA-10 · depende de: T-03
- [ ] **T-08** Intento durante el bloqueo: evento *Denegado*, sin alargar el bloqueo y sin forma de desbloquear · CA-7, CA-8 · depende de: T-05, T-07

## TS-15 · Cierre de sesión por inactividad

- [ ] **T-09** Cierre a los 15 minutos, reiniciado por cualquier acción, con sede borrada y aviso · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6 · depende de: T-04, T-07
- [ ] **T-10** Cierre que falla: la app igual oculta sus pantallas y muestra el inicio de sesión · CA-7 · depende de: T-09

## TS-16 · Declaración del propósito de consulta

- [x] **T-11** Matriz única de propósitos por rol, con el propósito en el evento guardado · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-8, CA-9, CA-10 · depende de: T-04
  - Hecha: 2026-11-25
  - Archivos: `lib/services/access_control_service.dart` (nuevo), `lib/screens/app_screen.dart`, `lib/screens/app_screen_paginas.dart`, `test/proposito_lista_test.dart` (nuevo)
  - Notas: La matriz ya vivía en un solo lugar (`propositosDe` y `propositosParaRegistrar` de `lib/reglas/reglas.dart`); el servicio la expone (`purposesFor`, `decidePurpose`) sin duplicarla, y el pop-up, la pantalla del propósito de la lista y el perfil ahora piden los propósitos al servicio. Lo nuevo en el comportamiento: abrir la lista valida el propósito con `decidePurpose` y, si el rol no lo tiene, guarda el evento *Denegado* y no muestra la lista. Las reglas de abrir la historia, los datos básicos y registrar siguen usando la misma matriz. CA-3, CA-4, CA-5, CA-6 y CA-9 ya tenían pruebas; se agregaron las del servicio (CA-1, CA-2, CA-7, CA-8, CA-10).

## TS-17 · Acceso de emergencia

- [ ] **T-12** Marca y aviso de emergencia: Urgencia permitida, filtro *Emergencia* y aviso al ver y al guardar · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-8, CA-9, CA-10 · depende de: T-11

## TS-06 · Pacientes con alta reciente por riesgo de reingreso

- [x] **T-13** Servicio de pacientes y lista de altas de los últimos 30 días, ordenada y con alerta · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-10, CA-11, CA-14 · depende de: ninguna
  - Hecha: 2026-11-24
  - Archivos: `lib/services/patient_service.dart` (nuevo), `lib/services/patient_memory.dart` (nuevo), `lib/services/patient_supabase.dart` (nuevo), `lib/datos/fuente_de_datos.dart`, `lib/main.dart`, `lib/screens/app_screen.dart`, `supabase/migraciones/004_pacientes_y_riesgo.sql` (nuevo), `test/pacientes_servicio_test.dart` (nuevo)
  - Notas: El servicio entrega todos los pacientes con su última alta y su riesgo guardado (`listPatients`), no solo las altas recientes: la búsqueda también los necesita. La ventana de 30 días, el orden y la alerta de 70 siguen en `pacientesConAltaReciente` y `conAlerta`, que ya estaban probadas. Se cargan al abrir la sesión; si falla la carga, la app sigue con la lista anterior hasta que T-15 muestre el error. El script 004 ya se aplicó al proyecto `red-vitalys` y trae 13 pacientes con fechas fijas (hoy es el 6 nov 2026). Verificado con una prueba temporal (no se sube): los 13 pacientes de Supabase son idénticos a los simulados y las altas recientes son 8. Falta la prueba a mano en la pantalla.
- [x] **T-14** Propósito y evento al abrir la lista, y rechazo del administrativo y del auditor · CA-9, CA-12, CA-13, CA-15 · depende de: T-04, T-11, T-13
  - Hecha: 2026-11-25
  - Archivos: `test/proposito_lista_test.dart`
  - Notas: El pedido del propósito antes de ver pacientes, el evento *Consultar* de la lista sin paciente y el rechazo del administrativo y del auditor por `intentarAcceso` ya existían. Esta tarea los cubre con pruebas contra una auditoría remota falsa (CA-9, CA-12, CA-13, CA-15). Verificada en el navegador contra `red-vitalys`: abrir la lista con *Urgencia* guardó el evento 25 sin paciente, con la sede y el propósito, y el auditor lo ve en el filtro *Emergencia*. El rechazo del administrativo y del auditor no se puede provocar desde la pantalla (no tienen la sección); solo se prueba por `intentarAcceso`.
- [x] **T-15** Carga y error reales de la lista, con *Reintentar* · CA-8 · depende de: T-13
  - Hecha: 2026-11-25
  - Archivos: `lib/screens/app_screen.dart`, `lib/screens/app_screen_paginas.dart`, `lib/pages/seguimiento_page.dart`, `lib/pages/inicio_page.dart`, `test/pacientes_servicio_test.dart`
  - Notas: Se usa `CargaRemota`, que ya existía para la auditoría, en lugar de cambiar `lib/widgets/carga.dart`. El interruptor de demo *Simular fallas de red* sigue igual. Con Supabase la lista empieza vacía y no con los pacientes simulados. El Inicio del médico también muestra la carga y el error, porque usa los mismos pacientes. Mientras carga o si falla, los contadores del Inicio muestran 0. Verificada en el navegador contra `red-vitalys`, cortando solo la consulta de atenciones: se ve el error en el Inicio y en la lista, y al volver la red *Reintentar* trae los 8 pacientes.

## TS-05 · Relación médico-paciente

- [ ] **T-16** Relación con datos de la base: atención propia o alta de 30 días en una sede asignada, Urgencia sin dar relación y error de verificación · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-8, CA-9 · depende de: T-11, T-13

## TS-18 · Control de acceso por rol

- [ ] **T-17** Una sola tabla de permisos y rechazos con su mensaje, su evento y sin datos del paciente · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-8, CA-9, CA-10, CA-11 · depende de: T-11, T-16
