# Clase 031 — Sprites, animación por frames y AnimationPlayer

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4*
> ⏱️ Duración estimada: **90 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Hasta ahora tu jugador es un rectángulo (o un sprite estático) que se mueve y salta. En esta clase le damos **vida visual**: aprenderás a animar por cuadros (frames) con `AnimatedSprite2D` y su recurso `SpriteFrames`, creando ciclos de `idle`, `run` y `jump`, y a **sincronizar** la animación reproducida con el estado real del cuerpo (velocidad e `is_on_floor()`).

Además distinguirás las dos herramientas de animación de Godot 4: `AnimatedSprite2D` (ideal para spritesheets de personajes) y `AnimationPlayer` (para animar *cualquier propiedad* por keyframes: escala, posición, modulación). Al final tu personaje corre mirando en la dirección correcta y "aterriza" con un pequeño golpe de escala que se siente jugoso.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Crear un recurso `SpriteFrames` con animaciones `idle`, `run` y `jump`, ajustando FPS y bucle.
2. Reproducir la animación correcta en tiempo de ejecución según la velocidad y el estado en suelo/aire.
3. Voltear el sprite horizontalmente con `flip_h` según la dirección de movimiento.
4. Usar `AnimationPlayer` para animar propiedades (escala, posición) mediante keyframes.
5. Conectar la señal `animation_finished` para encadenar comportamientos al terminar una animación.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | `AnimatedSprite2D` vs `Sprite2D` | El primero reproduce secuencias; el segundo muestra una imagen fija |
| 2 | Recurso `SpriteFrames` | Contenedor de animaciones (frames, FPS, loop) reutilizable |
| 3 | FPS y bucle por animación | Controlan velocidad y si el ciclo se repite (correr sí, saltar no) |
| 4 | `flip_h` y dirección | Reutiliza los mismos frames para mirar izquierda y derecha |
| 5 | Selección de animación por estado | La animación debe reflejar lo que hace el cuerpo, no al revés |
| 6 | `AnimationPlayer` y keyframes | Anima escala/posición/color para *juice* sin dibujar frames |
| 7 | Señal `animation_finished` | Permite encadenar lógica cuando termina un ciclo no-loop |

## 📖 Definiciones y características

- **AnimatedSprite2D**: nodo que reproduce animaciones cuadro a cuadro desde un `SpriteFrames`. Clave: método `play("nombre")` y propiedad `animation`.
- **SpriteFrames**: recurso que agrupa varias animaciones con nombre, cada una con su lista de frames, FPS y flag de bucle. Clave: se edita en el panel *SpriteFrames* del editor.
- **flip_h**: booleano que voltea el sprite en el eje horizontal sin necesitar frames espejo. Clave: cámbialo solo cuando la dirección no sea cero.
- **FPS de animación**: cuadros por segundo de un ciclo. Clave: `run` a 10–12 FPS se ve fluido; `idle` a 4–6 FPS respira.
- **Bucle (loop)**: indica si la animación se reinicia sola. Clave: `idle`/`run` con loop; `jump` normalmente sin loop.
- **AnimationPlayer**: nodo que anima cualquier propiedad de cualquier nodo por keyframes en una línea de tiempo. Clave: crea pistas (*tracks*) de propiedad.
- **Keyframe**: valor de una propiedad en un instante concreto; Godot interpola entre keyframes. Clave: dos keyframes bastan para un *stretch*.
- **animation_finished**: señal emitida por `AnimatedSprite2D` al terminar una animación sin bucle. Clave: útil para transiciones (p. ej. de `jump` a `fall`).

## 🧰 Herramientas y preparación

Necesitas Godot 4.x (recomendado 4.3+) y la escena `Player` de las clases anteriores, con un `CharacterBody2D` que ya se mueve y salta. Para los frames puedes usar una spritesheet libre (por ejemplo de [Kenney](https://kenney.nl/assets) o [OpenGameArt](https://opengameart.org/)) o placeholders. Consulta la documentación de [AnimatedSprite2D](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html) y de [AnimationPlayer](https://docs.godotengine.org/en/stable/tutorials/animation/introduction.html).

## 🧪 Laboratorio guiado

### Paso 1 — Sustituir el sprite por un AnimatedSprite2D

En tu escena `Player` (raíz `CharacterBody2D`), si tienes un `Sprite2D`, bórralo y añade un **AnimatedSprite2D** como hijo. Deja también el `CollisionShape2D`. El árbol queda:

```text
Player (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
└── Camera2D   (si ya la tienes)
```

### Paso 2 — Crear el recurso SpriteFrames

Selecciona el `AnimatedSprite2D`. En el Inspector, en la propiedad **Sprite Frames**, elige *Nuevo SpriteFrames*. Haz clic sobre el recurso para abrir el panel **SpriteFrames** (abajo). Ahí:

1. Renombra la animación `default` a `idle`.
2. Con el botón *Agregar frames desde una spritesheet* (icono de cuadrícula), carga tu imagen, define columnas/filas y selecciona los cuadros del ciclo `idle`. Pon **FPS = 6** y activa **Loop**.
3. Crea una animación `run` (FPS = 10, Loop activado) con sus cuadros.
4. Crea una animación `jump` (FPS = 8, Loop **desactivado**).

### Paso 3 — Script que elige la animación según el estado

Amplía el script del jugador. La idea central: primero mueves el cuerpo, luego eliges la animación a partir de `velocity` e `is_on_floor()`.

```gdscript
extends CharacterBody2D

@export var velocidad: float = 220.0
@export var fuerza_salto: float = 430.0
@export var gravedad: float = 1200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# --- Gravedad ---
	if not is_on_floor():
		velocity.y += gravedad * delta

	# --- Salto ---
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = -fuerza_salto

	# --- Movimiento horizontal ---
	var direccion: float = Input.get_axis("mover_izquierda", "mover_derecha")
	velocity.x = direccion * velocidad

	move_and_slide()

	# --- Animación (después de mover) ---
	actualizar_animacion(direccion)

func actualizar_animacion(direccion: float) -> void:
	# Voltear solo si hay dirección clara
	if direccion > 0.0:
		sprite.flip_h = false
	elif direccion < 0.0:
		sprite.flip_h = true

	# Prioridad: aire > correr > quieto
	if not is_on_floor():
		reproducir("jump")
	elif absf(velocity.x) > 5.0:
		reproducir("run")
	else:
		reproducir("idle")

func reproducir(nombre: String) -> void:
	# Evita reiniciar la animación en cada frame
	if sprite.animation != nombre:
		sprite.play(nombre)
```

> Nota: `reproducir()` comprueba `sprite.animation != nombre` para no reiniciar el ciclo en cada frame (si llamas `play()` sin parar, el frame nunca avanza).

### Paso 4 — Añadir *juice* con AnimationPlayer (golpe al aterrizar)

Añade un nodo **AnimationPlayer** como hijo del `Player`. Crea una animación `aterrizar` de 0.2 s con dos pistas de propiedad sobre `AnimatedSprite2D:scale`:

- t = 0.0 → `scale = (1.3, 0.7)` (aplastado)
- t = 0.2 → `scale = (1.0, 1.0)` (normal)

Luego dispárala cuando el jugador toque suelo tras estar en el aire:

```gdscript
@onready var anim_player: AnimationPlayer = $AnimationPlayer
var estaba_en_aire: bool = false

func _physics_process(delta: float) -> void:
	# ... (código anterior de movimiento) ...
	move_and_slide()

	# Detectar aterrizaje: veníamos del aire y ahora tocamos suelo
	if is_on_floor() and estaba_en_aire:
		anim_player.play("aterrizar")
	estaba_en_aire = not is_on_floor()

	actualizar_animacion(Input.get_axis("mover_izquierda", "mover_derecha"))
```

Ejecuta: al correr verás `run`, al saltar `jump`, y al caer el sprite se aplasta y recupera su forma. Eso es *game feel*.

## ✍️ Ejercicios

1. Añade una animación `fall` distinta a `jump` y reprodúcela cuando `velocity.y > 0` en el aire.
2. Ajusta los FPS de `run` para que el ciclo de piernas coincida con la velocidad real de desplazamiento.
3. Crea una animación `crouch` (agacharse) que se reproduzca al mantener presionada una acción "agacharse".
4. Usa la señal `animation_finished` para pasar automáticamente de `jump` a `fall`.
5. Con `AnimationPlayer`, anima la propiedad `modulate` para que el jugador parpadee en rojo 0.3 s (base de un futuro "recibir daño").
6. Expón `@export var fps_correr: int` y aplícalo con `sprite.sprite_frames.set_animation_speed("run", fps_correr)`.

## 📝 Reto verificable

Implementa un sistema de animación completo con cuatro estados visuales: `idle`, `run`, `jump` (subiendo) y `fall` (cayendo), seleccionados exclusivamente a partir de `velocity` e `is_on_floor()`. El sprite debe voltearse correctamente y no reiniciar su ciclo cada frame.

**Criterio de aceptación**: al jugar, cada estado muestra su animación correcta sin parpadeos ni reinicios; el sprite mira siempre hacia donde se mueve; al subir se ve `jump` y al bajar `fall`; y al aterrizar tras un salto se dispara un efecto de *stretch* con `AnimationPlayer`.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La animación se queda en el primer frame | Llamas a `play()` cada frame; comprueba `sprite.animation != nombre` antes de reproducir |
| `Invalid call. Nonexistent function 'play'` | El `@onready` apunta a un nodo que no es `AnimatedSprite2D`; revisa la ruta `$AnimatedSprite2D` |
| El sprite mira siempre a la derecha | Cambias `flip_h` incluso cuando `direccion == 0`; voltea solo si hay dirección |
| `jump` se repite en bucle infinito | Dejaste **Loop** activado en esa animación; desactívalo en el panel SpriteFrames |
| El efecto de `AnimationPlayer` no se ve | La pista anima una ruta mal escrita; verifica que sea `AnimatedSprite2D:scale` relativa al nodo con el AnimationPlayer |
| Animación "corre" aunque estás quieto | Umbral de velocidad muy bajo; compara `absf(velocity.x) > 5.0` en vez de `!= 0` |

## ❓ Preguntas frecuentes

**❓ ¿Cuándo uso `AnimatedSprite2D` y cuándo `AnimationPlayer`?** Usa `AnimatedSprite2D` para animar personajes por cuadros (spritesheets) y `AnimationPlayer` para animar propiedades (escala, posición, color, incluso llamar funciones). A menudo conviven en el mismo personaje.

**❓ ¿Por qué mi ciclo de correr va demasiado rápido o lento?** El FPS de la animación es independiente de los FPS del juego. Ajústalo por animación en el panel SpriteFrames o en runtime con `set_animation_speed`.

**❓ ¿Puedo tener frames espejo en lugar de `flip_h`?** Sí, pero `flip_h` ahorra memoria y trabajo: reutiliza los mismos cuadros. Solo dibuja frames distintos si la asimetría del personaje lo exige.

**❓ ¿El `AnimationPlayer` puede llamar a mis funciones?** Sí: con una pista de tipo *Call Method* puedes invocar funciones del nodo en instantes concretos de la línea de tiempo, útil para sincronizar sonidos o efectos.

## 🔗 Referencias

- [AnimatedSprite2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html)
- [SpriteFrames — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html)
- [Introducción a la animación (AnimationPlayer) — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/animation/introduction.html)
- [2D sprite animation — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html)

## ➡️ Siguiente clase

[Clase 032 - Cámaras 2D: seguimiento, límites y screen shake](../032-camaras-2d-seguimiento-limites-y-screen-shake/README.md)
