# Clase 032 — Cámaras 2D: seguimiento, límites y screen shake

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4*
> ⏱️ Duración estimada: **85 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Un buen juego 2D no se juega "mirando todo el nivel a la vez": la **cámara** decide qué ve el jugador y cómo se siente el movimiento. En esta clase añadirás una `Camera2D` como hija del personaje, con **suavizado** para que no persiga de forma brusca, **límites** para que no muestre el vacío fuera del nivel y un **zoom** ajustado.

Después implementarás uno de los efectos de *juice* más reconocibles: el **screen shake** (sacudida de pantalla). Programarás una función `sacudir(intensidad, duracion)` que mueve el `offset` de la cámara con valores aleatorios que decaen hasta cero, y la dispararás al saltar o aterrizar para dar contundencia a esas acciones.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Configurar una `Camera2D` hija del jugador con `position_smoothing_enabled` y `position_smoothing_speed`.
2. Definir los límites del nivel con `limit_left/right/top/bottom` para acotar la vista.
3. Ajustar el `zoom` de la cámara y entender su efecto en el encuadre.
4. Implementar una función `sacudir(intensidad, duracion)` moviendo el `offset` con decaimiento.
5. Añadir *look-ahead* para adelantar la cámara en la dirección del movimiento.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | `Camera2D` como hija del jugador | La vista sigue al personaje automáticamente |
| 2 | Suavizado de posición | Evita el "tirón" al perseguir y da sensación de peso |
| 3 | Límites del nivel | Impide mostrar el vacío más allá de los bordes |
| 4 | Zoom | Controla cuánto del mundo se ve; afecta legibilidad y tensión |
| 5 | Screen shake vía `offset` | Refuerza impactos, saltos y aterrizajes |
| 6 | Decaimiento del temblor | Un shake que no decae molesta; debe extinguirse suave |
| 7 | Look-ahead | Adelantar la cámara mejora la anticipación al correr |

## 📖 Definiciones y características

- **Camera2D**: nodo que define la porción visible del mundo 2D. Clave: si es la única/activa, se convierte en la vista del juego; hazla hija del jugador para que lo siga.
- **position_smoothing_enabled**: activa el seguimiento suavizado. Clave: sin él la cámara se pega exacta al jugador (brusco).
- **position_smoothing_speed**: velocidad de aproximación del suavizado. Clave: valores bajos (2–5) son perezosos; altos (10+) casi instantáneos.
- **limit_left/right/top/bottom**: bordes en píxeles que la cámara no cruza. Clave: se miden en coordenadas de mundo.
- **zoom**: `Vector2` multiplicador de la vista. Clave: en Godot 4, `zoom` mayor a 1 **acerca** (se ve más grande) y menor a 1 aleja.
- **offset**: desplazamiento de la cámara respecto a su posición. Clave: es donde aplicamos el temblor sin mover el nodo real.
- **Screen shake**: sacudida breve de la cámara para dar impacto. Clave: intensidad decreciente + aleatoriedad = golpe convincente.
- **Look-ahead**: desplazar la mirada hacia donde va el jugador. Clave: mejora la anticipación en plataformas rápidas.

## 🧰 Herramientas y preparación

Parte de la escena `Player` de la clase 031, con su `AnimatedSprite2D`. Necesitas un nivel con algo de extensión horizontal para notar los límites (basta con un suelo largo `StaticBody2D`). Documentación de referencia: [Camera2D](https://docs.godotengine.org/en/stable/classes/class_camera2d.html) y la guía de [cámaras 2D](https://docs.godotengine.org/en/stable/tutorials/2d/2d_transforms.html).

## 🧪 Laboratorio guiado

### Paso 1 — Añadir la cámara al jugador

En la escena `Player`, añade una **Camera2D** como hija del `CharacterBody2D`:

```text
Player (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
└── Camera2D
```

En el Inspector de la `Camera2D`, activa **Position Smoothing → Enabled** y pon **Speed = 6**. Ajusta **Zoom** a `(2, 2)` si tu arte es de pixel-art pequeño.

### Paso 2 — Script de la cámara (suavizado, límites y shake)

Crea un script en la `Camera2D` (`camara_jugador.gd`). Aquí concentramos configuración y la función `sacudir`:

```gdscript
extends Camera2D

@export var suavizado_velocidad: float = 6.0
@export var look_ahead: float = 40.0   # píxeles que se adelanta al correr

var _shake_intensidad: float = 0.0
var _shake_restante: float = 0.0
var _shake_duracion: float = 0.0

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = suavizado_velocidad
	# Límites del nivel (ajústalos a tu escena)
	limit_left = 0
	limit_top = -600
	limit_right = 3000
	limit_bottom = 800

func _process(delta: float) -> void:
	# --- Look-ahead según la velocidad horizontal del padre ---
	var cuerpo := get_parent() as CharacterBody2D
	var objetivo_x: float = 0.0
	if cuerpo and absf(cuerpo.velocity.x) > 5.0:
		objetivo_x = signf(cuerpo.velocity.x) * look_ahead
	# offset base (look-ahead) suavizado
	var base := Vector2(lerp(offset.x, objetivo_x, delta * 4.0), 0.0)

	# --- Screen shake (se suma sobre el offset base) ---
	if _shake_restante > 0.0:
		_shake_restante -= delta
		var t: float = _shake_restante / _shake_duracion   # 1 → 0
		var actual: float = _shake_intensidad * t           # decae linealmente
		base += Vector2(
			randf_range(-actual, actual),
			randf_range(-actual, actual)
		)
	offset = base

func sacudir(intensidad: float, duracion: float) -> void:
	# Solo sobrescribe si la nueva sacudida es más fuerte o ya terminó la anterior
	if intensidad >= _shake_intensidad or _shake_restante <= 0.0:
		_shake_intensidad = intensidad
		_shake_duracion = duracion
		_shake_restante = duracion
```

### Paso 3 — Disparar la sacudida desde el jugador

En el script del jugador, guarda una referencia a la cámara y llama a `sacudir` al saltar y al aterrizar:

```gdscript
@onready var camara: Camera2D = $Camera2D
var estaba_en_aire: bool = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravedad * delta

	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = -fuerza_salto
		camara.sacudir(3.0, 0.12)   # sacudida leve al saltar

	velocity.x = Input.get_axis("mover_izquierda", "mover_derecha") * velocidad
	move_and_slide()

	if is_on_floor() and estaba_en_aire:
		camara.sacudir(6.0, 0.18)   # sacudida más fuerte al aterrizar
	estaba_en_aire = not is_on_floor()
```

### Paso 4 — Probar y afinar

Ejecuta y salta cerca de los bordes del nivel: verás que la cámara **no cruza los límites**, se adelanta al correr (look-ahead) y **tiembla** brevemente al saltar y con más fuerza al aterrizar. Ajusta `suavizado_velocidad`, `look_ahead` e intensidades hasta que se sienta bien. Un shake demasiado largo marea; mantenlo por debajo de 0.25 s para acciones frecuentes.

## ✍️ Ejercicios

1. Añade `@export var shake_maximo: float` y limita (`min`) la intensidad para que ningún efecto exceda ese tope.
2. Sustituye el decaimiento lineal por uno cuadrático (`t * t`) y compara la sensación.
3. Implementa `sacudir` alternativamente con `create_tween()` animando `offset` y compáralo con la versión en `_process`.
4. Haz que el `zoom` se acerque suavemente (con un `Tween`) cuando el jugador está quieto y se aleje al correr.
5. Añade un pequeño temblor continuo y sutil de "cámara viva" (idle sway) usando `sin(tiempo)`.
6. Calcula los límites automáticamente a partir del tamaño del suelo en `_ready()` en lugar de números fijos.

## 📝 Reto verificable

Crea una cámara reutilizable con suavizado, límites de nivel, look-ahead y una función pública `sacudir(intensidad, duracion)` cuyo temblor decaiga a cero. Dispara sacudidas de distinta intensidad al saltar (leve) y al aterrizar (fuerte).

**Criterio de aceptación**: la cámara sigue al jugador sin tirones, nunca muestra el exterior del nivel, se adelanta al correr, y las sacudidas se ven con intensidad proporcional a la acción y se extinguen suavemente sin dejar la cámara "descentrada" (el `offset` vuelve a la base).

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La cámara no sigue al jugador | La `Camera2D` no es la activa o no es hija del jugador; hazla hija y verifica que sea la única activa |
| Todo se ve alejado/diminuto | En Godot 4 el `zoom` funciona al revés que en Godot 3; usa valores > 1 para acercar |
| La pantalla queda temblando para siempre | No decrementas `_shake_restante` o no reinicias `offset` a la base; asegúrate del decaimiento |
| La cámara muestra vacío en los bordes | Límites mal puestos o en 0; ajusta `limit_left/right/top/bottom` al tamaño real del nivel |
| El seguimiento es brusco | `position_smoothing_enabled` desactivado; actívalo y baja `position_smoothing_speed` |
| El shake "empuja" la cámara y no vuelve | Aplicas el temblor sobre `position` en vez de `offset`; usa siempre `offset` |

## ❓ Preguntas frecuentes

**❓ ¿Por qué mover `offset` y no `position`?** El `offset` desplaza la vista sin alterar la posición lógica de la cámara. Así el temblor no interfiere con el seguimiento ni con los límites, y es trivial volver a cero.

**❓ ¿Suavizado en `_process` o `_physics_process`?** El suavizado interno de `Camera2D` ya funciona bien; el look-ahead y el shake visual encajan en `_process` (ligado a frames). Si notas jitter con física, activa además el suavizado físico de la cámara.

**❓ ¿`create_tween` o `_process` para el shake?** Ambos sirven. `_process` da control fino frame a frame; `create_tween` es más declarativo. Para temblores con aleatoriedad por frame, `_process` suele ser más directo.

**❓ ¿Cómo evito que dos sacudidas se pisen?** Compara la intensidad entrante con la actual y quédate con la mayor (como en `sacudir`), o suma intensidades con un tope máximo.

## 🔗 Referencias

- [Camera2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_camera2d.html)
- [Transformaciones 2D y cámaras — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/2d/2d_transforms.html)
- [Tween — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_tween.html)
- [Métodos de aleatoriedad (RandomNumberGenerator) — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/math/random_number_generation.html)

## ⬅️ Clase anterior

[Clase 031 - Sprites, animación por frames y AnimationPlayer](../031-sprites-animacion-por-frames-y-animationplayer/README.md)

## ➡️ Siguiente clase

[Clase 033 - Colisiones 2D: cuerpos, áreas y capas](../033-colisiones-2d-cuerpos-areas-y-capas/README.md)
