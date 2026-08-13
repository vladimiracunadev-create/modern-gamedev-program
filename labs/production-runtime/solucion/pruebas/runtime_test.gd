extends SceneTree

## Pruebas del runtime de producción (clases 311-317, 324).
##
##   godot --headless --path . --script res://pruebas/runtime_test.gd
##
## Ninguna necesita red, clave de API ni servicio: por eso pasan también en un
## fork y en una máquina sin acceso a internet.

var t := AyudaPruebas.new()
var _creados: Array = []


func _init() -> void:
	_offline()
	_caos()
	_config_y_flags()
	_telemetria()
	_migraciones()
	for r in _creados:
		r.liberar()
	_creados.clear()
	quit(t.resumen())


func _nuevo(mock: MockBackend, jugador: StringName = &"plr_demo") -> Runtime:
	var r := Runtime.nuevo(mock, jugador)
	_creados.append(r)
	return r


# --------------------------------------------------------------------------
func _offline() -> void:
	## La prueba más importante: el juego funciona SIN NADA.
	var mock := MockBackend.new(42)
	mock.modo = MockBackend.Modo.CAIDO
	var llamadas0 := mock.llamadas
	var r := _nuevo(mock)

	t.check(r.arranco(), "el runtime arranca sin conexión")
	t.check(r.puede_jugar(), "SE PUEDE JUGAR sin conexión")
	t.check(not r.hay_red(), "se detecta correctamente que no hay red")

	# Config: defectos compilados.
	t.check(is_equal_approx(r.cfg.get_float("multiplicador_xp"), 1.0),
		"la config usa los defectos compilados")
	t.check(r.cfg.origen("multiplicador_xp") == "defecto", "y lo dice al preguntarle")

	# Flags: lo desconocido está apagado.
	t.check(not r.flags.activo("nueva_ui"), "sin config remota, los flags están apagados")
	t.check(not r.flags.activo("flag_que_no_existe"), "un flag desconocido está apagado")

	# Guardado local: siempre funciona.
	r.guardado.borrar()
	r.guardado.datos["progresion"] = {"xp": 500}
	t.check(r.guardado.guardar(), "guardar en local funciona sin red")
	var g2 := GuardadoRuntime.new()
	t.check(g2.cargar(), "cargar en local funciona sin red")
	t.check(int(g2.datos["progresion"]["xp"]) == 500, "y trae el estado correcto")

	# Telemetría: se encola, no se pierde.
	t.check(r.tel.registrar("sesion_iniciada",
		{"plataforma": "linux", "build": "test", "primera_vez": true}),
		"la telemetría esencial se encola sin red")
	t.check(r.tel.pendientes() > 0, "los eventos quedan en cola")

	# Escrituras remotas encoladas.
	t.check(not r.backend.guardar_progreso(&"plr", {"xp": 1}, 1.0),
		"la escritura remota falla sin red")
	t.check(r.backend.pendientes() > 0, "y queda encolada")

	# Al volver la red, todo se envía.
	mock.modo = MockBackend.Modo.NORMAL
	r.backend.interruptor.reiniciar()
	r.sincronizar(100.0)
	t.check(r.tel.pendientes() == 0, "la cola de telemetría se vacía al recuperar la red")
	t.check(r.backend.pendientes() == 0, "y las escrituras pendientes también")
	t.check(mock.llamadas > llamadas0, "el proveedor ha recibido llamadas")


# --------------------------------------------------------------------------
func _caos() -> void:
	## Los seis modos de fallo. En TODOS el juego tiene que ser jugable.
	for modo in [MockBackend.Modo.NORMAL, MockBackend.Modo.ERROR_5XX,
			MockBackend.Modo.ERROR_4XX, MockBackend.Modo.CAIDO,
			MockBackend.Modo.CORRUPTO, MockBackend.Modo.INTERMITENTE]:
		var mock := MockBackend.new(7)
		mock.modo = modo
		mock.probabilidad_fallo = 0.5
		var r := _nuevo(mock)
		var nombre := mock.modo_nombre()

		t.check(r.arranco(), "arranca en modo %s" % nombre)
		t.check(r.puede_jugar(), "se puede jugar en modo %s" % nombre)
		r.guardado.borrar()
		t.check(r.guardado.guardar(), "guarda en local en modo %s" % nombre)
		# Un 200 con basura dentro no puede colarse en la config.
		t.check(is_equal_approx(r.cfg.get_float("multiplicador_xp"),
				2.0 if modo == MockBackend.Modo.NORMAL or modo == MockBackend.Modo.INTERMITENTE
				else 1.0)
			or modo == MockBackend.Modo.INTERMITENTE,
			"la config es coherente en modo %s" % nombre)

	# Reintentos: solo lo idempotente, y con tope.
	var m2 := MockBackend.new(1)
	m2.modo = MockBackend.Modo.ERROR_5XX
	var r2 := _nuevo(m2)
	r2.backend.interruptor.reiniciar()
	var antes := m2.llamadas
	r2.backend.obtener_perfil(&"plr", 0.0)
	t.check(m2.llamadas - antes == Backend.MAX_INTENTOS,
		"una lectura idempotente reintenta exactamente %d veces" % Backend.MAX_INTENTOS)

	# Un 404 NO se reintenta: reintentar daría el mismo error.
	m2.modo = MockBackend.Modo.ERROR_4XX
	r2.backend.interruptor.reiniciar()
	antes = m2.llamadas
	r2.backend.obtener_perfil(&"plr", 0.0)
	t.check(m2.llamadas - antes == 1, "un 404 no se reintenta")

	# El interruptor corta: deja de golpear un servicio caído.
	var m3 := MockBackend.new(1)
	m3.modo = MockBackend.Modo.CAIDO
	var r3 := _nuevo(m3)
	r3.backend.interruptor.reiniciar()
	# Se cuentan por separado las 10 primeras operaciones y las 10 siguientes:
	# lo que importa no es cuántas llamadas se hacen antes de abrir, sino que
	# DESPUÉS de abrir no se haga ni una más.
	var antes_apertura := m3.llamadas
	for i in 10:
		r3.backend.obtener_perfil(&"plr", 1.0)
	var durante := m3.llamadas - antes_apertura
	var tope := Backend.MAX_INTENTOS * r3.backend.interruptor.umbral_fallos
	t.check(durante <= tope,
		"antes de abrir se hacen como mucho %d llamadas (fueron %d)" % [tope, durante])
	t.check(r3.backend.interruptor.estado() == Interruptor.Estado.ABIERTO,
		"el interruptor queda ABIERTO")

	var tras_apertura := m3.llamadas
	for i in 10:
		r3.backend.obtener_perfil(&"plr", 1.0)
	t.check(m3.llamadas == tras_apertura,
		"con el interruptor abierto NO se llama al proveedor ni una vez")

	# Y se recupera solo pasado el tiempo de espera.
	m3.modo = MockBackend.Modo.NORMAL
	var resp := r3.backend.obtener_perfil(&"plr", 1.0 + r3.backend.interruptor.espera_reintento)
	t.check(resp.ok and resp.origen == "red", "pasado el tiempo, vuelve a intentarlo")
	t.check(r3.backend.interruptor.estado() == Interruptor.Estado.CERRADO,
		"y una respuesta correcta lo cierra")

	# Caché: con el servicio caído se sirve lo último conocido, marcado.
	var m4 := MockBackend.new(1)
	var r4 := _nuevo(m4)
	var buena := r4.backend.obtener_perfil(&"plr", 0.0)
	t.check(buena.ok and buena.origen == "red", "primera lectura desde la red")
	m4.modo = MockBackend.Modo.CAIDO
	r4.backend.interruptor.reiniciar()
	var cacheada := r4.backend.obtener_perfil(&"plr", 0.0)
	t.check(cacheada.ok, "con el servicio caído sigue habiendo respuesta")
	t.check(cacheada.origen == "cache", "y viene marcada como de caché")


# --------------------------------------------------------------------------
func _config_y_flags() -> void:
	var cfg := Config.new()
	var rechazos: Array = []
	cfg.rechazada.connect(func(c, _m): rechazos.append(c))

	cfg.aplicar_remoto({"valores": {
		"multiplicador_xp": 2.0,      # válido
		"precio_pocion": -5,          # fuera de rango
		"dificultad_por_defecto": "imposible",  # fuera de la lista
		"clave_inventada": 1,         # desconocida
		"intervalo_autosave": "mucho",  # tipo incorrecto
	}})
	t.check(is_equal_approx(cfg.get_float("multiplicador_xp"), 2.0),
		"un valor válido se adopta")
	t.check(cfg.get_int("precio_pocion") == 15, "un valor fuera de rango se rechaza")
	t.check(cfg.get_str("dificultad_por_defecto") == "normal",
		"un valor fuera de la lista se rechaza")
	t.check(is_equal_approx(cfg.get_float("intervalo_autosave"), 120.0),
		"un tipo incorrecto se rechaza")
	t.check(rechazos.size() == 4, "se rechazaron los cuatro valores inválidos (fueron %d)"
		% rechazos.size())

	# Payload corrupto: se rechaza entero y se sigue con los defectos.
	var cfg2 := Config.new()
	cfg2.aplicar_remoto({"valores": "<<basura>>"})
	t.check(is_equal_approx(cfg2.get_float("multiplicador_xp"), 1.0),
		"un payload corrupto no toca la configuración")

	# Flags: determinismo y distribución.
	var payload := {"flags": {"nueva_ui": {"activo": true, "porcentaje": 50, "sal": "v1"}}}
	var f1 := Flags.new(&"plr_abc")
	var f2 := Flags.new(&"plr_abc")
	f1.configurar(payload)
	f2.configurar(payload)
	t.check(f1.activo("nueva_ui") == f2.activo("nueva_ui"),
		"el mismo jugador cae siempre en el mismo grupo")

	var dentro := 0
	for i in 10000:
		var f := Flags.new(StringName("plr_%d" % i))
		f.configurar(payload)
		if f.activo("nueva_ui"):
			dentro += 1
	t.check(absi(dentro - 5000) < 300,
		"un rollout al 50%% activa entre el 47%% y el 53%% (fue %d de 10000)" % dentro)

	# Sales distintas reparten a jugadores distintos.
	var coincidencias := 0
	for i in 1000:
		var jugador := StringName("plr_%d" % i)
		var a := Flags.bucket("sal_a", jugador) < 50
		var b := Flags.bucket("sal_b", jugador) < 50
		if a == b:
			coincidencias += 1
	t.check(absi(coincidencias - 500) < 80,
		"dos sales distintas no asignan al mismo conjunto (%d/1000 coinciden)" % coincidencias)

	# Kill switch: gana a todo.
	var f3 := Flags.new(&"plr_abc")
	f3.configurar({"flags": {"nueva_ui": {"activo": true, "porcentaje": 100, "kill": true}}})
	t.check(not f3.activo("nueva_ui"), "el kill switch apaga el flag aunque esté al 100%")

	# El override no existe en release.
	var cfg3 := Config.new()
	cfg3.permite_override = false
	t.check(not cfg3.forzar("multiplicador_xp", 5.0),
		"el override no tiene efecto en una build de release")


# --------------------------------------------------------------------------
func _telemetria() -> void:
	var tel := Telemetria.new(3)
	t.check(tel.cargar_taxonomia("res://datos/taxonomia.json").is_empty(),
		"la taxonomía valida")
	var rechazos: Array = []
	tel.evento_rechazado.connect(func(n, m): rechazos.append("%s: %s" % [n, m]))

	# Por defecto, la analítica NO está permitida.
	t.check(not tel.registrar("nivel_completado",
		{"nivel_id": "n1", "segundos": 40, "muertes": 2, "dificultad": "normal"}),
		"sin consentimiento no se registra analítica")
	t.check(tel.pendientes() == 0, "y no entra nada en la cola")

	tel.fijar_consentimiento("analitica", true)
	t.check(tel.registrar("nivel_completado",
		{"nivel_id": "n1", "segundos": 40, "muertes": 2, "dificultad": "normal"}),
		"con consentimiento sí se registra")

	# Evento no declarado.
	t.check(not tel.registrar("evento_inventado", {}),
		"un evento fuera de la taxonomía se rechaza")

	# Campo prohibido: se rechaza el evento ENTERO.
	var antes := tel.pendientes()
	t.check(not tel.registrar("nivel_completado", {"nivel_id": "n1", "email": "a@b.c"}),
		"un campo prohibido rechaza el evento entero")
	t.check(tel.pendientes() == antes, "y no entra nada en la cola")

	# Campo no declarado: se descarta el campo, el evento pasa limpio.
	t.check(tel.registrar("nivel_completado", {"nivel_id": "n1", "extra": 1}),
		"un campo no declarado no tumba el evento")
	var ultimo: Dictionary = tel.cola()[tel.pendientes() - 1]
	t.check(not (ultimo["p"] as Dictionary).has("extra"),
		"pero el campo no llega a la cola")

	# Valor fuera de rango.
	t.check(tel.registrar("nivel_completado", {"nivel_id": "n1", "segundos": -5}),
		"un valor fuera de rango no tumba el evento")
	ultimo = tel.cola()[tel.pendientes() - 1]
	t.check(not (ultimo["p"] as Dictionary).has("segundos"),
		"pero el valor inválido se descarta")

	# Ningún evento de la cola lleva un campo prohibido.
	var limpia := true
	for ev in tel.cola():
		for clave in ev["p"]:
			if str(clave).to_lower() in Telemetria.PROHIBIDOS:
				limpia = false
	t.check(limpia, "ningún evento en cola contiene un campo prohibido")

	# Todos llevan su versión.
	var con_version := true
	for ev in tel.cola():
		if not ev.has("v"):
			con_version = false
	t.check(con_version, "todos los eventos llevan su número de versión")

	# "esencial" no se puede desactivar.
	t.check(not tel.fijar_consentimiento("esencial", false),
		"el consentimiento esencial no se puede desactivar")

	# Olvidar: rota el seudónimo y vacía la cola.
	var sid := tel.seudonimo()
	tel.olvidar()
	t.check(tel.seudonimo() != sid, "olvidar rota el seudónimo")
	t.check(tel.pendientes() == 0, "y vacía la cola")

	t.check(rechazos.size() >= 4, "se registraron los rechazos con su motivo")


# --------------------------------------------------------------------------
func _migraciones() -> void:
	var v1 := {
		"version": 1,
		"datos": {"progresion": {"xp": 900, "oro": 350, "volumen": 0.8, "idioma": "es"}},
	}
	var m := GuardadoRuntime.migrar(v1.duplicate(true))
	t.check(int(m["version"]) == GuardadoRuntime.SAVE_VERSION,
		"la migración llega a la versión actual")
	t.check((m["datos"]["ajustes"] as Dictionary).has("volumen"),
		"v1→v2 movió los ajustes fuera de progresión")
	t.check(not (m["datos"]["progresion"] as Dictionary).has("volumen"),
		"y los quitó de allí")
	t.check(int(m["datos"]["monedero"]["oro"]) == 350,
		"v2→v3 creó el monedero con el oro que había")
	t.check(int(m["datos"]["progresion"]["xp"]) == 900, "sin tocar la XP")
	t.check(m.has("sync"), "y añadió los metadatos de sincronización")

	# Ida y vuelta en disco.
	var g := GuardadoRuntime.new()
	g.borrar()
	g.datos = {"progresion": {"xp": 1234}, "ajustes": {"idioma": "es"}, "monedero": {"oro": 77}}
	t.check(g.guardar(), "se guarda")
	var g2 := GuardadoRuntime.new()
	t.check(g2.cargar(), "se carga")
	# Se compara la forma SERIALIZADA, no los diccionarios: JSON no distingue
	# enteros de flotantes, así que un 1234 vuelve como 1234.0 y la comparación
	# directa de Variant falla aunque el dato sea el mismo. Es el detalle que
	# más tiempo hace perder al depurar un guardado (clase 307).
	t.check(JSON.stringify(g2.datos) == JSON.stringify(g.datos),
		"el estado restaurado es idéntico")
	t.check(g2.version_local == g.version_local, "y el contador de versión también")

	# Un save de versión futura se rechaza sin romper nada.
	var f := FileAccess.open(GuardadoRuntime.RUTA, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": GuardadoRuntime.SAVE_VERSION + 9, "datos": {}}))
	f.close()
	var g3 := GuardadoRuntime.new()
	t.check(not g3.cargar(), "un save de versión futura se rechaza")

	# Un save ilegible tampoco rompe.
	var f2 := FileAccess.open(GuardadoRuntime.RUTA, FileAccess.WRITE)
	f2.store_string("{ no soy json")
	f2.close()
	var g4 := GuardadoRuntime.new()
	t.check(not g4.cargar(), "un save ilegible se rechaza sin lanzar errores")
	g4.borrar()
