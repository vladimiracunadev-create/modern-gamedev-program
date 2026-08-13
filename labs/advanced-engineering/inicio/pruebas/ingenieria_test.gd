extends SceneTree

## Pruebas de ingeniería avanzada (clases 339-342).
##
##   godot --headless --path . --script res://pruebas/ingenieria_test.gd
##
## Todo lo de aquí es verificable SIN GPU, que es el requisito para estar en
## CI. Lo que necesita tarjeta gráfica está documentado en el README del lab,
## no escondido en un test que se salta.

const N := 100000
const N_ESPACIAL := 5000

var t := AyudaPruebas.new()


func _init() -> void:
	_dod()
	_memoria()
	_espacial()
	_jobs()
	quit(t.resumen())


# --------------------------------------------------------------------------
func _dod() -> void:
	# CORRECCIÓN primero: SoA y AoS deben dar el mismo resultado.
	var soa := Particulas.new()
	soa.crear(2000, 7)
	var aos := Particulas.crear_aos(2000, 7)
	for i in 50:
		soa.avanzar(0.016)
		Particulas.avanzar_aos(aos, 0.016)
	t.check(soa.equivalente_a(aos), "SoA y AoS dan el mismo resultado tras 50 pasos")

	# Compactación: no pierde ni duplica.
	var p := Particulas.new()
	p.crear(1000, 3)
	var vivas0 := p.vivas
	for i in 20:
		p.avanzar(0.05)
	var muertas := p.compactar()
	t.check(p.vivas + muertas == vivas0,
		"compactar no pierde ni duplica entidades (%d + %d = %d)" % [p.vivas, muertas, vivas0])
	t.check(p.vivas <= vivas0, "el número de vivas nunca crece")

	# Todas las vivas tienen vida positiva: el bucle caliente no necesita ramas.
	var todas_vivas := true
	for i in p.vivas:
		if p.vida[i] <= 0.0:
			todas_vivas = false
	t.check(todas_vivas, "tras compactar, [0, vivas) solo contiene partículas vivas")

	# RENDIMIENTO: SoA debe ser claramente más rápido con volumen.
	var grande := Particulas.new()
	grande.crear(N, 1)
	var aos_grande := Particulas.crear_aos(N, 1)
	var ms_soa := AyudaPruebas.medir(func(): grande.avanzar(0.016))
	var ms_aos := AyudaPruebas.medir(func(): Particulas.avanzar_aos(aos_grande, 0.016))
	print("  DOD %d partículas: SoA %.2f ms · AoS %.2f ms · ×%.1f"
		% [N, ms_soa, ms_aos, ms_aos / maxf(ms_soa, 0.001)])
	t.check(ms_soa < ms_aos,
		"SoA es más rápido que AoS (%.2f vs %.2f ms)" % [ms_soa, ms_aos])
	t.check(ms_soa < 25.0,
		"el presupuesto de %d partículas se cumple (%.2f ms)" % [N, ms_soa])


# --------------------------------------------------------------------------
func _memoria() -> void:
	var fabrica := func(): return PoolObjetos.Elemento.new()
	var reset := func(o): o.reiniciar()
	var pool := PoolObjetos.new(fabrica, reset, 12000)
	t.check(pool.creados == 12000, "el pool precrea lo que se le pide")

	# 10.000 ciclos obtener/devolver sin crear ni un objeto más.
	var creados0 := pool.creados
	for i in 10000:
		var o: PoolObjetos.Elemento = pool.obtener()
		o.x = float(i)
		o.activo = true
		pool.devolver(o)
	t.check(pool.creados == creados0,
		"10.000 ciclos no crean ni un objeto más (creados: %d)" % pool.creados)
	t.check(pool.en_uso() == 0, "no queda nada en uso")

	# Un objeto devuelto no conserva el estado anterior.
	var o2: PoolObjetos.Elemento = pool.obtener()
	t.check(not o2.activo and is_equal_approx(o2.x, 0.0),
		"un objeto del pool viene limpio")
	pool.devolver(o2)

	# Devolver algo que no salió del pool se detecta.
	t.check(not pool.devolver(PoolObjetos.Elemento.new()),
		"se detecta una devolución de un objeto ajeno")
	t.check(not pool.devolver(null), "y una devolución nula")

	# Objetos distintos con el MISMO contenido son objetos distintos: es lo que
	# rompía el pool cuando se indexaba por valor en vez de por identidad.
	var a: PoolObjetos.Elemento = pool.obtener()
	var b: PoolObjetos.Elemento = pool.obtener()
	t.check(pool.en_uso() == 2, "dos objetos idénticos en contenido cuentan como dos")
	pool.devolver(a)
	pool.devolver(b)

	# Desbordar el pool se registra en vez de ocultarse.
	var pequeno := PoolObjetos.new(fabrica, reset, 2)
	pequeno.obtener()
	pequeno.obtener()
	pequeno.obtener()
	t.check(pequeno.desbordes == 1, "el desbordamiento del pool se registra")

	# Rendimiento: pool frente a crear objetos nuevos.
	var ms_pool := AyudaPruebas.medir(func():
		var tmp: Array = []
		for i in 10000:
			tmp.append(pool.obtener())
		for o in tmp:
			pool.devolver(o))
	var ms_nuevo := AyudaPruebas.medir(func():
		var tmp: Array = []
		for i in 10000:
			tmp.append(PoolObjetos.Elemento.new()))
	print("  Memoria 10k objetos: pool %.2f ms · nuevos %.2f ms · ×%.1f"
		% [ms_pool, ms_nuevo, ms_nuevo / maxf(ms_pool, 0.001)])

	# Arena: marcas y liberación total.
	var arena := Arena.new(100, func(): return {"v": 0})
	for i in 40:
		arena.asignar()
	var m := arena.marca()
	for i in 30:
		arena.asignar()
	t.check(arena.usados() == 70, "la arena lleva la cuenta de lo asignado")
	arena.liberar_hasta(m)
	t.check(arena.usados() == 40, "liberar hasta la marca libera exactamente eso")
	arena.reiniciar()
	t.check(arena.usados() == 0, "reiniciar libera todo de golpe")
	for i in 200:
		arena.asignar()
	t.check(arena.desbordes > 0, "la arena registra el desbordamiento en vez de crecer")


# --------------------------------------------------------------------------
func _espacial() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var px := PackedFloat32Array()
	var py := PackedFloat32Array()
	px.resize(N_ESPACIAL)
	py.resize(N_ESPACIAL)
	for i in N_ESPACIAL:
		# Incluye coordenadas NEGATIVAS a propósito: es donde `int()` en vez
		# de `floor()` mete objetos en la celda equivocada.
		px[i] = rng.randf_range(-2000.0, 2000.0)
		py[i] = rng.randf_range(-2000.0, 2000.0)

	var rejilla := RejillaUniforme.new(50.0)
	rejilla.construir(px, py)
	var hash_esp := HashEspacial.new(50.0)
	hash_esp.construir(px, py)

	# CORRECCIÓN: mismo resultado que la fuerza bruta, en 200 consultas.
	var iguales_rejilla := 0
	var iguales_hash := 0
	for c in 200:
		var x := rng.randf_range(-2000.0, 2000.0)
		var y := rng.randf_range(-2000.0, 2000.0)
		var ref := RejillaUniforme.fuerza_bruta(px, py, x, y, 60.0)
		ref.sort()
		if rejilla.consultar_radio(x, y, 60.0) == ref:
			iguales_rejilla += 1
		if hash_esp.consultar_radio(x, y, 60.0) == ref:
			iguales_hash += 1
	t.check(iguales_rejilla == 200,
		"la rejilla da el mismo resultado que la fuerza bruta (%d/200)" % iguales_rejilla)
	t.check(iguales_hash == 200,
		"el hash espacial también (%d/200)" % iguales_hash)

	# Mover no rompe la estructura.
	for i in 500:
		rejilla.mover(i, px[i] + 300.0, py[i] - 200.0)
	var ref2 := RejillaUniforme.fuerza_bruta(px, py, 0.0, 0.0, 100.0)
	ref2.sort()
	t.check(rejilla.consultar_radio(0.0, 0.0, 100.0) == ref2,
		"tras mover 500 objetos, la rejilla sigue siendo correcta")

	# RENDIMIENTO.
	var ms_bruta := AyudaPruebas.medir(func():
		for c in 200:
			RejillaUniforme.fuerza_bruta(px, py, 0.0, 0.0, 60.0))
	var ms_rejilla := AyudaPruebas.medir(func():
		for c in 200:
			rejilla.consultar_radio(0.0, 0.0, 60.0))
	print("  Espacial %d objetos, 200 consultas: fuerza bruta %.2f ms · rejilla %.2f ms · ×%.1f"
		% [N_ESPACIAL, ms_bruta, ms_rejilla, ms_bruta / maxf(ms_rejilla, 0.001)])
	t.check(ms_rejilla * 5.0 < ms_bruta,
		"la rejilla es al menos 5 veces más rápida (%.2f vs %.2f ms)" % [ms_rejilla, ms_bruta])

	# El hash no reserva memoria para el vacío.
	t.check(hash_esp.cubos_ocupados() <= rejilla.celdas_ocupadas() + 1,
		"el hash espacial no ocupa más cubos que celdas la rejilla")


# --------------------------------------------------------------------------
func _jobs() -> void:
	var n := 200000

	# CORRECCIÓN: paralelo y secuencial dan EXACTAMENTE lo mismo.
	var a := Paralelo.new()
	a.crear(n, 5)
	a.trabajo_secuencial()
	var hash_sec := a.hash_salida()

	var b := Paralelo.new()
	b.crear(n, 5)
	b.trabajo_paralelo()
	t.check(b.hash_salida() == hash_sec, "paralelo y secuencial dan el mismo resultado")

	# La reducción con acumulador local también.
	var sec := b.contar_secuencial(2.0)
	var par := b.contar_paralelo(2.0)
	t.check(sec == par, "la reducción paralela cuenta lo mismo (%d vs %d)" % [sec, par])

	# DETERMINISMO: una carrera aparece una vez de cada mil, así que una sola
	# pasada no prueba nada.
	var estable := true
	for i in 50:
		b.trabajo_paralelo()
		if b.hash_salida() != hash_sec or b.contar_paralelo(2.0) != sec:
			estable = false
	t.check(estable, "50 ejecuciones paralelas dan exactamente el mismo resultado")

	# Grafo de tareas: detecta ciclos.
	var g := GrafoDeTareas.new()
	g.agregar("a", func(): pass, ["b"])
	g.agregar("b", func(): pass, ["a"])
	t.check(not g.validar().is_empty(), "el grafo detecta un ciclo de dependencias")

	# Y respeta el orden de las dependencias.
	var orden: Array = []
	var g2 := GrafoDeTareas.new()
	g2.agregar("render", func(): orden.append("render"), ["culling", "particulas"])
	g2.agregar("culling", func(): orden.append("culling"), ["transformadas"])
	g2.agregar("particulas", func(): orden.append("particulas"), ["transformadas"])
	g2.agregar("transformadas", func(): orden.append("transformadas"), ["ia", "fisica"])
	g2.agregar("ia", func(): orden.append("ia"))
	g2.agregar("fisica", func(): orden.append("fisica"))
	t.check(g2.validar().is_empty(), "el grafo del frame valida")
	g2.ejecutar()
	t.check(orden.find("transformadas") > orden.find("ia")
		and orden.find("transformadas") > orden.find("fisica"),
		"las transformadas van después de IA y física")
	t.check(orden.find("render") > orden.find("culling")
		and orden.find("render") > orden.find("particulas"),
		"el render va el último")
	t.check(orden.size() == 6, "se ejecutan los seis nodos")

	# Dependencia inexistente.
	var g3 := GrafoDeTareas.new()
	g3.agregar("x", func(): pass, ["no_existe"])
	t.check(not g3.validar().is_empty(), "una dependencia inexistente se detecta")

	# ESCALADO. El número se IMPRIME, pero lo que se comprueba es que el
	# paralelo no se desploma — no que gane.
	#
	# La diferencia importa. `OS.get_processor_count()` cuenta hilos lógicos, y
	# en una máquina virtual compartida (cualquier runner de CI) esos hilos ni
	# son núcleos físicos ni están disponibles enteros: medido en el runner de
	# este repositorio, 4 «núcleos» dan ×0.98. Exigir una aceleración concreta
	# convierte el test en una lotería del hardware, y un test que falla por
	# motivos ajenos al código acaba desactivado — que es peor que no tenerlo.
	#
	# Lo que sí se puede exigir, y aquí se exige, es que repartir el trabajo no
	# cueste MÁS que hacerlo entero: eso sí sería una regresión real del código.
	var ms_sec := AyudaPruebas.medir(func(): a.trabajo_secuencial(), 5, 1)
	var ms_par := AyudaPruebas.medir(func(): b.trabajo_paralelo(), 5, 1)
	var nucleos := OS.get_processor_count()
	var factor := ms_sec / maxf(ms_par, 0.001)
	print("  Jobs %d elementos (%d hilos lógicos): secuencial %.2f ms · paralelo %.2f ms · ×%.2f"
		% [n, nucleos, ms_sec, ms_par, factor])
	if factor < 1.2:
		print("    (sin ganancia: hilos compartidos o poco trabajo por elemento — clase 341)")
	t.check(ms_par < ms_sec * 1.5,
		"el reparto no cuesta más que el trabajo (×%.2f, mínimo aceptable ×0.67)" % factor)
