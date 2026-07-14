# Clase 085 — Capstone Parte 3: un mini-juego de física

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Integración de aula — Godot 4.x (RigidBody2D, impulsos, joints) y patrones tipo Angry Birds*
> ⏱️ Duración estimada: **75 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Integrar todo lo aprendido en la Parte 3 en un mini-juego jugable: un **lanzador de proyectiles contra una estructura** (estilo Angry Birds). Aplicarás `RigidBody2D` con impulsos, colisiones con restitución, una **trayectoria predicha** dibujada con puntos, `joints` que mantienen unida la estructura hasta que el impacto la derriba, y **easing** en la UI. Cerrarás con una especificación, un checklist, un "definition of done" y una ronda de playtesting.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diseñar un mini-juego de física con una **especificación** clara y una lista de features.
2. Lanzar un `RigidBody2D` con `apply_impulse` calculando el vector desde un arrastre del mouse.
3. **Predecir y dibujar** la trayectoria del proyectil antes de disparar con la ecuación balística.
4. Construir una estructura con `RigidBody2D` unidos por `PinJoint2D` y ajustar restitución/fricción.
5. Aplicar un **definition of done** y un checklist de playtesting para cerrar el proyecto.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Especificación y alcance | Evita el proyecto infinito |
| 2 | Impulso desde arrastre | Control de puntería intuitivo |
| 3 | Predicción de trayectoria | Feedback que hace el juego "justo" |
| 4 | Restitución y fricción | Definen la sensación de los rebotes |
| 5 | Joints en la estructura | Torres que se derrumban de forma creíble |
| 6 | Condición de victoria | Da objetivo y cierre a la partida |
| 7 | Easing en UI y checklist DoD | Pulido final y criterio de terminado |

## 📖 Definiciones y características

- **`RigidBody2D`**: cuerpo simulado por el motor (gravedad, colisiones). Clave: no muevas su `position` a mano; usa fuerzas/impulsos.
- **`apply_impulse(impulso)`**: cambia la velocidad instantáneamente. Clave: ideal para un disparo o salto.
- **Restitución (bounce)**: cuánta energía conserva un choque (0 = pegajoso, 1 = rebote total). Clave: se define en `PhysicsMaterial`.
- **Fricción**: resistencia al deslizar. Clave: bloques con poca fricción resbalan y la torre cae más fácil.
- **`PinJoint2D`**: une dos cuerpos por un punto permitiendo giro. Clave: mantiene la estructura hasta que la fuerza la separa.
- **Trayectoria balística**: `pos(t) = p0 + v0·t + ½·g·t²`. Clave: permite dibujar la línea de puntería.
- **Definition of Done (DoD)**: criterios objetivos que marcan "terminado". Clave: separa "casi listo" de jugable de verdad.
- **Playtesting**: probar con foco en observar, no en defender el diseño. Clave: revela lo que las specs no anticipan.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x** ([godotengine.org](https://godotengine.org)). Crea un proyecto 2D. Escenas: `Proyectil` (`RigidBody2D` + `CollisionShape2D` circular + `Sprite2D`), `Bloque` (`RigidBody2D` rectangular) y `Main` (`Node2D` con el suelo `StaticBody2D`, la estructura y un `CanvasLayer` de UI). Asigna un `PhysicsMaterial` a proyectil y bloques para controlar rebote/fricción. Ten a mano [RigidBody2D](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html) y [PinJoint2D](https://docs.godotengine.org/en/stable/classes/class_pinjoint2d.html). La gravedad global está en Project Settings → Physics → 2D → Default Gravity (usa su valor para predecir la trayectoria).

## 🧪 Laboratorio guiado

Ensamblaremos el mini-juego: lanzador con arrastre, predicción de trayectoria y estructura con joints.

**Paso 1 — Lanzador con impulso desde el arrastre.** El jugador arrastra desde el proyectil; al soltar, dispara con impulso proporcional.

```gdscript
extends Node2D

@export var fuerza := 8.0
@onready var punto_lanzamiento: Vector2 = $PuntoLanzamiento.global_position

var _arrastrando := false
var _inicio := Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_arrastrando = true
			_inicio = get_global_mouse_position()
		elif _arrastrando:
			_arrastrando = false
			var impulso := (_inicio - get_global_mouse_position()) * fuerza
			_disparar(impulso)

func _disparar(impulso: Vector2) -> void:
	var p := preload("res://Proyectil.tscn").instantiate() as RigidBody2D
	p.global_position = punto_lanzamiento
	add_child(p)
	p.apply_impulse(impulso)  # una sola patada de velocidad
```

**Observable**: arrastras "hacia atrás" como una honda y el proyectil sale con la fuerza y dirección opuestas al arrastre.

**Paso 2 — Predicción de trayectoria.** Mientras arrastras, dibuja puntos siguiendo la ecuación balística usando la gravedad del proyecto.

```gdscript
@onready var gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _draw() -> void:
	if not _arrastrando:
		return
	var v0 := (_inicio - get_global_mouse_position()) * fuerza
	var g := Vector2(0, gravedad)
	var puntos := PackedVector2Array()
	for i in 30:
		var t := i * 0.05
		# pos(t) = p0 + v0*t + 0.5*g*t^2  (relativo, _draw usa coords locales)
		var pos := (punto_lanzamiento - global_position) + v0 * t + 0.5 * g * t * t
		puntos.append(pos)
	for i in range(puntos.size() - 1):
		draw_line(puntos[i], puntos[i + 1], Color(1, 1, 1, 0.5), 2.0)

func _process(_delta: float) -> void:
	if _arrastrando:
		queue_redraw()  # actualizar la linea mientras se apunta
```

**Observable**: una línea punteada muestra el arco previsto y coincide con el vuelo real del proyectil, porque usa la misma gravedad e impulso.

**Paso 3 — Estructura con joints.** Apila bloques y únelos con `PinJoint2D` para que la torre resista hasta el impacto.

```gdscript
func construir_torre(base: Vector2) -> void:
	var previo: RigidBody2D = null
	for i in 5:
		var bloque := preload("res://Bloque.tscn").instantiate() as RigidBody2D
		bloque.global_position = base + Vector2(0, -i * 34.0)
		add_child(bloque)
		if previo:
			var junta := PinJoint2D.new()
			junta.global_position = (bloque.global_position + previo.global_position) / 2.0
			junta.node_a = previo.get_path()
			junta.node_b = bloque.get_path()
			junta.softness = 0.2  # cede un poco antes de romperse visualmente
			add_child(junta)
		previo = bloque
```

**Observable**: la torre se mantiene erguida y tiembla como un bloque unido; un buen impacto la desarticula y los bloques caen por separado.

**Paso 4 — Condición de victoria y "pop" de UI.** Detecta cuando el objetivo cae por debajo de una altura y muestra un cartel con easing elastic.

```gdscript
func _mostrar_victoria() -> void:
	var cartel := $UI/CartelVictoria
	cartel.visible = true
	cartel.scale = Vector2.ZERO
	cartel.pivot_offset = cartel.size / 2.0
	var tw := create_tween()
	tw.tween_property(cartel, "scale", Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
```

**Observable**: al derribar el objetivo aparece el cartel "¡Ganaste!" con un rebote elástico, cerrando el bucle de juego con feedback satisfactorio.

## Tabla de features

| Feature | Estado objetivo |
|---------|-----------------|
| Lanzar proyectil con arrastre + impulso | Obligatorio |
| Predicción de trayectoria visible al apuntar | Obligatorio |
| Estructura de bloques con joints | Obligatorio |
| Restitución y fricción configuradas | Obligatorio |
| Condición de victoria (objetivo derribado) | Obligatorio |
| Contador de intentos / puntaje | Deseable |
| Reinicio de nivel con tecla | Deseable |
| Easing en aparición de UI | Obligatorio |
| Múltiples niveles | Opcional |

## ✍️ Ejercicios

1. Añade un contador de "pájaros" (intentos) que baje con cada disparo y muestre derrota al llegar a 0 sin ganar.
2. Da al proyectil una habilidad al hacer clic en el aire (impulso extra o dividirse en tres).
3. Ajusta el `PhysicsMaterial` para comparar una torre "resbaladiza" vs. "pegajosa".
4. Reinicia el nivel con la tecla R recargando la escena (`get_tree().reload_current_scene()`).
5. Muestra el puntaje con un Tween que cuenta hacia arriba en vez de saltar al total.
6. Guarda el mejor puntaje en disco con `FileAccess` y muéstralo en pantalla.

## 📝 Reto verificable

Entrega un nivel jugable completo: apuntar con arrastre, línea de predicción, torre de al menos 5 bloques con joints, un objetivo que al caer dispara la victoria con UI animada, y un botón/tecla de reinicio.

**Criterio de aceptación (Definition of Done)**: (1) el proyectil se lanza solo con impulso, nunca moviendo `position`; (2) la línea predicha coincide con el vuelo real; (3) la torre se sostiene sola y se derrumba con un impacto suficiente; (4) al derribar el objetivo aparece la UI de victoria con easing; (5) el nivel se puede reiniciar sin cerrar el juego; (6) un compañero completa el nivel en su primer intento de playtesting sin instrucciones verbales.

## Checklist de playtesting

- [ ] ¿Se entiende cómo apuntar sin explicación?
- [ ] ¿La predicción ayuda o estorba (demasiada/poca)?
- [ ] ¿La dificultad es justa en el primer nivel?
- [ ] ¿Hay feedback claro al ganar y al fallar?
- [ ] ¿El rendimiento se mantiene con la torre completa cayendo?

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El proyectil atraviesa la torre | Colisiones rápidas; activa Continuous CD en el `RigidBody2D` |
| La predicción no coincide con el vuelo | Usaste una gravedad distinta a la del proyecto; lee `default_gravity` |
| La torre tiembla o "explota" al iniciar | Bloques solapados o joints mal ubicados; sepáralos y centra las juntas |
| Mover `position` no hace nada creíble | Estás moviendo un rígido a mano; usa `apply_impulse`/fuerzas |
| El cartel de victoria crece desde una esquina | Falta `pivot_offset` centrado antes del Tween de escala |

## ❓ Preguntas frecuentes

**¿Por qué no muevo el proyectil con `position`?** Porque es un `RigidBody2D`: el motor lo controla. Cambiar `position` pelea con la simulación y produce saltos. Usa impulsos y fuerzas.

**¿Cómo hago la predicción exacta si hay rebotes?** La fórmula balística solo predice el vuelo libre. Para rebotes se usa `PhysicsDirectSpaceState2D` o se simula en un mundo aparte; para el capstone basta el arco hasta el primer impacto.

**¿Los joints se "rompen" solos?** `PinJoint2D` no se rompe por defecto: cede y gira. Para que se separen del todo puedes eliminarlos cuando la fuerza supere un umbral, o simplemente dejar que los bloques se desacoplen al caer.

**¿Qué entra en el "definition of done"?** Criterios objetivos y verificables por otra persona: features obligatorias funcionando, sin crashes, y un playtest superado. No "me parece que está bien".

## 🔗 Referencias

- Godot Docs — RigidBody2D: <https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html>
- Godot Docs — PinJoint2D: <https://docs.godotengine.org/en/stable/classes/class_pinjoint2d.html>
- Godot Docs — Physics materials y RigidBody: <https://docs.godotengine.org/en/stable/tutorials/physics/using_area_2d.html>
- Godot Docs — Tween (UI easing): <https://docs.godotengine.org/en/stable/classes/class_tween.html>

## ➡️ Siguiente clase

Con este capstone cierras la **Parte 3**. Continúas con la Parte 4, dedicada a gráficos, shaders y rendering moderno:

[Clase 086 - El pipeline de render moderno en profundidad](../../parte-4-graficos-shaders-y-rendering-moderno/086-el-pipeline-de-render-moderno-en-profundidad/README.md)
