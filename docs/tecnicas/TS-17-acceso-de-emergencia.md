---
id: TS-17
titulo: Acceso de emergencia
version: 0.1.0
fecha: 2026-11-24
estado: borrador
funcional: F-17 0.2.7
---

# TS-17 · Acceso de emergencia

## Resumen

Un evento es de emergencia si su propósito es *Urgencia* y su resultado es *Permitido*. Esa marca se calcula al leer los eventos de Supabase, y el aviso se muestra al ver la historia y al guardar una atención con *Urgencia*.

## Preparación en Supabase

- Sembrar al menos 1 evento permitido con propósito *Urgencia* en `evento_auditoria` (RNF-04, CA-8), por ejemplo la consulta de Hernán Darío Quintero por la Dra. Camila.

## Piezas

- `lib/modelos/modelos.dart` · **cambia** (T-12) · `EventoAuditoria.esEmergencia` es *Urgencia* con resultado *Permitido*.
- `lib/repositorios/auditoria_supabase.dart` · **cambia** (T-12) · al leer, traduce `proposito` y `resultado` a los enums de la app.
- `lib/screens/app_screen_guardado.dart` · **cambia** (T-12) · al guardar una atención con *Urgencia* muestra "Acceso de emergencia: queda registrado y el auditor lo revisará", con o sin relación.
- `lib/pages/paciente_page.dart` · **cambia** (T-12) · la historia muestra el mismo aviso cuando el acceso fue con *Urgencia*.
- `lib/reglas/reglas.dart` · **sin cambio** · los textos del aviso (`avisoAccesoEmergencia`) ya están en un solo lugar.

## Estado

- Ninguno nuevo: la marca se deriva del evento y el aviso sale de la consulta en curso.

## Datos

- `evento_auditoria.proposito` y `evento_auditoria.resultado`. El filtro *Emergencia* de la auditoría usa la misma regla.

## Paquetes y plataformas

- Ninguno nuevo.

## Tareas

- **T-12** Marca y aviso de emergencia: el filtro *Emergencia* muestra los eventos de *Urgencia* permitidos (los denegados no), la historia y el guardado de una atención muestran el aviso, y no se pide ninguna justificación. · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-8, CA-9, CA-10 · depende de: T-11
  - Prueba: como la Dra. Camila abrir un paciente sin relación con *Urgencia* y ver la historia con el aviso; como auditor elegir *Emergencia* y ver ese evento; abrir el mismo paciente con *Atención del paciente* y ver que el rechazo no aparece en *Emergencia*; registrar una atención con *Urgencia* y ver el aviso; como administrativo declarar *Urgencia* y no ver información del paciente.

## Preguntas abiertas

- ¿Un evento denegado que declara *Urgencia* (por ejemplo, un administrativo) debe quedar visible de otra forma para el auditor? Hoy no es de emergencia.

## Historial

- 0.1.0 · 2026-11-24 · Primera versión.
