---
id: F-22
titulo: Perfil y permisos del rol
version: 0.1.1
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-22]
depende_de: []
---

# F-22 · Perfil y permisos del rol

## Objetivo

Cualquier usuario (médico, administrativo o auditor) ve con qué cuenta, con qué rol y desde qué sede está trabajando, y qué puede hacer y qué no con su rol (O-05).

## Flujo principal

1. El usuario entra a *Perfil*.
2. El sistema muestra su nombre, su correo, su rol y la sede de esta sesión.
3. El sistema muestra la lista *Qué puede hacer con su rol*, con cada acción marcada como *Permitido* o *No incluido*.
4. Debajo de la lista se ve la nota: "El acceso también depende de la sede desde la que ingresó y del propósito que declare en cada consulta."
5. Debajo se ve la opción *Cerrar sesión* (F-23).

## Flujos alternos

- **A1 · Otro rol:** si el usuario es administrativo o auditor, la lista tiene las mismas acciones en el mismo orden, marcadas según la tabla de *Reglas*.

## Reglas

- Todos los roles pueden ver su propio perfil.
- El perfil solo muestra datos de la persona que inició sesión.
- La sede que se muestra es la que el usuario eligió al iniciar sesión.
- La lista tiene siempre las mismas 7 acciones, en este orden, para los 3 roles:

| Acción | Médico | Administrativo | Auditor |
|---|---|---|---|
| Consultar datos básicos de pacientes | Permitido | Permitido | No incluido |
| Consultar pacientes y su historia | Permitido | No incluido | No incluido |
| Ver el riesgo de reingreso y su explicación | Permitido | No incluido | No incluido |
| Registrar atenciones | Permitido | No incluido | No incluido |
| Ver el tablero de indicadores | Permitido | Permitido | Permitido |
| Registrar mediciones de indicadores | No incluido | Permitido | No incluido |
| Ver la auditoría de accesos | No incluido | No incluido | Permitido |

- La lista sale de las mismas reglas que el sistema aplica para permitir o denegar cada acción. Si una acción está *Permitido* en el perfil, el sistema la permite. Si está *No incluido*, el sistema la deniega.
- El usuario no puede cambiar su rol, su sede ni sus datos desde el perfil.
- Ver el perfil no crea un evento de acceso, porque no es información de un paciente.

## Estados

- **Cargando:** mientras llegan los datos, se ve "Cargando perfil…".
- **Vacío:** no aplica, porque siempre hay un usuario con sesión iniciada.
- **Error:** si los datos no se pueden cargar, se ve "No se pudo cargar su perfil" con la opción *Reintentar*. La opción *Cerrar sesión* sigue disponible.

## Datos

- **Nombre** del usuario, por ejemplo "Dra. Camila Martínez".
- **Correo** institucional, por ejemplo "camila.martinez@vitalys.co".
- **Rol:** *Médico*, *Administrativo* o *Auditor*.
- **Sede de esta sesión**, por ejemplo "Clínica Vitalys Cali Norte".
- **Lista de acciones** del rol, cada una con su marca: *Permitido* o *No incluido*.

## Criterios de aceptación

- **CA-1** Dado que la Dra. Camila Martínez, médica, ingresó desde Clínica Vitalys Cali Norte, cuando abre el perfil, entonces ve su nombre, su correo camila.martinez@vitalys.co, el rol *Médico* y la sede Clínica Vitalys Cali Norte.
- **CA-2** Dado un médico, cuando abre el perfil, entonces ve como *Permitido* consultar datos básicos de pacientes, consultar pacientes y su historia, ver el riesgo de reingreso y su explicación, registrar atenciones y ver el tablero de indicadores, y como *No incluido* registrar mediciones de indicadores y ver la auditoría de accesos.
- **CA-3** Dado un administrativo, cuando abre el perfil, entonces ve como *Permitido* consultar datos básicos de pacientes, ver el tablero de indicadores y registrar mediciones de indicadores, y como *No incluido* las otras 4 acciones.
- **CA-4** Dado un auditor, cuando abre el perfil, entonces ve como *Permitido* ver el tablero de indicadores y ver la auditoría de accesos, y como *No incluido* las otras 5 acciones.
- **CA-5** Dado un usuario de cualquier rol, cuando intenta una acción que su perfil muestra como *No incluido*, entonces el sistema la rechaza. Dado que intenta una que se muestra como *Permitido*, el sistema la deja hacer.
- **CA-6** Dado un usuario que ingresó desde una sede, cuando cierra sesión, vuelve a entrar desde otra sede y abre el perfil, entonces ve la sede nueva.
- **CA-7** Dado cualquier usuario, cuando abre el perfil, entonces ve la nota sobre la sede y el propósito debajo de la lista.
- **CA-8** Dado que los datos del perfil no se pueden cargar, cuando el usuario abre el perfil, entonces ve "No se pudo cargar su perfil", puede elegir *Reintentar* y todavía puede cerrar sesión.

## Fuera de alcance

- Editar el nombre, el correo o la contraseña.
- Cambiar de rol o de sede sin cerrar sesión.
- Crear, editar o desactivar usuarios y roles.
- Cerrar sesión, que es F-23.

## Preguntas abiertas

- ¿Los textos de los estados de carga y de error son los definitivos? Son una propuesta: la captura no los muestra.
- ¿El perfil debe mostrar alguna diferencia según la sede, o la lista de acciones depende solo del rol? Está ligado a las preguntas abiertas del PRD sobre la sede.

## Historial

- 0.1.0 · 2026-11-05 · Primera versión.
- 0.1.1 · 2026-11-06 · Autores: los 4 integrantes del equipo.
