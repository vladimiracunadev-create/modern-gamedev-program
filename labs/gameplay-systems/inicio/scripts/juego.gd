class_name Juego
extends RefCounted

## Composition root del laboratorio (clase 310).
##
## Es el ÚNICO archivo que conoce a todos los sistemas. Lo comparten la escena
## principal y las pruebas headless: así lo que se prueba es exactamente lo
## que se ejecuta, no una versión paralela que puede divergir.

var base: BaseDeItems
var rng: RandomNumberGenerator
var bus: EventosJuego
var stats: Stats
var tags: Tags
var inv: Inventario
var equipo: Equipo
var efectos: Efectos
var habilidades: AbilitySystem
var prog: Progresion
var monedero: Monedero
var loot: TablasDeLoot
var diario: Diario
var guardado: Guardado

var errores_contenido: Array = []
var defs_efectos := {}


static func nuevo(semilla: int = 12345) -> Juego:
	var j := Juego.new()
	j._construir(semilla)
	return j


func _construir(semilla: int) -> void:
	# 1) CONTENIDO primero: todo lo demás depende de él.
	base = BaseDeItems.new()
	errores_contenido.append_array(base.cargar_desde_json("res://datos/items.json"))
	errores_contenido.append_array(base.validar())

	rng = RandomNumberGenerator.new()
	rng.seed = semilla

	loot = TablasDeLoot.new(base, rng)
	errores_contenido.append_array(loot.cargar("res://datos/loot.json"))

	diario = Diario.new()
	errores_contenido.append_array(diario.cargar("res://datos/quests.json"))

	# 2) SISTEMAS de estado.
	stats = Stats.new()
	tags = Tags.new()
	inv = Inventario.new(base, 30)
	equipo = Equipo.new(base, stats)
	efectos = Efectos.new(stats, tags)
	habilidades = AbilitySystem.new()
	habilidades.tags = tags
	prog = Progresion.new()
	monedero = Monedero.new()

	_cargar_habilidades("res://datos/habilidades.json")
	_cargar_efectos("res://datos/efectos.json")

	# 3) CONEXIONES: todo el pegamento del juego, en un solo sitio.
	bus = EventosJuego.new()
	diario.conectar(bus)
	bus.enemigo_muerto.connect(_on_enemigo_muerto)
	# `_conectar_nivel` usa una lambda que captura el diario y NO el Juego:
	# así esta conexión concreta no crea un ciclo con el composition root.
	_conectar_nivel(prog, diario)
	habilidades.efectos_aplicados.connect(_on_efectos_de_habilidad)
	efectos.tick_efecto.connect(_on_tick_efecto)

	# 4) GUARDADO: cada sistema aporta su par leer/escribir.
	guardado = Guardado.new()
	guardado.registrar("stats", stats.a_dict, stats.de_dict)
	guardado.registrar("inventario", inv.a_dict, inv.de_dict)
	guardado.registrar("equipo", equipo.a_dict, func(d): equipo.de_dict(d, inv))
	guardado.registrar("progresion", prog.a_dict, prog.de_dict)
	guardado.registrar("monedero", monedero.a_dict, monedero.de_dict)
	guardado.registrar("quests", diario.a_dict, diario.de_dict)
	guardado.registrar("habilidades", habilidades.a_dict, habilidades.de_dict)


func liberar() -> void:
	## Rompe los ciclos de referencia antes de soltar el objeto (clase 340).
	##
	## Conectar `bus.enemigo_muerto` a un método de `Juego` hace que el bus
	## retenga al Juego, y el Juego ya retiene al bus: es un ciclo, y con
	## contado de referencias un ciclo NO se libera nunca. En un juego real se
	## nota como memoria que sube y no baja; aquí, como "instances leaked at
	## exit" en el log de la CI.
	if bus != null and bus.enemigo_muerto.is_connected(_on_enemigo_muerto):
		bus.enemigo_muerto.disconnect(_on_enemigo_muerto)
	if habilidades != null and habilidades.efectos_aplicados.is_connected(_on_efectos_de_habilidad):
		habilidades.efectos_aplicados.disconnect(_on_efectos_de_habilidad)
	if efectos != null and efectos.tick_efecto.is_connected(_on_tick_efecto):
		efectos.tick_efecto.disconnect(_on_tick_efecto)
	# El guardado retiene `Callable` ligadas a este mismo objeto: mismo ciclo.
	if guardado != null:
		guardado.limpiar()


func tick(delta: float) -> void:
	habilidades.tick(delta)
	efectos.tick(delta)
	diario.tick(delta)
	monedero.avanzar_tiempo(delta)


func efecto(id: StringName) -> Efectos.Definicion:
	return defs_efectos.get(id)


func meta() -> Dictionary:
	return {"nivel": prog.nivel(), "zona": "villarroca", "tiempo_jugado": 0.0}


func instantanea() -> Dictionary:
	## El estado completo, para comparar antes y después de guardar/cargar.
	var d := {}
	for clave in guardado.sistemas():
		d[clave] = _leer_de(clave)
	return d


func _leer_de(clave: String) -> Dictionary:
	match clave:
		"stats": return stats.a_dict()
		"inventario": return inv.a_dict()
		"equipo": return equipo.a_dict()
		"progresion": return prog.a_dict()
		"monedero": return monedero.a_dict()
		"quests": return diario.a_dict()
		"habilidades": return habilidades.a_dict()
		_: return {}


func _cargar_habilidades(ruta: String) -> void:
	if not FileAccess.file_exists(ruta):
		errores_contenido.append("no existe: " + ruta)
		return
	var f := FileAccess.open(ruta, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		errores_contenido.append("habilidades.json ilegible")
		return
	for h in d.get("habilidades", []):
		habilidades.aprender(AbilitySystem.Definicion.de_dict(h))
	habilidades.fijar_recurso(&"mana", 100.0)


func _cargar_efectos(ruta: String) -> void:
	if not FileAccess.file_exists(ruta):
		errores_contenido.append("no existe: " + ruta)
		return
	var f := FileAccess.open(ruta, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		errores_contenido.append("efectos.json ilegible")
		return
	for e in d.get("efectos", []):
		var def := Efectos.Definicion.de_dict(e)
		defs_efectos[def.id] = def


static func _conectar_nivel(p: Progresion, d: Diario) -> void:
	p.subio_nivel.connect(func(n, _puntos): d.fijar_nivel(n))


func _on_enemigo_muerto(id: StringName, _pos: Vector2) -> void:
	var tabla := StringName("loot_%s" % id)
	if not loot.existe(tabla):
		return
	for s in loot.tirar(tabla, {"nivel": prog.nivel()}):
		if s.id == &"moneda_oro":
			monedero.ingresar(&"oro", s.cantidad, &"loot")
		else:
			inv.agregar(s.id, s.cantidad)


func _on_efectos_de_habilidad(_id: StringName, _objetivos: Array, efs: Array) -> void:
	for e in efs:
		if str(e.get("tipo", "")) == "estado":
			var def := efecto(StringName(str(e.get("estado", ""))))
			if def != null:
				efectos.aplicar(def, &"jugador")


func _on_tick_efecto(_id: StringName, _efecto: Dictionary, _origen: StringName) -> void:
	# En un juego real, esto iría al pipeline de daño (clase 299). Aquí basta
	# con que el laboratorio demuestre que el evento llega.
	pass
