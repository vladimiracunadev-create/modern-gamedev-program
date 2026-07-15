extends Node
## Estado global de la partida (Autoload / singleton).
##
## Se comunica por SEÑALES: el HUD y el mundo escuchan y reaccionan. Nadie
## consulta este nodo cada frame (nada de polling). Ver clases 039 y 043.

signal puntuacion_cambiada(valor: int)
signal vidas_cambiadas(valor: int)
signal partida_terminada(victoria: bool)

const VIDAS_INICIALES: int = 3
const RUTA_GUARDADO: String = "user://save.json"

var puntuacion: int = 0
var vidas: int = VIDAS_INICIALES
var record: int = 0

var _terminada: bool = false


func _ready() -> void:
	cargar()


func reiniciar_partida() -> void:
	puntuacion = 0
	vidas = VIDAS_INICIALES
	_terminada = false
	puntuacion_cambiada.emit(puntuacion)
	vidas_cambiadas.emit(vidas)


func sumar_puntos(cantidad: int) -> void:
	puntuacion += cantidad
	if puntuacion > record:
		record = puntuacion
		guardar()
	puntuacion_cambiada.emit(puntuacion)


func perder_vida() -> void:
	if _terminada:
		return
	vidas = maxi(vidas - 1, 0)
	vidas_cambiadas.emit(vidas)
	if vidas == 0:
		terminar(false)


func terminar(victoria: bool) -> void:
	if _terminada:
		return
	_terminada = true
	partida_terminada.emit(victoria)


func esta_terminada() -> bool:
	return _terminada


# --- Persistencia (clase 043) -------------------------------------------------
func guardar() -> void:
	var f := FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if f == null:
		push_warning("No se pudo guardar (error %d)" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify({"record": record}))


func cargar() -> void:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		return
	var f := FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if f == null:
		return
	# JSON.parse_string devuelve null si el archivo está corrupto: lo toleramos.
	var datos: Variant = JSON.parse_string(f.get_as_text())
	if typeof(datos) == TYPE_DICTIONARY and datos.has("record"):
		record = int(datos["record"])
