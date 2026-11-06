---
id: F-13
titulo: Inicio de sesión con la sede asignada
version: 0.4.1
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-32, RF-33, RF-18, RF-37]
depende_de: [F-20]
---

# F-13 · Inicio de sesión con la sede asignada

## Objetivo

El médico, el administrativo y el auditor entran a la app con su correo institucional y su contraseña, y eligen la sede desde la que ingresan entre las que tienen asignadas (O-05).

## Flujo principal

1. El usuario abre la app y ve el inicio de sesión.
2. Escribe su correo institucional y su contraseña, y elige *Ingresar*.
3. El sistema valida los datos y muestra las sedes asignadas al usuario.
4. El usuario elige la sede desde la que ingresa y confirma.
5. El sistema crea un evento de acceso *Ingresar* sobre *Sesión* con resultado *Permitido*. Si no puede crearlo, no abre la sesión (F-20).
6. El sistema abre la sesión con esa sede y el usuario entra a la pantalla inicial de su rol.

## Flujos alternos

- **A1 · Datos incorrectos:** si el correo o la contraseña no son correctos, se ve "Correo o contraseña incorrectos", sin decir cuál falló, y el usuario sigue en el inicio de sesión. Queda un evento *Denegado* con el correo escrito y la IP (F-20).
- **A2 · Inicio de sesión bloqueado:** después de 5 intentos fallidos seguidos en el dispositivo, nadie entra desde él durante 15 minutos, aunque la contraseña sea correcta (F-14).
- **A3 · Sin sedes asignadas:** si el usuario no tiene ninguna sede asignada, se ve "Su cuenta no tiene sedes asignadas" y no entra.
- **A4 · Una sola sede:** si el usuario tiene una sola sede asignada, esa aparece elegida y el usuario debe confirmarla.
- **A5 · Campos vacíos:** si falta el correo o la contraseña, se ve "Escriba su correo y su contraseña" y no se intenta ingresar.
- **A6 · Abandona antes de elegir la sede:** el usuario valida sus datos y sale sin confirmar la sede. No se abre la sesión y no queda un evento de ingreso exitoso.

## Reglas

- Los 3 roles inician sesión de la misma manera.
- La pantalla inicial depende del rol (RF-37): el médico entra a *Pacientes con alta reciente* (F-06), el administrativo al *Tablero de indicadores* (F-08) y el auditor a la *Auditoría de accesos* (F-21).
- Las cuentas ya existen. No hay registro desde la app ni recuperación de contraseña.
- La contraseña no se muestra mientras se escribe.
- El mensaje de datos incorrectos es el mismo si el correo no existe o si la contraseña está mal.
- Solo se pueden elegir sedes asignadas al usuario. La sede elegida queda en la sesión y se muestra en el perfil (F-22).
- El rol y las sedes salen del registro del usuario, no de los datos de la cuenta de acceso (AD-04).
- Cada inicio de sesión, exitoso o fallido, crea un evento (F-20). El evento exitoso se crea cuando el usuario confirma la sede, antes de abrir la sesión, porque lleva la sede. Si el usuario valida sus datos y abandona antes de elegir la sede, no se abre la sesión y no se crea ese evento.
- Los datos son simulados.

## Estados

- **Cargando:** mientras se valida, se ve "Ingresando…" y no se puede volver a elegir *Ingresar*.
- **Vacío:** el mensaje de A3.
- **Error:** si el sistema no responde, se ve "No se pudo iniciar sesión. Intente de nuevo." y se conservan el correo y la sede, pero no la contraseña.

## Datos

- **Correo institucional**, por ejemplo "camila.martinez@vitalys.co".
- **Contraseña.**
- **Sedes asignadas** del usuario y la **sede elegida**.

## Criterios de aceptación

- **CA-1** Dada la Dra. Camila Martínez con Clínica Vitalys Cali Norte asignada, cuando escribe su correo y su contraseña correctos, entonces ve sus sedes asignadas y, al elegir Cali Norte y confirmar, entra a la app.
- **CA-2** Dada la Dra. Martínez con una sola sede asignada, cuando valida sus datos, entonces ve esa sede elegida y entra solo al confirmarla.
- **CA-3** Dado un usuario con 2 sedes asignadas, cuando valida sus datos, entonces ve exactamente esas 2 sedes y ninguna otra.
- **CA-4** Dado un correo que existe y una contraseña equivocada, cuando el usuario elige *Ingresar*, entonces ve "Correo o contraseña incorrectos".
- **CA-5** Dado un correo que no existe, cuando el usuario elige *Ingresar*, entonces ve el mismo mensaje "Correo o contraseña incorrectos".
- **CA-6** Dado un inicio de sesión fallido, cuando el auditor revisa la auditoría, entonces ve un evento con la acción *Ingresar*, el recurso *Sesión*, el correo escrito, la IP y el resultado *Denegado*.
- **CA-7** Dado un usuario sin sedes asignadas, cuando valida sus datos, entonces ve "Su cuenta no tiene sedes asignadas" y no entra.
- **CA-8** Dado el correo vacío, cuando el usuario elige *Ingresar*, entonces ve "Escriba su correo y su contraseña" y no se intenta ingresar.
- **CA-9** Dado que el sistema no responde, cuando el usuario elige *Ingresar*, entonces ve "No se pudo iniciar sesión. Intente de nuevo." y el correo sigue escrito.
- **CA-10** Dado un usuario que inició sesión, cuando el auditor revisa la auditoría, entonces ve un evento con su nombre, la acción *Ingresar*, el recurso *Sesión*, el propósito *No aplica*, el resultado *Permitido* y la sede elegida.
- **CA-11** Dados los datos simulados, cuando se prueban los 3 roles, entonces hay 3 usuarios, uno por rol, cada uno con al menos una sede asignada (RNF-04).
- **CA-12** Dado un usuario de cada rol, cuando confirma la sede, entonces el médico ve que se le pide el propósito para abrir *Pacientes con alta reciente*, el administrativo ve el *Tablero de indicadores* y el auditor ve la *Auditoría de accesos*.
- **CA-13** Dado un usuario que validó su correo y su contraseña, cuando sale sin confirmar la sede, entonces no entra a la app y el auditor no ve un evento *Permitido* de su ingreso.

## Fuera de alcance

- Bloquear el inicio de sesión tras los intentos fallidos, que es F-14.
- Cerrar la sesión (F-23) y el cierre por inactividad (F-15).
- Crear cuentas, recuperar o cambiar la contraseña, y asignar sedes.

## Preguntas abiertas

- ¿El usuario sin sedes asignadas debe generar un evento de acceso?

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.1.1 · 2026-11-06 · Se cierra la pregunta sobre la sede del inicio de sesión fallido: no la lleva (RF-14 0.2.0).
- 0.2.0 · 2026-11-06 · A2: el bloqueo es del inicio de sesión en el dispositivo, no de la cuenta (F-14 0.2.0).
- 0.3.0 · 2026-11-06 · Se define la pantalla inicial de cada rol (CA-12) y se aprueban los textos de los mensajes. Se cierran 2 preguntas abiertas.
- 0.4.0 · 2026-11-06 · El ingreso exitoso se registra solo al abrirse la sesión (A6, CA-13), y la spec cita RF-37, como RF-14 0.6.0.
- 0.4.1 · 2026-11-06 · El evento se crea antes de ejecutar la acción, y si no se puede crear la acción no se hace, como RF-14 0.6.1 y AD-07 0.6.1.
