class_name BaseDeItems
extends RefCounted

## Catálogo de objetos: carga, indexado y validación (clase 294).

const TIPOS_EFECTO := ["curar", "dano", "modificador", "estado"]

var _por_id := {}


func cargar_desde_json(ruta: String) -> Array:
	var errores: Array = []
	if not FileAccess.file_exists(ruta):
		return ["no existe el catálogo: " + ruta]
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return ["no se pudo abrir el catálogo: " + ruta]
	var datos = JSON.parse_string(f.get_as_text())
	if typeof(datos) != TYPE_DICTIONARY or not datos.has("items"):
		return ["el catálogo no es un objeto con clave 'items': " + ruta]

	for bruto in datos["items"]:
		var def := ItemDefinition.de_dict(bruto)
		if def.id == &"":
			errores.append("item sin id")
			continue
		if _por_id.has(def.id):
			errores.append("id duplicado: %s" % def.id)
			continue
		_por_id[def.id] = def
	return errores


func obtener(id: StringName) -> ItemDefinition:
	## Fallar AQUÍ y con el id en el mensaje es mucho mejor que devolver null
	## y que reviente tres sistemas más allá sin pista de quién lo pidió.
	assert(_por_id.has(id), "item desconocido: %s" % id)
	return _por_id.get(id)


func existe(id: StringName) -> bool:
	return _por_id.has(id)


func todos() -> Array:
	return _por_id.values()


func con_tag(tag: String) -> Array:
	return _por_id.values().filter(func(d): return d.tiene_tag(tag))


func validar() -> Array:
	var errores: Array = []
	for d in _por_id.values():
		var donde := "item '%s'" % d.id
		if not String(d.id).is_valid_identifier():
			errores.append("%s: el id debe ser snake_case sin espacios" % donde)
		if d.nombre.strip_edges() == "":
			errores.append("%s: falta el nombre visible" % donde)
		if d.max_stack < 1:
			errores.append("%s: max_stack debe ser >= 1" % donde)
		if d.tipo == Item.Tipo.ARMA and d.max_stack != 1:
			errores.append("%s: las armas no se apilan (max_stack debe ser 1)" % donde)
		if d.valor < 0:
			errores.append("%s: el valor no puede ser negativo" % donde)
		for e in d.efectos:
			var t := str(e.get("tipo", ""))
			if not TIPOS_EFECTO.has(t):
				errores.append("%s: tipo de efecto desconocido '%s'" % [donde, t])
			elif t in ["curar", "dano"] and int(e.get("valor", 0)) <= 0:
				errores.append("%s: el efecto '%s' necesita un valor positivo" % [donde, t])
	return errores
