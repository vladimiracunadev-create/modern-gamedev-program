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
	## TODO (clase 335): normaliza la pregunta (minúsculas, sin acentos, sin
	## signos, sin espacios de más) e incluye en la clave SOLO el estado que
	## cambia la respuesta. Sin normalizar, "¿Dónde está la mina?" y "donde
	## esta la mina" se pagan como dos preguntas distintas — y la tasa de
	## acierto se hunde.
	return "%s|%s" % [npc_id, pregunta]


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
