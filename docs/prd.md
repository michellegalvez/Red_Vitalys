---
documento: prd
proyecto: Red Vitalys
version: 0.1.0
fecha: 2026-11-05
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
---

# PRD · Red Vitalys

## Problema

Red Vitalys tiene 6 clínicas de alta complejidad, 40 centros ambulatorios y un laboratorio, y sus sistemas de historia clínica no se comunican entre sí. Por eso no se reconoce a un mismo paciente entre sedes, su información no se comparte a tiempo y las decisiones se toman con datos incompletos.

Hoy cada sede trabaja con su propio sistema. Un mismo paciente puede tener un registro distinto en cada uno, con otro identificador. Para saber qué pasó en otra sede hay que pedírselo a esa sede. Los indicadores de calidad se consolidan por separado en cada sede y no hay un registro común de quién consultó la información.

Lo que más afecta:

- El médico decide sin conocer la historia completa del paciente.
- No hay una sola vista para comparar entre sedes el reingreso a 30 días ni los demás indicadores.
- No se puede rastrear quién accedió a la información de un paciente, cuándo y para qué.

El problema afecta en este orden al personal clínico, a la Dirección Médica y a los auditores. El paciente sufre las consecuencias, pero no usa la app.

## Usuarios

El acceso depende del rol, de la sede desde la que se ingresa y del propósito que se declara en cada consulta, y cada acción queda registrada. La sede de ingreso queda en la sesión, se ve en el perfil y aparece en cada registro de auditoría.

- **Médico**: abre la app en cada atención para ver la historia unificada del paciente con la información de todas las sedes, saber si tiene riesgo alto de volver a hospitalizarse y por qué, y registrar la atención. Es el único rol que ve la historia clínica completa y el riesgo de reingreso, y el único que registra atenciones. Puede consultar pacientes atendidos en cualquier sede de la red declarando el propósito. Al registrar una atención se propone la sede de la sesión, pero puede elegir otra.
- **Administrativo** (incluye a la Dirección Médica): consulta los datos básicos del paciente, sin historia clínica ni riesgo de reingreso. Compara los indicadores de calidad entre sedes y registra las mediciones de cada sede cuando cierra el periodo de medición, que es mensual.
- **Auditor**: revisa quién accedió a qué información, cuándo, con qué propósito y con qué resultado, en revisiones periódicas y cada vez que hay accesos denegados o de emergencia. Es el único rol que ve la auditoría de accesos y no puede modificar información clínica ni administrativa.

Los tres roles ven el tablero de indicadores, ven su perfil con lo que tienen permitido y cierran sesión. Usan la app desde el computador y desde el celular.

### Propósitos de acceso

En cada consulta a la información de un paciente el usuario declara uno de estos propósitos: *Atención del paciente*, *Consulta de historia clínica*, *Seguimiento de reingreso*, *Revisión de calidad* o *Urgencia*. El inicio de sesión queda registrado con el propósito *No aplica*.

**Urgencia** es el acceso de emergencia. Se usa cuando un médico necesita la historia de un paciente con el que no tiene una atención ni un seguimiento. El acceso se permite, pero queda marcado como emergencia para que el auditor lo revise.

Si un rol intenta algo que no le corresponde, se rechaza y queda registrado como denegado.

## Objetivos

- **O-01** · **Ver al paciente unificado.** El médico ve en un solo lugar la información de un paciente de todas las sedes, aunque cada sede lo tenga registrado con un identificador distinto. *Se cumple si*, al buscar a un paciente por nombre o documento, el médico ve en una sola consulta sus datos, sus identificadores en cada sistema de origen y sus atenciones de al menos 2 sedes distintas.
- **O-02** · **Anticipar el reingreso.** El médico sabe qué pacientes dados de alta tienen riesgo alto de volver a hospitalizarse en 30 días y entiende por qué. *Se cumple si* el médico ve a los pacientes con alta en los últimos 30 días ordenados de mayor a menor riesgo, los que tienen riesgo de 70 o más aparecen con una alerta y, al abrir uno, ve los factores que suben o bajan su riesgo y cuántos puntos aporta cada uno.
- **O-03** · **Comparar la calidad entre sedes.** La Dirección Médica compara los 4 indicadores de calidad entre sedes y ve cuáles están peor que el promedio de la red. *Se cumple si* cualquiera de los 3 roles ve el valor del último periodo de los 4 indicadores (reingreso a 30 días, tiempo de espera, adherencia a protocolos clínicos y eventos adversos evitables), su cambio frente al periodo anterior y cada sede marcada como mejor o peor que el promedio de la red.
- **O-04** · **Rastrear cada acceso.** Cada acceso a la información de un paciente queda registrado y el auditor lo puede revisar. *Se cumple si* el 100 % de los inicios de sesión y de las consultas y registros sobre información de un paciente quedan registrados con 6 datos: quién, cuándo, qué acción, sobre qué recurso, con qué propósito y con qué resultado (permitido o denegado). Además, el auditor tiene que poder filtrar los accesos denegados y los de emergencia, y ningún registro se puede editar ni borrar.
- **O-05** · **Acceso según rol, sede y propósito.** Cada usuario solo puede hacer lo que su rol permite y sabe qué es. *Se cumple si* cada uno de los 3 roles (médico, administrativo y auditor) solo puede hacer lo que su rol permite, ve en su perfil lo que tiene permitido y lo que no, y todo intento de hacer algo no permitido se rechaza y queda registrado como denegado.

## Alcance

### Incluye

Los 5 objetivos funcionando con datos simulados y con los 3 roles, en un recorrido completo por la app:

- Iniciar sesión eligiendo la sede.
- Ver a los pacientes con alerta de riesgo de reingreso.
- Abrir la historia unificada de un paciente con su riesgo de reingreso y la explicación.
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
- Crear, editar o desactivar usuarios y roles.
- Editar o borrar registros de auditoría.
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
- ¿Puede un médico ver la historia de un paciente de otra sede sin declarar *Urgencia* cuando ese paciente no está en seguimiento?
- ¿El administrativo registra solo las mediciones de su propia sede o las de cualquier sede?
- ¿Cuándo es la entrega 3?

## Historial

- 0.1.0 · 2026-11-05 · Primera versión.
