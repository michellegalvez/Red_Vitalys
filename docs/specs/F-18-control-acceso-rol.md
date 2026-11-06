---
id: F-18
titulo: Control de acceso por rol
version: 0.2.3
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-34, RF-21]
depende_de: []
---

# F-18 · Control de acceso por rol

## Objetivo

El sistema permite a cada rol solo lo que su rol permite, rechaza lo demás y deja el rechazo registrado, para que nadie vea ni haga lo que no le corresponde (O-05).

## Flujo principal

1. El usuario intenta una acción: ver, registrar o abrir algo.
2. El sistema la compara con la tabla de permisos de su rol y, cuando es sobre un paciente, con el propósito declarado y la relación con el paciente (F-05).
3. Si la acción está permitida, el sistema crea el evento *Permitido* cuando corresponde y, si pudo crearlo, la ejecuta (F-20).
4. Si no está permitida, el sistema no la ejecuta, le muestra al usuario el mensaje que corresponde a la causa del rechazo y crea un evento *Denegado* (F-20).

## Flujos alternos

- **A1 · Acción fuera del rol:** la acción no está en la tabla del rol, por ejemplo un administrativo que intenta registrar una atención. Se rechaza.
- **A2 · Propósito no permitido:** el usuario declara un propósito que su rol no puede, por ejemplo un administrativo que declara *Urgencia*. Se rechaza.
- **A3 · Sin relación:** un médico consulta la historia o registra una atención de un paciente sin relación y sin *Urgencia*. Se rechaza (F-05).
- **A4 · Acción permitida sin evento:** ver el tablero, ver el perfil y cerrar sesión están permitidos y no crean evento.

## Reglas

- Hay una sola tabla de permisos. El perfil (F-22) se arma con esa misma tabla.
- Lo que no está en la tabla se rechaza.
- El mensaje de rechazo depende de la causa y nunca muestra datos del paciente:
  - **El rol no permite la acción:** "Su rol no permite esta acción."
  - **El rol no puede declarar ese propósito:** "Su rol no puede declarar ese propósito."
  - **El médico no tiene relación con el paciente:** "No tiene relación con este paciente. Si es una emergencia, declare *Urgencia*."
- La tabla de permisos por rol:

| Acción | Médico | Administrativo | Auditor |
|---|---|---|---|
| Buscar paciente y ver sus datos básicos | Permitido | Permitido | No incluido |
| Ver la historia clínica y el riesgo de reingreso | Permitido | No incluido | No incluido |
| Registrar una atención | Permitido | No incluido | No incluido |
| Ver el tablero y el detalle de los indicadores | Permitido | Permitido | Permitido |
| Registrar una medición | No incluido | Permitido | No incluido |
| Ver la auditoría de accesos | No incluido | No incluido | Permitido |
| Ver el perfil y cerrar sesión | Permitido | Permitido | Permitido |

- Propósitos por rol: el médico los 5, el administrativo solo *Revisión de calidad* y el auditor ninguno.
- Las pantallas pueden ocultar las opciones que el rol no tiene, pero el rechazo lo decide el sistema, no la pantalla (AD-06).
- Toda acción rechazada crea un evento *Denegado* con el usuario, la acción, el recurso, el propósito y la sede, sea o no sobre un paciente.
- El usuario no puede cambiar su rol desde la app.
- Los datos son simulados.

## Estados

- **Cargando:** no aplica. El usuario ve el estado de la acción que intentó.
- **Vacío:** no aplica.
- **Error:** si el sistema no puede decidir, rechaza la acción y se ve "No se pudo verificar el acceso".

## Datos

- **Rol** del usuario.
- **Acción**, **recurso** y **propósito** declarado.
- **Resultado:** *Permitido* o *Denegado*.

## Criterios de aceptación

- **CA-1** Dado un administrativo, cuando intenta registrar una atención, entonces no se registra, ve "Su rol no permite esta acción." y queda un evento con la acción *Registrar*, el recurso *Atención* y el resultado *Denegado*.
- **CA-2** Dado un auditor, cuando intenta buscar pacientes, entonces no ve resultados y queda un evento *Denegado*.
- **CA-3** Dado un médico, cuando intenta registrar una medición, entonces no se registra y queda un evento con el recurso *Medición de indicador* y el resultado *Denegado*.
- **CA-4** Dado un médico, cuando intenta abrir la auditoría de accesos, entonces no la ve y queda un evento con el recurso *Auditoría de accesos* y el resultado *Denegado*.
- **CA-5** Dado que el sistema recibe la consulta de un administrativo con el propósito *Urgencia*, cuando la procesa, entonces no se muestra la información del paciente y queda un evento con el resultado *Denegado*.
- **CA-6** Dado un auditor, cuando abre el tablero de indicadores, entonces lo ve y no queda ningún evento.
- **CA-7** Dado que el sistema recibe de un administrativo la orden de registrar una atención, cuando la procesa, entonces la atención no se registra y queda un evento con la acción *Registrar*, el recurso *Atención* y el resultado *Denegado*.
- **CA-8** Dado un usuario cuyo perfil muestra una acción como *No incluido*, cuando la intenta, entonces el sistema la rechaza, y si el perfil la muestra como *Permitido*, el sistema la permite.
- **CA-9** Dado que el sistema no puede verificar el acceso, cuando el usuario intenta una acción, entonces ve "No se pudo verificar el acceso" y la acción no se hace.
- **CA-10** Dado un médico sin relación con un paciente, cuando abre su historia declarando *Atención del paciente*, entonces no ve la historia y ve "No tiene relación con este paciente. Si es una emergencia, declare *Urgencia*."
- **CA-11** Dado cualquier rechazo, cuando el usuario ve el mensaje, entonces el mensaje no muestra el nombre, el documento ni ningún otro dato del paciente.

## Fuera de alcance

- Crear o editar roles y permisos.
- La relación médico-paciente (F-05) y el acceso de emergencia (F-17), que usan este control.
- Registrar los eventos, que es F-20.

## Preguntas abiertas

Ninguna.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.1.1 · 2026-11-06 · CA-7 pasa a un resultado que el usuario ve.
- 0.1.2 · 2026-11-06 · CA-5 y CA-7 se redactan a nivel del sistema, porque parten de acciones que el usuario no puede hacer desde la app.
- 0.2.0 · 2026-11-06 · Se definen los 3 mensajes de rechazo según la causa, sin datos del paciente (CA-1, CA-10, CA-11). Se cierran 2 preguntas abiertas.
- 0.2.1 · 2026-11-06 · Se aprueban los textos de los estados como definitivos. Se cierra esa pregunta abierta.
- 0.2.2 · 2026-11-06 · A3 incluye el registro de una atención sin relación, como RF-20 0.5.0.
- 0.2.3 · 2026-11-06 · El evento se crea antes de ejecutar la acción, y si no se puede crear la acción no se hace, como RF-14 0.6.1 y AD-07 0.6.1.
