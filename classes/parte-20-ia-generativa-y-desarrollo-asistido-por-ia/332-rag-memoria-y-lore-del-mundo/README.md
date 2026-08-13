# Clase 332 — RAG, memoria y lore del mundo

> Parte: **20 — IA generativa y desarrollo de juegos asistido por IA** · Fuente: *Literatura sobre recuperación aumentada (RAG) · Prácticas de diseño narrativo y bases de conocimiento*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Resolver el problema que hace inservibles a la mayoría de los NPC con LLM: **inventan**. Un modelo no conoce tu mundo, así que cuando le preguntan por el rey de tu reino ficticio, produce una respuesta plausible y completamente falsa. Y una vez que un NPC afirma que el rey murió hace diez años, la coherencia de tu narrativa se ha roto delante del jugador.

La solución tiene dos mitades. **RAG (retrieval-augmented generation)**: mantener una base de lore verificado y recuperar solo lo relevante para inyectarlo en el contexto, de forma que el modelo hable **desde** hechos en vez de desde su imaginación. Y **memoria**: registrar lo ocurrido entre el jugador y cada NPC, para que la conversación tenga continuidad sin volver a mandar todo el historial.

Vas a implementar las dos, con un enfoque deliberadamente sencillo —recuperación léxica con etiquetas y palabras clave— que funciona muy bien para el tamaño de lore de un juego y **no requiere modelos de embedding ni base de datos vectorial**.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Estructurar el lore de un juego como base de conocimiento consultable.
2. Implementar recuperación por relevancia con etiquetas, palabras clave y contexto.
3. Explicar cuándo hace falta búsqueda semántica y cuándo la léxica basta.
4. Implementar memoria a corto plazo (conversación) y a largo plazo (hechos).
5. Resumir y podar la memoria para que no crezca sin control.
6. Controlar la visibilidad del lore: qué sabe cada NPC y qué es secreto.
7. Verificar el anclaje: comprobar que el NPC no afirma cosas fuera del lore.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Alucinación en un mundo ficticio | El modelo no puede saber tu lore: lo inventará. |
| 2 | Base de lore | Estructurada, versionada y validada como cualquier contenido. |
| 3 | Recuperación por relevancia | Mandar todo el lore ni cabe ni funciona. |
| 4 | Léxica vs semántica | La sencilla basta más veces de lo que parece. |
| 5 | Visibilidad y secretos | Un NPC no debe saber lo que su personaje no sabe. |
| 6 | Memoria a corto plazo | Continuidad dentro de una conversación. |
| 7 | Memoria a largo plazo | Continuidad entre sesiones, y es estado del save. |
| 8 | Resumen y poda | La memoria crece; el contexto no. |
| 9 | Anclaje verificable | Se puede comprobar que la respuesta se ciñe a los hechos. |
| 10 | Coste del contexto | Cada token recuperado se paga en cada turno. |

## 📖 Definiciones y características

- **RAG (retrieval-augmented generation)**: recuperar información relevante e inyectarla en el contexto antes de generar. Clave: es la mitigación principal de la alucinación.
- **Base de lore**: colección estructurada de hechos del mundo. Clave: es contenido del juego, validable y versionado.
- **Entrada de lore**: unidad de conocimiento con id, texto, etiquetas y visibilidad. Clave: debe ser autocontenida y breve.
- **Recuperación (retrieval)**: seleccionar las entradas relevantes para una consulta. Clave: la calidad del NPC depende más de esto que del modelo.
- **Búsqueda léxica**: coincidencia por palabras y etiquetas. Clave: simple, determinista y suficiente para miles de entradas.
- **Búsqueda semántica**: coincidencia por significado usando embeddings. Clave: mejor con sinónimos y paráfrasis; añade dependencias y coste.
- **Embedding**: representación numérica del significado de un texto. Clave: requiere un modelo y un índice; evalúa si te compensa.
- **Visibilidad**: quién puede conocer una entrada de lore. Clave: impide que un NPC revele lo que su personaje no sabe.
- **Secreto narrativo**: hecho que no debe revelarse todavía. Clave: nunca entra en el contexto de quien no debe conocerlo.
- **Memoria a corto plazo**: últimos turnos de la conversación actual. Clave: da continuidad inmediata; se descarta al salir.
- **Memoria a largo plazo**: hechos persistentes sobre el jugador y sus interacciones. Clave: es estado del save.
- **Resumen (compactación)**: condensar memoria antigua para que ocupe menos. Clave: evita el crecimiento indefinido del contexto.
- **Poda (eviction)**: eliminar recuerdos irrelevantes o antiguos. Clave: sin ella, la memoria se llena de ruido.
- **Anclaje (grounding)**: que la respuesta se apoye en hechos proporcionados. Clave: es verificable, al menos parcialmente.
- **Ventana de contexto**: espacio total disponible. Clave: es el recurso que se reparte entre lore, memoria y estado.

## 🧰 Herramientas y preparación

Godot 4.x y el NPC de la [clase 331](../331-npc-controlados-por-llm/README.md). Trabajaremos en `res://ia/lore/` y `res://datos/lore/`. **No hace falta ninguna base de datos vectorial ni ningún modelo de embedding**: la implementación es léxica y cabe en 200 líneas. La memoria a largo plazo se guarda con el sistema de la [clase 307](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/307-save-system-de-produccion/README.md), con su versión y su migración.

## 🧪 Laboratorio guiado

1. **La base de lore.** Entradas cortas, etiquetadas y con visibilidad:

```json
{
  "version": 1,
  "entradas": [
    {
      "id": "villarroca_general",
      "texto": "Villarroca es un pueblo minero de unas trescientas personas, en el valle del río Gris. Vive del hierro de la mina del norte.",
      "etiquetas": ["villarroca", "pueblo", "lugar", "mina"],
      "visibilidad": "publico",
      "peso": 1.0
    },
    {
      "id": "mina_derrumbe",
      "texto": "Hace tres años, un derrumbe en el nivel bajo de la mina mató a once mineros. La galería sigue cerrada.",
      "etiquetas": ["mina", "derrumbe", "historia", "muertos"],
      "visibilidad": "publico",
      "peso": 1.2
    },
    {
      "id": "bram_hermano",
      "texto": "El hermano de Bram, Doran, murió en el derrumbe. Bram no habla de ello con desconocidos.",
      "etiquetas": ["bram", "doran", "derrumbe", "familia"],
      "visibilidad": "npc:herrero_bram",
      "peso": 1.5
    },
    {
      "id": "mina_causa_real",
      "texto": "El derrumbe lo causó una excavación no autorizada del capataz Verol, que ocultó los informes.",
      "etiquetas": ["mina", "derrumbe", "verol", "secreto"],
      "visibilidad": "secreto",
      "requiere_quest": "la_verdad_de_la_mina",
      "peso": 2.0
    }
  ]
}
```

La entrada `mina_causa_real` es la razón de ser del campo `visibilidad`. Si estuviera disponible para cualquier NPC, el primer aldeano al que le preguntes por la mina te destriparía la trama.

2. **La recuperación.** Léxica, determinista y en 60 líneas:

```gdscript
class_name BaseDeLore
extends RefCounted

var _entradas := []
var _por_etiqueta := {}        # etiqueta -> [índices]

func cargar(ruta: String) -> Array[String]:
	var d = JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return ["lore ilegible"]
	_entradas = d.get("entradas", [])
	for i in _entradas.size():
		for e in _entradas[i].get("etiquetas", []):
			_por_etiqueta[str(e)] = _por_etiqueta.get(str(e), []) + [i]
	return _validar()

func recuperar(consulta: String, npc_id: StringName, estado: Dictionary,
			   max_entradas := 5) -> Array:
	var palabras := _normalizar(consulta)
	var puntuadas := []

	for i in _entradas.size():
		var e: Dictionary = _entradas[i]
		if not _visible_para(e, npc_id, estado):
			continue                      # el filtro de visibilidad va PRIMERO
		var p := _puntuar(e, palabras, estado)
		if p > 0.0:
			puntuadas.append({"i": i, "p": p})

	# Orden estable: por puntuación y, a igualdad, por id. Sin el desempate por
	# id, dos ejecuciones podrían recuperar cosas distintas y el NPC sería
	# irreproducible en un test.
	puntuadas.sort_custom(func(a, b):
		if abs(a["p"] - b["p"]) > 0.0001:
			return a["p"] > b["p"]
		return str(_entradas[a["i"]]["id"]) < str(_entradas[b["i"]]["id"]))

	return puntuadas.slice(0, max_entradas).map(func(x): return _entradas[x["i"]])

func _puntuar(e: Dictionary, palabras: PackedStringArray, estado: Dictionary) -> float:
	var p := 0.0
	# 1) Coincidencia con etiquetas: la señal más fuerte y más barata.
	for etq in e.get("etiquetas", []):
		if palabras.has(_sin_acentos(str(etq))):
			p += 3.0
	# 2) Coincidencia en el texto.
	var texto := _sin_acentos(str(e.get("texto", "")))
	for w in palabras:
		if w.length() > 3 and texto.contains(w):
			p += 1.0
	# 3) Contexto de la escena: lo relacionado con el lugar donde estamos
	#    sube, aunque el jugador no lo haya nombrado.
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
		# Un secreto solo se revela si el juego dice que ya se puede.
		var q := str(e.get("requiere_quest", ""))
		return q != "" and q in estado.get("quests_completadas", [])
	return false
```

3. **Léxica o semántica: la decisión honesta.**

| Criterio | Léxica (esta clase) | Semántica (embeddings) |
|---|---|---|
| Dependencias | Ninguna | Modelo de embedding + índice |
| Coste | Cero | Por consulta o por hardware |
| Determinismo | Total | Alto, pero depende del modelo |
| Sinónimos y paráfrasis | Débil | Fuerte |
| Escala razonable | Hasta miles de entradas | Decenas de miles o más |
| Depurable | Sí: ves por qué puntuó | No directamente |

La regla práctica: **empieza por léxica con etiquetas bien puestas**. Para el lore de un juego —que rara vez pasa de unos cientos de entradas y cuyo vocabulario controlas tú— funciona sorprendentemente bien, y su determinismo hace posible probarlo. Pasa a semántica solo si mides que la recuperación falla con paráfrasis reales de jugadores.

4. **La memoria, en dos capas:**

```gdscript
class_name Memoria
extends RefCounted

const MAX_CORTO := 6              # turnos completos que se mandan tal cual
const MAX_LARGO_POR_NPC := 20     # hechos persistentes por NPC

# CORTO PLAZO: los últimos turnos, literales. Se pierde al salir.
var _conversacion := {}           # npc_id -> [{jugador, npc}]

# LARGO PLAZO: hechos condensados. ESTADO DEL SAVE.
var _hechos := {}                 # npc_id -> [{texto, turno, peso}]

func turno(npc_id: StringName, dice_jugador: String, dice_npc: String) -> void:
	var c: Array = _conversacion.get(npc_id, [])
	c.append({"jugador": dice_jugador, "npc": dice_npc})
	if c.size() > MAX_CORTO:
		c.pop_front()
	_conversacion[npc_id] = c

func anotar(npc_id: StringName, hecho: String, peso := 1.0) -> void:
	if hecho.strip_edges() == "":
		return
	var h: Array = _hechos.get(npc_id, [])
	# Deduplicación simple: si ya sabemos algo casi igual, subimos su peso en
	# vez de acumular tres versiones del mismo recuerdo.
	for x in h:
		if _parecidos(str(x["texto"]), hecho):
			x["peso"] = float(x["peso"]) + 0.5
			return
	h.append({"texto": hecho, "turno": _turno_global, "peso": peso})
	if h.size() > MAX_LARGO_POR_NPC:
		_podar(h)
	_hechos[npc_id] = h

func _podar(h: Array) -> void:
	# Se conserva lo importante y lo reciente; se descarta lo trivial y viejo.
	h.sort_custom(func(a, b):
		var pa := float(a["peso"]) - (_turno_global - int(a["turno"])) * 0.02
		var pb := float(b["peso"]) - (_turno_global - int(b["turno"])) * 0.02
		return pa > pb)
	h.resize(MAX_LARGO_POR_NPC)

func contexto(npc_id: StringName, presupuesto: int) -> String:
	var partes := []
	var hechos: Array = _hechos.get(npc_id, [])
	if not hechos.is_empty():
		partes.append("LO QUE RECUERDAS DE ESTE JUGADOR:")
		for x in hechos.slice(0, 8):
			partes.append("- " + str(x["texto"]))
	var conv: Array = _conversacion.get(npc_id, [])
	if not conv.is_empty():
		partes.append("\nCONVERSACIÓN RECIENTE:")
		for t in conv:
			partes.append("Jugador: " + str(t["jugador"]))
			partes.append("Tú: " + str(t["npc"]))
	return _recortar("\n".join(partes), presupuesto)

func a_dict() -> Dictionary:
	# Solo el largo plazo se guarda: la conversación de una sesión no tiene
	# sentido restaurarla tres semanas después.
	return {"hechos": _hechos, "turno": _turno_global}
```

5. **El presupuesto de contexto.** Repartido, no "lo que quepa":

```gdscript
func construir_contexto(npc: Dictionary, consulta: String, estado: Dictionary) -> String:
	var partes := []
	partes.append(_identidad(npc))                                   # ~350 tokens

	# Lore recuperado, con la fuente marcada. Que el modelo vea que son HECHOS
	# y no sugerencias es parte del anclaje.
	var entradas := _lore.recuperar(consulta, npc["id"], estado, 5)
	if not entradas.is_empty():
		partes.append("HECHOS DEL MUNDO (verificados; NO inventes nada fuera de aquí):")
		for e in entradas:
			partes.append("- [%s] %s" % [e["id"], e["texto"]])       # ~600 tokens

	partes.append(_memoria.contexto(npc["id"], 300))                 # ~300 tokens
	partes.append(_estado(estado))                                   # ~200 tokens
	partes.append(_reglas_de_anclaje())
	return "\n\n".join(partes)

func _reglas_de_anclaje() -> String:
	return """ANCLAJE (obligatorio):
- Solo puedes afirmar hechos que aparezcan en HECHOS DEL MUNDO, en LO QUE
  RECUERDAS o en tu identidad.
- Si el jugador pregunta por algo que no está ahí, di que no lo sabes. NO
  inventes nombres, fechas, lugares ni sucesos.
- Nunca reveles información marcada como secreta."""
```

6. **Verificar el anclaje.** Se puede comprobar, al menos parcialmente:

```gdscript
class_name VerificadorAnclaje
extends RefCounted

# Nombres propios del mundo. Si el NPC menciona uno que no está en el lore
# recuperado ni en su identidad, probablemente se lo ha inventado.
var _conocidos := {}

func indexar(lore: BaseDeLore, npcs: Array) -> void:
	for e in lore.todas():
		for palabra in _nombres_propios(str(e["texto"])):
			_conocidos[palabra] = str(e["id"])
	for n in npcs:
		_conocidos[str(n["nombre"])] = str(n["id"])

func revisar(respuesta: String, entradas_usadas: Array, npc: Dictionary) -> Array[String]:
	var permitidos := {}
	for e in entradas_usadas:
		for p in _nombres_propios(str(e["texto"])):
			permitidos[p] = true
	for p in _nombres_propios(str(npc.get("voz", "")) + " " + str(npc.get("nombre", ""))):
		permitidos[p] = true

	var sospechosos: Array[String] = []
	for p in _nombres_propios(respuesta):
		if permitidos.has(p):
			continue
		# Distinguimos dos casos, y el segundo es el grave: un nombre que
		# existe en el mundo pero NO se recuperó puede ser una fuga; uno que no
		# existe en absoluto es una invención.
		if _conocidos.has(p):
			sospechosos.append("%s: nombre del lore no recuperado (posible fuga)" % p)
		else:
			sospechosos.append("%s: nombre desconocido (posible invención)" % p)
	return sospechosos

static func _nombres_propios(texto: String) -> PackedStringArray:
	var salida := PackedStringArray()
	var regex := RegEx.create_from_string("\\b[A-ZÁÉÍÓÚÑ][a-záéíóúñ]{2,}\\b")
	for m in regex.search_all(texto):
		salida.append(m.get_string())
	return salida
```

Es una heurística, no una prueba: puede dar falsos positivos con palabras al principio de frase. Pero como **señal de telemetría** es valiosísima — si la tasa de nombres desconocidos sube tras cambiar un prompt, algo se ha roto.

7. **Validar la base de lore.** Contenido, luego CI:

```gdscript
func _validar() -> Array[String]:
	var errores: Array[String] = []
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
			# Entradas largas diluyen la recuperación: 5 entradas de 400
			# caracteres ya son 2.000, y una sola no debe comerse el presupuesto.
			errores.append("%s: texto demasiado largo (parte la entrada)" % id)
		if (e.get("etiquetas", []) as Array).is_empty():
			errores.append("%s: sin etiquetas (nunca se recuperará)" % id)
		var v := str(e.get("visibilidad", "publico"))
		if v == "secreto" and str(e.get("requiere_quest", "")) == "":
			errores.append("%s: secreto sin condición de revelado" % id)
	return errores
```

8. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	var lore := BaseDeLore.new()
	check.call(lore.cargar("res://datos/lore/mundo.json").is_empty(), "el lore valida")

	var estado := {"lugar": "villarroca", "quests_completadas": []}

	# Recuperación por etiqueta.
	var r1 := lore.recuperar("háblame de la mina", &"aldeano_generico", estado)
	check.call(r1.any(func(e): return e["id"] == "mina_derrumbe"),
		"se recupera el lore de la mina")

	# El SECRETO no se recupera sin la quest.
	check.call(not r1.any(func(e): return e["id"] == "mina_causa_real"),
		"el secreto no se filtra sin la quest")
	estado["quests_completadas"] = ["la_verdad_de_la_mina"]
	var r2 := lore.recuperar("háblame de la mina", &"aldeano_generico", estado)
	check.call(r2.any(func(e): return e["id"] == "mina_causa_real"),
		"el secreto se revela tras la quest")

	# Visibilidad por NPC.
	var r3 := lore.recuperar("háblame de Doran", &"aldeano_generico", estado)
	check.call(not r3.any(func(e): return e["id"] == "bram_hermano"),
		"otro NPC no conoce el lore privado de Bram")
	var r4 := lore.recuperar("háblame de Doran", &"herrero_bram", estado)
	check.call(r4.any(func(e): return e["id"] == "bram_hermano"),
		"Bram sí conoce su propio lore")

	# Determinismo.
	check.call(_ids(lore.recuperar("la mina", &"herrero_bram", estado))
			== _ids(lore.recuperar("la mina", &"herrero_bram", estado)),
		"la recuperación es determinista")

	# Memoria: poda y persistencia.
	var m := Memoria.new()
	for i in 40:
		m.anotar(&"herrero_bram", "hecho número %d" % i)
	check.call(m.hechos(&"herrero_bram").size() <= Memoria.MAX_LARGO_POR_NPC,
		"la memoria se poda")
	var d := m.a_dict()
	var m2 := Memoria.new(); m2.de_dict(d)
	check.call(m2.hechos(&"herrero_bram").size() == m.hechos(&"herrero_bram").size(),
		"la memoria sobrevive al guardado")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

## ✍️ Ejercicios

1. Escribe 30 entradas de lore de tu juego con etiquetas y visibilidad.
2. Añade un tipo de visibilidad `faccion:` y respétalo en la recuperación.
3. Mide qué porcentaje de consultas típicas recupera la entrada correcta en el top 3.
4. Implementa resumen automático de la memoria antigua en un solo hecho condensado.
5. Añade el verificador de anclaje a la telemetría y mide la tasa de nombres desconocidos.
6. Compara la recuperación léxica con una búsqueda semántica sencilla y documenta la diferencia real.
7. Diseña qué recuerdos deben caducar (una promesa cumplida) y cuáles no (una traición).

## 📝 Reto verificable

Implementa la base de lore con **al menos 25 entradas** y tres niveles de visibilidad, recuperación léxica determinista con etiquetas, texto y contexto de escena, memoria a corto y largo plazo con deduplicación y poda, persistencia en el save, presupuesto de contexto y verificador de anclaje.

**Criterio de aceptación**: una prueba headless con **al menos 18 aserciones** demuestra que: (a) el validador rechaza entrada sin etiquetas, sin texto, con texto excesivo, con id duplicado y secreto sin condición; (b) una entrada `secreto` no se recupera antes de cumplirse su condición y **sí** después; (c) una entrada con visibilidad `npc:X` solo la recupera ese NPC; (d) la recuperación es determinista: la misma consulta y el mismo estado devuelven exactamente los mismos ids en el mismo orden; (e) la memoria se poda al máximo configurado conservando los hechos de mayor peso y más recientes; (f) `a_dict()` → `de_dict()` conserva la memoria a largo plazo y **no** la conversación; (g) el contexto construido no supera el presupuesto de tokens declarado; (h) el verificador de anclaje detecta un nombre propio inventado en una respuesta de prueba.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El NPC inventa nombres y sucesos | No hay lore recuperado o no se pide anclaje. Ambas cosas. |
| Un aldeano revela el giro de la trama | Falta visibilidad en la entrada. Marca los secretos y su condición. |
| Se recupera lore irrelevante y se pierde el bueno | Etiquetas pobres o entradas demasiado largas. Parte y etiqueta mejor. |
| El NPC no recuerda nada entre sesiones | La memoria no se guarda. Va al save, con su versión. |
| El contexto crece hasta desbordar | Sin presupuesto ni poda. Reparte y poda. |
| La memoria se llena de trivialidades | Sin peso ni deduplicación. Añade ambos. |
| Dos ejecuciones recuperan cosas distintas | Falta desempate estable en el orden. Ordena por puntuación y luego por id. |
| Se montó una base vectorial para 40 entradas | Complejidad innecesaria. Empieza por léxica y mide antes de cambiar. |
| El NPC menciona algo del lore que no debía conocer | El filtro de visibilidad se aplicó después de puntuar. Va primero. |

## ❓ Preguntas frecuentes

**❓ ¿No necesito embeddings para hacer RAG "de verdad"?** No. RAG significa recuperar y aumentar el contexto; **cómo** recuperas es una decisión de implementación. Con un vocabulario controlado (el de tu mundo) y etiquetas bien puestas, la recuperación léxica acierta casi siempre, es gratis, determinista y depurable. Los embeddings aportan con paráfrasis y sinónimos; mide si eso te está costando aciertos antes de añadir la dependencia.

**❓ ¿Cuánto lore mando por turno?** Entre 3 y 6 entradas cortas. Más diluye la señal: el modelo presta menos atención a cada hecho y el coste sube en cada turno. Si necesitas mandar diez entradas para responder algo, probablemente las entradas son demasiado largas o están mal etiquetadas.

**❓ ¿Cómo evito que un NPC revele un secreto?** Con tres capas: **no está en su contexto** (visibilidad), **la regla de anclaje lo prohíbe** (prompt) y **el validador comprueba la respuesta** (clase 331). La primera es la que de verdad funciona: lo que no está en el contexto no se puede filtrar.

**❓ ¿La memoria debe ser literal o resumida?** Corto plazo literal (los últimos turnos, tal cual) y largo plazo resumido (hechos de una línea). Guardar toda la conversación de 200 turnos no cabe en el contexto ni aporta: lo que importa a los tres días es "le vendí una espada y me cayó bien", no las palabras exactas.

**❓ ¿Esto sirve para NPC sin LLM?** Sí, y es un uso infravalorado: la base de lore con visibilidad y recuperación sirve igual para decidir qué opciones de diálogo escrito ofrecer ([clase 304](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/304-sistemas-de-dialogo/README.md)), y la memoria a largo plazo alimenta condiciones de diálogo sin ningún modelo de por medio.

## 🔗 Referencias

- Godot Docs — `RegEx` (extracción de nombres propios): <https://docs.godotengine.org/en/stable/classes/class_regex.html>
- Godot Docs — `JSON` y diccionarios: <https://docs.godotengine.org/en/stable/classes/class_json.html>
- OWASP — Top 10 for LLM Applications (fuga de información sensible): <https://owasp.org/www-project-top-10-for-large-language-model-applications/>
- Lewis et al. — *Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks* (artículo original de RAG): <https://arxiv.org/abs/2005.11401>
- GDC Vault — charlas sobre bases de conocimiento narrativo y coherencia de mundo: <https://www.gdcvault.com/>

## ⬅️ Clase anterior

[Clase 331 - NPC controlados por LLM](../331-npc-controlados-por-llm/README.md)

## ➡️ Siguiente clase

[Clase 333 - Diálogo, quests y contenido generativo](../333-dialogo-quests-y-contenido-generativo/README.md)
