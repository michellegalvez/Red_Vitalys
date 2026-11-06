---
id: F-22
titulo: Perfil del usuario
version: 0.2.3
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-22]
depende_de: [F-18]
---

# F-22 · Perfil del usuario

## Objetivo

Cualquier usuario (médico, administrativo o auditor) ve con qué cuenta, con qué rol y desde qué sede está trabajando, y qué puede hacer y qué no con su rol (O-05).

## Flujo principal

1. El usuario entra a *Perfil*.
2. El sistema muestra su nombre, su correo, su rol, la sede de esta sesión y las sedes que tiene asignadas.
3. El sistema muestra la lista *Qué puede hacer con su rol*, con cada acción marcada como *Permitido* o *No incluido*, y los propósitos que su rol puede declarar.
4. El perfil muestra la nota: "El acceso también depende de la sede desde la que ingresó y del propósito que declare en cada consulta."
5. El perfil ofrece la opción *Cerrar sesión* (F-23).

## Flujos alternos

- **A1 · Otro rol:** si el usuario es administrativo o auditor, la lista tiene las mismas acciones en el mismo orden, marcadas según la tabla de *Reglas*.

## Reglas

- Todos los roles pueden ver su propio perfil.
- El perfil solo muestra datos de la persona que inició sesión.
- La sede que se muestra es la que el usuario eligió al iniciar sesión. Las sedes asignadas son las que podía elegir (F-13).
- Los propósitos que se muestran son los de la tabla de F-18: el médico los 5 (*Atención del paciente*, *Consulta de historia clínica*, *Seguimiento de reingreso*, *Revisión de calidad* y *Urgencia*), el administrativo solo *Revisión de calidad* y el auditor ninguno.
- La lista tiene siempre las mismas 7 acciones, en este orden, para los 3 roles:

| Acción | Médico | Administrativo | Auditor |
|---|---|---|---|
| Buscar paciente y ver sus datos básicos | Permitido | Permitido | No incluido |
| Ver la historia clínica y el riesgo de reingreso | Permitido | No incluido | No incluido |
| Registrar una atención | Permitido | No incluido | No incluido |
| Ver el tablero y el detalle de los indicadores | Permitido | Permitido | Permitido |
| Registrar una medición | No incluido | Permitido | No incluido |
| Ver la auditoría de accesos | No incluido | No incluido | Permitido |
| Ver el perfil y cerrar sesión | Permitido | Permitido | Permitido |

Es la misma tabla de F-18.

- La lista sale de las mismas reglas que el sistema aplica para permitir o denegar cada acción. Si una acción está *Permitido* en el perfil, el sistema la permite. Si está *No incluido*, el sistema la deniega.
- El usuario no puede cambiar su rol, su sede ni sus datos desde el perfil.
- Ver el perfil no crea un evento de acceso, porque no es información de un paciente.

## Estados

- **Cargando:** mientras llegan los datos, se ve "Cargando perfil…".
- **Vacío:** no aplica, porque siempre hay un usuario con sesión iniciada.
- **Error:** si los datos no se pueden cargar, se ve "No se pudo cargar su perfil" con la opción *Reintentar*. La opción *Cerrar sesión* sigue disponible.

## Datos

- **Nombre** del usuario, por ejemplo "Dra. Camila Martínez".
- **Correo** institucional, por ejemplo "camila.martinez@vitalys.co".
- **Rol:** *Médico*, *Administrativo* o *Auditor*.
- **Sede de esta sesión**, por ejemplo "Clínica Vitalys Cali Norte".
- **Sedes asignadas** del usuario.
- **Lista de acciones** del rol, cada una con su marca: *Permitido* o *No incluido*.
- **Propósitos** que el rol puede declarar.

## Criterios de aceptación

- **CA-1** Dado que la Dra. Camila Martínez, médica, ingresó desde Clínica Vitalys Cali Norte, cuando abre el perfil, entonces ve su nombre, su correo camila.martinez@vitalys.co, el rol *Médico* y la sede Clínica Vitalys Cali Norte.
- **CA-2** Dado un médico, cuando abre el perfil, entonces ve como *Permitido* buscar paciente y ver sus datos básicos, ver la historia clínica y el riesgo de reingreso, registrar una atención, ver el tablero y el detalle de los indicadores y ver el perfil y cerrar sesión, y como *No incluido* registrar una medición y ver la auditoría de accesos.
- **CA-3** Dado un administrativo, cuando abre el perfil, entonces ve como *Permitido* buscar paciente y ver sus datos básicos, ver el tablero y el detalle de los indicadores, registrar una medición y ver el perfil y cerrar sesión, y como *No incluido* ver la historia clínica y el riesgo de reingreso, registrar una atención y ver la auditoría de accesos.
- **CA-4** Dado un auditor, cuando abre el perfil, entonces ve como *Permitido* ver el tablero y el detalle de los indicadores, ver la auditoría de accesos y ver el perfil y cerrar sesión, y como *No incluido* buscar paciente y ver sus datos básicos, ver la historia clínica y el riesgo de reingreso, registrar una atención y registrar una medición.
- **CA-5** Dado un administrativo, cuyo perfil muestra *Ver la historia clínica y el riesgo de reingreso* como *No incluido*, cuando intenta consultar la historia clínica de un paciente, entonces no ve la historia y el auditor ve en la auditoría de accesos un evento *Denegado*.
- **CA-6** Dado un usuario que ingresó desde una sede, cuando cierra sesión, vuelve a entrar desde otra sede y abre el perfil, entonces ve la sede nueva.
- **CA-7** Dado cualquier usuario, cuando abre el perfil, entonces ve la nota sobre la sede y el propósito.
- **CA-8** Dado que los datos del perfil no se pueden cargar, cuando el usuario abre el perfil, entonces ve "No se pudo cargar su perfil", puede elegir *Reintentar* y todavía puede cerrar sesión.
- **CA-9** Dado un administrativo, cuyo perfil muestra *Registrar una medición* como *Permitido*, cuando registra la medición de un indicador para una sede, entonces ve esa medición entre las mediciones registradas.
- **CA-10** Dado un usuario con 2 sedes asignadas que ingresó desde una de ellas, cuando abre el perfil, entonces ve la sede de la sesión y las 2 sedes asignadas.
- **CA-11** Dado un médico, cuando abre el perfil, entonces ve los 5 propósitos; dado un administrativo, ve solo *Revisión de calidad*; y dado un auditor, ve que no declara ninguno.

## Fuera de alcance

- Editar el nombre, el correo o la contraseña.
- Cambiar de rol o de sede sin cerrar sesión.
- Crear, editar o desactivar usuarios y roles.
- Cerrar sesión, que es F-23.

## Preguntas abiertas

Ninguna.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión, alineada con los requisitos 0.1.0: muestra las sedes asignadas y los propósitos por rol (CA-10, CA-11).
- 0.2.0 · 2026-11-06 · La tabla de acciones es la misma de F-18, con sus 7 filas, y CA-2, CA-3, CA-4, CA-5 y CA-9 usan sus nombres.
- 0.2.1 · 2026-11-06 · Los mensajes de rechazo quedan definidos en F-18. Se cierra esa pregunta abierta.
- 0.2.2 · 2026-11-06 · Se aprueban los textos de los estados como definitivos. Se cierra esa pregunta abierta.
- 0.2.3 · 2026-11-06 · Formato: línea en blanco antes de los encabezados y lista de criterios sin cortes.
