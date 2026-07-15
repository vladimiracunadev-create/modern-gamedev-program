# Clase 040 — Menús, pausa y flujo de escenas

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4*
> ⏱️ Duración estimada: **90 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dar al juego su envoltura completa: **menú principal**, **pausa** y **game over**, con el flujo de escenas que los conecta. Construiremos pantallas de UI con nodos `Control` y botones, navegaremos con `change_scene_to_file`, y congelaremos la partida con `get_tree().paused` manteniendo activo el menú de pausa gracias a `process_mode`.

Al terminar, el jugador podrá arrancar desde un menú, pausar en cualquier momento, morir y reintentar. Es la capa que transforma tu prototipo jugable en un juego con principio, interrupción y reinicio.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Crear escenas de UI con nodos `Control` y botones funcionales.
2. Conectar la señal `pressed` de un botón a la lógica de navegación.
3. Cambiar de escena con `change_scene_to_file`.
4. Implementar un menú de pausa con `get_tree().paused` y `process_mode`.
5. Construir una pantalla de Game Over con reinicio de nivel.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Escenas de UI con Control | Son la base de menús y pantallas. |
| 2 | Botón y señal pressed | Traducen el clic en acción de juego. |
| 3 | change_scene_to_file | Cambia el nivel o la pantalla activa. |
| 4 | get_tree().paused | Congela toda la lógica del juego. |
| 5 | process_mode del menú | Deja vivo el menú mientras el resto duerme. |
| 6 | Acción de pausa en el Input Map | Permite abrir/cerrar el menú con una tecla. |
| 7 | Reiniciar nivel | Cierra el bucle tras la derrota. |
| 8 | Transición simple | Suaviza el paso entre pantallas. |

## 📖 Definiciones y características

- **Control**: nodo base de interfaz; ancla y organiza elementos. Clave: se posiciona con anclas y contenedores.
- **Button**: control que emite `pressed` al pulsarse. Clave: se conecta a un método sin escribir la detección del clic.
- **change_scene_to_file**: cambia la escena principal por otra `.tscn`. Clave: libera la escena anterior automáticamente.
- **get_tree().paused**: pausa el SceneTree completo. Clave: detiene `_process` y `_physics_process` según el `process_mode`.
- **process_mode**: define cómo reacciona un nodo a la pausa. Clave: `PROCESS_MODE_ALWAYS` lo mantiene activo aun en pausa.
- **CanvasLayer del menú**: capa fija donde vive la UI de pausa. Clave: no se mueve con la cámara y se muestra encima.
- **Game Over**: pantalla tras perder. Clave: ofrece reintentar o volver al menú.
- **Reintentar**: recarga o reinicia el nivel. Clave: reinicia también el estado global si procede.

## 🧰 Herramientas y preparación

Trabaja en `PlataformasCurso` con tu nivel jugable (`escenas/nivel.tscn`) y el `GameState` de la clase 039. Define una acción `pausa` en **Project Settings > Input Map** (por ejemplo la tecla `Esc`). Repasa la guía de UI de Godot (<https://docs.godotengine.org/en/stable/tutorials/ui/index.html>), el manejo de pausa (<https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html>) y `change_scene_to_file` en `SceneTree` (<https://docs.godotengine.org/en/stable/classes/class_scenetree.html>).

Ten a mano las rutas exactas de tus escenas (`res://escenas/menu.tscn`, `res://escenas/nivel.tscn`, etc.); un error de ruta es el fallo más frecuente al cambiar de escena.

## 🧪 Laboratorio guiado

Crearemos el menú principal, la pausa y el game over.

1. Crea la escena `Menu` con raíz `Control`. Añade un `Label` de título y dos `Button`: `BotonJugar` y `BotonSalir`. Añade el script al `Control`.

```gdscript
extends Control

func _ready() -> void:
	$BotonJugar.pressed.connect(_on_jugar)
	$BotonSalir.pressed.connect(_on_salir)

func _on_jugar() -> void:
	get_tree().change_scene_to_file("res://escenas/nivel.tscn")

func _on_salir() -> void:
	get_tree().quit()
```

2. Guarda como `escenas/menu.tscn`. En **Project Settings > Application > Run**, define esta escena como **Main Scene** para que el juego arranque en el menú. Ejecuta y confirma que **Jugar** carga el nivel.

3. Crea la escena `PausaMenu` con raíz `CanvasLayer`. En su inspector, pon `process_mode` en **Always** para que siga vivo con el juego pausado. Añade dentro un `Control` con un `Panel` semitransparente y dos botones: `BotonReanudar` y `BotonMenu`. Añade el script al `CanvasLayer`.

```gdscript
extends CanvasLayer

func _ready() -> void:
	hide()
	$Control/BotonReanudar.pressed.connect(_reanudar)
	$Control/BotonMenu.pressed.connect(_ir_al_menu)

func _reanudar() -> void:
	get_tree().paused = false
	hide()

func _ir_al_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://escenas/menu.tscn")
```

4. Añade la apertura de la pausa. Como el `CanvasLayer` no recibe input por sí solo, gestiona la acción `pausa` desde su script con `_unhandled_input`, alternando `paused` y visibilidad.

```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa"):
		var pausar := not get_tree().paused
		get_tree().paused = pausar
		visible = pausar
```

5. Instancia `PausaMenu` como hijo del nivel (o de una escena raíz que contenga el nivel y el HUD). Al pulsar `Esc` el juego debe congelarse y aparecer el menú; al reanudar, continuar. Verifica que el jugador no se mueve mientras está pausado.

6. Crea la escena `GameOver` con raíz `Control`: un `Label` "Game Over", un `Label` para la puntuación final y dos botones `BotonReintentar` y `BotonMenu`. Añade el script.

```gdscript
extends Control

func _ready() -> void:
	$PuntuacionLabel.text = "Puntos: %d" % GameState.puntuacion
	$BotonReintentar.pressed.connect(_reintentar)
	$BotonMenu.pressed.connect(_ir_al_menu)

func _reintentar() -> void:
	GameState.reiniciar()
	get_tree().change_scene_to_file("res://escenas/nivel.tscn")

func _ir_al_menu() -> void:
	GameState.reiniciar()
	get_tree().change_scene_to_file("res://escenas/menu.tscn")
```

7. Enlaza la derrota. Cuando `GameState.vidas` llegue a 0, cambia a la pantalla de game over. Añade en `game_state.gd`:

```gdscript
func perder_vida() -> void:
	vidas = max(vidas - 1, 0)
	vidas_cambiadas.emit(vidas)
	if vidas == 0:
		get_tree().change_scene_to_file("res://escenas/game_over.tscn")
```

8. Prueba el flujo completo: Menú → Jugar → nivel → `Esc` pausa/reanuda → perder todas las vidas → Game Over → Reintentar reinicia el nivel con puntuación a cero. Confirma que la pausa detiene enemigos y jugador pero permite pulsar los botones.

## ✍️ Ejercicios

1. Añade al menú de pausa un botón "Reiniciar nivel" que use `reload_current_scene`.
2. Enfoca por defecto el primer botón (`grab_focus`) para permitir navegación con teclado.
3. Añade una transición de oscurecido (tween sobre un `ColorRect`) antes de cambiar de escena.
4. Reproduce un sonido distinto al abrir y al cerrar la pausa.
5. Muestra en el Game Over la puntuación máxima además de la actual.
6. Añade confirmación al botón "Salir" del menú con un pequeño diálogo.

## 📝 Reto verificable

Implementa un menú de opciones accesible desde el menú principal y desde la pausa, con un control de volumen (`HSlider`) que ajuste el bus maestro de audio y una casilla de pantalla completa; los cambios deben conservarse al navegar entre escenas usando el `GameState` u otro Autoload de ajustes. **Criterio de aceptación**: desde ambos menús se abre Opciones, el slider modifica el volumen en tiempo real, la casilla alterna pantalla completa, al volver y reabrir Opciones los valores persisten, y ninguna transición deja el juego pausado por error.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| Los botones de pausa no responden | El menú no tiene `process_mode = Always`; el árbol pausado ignora su input. |
| `Cannot open file res://...` | Ruta de escena mal escrita; copia la ruta exacta desde el FileSystem. |
| El juego sigue pausado tras cambiar de escena | No pusiste `paused = false` antes de `change_scene_to_file`. |
| La pausa no se abre con Esc | Falta la acción `pausa` en el Input Map o usas la señal equivocada. |
| Game Over conserva puntuación vieja | No llamas a `GameState.reiniciar()` al reintentar. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué el menú de pausa necesita `process_mode = Always`?** Porque al pausar el árbol, los nodos con el modo por defecto dejan de procesar. Con `Always`, el menú sigue recibiendo input para poder reanudar.

**❓ ¿`change_scene_to_file` libera la escena anterior?** Sí, la elimina y carga la nueva como escena actual. Por eso el estado que quieras conservar debe vivir en un Autoload.

**❓ ¿Puedo pausar solo una parte del juego?** No con `get_tree().paused`, que afecta a todo el árbol. Para pausar solo algunos nodos, ajusta su `process_mode` individualmente.

**❓ ¿Menú como escena aparte o superpuesto?** El menú principal y el game over suelen ser escenas completas; la pausa es un `CanvasLayer` superpuesto sobre el nivel para no descargarlo.

## 🔗 Referencias

- Godot — Pausing games: <https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html>
- Godot — SceneTree (change_scene_to_file): <https://docs.godotengine.org/en/stable/classes/class_scenetree.html>
- Godot — UI building blocks: <https://docs.godotengine.org/en/stable/tutorials/ui/index.html>
- Godot — Button: <https://docs.godotengine.org/en/stable/classes/class_button.html>

## ⬅️ Clase anterior

[Clase 039 - Recolectables, puntuación y HUD](../039-recolectables-puntuacion-y-hud/README.md)

## ➡️ Siguiente clase

[Clase 041 - Sonido y música en 2D: efectos y bucle musical](../041-sonido-y-musica-en-2d-efectos-y-bucle-musical/README.md)
