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

| # | Parte | Clases | Estado |
|---|---|---:|:---:|
| 0 | Fundamentos y prerrequisitos | 25 | ✅ |
| 1 | Motores 2D y tu primer juego jugable | 20 | ✅ |
| 2 | Desarrollo 3D: motores, escenas y transformaciones | 22 | ✅ |
| 3 | Física y matemáticas de juegos aplicadas | 18 | ✅ |
| 4 | Gráficos, shaders y rendering moderno | 22 | ✅ |
| 5 | Inteligencia artificial para juegos | 18 | ✅ |
| 6 | Audio y música interactiva | 12 | ✅ |
| 7 | Multijugador y networking | 18 | ✅ |
| 8 | Game design y diseño de niveles | 16 | ✅ |
| 9 | Arte, animación y pipeline de assets | 16 | ✅ |
| 10 | UI/UX, accesibilidad y localización | 12 | ✅ |
| 11 | Móvil, consolas y plataformas | 14 | ✅ |
| 12 | Juegos web y HTML5 | 14 | ✅ |
| 13 | VR, AR y experiencias inmersivas | 12 | ✅ |
| 14 | Optimización, profiling y rendimiento | 15 | ✅ |
| 15 | Herramientas, editores y automatización (tooling) | 12 | ✅ |
| 16 | Producción, publicación, monetización y LiveOps | 14 | ✅ |
| 17 | Capstones y preparación profesional / portfolio | 12 | ✅ |
| 18 | Arquitectura de gameplay y sistemas sistémicos | 18 | ✅ |
| 19 | Ingeniería de producción, backend y confiabilidad | 14 | ✅ |
| 20 | IA generativa y desarrollo asistido por IA | 14 | ✅ |
| 21 | Arquitectura avanzada de motores y rendering | 14 | ✅ |

➡️ **[Ver el índice completo de clases](classes/README.md)**

### 🔧 Las cuatro partes de especialización (18–21)

Las Partes 0–17 te llevan de cero a un juego publicado. Las cuatro siguientes son otra cosa: **la diferencia entre saber hacer un juego y saber sostener uno**. Llegan después del capstone porque cada una responde a un problema que solo se reconoce cuando ya lo tienes delante.

| Parte | El problema que resuelve |
|---|---|
| **18 — Sistemas de gameplay** | Tu inventario, tus stats y tus quests funcionan por separado y se rompen al combinarse. Es lo que más cuesta reescribir a mitad de producción. |
| **19 — Producción y confiabilidad** | El juego funciona en tu máquina. En producción hay red que falla, saves que se corrompen a media escritura y parches que rompen partidas. |
| **20 — IA generativa** | Dónde aporta de verdad un modelo de lenguaje —en desarrollo y dentro del juego— y cómo impedir que un jugador le pida una espada legendaria y se la lleve. **No sustituye a la Parte 5**: la complementa. |
| **21 — Arquitectura avanzada** | El profiler dice que el bucle tarda 40 ms y no sabes por qué. Datos, memoria, paralelismo y rendering moderno, medidos en vez de supuestos. |

Los cuatro laboratorios correspondientes funcionan **sin claves de API, sin servicios de pago y sin red**: la CI los ejecuta completamente offline con mocks deterministas.

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

- **Programador de gameplay** → Partes 0, 1, 2, 3, 5, 8.
- **Programador gráfico / técnico** → Partes 0, 3, 4, 14.
- **Desarrollador indie (solo dev)** → Partes 0, 1, 6, 8, 9, 16.
- **Desarrollador móvil / web** → Partes 0, 1, 11, 12.
- **Programador de multijugador** → Partes 0, 2, 3, 7, 14.
- **Diseñador de niveles / técnico** → Partes 0, 1, 8, 15.

Y las especializaciones, que **empiezan donde terminan las anteriores**:

- **Programador de sistemas de gameplay** → Parte 18, tras la ruta de gameplay.
- **Ingeniero de backend / online** → Partes 15 y 19, tras la de multijugador.
- **Desarrollador de IA para juegos** → Parte 5 **primero**, luego 18 y 20.
- **Programador de motor / rendimiento** → Partes 14 y 21.
- **Arquitecto técnico** → Partes 18, 19, 21 y 16, tras dos especializaciones.
- **Indie avanzado** → Partes 18, 19 y 21, con un juego ya publicado.

➡️ El detalle de cada una, con orden e hitos, en **[rutas/](rutas/README.md)**.

## 📄 Licencia

[MIT](LICENSE) — úsalo, modifícalo y compártelo. El conocimiento debe ser accesible.

---

<div align="center">

**Hecho para quien quiere aprender a hacer videojuegos en serio, de principio a fin.**

[⬆️ Empezar por el índice de clases](classes/README.md)

</div>
