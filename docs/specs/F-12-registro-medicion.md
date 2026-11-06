---
id: F-12
titulo: Registro de la medición mensual de una sede
version: 0.2.3
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-13, RF-28, RF-29, RF-30]
depende_de: [F-08, F-18]
---

# F-12 · Registro de la medición mensual de una sede

## Objetivo

Cuando cierra el mes, el administrativo registra el valor de un indicador para una sede, y ese valor alimenta el tablero y los detalles (O-03).

## Flujo principal

1. El administrativo elige *Registrar medición*.
2. Elige el indicador, la sede y el mes, y digita el valor ya calculado por la sede.
3. Confirma.
4. El sistema valida la medición.
5. El sistema crea un evento de acceso *Registrar* sobre *Medición de indicador*. Si no puede crearlo, no guarda la medición (F-20).
6. El sistema guarda la medición y muestra "Medición registrada".
7. La medición aparece entre las mediciones recientes (F-11) y entra en el promedio de la red del tablero (F-08).

## Flujos alternos

- **A1 · Valor fuera de rango:** se ve "El valor debe estar entre X y Y", con el rango del indicador, y no se guarda.
- **A2 · Mes sin terminar:** si el mes no ha terminado, se ve "El mes todavía no ha terminado" y no se guarda.
- **A3 · Medición repetida:** si el indicador ya tiene medición de esa sede en ese mes, se ve "Ya existe una medición de este indicador para esta sede en ese mes" y no se guarda.
- **A4 · Indicador que no aplica:** si el indicador no aplica al tipo de sede, se ve "Este indicador no aplica a esta sede" y no se guarda.
- **A5 · Error al guardar:** se ve "No se pudo registrar la medición" y lo que el administrativo digitó se conserva.
- **A6 · Otro rol:** si un médico o un auditor intenta registrar una medición, se rechaza y queda un evento *Denegado* (F-18).
- **A7 · Más de 1 decimal:** si el valor tiene más de 1 decimal, se ve "Use máximo 1 decimal" y no se guarda.

## Reglas

- Solo el administrativo registra mediciones.
- Puede registrar mediciones de cualquier sede de la red, no solo la de su sesión.
- El administrativo digita el valor. La app no lo calcula a partir de las atenciones.
- El valor debe estar dentro del rango del indicador:

| Indicador | Rango válido | Aplica en |
|---|---|---|
| Reingreso hospitalario a 30 días (%) | 0 a 100 | clínicas |
| Tiempo de espera promedio (min) | 0 a 1.440 | clínicas y centros ambulatorios |
| Adherencia a protocolos clínicos (%) | 0 a 100 | clínicas y centros ambulatorios |
| Eventos adversos evitables (por cada 1.000 atenciones) | 0 a 1.000 | clínicas y centros ambulatorios |

- El valor admite hasta 1 decimal, con coma, por ejemplo "8,5".
- Un mes cierra cuando termina. La medición de noviembre se puede registrar desde el 1 de diciembre.
- Hay una sola medición por indicador, sede y mes.
- Los laboratorios no tienen indicadores.
- Una medición registrada no se edita ni se borra en esta versión.
- Las validaciones se hacen en un único lugar (AD-11), sin importar desde dónde se registre.
- El evento de auditoría no tiene paciente y su propósito es *No aplica*.
- Los datos son simulados.

## Estados

- **Cargando:** mientras se guarda, se ve "Guardando medición…" y no se puede confirmar de nuevo.
- **Vacío:** no aplica.
- **Error:** el mensaje de A5.

## Datos

- **Indicador**, **sede** y **mes** (periodo).
- **Valor** digitado, con la unidad del indicador.
- **Administrativo** que la registra y **fecha y hora** del registro.

## Criterios de aceptación

- **CA-1** Dado un administrativo, cuando registra el tiempo de espera de 34 min de una clínica para octubre de 2026, entonces ve "Medición registrada" y la ve entre las mediciones recientes de ese indicador.
- **CA-2** Dada una medición recién registrada, cuando el administrativo abre el tablero, entonces el promedio de la red de ese indicador incluye esa medición.
- **CA-3** Dado un administrativo con la sede de la sesión en una sede A, cuando registra una medición para una sede B, entonces la medición se registra.
- **CA-4** Dada una adherencia de 120, cuando el administrativo confirma, entonces ve "El valor debe estar entre 0 y 100" y la medición no se guarda.
- **CA-5** Dado que hoy es el 6 de noviembre de 2026 (RNF-04), cuando el administrativo intenta registrar una medición de noviembre, entonces ve "El mes todavía no ha terminado" y no se guarda.
- **CA-6** Dado un indicador que ya tiene medición de octubre para esa sede, cuando el administrativo registra otra, entonces ve el mensaje de medición repetida y no se guarda.
- **CA-7** Dado un centro ambulatorio, cuando el administrativo intenta registrar el reingreso para él, entonces ve "Este indicador no aplica a esta sede" y no se guarda.
- **CA-8** Dado que el guardado falla, cuando el administrativo confirma, entonces ve "No se pudo registrar la medición" y el formulario conserva lo digitado.
- **CA-9** Dado un administrativo que registró una medición, cuando el auditor revisa la auditoría, entonces ve un evento con la acción *Registrar*, el recurso *Medición de indicador*, sin paciente, el propósito *No aplica* y el resultado *Permitido*.
- **CA-10** Dado un médico, cuando intenta registrar una medición, entonces no puede y queda un evento con la acción *Registrar*, el recurso *Medición de indicador* y el resultado *Denegado*.
- **CA-11** Dado un administrativo que digita 8,55 en el reingreso, cuando confirma, entonces ve "Use máximo 1 decimal" y la medición no se guarda; si digita 8,5, se guarda.

## Fuera de alcance

- Calcular el valor a partir de las atenciones.
- Editar o borrar una medición registrada.
- Importar mediciones desde un archivo.
- Ver las mediciones, que es F-11.

## Preguntas abiertas

- ¿Una medición registrada con error se puede corregir? Quedó fuera de alcance en esta versión.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.1.1 · 2026-11-06 · CA-5 se liga a la fecha de hoy fija de RNF-04.
- 0.1.2 · 2026-11-06 · Se confirma el propósito *No aplica* del evento de una medición. Se cierra esa pregunta abierta.
- 0.2.0 · 2026-11-06 · El valor admite hasta 1 decimal (A7, CA-11) y se aprueban los textos de los mensajes. Se cierran 2 preguntas abiertas.
- 0.2.1 · 2026-11-06 · El evento se crea antes de ejecutar la acción, y si no se puede crear la acción no se hace, como RF-14 0.6.1 y AD-07 0.6.1. Una medición rechazada por la validación no crea evento.
- 0.2.2 · 2026-11-06 · Formato: línea en blanco antes de los encabezados y lista de criterios sin cortes.
- 0.2.3 · 2026-11-06 · La red tiene una cadena de laboratorios clínicos propia: "el laboratorio" pasa a plural.
