extends Area2D
## EJERCICIO (clase 039): recolectable.
##
## La moneda ya gira y está en el nivel, pero no hace nada al tocarla.

@export var valor: int = 10

var _recogida: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx: AudioStreamPlayer2D = $Sfx


func _ready() -> void:
	sprite.play("girar")
	# TODO 1: conecta la señal body_entered a _on_body_entered.
	#         Pista: body_entered.connect(_on_body_entered)
	pass


func _on_body_entered(body: Node2D) -> void:
	# TODO 2: si ya está recogida o el cuerpo no es un Jugador, return.
	# TODO 3: marca _recogida, suma puntos con GameState.sumar_puntos(valor)
	#         y reproduce sfx.play().
	# TODO 4 (juice): desactiva la detección con
	#         set_deferred("monitoring", false) y anima la moneda con
	#         create_tween() (sube y desvanece) antes de queue_free().
	pass
