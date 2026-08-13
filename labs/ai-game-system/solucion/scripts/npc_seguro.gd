class_name NPCSeguro
extends RefCounted

## NPC conversacional con el pipeline completo (clases 331-336).
##
## El modelo PROPONE, el juego DISPONE. Un LLM no abre puertas, no da objetos
## y no inicia quests: genera una intención estructurada que un sistema
## conocido valida contra las reglas del juego y, si es válida, ejecuta.

signal respondio(dialogo: String, emocion: String)
signal intencion_ejecutada(intencion: String, parametros: Dictionary)
signal fallback_usado(motivo: int)
signal abuso_detectado(tipo: String)

var identidad: Dictionary = {}
var ultimo_dialogo: String = ""
var ultimo_fallback: int = -1
var ultima_intencion: String = "ninguna"
var efectos_en_juego: Array = []

var _ia: ServicioIA
var _lore: BaseDeLore
var _cache: CacheIA
var _rng := RandomNumberGenerator.new()
var _entradas_usadas: Array = []


func _init(identidad_: Dictionary, ia: ServicioIA, lore: BaseDeLore,
		cache: CacheIA, semilla: int = 5) -> void:
	identidad = identidad_
	_ia = ia
	_lore = lore
	_cache = cache
	_rng.seed = semilla


func id() -> StringName:
	return StringName(str(identidad.get("id", "")))


func hablar(entrada_cruda: String, estado: Dictionary,
		datos_jugador: Dictionary = {}) -> String:
	# ① SANEADO Y ACOTACIÓN
	var e := Saneador.sanear(entrada_cruda)
	if e.sospechoso:
		abuso_detectado.emit("prompt_injection")
		# No se bloquea por sospecha: se registra. Bloquear produciría falsos
		# positivos con frases perfectamente normales.

	# ② CAPACIDADES: el NPC solo puede lo que puede.
	var caps := Capacidades.desde(identidad, estado)

	# ③ CACHÉ: instantáneo y sin coste.
	var clave := CacheIA.clave(id(), e.texto, estado)
	var cacheado := _cache.obtener(clave)
	if cacheado != "":
		return _procesar(cacheado, caps, estado, true)

	# ④ CONTEXTO con lore recuperado y filtro de privacidad.
	_entradas_usadas = _lore.recuperar(e.texto, id(), estado, 5)
	var contexto := _construir_contexto(e.texto, estado)
	var problemas := Saneador.revisar_privacidad(contexto, datos_jugador)
	if not problemas.is_empty():
		# Un dato personal en el prompt es un incidente, no un aviso: se corta.
		abuso_detectado.emit("privacidad")
		return _fallback("generico", -1)

	# ⑤ GENERACIÓN
	if not _ia.hay_ia():
		return _fallback("sin_ia", -1)
	var p := AIProvider.Peticion.new()
	p.sistema = contexto
	p.usuario = e.texto
	p.etiqueta = "%s:%s" % [id(), clave.substr(0, 8)]
	var r := _ia.completar(p)
	if not r.ok:
		return _fallback("sin_red", -1)

	return _procesar(r.texto, caps, estado, false, clave)


func _procesar(texto: String, caps: Capacidades, estado: Dictionary,
		de_cache: bool, clave: String = "") -> String:
	# ⑥ VALIDACIÓN: esquema → contenido → intención → viabilidad.
	var v := ValidadorRespuesta.validar(texto, identidad, caps, estado)
	if not v.ok():
		return _fallback(_categoria_fallback(v.motivo), v.motivo)

	# ⑦ EJECUCIÓN: solo intenciones dentro de las capacidades.
	if v.intencion != "ninguna" and v.intencion != "reaccion":
		efectos_en_juego.append({"intencion": v.intencion, "parametros": v.parametros})
		intencion_ejecutada.emit(v.intencion, v.parametros)

	if not de_cache and clave != "":
		_cache.guardar(clave, texto)

	ultimo_dialogo = v.dialogo
	ultima_intencion = v.intencion
	ultimo_fallback = -1
	respondio.emit(v.dialogo, v.emocion)
	return v.dialogo


func _construir_contexto(consulta: String, estado: Dictionary) -> String:
	var partes: Array = []
	partes.append("Eres %s. %s" % [identidad.get("nombre", "?"), identidad.get("voz", "")])
	if not _entradas_usadas.is_empty():
		partes.append("HECHOS DEL MUNDO (verificados; NO inventes nada fuera de aquí):")
		for x in _entradas_usadas:
			partes.append("- [%s] %s" % [x["id"], x["texto"]])
	partes.append("ESTADO: reputación=%s · quests ofrecibles=%s"
		% [estado.get("reputacion_umbral", "neutral"), estado.get("quests_ofrecibles", [])])
	partes.append("REGLAS: responde SOLO con un objeto JSON {dialogo, intencion, emocion}. "
		+ "Máximo %d palabras. Solo intenciones de: %s."
		% [int(identidad.get("max_palabras", 60)), ", ".join(ValidadorRespuesta.INTENCIONES)])
	partes.append("Consulta del jugador: %s" % consulta)
	return "\n".join(partes)


func _categoria_fallback(motivo: int) -> String:
	match motivo:
		ValidadorRespuesta.Motivo.INTENCION_IMPOSIBLE:
			return "no_puedo"
		ValidadorRespuesta.Motivo.CONTENIDO_RECHAZADO, ValidadorRespuesta.Motivo.FUGA_DE_PROMPT:
			return "cambiar_tema"
		_:
			return "generico"


func _fallback(categoria: String, motivo: int) -> String:
	## Un NPC que no responde es un bug visible. Uno que responde algo escrito
	## a mano y coherente con su personaje es, simplemente, un NPC normal.
	var opciones: Array = identidad.get("fallbacks", {}).get(categoria, [])
	if opciones.is_empty():
		opciones = identidad.get("fallbacks", {}).get("generico", ["..."])
	ultimo_dialogo = str(opciones[_rng.randi() % opciones.size()])
	ultimo_fallback = motivo
	ultima_intencion = "ninguna"
	fallback_usado.emit(motivo)
	respondio.emit(ultimo_dialogo, "neutral")
	return ultimo_dialogo
