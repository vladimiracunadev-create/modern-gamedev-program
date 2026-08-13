class_name Equipo
extends RefCounted

## Equipamiento con slots, restricciones y operaciones atómicas (clase 296).

signal slot_cambiado(slot: StringName, id: StringName)

const SLOTS := {
	&"cabeza": [Item.Tipo.ARMADURA],
	&"torso": [Item.Tipo.ARMADURA],
	&"mano_principal": [Item.Tipo.ARMA],
	&"mano_secundaria": [Item.Tipo.ARMA, Item.Tipo.ARMADURA],
}

var _base: BaseDeItems
var _stats: Stats
var _puesto := {}


func _init(base: BaseDeItems, stats: Stats) -> void:
	_base = base
	_stats = stats


func admite(slot: StringName, id: StringName) -> bool:
	if not SLOTS.has(slot) or not _base.existe(id):
		return false
	var d := _base.obtener(id)
	if not SLOTS[slot].has(d.tipo):
		return false
	if d.tiene_tag("dos_manos"):
		return slot == &"mano_principal"
	return true


func equipado(slot: StringName) -> StringName:
	return _puesto.get(slot, &"")


func equipar(inv: Inventario, slot: StringName, id: StringName) -> bool:
	if not admite(slot, id) or inv.contar(id) < 1:
		return false

	var anterior: StringName = _puesto.get(slot, &"")
	var d := _base.obtener(id)
	var a_devolver: Array = []
	if anterior != &"":
		a_devolver.append([slot, anterior])
	if d.tiene_tag("dos_manos") and _puesto.get(&"mano_secundaria", &"") != &"":
		a_devolver.append([&"mano_secundaria", _puesto[&"mano_secundaria"]])

	# Se comprueba el hueco ANTES de tocar nada: si no, el jugador se queda sin
	# el item que entra y sin sitio para el que sale.
	var huecos := a_devolver.size()
	if inv.contar(id) == 1 and huecos > 0:
		huecos -= 1  # el propio item libera su ranura al salir
	if inv.libres() < huecos:
		return false

	if not inv.quitar(id, 1):
		return false
	for par in a_devolver:
		_desequipar_interno(par[0])
		var restante := inv.agregar(par[1], 1)
		assert(restante == 0, "se ha perdido un item al desequipar: %s" % par[1])

	_puesto[slot] = id
	_stats.aplicar_efectos(_origen(slot), d.efectos)
	slot_cambiado.emit(slot, id)
	return true


func desequipar(inv: Inventario, slot: StringName) -> bool:
	var id: StringName = _puesto.get(slot, &"")
	if id == &"":
		return false
	# Inventario lleno: NO se desequipa. Tirar el item sería peor.
	if not inv.agregar_todo_o_nada(id, 1):
		return false
	_desequipar_interno(slot)
	return true


func loadout() -> Dictionary:
	var l := {}
	for slot in _puesto:
		l[String(slot)] = String(_puesto[slot])
	return l


func a_dict() -> Dictionary:
	return {"slots": loadout()}


func de_dict(d: Dictionary, inv: Inventario) -> void:
	## Al cargar se REAPLICAN los modificadores: nunca se guardan los valores
	## finales de las estadísticas (clase 296).
	for slot in SLOTS:
		_desequipar_interno(slot)
	var slots: Dictionary = d.get("slots", {})
	for slot in slots:
		var s := StringName(str(slot))
		var id := StringName(str(slots[slot]))
		if not _base.existe(id) or not SLOTS.has(s):
			push_warning("equipo con item o slot desconocido: %s / %s" % [s, id])
			continue
		_puesto[s] = id
		_stats.aplicar_efectos(_origen(s), _base.obtener(id).efectos)
		slot_cambiado.emit(s, id)


func _desequipar_interno(slot: StringName) -> void:
	if _puesto.get(slot, &"") == &"":
		return
	# Se retira por ORIGEN: así desequipar la mano principal quita exactamente
	# sus bonificaciones, aunque el mismo item esté también en la otra mano.
	_stats.retirar_origen(_origen(slot))
	_puesto.erase(slot)
	slot_cambiado.emit(slot, &"")


func _origen(slot: StringName) -> StringName:
	return StringName("equipo:%s" % slot)
