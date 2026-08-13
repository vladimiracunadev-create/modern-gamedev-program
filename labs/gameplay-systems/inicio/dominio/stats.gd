class_name Stats
extends RefCounted

## Bloque de estadísticas del personaje (clase 296).

const PRIMARIAS := [&"fuerza", &"constitucion", &"destreza"]
const DERIVADAS_BASE := [&"ataque", &"defensa", &"velocidad",
	&"res_fisico", &"res_fuego", &"res_hielo", &"res_veneno"]

var _stats := {}


func _init() -> void:
	for clave in PRIMARIAS:
		_crear(clave, 10.0)
	for clave in DERIVADAS_BASE:
		_crear(clave, 0.0)


func _crear(clave: StringName, base: float) -> void:
	# Deliberadamente NO se reenvía la señal `cambio` de cada estadística: una
	# lambda que capture `self` haría que la Estadistica retuviera al Stats que
	# la contiene, y eso es un ciclo de referencias que nunca se libera
	# (clase 340). Quien necesite reaccionar se suscribe a la estadística.
	_stats[clave] = Estadistica.new(base)


func existe(clave: StringName) -> bool:
	return _stats.has(clave)


func get_stat(clave: StringName) -> Estadistica:
	assert(_stats.has(clave), "estadística desconocida: %s" % clave)
	return _stats[clave]


func valor(clave: StringName) -> float:
	return get_stat(clave).valor()


func vida_maxima() -> int:
	## DERIVADA: se calcula siempre, nunca se guarda. Si se guardara, cambiar
	## la fórmula en un parche dejaría a los personajes viejos con la vida
	## antigua y sin forma de arreglarlo.
	return int(50.0 + 10.0 * valor(&"constitucion"))


func dano_fisico() -> float:
	return valor(&"ataque") + valor(&"fuerza") * 0.5


func aplicar_efectos(origen: StringName, efectos: Array, escala: float = 1.0) -> int:
	var aplicados := 0
	for e in efectos:
		if str(e.get("tipo", "")) != "modificador":
			continue
		var clave := StringName(str(e.get("stat", "")))
		if not _stats.has(clave):
			push_warning("efecto sobre stat desconocida: %s" % clave)
			continue
		var modo := Estadistica.modo_desde(str(e.get("modo", "plano")))
		get_stat(clave).agregar_mod(origen, modo, float(e.get("valor", 0.0)) * escala)
		aplicados += 1
	return aplicados


func retirar_origen(origen: StringName) -> int:
	var n := 0
	for s in _stats.values():
		n += s.quitar_mods_de(origen)
	return n


func total_modificadores() -> int:
	var n := 0
	for s in _stats.values():
		n += s.n_mods()
	return n


func a_dict() -> Dictionary:
	## Solo las BASES. Los modificadores se reconstruyen al cargar equipo,
	## árbol y efectos: guardarlos duplicaría el estado.
	var bases := {}
	for clave in _stats:
		bases[String(clave)] = _stats[clave].base
	return {"bases": bases}


func de_dict(d: Dictionary) -> void:
	var bases: Dictionary = d.get("bases", {})
	for clave in bases:
		var k := StringName(str(clave))
		if _stats.has(k):
			_stats[k].fijar_base(float(bases[clave]))
