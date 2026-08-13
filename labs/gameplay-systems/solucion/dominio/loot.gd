class_name TablasDeLoot
extends RefCounted

## Tablas de loot ponderadas, anidadas y DETERMINISTAS (clase 300).
##
## El RNG se inyecta: con la misma semilla, el mismo loot. Sin eso, un bug de
## loot reportado por un jugador es irreproducible, y un test es imposible.

var _base: BaseDeItems
var _tablas := {}
var _rng: RandomNumberGenerator


func _init(base: BaseDeItems, rng: RandomNumberGenerator) -> void:
	_base = base
	_rng = rng


func cargar(ruta: String) -> Array:
	if not FileAccess.file_exists(ruta):
		return ["no existe: " + ruta]
	var f := FileAccess.open(ruta, FileAccess.READ)
	var datos = JSON.parse_string(f.get_as_text())
	if typeof(datos) != TYPE_DICTIONARY:
		return ["loot.json ilegible"]
	_tablas = datos.get("tablas", {})
	return validar()


func total() -> int:
	return _tablas.size()


func existe(nombre: StringName) -> bool:
	return _tablas.has(String(nombre))


func tirar(nombre: StringName, contexto: Dictionary = {}, profundidad: int = 0) -> Array:
	var salida: Array = []
	if profundidad > 8:
		push_error("tabla de loot con anidamiento excesivo o cíclico: %s" % nombre)
		return salida
	if not _tablas.has(String(nombre)):
		push_error("tabla de loot desconocida: %s" % nombre)
		return salida

	var t: Dictionary = _tablas[String(nombre)]

	# Los garantizados NO pasan por el sorteo.
	for g in t.get("garantizados", []):
		if _cumple(g, contexto):
			salida.append(ItemStack.new(StringName(str(g["item"])), _cantidad(g)))

	for _i in int(t.get("rolls", 1)):
		var e := _elegir(t.get("entradas", []), contexto)
		if e.is_empty() or bool(e.get("nada", false)):
			continue
		if e.has("tabla"):
			salida.append_array(tirar(StringName(str(e["tabla"])), contexto, profundidad + 1))
		else:
			salida.append(ItemStack.new(StringName(str(e["item"])), _cantidad(e)))

	return _compactar(salida)


func validar() -> Array:
	var errores: Array = []
	for nombre in _tablas:
		var t: Dictionary = _tablas[nombre]
		var entradas: Array = t.get("entradas", [])
		if entradas.is_empty() and (t.get("garantizados", []) as Array).is_empty():
			errores.append("tabla '%s' vacía" % nombre)
		var suma := 0.0
		for e in entradas:
			var peso := float(e.get("peso", 1))
			suma += peso
			if peso <= 0.0:
				errores.append("tabla '%s': peso <= 0" % nombre)
			if e.has("item") and not _base.existe(StringName(str(e["item"]))):
				errores.append("tabla '%s': item inexistente '%s'" % [nombre, e["item"]])
			if e.has("tabla") and not _tablas.has(str(e["tabla"])):
				errores.append("tabla '%s': subtabla inexistente '%s'" % [nombre, e["tabla"]])
			if int(e.get("min", 1)) > int(e.get("max", 1)):
				errores.append("tabla '%s': min > max" % nombre)
		for g in t.get("garantizados", []):
			if not _base.existe(StringName(str(g.get("item", "")))):
				errores.append("tabla '%s': garantizado inexistente '%s'" % [nombre, g.get("item", "")])
		if suma <= 0.0 and not entradas.is_empty():
			errores.append("tabla '%s': suma de pesos 0" % nombre)
	return errores


func _elegir(entradas: Array, contexto: Dictionary) -> Dictionary:
	# Se filtra por condición ANTES de sumar: si no, los pesos de entradas
	# inaccesibles se comen probabilidad y nadie entiende los números.
	var validas := entradas.filter(func(e): return _cumple(e, contexto))
	var total_peso := 0.0
	for e in validas:
		total_peso += maxf(0.0, float(e.get("peso", 1)))
	if total_peso <= 0.0:
		return {}
	var tirada := _rng.randf() * total_peso
	var acumulado := 0.0
	for e in validas:
		acumulado += maxf(0.0, float(e.get("peso", 1)))
		if tirada < acumulado:
			return e
	return validas[validas.size() - 1]


func _cumple(e: Dictionary, contexto: Dictionary) -> bool:
	var c: Dictionary = e.get("condicion", {})
	if c.is_empty():
		return true
	if c.has("nivel_min") and int(contexto.get("nivel", 0)) < int(c["nivel_min"]):
		return false
	if c.has("primera_vez") and not bool(contexto.get("primera_vez", false)):
		return false
	return true


func _cantidad(e: Dictionary) -> int:
	var lo := int(e.get("min", 1))
	var hi := int(e.get("max", lo))
	return _rng.randi_range(mini(lo, hi), maxi(lo, hi))


func _compactar(items: Array) -> Array:
	# Tres tiradas de "5 monedas" llegan al inventario como una de 15.
	var por_id := {}
	for s in items:
		por_id[s.id] = int(por_id.get(s.id, 0)) + s.cantidad
	var salida: Array = []
	for id in por_id:
		salida.append(ItemStack.new(id, int(por_id[id])))
	return salida
