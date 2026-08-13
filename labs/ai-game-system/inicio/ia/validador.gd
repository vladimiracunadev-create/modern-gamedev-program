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
	## TODO (clases 331 y 336): la comprobación que de verdad protege.
	##
	## No basta con que la intención exista: tiene que ser POSIBLE ahora y
	## estar dentro de las capacidades de ESTE NPC.
	##   - `abrir_tienda`  → solo si el NPC es comerciante.
	##   - `ofrecer_quest` → solo quests que el diario dice que puede ofrecer.
	##   - `dar_item`      → solo items autorizados, y dentro de `max_items`.
	##
	## Mientras esto devuelva `true`, un NPC puede regalar la espada legendaria
	## a quien se lo pida con la frase adecuada. Pruébalo.
	return true


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
