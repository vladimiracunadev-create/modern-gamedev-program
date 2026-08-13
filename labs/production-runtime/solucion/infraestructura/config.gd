class_name Config
extends RefCounted

## Configuración remota con esquema y DEFECTOS COMPILADOS (clase 315).
##
## La regla que gobierna todo: el servicio remoto es una mejora, nunca un
## requisito. Sin red, el juego funciona con los valores por defecto que trae
## el binario; y un valor remoto inválido se rechaza en vez de adoptarse.

signal actualizada(claves: Array)
signal rechazada(clave: String, motivo: String)

const ESQUEMA := {
	"multiplicador_xp": {"tipo": TYPE_FLOAT, "defecto": 1.0, "min": 0.1, "max": 10.0},
	"dano_base_jugador": {"tipo": TYPE_FLOAT, "defecto": 10.0, "min": 1.0, "max": 100.0},
	"precio_pocion": {"tipo": TYPE_INT, "defecto": 15, "min": 1, "max": 10000},
	"intervalo_autosave": {"tipo": TYPE_FLOAT, "defecto": 120.0, "min": 30.0, "max": 900.0},
	"dificultad_por_defecto": {"tipo": TYPE_STRING, "defecto": "normal",
		"opciones": ["facil", "normal", "dificil"]},
}

var permite_override: bool = OS.is_debug_build()

var _remoto := {}
var _override := {}


static func validar_valor(clave: String, valor: Variant) -> String:
	if not ESQUEMA.has(clave):
		return "clave desconocida"
	var d: Dictionary = ESQUEMA[clave]
	var tipo := int(d["tipo"])
	if typeof(valor) != tipo:
		# JSON no distingue int de float: aceptamos el caso compatible y
		# rechazamos el resto.
		if not (tipo == TYPE_FLOAT and typeof(valor) == TYPE_INT):
			return "tipo incorrecto"
	if d.has("min") and float(valor) < float(d["min"]):
		return "por debajo del mínimo"
	if d.has("max") and float(valor) > float(d["max"]):
		return "por encima del máximo"
	if d.has("opciones") and not (d["opciones"] as Array).has(valor):
		return "valor fuera de la lista permitida"
	return ""


func total() -> int:
	return ESQUEMA.size()


func get_valor(clave: String) -> Variant:
	# PRECEDENCIA: override local (solo en debug) > remoto > defecto compilado.
	if permite_override and _override.has(clave):
		return _override[clave]
	if _remoto.has(clave):
		return _remoto[clave]
	return ESQUEMA.get(clave, {}).get("defecto", null)


func get_float(clave: String) -> float:
	return float(get_valor(clave))


func get_int(clave: String) -> int:
	return int(get_valor(clave))


func get_str(clave: String) -> String:
	return str(get_valor(clave))


func origen(clave: String) -> String:
	if permite_override and _override.has(clave):
		return "override"
	if _remoto.has(clave):
		return "remoto"
	return "defecto"


func aplicar_remoto(payload: Dictionary) -> Array:
	var aplicadas: Array = []
	var valores = payload.get("valores", {})
	if typeof(valores) != TYPE_DICTIONARY:
		# Modo CORRUPTO: un 200 con basura dentro. Se rechaza entero y se sigue
		# con los defectos; el juego ni se entera.
		rechazada.emit("(payload)", "la configuración remota no es un objeto")
		return aplicadas
	for clave in valores:
		var motivo := validar_valor(str(clave), valores[clave])
		if motivo != "":
			rechazada.emit(str(clave), motivo)
			continue
		_remoto[str(clave)] = valores[clave]
		aplicadas.append(str(clave))
	if not aplicadas.is_empty():
		actualizada.emit(aplicadas)
	return aplicadas


func forzar(clave: String, valor: Variant) -> bool:
	## Solo existe en builds de desarrollo. En release no tiene ningún efecto,
	## para que un override de QA no pueda llegar a producción.
	if not permite_override:
		return false
	if validar_valor(clave, valor) != "":
		return false
	_override[clave] = valor
	return true
