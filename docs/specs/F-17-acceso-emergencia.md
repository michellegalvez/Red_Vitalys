---
id: F-17
titulo: Acceso de emergencia
version: 0.2.3
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-20]
depende_de: [F-04, F-05, F-16, F-18]
---

# F-17 · Acceso de emergencia

## Objetivo

El médico puede ver la historia de un paciente, o registrarle una atención, cuando no tiene relación con él y lo necesita con urgencia, y ese acceso queda marcado como emergencia para que el auditor lo revise (O-04, O-05).

## Flujo principal

1. El médico elige un paciente con el que no tiene relación (F-05).
2. En la declaración del propósito (F-16) elige *Urgencia* y confirma.
3. El sistema crea un evento *Consultar* sobre *Historia clínica* con propósito *Urgencia* y resultado *Permitido*. Si no puede crearlo, no muestra la historia (F-20).
4. El sistema permite el acceso y muestra la historia (F-02).
5. La historia muestra el aviso "Acceso de emergencia: queda registrado y el auditor lo revisará".

## Flujos alternos

- **A1 · Con relación:** si el médico tiene relación y declara *Urgencia*, el acceso se permite y también queda marcado como emergencia, porque la marca depende del propósito.
- **A2 · Otro rol:** *Urgencia* solo es para el médico. Si un administrativo o un auditor intenta usarla, se rechaza y queda un evento *Denegado* (F-18).
- **A3 · Sin *Urgencia*:** sin relación y con otro propósito, el acceso se rechaza (F-05).
- **A4 · Registrar una atención:** el médico sin relación elige *Registrar atención* (F-04) y declara *Urgencia*. La atención se registra y el evento queda con la acción *Registrar*, el recurso *Atención* y el propósito *Urgencia*, marcado como emergencia.

## Reglas

- Solo el médico puede declarar *Urgencia*.
- Un evento es de emergencia si su propósito es *Urgencia*.
- El acceso de emergencia se permite sin pedir una justificación escrita.
- El acceso de emergencia aplica a la historia clínica, al riesgo de reingreso y al registro de una atención.
- Una atención registrada con *Urgencia* no le da al médico relación con el paciente (F-05).
- Los eventos de emergencia aparecen en el filtro *Emergencia* de la auditoría (F-21).
- El médico no puede quitar la marca de emergencia.
- El aviso se muestra en cada consulta de emergencia.
- Los datos son simulados.

## Estados

- **Cargando:** el de la consulta (F-02).
- **Vacío:** no aplica.
- **Error:** el de la consulta (F-02).

## Datos

- **Propósito** *Urgencia*.
- **Marca de emergencia** del evento.

## Criterios de aceptación

- **CA-1** Dada la Dra. Camila Martínez sin relación con un paciente, cuando declara *Urgencia*, entonces ve su historia y el aviso "Acceso de emergencia: queda registrado y el auditor lo revisará".
- **CA-2** Dado el acceso del criterio anterior, cuando el auditor revisa la auditoría, entonces ve un evento con la acción *Consultar*, el recurso *Historia clínica*, ese paciente, el propósito *Urgencia* y el resultado *Permitido*.
- **CA-3** Dado el evento anterior, cuando el auditor elige el filtro *Emergencia*, entonces lo ve en la lista.
- **CA-4** Dado un médico con relación con el paciente, cuando declara *Urgencia*, entonces ve la historia y el evento queda en el filtro *Emergencia*.
- **CA-5** Dado un médico sin relación, cuando declara *Atención del paciente*, entonces no ve la historia y queda un evento *Denegado* que no aparece en el filtro *Emergencia*.
- **CA-6** Dado que el sistema recibe la consulta de un administrativo con el propósito *Urgencia*, cuando la procesa, entonces no se muestra la información del paciente y queda un evento con el resultado *Denegado*.
- **CA-7** Dado un médico, cuando abre la historia con *Urgencia*, entonces no se le pide ninguna justificación.
- **CA-8** Dados los datos simulados, cuando el auditor elige *Emergencia*, entonces ve al menos 1 evento (RNF-04).
- **CA-9** Dada la Dra. Camila Martínez sin relación con un paciente, cuando registra una atención declarando *Urgencia*, entonces la atención se registra y el auditor ve un evento con la acción *Registrar*, el recurso *Atención*, el propósito *Urgencia* y el resultado *Permitido*, que aparece en el filtro *Emergencia*.

## Fuera de alcance

- Avisarle al auditor o al responsable cuando ocurre una emergencia.
- Marcar un acceso de emergencia como revisado.
- Pedir una justificación del médico.

## Preguntas abiertas

- ¿El médico debe confirmar antes de entrar de emergencia, con un mensaje previo que diga que el acceso queda marcado? Hoy el aviso sale después.
- ¿Debe exigirse una justificación escrita? Hoy no.
- ¿Cuánto tiempo dura el acceso de emergencia? Hoy vale solo para esa consulta.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.1.1 · 2026-11-06 · CA-6 se redacta a nivel del sistema, porque un administrativo no puede declarar *Urgencia* desde la app.
- 0.2.0 · 2026-11-06 · La emergencia también cubre el registro de una atención (A4, CA-9), como RF-20 0.5.0 y F-04. Depende también de F-04.
- 0.2.1 · 2026-11-06 · Una atención registrada con *Urgencia* no da relación, como RF-25 0.6.0.
- 0.2.2 · 2026-11-06 · El evento se crea antes de ejecutar la acción, y si no se puede crear la acción no se hace, como RF-14 0.6.1 y AD-07 0.6.1.
- 0.2.3 · 2026-11-06 · Formato: línea en blanco antes de los encabezados y lista de criterios sin cortes.
