# Clase 036 — Máquina de estados del jugador: idle, run, jump, fall

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4*
> ⏱️ Duración estimada: **90 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Reemplazar el controlador del jugador basado en un `if` gigante por una **máquina de estados finitos (FSM)**. Cada estado —`IDLE`, `RUN`, `JUMP`, `FALL`— tendrá su propia lógica de entrada, actualización por frame y salida, con transiciones explícitas entre ellos.

Al terminar, tu `CharacterBody2D` responderá igual que antes pero el código será legible, ampliable y libre de banderas cruzadas. Verás por qué la FSM es el patrón estándar para controlar personajes y cómo aplicarlo tanto con un `enum` simple como comparándolo con la variante basada en nodos.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar por qué un condicional monolítico no escala al crecer el número de estados.
2. Modelar el jugador con un `enum` de estados y una función por estado.
3. Implementar la tríada `enter` / `update` / `exit` para cada estado.
4. Definir transiciones basadas en física (`is_on_floor`, `velocity.y`) e input.
5. Comparar la FSM por `enum` con la FSM por nodos y elegir según el proyecto.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | El problema del `if` gigante | Los estados implícitos generan bugs difíciles de rastrear. |
| 2 | Patrón State aplicado al jugador | Aísla cada comportamiento en una unidad clara. |
| 3 | Estados Idle/Run/Jump/Fall | Cubren el ciclo completo de un plataformas 2D. |
| 4 | Tríada enter/update/exit | Ordena inicialización, lógica y limpieza por estado. |
| 5 | Transiciones explícitas | Hacen visible cuándo y por qué se cambia de estado. |
| 6 | FSM por enum | Simple, rápida y suficiente para un jugador. |
| 7 | FSM por nodos | Escala mejor cuando hay muchos estados complejos. |
| 8 | Integración con animación y física | Cada estado ajusta sprite y `velocity`. |

## 📖 Definiciones y características

- **Máquina de estados finitos (FSM)**: modelo en el que el objeto está en exactamente un estado a la vez. Clave: solo se ejecuta la lógica del estado activo.
- **Estado**: condición nombrada con comportamiento propio (`IDLE`, `RUN`…). Clave: encapsula qué hacer y a qué otros estados puede ir.
- **Transición**: cambio de un estado a otro cuando se cumple una condición. Clave: debe ser explícita y unidireccional en cada paso.
- **enter**: código que corre una vez al entrar al estado. Clave: ideal para lanzar la animación correcta.
- **update**: lógica que corre cada `_physics_process`. Clave: aplica movimiento y evalúa transiciones.
- **exit**: código que corre al salir del estado. Clave: limpia efectos temporales antes de cambiar.
- **enum**: tipo que enumera constantes con nombre. Clave: representa el conjunto de estados de forma segura.
- **match**: estructura de Godot para ramificar por valor. Clave: despacha al bloque del estado activo con claridad.

## 🧰 Herramientas y preparación

Continúa con el proyecto `PlataformasCurso` de clases anteriores. Necesitas la escena `Jugador` (un `CharacterBody2D` con `AnimatedSprite2D` y `CollisionShape2D`) y las acciones de input `mover_izquierda`, `mover_derecha` y `saltar` definidas en **Project Settings > Input Map**. Ten a mano la referencia de `CharacterBody2D` (<https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html>) y la guía sobre `match` en GDScript (<https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#match>).

Si tu `AnimatedSprite2D` aún no tiene las animaciones `idle`, `run`, `jump` y `fall`, créalas en el editor de **SpriteFrames**; pueden ser de un solo cuadro por ahora.

## 🧪 Laboratorio guiado

Refactorizaremos el controlador a una FSM por `enum` con una función por estado.

1. Abre la escena `Jugador` y selecciona el nodo raíz `CharacterBody2D`. Reemplaza su script por el siguiente esqueleto, que declara el `enum` y las variables base.

```gdscript
extends CharacterBody2D

enum Estado { IDLE, RUN, JUMP, FALL }

const VELOCIDAD := 130.0
const FUERZA_SALTO := -320.0
const GRAVEDAD := 900.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var estado: Estado = Estado.IDLE
var direccion: float = 0.0
```

2. Añade `_physics_process`. Su única responsabilidad es leer input, aplicar gravedad, delegar en el estado activo y mover el cuerpo.

```gdscript
func _physics_process(delta: float) -> void:
	direccion = Input.get_axis("mover_izquierda", "mover_derecha")

	if not is_on_floor():
		velocity.y += GRAVEDAD * delta

	match estado:
		Estado.IDLE:
			_estado_idle()
		Estado.RUN:
			_estado_run()
		Estado.JUMP:
			_estado_jump()
		Estado.FALL:
			_estado_fall()

	if direccion != 0.0:
		sprite.flip_h = direccion < 0.0

	move_and_slide()
```

3. Crea la función de transición central. Ejecuta el `exit` implícito, cambia el estado y lanza el `enter` (aquí, la animación correcta).

```gdscript
func _cambiar_estado(nuevo: Estado) -> void:
	if nuevo == estado:
		return
	estado = nuevo
	match estado:
		Estado.IDLE:
			sprite.play("idle")
		Estado.RUN:
			sprite.play("run")
		Estado.JUMP:
			sprite.play("jump")
		Estado.FALL:
			sprite.play("fall")
```

4. Implementa `IDLE` y `RUN`. Ambos están en el suelo: frenan o mueven en horizontal y comparten las transiciones a salto y caída.

```gdscript
func _estado_idle() -> void:
	velocity.x = move_toward(velocity.x, 0.0, VELOCIDAD)
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = FUERZA_SALTO
		_cambiar_estado(Estado.JUMP)
	elif direccion != 0.0:
		_cambiar_estado(Estado.RUN)

func _estado_run() -> void:
	velocity.x = direccion * VELOCIDAD
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = FUERZA_SALTO
		_cambiar_estado(Estado.JUMP)
	elif not is_on_floor():
		_cambiar_estado(Estado.FALL)
	elif direccion == 0.0:
		_cambiar_estado(Estado.IDLE)
```

5. Implementa los estados aéreos `JUMP` y `FALL`. Permiten control horizontal en el aire y transicionan según el signo de `velocity.y` y el aterrizaje.

```gdscript
func _estado_jump() -> void:
	velocity.x = direccion * VELOCIDAD
	if velocity.y >= 0.0:
		_cambiar_estado(Estado.FALL)

func _estado_fall() -> void:
	velocity.x = direccion * VELOCIDAD
	if is_on_floor():
		if direccion != 0.0:
			_cambiar_estado(Estado.RUN)
		else:
			_cambiar_estado(Estado.IDLE)
```

6. Ejecuta la escena. El jugador debería moverse, saltar y caer con la animación adecuada. Añade temporalmente `print(Estado.keys()[estado])` dentro de `_cambiar_estado` para observar las transiciones en la consola de salida.

## ✍️ Ejercicios

1. Añade un estado `WALL_SLIDE` que reduzca la caída al empujar contra una pared (`is_on_wall()`).
2. Introduce un pequeño *coyote time*: permite saltar durante 0.1 s tras dejar el suelo.
3. Extrae los cuatro nombres de animación a un `Dictionary` para evitar el `match` de `_cambiar_estado`.
4. Registra en un `Label` de depuración el estado actual actualizado por frame.
5. Añade un *buffer* de salto: si se pulsa saltar poco antes de aterrizar, salta al tocar suelo.
6. Reescribe la FSM usando un nodo hijo por estado y compara la legibilidad con la versión por `enum`.

## 📝 Reto verificable

Amplía la FSM con un estado `DASH` que impulse al jugador horizontalmente a alta velocidad durante 0.15 s al pulsar una acción `dash`, ignorando el input direccional mientras dura, y que vuelva a `IDLE`, `RUN` o `FALL` al terminar según el contexto. **Criterio de aceptación**: al pulsar `dash` en el suelo el personaje recorre una distancia fija reproduciendo una animación `dash`, no puede encadenar dos dashes sin tocar suelo, y las transiciones de salida son correctas verificadas por consola.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| El personaje "vibra" entre RUN e IDLE | Se evalúan transiciones opuestas el mismo frame; ordena las condiciones y usa `elif`. |
| La animación no cambia al saltar | Olvidaste llamar a `_cambiar_estado`; el `sprite.play` solo ocurre allí. |
| `Invalid get index 'IDLE'` | Usas el nombre como texto; accede con `Estado.IDLE`, no `"IDLE"`. |
| Salta en el aire indefinidamente | Falta la comprobación `is_on_floor()` antes de aplicar `FUERZA_SALTO`. |
| Nunca entra en FALL | No transicionas de JUMP a FALL; compara `velocity.y >= 0.0`. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué separar enter/update/exit si mi estado es simple?** Porque cuando el estado crezca (efectos, sonidos, temporizadores) ya tendrás dónde colocar cada cosa sin reescribir la estructura.

**❓ ¿enum o nodos para la FSM?** Para un jugador con pocos estados el `enum` es más directo. Si prevés decenas de estados con lógica extensa, la variante por nodos aísla mejor cada archivo.

**❓ ¿Dónde aplico la gravedad, en cada estado o fuera?** Fuera, en `_physics_process`, para no repetirla. Los estados solo deciden `velocity.x` y las transiciones.

**❓ ¿Puedo estar en dos estados a la vez?** No: una FSM tiene un único estado activo. Si necesitas capas paralelas (ej. movimiento + ataque), usa dos FSM independientes.

## 🔗 Referencias

- Godot — CharacterBody2D: <https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html>
- Godot — GDScript `match` y `enum`: <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html>
- Godot — Finite State Machine (comunidad): <https://docs.godotengine.org/en/stable/tutorials/scripting/index.html>
- Godot — AnimatedSprite2D: <https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html>

## ⬅️ Clase anterior

[Clase 035 - Tilemaps y diseño de niveles 2D](../035-tilemaps-y-diseno-de-niveles-2d/README.md)

## ➡️ Siguiente clase

[Clase 037 - Enemigos e IA básica 2D: patrullas y persecución](../037-enemigos-e-ia-basica-2d-patrullas-y-persecucion/README.md)
