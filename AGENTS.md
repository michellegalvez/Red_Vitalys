# AGENTS.md · Red Vitalys

## Qué es la app

Red Vitalys es una red de salud colombiana con seis clínicas de alta complejidad, cuarenta centros ambulatorios y una cadena de laboratorios cuyos sistemas de historia clínica no se comunican entre sí. Hoy no se reconoce a un mismo paciente en distintas sedes ni se comparte su información a tiempo.

La app es el frontend para la Dirección Médica y el personal clínico. Con ella el usuario puede:

- Consultar la historia clínica unificada de un paciente.
- Ver el tablero de indicadores de calidad: reingreso hospitalario a 30 días, tiempo de espera, adherencia a protocolos clínicos y eventos adversos evitables, por sede.
- Ver el riesgo de reingreso de un paciente y la explicación de qué factores lo subieron o bajaron.
- Ver su perfil y lo que puede hacer según su rol (médico, administrativo, auditor).
- Revisar la auditoría de accesos: quién accedió, cuándo, a qué recurso, con qué resultado y con qué propósito.

El acceso depende del rol, de la sede desde la que se ingresa y del propósito declarado en cada consulta, y cada acción queda registrada.

Equipo: Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco y Samuel Cardoso Martinez.
Materia: Seminario en Ingeniería de Software · Universidad Icesi.

## Estructura actual de lib/

Proyecto recién creado con `flutter create`. Todavía no hay código propio:

```
lib/
└── main.dart   # app de ejemplo generada por Flutter
```

## Documentos

La carpeta `docs/` tiene los documentos que guían el desarrollo (Spec Driven Development), en este orden:

- `docs/prd.md`: el PRD, con el problema, los usuarios, los objetivos medibles y el alcance.
- `docs/requisitos.md`: los requisitos funcionales (RF) y no funcionales (RNF), numerados y ligados a un objetivo.
- `docs/architectural_spine.md`: la architectural spine, con el stack, el diagrama y las invariantes.
- `docs/specs/`: una spec funcional por funcionalidad, con el índice en `docs/specs/README.md` y el reporte de la crítica en `docs/specs/reporte.md`.

Las skills que crean y revisan esos documentos están en `.agents/skills/`.
