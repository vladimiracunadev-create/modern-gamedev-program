class_name EventosJuego
extends RefCounted

## Bus de eventos TIPADOS (clase 305).
##
## No es un diccionario de cadenas: cada evento es una señal con su firma, así
## que un typo se detecta al escribirlo y no en runtime. Es la pieza que
## permite que el diario de misiones avance sin que el código de los enemigos
## sepa siquiera que existen las misiones.

signal enemigo_muerto(id_enemigo: StringName, posicion: Vector2)
signal item_recogido(id_item: StringName, cantidad: int)
signal item_entregado(id_item: StringName, cantidad: int, a_quien: StringName)
signal zona_alcanzada(id_zona: StringName)
signal npc_hablado(id_npc: StringName)
signal flag_narrativa(clave: StringName, valor: bool)
