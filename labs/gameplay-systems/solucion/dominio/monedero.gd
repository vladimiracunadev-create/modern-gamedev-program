class_name Monedero
extends RefCounted

## Monedero con PUNTO ÚNICO de mutación y registro (clase 303).
##
## No hay setter público de saldo. Toda variación pasa por `_mover`, con un
## motivo obligatorio, y queda registrada. Con eso salen gratis el informe de
## fuentes y sumideros, la auditoría y la telemetría de economía.

const MONEDAS := [&"oro", &"gemas", &"fragmentos"]
const MAX_HISTORIAL := 500

signal saldo_cambiado(moneda: StringName, nuevo: int, delta: int, motivo: StringName)

var _saldos := {}
var _historial: Array = []
var _tiempo_juego: float = 0.0


func _init() -> void:
	for m in MONEDAS:
		_saldos[m] = 0


func saldo(m: StringName) -> int:
	return int(_saldos.get(m, 0))


func avanzar_tiempo(delta: float) -> void:
	_tiempo_juego += delta


func puede_pagar(m: StringName, cantidad: int) -> bool:
	return saldo(m) >= cantidad


func ingresar(m: StringName, cantidad: int, motivo: StringName) -> bool:
	assert(cantidad > 0, "ingresar espera cantidades positivas")
	return _mover(m, cantidad, motivo)


func gastar(m: StringName, cantidad: int, motivo: StringName) -> bool:
	assert(cantidad > 0, "gastar espera cantidades positivas")
	return _mover(m, -cantidad, motivo)


func informe() -> Dictionary:
	var fuentes := {}
	var sumideros := {}
	for t in _historial:
		var clave := "%s:%s" % [t["moneda"], t["motivo"]]
		if int(t["delta"]) > 0:
			fuentes[clave] = int(fuentes.get(clave, 0)) + int(t["delta"])
		else:
			sumideros[clave] = int(sumideros.get(clave, 0)) - int(t["delta"])
	var total_in := 0
	var total_out := 0
	for v in fuentes.values():
		total_in += int(v)
	for v in sumideros.values():
		total_out += int(v)
	var horas := maxf(_tiempo_juego / 3600.0, 0.0001)
	return {
		"fuentes": fuentes,
		"sumideros": sumideros,
		"neto": total_in - total_out,
		"neto_por_hora": float(total_in - total_out) / horas,
		"transacciones": _historial.size(),
	}


func a_dict() -> Dictionary:
	var s := {}
	for m in MONEDAS:
		s[String(m)] = saldo(m)
	return {"saldos": s}


func de_dict(d: Dictionary) -> void:
	var s: Dictionary = d.get("saldos", {})
	for m in MONEDAS:
		_saldos[m] = int(s.get(String(m), 0))


func _mover(m: StringName, delta: int, motivo: StringName) -> bool:
	if delta == 0 or not _saldos.has(m):
		return false
	var nuevo := saldo(m) + delta
	if nuevo < 0:
		return false  # nunca se permite saldo negativo
	_saldos[m] = nuevo
	_historial.append({
		"t": _tiempo_juego, "moneda": String(m),
		"delta": delta, "saldo": nuevo, "motivo": String(motivo),
	})
	if _historial.size() > MAX_HISTORIAL:
		_historial.pop_front()
	saldo_cambiado.emit(m, nuevo, delta, motivo)
	return true
