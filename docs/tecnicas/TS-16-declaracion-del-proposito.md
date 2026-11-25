---
id: TS-16
titulo: Declaración del propósito de consulta
version: 0.1.0
fecha: 2026-11-24
estado: borrador
funcional: F-16 0.3.6
---

# TS-16 · Declaración del propósito de consulta

## Resumen

El pop-up del propósito ya existe. Lo que falta es que los propósitos de cada rol, y los dos de registrar una atención, salgan de una sola matriz en el servicio de control de acceso (AD-06), y que el propósito viaje en el evento que se guarda en Supabase.

## Preparación en Supabase

- Ninguna. La columna del propósito ya está en `evento_auditoria`.

## Piezas

- `lib/services/access_control_service.dart` · **nueva** (T-11) · servicio. `purposesFor(Rol rol, {bool registering}) → List<Proposito>`; `decidePurpose(Usuario user, Proposito purpose) → AccessDecision`. Reutiliza las funciones puras de `lib/reglas/reglas.dart` (`propositosDe`, `propositosParaRegistrar`) y no las duplica.
- `lib/widgets/proposito.dart` · **cambia** (T-11) · el pop-up recibe la lista de propósitos del servicio; ninguno viene elegido.
- `lib/screens/app_screen.dart` · **cambia** (T-11) · al confirmar sin elegir muestra "Elija el propósito de la consulta"; al cancelar vuelve a donde estaba o, si el propósito lo pidió la lista tras iniciar sesión, queda en el *Tablero de indicadores*.
- `lib/repositorios/auditoria_repositorio.dart` · **sin cambio** · el evento lleva el propósito declarado.

## Estado

- Screen anfitriona: la solicitud en curso (paciente, propósito elegido, error y si es para registrar). El propósito no se guarda en la sesión ni se hereda de una consulta a otra (AD-05).

## Datos

- Columna `proposito` de `evento_auditoria`: `seguimiento_reingreso`, `consulta_historia`, `atencion_paciente`, `revision_calidad` o `urgencia`; vacío (*No aplica*) cuando no hay propósito.

## Paquetes y plataformas

- Ninguno nuevo.

## Tareas

- **T-11** Matriz única de propósitos por rol: el médico ve los 5 al consultar o abrir la lista y solo *Atención del paciente* y *Urgencia* al registrar; el administrativo solo *Revisión de calidad*; ninguno viene elegido, no se hereda, un propósito no permitido para el rol se rechaza con su evento y el propósito queda en el evento guardado. · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-8, CA-9, CA-10 · depende de: T-04
  - Prueba: como médico abrir un paciente y ver los 5 sin ninguno elegido; confirmar sin elegir y ver "Elija el propósito de la consulta"; consultar a otro paciente y ver que no viene elegido; cancelar y no ver ningún evento nuevo; como administrativo ver solo *Revisión de calidad*; pedir registrar una atención y ver solo 2; revisar en la auditoría el propósito *Seguimiento de reingreso*.

## Preguntas abiertas

- ¿Qué se muestra si la lista de propósitos del rol llega vacía (por ejemplo, el auditor)? F-16 solo dice que no declara ninguno.

## Historial

- 0.1.0 · 2026-11-24 · Primera versión.
