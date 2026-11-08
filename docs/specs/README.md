# Specs funcionales · Red Vitalys

Actualizado: 2026-11-08

Las 23 specs cubren los 37 requisitos funcionales (RF-01 a RF-37) y 4 no funcionales (RNF-01, RNF-03, RNF-05 y RNF-07, en F-19).

- [F-01 · Búsqueda de pacientes](F-01-busqueda-pacientes.md) · v0.1.3 · borrador · RF-01
- [F-02 · Historia unificada del paciente](F-02-historia-unificada.md) · v0.1.4 · borrador · RF-02
- [F-03 · Datos básicos del paciente](F-03-datos-basicos-paciente.md) · v0.1.3 · borrador · RF-03
- [F-04 · Registro de una atención](F-04-registro-atencion.md) · v0.3.1 · borrador · RF-04
- [F-05 · Relación médico-paciente](F-05-relacion-medico-paciente.md) · v0.2.2 · borrador · RF-24, RF-25
- [F-06 · Pacientes con alta reciente por riesgo de reingreso](F-06-pacientes-riesgo-reingreso.md) · v0.3.2 · borrador · RF-05, RF-06
- [F-07 · Factores que explican el riesgo de reingreso](F-07-factores-riesgo-reingreso.md) · v0.2.5 · borrador · RF-07
- [F-08 · Tablero de indicadores](F-08-tablero-indicadores.md) · v0.1.3 · borrador · RF-08, RF-09, RF-26, RF-27
- [F-09 · Tendencia mensual de un indicador](F-09-tendencia-indicador.md) · v0.1.3 · borrador · RF-10
- [F-10 · Comparación entre sedes de un indicador](F-10-comparacion-sedes.md) · v0.1.2 · borrador · RF-11
- [F-11 · Mediciones recientes de un indicador](F-11-mediciones-recientes.md) · v0.1.1 · borrador · RF-12
- [F-12 · Registro de la medición mensual de una sede](F-12-registro-medicion.md) · v0.2.3 · borrador · RF-13, RF-28, RF-29, RF-30
- [F-13 · Inicio de sesión con la sede asignada](F-13-inicio-sesion.md) · v0.4.1 · borrador · RF-18, RF-32, RF-33, RF-37
- [F-14 · Bloqueo del inicio de sesión por intentos fallidos](F-14-bloqueo-inicio-sesion.md) · v0.2.1 · borrador · RF-36
- [F-15 · Cierre de sesión por inactividad](F-15-cierre-inactividad.md) · v0.2.2 · borrador · RF-35
- [F-16 · Declaración del propósito de consulta](F-16-declaracion-proposito.md) · v0.3.3 · borrador · RF-19
- [F-17 · Acceso de emergencia](F-17-acceso-emergencia.md) · v0.2.3 · borrador · RF-20
- [F-18 · Control de acceso por rol](F-18-control-acceso-rol.md) · v0.2.3 · borrador · RF-21, RF-34
- [F-19 · Condiciones de uso de la app](F-19-condiciones-uso-app.md) · v0.2.0 · borrador · RNF-01, RNF-03, RNF-05, RNF-07
- [F-20 · Registro de eventos de acceso](F-20-registro-eventos-acceso.md) · v0.4.2 · borrador · RF-14, RF-17, RF-31
- [F-21 · Consulta de la auditoría de accesos](F-21-auditoria-accesos.md) · v0.1.4 · borrador · RF-15, RF-16
- [F-22 · Perfil del usuario](F-22-perfil-permisos.md) · v0.2.3 · borrador · RF-22
- [F-23 · Cierre de sesión](F-23-cierre-sesion.md) · v0.1.1 · borrador · RF-23

## Avance

- Implementadas en el prototipo de la Entrega 2 (front-end con datos simulados): 23 de 23 (F-01 a F-23).
- Aprobadas: 0 de 23. Las specs siguen en borrador; implementar no las aprueba.

### Excepciones del prototipo

El prototipo no tiene backend, así que se aparta de las specs en estos puntos:

- No hay estados de carga ni de error de red: los datos son locales, y no se muestran «Cargando…» ni «Reintentar».
- El mensaje «No se pudo completar la acción» de F-20 no se simula, porque el registro de eventos en memoria no falla.
- La fecha de «hoy» es fija: el 6 de noviembre de 2026.
- El pop-up de propósito no muestra el riesgo antes de declarar el propósito.
