---
id: F-21
titulo: Consulta de la auditoría de accesos
version: 0.1.4
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-15, RF-16]
depende_de: [F-18, F-20]
---

# F-21 · Consulta de la auditoría de accesos

## Objetivo

El auditor revisa quién accedió a la información de los pacientes, cuándo, a qué recurso, con qué propósito y con qué resultado, y separa los accesos denegados y los de emergencia para revisarlos (O-04).

## Flujo principal

1. El auditor entra a *Auditoría de accesos*.
2. El sistema muestra todos los eventos de acceso, del más reciente al más antiguo, con el filtro *Todos* seleccionado.
3. Cada evento muestra su fecha y hora, el usuario y la acción. Al deslizar se ven el recurso, el paciente, el propósito, el resultado, la sede y, en los inicios de sesión fallidos, la IP.
4. La pantalla muestra el contador de cuántos eventos hay con el filtro elegido, por ejemplo "8 eventos".

## Flujos alternos

- **A1 · Filtrar denegados:** el auditor elige *Denegados*. El sistema muestra solo los eventos con resultado *Denegado*, en el mismo orden, y el contador se actualiza, por ejemplo a "2 eventos".
- **A2 · Filtrar emergencias:** el auditor elige *Emergencia*. El sistema muestra solo los eventos con propósito *Urgencia*, y el contador se actualiza.
- **A3 · Volver a todos:** el auditor elige *Todos* y vuelve a ver todos los eventos.
- **A4 · Filtro sin eventos:** si el filtro elegido no tiene eventos, se ve "No hay eventos con este filtro" y el contador dice "0 eventos".
- **A5 · Otro rol intenta entrar:** si un médico o un administrativo intenta abrir la auditoría, el acceso se rechaza y queda registrado como *Denegado* (RF-21).

## Reglas

- Solo el auditor puede ver la auditoría de accesos.
- Los filtros son *Todos*, *Denegados* y *Emergencia*. Son excluyentes, así que hay siempre uno elegido.
- Al abrir la auditoría el filtro elegido es *Todos*.
- Los eventos van siempre del más reciente al más antiguo.
- No hay paginación: se muestran todos los eventos que cumplen el filtro.
- El contador muestra la cantidad de eventos que cumplen el filtro elegido, en la forma "N eventos".
- La pantalla dice que los registros no se pueden editar. No hay ninguna opción para editar ni borrar eventos (RF-17, F-20).
- El auditor no puede modificar información clínica ni administrativa desde esta pantalla.
- Las fechas van en el formato "30 oct 2026 · 09:47", con la hora en formato de 24 horas.
- En un inicio de sesión fallido, el usuario es el correo con el que se intentó, la sede queda vacía y se ve la IP.
- Los eventos sin paciente (inicios de sesión, mediciones, la lista de pacientes con alta reciente y la auditoría de accesos) muestran el paciente vacío.

## Estados

- **Cargando:** mientras llegan los eventos, se ve "Cargando eventos…" en lugar de la lista.
- **Vacío:** si el filtro no tiene eventos, se ve "No hay eventos con este filtro" y el contador dice "0 eventos".
- **Error:** si los eventos no se pueden cargar, se ve "No se pudieron cargar los eventos" con la opción *Reintentar*.

## Datos

Por cada evento de acceso (definido en F-20):

- **Se ve al abrir:**
  - Fecha y hora.
  - Usuario.
  - Acción.
- **Se ve al deslizar, en este orden:**
  - Recurso.
  - Paciente.
  - Propósito.
  - Resultado.
  - Sede.
  - IP, solo en los inicios de sesión fallidos.

Además:

- El filtro elegido.
- El contador de eventos.

## Criterios de aceptación

- **CA-1** Dado que el auditor inició sesión, cuando abre la auditoría de accesos, entonces ve todos los eventos del más reciente al más antiguo, el filtro *Todos* elegido y el contador con el total, por ejemplo "8 eventos".
- **CA-2** Dado el auditor en la auditoría, cuando desliza la lista, entonces ve de cada evento el recurso, el paciente, el propósito, el resultado y, al final, la sede.
- **CA-3** Dado el auditor en la auditoría, cuando elige *Denegados*, entonces solo ve los eventos con resultado *Denegado* y el contador muestra su cantidad, por ejemplo "2 eventos".
- **CA-4** Dado el auditor en la auditoría, cuando elige *Emergencia*, entonces solo ve los eventos con propósito *Urgencia* y el contador muestra su cantidad.
- **CA-5** Dado el filtro *Denegados* elegido, cuando el auditor elige *Todos*, entonces vuelve a ver todos los eventos y *Denegados* deja de estar elegido.
- **CA-6** Dado que no hay eventos de emergencia, cuando el auditor elige *Emergencia*, entonces ve "No hay eventos con este filtro" y el contador dice "0 eventos".
- **CA-7** Dado que los eventos no se pueden cargar, cuando el auditor abre la auditoría, entonces ve "No se pudieron cargar los eventos" y, al elegir *Reintentar*, el sistema vuelve a cargarlos.
- **CA-8** Dado un médico o un administrativo, cuando intenta abrir la auditoría de accesos, entonces no la ve y queda un evento con resultado *Denegado*.
- **CA-9** Dado el auditor en la auditoría, cuando revisa cualquier evento, entonces no encuentra ninguna opción para editarlo ni borrarlo.
- **CA-10** Dados los datos simulados, cuando el auditor abre la auditoría, entonces la lista se muestra en menos de 2 segundos (RNF-06).
- **CA-11** Dados los datos simulados, cuando el auditor abre la auditoría con el filtro *Todos*, entonces ve al menos 8 eventos, al menos 1 *Denegado* y al menos 1 con propósito *Urgencia* (RNF-04). Viene de F-20 CA-8.
- **CA-12** Dado un inicio de sesión fallido, cuando el auditor desliza ese evento, entonces ve el correo con el que se intentó como usuario, la IP, el resultado *Denegado* y la sede vacía.

## Fuera de alcance

- Crear los eventos, que es F-20.
- Buscar por usuario, por paciente o por rango de fechas, y combinar filtros.
- Exportar o imprimir la auditoría.
- Marcar un evento como revisado.

## Preguntas abiertas

- ¿Abrir la auditoría, siendo auditor, debe quedar registrado como un evento? Hoy no queda, porque no es información de un paciente (RF-14).
- Sin paginación, ¿hasta cuántos eventos debe aguantar la pantalla en la entrega 3, cuando haya más que los datos simulados?

## Historial

- 0.1.0 · 2026-11-06 · Primera versión, alineada con los requisitos 0.1.0: muestra la IP de los inicios de sesión fallidos (CA-12) y el paciente vacío en los eventos sin paciente.
- 0.1.1 · 2026-11-06 · Los eventos sin paciente incluyen el rechazo de la lista de pacientes con alta reciente (F-20 0.2.0).
- 0.1.2 · 2026-11-06 · Depende también de F-18, que decide el rechazo de A5.
- 0.1.3 · 2026-11-06 · Se aprueban los textos de los estados como definitivos. Se cierra esa pregunta abierta.
- 0.1.4 · 2026-11-06 · Formato: línea en blanco antes de los encabezados y lista de criterios sin cortes.
