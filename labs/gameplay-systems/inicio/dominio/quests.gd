class_name Diario
extends RefCounted

## Sistema de misiones con máquina de estados y objetivos por eventos (clase 305).

enum Estado { LOCKED, AVAILABLE, ACTIVE, COMPLETED, ENTREGADA, FAILED }

const TIPOS_OBJETIVO := ["matar", "recoger", "entregar", "alcanzar", "hablar", "flag"]

## Transiciones permitidas. Cualquier otra es un bug y queremos que salte.
const VALIDAS := {
	Estado.LOCKED: [Estado.AVAILABLE],
	Estado.AVAILABLE: [Estado.ACTIVE, Estado.LOCKED],
	Estado.ACTIVE: [Estado.COMPLETED, Estado.FAILED],
	Estado.COMPLETED: [Estado.ENTREGADA],
	Estado.ENTREGADA: [],
	Estado.FAILED: [Estado.AVAILABLE],
}

signal disponible(id: StringName)
signal aceptada(id: StringName)
signal progreso_objetivo(id: StringName, objetivo: String, actual: int, total: int)
signal completada(id: StringName)
signal fallada(id: StringName)
signal entregada(id: StringName, recompensas: Dictionary)


class Quest extends RefCounted:
	var definicion: Dictionary = {}
	var estado: int = Estado.LOCKED
	var progreso := {}
	var tiempo_restante: float = -1.0

	func _init(def: Dictionary) -> void:
		definicion = def
		for o in def.get("objetivos", []):
			progreso[str(o["id"])] = 0
		tiempo_restante = float(def.get("limite_tiempo", -1.0))

	func id() -> StringName:
		return StringName(str(definicion.get("id", "")))

	func objetivos() -> Array:
		return definicion.get("objetivos", [])

	func requerido_completo(o: Dictionary) -> bool:
		return int(progreso.get(str(o["id"]), 0)) >= int(o.get("cantidad", 1))

	func obligatorios_completos() -> bool:
		for o in objetivos():
			if not bool(o.get("opcional", false)) and not requerido_completo(o):
				return false
		return true

	func opcionales_completos() -> bool:
		for o in objetivos():
			if bool(o.get("opcional", false)) and not requerido_completo(o):
				return false
		return true


## Motivo del último rechazo de transición. La UI y los tests lo consultan;
## así el sistema puede explicar por qué dijo que no.
var ultimo_rechazo: String = ""

var _quests := {}
var _nivel_actual: int = 1


func cargar(ruta: String) -> Array:
	if not FileAccess.file_exists(ruta):
		return ["no existe: " + ruta]
	var f := FileAccess.open(ruta, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return ["quests.json ilegible"]
	for def in d.get("quests", []):
		var q := Quest.new(def)
		_quests[q.id()] = q
	var errores := validar()
	_reevaluar_disponibles()
	return errores


func total() -> int:
	return _quests.size()


func existe(id: StringName) -> bool:
	return _quests.has(id)


func estado(id: StringName) -> int:
	return _quests[id].estado if _quests.has(id) else Estado.LOCKED


func progreso_de(id: StringName, objetivo: String) -> int:
	return int(_quests[id].progreso.get(objetivo, 0)) if _quests.has(id) else 0


func activas() -> Array:
	return _quests.values().filter(func(q): return q.estado == Estado.ACTIVE)


func fijar_nivel(n: int) -> void:
	_nivel_actual = n
	_reevaluar_disponibles()


func aceptar(id: StringName) -> bool:
	if not _quests.has(id):
		return false
	if not _transicion(_quests[id], Estado.ACTIVE):
		return false
	aceptada.emit(id)
	return true


func fallar(id: StringName) -> bool:
	if not _quests.has(id) or not _transicion(_quests[id], Estado.FAILED):
		return false
	fallada.emit(id)
	return true


func conectar(bus: EventosJuego) -> void:
	bus.enemigo_muerto.connect(func(id, _pos): _avanzar("matar", id, 1))
	bus.item_recogido.connect(func(id, n): _avanzar("recoger", id, n))
	bus.item_entregado.connect(func(id, n, _a): _avanzar("entregar", id, n))
	bus.zona_alcanzada.connect(func(id): _avanzar("alcanzar", id, 1))
	bus.npc_hablado.connect(func(id): _avanzar("hablar", id, 1))
	bus.flag_narrativa.connect(func(clave, v): if v: _avanzar("flag", clave, 1))


func tick(delta: float) -> void:
	for q in activas():
		if q.tiempo_restante > 0.0:
			q.tiempo_restante -= delta
			if q.tiempo_restante <= 0.0:
				if _transicion(q, Estado.FAILED):
					fallada.emit(q.id())


func entregar(id: StringName, inv: Inventario, monedero: Monedero, prog: Progresion) -> bool:
	if not _quests.has(id):
		return false
	var q: Quest = _quests[id]
	if q.estado != Estado.COMPLETED:
		return false

	var r: Dictionary = q.definicion.get("recompensas", {})
	var items: Array = (r.get("items", []) as Array).duplicate()
	if q.opcionales_completos():
		items.append_array(r.get("opcional", {}).get("items", []))

	# Si no cabe TODO, no se entrega nada: mejor que el jugador vacíe la
	# mochila a que pierda la recompensa de una misión de tres horas.
	for it in items:
		var iid := StringName(str(it["item"]))
		var n := int(it.get("cantidad", 1))
		if inv.cabe(iid, n) < n:
			return false

	if not _transicion(q, Estado.ENTREGADA):
		return false
	for it in items:
		inv.agregar_todo_o_nada(StringName(str(it["item"])), int(it.get("cantidad", 1)))
	var oro := int(r.get("oro", 0))
	if q.opcionales_completos():
		oro += int(r.get("opcional", {}).get("oro", 0))
	if oro > 0:
		monedero.ingresar(&"oro", oro, StringName("quest:%s" % id))
	if int(r.get("xp", 0)) > 0:
		prog.ganar_xp(int(r["xp"]))
	for u in r.get("desbloqueos", []):
		prog.desbloquear(StringName(str(u)))

	entregada.emit(id, r)
	_reevaluar_disponibles()
	return true


func validar() -> Array:
	var errores: Array = []
	for q in _quests.values():
		if q.objetivos().is_empty():
			errores.append("quest '%s': sin objetivos" % q.id())
		var vistos := {}
		var todos_opcionales := true
		for o in q.objetivos():
			var oid := str(o.get("id", ""))
			if vistos.has(oid):
				errores.append("quest '%s': id de objetivo duplicado '%s'" % [q.id(), oid])
			vistos[oid] = true
			if not TIPOS_OBJETIVO.has(str(o.get("tipo", ""))):
				errores.append("quest '%s': tipo de objetivo desconocido '%s'"
					% [q.id(), o.get("tipo", "")])
			if not bool(o.get("opcional", false)):
				todos_opcionales = false
		if todos_opcionales and not q.objetivos().is_empty():
			errores.append("quest '%s': todos los objetivos son opcionales (se completa sola)" % q.id())
		for p in q.definicion.get("prerrequisitos", []):
			if p.has("quest_completada") and not _quests.has(StringName(str(p["quest_completada"]))):
				errores.append("quest '%s': prerrequisito inexistente '%s'"
					% [q.id(), p["quest_completada"]])
	return errores


func a_dict() -> Dictionary:
	var out := {}
	for id in _quests:
		var q: Quest = _quests[id]
		if q.estado == Estado.LOCKED:
			continue  # lo bloqueado se recalcula; no ocupa save
		out[String(id)] = {
			"estado": q.estado,
			"progreso": q.progreso.duplicate(),
			"tiempo": q.tiempo_restante,
		}
	return out


func de_dict(d: Dictionary) -> void:
	for clave in d:
		var id := StringName(str(clave))
		if not _quests.has(id):
			push_warning("quest desconocida en el save (¿borrada en un parche?): %s" % id)
			continue
		var q: Quest = _quests[id]
		q.estado = int(d[clave].get("estado", Estado.LOCKED))
		# JSON no distingue enteros de flotantes: sin este `int()`, el progreso
		# vuelve como 3.0 y un `a_dict()` posterior ya no es igual al original.
		# Es el bug más silencioso de todo el guardado.
		var progreso_bruto: Dictionary = d[clave].get("progreso", {})
		q.progreso.clear()
		for k in progreso_bruto:
			q.progreso[str(k)] = int(progreso_bruto[k])
		q.tiempo_restante = float(d[clave].get("tiempo", -1.0))
	_reevaluar_disponibles()


func _transicion(q: Quest, nuevo: int) -> bool:
	if not VALIDAS[q.estado].has(nuevo):
		# Se registra y se rechaza, pero NO se hace `push_error`: rechazar una
		# transición inválida es comportamiento correcto del sistema, y llenar
		# el log de errores por algo esperado enseña a ignorar los errores.
		ultimo_rechazo = "transición inválida en '%s': %s -> %s" % [
			q.id(), Estado.keys()[q.estado], Estado.keys()[nuevo]]
		return false
	q.estado = nuevo
	return true


func _prerrequisitos_ok(q: Quest) -> bool:
	for p in q.definicion.get("prerrequisitos", []):
		if p.has("quest_completada"):
			var otra := StringName(str(p["quest_completada"]))
			if not estado(otra) in [Estado.COMPLETED, Estado.ENTREGADA]:
				return false
		if p.has("nivel_min") and _nivel_actual < int(p["nivel_min"]):
			return false
	return true


func _reevaluar_disponibles() -> void:
	for q in _quests.values():
		if q.estado != Estado.LOCKED:
			continue
		if _prerrequisitos_ok(q):
			if _transicion(q, Estado.AVAILABLE):
				disponible.emit(q.id())


func _avanzar(tipo: String, objetivo: StringName, cantidad: int) -> void:
	## TODO (clase 305): avanza los objetivos de las quests ACTIVAS.
	##   - Un objetivo avanza si coinciden `tipo` y `objetivo`, y aún no está
	##     completo. Acota con `mini(total, actual + cantidad)`.
	##   - Si la quest es `secuencial`, un objetivo NO avanza mientras alguno
	##     anterior siga incompleto.
	##   - Al completarse los obligatorios: transición a COMPLETED, emitir
	##     `completada` y reevaluar disponibles — así la cadena avanza sola.
	pass
