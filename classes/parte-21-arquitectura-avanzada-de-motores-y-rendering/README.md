# Parte 21 — Arquitectura avanzada de motores y rendering

> [⬅️ Volver al programa](../../README.md) · [📚 Índice completo](../README.md) · [⏮️ Parte anterior](../parte-20-ia-generativa-y-desarrollo-asistido-por-ia/README.md)

**14 clases** · rango 339–352 · El nivel más profundo del programa: cómo están hechos por dentro los motores que has estado usando. Data-oriented design, allocators, job systems, particionamiento espacial, streaming, mundos grandes, rendering temporal, upscaling, HDR, iluminación global, GPU-driven rendering, compilación de shaders y las APIs gráficas modernas

**Fuentes de referencia de esta parte:**

- Jason Gregory — *Game Engine Architecture* (3.ª ed.): <https://www.gameenginebook.com/>
- Akenine-Möller, Haines & Hoffman — *Real-Time Rendering* (4.ª ed.): <https://www.realtimerendering.com/>
- Documentación de [Vulkan](https://docs.vulkan.org/), [DirectX 12](https://learn.microsoft.com/windows/win32/direct3d12/), [Metal](https://developer.apple.com/metal/) y [WebGPU](https://www.w3.org/TR/webgpu/).
- [Khronos Group](https://www.khronos.org/) — estándares abiertos de gráficos y cómputo.
- Documentación del [rendering de Godot 4](https://docs.godotengine.org/en/stable/tutorials/rendering/index.html) y de sus servidores.
- Charlas técnicas de GDC y SIGGRAPH sobre arquitectura de motores y rendering: <https://www.gdcvault.com/>

---

## 🎯 ¿De qué trata esta parte?

Hasta aquí has **usado** un motor: nodos, escenas, materiales, luces. Esta parte explica **cómo está hecho por dentro** y por qué las decisiones que toma afectan a lo que puedes hacer con él.

No es una parte de trivia técnica. Es la que te permite responder a preguntas que aparecen en todo proyecto serio: por qué 10.000 entidades con `_process` van mal y con otra disposición de datos van bien; por qué el juego se congela un cuarto de segundo la primera vez que aparece un efecto; por qué un mundo abierto necesita una arquitectura distinta a la de un nivel; por qué el mismo juego se ve distinto en un monitor HDR; y qué significa realmente que una técnica sea "cara en GPU".

La Parte 14 enseñó a **optimizar** midiendo. Esta explica **por qué** las cosas cuestan lo que cuestan, que es lo que te permite diseñar para que no lleguen a costar. Y la Parte 4 enseñó shaders y rendering desde el uso; aquí se ve el pipeline desde dentro.

El laboratorio de la parte se apoya en **alternativas abiertas y ejecutables**: estructuras de datos, medición y compute shaders en Godot, verificables en CI sin GPU cuando es posible y con comprobación visual documentada cuando no.

## 🧩 Problemas que resuelve

- Miles de entidades que van lentas aunque cada una haga muy poco.
- Tirones periódicos por reservas de memoria y recolección de basura.
- Un solo núcleo al 100 % y siete parados.
- Consultas espaciales (¿quién está cerca?) que escalan cuadráticamente.
- Cargas que congelan el juego y mundos que no caben en memoria.
- Fantasmas y parpadeos al mover la cámara con antialiasing temporal.
- Juegos que no llegan a 60 fps y no saben si escalar resolución o calidad.
- Colores que se ven mal en pantallas modernas.
- Tirones la primera vez que se ve un efecto (compilación de shaders).
- No entender qué hace el motor cuando pides "dibuja esto".

## 🎓 Resultados de aprendizaje

Al terminar la parte, el alumno podrá:

- Diseñar estructuras de datos orientadas a caché y medir la diferencia real.
- Elegir y aplicar estrategias de asignación de memoria según el tiempo de vida.
- Descomponer trabajo en jobs con dependencias, y razonar sobre carreras de datos.
- Implementar y comparar rejillas, hashing espacial, quadtrees, octrees y BVH.
- Diseñar carga asíncrona, streaming y gestión de referencias de recursos.
- Diseñar mundos grandes con particionado, rebase de origen y persistencia por región.
- Explicar el rendering temporal, sus artefactos y sus mitigaciones.
- Comparar upscaling espacial, temporal y resolución dinámica.
- Aplicar un flujo de color lineal correcto y entender HDR y tone mapping.
- Comparar técnicas de iluminación global y su coste.
- Explicar el rendering dirigido por GPU y sus requisitos.
- Diagnosticar y prevenir el stutter por compilación de shaders.
- Comparar Vulkan, DirectX 12, Metal y WebGPU en sus conceptos comunes.

## 🧱 Prerrequisitos

- Parte 3 (matemáticas y física) y Parte 4 (gráficos y shaders): son la base directa.
- Parte 14 (optimización y profiling): aquí se explica el porqué de lo que allí se medía.
- Parte 18: la arquitectura de sistemas de la clase 293 es el contrapunto de la 339.
- Godot 4.x. Algunas clases usan compute shaders; los laboratorios indican qué necesita GPU y qué no.
- Conocer C++ ayuda a leer los ejemplos comparativos, pero no es imprescindible: los conceptos se explican y se implementan también en GDScript.

## 📚 Las 14 clases

| # | Clase |
|---|---|
| 339 | [Data-Oriented Design](339-data-oriented-design/README.md) |
| 340 | [Allocators y gestión avanzada de memoria](340-allocators-y-gestion-avanzada-de-memoria/README.md) |
| 341 | [Job Systems y Task Graphs](341-job-systems-y-task-graphs/README.md) |
| 342 | [Particionamiento espacial](342-particionamiento-espacial/README.md) |
| 343 | [Resource Management y streaming asíncrono](343-resource-management-y-streaming-asincrono/README.md) |
| 344 | [Grandes mundos y world partition](344-grandes-mundos-y-world-partition/README.md) |
| 345 | [Rendering temporal](345-rendering-temporal/README.md) |
| 346 | [Upscaling y resolución dinámica](346-upscaling-y-resolucion-dinamica/README.md) |
| 347 | [HDR y gestión moderna de color](347-hdr-y-gestion-moderna-de-color/README.md) |
| 348 | [Global illumination y ray tracing moderno](348-global-illumination-y-ray-tracing-moderno/README.md) |
| 349 | [GPU-driven rendering](349-gpu-driven-rendering/README.md) |
| 350 | [Shader compilation y stutter](350-shader-compilation-y-stutter/README.md) |
| 351 | [APIs gráficas modernas](351-apis-graficas-modernas/README.md) |
| 352 | [Capstone Parte 21: ingeniería avanzada verificable](352-capstone-parte-21-ingenieria-avanzada-verificable/README.md) |

---

> **Fin del programa.** Has recorrido de los fundamentos a la arquitectura interna de un motor, pasando por el diseño, la producción, los sistemas de juego, la operación y la IA. Ahora la parte más importante: **construir, terminar y publicar**. Vuelve al [índice](../README.md) y elige tu próximo capstone. 🎮
