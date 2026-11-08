---
documento: requisitos
proyecto: Red Vitalys
version: 0.7.7
fecha: 2026-11-08
estado: borrador
basado_en: prd 0.7.6
---

# Requisitos · Red Vitalys

## Funcionales

### O-01 · Ver al paciente unificado

- **RF-01** El sistema debe permitir que el médico y el administrativo busquen a un paciente por nombre o por número de documento. *Debe*
- **RF-02** El sistema debe permitir que el médico vea la historia unificada de un paciente, con sus datos, su identificador en cada sistema de origen y sus atenciones en todas las sedes. *Debe*
- **RF-03** El sistema debe permitir que el administrativo consulte los datos básicos de un paciente, sin mostrarle la historia clínica ni el riesgo de reingreso. *Debe*
- **RF-04** El sistema debe permitir que el médico registre una atención de un paciente, que pasa a formar parte de su historia unificada. El médico declara el propósito: *Atención del paciente* si tiene relación con el paciente, o *Urgencia* si no la tiene (RF-25). La sede propuesta es la de la sesión, y el médico puede elegir otra. *Debe*
- **RF-24** El sistema debe permitir que el médico consulte pacientes atendidos en cualquier sede de la red, declarando el propósito de la consulta. *Debe*
- **RF-25** El sistema debe considerar que un médico tiene relación con un paciente si registró al menos una atención suya declarando *Atención del paciente* o si el paciente fue dado de alta en una de las sedes asignadas al médico en los últimos 30 días. Una atención registrada con *Urgencia* no da relación, ni por la atención ni por el alta que lleve. Sin relación, el médico solo puede consultar la historia o registrar una atención declarando *Urgencia* (RF-20). *Debe*

### O-02 · Anticipar el reingreso

- **RF-05** El sistema debe permitir que el médico vea a los pacientes de toda la red dados de alta en los últimos 30 días, ordenados de mayor a menor riesgo de reingreso, con el riesgo en una escala de 0 a 100. *Debe*
- **RF-06** El sistema debe marcar con una alerta a los pacientes con riesgo de reingreso de 70 o más. *Debe*
- **RF-07** El sistema debe permitir que el médico vea los factores que suben o bajan el riesgo de reingreso de un paciente y cuántos puntos aporta cada uno. *Debe*

### O-03 · Comparar la calidad entre sedes

- **RF-08** El sistema debe permitir que el médico, el administrativo y el auditor vean de cada uno de los 4 indicadores (reingreso a 30 días, tiempo de espera, adherencia a protocolos clínicos y eventos adversos evitables) el valor del último periodo, su categoría (*Resultado*, *Estructura* o *Proceso*) y su cambio frente al periodo anterior. *Debe*
- **RF-09** El sistema debe marcar cada sede como *Mejor que el promedio*, *Peor que el promedio* o *Igual al promedio* de la red en cada indicador, según la dirección de la *Tabla de indicadores* y comparando los valores redondeados a 1 decimal. *Debe*
- **RF-26** El sistema debe calcular el promedio de la red de un indicador como el promedio simple de las sedes que tienen medición en ese periodo. Una sede sin medición se muestra como *Sin medición* y no entra en el promedio. *Debe*
- **RF-27** El sistema debe mostrar el cambio frente al periodo anterior como la diferencia en la unidad del indicador, por ejemplo "−1,2 puntos" o "+5 min", calculada con los valores redondeados a 1 decimal. Junto al cambio se ve *Mejora*, *Empeora* o *Sin cambio* según la dirección del indicador. *Debe*
- **RF-10** El sistema debe permitir que el usuario vea, en el detalle de un indicador, la tendencia mensual de los últimos 6 periodos, de toda la red o de la sede que elija. *Debe*
- **RF-11** El sistema debe permitir que el usuario vea, en el detalle de un indicador, la comparación entre sedes del último periodo, con el promedio de la red como referencia. *Debe*
- **RF-12** El sistema debe permitir que el usuario vea, en el detalle de un indicador, las mediciones recientes con la sede, el periodo, el valor y si está mejor, peor o igual que el promedio de la red. *Debe*
- **RF-13** El sistema debe permitir que el administrativo registre la medición mensual de un indicador para cualquier sede de la red, digitando el valor ya calculado por la sede. El sistema no calcula ese valor. *Debe*
- **RF-28** El sistema debe rechazar una medición con un valor fuera del rango de su indicador según la *Tabla de indicadores*, o con más de 1 decimal. *Debe*
- **RF-29** El sistema debe rechazar una medición de un mes que todavía no termina, o de un indicador que ya tiene medición para esa sede en ese mes. *Debe*
- **RF-30** El sistema debe rechazar una medición de un indicador que no aplica al tipo de sede según la *Tabla de indicadores*. *Debe*

### O-04 · Rastrear cada acceso

- **RF-14** El sistema debe registrar cada inicio de sesión, exitoso o fallido, cada consulta o registro sobre la información de un paciente, cada registro de una medición, cada apertura de la lista de pacientes con alta reciente y toda acción denegada, con quién, cuándo, la acción, el recurso, el propósito, el resultado (permitido o denegado) y la sede de ingreso, excepto en un inicio de sesión fallido, que todavía no tiene sesión. La búsqueda de pacientes, que solo muestra nombre y documento, no se registra, salvo que el rol la rechace: entonces queda como acción denegada. Abrir la historia de un paciente crea dos eventos, el de *Historia clínica* y el de *Riesgo de reingreso*. Un ingreso con credenciales correctas y sin sedes asignadas queda como inicio de sesión fallido y no suma al conteo del bloqueo. No son eventos el intento de ingreso con el correo o la contraseña vacíos ni la medición ni la atención que la validación rechaza, porque no llegan a ejecutarse. El evento se crea antes de ejecutar la acción; el del inicio de sesión exitoso, al confirmar la sede y antes de abrir la sesión. Si el evento no se puede crear, la acción no se hace. *Debe*
- **RF-31** El sistema debe registrar en un inicio de sesión fallido el correo con el que se intentó y la dirección IP desde la que se hizo, tal como la ve el sistema. En la entrega 2 la IP es un dato simulado. *Debe*
- **RF-15** El sistema debe permitir que el auditor consulte el registro de accesos. *Debe*
- **RF-16** El sistema debe permitir que el auditor filtre los accesos denegados y los de emergencia. *Debe*
- **RF-17** El sistema debe impedir que cualquier usuario edite o borre un registro de acceso. *Debe*

### O-05 · Acceso según rol, sede y propósito

- **RF-32** El sistema debe permitir que el usuario inicie sesión con su correo institucional y su contraseña. *Debe*
- **RF-33** El sistema debe rechazar un inicio de sesión con datos incorrectos sin decir cuál de los dos datos falló. *Debe*
- **RF-36** El sistema debe bloquear el inicio de sesión en un dispositivo durante 15 minutos después de 5 intentos fallidos seguidos en él, sin importar el correo, y mostrar "Demasiados intentos fallidos. Intente de nuevo en 15 minutos." El inicio de sesión se desbloquea solo al pasar ese tiempo y nadie puede desbloquearlo antes. *Debe*
- **RF-18** El sistema debe permitir que el usuario inicie sesión eligiendo la sede desde la que ingresa, solo entre las sedes que tiene asignadas. Si no tiene ninguna, no puede ingresar. *Debe*
- **RF-19** El sistema debe exigir que el usuario declare uno de estos propósitos para consultar la información de un paciente, abrir la lista de pacientes con alta reciente o registrar una atención: *Atención del paciente*, *Consulta de historia clínica*, *Seguimiento de reingreso*, *Revisión de calidad* o *Urgencia*. Al registrar una atención solo se ofrecen *Atención del paciente* y *Urgencia*. Las acciones sin propósito, como el inicio de sesión, el registro de una medición o un rechazo por rol, se registran con *No aplica*. *Debe*
- **RF-20** El sistema debe permitir que el médico declare *Urgencia* para ver la historia de un paciente, o registrarle una atención, cuando no tiene relación con él (RF-25), y debe marcar ese acceso como emergencia y avisarle al médico que queda registrado. *Debe*
- **RF-34** El sistema debe aplicar la *Tabla de permisos*, que define qué acciones puede hacer cada rol y qué propósitos puede declarar. *Debe*
- **RF-21** El sistema debe rechazar toda acción que la *Tabla de permisos* no le permite al rol del usuario y registrarla como denegada, mostrando un mensaje según la causa (el rol, el propósito o la falta de relación) que no incluya datos del paciente. *Debe*
- **RF-22** El sistema debe permitir que el usuario vea en su perfil su rol, su sede de ingreso y la lista de lo que tiene permitido y lo que no. *Debe*
- **RF-23** El sistema debe permitir que el usuario cierre sesión. *Debe*
- **RF-35** El sistema debe cerrar la sesión de un usuario después de 15 minutos sin uso. *Debe*
- **RF-37** El sistema debe llevar al usuario, al abrir la sesión, a la pantalla inicial de su rol: *Pacientes con alta reciente* para el médico, el *Tablero de indicadores* para el administrativo y la *Auditoría de accesos* para el auditor. *Debe*

### Tabla de permisos

| Acción | Médico | Administrativo | Auditor |
|---|---|---|---|
| Buscar paciente y ver sus datos básicos | Sí | Sí | No |
| Ver la historia clínica y el riesgo de reingreso | Sí | No | No |
| Registrar una atención | Sí | No | No |
| Ver el tablero y el detalle de los indicadores | Sí | Sí | Sí |
| Registrar una medición | No | Sí | No |
| Ver la auditoría de accesos | No | No | Sí |
| Ver el perfil y cerrar sesión | Sí | Sí | Sí |

Propósitos que puede declarar cada rol:

- **Médico:** los 5.
- **Administrativo:** solo *Revisión de calidad*.
- **Auditor:** ninguno, porque no consulta información de pacientes.

### Tabla de indicadores

| Indicador | Unidad | Rango válido | Es mejor un valor | Aplica en |
|---|---|---|---|---|
| Reingreso hospitalario a 30 días | % de altas que vuelven a hospitalizarse | 0 a 100 | más bajo | clínicas |
| Tiempo de espera promedio | minutos | 0 a 1.440 | más bajo | clínicas y centros ambulatorios |
| Adherencia a protocolos clínicos | % de atenciones que cumplen el protocolo | 0 a 100 | más alto | clínicas y centros ambulatorios |
| Eventos adversos evitables | por cada 1.000 atenciones | 0 a 1.000 | más bajo | clínicas y centros ambulatorios |

Los laboratorios no tienen indicadores. Un mes cierra cuando termina: la medición de noviembre se puede registrar desde el 1 de diciembre.

## No funcionales

- **RNF-01** La app funciona en Chrome y Edge, en su versión actual, en un computador, y como app instalada en celulares con Android 10 o superior. iPhone no se incluye. (O-01, O-02, O-03, O-04, O-05) *Debe*
- **RNF-02** Todos los datos de pacientes son simulados y no se guarda ningún dato real, por la Ley 1581 de 2012. (O-01, O-02, O-04) *Debe*
- **RNF-03** En la entrega 2 la app funciona completa con datos en memoria, sin conexión a la nube. (O-01, O-02, O-03, O-04, O-05) *Debe*
- **RNF-04** Los datos simulados incluyen como mínimo: 8 sedes entre clínicas y centros ambulatorios, más al menos 2 laboratorios clínicos; 8 pacientes en seguimiento, de los que al menos 4 tienen alerta de riesgo y al menos 3 tienen atenciones en 2 sedes o más; 3 usuarios, uno por rol, cada uno con al menos una sede asignada, más una cuenta sin sedes asignadas y un usuario con 2 sedes; los indicadores que aplican a cada sede con mediciones de los últimos 6 meses, salvo una sede de prueba sin medición en el último periodo; y al menos 8 registros de acceso, con al menos 1 denegado y al menos 1 de emergencia; y una fecha de hoy fija, el 6 de noviembre de 2026, para todos los datos simulados. (O-01, O-02, O-03, O-04, O-05) *Debe*
- **RNF-05** Toda la interfaz está en español, con las fechas en formato día, mes abreviado y año (por ejemplo, "30 oct 2026") y la hora en formato de 24 horas. (O-01, O-02, O-03, O-04, O-05) *Debe*
- **RNF-06** Con los datos simulados, la búsqueda de pacientes, la lista de pacientes con alta reciente, la historia unificada, el tablero de indicadores y el registro de accesos se muestran en menos de 2 segundos desde que el usuario los abre. (O-01, O-02, O-03, O-04) *Debe*
- **RNF-07** Todas las pantallas se pueden usar sin desplazamiento horizontal en un ancho de 360 px (celular) y de 1280 px (computador). (O-01, O-02, O-03, O-04, O-05) *Debe*

## Preguntas abiertas

Ninguna.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.2.0 · 2026-11-06 · RF-14: el inicio de sesión fallido no tiene sede. Se cierra la pregunta sobre los 6 o 7 datos del PRD.
- 0.3.0 · 2026-11-06 · RF-14 incluye la apertura de la lista de pacientes con alta reciente y excluye la búsqueda. RNF-04 fija la fecha de hoy de los datos simulados. Se cierra la pregunta sobre la IP, que define AD-15.
- 0.4.0 · 2026-11-06 · RF-36: el bloqueo es del inicio de sesión en el dispositivo, sin importar el correo, con un mensaje fijo. Se cierra la pregunta sobre lo que ve el usuario bloqueado.
- 0.5.0 · 2026-11-06 · RF-04, RF-19, RF-20 y RF-25: el propósito y *Urgencia* también valen al registrar una atención. RF-28: hasta 1 decimal. RNF-01: Chrome y Edge, y Android 10 o superior.
- 0.6.0 · 2026-11-06 · RF-19: el propósito también se declara al abrir la lista de pacientes con alta reciente. RF-25: una atención registrada con *Urgencia* no da relación. RF-14: el ingreso exitoso se registra al abrir la sesión y, si el evento no se puede crear, la acción no se hace. RF-18, RF-20 y RF-21: detalles que ya estaban en las specs. Nuevo RF-37: pantalla inicial de cada rol.
- 0.6.1 · 2026-11-06 · RF-14: el evento se crea antes de ejecutar la acción, y el del ingreso exitoso antes de abrir la sesión.
- 0.6.2 · 2026-11-06 · Alineado con el prd 0.6.1, sin cambios en los requisitos.
- 0.7.0 · 2026-11-06 · RNF-04: los datos simulados tienen al menos 2 laboratorios clínicos. La tabla de indicadores dice que los laboratorios no tienen indicadores. Alineado con el prd 0.7.0.
- 0.7.1 · 2026-11-06 · Se quita la pregunta abierta sobre la historia completa del médico, que RF-02 ya responde.
- 0.7.2 · 2026-11-06 · Alineado con el prd 0.7.1, sin cambios en los requisitos.
- 0.7.3 · 2026-11-08 · RF-14: la búsqueda rechazada por el rol sí se registra, como toda acción denegada (F-01, F-18). Alineado con el prd 0.7.2.
- 0.7.4 · 2026-11-08 · RF-14 y RF-19: las dos excepciones de eventos y el propósito No aplica. Alineado con el prd 0.7.3.
- 0.7.5 · 2026-11-08 · RF-14: la atención rechazada por validación no es evento. RF-08: categoría del indicador. RF-27: redondeo del cambio y marca Mejora/Empeora/Sin cambio. Alineado con el prd 0.7.4.
- 0.7.6 · 2026-11-08 · RF-25: la atención con Urgencia no da relación ni por su alta. RF-14: dos eventos al abrir la historia y el ingreso sin sedes. Alineado con el prd 0.7.5.
- 0.7.7 · 2026-11-08 · RF-19: al registrar solo dos propósitos. RNF-04: la cuenta sin sedes, el usuario con 2 sedes y la sede sin medición de prueba. Alineado con el prd 0.7.6.
