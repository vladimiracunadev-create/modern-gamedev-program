# Clase 301 — Crafting y recetas

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Nystrom, «Game Programming Patterns» (Type Object) · Charlas de GDC sobre sistemas de crafteo y economías de materiales*
> ⏱️ Duración estimada: **110 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Implementar el sistema de **crafteo**: recetas definidas como datos, con ingredientes, cantidades, requisitos, estaciones, resultados y mejoras. Es el sistema que convierte los materiales que suelta el loot en objetos útiles, y por tanto el que cierra el círculo de la economía: sin él, los materiales son basura que ocupa inventario.

La trampa aquí es la misma de siempre —hardcodear— pero con una vuelta de tuerca: el crafteo **toca dos sistemas a la vez** (quita ingredientes y añade resultado), así que es donde más objetos se pierden si la operación no es atómica. Vas a apoyarte en las transacciones del inventario de la [clase 295](../295-sistema-de-inventario/README.md) para que craftear sea todo-o-nada, y a validar el recetario en CI para que una receta imposible no llegue nunca a una partida.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Modelar una receta como dato con ingredientes, requisitos, estación y resultados.
2. Implementar `puede_craftear` como consulta pura y `craftear` como transacción atómica.
3. Distinguir ingredientes **consumidos** de **catalizadores** (requeridos pero no gastados).
4. Implementar estaciones de crafteo y niveles de habilidad como requisitos.
5. Implementar mejora (upgrade) de items conservando su identidad y su estado.
6. Validar el recetario: ciclos, ingredientes inexistentes, recetas inalcanzables.
7. Calcular el coste real de una receta recorriendo su árbol de dependencias.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Receta como dato | Diseño puede añadir recetas sin tocar código. |
| 2 | Ingredientes y catalizadores | La diferencia entre gastar madera y necesitar un martillo. |
| 3 | Atomicidad | Craftear toca dos operaciones: sin transacción, se pierden materiales. |
| 4 | Requisitos | Nivel, receta aprendida, estación: puertas de progresión. |
| 5 | Estaciones | Ancla el crafteo al mundo y da sentido a la exploración. |
| 6 | Resultados múltiples | Subproductos y cantidades variables. |
| 7 | Mejora de items | Upgrade conserva la identidad; craftear crea una nueva. |
| 8 | Descubrimiento de recetas | Aprendidas, encontradas o deducidas: es diseño, y es dato. |
| 9 | Árbol de coste | Saber cuánta madera cuesta *de verdad* una espada de acero. |
| 10 | Validación del recetario | Un ciclo de recetas es contenido roto que no da error en runtime. |

## 📖 Definiciones y características

- **Receta (recipe)**: dato que describe cómo obtener uno o varios items a partir de otros. Clave: es contenido validable, no una función.
- **Ingrediente**: item consumido por la receta, con cantidad. Clave: se descuenta solo si la receta tiene éxito completo.
- **Catalizador (herramienta)**: item que debe estar presente pero **no** se consume. Clave: modela martillos, moldes y llaves sin gastarlos.
- **Resultado (output)**: item o items producidos, con cantidad fija o variable. Clave: puede incluir subproductos y devoluciones.
- **Estación de crafteo**: lugar u objeto del mundo que habilita ciertas recetas. Clave: es un requisito de contexto, no del inventario.
- **Requisito**: condición previa (nivel, habilidad, receta aprendida, facción). Clave: se comprueba antes de tocar nada.
- **Recetario**: colección de recetas indexada por id, con las que el jugador conoce marcadas aparte. Clave: conocer una receta es estado del jugador; la receta es contenido.
- **Crafteo atómico**: operación que consume ingredientes y entrega resultado o no hace nada. Clave: usa la transacción del inventario.
- **Upgrade (mejora)**: receta que transforma un item conservando su instancia y su estado. Clave: diferencia clave frente a "destruir y crear".
- **Árbol de dependencias**: grafo de recetas necesarias para obtener un item desde materiales base. Clave: da el coste real y detecta ciclos.
- **Coste efectivo**: cantidad de materiales base equivalente a un item crafteado. Clave: es la cifra que conecta el crafteo con la economía.
- **Receta inalcanzable**: aquella cuyos ingredientes no puede obtener el jugador. Clave: se detecta cruzando recetario, loot y tiendas.
- **Ciclo de recetas**: A se craftea con B y B con A. Clave: contenido roto que no falla en runtime, solo desconcierta.
- **Rendimiento (yield)**: cantidad de resultado por ejecución, a veces aleatoria. Clave: si es aleatorio, usa el RNG inyectado de la clase 300.
- **Devolución (refund)**: parte de los ingredientes recuperada al desmontar. Clave: es un sink parcial y afecta al balance.

## 🧰 Herramientas y preparación

Necesitas el catálogo (294), el inventario con transacciones (295) y, para el análisis, el RNG inyectado de la clase 300. Trabajaremos en `res://dominio/crafteo/` y `res://datos/recetas.json`. Añade al catálogo materiales base (`madera`, `hierro`, `cuero`) e intermedios (`lingote_hierro`, `empuñadura`) para poder construir un árbol de dos niveles.

## 🧪 Laboratorio guiado

1. **El formato de receta:**

```json
{
  "version": 1,
  "recetas": [
    {
      "id": "lingote_hierro",
      "estacion": "fragua",
      "requisitos": { "nivel_min": 1 },
      "ingredientes": [{ "item": "mineral_hierro", "cantidad": 2 }],
      "catalizadores": [],
      "resultados": [{ "item": "lingote_hierro", "cantidad": 1 }],
      "tiempo": 3.0
    },
    {
      "id": "espada_hierro",
      "estacion": "fragua",
      "requisitos": { "nivel_min": 3, "requiere_aprendida": true },
      "ingredientes": [
        { "item": "lingote_hierro", "cantidad": 3 },
        { "item": "empunadura", "cantidad": 1 }
      ],
      "catalizadores": [{ "item": "martillo_herrero" }],
      "resultados": [{ "item": "espada_hierro", "cantidad": 1 }],
      "tiempo": 8.0
    },
    {
      "id": "mejorar_espada_hierro",
      "tipo": "upgrade",
      "estacion": "fragua",
      "objetivo": "espada_hierro",
      "ingredientes": [{ "item": "lingote_hierro", "cantidad": 2 }],
      "resultados": [{ "item": "espada_hierro_plus", "cantidad": 1 }]
    }
  ]
}
```

2. **La receta en código:**

```gdscript
class_name Receta
extends RefCounted

var id: StringName
var tipo: String = "craft"            # "craft" | "upgrade"
var estacion: StringName = &""        # "" = se puede hacer a mano
var objetivo: StringName = &""        # solo en upgrades
var nivel_min: int = 0
var requiere_aprendida := false
var ingredientes: Array[Dictionary] = []
var catalizadores: Array[Dictionary] = []
var resultados: Array[Dictionary] = []
var tiempo: float = 0.0

static func de_dict(d: Dictionary) -> Receta:
	var r := Receta.new()
	r.id = StringName(str(d.get("id", "")))
	r.tipo = str(d.get("tipo", "craft"))
	r.estacion = StringName(str(d.get("estacion", "")))
	r.objetivo = StringName(str(d.get("objetivo", "")))
	var req: Dictionary = d.get("requisitos", {})
	r.nivel_min = int(req.get("nivel_min", 0))
	r.requiere_aprendida = bool(req.get("requiere_aprendida", false))
	r.ingredientes = d.get("ingredientes", []) as Array[Dictionary]
	r.catalizadores = d.get("catalizadores", []) as Array[Dictionary]
	r.resultados = d.get("resultados", []) as Array[Dictionary]
	r.tiempo = float(d.get("tiempo", 0.0))
	return r
```

3. **El motivo de fallo, otra vez.** Igual que en habilidades: la UI necesita explicar, no solo bloquear.

```gdscript
class_name FalloCrafteo
extends RefCounted

enum Motivo {
	OK, RECETA_DESCONOCIDA, NO_APRENDIDA, NIVEL_INSUFICIENTE,
	SIN_ESTACION, FALTAN_INGREDIENTES, FALTA_CATALIZADOR,
	SIN_ESPACIO, OBJETIVO_AUSENTE,
}
```

4. **El sistema.** Consulta pura primero, transacción después:

```gdscript
class_name Crafteo
extends RefCounted

signal crafteado(receta: StringName, resultados: Array)
signal fallo_crafteo(receta: StringName, motivo: int)

var _base: BaseDeItems
var _recetas := {}
var _aprendidas := {}        # StringName -> true (ESTADO del jugador: va al save)

func _init(base: BaseDeItems) -> void:
	_base = base

func cargar(ruta: String) -> Array[String]:
	var datos = JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())
	if typeof(datos) != TYPE_DICTIONARY:
		return ["recetas.json ilegible"]
	for d in datos.get("recetas", []):
		var r := Receta.de_dict(d)
		_recetas[r.id] = r
	return []

func aprender(id: StringName) -> void:
	_aprendidas[id] = true

func conoce(id: StringName) -> bool:
	return _aprendidas.has(id)

func puede_craftear(id: StringName, inv: Inventario, ctx: Dictionary) -> FalloCrafteo.Motivo:
	if not _recetas.has(id):
		return FalloCrafteo.Motivo.RECETA_DESCONOCIDA
	var r: Receta = _recetas[id]

	if r.requiere_aprendida and not conoce(id):
		return FalloCrafteo.Motivo.NO_APRENDIDA
	if int(ctx.get("nivel", 0)) < r.nivel_min:
		return FalloCrafteo.Motivo.NIVEL_INSUFICIENTE
	if r.estacion != &"" and StringName(str(ctx.get("estacion", ""))) != r.estacion:
		return FalloCrafteo.Motivo.SIN_ESTACION
	if r.tipo == "upgrade" and inv.contar(r.objetivo) < 1:
		return FalloCrafteo.Motivo.OBJETIVO_AUSENTE

	for c in r.catalizadores:
		if inv.contar(StringName(str(c["item"]))) < int(c.get("cantidad", 1)):
			return FalloCrafteo.Motivo.FALTA_CATALIZADOR
	for i in r.ingredientes:
		if inv.contar(StringName(str(i["item"]))) < int(i.get("cantidad", 1)):
			return FalloCrafteo.Motivo.FALTAN_INGREDIENTES

	# El hueco se comprueba ANTES de consumir: si no, el jugador se queda sin
	# materiales y sin espada.
	for res in r.resultados:
		if inv.cabe(StringName(str(res["item"])), int(res.get("cantidad", 1))) < int(res.get("cantidad", 1)):
			return FalloCrafteo.Motivo.SIN_ESPACIO
	return FalloCrafteo.Motivo.OK
```

5. **Craftear, de forma atómica.** La transacción del inventario hace el trabajo sucio:

```gdscript
func craftear(id: StringName, inv: Inventario, ctx: Dictionary) -> FalloCrafteo.Motivo:
	var motivo := puede_craftear(id, inv, ctx)
	if motivo != FalloCrafteo.Motivo.OK:
		fallo_crafteo.emit(id, motivo)
		return motivo

	var r: Receta = _recetas[id]
	var ops: Array[Callable] = []

	if r.tipo == "upgrade":
		ops.append(func(): return inv.quitar(r.objetivo, 1))
	for i in r.ingredientes:
		var item := StringName(str(i["item"]))
		var n := int(i.get("cantidad", 1))
		ops.append(func(): return inv.quitar(item, n))
	for res in r.resultados:
		var item := StringName(str(res["item"]))
		var n := int(res.get("cantidad", 1))
		ops.append(func(): return inv.agregar_todo_o_nada(item, n))

	# Si CUALQUIER paso falla, el inventario vuelve exactamente a como estaba.
	if not inv.transaccion(ops):
		fallo_crafteo.emit(id, FalloCrafteo.Motivo.SIN_ESPACIO)
		return FalloCrafteo.Motivo.SIN_ESPACIO

	crafteado.emit(id, r.resultados)
	return FalloCrafteo.Motivo.OK
```

Fíjate en que los catalizadores **no aparecen** en `ops`: se comprueban y no se tocan. Ese es todo el mecanismo.

6. **El árbol de coste.** Lo que de verdad cuesta una espada:

```gdscript
func coste_base(id_item: StringName, visitados: Dictionary = {}) -> Dictionary:
	"""Materiales base equivalentes. Detecta ciclos por el camino."""
	if visitados.has(id_item):
		push_error("ciclo de recetas detectado en '%s'" % id_item)
		return {}
	visitados[id_item] = true

	var receta := _receta_que_produce(id_item)
	if receta == null:
		return {id_item: 1}          # material base: no se craftea, se obtiene

	var total := {}
	for i in receta.ingredientes:
		var sub := coste_base(StringName(str(i["item"])), visitados.duplicate())
		for clave in sub:
			total[clave] = total.get(clave, 0) + sub[clave] * int(i.get("cantidad", 1))
	return total

func _receta_que_produce(id_item: StringName) -> Receta:
	for r in _recetas.values():
		for res in r.resultados:
			if StringName(str(res["item"])) == id_item:
				return r
	return null
```

Con el recetario del paso 1, `coste_base("espada_hierro")` devuelve `{mineral_hierro: 6, empunadura: 1}` — y ahora sí puedes decidir cuánto debe valer en la tienda.

7. **Validar el recetario:**

```gdscript
static func validar(sistema: Crafteo, base: BaseDeItems) -> Array[String]:
	var errores: Array[String] = []
	for r in sistema._recetas.values():
		var donde := "receta '%s'" % r.id
		if r.resultados.is_empty():
			errores.append("%s: sin resultados" % donde)
		if r.tipo == "upgrade" and not base.existe(r.objetivo):
			errores.append("%s: objetivo inexistente '%s'" % [donde, r.objetivo])
		for lista in [r.ingredientes, r.catalizadores, r.resultados]:
			for e in lista:
				if not base.existe(StringName(str(e.get("item", "")))):
					errores.append("%s: item inexistente '%s'" % [donde, e.get("item", "")])
				if int(e.get("cantidad", 1)) < 1:
					errores.append("%s: cantidad < 1" % donde)
		# Una receta que se consume a sí misma es un ciclo trivial.
		for i in r.ingredientes:
			for res in r.resultados:
				if str(i["item"]) == str(res["item"]):
					errores.append("%s: se consume y produce el mismo item" % donde)
	for r in sistema._recetas.values():
		for res in r.resultados:
			sistema.coste_base(StringName(str(res["item"])))   # detecta ciclos profundos
	return errores
```

8. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	var base := BaseDeItems.new(); base.cargar_desde_json("res://datos/items.json")
	var inv := Inventario.new(base, 20)
	var craft := Crafteo.new(base); craft.cargar("res://datos/recetas.json")
	var ctx := {"nivel": 5, "estacion": "fragua"}

	inv.agregar(&"mineral_hierro", 6)
	assert(craft.craftear(&"lingote_hierro", inv, ctx) == FalloCrafteo.Motivo.OK)
	assert(inv.contar(&"mineral_hierro") == 4 and inv.contar(&"lingote_hierro") == 1)

	# Sin estación: no se puede, y no se toca nada.
	var antes := inv.a_dict()
	assert(craft.craftear(&"lingote_hierro", inv, {"nivel": 5}) == FalloCrafteo.Motivo.SIN_ESTACION)
	assert(inv.a_dict() == antes, "un crafteo fallido ha mutado el inventario")

	# Catalizador: se exige y NO se consume.
	inv.agregar(&"lingote_hierro", 3); inv.agregar(&"empunadura", 1)
	inv.agregar(&"martillo_herrero", 1)
	craft.aprender(&"espada_hierro")
	assert(craft.craftear(&"espada_hierro", inv, ctx) == FalloCrafteo.Motivo.OK)
	assert(inv.contar(&"martillo_herrero") == 1, "el catalizador se ha consumido")

	print("== 6 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Añade `tiempo` real: el crafteo tarda y se puede cancelar devolviendo los materiales.
2. Implementa crafteo por lotes (`craftear(id, n)`) que sea atómico para las `n` unidades.
3. Añade rendimiento aleatorio con el RNG inyectado y comprueba el determinismo con semilla fija.
4. Implementa desmontar con devolución del 50 % redondeando hacia abajo.
5. Añade descubrimiento: combinar dos ingredientes desconocidos revela la receta si existe.
6. Genera un informe de recetas cuyos ingredientes no caen en ninguna tabla de loot ni se venden.
7. Implementa calidad del resultado en función de una estadística de artesanía.

## 📝 Reto verificable

Implementa el sistema de crafteo con **al menos ocho recetas** en tres niveles de profundidad (material base → intermedio → final), catalizadores, estaciones, requisitos de nivel y receta aprendida, una receta de upgrade, y el análisis de coste base.

**Criterio de aceptación**: una prueba headless con **al menos 16 aserciones** demuestra que: (a) cada uno de los ocho motivos de fallo se puede provocar y se devuelve el correcto; (b) tras cualquier crafteo fallido, `inv.a_dict()` es idéntico al de antes; (c) los catalizadores nunca se consumen; (d) `coste_base` del item final devuelve exactamente la cantidad de materiales base calculada a mano; (e) el validador detecta un ingrediente inexistente, una cantidad 0 y un ciclo introducido a propósito; (f) craftear con el inventario lleno devuelve `SIN_ESPACIO` **sin** consumir ingredientes.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El jugador pierde materiales y no recibe el item | Se consumió antes de comprobar el hueco. Usa `cabe()` primero y transacción después. |
| El martillo desaparece al forjar | Los catalizadores se metieron en la lista de ingredientes. Sepáralos. |
| Una receta se puede hacer sin estar en la fragua | El requisito solo estaba en la UI. Muévelo a `puede_craftear`. |
| El juego se cuelga al abrir el recetario | Ciclo de recetas en `coste_base`. Añade el conjunto de visitados y valida en CI. |
| Craftear por lotes deja las cuentas mal | Cada unidad se procesó por separado sin transacción global. Envuelve el lote entero. |
| Los precios de tienda no tienen sentido | Se fijaron a ojo sin mirar el coste base. Calcula el árbol y deriva el precio. |
| Recetas que nadie puede completar | Ingredientes que no caen en ninguna tabla. Cruza recetario con loot en un informe. |
| Al mejorar un item se pierden sus encantamientos | El upgrade destruye y crea. Si el item tiene estado, transfórmalo conservando la instancia. |

## ❓ Preguntas frecuentes

**❓ ¿Upgrade o craftear un item nuevo?** Si el item tiene estado propio (encantamientos, durabilidad, nombre puesto por el jugador), **upgrade**: modifica la instancia. Si es un item plano sin estado, destruir y crear es más simple y equivalente.

**❓ ¿Dónde guardo qué recetas conoce el jugador?** En el save del jugador, no en el recetario. El recetario es **contenido** (viene con el juego y se parchea); las recetas conocidas son **estado** (van al guardado con su migración).

**❓ ¿El crafteo debe consumir tiempo real?** Es una decisión de diseño con implicaciones fuertes: el tiempo convierte el crafteo en una decisión de planificación (y es la base de muchos modelos de monetización, ver Parte 16). Técnicamente solo añade una fase, como en el sistema de habilidades.

**❓ ¿Cómo evito que el crafteo rompa la economía?** Calculando el coste base y comparándolo con el valor del resultado y con lo que cuesta comprarlo. Si craftear es más barato que comprar y vender el resultado da beneficio, has creado una máquina de dinero. Esto se analiza en la [clase 303](../303-economia-interna-implementada/README.md).

**❓ ¿Y si es multijugador?** El crafteo autoritativo va en el servidor con clave de idempotencia: si el cliente reintenta por un timeout, no debe craftear dos veces. Es exactamente el patrón de la [clase 314](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/314-economia-transaccional-de-servidor/README.md).

## 🔗 Referencias

- Robert Nystrom — *Game Programming Patterns*, Type Object: <https://gameprogrammingpatterns.com/type-object.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `JSON` y carga de datos: <https://docs.godotengine.org/en/4.3/classes/class_json.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `Callable` (las operaciones de la transacción): <https://docs.godotengine.org/en/4.3/classes/class_callable.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- GDC Vault — charlas sobre economías de materiales y sistemas de crafteo: <https://www.gdcvault.com/> — catálogo por tema, no una charla identificada (ponente y año pendientes) · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Jason Gregory — *Game Engine Architecture*: <https://www.gameenginebook.com/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 300 - Loot tables y sistemas de recompensas](../300-loot-tables-y-sistemas-de-recompensas/README.md)

## ➡️ Siguiente clase

[Clase 302 - Progresión y skill trees](../302-progresion-y-skill-trees/README.md)
