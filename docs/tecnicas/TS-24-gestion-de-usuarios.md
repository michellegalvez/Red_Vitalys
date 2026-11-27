---
id: TS-24
titulo: Registro de cuentas y gestión de usuarios
version: 0.1.0
fecha: 2026-11-27
estado: borrador
funcional: F-24 0.1.0
---

# TS-24 · Registro de cuentas y gestión de usuarios

## Resumen

Una persona crea su cuenta desde el acceso con Supabase Auth (`signUp`). El disparador de Gabriela (`011`) la deja como médico sin sedes, así que no entra hasta que el director le asigne rol y sedes. El director gestiona las cuentas en la sección *Usuarios* y cada cambio pasa por la función `guardar_cuenta` de la base, que valida, crea el evento y guarda en una sola operación (AD-07).

## Preparación en Supabase

- Correr `supabase/migraciones/013_director.sql`: rol `director`, recurso `usuario` en la auditoría con la cuenta que cambió, la función `guardar_cuenta`, la cuenta `direccion@vitalys.co` y los indicadores solo para los otros tres roles.
- El registro público tiene que estar abierto (*Authentication → Sign In / Providers → Allow new users to sign up*). Sin él, *Crear cuenta* falla.
- Supabase pide confirmar el correo de una cuenta nueva. Con un correo real llega el enlace; con los de prueba no hay cómo confirmarla.

## Piezas

- `lib/services/account_service.dart` · **nueva** (T-25, T-26) · servicio. `signUp`, `listAccounts` y `saveAccount`, con su versión en memoria (que el inicio de sesión simulado también lee) y la de Supabase. La base rechaza con los mensajes `propia`, `sin_sedes` y `rol`, que la app traduce.
- `lib/reglas/cuentas.dart` · **nueva** (T-25, T-26) · reglas puras: validar el registro y el cambio, y los textos de F-24.
- `lib/pages/crear_cuenta_page.dart` · **nueva** (T-25) · formulario de registro; guarda solo lo que se escribe.
- `lib/pages/usuarios_page.dart` y `lib/pages/editar_cuenta_page.dart` · **nuevas** (T-26) · la lista con el filtro *Pendientes* y el editor de rol, sedes y cuenta activa.
- `lib/screens/app_screen_cuentas.dart` · **nueva** (T-26) · parte de la Screen anfitriona: cargar, abrir y guardar cuentas. El estado vive en `_AppScreenState`.
- `lib/modelos/modelos.dart`, `lib/reglas/reglas.dart`, `lib/screens/secciones.dart` · **cambian** (T-27) · el rol `director`, la acción *Gestionar usuarios*, el recurso *Usuario* y la sección *Usuarios*, su pantalla inicial (RF-37).
- `lib/services/auth_supabase.dart`, `lib/services/auth_memory.dart` · **cambian** (T-27) · reconocen el rol `director`; en memoria, el inicio de sesión lee las cuentas del servicio.
- `lib/repositorios/auditoria_supabase.dart`, `lib/pages/auditoria_page.dart` · **cambian** (T-28) · leen y muestran la cuenta que cambió.

## Estado

- Screen anfitriona: `_listaCuentas`, `_cargandoCuentas`, `_errorCuentas`, `_pedidoCuentas`, `_cuentaAbierta`, `_soloPendientes` y `_registrando`. Al cerrar sesión se borran.
- Las Pages guardan solo lo que se escribe o elige y lo suben con `onCrear` y `onGuardar`, que devuelven el mensaje de error o `null`.

## Datos

- `usuario` (`id_rol`, `activo`), `usuario_sede`, `rol` y `evento_auditoria` (`tipo_recurso = 'usuario'`, `id_usuario_afectado`, sin llave foránea para no volver ambigua la consulta de la auditoría).

## Paquetes y plataformas

- Sin paquetes nuevos ni permisos nuevos.

## Tareas

- **T-25** Crear una cuenta desde el acceso. · CA-1, CA-2, CA-3, CA-4 · depende de: ninguna
  - Prueba: crear una cuenta con un correo real y ver el mensaje de cuenta creada; con un correo de prueba ya registrado ver "Ya existe una cuenta con ese correo."; con 7 caracteres ver el aviso de la contraseña.
- **T-26** La sección *Usuarios* del director: lista, pendientes primero, editor y guardado con su evento. · CA-5, CA-6, CA-7, CA-8, CA-11 · depende de: T-25, T-27
  - Prueba: entrar como `direccion@vitalys.co`, aprobar una cuenta pendiente como médico en Cali Norte y que esa persona entre desde Cali Norte; intentar dejar una cuenta activa sin sedes y quitarse el propio rol.
- **T-27** El rol Director en la tabla de permisos, el inicio de sesión y su pantalla inicial. · CA-9, CA-10, CA-12 · depende de: ninguna
  - Prueba: entrar como directora y ver *Usuarios*; su perfil muestra solo *Gestionar usuarios* y *Ver el perfil y cerrar sesión*; desactivar una cuenta y ver que ya no entra.
- **T-28** La auditoría muestra los cambios de cuentas con la cuenta que cambió. · CA-6 · depende de: T-26
  - Prueba: después de aprobar una cuenta, entrar como auditora y ver *Registrar · Usuario* con "Cuenta" y el correo.

## Preguntas abiertas

- La cuenta de la directora la crea el script 013 directamente en Auth, porque desde la app las cuentas nuevas quedan pendientes y alguien tiene que ser el primer director.

## Historial

- 0.1.0 · 2026-11-27 · Primera versión.
