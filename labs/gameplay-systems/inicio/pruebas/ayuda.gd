class_name AyudaPruebas
extends RefCounted

## Contador de comprobaciones compartido por todas las pruebas headless.
##
## Imprime el mismo resumen que el resto del programa —
## `== N comprobaciones, M fallos ==` — porque es el formato que la CI busca.

var hechas: int = 0
var fallos: int = 0


func check(ok: bool, que: String) -> bool:
	hechas += 1
	if not ok:
		fallos += 1
		printerr("  FALLA  ", que)
	return ok


static func diferencia(a: Dictionary, b: Dictionary) -> String:
	## Nombra la primera clave que difiere. Un test que dice "no son iguales"
	## y no dice en qué obliga a depurar a mano; este lo señala con el dedo.
	for clave in a:
		if not b.has(clave):
			return "falta '%s' en el segundo" % clave
		if a[clave] != b[clave]:
			return "difiere '%s': %s  vs  %s" % [clave, a[clave], b[clave]]
	for clave in b:
		if not a.has(clave):
			return "sobra '%s' en el segundo" % clave
	return ""


func resumen() -> int:
	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	return 1 if fallos > 0 else 0
