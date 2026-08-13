class_name BaseDeLore
extends RefCounted

## Recuperación de lore con visibilidad (clase 332).
##
## Léxica y determinista a propósito: con un vocabulario que controlas tú (el
## de tu mundo) y etiquetas bien puestas, acierta casi siempre, es gratis y se
## puede depurar. Los embeddings aportan con paráfrasis; mide antes de añadir
## la dependencia.

var _entradas: Array = []


func cargar(ruta: String) -> Array:
	if not FileAccess.file_exists(ruta):
		return ["no existe: " + ruta]
	var f := FileAccess.open(ruta, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return ["lore ilegible"]
	_entradas = d.get("entradas", [])
	return validar()


func total() -> int:
	return _entradas.size()


func todas() -> Array:
	return _entradas


func recuperar(consulta: String, npc_id: StringName, estado: Dictionary,
		max_entradas: int = 5) -> Array:
	var palabras := _normalizar(consulta).split(" ", false)
	var puntuadas: Array = []

	for i in _entradas.size():
		var e: Dictionary = _entradas[i]
		# El filtro de VISIBILIDAD va primero, antes de puntuar: lo que no
		# está en el contexto no se puede filtrar después.
		if not _visible_para(e, npc_id, estado):
			continue
		var p := _puntuar(e, palabras, estado)
		if p > 0.0:
			puntuadas.append({"i": i, "p": p})

	# Orden estable: por puntuación y, a igualdad, por id. Sin el desempate,
	# dos ejecuciones podrían recuperar cosas distintas y el NPC sería
	# irreproducible en un test.
	puntuadas.sort_custom(func(a, b):
		if absf(float(a["p"]) - float(b["p"])) > 0.0001:
			return float(a["p"]) > float(b["p"])
		return str(_entradas[a["i"]]["id"]) < str(_entradas[b["i"]]["id"]))

	var salida: Array = []
	for x in puntuadas.slice(0, max_entradas):
		salida.append(_entradas[x["i"]])
	return salida


func validar() -> Array:
	var errores: Array = []
	var ids := {}
	for e in _entradas:
		var id := str(e.get("id", ""))
		if id == "":
			errores.append("entrada sin id")
			continue
		if ids.has(id):
			errores.append("id duplicado: %s" % id)
		ids[id] = true
		if str(e.get("texto", "")).strip_edges() == "":
			errores.append("%s: sin texto" % id)
		if str(e.get("texto", "")).length() > 400:
			# Entradas largas diluyen la recuperación: 5 de 400 caracteres ya
			# son 2.000, y una sola no debe comerse el presupuesto.
			errores.append("%s: texto demasiado largo (parte la entrada)" % id)
		if (e.get("etiquetas", []) as Array).is_empty():
			errores.append("%s: sin etiquetas (nunca se recuperará)" % id)
		if str(e.get("visibilidad", "publico")) == "secreto" \
				and str(e.get("requiere_quest", "")) == "":
			errores.append("%s: secreto sin condición de revelado" % id)
	return errores


func _puntuar(e: Dictionary, palabras: PackedStringArray, estado: Dictionary) -> float:
	var p := 0.0
	# 1) Etiquetas: la señal más fuerte y más barata.
	for etq in e.get("etiquetas", []):
		if palabras.has(_normalizar(str(etq))):
			p += 3.0
	# 2) Texto.
	var texto := _normalizar(str(e.get("texto", "")))
	for w in palabras:
		if w.length() > 3 and texto.contains(w):
			p += 1.0
	# 3) Contexto de escena: lo del lugar donde estamos sube aunque el jugador
	#    no lo haya nombrado.
	for etq in e.get("etiquetas", []):
		if str(etq) == str(estado.get("lugar", "")):
			p += 2.0
	return p * float(e.get("peso", 1.0))


func _visible_para(e: Dictionary, npc_id: StringName, estado: Dictionary) -> bool:
	var v := str(e.get("visibilidad", "publico"))
	if v == "publico":
		return true
	if v.begins_with("npc:"):
		return v.substr(4) == String(npc_id)
	if v == "secreto":
		var q := str(e.get("requiere_quest", ""))
		return q != "" and (estado.get("quests_completadas", []) as Array).has(q)
	return false


static func _normalizar(s: String) -> String:
	var t := s.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ñ", "n"],
			["¿", ""], ["?", ""], ["¡", ""], ["!", ""], [",", ""], [".", ""]]:
		t = t.replace(par[0], par[1])
	while t.contains("  "):
		t = t.replace("  ", " ")
	return t.strip_edges()
