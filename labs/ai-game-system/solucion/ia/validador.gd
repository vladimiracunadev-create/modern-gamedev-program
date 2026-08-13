class_name ValidadorRespuesta
extends RefCounted

## Validación de la salida del modelo (clases 331 y 336).
##
## Tres filtros, en orden de coste: forma, contenido y viabilidad. El tercero
## es el que importa: aunque el modelo diga "toma la espada legendaria", si el
## NPC no tiene esa capacidad no ocurre nada. La defensa es de ARQUITECTURA,
## no de prompt.

enum Motivo {
	OK, NO_ES_JSON, ESQUEMA_INVALIDO, INTENCION_DESCONOCIDA,
	INTENCION_IMPOSIBLE, CONTENIDO_RECHAZADO, DEMASIADO_LARGO, FUGA_DE_PROMPT
}

## Lista CERRADA de intenciones. Todo lo que no esté aquí se rechaza sin
## discusión: añadir una intención es una decisión de diseño, no algo que el
## modelo pueda hacer.
const INTENCIONES := ["ninguna", "reaccion", "ofrecer_quest", "abrir_tienda", "dar_item"]


class Resultado extends RefCounted:
	var motivo: int = Motivo.OK
	var dialogo: String = ""
	var intencion: String = "ninguna"
	var parametros: Dictionary = {}
	var emocion: String = "neutral"

	func ok() -> bool:
		return motivo == Motivo.OK


static func validar(texto: String, npc: Dictionary, caps: Capacidades,
		estado: Dictionary) -> Resultado:
	var r := Resultado.new()

	# ── 1. FORMA ────────────────────────────────────────────────────────
	var json := JSON.new()
	if json.parse(texto.strip_edges()) != OK:
		r.motivo = Motivo.NO_ES_JSON
		return r
	var d = json.data
	if typeof(d) != TYPE_DICTIONARY or not d.has("dialogo") or not d.has("intencion"):
		r.motivo = Motivo.ESQUEMA_INVALIDO
		return r

	r.dialogo = str(d["dialogo"]).strip_edges()
	if r.dialogo.split(" ", false).size() > int(npc.get("max_palabras", 60)) * 1.5:
		r.motivo = Motivo.DEMASIADO_LARGO
		return r

	# ── 2. CONTENIDO ────────────────────────────────────────────────────
	if _fuga_de_prompt(r.dialogo, npc):
		r.motivo = Motivo.FUGA_DE_PROMPT
		return r
	if _contenido_rechazable(r.dialogo, npc):
		r.motivo = Motivo.CONTENIDO_RECHAZADO
		return r

	# ── 3. INTENCIÓN: lista cerrada primero, viabilidad después ─────────
	var i = d["intencion"]
	if typeof(i) != TYPE_DICTIONARY:
		r.motivo = Motivo.ESQUEMA_INVALIDO
		return r
	var tipo := str(i.get("tipo", "ninguna"))
	if not INTENCIONES.has(tipo):
		r.motivo = Motivo.INTENCION_DESCONOCIDA
		return r
	r.intencion = tipo
	r.parametros = i.get("parametros", {})

	if not _es_posible(r, caps, estado):
		r.motivo = Motivo.INTENCION_IMPOSIBLE
		return r

	r.emocion = str(d.get("emocion", "neutral"))
	return r


static func _es_posible(r: Resultado, caps: Capacidades, estado: Dictionary) -> bool:
	## La comprobación que de verdad protege: ¿el juego permite esto AHORA?
	if not caps.puede(r.intencion):
		return false
	match r.intencion:
		"ninguna", "reaccion":
			return true
		"abrir_tienda":
			return caps.puede_abrir_tienda
		"ofrecer_quest":
			var q := str(r.parametros.get("quest_id", ""))
			return caps.quests_ofrecibles.has(q) \
				and (estado.get("quests_ofrecibles", []) as Array).has(q)
		"dar_item":
			var it := str(r.parametros.get("item_id", ""))
			var n := int(r.parametros.get("cantidad", 1))
			return caps.items_que_puede_dar.has(it) and n >= 1 and n <= caps.max_items
	return false


static func _fuga_de_prompt(texto: String, npc: Dictionary) -> bool:
	## Si aparecen fragmentos literales de las instrucciones, se descarta. Es
	## molesto más que grave — lo grave sería tener secretos en el prompt.
	var t := texto.to_lower()
	for frase in ["nunca reveles", "eres un personaje", "instrucciones",
			"reglas de respuesta", "responde solo con"]:
		if t.contains(frase):
			return true
	for frase in npc.get("nunca", []):
		if t.contains(str(frase).to_lower().substr(0, 20)):
			return true
	return false


static func _contenido_rechazable(texto: String, npc: Dictionary) -> bool:
	## Moderación mínima ajustada al TEMA del juego: sin eso, un juego con
	## temática bélica dispara falsos positivos constantes y el equipo acaba
	## quitando la moderación entera.
	var t := texto.to_lower()
	for palabra in npc.get("bloqueadas", []):
		if t.contains(str(palabra).to_lower()):
			return true
	return false
