---
id: F-22
titulo: Perfil del usuario
version: 0.3.2
fecha: 2026-11-27
estado: implementada
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-22, RF-38]
depende_de: [F-18]
---

# F-22 · Perfil del usuario

## Objetivo

Cualquier usuario (médico, administrativo o auditor) ve con qué cuenta, con qué rol y desde qué sede está trabajando, y qué puede hacer y qué no con su rol (O-05). Además puede tener una foto de perfil, que ve y cambia desde ahí.

## Flujo principal

1. El usuario entra a *Perfil*.
2. El sistema muestra su foto de perfil (o sus iniciales si no tiene), su nombre, su correo, su rol, la sede de esta sesión y las sedes que tiene asignadas.
3. El sistema muestra la lista *Qué puede hacer con su rol*, con cada acción marcada como *Permitido* o *No incluido*, y los propósitos que su rol puede declarar.
4. El perfil muestra la nota: "El acceso también depende de la sede desde la que ingresó y del propósito que declare en cada consulta."
5. El perfil ofrece la opción *Cerrar sesión* (F-23).

## Flujos alternos

- **A1 · Otro rol:** si el usuario es administrativo o auditor, la lista tiene las mismas acciones en el mismo orden, marcadas según la tabla de *Reglas*.
- **A2 · Subir o cambiar la foto:** el usuario elige *Subir foto* (o *Cambiar foto* si ya tiene una) y escoge una imagen de su dispositivo. Si cumple las reglas, el sistema la guarda, reemplaza la anterior y la muestra.
- **A3 · Quitar la foto:** el usuario elige *Quitar foto*. El sistema la borra y vuelve a mostrar sus iniciales.
- **A4 · Foto no válida:** si la imagen no es JPG ni PNG, pesa más de 2 MB o está vacía, el sistema no la guarda, conserva la foto anterior y muestra el motivo: "La foto debe ser JPG o PNG." o "La foto pesa más de 2 MB.".
- **A5 · No se pudo guardar:** si la foto no se puede guardar, se ve "No se pudo guardar su foto. Inténtelo de nuevo." y la foto anterior sigue igual.
- **A6 · Cancelar:** si el usuario cierra el selector sin elegir, no cambia nada.

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
- El usuario no puede cambiar su rol, su sede ni sus datos desde el perfil, salvo su foto.
- La foto es JPG o PNG y pesa hasta 2 MB. Cada usuario tiene una sola; subir otra reemplaza la anterior.
- Cada usuario solo ve y cambia su propia foto. Nadie más puede leerla ni cambiarla, ni siquiera otro usuario con sesión.
- La foto se guarda en un almacenamiento privado (AD-16) y sigue ahí al cerrar y volver a abrir la app.
- Ver o cambiar la foto no crea un evento de acceso, porque no es información de un paciente.
- Ver el perfil no crea un evento de acceso, porque no es información de un paciente.

## Estados

- **Cargando:** mientras llegan los datos, se ve "Cargando perfil…". La foto tiene su propio "Cargando foto…" y, mientras se guarda, el botón dice "Guardando…" y no se puede volver a pulsar.
- **Vacío:** no aplica, porque siempre hay un usuario con sesión iniciada.
- **Error:** si los datos no se pueden cargar, se ve "No se pudo cargar su perfil" con la opción *Reintentar*. La opción *Cerrar sesión* sigue disponible.
- **Error de la foto:** si la foto no se puede cargar, se ve "No se pudo cargar su foto" con *Reintentar*, y el resto del perfil se ve igual.

## Datos

- **Foto de perfil** del usuario, opcional. Sin ella se ven sus iniciales.
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
- **CA-12** Dado un usuario sin foto, cuando abre el perfil, entonces ve sus iniciales y el botón *Subir foto*, y no ve *Quitar foto*.
- **CA-13** Dado un usuario que elige un PNG de 500 KB, cuando la sube, entonces ve su foto en el perfil, el botón pasa a *Cambiar foto* y, si cierra la app y vuelve a entrar, la foto sigue ahí.
- **CA-14** Dado un usuario con foto, cuando elige *Quitar foto*, entonces vuelve a ver sus iniciales y, al volver a entrar, no hay foto.
- **CA-15** Dado un usuario que elige un archivo GIF o un JPG de 3 MB, cuando intenta subirlo, entonces ve "La foto debe ser JPG o PNG." o "La foto pesa más de 2 MB." y su foto anterior no cambia.
- **CA-16** Dado un usuario con foto, cuando sube otra distinta, entonces solo se ve la nueva y la anterior ya no está guardada.
- **CA-17** Dado que Marcela tiene foto, cuando otro usuario con sesión intenta leer o cambiar el archivo de Marcela, entonces el sistema se lo niega.
- **CA-18** Dado que la foto no se puede guardar, cuando el usuario la sube, entonces ve "No se pudo guardar su foto. Inténtelo de nuevo." y su foto anterior sigue igual.

## Fuera de alcance

- Editar el nombre, el correo o la contraseña.
- Recortar o girar la foto, o tomarla con la cámara.
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
- 0.3.0 · 2026-11-24 · Foto de perfil guardada en Supabase Storage (A2 a A6, CA-12 a CA-18) y requisito RF-38.
- 0.3.1 · 2026-11-27 · Implementada en la entrega 3 con Supabase (main 499e3e7). Pendiente: el error al cargar el perfil (CA-8) solo se ve en el modo de demostración.
- 0.3.2 · 2026-11-27 · Resuelto lo pendiente: con Supabase el perfil se vuelve a leer de la base y, si falla, se ve "No se pudo cargar su perfil" con Reintentar y Cerrar sesión (CA-8).
