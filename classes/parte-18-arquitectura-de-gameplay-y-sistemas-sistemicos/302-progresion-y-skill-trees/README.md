# Clase 302 — Progresión y skill trees

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Schell, «The Art of Game Design» (curvas de interés y progresión) · Charlas de GDC sobre diseño de progresión*
> ⏱️ Duración estimada: **115 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Implementar la **progresión**: experiencia, niveles, puntos de habilidad, desbloqueos, árboles con prerrequisitos, respec y metaprogresión. Es el sistema que decide cuánto tiempo dura tu juego y cuándo el jugador se siente más fuerte, y es también donde más se nota una decisión arquitectónica que aquí vamos a tomar de forma explícita: **separar el progreso persistente del estado de partida**.

Esa separación es la que permite que un roguelike pierda todo al morir pero conserve las mejoras permanentes, que un RPG guarde tu nivel pero no tu posición en la mazmorra, y que un parche pueda recalcular las bonificaciones sin corromper la partida. Construirás una curva de XP parametrizable, un árbol de habilidades data-driven con validación de prerrequisitos y ciclos, y un respec que devuelve exactamente los puntos gastados.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Separar **progreso persistente**, **progreso de partida** y **estado runtime**, y decidir dónde va cada dato.
2. Implementar curvas de XP (lineal, cuadrática, exponencial) y elegir según la duración objetivo.
3. Implementar subidas de nivel múltiples en un solo evento sin perder XP.
4. Modelar un árbol de habilidades como grafo dirigido acíclico con prerrequisitos.
5. Implementar desbloqueo, coste creciente y validación de que el árbol es alcanzable.
6. Implementar respec devolviendo exactamente lo gastado y limpiando los modificadores.
7. Distinguir progresión de personaje de **metaprogresión** y modelar ambas.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | XP y curvas | La curva decide la duración del juego más que ninguna otra cifra. |
| 2 | Subida de nivel | Un evento discreto con consecuencias: stats, puntos, desbloqueos. |
| 3 | Puntos de habilidad | La moneda de la progresión: escasa y con decisiones. |
| 4 | Prerrequisitos | Convierten una lista de mejoras en un árbol con forma. |
| 5 | Grafo acíclico | Un ciclo de prerrequisitos hace inalcanzable media rama. |
| 6 | Coste creciente | Evita maximizar una sola rama sin coste de oportunidad. |
| 7 | Respec | Devolver puntos exige saber exactamente qué se gastó. |
| 8 | Desbloqueos | Habilidades, recetas, zonas: todo se gobierna igual. |
| 9 | Metaprogresión | Progreso que sobrevive a la partida: otra caja, otro save. |
| 10 | Persistente vs runtime | Guardar lo derivado es la fuente de las partidas corruptas. |

## 📖 Definiciones y características

- **Experiencia (XP)**: recurso acumulativo que mide el avance. Clave: es un contador, y su significado lo da la curva.
- **Curva de XP**: función que dice cuánta experiencia cuesta cada nivel. Clave: se parametriza, no se escribe a mano nivel por nivel.
- **Curva lineal**: coste constante por nivel. Clave: sencilla y monótona; el nivel 50 se siente igual que el 5.
- **Curva cuadrática**: coste proporcional al cuadrado del nivel. Clave: el estándar de facto en RPG; ritmo decreciente pero no brutal.
- **Curva exponencial**: coste multiplicado por un factor por nivel. Clave: se dispara rápido; útil para topes duros o monetización.
- **Nivel**: escalón discreto derivado de la XP acumulada. Clave: se calcula desde la XP, nunca se guarda por separado.
- **Punto de habilidad**: recurso gastable en el árbol, obtenido al subir de nivel. Clave: es lo que crea decisiones y builds.
- **Nodo de habilidad**: entrada del árbol con coste, prerrequisitos, rangos y efectos. Clave: es dato, igual que un item.
- **Prerrequisito**: nodo o condición que debe cumplirse antes de invertir. Clave: define la topología del árbol.
- **Rango (rank)**: número de veces que se puede invertir en un mismo nodo. Clave: permite nodos de "+5 % por punto, hasta 5".
- **DAG (grafo dirigido acíclico)**: estructura correcta de un árbol de habilidades. Clave: si hay un ciclo, hay contenido inalcanzable.
- **Respec**: reinicio de la inversión devolviendo los puntos. Clave: exige retirar todos los modificadores por origen.
- **Desbloqueo (unlock)**: contenido que pasa a estar disponible por progresión. Clave: es un conjunto de ids, y va en el save.
- **Progreso persistente**: lo que sobrevive a la muerte o al fin de partida. Clave: metaprogresión, logros, colecciones.
- **Progreso de partida**: lo que solo vale en la run actual. Clave: se descarta al terminar y no debe mezclarse con lo anterior.
- **Estado derivado**: valor calculable desde otros (nivel a partir de XP, stats a partir del árbol). Clave: nunca se guarda.
- **Gating**: uso de la progresión para controlar el acceso a contenido. Clave: es diseño de ritmo, no una restricción técnica.

## 🧰 Herramientas y preparación

Necesitas `Stats` (clase 296) y, para los desbloqueos de habilidades, `AbilitySystem` (clase 297). Trabajaremos en `res://dominio/progresion/` y `res://datos/arbol_habilidades.json`. La [clase 160](../../parte-8-game-design-y-diseno-de-niveles/160-curvas-de-dificultad-y-progresion/README.md) de la Parte 8 diseñó las curvas de progresión y dificultad; aquí se implementan. Si aún no la has leído, hazlo antes: los números salen de allí.

## 🧪 Laboratorio guiado

1. **La curva de XP.** Parametrizada, no tabulada a mano:

```gdscript
class_name CurvaXP
extends RefCounted

enum Forma { LINEAL, CUADRATICA, EXPONENCIAL }

var forma: Forma = Forma.CUADRATICA
var base: float = 100.0
var factor: float = 1.15          # solo para exponencial
var nivel_max: int = 60

func coste_de_nivel(nivel: int) -> int:
	"""XP necesaria para pasar DE `nivel` A `nivel + 1`."""
	if nivel >= nivel_max:
		return 0
	match forma:
		Forma.LINEAL:       return int(base * nivel)
		Forma.CUADRATICA:   return int(base * nivel * nivel)
		Forma.EXPONENCIAL:  return int(base * pow(factor, nivel - 1))
		_:                  return int(base)

func total_hasta(nivel: int) -> int:
	var t := 0
	for n in range(1, nivel):
		t += coste_de_nivel(n)
	return t
```

Con `base = 100` y curva cuadrática: nivel 2 cuesta 100, nivel 10 cuesta 8.100, y llegar al 60 son ~7 millones de XP. Ese número **es** la duración de tu juego: compáralo con la XP que da matar un enemigo y sabrás cuántas horas dura antes de escribir una línea más.

2. **La progresión del personaje:**

```gdscript
class_name Progresion
extends RefCounted

signal xp_ganada(cantidad: int, total: int)
signal subio_nivel(nuevo: int, puntos_ganados: int)
signal desbloqueado(id: StringName)

const PUNTOS_POR_NIVEL := 1

var curva := CurvaXP.new()
var xp_total: int = 0            # ESTADO: lo único que se guarda del progreso
var puntos_disponibles: int = 0
var _desbloqueos := {}

func nivel() -> int:
	# DERIVADO de la XP: si el diseño cambia la curva en un parche, todos los
	# personajes se recalculan solos en vez de quedarse con el nivel viejo.
	var n := 1
	var acumulado := 0
	while n < curva.nivel_max:
		var coste := curva.coste_de_nivel(n)
		if xp_total < acumulado + coste:
			break
		acumulado += coste
		n += 1
	return n

func xp_en_nivel_actual() -> int:
	return xp_total - curva.total_hasta(nivel())

func xp_para_siguiente() -> int:
	return curva.coste_de_nivel(nivel())

func ganar_xp(cantidad: int) -> void:
	if cantidad <= 0:
		return
	var antes := nivel()
	xp_total += cantidad
	xp_ganada.emit(cantidad, xp_total)
	var despues := nivel()
	# Un jefe puede dar 3 niveles de golpe: hay que emitirlos todos, no solo uno.
	for n in range(antes + 1, despues + 1):
		puntos_disponibles += PUNTOS_POR_NIVEL
		subio_nivel.emit(n, PUNTOS_POR_NIVEL)

func desbloquear(id: StringName) -> void:
	if _desbloqueos.has(id):
		return
	_desbloqueos[id] = true
	desbloqueado.emit(id)

func tiene_desbloqueo(id: StringName) -> bool:
	return _desbloqueos.has(id)

func a_dict() -> Dictionary:
	return {"xp": xp_total, "puntos": puntos_disponibles,
			"desbloqueos": _desbloqueos.keys().map(func(k): return String(k))}

func de_dict(d: Dictionary) -> void:
	xp_total = int(d.get("xp", 0))
	puntos_disponibles = int(d.get("puntos", 0))
	_desbloqueos.clear()
	for k in d.get("desbloqueos", []):
		_desbloqueos[StringName(str(k))] = true
```

3. **El árbol, como datos:**

```json
{
  "version": 1,
  "nodos": [
    { "id": "vigor", "nombre": "Vigor", "rangos": 5, "coste": 1,
      "requiere": [], "nivel_min": 1,
      "efectos": [{ "stat": "constitucion", "modo": "plano", "valor": 2 }] },

    { "id": "coraza", "nombre": "Coraza", "rangos": 3, "coste": 1,
      "requiere": [{ "nodo": "vigor", "rango": 3 }], "nivel_min": 5,
      "efectos": [{ "stat": "defensa", "modo": "plano", "valor": 5 }] },

    { "id": "muro", "nombre": "Muro inquebrantable", "rangos": 1, "coste": 3,
      "requiere": [{ "nodo": "coraza", "rango": 3 }], "nivel_min": 12,
      "desbloquea_habilidad": "provocar",
      "efectos": [{ "stat": "defensa", "modo": "porcentual", "valor": 0.15 }] }
  ]
}
```

4. **El árbol en código:**

```gdscript
class_name ArbolHabilidades
extends RefCounted

signal invertido(nodo: StringName, rango: int)
signal respec_hecho(puntos_devueltos: int)

var _nodos := {}                  # id -> Dictionary
var _invertido := {}              # id -> rango actual (ESTADO)
var _stats: Stats
var _prog: Progresion

func _init(stats: Stats, prog: Progresion) -> void:
	_stats = stats
	_prog = prog

func cargar(ruta: String) -> Array[String]:
	var datos = JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())
	for n in datos.get("nodos", []):
		_nodos[StringName(str(n["id"]))] = n
	return validar()

func rango(id: StringName) -> int:
	return _invertido.get(id, 0)

func puede_invertir(id: StringName) -> bool:
	if not _nodos.has(id):
		return false
	var n: Dictionary = _nodos[id]
	if rango(id) >= int(n.get("rangos", 1)):
		return false
	if _prog.nivel() < int(n.get("nivel_min", 1)):
		return false
	if _prog.puntos_disponibles < int(n.get("coste", 1)):
		return false
	for req in n.get("requiere", []):
		if rango(StringName(str(req["nodo"]))) < int(req.get("rango", 1)):
			return false
	return true

func invertir(id: StringName) -> bool:
	if not puede_invertir(id):
		return false
	var n: Dictionary = _nodos[id]
	_prog.puntos_disponibles -= int(n.get("coste", 1))
	_invertido[id] = rango(id) + 1
	_reaplicar(id)
	if n.has("desbloquea_habilidad"):
		_prog.desbloquear(StringName(str(n["desbloquea_habilidad"])))
	invertido.emit(id, _invertido[id])
	return true

func _origen(id: StringName) -> StringName:
	return StringName("arbol:%s" % id)

func _reaplicar(id: StringName) -> void:
	# Retirar y volver a poner: el modificador escala con el rango, así que
	# sumar "uno más" cada vez acabaría desincronizado tras un respec.
	_stats.retirar_origen(_origen(id))
	var n: Dictionary = _nodos[id]
	var r := rango(id)
	for e in n.get("efectos", []):
		var modo := {"plano": Estadistica.Modo.PLANO,
					 "porcentual": Estadistica.Modo.PORCENTUAL,
					 "multiplicativo": Estadistica.Modo.MULTIPLICATIVO}.get(
						str(e.get("modo", "plano")), Estadistica.Modo.PLANO)
		_stats.get_stat(StringName(str(e["stat"]))).agregar_mod(
			_origen(id), modo, float(e["valor"]) * r)
```

5. **Respec.** Devolver exactamente lo gastado, ni un punto más:

```gdscript
func puntos_gastados() -> int:
	var t := 0
	for id in _invertido:
		t += int(_nodos[id].get("coste", 1)) * _invertido[id]
	return t

func respec() -> int:
	var devueltos := puntos_gastados()
	for id in _invertido.keys():
		_stats.retirar_origen(_origen(id))       # residuo cero, como en la clase 298
	_invertido.clear()
	_prog.puntos_disponibles += devueltos
	respec_hecho.emit(devueltos)
	return devueltos
```

6. **Validar el árbol.** Prerrequisitos existentes, sin ciclos y alcanzable:

```gdscript
func validar() -> Array[String]:
	var errores: Array[String] = []
	for id in _nodos:
		var n: Dictionary = _nodos[id]
		if int(n.get("rangos", 1)) < 1:
			errores.append("nodo '%s': rangos < 1" % id)
		for req in n.get("requiere", []):
			var rid := StringName(str(req["nodo"]))
			if not _nodos.has(rid):
				errores.append("nodo '%s': prerrequisito inexistente '%s'" % [id, rid])
			elif int(req.get("rango", 1)) > int(_nodos[rid].get("rangos", 1)):
				# Este es el error que más duele: la rama entera queda muerta y
				# nada falla en runtime.
				errores.append("nodo '%s': exige rango %d de '%s', que solo tiene %d"
					% [id, int(req.get("rango", 1)), rid, int(_nodos[rid].get("rangos", 1))])
	errores.append_array(_detectar_ciclos())
	return errores

func _detectar_ciclos() -> Array[String]:
	var estado := {}          # 0 sin visitar, 1 en pila, 2 cerrado
	var errores: Array[String] = []
	var visitar := func(id, self_ref):
		if estado.get(id, 0) == 1:
			errores.append("ciclo de prerrequisitos en '%s'" % id)
			return
		if estado.get(id, 0) == 2:
			return
		estado[id] = 1
		for req in _nodos[id].get("requiere", []):
			var rid := StringName(str(req["nodo"]))
			if _nodos.has(rid):
				self_ref.call(rid, self_ref)
		estado[id] = 2
	for id in _nodos:
		visitar.call(id, visitar)
	return errores
```

7. **Metaprogresión.** Otra caja, otro archivo, otra vida:

```gdscript
class_name MetaProgresion
extends RefCounted

# Esto NO se pierde al morir. Va a su propio archivo, con su propia versión.
var fragmentos: int = 0
var mejoras := {}                 # id -> rango permanente
var records := {}                 # "mejor_ronda" -> valor

func aplicar_a(stats: Stats) -> void:
	for id in mejoras:
		stats.get_stat(&"vida_bonus").agregar_mod(
			StringName("meta:%s" % id), Estadistica.Modo.PLANO, float(mejoras[id]) * 10.0)

func a_dict() -> Dictionary:
	return {"fragmentos": fragmentos, "mejoras": mejoras, "records": records}
```

8. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	var stats := Stats.new()
	var prog := Progresion.new()
	var arbol := ArbolHabilidades.new(stats, prog)
	assert(arbol.cargar("res://datos/arbol_habilidades.json").is_empty(), "el árbol no valida")

	# Subida múltiple: de golpe, del 1 al 3.
	var niveles := []
	prog.subio_nivel.connect(func(n, _p): niveles.append(n))
	prog.ganar_xp(prog.curva.total_hasta(3))
	assert(prog.nivel() == 3 and niveles == [2, 3], "las subidas múltiples no se emitieron")
	assert(prog.puntos_disponibles == 2)

	# Prerrequisito no cumplido.
	assert(not arbol.puede_invertir(&"coraza"), "coraza no debería estar disponible")

	var base_con := stats.valor(&"constitucion")
	assert(arbol.invertir(&"vigor"))
	assert(arbol.invertir(&"vigor"))
	assert(stats.valor(&"constitucion") == base_con + 4.0, "el rango no escaló el efecto")

	var devueltos := arbol.respec()
	assert(devueltos == 2 and prog.puntos_disponibles == 2)
	assert(stats.valor(&"constitucion") == base_con, "el respec dejó residuo")

	print("== 8 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Implementa coste creciente: el segundo punto en un nodo cuesta 2, el tercero 3.
2. Añade "puntos exclusivos de rama" que solo se puedan gastar en un subconjunto del árbol.
3. Implementa respec parcial de un solo nodo con un coste en oro.
4. Escribe un script que dibuje el árbol en Graphviz DOT para revisarlo visualmente.
5. Calcula y grafica las horas estimadas hasta el nivel máximo con las tres curvas.
6. Implementa niveles de maestría por arma con su propia curva independiente.
7. Añade un informe que liste nodos inalcanzables porque su `nivel_min` supera el nivel máximo.

## 📝 Reto verificable

Implementa progresión y árbol con **al menos 12 nodos** en tres ramas, prerrequisitos con rango, nodos multi-rango, un nodo que desbloquea una habilidad, respec completo y metaprogresión separada.

**Criterio de aceptación**: una prueba headless con **al menos 18 aserciones** demuestra que: (a) `nivel()` se deriva de `xp_total` y cambiar la curva recalcula el nivel sin tocar el save; (b) ganar XP suficiente para tres niveles emite tres eventos `subio_nivel` y concede tres puntos; (c) invertir en un nodo con prerrequisito no cumplido devuelve `false` y no gasta puntos; (d) el respec devuelve **exactamente** `puntos_gastados()` y deja todas las estadísticas en su valor base; (e) el validador detecta un prerrequisito inexistente, un prerrequisito con rango imposible y un ciclo introducido a propósito; (f) `a_dict()` → `de_dict()` conserva XP, puntos y desbloqueos.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Un jefe da 3 niveles y solo se concede 1 punto | Se comparó nivel antes/después sin iterar. Recorre el rango de niveles ganados. |
| Al cambiar la curva en un parche los personajes conservan el nivel viejo | Se guardó el nivel. Guarda solo la XP y deriva el nivel. |
| Tras un respec el personaje conserva bonificaciones | Se retiraron los nodos pero no sus modificadores. Retira por origen en el respec. |
| Media rama del árbol es inalcanzable | Un prerrequisito pide un rango mayor que los rangos del nodo. Lo detecta el validador. |
| El árbol se cuelga al calcular disponibilidad | Ciclo de prerrequisitos. Detecta ciclos al cargar. |
| El roguelike pierde las mejoras permanentes al morir | Metaprogresión guardada en el save de partida. Sepáralas en dos archivos. |
| Los puntos se duplican al recargar | Se guardaron los puntos **y** se recalcularon al cargar. Elige una fuente y respétala. |
| Subir de nivel no actualiza el HUD | Falta conectar `subio_nivel`. La presentación se suscribe, no consulta cada frame. |

## ❓ Preguntas frecuentes

**❓ ¿Qué curva elijo?** Empieza por la cuadrática con `base` ajustada a tu duración objetivo: calcula `total_hasta(nivel_max)` y divide por la XP media que da una hora de juego. Si sale muy lejos de lo que quieres, ajusta `base` antes de tocar la forma.

**❓ ¿Guardo el nivel o la XP?** La XP. El nivel es derivado, y guardarlo crea dos fuentes de verdad que se desincronizan en cuanto un parche toca la curva. La misma regla vale para las stats derivadas de la clase 296.

**❓ ¿Respec gratis o de pago?** Gratis favorece la experimentación y reduce la ansiedad de elegir; con coste hace que las decisiones pesen. Es diseño puro. Técnicamente da igual: lo que no es negociable es que devuelva **exactamente** lo gastado y no deje residuos.

**❓ ¿Metaprogresión en el mismo archivo que la partida?** No. Van en archivos distintos porque tienen ciclos de vida distintos: la partida se borra al morir y la metaprogresión no. Además cada uno lleva su propio `SAVE_VERSION` ([clase 307](../307-save-system-de-produccion/README.md)).

**❓ ¿Cómo enseño el árbol al jugador?** Con el mismo dato: el JSON tiene la topología, así que la UI puede dibujarlo automáticamente. Si tienes que colocar 40 nodos a mano en una escena, cada cambio de diseño te costará una tarde.

## 🔗 Referencias

- Jesse Schell — *The Art of Game Design*, capítulos sobre curvas de interés y recompensa: <https://www.schellgames.com/art-of-game-design/> · uso: respalda el Tema 1 «XP y curvas»
- Godot Docs — `JSON` y datos de juego: <https://docs.godotengine.org/en/4.3/classes/class_json.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — Señales: <https://docs.godotengine.org/en/4.3/getting_started/step_by_step/signals.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- GDC Vault — charlas sobre diseño de progresión, gating y metaprogresión: <https://www.gdcvault.com/> — catálogo por tema, no una charla identificada (ponente y año pendientes) · uso: respalda el Tema 9 «Metaprogresión»
- Wikipedia — Grafo dirigido acíclico (la estructura correcta de un skill tree): <https://en.wikipedia.org/wiki/Directed_acyclic_graph> · uso: respalda el Tema 5 «Grafo acíclico»

## ⬅️ Clase anterior

[Clase 301 - Crafting y recetas](../301-crafting-y-recetas/README.md)

## ➡️ Siguiente clase

[Clase 303 - Economía interna implementada](../303-economia-interna-implementada/README.md)
