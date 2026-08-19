# Clase 331 — NPC controlados por LLM

> Parte: **20 — IA generativa y desarrollo de juegos asistido por IA** · Fuente: *OWASP Top 10 for LLM Applications · Charlas de GDC sobre NPC conversacionales*
> ⏱️ Duración estimada: **125 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir la arquitectura de un **NPC que conversa** sin que el modelo pueda romper el juego. La cadena completa es esta, y cada flecha es un punto de control:

```text
NPC → Constructor de contexto → Lore → Memoria → AIProvider → Validador de respuesta → Acción de juego
```

La regla que gobierna toda la clase, y que conviene grabar antes de escribir una línea: **el modelo propone, el juego dispone**. Un LLM no abre puertas, no da objetos, no inicia quests y no modifica la reputación. Genera una **intención estructurada** que un sistema conocido valida contra las reglas del juego y, si es válida, ejecuta. Si no lo es, se descarta y el NPC dice otra cosa.

Vas a implementar esa arquitectura completa con el proveedor mock, de forma que sea testeable, determinista en CI y funcione igual si mañana cambias de modelo.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diseñar la arquitectura completa de un NPC conversacional con sus puntos de control.
2. Construir un contexto acotado con identidad, lore relevante, memoria y estado del juego.
3. Definir un contrato de salida estructurada con intenciones cerradas.
4. Implementar un validador que rechace toda intención imposible o no permitida.
5. Implementar la ejecución de intenciones válidas mediante los sistemas existentes.
6. Diseñar fallbacks que mantengan al NPC utilizable cuando el modelo falla.
7. Probar todo el sistema headless con un proveedor mock determinista.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | El modelo propone, el juego dispone | Es la regla que hace segura toda la arquitectura. |
| 2 | Identidad del personaje | Lo que hace que un NPC sea ese NPC y no un asistente. |
| 3 | Constructor de contexto | Decide qué sabe el NPC en cada momento. |
| 4 | Presupuesto de contexto | El contexto es finito y hay que repartirlo. |
| 5 | Salida estructurada | Texto libre no se puede validar; una intención sí. |
| 6 | Lista cerrada de intenciones | El NPC solo puede querer cosas que el juego entiende. |
| 7 | Validación contra el juego | La intención debe ser posible **ahora**. |
| 8 | Ejecución por sistemas conocidos | Nadie escribe estado directamente desde la respuesta. |
| 9 | Fallbacks | El NPC debe seguir sirviendo si el modelo no responde. |
| 10 | Pruebas con mock | Determinista, gratis y sin red. |

## 📖 Definiciones y características

- **NPC conversacional**: personaje con el que el jugador dialoga en lenguaje natural. Clave: su valor está en la variedad, no en la lógica.
- **Identidad (character card)**: descripción estable del personaje: quién es, cómo habla, qué sabe, qué no sabe. Clave: va en cada petición y no cambia.
- **Constructor de contexto**: componente que ensambla lo que el modelo recibe. Clave: es donde se decide todo lo que el NPC "sabe".
- **Presupuesto de contexto**: reparto de tokens entre identidad, lore, memoria y estado. Clave: sin reparto, algo se queda fuera de forma impredecible.
- **Intención (intent)**: acción estructurada que el modelo propone. Clave: pertenece a una lista cerrada definida por el juego.
- **Salida estructurada**: respuesta en formato validable (JSON con esquema). Clave: es la condición para poder validar.
- **Validador de respuesta**: comprueba forma, contenido y viabilidad. Clave: es el guardián entre el modelo y el estado del juego.
- **Validación de esquema**: la respuesta tiene los campos y tipos esperados. Clave: primer filtro, barato.
- **Validación de reglas**: la intención es **posible** en el estado actual. Clave: segundo filtro, y el que importa.
- **Acción de juego**: ejecución de una intención válida por el sistema correspondiente. Clave: siempre por los sistemas de la Parte 18, nunca escribiendo estado directamente.
- **Fallback**: respuesta prevista cuando el modelo falla o se rechaza su salida. Clave: escrita a mano, siempre disponible.
- **Anclaje (grounding)**: incluir hechos verificados para que la respuesta se ciña a ellos. Clave: reduce la invención (clase 332).
- **Barandilla (guardrail)**: restricción explícita sobre lo que el NPC puede decir o hacer. Clave: en el prompt **y** en el validador; solo en el prompt no basta.
- **Turno**: un intercambio jugador → NPC. Clave: es la unidad de coste, latencia y memoria.
- **Proveedor mock**: implementación determinista para pruebas. Clave: hace el sistema testeable en CI.

## 🧰 Herramientas y preparación

Godot 4.x, el sistema de diálogo de la [clase 304](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/304-sistemas-de-dialogo/README.md), el de quests de la [305](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/305-quest-system/README.md), el inventario de la [295](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/295-sistema-de-inventario/README.md) y la reputación de la [306](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/306-facciones-reputacion-y-relaciones/README.md). Trabajaremos en `res://ia/npc/`. **No necesitas ninguna clave de API**: todo el laboratorio usa `MockProvider`, y la abstracción completa se construye en la [clase 334](../334-proveedores-locales-y-remotos/README.md).

## 🧪 Laboratorio guiado

1. **La arquitectura, con los puntos de control marcados:**

```text
   Jugador escribe
        │
        ▼
 ┌──────────────────┐
 │ ConstructorCtx   │◄── Identidad (fija) · Lore (recuperado) · Memoria · Estado del juego
 └────────┬─────────┘
          │  prompt + esquema de salida
          ▼
 ┌──────────────────┐
 │   AIProvider     │   mock · local · remoto  (clase 334)
 └────────┬─────────┘
          │  texto (que puede ser cualquier cosa)
          ▼
 ┌──────────────────┐   ① ¿es JSON válido con el esquema?         ─┐
 │    Validador     │   ② ¿la intención está en la lista cerrada?   │ si falla
 │                  │   ③ ¿es posible AHORA en el juego?           ─┘   cualquiera
 └────────┬─────────┘                                                  → FALLBACK
          │  intención validada
          ▼
 ┌──────────────────┐
 │  Ejecutor        │──► Inventario · Quests · Reputación · Diálogo
 └────────┬─────────┘    (los sistemas de la Parte 18, sin excepción)
          ▼
   Respuesta al jugador  +  Memoria actualizada
```

2. **La identidad del personaje.** Estable, escrita a mano, versionada:

```json
{
  "id": "herrero_bram",
  "nombre": "Bram",
  "rol": "Herrero del pueblo de Villarroca",
  "voz": "Directo, seco, pocas palabras. Usa metáforas de fragua. Nunca es grosero.",
  "sabe": [
    "Forja armas y armaduras de hierro y acero.",
    "Conoce a todos los habitantes del pueblo.",
    "Perdió a su hermano en la mina hace tres años; no habla del tema con desconocidos."
  ],
  "no_sabe": [
    "Nada de lo que ocurre fuera del valle.",
    "Nada de magia: desconfía de ella.",
    "El nombre del jugador, salvo que se lo hayan dicho."
  ],
  "nunca": [
    "Prometer objetos, oro, quests o descuentos que el juego no haya confirmado.",
    "Revelar información marcada como secreta en el lore.",
    "Salirse del personaje ni mencionar que es un personaje de un juego.",
    "Hablar de temas ajenos al mundo del juego."
  ],
  "max_palabras": 60
}
```

Los apartados `no_sabe` y `nunca` son tan importantes como `sabe`: sin ellos, el NPC responderá **a todo**, porque el modelo subyacente sabe de todo. Y `max_palabras` no es un detalle de estilo: es control de coste y de latencia.

3. **El contrato de salida.** Intenciones cerradas, definidas por el juego:

```json
{
  "dialogo": "string, máximo 60 palabras, en la voz del personaje",
  "intencion": {
    "tipo": "ninguna | ofrecer_quest | abrir_tienda | dar_item | pedir_item | reaccion",
    "parametros": {}
  },
  "emocion": "neutral | contento | molesto | preocupado | orgulloso",
  "recordar": "string opcional, máximo 20 palabras: hecho relevante de este turno"
}
```

```gdscript
class_name Intencion
extends RefCounted

# LISTA CERRADA. Todo lo que no esté aquí se rechaza sin discusión. Añadir una
# intención nueva es una decisión de diseño, no algo que el modelo pueda hacer.
enum Tipo { NINGUNA, OFRECER_QUEST, ABRIR_TIENDA, DAR_ITEM, PEDIR_ITEM, REACCION }

const NOMBRES := {
	"ninguna": Tipo.NINGUNA, "ofrecer_quest": Tipo.OFRECER_QUEST,
	"abrir_tienda": Tipo.ABRIR_TIENDA, "dar_item": Tipo.DAR_ITEM,
	"pedir_item": Tipo.PEDIR_ITEM, "reaccion": Tipo.REACCION,
}

var tipo: Tipo = Tipo.NINGUNA
var parametros: Dictionary = {}
```

4. **El constructor de contexto.** Con presupuesto explícito de tokens:

```gdscript
class_name ConstructorContexto
extends RefCounted

# Reparto del presupuesto. Sin él, el lore se come la memoria o al revés, y el
# comportamiento cambia según la longitud de lo que el jugador escriba.
const PRESUPUESTO := {
	"identidad": 350,
	"lore": 600,
	"memoria": 300,
	"estado": 200,
	"conversacion": 400,
}

var lore: BaseDeLore                # clase 332
var memoria: Memoria                # clase 332

func construir(npc: Dictionary, jugador_dice: String, estado: Dictionary) -> Dictionary:
	var partes := []

	partes.append(_identidad(npc))
	# El lore se RECUPERA por relevancia, no se manda entero: no cabe, y
	# mandarlo entero diluye lo importante.
	partes.append(_lore(jugador_dice, estado, PRESUPUESTO["lore"]))
	partes.append(_memoria(npc["id"], PRESUPUESTO["memoria"]))
	partes.append(_estado_del_juego(estado))
	partes.append(_reglas_de_salida(npc))

	return {
		"sistema": "\n\n".join(partes),
		"usuario": jugador_dice.substr(0, 500),   # el jugador no fija el tamaño
		"esquema": ESQUEMA_RESPUESTA,
		"temperatura": 0.7,
		"max_tokens": 200,
	}

func _estado_del_juego(e: Dictionary) -> String:
	# HECHOS, no interpretaciones. El modelo no debe deducir si el jugador
	# tiene la quest: se lo decimos.
	return """ESTADO ACTUAL (hechos verificados; no inventes nada fuera de esto):
- Reputación del jugador con la facción del pueblo: %s
- Quests activas con este NPC: %s
- Quests que este NPC puede ofrecer ahora: %s
- Objetos relevantes que lleva el jugador: %s
- Momento del día: %s""" % [
		e.get("reputacion_umbral", "neutral"),
		str(e.get("quests_activas", [])),
		str(e.get("quests_ofrecibles", [])),
		str(e.get("items_relevantes", [])),
		e.get("momento", "día")]

func _reglas_de_salida(npc: Dictionary) -> String:
	return """REGLAS DE RESPUESTA (obligatorias):
- Responde SOLO con un objeto JSON que cumpla el esquema. Sin texto alrededor.
- El diálogo, máximo %d palabras, en la voz del personaje.
- `intencion.tipo` debe ser uno de: ninguna, ofrecer_quest, abrir_tienda,
  dar_item, pedir_item, reaccion. Cualquier otro valor será descartado.
- Solo puedes ofrecer quests de la lista "quests ofrecibles". Si el jugador
  pide otra cosa, usa `ninguna` y explícalo en el diálogo.
- No prometas nada que no esté en el estado actual.""" % int(npc.get("max_palabras", 60))
```

5. **El validador.** Tres filtros, en orden de coste:

```gdscript
class_name ValidadorRespuesta
extends RefCounted

enum Motivo { OK, NO_ES_JSON, ESQUEMA_INVALIDO, INTENCION_DESCONOCIDA,
			  INTENCION_IMPOSIBLE, CONTENIDO_RECHAZADO, DEMASIADO_LARGO }

class Resultado extends RefCounted:
	var motivo: Motivo = Motivo.OK
	var dialogo: String = ""
	var intencion := Intencion.new()
	var emocion: String = "neutral"
	var recordar: String = ""
	func ok() -> bool: return motivo == Motivo.OK

func validar(texto: String, npc: Dictionary, estado: Dictionary) -> Resultado:
	var r := Resultado.new()

	# ① FORMA. Barato: si no es JSON, no seguimos.
	var d = JSON.parse_string(texto.strip_edges())
	if typeof(d) != TYPE_DICTIONARY:
		r.motivo = Motivo.NO_ES_JSON
		return r
	if not d.has("dialogo") or not d.has("intencion"):
		r.motivo = Motivo.ESQUEMA_INVALIDO
		return r

	r.dialogo = str(d["dialogo"]).strip_edges()
	if r.dialogo.split(" ").size() > int(npc.get("max_palabras", 60)) * 1.5:
		r.motivo = Motivo.DEMASIADO_LARGO
		return r

	# ② CONTENIDO. Moderación y barandillas (clase 336).
	if _contenido_rechazable(r.dialogo, npc):
		r.motivo = Motivo.CONTENIDO_RECHAZADO
		return r

	# ③ INTENCIÓN. Lista cerrada primero, viabilidad después.
	var i: Dictionary = d["intencion"]
	var nombre := str(i.get("tipo", "ninguna"))
	if not Intencion.NOMBRES.has(nombre):
		r.motivo = Motivo.INTENCION_DESCONOCIDA
		return r
	r.intencion.tipo = Intencion.NOMBRES[nombre]
	r.intencion.parametros = i.get("parametros", {})

	var viable := _es_posible(r.intencion, estado)
	if not viable:
		r.motivo = Motivo.INTENCION_IMPOSIBLE
		return r

	r.emocion = str(d.get("emocion", "neutral"))
	r.recordar = str(d.get("recordar", "")).substr(0, 200)
	return r

func _es_posible(i: Intencion, estado: Dictionary) -> bool:
	"""La comprobación que importa: ¿el juego permite esto AHORA?"""
	match i.tipo:
		Intencion.Tipo.NINGUNA, Intencion.Tipo.REACCION:
			return true
		Intencion.Tipo.ABRIR_TIENDA:
			return bool(estado.get("npc_es_comerciante", false))
		Intencion.Tipo.OFRECER_QUEST:
			# Solo quests que el diario diga que están disponibles. Si el
			# modelo inventa una, aquí muere.
			var q := str(i.parametros.get("quest_id", ""))
			return q in estado.get("quests_ofrecibles", [])
		Intencion.Tipo.DAR_ITEM:
			# Un NPC no regala nada que no esté explícitamente autorizado.
			var it := str(i.parametros.get("item_id", ""))
			return it in estado.get("items_que_puede_dar", [])
		Intencion.Tipo.PEDIR_ITEM:
			var it2 := str(i.parametros.get("item_id", ""))
			return it2 in estado.get("items_relevantes", [])
	return false
```

6. **El ejecutor.** Nadie escribe estado directamente:

```gdscript
class_name EjecutorIntenciones
extends RefCounted

var _diario: Diario
var _inv: Inventario
var _social: Social
var _tienda: Tienda

func ejecutar(i: Intencion, jugador: StringName) -> Dictionary:
	# Cada intención se ejecuta por el SISTEMA correspondiente, que aplica sus
	# propias reglas. Si el sistema dice que no, no pasa nada raro: no ocurre.
	match i.tipo:
		Intencion.Tipo.OFRECER_QUEST:
			var q := StringName(str(i.parametros.get("quest_id", "")))
			return {"ok": _diario.aceptar(q), "efecto": "quest_ofrecida", "quest": q}
		Intencion.Tipo.ABRIR_TIENDA:
			return {"ok": true, "efecto": "abrir_tienda", "tienda": _tienda.id_tienda}
		Intencion.Tipo.DAR_ITEM:
			var it := StringName(str(i.parametros.get("item_id", "")))
			var n := clampi(int(i.parametros.get("cantidad", 1)), 1, 5)   # tope duro
			return {"ok": _inv.agregar_todo_o_nada(it, n), "efecto": "item_dado"}
		_:
			return {"ok": true, "efecto": "ninguno"}
```

7. **Los fallbacks.** Escritos a mano y siempre disponibles:

```gdscript
class_name Fallbacks
extends RefCounted

# Un NPC que no responde es un bug visible. Uno que responde algo escrito a
# mano y coherente con su personaje es, simplemente, un NPC normal.
const POR_MOTIVO := {
	ValidadorRespuesta.Motivo.NO_ES_JSON:          "generico",
	ValidadorRespuesta.Motivo.ESQUEMA_INVALIDO:    "generico",
	ValidadorRespuesta.Motivo.INTENCION_DESCONOCIDA: "generico",
	ValidadorRespuesta.Motivo.INTENCION_IMPOSIBLE: "no_puedo",
	ValidadorRespuesta.Motivo.CONTENIDO_RECHAZADO: "cambiar_tema",
	ValidadorRespuesta.Motivo.DEMASIADO_LARGO:     "generico",
}

static func para(npc: Dictionary, motivo: int, rng: RandomNumberGenerator) -> String:
	var clave: String = POR_MOTIVO.get(motivo, "generico")
	var opciones: Array = npc.get("fallbacks", {}).get(clave, ["..."])
	return str(opciones[rng.randi() % opciones.size()])
```

```json
"fallbacks": {
  "generico": ["Hmm. Ahora no tengo la cabeza para eso.",
               "El fuego no espera. Habla claro o vuelve luego."],
  "no_puedo": ["Eso no está en mi mano.",
               "Pídeme hierro y acero, no milagros."],
  "cambiar_tema": ["No hablemos de eso. ¿Necesitas algo de la fragua?"],
  "sin_conexion": ["*Bram sigue martilleando, absorto en su trabajo.*"]
}
```

8. **El NPC completo:**

```gdscript
class_name NPCConversacional
extends RefCounted

signal respondio(dialogo: String, emocion: String)
signal intencion_ejecutada(efecto: Dictionary)
signal fallback_usado(motivo: int)

var identidad: Dictionary
var _proveedor: AIProvider
var _ctx: ConstructorContexto
var _val: ValidadorRespuesta
var _ejec: EjecutorIntenciones
var _mem: Memoria
var _rng: RandomNumberGenerator

func hablar(texto_jugador: String, estado: Dictionary) -> void:
	var peticion := _ctx.construir(identidad, texto_jugador, estado)
	var respuesta := await _proveedor.completar(peticion)

	if not respuesta.ok:
		# Sin proveedor, el NPC sigue existiendo. Esto no es degradación: es
		# el comportamiento normal de un NPC de toda la vida.
		respondio.emit(Fallbacks.para(identidad, -1, _rng), "neutral")
		fallback_usado.emit(-1)
		return

	var r := _val.validar(respuesta.texto, identidad, estado)
	if not r.ok():
		respondio.emit(Fallbacks.para(identidad, r.motivo, _rng), "neutral")
		fallback_usado.emit(r.motivo)
		Log.warn("npc_respuesta_rechazada",
			{"npc": identidad["id"], "motivo": r.motivo})
		return

	if r.intencion.tipo != Intencion.Tipo.NINGUNA:
		var efecto := _ejec.ejecutar(r.intencion, estado.get("jugador", &""))
		intencion_ejecutada.emit(efecto)

	if r.recordar != "":
		_mem.anotar(StringName(identidad["id"]), r.recordar)
	respondio.emit(r.dialogo, r.emocion)
```

9. **Probarlo con el mock.** Determinista, gratis, sin red:

```gdscript
extends SceneTree

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	var mock := MockProvider.new(42)
	var npc := NPCConversacional.nuevo("res://datos/npcs/herrero_bram.json", mock)
	var estado := {"quests_ofrecibles": ["lobos_del_camino"],
				   "items_que_puede_dar": [], "npc_es_comerciante": true}

	# Respuesta válida con intención posible.
	mock.responder('{"dialogo":"Tengo trabajo para ti.","intencion":' +
		'{"tipo":"ofrecer_quest","parametros":{"quest_id":"lobos_del_camino"}},' +
		'"emocion":"neutral"}')
	await npc.hablar("¿Necesitas ayuda?", estado)
	check.call(npc.ultima_intencion().tipo == Intencion.Tipo.OFRECER_QUEST,
		"una intención válida se ejecuta")

	# Quest INVENTADA: se rechaza.
	mock.responder('{"dialogo":"Ve a matar al dragón.","intencion":' +
		'{"tipo":"ofrecer_quest","parametros":{"quest_id":"matar_dragon"}},"emocion":"neutral"}')
	await npc.hablar("¿Algo más?", estado)
	check.call(npc.ultimo_fallback() == ValidadorRespuesta.Motivo.INTENCION_IMPOSIBLE,
		"una quest inexistente se rechaza")

	# Intención FUERA de la lista cerrada.
	mock.responder('{"dialogo":"Toma.","intencion":{"tipo":"borrar_partida"},"emocion":"neutral"}')
	await npc.hablar("Hola", estado)
	check.call(npc.ultimo_fallback() == ValidadorRespuesta.Motivo.INTENCION_DESCONOCIDA,
		"una intención desconocida se rechaza")

	# Regalo NO autorizado.
	mock.responder('{"dialogo":"Toma mi espada legendaria.","intencion":' +
		'{"tipo":"dar_item","parametros":{"item_id":"hoja_legendaria","cantidad":99}},' +
		'"emocion":"contento"}')
	await npc.hablar("¿Me das algo?", estado)
	check.call(npc.ultimo_fallback() == ValidadorRespuesta.Motivo.INTENCION_IMPOSIBLE,
		"el NPC no puede regalar lo que no está autorizado")

	# Respuesta que no es JSON.
	mock.responder("Claro, aquí tienes tu espada mágica.")
	await npc.hablar("Hola", estado)
	check.call(npc.ultimo_fallback() == ValidadorRespuesta.Motivo.NO_ES_JSON,
		"texto libre se rechaza")

	# Proveedor caído: el NPC sigue funcionando.
	mock.caido = true
	await npc.hablar("Hola", estado)
	check.call(npc.ultimo_dialogo() != "", "hay fallback sin proveedor")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

## ✍️ Ejercicios

1. Escribe la identidad completa de un NPC de tu juego, con `sabe`, `no_sabe` y `nunca`.
2. Define la lista cerrada de intenciones que tu juego permite y su validación.
3. Añade la intención `cambiar_precio` con un rango acotado y su validación.
4. Implementa el presupuesto de contexto y mide cuántos tokens ocupa cada parte.
5. Escribe diez fallbacks en la voz del personaje, por categoría.
6. Añade telemetría de rechazos por motivo y analiza cuál domina.
7. Diseña la interfaz cuando el NPC tarda: qué ve el jugador durante la espera.

## 📝 Reto verificable

Implementa un NPC conversacional completo con identidad versionada, constructor de contexto con presupuesto, contrato de salida estructurada, **al menos cinco intenciones** en lista cerrada, validador de tres filtros, ejecutor que solo actúa por los sistemas existentes, fallbacks por motivo y proveedor mock determinista.

**Criterio de aceptación**: una prueba headless con **al menos 20 aserciones** demuestra que: (a) una respuesta que no es JSON se rechaza y produce fallback; (b) una intención fuera de la lista cerrada se rechaza; (c) una intención de la lista pero **imposible en el estado actual** (quest inexistente, item no autorizado, tienda en un NPC no comerciante) se rechaza; (d) una respuesta válida ejecuta la acción **a través del sistema correspondiente**, comprobable en el estado de ese sistema; (e) con el proveedor caído el NPC responde un fallback y el juego continúa; (f) el sistema **nunca** modifica inventario, quests ni reputación sin pasar por el ejecutor; (g) con la misma semilla del mock, dos ejecuciones producen exactamente la misma secuencia; (h) el contexto construido respeta el presupuesto de tokens declarado.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El NPC promete objetos que nunca llegan | Se validó el texto, no la intención. Lista cerrada + viabilidad. |
| El NPC regala un item legendario | La intención no se validó contra `items_que_puede_dar`. |
| El NPC habla de cosas ajenas al juego | Falta `no_sabe`/`nunca` en la identidad y filtro en el validador. |
| Sin conexión el NPC no dice nada | No hay fallback. Escríbelos a mano, por categoría. |
| Las respuestas se salen del personaje | Identidad demasiado vaga. Concreta voz, límites y ejemplos. |
| El contexto crece hasta desbordar | Sin presupuesto. Reparte y recorta por relevancia. |
| Las pruebas necesitan red y una clave | Se usa el proveedor real. Mock determinista en CI. |
| El NPC repite lo mismo todo el rato | Falta memoria o la temperatura es demasiado baja. Ver clase 332. |
| El jugador escribe algo largo y cambia el comportamiento | La entrada no está acotada. Recorta y trátala como no confiable (clase 336). |

## ❓ Preguntas frecuentes

**❓ ¿Por qué no dejar que el modelo llame directamente a funciones del juego?** Porque entonces el modelo **es** el sistema de reglas, y no puedes garantizar nada: ni que la quest exista, ni que el item sea razonable, ni que el jugador no lo haya convencido con un mensaje ingenioso. Con intención + validación, lo peor que puede pasar es que el NPC diga algo raro; el estado del juego queda intacto.

**❓ ¿Y si el modelo devuelve JSON mal formado?** Ocurre, y por eso el primer filtro es de forma. Medidas prácticas que ayudan: pedir explícitamente "solo el objeto JSON", dar el esquema, usar modo JSON si el proveedor lo tiene, y reintentar **una vez** antes de caer al fallback. Lo que no debe hacerse es intentar "arreglar" el JSON con expresiones regulares.

**❓ ¿Cuántas intenciones defino?** Las mínimas. Cada intención es superficie de ataque y de error. Empieza con `ninguna` y `reaccion` (que no tocan nada) y añade una a una las que aporten de verdad. Un NPC que solo conversa con variedad ya vale mucho.

**❓ ¿No es más simple usar el sistema de diálogo de la clase 304?** Para conversaciones que importan a la trama, **sí**, y esa es la respuesta correcta la mayoría de las veces: un grafo escrito da control, repetibilidad y calidad de escritura. El LLM aporta donde el grafo no llega: charla ambiental, respuestas a preguntas imprevistas, variedad en NPC secundarios. Lo mejor de los dos se combina en la [clase 333](../333-dialogo-quests-y-contenido-generativo/README.md).

**❓ ¿Cómo pruebo algo no determinista?** Con el mock: tú fijas la respuesta y compruebas que **tu sistema** hace lo correcto con ella. Lo que se prueba no es el modelo, es tu validador, tu ejecutor y tus fallbacks — que es exactamente lo que puede fallar por tu culpa.

## 🔗 Referencias

- OWASP — Top 10 for LLM Applications (manejo inseguro de salidas, agencia excesiva): <https://owasp.org/www-project-top-10-for-large-language-model-applications/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `JSON` (parseo y validación de la respuesta): <https://docs.godotengine.org/en/4.3/classes/class_json.html> · uso: respalda el Tema 7 «Validación contra el juego»
- Godot Docs — `HTTPRequest` (base del proveedor remoto): <https://docs.godotengine.org/en/4.3/classes/class_httprequest.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- JSON Schema — definición de esquemas de salida: <https://json-schema.org/> · uso: respalda el Tema 5 «Salida estructurada»
- GDC Vault — charlas sobre NPC conversacionales y sus límites de diseño: <https://www.gdcvault.com/> — catálogo por tema, no una charla identificada (ponente y año pendientes) · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 330 - Pipeline técnico de assets asistido por IA](../330-pipeline-tecnico-de-assets-asistido-por-ia/README.md)

## ➡️ Siguiente clase

[Clase 332 - RAG, memoria y lore del mundo](../332-rag-memoria-y-lore-del-mundo/README.md)
