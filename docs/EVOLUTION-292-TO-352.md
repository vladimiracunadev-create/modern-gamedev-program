# 📈 Evolución del programa: de 292 a 352 clases

> [⬅️ Volver al programa](../README.md) · [📚 Índice completo](../classes/README.md) · [🗺️ Roadmap](../ROADMAP.md)

Este documento explica **qué se añadió, qué no se tocó y por qué**. Existe porque un currículo que crece sin dejar rastro de sus decisiones acaba siendo un montón de carpetas, y porque quien ya empezó el curso merece saber exactamente qué le cambia (respuesta corta: **nada de lo que ya tenía**).

## 🔒 La regla que gobernó toda la ampliación

**Nada de lo existente se rompe.** En concreto:

- Las clases **001–292 conservan su número, su carpeta y su URL**. No hubo renumeración.
- Ninguna clase se eliminó, se fusionó ni se reemplazó.
- Los seis laboratorios anteriores siguen intactos y siguen verificándose igual.
- Los enlaces publicados (README, GitHub Pages, PDFs compartidos) siguen funcionando.

Lo único que cambió en las clases existentes son **secciones añadidas al final**, antes de las referencias: punteros hacia el material nuevo cuando es relevante. Ninguna reescribe lo que decía, ninguna la contradice.

Si tenías el curso a medias: **sigue exactamente donde estabas**. Las Partes 18–21 empiezan después de la 17, y hasta ahí no hay nada que rehacer.

## 📊 Qué cambió en números

| | Antes | Después |
|---|---:|---:|
| Clases | 292 | **352** |
| Partes | 18 | **22** |
| Laboratorios ejecutables | 6 | **10** |
| Comprobaciones automáticas en los labs | arranque + marcador | **+301 comprobaciones** |
| Preguntas de autoevaluación | 90 | **110** |
| Rutas por rol | 7 | **13** |
| Términos del glosario | 1.994 | **2.832** |

## 🧩 Las cuatro partes nuevas

### Parte 18 — Arquitectura de gameplay y sistemas sistémicos (293–310)

**El problema:** tienes un juego que funciona y unos sistemas que no se llevan bien. El inventario no sabe del equipo, el equipo no sabe de los stats, las quests leen variables globales y cada nueva mecánica toca cinco archivos.

Diecisiete clases sobre sistemas data-driven que se combinan: base de datos de items, inventario con transacciones atómicas, equipo, stats con modificadores, habilidades, efectos de estado, pipeline de daño, tablas de loot, crafteo, progresión, economía, diálogo, quests, facciones, guardado de producción, comandos y replays, y modding. Cierra en un capstone verificable (310).

**Por qué aquí y no antes:** estos sistemas solo tienen sentido cuando ya sabes hacer un juego. Enseñar un sistema de inventario a alguien que aún no tiene qué recoger es enseñar burocracia.

### Parte 19 — Ingeniería de producción, backend y confiabilidad (311–324)

**El problema:** funciona en tu máquina. En producción hay red que falla a medias, saves que se corrompen durante un apagón, parches que rompen partidas de hace seis meses y jugadores que no son los de tu playtest.

Catorce clases sobre lo que sostiene un juego vivo: arquitectura de backend, identidad y entitlements, saves en la nube, economía autoritativa en servidor, remote config y feature flags, observabilidad, telemetría con privacidad y consentimiento, modelado de amenazas, anti-cheat, testing de producción, pruebas de regresión de rendimiento, release engineering, parches y recuperación.

**Sobre seguridad:** el enfoque es **defensivo**. Se enseña a modelar amenazas contra tu propio juego y a cerrarlas. No se desarrollan técnicas ofensivas contra juegos ajenos.

### Parte 20 — IA generativa y desarrollo asistido por IA (325–338)

**El problema:** hay una tecnología nueva, mucho ruido alrededor y poca claridad sobre dónde aporta de verdad.

Catorce clases divididas en dos mitades: **la IA como herramienta de desarrollo** (dónde acelera y dónde estorba) y **la IA dentro del juego** (NPC conversacionales, diálogo, contenido generativo), con las clases de coste, latencia, caché, evaluación y seguridad que hacen la diferencia entre una demo y algo publicable.

**Lo que esta parte NO es:** no sustituye a la [Parte 5](../classes/parte-5-inteligencia-artificial-para-juegos/README.md). Los behavior trees, las máquinas de estados y el pathfinding siguen siendo la base del comportamiento de un NPC, y lo seguirán siendo: un enemigo que te persigue necesita un A\* depurable a 60 fps, no un modelo de lenguaje. La ruta de IA para juegos hace **la Parte 5 primero, y no es negociable**.

**Sin claves, sin coste, sin red:** todo el material funciona con proveedores mock o locales. El laboratorio se ejecuta en CI **completamente offline y de forma determinista**. Un proveedor remoto es estrictamente opcional, y si el proyecto no arrancara sin él, estaría mal hecho.

### Parte 21 — Arquitectura avanzada de motores y rendering (339–352)

**El problema:** el profiler dice que el bucle tarda 40 ms y no sabes por qué. O sí lo sabes, pero cada intento de arreglarlo cambia el resultado.

Catorce clases sobre el coste real de las decisiones: data-oriented design, allocators, job systems y task graphs, particionamiento espacial, streaming de recursos, mundos grandes, rendering temporal, upscaling, HDR y color, iluminación global y ray tracing, GPU-driven rendering, stutter de compilación de shaders y APIs gráficas modernas.

**Lo que se verifica y lo que no:** el laboratorio cubre las cuatro técnicas de CPU (datos, memoria, espacial, paralelismo) y **compara cada versión optimizada contra una implementación de referencia obviamente correcta**. Las clases 345–351 son de GPU y no tienen lab: medirlas exige hardware gráfico y una pantalla, y la CI no tiene ninguna de las dos cosas.

## 🔗 Integración con lo que ya existía

Las Partes 18–21 no viven aparte. Se añadieron punteros en las clases existentes cuya materia continúa en el material nuevo — siempre como una sección al final, sin tocar el contenido anterior:

| Clase existente | Continúa en |
|---|---|
| [043 — Guardado y carga de progreso](../classes/parte-1-motores-2d-y-tu-primer-juego-jugable/043-guardado-y-carga-de-progreso/README.md) | 307 (guardado de producción) y 313 (saves en la nube) |
| [148, 152, 154](../classes/parte-7-multijugador-y-networking/README.md) — multijugador | Parte 19 (backend, economía autoritativa, anti-cheat) |
| [158–163, 168](../classes/parte-8-game-design-y-diseno-de-niveles/README.md) — game design | Parte 18 (los sistemas que implementan esos diseños) |
| [259–260, 264–265](../classes/parte-15-herramientas-editores-y-automatizacion/README.md) — tooling | Parte 19 (CI de producción, release engineering) |
| [273, 278–279](../classes/parte-16-produccion-publicacion-monetizacion-y-liveops/README.md) — LiveOps | Parte 19 (telemetría, flags, parches) |
| [282–283](../classes/parte-17-capstones-y-preparacion-profesional-portfolio/README.md) — carrera | Partes 18–21 (las especializaciones que abren) |
| [292 — Capstone final](../classes/parte-17-capstones-y-preparacion-profesional-portfolio/292-capstone-final-publica-tu-juego-y-tu-portfolio/README.md) | 293 (el programa ya no termina ahí) |

## 🧪 Los cuatro laboratorios nuevos

Todos son **proyectos Godot 4.3 reales**, en versión `inicio/` (con TODO numerados) y `solucion/`, y todos se verifican en CI.

| Lab | Comprobaciones | Qué prueba de verdad |
|---|---:|---|
| [`gameplay-systems`](../labs/gameplay-systems/README.md) | 122 | Apilado, transacciones con rollback, equipar/desequipar, modificadores, cooldowns, efectos con conteo por fuente, transiciones de quest y migraciones de guardado v1→v3 |
| [`production-runtime`](../labs/production-runtime/README.md) | 91 | Un backend mock **deliberadamente hostil** (lento, 5xx, 4xx, caído, corrupto, intermitente) contra reintentos, circuit breaker, idempotencia, flags, telemetría y saves atómicos |
| [`ai-game-system`](../labs/ai-game-system/README.md) | 55 | **Siete ataques de prompt injection** con un modelo que obedece por completo al atacante, sin que ninguno altere el estado del juego |
| [`advanced-engineering`](../labs/advanced-engineering/README.md) | 33 | Que cada optimización **da el mismo resultado** que su referencia lenta, y cuánto gana medido en tu máquina |

### Restricciones que se respetaron

- **Sin dependencias nuevas.** Nada que instalar más allá de Godot 4.3, igual que antes.
- **Sin servicios de pago ni claves de API.** Ninguna.
- **Sin secretos ni credenciales** en el repositorio ni en la CI.
- **CI completamente offline.** Ninguna prueba llama a una API comercial; los proveedores de IA son mocks deterministas.

## 🤔 Preguntas razonables

**¿Por qué no reorganizar el programa entero ahora que hay 352 clases?**
Porque hay gente a mitad de camino, hay enlaces publicados y hay PDFs descargados. Una renumeración «más limpia» habría roto todo eso a cambio de una estética. Los números crecen hacia adelante; el pasado se queda quieto.

**¿Tengo que hacer las Partes 18–21?**
No. Las Partes 0–17 siguen siendo un programa completo que termina en un juego publicado. Las cuatro nuevas son especialización: hazlas cuando reconozcas el problema que resuelven.

**¿La Parte 20 significa que el curso ahora "va de IA"?**
No. Son 14 clases de 352, y su primera lección es dónde **no** usar un modelo de lenguaje. La IA clásica de la Parte 5 no perdió ni una clase.

**¿Y si algo de lo nuevo está mal?**
[Abre un issue](https://github.com/vladimiracunadev-create/modern-gamedev-program/issues). El material nuevo es tan corregible como el viejo.
