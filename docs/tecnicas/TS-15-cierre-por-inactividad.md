---
id: TS-15
titulo: Cierre de sesión por inactividad
version: 0.1.0
fecha: 2026-11-24
estado: borrador
funcional: F-15 0.2.3
---

# TS-15 · Cierre de sesión por inactividad

## Resumen

El mismo servicio de sesión de TS-14 lleva el temporizador de 15 minutos (AD-14). Cualquier acción del usuario lo reinicia. Al vencer, cierra la sesión de Supabase, borra la sede y deja la pantalla de inicio de sesión con el aviso.

## Preparación en Supabase

- Ninguna.

## Piezas

- `lib/services/session_service.dart` · **cambia** (T-09, T-10) · `startInactivityTimer(Function() onTimeout)`, `registerActivity()` y `stop()`. T-09 trae el temporizador y la actividad. T-10 trae el cierre que falla.
- `lib/services/auth_service.dart` · **cambia** (T-09, T-10) · `signOut()` cierra la sesión de Auth.
- `lib/screens/app_screen.dart` · **cambia** (T-09, T-10) · escucha el toque, la tecla, la rueda y el arrastre, y llama a `registerActivity()`. Al vencer limpia la sede, la consulta abierta y lo que no se guardó, y muestra "Su sesión se cerró por inactividad". Este cierre no crea evento.
- `lib/screens/app_screen_paginas.dart` · **cambia** (T-09) · el `Listener` que detecta la actividad.

## Estado

- En `SessionService`: el temporizador activo. En la Screen anfitriona: `_usuario`, `_sedeSesion` y el aviso `_avisoInactividad`.
- Después del cierre, *Atrás* no vuelve a ninguna pantalla: la Screen solo deja la página de acceso.

## Datos

- Ninguno en la base. El cierre de sesión no crea evento (F-20).

## Paquetes y plataformas

- Ninguno nuevo.

## Tareas

- **T-09** Cierre a los 15 minutos: temporizador que se reinicia con cualquier acción, cierre de sesión en Auth, sede borrada, aviso y sin evento; al volver a entrar se elige la sede y se vuelve a declarar el propósito. · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6 · depende de: T-04, T-07
  - Prueba: dejar la sesión 15 minutos sin tocar nada y ver el inicio con "Su sesión se cerró por inactividad"; tocar a los 14 minutos y ver que sigue abierta; usar *Atrás* y seguir en el inicio de sesión; entrar otra vez y ver que pide la sede; revisar que la auditoría no tiene un evento del cierre.
- **T-10** Cierre que falla: si el cierre de sesión en Auth falla, la app igual oculta sus pantallas y muestra el inicio de sesión. · CA-7 · depende de: T-09
  - Prueba: con el interruptor *Simular fallas de red* activo, dejar pasar los 15 minutos y comprobar que no se ve ninguna pantalla de la app.

## Preguntas abiertas

- ¿Cuenta como actividad mover el mouse sin hacer clic? Hoy no cuenta.

## Historial

- 0.1.0 · 2026-11-24 · Primera versión.
