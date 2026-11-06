---
id: F-23
titulo: Cierre de sesión
version: 0.1.1
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-23]
depende_de: [F-22]
---

# F-23 · Cierre de sesión

## Objetivo

Cualquier usuario (médico, administrativo o auditor) termina su sesión para que nadie más pueda seguir usando la app con su cuenta y su sede (O-05).

## Flujo principal

1. El usuario está en *Perfil* (F-22) y elige *Cerrar sesión*.
2. El sistema cierra la sesión sin pedir confirmación.
3. El sistema borra la sede de la sesión.
4. El usuario ve la pantalla de inicio de sesión.

## Flujos alternos

- **A1 · Volver atrás:** después de cerrar sesión, si el usuario usa *Atrás*, no vuelve a ninguna pantalla de la app y sigue en el inicio de sesión.
- **A2 · Entrar otra vez:** para volver a usar la app, el usuario tiene que iniciar sesión y elegir de nuevo la sede, porque la anterior ya no se recuerda.

## Reglas

- *Cerrar sesión* está disponible para los 3 roles.
- No se pide confirmación.
- Al cerrar sesión se borra la sede de la sesión.
- Después de cerrar sesión no se puede ver ninguna pantalla de la app sin iniciar sesión otra vez.
- En esta versión el cierre de sesión no crea un evento de acceso, porque RF-14 solo pide el inicio de sesión.

## Estados

- **Cargando:** mientras se cierra la sesión, se ve "Cerrando sesión…".
- **Vacío:** no aplica.
- **Error:** si la sesión no se pudo cerrar, el usuario sigue en el perfil y ve "No se pudo cerrar la sesión. Intente de nuevo."

## Datos

- La sesión del usuario.
- La sede de la sesión, que se borra.

## Criterios de aceptación

- **CA-1** Dado un usuario de cualquier rol en el perfil, cuando elige *Cerrar sesión*, entonces, sin que se le pida confirmación, ve la pantalla de inicio de sesión.
- **CA-2** Dado que el usuario cerró sesión, cuando usa *Atrás*, entonces sigue en el inicio de sesión y no ve ninguna pantalla de la app.
- **CA-3** Dado que el usuario cerró sesión después de ingresar desde Clínica Vitalys Cali Norte, cuando vuelve a iniciar sesión, entonces tiene que elegir la sede otra vez y no ve la anterior ya elegida.
- **CA-4** Dado que el usuario cerró sesión, cuando el auditor revisa la auditoría de accesos, entonces no aparece ningún evento de ese cierre de sesión.
- **CA-5** Dado que la sesión no se pudo cerrar, cuando el usuario elige *Cerrar sesión*, entonces sigue en el perfil y ve "No se pudo cerrar la sesión. Intente de nuevo."

## Fuera de alcance

- El inicio de sesión y la elección de la sede (RF-18), que especifica otro integrante del equipo.
- Cerrar la sesión de forma automática por inactividad.
- Cerrar la sesión en otros dispositivos.
- Registrar el cierre de sesión en la auditoría.

## Preguntas abiertas

- ¿Se puede cerrar sesión solo desde el perfil o también desde otras pantallas? Las capturas solo lo muestran en el perfil.
- ¿El texto del estado de error es el definitivo? Es una propuesta: la captura no lo muestra.
- ¿Cuál es el id de la spec de inicio de sesión? Hay que agregarlo en `depende_de` cuando exista.

## Historial

- 0.1.0 · 2026-11-05 · Primera versión.
- 0.1.1 · 2026-11-06 · Autores: los 4 integrantes del equipo.
