class_name AbilitySystem
extends RefCounted

## Sistema de habilidades con fases, coste, cooldown y tags (clase 297).
##
## Avanza con `tick(delta)` EXPLÍCITO, no con `_process`. Eso lo hace
## determinista, probable headless y replicable en un servidor.

enum Fase { INACTIVA, CASTEO, EJECUCION, RECUPERACION }
enum Motivo {
	OK, DESCONOCIDA, EN_COOLDOWN, SIN_RECURSO, FUERA_DE_RANGO,
	SIN_OBJETIVO, BLOQUEADA_POR_TAG, FALTA_REQUISITO, YA_ACTIVA, GCD
}

const GCD := 0.4

signal activada(id: StringName)
signal fase_cambiada(id: StringName, fase: int)
signal fallo(id: StringName, motivo: int)
signal efectos_aplicados(id: StringName, objetivos: Array, efectos: Array)


class Definicion extends RefCounted:
	enum Targeting { SELF, UNO, AREA, CONO, DIRECCION }

	var id: StringName = &""
	var nombre: String = ""
	var coste_recurso: StringName = &"mana"
	var coste: float = 0.0
	var cooldown: float = 0.0
	var tiempo_casteo: float = 0.0
	var tiempo_recuperacion: float = 0.0
	var rango: float = 0.0
	var targeting: int = Targeting.UNO
	var requiere_tags: PackedStringArray = PackedStringArray()
	var bloquea_tags: PackedStringArray = PackedStringArray()
	var cancelable_en_casteo: bool = true
	var efectos: Array = []

	static func de_dict(d: Dictionary) -> Definicion:
		var a := Definicion.new()
		a.id = StringName(str(d.get("id", "")))
		a.nombre = str(d.get("nombre", ""))
		a.coste_recurso = StringName(str(d.get("coste_recurso", "mana")))
		a.coste = float(d.get("coste", 0.0))
		a.cooldown = float(d.get("cooldown", 0.0))
		a.tiempo_casteo = float(d.get("casteo", 0.0))
		a.tiempo_recuperacion = float(d.get("recuperacion", 0.0))
		a.rango = float(d.get("rango", 0.0))
		var i := Targeting.keys().find(str(d.get("targeting", "UNO")).to_upper())
		a.targeting = i if i >= 0 else Targeting.UNO
		a.requiere_tags = PackedStringArray(d.get("requiere", []))
		a.bloquea_tags = PackedStringArray(d.get("bloquea", []))
		a.cancelable_en_casteo = bool(d.get("cancelable", true))
		a.efectos = d.get("efectos", [])
		return a


var tags := Tags.new()

var _defs := {}
var _cooldowns := {}
var _recursos := {}
var _activa: Definicion = null
var _fase: int = Fase.INACTIVA
var _t_fase: float = 0.0
var _gcd: float = 0.0
var _objetivos: Array = []


func aprender(d: Definicion) -> void:
	_defs[d.id] = d


func conoce(id: StringName) -> bool:
	return _defs.has(id)


func fase() -> int:
	return _fase


func activa() -> StringName:
	return _activa.id if _activa != null else &""


func recurso(clave: StringName) -> float:
	return float(_recursos.get(clave, 0.0))


func fijar_recurso(clave: StringName, v: float) -> void:
	_recursos[clave] = maxf(0.0, v)


func cooldown_restante(id: StringName) -> float:
	return float(_cooldowns.get(id, 0.0))


func puede_activar(id: StringName, objetivos: Array, distancia: float) -> int:
	if not _defs.has(id):
		return Motivo.DESCONOCIDA
	var d: Definicion = _defs[id]
	if _activa != null:
		return Motivo.YA_ACTIVA
	if _gcd > 0.0:
		return Motivo.GCD
	if cooldown_restante(id) > 0.0:
		return Motivo.EN_COOLDOWN
	if tags.tiene_alguna(d.bloquea_tags):
		return Motivo.BLOQUEADA_POR_TAG
	if not tags.tiene_todas(d.requiere_tags):
		return Motivo.FALTA_REQUISITO
	if recurso(d.coste_recurso) < d.coste:
		return Motivo.SIN_RECURSO
	if d.targeting != Definicion.Targeting.SELF and objetivos.is_empty():
		return Motivo.SIN_OBJETIVO
	if d.rango > 0.0 and distancia > d.rango:
		return Motivo.FUERA_DE_RANGO
	return Motivo.OK


func activar(id: StringName, objetivos: Array = [], distancia: float = 0.0) -> int:
	var motivo := puede_activar(id, objetivos, distancia)
	if motivo != Motivo.OK:
		fallo.emit(id, motivo)
		return motivo

	var d: Definicion = _defs[id]
	_activa = d
	_objetivos = objetivos.duplicate()
	# El coste se cobra AL ACTIVAR. Si se cobrara al impactar, el jugador
	# podría encadenar tres castes antes de pagar el primero.
	fijar_recurso(d.coste_recurso, recurso(d.coste_recurso) - d.coste)
	_gcd = GCD
	_pasar_a(Fase.CASTEO if d.tiempo_casteo > 0.0 else Fase.EJECUCION)
	activada.emit(id)
	return Motivo.OK


func tick(delta: float) -> void:
	_gcd = maxf(0.0, _gcd - delta)
	for id in _cooldowns.keys():
		var t := maxf(0.0, float(_cooldowns[id]) - delta)
		if t <= 0.0:
			_cooldowns.erase(id)
		else:
			_cooldowns[id] = t

	if _activa == null:
		return
	_t_fase += delta
	match _fase:
		Fase.CASTEO:
			if _t_fase >= _activa.tiempo_casteo:
				_pasar_a(Fase.EJECUCION)
		Fase.EJECUCION:
			_ejecutar()
			_pasar_a(Fase.RECUPERACION if _activa != null and _activa.tiempo_recuperacion > 0.0 else Fase.INACTIVA)
		Fase.RECUPERACION:
			if _t_fase >= _activa.tiempo_recuperacion:
				_pasar_a(Fase.INACTIVA)
		_:
			pass


func cancelar() -> bool:
	if _activa == null:
		return false
	if _fase == Fase.CASTEO and not _activa.cancelable_en_casteo:
		return false
	if _fase == Fase.EJECUCION:
		return false  # ya ha ocurrido: cancelar sería deshacer el efecto
	# El coste NO se devuelve: si cancelar fuera gratis, fintear también.
	_pasar_a(Fase.INACTIVA)
	return true


func interrumpir() -> bool:
	if _activa == null or _fase != Fase.CASTEO:
		return false
	var id := _activa.id
	# Cooldown reducido: castigo, no ruina.
	_cooldowns[id] = _activa.cooldown * 0.5
	_pasar_a(Fase.INACTIVA)
	return true


func _ejecutar() -> void:
	# El sistema NO aplica daño: publica los efectos y quien sepa hacerlo los
	# aplica. Por eso se puede probar entero sin un mundo.
	efectos_aplicados.emit(_activa.id, _objetivos, _activa.efectos)
	if _activa.cooldown > 0.0:
		_cooldowns[_activa.id] = _activa.cooldown


func _pasar_a(f: int) -> void:
	_fase = f
	_t_fase = 0.0
	if _activa != null:
		fase_cambiada.emit(_activa.id, f)
	if f == Fase.INACTIVA:
		_activa = null
		_objetivos.clear()


func a_dict() -> Dictionary:
	var cds := {}
	for id in _cooldowns:
		cds[String(id)] = float(_cooldowns[id])
	var rec := {}
	for k in _recursos:
		rec[String(k)] = float(_recursos[k])
	return {"cooldowns": cds, "recursos": rec}


func de_dict(d: Dictionary) -> void:
	_cooldowns.clear()
	for id in d.get("cooldowns", {}):
		_cooldowns[StringName(str(id))] = float(d["cooldowns"][id])
	_recursos.clear()
	for k in d.get("recursos", {}):
		_recursos[StringName(str(k))] = float(d["recursos"][k])
