class_name ItemStack
extends RefCounted

## Instancia: lo ÚNICO que viaja al guardado (clase 294).
##
## Fíjate en lo poco que es. Un save no contiene nombres, iconos ni
## descripciones: contiene `{"id": "pocion_menor", "cantidad": 3}`. Por eso
## se puede renombrar un objeto en un parche sin tocar una sola partida — y
## por eso el `id` no se cambia jamás.

var id: StringName = &""
var cantidad: int = 0


func _init(id_: StringName = &"", cantidad_: int = 1) -> void:
	id = id_
	cantidad = maxi(0, cantidad_)


func duplicado() -> ItemStack:
	return ItemStack.new(id, cantidad)


func a_dict() -> Dictionary:
	return {"id": String(id), "cantidad": cantidad}


static func de_dict(d: Dictionary) -> ItemStack:
	return ItemStack.new(StringName(str(d.get("id", ""))), int(d.get("cantidad", 0)))
