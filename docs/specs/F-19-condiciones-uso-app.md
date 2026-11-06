---
id: F-19
titulo: Condiciones de uso de la app
version: 0.2.0
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RNF-01, RNF-03, RNF-05, RNF-07]
depende_de: []
---

# F-19 · Condiciones de uso de la app

## Objetivo

El médico, el administrativo y el auditor usan la app de la misma manera desde el navegador de un computador y desde un celular Android, en español, y en la entrega 2 sin necesitar conexión a internet (O-01 a O-05).

Esta spec no describe una función con su propio flujo. Reúne las condiciones que valen para todas las pantallas, para poder comprobarlas en un solo lugar.

## Flujo principal

1. El usuario abre la app en el navegador de un computador o en la app instalada de un celular Android.
2. Inicia sesión (F-13) y recorre las pantallas que su rol permite.
3. Todos los textos están en español, y las fechas y las horas se ven en el formato de las *Reglas*.
4. Cada pantalla se usa completa sin desplazarse hacia los lados, tanto en el celular como en el computador.
5. En la entrega 2, todas las pantallas muestran sus datos sin conexión a internet.

## Flujos alternos

- **A1 · Celular y computador:** el usuario ve las mismas pantallas y las mismas opciones en los dos. Cambia solo cómo se acomoda el contenido al ancho disponible.
- **A2 · Sin conexión:** en la entrega 2 el usuario no ve ningún aviso de falta de conexión, porque la app no la necesita.

## Reglas

- La app funciona en el navegador web de un computador y como app instalada en celulares Android. iPhone no se incluye (RNF-01). En el computador, en Chrome y Edge en su versión actual. En el celular, en Android 10 o superior.
- En la entrega 2 la app funciona completa con datos simulados que viven en la app, sin conexión a la nube (RNF-03).
- Toda la interfaz está en español, incluidos los mensajes de los estados y de los errores (RNF-05).
- Las fechas van con el día, el mes abreviado en español y el año, por ejemplo "30 oct 2026". Cuando llevan hora, esta va en formato de 24 horas, por ejemplo "30 oct 2026 · 09:47" (RNF-05).
- Los meses abreviados son: ene, feb, mar, abr, may, jun, jul, ago, sep, oct, nov y dic.
- Todas las pantallas se pueden usar sin desplazamiento horizontal con un ancho de 360 px, que es el de un celular, y de 1280 px, que es el de un computador (RNF-07).
- Las fechas y los formatos se definen en un solo lugar para toda la app (AD-12).
- Los datos son simulados.

## Estados

- **Cargando:** no aplica. Cada pantalla tiene el suyo.
- **Vacío:** no aplica.
- **Error:** no aplica.

## Datos

- **Plataforma** desde la que se usa: navegador de un computador o Android.
- **Idioma** de la interfaz: español.
- **Formato de fecha y hora** de los eventos, las atenciones, las altas y las mediciones.

## Criterios de aceptación

- **CA-1** Dado un computador con Chrome o Edge en su versión actual, cuando el usuario abre la app e inicia sesión, entonces recorre las pantallas de su rol sin que falte ninguna.
- **CA-2** Dado un celular con Android 10 o superior y la app instalada, cuando el usuario inicia sesión, entonces recorre las mismas pantallas de su rol que en el computador.
- **CA-3** Dado un dispositivo sin conexión a internet en la entrega 2, cuando el usuario recorre las pantallas de su rol, entonces todas muestran sus datos.
- **CA-4** Dado cualquiera de los 3 roles, cuando recorre las pantallas que su rol permite, entonces todos los textos, mensajes y opciones están en español.
- **CA-5** Dado un evento del 30 de octubre de 2026 a las 09:47, cuando aparece en cualquier pantalla, entonces se ve "30 oct 2026 · 09:47".
- **CA-6** Dada una fecha sin hora en cualquier pantalla, cuando el usuario la ve, entonces lleva el día, el mes abreviado en español y el año, por ejemplo "30 oct 2026".
- **CA-7** Dada una hora de la tarde, cuando el usuario la ve, entonces está en formato de 24 horas, por ejemplo "15:30" y no "3:30 p. m.".
- **CA-8** Dado un ancho de 360 px, cuando el usuario abre cualquiera de las pantallas de su rol, entonces ve todo su contenido sin desplazarse hacia los lados.
- **CA-9** Dado un ancho de 1280 px, cuando el usuario abre cualquiera de las pantallas de su rol, entonces ve todo su contenido sin desplazarse hacia los lados.

## Fuera de alcance

- iPhone y otros sistemas de celular.
- Otros navegadores, como Firefox o Safari, y versiones de Android anteriores a la 10.
- Conectar la app a la nube, que es de la entrega 3.
- Otros idiomas.
- Lectores de pantalla y otras ayudas de accesibilidad, que no están en los requisitos.
- El rendimiento de cada pantalla, que está en la spec de cada una (RNF-06).

## Preguntas abiertas

- ¿Qué pasa en la entrega 3, cuando haya conexión, si el usuario la pierde? Hoy no está decidido.
- ¿Hay que probar también anchos intermedios, como el de una tableta?

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.2.0 · 2026-11-06 · Navegadores: Chrome y Edge en su versión actual. Android 10 o superior. Se cierran 2 preguntas abiertas.
