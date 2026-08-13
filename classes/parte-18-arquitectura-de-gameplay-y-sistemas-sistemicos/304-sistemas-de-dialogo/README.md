# Clase 304 — Sistemas de diálogo

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Charlas de GDC sobre herramientas narrativas y diálogo ramificado · Documentación de localización de Godot 4*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir un **sistema de diálogo data-driven**: un grafo de nodos con opciones, condiciones, variables, consecuencias y localización, ejecutado por un intérprete que no sabe nada del contenido concreto. La [clase 168](../../parte-8-game-design-y-diseno-de-niveles/168-narrativa-y-storytelling-en-juegos/README.md) enseñó a escribir narrativa; aquí construyes la máquina que la ejecuta.

El objetivo real no es "mostrar texto": es que un guionista pueda escribir una conversación de 40 nodos con ramas condicionales, probarla y publicarla **sin tocar el código ni pedirle nada a un programador**. Eso implica tres cosas que vas a implementar: un formato de datos legible y validable, un intérprete con un almacén de variables (*blackboard*), y un validador que detecte nodos huérfanos, saltos rotos y ramas inalcanzables antes de que un jugador se quede atascado mirando a un NPC.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Modelar una conversación como grafo dirigido de nodos con id estable.
2. Implementar un intérprete con estado explícito y avance controlado.
3. Implementar condiciones sobre variables, inventario, quests y reputación.
4. Implementar consecuencias (efectos) declarativas y aplicarlas por un despachador conocido.
5. Persistir el estado narrativo (variables, nodos vistos, opciones agotadas).
6. Localizar el diálogo separando claves de texto del grafo.
7. Validar el grafo: saltos rotos, nodos inalcanzables, callejones sin salida.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Grafo de nodos | Es la estructura natural de una conversación con ramas. |
| 2 | Nodo de línea y de elección | Dos tipos bastan para casi todo. |
| 3 | Blackboard de variables | El estado narrativo que no cabe en quests ni en el inventario. |
| 4 | Condiciones | Lo que hace que la conversación reaccione a la partida. |
| 5 | Consecuencias | El diálogo debe poder cambiar el mundo, con control. |
| 6 | Opciones agotables | "Ya se lo pregunté" es un requisito universal. |
| 7 | Localización | El texto no vive en el grafo: viven las claves. |
| 8 | Persistencia | Lo dicho debe sobrevivir al guardado. |
| 9 | Validación | Un salto roto deja al jugador encerrado en una conversación. |
| 10 | Separación intérprete/presentación | La misma conversación en bocadillo, pantalla completa o log. |

## 📖 Definiciones y características

- **Grafo de diálogo**: conjunto de nodos enlazados que representa una conversación. Clave: es contenido, editable y validable sin código.
- **Nodo**: unidad del grafo con id, tipo, contenido y salidas. Clave: su id debe ser estable porque el save guarda por dónde ibas.
- **Nodo de línea**: muestra texto de un hablante y continúa a otro nodo. Clave: la mayoría de un guion son estos.
- **Nodo de elección**: presenta opciones al jugador, cada una con su condición y su destino. Clave: es donde vive la ramificación.
- **Opción**: una alternativa dentro de un nodo de elección, con texto, condición, efectos y destino. Clave: puede estar oculta, visible pero bloqueada, o agotada.
- **Condición**: expresión evaluable sobre el estado del juego. Clave: se declara como dato, no como código incrustado.
- **Consecuencia (efecto)**: cambio declarado que se aplica al elegir o al salir de un nodo. Clave: la ejecuta un despachador con una lista cerrada de acciones.
- **Blackboard**: almacén de variables narrativas (`conoce_al_herrero`, `veces_preguntado`). Clave: es estado del jugador y va al save.
- **Bandera (flag)**: variable booleana narrativa. Clave: barata y suficiente para el 80 % de los casos.
- **Opción agotable (`una_vez`)**: opción que desaparece tras usarse. Clave: requiere registrar las opciones ya elegidas.
- **Clave de localización**: identificador del texto, resuelto en presentación. Clave: mantiene el grafo idéntico en todos los idiomas.
- **Intérprete (runner)**: objeto que recorre el grafo, evalúa condiciones y expone el estado actual. Clave: no dibuja nada.
- **Nodo terminal**: nodo sin salidas que cierra la conversación. Clave: todo camino debe llegar a uno.
- **Nodo huérfano**: nodo al que no llega ningún enlace. Clave: contenido escrito que nadie verá jamás.
- **Salto roto**: enlace a un id que no existe. Clave: deja la conversación colgada en runtime.
- **Callejón sin salida**: nodo no terminal sin salidas válidas. Clave: el jugador se queda encerrado sin poder cerrar el diálogo.

## 🧰 Herramientas y preparación

Necesitas el inventario (295) para condiciones de objetos y, opcionalmente, la progresión (302). Trabajaremos en `res://dominio/dialogo/` y `res://datos/dialogos/*.json`. Para la localización, revisa la [documentación de internacionalización de Godot](https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html) y el lab de UI accesible de la Parte 10, que ya usa CSV de traducciones.

## 🧪 Laboratorio guiado

1. **El formato.** Legible, diffeable y suficientemente expresivo:

```json
{
  "id": "herrero_intro",
  "inicio": "saludo",
  "nodos": {
    "saludo": {
      "tipo": "linea",
      "hablante": "herrero",
      "texto": "dlg.herrero.saludo",
      "siguiente": "menu"
    },
    "menu": {
      "tipo": "eleccion",
      "opciones": [
        { "texto": "dlg.herrero.op_trabajo", "destino": "trabajo",
          "condicion": { "flag_no": "herrero_contratado" } },
        { "texto": "dlg.herrero.op_espada", "destino": "espada",
          "condicion": { "tiene_item": "mineral_hierro", "cantidad": 3 } },
        { "texto": "dlg.herrero.op_secreto", "destino": "secreto",
          "condicion": { "reputacion_min": { "faccion": "gremio", "valor": 50 } },
          "una_vez": true },
        { "texto": "dlg.comun.adios", "destino": "fin" }
      ]
    },
    "trabajo": {
      "tipo": "linea", "hablante": "herrero", "texto": "dlg.herrero.trabajo",
      "efectos": [{ "tipo": "flag", "clave": "herrero_contratado", "valor": true }],
      "siguiente": "menu"
    },
    "espada": {
      "tipo": "linea", "hablante": "herrero", "texto": "dlg.herrero.espada",
      "efectos": [
        { "tipo": "quitar_item", "item": "mineral_hierro", "cantidad": 3 },
        { "tipo": "dar_item", "item": "espada_hierro", "cantidad": 1 }
      ],
      "siguiente": "menu"
    },
    "secreto": { "tipo": "linea", "hablante": "herrero", "texto": "dlg.herrero.secreto",
      "efectos": [{ "tipo": "iniciar_quest", "quest": "forja_perdida" }],
      "siguiente": "fin" },
    "fin": { "tipo": "fin" }
  }
}
```

2. **El blackboard.** Sencillo a propósito:

```gdscript
class_name Blackboard
extends RefCounted

signal cambio(clave: StringName, valor: Variant)

var _vars := {}
var _opciones_usadas := {}          # "dialogo:nodo:indice" -> true

func set_var(clave: StringName, valor: Variant) -> void:
	_vars[clave] = valor
	cambio.emit(clave, valor)

func get_var(clave: StringName, por_defecto: Variant = null) -> Variant:
	return _vars.get(clave, por_defecto)

func flag(clave: StringName) -> bool:
	return bool(_vars.get(clave, false))

func incrementar(clave: StringName, n := 1) -> void:
	set_var(clave, int(_vars.get(clave, 0)) + n)

func marcar_opcion(clave: String) -> void:
	_opciones_usadas[clave] = true

func opcion_usada(clave: String) -> bool:
	return _opciones_usadas.has(clave)

func a_dict() -> Dictionary:
	return {"vars": _vars, "opciones": _opciones_usadas.keys()}

func de_dict(d: Dictionary) -> void:
	_vars = d.get("vars", {}).duplicate()
	_opciones_usadas.clear()
	for k in d.get("opciones", []):
		_opciones_usadas[str(k)] = true
```

3. **El evaluador de condiciones.** Declarativo: una lista cerrada de comprobaciones, no un `eval()`.

```gdscript
class_name Condiciones
extends RefCounted

var bb: Blackboard
var inv: Inventario
var consultas := {}      # StringName -> Callable, para quests/reputación (clases 305-306)

func evaluar(c: Dictionary) -> bool:
	if c.is_empty():
		return true
	# Todas las claves presentes deben cumplirse (AND implícito).
	if c.has("flag") and not bb.flag(StringName(str(c["flag"]))):
		return false
	if c.has("flag_no") and bb.flag(StringName(str(c["flag_no"]))):
		return false
	if c.has("tiene_item"):
		if inv == null or inv.contar(StringName(str(c["tiene_item"]))) < int(c.get("cantidad", 1)):
			return false
	if c.has("var_min"):
		var d: Dictionary = c["var_min"]
		if int(bb.get_var(StringName(str(d["clave"])), 0)) < int(d["valor"]):
			return false
	for clave in ["quest_activa", "quest_completada", "reputacion_min"]:
		if c.has(clave):
			# Delegamos en quien sepa: así el diálogo no depende de quests ni facciones.
			var f: Callable = consultas.get(StringName(clave), Callable())
			if not f.is_valid() or not bool(f.call(c[clave])):
				return false
	if c.has("cualquiera"):
		var alguna := false
		for sub in c["cualquiera"]:
			alguna = alguna or evaluar(sub)
		if not alguna:
			return false
	return true
```

4. **El despachador de efectos.** Igual de cerrado, y por la misma razón:

```gdscript
class_name Efectos_Dialogo
extends RefCounted

signal efecto_desconocido(tipo: String)

var bb: Blackboard
var acciones := {}       # "dar_item" -> Callable(Dictionary)

func aplicar(lista: Array) -> void:
	for e in lista:
		var tipo := str(e.get("tipo", ""))
		match tipo:
			"flag":
				bb.set_var(StringName(str(e["clave"])), e.get("valor", true))
			"incrementar":
				bb.incrementar(StringName(str(e["clave"])), int(e.get("valor", 1)))
			_:
				# Todo lo demás (items, quests, reputación) lo resuelve quien sabe.
				var f: Callable = acciones.get(tipo, Callable())
				if f.is_valid():
					f.call(e)
				else:
					efecto_desconocido.emit(tipo)
```

Un efecto desconocido **avisa** en vez de fallar en silencio: es la diferencia entre un guion que se detecta roto en CI y un NPC que no da la recompensa prometida.

5. **El intérprete.** Estado explícito y avance controlado desde fuera:

```gdscript
class_name Dialogo
extends RefCounted

signal linea(hablante: String, clave_texto: String)
signal opciones(lista: Array)          # [{indice, clave_texto, bloqueada}]
signal terminado(id: StringName)

var _grafo := {}
var _id: StringName
var _actual: StringName = &""
var _cond: Condiciones
var _fx: Efectos_Dialogo
var _bb: Blackboard

func _init(cond: Condiciones, fx: Efectos_Dialogo, bb: Blackboard) -> void:
	_cond = cond; _fx = fx; _bb = bb

func cargar(ruta: String) -> Array[String]:
	var d = JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return ["diálogo ilegible: " + ruta]
	_id = StringName(str(d.get("id", "")))
	_grafo = d.get("nodos", {})
	_actual = StringName(str(d.get("inicio", "")))
	return Validador_Dialogo.validar(_id, _grafo, StringName(str(d.get("inicio", ""))))

func empezar() -> void:
	_entrar(_actual)

func nodo_actual() -> StringName:
	return _actual

func _entrar(id: StringName) -> void:
	_actual = id
	if not _grafo.has(id):
		push_error("nodo de diálogo inexistente: %s" % id)
		terminado.emit(_id)
		return
	var n: Dictionary = _grafo[id]
	_bb.incrementar(StringName("visto:%s:%s" % [_id, id]))
	_fx.aplicar(n.get("efectos", []))

	match str(n.get("tipo", "linea")):
		"fin":
			terminado.emit(_id)
		"eleccion":
			opciones.emit(_opciones_visibles(n))
		_:
			linea.emit(str(n.get("hablante", "")), str(n.get("texto", "")))

func avanzar() -> void:
	"""Para nodos de línea: pasa al siguiente cuando el jugador pulsa."""
	var n: Dictionary = _grafo.get(_actual, {})
	if str(n.get("tipo", "linea")) != "linea":
		return
	_entrar(StringName(str(n.get("siguiente", ""))))

func elegir(indice: int) -> bool:
	var n: Dictionary = _grafo.get(_actual, {})
	var visibles := _opciones_visibles(n)
	var elegida := visibles.filter(func(o): return o["indice"] == indice)
	if elegida.is_empty() or elegida[0]["bloqueada"]:
		return false
	var op: Dictionary = n["opciones"][indice]
	if bool(op.get("una_vez", false)):
		_bb.marcar_opcion("%s:%s:%d" % [_id, _actual, indice])
	_fx.aplicar(op.get("efectos", []))
	_entrar(StringName(str(op.get("destino", ""))))
	return true

func _opciones_visibles(n: Dictionary) -> Array:
	var salida := []
	var lista: Array = n.get("opciones", [])
	for i in lista.size():
		var op: Dictionary = lista[i]
		if bool(op.get("una_vez", false)) and _bb.opcion_usada("%s:%s:%d" % [_id, _actual, i]):
			continue
		var cumple := _cond.evaluar(op.get("condicion", {}))
		# 'oculta_si_no_cumple' distingue "no aparece" de "aparece en gris":
		# enseñar la opción bloqueada es una herramienta narrativa potente.
		if not cumple and bool(op.get("ocultar", true)):
			continue
		salida.append({"indice": i, "clave_texto": str(op.get("texto", "")), "bloqueada": not cumple})
	return salida
```

6. **El validador.** El paso que evita el bug más embarazoso: un jugador atrapado en una conversación.

```gdscript
class_name Validador_Dialogo
extends RefCounted

static func validar(id: StringName, grafo: Dictionary, inicio: StringName) -> Array[String]:
	var errores: Array[String] = []
	if not grafo.has(inicio):
		errores.append("%s: el nodo inicial '%s' no existe" % [id, inicio])
		return errores

	var alcanzables := {}
	var pila := [inicio]
	while not pila.is_empty():
		var actual: StringName = pila.pop_back()
		if alcanzables.has(actual):
			continue
		alcanzables[actual] = true
		var n: Dictionary = grafo.get(actual, {})
		var destinos: Array[StringName] = []
		if n.has("siguiente"):
			destinos.append(StringName(str(n["siguiente"])))
		for op in n.get("opciones", []):
			destinos.append(StringName(str(op.get("destino", ""))))
		for d in destinos:
			if not grafo.has(d):
				errores.append("%s/%s: salto roto a '%s'" % [id, actual, d])
			else:
				pila.append(d)
		# Callejón sin salida: ni es 'fin' ni lleva a ningún sitio.
		if str(n.get("tipo", "linea")) != "fin" and destinos.is_empty():
			errores.append("%s/%s: callejón sin salida (ni 'fin' ni salidas)" % [id, actual])

	for nodo in grafo:
		if not alcanzables.has(StringName(str(nodo))):
			errores.append("%s: nodo huérfano '%s' (nadie llega a él)" % [id, nodo])
	return errores
```

7. **Probarlo.** Sin UI, sin escena, sin NPC:

```gdscript
extends SceneTree

func _init() -> void:
	var bb := Blackboard.new()
	var base := BaseDeItems.new(); base.cargar_desde_json("res://datos/items.json")
	var inv := Inventario.new(base, 10)
	var cond := Condiciones.new(); cond.bb = bb; cond.inv = inv
	var fx := Efectos_Dialogo.new(); fx.bb = bb
	fx.acciones["dar_item"] = func(e): inv.agregar(StringName(str(e["item"])), int(e.get("cantidad", 1)))
	fx.acciones["quitar_item"] = func(e): inv.quitar(StringName(str(e["item"])), int(e.get("cantidad", 1)))

	var dlg := Dialogo.new(cond, fx, bb)
	assert(dlg.cargar("res://datos/dialogos/herrero_intro.json").is_empty(), "el grafo no valida")

	var ops := []
	dlg.opciones.connect(func(l): ops = l)
	dlg.empezar()
	dlg.avanzar()                       # saludo → menu

	# Sin mineral, la opción de la espada no aparece.
	assert(ops.filter(func(o): return o["indice"] == 1).is_empty(), "opción visible sin cumplir condición")

	inv.agregar(&"mineral_hierro", 3)
	dlg.elegir(0)                       # contratar
	dlg.avanzar()                       # vuelve al menú
	assert(bb.flag(&"herrero_contratado"), "el efecto de flag no se aplicó")
	# Ya contratado: la opción 0 (que exigía flag_no) desaparece...
	assert(ops.filter(func(o): return o["indice"] == 0).is_empty(), "la opción de contratar sigue visible")
	# ...y la 1 aparece, porque ahora sí hay mineral.
	assert(not ops.filter(func(o): return o["indice"] == 1).is_empty(), "la opción de la espada debería aparecer")

	dlg.elegir(1)
	assert(inv.contar(&"espada_hierro") == 1 and inv.contar(&"mineral_hierro") == 0)

	print("== 6 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Añade un tipo de nodo `aleatorio` que elija salida por peso usando el RNG inyectado de la clase 300.
2. Implementa un nodo `condicional` que salte a un destino u otro sin mostrar texto.
3. Añade retrato, emoción y velocidad de texto por nodo, y respétalos en la presentación.
4. Implementa un historial de conversación consultable ("registro de diálogo").
5. Exporta todas las claves de texto a un CSV listo para traducir y comprueba que ninguna falta.
6. Añade un modo depuración que imprima la ruta recorrida por el grafo.
7. Genera un diagrama Graphviz del grafo marcando los nodos huérfanos en rojo.

## 📝 Reto verificable

Implementa el sistema completo y escribe una conversación de **al menos 15 nodos** con tres ramas condicionales, una opción agotable, una opción visible pero bloqueada, efectos sobre inventario y variables, y localización por claves.

**Criterio de aceptación**: (a) `godot --headless --script res://herramientas/validar_dialogos.gd` valida todos los diálogos y devuelve 0; (b) al introducir a propósito un salto roto, un nodo huérfano y un callejón sin salida, el validador los detecta **los tres** con su id; (c) una prueba con al menos 15 aserciones recorre las tres ramas y comprueba que las condiciones ocultan/bloquean las opciones correctas; (d) la opción `una_vez` desaparece tras usarse y sigue desaparecida tras `a_dict()` → `de_dict()` del blackboard; (e) el sistema no contiene ninguna llamada a `eval` ni ejecuta código venido del JSON.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El jugador se queda atrapado en un diálogo | Callejón sin salida o salto roto. El validador los detecta antes de publicar. |
| Una rama escrita nunca se ve | Nodo huérfano o condición imposible. Comprueba alcanzabilidad y revisa la condición. |
| Al recargar la partida el NPC repite lo ya dicho | El blackboard no se guarda. Es estado del jugador: va al save. |
| Un efecto prometido no ocurre | Tipo de efecto no registrado en el despachador. Emite `efecto_desconocido` y falla en CI. |
| Traducir obliga a duplicar el grafo | Se escribió el texto dentro del JSON. Usa claves y resuélvelas en presentación. |
| Las opciones cambian de sitio al cumplirse una condición | La UI usa el índice de la lista visible. Usa el índice original del nodo. |
| "Invalid call. Nonexistent function 'call'" en efectos | Se guardó una `Callable` inválida en el diccionario. Comprueba `is_valid()`. |
| Añadir una condición nueva obliga a tocar diez sitios | La evaluación está repartida. Centraliza en `Condiciones.evaluar`. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué no permitir expresiones o código en el JSON?** Porque abre la puerta a ejecutar cualquier cosa desde un archivo de contenido —que puede venir de un mod— y porque un intérprete de expresiones es un lenguaje que tendrás que documentar, depurar y versionar. Una lista cerrada de condiciones cubre el 95 % de los casos y es segura por construcción ([clase 309](../309-modding-y-arquitectura-extensible/README.md)).

**❓ ¿Uso una herramienta externa (Yarn, Ink, Twine)?** Son excelentes y muy usadas en producción. Esta clase te enseña **el modelo** para que sepas qué hacen por dentro, puedas evaluar cuál encaja y puedas escribir el intérprete si tu juego tiene requisitos que ninguna cubre. En cualquier caso, exportarás a un grafo muy parecido a este.

**❓ ¿El diálogo debe conocer las quests?** No directamente. Le pasas `Callable` de consulta y de acción, así el sistema de diálogo funciona igual con o sin sistema de quests, y ambos se prueban por separado. Ese es el patrón de inyección de la [clase 293](../293-arquitectura-de-gameplay-a-escala/README.md).

**❓ ¿Cuándo mostrar una opción bloqueada en gris y cuándo ocultarla?** Bloqueada en gris cuando quieres **enseñar** al jugador que existe un camino (necesita 3 minerales, necesita reputación). Oculta cuando revelarla estropearía la sorpresa o revelaría contenido que aún no debe conocer. Es una decisión narrativa y por eso está en el dato (`ocultar`).

**❓ ¿Y el diálogo generado por IA?** El grafo sigue mandando: un NPC con LLM puede rellenar el **texto** de un nodo, pero las condiciones, los efectos y las transiciones deben seguir pasando por este intérprete y su validación. Es exactamente la arquitectura de la [clase 333](../../parte-20-ia-generativa-y-desarrollo-asistido-por-ia/333-dialogo-quests-y-contenido-generativo/README.md).

## 🔗 Referencias

- Godot Docs — Internacionalización de juegos: <https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html>
- Godot Docs — `JSON` y `Callable`: <https://docs.godotengine.org/en/stable/classes/class_callable.html>
- Yarn Spinner — herramienta de diálogo de referencia en la industria: <https://www.yarnspinner.dev/>
- Inkle — Ink, lenguaje de narrativa ramificada: <https://www.inklestudios.com/ink/>
- GDC Vault — charlas sobre herramientas narrativas y diálogo ramificado: <https://www.gdcvault.com/>

## ⬅️ Clase anterior

[Clase 303 - Economía interna implementada](../303-economia-interna-implementada/README.md)

## ➡️ Siguiente clase

[Clase 305 - Quest System](../305-quest-system/README.md)
