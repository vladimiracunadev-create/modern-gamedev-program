class_name ItemDefinition
extends RefCounted

## Definición de una clase de objeto: dato inmutable y COMPARTIDO (clase 294).
##
## Todas las «Poción menor» del mundo son esta misma instancia. Lo que cambia
## por objeto concreto (la cantidad) vive en `ItemStack`, no aquí. Confundir
## las dos cosas es la causa número uno de bugs de duplicación.

var id: StringName = &""
var nombre: String = ""
var descripcion: String = ""
var tipo: Item.Tipo = Item.Tipo.MISCELANEA
var rareza: Item.Rareza = Item.Rareza.COMUN
var max_stack: int = 1
var valor: int = 0
var tags: PackedStringArray = PackedStringArray()
var icono: String = ""
var efectos: Array = []
var metadata: Dictionary = {}


static func de_dict(b: Dictionary) -> ItemDefinition:
	var d := ItemDefinition.new()
	d.id = StringName(str(b.get("id", "")))
	d.nombre = str(b.get("nombre", ""))
	d.descripcion = str(b.get("descripcion", ""))
	d.tipo = Item.tipo_desde(str(b.get("tipo", "MISCELANEA")))
	d.rareza = Item.rareza_desde(str(b.get("rareza", "COMUN")))
	d.max_stack = int(b.get("max_stack", 1))
	d.valor = int(b.get("valor", 0))
	d.tags = PackedStringArray(b.get("tags", []))
	d.icono = str(b.get("icono", ""))
	d.efectos = b.get("efectos", [])
	d.metadata = b.get("metadata", {})
	return d


func apilable() -> bool:
	return max_stack > 1


func tiene_tag(t: String) -> bool:
	return tags.has(t)


func precio_venta() -> int:
	## Vender da la mitad: es un sumidero de economía, no un descuido.
	return int(valor * 0.5)
