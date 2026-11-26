# Planes · Red Vitalys

Un plan dice **cómo** se construye algo que las specs dicen **qué** debe hacer. Sale de una o más specs (`docs/specs/`) y se baja a tareas (`docs/tasks/`). La cadena es:

```
requisito (RF) → spec (F-xx) → plan (P-xx) → tareas (T-xx) → código y pruebas
```

Cada eslabón nombra al anterior en sus metadatos, así que se puede ir en los dos sentidos.

## Formato de un plan

Archivo `docs/plans/P-NN-nombre-corto.md`, con `NN` de dos dígitos. El P-00 es la infraestructura común; las funcionalidades arrancan en el P-01.

```markdown
---
id: P-00
titulo: Conexión con Supabase
version: 0.1.0
fecha: 2026-11-20
estado: borrador          # borrador | aprobado | en curso | hecho
autores: [Nombre Apellido, ...]
specs: [F-13]             # specs que implementa; [] si es transversal
requisitos: [RF-32]       # RF y RNF que cubre; [] si es transversal
invariantes: [AD-01]      # invariantes de la spine que aplica o respeta
tareas: T-00              # archivo de tareas que sale de este plan
---

# P-00 · Título

## Objetivo
Una o dos frases: qué queda funcionando al terminar y qué no cambia.

## Enfoque técnico
La decisión de cómo se hace y por qué, con las alternativas descartadas.

## Componentes
Tabla con cada archivo o pieza: ruta, responsabilidad y si es nuevo o cambia.

## Cambios
Qué se agrega, qué se modifica y qué NO se toca (el límite del plan).

## Riesgos y decisiones abiertas
Lo que puede salir mal o falta decidir. Nada abierto se da por hecho.

## Verificación
Cómo se sabe que el plan terminó: comandos y criterios de las specs que cubre.

## Historial
- 0.1.0 · fecha · Primera versión.
```

Reglas:

- Un plan no contradice la spine. Si necesita hacerlo, primero se cambia la spine.
- Un plan de funcionalidad cita los criterios de aceptación de sus specs en *Verificación*; no los reescribe.
- Si cambia el alcance, se sube la versión y se anota en *Historial*, como en las specs.
- El estado pasa a `hecho` cuando todas sus tareas están marcadas.

## Índice

- [P-00 · Conexión con Supabase](P-00-conexion-supabase.md) · v0.1.0 · hecho · transversal (AD-01, AD-02, AD-13) · tareas: [T-00](../tasks/T-00-conexion-supabase.md)
- [P-01 · Auditoría de accesos guardada en Supabase](P-01-auditoria-supabase.md) · v0.1.0 · hecho · F-20, F-21 · tareas: [T-01](../tasks/T-01-auditoria-supabase.md)
- [P-02 · Foto de perfil guardada en Supabase Storage](P-02-perfil-foto-storage.md) · v0.1.0 · hecho · F-22 · tareas: [T-02](../tasks/T-02-perfil-foto-storage.md)
- [P-04 · Pasar a Supabase lo que sigue en memoria](P-04-datos-restantes-supabase.md) · v0.1.0 · hecho · F-01 a F-04, F-07 a F-12, F-20, F-21 · tareas: T-18 a T-24 en [impl_progress](../impl_progress.md)
