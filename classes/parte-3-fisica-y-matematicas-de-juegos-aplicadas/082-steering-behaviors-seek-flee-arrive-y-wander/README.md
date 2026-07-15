# Clase 082 — Steering behaviors: seek, flee, arrive y wander

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Craig Reynolds — "Steering Behaviors for Autonomous Characters" (1999) y práctica con Godot 4.x*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Programar agentes que se mueven de forma creíble sin scripts rígidos ni caminos predefinidos, usando el modelo de **steering behaviors** de Craig Reynolds. Entenderás cómo una fuerza de dirección modifica la velocidad de un `CharacterBody2D` frame a frame para producir comportamientos como perseguir (seek), huir (flee), llegar frenando (arrive) y deambular (wander). Al final tendrás un agente que conmuta entre conductas y reacciona al mouse en tiempo real.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar el bucle **velocidad deseada → fuerza de dirección → velocidad → posición** del modelo de Reynolds.
2. Implementar **seek** y **flee** como fuerzas hacia/desde un objetivo con velocidad limitada.
3. Implementar **arrive** con un radio de frenado para llegar sin sobrepasar el objetivo.
4. Implementar **wander** con un círculo de proyección y ruido para vagar de forma natural.
5. **Combinar y conmutar** conductas manipulando el vector `velocity` de un `CharacterBody2D`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Velocidad deseada vs. actual | Núcleo del steering: la fuerza es su diferencia |
| 2 | Límites: `max_speed` y `max_force` | Evitan movimiento imposible o tembloroso |
| 3 | Seek | Persecución básica de cualquier IA |
| 4 | Flee | Huida y evasión |
| 5 | Arrive | Llegar a un punto sin rebotar |
| 6 | Wander | Vida ambiental sin destino fijo |
| 7 | Combinar fuerzas | Base de flocking y comportamientos ricos |

## 📖 Definiciones y características

- **Velocidad deseada**: vector que apunta al objetivo con magnitud `max_speed`. Clave: es "a dónde querría ir ahora mismo".
- **Fuerza de dirección (steering)**: `deseada - velocidad_actual`, recortada a `max_force`. Clave: corrige la trayectoria, no la impone de golpe.
- **`max_speed`**: rapidez máxima del agente. Clave: limita la magnitud de `velocity` con `limit_length`.
- **`max_force`**: cuánto puede corregir por frame. Clave: valores altos giran brusco; bajos, con inercia suave.
- **Seek**: buscar; velocidad deseada hacia el objetivo. Clave: sin frenado, orbita el objetivo si no lo detienes.
- **Flee**: huir; velocidad deseada en sentido contrario. Clave: útil dentro de un radio de pánico.
- **Arrive**: llegar; reduce la rapidez deseada dentro de un radio de frenado. Clave: evita el "temblor" al alcanzar el destino.
- **Wander**: deambular; objetivo sobre un círculo delante del agente que se desplaza con ruido. Clave: da un vagar orgánico, no aleatorio brusco.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x** ([godotengine.org](https://godotengine.org)). Crea un proyecto 2D y una escena con un `CharacterBody2D` como agente; dale un `Sprite2D` (o un `Polygon2D` triangular para ver hacia dónde mira) y un `CollisionShape2D`. El agente se moverá con `move_and_slide()`, así que trabajaremos su propiedad `velocity`. Ten a mano la referencia de [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html) y [Vector2](https://docs.godotengine.org/en/stable/classes/class_vector2.html). El objetivo será la posición del mouse (`get_global_mouse_position()`), así que podrás probar todo moviendo el cursor.

## 🧪 Laboratorio guiado

Construiremos un único agente con las cuatro conductas conmutables por tecla, que persigue o huye del mouse.

**Paso 1 — Estructura base y seek.** Adjunta este script al `CharacterBody2D`. El agente busca el mouse.

```gdscript
extends CharacterBody2D

enum Modo { SEEK, FLEE, ARRIVE, WANDER }

@export var max_speed := 300.0
@export var max_force := 800.0
@export var modo: Modo = Modo.SEEK

func _steer_hacia(deseada: Vector2) -> Vector2:
	# Fuerza = velocidad deseada - velocidad actual (recortada)
	return (deseada - velocity).limit_length(max_force)

func seek(objetivo: Vector2) -> Vector2:
	var deseada := (objetivo - global_position).normalized() * max_speed
	return _steer_hacia(deseada)

func _physics_process(delta: float) -> void:
	var objetivo := get_global_mouse_position()
	var fuerza := seek(objetivo)
	velocity = (velocity + fuerza * delta).limit_length(max_speed)
	move_and_slide()
	if velocity.length() > 1.0:
		rotation = velocity.angle()  # mirar hacia donde va
```

**Observable**: el agente persigue el cursor y, al no frenar, lo orbita cuando lo alcanza. Esa órbita es la señal de que falta `arrive`.

**Paso 2 — Flee y arrive.** Añade las dos conductas. `flee` invierte la deseada; `arrive` escala la rapidez dentro de un radio.

```gdscript
@export var radio_frenado := 120.0

func flee(objetivo: Vector2) -> Vector2:
	var deseada := (global_position - objetivo).normalized() * max_speed
	return _steer_hacia(deseada)

func arrive(objetivo: Vector2) -> Vector2:
	var hacia := objetivo - global_position
	var dist := hacia.length()
	var rapidez := max_speed
	if dist < radio_frenado:
		rapidez = max_speed * (dist / radio_frenado)  # frena al acercarse
	var deseada := hacia.normalized() * rapidez
	return _steer_hacia(deseada)
```

**Observable**: con `flee` el agente escapa del cursor; con `arrive` llega al mouse y se detiene suavemente en vez de orbitar.

**Paso 3 — Wander.** El objetivo es un punto sobre un círculo proyectado delante del agente; su ángulo se desplaza con ruido cada frame.

```gdscript
@export var wander_dist := 80.0     # cuán adelante está el círculo
@export var wander_radio := 40.0    # tamaño del círculo
@export var wander_jitter := 4.0    # cuánto varía el ángulo

var _wander_ang := 0.0

func wander() -> Vector2:
	_wander_ang += randf_range(-wander_jitter, wander_jitter) * 0.1
	var dir := velocity.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var centro := global_position + dir * wander_dist
	var desplazamiento := Vector2(cos(_wander_ang), sin(_wander_ang)) * wander_radio
	var deseada := (centro + desplazamiento - global_position).normalized() * max_speed
	return _steer_hacia(deseada)
```

**Observable**: el agente vaga con curvas suaves y giros impredecibles pero no bruscos, como un animal explorando.

**Paso 4 — Conmutar conductas.** Un `match` en `_physics_process` elige la fuerza según `modo`, cambiable por teclado.

```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		modo = (modo + 1) % Modo.size()  # rota entre conductas

func _fuerza_actual() -> Vector2:
	var m := get_global_mouse_position()
	match modo:
		Modo.SEEK: return seek(m)
		Modo.FLEE: return flee(m)
		Modo.ARRIVE: return arrive(m)
		Modo.WANDER: return wander()
	return Vector2.ZERO
```

**Observable**: pulsando la tecla el mismo agente pasa de perseguir a huir, a llegar frenando y a deambular sin reiniciar la escena.

## ✍️ Ejercicios

1. Añade un **radio de pánico** al `flee`: solo huye si el mouse está a menos de 200 px.
2. Combina `wander` + `flee` sumando ambas fuerzas ponderadas para que vague pero evite el cursor.
3. Dibuja con `draw_line` el vector `velocity` y la fuerza de steering para depurar visualmente.
4. Haz que `max_speed` disminuya con una "energía" que se agota al perseguir y se recupera al deambular.
5. Convierte el agente a `CharacterBody3D` reusando la misma lógica con `Vector3`.
6. Implementa **pursue** (perseguir prediciendo la posición futura del objetivo) a partir de `seek`.

## 📝 Reto verificable

Crea una manada de 8 agentes que hacen `wander` por defecto, pero cambian a `flee` cuando el mouse entra en su radio de pánico y vuelven a `wander` al alejarse. Los agentes no deben salir de la pantalla (rebota o envuelve en los bordes).

**Criterio de aceptación**: los 8 agentes se dispersan al acercar el cursor y retoman el vagar al alejarlo, ninguno queda atascado vibrando en un borde, y todas las conductas manipulan `velocity` respetando `max_speed` (ningún agente supera esa rapidez).

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El agente orbita el objetivo sin parar | Usas `seek` donde necesitas `arrive` con radio de frenado |
| Movimiento tembloroso o hiperveloz | No limitas `velocity` con `limit_length(max_speed)` |
| `wander` da giros bruscos aleatorios | Reasignas el ángulo entero en vez de sumar un pequeño jitter |
| El agente no mira hacia donde va | Falta `rotation = velocity.angle()` (y evita hacerlo con velocidad ~0) |
| No se mueve nada | Olvidaste `move_and_slide()` o no asignaste `velocity` |

## ❓ Preguntas frecuentes

**¿Steering es lo mismo que pathfinding?** No. El pathfinding (A*) decide la ruta en un mapa; el steering decide el movimiento suave momento a momento. Suelen combinarse: A* da waypoints y `arrive` los sigue.

**¿Por qué la fuerza es `deseada - velocidad`?** Porque queremos corregir gradualmente hacia la velocidad deseada, dando inercia natural, en vez de teletransportar la velocidad.

**¿Multiplico la fuerza por `delta`?** Sí, al integrarla sobre la velocidad, para que el comportamiento sea independiente de los FPS.

**¿Puedo sumar varias conductas a la vez?** Sí: ese es el flocking. Suma las fuerzas (a veces ponderadas) y luego limita el total a `max_force`.

## 🔗 Referencias

- Craig Reynolds — Steering Behaviors for Autonomous Characters: <https://www.red3d.com/cwr/steer/>
- Godot Docs — CharacterBody2D: <https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html>
- The Nature of Code (Daniel Shiffman) — Autonomous Agents: <https://natureofcode.com/autonomous-agents/>
- Godot Docs — Vector2: <https://docs.godotengine.org/en/stable/classes/class_vector2.html>

## ⬅️ Clase anterior

[Clase 081 - Interpolación y easing (lerp, slerp y tweens)](../081-interpolacion-y-easing-lerp-slerp-y-tweens/README.md)

## ➡️ Siguiente clase

[Clase 083 - Física de partículas y telas (soft bodies)](../083-fisica-de-particulas-y-telas-soft-bodies/README.md)
