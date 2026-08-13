class_name Estadistica
extends RefCounted

## Estadística con modificadores (clase 296).
##
## La clave está en que `valor()` es una FUNCIÓN PURA de `base` y de la lista
## de modificadores. No se muta un número al equipar y se resta al desequipar:
## se añade y se quita un modificador, y el valor se recalcula. Eso elimina
## de golpe toda la familia de bugs de "se quedó pegado".

enum Modo { PLANO, PORCENTUAL, MULTIPLICATIVO }

signal cambio(nuevo: float)

var base: float = 0.0

var _mods: Array = []
var _cache: float = 0.0
var _sucio: bool = true


func _init(base_: float = 0.0) -> void:
	base = base_


static func modo_desde(nombre: String) -> Modo:
	match nombre:
		"porcentual":
			return Modo.PORCENTUAL
		"multiplicativo":
			return Modo.MULTIPLICATIVO
		_:
			return Modo.PLANO


func fijar_base(v: float) -> void:
	## Cambiar `base` directamente dejaría la caché sucia sin invalidar. Toda
	## escritura pasa por aquí: es la única forma de que la caché sea correcta.
	base = v
	_invalidar()


func agregar_mod(origen: StringName, modo: Modo, valor_mod: float) -> void:
	_mods.append({"origen": origen, "modo": modo, "valor": valor_mod})
	_invalidar()


func quitar_mods_de(origen: StringName) -> int:
	## Se retira por ORIGEN, no por valor: dos items pueden dar +7 y hay que
	## quitar el del item correcto.
	var antes := _mods.size()
	_mods = _mods.filter(func(m): return m["origen"] != origen)
	if _mods.size() != antes:
		_invalidar()
	return antes - _mods.size()


func n_mods() -> int:
	return _mods.size()


func valor() -> float:
	if _sucio:
		_cache = _calcular()
		_sucio = false
	return _cache


func _calcular() -> float:
	var v := base
	# 1) Planos: suman al base.
	for m in _mods:
		if m["modo"] == Modo.PLANO:
			v += float(m["valor"])
	# 2) Porcentuales: se SUMAN entre ellos y se aplican una vez.
	var pct := 0.0
	for m in _mods:
		if m["modo"] == Modo.PORCENTUAL:
			pct += float(m["valor"])
	v *= 1.0 + pct
	# 3) Multiplicativos: se componen. Aquí nacen las builds rotas.
	for m in _mods:
		if m["modo"] == Modo.MULTIPLICATIVO:
			v *= float(m["valor"])
	return maxf(0.0, v)


func _invalidar() -> void:
	_sucio = true
	cambio.emit(valor())
