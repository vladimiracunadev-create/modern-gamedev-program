extends CharacterBody2D
class_name Jugador
## Controlador de plataformas con buen tacto (game feel).
##
## Implementa lo de la clase 030: aceleración/fricción con move_toward, salto
## variable, coyote time y jump buffer; y la máquina de estados de la 036 para
## elegir la animación.

signal murio

@export_group("Movimiento")
@export var velocidad_max: float = 140.0
@export var aceleracion: float = 900.0
@export var friccion: float = 1200.0

@export_group("Salto")
@export var fuerza_salto: float = 300.0
## Al soltar el botón se recorta la velocidad vertical: salto variable.
@export_range(0.0, 1.0) var corte_salto: float = 0.45
## Margen para saltar justo después de salir de una plataforma.
@export var coyote_max: float = 0.10
## Margen para recordar una pulsación hecha justo antes de aterrizar.
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
	# Coyote: se recarga en el suelo y decrece en el aire.
	if is_on_floor():
		_coyote = coyote_max
	else:
		_coyote = maxf(_coyote - delta, 0.0)

	# Buffer: recuerda la pulsación durante un instante.
	if Input.is_action_just_pressed("jump"):
		_buffer = buffer_max
	else:
		_buffer = maxf(_buffer - delta, 0.0)

	if _invulnerable > 0.0:
		_invulnerable = maxf(_invulnerable - delta, 0.0)
		# Parpadeo mientras dura la invulnerabilidad (i-frames).
		sprite.visible = fmod(_invulnerable, 0.16) > 0.08
		if _invulnerable == 0.0:
			sprite.visible = true


func _aplicar_gravedad(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravedad * delta


func _mover_horizontal(delta: float) -> void:
	var eje: float = Input.get_axis("move_left", "move_right")
	if eje != 0.0:
		velocity.x = move_toward(velocity.x, eje * velocidad_max, aceleracion * delta)
		sprite.flip_h = eje < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friccion * delta)


func _gestionar_salto() -> void:
	# Salta si hay pulsación reciente (buffer) y suelo reciente (coyote).
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = -fuerza_salto
		_buffer = 0.0
		_coyote = 0.0
		sfx_salto.play()
	# Salto variable: al soltar, se corta el impulso restante.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= corte_salto


func _actualizar_estado() -> void:
	var nuevo: Estado
	if not is_on_floor():
		nuevo = Estado.JUMP if velocity.y < 0.0 else Estado.FALL
	elif absf(velocity.x) > 5.0:
		nuevo = Estado.RUN
	else:
		nuevo = Estado.IDLE

	if nuevo == _estado:
		return
	_estado = nuevo
	match _estado:
		Estado.IDLE:
			sprite.play("idle")
		Estado.RUN:
			sprite.play("run")
		Estado.JUMP:
			sprite.play("jump")
		Estado.FALL:
			sprite.play("fall")


# --- API pública --------------------------------------------------------------
func rebotar() -> void:
	## Lo llama el enemigo cuando lo pisamos (stomp).
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
