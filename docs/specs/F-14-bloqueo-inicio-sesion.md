---
id: F-14
titulo: Bloqueo del inicio de sesión por intentos fallidos
version: 0.2.1
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-36]
depende_de: [F-13]
---

# F-14 · Bloqueo del inicio de sesión por intentos fallidos

## Objetivo

Después de 5 intentos fallidos seguidos en un dispositivo, el sistema bloquea el inicio de sesión en ese dispositivo durante 15 minutos, para que nadie adivine una contraseña probando muchas veces, y sin revelar qué correos existen (O-05).

## Flujo principal

1. Un usuario falla el inicio de sesión (F-13) por quinta vez seguida en el mismo dispositivo, con el correo que sea.
2. El sistema bloquea el inicio de sesión en ese dispositivo durante 15 minutos.
3. El usuario ve "Demasiados intentos fallidos. Intente de nuevo en 15 minutos."
4. Durante esos 15 minutos, ningún correo puede ingresar desde ese dispositivo, aunque la contraseña sea correcta.
5. Pasados los 15 minutos, el inicio de sesión se desbloquea solo.

## Flujos alternos

- **A1 · Éxito antes del quinto fallo:** si alguien ingresa bien después de 1 a 4 fallos, el conteo vuelve a cero.
- **A2 · Correo que no existe:** el intento cuenta igual que con un correo que existe. Así el bloqueo no revela qué correos existen.
- **A3 · Intento durante el bloqueo:** se rechaza, se ve el mismo mensaje, queda un evento *Denegado* y el bloqueo no se alarga.

## Reglas

- El límite es de 5 intentos fallidos seguidos en el mismo dispositivo, con cualquier correo.
- Un dispositivo es el navegador o el celular desde el que se intenta ingresar.
- El bloqueo dura 15 minutos desde el quinto fallo.
- El inicio de sesión se desbloquea solo. Nadie puede desbloquearlo antes, ni el auditor ni un administrativo.
- Un inicio de sesión exitoso reinicia el conteo.
- Un intento con el correo o la contraseña vacíos no cuenta como intento fallido ni crea un evento (F-13).
- El mensaje es siempre "Demasiados intentos fallidos. Intente de nuevo en 15 minutos.", sin mostrar cuánto tiempo falta y sin decir si el correo existe.
- Cada intento fallido y cada intento durante el bloqueo crea un evento *Denegado* con el correo escrito y la IP (F-20).
- El límite y la duración se definen en un solo lugar y se aplican igual en toda la app (AD-14).
- Los datos son simulados.

## Estados

- **Cargando:** el de F-13.
- **Vacío:** no aplica.
- **Error:** el mensaje de bloqueo.

## Datos

- **Intentos fallidos seguidos** en el dispositivo.
- **Hora del bloqueo**, de la que sale el momento en que termina.

## Criterios de aceptación

- **CA-1** Dados 4 intentos fallidos seguidos en un dispositivo, cuando falla el quinto, entonces el usuario ve "Demasiados intentos fallidos. Intente de nuevo en 15 minutos."
- **CA-2** Dado un dispositivo bloqueado, cuando alguien escribe un correo y una contraseña correctos, entonces no entra y ve el mensaje de bloqueo.
- **CA-3** Dado un dispositivo bloqueado hace 15 minutos, cuando el usuario escribe su correo y su contraseña correctos, entonces entra.
- **CA-4** Dados 4 intentos fallidos seguidos, cuando el usuario ingresa bien, entonces entra y el siguiente fallo cuenta como el primero.
- **CA-5** Dados 5 intentos fallidos con un correo que no existe, cuando falla el quinto, entonces el usuario ve el mismo mensaje de bloqueo que con un correo que existe.
- **CA-6** Dados 5 intentos fallidos repartidos entre 2 correos distintos en el mismo dispositivo, cuando falla el quinto, entonces el inicio de sesión se bloquea.
- **CA-7** Dado un dispositivo bloqueado, cuando alguien intenta ingresar, entonces el auditor ve un evento *Denegado* con el correo escrito y la IP.
- **CA-8** Dado un dispositivo bloqueado, cuando un administrativo o un auditor busca la forma de desbloquearlo, entonces no la encuentra en ninguna parte de la app.
- **CA-9** Dados 4 intentos fallidos seguidos en un dispositivo, cuando el usuario elige *Ingresar* con la contraseña vacía, entonces ve "Escriba su correo y su contraseña", el inicio de sesión no se bloquea y el auditor no ve un evento de ese intento.

## Fuera de alcance

- Desbloquear el inicio de sesión antes de que pasen los 15 minutos.
- Bloquear una cuenta en todos los dispositivos.
- Avisarle a alguien del bloqueo.
- El inicio de sesión en sí, que es F-13.

## Preguntas abiertas

- El bloqueo se salta cambiando de dispositivo. ¿Se acepta en esta versión? La spine lo deja diferido para la entrega 3.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.1.1 · 2026-11-06 · Redacción: se quita el nombre de un servicio de las reglas.
- 0.2.0 · 2026-11-06 · El bloqueo pasa a ser del inicio de sesión en el dispositivo, para cualquier correo, con un mensaje fijo que no revela qué correos existen (RF-36 0.4.0). Se cierran 3 preguntas abiertas.
- 0.2.1 · 2026-11-06 · Un intento con el correo o la contraseña vacíos no cuenta ni crea un evento (regla y CA-9), como F-13.
