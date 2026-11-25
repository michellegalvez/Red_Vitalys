---
id: TS-14
titulo: Bloqueo del inicio de sesión por intentos fallidos
version: 0.1.0
fecha: 2026-11-24
estado: borrador
funcional: F-14 0.2.3
---

# TS-14 · Bloqueo del inicio de sesión por intentos fallidos

## Resumen

Un servicio de sesión cuenta los intentos fallidos del dispositivo y decide si el inicio de sesión está bloqueado (AD-14). El límite y la duración se definen en un solo lugar, `lib/reglas/reglas.dart`. El servicio de autenticación consulta al servicio de sesión antes de llamar a Supabase.

## Preparación en Supabase

- Ninguna. El conteo es del dispositivo y no se guarda en la base.

## Piezas

- `lib/services/session_service.dart` · **nueva** (T-07, T-08) · servicio. `isLocked(DateTime now) → bool`; `registerFailure(DateTime now)`; `registerSuccess()`. T-07 trae el conteo y el desbloqueo. T-08 agrega que un intento durante el bloqueo no alarga el tiempo.
- `lib/reglas/reglas.dart` · **cambia** (T-07) · se mantienen `intentosParaBloqueo` (5) y `duracionBloqueo` (15 minutos) como único punto; el servicio los lee.
- `lib/services/auth_service.dart` · **cambia** (T-07, T-08) · antes de validar, pregunta `isLocked`; si está bloqueado devuelve el estado `locked` sin llamar a Auth.
- `lib/screens/app_screen.dart` · **cambia** (T-07, T-08) · muestra "Demasiados intentos fallidos. Intente de nuevo en 15 minutos." y crea el evento *Denegado* del intento durante el bloqueo.

## Estado

- Dentro de `SessionService`: el número de fallos seguidos y la hora en que empezó el bloqueo.
- Solo se reinicia el conteo con un ingreso que termina con la sede elegida (T-04 de TS-13). Validar las credenciales y abandonar no lo reinicia. Un ingreso con credenciales correctas y sin sedes no suma ni reinicia.

## Datos

- Ninguno en la base. El evento *Denegado* del intento usa `evento_auditoria` como en TS-13.

## Paquetes y plataformas

- Ninguno nuevo. El conteo vive en memoria: se pierde al recargar la página o reiniciar la app.

## Tareas

- **T-07** Contador de fallos y bloqueo: 5 fallos seguidos con cualquier correo bloquean 15 minutos, se desbloquea solo y un ingreso exitoso reinicia el conteo; los campos vacíos y la cuenta sin sedes no cuentan. · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-9, CA-10 · depende de: T-03
  - Prueba: fallar 5 veces y ver el mensaje de bloqueo; con la contraseña correcta seguir bloqueado; esperar 15 minutos y entrar; 4 fallos más un ingreso bueno y un fallo, que cuenta como el primero; 5 fallos repartidos entre 2 correos que bloquean; 4 fallos y una contraseña vacía sin bloqueo.
- **T-08** Intento durante el bloqueo: se rechaza con el mismo mensaje, deja un evento *Denegado* con el correo y la IP, no alarga el bloqueo y la app no ofrece forma de desbloquear. · CA-7, CA-8 · depende de: T-05, T-07
  - Prueba: con el dispositivo bloqueado intentar ingresar y ver en la auditoría el evento con el correo y la IP; revisar que ningún rol tenga una opción de desbloqueo.

## Preguntas abiertas

- ¿El bloqueo debe sobrevivir a recargar la página? Pediría `shared_preferences`, que la spine no permite sin preguntar.

## Historial

- 0.1.0 · 2026-11-24 · Primera versión.
