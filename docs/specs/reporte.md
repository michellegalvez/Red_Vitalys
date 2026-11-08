# Reporte de specs · Red Vitalys

Fecha: 2026-11-08 · Revisado: prd 0.7.6 · requisitos 0.7.7 · spine 0.6.10 · 23 specs (F-01 a F-23)

Este reporte reemplaza al anterior. Se hicieron cuatro pasadas de la crítica sobre los documentos y se corrigió en cada una lo que encontró. La primera dejó la consistencia en rojo con 5 contradicciones; la segunda, con 8 (nacidas de los cambios de esa misma ronda: la historia con el riesgo y sus dos eventos, el formulario de la atención, el orden de las sedes); la tercera, con 2; la cuarta, con 3. Las 3 de la cuarta pasada se corrigieron en el texto, pero la crítica no se volvió a ejecutar después de esa última ronda, así que no hay una quinta lectura que lo confirme. El script de verificación pasa.

Versiones de las specs: F-01 0.1.3 · F-02 0.1.9 · F-03 0.1.3 · F-04 0.3.6 · F-05 0.2.6 · F-06 0.3.6 · F-07 0.2.8 · F-08 0.1.6 · F-09 0.1.3 · F-10 0.1.3 · F-11 0.1.1 · F-12 0.2.3 · F-13 0.4.3 · F-14 0.2.3 · F-15 0.2.3 · F-16 0.3.6 · F-17 0.2.7 · F-18 0.2.5 · F-19 0.2.1 · F-20 0.4.6 · F-21 0.1.9 · F-22 0.2.3 · F-23 0.1.1.

## Métricas

- **Completitud** (verde): 37/37 · 100 %. Todo RF aparece en el campo `requisitos` de alguna spec.
- **Trazabilidad** (amarillo):
  - RF → objetivo: 37/37 · 100 %.
  - Spec → RF: 22/23 · 96 %. F-19 cita solo RNF, a propósito. Con RF o RNF, el resultado es 23/23 · 100 %.
- **Verificabilidad** (verde): 241/241 · 100 %. Cada criterio empieza con Dado y tiene "cuando" antes de "entonces". Ninguna spec está sin criterios.
- **Ambigüedad** (verde): 0.
- **Consistencia** (sin confirmar): 0 contradicciones conocidas. La cuarta pasada encontró 3 y se corrigieron, pero falta una lectura posterior que lo confirme.
- **Atomicidad** (verde): 0. F-19 reúne a propósito 4 requisitos no funcionales, sin flujo propio.
- **Pureza funcional** (verde): 0.
- **Formato** (verde): 0 defectos. Los criterios y los flujos alternos de las 23 specs van en orden y ningún historial repite una versión.
- **Preguntas abiertas:** 28. Bajó de 31 en el reporte anterior. Ninguna cambia lo que ya está escrito.
- **Avance de implementación:** todo en borrador. Hay 0 specs aprobadas o implementadas.
- **Estabilidad:** ninguna spec ha subido de versión mayor. Las que más versiones menores acumulan son F-13 y F-20 (0.4), y F-04, F-06 y F-16 (0.3).

## Verificación automática

`docs/verificar.sh` revisa, sin modificar ningún archivo: versiones e índice, dependencias sin ciclos, requisitos citados, forma Dado / cuando / entonces de los criterios, estructura de las 10 secciones, formato, palabras vagas y tecnología, las reglas compartidas, las frases retiradas, la tabla de permisos y que este reporte esté al día. Con este reporte debe dar 0 fallas.

Lo que el script **no** puede revisar: contradicciones con reglas que todavía no tiene en su lista, casos sin definir e ids de criterio mal escritos (por ejemplo `CA-{M}`, que apareció dos veces durante las correcciones y se borró a mano).

## Correcciones aplicadas en esta ronda

1. **Eventos al abrir la historia.** Abrir la historia con un propósito crea dos eventos, *Historia clínica* y *Riesgo de reingreso*, que se permiten o se deniegan juntos. Es igual en RF-14, AD-07, F-02, F-05, F-06, F-07, F-17 y F-20. Si solo se crea uno, no se muestra nada.
2. **Atención (F-04).** Sin motivo ni diagnóstico, como en el Figma: tipo de atención, sede, fecha de inicio, fecha de alta y destino al alta. Las fechas se escriben como "30 oct 2026". Una atención rechazada por validación no crea evento, como una medición.
3. **Relación con *Urgencia*.** Una atención registrada con *Urgencia* no da relación, ni por la atención ni por el alta que lleve (PRD, RF-25, F-05, F-04 CA-17).
4. **Emergencia.** Un evento es de emergencia si su propósito es *Urgencia* y su resultado es *Permitido* (F-17, F-20, F-21).
5. **Ingreso sin sedes.** Queda un evento *Denegado* con el correo y la IP; no suma al bloqueo ni lo reinicia, y abandonar antes de elegir la sede tampoco lo reinicia (F-13, F-14, F-20).
6. **Sedes de peor a mejor** en el tablero y en la comparación (F-08, F-10), con categoría del indicador y marca *Mejora* / *Empeora* / *Sin cambio*.
7. **F-21.** En celular cada evento es una tarjeta y en computador una tabla, sin desplazarse hacia los lados (RNF-07).
8. **Nombre de la pantalla de la lista:** *Pacientes con alta reciente* en todas partes; en la navegación se ve como *Pacientes*.
9. **Historia y riesgo.** El alcance del PRD une las dos aperturas en una: la historia, desde la búsqueda o la lista, con su riesgo. La regla compartida del script se reescribió para el nuevo diseño.
10. **Al registrar una atención** solo se ofrecen *Atención del paciente* y *Urgencia* (PRD, RF-19, F-16, F-04).
11. **Datos simulados (RNF-04):** una cuenta sin sedes, un usuario con 2 sedes y una sede de prueba sin medición en el último periodo.

## Lo que está bien

- Las tablas de permisos (requisitos, F-18 y F-22) son iguales entre sí.
- La tabla de indicadores coincide entre los requisitos, F-08 y F-12.
- Las dependencias no tienen ciclos y los 37 RF tienen spec.
- Ninguna spec nombra tecnología concreta.
