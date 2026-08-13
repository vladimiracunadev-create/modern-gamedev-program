class_name SistemaIA
extends RefCounted

## Composition root del sistema de IA (clase 338).
##
## El proveedor se elige AQUÍ y en ningún otro sitio. Sin variables de entorno
## configuradas, la cadena acaba en `SinIA` y el juego es completo igual: la
## IA es una mejora, nunca un requisito.

var ia := ServicioIA.new()
var lore := BaseDeLore.new()
var cache := CacheIA.new()
var npcs := {}
var errores_arranque: Array = []


static func nuevo(proveedores: Array = []) -> SistemaIA:
	var s := SistemaIA.new()
	s._construir(proveedores)
	return s


func _construir(proveedores: Array) -> void:
	errores_arranque.append_array(lore.cargar("res://datos/lore/mundo.json"))
	errores_arranque.append_array(_cargar_npcs("res://datos/npcs.json"))

	var cadena: Array = proveedores.duplicate()
	# Un proveedor remoto SOLO si está configurado. Nunca es obligatorio, y
	# nunca lleva una clave dentro del cliente.
	if OS.get_environment("MIJUEGO_IA_URL") != "":
		push_warning("MIJUEGO_IA_URL definida: el proveedor remoto no está "
			+ "implementado en el laboratorio (clase 334). Se ignora.")
	# El último SIEMPRE es SinIA.
	cadena.append(Proveedores.SinIA.new())
	ia.configurar(cadena)


func npc(id: StringName) -> NPCSeguro:
	var identidad: Dictionary = npcs.get(id, {})
	assert(not identidad.is_empty(), "NPC desconocido: %s" % id)
	return NPCSeguro.new(identidad, ia, lore, cache)


func hay_ia() -> bool:
	return ia.hay_ia()


func arranco() -> bool:
	return errores_arranque.is_empty()


func _cargar_npcs(ruta: String) -> Array:
	if not FileAccess.file_exists(ruta):
		return ["no existe: " + ruta]
	var f := FileAccess.open(ruta, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return ["npcs.json ilegible"]
	var errores: Array = []
	for n in d.get("npcs", []):
		var id := StringName(str(n.get("id", "")))
		if id == &"":
			errores.append("npc sin id")
			continue
		if not n.has("fallbacks"):
			errores.append("%s: sin fallbacks escritos a mano" % id)
		if not n.has("capacidades"):
			errores.append("%s: sin capacidades declaradas" % id)
		npcs[id] = n
	return errores
