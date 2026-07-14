# Clase 034 — Física 2D: RigidBody, gravedad y plataformas

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4*
> ⏱️ Duración estimada: **100 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

En la clase anterior clasificaste los cuerpos; ahora los pones a **simular física**. Trabajarás con `RigidBody2D` (masa, fricción, rebote, fuerzas e impulsos) para cajas que el jugador empuja, y entenderás la diferencia esencial entre **control directo** (`CharacterBody2D`) y **simulación** (`RigidBody2D`): quién decide el movimiento en cada caso.

Luego construirás dos piezas clásicas de plataformas: una **plataforma de un solo sentido** (one-way, por la que subes desde abajo pero te sostiene desde arriba) y una **plataforma móvil** con `AnimatableBody2D`, que mueve al jugador consigo sin dramas de física. También verás la gravedad global frente a la gravedad por área con `Area2D`.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Configurar un `RigidBody2D` con masa, fricción y rebote, y aplicarle `apply_impulse`.
2. Explicar cuándo usar `CharacterBody2D` (control) frente a `RigidBody2D` (simulación).
3. Crear plataformas de un solo sentido con *one-way collision*.
4. Construir una plataforma móvil con `AnimatableBody2D` que arrastre al jugador.
5. Ajustar la gravedad global y aplicar gravedad por zona con un `Area2D`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | `RigidBody2D` y sus propiedades | Modela objetos que el motor mueve por ti |
| 2 | Fuerzas vs impulsos | Empujar continuo vs golpe instantáneo |
| 3 | Control directo vs simulación | Define quién manda: tu código o el motor |
| 4 | One-way collision | Plataformas atravesables desde abajo |
| 5 | `AnimatableBody2D` | Plataformas móviles que arrastran cuerpos |
| 6 | Gravedad global | Ajuste base de caída para todo el juego |
| 7 | Gravedad por área | Zonas de baja/alta/cero gravedad con `Area2D` |

## 📖 Definiciones y características

- **RigidBody2D**: cuerpo cuyo movimiento simula el motor de física. Clave: no muevas su `position` a mano; aplícale fuerzas o impulsos.
- **mass / physics_material**: masa y material (fricción, rebote). Clave: `PhysicsMaterial` controla `friction` y `bounce`.
- **apply_impulse / apply_force**: impulso (cambio instantáneo de velocidad) vs fuerza (aceleración continua). Clave: impulso para golpes, fuerza para viento constante.
- **CharacterBody2D vs RigidBody2D**: control directo con `velocity` vs simulación completa. Clave: personajes con `CharacterBody2D`; objetos "sueltos" con `RigidBody2D`.
- **One-way collision**: colisión que solo bloquea desde un lado. Clave: se activa en el `CollisionShape2D` con *One Way Collision*.
- **AnimatableBody2D**: cuerpo movido por animación/código que empuja y arrastra otros cuerpos. Clave: ideal para plataformas y puertas móviles.
- **Gravedad global**: valor por defecto en *Project Settings → Physics → 2D*. Clave: afecta a todos los `RigidBody2D`.
- **Gravedad por área**: un `Area2D` con *Gravity* sobreescribe la gravedad dentro de su región. Clave: para zonas especiales.

## 🧰 Herramientas y preparación

Continúa el proyecto de plataformas con tu `Player` y las capas de colisión ya nombradas (clase 033). Necesitarás añadir cajas y plataformas al nivel. Referencias: [RigidBody2D](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html), [AnimatableBody2D](https://docs.godotengine.org/en/stable/classes/class_animatablebody2d.html) y la [introducción a la física 2D](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html).

## 🧪 Laboratorio guiado

### Paso 1 — Una caja RigidBody2D empujable

En la escena del nivel añade un **RigidBody2D** llamado `Caja` con:

- Un `CollisionShape2D` con `RectangleShape2D`.
- Un `Sprite2D` (o un `ColorRect` de placeholder).
- **Mass = 1.5**, y un `PhysicsMaterial` con `friction = 0.8`, `bounce = 0.1`.
- **Collision → Layer**: `World`; **Mask**: `World` (para apoyarse en el suelo).

Para que tu `CharacterBody2D` empuje cajas, activa en el jugador la propiedad **Motion Mode = Grounded** (por defecto) y, tras `move_and_slide()`, empuja los `RigidBody2D` con los que choca:

```gdscript
const FUERZA_EMPUJE: float = 90.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravedad * delta
	velocity.x = Input.get_axis("mover_izquierda", "mover_derecha") * velocidad
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = -fuerza_salto

	move_and_slide()

	# Empujar cajas RigidBody2D con las que colisionamos
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var cuerpo := col.get_collider()
		if cuerpo is RigidBody2D:
			var direccion := -col.get_normal()
			cuerpo.apply_central_impulse(direccion * FUERZA_EMPUJE)
```

### Paso 2 — Un impulso de "explosión" con apply_impulse

Añade una acción `empujar` (por ejemplo tecla E) que lance un impulso a las cajas cercanas hacia arriba y en la dirección en que miras:

```gdscript
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("empujar"):
		for caja in get_tree().get_nodes_in_group("cajas"):
			if caja is RigidBody2D and global_position.distance_to(caja.global_position) < 120.0:
				caja.apply_impulse(Vector2(200, -250))
```

Recuerda añadir cada caja al grupo `cajas`.

### Paso 3 — Plataforma de un solo sentido (one-way)

Añade un **StaticBody2D** llamado `PlataformaOneWay` con un `CollisionShape2D` (rectángulo fino). Selecciona **ese CollisionShape2D** y en el Inspector activa **One Way Collision = On**. La flecha que aparece indica el lado sólido (normalmente hacia arriba): el jugador la atraviesa saltando desde abajo y aterriza sobre ella. Colócala flotando sobre el suelo para probar.

### Paso 4 — Plataforma móvil con AnimatableBody2D

Añade un **AnimatableBody2D** llamado `PlataformaMovil` con su `CollisionShape2D`. Como `AnimatableBody2D` está pensado para moverse por código/animación arrastrando cuerpos, muévela con un `Tween` en bucle:

```gdscript
extends AnimatableBody2D

@export var distancia: Vector2 = Vector2(300, 0)
@export var duracion: float = 2.0

func _ready() -> void:
	var inicio := position
	var t := create_tween().set_loops()
	t.tween_property(self, "position", inicio + distancia, duracion) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "position", inicio, duracion) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
```

Súbete a ella: al ser `AnimatableBody2D`, la plataforma **arrastra** al jugador (que es `CharacterBody2D`) sin que este resbale, siempre que `is_on_floor()` sea verdadero encima de ella.

### Paso 5 — Gravedad por zona con Area2D

Añade un **Area2D** con un `CollisionShape2D` grande. En su Inspector, en **Gravity**, activa *Override* y baja `Gravity` (por ejemplo a 100) o cambia la dirección. Cualquier `RigidBody2D` (una caja) que entre en esa zona flotará o caerá lento. Prueba lanzando una caja dentro.

## ✍️ Ejercicios

1. Crea cajas de distinta `mass` y comprueba cómo cambia cuánto las mueve tu impulso.
2. Dale a una caja un `PhysicsMaterial` con `bounce = 0.8` y observa los rebotes.
3. Haz una plataforma one-way vertical (pared atravesable desde un lado) girando la flecha.
4. Añade una plataforma móvil vertical (ascensor) reutilizando el script con `distancia = (0, -200)`.
5. Crea una `Area2D` de gravedad cero y comprueba que las cajas flotan al entrar.
6. Aplica `apply_torque_impulse` a una caja para que gire al recibir el golpe.

## 📝 Reto verificable

Amplía el nivel con: al menos dos cajas `RigidBody2D` (con masa y material) que el jugador pueda empujar, una plataforma one-way por la que se suba desde abajo, una plataforma móvil `AnimatableBody2D` que arrastre al jugador, y un `Area2D` que modifique la gravedad de las cajas que entren.

**Criterio de aceptación**: las cajas se mueven al empujarlas y responden a un impulso puntual; el jugador atraviesa la plataforma one-way desde abajo y aterriza sobre ella; al pararse sobre la plataforma móvil se desplaza con ella sin resbalar; y las cajas cambian de comportamiento (flotan/caen distinto) dentro del área de gravedad.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La caja no se mueve al chocar | El jugador es `CharacterBody2D` y no aplica fuerza; empuja con `apply_central_impulse` desde `get_slide_collision` |
| El `RigidBody2D` "tiembla" o se hunde | Mueves su `position` por código; deja que lo mueva la física, solo aplica fuerzas/impulsos |
| El jugador resbala sobre la plataforma móvil | Usas `StaticBody2D` en vez de `AnimatableBody2D`; cambia el tipo de cuerpo |
| No puedo subir por la plataforma one-way | La flecha apunta al lado equivocado; invierte *One Way Collision* en el `CollisionShape2D` |
| La caja atraviesa el suelo a alta velocidad | *Tunneling*; activa **Continuous CD** en el `RigidBody2D` |
| El área de gravedad no afecta nada | Falta activar *Override* en Gravity o las cajas no están en su máscara/capa |

## ❓ Preguntas frecuentes

**❓ ¿Por qué mi personaje es `CharacterBody2D` y no `RigidBody2D`?** Porque quieres control fino (aceleración, coyote time, salto variable). La simulación de `RigidBody2D` te quita ese control directo; resérvala para objetos que deben comportarse "físicamente" solos.

**❓ ¿Fuerza o impulso?** El impulso cambia la velocidad al instante (un golpe, un salto). La fuerza acelera de forma continua mientras se aplica (viento, propulsión). No los mezcles sin pensar en las unidades.

**❓ ¿Por qué `AnimatableBody2D` y no animar un `StaticBody2D`?** `AnimatableBody2D` está diseñado para moverse informando al motor de física, de modo que empuja y arrastra otros cuerpos correctamente; un `StaticBody2D` movido a mano no lo hace bien.

**❓ ¿Cómo evito que las cajas vibren al apilarse?** Aumenta la fricción del material, reduce el `bounce`, y considera subir las iteraciones de física en Project Settings si apilas muchas.

## 🔗 Referencias

- [RigidBody2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html)
- [AnimatableBody2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_animatablebody2d.html)
- [Introducción a la física 2D — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html)
- [PhysicsMaterial — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_physicsmaterial.html)

## ➡️ Siguiente clase

[Clase 035 - Tilemaps y diseño de niveles 2D](../035-tilemaps-y-diseno-de-niveles-2d/README.md)
