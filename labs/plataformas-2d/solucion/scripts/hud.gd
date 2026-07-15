extends CanvasLayer
## HUD (clase 039). Vive en un CanvasLayer para no moverse con la cámara y se
## actualiza SOLO por señales de GameState: nada de leer el estado cada frame.

@onready var lbl_puntos: Label = $Margen/Datos/Puntos
@onready var lbl_vidas: Label = $Margen/Datos/Vidas
@onready var lbl_record: Label = $Margen/Datos/Record
@onready var aviso: Control = $Aviso
@onready var lbl_aviso: Label = $Aviso/Centro/Texto


func _ready() -> void:
	GameState.puntuacion_cambiada.connect(_on_puntuacion_cambiada)
	GameState.vidas_cambiadas.connect(_on_vidas_cambiadas)
	GameState.partida_terminada.connect(_on_partida_terminada)

	aviso.visible = false
	_on_puntuacion_cambiada(GameState.puntuacion)
	_on_vidas_cambiadas(GameState.vidas)


func _on_puntuacion_cambiada(valor: int) -> void:
	lbl_puntos.text = "Puntos: %d" % valor
	lbl_record.text = "Récord: %d" % GameState.record
	# Pequeño "pop" de feedback (clase 193).
	var tw := create_tween()
	tw.tween_property(lbl_puntos, "scale", Vector2(1.15, 1.15), 0.06)
	tw.tween_property(lbl_puntos, "scale", Vector2.ONE, 0.10)


func _on_vidas_cambiadas(valor: int) -> void:
	lbl_vidas.text = "Vidas: %s" % ("♥".repeat(valor) if valor > 0 else "—")


func _on_partida_terminada(victoria: bool) -> void:
	lbl_aviso.text = "¡Has llegado a la meta!\nPuntos: %d\n\nPulsa R para jugar otra vez" % GameState.puntuacion \
		if victoria else "Te has quedado sin vidas\nPuntos: %d\n\nPulsa R para reintentar" % GameState.puntuacion
	aviso.modulate.a = 0.0
	aviso.visible = true
	create_tween().tween_property(aviso, "modulate:a", 1.0, 0.4)
