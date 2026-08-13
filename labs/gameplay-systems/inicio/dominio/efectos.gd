class_name Efectos
extends RefCounted

## Efectos de estado: buffs, debuffs y DoT (clase 298).
##
## Se apoya en lo ya construido: un buff es un modificador de `Stats` con
## caducidad, y un aturdimiento es un tag de `Tags` que bloquea habilidades.
## Que encaje sin añadir nada nuevo es la prueba de que las clases anteriores
## estaban bien diseñadas.

enum Apilamiento { REFRESH, STACK, INDEPENDIENTE, IGNORAR }

signal aplicado(id: StringName, stacks: int)
signal refrescado(id: StringName, stacks: int)
signal expirado(id: StringName)
signal tick_efecto(id: StringName, efecto: Dictionary, origen: StringName)


class Definicion extends RefCounted:
	var id: StringName = &""
	var nombre: String = ""
	var duracion: float = 0.0
	var periodo: float = 0.0
	var apilamiento: int = Apilamiento.REFRESH
	var max_stacks: int = 1
	var prioridad: int = 0
	var dispelable: bool = true
	var beneficioso: bool = false
	var tags_aplicados: PackedStringArray = PackedStringArray()
	var modificadores: Array = []
	var por_tick: Array = []

	static func de_dict(d: Dictionary) -> Definicion:
		var e := Definicion.new()
		e.id = StringName(str(d.get("id", "")))
		e.nombre = str(d.get("nombre", ""))
		e.duracion = float(d.get("duracion", 0.0))
		e.periodo = float(d.get("periodo", 0.0))
		var i := Apilamiento.keys().find(str(d.get("apilamiento", "REFRESH")).to_upper())
		e.apilamiento = i if i >= 0 else Apilamiento.REFRESH
		e.max_stacks = int(d.get("max_stacks", 1))
		e.prioridad = int(d.get("prioridad", 0))
		e.dispelable = bool(d.get("dispelable", true))
		e.beneficioso = bool(d.get("beneficioso", false))
		e.tags_aplicados = PackedStringArray(d.get("tags", []))
		e.modificadores = d.get("modificadores", [])
		e.por_tick = d.get("por_tick", [])
		return e


class Activo extends RefCounted:
	var definicion: Definicion
	var origen: StringName = &""
	var stacks: int = 1
	var restante: float = 0.0
	var acumulado_tick: float = 0.0

	func _init(d: Definicion, origen_: StringName) -> void:
		definicion = d
		origen = origen_
		restante = d.duracion

	func clave() -> StringName:
		# Un efecto INDEPENDIENTE se identifica también por su origen: el
		# veneno de dos jugadores son dos efectos, no uno.
		if definicion.apilamiento == Apilamiento.INDEPENDIENTE:
			return StringName("%s@%s" % [definicion.id, origen])
		return definicion.id

	func caducado() -> bool:
		return definicion.duracion > 0.0 and restante <= 0.0


var resistencia_duracion: float = 0.0

var _stats: Stats
var _tags: Tags
var _activos := {}
var _inmunidades := {}


func _init(stats: Stats, tags: Tags) -> void:
	_stats = stats
	_tags = tags


func aplicar(d: Definicion, origen: StringName = &"desconocido") -> bool:
	if _inmunidades.has(d.id):
		return false  # la inmunidad se comprueba ANTES de aplicar

	var provisional := Activo.new(d, origen)
	var clave := provisional.clave()
	var existente: Activo = _activos.get(clave)

	if existente == null:
		provisional.restante = _duracion_efectiva(d)
		_activos[clave] = provisional
		_aplicar_capa(provisional)
		aplicado.emit(d.id, provisional.stacks)
		return true

	match d.apilamiento:
		Apilamiento.IGNORAR:
			return false
		Apilamiento.REFRESH:
			existente.restante = _duracion_efectiva(d)
			refrescado.emit(d.id, existente.stacks)
		Apilamiento.STACK:
			# Quitar, subir y volver a poner: si se sumara "uno más" cada vez,
			# el número de modificadores se desincronizaría de los stacks.
			_retirar_capa(existente)
			existente.stacks = mini(existente.stacks + 1, d.max_stacks)
			existente.restante = _duracion_efectiva(d)
			_aplicar_capa(existente)
			refrescado.emit(d.id, existente.stacks)
		_:
			pass
	return true


func tick(delta: float) -> void:
	## TODO (clase 298): avanza inmunidades, efectos periódicos y duraciones.
	##   - Los efectos periódicos usan SU PROPIO acumulador, no el frame: con
	##     `while acumulado >= periodo` el daño es el mismo a 30 y a 144 fps.
	##   - Itera sobre una COPIA de las claves: vas a borrar mientras recorres.
	##   - El valor de cada tick escala con `stacks`.
	##   - Al caducar, sal SIEMPRE por `_quitar()`: es el único camino que
	##     garantiza residuo cero en stats y tags.
	for id in _inmunidades.keys():
		var t := float(_inmunidades[id]) - delta
		if t <= 0.0:
			_inmunidades.erase(id)
		else:
			_inmunidades[id] = t


func dispel(cantidad: int = 1, solo_perjudiciales: bool = true) -> int:
	var candidatos := _activos.values().filter(func(e):
		return e.definicion.dispelable and (not solo_perjudiciales or not e.definicion.beneficioso))
	# Primero lo más prioritario: dispelar debe quitar el aturdimiento, no un
	# +2 de velocidad.
	candidatos.sort_custom(func(a, b): return a.definicion.prioridad > b.definicion.prioridad)
	var quitados := 0
	for e in candidatos.slice(0, cantidad):
		_quitar(e.clave())
		quitados += 1
	return quitados


func inmunizar(id: StringName, segundos: float) -> void:
	_inmunidades[id] = segundos
	for clave in _activos.keys().duplicate():
		if _activos[clave].definicion.id == id:
			_quitar(clave)


func tiene(id: StringName) -> bool:
	return _activos.values().any(func(e): return e.definicion.id == id)


func stacks_de(id: StringName) -> int:
	for e in _activos.values():
		if e.definicion.id == id:
			return e.stacks
	return 0


func activos() -> int:
	return _activos.size()


func limpiar_todo() -> void:
	for clave in _activos.keys().duplicate():
		_quitar(clave)


func _duracion_efectiva(d: Definicion) -> float:
	if d.beneficioso or d.duracion <= 0.0:
		return d.duracion
	return d.duracion * (1.0 - clampf(resistencia_duracion, 0.0, 0.9))


func _origen_mod(e: Activo) -> StringName:
	return StringName("efecto:%s" % e.clave())


func _aplicar_capa(e: Activo) -> void:
	# El valor escala con los stacks: 3 stacks de quemadura pegan el triple.
	_stats.aplicar_efectos(_origen_mod(e), _mods_como_efectos(e.definicion), float(e.stacks))
	for t in e.definicion.tags_aplicados:
		_tags.agregar(t)


func _retirar_capa(e: Activo) -> void:
	_stats.retirar_origen(_origen_mod(e))
	for t in e.definicion.tags_aplicados:
		_tags.quitar(t)


func _mods_como_efectos(d: Definicion) -> Array:
	var salida: Array = []
	for m in d.modificadores:
		salida.append({"tipo": "modificador", "stat": m.get("stat", ""),
			"modo": m.get("modo", "plano"), "valor": m.get("valor", 0.0)})
	return salida


func _quitar(clave: StringName) -> void:
	var e: Activo = _activos.get(clave)
	if e == null:
		return
	# El residuo cero está garantizado aquí: es el ÚNICO camino de salida.
	_retirar_capa(e)
	_activos.erase(clave)
	expirado.emit(e.definicion.id)
