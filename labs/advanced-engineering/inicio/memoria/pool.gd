class_name PoolObjetos
extends RefCounted

## Pool de objetos (clase 340).
##
## El problema de asignar no es el coste medio, es la VARIANZA: mil
## asignaciones de 100 ns no se notan, pero una que provoca ampliar el heap
## cuesta milisegundos y produce un tirón visible. El pool elimina esa varianza.

var creados: int = 0
var desbordes: int = 0

## Elemento reutilizable de ejemplo. El pool exige `Object` (o derivado)
## porque necesita IDENTIDAD: `Dictionary` y `Array` se comparan por contenido.
class Elemento extends RefCounted:
	var x: float = 0.0
	var y: float = 0.0
	var activo: bool = false

	func reiniciar() -> void:
		x = 0.0
		y = 0.0
		activo = false


var _libres: Array = []
var _en_uso := {}
var _fabrica: Callable
var _resetear: Callable


func _init(fabrica: Callable, resetear: Callable, precrear: int = 0) -> void:
	_fabrica = fabrica
	_resetear = resetear
	for i in precrear:
		_libres.append(_fabrica.call())
		creados += 1


func obtener() -> Object:
	# TODO(2a): esto NO es un pool, es un `new` con otro nombre: nunca reutiliza
	# y nunca registra nada. Saca el objeto de `_libres` si hay alguno; si está
	# vacío, fabrica uno y cuenta el desborde (crecer en caliente es un fallo de
	# dimensionado, no algo normal). Registra el objeto en `_en_uso` indexando
	# por `o.get_instance_id()`, NO por el objeto: Godot compara `Dictionary` y
	# `Array` por contenido, y el pool creería que 10.000 objetos iguales son
	# uno solo.
	var o: Object = _fabrica.call()
	creados += 1
	return o


func devolver(o: Object) -> bool:
	# TODO(2b): rechaza `null` y lo que no esté en `_en_uso`; en otro caso
	# quítalo de `_en_uso`, llama a `_resetear` y devuélvelo a `_libres`.
	# Limpia AL DEVOLVER, no al obtener: así un objeto guardado en el pool nunca
	# retiene referencias del uso anterior.
	return false


func en_uso() -> int:
	return _en_uso.size()


func libres() -> int:
	return _libres.size()


func limpiar() -> void:
	_libres.clear()
	_en_uso.clear()
