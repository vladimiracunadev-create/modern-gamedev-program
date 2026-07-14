# Parte 0 — Fundamentos y prerrequisitos

> [⬅️ Volver al programa](../../README.md) · [📚 Índice completo](../README.md) · [⏭️ Parte siguiente](../parte-1-motores-2d-y-tu-primer-juego-jugable/README.md)

**25 clases** · rango 001–025 · Matemáticas, programación (C#, C++, GDScript), game loop, patrones, ECS, gráficos base, audio y entorno de trabajo

**Fuentes de referencia de esta parte:**

- Jason Gregory, *Game Engine Architecture* (3ª ed., CRC Press).
- Robert Nystrom, *Game Programming Patterns* (Genever Benning) — [gratis online](https://gameprogrammingpatterns.com/).
- Eric Lengyel, *Mathematics for 3D Game Programming and Computer Graphics* (3ª ed., Cengage).
- Ian Millington, *Game Physics Engine Development* (2ª ed., CRC Press).
- Documentación oficial de [Godot 4](https://docs.godotengine.org/), [Unity](https://docs.unity3d.com/) y [Microsoft C#](https://learn.microsoft.com/dotnet/csharp/).

---

## 🎯 ¿De qué trata esta parte?

La Parte 0 es la base sobre la que se construye todo el programa. Antes de encender un motor y arrastrar un sprite, hay que **entender qué hay debajo**: cómo un juego actualiza y dibuja el mundo 60 veces por segundo, cómo las matemáticas de vectores y matrices mueven y rotan todo lo que ves, cómo el código se organiza para no volverse un caos, y cómo las imágenes y el sonido llegan a la pantalla y los altavoces. Sin estos fundamentos, usar Unity o Godot se vuelve copiar tutoriales sin criterio: funciona hasta que algo se rompe y no sabes por qué.

Cubrimos cinco pilares: **matemáticas y física** (vectores, matrices, trigonometría, cinemática e integración), **programación** (C# a fondo, POO, estructuras de datos, C++ y su gestión de memoria, GDScript y Python), **arquitectura de software de juegos** (game loop, patrones de diseño, ECS), **fundamentos técnicos** (cómo se dibuja un frame, espacios de coordenadas, color, texturas, audio digital, pipeline de assets, delta time y determinismo) y el **entorno profesional** (Git con LFS, montaje de Godot/Unity/Unreal, debugging, profiling, prototipado y metodología).

Esta parte sirve a quien llega desde otra rama de la programación, desde el diseño, o desde cero con vocación. Al terminarla tendrás las herramientas instaladas, sabrás leer y escribir el código que mueve un juego, y entenderás **por qué** funciona lo que en las partes siguientes solo tendrás que aplicar.

## 🧩 Problemas que resuelve

- No entender qué hace un motor por debajo y quedar atrapado copiando tutoriales sin poder adaptarlos.
- Confundir conceptos básicos (posición vs. velocidad, transform local vs. global, fotograma vs. física fija).
- No dominar las matemáticas mínimas (vectores, ángulos) que aparecen en **cada** juego.
- Escribir código de gameplay que se vuelve inmantenible al tercer sistema (sin patrones ni arquitectura).
- No saber por qué el juego "corre distinto" en otro PC (delta time y timestep mal entendidos).
- Perder trabajo por no versionar, o romper un proyecto por meter binarios enormes en Git sin LFS.
- No tener criterio para elegir motor, lenguaje o formato de asset según el proyecto.

## 🎓 Resultados de aprendizaje

Al terminar la parte, el alumno podrá:

- Explicar el game loop, el estado del juego y la diferencia entre frame de render y paso de física.
- Operar con vectores, matrices, trigonometría y las transformaciones que mueven objetos en 2D y 3D.
- Modelar movimiento con cinemática e integración numérica estable.
- Programar con soltura en C# (y leer C++ y GDScript), aplicando POO, composición y estructuras de datos adecuadas.
- Aplicar patrones de diseño de juegos y comprender la arquitectura ECS.
- Montar y aislar un entorno de desarrollo con Godot, Unity, Git + LFS y herramientas de arte/audio.
- Razonar sobre el pipeline gráfico, los espacios de coordenadas, el color, las texturas y el audio digital.
- Versionar, depurar, perfilar y prototipar un proyecto de juego con método profesional.

## 🧱 Prerrequisitos

- Un ordenador con Windows, macOS o Linux capaz de correr un motor moderno (8 GB RAM recomendado, GPU con OpenGL 3.3 / Vulkan).
- Conocimientos básicos de informática (instalar programas, usar el explorador de archivos, la terminal a nivel básico).
- No se requiere experiencia previa en programación ni en juegos: la parte parte de cero, pero es intensa.

## 📚 Las 25 clases

| # | Clase |
|---|---|
| 001 | [Qué es el desarrollo de videojuegos moderno: motores, disciplinas y pipeline](001-que-es-el-desarrollo-de-videojuegos-moderno-motores-disciplinas-y-pipeline/README.md) |
| 002 | [Anatomía de un videojuego: game loop, estado, tiempo y frames](002-anatomia-de-un-videojuego-game-loop-estado-tiempo-y-frames/README.md) |
| 003 | [Historia y géneros: qué define la jugabilidad](003-historia-y-generos-que-define-la-jugabilidad/README.md) |
| 004 | [Matemáticas para juegos I: vectores y álgebra lineal](004-matematicas-para-juegos-i-vectores-y-algebra-lineal/README.md) |
| 005 | [Matemáticas para juegos II: matrices y transformaciones](005-matematicas-para-juegos-ii-matrices-y-transformaciones/README.md) |
| 006 | [Matemáticas para juegos III: trigonometría, ángulos y rotaciones](006-matematicas-para-juegos-iii-trigonometria-angulos-y-rotaciones/README.md) |
| 007 | [Física básica para juegos: cinemática, fuerzas e integración](007-fisica-basica-para-juegos-cinematica-fuerzas-e-integracion/README.md) |
| 008 | [Programación fundamentos con C#: tipos, control de flujo y funciones](008-programacion-fundamentos-con-c-sharp-tipos-control-de-flujo-y-funciones/README.md) |
| 009 | [POO para juegos: clases, herencia y composición](009-programacion-orientada-a-objetos-para-juegos-clases-herencia-y-composicion/README.md) |
| 010 | [Estructuras de datos para juegos: arrays, listas, diccionarios y colas](010-estructuras-de-datos-para-juegos-arrays-listas-diccionarios-y-colas/README.md) |
| 011 | [C++ para juegos: fundamentos, punteros y memoria](011-c-plus-plus-para-juegos-fundamentos-punteros-y-memoria/README.md) |
| 012 | [GDScript y Python en juegos: scripting rápido](012-gdscript-y-python-en-juegos-scripting-rapido/README.md) |
| 013 | [Patrones de diseño en juegos: State, Observer, Component y más](013-patrones-de-diseno-en-juegos-state-observer-component-y-mas/README.md) |
| 014 | [Arquitectura ECS (Entity-Component-System)](014-arquitectura-ecs-entity-component-system/README.md) |
| 015 | [Git y control de versiones para proyectos de juegos (con LFS)](015-git-y-control-de-versiones-para-proyectos-de-juegos-con-lfs/README.md) |
| 016 | [Montaje del entorno: Godot, Unity, Unreal y herramientas](016-montaje-del-entorno-godot-unity-unreal-y-herramientas/README.md) |
| 017 | [Gráficos por computadora: cómo se dibuja un frame](017-graficos-por-computadora-como-se-dibuja-un-frame/README.md) |
| 018 | [Sistemas de coordenadas y espacios: local, mundo, cámara, pantalla](018-sistemas-de-coordenadas-y-espacios-local-mundo-camara-pantalla/README.md) |
| 019 | [Color, sprites, texturas y formatos de imagen](019-color-sprites-texturas-y-formatos-de-imagen/README.md) |
| 020 | [Audio digital: muestreo, formatos y mezcla](020-audio-digital-muestreo-formatos-y-mezcla/README.md) |
| 021 | [Assets y pipeline de contenido: import, compresión y presupuestos](021-assets-y-pipeline-de-contenido-import-compresion-y-presupuestos/README.md) |
| 022 | [Delta time, fixed timestep y determinismo](022-delta-time-fixed-timestep-y-determinismo/README.md) |
| 023 | [Debugging y profiling: herramientas y mentalidad](023-debugging-y-profiling-herramientas-y-mentalidad/README.md) |
| 024 | [Prototipado rápido y bucle de iteración de diseño](024-prototipado-rapido-y-bucle-de-iteracion-de-diseno/README.md) |
| 025 | [Metodología, gestión de proyectos y portfolio del desarrollador](025-metodologia-gestion-de-proyectos-y-portfolio-del-desarrollador/README.md) |

---

> Cuando termines la Parte 0, tendrás la base para **construir juegos de verdad**. La [Parte 1](../parte-1-motores-2d-y-tu-primer-juego-jugable/README.md) te lleva de un sprite en pantalla a un plataformas 2D completo y jugable.
