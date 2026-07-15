# Clase 038 — Salud, daño y combate 2D

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4*
> ⏱️ Duración estimada: **100 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Construir un sistema de combate reutilizable en 2D. El núcleo es un **`HealthComponent`**: un nodo con vida, señales `damaged` y `died`, que cualquier entidad puede tener. Sobre él montaremos **hurtbox** (recibe golpes) y **hitbox** (inflige golpes) con `Area2D`, más invulnerabilidad temporal con parpadeo y knockback.

Al terminar, tu enemigo dañará al jugador al tocarlo y el jugador podrá derrotar al enemigo saltándole encima (*stomp*). El componente será desacoplado: la misma pieza sirve para jugador, enemigos y futuros jefes.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diseñar un `HealthComponent` reutilizable con señales `damaged` y `died`.
2. Distinguir hitbox (ofensiva) de hurtbox (defensiva) y conectarlas con capas.
3. Aplicar daño cuando dos áreas colisionan.
4. Implementar i-frames con parpadeo para evitar daño encadenado.
5. Añadir knockback y muerte con `queue_free`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Componente de salud reutilizable | Un solo nodo para todas las entidades vivas. |
| 2 | Señales damaged/died | Desacoplan la salud de la UI y los efectos. |
| 3 | Hitbox vs hurtbox | Separan quién golpea de quién recibe. |
| 4 | Capas y máscaras de combate | Controlan qué hurtbox detecta qué hitbox. |
| 5 | Invulnerabilidad (i-frames) | Evita perder toda la vida en un contacto. |
| 6 | Parpadeo con tween | Da feedback visual del estado invulnerable. |
| 7 | Knockback | Comunica el impacto y separa a los cuerpos. |
| 8 | Stomp (saltar encima) | Da al jugador una forma de vencer sin arma. |

## 📖 Definiciones y características

- **HealthComponent**: nodo que guarda vida actual y máxima y expone `recibir_dano`. Clave: emite señales en vez de tocar la UI directamente.
- **Hitbox**: `Area2D` que representa la parte ofensiva. Clave: su máscara apunta a las hurtbox enemigas.
- **Hurtbox**: `Area2D` que representa la parte vulnerable. Clave: al ser tocada, avisa a su `HealthComponent`.
- **i-frames**: ventana de invulnerabilidad tras recibir daño. Clave: ignora nuevos golpes hasta que expira.
- **Knockback**: empuje aplicado al recibir un golpe. Clave: usa la dirección entre atacante y víctima.
- **Tween**: animación por código creada con `create_tween`. Clave: la usamos para el parpadeo del `modulate`.
- **Stomp**: derrota por pisada al caer sobre el enemigo. Clave: se valida con `velocity.y > 0`.
- **queue_free**: elimina el nodo de forma segura al final del frame. Clave: cierra el ciclo de muerte.

## 🧰 Herramientas y preparación

Usa `PlataformasCurso` con el `Jugador` (clase 036) y el `Enemigo` (clase 037). Define en **Layer Names > 2D Physics** capas de combate, por ejemplo: capa 4 `HurtboxJugador`, capa 5 `HitboxEnemigo`, capa 6 `HitboxJugador`, capa 7 `HurtboxEnemigo`. Repasa `Area2D` y sus señales `area_entered` (<https://docs.godotengine.org/en/stable/classes/class_area2d.html>) y el uso de `create_tween` (<https://docs.godotengine.org/en/stable/classes/class_tween.html>).

Ten claro el principio: una **hitbox** solo tiene su **máscara** activada en la capa de la **hurtbox** que quiere golpear; la hurtbox vive en su propia capa y no necesita máscara.

## 🧪 Laboratorio guiado

Crearemos el componente de salud y lo conectaremos con hitbox y hurtbox.

1. Crea un script independiente `escenas/health_component.gd` con `class_name` para reutilizarlo como nodo. Extiende de `Node`.

```gdscript
class_name HealthComponent
extends Node

signal damaged(cantidad: int, vida_actual: int)
signal died

@export var vida_maxima: int = 3
var vida_actual: int

func _ready() -> void:
	vida_actual = vida_maxima

func recibir_dano(cantidad: int) -> void:
	if vida_actual <= 0:
		return
	vida_actual = max(vida_actual - cantidad, 0)
	damaged.emit(cantidad, vida_actual)
	if vida_actual == 0:
		died.emit()
```

2. En la escena `Jugador`, añade un nodo hijo `Node` y asígnale el script `health_component.gd` (aparecerá como `HealthComponent`). Añade también un `Area2D` llamado `Hurtbox` con su `CollisionShape2D`; ponlo en la capa `HurtboxJugador` sin máscara.

3. En el script del `Jugador`, añade variables de invulnerabilidad y referencias. Conecta las señales del componente en `_ready`.

```gdscript
@onready var salud: HealthComponent = $HealthComponent
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const DURACION_IFRAMES := 1.0
var invulnerable: bool = false

func _ready() -> void:
	salud.damaged.connect(_on_damaged)
	salud.died.connect(_on_died)
```

4. Implementa la recepción de daño con i-frames, parpadeo por tween y knockback. Expón un método que la hitbox enemiga pueda invocar.

```gdscript
func aplicar_dano(cantidad: int, origen: Vector2) -> void:
	if invulnerable:
		return
	salud.recibir_dano(cantidad)
	var dir := sign(global_position.x - origen.x)
	velocity.x = dir * 180.0
	velocity.y = -150.0
	_activar_iframes()

func _activar_iframes() -> void:
	invulnerable = true
	var t := create_tween().set_loops(5)
	t.tween_property(sprite, "modulate:a", 0.2, 0.1)
	t.tween_property(sprite, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(DURACION_IFRAMES).timeout
	invulnerable = false
	sprite.modulate.a = 1.0

func _on_damaged(_cantidad: int, _vida: int) -> void:
	pass

func _on_died() -> void:
	get_tree().reload_current_scene()
```

5. En la escena `Enemigo`, añade un `Area2D` llamado `Hitbox` (capa `HitboxEnemigo`, máscara en `HurtboxJugador`) con su forma. Conéctalo por código para dañar al jugador al solaparse con su hurtbox.

```gdscript
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	# ... conexiones de visión de la clase 037 ...
	hitbox.area_entered.connect(_on_hitbox_area_entered)

func _on_hitbox_area_entered(area: Area2D) -> void:
	var cuerpo := area.get_parent()
	if cuerpo.has_method("aplicar_dano"):
		cuerpo.aplicar_dano(1, global_position)
```

6. Dale vida al enemigo. Añade un `HealthComponent` al `Enemigo`, conéctale `died` para desaparecer, y expón `aplicar_dano` para que el jugador lo derrote.

```gdscript
@onready var salud: HealthComponent = $HealthComponent

func aplicar_dano(cantidad: int, _origen: Vector2) -> void:
	salud.recibir_dano(cantidad)

func _on_died() -> void:
	queue_free()
```

7. Implementa el *stomp* en el jugador. Añade una `Area2D` `PiesHitbox` bajo el personaje (capa `HitboxJugador`, máscara `HurtboxEnemigo`). Al tocar una hurtbox enemiga cayendo, daña al enemigo y rebota.

```gdscript
@onready var pies: Area2D = $PiesHitbox

func _ready() -> void:
	salud.damaged.connect(_on_damaged)
	salud.died.connect(_on_died)
	pies.area_entered.connect(_on_pies_area_entered)

func _on_pies_area_entered(area: Area2D) -> void:
	if velocity.y > 0.0:
		var enemigo := area.get_parent()
		if enemigo.has_method("aplicar_dano"):
			enemigo.aplicar_dano(1, global_position)
			velocity.y = -220.0
```

8. Ejecuta. Al tocar al enemigo de frente pierdes vida, parpadeas y sales despedido; al caerle encima, lo derrotas y rebotas. Conecta `died` del enemigo a un `print` temporal para confirmar la secuencia.

## ✍️ Ejercicios

1. Añade un parámetro `@export var dano` a la hitbox del enemigo en lugar del `1` fijo.
2. Emite una señal `murio(puntos)` desde el enemigo al morir para preparar la puntuación.
3. Reproduce una animación `hurt` durante los i-frames del jugador.
4. Ajusta la fuerza del knockback con un `@export` y prueba distintos valores.
5. Impide el *stomp* si el jugador está invulnerable, para evitar rebotes gratis.
6. Añade un breve *hit stop* (congelar 0.05 s con `Engine.time_scale`) al conectar un golpe.

## 📝 Reto verificable

Crea una escena `Proyectil` (Area2D con hitbox) que el jugador dispare en la dirección en que mira al pulsar una acción `disparar`; el proyectil vuela recto, daña al enemigo al tocar su hurtbox y se elimina al impactar o tras 2 s. **Criterio de aceptación**: al disparar aparece un proyectil que viaja en la dirección correcta, resta vida al enemigo (que muere al llegar a 0), se destruye al impactar y también caduca solo si no golpea nada, sin dañar al propio jugador.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| El jugador pierde toda la vida de golpe | Faltan i-frames; activa `invulnerable` tras el primer impacto. |
| La hitbox no detecta la hurtbox | La máscara de la hitbox no incluye la capa de la hurtbox; revísala. |
| `Invalid call ... aplicar_dano` | El área no es hija directa de la entidad; ajusta `get_parent()` o usa `owner`. |
| El enemigo muere al tocarlo de frente | El *stomp* no valida `velocity.y > 0`; sin caer no debe dañar. |
| El parpadeo se queda a medias | La escena se recarga durante el tween; restaura `modulate.a` en `_ready`. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué un componente y no la vida en el propio jugador?** Porque así el mismo código sirve para enemigos, jefes y objetos destructibles sin duplicarlo, y las señales lo mantienen desacoplado de la UI.

**❓ ¿Uso `area_entered` o `body_entered`?** Para combate hitbox-hurtbox usa `area_entered`: ambos lados son `Area2D`. `body_entered` es para pickups o zonas que detectan cuerpos físicos.

**❓ ¿Los i-frames van en el componente o en la entidad?** En la entidad, porque afectan a su render y física. El componente solo gestiona números de vida y sus señales.

**❓ ¿Cómo evito que la hitbox del enemigo se golpee a sí misma?** Con las capas: la hitbox enemiga solo tiene máscara en la hurtbox del jugador, nunca en la suya.

## 🔗 Referencias

- Godot — Area2D: <https://docs.godotengine.org/en/stable/classes/class_area2d.html>
- Godot — Tween: <https://docs.godotengine.org/en/stable/classes/class_tween.html>
- Godot — Señales: <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#signals>
- Godot — Physics layers and masks: <https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html>

## ⬅️ Clase anterior

[Clase 037 - Enemigos e IA básica 2D: patrullas y persecución](../037-enemigos-e-ia-basica-2d-patrullas-y-persecucion/README.md)

## ➡️ Siguiente clase

[Clase 039 - Recolectables, puntuación y HUD](../039-recolectables-puntuacion-y-hud/README.md)
