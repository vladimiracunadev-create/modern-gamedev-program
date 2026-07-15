extends CharacterBody2D
class_name Enemigo
## Enemigo que patrulla (clase 037) y puede ser derrotado saltándole encima
## (stomp, clase 038). Usa RayCast2D para detectar bordes y paredes.

@export var velocidad: float = 40.0
## Y relativa a partir de la cual se considera que el jugador viene "de arriba".
@export var margen_stomp: float = 6.0

var gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _dir: float = 1.0
var _vivo: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_suelo: RayCast2D = $RaySuelo
@onready var ray_pared: RayCast2D = $RayPared
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	sprite.play("mover")
	hitbox.body_entered.connect(_on_hitbox_body_entered)


func _physics_process(delta: float) -> void:
	if not _vivo:
		return

	if not is_on_floor():
		velocity.y += gravedad * delta

	# Gira si se acaba el suelo delante o si choca con una pared.
	if is_on_floor() and (not ray_suelo.is_colliding() or ray_pared.is_colliding()):
		_girar()

	velocity.x = _dir * velocidad
	move_and_slide()


func _girar() -> void:
	_dir = -_dir
	sprite.flip_h = _dir < 0.0
	# Los raycast miran hacia donde caminamos.
	ray_suelo.position.x = absf(ray_suelo.position.x) * _dir
	ray_pared.target_position.x = absf(ray_pared.target_position.x) * _dir


func _on_hitbox_body_entered(body: Node2D) -> void:
	if not _vivo or not body is Jugador:
		return
	var jugador := body as Jugador
	# Stomp: el jugador viene desde arriba y cayendo.
	var viene_de_arriba: bool = jugador.global_position.y < global_position.y - margen_stomp
	if viene_de_arriba and jugador.velocity.y > 0.0:
		jugador.rebotar()
		_derrotar()
	else:
		jugador.recibir_dano(global_position)


func _derrotar() -> void:
	_vivo = false
	velocity = Vector2.ZERO
	GameState.sumar_puntos(25)
	set_deferred("monitoring", false)
	# Aplastar y desvanecer.
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2(1.3, 0.3), 0.12)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(queue_free)
