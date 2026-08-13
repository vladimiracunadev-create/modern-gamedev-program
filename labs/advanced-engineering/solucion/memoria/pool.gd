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
	var o: Object
	if _libres.is_empty():
		# Crecer en caliente es un fallo de DIMENSIONADO, no algo normal: se
		# registra, porque es exactamente la asignación que queríamos evitar.
		o = _fabrica.call()
		creados += 1
		desbordes += 1
	else:
		o = _libres.pop_back()
	# Se indexa por INSTANCE ID, no por el objeto: dos `Dictionary` con el
	# mismo contenido son la misma clave para un `Dictionary` de Godot, y el
	# pool acabaría creyendo que 10.000 objetos distintos son uno solo. Por eso
	# el pool trabaja con `Object`, que sí tiene identidad propia.
	_en_uso[o.get_instance_id()] = o
	return o


func devolver(o: Object) -> bool:
	if o == null or not _en_uso.has(o.get_instance_id()):
		return false
	_en_uso.erase(o.get_instance_id())
	# Se limpia AL DEVOLVER, no al obtener: así un objeto que está en el pool
	# nunca retiene referencias del uso anterior.
	_resetear.call(o)
	_libres.append(o)
	return true


func en_uso() -> int:
	return _en_uso.size()


func libres() -> int:
	return _libres.size()


func limpiar() -> void:
	_libres.clear()
	_en_uso.clear()
