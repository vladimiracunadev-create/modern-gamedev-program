class_name AyudaPruebas
extends RefCounted

## Contador de comprobaciones y medidor con calentamiento y mediana.

var hechas: int = 0
var fallos: int = 0


func check(ok: bool, que: String) -> bool:
	hechas += 1
	if not ok:
		fallos += 1
		printerr("  FALLA  ", que)
	return ok


func resumen() -> int:
	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	return 1 if fallos > 0 else 0


static func medir(f: Callable, iteraciones: int = 7, calentamiento: int = 2) -> float:
	## Mediana, no media: un pico del sistema operativo no debe decidir el
	## resultado. Y con calentamiento: la primera pasada mide cachés frías.
	for i in calentamiento:
		f.call()
	var muestras: Array = []
	for i in iteraciones:
		var t0 := Time.get_ticks_usec()
		f.call()
		muestras.append((Time.get_ticks_usec() - t0) / 1000.0)
	muestras.sort()
	return float(muestras[muestras.size() / 2])
