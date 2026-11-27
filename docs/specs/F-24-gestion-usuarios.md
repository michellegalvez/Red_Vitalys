---
id: F-24
titulo: Registro de cuentas y gestión de usuarios
version: 0.1.0
fecha: 2026-11-27
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-39, RF-40]
depende_de: [F-13, F-18, F-20]
---

# F-24 · Registro de cuentas y gestión de usuarios

## Objetivo

Una persona que trabaja en la red crea su cuenta desde la pantalla de acceso, y el director la aprueba asignándole un rol y las sedes desde las que puede ingresar, para que nadie entre a la app sin que la Dirección lo autorice (O-05).

## Flujo principal

1. En la pantalla de acceso, la persona elige *Crear cuenta*.
2. Escribe su nombre completo, su correo y una contraseña de al menos 8 caracteres, la repite y elige *Crear cuenta*.
3. El sistema crea la cuenta sin sedes, le envía un enlace para confirmar el correo y le muestra "Cuenta creada. Confirme su correo y espere a que la Dirección la apruebe."
4. El director inicia sesión y entra a *Usuarios*, donde ve todas las cuentas, primero las que esperan aprobación.
5. Elige una cuenta, le asigna un rol y al menos una sede y elige *Guardar*.
6. El sistema crea el evento del cambio y, si pudo crearlo, guarda el rol y las sedes (F-20).
7. La persona inicia sesión, elige una de sus sedes y entra a la pantalla inicial de su rol (F-13).

## Flujos alternos

- **A1 · Correo ya registrado:** el sistema no crea otra cuenta y muestra "Ya existe una cuenta con ese correo."
- **A2 · Datos que no sirven:** con el nombre vacío, un correo sin formato de correo, una contraseña de menos de 8 caracteres o dos contraseñas distintas, se muestra el mensaje del campo y no se crea la cuenta.
- **A3 · Ingresa antes de la aprobación:** la cuenta no tiene sedes, así que ve el mensaje de la cuenta sin sedes de F-13 A3 y no entra.
- **A4 · Cambiar una cuenta aprobada:** el director le cambia el rol o las sedes, o la desactiva. Una cuenta desactivada no puede iniciar sesión y ve "Correo o contraseña incorrectos" (F-13).
- **A5 · El director sobre su propia cuenta:** no puede quitarse el rol de director ni desactivarse. Ve "No puede quitarse su propio rol ni desactivar su cuenta." y no se guarda nada.
- **A6 · Sin sedes:** si guarda una cuenta activa sin ninguna sede, ve "Asigne al menos una sede." y no se guarda nada.
- **A7 · Otro rol intenta gestionar usuarios:** el sistema lo rechaza con "Su rol no permite esta acción." y crea un evento *Denegado* (F-18).

## Reglas

- Solo el director gestiona usuarios. No ve pacientes, historias, el tablero de indicadores ni la auditoría de accesos.
- El director no declara propósitos, porque no consulta información de pacientes.
- Los roles que se pueden asignar son médico, administrativo, auditor y director.
- Una cuenta nueva queda sin sedes hasta que el director le asigne al menos una. Mientras tanto es una cuenta pendiente.
- Cada cambio de rol, de sedes o de cuenta activa crea un evento *Registrar · Usuario · Permitido* con el director, su sede y la cuenta que cambió. El evento se crea antes de guardar el cambio; si no se puede crear, el cambio no se guarda (F-20).
- Ver la lista de cuentas no crea un evento.
- El correo de una cuenta no se cambia desde la app.
- Los datos de prueba incluyen al director, con el correo direccion@vitalys.co (RNF-04).

## Estados

- **Cargando:** se ve "Cargando usuarios…". Mientras se crea una cuenta, el botón dice "Creando cuenta…"; mientras se guarda un cambio, dice "Guardando…". En los dos casos no se puede volver a pulsar.
- **Vacío:** con el filtro *Pendientes* y ninguna cuenta pendiente, se ve "No hay cuentas que esperen aprobación."
- **Error:** si la lista no se puede cargar, se ve "No se pudieron cargar los usuarios" con *Reintentar*. Si el cambio no se puede guardar, se ve "No se pudo guardar el cambio. Intente de nuevo." y se conserva lo elegido. Si la cuenta no se puede crear, se ve "No se pudo crear la cuenta. Intente de nuevo." y se conserva lo escrito, salvo las contraseñas.

## Datos

- **Cuenta:** nombre completo, correo, rol, sedes asignadas y si está activa.
- **Cuenta pendiente:** una cuenta activa sin sedes asignadas.

## Criterios de aceptación

- **CA-1** Dado que una persona no tiene cuenta, cuando crea una con su nombre, su correo y una contraseña de 8 caracteres o más, entonces ve "Cuenta creada. Confirme su correo y espere a que la Dirección la apruebe." y la cuenta aparece en *Usuarios* como pendiente.
- **CA-2** Dado un correo que ya tiene cuenta, cuando alguien crea otra con ese correo, entonces ve "Ya existe una cuenta con ese correo." y no se crea.
- **CA-3** Dada una contraseña de 7 caracteres, cuando la persona intenta crear la cuenta, entonces ve "La contraseña debe tener al menos 8 caracteres." y no se crea.
- **CA-4** Dada una cuenta pendiente, cuando inicia sesión con sus datos correctos, entonces ve el mensaje de la cuenta sin sedes de F-13 A3 y no entra.
- **CA-5** Dado el director, cuando abre *Usuarios*, entonces ve todas las cuentas con su nombre, su correo, su rol, sus sedes y si está activa, con las pendientes primero.
- **CA-6** Dada una cuenta pendiente, cuando el director le asigna el rol médico y la sede Cali Norte y guarda, entonces queda el evento *Registrar · Usuario · Permitido* y la persona puede iniciar sesión desde Cali Norte.
- **CA-7** Dado el director, cuando guarda una cuenta activa sin ninguna sede, entonces ve "Asigne al menos una sede." y la cuenta no cambia.
- **CA-8** Dado el director, cuando intenta quitarse su rol o desactivar su propia cuenta, entonces ve "No puede quitarse su propio rol ni desactivar su cuenta." y la cuenta no cambia.
- **CA-9** Dada una cuenta desactivada, cuando inicia sesión con sus datos correctos, entonces no entra y ve "Correo o contraseña incorrectos".
- **CA-10** Dado un médico, un administrativo o un auditor, cuando intenta gestionar usuarios, entonces el sistema lo rechaza con "Su rol no permite esta acción." y queda un evento *Denegado*.
- **CA-11** Dado que el evento del cambio no se puede crear, cuando el director guarda, entonces ve "No se pudo guardar el cambio. Intente de nuevo." y la cuenta no cambia.
- **CA-12** Dado el director, cuando inicia sesión, entonces entra a *Usuarios*, y su perfil muestra *Gestionar usuarios* y *Ver el perfil y cerrar sesión* como *Permitido* y las demás acciones como *No incluido*.

## Fuera de alcance

- Recuperar la contraseña.
- Cambiar el correo de una cuenta.
- Borrar cuentas: se desactivan.
- Que el director vea pacientes, el tablero de indicadores o la auditoría de accesos.
- Invitar a una persona por correo para que cree su cuenta.

## Preguntas abiertas

- ¿Hace falta confirmar el correo para que la cuenta nueva pueda entrar? Hoy sí, y con los correos de prueba, que no existen, la cuenta no se puede confirmar.
- ¿Un director puede quitarle el rol de director a otro director? Hoy sí.

## Historial

- 0.1.0 · 2026-11-27 · Primera versión: registro de cuentas desde el acceso y rol Director que las aprueba y gestiona (RF-39, RF-40).
