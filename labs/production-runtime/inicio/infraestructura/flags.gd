class_name Flags
extends RefCounted

## Feature flags con rollout gradual y kill switch (clase 315).
##
## La asignación es DETERMINISTA: el mismo jugador cae siempre en el mismo
## grupo para el mismo flag. Sin eso, un jugador vería la función un día sí y
## otro no, y cualquier medición sería ruido.

var _defs := {}
var _jugador: StringName = &""


func _init(jugador: StringName = &"") -> void:
	_jugador = jugador


func configurar(payload: Dictionary) -> void:
	var flags = payload.get("flags", {})
	if typeof(flags) != TYPE_DICTIONARY:
		return
	for nombre in flags:
		var d: Dictionary = flags[nombre]
		_defs[str(nombre)] = {
			"activo": bool(d.get("activo", false)),
			"porcentaje": clampi(int(d.get("porcentaje", 0)), 0, 100),
			"sal": str(d.get("sal", nombre)),
			"kill": bool(d.get("kill", false)),
		}


func total() -> int:
	return _defs.size()


func conocidos() -> Array:
	return _defs.keys()


func activo(nombre: String) -> bool:
	## TODO (clase 315): resuelve el flag en este orden, que no es casual:
	##   1. Desconocido → apagado (SIEMPRE).
	##   2. `kill` a true → apagado, aunque esté activo y al 100 %.
	##   3. No activo → apagado.
	##   4. Porcentaje >= 100 → encendido.
	##   5. Si no, compara `bucket(sal, jugador)` con el porcentaje.
	var d: Dictionary = _defs.get(nombre, {})
	if d.is_empty():
		return false
	return false


static func bucket(sal: String, jugador: StringName) -> int:
	## TODO (clase 315): devuelve un número de 0 a 99 DETERMINISTA a partir de
	## la sal y del id del jugador. Usa `sha256_buffer()` sobre "sal|jugador":
	## con aleatoriedad, el jugador vería la función un día sí y otro no.
	return 0
