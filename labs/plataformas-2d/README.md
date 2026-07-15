# 🕹️ Lab — Plataformas 2D

> [⬅️ Volver a los labs](../README.md) · [📚 Parte 1 del curso](../../classes/parte-1-motores-2d-y-tu-primer-juego-jugable/README.md)

El proyecto que acompaña a la **Parte 1** (clases 026–045) y a su [capstone (clase 045)](../../classes/parte-1-motores-2d-y-tu-primer-juego-jugable/045-capstone-parte-1-un-plataformas-2d-completo-jugable/README.md).

## 🎮 Qué es

Un plataformas 2D completo y jugable en Godot 4:

- **Controlador con game feel**: aceleración/fricción, salto variable, *coyote time* y *jump buffer* (clase 030).
- **Máquina de estados** para la animación: idle / run / jump / fall (clase 036).
- **Cámara** que sigue al jugador con suavizado y límites de nivel (clase 032).
- **Monedas** con feedback y sonido (clase 039); **enemigos** que patrullan con RayCast y se derrotan de un pisotón (clases 037–038).
- **HUD** en CanvasLayer que se actualiza por señales; **vidas**, daño con *i-frames* y empuje (clase 039).
- **Récord persistente** guardado en `user://save.json` (clase 043).
- **Meta**: llega a la bandera para ganar.

**Controles:** `A`/`D` o `←`/`→` para moverte · `Espacio`/`W` para saltar · `R` para reiniciar.

## 📁 Estructura

```text
plataformas-2d/
├── inicio/      ← empieza aquí: completa los TODO
│   ├── project.godot
│   ├── assets/          (sprites y sonidos CC0)
│   ├── escenas/         (mundo, jugador, moneda, enemigo, HUD)
│   └── scripts/         (jugador.gd, moneda.gd y enemigo.gd con TODO)
└── solucion/    ← referencia completa y jugable
```

Lo que ya viene resuelto en `inicio/` (para que te centres en el gameplay): la generación del nivel, el HUD, el estado global, las escenas, el Input Map, las capas de colisión y los assets.

## 🚀 Cómo empezar

1. Instala **Godot 4.3+** desde <https://godotengine.org/download>.
2. Godot → *Import* → `labs/plataformas-2d/inicio/project.godot` → **F5**.
3. Verás el nivel y al personaje… quieto. Ese es tu punto de partida.
4. Abre `scripts/jugador.gd` y completa los `TODO` **en orden**. Ejecuta tras cada uno.

| TODO | Qué consigues | Clase |
|---|---|---|
| 1 | El personaje cae (gravedad) | 007, 030 |
| 2 | Se mueve con aceleración y fricción | 030 |
| 3–4 | Coyote time y jump buffer | 030 |
| 5–6 | Salto y salto variable | 030 |
| 7 | Animaciones según el estado | 031, 036 |

Luego sigue con `moneda.gd` (clase 039) y `enemigo.gd` (clases 037–038).

> ¿Atascado? Abre el archivo equivalente en `solucion/scripts/` y compara. No es hacer trampa: leer código bueno es parte de aprender.

## 🗺️ El nivel

El nivel se genera desde un **mapa ASCII** que está en `scripts/mundo.gd` (constante `NIVEL`). Edítalo y verás el cambio al instante:

```text
'#' suelo   'S' piedra   '=' plataforma   'o' moneda
'e' enemigo 'P' inicio   'F' meta         '.' vacío
```

> La [clase 035](../../classes/parte-1-motores-2d-y-tu-primer-juego-jugable/035-tilemaps-y-diseno-de-niveles-2d/README.md) enseña el flujo real con **TileMapLayer** en el editor. Aquí usamos texto para que el nivel sea legible y editable en un diff — el resultado en pantalla es equivalente, y diseñar niveles retocando el mapa es rapidísimo.

## ✅ Retos para ampliarlo

1. **Doble salto**: permite un salto extra en el aire (resetea al tocar suelo).
2. **Dash**: un impulso horizontal con cooldown (clase 024).
3. **Plataformas móviles**: usa `AnimatableBody2D` con un `Tween` (clase 034).
4. **Partículas**: polvo al aterrizar y explosión al derrotar un enemigo (clase 042).
5. **Screen shake**: sacude la cámara al recibir daño (clase 032).
6. **Menú y pausa**: pantalla de inicio y pausa con `get_tree().paused` (clase 040).
7. **Exporta**: genera un `.exe` y un build web y publícalo en itch.io (clase 044).

## 🔍 Verificación

Este proyecto se comprueba automáticamente en CI con **Godot headless**: se regeneran los assets (y se valida que el generador es determinista), se importa el proyecto y se arranca durante 120 frames buscando errores de script o de carga. Puedes hacer lo mismo en local:

```bash
godot --headless --path labs/plataformas-2d/solucion --import
godot --headless --path labs/plataformas-2d/solucion --quit-after 120
```
