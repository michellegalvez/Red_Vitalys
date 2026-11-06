---
id: F-15
titulo: Cierre de sesión por inactividad
version: 0.2.2
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-35]
depende_de: [F-13, F-23]
---

# F-15 · Cierre de sesión por inactividad

## Objetivo

El sistema cierra la sesión de un usuario que lleva 15 minutos sin usar la app, para que nadie use una cuenta que quedó abierta (O-05).

## Flujo principal

1. El usuario deja de usar la app.
2. A los 15 minutos sin ninguna acción, el sistema cierra la sesión.
3. El sistema borra la sede de la sesión.
4. El usuario ve el inicio de sesión con el aviso "Su sesión se cerró por inactividad".

## Flujos alternos

- **A1 · Uso antes de los 15 minutos:** si el usuario hace cualquier acción antes de cumplirse los 15 minutos, la cuenta de tiempo empieza de nuevo.
- **A2 · Volver atrás:** después del cierre, si el usuario usa *Atrás*, no vuelve a ninguna pantalla de la app.
- **A3 · Entrar otra vez:** para volver a usar la app, el usuario inicia sesión y elige de nuevo la sede (F-13).

## Reglas

- Aplica a los 3 roles.
- Cuenta como uso cualquier acción del usuario en la app.
- El límite es de 15 minutos y se define en un solo lugar (AD-14).
- El cierre por inactividad tiene los mismos efectos que el cierre manual (F-23): se borra la sede y no se puede ver ninguna pantalla sin iniciar sesión de nuevo.
- No crea un evento de acceso, igual que el cierre manual.
- Lo que el usuario estaba escribiendo y no guardó se pierde.
- Los datos son simulados.

## Estados

- **Cargando:** no aplica.
- **Vacío:** no aplica.
- **Error:** si el cierre falla, el sistema vuelve a intentarlo y no deja ver ninguna pantalla de la app.

## Datos

- **Momento de la última acción** del usuario.
- **Sesión** y **sede de la sesión**, que se borran.

## Criterios de aceptación

- **CA-1** Dado un usuario con sesión iniciada, cuando pasan 15 minutos sin ninguna acción, entonces ve el inicio de sesión con "Su sesión se cerró por inactividad".
- **CA-2** Dado un usuario que hace una acción a los 14 minutos, cuando pasan 14 minutos más sin acción, entonces su sesión sigue abierta.
- **CA-3** Dado un usuario cuya sesión se cerró por inactividad, cuando usa *Atrás*, entonces sigue en el inicio de sesión.
- **CA-4** Dado un usuario cuya sesión se cerró por inactividad, cuando vuelve a iniciar sesión, entonces tiene que elegir la sede otra vez.
- **CA-5** Dado un usuario cuya sesión se cerró por inactividad, cuando el auditor revisa la auditoría, entonces no ve ningún evento de ese cierre.
- **CA-6** Dado un médico sin relación con un paciente, cuya sesión se cerró por inactividad con la historia abierta, cuando vuelve a iniciar sesión, entonces tiene que volver a declarar el propósito para ver esa historia.
- **CA-7** Dado que el cierre automático falla, cuando se cumplen 15 minutos sin ninguna acción, entonces el usuario no ve ninguna pantalla de la app y ve el inicio de sesión.

## Fuera de alcance

- Cerrar la sesión a mano, que es F-23.
- Cerrar las sesiones abiertas en otros dispositivos.
- Cambiar el límite de 15 minutos desde la app.

## Preguntas abiertas

- ¿Se avisa al usuario antes del cierre, por ejemplo a los 14 minutos? Hoy no.
- ¿Lo que el usuario estaba escribiendo se debe conservar? Hoy se pierde.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.2.0 · 2026-11-06 · Se agrega CA-7 para el estado de error.
- 0.2.1 · 2026-11-06 · Redacción: se quitan los gestos del teléfono de las reglas.
- 0.2.2 · 2026-11-06 · Se aprueban los textos de los estados como definitivos. Se cierra esa pregunta abierta.
