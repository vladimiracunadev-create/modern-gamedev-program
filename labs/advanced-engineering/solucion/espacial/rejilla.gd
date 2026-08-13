class_name RejillaUniforme
extends RefCounted

## Rejilla uniforme para consultas de proximidad (clase 342).
##
## La primera estructura que hay que probar casi siempre: insertar y consultar
## son O(1), mover cuesta cero cuando no se cambia de celda (el 90 % de las
## veces) y con objetos móviles es muy difícil de superar.

var _celdas := {}
var _tamano_celda: float = 64.0
var _pos_x := PackedFloat32Array()
var _pos_y := PackedFloat32Array()
var _celda_de := {}


func _init(tamano_celda: float) -> void:
	_tamano_celda = tamano_celda


func construir(pos_x: PackedFloat32Array, pos_y: PackedFloat32Array) -> void:
	_pos_x = pos_x
	_pos_y = pos_y
	_celdas.clear()
	_celda_de.clear()
	for i in pos_x.size():
		_insertar(i, pos_x[i], pos_y[i])


func mover(id: int, x: float, y: float) -> bool:
	var nueva := _celda(x, y)
	var vieja: Vector2i = _celda_de.get(id, nueva)
	_pos_x[id] = x
	_pos_y[id] = y
	if nueva == vieja and _celda_de.has(id):
		return false  # no ha cambiado de celda: no hay nada que hacer
	_quitar_de(vieja, id)
	_insertar(id, x, y)
	return true


func consultar_radio(x: float, y: float, r: float) -> PackedInt32Array:
	var salida := PackedInt32Array()
	var min_c := _celda(x - r, y - r)
	var max_c := _celda(x + r, y + r)
	var r2 := r * r
	for cy in range(min_c.y, max_c.y + 1):
		for cx in range(min_c.x, max_c.x + 1):
			var lista: PackedInt32Array = _celdas.get(Vector2i(cx, cy), PackedInt32Array())
			for id in lista:
				# Comprobación EXACTA: la celda es una aproximación, no el
				# resultado. Sin esto se cuelan los objetos de las esquinas.
				var dx := _pos_x[id] - x
				var dy := _pos_y[id] - y
				if dx * dx + dy * dy <= r2:
					salida.append(id)
	salida.sort()
	return salida


static func fuerza_bruta(pos_x: PackedFloat32Array, pos_y: PackedFloat32Array,
		x: float, y: float, r: float) -> PackedInt32Array:
	## Implementación de REFERENCIA: evidentemente correcta y evidentemente
	## lenta. Es el criterio contra el que se compara la rejilla.
	var salida := PackedInt32Array()
	var r2 := r * r
	for i in pos_x.size():
		var dx := pos_x[i] - x
		var dy := pos_y[i] - y
		if dx * dx + dy * dy <= r2:
			salida.append(i)
	return salida


func celdas_ocupadas() -> int:
	return _celdas.size()


func _celda(x: float, y: float) -> Vector2i:
	# floor, no int(): con coordenadas negativas, int() trunca hacia cero y
	# mete en la misma celda puntos que están en celdas distintas.
	return Vector2i(int(floor(x / _tamano_celda)), int(floor(y / _tamano_celda)))


func _insertar(id: int, x: float, y: float) -> void:
	var c := _celda(x, y)
	var lista: PackedInt32Array = _celdas.get(c, PackedInt32Array())
	lista.append(id)
	_celdas[c] = lista
	_celda_de[id] = c


func _quitar_de(c: Vector2i, id: int) -> void:
	if not _celdas.has(c):
		return
	var lista: PackedInt32Array = _celdas[c]
	var i := lista.find(id)
	if i >= 0:
		lista.remove_at(i)
	if lista.is_empty():
		_celdas.erase(c)
	else:
		_celdas[c] = lista
