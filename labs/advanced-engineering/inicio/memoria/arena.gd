class_name Arena
extends RefCounted

## Arena / stack allocator de objetos (clase 340).
##
## Modelo conceptual: en C++ sería un puntero que avanza sobre un bloque; aquí
## es un array preasignado y un cursor. La IDEA es la misma y el patrón de uso
## también: asignar es barato y liberar es TOTAL e instantáneo.

var desbordes: int = 0

var _bloque: Array = []
var _cursor: int = 0
var _capacidad: int = 0


func _init(capacidad: int, fabrica: Callable) -> void:
	_capacidad = capacidad
	_bloque.resize(capacidad)
	for i in capacidad:
		_bloque[i] = fabrica.call()


func capacidad() -> int:
	return _capacidad


func usados() -> int:
	return _cursor


func asignar() -> Variant:
	if _cursor >= _capacidad:
		# La arena NO crece: si desborda, está mal dimensionada y hay que
		# enterarse, no ocultarlo con una asignación silenciosa.
		desbordes += 1
		return null
	var o = _bloque[_cursor]
	_cursor += 1
	return o


func reiniciar() -> void:
	## Liberar TODO cuesta una asignación de entero. Ese es el punto entero.
	_cursor = 0


func marca() -> int:
	return _cursor


func liberar_hasta(m: int) -> void:
	## Stack allocator: liberación en orden inverso mediante marcas.
	_cursor = maxi(0, mini(m, _cursor))
