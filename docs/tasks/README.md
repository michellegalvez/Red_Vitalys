# Tareas · Red Vitalys

Cada archivo de tareas baja **un** plan a pasos pequeños que una persona puede terminar y comprobar en una sola sesión. El plan dice el enfoque; las tareas, el orden.

## Formato de un archivo de tareas

Archivo `docs/tasks/T-NN-nombre-corto.md`, con el mismo `NN` que su plan.

```markdown
---
id: T-00
titulo: Tareas de la conexión con Supabase
version: 0.1.0
fecha: 2026-11-20
plan: P-00                # el plan del que sale (uno solo)
estado: pendiente         # pendiente | en curso | hecho
autores: [Nombre Apellido, ...]   # todo el equipo, como en las specs y los planes
---

# T-00 · Título

Plan: [P-00](../plans/P-00-nombre.md)

## Tareas

- [ ] **T-00.1** · Qué se hace, en una frase y en infinitivo.
  - Toca: `ruta/archivo.dart`
  - Se comprueba: comando u observación concreta, con el resultado esperado.
```

Reglas:

- Una tarea cabe en un commit. Si necesita más de uno, se parte.
- Toda tarea lleva **Se comprueba** con algo que se pueda ejecutar o ver, no "queda bien".
- El id es `T-NN.k` y no se reutiliza. Si una tarea se descarta, se tacha con `~~` y se deja la razón.
- Se marca `[x]` solo cuando su comprobación pasó.
- Las tareas siguen el orden del plan: cada una puede depender de las anteriores, nunca de las siguientes.
- El mensaje del commit cita el id: `feat(T-00.3): inicializa Supabase en main`.
- Antes de marcar un archivo como `hecho`: `dart format lib test`, `flutter analyze` y `flutter test`.

## Índice

- [T-00 · Conexión con Supabase](T-00-conexion-supabase.md) · v0.1.0 · hecho · plan P-00
- [T-01 · Auditoría en Supabase](T-01-auditoria-supabase.md) · v0.1.0 · hecho · plan P-01
- [T-02 · Foto de perfil en Storage](T-02-perfil-foto-storage.md) · v0.1.0 · hecho · plan P-02
