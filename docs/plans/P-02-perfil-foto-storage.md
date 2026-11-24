---
id: P-02
titulo: Foto de perfil guardada en Supabase Storage
version: 0.1.0
fecha: 2026-11-24
estado: hecho
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
specs: [F-22]
requisitos: [RF-22, RF-38]
invariantes: [AD-02, AD-03, AD-13, AD-16]
tareas: T-02
---

# P-02 · Foto de perfil guardada en Supabase Storage

## Objetivo

Que cada usuario pueda subir, cambiar y quitar su foto de perfil desde la pantalla *Perfil*, que la foto se guarde en Supabase Storage y que siga ahí al cerrar y volver a abrir la app. Es la parte de Storage de la entrega 3.

## Enfoque técnico

- **Un repositorio con dos implementaciones (AD-02, AD-03).** Una interfaz `FotoPerfilRepositorio` con `descargar`, `subir` y `quitar`. La de Supabase usa Storage y la tabla `usuario`; la de memoria sirve para las pruebas y para correr sin `env.json`. La elección se hace en `fuente_de_datos.dart`.
- **Bucket privado, una carpeta por usuario (AD-16).** El bucket `fotos-perfil` no es público. Cada foto está en `<id_usuario>/foto.<ext>` y las políticas de Storage solo dejan leer, subir, reemplazar y borrar dentro de la carpeta cuyo nombre es el `auth.uid()` de quien pregunta. El bucket lo crea el script SQL, igual que las tablas, y también fija el límite de 2 MB y los tipos JPG y PNG.
- **La ruta queda en `usuario.foto_ruta`.** Al subir, la app guarda el archivo y luego escribe la ruta en la fila del usuario (la política de 001 solo deja cambiar esa columna). Para mostrar la foto se lee la ruta y se descarga el archivo con la sesión del usuario; no hay enlaces públicos ni firmados.
- **Reglas de la foto en un solo lugar.** `lib/reglas/foto.dart` define tipo (JPG, PNG) y tamaño (hasta 2 MB) como funciones puras. La app valida antes de subir, y Storage vuelve a validar por su cuenta.
- **Una sola foto por usuario.** Si cambia de JPG a PNG, la app borra el archivo anterior para que no queden fotos sueltas.
- **El selector es un paquete aparte.** `image_picker` abre la galería o los archivos en web y Android. Va detrás de una interfaz `SelectorFoto` para que las pruebas usen uno falso. Es el segundo paquete externo del proyecto.
- **La Screen manda, la Page muestra.** `AppScreen` guarda los bytes de la foto y los estados de carga, guardado y error; `PerfilPage` solo los pinta y avisa con callbacks. La foto se trae al abrir el perfil y se borra del estado al cerrar sesión.

Alternativas descartadas:

| Alternativa | Por qué no |
|---|---|
| Bucket público con la URL de la foto | Cualquiera con el enlace vería la foto; AD-16 pide privado |
| URL firmada con vencimiento | Hay que renovarla y no aporta nada: la app ya tiene sesión y puede descargar el archivo |
| Guardar la foto en la tabla `usuario` como bytes | Mezcla archivos con datos y no usa Storage |
| Un nombre de archivo distinto cada vez | Dejaría fotos viejas acumuladas en el bucket |

## Componentes

| Pieza | Ruta | Responsabilidad | |
|---|---|---|---|
| Bucket y políticas | `supabase/migraciones/003_fotos_perfil.sql` | Crea el bucket privado y las políticas por carpeta | nuevo |
| Reglas | `lib/reglas/foto.dart` | Valida tipo y tamaño; mensajes de rechazo | nuevo |
| Interfaz | `lib/repositorios/foto_repositorio.dart` | `descargar`, `subir`, `quitar` | nuevo |
| En memoria | `lib/repositorios/foto_memoria.dart` | La foto en memoria, para pruebas | nuevo |
| Supabase | `lib/repositorios/foto_supabase.dart` | Storage y `usuario.foto_ruta` | nuevo |
| Selector | `lib/repositorios/selector_foto.dart` | Interfaz y selector con `image_picker` | nuevo |
| Fuente | `lib/datos/fuente_de_datos.dart`, `lib/main.dart` | Elige el repositorio de fotos | cambia |
| Screen | `lib/screens/app_screen.dart`, `lib/screens/app_screen_foto.dart`, `lib/screens/app_screen_paginas.dart` | Estado de la foto: cargar, subir, quitar | cambia / nuevo |
| Widget | `lib/widgets/foto_perfil.dart` | Tarjeta con la foto, botones y estados | nuevo |
| Page | `lib/pages/perfil_page.dart` | Pone la tarjeta de la foto en el perfil | cambia |
| Pruebas | `test/foto_perfil_test.dart` | Reglas, repositorio en memoria y flujo del perfil | nuevo |

## Cambios

**Se agrega:** el script SQL del bucket, las reglas de la foto, el repositorio (interfaz y dos implementaciones), el selector de imágenes, la tarjeta de la foto y sus pruebas.

**Se modifica:** el perfil (muestra la foto y sus botones), la Screen anfitriona (estado de la foto) y `pubspec.yaml` (agrega `image_picker`).

**No se toca:** los datos de la cuenta, los permisos del rol, el cierre de sesión ni la auditoría: ver o cambiar la foto no crea eventos porque no es información de un paciente.

## Riesgos y decisiones abiertas

- **Sesión puente.** Para leer y escribir en Storage hace falta sesión de Supabase. Hoy la da la sesión puente de P-01; cuando el inicio de sesión use Auth (F-13) sigue funcionando sin cambios, porque el repositorio toma el usuario de `auth.currentUser`.
- **Sin sesión de Supabase no hay foto.** Si la app corre sin `env.json`, la foto vive en memoria y se pierde al cerrar la app.
- **Fotos de otros tamaños.** No se recorta ni se reduce la foto: se acepta hasta 2 MB tal cual. Recortarla queda fuera de alcance.
- **El nombre del archivo en web.** El selector del navegador puede no dar la extensión; en ese caso se usa el tipo MIME. Si tampoco sirve, la foto se rechaza como no válida.

## Verificación

- `flutter analyze` y `flutter test` pasan.
- En *Storage* de Supabase está el bucket `fotos-perfil`, privado.
- Como Marcela: *Subir foto* con un PNG de menos de 2 MB muestra la foto; en *Storage* aparece `<id>/foto.png` y `usuario.foto_ruta` tiene esa ruta. Cerrar la app y volver a entrar la conserva.
- *Cambiar foto* a un JPG deja un solo archivo en la carpeta; *Quitar foto* la borra y deja `foto_ruta` vacía.
- Un GIF o un archivo de más de 2 MB se rechaza con su mensaje y no cambia nada.
- Como Camila, la foto de Marcela no se ve; un intento de leer su archivo con la sesión de Camila falla.
- F-22 CA-12 a CA-18.

## Historial

- 0.1.0 · 2026-11-24 · Primera versión.
