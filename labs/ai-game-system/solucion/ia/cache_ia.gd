class_name CacheIA
extends RefCounted

## Caché por clave normalizada (clase 335).
##
## Es la optimización con más retorno de toda la parte: en un juego, las
## preguntas se repiten muchísimo más de lo que parece, y cada acierto es
## coste cero **y** latencia cero.

var aciertos: int = 0
var fallos: int = 0

var _memoria := {}


static func clave(npc_id: StringName, pregunta: String, estado: Dictionary) -> String:
	## La NORMALIZACIÓN decide la tasa de acierto. "¿Dónde está la mina?",
	## "donde esta la mina" y "¿Dónde está la mina?  " son la misma pregunta,
	## y pagarla tres veces no tiene ningún sentido.
	var p := BaseDeLore._normalizar(pregunta)

	# Solo entra en la clave el estado que CAMBIA la respuesta. Meter aquí la
	# posición exacta del jugador destruiría la caché sin mejorar nada.
	var relevante := "%s|%s|%s" % [
		str(estado.get("reputacion_umbral", "neutral")),
		str(estado.get("quests_ofrecibles", [])),
		str(estado.get("lugar", "")),
	]
	return "%s|%s|%s" % [npc_id, p.sha256_text().substr(0, 16),
		relevante.sha256_text().substr(0, 8)]


func obtener(c: String) -> String:
	if _memoria.has(c):
		aciertos += 1
		return str(_memoria[c])
	fallos += 1
	return ""


func guardar(c: String, texto: String) -> void:
	_memoria[c] = texto


func tasa_acierto() -> float:
	var total := aciertos + fallos
	return float(aciertos) / maxf(float(total), 1.0)


func entradas() -> int:
	return _memoria.size()
