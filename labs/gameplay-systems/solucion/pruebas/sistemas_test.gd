extends SceneTree

## Pruebas de los sistemas de gameplay (clases 294-307).
##
## Se ejecuta con:
##   godot --headless --path . --script res://pruebas/sistemas_test.gd
##
## Todo corre sin escenas, sin GPU y en milisegundos: es exactamente lo que
## permitió que el dominio no extienda Node.

var t := AyudaPruebas.new()
var _creados: Array = []


func _init() -> void:
	_catalogo()
	_inventario()
	_stats_y_equipo()
	_habilidades()
	_efectos()
	_quests()
	_loot()
	_guardado()

	# Romper los ciclos de referencia antes de salir: si no, el motor avisa de
	# instancias filtradas al cerrar, y ese aviso es un fallo real (clase 340).
	for j in _creados:
		j.liberar()
	_creados.clear()

	quit(t.resumen())


func _nuevo(semilla: int) -> Juego:
	var j := Juego.nuevo(semilla)
	_creados.append(j)
	return j


# --------------------------------------------------------------------------
func _catalogo() -> void:
	var j := _nuevo(1)
	t.check(j.errores_contenido.is_empty(), "el contenido valida sin errores")
	t.check(j.base.todos().size() >= 20, "el catálogo tiene al menos 20 items")
	t.check(j.base.existe(&"pocion_menor"), "se encuentra un item por id")
	t.check(not j.base.existe(&"item_inventado"), "un id inexistente no existe")
	t.check(j.base.con_tag("arma").size() >= 4, "la consulta por tag devuelve las armas")


# --------------------------------------------------------------------------
func _inventario() -> void:
	var j := _nuevo(1)
	var base := j.base
	var inv := Inventario.new(base, 3)

	# Apilamiento y reparto entre ranuras.
	t.check(inv.agregar(&"pocion_menor", 25) == 0, "25 pociones caben en 2 ranuras de 20")
	t.check(inv.contar(&"pocion_menor") == 25, "el recuento total es correcto")
	t.check(inv.libres() == 1, "queda una ranura libre")

	# Restante: 1 ranura libre (20) + hueco del stack parcial (15) = 35.
	t.check(inv.agregar(&"pocion_menor", 50) == 15, "el restante que no cabe se devuelve")

	# `cabe()` no miente.
	var inv2 := Inventario.new(base, 2)
	t.check(inv2.cabe(&"pocion_menor", 100) == 40, "cabe() calcula el hueco real")
	t.check(inv2.cabe(&"item_inventado", 1) == 0, "un item inexistente no cabe")
	t.check(inv2.cabe(&"pocion_menor", -5) == 0, "una cantidad negativa no cabe")

	# Atómico: si no cabe, no se toca nada.
	var inv3 := Inventario.new(base, 1)
	inv3.agregar(&"espada_hierro", 1)
	var antes := inv3.a_dict()
	t.check(not inv3.agregar_todo_o_nada(&"casco_hierro", 1), "todo-o-nada rechaza si no cabe")
	t.check(inv3.a_dict() == antes, "una operación fallida no muta el inventario")

	# Quitar y ranuras vacías.
	var inv4 := Inventario.new(base, 5)
	inv4.agregar(&"pocion_menor", 5)
	t.check(inv4.quitar(&"pocion_menor", 5), "se quita la cantidad exacta")
	t.check(inv4.libres() == 5, "una ranura vaciada queda libre, no con un stack de 0")
	t.check(not inv4.quitar(&"pocion_menor", 1), "no se puede quitar lo que no hay")

	# Mover: fusión con sobrante en el origen.
	var inv5 := Inventario.new(base, 4)
	inv5.agregar(&"pocion_menor", 20)
	inv5.agregar(&"pocion_menor", 15)
	t.check(inv5.mover(1, 0), "mover fusiona stacks del mismo item")
	t.check(inv5.ranura(0).cantidad == 20, "el destino queda al máximo")
	t.check(inv5.ranura(1) != null and inv5.ranura(1).cantidad == 15,
		"el sobrante SE QUEDA en el origen")
	t.check(inv5.contar(&"pocion_menor") == 35, "mover no crea ni destruye unidades")

	# Partir.
	t.check(inv5.partir(0, 8), "se parte un stack si hay hueco")
	t.check(inv5.contar(&"pocion_menor") == 35, "partir conserva el total")

	# Transacción con rollback.
	var inv6 := Inventario.new(base, 10)
	inv6.agregar(&"mineral_hierro", 10)
	var antes6 := inv6.a_dict()
	var ok := inv6.transaccion([
		func(): return inv6.quitar(&"mineral_hierro", 5),
		func(): return false,  # el segundo paso siempre falla
	])
	t.check(not ok, "la transacción informa del fallo")
	t.check(inv6.a_dict() == antes6, "el rollback deja el inventario byte a byte igual")

	# Serialización con posiciones.
	var d := inv5.a_dict()
	var inv7 := Inventario.new(base, 4)
	inv7.de_dict(d)
	t.check(inv7.a_dict() == d, "a_dict/de_dict conserva la posición de cada ranura")


# --------------------------------------------------------------------------
func _stats_y_equipo() -> void:
	var j := _nuevo(1)
	var stats := j.stats
	var inv := j.inv
	var eq := j.equipo

	# Orden de aplicación: (10 + 5) × 1.30 × 1.5 = 29.25
	var s := Estadistica.new(10.0)
	s.agregar_mod(&"a", Estadistica.Modo.PLANO, 5.0)
	s.agregar_mod(&"b", Estadistica.Modo.PORCENTUAL, 0.10)
	s.agregar_mod(&"c", Estadistica.Modo.PORCENTUAL, 0.20)
	s.agregar_mod(&"d", Estadistica.Modo.MULTIPLICATIVO, 1.5)
	t.check(is_equal_approx(s.valor(), 29.25),
		"el orden documentado da 29.25 (fue %.4f)" % s.valor())

	# La caché se invalida al cambiar la base.
	s.fijar_base(20.0)
	t.check(is_equal_approx(s.valor(), 48.75),
		"cambiar la base invalida la caché (fue %.4f)" % s.valor())

	# Derivadas: se calculan, no se guardan.
	var vida1 := stats.vida_maxima()
	stats.get_stat(&"constitucion").fijar_base(stats.get_stat(&"constitucion").base + 5.0)
	t.check(stats.vida_maxima() == vida1 + 50, "la vida máxima se deriva de la constitución")

	# Equipar: el modificador se aplica.
	inv.agregar(&"espada_hierro", 2)
	var ataque0 := stats.valor(&"ataque")
	t.check(eq.equipar(inv, &"mano_principal", &"espada_hierro"), "se equipa la espada")
	t.check(is_equal_approx(stats.valor(&"ataque"), ataque0 + 7.0), "el modificador se aplica")

	# Equipar el mismo item encima NO acumula.
	t.check(eq.equipar(inv, &"mano_principal", &"espada_hierro"), "se equipa la segunda espada")
	t.check(is_equal_approx(stats.valor(&"ataque"), ataque0 + 7.0),
		"la bonificación no se duplica al reemplazar")

	# Desequipar: residuo cero.
	t.check(eq.desequipar(inv, &"mano_principal"), "se desequipa")
	t.check(is_equal_approx(stats.valor(&"ataque"), ataque0),
		"desequipar no deja modificadores pegados")
	t.check(inv.contar(&"espada_hierro") == 2, "no se ha perdido ninguna espada")
	t.check(stats.total_modificadores() == 0, "no quedan modificadores huérfanos")

	# Restricción de slot.
	t.check(not eq.admite(&"cabeza", &"espada_hierro"), "una espada no va en la cabeza")
	t.check(eq.admite(&"cabeza", &"casco_hierro"), "un casco sí va en la cabeza")
	t.check(not eq.admite(&"mano_secundaria", &"hacha_dos_manos"),
		"un arma a dos manos no va en la secundaria")

	# Dos manos devuelve el escudo al inventario.
	inv.agregar(&"escudo_madera", 1)
	inv.agregar(&"hacha_dos_manos", 1)
	eq.equipar(inv, &"mano_secundaria", &"escudo_madera")
	t.check(eq.equipar(inv, &"mano_principal", &"hacha_dos_manos"),
		"se equipa el arma a dos manos")
	t.check(eq.equipado(&"mano_secundaria") == &"", "la mano secundaria queda libre")
	t.check(inv.contar(&"escudo_madera") == 1, "el escudo volvió al inventario")

	# Desequipar con el inventario lleno: no se hace, y no se destruye nada.
	var j2 := _nuevo(1)
	var inv_lleno := Inventario.new(j2.base, 1)
	var eq2 := Equipo.new(j2.base, j2.stats)
	inv_lleno.agregar(&"casco_hierro", 1)
	eq2.equipar(inv_lleno, &"cabeza", &"casco_hierro")
	inv_lleno.agregar(&"pocion_menor", 20)  # ocupa la única ranura
	t.check(not eq2.desequipar(inv_lleno, &"cabeza"),
		"con el inventario lleno no se desequipa")
	t.check(eq2.equipado(&"cabeza") == &"casco_hierro", "y el casco sigue puesto")


# --------------------------------------------------------------------------
func _habilidades() -> void:
	var j := _nuevo(1)
	var h := j.habilidades

	t.check(h.activar(&"bola_fuego", ["enemigo"], 5.0) == AbilitySystem.Motivo.OK,
		"una habilidad válida se activa")
	t.check(is_equal_approx(h.recurso(&"mana"), 75.0), "el coste se cobra AL ACTIVAR")
	t.check(h.activar(&"bola_fuego", ["enemigo"], 5.0) == AbilitySystem.Motivo.YA_ACTIVA,
		"no se puede activar otra con una en curso")

	# Casteo + ejecución + recuperación.
	for i in 20:
		h.tick(0.1)
	t.check(h.fase() == AbilitySystem.Fase.INACTIVA, "vuelve a INACTIVA tras el ciclo")
	t.check(h.cooldown_restante(&"bola_fuego") > 0.0, "se aplicó el cooldown")
	t.check(h.activar(&"bola_fuego", ["enemigo"], 5.0) == AbilitySystem.Motivo.EN_COOLDOWN,
		"en cooldown no se puede reactivar")

	for i in 80:
		h.tick(0.1)
	t.check(h.cooldown_restante(&"bola_fuego") == 0.0, "el cooldown se agota con el tiempo")

	# Tags de bloqueo.
	h.tags.agregar("estado.aturdido")
	t.check(h.activar(&"bola_fuego", ["enemigo"], 5.0) == AbilitySystem.Motivo.BLOQUEADA_POR_TAG,
		"un tag de bloqueo impide activar")
	h.tags.quitar("estado.aturdido")

	# Rango, objetivo y habilidad desconocida.
	t.check(h.activar(&"bola_fuego", ["enemigo"], 99.0) == AbilitySystem.Motivo.FUERA_DE_RANGO,
		"fuera de rango se rechaza")
	t.check(h.activar(&"bola_fuego", [], 1.0) == AbilitySystem.Motivo.SIN_OBJETIVO,
		"sin objetivo se rechaza")
	t.check(h.activar(&"habilidad_inventada", ["x"], 1.0) == AbilitySystem.Motivo.DESCONOCIDA,
		"una habilidad desconocida se rechaza")

	# Recurso insuficiente.
	h.fijar_recurso(&"mana", 5.0)
	t.check(h.activar(&"bola_fuego", ["enemigo"], 5.0) == AbilitySystem.Motivo.SIN_RECURSO,
		"sin maná se rechaza")

	# Requisito por tag.
	h.fijar_recurso(&"mana", 100.0)
	t.check(h.activar(&"ventisca", ["enemigo"], 5.0) == AbilitySystem.Motivo.FALTA_REQUISITO,
		"falta el tag requerido")

	# Interrupción durante el casteo.
	var j3 := _nuevo(1)
	var h3 := j3.habilidades
	h3.activar(&"bola_fuego", ["enemigo"], 5.0)
	h3.tick(0.3)
	t.check(h3.fase() == AbilitySystem.Fase.CASTEO, "está casteando")
	t.check(h3.interrumpir(), "se puede interrumpir el casteo")
	t.check(h3.fase() == AbilitySystem.Fase.INACTIVA, "tras interrumpir queda inactiva")
	t.check(is_equal_approx(h3.recurso(&"mana"), 75.0), "interrumpir NO devuelve el coste")

	# Determinismo: dos sistemas con la misma secuencia acaban igual.
	var a := _nuevo(7).habilidades
	var b := _nuevo(7).habilidades
	for i in 50:
		a.activar(&"golpe_pesado", ["e"], 1.0)
		b.activar(&"golpe_pesado", ["e"], 1.0)
		a.tick(0.1)
		b.tick(0.1)
	t.check(a.a_dict() == b.a_dict(), "el sistema es determinista")


# --------------------------------------------------------------------------
func _efectos() -> void:
	var j := _nuevo(1)
	var fx := j.efectos
	var stats := j.stats

	# Las lambdas de GDScript capturan por VALOR: si `golpes` fuera un int, el
	# `+=` de dentro modificaría una copia. Un Array es referencia y sí funciona.
	var golpes := [0]
	fx.tick_efecto.connect(func(_id, e, _o): golpes[0] += int(e["valor"]))

	# STACK: acumula y escala el daño.
	var quemadura := j.efecto(&"quemadura")
	fx.aplicar(quemadura, &"mago")
	fx.aplicar(quemadura, &"mago")
	t.check(fx.stacks_de(&"quemadura") == 2, "los stacks se acumulan")
	# Pasos de 0,125 s (1/8, exacto en binario): con 0,1 la suma de 40 pasos
	# se queda en 3,9999… y el último tick del DoT no llega a dispararse. Es
	# un recordatorio de que el acumulador flotante no perdona.
	for i in 32:
		fx.tick(0.125)  # 4 s → 4 ticks × 6 × 2 stacks = 48
	t.check(golpes[0] == 48, "el daño periódico escala con los stacks (fue %d)" % golpes[0])
	t.check(not fx.tiene(&"quemadura"), "el efecto expira con su duración")

	# Independiente del framerate: mismo daño con distinto delta.
	var j2 := _nuevo(1)
	var golpes2 := [0]
	j2.efectos.tick_efecto.connect(func(_id, e, _o): golpes2[0] += int(e["valor"]))
	j2.efectos.aplicar(j2.efecto(&"quemadura"), &"mago")
	for i in 4:
		j2.efectos.tick(1.0)
	t.check(golpes2[0] == 24,
		"4 ticks de 1 s dan lo mismo que 40 de 0,1 s (fue %d)" % golpes2[0])

	# Buff: modifica y no deja residuo. El ataque base parte de 0, así que se
	# le da un valor para que un modificador porcentual tenga sobre qué actuar.
	stats.get_stat(&"ataque").fijar_base(20.0)
	var base_ataque := stats.valor(&"ataque")
	fx.aplicar(j.efecto(&"furia"), &"self")
	t.check(stats.valor(&"ataque") > base_ataque, "el buff modifica la estadística")
	for i in 110:
		fx.tick(0.1)
	t.check(is_equal_approx(stats.valor(&"ataque"), base_ataque),
		"al expirar no queda residuo")
	t.check(stats.total_modificadores() == 0, "no quedan modificadores huérfanos")

	# IGNORAR: no reinicia la duración.
	fx.aplicar(j.efecto(&"aturdimiento"), &"enemigo")
	fx.tick(1.0)
	t.check(not fx.aplicar(j.efecto(&"aturdimiento"), &"enemigo"),
		"un control con IGNORAR rechaza la reaplicación")
	t.check(j.tags.tiene("estado.aturdido"), "el tag está activo")
	fx.tick(1.5)
	t.check(not j.tags.tiene("estado.aturdido"), "el tag se retira al expirar")

	# INDEPENDIENTE: dos orígenes, dos efectos.
	var j3 := _nuevo(1)
	j3.efectos.aplicar(j3.efecto(&"veneno"), &"jugador_a")
	j3.efectos.aplicar(j3.efecto(&"veneno"), &"jugador_b")
	t.check(j3.efectos.activos() == 2, "dos orígenes producen dos efectos independientes")

	# Inmunidad: se comprueba ANTES de aplicar.
	var j4 := _nuevo(1)
	j4.efectos.inmunizar(&"aturdimiento", 5.0)
	t.check(not j4.efectos.aplicar(j4.efecto(&"aturdimiento"), &"x"),
		"la inmunidad impide aplicar")

	# Dispel: quita primero lo más prioritario.
	var j5 := _nuevo(1)
	j5.efectos.aplicar(j5.efecto(&"congelacion"), &"x")
	j5.efectos.aplicar(j5.efecto(&"veneno"), &"x")
	t.check(j5.efectos.dispel(1) == 1, "dispel quita un efecto")
	t.check(not j5.efectos.tiene(&"congelacion"), "quita primero el de mayor prioridad")

	# Tags con conteo de fuentes.
	var tg := Tags.new()
	tg.agregar("estado.aturdido")
	tg.agregar("estado.aturdido")
	tg.quitar("estado.aturdido")
	t.check(tg.tiene("estado.aturdido"), "dos fuentes y una que acaba dejan el tag activo")
	tg.quitar("estado.aturdido")
	t.check(not tg.tiene("estado.aturdido"), "al irse la última fuente, el tag se va")


# --------------------------------------------------------------------------
func _quests() -> void:
	var j := _nuevo(1)
	var d := j.diario

	t.check(d.validar().is_empty(), "las quests validan")
	t.check(d.estado(&"la_guarida") == Diario.Estado.LOCKED,
		"una quest con prerrequisito empieza bloqueada")
	t.check(d.estado(&"lobos_del_camino") == Diario.Estado.AVAILABLE,
		"una quest sin prerrequisitos está disponible")

	# Los objetivos avanzan SOLO por eventos del bus.
	t.check(d.aceptar(&"lobos_del_camino"), "se acepta la quest")
	for i in 5:
		j.bus.enemigo_muerto.emit(&"lobo", Vector2.ZERO)
	t.check(d.estado(&"lobos_del_camino") == Diario.Estado.COMPLETED,
		"los objetivos obligatorios completan la quest")
	t.check(d.estado(&"la_guarida") == Diario.Estado.AVAILABLE,
		"la cadena se desbloquea sola al completar el prerrequisito")

	# Transición inválida: se rechaza y se registra, sin ensuciar el log.
	t.check(not d.aceptar(&"lobos_del_camino"),
		"no se puede reaceptar una quest completada")
	t.check(d.ultimo_rechazo.contains("COMPLETED"),
		"el rechazo queda registrado con su motivo")

	# Entrega: recompensas atómicas.
	var oro0 := j.monedero.saldo(&"oro")
	var nivel0 := j.prog.nivel()
	t.check(d.entregar(&"lobos_del_camino", j.inv, j.monedero, j.prog),
		"se entrega la recompensa")
	t.check(j.monedero.saldo(&"oro") > oro0, "la recompensa pagó oro")
	t.check(j.prog.nivel() > nivel0, "la XP subió de nivel")
	t.check(d.estado(&"lobos_del_camino") == Diario.Estado.ENTREGADA, "queda entregada")

	# Secuencial: no se salta el orden.
	var j2 := _nuevo(1)
	j2.diario.aceptar(&"lobos_del_camino")
	for i in 5:
		j2.bus.enemigo_muerto.emit(&"lobo", Vector2.ZERO)
	j2.diario.aceptar(&"la_guarida")
	j2.bus.enemigo_muerto.emit(&"lobo_alfa", Vector2.ZERO)
	t.check(j2.diario.progreso_de(&"la_guarida", "jefe") == 0,
		"un objetivo secuencial no avanza fuera de orden")
	j2.bus.zona_alcanzada.emit(&"zona_guarida")
	j2.bus.enemigo_muerto.emit(&"lobo_alfa", Vector2.ZERO)
	t.check(j2.diario.progreso_de(&"la_guarida", "jefe") == 1,
		"tras el paso previo, el siguiente sí avanza")

	# Límite de tiempo.
	j2.diario.tick(700.0)
	t.check(j2.diario.estado(&"la_guarida") == Diario.Estado.FAILED,
		"se falla al agotarse el límite de tiempo")

	# Entregar con el inventario lleno: no se pierde la recompensa.
	var j3 := _nuevo(1)
	var inv_lleno := Inventario.new(j3.base, 1)
	inv_lleno.agregar(&"hoja_legendaria", 1)
	j3.diario.aceptar(&"lobos_del_camino")
	for i in 5:
		j3.bus.enemigo_muerto.emit(&"lobo", Vector2.ZERO)
	t.check(not j3.diario.entregar(&"lobos_del_camino", inv_lleno, j3.monedero, j3.prog),
		"con el inventario lleno no se entrega")
	t.check(j3.diario.estado(&"lobos_del_camino") == Diario.Estado.COMPLETED,
		"la quest sigue COMPLETED y se puede reintentar")


# --------------------------------------------------------------------------
func _loot() -> void:
	var a := _nuevo(777)
	var b := _nuevo(777)
	var c := _nuevo(778)

	var ta := _tiradas(a, 50)
	var tb := _tiradas(b, 50)
	var tc := _tiradas(c, 50)
	t.check(ta == tb, "la misma semilla produce exactamente el mismo loot")
	t.check(ta != tc, "semillas distintas producen loot distinto")

	# Garantizados: siempre caen.
	var j := _nuevo(3)
	var con_oro := 0
	for i in 30:
		for s in j.loot.tirar(&"loot_lobo"):
			if s.id == &"moneda_oro":
				con_oro += 1
	t.check(con_oro == 30, "el drop garantizado cae en las 30 tiradas (fue %d)" % con_oro)

	# Condición por nivel: sin nivel, la entrada no puede salir.
	var j2 := _nuevo(5)
	var legendarias := 0
	for i in 2000:
		for s in j2.loot.tirar(&"loot_lobo_alfa", {"nivel": 1}):
			if s.id == &"hoja_legendaria":
				legendarias += 1
	t.check(legendarias == 0, "una entrada condicionada no sale sin cumplir la condición")
	t.check(j2.loot.validar().is_empty(), "las tablas de loot validan")


func _borrar_saves() -> void:
	var dir := DirAccess.open("user://saves")
	if dir == null:
		return
	for f in dir.get_files():
		dir.remove(f)


func _tiradas(j: Juego, n: int) -> Array:
	var salida: Array = []
	for i in n:
		for s in j.loot.tirar(&"loot_bandido", {"nivel": 25}):
			salida.append("%s:%d" % [s.id, s.cantidad])
	return salida


# --------------------------------------------------------------------------
func _guardado() -> void:
	# Partir de cero: un save de una ejecución anterior haría el test
	# dependiente del orden en que se ejecutó, que es lo contrario de un test.
	_borrar_saves()

	# Migración encadenada v1 → v3.
	var viejo := {
		"version": 1,
		"meta": {"nivel": 5},
		"datos": {
			"inventario": {"capacidad": 20,
				"ranuras": {"0": {"id": "moneda_oro", "cantidad": 250},
							"1": {"id": "pocion_menor", "cantidad": 3}}},
			"habilidades": {"cooldowns": {"golpe": 2.5}},
		},
	}
	var nuevo := Guardado.migrar(viejo.duplicate(true))
	t.check(int(nuevo["version"]) == Guardado.SAVE_VERSION,
		"la migración llega a la versión actual")
	t.check(int(nuevo["datos"]["monedero"]["saldos"]["oro"]) == 250,
		"la migración v1→v2 extrajo el oro del inventario")
	t.check(not (nuevo["datos"]["inventario"]["ranuras"] as Dictionary).has("0"),
		"y lo quitó del inventario")
	t.check((nuevo["datos"]["inventario"]["ranuras"] as Dictionary).has("1"),
		"sin tocar el resto de ranuras")
	t.check((nuevo["datos"]["habilidades"]["cooldowns"] as Dictionary).has("golpe_pesado"),
		"la migración v2→v3 renombró la habilidad")

	# Un save de versión futura no se migra hacia atrás.
	var futuro := Guardado.migrar({"version": Guardado.SAVE_VERSION + 5, "datos": {}})
	t.check(int(futuro["version"]) == Guardado.SAVE_VERSION + 5,
		"una versión futura queda intacta (y `cargar` la rechaza)")

	# Ida y vuelta completa del estado real.
	var j := _nuevo(42)
	j.inv.agregar(&"pocion_menor", 7)
	j.inv.agregar(&"espada_hierro", 1)
	j.equipo.equipar(j.inv, &"mano_principal", &"espada_hierro")
	j.monedero.ingresar(&"oro", 1234, &"prueba")
	j.prog.ganar_xp(5000)
	j.diario.aceptar(&"hierro_para_bram")
	j.bus.item_entregado.emit(&"mineral_hierro", 3, &"herrero_bram")

	var antes := j.instantanea()
	t.check(j.guardado.guardar(0, j.meta()), "se guarda la partida")

	var j2 := _nuevo(42)
	t.check(j2.guardado.cargar(0), "se carga la partida")
	var dif := AyudaPruebas.diferencia(antes, j2.instantanea())
	t.check(dif == "", "el estado restaurado es IDÉNTICO (%s)" % dif)
	t.check(j2.equipo.equipado(&"mano_principal") == &"espada_hierro",
		"el equipo se restaura")
	t.check(is_equal_approx(j2.stats.valor(&"ataque"), j.stats.valor(&"ataque")),
		"los modificadores del equipo se REAPLICAN al cargar")
	t.check(j2.diario.progreso_de(&"hierro_para_bram", "traer") == 3,
		"el progreso parcial de la quest sobrevive")

	# Ranuras: se leen los metadatos SIN cargar la partida.
	var ranuras := j.guardado.listar_ranuras(3)
	t.check(ranuras.size() == 3, "se listan las tres ranuras")
	t.check(not bool(ranuras[0]["vacia"]), "la ranura 0 no está vacía")
	t.check(bool(ranuras[2]["vacia"]), "la ranura 2 sí lo está")
	t.check(int(ranuras[0]["nivel"]) == j.prog.nivel(),
		"los metadatos traen el nivel sin deserializar los sistemas")

	# Corrupción: se recupera del backup (el guardado anterior).
	t.check(j.guardado.guardar(0, j.meta()), "se guarda otra vez (crea backup)")
	var f := FileAccess.open("user://saves/slot_0.json", FileAccess.WRITE)
	f.store_string("{ esto no es json valido")
	f.close()
	var j3 := _nuevo(42)
	t.check(j3.guardado.cargar(0), "se recupera del backup tras corromper el save")
	t.check(j3.monedero.saldo(&"oro") == j.monedero.saldo(&"oro"),
		"el backup traía el estado correcto")

	# Un checksum manipulado invalida el save (y no hay backup del que tirar).
	t.check(j.guardado.guardar(2, j.meta()), "se guarda en la ranura 2")
	var lector := FileAccess.open("user://saves/slot_2.json", FileAccess.READ)
	var d = JSON.parse_string(lector.get_as_text())
	lector.close()
	d["checksum"] = "0000000000000000"
	var f2 := FileAccess.open("user://saves/slot_2.json", FileAccess.WRITE)
	f2.store_string(JSON.stringify(d))
	f2.close()
	var j4 := _nuevo(42)
	t.check(not j4.guardado.cargar(2), "un checksum incorrecto invalida el save")
