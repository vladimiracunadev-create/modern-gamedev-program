class_name Inventario
extends RefCounted

## Inventario por ranuras con operaciones atómicas (clase 295).
##
## No extiende Node y no conoce la UI: emite señales y expone consultas. Por
## eso se puede probar headless en milisegundos y reutilizar tal cual en un
## cofre, una tienda o el inventario de un NPC.

signal ranura_cambiada(indice: int)
signal inventario_lleno(id: StringName, restante: int)

var _base: BaseDeItems
var _ranuras: Array = []


func _init(base: BaseDeItems, capacidad: int) -> void:
	_base = base
	_ranuras.resize(maxi(1, capacidad))


func capacidad() -> int:
	return _ranuras.size()


func ranura(i: int) -> ItemStack:
	return _ranuras[i] if _valido(i) else null


func libres() -> int:
	return _ranuras.count(null)


func contar(id: StringName) -> int:
	var n := 0
	for s in _ranuras:
		if s != null and s.id == id:
			n += s.cantidad
	return n


func cabe(id: StringName, cantidad: int) -> int:
	## Consulta pura: no muta nada. Es lo que hace posible la atomicidad.
	if cantidad <= 0 or not _base.existe(id):
		return 0
	var tope: int = _base.obtener(id).max_stack
	var hueco := 0
	for s in _ranuras:
		if s == null:
			hueco += tope
		elif s.id == id:
			hueco += tope - s.cantidad
		if hueco >= cantidad:
			return cantidad
	return hueco


func agregar(id: StringName, cantidad: int) -> int:
	## Añade lo que pueda y devuelve el RESTANTE. Descartarlo en silencio es
	## la forma más común de que un jugador pierda objetos.
	if cantidad <= 0 or not _base.existe(id):
		return cantidad
	var tope: int = _base.obtener(id).max_stack
	var quedan := cantidad

	# Fase 1: completar stacks parciales, para no fragmentar el inventario.
	for i in _ranuras.size():
		if quedan == 0:
			break
		var s: ItemStack = _ranuras[i]
		if s != null and s.id == id and s.cantidad < tope:
			var mete: int = mini(tope - s.cantidad, quedan)
			s.cantidad += mete
			quedan -= mete
			ranura_cambiada.emit(i)

	# Fase 2: ocupar ranuras vacías.
	for i in _ranuras.size():
		if quedan == 0:
			break
		if _ranuras[i] == null:
			var mete: int = mini(tope, quedan)
			_ranuras[i] = ItemStack.new(id, mete)
			quedan -= mete
			ranura_cambiada.emit(i)

	if quedan > 0:
		inventario_lleno.emit(id, quedan)
	return quedan


func agregar_todo_o_nada(id: StringName, cantidad: int) -> bool:
	if cabe(id, cantidad) < cantidad:
		return false
	var restante := agregar(id, cantidad)
	assert(restante == 0, "cabe() y agregar() discrepan: hay un bug en uno de los dos")
	return restante == 0


func quitar(id: StringName, cantidad: int) -> bool:
	if cantidad <= 0 or contar(id) < cantidad:
		return false
	var quedan := cantidad
	for i in range(_ranuras.size() - 1, -1, -1):
		if quedan == 0:
			break
		var s: ItemStack = _ranuras[i]
		if s != null and s.id == id:
			var saca: int = mini(s.cantidad, quedan)
			s.cantidad -= saca
			quedan -= saca
			if s.cantidad <= 0:
				# Una ranura vacía es `null`, nunca un stack de 0: si no, la UI
				# pinta iconos fantasma y el save se llena de ruido.
				_ranuras[i] = null
			ranura_cambiada.emit(i)
	return true


func mover(desde: int, hasta: int) -> bool:
	if desde == hasta or not _valido(desde) or not _valido(hasta):
		return false
	var a: ItemStack = _ranuras[desde]
	if a == null:
		return false
	var b: ItemStack = _ranuras[hasta]

	if b == null:
		_ranuras[hasta] = a
		_ranuras[desde] = null
	elif b.id == a.id:
		var tope: int = _base.obtener(a.id).max_stack
		var pasa: int = mini(tope - b.cantidad, a.cantidad)
		b.cantidad += pasa
		a.cantidad -= pasa
		if a.cantidad == 0:
			_ranuras[desde] = null  # el sobrante SE QUEDA en el origen
	else:
		_ranuras[hasta] = a
		_ranuras[desde] = b

	ranura_cambiada.emit(desde)
	ranura_cambiada.emit(hasta)
	return true


func partir(indice: int, cantidad: int) -> bool:
	var s: ItemStack = ranura(indice)
	if s == null or cantidad <= 0 or cantidad >= s.cantidad:
		return false
	var hueco := _ranuras.find(null)
	if hueco == -1:
		return false
	s.cantidad -= cantidad
	_ranuras[hueco] = ItemStack.new(s.id, cantidad)
	ranura_cambiada.emit(indice)
	ranura_cambiada.emit(hueco)
	return true


func instantanea() -> Array:
	## Copia PROFUNDA: con referencias, el rollback no restauraría nada.
	var copia: Array = []
	for s in _ranuras:
		copia.append(s.duplicado() if s != null else null)
	return copia


func restaurar(previa: Array) -> void:
	_ranuras = previa
	for i in _ranuras.size():
		ranura_cambiada.emit(i)


func transaccion(operaciones: Array) -> bool:
	## Todo o nada: si cualquier paso falla, el inventario vuelve exactamente
	## a como estaba. Sin esto, una compra interrumpida pierde el oro Y el item.
	var copia := instantanea()
	for op in operaciones:
		if not op.call():
			restaurar(copia)
			return false
	return true


func a_dict() -> Dictionary:
	var ranuras := {}
	for i in _ranuras.size():
		if _ranuras[i] != null:
			ranuras[str(i)] = _ranuras[i].a_dict()
	return {"capacidad": _ranuras.size(), "ranuras": ranuras}


func de_dict(d: Dictionary) -> void:
	_ranuras.clear()
	_ranuras.resize(int(d.get("capacidad", 20)))
	var ranuras: Dictionary = d.get("ranuras", {})
	for clave in ranuras:
		var i := int(clave)
		var stack := ItemStack.de_dict(ranuras[clave])
		# Un item borrado en un parche no puede impedir cargar la partida.
		if _valido(i) and _base.existe(stack.id):
			_ranuras[i] = stack
	for i in _ranuras.size():
		ranura_cambiada.emit(i)


func _valido(i: int) -> bool:
	return i >= 0 and i < _ranuras.size()
