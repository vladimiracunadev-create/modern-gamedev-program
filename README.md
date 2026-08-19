<div align="center">

# 🎮 Programa de Desarrollo de Videojuegos Moderno

## **352 clases · 22 partes · de fundamentos a nivel profesional**

**El programa de desarrollo de videojuegos más completo en español — desde matemáticas, C#, C++ y game loops hasta motores 2D/3D, shaders, IA de juegos, multijugador, VR/AR, optimización, publicación, sistemas de gameplay, backend, IA generativa y arquitectura de motores.**

[![CI](https://github.com/vladimiracunadev-create/modern-gamedev-program/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/vladimiracunadev-create/modern-gamedev-program/actions/workflows/ci.yml)
[![Security](https://github.com/vladimiracunadev-create/modern-gamedev-program/actions/workflows/security.yml/badge.svg?branch=main)](https://github.com/vladimiracunadev-create/modern-gamedev-program/actions/workflows/security.yml)
[![Deploy Pages](https://github.com/vladimiracunadev-create/modern-gamedev-program/actions/workflows/deploy-pages.yml/badge.svg?branch=main)](https://github.com/vladimiracunadev-create/modern-gamedev-program/actions/workflows/deploy-pages.yml)
[![Labs (Godot)](https://github.com/vladimiracunadev-create/modern-gamedev-program/actions/workflows/labs.yml/badge.svg?branch=main)](https://github.com/vladimiracunadev-create/modern-gamedev-program/actions/workflows/labs.yml)

[![Clases](https://img.shields.io/badge/clases-352%20·%2022%20partes-7c5cff?style=for-the-badge)](classes/README.md)
[![Nivel](https://img.shields.io/badge/nivel-fundamentos%20→%20profesional-2e8b57?style=for-the-badge)](classes/README.md)
[![Idioma](https://img.shields.io/badge/idioma-español-blue?style=for-the-badge)](README.md)
[![Motores](https://img.shields.io/badge/motores-Godot%20·%20Unity%20·%20Unreal-orange?style=for-the-badge)](classes/README.md)
[![License](https://img.shields.io/badge/license-MIT-3fb950?style=for-the-badge)](LICENSE)

[🌐 Sitio del curso](https://vladimiracunadev-create.github.io/modern-gamedev-program/) · [📚 Clases](classes/README.md) · [🧪 Laboratorios](labs/README.md) · [🧭 Rutas](rutas/README.md) · [📝 Autoevaluación](autoevaluaciones/README.md) · [📖 Glosario](glosario/README.md) · [🗺️ Roadmap](ROADMAP.md)

</div>

---

> 🧭 **Estado del programa.** **Programa completo: las 22 partes (352 clases) están construidas** — de los fundamentos, el 2D y el 3D a física, shaders, IA, audio, multijugador, game design, arte, UI, plataformas, web, VR/AR, optimización, tooling, producción y carrera profesional; y de ahí a las cuatro partes de **especialización en ingeniería**: sistemas de gameplay, backend y confiabilidad, IA generativa y arquitectura avanzada de motores. Cada clase incluye laboratorio guiado paso a paso, ejercicios y reto verificable.
>
> **Qué está verificado por una máquina y qué no**, para que sepas de qué te fías: los **10 [laboratorios](labs/README.md)** son proyectos Godot completos que la CI importa, arranca y pone a prueba en cada push — los cuatro últimos con suites de **301 comprobaciones** entre todos. El código que vive dentro de los README de clase está escrito y revisado a mano, pero **no se ejecuta en CI**: es material de lectura y guía, no un proyecto que se abra. Si el badge de Labs está verde, lo que garantiza son los laboratorios.

## 🎯 Qué es esto

Un currículo modular y **secuencial** que cubre **todo el espectro del desarrollo de videojuegos moderno**, paso a paso, en clases numeradas (001→…) agrupadas en 22 partes. No es teoría suelta: **cada clase termina en un reto verificable con criterio de aceptación**. En las clases de programación eso es código que corre; en las de arte, producción o carrera, un entregable concreto (un set de assets, un presupuesto, un portfolio). Cada clase es una carpeta con un `README.md` completo que incluye:

- 🎯 **Objetivo** y **resultados de aprendizaje verificables**.
- 🗺️ **Temas** con el porqué de cada uno.
- 📖 **Definiciones y características** de los términos técnicos.
- 🧪 **Laboratorio guiado** paso a paso (con motores y herramientas reales).
- ✍️ **Ejercicios** y **reto verificable** con criterio de aceptación.
- ⚠️ **Errores comunes** (síntoma → causa → solución).
- ❓ **Preguntas frecuentes** auténticas.
- 🔗 **Referencias** a los libros y fuentes del área.

## 📚 Fuentes y trazabilidad

Cada clase cierra con sus fuentes, y cada fuente citada existe en un registro único con localizador resoluble. Lo que no se pudo resolver está declarado como hueco, no rellenado a ojo.

<!-- fuentes:inicio -->
![Fuentes](https://img.shields.io/badge/fuentes-207%20obras%20%C2%B7%20204%20verificadas%20%C2%B7%203%20pendientes-yellow)

**Registro de fuentes:** [`sources/bibliography.json`](sources/bibliography.json) ·
verificado el **2026-08-19** · comprobado por
[`scripts/verify-sources`](scripts/verify-sources).

| | |
|---|---:|
| Obras registradas | **207** |
| Con localizador resuelto (`verificada`) | **204** (98.6 %) |
| Con hueco declarado (`pendiente`) | **3** |
| Fuentes primarias / secundarias | **140** / **67** |
| Libros (ISBN-13) / artículos (DOI) / normas / documentación | **31** / **5** / **18** / **153** |
| Citas de clase cubiertas | **1490** en **352** clases |

**Política de versión del motor.** La documentación del motor y de la suite de
arte va anclada a versión, nunca a un alias móvil: **Godot 4.3** —la que
compila y ejecuta la CI de laboratorios— y **Blender 4.2 LTS**. Los alias
`/en/stable` y `/latest` se mueven solos y dejan al programa citando una versión
que nunca enseñó; `verify-sources` falla si reaparecen.

**Obras rectoras** (las primarias más usadas; la lista completa está en el registro):

| Obra | Autoría | Tipo | Clases | Localizador |
|---|---|---|---:|---|
| Godot Engine 4.3 documentation | Godot Engine (colaboradores del proyecto) | `reference` | 275 | [localizador](https://docs.godotengine.org/en/4.3/) |
| Game Engine Architecture | Gregory, Jason | `book` | 21 | [localizador](https://openlibrary.org/isbn/9781138035454) |
| Steamworks Documentation | Valve Corporation | `reference` | 19 | [localizador](https://partner.steamgames.com/) |
| Game Programming Patterns | Nystrom, Robert | `book` | 18 | [localizador](https://openlibrary.org/isbn/9780990582908) |
| OWASP — Top Ten y proyectos asociados | OWASP Foundation | `reference` | 16 | [localizador](https://owasp.org/) |
| Real-Time Rendering | Akenine-Möller, Tomas · Haines, Eric | `book` | 15 | [localizador](https://openlibrary.org/isbn/9781138627000) |
| MDN Web Docs | Mozilla y colaboradores de MDN | `reference` | 15 | [localizador](https://developer.mozilla.org/) |
| The Art of Game Design: A Book of Lenses | Schell, Jesse | `book` | 13 | [localizador](https://openlibrary.org/isbn/9781138632059) |
<!-- fuentes:fin -->

## 🧪 Laboratorios ejecutables

No solo se lee: se juega. El programa incluye **proyectos Godot reales** que se abren y se ejecutan, en versión `inicio/` (con `TODO` para que los completes) y `solucion/` (referencia jugable).

- 🕹️ **[Plataformas 2D](labs/plataformas-2d/README.md)** — el juego completo de la Parte 1: game feel, monedas, enemigos, HUD, audio y récord persistente.
- 🎮 **[3D en tercera persona](labs/3d-tercera-persona/README.md)** — el nivel explorable de la Parte 2: control relativo a la cámara, cámara orbital con `SpringArm3D` y recolectables.
- 🎨 **[Shaders](labs/shaders/README.md)** — la galería de la Parte 4: siete shaders (UV, ondas, disolución, contorno, agua, cel shading y CRT) con sus uniforms editables en marcha.
- 🌐 **[Multijugador](labs/multijugador/README.md)** — la arena en red de la Parte 7: servidor autoritativo, predicción, reconciliación e interpolación, verificado en CI levantando un servidor y tres clientes de verdad.
- 🧠 **[IA de enemigos](labs/ia-enemigo/README.md)** — el enemigo de la Parte 5: behavior tree, cono de visión, memoria y pathfinding A\*. La CI no comprueba que arranque, sino que **decide**: patrulla, te ve, te persigue, te pierde y va a buscarte.
- 🖥️ **[UI accesible](labs/ui-accesible/README.md)** — la interfaz de la Parte 10: idioma cambiable en marcha, texto al 200 % sin recortes y navegación completa con teclado. La UI se calcula en la CPU, así que la CI puede medirla.
- 🎒 **[Sistemas de gameplay](labs/gameplay-systems/README.md)** — los sistemas de la Parte 18: inventario, equipo, stats con modificadores, habilidades, efectos, loot, quests, progresión y economía. **122 comprobaciones**, incluidas transacciones atómicas con rollback y migraciones de guardado encadenadas.
- ☁️ **[Runtime de producción](labs/production-runtime/README.md)** — el cliente de la Parte 19 frente a un servidor deliberadamente hostil (lento, 5xx, caído, corrupto, intermitente): reintentos con jitter, circuit breaker, idempotencia, feature flags y saves atómicos con checksum. **91 comprobaciones**.
- 🤖 **[Sistema de IA en el juego](labs/ai-game-system/README.md)** — el NPC de la Parte 20 con lore anclado y validación de salida. La CI lanza **siete ataques de prompt injection con un modelo que obedece por completo al atacante**, y ninguno altera el estado del juego. Sin red y **sin claves de API**.
- ⚙️ **[Ingeniería avanzada](labs/advanced-engineering/README.md)** — el banco de la Parte 21: SoA frente a AoS, pool frente a asignación, rejilla frente a fuerza bruta y paralelo frente a secuencial. Mide en tu máquina y **comprueba que cada versión rápida da el mismo resultado que la lenta**.

Los assets son **CC0 generados por código** ([`scripts/generar_assets.py`](scripts/generar_assets.py)) y cada push **verifica los proyectos con Godot headless** (importa, compila y arranca). **No hay un lab por clase, y es a propósito**: los tiene cada parte que termina en algo ejecutable. Las de arte, producción o carrera terminan en un entregable, no en un `.exe` — el porqué, en **[labs/](labs/README.md)**.

## 🧭 Portal: rutas, autoevaluación, progreso y buscador

- 🧭 **[Rutas guiadas por rol](rutas/README.md)** — **13 recorridos** ordenados: gameplay, gráficos, indie, móvil/web, multijugador, diseño de niveles y XR; y las seis rutas de especialización (sistemas de gameplay, backend/online, IA para juegos, motor/rendimiento, arquitecto técnico e indie avanzado).
- 📝 **[Autoevaluaciones](autoevaluaciones/README.md)** — 110 preguntas (una batería por parte) con explicación. Versión interactiva: [quiz](https://vladimiracunadev-create.github.io/modern-gamedev-program/autoevaluaciones/quiz.html).
- ✅ **[Seguimiento de progreso](https://vladimiracunadev-create.github.io/modern-gamedev-program/autoevaluaciones/progreso.html)** — marca las 352 clases (se guarda en tu navegador).
- 🔎 **[Buscador](https://vladimiracunadev-create.github.io/modern-gamedev-program/buscar.html)** — busca por título o tema entre las 352 clases.
- 📖 **[Glosario](glosario/README.md)** — ~2.800 términos enlazados a la clase donde se explican.

🌐 Todo navegable en el **[sitio del curso](https://vladimiracunadev-create.github.io/modern-gamedev-program/)**.

### 📕 Manual completo (todo el curso en un PDF)

¿Prefieres el curso entero en un solo documento, para leer de corrido o estudiar sin conexión? El **manual** consolida las **352 clases** en orden, con portada e índice enlazado.

- 📥 **[Descargar el manual en PDF](manual/MANUAL.pdf)** — listo para imprimir o leer offline.

> Se genera con `python scripts/generar_manual.py` a partir de las clases, así que refleja el contenido del repositorio.

## 📱 Apps para leer sin conexión (Windows y Android)

¿Prefieres estudiar sin navegador y sin internet? Las apps **Videojuegos Moderno** ([`app/`](app/README.md)) empaquetan **el mismo HTML** que se publica en GitHub Pages: las 352 clases, el buscador, el glosario, las autoevaluaciones y el seguimiento de progreso, todo dentro del ejecutable.

- 📥 **[Descargar desde la última release](https://github.com/vladimiracunadev-create/modern-gamedev-program/releases/latest)** — APK de Android y ZIP portable de Windows x64 · verifica la integridad con `SHA256SUMS.txt`.
- 🔌 **Offline de verdad:** el curso viaja dentro. El APK **no declara ni el permiso de INTERNET**, y el progreso se guarda **solo en tu dispositivo**.
- 🔎 **Funciona todo:** buscador, quiz y progreso incluidos, porque el contenido se sirve desde un origen propio y no con `file://` — el detalle técnico está en [`app/README.md`](app/README.md).
- 📕 El manual en PDF **no va dentro** (pesa más que la app entera y ninguna de las dos lo mostraría bien): se descarga aparte, en la misma release.

> APK de **sideload**, fuera de Play Store, firmado en el proceso de release. En Android hay que permitir la instalación desde orígenes desconocidos para el instalador que uses. La app de Windows es un ZIP portable: se descomprime y se ejecuta, sin instalador.

### 🖨️ ¿O solo una parte?

También puedes generar guías **PDF por clase** (mismo estilo imprimible):

```bash
python scripts/generar_material.py --parte 1   # una parte
python scripts/generar_material.py --all       # las 352 clases (~12 min)
```

Estas guías por clase **no se versionan** (sumarían ~200 MB): se generan bajo demanda en `material/`. Salen optimizadas para imprimir: sin color, densas y **sin partir los bloques de código** entre páginas.

## 🛠️ Todas las tecnologías, no una sola

El programa es **agnóstico de motor por diseño**: primero enseña los conceptos (game loop, vectores, colisiones, ECS) y luego los aterriza en las herramientas líderes de la industria. A lo largo del programa se usan:

| Categoría | Tecnologías cubiertas |
|---|---|
| **Motores** | Godot 4 (principal, gratis y open source), Unity (C#), Unreal Engine 5 (C++/Blueprints) |
| **Lenguajes** | C#, C++, GDScript, Python, JavaScript/TypeScript, HLSL/GLSL (shaders), Rust (Bevy) |
| **Web / HTML5** | Canvas, WebGL, Phaser, PixiJS, Three.js, WebAssembly |
| **Gráficos** | Pipeline de render, shaders, PBR, iluminación, post-procesado |
| **Física** | Godot Physics, Box2D, PhysX, integración numérica |
| **Networking** | ENet, netcode determinista, cliente-servidor, rollback |
| **Herramientas** | Git + LFS, Blender, Aseprite, Tiled, FMOD/Wwise, profilers |
| **Plataformas** | Windows, Linux, macOS, Android/iOS, web, consolas, VR/AR |
| **Backend y confiabilidad** | HTTP/REST, autenticación y entitlements, feature flags, telemetría, circuit breakers, release engineering |
| **IA generativa** | Abstracción de proveedor, modelos locales y remotos, RAG, evaluación, seguridad frente a prompt injection |
| **Ingeniería de motor** | Data-oriented design, allocators, job systems, particionamiento espacial, Vulkan/DX12/Metal, GPU-driven rendering |

> Godot 4 es el motor **principal** para la práctica temprana (gratis, ligero, moderno, exporta a todo), pero los conceptos se contrastan con Unity y Unreal para que puedas trabajar en cualquier estudio.
>
> 🔖 **Versión de referencia: Godot 4.3.** Todo el código de las clases usa la API de Godot 4 y los laboratorios se verifican en CI contra **Godot 4.3** en cada push. Con versiones 4.x posteriores debería funcionar igual; si algo cambia, [abre un issue](https://github.com/vladimiracunadev-create/modern-gamedev-program/issues).

## 🗂️ Las 22 partes

Cada parte tiene su **propio README** con narrativa completa: de qué trata, resultados de aprendizaje, temario y enlaces a sus clases. Las cinco etapas se presentan aquí con el mismo detalle porque las cinco están completas.

### 🟢 Etapa 1 — Primeros juegos

Para quien empieza sin base. Al terminarla tienes un plataformas 2D con buen game feel y un nivel 3D explorable, ambos exportados y jugables por otra persona.

| # | Parte | Clases | Contenido central | README |
|---:|---|---:|---|---|
| 0 | Fundamentos y prerrequisitos | 25 (001–025) | Vectores, game loop, POO, patrones, Git+LFS y montaje del entorno | [📘 leer](classes/parte-0-fundamentos-y-prerrequisitos/README.md) |
| 1 | Motores 2D y tu primer juego jugable | 20 (026–045) | Escenas, tilemaps, controlador, game feel, HUD, audio y guardado | [📘 leer](classes/parte-1-motores-2d-y-tu-primer-juego-jugable/README.md) |
| 2 | Desarrollo 3D: motores, escenas y transformaciones | 22 (046–067) | Transformaciones, cámaras, materiales, luces, navegación y blockout | [📘 leer](classes/parte-2-desarrollo-3d-motores-escenas-y-transformaciones/README.md) |

### 🔵 Etapa 2 — Los sistemas del juego

Las disciplinas técnicas que hacen que un juego se sienta, se vea, reaccione, suene y se juegue con otros. Al terminarla sabes escribir shaders, un enemigo que decide y una partida en red autoritativa.

| # | Parte | Clases | Contenido central | README |
|---:|---|---:|---|---|
| 3 | Física y matemáticas de juegos aplicadas | 18 (068–085) | Integradores, colisiones, steering, easing y determinismo | [📘 leer](classes/parte-3-fisica-y-matematicas-de-juegos-aplicadas/README.md) |
| 4 | Gráficos, shaders y rendering moderno | 22 (086–107) | Pipeline, GLSL, PBR, iluminación, post-procesado y optimización visual | [📘 leer](classes/parte-4-graficos-shaders-y-rendering-moderno/README.md) |
| 5 | Inteligencia artificial para juegos | 18 (108–125) | FSM, behavior trees, pathfinding A\*, percepción, memoria y squads | [📘 leer](classes/parte-5-inteligencia-artificial-para-juegos/README.md) |
| 6 | Audio y música interactiva | 12 (126–137) | Buses, mezcla, audio espacial, música adaptativa y ducking | [📘 leer](classes/parte-6-audio-y-musica-interactiva/README.md) |
| 7 | Multijugador y networking | 18 (138–155) | RPCs, servidor autoritativo, predicción, reconciliación y rollback | [📘 leer](classes/parte-7-multijugador-y-networking/README.md) |

### 🟣 Etapa 3 — Diseño, arte y experiencia

Lo que convierte un prototipo técnico en un juego que alguien quiere jugar. Al terminarla tienes un nivel diseñado con intención, un set de assets coherente y una UI que se entiende y se navega.

| # | Parte | Clases | Contenido central | README |
|---:|---|---:|---|---|
| 8 | Game design y diseño de niveles | 16 (156–171) | Mecánicas, economía, curvas de dificultad, balance, narrativa y niveles | [📘 leer](classes/parte-8-game-design-y-diseno-de-niveles/README.md) |
| 9 | Arte, animación y pipeline de assets | 16 (172–187) | Pixel art, 3D, rigging, animación, LODs y nomenclatura de assets | [📘 leer](classes/parte-9-arte-animacion-y-pipeline-de-assets/README.md) |
| 10 | UI/UX, accesibilidad y localización | 12 (188–199) | Layouts, foco, navegación por teclado, i18n y texto al 200 % | [📘 leer](classes/parte-10-ui-ux-accesibilidad-y-localizacion/README.md) |

### 🟠 Etapa 4 — Plataformas, rendimiento y publicación

Sacar el juego de tu máquina y ponerlo en manos de la gente. Al terminarla has exportado a móvil y web, has optimizado con el profiler y tienes un plan de lanzamiento y un portfolio.

| # | Parte | Clases | Contenido central | README |
|---:|---|---:|---|---|
| 11 | Móvil, consolas y plataformas | 14 (200–213) | Export, táctil, batería, tiendas y requisitos de plataforma | [📘 leer](classes/parte-11-movil-consolas-y-plataformas/README.md) |
| 12 | Juegos web y HTML5 | 14 (214–227) | Canvas, WebGL, WebAssembly, Phaser, Three.js y PWA | [📘 leer](classes/parte-12-juegos-web-y-html5/README.md) |
| 13 | VR, AR y experiencias inmersivas | 12 (228–239) | Visores, tracking, interacción, confort y rendimiento en XR | [📘 leer](classes/parte-13-vr-ar-y-experiencias-inmersivas/README.md) |
| 14 | Optimización, profiling y rendimiento | 15 (240–254) | Profiler, presupuesto de fotograma, CPU, GPU, memoria y carga | [📘 leer](classes/parte-14-optimizacion-profiling-y-rendimiento/README.md) |
| 15 | Herramientas, editores y automatización | 12 (255–266) | Plugins de editor, datos, testing automatizado y CI de proyecto | [📘 leer](classes/parte-15-herramientas-editores-y-automatizacion/README.md) |
| 16 | Producción, publicación, monetización y LiveOps | 14 (267–280) | Alcance, hitos, presupuesto, tiendas, analítica y post-lanzamiento | [📘 leer](classes/parte-16-produccion-publicacion-monetizacion-y-liveops/README.md) |
| 17 | Capstones y preparación profesional / portfolio | 12 (281–292) | Vertical slice, portfolio, entrevistas y publicación del juego | [📘 leer](classes/parte-17-capstones-y-preparacion-profesional-portfolio/README.md) |

### 🔴 Etapa 5 — Especialización en ingeniería

**La diferencia entre saber hacer un juego y saber sostener uno.** Llega después del capstone porque cada parte responde a un problema que solo se reconoce cuando ya lo tienes delante. Sus cuatro laboratorios funcionan **sin claves de API, sin servicios de pago y sin red**: la CI los ejecuta completamente offline con mocks deterministas.

| # | Parte | Clases | El problema que resuelve | README |
|---:|---|---:|---|---|
| 18 | Arquitectura de gameplay y sistemas sistémicos | 18 (293–310) | Tu inventario, tus stats y tus quests funcionan por separado y se rompen al combinarse | [📘 leer](classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/README.md) |
| 19 | Ingeniería de producción, backend y confiabilidad | 14 (311–324) | Funciona en tu máquina; en producción hay red que falla y saves que se corrompen | [📘 leer](classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md) |
| 20 | IA generativa y desarrollo asistido por IA | 14 (325–338) | Dónde aporta un modelo de lenguaje, y cómo impedir que regale una espada legendaria | [📘 leer](classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/README.md) |
| 21 | Arquitectura avanzada de motores y rendering | 14 (339–352) | El profiler dice 40 ms y no sabes por qué: datos, memoria, paralelismo y rendering | [📘 leer](classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/README.md) |

> ⚠️ La Parte 20 **no sustituye a la Parte 5**: la complementa. Los behavior trees y el pathfinding siguen siendo la base del comportamiento de un NPC, y la [ruta de IA para juegos](rutas/ia-juegos.md) hace la Parte 5 primero.

➡️ **[Ver el índice plano de las 352 clases](classes/README.md)**

> 📈 **¿Ya estabas siguiendo el curso?** Las clases **001–292 no cambiaron de número ni de URL**, y no se eliminó ni se reemplazó ninguna. Sigues exactamente donde estabas. El detalle de qué se añadió y qué se respetó, en **[docs/EVOLUTION-292-TO-352.md](docs/EVOLUTION-292-TO-352.md)**.

## 📚 Pauta derivada de los mejores libros de la industria

Cada parte sigue explícitamente la secuencia y los énfasis de la literatura de referencia del sector:

| Área | Libros de referencia |
|---|---|
| **Arquitectura de motores** | Gregory — *Game Engine Architecture* · Nystrom — *Game Programming Patterns* |
| **Matemáticas y física** | Lengyel — *Mathematics for 3D Game Programming* · Millington — *Game Physics Engine Development* |
| **Gráficos / shaders** | Akenine-Möller et al. — *Real-Time Rendering* · *The Book of Shaders* (Gonzalez Vivo) |
| **IA de juegos** | Millington & Funge — *Artificial Intelligence for Games* · *Game AI Pro* (Rabin) |
| **Game design** | Schell — *The Art of Game Design* · Fullerton — *Game Design Workshop* |
| **Multijugador** | Glazer & Madhav — *Multiplayer Game Programming* · Valve/GDC netcode talks |
| **Producción** | Keith — *Agile Game Development* · Chandler — *The Game Production Handbook* |
| **Sistemas y datos** | Nystrom — *Game Programming Patterns* · Fabian — *Data-Oriented Design* |
| **Confiabilidad** | Beyer et al. — *Site Reliability Engineering* · Kleppmann — *Designing Data-Intensive Applications* |
| **Rendering avanzado** | *GPU Gems* / *GPU Zen* · Pharr, Jakob & Humphreys — *Physically Based Rendering* |

> Las referencias apuntan a las obras; **no se reproduce su contenido**. El material del curso es original en su redacción.

## 🚀 Cómo usar el programa

1. **Sigue el orden.** La numeración es secuencial por diseño: cada clase asume lo anterior. Si ya dominas un bloque, sáltalo, pero no empieces por la Parte 4 (shaders) sin la 0.
2. **Monta el entorno primero.** La [Clase 016](classes/parte-0-fundamentos-y-prerrequisitos/016-montaje-del-entorno-godot-unity-unreal-y-herramientas/README.md) te deja Godot, Unity y las herramientas listas para trabajar.
3. **Haz los retos.** Leer no basta: cada clase termina en un reto con criterio de aceptación. Escribe el código, ejecútalo, rómpelo y arréglalo — y en las clases sin código, entrega la pieza que pidan.
4. **Construye tu portfolio.** Cada capstone es una pieza publicable. Al final tendrás juegos jugables que enseñar.

## 🧭 Rutas sugeridas por rol

Cada rol tiene una **guía de carrera completa** (qué es, día a día, qué necesitas saber, tu ruta en el curso, qué te contrata, salario orientativo, mitos y siguientes pasos). Haz clic en el nombre:

**Rutas de base** (Partes 0–17), que se pueden empezar desde cero:

- **[Programador de gameplay](rutas/gameplay.md)** → Partes 0, 1, 2, 3, 5, 8, 14, 17 · el rol más demandado: haces que el juego *se sienta* bien.
- **[Programador gráfico / técnico](rutas/grafico.md)** → Partes 0, 1, 2, 4, 3, 14, 9 · shaders, iluminación y el *look* del juego.
- **[Desarrollador indie (solo dev)](rutas/indie.md)** → Partes 0, 1, 8, 9, 6, 10, 15, 16 · lo haces todo tú; lo difícil es **terminar**.
- **[Desarrollador móvil / web](rutas/movil-web.md)** → Partes 0, 1, 10, 11, 12, 14, 16 · alcance masivo con restricciones duras.
- **[Programador de multijugador](rutas/multijugador.md)** → Partes 0, 1, 2, 3, 7, 14, 15 · de los roles más difíciles y mejor pagados.
- **[Diseñador de niveles / técnico](rutas/diseno-niveles.md)** → Partes 0, 1, 8, 2, 15, 10 · diseñas la experiencia **y** las herramientas.
- **[Desarrollador XR (VR/AR)](rutas/xr.md)** → Partes 0, 1, 2, 3, 14, 13, 6 · nicho exigente donde los fps no se negocian.

**Rutas de especialización** (Partes 18–21), que **empiezan donde terminan las anteriores**:

- **[Programador de sistemas de gameplay](rutas/sistemas-gameplay.md)** → Parte 18, tras la ruta de gameplay · inventario, stats, quests y economía que no se rompen al combinarse.
- **[Ingeniero de backend y online](rutas/backend-online.md)** → Partes 15 y 19, tras la de multijugador · la ruta **más transferible fuera de los videojuegos**.
- **[Desarrollador de IA para juegos](rutas/ia-juegos.md)** → Parte 5 **primero**, luego 18 y 20 · las dos IA, en el orden correcto.
- **[Programador de motor / rendimiento](rutas/motor-rendimiento.md)** → Partes 14 y 21 · el techo salarial técnico del sector.
- **[Arquitecto técnico de juegos](rutas/arquitecto-tecnico.md)** → Partes 18, 19, 21 y 16, tras dos especializaciones · decidir qué **no** se construye.
- **[Indie avanzado](rutas/indie-avanzado.md)** → Partes 18, 19 y 21, con un juego ya publicado · que lo terminado aguante.

➡️ El índice con las trece rutas y cómo se encadenan, en **[rutas/](rutas/README.md)**.

## ✅ Calidad y CI

El repositorio no se publica a ciegas: cada `push` y cada PR pasan por integración continua que valida estructura, enlaces, codificación, estilo, build del sitio **y los diez laboratorios con Godot headless**. Nada llega a `main` en rojo.

| ⚙️ Workflow | Qué cubre |
|---|---|
| 🧪 [ci.yml](.github/workflows/ci.yml) | estructura y secciones obligatorias de las 352 clases, enlaces internos, navegación anterior/siguiente, índice/manifest/glosario sincronizados, codificación UTF-8 sin mojibake, `markdownlint` y build del sitio |
| 🎮 [labs.yml](.github/workflows/labs.yml) | los 10 laboratorios × `inicio`/`solucion` con **Godot 4.3 headless**: importan limpio, arrancan y publican su marcador. Más las pruebas dedicadas de red, IA y UI, las **cuatro suites** de las Partes 18–21 (301 comprobaciones) y el contrato offline (sin red, sin URLs externas, sin credenciales) |
| 🔒 [security.yml](.github/workflows/security.yml) | escaneo de secretos (`gitleaks`) y análisis estático (`bandit`) de los scripts |
| 🚀 [deploy-pages.yml](.github/workflows/deploy-pages.yml) | genera y despliega el sitio del curso a GitHub Pages |

Los mismos validadores corren en local antes de subir:

```bash
python scripts/verificar_todo.py --godot /ruta/a/godot
```

O uno a uno, si prefieres ir por partes:

```bash
python scripts/validar_estructura.py    # 352 clases + enlaces .md sin rotos
python scripts/validar_encoding.py      # todo UTF-8, sin mojibake
python scripts/generar_navegacion.py --check
npx markdownlint-cli2 "**/*.md"
```

## 🎯 Qué es y qué no es este programa

<table>
<tr>
<td valign="top" width="50%">

### ✅ Lo que sí es

- 📚 un currículo **secuencial y completo** de 352 clases, de fundamentos a especialización en ingeniería;
- 🧪 un curso con **práctica real**: 10 laboratorios Godot ejecutables y verificados en CI, cuatro de ellos con suites de pruebas;
- 🧭 una guía de **carrera por rol** con día a día, habilidades, portfolio y salario orientativo;
- 🔍 material **honesto sobre sus límites**: dice explícitamente qué verifica una máquina y qué no;
- 📖 material **abierto y offline-friendly** (manual PDF, sitio en Pages y apps de escritorio y Android), en español.

</td>
<td valign="top" width="50%">

### ❌ Lo que no es

- 🚫 un atajo para "hacer un juego en un fin de semana": la numeración es secuencial por diseño;
- 🚫 un curso de un solo motor: Godot es el principal, pero los conceptos se contrastan con Unity y Unreal;
- 🚫 una promesa de empleo: las guías de rol marcan los salarios como **orientativos**, y el sector paga por debajo del software empresarial equivalente;
- 🚫 un sustituto de publicar: lo que te contrata es un juego terminado, no haber leído 352 clases;
- 🚫 contenido copiado de los libros de referencia: la redacción es **original**.

</td>
</tr>
</table>

## 💡 Idea fuerza

> El valor de este programa no está en acumular tecnologías, sino en **traducirlas en juegos que existen**: una secuencia pedagógica que no se salta pasos, laboratorios que se abren y se ejecutan, honestidad sobre lo que cada rol implica de verdad, y un recorrido que puedes hacer de principio a fin sin quedarte a medias.

## 📄 Licencia

[MIT](LICENSE) — úsalo, modifícalo y compártelo. El conocimiento debe ser accesible.

---

<div align="center">

**Hecho para quien quiere aprender a hacer videojuegos en serio, de principio a fin.**

[⬆️ Empezar por el índice de clases](classes/README.md)

<br>

**¿Te resulta útil? ⭐ Dale una estrella al repo.**

[![GitHub stars](https://img.shields.io/github/stars/vladimiracunadev-create/modern-gamedev-program?style=social)](https://github.com/vladimiracunadev-create/modern-gamedev-program/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/vladimiracunadev-create/modern-gamedev-program?style=social)](https://github.com/vladimiracunadev-create/modern-gamedev-program/network/members)
[![Follow](https://img.shields.io/github/followers/vladimiracunadev-create?style=social&label=Follow)](https://github.com/vladimiracunadev-create)

Hecho con 🎮 y ☕ por [Vladimir Acuña](https://github.com/vladimiracunadev-create)

</div>
