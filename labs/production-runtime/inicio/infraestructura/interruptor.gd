class_name Interruptor
extends RefCounted

## Circuit breaker (clase 311).
##
## Cuando un servicio está caído, seguir golpeándolo no ayuda a nadie: ni al
## servicio, que está peor, ni al jugador, que espera el timeout cada vez.
## El interruptor corta, responde al instante desde caché y tantea de vez en
## cuando por si ha vuelto.

enum Estado { CERRADO, ABIERTO, SEMIABIERTO }

var umbral_fallos: int = 5
var espera_reintento: float = 30.0

var _estado: int = Estado.CERRADO
var _fallos: int = 0
var _abierto_desde: float = 0.0


func estado() -> int:
	return _estado


func estado_nombre() -> String:
	return Estado.keys()[_estado]


func fallos() -> int:
	return _fallos


func permite(ahora: float) -> bool:
	match _estado:
		Estado.CERRADO:
			return true
		Estado.ABIERTO:
			if ahora - _abierto_desde >= espera_reintento:
				_estado = Estado.SEMIABIERTO  # dejamos pasar UNA para tantear
				return true
			return false
		_:
			return true


func exito() -> void:
	_estado = Estado.CERRADO
	_fallos = 0


func fallo(ahora: float) -> void:
	_fallos += 1
	if _estado == Estado.SEMIABIERTO or _fallos >= umbral_fallos:
		_estado = Estado.ABIERTO
		_abierto_desde = ahora


func reiniciar() -> void:
	_estado = Estado.CERRADO
	_fallos = 0
	_abierto_desde = 0.0
