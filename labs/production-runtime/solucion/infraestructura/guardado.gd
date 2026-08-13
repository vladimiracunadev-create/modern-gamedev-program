class_name GuardadoRuntime
extends RefCounted

## Guardado local con versión y migraciones (clase 307), listo para la nube
## (clase 313): lleva versión, contador de cambios y dispositivo, que son los
## tres campos que necesita la resolución de conflictos.

const SAVE_VERSION := 3
const RUTA := "user://runtime_save.json"

var version_local: int = 0
var dispositivo: String = "dev"

var datos := {"progresion": {"xp": 0}, "ajustes": {}, "monedero": {"oro": 0}}


static func migrar(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 1))
	while v < SAVE_VERSION:
		match v:
			1:
				d = _m1_a_2(d)
			2:
				d = _m2_a_3(d)
			_:
				push_warning("no hay migración de la versión %d" % v)
				return {}
		v += 1
		d["version"] = v
	return d


static func _m1_a_2(d: Dictionary) -> Dictionary:
	## v2 movió los ajustes fuera del bloque de progresión.
	var datos_: Dictionary = d.get("datos", {})
	var prog: Dictionary = datos_.get("progresion", {})
	var ajustes := {}
	for clave in ["volumen", "idioma", "dificultad"]:
		if prog.has(clave):
			ajustes[clave] = prog[clave]
			prog.erase(clave)
	datos_["progresion"] = prog
	datos_["ajustes"] = ajustes
	d["datos"] = datos_
	return d


static func _m2_a_3(d: Dictionary) -> Dictionary:
	## v3 añadió el monedero y los metadatos de sincronización.
	var datos_: Dictionary = d.get("datos", {})
	if not datos_.has("monedero"):
		datos_["monedero"] = {"oro": int(datos_.get("progresion", {}).get("oro", 0))}
		if datos_.get("progresion", {}).has("oro"):
			datos_["progresion"].erase("oro")
	d["datos"] = datos_
	if not d.has("sync"):
		d["sync"] = {"version_local": 1, "base": 0, "dispositivo": "desconocido"}
	return d


func guardar() -> bool:
	version_local += 1
	var payload := {
		"version": SAVE_VERSION,
		"sync": {"version_local": version_local, "base": 0, "dispositivo": dispositivo},
		"datos": datos,
	}
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	return true


func cargar() -> bool:
	if not FileAccess.file_exists(RUTA):
		return false
	var f := FileAccess.open(RUTA, FileAccess.READ)
	var json := JSON.new()
	var texto := f.get_as_text()
	f.close()
	if json.parse(texto) != OK:
		push_warning("save ilegible: %s" % json.get_error_message())
		return false
	var d = json.data
	if typeof(d) != TYPE_DICTIONARY or not d.has("version"):
		return false
	if int(d["version"]) > SAVE_VERSION:
		push_warning("save de una versión futura (%d > %d)" % [int(d["version"]), SAVE_VERSION])
		return false
	d = migrar(d)
	if d.is_empty():
		return false
	datos = d.get("datos", {})
	version_local = int(d.get("sync", {}).get("version_local", 0))
	return true


func borrar() -> void:
	if FileAccess.file_exists(RUTA):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
