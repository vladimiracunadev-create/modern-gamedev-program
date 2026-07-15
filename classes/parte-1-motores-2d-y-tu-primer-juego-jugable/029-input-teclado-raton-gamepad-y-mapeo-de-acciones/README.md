# Clase 029 — Input: teclado, ratón, gamepad y mapeo de acciones

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4 (InputEvent, Using InputMap)*
> ⏱️ Duración estimada: **80 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Aprender a leer la entrada del jugador en Godot 4 de forma robusta y portable usando el **Input Map**: acciones abstractas ("move_left", "jump") que puedes asignar a teclado, ratón y gamepad a la vez, sin acoplar tu código a teclas concretas.

Verás la diferencia entre `is_action_pressed` (mientras se mantiene) e `is_action_just_pressed` (solo el instante inicial), los helpers `get_axis` y `get_vector`, y cuándo conviene hacer *polling* en `_physics_process` frente a responder a eventos en `_input`. El laboratorio deja definidas las acciones del jugador y las lee en pantalla.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Crear acciones en el Input Map y asignarles teclas y botones de gamepad.
2. Leer un eje horizontal continuo con `Input.get_axis`.
3. Distinguir `is_action_pressed` de `is_action_just_pressed` y usar cada uno.
4. Leer un vector de movimiento en dos ejes con `Input.get_vector`.
5. Decidir entre polling en `_physics_process` y eventos en `_input`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Input Map | Desacopla acciones de teclas concretas. |
| 2 | Teclado | Entrada principal en PC. |
| 3 | Ratón (posición y clics) | Apuntado, menús e interacción. |
| 4 | Gamepad | Soporte de mando sin cambiar código. |
| 5 | `is_action_pressed` vs `just_pressed` | Sostenido frente a pulsación única. |
| 6 | `get_axis` y `get_vector` | Lectura limpia de movimiento. |
| 7 | Polling vs eventos | Dos formas de leer input según el caso. |
| 8 | `_input` y `_unhandled_input` | Reaccionar a eventos concretos. |

## 📖 Definiciones y características

- **Acción de input**: nombre lógico (p. ej. `jump`) con una lista de eventos asociados. Clave: cambias el mapeo sin tocar el código.
- **Input Map**: tabla de acciones en Project Settings. Clave: define teclas, botones de ratón y de gamepad para cada acción.
- **`is_action_pressed`**: devuelve `true` mientras la acción se mantiene. Clave: ideal para movimiento continuo.
- **`is_action_just_pressed`**: `true` solo el frame en que se pulsa. Clave: perfecto para saltos y disparos únicos.
- **`Input.get_axis(neg, pos)`**: devuelve un valor de -1 a 1. Clave: resume dos acciones opuestas en un número.
- **`Input.get_vector(...)`**: devuelve un `Vector2` normalizado de movimiento. Clave: entrada 2D limpia y con zona muerta.
- **Polling**: consultar el estado del input cada frame. Clave: se hace en `_physics_process` para movimiento.
- **Eventos**: recibir `InputEvent` puntuales en `_input`. Clave: útil para acciones discretas y UI.

## 🧰 Herramientas y preparación

Sigue en `PlataformasCurso`. Si tienes un gamepad, conéctalo por USB o Bluetooth antes de abrir Godot para que lo detecte. No hacen falta assets. Usaremos la pantalla y el Output para ver los valores de input.

Consulta el Input Map en <https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html#actions> y la clase `Input` en <https://docs.godotengine.org/en/stable/classes/class_input.html>. Todo el mapeo se hace en Project Settings → Input Map.

## 🧪 Laboratorio guiado

Definiremos las acciones del jugador y leeremos su input en pantalla.

1. Abre **Project → Project Settings → Input Map**. En el campo superior escribe `move_left` y pulsa **Add**. Repite con `move_right`, `move_up`, `move_down` y `jump`.

2. Asigna teclas: pulsa el **+** a la derecha de `move_left`, elige **Key**, y presiona la tecla A (y opcionalmente flecha izquierda). Haz lo mismo con `move_right` → D/flecha derecha, `move_up` → W/flecha arriba, `move_down` → S/flecha abajo, y `jump` → barra espaciadora.

3. Añade soporte de gamepad: en `move_left`/`move_right` agrega un evento **Joypad Axis** (eje izquierdo horizontal) y en `jump` un **Joypad Button** (el botón inferior, típicamente "A"). Así el mismo código funcionará con mando.

4. Abre `escenas/jugador.tscn` y reemplaza `jugador.gd` para leer el input por *polling* en `_physics_process`:

```gdscript
extends Node2D

@export var velocidad: float = 200.0

func _physics_process(delta: float) -> void:
	# Eje horizontal continuo: -1 (izquierda) a 1 (derecha).
	var eje_x: float = Input.get_axis("move_left", "move_right")
	position.x += eje_x * velocidad * delta

	# Salto: solo el instante de la pulsacion, no mientras se mantiene.
	if Input.is_action_just_pressed("jump"):
		print("Salto solicitado (just_pressed)")

	# Ejemplo de accion sostenida: util para correr, agacharse, etc.
	if Input.is_action_pressed("move_down"):
		print("Manteniendo abajo (pressed)")

	# Vector de movimiento 2D normalizado (con zona muerta de gamepad).
	var mov: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if mov != Vector2.ZERO:
		print("Vector de input: ", mov)
```

5. Ejecuta con F5. Mueve con A/D o el stick: el sprite se desplaza y el Output muestra el eje, el vector y los avisos de salto. Observa que "Salto solicitado" aparece **una sola vez** por pulsación, mientras que "Manteniendo abajo" se repite cada frame.

6. Añade lectura del **ratón** con un manejador de eventos. Crea un script en `Mundo` (o edita `mundo.gd`) con:

```gdscript
extends Node2D

func _input(event: InputEvent) -> void:
	# Posicion del raton al mover.
	if event is InputEventMouseMotion:
		pass  # descomenta para depurar: print("Raton en: ", event.position)
	# Clic izquierdo del raton como evento discreto.
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Clic izquierdo en: ", event.position)
```

7. Ejecuta y haz clic en la ventana: el Output imprime la posición del clic. Fíjate en el contraste: el movimiento usa *polling* cada frame; el clic se atiende como *evento* puntual, que es más eficiente para acciones discretas.

Ya tienes un esquema de input portable (teclado + ratón + gamepad) listo para el controlador de movimiento de la clase 030.

## ✍️ Ejercicios

1. Añade una acción `run` (Shift) y multiplica la velocidad cuando esté `is_action_pressed`.
2. Muestra el eje horizontal en una `Label` en pantalla en lugar de en Output.
3. Cambia el mapeo de salto a otra tecla desde el Input Map sin tocar el script.
4. Usa `Input.get_vector` para mover el sprite libre en 2D (sin gravedad todavía).
5. Detecta el botón derecho del ratón (`MOUSE_BUTTON_RIGHT`) e imprime un mensaje distinto.
6. Mueve la detección de salto a `_unhandled_input` y comenta la diferencia frente a `_input`.

## 📝 Reto verificable

Crea las cinco acciones (`move_left`, `move_right`, `move_up`, `move_down`, `jump`) con teclado y gamepad, y haz que el jugador se mueva en 2D con `Input.get_vector`, mostrando en una `Label` el vector actual y contando en pantalla cuántas veces se ha pulsado saltar usando `is_action_just_pressed`.

**Criterio de aceptación**: el sprite se mueve con teclado y mando por igual, la etiqueta refleja el vector de input en vivo y el contador de saltos solo sube una unidad por cada pulsación real.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| "The InputMap action 'jump' doesn't exist" | La acción no está creada o está mal escrita. Revísala en Project Settings → Input Map. |
| El salto se dispara muchas veces por pulsación | Usaste `is_action_pressed` en vez de `is_action_just_pressed`. |
| El gamepad no responde | Se conectó después de abrir el juego o falta el evento Joypad en la acción. Reasígnalo. |
| El movimiento diagonal es más rápido | No normalizaste el vector. `get_vector` ya lo normaliza; si sumas ejes a mano, usa `.normalized()`. |
| El ratón no imprime posición | Estás leyendo en polling; usa `_input` con `InputEventMouseButton`/`InputEventMouseMotion`. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué usar acciones y no leer teclas directas?** Porque el Input Map permite reasignar controles y soportar teclado, ratón y gamepad sin cambiar el código del juego.

**❓ ¿Cuándo uso polling y cuándo eventos?** El polling en `_physics_process` va bien para movimiento continuo; los eventos en `_input` son más eficientes para acciones discretas como clics o menús.

**❓ ¿Qué diferencia hay entre `_input` y `_unhandled_input`?** `_input` recibe todos los eventos; `_unhandled_input` solo los que la UI no consumió, ideal para gameplay que no debe robar clics a los menús.

**❓ ¿`get_vector` maneja la zona muerta del stick?** Sí, aplica una zona muerta y normaliza el resultado, evitando deriva del analógico y movimiento diagonal exagerado.

## 🔗 Referencias

- Godot Docs — InputEvent y acciones: <https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html>
- Godot Docs — Using InputMap: <https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html>
- Godot Docs — Clase Input: <https://docs.godotengine.org/en/stable/classes/class_input.html>
- Godot Docs — Controllers, gamepads and joysticks: <https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html>

## ⬅️ Clase anterior

[Clase 028 - El game loop en la práctica: _process,_physics_process y señales](../028-el-game-loop-en-la-practica-process-physics-process-y-senales/README.md)

## ➡️ Siguiente clase

[Clase 030 - Movimiento de personaje 2D: velocidad, aceleración y control](../030-movimiento-de-personaje-2d-velocidad-aceleracion-y-control/README.md)
