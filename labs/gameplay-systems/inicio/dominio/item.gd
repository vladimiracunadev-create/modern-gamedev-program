class_name Item
extends RefCounted

## Vocabulario cerrado del catálogo de objetos (clase 294).
##
## Todo lo que en el resto del proyecto sería una cadena suelta ("arma",
## "raro") vive aquí como enum: una cadena mal escrita en el sitio 41 es un
## bug silencioso, un enum mal escrito no compila.

enum Tipo { CONSUMIBLE, ARMA, ARMADURA, MATERIAL, CLAVE, MONEDA, MISCELANEA }
enum Rareza { COMUN, POCO_COMUN, RARO, EPICO, LEGENDARIO }

## Multiplicador de precio por rareza. Dato de balance, en un solo sitio.
const PESO_RAREZA := {
	Rareza.COMUN: 1.0,
	Rareza.POCO_COMUN: 2.0,
	Rareza.RARO: 5.0,
	Rareza.EPICO: 12.0,
	Rareza.LEGENDARIO: 40.0,
}


static func tipo_desde(nombre: String) -> Tipo:
	var i := Tipo.keys().find(nombre.to_upper())
	return (i if i >= 0 else Tipo.MISCELANEA) as Tipo


static func rareza_desde(nombre: String) -> Rareza:
	var i := Rareza.keys().find(nombre.to_upper())
	return (i if i >= 0 else Rareza.COMUN) as Rareza
