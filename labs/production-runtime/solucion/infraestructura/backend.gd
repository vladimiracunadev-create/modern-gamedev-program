class_name Backend
extends RefCounted

## Cliente resiliente: reintentos, interruptor, caché y cola (clase 311).
##
## Todo lo remoto pasa por aquí, y aquí se decide qué hacer cuando falla. El
## resto del juego llama y recibe SIEMPRE una respuesta utilizable — de la red,
## de la caché o del valor por defecto.

signal degradado(motivo: String)

const MAX_INTENTOS := 3

var proveedor: ProveedorBackend
var interruptor := Interruptor.new()

var _cache := {}
var _pendientes: Array = []
var _intentos_ultima: int = 0


func _init(p: ProveedorBackend) -> void:
	proveedor = p


func intentos_ultima_operacion() -> int:
	return _intentos_ultima


func pendientes() -> int:
	return _pendientes.size()


func obtener_config(ahora: float) -> ProveedorBackend.Respuesta:
	return _leer(&"config", proveedor.obtener_config, ahora, true)


func obtener_perfil(id: StringName, ahora: float) -> ProveedorBackend.Respuesta:
	return _leer(id, func(): return proveedor.obtener_perfil(id), ahora, true)


func guardar_progreso(id: StringName, datos: Dictionary, ahora: float) -> bool:
	## Escribir NO es idempotente por sí solo, así que no se reintenta a lo
	## loco: si falla, se encola y se reenvía cuando vuelva la conexión.
	if not interruptor.permite(ahora):
		_pendientes.append({"id": id, "datos": datos})
		return false
	var r := proveedor.guardar_progreso(id, datos)
	if r.ok:
		interruptor.exito()
		return true
	interruptor.fallo(ahora)
	_pendientes.append({"id": id, "datos": datos})
	return false


func reenviar_pendientes(ahora: float) -> int:
	var enviados := 0
	for p in _pendientes.duplicate():
		if not interruptor.permite(ahora):
			break
		var r := proveedor.guardar_progreso(p["id"], p["datos"])
		if not r.ok:
			interruptor.fallo(ahora)
			break
		interruptor.exito()
		_pendientes.erase(p)
		enviados += 1
	return enviados


func _leer(clave: StringName, llamada: Callable, ahora: float,
		idempotente: bool) -> ProveedorBackend.Respuesta:
	_intentos_ultima = 0

	if not interruptor.permite(ahora):
		# El interruptor está abierto: respuesta INMEDIATA desde caché, sin
		# esperar un timeout que ya sabemos que va a llegar.
		return _de_cache(clave)

	var intentos := MAX_INTENTOS if idempotente else 1
	for i in intentos:
		_intentos_ultima += 1
		var r: ProveedorBackend.Respuesta = llamada.call()
		if r.ok:
			interruptor.exito()
			_cache[clave] = r.datos
			return r
		# 4xx (salvo 429) es culpa nuestra: reintentar da el mismo error.
		if r.codigo >= 400 and r.codigo < 500 and r.codigo != 429:
			interruptor.fallo(ahora)
			degradado.emit("petición rechazada (%d)" % r.codigo)
			return _de_cache(clave)

	interruptor.fallo(ahora)
	degradado.emit("sin respuesta tras %d intento(s)" % _intentos_ultima)
	return _de_cache(clave)


func _de_cache(clave: StringName) -> ProveedorBackend.Respuesta:
	if _cache.has(clave):
		return ProveedorBackend.Respuesta.exito(_cache[clave], "cache")
	# Ni red ni caché: se devuelve vacío con origen "defecto". Nunca un fallo
	# que el llamador tenga que gestionar con un `if` en cada sitio.
	return ProveedorBackend.Respuesta.exito({}, "defecto")
