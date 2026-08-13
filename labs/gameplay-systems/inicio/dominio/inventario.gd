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
	##
	## TODO (clase 295): calcula cuántas unidades de `id` cabrían de verdad.
	## Cuenta el hueco de las ranuras vacías (un stack entero cada una) MÁS lo
	## que le falta a cada stack parcial del mismo item. Sal en cuanto sepas
	## que cabe todo: no hace falta recorrerlo entero.
	if cantidad <= 0 or not _base.existe(id):
		return 0
	return 0


func agregar(id: StringName, cantidad: int) -> int:
	## Añade lo que pueda y devuelve el RESTANTE. Descartarlo en silencio es
	## la forma más común de que un jugador pierda objetos.
	##
	## TODO (clase 295): impleméntalo en DOS fases.
	##   1. Completar los stacks parciales del mismo item (para no fragmentar).
	##   2. Ocupar ranuras vacías con `mini(tope, quedan)`.
	## Emite `ranura_cambiada(i)` por cada ranura que toques, e
	## `inventario_lleno(id, quedan)` si sobra algo. Y devuelve el restante:
	## descartarlo en silencio es la forma más común de perder objetos.
	if cantidad <= 0 or not _base.existe(id):
		return cantidad
	return cantidad


func agregar_todo_o_nada(id: StringName, cantidad: int) -> bool:
	if cabe(id, cantidad) < cantidad:
		return false
	var restante := agregar(id, cantidad)
	assert(restante == 0, "cabe() y agregar() discrepan: hay un bug en uno de los dos")
	return restante == 0


func quitar(id: StringName, cantidad: int) -> bool:
	## TODO (clase 295): quita `cantidad` unidades, todo o nada.
	## Recorre desde el FINAL para consumir antes los stacks parciales, y deja
	## `null` en la ranura cuando llegue a 0: un stack de cantidad 0 no existe.
	if cantidad <= 0 or contar(id) < cantidad:
		return false
	return false


func mover(desde: int, hasta: int) -> bool:
	if desde == hasta or not _valido(desde) or not _valido(hasta):
		return false
	## TODO (clase 295): tres casos, y el segundo es donde nacen los bugs.
	##   - destino vacío  → movimiento simple
	##   - mismo item     → fusionar hasta `max_stack`; EL SOBRANTE SE QUEDA
	##                      en el origen (si no, se duplican unidades)
	##   - items distintos→ intercambio
	var a: ItemStack = _ranuras[desde]
	if a == null:
		return false
	return false


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
