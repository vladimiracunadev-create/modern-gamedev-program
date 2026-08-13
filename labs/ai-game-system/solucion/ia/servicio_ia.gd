class_name ServicioIA
extends RefCounted

## Cadena de proveedores con degradación automática (clase 334).
##
## El gameplay solo conoce esto. No aparece "local", "remoto" ni "mock" en
## ninguna parte del juego.

const MAX_FALLOS := 3

signal proveedor_cambiado(nombre: String, motivo: String)

var _cadena: Array = []
var _activo: AIProvider = null
var _fallos_seguidos: int = 0


func configurar(proveedores: Array) -> void:
	## El último SIEMPRE es `SinIA`, para que `completar()` nunca deje al
	## llamador sin una respuesta que manejar.
	_cadena = proveedores
	_activo = _primero_disponible()


func activo() -> String:
	return _activo.nombre() if _activo != null else "ninguno"


func hay_ia() -> bool:
	return _activo != null and _activo.nombre() != "ninguno"


func completar(p: AIProvider.Peticion) -> AIProvider.Respuesta:
	if _activo == null:
		var vacia := AIProvider.Respuesta.new()
		vacia.error = "sin proveedor de IA"
		return vacia

	var r := _activo.completar(p)
	if r.ok:
		_fallos_seguidos = 0
		return r

	_fallos_seguidos += 1
	if _fallos_seguidos >= MAX_FALLOS:
		var anterior := _activo.nombre()
		_activo = _siguiente_disponible(_activo)
		_fallos_seguidos = 0
		proveedor_cambiado.emit(activo(), "%d fallos seguidos de '%s'" % [MAX_FALLOS, anterior])
		if _activo != null:
			return _activo.completar(p)
	return r


func _primero_disponible() -> AIProvider:
	for p in _cadena:
		if p.disponible():
			return p
	return _cadena[_cadena.size() - 1] if not _cadena.is_empty() else null


func _siguiente_disponible(actual: AIProvider) -> AIProvider:
	var i := _cadena.find(actual)
	for j in range(i + 1, _cadena.size()):
		if _cadena[j].disponible():
			return _cadena[j]
	return _cadena[_cadena.size() - 1] if not _cadena.is_empty() else null
