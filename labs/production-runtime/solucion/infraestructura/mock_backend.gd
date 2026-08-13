class_name MockBackend
extends ProveedorBackend

## Backend simulado y DETERMINISTA (clase 324).
##
## Es la pieza más importante del laboratorio, aunque parezca la menor: un
## backend real no te deja provocar una caída total, ni una respuesta corrupta,
## ni un 503 intermitente al 50 %, y desde luego no de forma reproducible.
## Esto no es una versión pobre del backend: es un instrumento de laboratorio.

enum Modo { NORMAL, LENTO, ERROR_5XX, ERROR_4XX, CAIDO, CORRUPTO, INTERMITENTE }

var modo: int = Modo.NORMAL
var latencia_ms: float = 0.0
var probabilidad_fallo: float = 0.5
var llamadas: int = 0
var eventos_recibidos: int = 0

var _rng := RandomNumberGenerator.new()
var _progreso := {}


func _init(semilla: int = 1234) -> void:
	_rng.seed = semilla


func nombre() -> String:
	return "mock"


func disponible() -> bool:
	return modo != Modo.CAIDO


func modo_nombre() -> String:
	return Modo.keys()[modo]


func obtener_config() -> Respuesta:
	var r := _puerta()
	if r != null:
		return r
	return Respuesta.exito({"valores": {
		"multiplicador_xp": 2.0,
		"intervalo_autosave": 90.0,
		"dificultad_por_defecto": "normal",
	}, "flags": {
		"tienda_online": {"activo": true, "porcentaje": 100, "sal": "v1"},
		"nueva_ui": {"activo": true, "porcentaje": 50, "sal": "v1"},
		"evento_invierno": {"activo": true, "porcentaje": 100, "kill": true},
	}})


func obtener_perfil(id: StringName) -> Respuesta:
	var r := _puerta()
	if r != null:
		return r
	return Respuesta.exito({"player_id": String(id), "nivel": 12, "oro": 340})


func guardar_progreso(id: StringName, datos: Dictionary) -> Respuesta:
	var r := _puerta()
	if r != null:
		return r
	_progreso[id] = datos.duplicate(true)
	return Respuesta.exito({"guardado": true})


func enviar_telemetria(eventos: Array) -> Respuesta:
	var r := _puerta()
	if r != null:
		return r
	eventos_recibidos += eventos.size()
	return Respuesta.exito({"recibidos": eventos.size()})


func _puerta() -> Respuesta:
	## Los modos de fallo, en un solo sitio. Cada uno es un caso que el runtime
	## tiene que sobrevivir sin que el jugador vea un error.
	llamadas += 1
	match modo:
		Modo.CAIDO:
			return Respuesta.fallo("sin conexión")
		Modo.ERROR_5XX:
			return Respuesta.fallo("error del servidor", 503)
		Modo.ERROR_4XX:
			return Respuesta.fallo("no encontrado", 404)
		Modo.CORRUPTO:
			# El modo que más bugs descubre: un 200 con basura dentro. Un
			# cliente que solo comprueba `ok` se lo traga entero.
			var r := Respuesta.exito({"valores": "<<esto no es un diccionario>>"})
			return r
		Modo.INTERMITENTE:
			if _rng.randf() < probabilidad_fallo:
				return Respuesta.fallo("error transitorio", 503)
	return null
