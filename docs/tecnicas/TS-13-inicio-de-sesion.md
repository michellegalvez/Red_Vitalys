---
id: TS-13
titulo: Inicio de sesión con la sede asignada
version: 0.1.0
fecha: 2026-11-24
estado: borrador
funcional: F-13 0.4.3
---

# TS-13 · Inicio de sesión con la sede asignada

## Resumen

El inicio de sesión deja de comparar contra los usuarios simulados y valida con Supabase Auth. El rol y las sedes salen de la base (`usuario`, `usuario_sede`), nunca de Auth (AD-04). Un servicio de autenticación devuelve el resultado y la Screen anfitriona decide qué pantalla muestra.

## Preparación en Supabase

- Correr, en este orden y una sola vez, `supabase/migraciones/001_base_y_auditoria.sql` y `002_usuarios_de_prueba.sql`.
- Crear en *Authentication → Users* los 4 correos de la tabla *Cuentas de prueba* del README, con la contraseña `vitalys2026` y *Auto Confirm User* marcado.
- Política en `evento_auditoria` que deje a quien no tiene sesión insertar solo eventos de la acción *Ingresar* con resultado *Denegado* (un intento fallido todavía no tiene sesión). La IP la pone la base (AD-15).
- Datos de prueba (CA-11): un usuario por rol con al menos una sede, un usuario con 2 sedes y `tomas.herrera@vitalys.co` sin sedes.

## Piezas

- `lib/services/auth_service.dart` · **nueva** (T-03) · servicio. `signIn(String email, String password) → Future<SignInResult>`; `signOut() → Future<void>`. Valida con Auth, lee `usuario` y `usuario_sede` y arma el `Usuario` existente.
- `lib/models/sign_in_result.dart` · **nueva** (T-03) · modelo. Estado (`success`, `wrongCredentials`, `noSites`, `networkError`), el `Usuario` y sus sedes.
- `lib/screens/app_screen.dart` · **cambia** (T-03, T-04, T-05, T-06) · el estado del acceso (`_usuarioValidado`, `_paso`, `_sedeElegida`, `_mensajeError`) lo sigue guardando la Screen. T-03 usa el servicio en lugar de `datos.usuarioPorCorreo`. T-04 confirma la sede y abre la sesión. T-05 crea los eventos *Denegado*.
- `lib/pages/acceso_page.dart` · **cambia** (T-06) · formulario. Valida campos vacíos antes de llamar al servicio.
- `lib/datos/fuente_de_datos.dart` · **cambia** (T-03) · elige `AuthService` de Supabase o la versión en memoria para las pruebas (AD-02).
- `lib/repositorios/auditoria_repositorio.dart` · **sin cambio** · ya agrega eventos. T-04 y T-05 lo usan.

## Estado

- Screen anfitriona: `_usuarioValidado` (quién validó sus datos y todavía no confirma sede), `_paso` (credenciales o sede), `_sedeElegida`, `_sedeSesion` (la sede de la sesión, AD-05) y `_mensajeError`.
- Los datos suben a la Screen con funciones: el formulario entrega `onSignIn(email, password)` y no guarda el dato.

## Datos

- Tablas `usuario` (`id_usuario`, `id_rol`, `nombre_completo`, `correo`, `activo`), `usuario_sede` (`id_usuario`, `id_sede`), `sede`, `rol` y `evento_auditoria`.
- La sede de la sesión vive en la app, no en Auth.

## Paquetes y plataformas

- `supabase_flutter` · ya está. Sin paquetes nuevos ni permisos nuevos en Android o web.

## Tareas

- **T-03** Servicio de autenticación: validar con Supabase Auth, leer rol y sedes de la base y devolver el resultado. · CA-1, CA-2, CA-3, CA-4, CA-5, CA-9 · depende de: ninguna
  - Prueba: entrar como la Dra. Camila y ver exactamente sus 2 sedes; con una contraseña equivocada y con un correo que no existe ver "Correo o contraseña incorrectos"; con una sola sede ver que aparece elegida; sin red ver "No se pudo iniciar sesión. Intente de nuevo." y el correo sigue escrito.
- **T-04** Confirmar la sede y abrir la sesión: guardar la sede en la sesión, crear el evento *Ingresar* *Permitido* antes de abrir y llevar a la pantalla inicial del rol. · CA-10, CA-12, CA-13 · depende de: T-03
  - Prueba: ingresar con cada rol y ver su pantalla inicial; entrar como auditor y ver el evento con la sede; validar los datos y volver sin confirmar la sede y comprobar que no queda un evento *Permitido*.
- **T-05** Eventos de ingreso denegado: datos incorrectos, correo inexistente y cuenta sin sedes dejan un evento *Denegado* con el correo, la IP puesta por la base y sin sede. · CA-6, CA-7 · depende de: T-03
  - Prueba: fallar un ingreso y ver en la auditoría el evento con el correo escrito, la IP y la sede vacía; ingresar como `tomas.herrera@vitalys.co` y ver "Su cuenta no tiene sedes asignadas" y su evento.
- **T-06** Campos vacíos y usuarios de prueba: no se intenta ingresar si falta el correo o la contraseña, y la base trae un usuario por rol, uno con 2 sedes y uno sin sedes. · CA-8, CA-11 · depende de: T-03
  - Prueba: dejar el correo vacío y ver "Escriba su correo y su contraseña" sin evento; revisar los 4 usuarios con sus sedes.

## Preguntas abiertas

- ¿Qué pasa si `usuario.activo` es falso? F-13 no lo dice.
- ¿Se debe cerrar la sesión de Auth si el usuario abandona antes de elegir la sede (A6)? Hoy la sesión de Auth quedaría abierta.

## Historial

- 0.1.0 · 2026-11-24 · Primera versión.
