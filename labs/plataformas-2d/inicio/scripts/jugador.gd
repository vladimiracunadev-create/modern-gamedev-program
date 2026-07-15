extends CharacterBody2D
class_name Jugador
## EJERCICIO PRINCIPAL del laboratorio (clases 030 y 036).
##
## El proyecto arranca tal cual: verás el nivel y al personaje quieto. Tu tarea
## es darle vida. Ve completando los TODO en orden; tras cada uno, ejecuta (F5)
## y comprueba el resultado. La solución de referencia está en ../solucion/.

signal murio

@export_group("Movimiento")
@export var velocidad_max: float = 140.0
@export var aceleracion: float = 900.0
@export var friccion: float = 1200.0

@export_group("Salto")
@export var fuerza_salto: float = 300.0
@export_range(0.0, 1.0) var corte_salto: float = 0.45
@export var coyote_max: float = 0.10
@export var buffer_max: float = 0.10

@export_group("Daño")
@export var rebote_stomp: float = 220.0
@export var invulnerable_tiempo: float = 1.0
@export var empuje_dano: float = 160.0

enum Estado { IDLE, RUN, JUMP, FALL }

var gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var _estado: Estado = Estado.IDLE
var _coyote: float = 0.0
var _buffer: float = 0.0
var _invulnerable: float = 0.0
var _vivo: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_salto: AudioStreamPlayer2D = $SfxSalto
@onready var sfx_dano: AudioStreamPlayer2D = $SfxDano


func _physics_process(delta: float) -> void:
	if not _vivo:
		return
	_temporizadores(delta)
	_aplicar_gravedad(delta)
	_mover_horizontal(delta)
	_gestionar_salto()
	# En Godot 4, move_and_slide() usa 'velocity' y NO recibe argumentos.
	move_and_slide()
	_actualizar_estado()


func _temporizadores(delta: float) -> void:
	# TODO 3 (coyote time): recarga _coyote a coyote_max cuando is_on_floor(),
	#        y si no, réstale delta sin bajar de 0 (usa maxf).
	# TODO 4 (jump buffer): si Input.is_action_just_pressed("jump"), pon
	#        _buffer = buffer_max; si no, réstale delta sin bajar de 0.
	if _invulnerable > 0.0:
		_invulnerable = maxf(_invulnerable - delta, 0.0)
		sprite.visible = fmod(_invulnerable, 0.16) > 0.08
		if _invulnerable == 0.0:
			sprite.visible = true


func _aplicar_gravedad(delta: float) -> void:
	# TODO 1: si NO estamos en el suelo, suma gravedad * delta a velocity.y.
	pass


func _mover_horizontal(delta: float) -> void:
	# TODO 2: lee el eje con Input.get_axis("move_left", "move_right").
	#   - Si el eje != 0: acelera con move_toward(velocity.x, eje * velocidad_max,
	#     aceleracion * delta) y voltea el sprite con sprite.flip_h = eje < 0.0
	#   - Si el eje == 0: frena con move_toward(velocity.x, 0.0, friccion * delta)
	pass


func _gestionar_salto() -> void:
	# TODO 5: salta si _buffer > 0.0 y _coyote > 0.0 →
	#         velocity.y = -fuerza_salto, resetea ambos a 0 y sfx_salto.play()
	# TODO 6 (salto variable): si Input.is_action_just_released("jump") y
	#         velocity.y < 0.0 → velocity.y *= corte_salto
	pass


func _actualizar_estado() -> void:
	# TODO 7: elige el estado según is_on_floor() y velocity, y reproduce la
	#         animación ("idle", "run", "jump", "fall") solo cuando cambie.
	pass


# --- API pública (ya resuelta: la usan el enemigo y el mundo) ------------------
func rebotar() -> void:
	velocity.y = -rebote_stomp
	_buffer = 0.0


func recibir_dano(desde: Vector2) -> void:
	if _invulnerable > 0.0 or not _vivo:
		return
	_invulnerable = invulnerable_tiempo
	var dir: float = signf(global_position.x - desde.x)
	if dir == 0.0:
		dir = 1.0
	velocity = Vector2(dir * empuje_dano, -empuje_dano * 0.6)
	sfx_dano.play()
	GameState.perder_vida()


func morir() -> void:
	if not _vivo:
		return
	_vivo = false
	velocity = Vector2.ZERO
	sprite.visible = true
	murio.emit()
