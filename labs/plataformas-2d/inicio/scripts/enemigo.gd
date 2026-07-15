extends CharacterBody2D
class_name Enemigo
## EJERCICIO (clases 037 y 038): patrulla y combate por pisotón.
##
## El enemigo ya está en el nivel con sus RayCast2D y su Hitbox configurados,
## pero se queda quieto y no interactúa.

@export var velocidad: float = 40.0
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
	# TODO 1: conecta hitbox.body_entered a _on_hitbox_body_entered.
	pass


func _physics_process(delta: float) -> void:
	if not _vivo:
		return
	# TODO 2: aplica gravedad si no is_on_floor().
	# TODO 3: si is_on_floor() y (no hay suelo delante -> not ray_suelo.is_colliding()
	#         o hay pared -> ray_pared.is_colliding()), llama a _girar().
	# TODO 4: velocity.x = _dir * velocidad y move_and_slide().
	pass


func _girar() -> void:
	# TODO 5: invierte _dir, voltea el sprite (sprite.flip_h = _dir < 0.0) y
	#         reorienta los raycast hacia la nueva dirección:
	#         ray_suelo.position.x = absf(ray_suelo.position.x) * _dir
	#         ray_pared.target_position.x = absf(ray_pared.target_position.x) * _dir
	pass


func _on_hitbox_body_entered(body: Node2D) -> void:
	# TODO 6: si el jugador viene de arriba (su global_position.y es menor que
	#         global_position.y - margen_stomp) Y está cayendo (velocity.y > 0):
	#         jugador.rebotar() y _derrotar(). En caso contrario:
	#         jugador.recibir_dano(global_position).
	pass


func _derrotar() -> void:
	# TODO 7: marca _vivo = false, suma puntos, desactiva la hitbox con
	#         set_deferred("monitoring", false) y anima el aplastado con un
	#         tween antes de queue_free().
	pass
