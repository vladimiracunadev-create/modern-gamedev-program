extends Area2D
## Recolectable (clase 039). Es un Area2D: detecta al jugador y desaparece.

@export var valor: int = 10

var _recogida: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx: AudioStreamPlayer2D = $Sfx


func _ready() -> void:
	sprite.play("girar")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _recogida or not body is Jugador:
		return
	_recogida = true
	GameState.sumar_puntos(valor)
	sfx.play()

	# Feedback: sube y se desvanece; se libera al terminar el tween.
	set_deferred("monitoring", false)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "position:y", sprite.position.y - 12.0, 0.25)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.25)
	# Esperamos también al sonido para no cortarlo al liberar el nodo.
	tw.chain().tween_interval(0.1)
	tw.chain().tween_callback(queue_free)
