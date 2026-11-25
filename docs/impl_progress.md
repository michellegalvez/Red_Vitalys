# Avance de la implementación · Red Vitalys

Actualizado: 2026-11-24 · Hechas: 0 de 15

Lo escribe la skill `sdd-tecnicas` (tareas nuevas, `[ ]`) y lo marca la skill `sdd-implementar` (`[x]`). Una tarea se marca cuando pasa `flutter analyze` sin errores. La prueba a mano la haces tú: si falla, desmárcala y vuelve a pedirla.

Los ids siguen desde `T-03`: `T-00` a `T-02` ya se usaron en `docs/tasks/` (conexión a Supabase, auditoría y foto de perfil).

## TS-13 · Inicio de sesión con la sede asignada

- [ ] **T-03** Servicio de autenticación: validar con Supabase Auth, leer rol y sedes de la base y devolver el resultado · CA-1, CA-2, CA-3, CA-4, CA-5, CA-9 · depende de: ninguna
- [ ] **T-04** Confirmar la sede y abrir la sesión: guardar la sede, crear el evento *Ingresar* y llevar a la pantalla inicial del rol · CA-10, CA-12, CA-13 · depende de: T-03
- [ ] **T-05** Eventos de ingreso denegado: datos incorrectos, correo inexistente y cuenta sin sedes · CA-6, CA-7 · depende de: T-03
- [ ] **T-06** Campos vacíos y usuarios de prueba: un usuario por rol, uno con 2 sedes y uno sin sedes · CA-8, CA-11 · depende de: T-03

## TS-14 · Bloqueo del inicio de sesión por intentos fallidos

- [ ] **T-07** Contador de fallos y bloqueo de 5 intentos por 15 minutos · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-9, CA-10 · depende de: T-03
- [ ] **T-08** Intento durante el bloqueo: evento *Denegado*, sin alargar el bloqueo y sin forma de desbloquear · CA-7, CA-8 · depende de: T-05, T-07

## TS-15 · Cierre de sesión por inactividad

- [ ] **T-09** Cierre a los 15 minutos, reiniciado por cualquier acción, con sede borrada y aviso · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6 · depende de: T-04, T-07
- [ ] **T-10** Cierre que falla: la app igual oculta sus pantallas y muestra el inicio de sesión · CA-7 · depende de: T-09

## TS-16 · Declaración del propósito de consulta

- [ ] **T-11** Matriz única de propósitos por rol, con el propósito en el evento guardado · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-8, CA-9, CA-10 · depende de: T-04

## TS-17 · Acceso de emergencia

- [ ] **T-12** Marca y aviso de emergencia: Urgencia permitida, filtro *Emergencia* y aviso al ver y al guardar · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-8, CA-9, CA-10 · depende de: T-11

## TS-06 · Pacientes con alta reciente por riesgo de reingreso

- [ ] **T-13** Servicio de pacientes y lista de altas de los últimos 30 días, ordenada y con alerta · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-10, CA-11, CA-14 · depende de: ninguna
- [ ] **T-14** Propósito y evento al abrir la lista, y rechazo del administrativo y del auditor · CA-9, CA-12, CA-13, CA-15 · depende de: T-04, T-11, T-13
- [ ] **T-15** Carga y error reales de la lista, con *Reintentar* · CA-8 · depende de: T-13

## TS-05 · Relación médico-paciente

- [ ] **T-16** Relación con datos de la base: atención propia o alta de 30 días en una sede asignada, Urgencia sin dar relación y error de verificación · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-8, CA-9 · depende de: T-11, T-13

## TS-18 · Control de acceso por rol

- [ ] **T-17** Una sola tabla de permisos y rechazos con su mensaje, su evento y sin datos del paciente · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-8, CA-9, CA-10, CA-11 · depende de: T-11, T-16
