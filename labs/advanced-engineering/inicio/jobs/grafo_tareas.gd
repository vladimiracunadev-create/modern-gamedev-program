class_name GrafoDeTareas
extends RefCounted

## Task graph con dependencias (clase 341).
##
## Las dependencias son la mitad del problema del paralelismo: no puedes hacer
## culling antes de actualizar las transformadas. El grafo las declara, valida
## que no haya ciclos (un ciclo es un interbloqueo garantizado) y ejecuta por
## niveles.

class Nodo extends RefCounted:
	var nombre: String = ""
	var trabajo: Callable
	var depende_de: Array = []
	var terminado: bool = false


var _nodos := {}
var _orden: Array = []


func agregar(nombre: String, trabajo: Callable, depende_de: Array = []) -> void:
	var n := Nodo.new()
	n.nombre = nombre
	n.trabajo = trabajo
	n.depende_de = depende_de
	_nodos[nombre] = n


func validar() -> Array:
	var errores: Array = []
	for nombre in _nodos:
		for dep in _nodos[nombre].depende_de:
			if not _nodos.has(dep):
				errores.append("'%s' depende de '%s', que no existe" % [nombre, dep])
	errores.append_array(_ordenar())
	return errores


func ejecutar() -> Array:
	## Por NIVELES: todo lo que no depende de nada pendiente va junto; después
	## se espera y se pasa al siguiente nivel.
	var ejecutados: Array = []
	for n in _nodos.values():
		n.terminado = false
	var pendientes := _nodos.keys()
	while not pendientes.is_empty():
		var nivel: Array = []
		for nombre in pendientes:
			var listo := true
			for dep in _nodos[nombre].depende_de:
				if not _nodos.has(dep) or not _nodos[dep].terminado:
					listo = false
			if listo:
				nivel.append(nombre)
		if nivel.is_empty():
			push_warning("el grafo no avanza: revisa las dependencias")
			return ejecutados
		nivel.sort()  # orden estable dentro del nivel: plan reproducible
		for nombre in nivel:
			_nodos[nombre].trabajo.call()
			_nodos[nombre].terminado = true
			ejecutados.append(nombre)
			pendientes.erase(nombre)
	return ejecutados


func _ordenar() -> Array:
	# Kahn: si al terminar quedan nodos sin colocar, hay un ciclo.
	var errores: Array = []
	var entrada := {}
	for n in _nodos:
		entrada[n] = _nodos[n].depende_de.size()
	var listos: Array = _nodos.keys().filter(func(n): return int(entrada[n]) == 0)
	listos.sort()
	_orden.clear()
	while not listos.is_empty():
		var n: String = listos.pop_front()
		_orden.append(n)
		for otro in _nodos:
			if _nodos[otro].depende_de.has(n):
				entrada[otro] = int(entrada[otro]) - 1
				if int(entrada[otro]) == 0:
					listos.append(otro)
					listos.sort()
	if _orden.size() != _nodos.size():
		errores.append("ciclo de dependencias en el grafo de tareas")
	return errores
