class_name AIProvider
extends RefCounted

## Abstracción de proveedor de IA (clase 334).
##
## Es la pieza que hace que el juego NO dependa de ningún proveedor. Sin ella,
## el día que un servicio cambie de precio, de API o desaparezca, el juego deja
## de funcionar — y eso es inaceptable en algo que se vende una vez y tiene que
## seguir funcionando durante años.

class Peticion extends RefCounted:
	var sistema: String = ""
	var usuario: String = ""
	var esquema: Dictionary = {}
	var temperatura: float = 0.7
	var max_tokens: int = 200
	var etiqueta: String = ""


class Respuesta extends RefCounted:
	var ok: bool = false
	var texto: String = ""
	var proveedor: String = ""
	var tokens_entrada: int = 0
	var tokens_salida: int = 0
	var error: String = ""
	var de_cache: bool = false


func nombre() -> String:
	return "abstracto"


func disponible() -> bool:
	return false


func completar(_p: Peticion) -> Respuesta:
	var r := Respuesta.new()
	r.error = "no implementado"
	return r
