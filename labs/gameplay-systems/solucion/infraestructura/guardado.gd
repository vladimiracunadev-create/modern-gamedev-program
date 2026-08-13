class_name Guardado
extends RefCounted

## Guardado de producción: versión, migraciones, escritura atómica y backups
## (clase 307).
##
## No serializa el árbol de escena: serializa el ESTADO DE DOMINIO que cada
## sistema aporta con su par leer/escribir. Por eso mover un nodo o actualizar
## el motor no rompe ninguna partida.

const SAVE_VERSION := 3
const DIR := "user://saves"
const MAX_BACKUPS := 3

signal guardado_ok(slot: int)
signal guardado_fallo(slot: int, motivo: String)
signal cargado_ok(slot: int, migrado_desde: int)

var _sistemas := {}
var _orden: Array = []


func registrar(clave: String, leer: Callable, escribir: Callable) -> void:
	if not _sistemas.has(clave):
		_orden.append(clave)
	_sistemas[clave] = {"leer": leer, "escribir": escribir}


func sistemas() -> Array:
	return _orden.duplicate()


func limpiar() -> void:
	## Suelta las `Callable` registradas.
	##
	## Cada par leer/escribir está ligado a un objeto (o a una lambda creada
	## dentro del composition root, que captura `self`). Eso hace que el
	## guardado retenga a quien lo creó, y quien lo creó retiene al guardado:
	## un ciclo de referencias que con contado de referencias no se libera
	## nunca (clase 340). Llamar a esto lo rompe.
	_sistemas.clear()
	_orden.clear()


func guardar(slot: int, meta: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)

	var datos := {}
	for clave in _orden:
		datos[clave] = _sistemas[clave]["leer"].call()

	var payload := {"version": SAVE_VERSION, "meta": meta, "datos": datos}
	payload["checksum"] = _checksum(payload)
	var texto := JSON.stringify(payload, "\t")

	# 1) Escribir a un TEMPORAL. Si el juego muere aquí, el save bueno intacto.
	var tmp := _ruta(slot) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		guardado_fallo.emit(slot, "no se pudo abrir el temporal: %d" % FileAccess.get_open_error())
		return false
	f.store_string(texto)
	f.flush()
	f.close()

	# 2) Releer y comprobar ANTES de sustituir: un disco lleno puede haber
	#    escrito la mitad sin dar error.
	var verif := FileAccess.open(tmp, FileAccess.READ)
	if verif == null or verif.get_as_text() != texto:
		if verif != null:
			verif.close()
		DirAccess.remove_absolute(tmp)
		guardado_fallo.emit(slot, "el archivo temporal no se escribió completo")
		return false
	verif.close()

	# 3) Rotar backups y renombrar. El rename es lo único atómico que hay.
	_rotar_backups(slot)
	var dir := DirAccess.open(DIR)
	if FileAccess.file_exists(_ruta(slot)):
		dir.copy(_ruta(slot), _ruta(slot) + ".bak1")
	var err := dir.rename(tmp, _ruta(slot))
	if err != OK:
		guardado_fallo.emit(slot, "no se pudo sustituir el save (error %d)" % err)
		return false

	guardado_ok.emit(slot)
	return true


func cargar(slot: int) -> bool:
	var candidatos: Array = [_ruta(slot)]
	for i in MAX_BACKUPS:
		candidatos.append("%s.bak%d" % [_ruta(slot), i + 1])

	for ruta in candidatos:
		var d := _leer_y_validar(ruta)
		if d.is_empty():
			continue
		var version_original := int(d.get("version", 1))
		if version_original > SAVE_VERSION:
			push_error("save de la versión %d, esta build entiende hasta la %d"
				% [version_original, SAVE_VERSION])
			continue
		d = migrar(d)
		if d.is_empty():
			continue
		_aplicar(d.get("datos", {}))
		if ruta != _ruta(slot):
			push_warning("se ha cargado un backup: el save principal estaba dañado")
		cargado_ok.emit(slot, version_original)
		return true
	return false


func listar_ranuras(maximo: int = 3) -> Array:
	var salida: Array = []
	for slot in maximo:
		var d := _leer_y_validar(_ruta(slot))
		if d.is_empty():
			salida.append({"slot": slot, "vacia": true})
		else:
			var m: Dictionary = d.get("meta", {})
			salida.append({
				"slot": slot, "vacia": false,
				"nivel": int(m.get("nivel", 1)),
				"zona": str(m.get("zona", "")),
				"version": int(d.get("version", 1)),
			})
	return salida


# --------------------------------------------------------------------------
# Migraciones: cada una lleva de la versión N a la N+1 y se aplican EN CADENA.
# Se escriben el mismo día que se cambia el formato, y no se borran nunca.
# --------------------------------------------------------------------------
static func migrar(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 1))
	while v < SAVE_VERSION:
		match v:
			1:
				d = _m1_a_2(d)
			2:
				d = _m2_a_3(d)
			_:
				push_error("no hay migración de la versión %d: el save no se puede cargar" % v)
				return {}
		v += 1
		d["version"] = v
	return d


static func _m1_a_2(d: Dictionary) -> Dictionary:
	## v2 separó el monedero del inventario: antes el oro era un item más.
	var datos: Dictionary = d.get("datos", {})
	var inv: Dictionary = datos.get("inventario", {})
	var ranuras: Dictionary = inv.get("ranuras", {})
	var oro := 0
	for clave in ranuras.keys():
		if str(ranuras[clave].get("id", "")) == "moneda_oro":
			oro += int(ranuras[clave].get("cantidad", 0))
			ranuras.erase(clave)
	inv["ranuras"] = ranuras
	datos["inventario"] = inv
	datos["monedero"] = {"saldos": {"oro": oro, "gemas": 0, "fragmentos": 0}}
	d["datos"] = datos
	return d


static func _m2_a_3(d: Dictionary) -> Dictionary:
	## v3 renombró la habilidad "golpe" a "golpe_pesado" y añadió el bloque
	## de habilidades con valores por defecto.
	var datos: Dictionary = d.get("datos", {})
	var hab: Dictionary = datos.get("habilidades", {"cooldowns": {}, "recursos": {}})
	var cds: Dictionary = hab.get("cooldowns", {})
	if cds.has("golpe"):
		cds["golpe_pesado"] = cds["golpe"]
		cds.erase("golpe")
	hab["cooldowns"] = cds
	if not hab.has("recursos"):
		hab["recursos"] = {"mana": 100.0}
	datos["habilidades"] = hab
	d["datos"] = datos
	return d


func _ruta(slot: int) -> String:
	return "%s/slot_%d.json" % [DIR, slot]


func _rotar_backups(slot: int) -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		return
	for i in range(MAX_BACKUPS, 1, -1):
		var viejo := "%s.bak%d" % [_ruta(slot), i - 1]
		if FileAccess.file_exists(viejo):
			dir.copy(viejo, "%s.bak%d" % [_ruta(slot), i])


func _checksum(payload: Dictionary) -> String:
	var copia: Dictionary = payload.duplicate(true)
	copia.erase("checksum")
	return JSON.stringify(copia).sha256_text()


func _leer_y_validar(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return {}
	var texto := f.get_as_text()
	f.close()
	# `JSON.parse_string` escribe un ERROR en el log cuando el texto no es
	# válido, y aquí un save corrupto es un caso ESPERADO que se recupera del
	# backup. Con `JSON.new().parse()` obtenemos el código de error sin ruido.
	var json := JSON.new()
	if json.parse(texto) != OK:
		push_warning("save ilegible (%s): %s" % [json.get_error_message(), ruta])
		return {}
	var d = json.data
	if typeof(d) != TYPE_DICTIONARY:
		push_warning("save con estructura inesperada: %s" % ruta)
		return {}
	if not d.has("version") or not d.has("datos"):
		push_warning("save sin estructura esperada: %s" % ruta)
		return {}
	if d.has("checksum") and str(d["checksum"]) != _checksum(d):
		push_warning("checksum incorrecto (corrupto o editado): %s" % ruta)
		return {}
	return d


func _aplicar(datos: Dictionary) -> void:
	for clave in _orden:
		# Un sistema NUEVO que no existía en el save recibe {} y aplica sus
		# valores por defecto. Nunca se salta la llamada.
		_sistemas[clave]["escribir"].call(datos.get(clave, {}))
