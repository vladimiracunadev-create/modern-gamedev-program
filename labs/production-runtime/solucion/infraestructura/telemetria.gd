class_name Telemetria
extends RefCounted

## Telemetría gobernada por taxonomía y consentimiento (clase 317).
##
## La lista blanca no es una política escrita en un documento: es una
## condición del código. Un campo prohibido no se recorta — el evento entero
## se rechaza, porque enviar la mitad de un dato personal sigue siendo enviarlo.

signal evento_rechazado(nombre: String, motivo: String)

## Campos que NUNCA salen del dispositivo, aunque alguien los ponga por error.
const PROHIBIDOS := ["nombre", "email", "correo", "ip", "telefono", "direccion",
	"usuario", "username", "password", "token", "ruta", "path",
	"player_name", "steam_id", "device_id", "lat", "lon"]

const MAX_COLA := 200

var _taxonomia := {}
var _consentimiento := {}
var _cola: Array = []
var _seudonimo: String = ""
var _rng := RandomNumberGenerator.new()


func _init(semilla: int = 99) -> void:
	_rng.seed = semilla
	_seudonimo = _nuevo_seudonimo()
	# Solo "esencial" viene activo. Todo lo demás exige consentimiento
	# explícito, y su valor por defecto es NO.
	_consentimiento = {"esencial": true, "analitica": false, "marketing": false}


func cargar_taxonomia(ruta: String) -> Array:
	if not FileAccess.file_exists(ruta):
		return ["no existe: " + ruta]
	var f := FileAccess.open(ruta, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return ["taxonomía ilegible"]
	_taxonomia = d.get("eventos", {})
	return validar_taxonomia()


func validar_taxonomia() -> Array:
	var errores: Array = []
	for nombre in _taxonomia:
		var e: Dictionary = _taxonomia[nombre]
		if not e.has("v"):
			errores.append("%s: sin versión de evento" % nombre)
		if not e.has("pregunta"):
			errores.append("%s: sin la pregunta que justifica su existencia" % nombre)
		if not e.has("consentimiento"):
			errores.append("%s: sin categoría de consentimiento" % nombre)
		for campo in e.get("campos", {}):
			if str(campo).to_lower() in PROHIBIDOS:
				errores.append("%s: campo prohibido en el esquema: %s" % [nombre, campo])
	return errores


func total_eventos() -> int:
	return _taxonomia.size()


func seudonimo() -> String:
	return _seudonimo


func permite(categoria: String) -> bool:
	return bool(_consentimiento.get(categoria, false))


func fijar_consentimiento(categoria: String, permitido: bool) -> bool:
	if categoria == "esencial":
		return false  # no se puede desactivar, y por eso debe ser mínimo
	if not _consentimiento.has(categoria):
		return false
	_consentimiento[categoria] = permitido
	return true


func registrar(nombre: String, campos: Dictionary = {}) -> bool:
	# 1) El evento debe estar DECLARADO. No hay eventos ad hoc.
	if not _taxonomia.has(nombre):
		evento_rechazado.emit(nombre, "evento no declarado en la taxonomía")
		return false
	var def: Dictionary = _taxonomia[nombre]

	# 2) El consentimiento manda. Si el jugador no lo dio, aquí acaba.
	if not permite(str(def.get("consentimiento", "analitica"))):
		return false

	# 3) LISTA BLANCA de campos, con tipo y rango.
	var limpio := {}
	var esquema: Dictionary = def.get("campos", {})
	for clave in campos:
		if str(clave).to_lower() in PROHIBIDOS:
			evento_rechazado.emit(nombre, "campo prohibido: %s" % clave)
			return false  # se rechaza el evento ENTERO, no se recorta
		if not esquema.has(clave):
			evento_rechazado.emit(nombre, "campo no declarado: %s" % clave)
			continue
		if not _valida_campo(esquema[clave], campos[clave]):
			evento_rechazado.emit(nombre, "campo inválido: %s" % clave)
			continue
		limpio[clave] = campos[clave]

	_cola.append({
		"e": nombre,
		"v": int(def.get("v", 1)),
		"t": 0,
		"sid": _seudonimo,
		"p": limpio,
	})
	if _cola.size() > MAX_COLA:
		_cola.pop_front()  # la cola está acotada: nunca crece sin límite
	return true


func pendientes() -> int:
	return _cola.size()


func cola() -> Array:
	return _cola.duplicate(true)


func vaciar_hacia(backend: ProveedorBackend) -> bool:
	if _cola.is_empty():
		return true
	var r := backend.enviar_telemetria(_cola)
	if not r.ok:
		return false  # se queda en cola: los eventos no se pierden
	_cola.clear()
	return true


func olvidar() -> void:
	## El jugador retira el consentimiento: se rota el seudónimo (los datos
	## futuros ya no se pueden enlazar con los pasados) y se tira la cola.
	_seudonimo = _nuevo_seudonimo()
	_cola.clear()


func _nuevo_seudonimo() -> String:
	# Aleatorio, NO derivado del hardware ni de nada personal: derivarlo lo
	# haría reidentificable y no habríamos seudonimizado nada.
	return "anon_%08x%08x" % [_rng.randi(), _rng.randi()]


func _valida_campo(d: Dictionary, valor: Variant) -> bool:
	match str(d.get("tipo", "")):
		"string":
			if typeof(valor) != TYPE_STRING:
				return false
			if d.has("valores") and not (d["valores"] as Array).has(valor):
				return false
		"int":
			if typeof(valor) != TYPE_INT:
				return false
			if d.has("min") and int(valor) < int(d["min"]):
				return false
			if d.has("max") and int(valor) > int(d["max"]):
				return false
		"bool":
			if typeof(valor) != TYPE_BOOL:
				return false
		_:
			return false
	return true
