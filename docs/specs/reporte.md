# Reporte de specs · Red Vitalys

Fecha: 2026-11-06 · Revisado: prd 0.1.0 · requisitos 0.1.0 · spine 0.1.0 · 4 specs (F-20 v0.2.0, F-21 v0.2.0, F-22 v0.2.0, F-23 v0.1.1)

**Alcance de esta revisión:** solo existen las specs F-20 a F-23. Las demás pantallas las especifican otros integrantes del equipo, así que la completitud y la trazabilidad RF → objetivo se calculan sobre los 6 RF de este grupo: RF-14, RF-15, RF-16, RF-17, RF-22 y RF-23.

Este reporte reemplaza el anterior del mismo día, que daba 81 % de verificabilidad, 1 inconsistencia y 1 spec no atómica. Desde entonces se aplicaron sus 3 correcciones principales y sus 3 correcciones menores.

## Métricas

- **Completitud** (verde): 6/6 · 100 %. Todos tienen spec: RF-14 y RF-17 en F-20, RF-15 y RF-16 en F-21, RF-22 en F-22 y RF-23 en F-23.
- **Trazabilidad** (verde):
  - RF → objetivo: 6/6 · 100 %. RF-14 a RF-17 están bajo O-04, y RF-22 y RF-23 bajo O-05.
  - Spec → RF: 4/4 · 100 %.
- **Verificabilidad** (verde): 33/33 · 100 %.
  - Criterios por spec: F-20 tiene 8 (CA-8 pasó a F-21), F-21 tiene 11, F-22 tiene 9 y F-23 tiene 5.
  - Todos tienen la forma Dado / cuando / entonces y un resultado que se ve.
  - Ninguna spec está sin criterios.
- **Ambigüedad** (verde): 0. No aparecen palabras vagas en ninguna spec.
- **Consistencia** (verde): 0.
  - F-20 *Reglas* ahora registra toda acción denegada, igual que F-21 A5 y CA-8 y RF-21.
  - F-20 *Datos* incluye el recurso *Auditoría de accesos*.
  - F-20 *Fuera de alcance* solo excluye la consulta permitida de la auditoría por el auditor.
- **Atomicidad** (verde): 0. F-22 se llama ahora *Perfil del usuario*. Las 4 specs tienen un solo flujo principal.
- **Pureza funcional** (verde): 0. Ninguna spec nombra tecnología. Tampoco quedan posiciones en la pantalla: se quitaron "debajo" de F-21 paso 4, de F-22 pasos 4 y 5, y de F-22 CA-7.
- **Preguntas abiertas:** 14 (F-20: 5, F-21: 3, F-22: 3, F-23: 3). Subieron de 12 a 14 porque F-20 y F-22 ahora preguntan qué ve el usuario cuando se le niega una acción. Esa pregunta depende de la spec del control de acceso (RF-21), que escribe otro integrante del equipo.
- **Avance de implementación:** todo en borrador. Hay 0 specs aprobadas o implementadas.
- **Estabilidad:** ninguna spec ha llegado a 1.0.0, así que no hay cambios de versión mayor. F-20, F-21 y F-22 tuvieron 1 cambio de comportamiento (de 0.1 a 0.2), y F-23 solo un parche de autores.

## Correcciones propuestas

1. **Pregunta compartida de F-20 y F-22.** Las dos specs preguntan qué ve el usuario cuando se le niega una acción. Conviene resolverla con quien escriba la spec del control de acceso (RF-21) y responderla igual en las dos specs.
2. **F-20 · Preguntas abiertas.** Si el evento no se puede crear, ¿se bloquea la acción? Mientras no se responda, F-20 *Estados* no tiene un estado de error definido ni un criterio que lo compruebe.
3. **F-20 · Datos y F-23 · Preguntas abiertas.** Hay que confirmar los nombres de recurso y el id de la spec de inicio de sesión con los compañeros para cerrar dos preguntas de coordinación. Después, se agrega ese id en `depende_de` de F-23.

Ninguna de las 3 es un error en las specs. Son preguntas abiertas que hay que cerrar antes de pasar las specs a `aprobada`.

## Lo que está bien

- **Las 7 métricas medibles están en verde.** Son completitud, trazabilidad, verificabilidad, ambigüedad, consistencia, atomicidad y pureza.
- **Todos los criterios de F-20 se comprueban.** Ahora se ven en la auditoría de accesos.
- **El nuevo F-20 CA-9 cubre la inconsistencia anterior.** Comprueba el intento denegado de abrir la auditoría.
- **F-22 compara la tabla de permisos con lo que el sistema hace.** Lo hace con un caso *No incluido* (CA-5) y uno *Permitido* (CA-9).
- **Coherencia con la spine.** La sede vive en la sesión y el propósito se declara en cada consulta (AD-05). La auditoría solo se agrega y nunca se edita (AD-08). Las fechas usan el formato "30 oct 2026 · 09:47" (AD-12).
