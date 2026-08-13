extends Node

## Escena principal del laboratorio. Construye el juego, ejercita el bucle
## sistémico completo e imprime el marcador que la CI busca.

var juego: Juego


func _ready() -> void:
	juego = Juego.nuevo(12345)

	# El contenido se valida al arrancar y DETIENE el juego si hay errores
	# graves: un catálogo roto no puede llegar a la partida de nadie.
	if not juego.errores_contenido.is_empty():
		for e in juego.errores_contenido:
			printerr("CONTENIDO: ", e)
		push_error("el contenido no valida: %d error(es)" % juego.errores_contenido.size())
		return

	_demostrar_bucle_sistemico()

	print("Mundo construido: %d items, %d quests, %d tablas de loot"
		% [juego.base.todos().size(), juego.diario.total(), juego.loot.total()])


func _demostrar_bucle_sistemico() -> void:
	## Matar → loot → quest → XP → crafteo → equipo → stats, todo por eventos.
	juego.diario.aceptar(&"lobos_del_camino")
	for i in 5:
		juego.bus.enemigo_muerto.emit(&"lobo", Vector2.ZERO)

	if juego.diario.estado(&"lobos_del_camino") == Diario.Estado.COMPLETED:
		juego.diario.entregar(&"lobos_del_camino", juego.inv, juego.monedero, juego.prog)

	juego.inv.agregar(&"espada_hierro", 1)
	juego.equipo.equipar(juego.inv, &"mano_principal", &"espada_hierro")

	juego.habilidades.activar(&"golpe_pesado", ["enemigo"], 2.0)
	for i in 30:
		juego.tick(0.1)

	print("  bucle: nivel %d · oro %d · ataque %.1f · quest %s"
		% [juego.prog.nivel(), juego.monedero.saldo(&"oro"),
		   juego.stats.valor(&"ataque"),
		   Diario.Estado.keys()[juego.diario.estado(&"lobos_del_camino")]])


func _process(delta: float) -> void:
	if juego != null and juego.errores_contenido.is_empty():
		juego.tick(delta)


func _exit_tree() -> void:
	# Sin esto, los ciclos de referencia del composition root sobreviven al
	# cierre y el motor avisa de instancias filtradas (clase 340).
	if juego != null:
		juego.liberar()
		juego = null
