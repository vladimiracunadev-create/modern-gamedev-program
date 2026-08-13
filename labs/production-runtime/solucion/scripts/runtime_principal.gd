extends Node

## Escena principal: construye el runtime y demuestra la degradación.

var runtime: Runtime


func _ready() -> void:
	# Sin variables de entorno, sin claves y sin red: el proveedor por defecto
	# es el mock. Es exactamente lo que hace la CI.
	var mock := MockBackend.new(1234)
	runtime = Runtime.nuevo(mock)

	if not runtime.arranco():
		for e in runtime.errores_arranque:
			printerr("ARRANQUE: ", e)
		push_error("el runtime no arrancó: %d error(es)" % runtime.errores_arranque.size())
		return

	_demostrar_degradacion(mock)

	print("Runtime construido: %d claves de config, %d flags, %d eventos de telemetría"
		% [runtime.cfg.total(), runtime.flags.total(), runtime.tel.total_eventos()])


func _demostrar_degradacion(mock: MockBackend) -> void:
	## Recorre los modos de fallo y comprueba que en todos se puede jugar.
	var linea := PackedStringArray()
	for modo in [MockBackend.Modo.NORMAL, MockBackend.Modo.ERROR_5XX,
			MockBackend.Modo.CAIDO, MockBackend.Modo.CORRUPTO]:
		mock.modo = modo
		runtime.backend.interruptor.reiniciar()
		runtime.sincronizar(0.0)
		var jugable := runtime.puede_jugar() and runtime.guardado.guardar()
		linea.append("%s=%s" % [mock.modo_nombre(), "jugable" if jugable else "ROTO"])
	mock.modo = MockBackend.Modo.NORMAL
	print("  degradación: %s" % " · ".join(linea))
	print("  xp=%.1f (%s) · tienda_online=%s · evento_invierno=%s (kill switch)"
		% [runtime.cfg.get_float("multiplicador_xp"),
		   runtime.cfg.origen("multiplicador_xp"),
		   runtime.flags.activo("tienda_online"),
		   runtime.flags.activo("evento_invierno")])


func _exit_tree() -> void:
	if runtime != null:
		runtime.liberar()
		runtime = null
