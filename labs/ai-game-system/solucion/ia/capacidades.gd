class_name Capacidades
extends RefCounted

## Mínima capacidad por NPC (clase 336).
##
## Es la defensa que SÍ es fiable, porque no depende de que el modelo obedezca:
## un aldeano no puede dar items, punto. Que el jugador le convenza es
## irrelevante — el ejecutor no tiene esa opción.

var intenciones_permitidas: Array = ["ninguna", "reaccion"]
var items_que_puede_dar: Array = []
var quests_ofrecibles: Array = []
var puede_abrir_tienda: bool = false
var max_items: int = 1


func puede(intencion: String) -> bool:
	return intenciones_permitidas.has(intencion)


static func desde(npc: Dictionary, estado: Dictionary) -> Capacidades:
	var c := Capacidades.new()
	var caps: Dictionary = npc.get("capacidades", {})
	c.intenciones_permitidas = caps.get("intenciones", ["ninguna", "reaccion"])
	c.items_que_puede_dar = caps.get("items_que_puede_dar", [])
	c.puede_abrir_tienda = bool(caps.get("puede_abrir_tienda", false))
	c.max_items = int(caps.get("max_items", 1))
	# Las quests ofrecibles salen del ESTADO del juego, no del archivo del NPC:
	# lo que puede ofrecer ahora mismo lo decide el diario, no el modelo.
	c.quests_ofrecibles = estado.get("quests_ofrecibles", [])
	return c
