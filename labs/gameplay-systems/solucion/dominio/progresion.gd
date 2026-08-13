class_name Progresion
extends RefCounted

## Experiencia, niveles y desbloqueos (clase 302).
##
## Se guarda la XP, NUNCA el nivel: el nivel es derivado. Si se guardara,
## cambiar la curva en un parche dejaría a los personajes con el nivel viejo.

enum Forma { LINEAL, CUADRATICA, EXPONENCIAL }

const PUNTOS_POR_NIVEL := 1

signal xp_ganada(cantidad: int, total: int)
signal subio_nivel(nuevo: int, puntos_ganados: int)
signal desbloqueado(id: StringName)

var forma: int = Forma.CUADRATICA
var base_curva: float = 100.0
var factor: float = 1.15
var nivel_max: int = 60

var xp_total: int = 0
var puntos_disponibles: int = 0

var _desbloqueos := {}


func coste_de_nivel(nivel: int) -> int:
	if nivel >= nivel_max:
		return 0
	match forma:
		Forma.LINEAL:
			return int(base_curva * nivel)
		Forma.EXPONENCIAL:
			return int(base_curva * pow(factor, nivel - 1))
		_:
			return int(base_curva * nivel * nivel)


func total_hasta(nivel: int) -> int:
	var t := 0
	for n in range(1, nivel):
		t += coste_de_nivel(n)
	return t


func nivel() -> int:
	var n := 1
	var acumulado := 0
	while n < nivel_max:
		var coste := coste_de_nivel(n)
		if xp_total < acumulado + coste:
			break
		acumulado += coste
		n += 1
	return n


func ganar_xp(cantidad: int) -> void:
	if cantidad <= 0:
		return
	var antes := nivel()
	xp_total += cantidad
	xp_ganada.emit(cantidad, xp_total)
	var despues := nivel()
	# Un jefe puede dar 3 niveles de golpe: hay que emitirlos TODOS.
	for n in range(antes + 1, despues + 1):
		puntos_disponibles += PUNTOS_POR_NIVEL
		subio_nivel.emit(n, PUNTOS_POR_NIVEL)


func desbloquear(id: StringName) -> void:
	if _desbloqueos.has(id):
		return
	_desbloqueos[id] = true
	desbloqueado.emit(id)


func tiene_desbloqueo(id: StringName) -> bool:
	return _desbloqueos.has(id)


func desbloqueos() -> Array:
	return _desbloqueos.keys()


func a_dict() -> Dictionary:
	return {
		"xp": xp_total,
		"puntos": puntos_disponibles,
		"desbloqueos": _desbloqueos.keys().map(func(k): return String(k)),
	}


func de_dict(d: Dictionary) -> void:
	xp_total = int(d.get("xp", 0))
	puntos_disponibles = int(d.get("puntos", 0))
	_desbloqueos.clear()
	for k in d.get("desbloqueos", []):
		_desbloqueos[StringName(str(k))] = true
