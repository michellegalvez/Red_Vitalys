---
id: TS-18
titulo: Control de acceso por rol
version: 0.1.0
fecha: 2026-11-24
estado: borrador
funcional: F-18 0.2.5
---

# TS-18 · Control de acceso por rol

## Resumen

Toda acción pasa por el servicio de control de acceso, que usa una sola tabla de permisos por rol, la misma que dibuja el perfil (AD-06). Si la rechaza, muestra el mensaje de la causa sin datos del paciente y crea el evento *Denegado*. Las políticas de Supabase repiten la regla del lado de la base.

## Preparación en Supabase

- Políticas de acceso por rol en las tablas de pacientes (script 004 de TS-06): solo el médico lee la historia y el riesgo; el administrativo lee solo los datos básicos; el auditor no lee pacientes. Se crean a mano en el *SQL Editor*.

## Piezas

- `lib/services/access_control_service.dart` · **cambia** (T-17) · `canDo(Rol role, AccionPermitida action) → bool` y `attempt(AccionPermitida action, RecursoAuditoria resource, {...}) → Future<bool>`: decide, crea el evento *Denegado* y devuelve el mensaje. Es la puerta que hoy es `intentarAcceso`.
- `lib/reglas/reglas.dart` · **cambia** (T-17) · `rolPermite` sigue siendo la única tabla; `seccionesDe` y el perfil se derivan de ella.
- `lib/screens/app_screen.dart` · **cambia** (T-17) · usa el servicio en la navegación, al registrar una atención y al guardar una medición.
- `lib/pages/consulta_page.dart` · **cambia** (T-17) · la pantalla de rechazo muestra el mensaje y nunca el nombre ni el documento del paciente.
- `lib/pages/perfil_page.dart` · **sin cambio** · ya lista *Permitido* y *No incluido* desde la misma tabla.

## Estado

- Ninguno nuevo: la decisión se toma en cada acción.

## Datos

- Tabla de permisos: 7 acciones por rol (buscar paciente, ver historia, registrar atención, ver tablero, registrar medición, ver auditoría, ver perfil). Mensajes de rechazo: "Su rol no permite esta acción.", "Su rol no puede declarar ese propósito." y "No tiene relación con este paciente. Si es una emergencia, declare *Urgencia*.".

## Paquetes y plataformas

- Ninguno nuevo.

## Tareas

- **T-17** Una sola tabla de permisos y rechazos con su mensaje: rechazar las acciones fuera del rol, los propósitos no permitidos y la falta de relación con el mensaje de su causa y su evento *Denegado*; que el tablero, el perfil y el cierre de sesión no creen evento; que lo que el perfil muestra como *No incluido* se rechace y lo *Permitido* se permita; y si no se puede verificar, mostrar "No se pudo verificar el acceso" y no hacer la acción. · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-8, CA-9, CA-10, CA-11 · depende de: T-11, T-16
  - Prueba: como administrativo no poder registrar una atención y ver el evento; como auditor no ver *Buscar*; como médico no ver *Mediciones* ni *Auditoría*; el auditor abre el tablero sin que quede evento; un médico sin relación ve el mensaje de relación sin el nombre del paciente; con la red apagada ver "No se pudo verificar el acceso".

## Preguntas abiertas

- ¿Las políticas de la base deben repetir la tabla completa o solo la lectura de pacientes?

## Historial

- 0.1.0 · 2026-11-24 · Primera versión.
