---
documento: requisitos
proyecto: Red Vitalys
version: 0.1.0
fecha: 2026-11-05
estado: borrador
basado_en: prd 0.1.0
---

# Requisitos · Red Vitalys

## Funcionales

### O-01 · Ver al paciente unificado

- **RF-01** El sistema debe permitir que el médico busque a un paciente por nombre o por número de documento. *Debe*
- **RF-02** El sistema debe permitir que el médico vea la historia unificada de un paciente, con sus datos, su identificador en cada sistema de origen y sus atenciones en todas las sedes. *Debe*
- **RF-03** El sistema debe permitir que el administrativo consulte los datos básicos de un paciente, sin mostrarle la historia clínica ni el riesgo de reingreso. *Debe*
- **RF-04** El sistema debe permitir que el médico registre una atención de un paciente, que pasa a formar parte de su historia unificada. La sede propuesta es la de la sesión, y el médico puede elegir otra. *Debe*

### O-02 · Anticipar el reingreso

- **RF-05** El sistema debe permitir que el médico vea a los pacientes dados de alta en los últimos 30 días, ordenados de mayor a menor riesgo de reingreso. *Debe*
- **RF-06** El sistema debe marcar con una alerta a los pacientes con riesgo de reingreso de 70 o más. *Debe*
- **RF-07** El sistema debe permitir que el médico vea los factores que suben o bajan el riesgo de reingreso de un paciente y cuántos puntos aporta cada uno. *Debe*

### O-03 · Comparar la calidad entre sedes

- **RF-08** El sistema debe permitir que el médico, el administrativo y el auditor vean de cada uno de los 4 indicadores (reingreso a 30 días, tiempo de espera, adherencia a protocolos clínicos y eventos adversos evitables) el valor del último periodo y su cambio frente al periodo anterior. *Debe*
- **RF-09** El sistema debe marcar cada sede como mejor o peor que el promedio de la red en cada indicador. *Debe*
- **RF-10** El sistema debe permitir que el usuario vea, en el detalle de un indicador, la tendencia mensual de los últimos 6 periodos, de toda la red o de la sede que elija. *Debe*
- **RF-11** El sistema debe permitir que el usuario vea, en el detalle de un indicador, la comparación entre sedes del último periodo, con el promedio de la red como referencia. *Debe*
- **RF-12** El sistema debe permitir que el usuario vea, en el detalle de un indicador, las mediciones recientes con la sede, el periodo, el valor y si está mejor o peor que el promedio de la red. *Debe*
- **RF-13** El sistema debe permitir que el administrativo registre la medición mensual de un indicador para una sede. *Debe*

### O-04 · Rastrear cada acceso

- **RF-14** El sistema debe registrar cada inicio de sesión y cada consulta o registro sobre la información de un paciente con quién, cuándo, la acción, el recurso, el propósito, el resultado (permitido o denegado) y la sede de ingreso. *Debe*
- **RF-15** El sistema debe permitir que el auditor consulte el registro de accesos. *Debe*
- **RF-16** El sistema debe permitir que el auditor filtre los accesos denegados y los de emergencia. *Debe*
- **RF-17** El sistema debe impedir que cualquier usuario edite o borre un registro de acceso. *Debe*

### O-05 · Acceso según rol, sede y propósito

- **RF-18** El sistema debe permitir que el usuario inicie sesión eligiendo la sede desde la que ingresa. *Debe*
- **RF-19** El sistema debe exigir que el usuario declare uno de estos propósitos para consultar la información de un paciente: *Atención del paciente*, *Consulta de historia clínica*, *Seguimiento de reingreso*, *Revisión de calidad* o *Urgencia*. *Debe*
- **RF-20** El sistema debe permitir que el médico declare *Urgencia* para ver la historia de un paciente con el que no tiene una atención ni un seguimiento, y debe marcar ese acceso como emergencia. *Debe*
- **RF-21** El sistema debe rechazar toda acción que el rol del usuario no permite y registrarla como denegada. *Debe*
- **RF-22** El sistema debe permitir que el usuario vea en su perfil su rol, su sede de ingreso y la lista de lo que tiene permitido y lo que no. *Debe*
- **RF-23** El sistema debe permitir que el usuario cierre sesión. *Debe*

## No funcionales

- **RNF-01** La app funciona en el navegador web de un computador y como app instalada en celulares Android. iPhone no se incluye. (O-01, O-02, O-03, O-04, O-05) *Debe*
- **RNF-02** Todos los datos de pacientes son simulados y no se guarda ningún dato real, por la Ley 1581 de 2012. (O-01, O-02, O-04) *Debe*
- **RNF-03** En la entrega 2 la app funciona completa con datos en memoria, sin conexión a la nube. (O-01, O-02, O-03, O-04, O-05) *Debe*
- **RNF-04** Los datos simulados incluyen como mínimo: 8 sedes entre clínicas y centros ambulatorios, más el laboratorio central; 8 pacientes en seguimiento, de los que al menos 4 tienen alerta de riesgo y al menos 3 tienen atenciones en 2 sedes o más; 3 usuarios, uno por rol; los 4 indicadores con mediciones de los últimos 6 meses en cada sede; y al menos 8 registros de acceso, con al menos 1 denegado y al menos 1 de emergencia. (O-01, O-02, O-03, O-04, O-05) *Debe*
- **RNF-05** Toda la interfaz está en español, con las fechas en formato día, mes abreviado y año (por ejemplo, "30 oct 2026") y la hora en formato de 24 horas. (O-01, O-02, O-03, O-04, O-05) *Debe*
- **RNF-06** Con los datos simulados, la historia unificada, el tablero de indicadores y el registro de accesos se muestran en menos de 2 segundos desde que el usuario los abre. (O-01, O-03, O-04) *Debe*

## Preguntas abiertas

- ¿Puede un médico ver la historia de un paciente de otra sede sin declarar *Urgencia* cuando ese paciente no está en seguimiento? Esto afecta a RF-20. (Viene del PRD.)
- ¿El administrativo registra solo las mediciones de su propia sede o las de cualquier sede? Esto afecta a RF-13. (Viene del PRD.)

## Historial

- 0.1.0 · 2026-11-05 · Primera versión.
