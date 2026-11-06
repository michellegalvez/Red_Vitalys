---
documento: prd
proyecto: Red Vitalys
version: 0.7.1
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
---

# PRD · Red Vitalys

## Problema

Red Vitalys tiene 6 clínicas de alta complejidad, 40 centros ambulatorios y una cadena de laboratorios clínicos propia, y sus sistemas de historia clínica no se comunican entre sí. Por eso no se reconoce a un mismo paciente entre sedes, su información no se comparte a tiempo y las decisiones se toman con datos incompletos.

Hoy cada sede trabaja con su propio sistema. Un mismo paciente puede tener un registro distinto en cada uno, con otro identificador. Para saber qué pasó en otra sede hay que pedírselo a esa sede. Los indicadores de calidad se consolidan por separado en cada sede y no hay un registro común de quién consultó la información.

Lo que más afecta:

- El médico decide sin conocer la historia completa del paciente.
- No hay una sola vista para comparar entre sedes el reingreso a 30 días ni los demás indicadores.
- No se puede rastrear quién accedió a la información de un paciente, cuándo y para qué.

El problema afecta en este orden al personal clínico, a la Dirección Médica y a los auditores. El paciente sufre las consecuencias, pero no usa la app.

## Usuarios

Cada usuario entra con su correo institucional y su contraseña. Después de 5 intentos fallidos seguidos, el inicio de sesión se bloquea 15 minutos en ese dispositivo para cualquier correo, y una sesión sin uso se cierra a los 15 minutos.

El acceso depende del rol, de la sede desde la que se ingresa y del propósito que se declara en cada consulta, y cada acción queda registrada. Cada usuario tiene asignadas una o más sedes y solo puede ingresar desde una de ellas. La sede de ingreso queda en la sesión, se ve en el perfil y aparece en cada registro de auditoría.

- **Médico**: abre la app en cada atención para ver la historia unificada del paciente con la información de todas las sedes, saber si tiene riesgo alto de volver a hospitalizarse y por qué, y registrar la atención. Es el único rol que ve la historia clínica completa y el riesgo de reingreso, y el único que registra atenciones. Puede buscar pacientes de cualquier sede de la red y ver su historia cuando tiene relación con ellos: registró una atención suya declarando *Atención del paciente* o lo dieron de alta en una de sus sedes asignadas. Con un paciente con el que no tiene relación solo puede ver la historia o registrar una atención declarando *Urgencia*, y una atención registrada con *Urgencia* no le da relación. Al registrar una atención declara el propósito (*Atención del paciente* si tiene relación) y se le propone la sede de la sesión, pero puede elegir otra.
- **Administrativo** (incluye a la Dirección Médica): busca pacientes y consulta sus datos básicos, sin historia clínica ni riesgo de reingreso. Compara los indicadores de calidad entre sedes y registra las mediciones de cualquier sede cuando cierra el periodo de medición, que es mensual. Digita el valor ya calculado por la sede; la app no lo calcula.
- **Auditor**: revisa quién accedió a qué información, cuándo, con qué propósito y con qué resultado, en revisiones periódicas y cada vez que hay accesos denegados o de emergencia. Es el único rol que ve la auditoría de accesos, no consulta información de pacientes y no puede modificar información clínica ni administrativa.

Los tres roles ven el tablero de indicadores, ven su perfil con lo que tienen permitido y cierran sesión. Usan la app desde el computador y desde el celular.

### Propósitos de acceso

En cada consulta a la información de un paciente, al abrir la lista de pacientes con alta reciente y al registrar una atención, el usuario declara uno de estos propósitos: *Atención del paciente*, *Consulta de historia clínica*, *Seguimiento de reingreso*, *Revisión de calidad* o *Urgencia*. El médico puede declarar cualquiera de los 5. El administrativo solo *Revisión de calidad*. El auditor ninguno, porque no consulta pacientes. El inicio de sesión queda registrado con el propósito *No aplica*.

**Urgencia** es el acceso de emergencia. Se usa cuando un médico necesita la historia de un paciente con el que no tiene relación, o registrarle una atención. El acceso se permite, pero queda marcado como emergencia para que el auditor lo revise.

Si un rol intenta algo que no le corresponde, se rechaza y queda registrado como denegado.

### Indicadores por tipo de sede

Los indicadores de calidad son 4. El reingreso hospitalario a 30 días solo aplica en las clínicas. El tiempo de espera, la adherencia a protocolos clínicos y los eventos adversos evitables aplican en las clínicas y en los centros ambulatorios. Los laboratorios no tienen indicadores.

## Objetivos

- **O-01** · **Ver al paciente unificado.** El médico ve en un solo lugar la información de un paciente de todas las sedes, aunque cada sede lo tenga registrado con un identificador distinto. *Se cumple si*, al buscar a un paciente por nombre o documento, el médico ve en una sola consulta sus datos, sus identificadores en cada sistema de origen y sus atenciones de al menos 2 sedes distintas.
- **O-02** · **Anticipar el reingreso.** El médico sabe qué pacientes dados de alta tienen riesgo alto de volver a hospitalizarse en 30 días y entiende por qué. *Se cumple si* el médico ve a los pacientes con alta en los últimos 30 días ordenados de mayor a menor riesgo, los que tienen riesgo de 70 o más aparecen con una alerta y, al abrir uno, ve los factores que suben o bajan su riesgo y cuántos puntos aporta cada uno.
- **O-03** · **Comparar la calidad entre sedes.** La Dirección Médica compara los 4 indicadores de calidad entre sedes y ve cuáles están peor que el promedio de la red. *Se cumple si* cualquiera de los 3 roles ve el valor del último periodo de los 4 indicadores (reingreso a 30 días, tiempo de espera, adherencia a protocolos clínicos y eventos adversos evitables), su cambio frente al periodo anterior y cada sede, en los indicadores que le aplican, marcada como mejor, peor o igual al promedio de la red.
- **O-04** · **Rastrear cada acceso.** Cada acceso a la información de un paciente queda registrado y el auditor lo puede revisar. *Se cumple si* el 100 % de los inicios de sesión, exitosos o fallidos, de las consultas y registros sobre información de un paciente, de los registros de mediciones, de las aperturas de la lista de pacientes con alta reciente y de las acciones denegadas quedan registrados con 7 datos: quién, cuándo, qué acción, sobre qué recurso, con qué propósito, con qué resultado (permitido o denegado) y desde qué sede. El único evento sin sede es el inicio de sesión fallido, porque todavía no hay sesión, y lleva en su lugar la IP. La búsqueda de pacientes, que solo muestra nombre y documento, no se registra. Además, el auditor tiene que poder filtrar los accesos denegados y los de emergencia, y ningún registro se puede editar ni borrar.
- **O-05** · **Acceso según rol, sede y propósito.** Cada usuario solo puede hacer lo que su rol permite y sabe qué es. *Se cumple si* cada uno de los 3 roles (médico, administrativo y auditor) solo puede hacer lo que su rol permite, ve en su perfil lo que tiene permitido y lo que no, y todo intento de hacer algo no permitido se rechaza y queda registrado como denegado.

## Alcance

### Incluye

Los 5 objetivos funcionando con datos simulados y con los 3 roles, en un recorrido completo por la app:

- Iniciar sesión con correo y contraseña, eligiendo la sede entre las asignadas, y entrar a la pantalla inicial del rol: pacientes con alta reciente para el médico, tablero de indicadores para el administrativo y auditoría de accesos para el auditor.
- Bloquear el inicio de sesión tras 5 intentos fallidos y cerrar la sesión tras 15 minutos sin uso.
- Buscar pacientes y ver sus datos básicos.
- Ver a los pacientes con alta reciente, ordenados por riesgo de reingreso y con alerta los de riesgo alto.
- Abrir la historia unificada de un paciente.
- Abrir el riesgo de reingreso de un paciente de la lista, con la explicación de qué factores lo suben o bajan.
- Registrar una atención.
- Ver el tablero de indicadores y el detalle de un indicador.
- Registrar las mediciones de los indicadores de una sede.
- Revisar la auditoría de accesos, con filtros para los denegados y los de emergencia.
- Ver el perfil con lo que el rol permite y lo que no.
- Cerrar sesión.

### No incluye

- Conexión real con los sistemas de historia clínica de las sedes. Todos los datos son simulados.
- App para pacientes.
- Entrenamiento de un modelo real de riesgo de reingreso. El puntaje y sus factores son simulados.
- Facturación.
- Agenda de citas.
- Crear, editar o desactivar usuarios y roles, o cambiar las sedes asignadas a un usuario.
- Editar o borrar registros de auditoría.
- Corregir o borrar una medición ya registrada.
- Desbloquear el inicio de sesión antes de que pasen los 15 minutos.
- Notificaciones que le lleguen al usuario fuera de la app.
- La sesión de co-creación con médicos y administrativos para validar el tablero.

## Restricciones

- **Equipo**: 4 personas: Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco y Samuel Cardoso Martinez.
- **Entrega 2** (8 de noviembre de 2026): prototipo navegable con datos simulados en memoria, sin conexión a la nube.
- **Entrega 3**: aplicación final con exhibición y las specs completas.
- **Datos**: no se guardan datos reales de pacientes. Todos son simulados, por la protección de los datos de salud en Colombia (Ley 1581 de 2012).
- **Plataformas**: computador y celular.
- **Contexto académico**: Seminario en Ingeniería de Software · Universidad Icesi.

## Preguntas abiertas

- ¿Cuánto se demora hoy conseguir la historia de un paciente de otra sede y cada cuánto se repiten exámenes? No hay cifras porque el proyecto no se ha validado con datos reales de la red.
- ¿Con qué frecuencia exacta usa la app cada rol y cuál es el dispositivo principal de cada uno? No hay datos reales de uso.
- ¿Quién asigna las sedes a cada usuario, si la app no crea ni edita usuarios? Hoy vienen ya asignadas en los datos simulados.
- ¿Cuántos laboratorios tiene la cadena? Para los datos simulados se usan al menos 2.

## Historial

- 0.1.0 · 2026-11-05 · Primera versión.
- 0.1.1 · 2026-11-06 · Alineado con los requisitos 0.1.0: 7 datos por evento, login con correo y contraseña, bloqueo e inactividad, sedes asignadas, relación médico-paciente, propósitos por rol, indicadores por tipo de sede y mediciones de cualquier sede. Se cierran 2 preguntas abiertas.
- 0.2.0 · 2026-11-06 · O-04 aclara que el inicio de sesión fallido no tiene sede y lleva la IP, a raíz de la crítica de las specs.
- 0.3.0 · 2026-11-06 · O-04 incluye las aperturas de la lista de pacientes con alta reciente y excluye la búsqueda de pacientes, a raíz de la segunda crítica de las specs.
- 0.4.0 · 2026-11-06 · El bloqueo tras 5 intentos fallidos es del inicio de sesión en el dispositivo, no de una cuenta. Se quitan las preguntas sobre la entrega 3 y sobre lo que ve el usuario bloqueado.
- 0.5.0 · 2026-11-06 · El propósito y *Urgencia* también valen al registrar una atención, a raíz de la tercera crítica de las specs.
- 0.6.0 · 2026-11-06 · El propósito también se declara al abrir la lista de pacientes con alta reciente. Una atención registrada con *Urgencia* no da relación. Se escribe la pantalla inicial de cada rol. A raíz de la cuarta crítica de las specs.
- 0.6.1 · 2026-11-06 · Redacción: la frase del médico sobre el propósito y la sede de una atención.
- 0.7.0 · 2026-11-06 · Problema: la red tiene una cadena de laboratorios clínicos propia, no un laboratorio. Los laboratorios no tienen indicadores. Nueva pregunta abierta sobre cuántos laboratorios tiene la cadena.
- 0.7.1 · 2026-11-06 · Alcance: la historia unificada y el riesgo de reingreso son dos líneas, como F-02 y F-07, y la lista dice que muestra a los pacientes con alta reciente ordenados por riesgo.
