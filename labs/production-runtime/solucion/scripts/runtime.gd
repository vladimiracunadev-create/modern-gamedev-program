class_name Runtime
extends RefCounted

## Composition root del runtime de producción (clase 324).
##
## El orden importa: observabilidad → configuración con defectos → telemetría
## → backend → guardado. Si algo falla después, queremos poder verlo; y el
## juego tiene que ser jugable desde el primer instante, sin esperar a la red.

var cfg: Config
var flags: Flags
var tel: Telemetria
var backend: Backend
var guardado: GuardadoRuntime
var mock: MockBackend

var errores_arranque: Array = []
var degradaciones: Array = []


static func nuevo(proveedor: MockBackend, jugador: StringName = &"plr_demo") -> Runtime:
	var r := Runtime.new()
	r._construir(proveedor, jugador)
	return r


func _construir(proveedor: MockBackend, jugador: StringName) -> void:
	mock = proveedor

	# 1) CONFIGURACIÓN con defectos compilados: el juego ya puede funcionar.
	cfg = Config.new()
	flags = Flags.new(jugador)

	# 2) TELEMETRÍA gobernada por consentimiento.
	tel = Telemetria.new(7)
	errores_arranque.append_array(tel.cargar_taxonomia("res://datos/taxonomia.json"))

	# 3) BACKEND: el juego no sabe si detrás hay un servicio real o un mock.
	backend = Backend.new(proveedor)
	backend.degradado.connect(func(m): degradaciones.append(m))

	# 4) GUARDADO local: siempre disponible, con o sin red.
	guardado = GuardadoRuntime.new()

	# 5) Sincronización remota que NO bloquea. Si falla, seguimos con los
	#    defectos y la caché — que es el modo normal, no una excepción.
	sincronizar(0.0)


func sincronizar(ahora: float) -> void:
	var r := backend.obtener_config(ahora)
	if r.ok and r.origen != "defecto":
		cfg.aplicar_remoto(r.datos)
		flags.configurar(r.datos)
	tel.vaciar_hacia(backend.proveedor)
	backend.reenviar_pendientes(ahora)


func hay_red() -> bool:
	return backend.interruptor.estado() != Interruptor.Estado.ABIERTO \
		and backend.proveedor.disponible()


func puede_jugar() -> bool:
	## La pregunta que resume el laboratorio: pase lo que pase con el backend,
	## esto tiene que devolver `true`.
	return cfg != null and guardado != null


func arranco() -> bool:
	return errores_arranque.is_empty()


func liberar() -> void:
	if backend != null:
		for c in backend.degradado.get_connections():
			backend.degradado.disconnect(c["callable"])
