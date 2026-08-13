class_name ProveedorBackend
extends RefCounted

## Contrato del backend (clase 311).
##
## El juego solo conoce esta interfaz. Que detrás haya un servicio real, un
## mock determinista o nada en absoluto es una decisión del arranque, y el
## gameplay no se entera.

class Respuesta extends RefCounted:
	var ok: bool = false
	var datos: Dictionary = {}
	var codigo: int = 0
	## De dónde salió el dato. Un valor sin procedencia es una fuente de bugs
	## invisibles: la UI necesita poder decir "esto es de hace dos días".
	var origen: String = "red"
	var error: String = ""

	static func exito(d: Dictionary, origen_: String = "red") -> Respuesta:
		var r := Respuesta.new()
		r.ok = true
		r.datos = d
		r.origen = origen_
		r.codigo = 200
		return r

	static func fallo(motivo: String, codigo_: int = 0) -> Respuesta:
		var r := Respuesta.new()
		r.error = motivo
		r.codigo = codigo_
		return r


func nombre() -> String:
	return "abstracto"


func disponible() -> bool:
	return false


func obtener_config() -> Respuesta:
	return Respuesta.fallo("no implementado")


func obtener_perfil(_id: StringName) -> Respuesta:
	return Respuesta.fallo("no implementado")


func guardar_progreso(_id: StringName, _datos: Dictionary) -> Respuesta:
	return Respuesta.fallo("no implementado")


func enviar_telemetria(_eventos: Array) -> Respuesta:
	return Respuesta.fallo("no implementado")
