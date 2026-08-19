# Parte 18 — Arquitectura de gameplay y sistemas sistémicos

> [⬅️ Volver al programa](../../README.md) · [📚 Índice completo](../README.md) · [⏮️ Parte anterior](../parte-17-capstones-y-preparacion-profesional-portfolio/README.md) · [⏭️ Parte siguiente](../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md)

**18 clases** · rango 293–310 · De "sé hacer un juego" a "sé construir los sistemas que un juego grande necesita": items, inventario, equipo, habilidades, efectos, combate, loot, crafting, progresión, economía, diálogo, quests, facciones, guardado versionado, replays y modding

**Fuentes de referencia de esta parte:**

- Robert Nystrom, *Game Programming Patterns* — Component, Command, Event Queue, Type Object, Service Locator: <https://gameprogrammingpatterns.com/>
- Jason Gregory, *Game Engine Architecture* (3.ª ed.) — capítulos de gameplay foundation systems y object models.
- Documentación de [recursos personalizados de Godot 4](https://docs.godotengine.org/en/4.3/tutorials/scripting/resources.html) y de [señales](https://docs.godotengine.org/en/4.3/getting_started/step_by_step/signals.html).
- Documentación del [Gameplay Ability System de Unreal Engine](https://dev.epicgames.com/documentation/en-us/unreal-engine/gameplay-ability-system-for-unreal-engine) como referencia conceptual de sistemas de habilidades de producción.
- Charlas de GDC sobre diseño de sistemas de inventario, loot y economías: <https://www.gdcvault.com/>

---

## 🎯 ¿De qué trata esta parte?

Hasta aquí sabes construir **un juego**. Esta parte enseña a construir **los sistemas de un juego que crece**: los que aparecen en cuanto el proyecto pasa de tres escenas a treinta, de cinco objetos a quinientos, y de un programador a un equipo con diseñadores que quieren cambiar el balance sin tocar código.

Es la diferencia entre un `if` con el nombre del objeto y una **base de datos de items**; entre restar vida en el `_process` del enemigo y un **pipeline de daño** con resistencias, críticos e invulnerabilidad; entre un `save.json` que se rompe en la versión 1.1 y un **save versionado con migraciones**. Todos estos sistemas comparten la misma idea de fondo: **separar los datos del comportamiento y el comportamiento de la presentación**, de forma que cada pieza se pueda probar sola.

La Parte 8 te enseñó a **diseñar** economías, progresión y recompensas. Esta parte las **implementa**. La distinción es deliberada y se mantiene en cada clase: allí se decide *qué* debe pasar; aquí se construye el sistema que hace que pase, con sus casos límite y su persistencia.

## 🧩 Problemas que resuelve

- Juegos monolíticos donde tocar el inventario rompe la UI y el combate.
- Items definidos a base de `if nombre == "espada"` repartidos por todo el código.
- Inventarios que pierden objetos al llenarse, o que duplican stacks al mover.
- Habilidades copiadas y pegadas con su cooldown propio en cada script.
- Buffs que se pisan entre sí, no caducan o se acumulan hasta el infinito.
- Loot que "parece" aleatorio pero no se puede reproducir ni depurar.
- Guardados que dejan de cargar en cuanto añades un campo.
- Diálogos y quests hardcodeados que ningún diseñador puede tocar.
- Mods que exigen recompilar el juego, o que ejecutan cualquier cosa sin control.

## 🎓 Resultados de aprendizaje

Al terminar la parte, el alumno podrá:

- Separar un juego en capas **dominio / gameplay / presentación / infraestructura** con dependencias en un solo sentido.
- Definir catálogos de contenido **data-driven** con IDs estables, esquema y validación automática.
- Implementar inventario, equipo, estadísticas con modificadores, habilidades y efectos de estado como sistemas independientes y testeables.
- Construir un pipeline de daño explícito y un sistema de loot **determinista y reproducible**.
- Implementar progresión, economía, diálogo, quests y reputación sobre datos, no sobre código.
- Escribir un save system de producción con `SAVE_VERSION`, migraciones, escritura atómica y recuperación ante corrupción.
- Grabar y reproducir partidas con el patrón Command, y usar los replays como test de regresión.
- Diseñar una arquitectura de mods con límites de API, manifiestos y permisos explícitos.

## 🧱 Prerrequisitos

- Partes 0 a 3 (POO, patrones, vectores, física básica) y Parte 5 (IA) para el capstone.
- Parte 8 (game design): aquí se implementa lo que allí se diseña.
- Parte 15 (tooling): los recursos personalizados y el diseño data-driven de las clases 259–260 son el punto de partida de la 294.
- Godot 4.x. El capstone se entrega como proyecto ejecutable.

## 📚 Las 18 clases

| # | Clase |
|---|---|
| 293 | [Arquitectura de gameplay a escala](293-arquitectura-de-gameplay-a-escala/README.md) |
| 294 | [Items y base de datos de objetos](294-items-y-base-de-datos-de-objetos/README.md) |
| 295 | [Sistema de inventario](295-sistema-de-inventario/README.md) |
| 296 | [Equipamiento, loadouts y estadísticas](296-equipamiento-loadouts-y-estadisticas/README.md) |
| 297 | [Ability System: arquitectura de habilidades](297-ability-system-arquitectura-de-habilidades/README.md) |
| 298 | [Status effects, buffs y debuffs](298-status-effects-buffs-y-debuffs/README.md) |
| 299 | [Arquitectura avanzada de combate y daño](299-arquitectura-avanzada-de-combate-y-dano/README.md) |
| 300 | [Loot tables y sistemas de recompensas](300-loot-tables-y-sistemas-de-recompensas/README.md) |
| 301 | [Crafting y recetas](301-crafting-y-recetas/README.md) |
| 302 | [Progresión y skill trees](302-progresion-y-skill-trees/README.md) |
| 303 | [Economía interna implementada](303-economia-interna-implementada/README.md) |
| 304 | [Sistemas de diálogo](304-sistemas-de-dialogo/README.md) |
| 305 | [Quest System](305-quest-system/README.md) |
| 306 | [Facciones, reputación y relaciones](306-facciones-reputacion-y-relaciones/README.md) |
| 307 | [Save System de producción](307-save-system-de-produccion/README.md) |
| 308 | [Commands, input recording y replays](308-commands-input-recording-y-replays/README.md) |
| 309 | [Modding y arquitectura extensible](309-modding-y-arquitectura-extensible/README.md) |
| 310 | [Capstone Parte 18: un juego sistémico](310-capstone-parte-18-un-juego-sistemico/README.md) |

---

> Con los sistemas del juego construidos, la [Parte 19](../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md) los pone a funcionar en producción: backend, configuración remota, observabilidad, seguridad y entrega.
