class_name Tags
extends RefCounted

## Contenedor de gameplay tags con CONTEO DE FUENTES (clase 297).
##
## Con banderas booleanas, dos efectos que aturden y uno que termina dejan al
## personaje andando en mitad del aturdimiento. Contando fuentes, no.

var _cuenta := {}


func agregar(t: String) -> void:
	_cuenta[t] = int(_cuenta.get(t, 0)) + 1


func quitar(t: String) -> void:
	if not _cuenta.has(t):
		return
	_cuenta[t] = int(_cuenta[t]) - 1
	if int(_cuenta[t]) <= 0:
		_cuenta.erase(t)


func tiene(t: String) -> bool:
	return _cuenta.has(t)


func fuentes(t: String) -> int:
	return int(_cuenta.get(t, 0))


func tiene_alguna(lista: PackedStringArray) -> bool:
	for t in lista:
		if tiene(t):
			return true
	return false


func tiene_todas(lista: PackedStringArray) -> bool:
	for t in lista:
		if not tiene(t):
			return false
	return true


func vacio() -> bool:
	return _cuenta.is_empty()


func todas() -> Array:
	return _cuenta.keys()
