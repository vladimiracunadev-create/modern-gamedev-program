class_name AyudaPruebas
extends RefCounted

## Contador de comprobaciones compartido por todas las pruebas headless.

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
