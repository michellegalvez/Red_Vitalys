# Reporte de specs · Red Vitalys

Fecha: 2026-11-06 · Revisado: prd 0.7.1 · requisitos 0.7.2 · spine 0.6.5 · 23 specs (F-01 a F-23)

Este reporte reemplaza al anterior del mismo día, que daba 1 inconsistencia: el alcance del PRD describía como una sola pantalla la historia unificada y el riesgo de reingreso, que en F-02 y F-07 son dos. Se corrigió el PRD y se cerró la cadena de versiones.

Versiones de las specs: F-01 0.1.3 · F-02 0.1.4 · F-03 0.1.3 · F-04 0.3.1 · F-05 0.2.2 · F-06 0.3.2 · F-07 0.2.5 · F-08 0.1.3 · F-09 0.1.3 · F-10 0.1.2 · F-11 0.1.1 · F-12 0.2.3 · F-13 0.4.1 · F-14 0.2.1 · F-15 0.2.2 · F-16 0.3.3 · F-17 0.2.3 · F-18 0.2.3 · F-19 0.2.0 · F-20 0.4.2 · F-21 0.1.4 · F-22 0.2.3 · F-23 0.1.1.

## Métricas

- **Completitud** (verde): 37/37 · 100 %. Todo RF aparece en el campo `requisitos` de alguna spec.
- **Trazabilidad** (amarillo):
  - RF → objetivo: 37/37 · 100 %.
  - Spec → RF: 22/23 · 96 %. F-19 cita solo RNF, a propósito. Con RF o RNF, el resultado es 23/23 · 100 %.
- **Verificabilidad** (verde): 219/219 · 100 %. El script comprueba que cada criterio empiece con Dado y tenga "cuando" antes de "entonces".
- **Ambigüedad** (verde): 0.
- **Consistencia** (verde): 0. El alcance del PRD separa la historia unificada (F-02) del riesgo de reingreso (F-07), que se abre desde la lista de pacientes con alta reciente (F-06).
- **Atomicidad** (verde): 0.
- **Pureza funcional** (verde): 0.
- **Formato** (amarillo): 1 defecto. **F-05** tiene los criterios en el orden CA-6, CA-9, CA-7, CA-8. El CA-9 se agregó al final de la ronda de relación y quedó antes del CA-7. Las demás 22 specs tienen los criterios y los flujos alternos en orden. Ningún historial repite una versión.
- **Preguntas abiertas:** 31. Son las de las specs y ninguna cambia lo que ya está escrito. Subió de 30 por la pregunta nueva de F-07 sobre un paciente que ya no está en la lista.
- **Avance de implementación:** todo en borrador. Hay 0 specs aprobadas o implementadas.
- **Estabilidad:** ninguna spec ha subido de versión mayor.

## Verificación automática

`docs/verificar.sh` revisa, sin modificar ningún archivo:

- Versiones: la de cada documento coincide con el último renglón de su historial, con el índice y con el `basado_en` de los documentos que lo citan. Ningún historial repite una versión ni retrocede.
- Dependencias entre specs: existen, no apuntan a sí mismas y no forman ciclos.
- Requisitos: todos los citados existen, cada spec cita al menos uno y los 37 RF tienen spec.
- Criterios: sin repetidos ni saltos, con la forma Dado / cuando / entonces.
- Estructura: las 10 secciones en orden, pasos del flujo consecutivos y sin pasos pegados, y ninguna sección de preguntas abiertas vacía.
- Formato: línea en blanco antes de cada encabezado, listas sin cortes, sin dobles líneas en blanco, salto de línea al final y sin CRLF.
- Palabras: ninguna palabra vaga, ninguna tecnología y ninguna posición en la pantalla en el cuerpo de las specs.
- Reglas compartidas: 20 reglas que aparecen en varios documentos tienen que decir lo mismo en cada uno.
- Frases retiradas: las redacciones que ya se corrigieron no pueden volver.
- Tabla de permisos: la de los requisitos, F-18 y F-22 son iguales.
- Reporte al día: dice las versiones y las cifras actuales.

Lo que el script **no** puede revisar es si una regla nueva contradice a otra que todavía no está en su lista, ni si un caso de uso quedó sin definir. Eso sigue exigiendo leer. Tarda cerca de 2 minutos en Git Bash, porque lanza muchos procesos pequeños.

## Correcciones propuestas

1. **F-05, *Criterios de aceptación*.** Mover el CA-9 después del CA-8. Es redacción, así que sube el parche de F-05 a 0.2.2.
2. **`docs/verificar.sh`.** Agregar un chequeo de que los criterios y los flujos alternos de cada spec estén en orden creciente. Hoy solo comprueba que no haya repetidos ni saltos, y por eso no vio este defecto.

Con esas dos correcciones no queda nada más. Se releyeron las 23 specs, el PRD, los requisitos y la spine, y el resto del contenido no se contradice.

## Lo que está bien

- **El contenido de las 23 specs, el PRD, los requisitos, la spine y `AGENTS.md` no tiene contradicciones entre sí.**
- **Las reglas que se repiten en varios documentos y las frases ya corregidas están vigiladas por el script.**
- **Las tablas de permisos (F-18, F-22) y de indicadores (F-08, F-12) coinciden con `docs/requisitos.md`.**
- **Las dependencias no tienen ciclos.**
- **Ninguna spec nombra tecnología concreta:** ni Supabase, ni Flutter, ni tablas, ni SQL.
