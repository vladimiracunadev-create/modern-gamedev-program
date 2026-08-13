# Clase 333 — Diálogo, quests y contenido generativo

> Parte: **20 — IA generativa y desarrollo de juegos asistido por IA** · Fuente: *Prácticas de generación procedural de contenido · OWASP Top 10 for LLM Applications*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Generar **contenido de juego** —diálogo, quests, descripciones, encuentros, eventos— de forma que sea siempre jugable. La diferencia con las dos clases anteriores es de alcance: allí el modelo producía una frase que un NPC decía; aquí produce una **estructura** que el juego va a ejecutar, y si esa estructura es imposible, el jugador se queda atascado.

De ahí la regla de la clase, que es la de la 331 llevada al extremo: **toda salida generativa pasa por doble validación** — primero de esquema (¿tiene la forma correcta?) y después de reglas del juego (¿es posible completarla en este mundo, con este contenido, ahora?). Y una tercera capa que casi nadie implementa y evita el 90 % de los problemas: **generar en desarrollo, publicar como contenido fijo**.

Vas a construir el generador, las dos validaciones, la corrección automática de lo corregible y el flujo que convierte una quest generada en una quest normal del juego, indistinguible de una escrita a mano.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Distinguir generación **en desarrollo** de generación **en runtime** y elegir la adecuada.
2. Definir el espacio de generación con vocabularios cerrados y plantillas.
3. Implementar validación de esquema y validación contra las reglas del juego.
4. Implementar corrección automática de errores recuperables y rechazo del resto.
5. Verificar que una quest generada es **completable** simulando su cumplimiento.
6. Implementar caché y revisión de contenido generado para publicarlo como fijo.
7. Medir la calidad del contenido generado con métricas objetivas.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Desarrollo vs runtime | Cambia por completo el riesgo y los requisitos. |
| 2 | Vocabulario cerrado | El modelo solo puede referirse a lo que existe. |
| 3 | Plantillas y huecos | Estructura fija, contenido variable: lo mejor de los dos. |
| 4 | Validación de esquema | Forma correcta: barato y primero. |
| 5 | Validación de reglas | Posible en el juego: lo que de verdad importa. |
| 6 | Completabilidad | Una quest imposible es peor que ninguna quest. |
| 7 | Corrección automática | Muchos errores se arreglan sin volver a generar. |
| 8 | Caché y revisión | Convertir lo generado en contenido normal. |
| 9 | Métricas de calidad | Repetición, variedad, coherencia: medibles. |
| 10 | Presupuesto de rechazo | Si se rechaza demasiado, el planteamiento falla. |

## 📖 Definiciones y características

- **Contenido generativo**: contenido de juego producido por un modelo. Clave: es una propuesta hasta que valida.
- **Generación en desarrollo**: producir, revisar y publicar como contenido fijo. Clave: riesgo bajo, calidad alta, sin coste en producción.
- **Generación en runtime**: producir durante la partida. Clave: variedad infinita, y todos los problemas de coste, latencia y validación.
- **Vocabulario cerrado**: lista de ids que el modelo puede usar (items, NPC, zonas, enemigos). Clave: impide referencias a cosas inexistentes.
- **Plantilla**: estructura fija con huecos que el modelo rellena. Clave: acota el espacio de error drásticamente.
- **Validación de esquema**: comprobar forma, campos y tipos. Clave: primer filtro.
- **Validación de reglas**: comprobar que el contenido es coherente con el juego. Clave: segundo filtro, el decisivo.
- **Completabilidad**: propiedad de que una quest se puede terminar. Clave: se verifica simulando, no leyendo.
- **Corrección automática (reparación)**: arreglar errores recuperables sin regenerar. Clave: ahorra llamadas y mejora la tasa de aceptación.
- **Error recuperable**: el que se puede arreglar sin cambiar el sentido (cantidad fuera de rango, título largo). Clave: se corrige.
- **Error no recuperable**: referencia inexistente, estructura imposible. Clave: se rechaza.
- **Tasa de aceptación**: proporción de generaciones que pasan la validación. Clave: es la métrica de salud del sistema.
- **Presupuesto de rechazo**: número máximo de reintentos antes de caer al contenido fijo. Clave: acota coste y latencia.
- **Contenido curado**: generado, revisado por una persona y publicado como fijo. Clave: es el destino ideal de casi todo lo generado.
- **Métricas de variedad**: repetición, distribución, longitud. Clave: detectan el aburrimiento antes que los jugadores.

## 🧰 Herramientas y preparación

Godot 4.x, el sistema de diálogo de la [clase 304](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/304-sistemas-de-dialogo/README.md), el de quests de la [305](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/305-quest-system/README.md), el catálogo de la [294](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/294-items-y-base-de-datos-de-objetos/README.md) y el `MockProvider`. Trabajaremos en `res://ia/generacion/`. Todo lo generado pasa por **los mismos validadores** que el contenido escrito a mano: eso no es una casualidad, es el diseño.

## 🧪 Laboratorio guiado

1. **La decisión previa: ¿desarrollo o runtime?**

| | En desarrollo | En runtime |
|---|---|---|
| Cuándo se genera | Antes de publicar | Durante la partida |
| Revisión humana | Sí, siempre | Imposible |
| Coste en producción | Cero | Por generación |
| Latencia | Irrelevante | Crítica |
| Validación | La misma, más revisión | Automática y estricta |
| Si falla | Se descarta y se regenera | Fallback al contenido fijo |
| Variedad | Acotada (lo que generes) | Infinita |
| Riesgo | Bajo | Alto |

**Empieza siempre por desarrollo.** Generar 200 descripciones de items, revisarlas en una tarde y publicarlas como contenido fijo te da el 80 % del valor con el 5 % del riesgo. La generación en runtime solo compensa cuando la variedad **infinita** es la propuesta del juego.

2. **El vocabulario cerrado.** Lo que hace posible validar:

```gdscript
class_name VocabularioGeneracion
extends RefCounted

# Se construye del contenido REAL del juego. El modelo no puede referirse a
# nada que no esté aquí, y como se genera del contenido, nunca se desincroniza.
var items: PackedStringArray
var enemigos: PackedStringArray
var npcs: PackedStringArray
var zonas: PackedStringArray
var tipos_objetivo := PackedStringArray(["matar", "recoger", "entregar", "alcanzar", "hablar"])

static func desde_contenido(base: BaseDeItems, diario: Diario, mundo: Mundo) -> VocabularioGeneracion:
	var v := VocabularioGeneracion.new()
	v.items = PackedStringArray(base.todos().map(func(d): return String(d.id)))
	v.enemigos = mundo.ids_enemigos()
	v.npcs = mundo.ids_npcs()
	v.zonas = mundo.ids_zonas()
	return v

func como_prompt() -> String:
	# Se le da la lista COMPLETA y se dice explícitamente que es cerrada.
	return """VOCABULARIO PERMITIDO (listas cerradas; cualquier valor fuera de
estas listas hará que la generación se descarte):
- items: %s
- enemigos: %s
- npcs: %s
- zonas: %s
- tipos de objetivo: %s""" % [
		", ".join(items), ", ".join(enemigos), ", ".join(npcs),
		", ".join(zonas), ", ".join(tipos_objetivo)]
```

3. **La plantilla.** Estructura fija, contenido variable:

```gdscript
const PLANTILLA_QUEST := {
	"tipo": "recado",                  # el ESQUEMA lo fija el juego
	"estructura": {
		"objetivos": {"min": 1, "max": 3},
		"recompensas": {"xp": {"min": 50, "max": 500},
						"oro": {"min": 10, "max": 300}},
	},
	"genera_el_modelo": ["titulo", "descripcion", "dialogo_ofrecimiento",
						 "dialogo_entrega", "eleccion_de_objetivos"],
}
```

La distinción importa: el modelo **no** decide cuántos objetivos puede tener una quest ni el rango de recompensas — eso es balance, y lo decide el diseño. Decide **cuáles** dentro del espacio permitido, y escribe el texto.

4. **La generación con doble validación:**

```gdscript
class_name GeneradorQuests
extends RefCounted

signal generada(quest: Dictionary, intentos: int)
signal rechazada(motivo: String, intento: int)
signal agotado(ultimo_motivo: String)

const MAX_INTENTOS := 3           # presupuesto de rechazo: acota coste y latencia

var _proveedor: AIProvider
var _vocab: VocabularioGeneracion
var _diario: Diario
var _base: BaseDeItems

func generar(contexto: Dictionary) -> Dictionary:
	var ultimo := ""
	for intento in MAX_INTENTOS:
		var texto := await _pedir(contexto, ultimo)
		var r := _validar(texto)

		if r["ok"]:
			generada.emit(r["quest"], intento + 1)
			return r["quest"]

		# Intento de REPARACIÓN antes de regenerar: muchos errores son de
		# rango o de longitud y no hace falta gastar otra llamada.
		var reparada := _reparar(r)
		if not reparada.is_empty():
			var r2 := _validar(JSON.stringify(reparada))
			if r2["ok"]:
				generada.emit(r2["quest"], intento + 1)
				return r2["quest"]

		ultimo = str(r["motivo"])
		rechazada.emit(ultimo, intento + 1)

	agotado.emit(ultimo)
	return {}                      # el llamador cae al contenido fijo
```

5. **Validación de esquema y de reglas.** Separadas a propósito:

```gdscript
func _validar(texto: String) -> Dictionary:
	# ── ① ESQUEMA ────────────────────────────────────────────────────────
	var d = JSON.parse_string(texto.strip_edges())
	if typeof(d) != TYPE_DICTIONARY or not d.has("quest"):
		return {"ok": false, "motivo": "no es un objeto con clave 'quest'", "clase": "esquema"}
	var q: Dictionary = d["quest"]

	for campo in ["id", "titulo", "objetivos", "recompensas"]:
		if not q.has(campo):
			return {"ok": false, "motivo": "falta '%s'" % campo, "clase": "esquema"}
	if not str(q["id"]).is_valid_identifier():
		return {"ok": false, "motivo": "id no es snake_case", "clase": "esquema", "q": q}
	if str(q["titulo"]).length() > 60:
		return {"ok": false, "motivo": "título largo", "clase": "reparable", "q": q}

	var objetivos: Array = q.get("objetivos", [])
	if objetivos.size() < 1 or objetivos.size() > 3:
		return {"ok": false, "motivo": "número de objetivos fuera de rango",
				"clase": "reparable", "q": q}

	# ── ② REGLAS DEL JUEGO ───────────────────────────────────────────────
	if _diario.existe(StringName(str(q["id"]))):
		return {"ok": false, "motivo": "id de quest ya existente", "clase": "reparable", "q": q}

	for o in objetivos:
		var tipo := str(o.get("tipo", ""))
		var obj := str(o.get("objetivo", ""))
		if not _vocab.tipos_objetivo.has(tipo):
			return {"ok": false, "motivo": "tipo de objetivo desconocido: %s" % tipo,
					"clase": "fatal"}
		# La comprobación clave: el objetivo debe EXISTIR en el juego. Un
		# "matar 5 dragones" en un juego sin dragones es una quest imposible.
		if not _existe_objetivo(tipo, obj):
			return {"ok": false, "motivo": "objetivo inexistente: %s (%s)" % [obj, tipo],
					"clase": "fatal"}
		var n := int(o.get("cantidad", 1))
		if n < 1 or n > 50:
			return {"ok": false, "motivo": "cantidad fuera de rango", "clase": "reparable", "q": q}

	for it in q["recompensas"].get("items", []):
		if not _base.existe(StringName(str(it.get("item", "")))):
			return {"ok": false, "motivo": "recompensa inexistente: %s" % it.get("item", ""),
					"clase": "fatal"}

	# ── ③ COMPLETABILIDAD ────────────────────────────────────────────────
	var c := _es_completable(q)
	if not c["ok"]:
		return {"ok": false, "motivo": "no completable: %s" % c["motivo"], "clase": "fatal"}

	return {"ok": true, "quest": q}

func _existe_objetivo(tipo: String, obj: String) -> bool:
	match tipo:
		"matar":     return _vocab.enemigos.has(obj)
		"recoger", "entregar": return _vocab.items.has(obj)
		"alcanzar":  return _vocab.zonas.has(obj)
		"hablar":    return _vocab.npcs.has(obj)
	return false
```

6. **La completabilidad.** La comprobación que separa una quest jugable de una trampa:

```gdscript
func _es_completable(q: Dictionary) -> Dictionary:
	"""No basta con que los objetivos existan: tienen que ser ALCANZABLES.
	Un item que no cae en ninguna tabla de loot ni se vende ni se craftea es
	un objetivo que el jugador no puede cumplir nunca."""
	for o in q.get("objetivos", []):
		var tipo := str(o["tipo"])
		var obj := StringName(str(o["objetivo"]))
		var n := int(o.get("cantidad", 1))

		match tipo:
			"recoger", "entregar":
				if not _mundo.item_obtenible(obj):
					return {"ok": false, "motivo": "'%s' no se puede conseguir" % obj}
				# Y en cantidad razonable: pedir 40 de un drop del 1 % son
				# horas de farmeo que nadie ha decidido.
				var esperado := _mundo.tasa_obtencion_por_hora(obj)
				if esperado > 0.0 and n / esperado > 2.0:
					return {"ok": false, "motivo": "'%s' × %d exigiría más de 2 h" % [obj, n]}
			"matar":
				if not _mundo.enemigo_presente(obj):
					return {"ok": false, "motivo": "'%s' no aparece en el mundo" % obj}
			"alcanzar":
				if not _mundo.zona_accesible(obj):
					return {"ok": false, "motivo": "la zona '%s' no es accesible" % obj}
			"hablar":
				if not _mundo.npc_vivo(obj):
					return {"ok": false, "motivo": "el NPC '%s' no está disponible" % obj}
	return {"ok": true}
```

7. **La reparación.** Muchos errores no necesitan otra llamada:

```gdscript
func _reparar(r: Dictionary) -> Dictionary:
	if str(r.get("clase", "")) != "reparable" or not r.has("q"):
		return {}                        # lo fatal no se repara: se rechaza
	var q: Dictionary = r["q"].duplicate(true)

	if str(q.get("titulo", "")).length() > 60:
		q["titulo"] = str(q["titulo"]).substr(0, 57) + "..."
	if _diario.existe(StringName(str(q.get("id", "")))):
		q["id"] = "%s_%d" % [q["id"], _siguiente_sufijo()]
	var objetivos: Array = q.get("objetivos", [])
	if objetivos.size() > 3:
		objetivos.resize(3)
	for o in objetivos:
		o["cantidad"] = clampi(int(o.get("cantidad", 1)), 1, 50)
	q["objetivos"] = objetivos
	var rec: Dictionary = q.get("recompensas", {})
	rec["xp"] = clampi(int(rec.get("xp", 100)), 50, 500)
	rec["oro"] = clampi(int(rec.get("oro", 50)), 10, 300)
	q["recompensas"] = rec
	return {"quest": q}
```

8. **De generado a contenido fijo.** El flujo que más rinde:

```gdscript
extends SceneTree   # herramientas/generar_contenido.gd -- --tipo quests --n 50

func _init() -> void:
	var gen := GeneradorQuests.nuevo(_proveedor_real_o_mock())
	var aceptadas := []
	var rechazos := {}

	for i in _n:
		var q := await gen.generar({"nivel": 5 + i % 20, "zona": _zonas[i % _zonas.size()]})
		if q.is_empty():
			continue
		aceptadas.append(q)

	# Se vuelca a un archivo REVISABLE, no directamente al contenido del juego.
	var salida := "res://datos/generado/quests_pendientes.json"
	FileAccess.open(salida, FileAccess.WRITE).store_string(
		JSON.stringify({"generadas_en": _fecha, "quests": aceptadas}, "\t"))

	print("== %d/%d aceptadas (%.0f%%) ==" % [aceptadas.size(), _n,
		100.0 * aceptadas.size() / _n])
	for motivo in rechazos:
		print("  rechazo '%s': %d" % [motivo, rechazos[motivo]])
	print("  revisa %s y mueve a datos/quests.json lo que valga" % salida)
	quit()
```

El paso final —una persona lee las 50 quests, borra 20, retoca 15 y publica 15— es el que convierte contenido generado en **contenido del juego**, con la misma consideración que el escrito a mano: entra en el catálogo, pasa los validadores normales y ya no depende de ningún proveedor.

9. **Métricas de calidad.** Objetivas, no impresiones:

```gdscript
func analizar(quests: Array) -> Dictionary:
	var titulos := {}
	var tipos := {}
	var objetivos := {}
	var repetidos := 0
	var longitudes := []

	for q in quests:
		var t := str(q["titulo"]).to_lower()
		if titulos.has(t): repetidos += 1
		titulos[t] = true
		longitudes.append(str(q.get("descripcion", "")).length())
		for o in q.get("objetivos", []):
			tipos[str(o["tipo"])] = int(tipos.get(str(o["tipo"]), 0)) + 1
			objetivos[str(o["objetivo"])] = int(objetivos.get(str(o["objetivo"]), 0)) + 1

	# Concentración: si el 60 % de las quests usan el mismo objetivo, la
	# variedad es aparente. Es la métrica que más engaña a ojo.
	var top := 0
	for k in objetivos: top = maxi(top, int(objetivos[k]))
	return {
		"total": quests.size(),
		"titulos_repetidos": repetidos,
		"variedad_objetivos": objetivos.size(),
		"concentracion_top": float(top) / maxf(quests.size(), 1),
		"distribucion_tipos": tipos,
		"longitud_media": _media(longitudes),
	}
```

10. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	var mock := MockProvider.new(7)
	var gen := GeneradorQuests.nuevo(mock, _vocab, _diario, _base, _mundo)

	# Válida.
	mock.responder(_json_quest("recado_lobos", [["matar", "lobo", 5]]))
	var q1 := await gen.generar({})
	check.call(not q1.is_empty(), "una quest válida se acepta")

	# Enemigo INEXISTENTE: fatal, no reparable.
	mock.responder(_json_quest("matar_dragon", [["matar", "dragon", 1]]))
	var q2 := await gen.generar({})
	check.call(q2.is_empty(), "un enemigo inexistente se rechaza")

	# Cantidad fuera de rango: REPARABLE, no debe rechazarse.
	mock.responder(_json_quest("muchos_lobos", [["matar", "lobo", 9999]]))
	var q3 := await gen.generar({})
	check.call(not q3.is_empty() and int(q3["objetivos"][0]["cantidad"]) <= 50,
		"una cantidad excesiva se repara en vez de rechazarse")

	# Item no obtenible: no completable.
	mock.responder(_json_quest("imposible", [["recoger", "item_sin_fuente", 1]]))
	check.call((await gen.generar({})).is_empty(), "una quest no completable se rechaza")

	# Presupuesto de rechazo: no se insiste indefinidamente.
	mock.responder("no soy json")
	var llamadas_antes := mock.llamadas
	await gen.generar({})
	check.call(mock.llamadas - llamadas_antes <= GeneradorQuests.MAX_INTENTOS,
		"se respeta el presupuesto de intentos")

	# La quest generada es indistinguible de una escrita: pasa el validador normal.
	check.call(_diario.validar_definicion(q1).is_empty(),
		"la quest generada pasa el validador del juego")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

## ✍️ Ejercicios

1. Genera 50 descripciones de items en desarrollo, revísalas y publica las buenas como fijas.
2. Añade generación de encuentros con validación de que la dificultad está en rango.
3. Implementa la métrica de concentración y comprueba la variedad real de un lote de 100.
4. Añade reparación de un caso más (recompensa desproporcionada respecto al esfuerzo).
5. Mide la tasa de aceptación de tu generador y diagnostica el motivo de rechazo dominante.
6. Genera diálogo para el grafo de la clase 304 rellenando solo los textos, no la estructura.
7. Implementa el flujo de revisión: interfaz que muestra lo generado y permite aceptar, editar o descartar.

## 📝 Reto verificable

Implementa un generador de contenido con vocabulario cerrado derivado del contenido real, plantilla con estructura fija, validación de esquema, validación de reglas, verificación de completabilidad, reparación de errores recuperables, presupuesto de rechazo, exportación a contenido fijo y métricas de calidad.

**Criterio de aceptación**: una prueba headless con **al menos 20 aserciones** demuestra que: (a) una referencia a un enemigo, item, zona o NPC inexistente se rechaza como fatal; (b) una cantidad, título o recompensa fuera de rango se **repara** y la quest se acepta; (c) una quest cuyo objetivo no es obtenible en el mundo se rechaza como no completable; (d) nunca se hacen más de `MAX_INTENTOS` llamadas al proveedor por generación; (e) toda quest aceptada pasa **el mismo validador** que las escritas a mano; (f) el análisis de un lote de 100 informa de títulos repetidos, variedad de objetivos y concentración; (g) el exportador escribe a un archivo de pendientes y **no** al contenido del juego; (h) con la misma semilla del mock, el resultado es idéntico.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Una quest pide matar enemigos que no existen | Sin vocabulario cerrado ni validación de reglas. Ambas. |
| Una quest no se puede completar nunca | No se verificó la completabilidad. Simula el cumplimiento. |
| Se gastan diez llamadas por quest | Sin presupuesto de rechazo ni reparación. Añade ambos. |
| Las quests generadas se ven todas iguales | Falta métrica de concentración. Mide y diversifica el prompt. |
| Contenido generado publicado sin revisar | Se escribió directo al catálogo. Vuélcalo a pendientes. |
| El modelo decide el balance de recompensas | Se le dejó fijar rangos. Los rangos son diseño; el texto, generación. |
| El contenido generado no pasa el validador del juego | Se validó con reglas distintas. Usa el mismo validador. |
| El id generado choca con uno existente | Sin comprobación de unicidad. Es reparable: añade sufijo. |

## ❓ Preguntas frecuentes

**❓ ¿Generación en runtime o en desarrollo?** En desarrollo salvo que la variedad infinita **sea** tu juego. Generar 200 descripciones, revisarlas y publicarlas te da variedad real, calidad revisada, coste cero en producción y ninguna dependencia de un proveedor. La generación en runtime es una decisión de producto con consecuencias grandes, no una comodidad técnica.

**❓ ¿Cuánto puede decidir el modelo?** El texto y la **elección dentro del espacio permitido**. Nunca el espacio: rangos de recompensa, número de objetivos, dificultad y precios son balance, y el balance es diseño. Un generador que decide el balance produce contenido incoherente con el resto del juego, aunque cada pieza suelta parezca razonable.

**❓ ¿Qué tasa de aceptación es buena?** Por encima del 70 % con reparación indica que el planteamiento funciona. Por debajo del 40 % significa que el prompt, el vocabulario o el esquema están mal — y seguir insistiendo solo gasta dinero. La tasa de aceptación es la métrica de salud del sistema, no un detalle.

**❓ ¿Puedo generar el grafo de diálogo entero?** Puedes, y suele salir mal: los grafos generados tienen saltos rotos y nodos huérfanos con facilidad. El patrón que funciona es el inverso: **la estructura la escribe una persona** (o una plantilla) y el modelo rellena los textos de los nodos. El validador de la clase 304 sigue siendo obligatorio en cualquier caso.

**❓ ¿Y el contenido generado en el save del jugador?** Si generas en runtime, la quest generada pasa a ser estado de esa partida y hay que guardarla **entera** (no su id, que no existe en el catálogo). Eso afecta al tamaño del save y a las migraciones: es otra razón de peso para preferir la generación en desarrollo.

## 🔗 Referencias

- Godot Docs — `JSON` y validación: <https://docs.godotengine.org/en/stable/classes/class_json.html>
- JSON Schema — esquemas para validar contenido generado: <https://json-schema.org/>
- OWASP — Top 10 for LLM Applications: <https://owasp.org/www-project-top-10-for-large-language-model-applications/>
- Shaker, Togelius & Nelson — *Procedural Content Generation in Games* (fundamentos de PCG): <https://www.pcgbook.com/>
- GDC Vault — charlas sobre generación de contenido y validación: <https://www.gdcvault.com/>

## ⬅️ Clase anterior

[Clase 332 - RAG, memoria y lore del mundo](../332-rag-memoria-y-lore-del-mundo/README.md)

## ➡️ Siguiente clase

[Clase 334 - Proveedores locales y remotos](../334-proveedores-locales-y-remotos/README.md)
