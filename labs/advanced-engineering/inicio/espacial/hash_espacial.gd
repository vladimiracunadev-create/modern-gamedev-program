class_name HashEspacial
extends RefCounted

## Hashing espacial: rejilla infinita sin reservar el vacío (clase 342).
##
## Para mundos enormes o dispersos, donde una rejilla gastaría memoria en
## celdas que nadie usa.

const P1 := 73856093
const P2 := 19349663

var _cubos := {}
var _n_cubos: int = 4096
var _tamano_celda: float = 64.0
var _pos_x := PackedFloat32Array()
var _pos_y := PackedFloat32Array()


func _init(tamano_celda: float, n_cubos: int = 4096) -> void:
	_tamano_celda = tamano_celda
	_n_cubos = n_cubos


func construir(pos_x: PackedFloat32Array, pos_y: PackedFloat32Array) -> void:
	_pos_x = pos_x
	_pos_y = pos_y
	_cubos.clear()
	for i in pos_x.size():
		var h := _hash(_cx(pos_x[i]), _cy(pos_y[i]))
		var lista: PackedInt32Array = _cubos.get(h, PackedInt32Array())
		lista.append(i)
		_cubos[h] = lista


func consultar_radio(x: float, y: float, r: float) -> PackedInt32Array:
	var salida := PackedInt32Array()
	var vistos := {}
	var r2 := r * r
	for cy in range(_cy(y - r), _cy(y + r) + 1):
		for cx in range(_cx(x - r), _cx(x + r) + 1):
			for id in _cubos.get(_hash(cx, cy), PackedInt32Array()):
				# COLISIÓN DE HASH: dos celdas lejanas pueden caer en el mismo
				# cubo, y un mismo id puede aparecer por dos cubos. Hay que
				# comprobar la posición real Y evitar duplicados.
				if vistos.has(id):
					continue
				vistos[id] = true
				var dx := _pos_x[id] - x
				var dy := _pos_y[id] - y
				if dx * dx + dy * dy <= r2:
					salida.append(id)
	salida.sort()
	return salida


func cubos_ocupados() -> int:
	return _cubos.size()


func _cx(x: float) -> int:
	return int(floor(x / _tamano_celda))


func _cy(y: float) -> int:
	return int(floor(y / _tamano_celda))


func _hash(cx: int, cy: int) -> int:
	return absi((cx * P1) ^ (cy * P2)) % _n_cubos
