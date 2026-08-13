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
	var d: Dictionary = _defs.get(nombre, {})
	if d.is_empty():
		return false  # un flag desconocido está SIEMPRE apagado
	if bool(d["kill"]):
		return false  # el kill switch gana a todo lo demás
	if not bool(d["activo"]):
		return false
	if int(d["porcentaje"]) >= 100:
		return true
	return bucket(str(d["sal"]), _jugador) < int(d["porcentaje"])


static func bucket(sal: String, jugador: StringName) -> int:
	## Determinista y estable. La SAL por flag evita que los mismos
	## desafortunados entren en todos los experimentos a la vez.
	var h := ("%s|%s" % [sal, jugador]).sha256_buffer()
	return ((int(h[0]) << 8) | int(h[1])) % 100
