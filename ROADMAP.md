# 🗺️ Roadmap

El programa se construye por fases. El **currículo escrito** (README completo por cada clase)
es la base y el primer entregable.

## Fase 1 — Currículo escrito ✅ (completa)

- [x] Diseño del currículo: 22 partes, 352 clases, numeración secuencial 001–352.
- [x] Estructura de carpetas + índice maestro y manifest generados (`scripts/generar_indice.py`).
- [x] README rico por parte (22) + README rico por clase (352): objetivo, temas, definiciones, laboratorio guiado, ejercicios, reto verificable, errores comunes, FAQ y referencias.
- [x] **Partes 0–7** (clases 001–155): fundamentos, 2D, 3D, física, shaders, IA, audio y multijugador.
- [x] **Partes 8–17** (clases 156–292): game design, arte, UI/UX, plataformas, web, VR/AR, optimización, tooling, producción y preparación profesional.
- [x] **Partes 18–21** (clases 293–352): arquitectura de gameplay, ingeniería de producción y backend, IA generativa y arquitectura avanzada de motores.

**Las 22 partes del currículo escrito están completas.** La numeración 001–292 no cambió al añadir las cuatro últimas partes: las clases y sus URLs siguen donde estaban.

## Fase 2 — Laboratorios ejecutables (en curso)

- [ ] Proyecto base de Godot por parte, versionado y clonable.
- [x] Lab **[plataformas 2D](labs/plataformas-2d/README.md)** completo (Parte 1) como repositorio jugable.
- [x] Lab **[3D third-person controller](labs/3d-tercera-persona/README.md)** (Parte 2).
- [x] Lab **[shaders](labs/shaders/README.md)** con ejemplos ejecutables (Parte 4).
- [x] Lab **[multijugador](labs/multijugador/README.md)** cliente-servidor mínimo (Parte 7).
- [x] Lab **[IA de enemigos](labs/ia-enemigo/README.md)** con behavior tree, percepción y A* (Parte 5).
- [x] Lab **[UI accesible y localizada](labs/ui-accesible/README.md)** (Parte 10).
- [x] Lab **[sistemas de gameplay](labs/gameplay-systems/README.md)** (Parte 18) — 122 comprobaciones.
- [x] Lab **[runtime de producción](labs/production-runtime/README.md)** (Parte 19) — 91 comprobaciones.
- [x] Lab **[sistema de IA en el juego](labs/ai-game-system/README.md)** (Parte 20) — 55 comprobaciones, offline y sin claves.
- [x] Lab **[ingeniería avanzada](labs/advanced-engineering/README.md)** (Parte 21) — 33 comprobaciones.

Cada lab viene en versión `inicio/` (con `TODO`) y `solucion/`, y las dos se verifican en
CI con Godot headless. Ver **[labs/](labs/README.md)**.

## Fase 3 — Material complementario (en curso)

- [x] Guías **PDF** imprimibles por clase (`scripts/generar_material.py`, en B/N para imprimir).
- [ ] Presentaciones **PPTX** por clase.
- [x] Assets de práctica (sprites, tilesets, texturas y sonidos **CC0 generados por código**:
      `scripts/generar_assets.py`).

## Fase 4 — Portal y evaluación ✅ (completa)

- [x] Sitio web navegable del currículo (GitHub Pages: `scripts/generar_sitio.py` + `deploy-pages.yml`).
- [x] Autoevaluaciones interactivas por parte (`autoevaluaciones/quiz.html`).
- [x] Seguimiento de progreso de las clases (localStorage: `autoevaluaciones/progreso.html`).
- [x] Rutas guiadas por rol (`rutas/README.md`) — 7 de base + 6 de especialización.

## Fase 5 — Especialización en ingeniería ✅ (completa)

- [x] **Parte 18** (293–310): sistemas de gameplay data-driven, inventario, stats, habilidades, efectos, loot, crafteo, progresión, economía, diálogo, quests, facciones, guardado de producción, comandos y modding.
- [x] **Parte 19** (311–324): arquitectura de backend, identidad, saves en la nube, economía autoritativa, remote config, observabilidad, telemetría con privacidad, modelado de amenazas, anti-cheat, testing de producción, regresión de rendimiento, release engineering y parches.
- [x] **Parte 20** (325–338): IA generativa para desarrollo y dentro del juego, con mocks deterministas y sin claves de API. **Complementa la Parte 5, no la sustituye.**
- [x] **Parte 21** (339–352): DOD, allocators, job systems, particionamiento espacial, streaming, mundos grandes, rendering temporal, upscaling, HDR, GI, GPU-driven, stutter de shaders y APIs gráficas modernas.
- [x] Cuatro laboratorios ejecutables, 301 comprobaciones en total, **CI completamente offline**.
- [x] [Documento de la evolución 292 → 352](docs/EVOLUTION-292-TO-352.md).

---

**Prioridad actual:** las presentaciones **PPTX** de la Fase 3, y los labs que aún tienen
sentido: **física** (Parte 3, con integradores propios en vez del solver, que no es
reproducible), **audio** (Parte 6, solo su parte estructural: su capstone se juzga de oído) y
**tooling** (Parte 15). No habrá un lab por parte: las de arte, producción y carrera terminan
en un entregable que no es un ejecutable, y las de VR/AR y móvil no se pueden verificar sin
hardware (ver [labs/](labs/README.md)). Del mismo modo, las clases 345–351 (rendering temporal,
upscaling, HDR, GI, GPU-driven y stutter de shaders) **no tienen lab y no lo tendrán mientras
la CI no tenga pantalla**: medirlas exige hardware gráfico concreto, y prometer un badge verde
sobre algo que no se ejecuta sería exactamente lo que aquí no se hace.
¿Ideas o mejoras? Abre un *issue*.
