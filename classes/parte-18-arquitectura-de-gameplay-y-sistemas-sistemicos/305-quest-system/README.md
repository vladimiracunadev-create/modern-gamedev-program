# Clase 305 — Quest System

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Charlas de GDC sobre diseño y herramientas de misiones · Nystrom, «Game Programming Patterns» (Observer, State)*
> ⏱️ Duración estimada: **125 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir el **sistema de misiones**: quests definidas como datos, con estados, objetivos múltiples, prerrequisitos, cadenas, recompensas y persistencia. Es el sistema que da estructura al contenido de un juego grande y el que conecta casi todos los demás: usa el diálogo para entregarse, el inventario para sus recompensas, la economía para pagarlas y la reputación para condicionarse.

El error clásico es implementar los objetivos con `if` repartidos por el juego ("si el enemigo muerto era un lobo y la quest 3 está activa, sumar 1"). Aquí harás lo contrario: los sistemas del juego **publican eventos** (`enemigo_muerto`, `item_recogido`, `zona_alcanzada`) y el rastreador de quests los escucha. El resultado es que añadir una misión no toca ni una línea de código de gameplay, y que puedes probar el sistema entero emitiendo eventos falsos.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Modelar una quest con id estable, prerrequisitos, objetivos, recompensas y estados.
2. Implementar la máquina de estados `Locked → Available → Active → Completed/Failed`.
3. Implementar objetivos escuchando eventos, sin acoplar gameplay al sistema de quests.
4. Implementar objetivos opcionales, contadores y objetivos con orden obligatorio.
5. Implementar cadenas de misiones y desbloqueo automático por prerrequisitos.
6. Entregar recompensas de forma atómica y tratar el caso de inventario lleno.
7. Persistir y restaurar el estado de todas las quests, incluido el progreso parcial.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Estados de una quest | Sin máquina de estados explícita, aparecen quests "activas y completadas". |
| 2 | Objetivos como datos | Añadir una misión no debe tocar el código del juego. |
| 3 | Eventos de gameplay | El desacople que hace posible todo lo demás. |
| 4 | Contadores y progreso | "3 de 10 lobos" es estado y va al save. |
| 5 | Objetivos opcionales | Recompensa extra sin bloquear la misión. |
| 6 | Orden de objetivos | Algunas misiones son secuenciales; hay que poder expresarlo. |
| 7 | Prerrequisitos y cadenas | Estructuran el contenido y el ritmo. |
| 8 | Recompensas atómicas | Inventario lleno al entregar es el caso que todos olvidan. |
| 9 | Fallo de misiones | Los tiempos límite y los NPC muertos existen. |
| 10 | Persistencia | Guardar el progreso parcial, no solo el estado. |

## 📖 Definiciones y características

- **Quest**: unidad de contenido con objetivos y recompensa. Clave: es dato, con id estable, igual que un item.
- **Estado de quest**: `LOCKED`, `AVAILABLE`, `ACTIVE`, `COMPLETED`, `FAILED`, `ENTREGADA`. Clave: las transiciones válidas se definen y se comprueban.
- **Locked**: no cumple prerrequisitos; ni siquiera se muestra. Clave: es el estado por defecto de casi todo el contenido.
- **Available**: se puede aceptar, pero aún no se ha aceptado. Clave: es lo que hace aparecer el "!" sobre un NPC.
- **Objetivo (objective)**: condición concreta que hay que cumplir. Clave: tiene tipo, objetivo y cantidad; y su progreso es estado.
- **Tipo de objetivo**: `matar`, `recoger`, `entregar`, `alcanzar`, `hablar`, `flag`. Clave: una lista cerrada que cubre casi todo.
- **Progreso**: cuánto se lleva de un objetivo con contador. Clave: se guarda; perderlo es de los bugs peor recibidos.
- **Objetivo opcional**: no bloquea la finalización pero da recompensa extra. Clave: necesita marcarse en el dato y en la UI.
- **Objetivo secuencial**: solo cuenta si los anteriores están completos. Clave: evita "completar" el paso 3 antes del 1.
- **Prerrequisito**: quest o condición previa que desbloquea otra. Clave: define la cadena y su ritmo.
- **Cadena de misiones (questline)**: secuencia encadenada por prerrequisitos. Clave: emerge del dato; no hace falta un tipo especial.
- **Recompensa**: items, moneda, XP, reputación o desbloqueos entregados al completar. Clave: se entrega de forma atómica o no se entrega.
- **Entrega (turn-in)**: paso opcional de volver a hablar con el dador. Clave: separa "completada" de "cobrada".
- **Rastreador (tracker)**: componente que escucha eventos y actualiza objetivos. Clave: es el único punto que conoce gameplay.
- **Evento de gameplay**: notificación tipada de algo ocurrido en el juego. Clave: es el contrato entre el juego y las quests.
- **Quest fallable**: la que puede pasar a `FAILED` por tiempo, muerte de un NPC o decisión. Clave: hay que decidir si se puede reintentar.

## 🧰 Herramientas y preparación

Necesitas inventario (295), monedero (303) y progresión (302) para las recompensas, y el diálogo (304) para entregar misiones. Trabajaremos en `res://dominio/quests/` y `res://datos/quests.json`. Conviene tener ya un pequeño bus de eventos; si no, esta clase te lo hace construir — y es la pieza que más veces reutilizarás en el resto del programa.

## 🧪 Laboratorio guiado

1. **El bus de eventos.** Diez líneas que desacoplan medio juego:

```gdscript
class_name EventosJuego
extends RefCounted

# Un bus con eventos TIPADOS. No es un diccionario de strings: cada evento es
# una señal con su firma, así un typo se detecta al escribirlo y no en runtime.
signal enemigo_muerto(id_enemigo: StringName, posicion: Vector2)
signal item_recogido(id_item: StringName, cantidad: int)
signal item_entregado(id_item: StringName, cantidad: int, a_quien: StringName)
signal zona_alcanzada(id_zona: StringName)
signal npc_hablado(id_npc: StringName)
signal flag_narrativa(clave: StringName, valor: bool)
```

2. **El dato de quest:**

```json
{
  "version": 1,
  "quests": [
    {
      "id": "lobos_del_camino",
      "titulo": "quest.lobos.titulo",
      "descripcion": "quest.lobos.desc",
      "dador": "guardia_puerta",
      "prerrequisitos": [],
      "secuencial": false,
      "objetivos": [
        { "id": "matar_lobos", "tipo": "matar", "objetivo": "lobo", "cantidad": 5 },
        { "id": "pieles", "tipo": "recoger", "objetivo": "piel_lobo", "cantidad": 3,
          "opcional": true }
      ],
      "recompensas": {
        "xp": 250,
        "oro": 120,
        "items": [{ "item": "pocion_menor", "cantidad": 3 }],
        "opcional": { "oro": 60 }
      }
    },
    {
      "id": "la_guarida",
      "titulo": "quest.guarida.titulo",
      "prerrequisitos": [{ "quest_completada": "lobos_del_camino" }],
      "secuencial": true,
      "limite_tiempo": 600.0,
      "objetivos": [
        { "id": "llegar", "tipo": "alcanzar", "objetivo": "zona_guarida" },
        { "id": "jefe", "tipo": "matar", "objetivo": "lobo_alfa", "cantidad": 1 },
        { "id": "volver", "tipo": "hablar", "objetivo": "guardia_puerta" }
      ],
      "recompensas": { "xp": 800, "oro": 400, "desbloqueos": ["receta_capa_lobo"] }
    }
  ]
}
```

3. **La instancia de quest y su máquina de estados:**

```gdscript
class_name Quest
extends RefCounted

enum Estado { LOCKED, AVAILABLE, ACTIVE, COMPLETED, ENTREGADA, FAILED }

# Transiciones permitidas: cualquier otra es un bug y queremos que salte.
const VALIDAS := {
	Estado.LOCKED:    [Estado.AVAILABLE],
	Estado.AVAILABLE: [Estado.ACTIVE, Estado.LOCKED],
	Estado.ACTIVE:    [Estado.COMPLETED, Estado.FAILED],
	Estado.COMPLETED: [Estado.ENTREGADA],
	Estado.ENTREGADA: [],
	Estado.FAILED:    [Estado.AVAILABLE],      # reintentables
}

var definicion: Dictionary
var estado: Estado = Estado.LOCKED
var progreso := {}                 # id_objetivo -> contador actual
var tiempo_restante: float = -1.0

func _init(def: Dictionary) -> void:
	definicion = def
	for o in def.get("objetivos", []):
		progreso[str(o["id"])] = 0
	tiempo_restante = float(def.get("limite_tiempo", -1.0))

func id() -> StringName:
	return StringName(str(definicion.get("id", "")))

func puede_pasar_a(nuevo: Estado) -> bool:
	return VALIDAS[estado].has(nuevo)

func objetivos() -> Array:
	return definicion.get("objetivos", [])

func requerido_completo(o: Dictionary) -> bool:
	return progreso.get(str(o["id"]), 0) >= int(o.get("cantidad", 1))

func obligatorios_completos() -> bool:
	for o in objetivos():
		if not bool(o.get("opcional", false)) and not requerido_completo(o):
			return false
	return true

func opcionales_completos() -> bool:
	for o in objetivos():
		if bool(o.get("opcional", false)) and not requerido_completo(o):
			return false
	return true
```

4. **El diario (el sistema).** Carga, desbloquea y transiciona:

```gdscript
class_name Diario
extends RefCounted

signal disponible(id: StringName)
signal aceptada(id: StringName)
signal progreso_objetivo(id: StringName, objetivo: String, actual: int, total: int)
signal completada(id: StringName)
signal fallada(id: StringName)
signal entregada(id: StringName, recompensas: Dictionary)

var _quests := {}                  # StringName -> Quest

func cargar(ruta: String) -> Array[String]:
	var d = JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return ["quests.json ilegible"]
	for def in d.get("quests", []):
		var q := Quest.new(def)
		_quests[q.id()] = q
	var errores := _validar()
	_reevaluar_disponibles()
	return errores

func estado(id: StringName) -> Quest.Estado:
	return _quests[id].estado if _quests.has(id) else Quest.Estado.LOCKED

func activas() -> Array:
	return _quests.values().filter(func(q): return q.estado == Quest.Estado.ACTIVE)

func _transicion(q: Quest, nuevo: Quest.Estado) -> bool:
	if not q.puede_pasar_a(nuevo):
		push_error("transición inválida en '%s': %d -> %d" % [q.id(), q.estado, nuevo])
		return false
	q.estado = nuevo
	return true

func _reevaluar_disponibles() -> void:
	for q in _quests.values():
		if q.estado != Quest.Estado.LOCKED:
			continue
		if _prerrequisitos_ok(q):
			_transicion(q, Quest.Estado.AVAILABLE)
			disponible.emit(q.id())

func _prerrequisitos_ok(q: Quest) -> bool:
	for p in q.definicion.get("prerrequisitos", []):
		if p.has("quest_completada"):
			var otra := StringName(str(p["quest_completada"]))
			if estado(otra) not in [Quest.Estado.COMPLETED, Quest.Estado.ENTREGADA]:
				return false
		if p.has("nivel_min") and _nivel_actual < int(p["nivel_min"]):
			return false
	return true

var _nivel_actual := 1
func fijar_nivel(n: int) -> void:
	_nivel_actual = n
	_reevaluar_disponibles()

func aceptar(id: StringName) -> bool:
	if not _quests.has(id):
		return false
	var q: Quest = _quests[id]
	if not _transicion(q, Quest.Estado.ACTIVE):
		return false
	aceptada.emit(id)
	return true
```

5. **El rastreador.** El único punto que conoce el gameplay:

```gdscript
func conectar(bus: EventosJuego) -> void:
	bus.enemigo_muerto.connect(func(id, _pos): _avanzar("matar", id, 1))
	bus.item_recogido.connect(func(id, n): _avanzar("recoger", id, n))
	bus.item_entregado.connect(func(id, n, _a): _avanzar("entregar", id, n))
	bus.zona_alcanzada.connect(func(id): _avanzar("alcanzar", id, 1))
	bus.npc_hablado.connect(func(id): _avanzar("hablar", id, 1))
	bus.flag_narrativa.connect(func(clave, v): if v: _avanzar("flag", clave, 1))

func _avanzar(tipo: String, objetivo: StringName, cantidad: int) -> void:
	for q in activas():
		var secuencial := bool(q.definicion.get("secuencial", false))
		var anteriores_ok := true
		for o in q.objetivos():
			if secuencial and not anteriores_ok:
				break                              # en secuencial, no se salta turno
			var coincide := str(o.get("tipo", "")) == tipo \
				and StringName(str(o.get("objetivo", ""))) == objetivo
			if coincide and not q.requerido_completo(o):
				var clave := str(o["id"])
				var total := int(o.get("cantidad", 1))
				q.progreso[clave] = mini(total, q.progreso[clave] + cantidad)
				progreso_objetivo.emit(q.id(), clave, q.progreso[clave], total)
			anteriores_ok = anteriores_ok and q.requerido_completo(o)
		if q.obligatorios_completos():
			_transicion(q, Quest.Estado.COMPLETED)
			completada.emit(q.id())
			_reevaluar_disponibles()               # la cadena avanza sola
```

6. **Tiempo y fallo:**

```gdscript
func tick(delta: float) -> void:
	for q in activas():
		if q.tiempo_restante > 0.0:
			q.tiempo_restante -= delta
			if q.tiempo_restante <= 0.0:
				_transicion(q, Quest.Estado.FAILED)
				fallada.emit(q.id())

func fallar(id: StringName) -> bool:
	if not _quests.has(id):
		return false
	var q: Quest = _quests[id]
	if not _transicion(q, Quest.Estado.FAILED):
		return false
	fallada.emit(id)
	return true
```

7. **Entregar la recompensa, de forma atómica.** El caso que todos olvidan:

```gdscript
func entregar(id: StringName, inv: Inventario, w: Monedero, prog: Progresion) -> bool:
	if not _quests.has(id):
		return false
	var q: Quest = _quests[id]
	if q.estado != Quest.Estado.COMPLETED:
		return false

	var r: Dictionary = q.definicion.get("recompensas", {})
	var items: Array = r.get("items", []).duplicate()
	if q.opcionales_completos():
		items.append_array(r.get("opcional", {}).get("items", []))

	# Si no cabe TODO, no se entrega nada: mejor que el jugador vacíe la mochila
	# a que pierda la recompensa de una misión de tres horas.
	for it in items:
		var iid := StringName(str(it["item"]))
		var n := int(it.get("cantidad", 1))
		if inv.cabe(iid, n) < n:
			return false

	if not _transicion(q, Quest.Estado.ENTREGADA):
		return false
	for it in items:
		inv.agregar_todo_o_nada(StringName(str(it["item"])), int(it.get("cantidad", 1)))
	var oro := int(r.get("oro", 0)) + (int(r.get("opcional", {}).get("oro", 0)) if q.opcionales_completos() else 0)
	if oro > 0:
		w.ingresar(&"oro", oro, StringName("quest:%s" % id))
	if int(r.get("xp", 0)) > 0:
		prog.ganar_xp(int(r["xp"]))
	for u in r.get("desbloqueos", []):
		prog.desbloquear(StringName(str(u)))

	entregada.emit(id, r)
	_reevaluar_disponibles()
	return true
```

8. **Persistencia y validación:**

```gdscript
func a_dict() -> Dictionary:
	var out := {}
	for id in _quests:
		var q: Quest = _quests[id]
		if q.estado == Quest.Estado.LOCKED:
			continue                     # lo bloqueado se recalcula; no ocupa save
		out[String(id)] = {"estado": q.estado, "progreso": q.progreso,
						   "tiempo": q.tiempo_restante}
	return out

func de_dict(d: Dictionary) -> void:
	for clave in d:
		var id := StringName(str(clave))
		if not _quests.has(id):
			push_warning("quest desconocida en el save (¿borrada en un parche?): %s" % id)
			continue
		var q: Quest = _quests[id]
		q.estado = int(d[clave].get("estado", Quest.Estado.LOCKED)) as Quest.Estado
		q.progreso = d[clave].get("progreso", {}).duplicate()
		q.tiempo_restante = float(d[clave].get("tiempo", -1.0))
	_reevaluar_disponibles()

func _validar() -> Array[String]:
	var errores: Array[String] = []
	const TIPOS := ["matar", "recoger", "entregar", "alcanzar", "hablar", "flag"]
	for q in _quests.values():
		if q.objetivos().is_empty():
			errores.append("quest '%s': sin objetivos" % q.id())
		var vistos := {}
		for o in q.objetivos():
			if vistos.has(str(o.get("id", ""))):
				errores.append("quest '%s': id de objetivo duplicado '%s'" % [q.id(), o.get("id", "")])
			vistos[str(o.get("id", ""))] = true
			if not TIPOS.has(str(o.get("tipo", ""))):
				errores.append("quest '%s': tipo de objetivo desconocido '%s'" % [q.id(), o.get("tipo", "")])
		var todos_opcionales := q.objetivos().all(func(o): return bool(o.get("opcional", false)))
		if todos_opcionales and not q.objetivos().is_empty():
			errores.append("quest '%s': todos los objetivos son opcionales (se completa sola)" % q.id())
		for p in q.definicion.get("prerrequisitos", []):
			if p.has("quest_completada") and not _quests.has(StringName(str(p["quest_completada"]))):
				errores.append("quest '%s': prerrequisito inexistente '%s'" % [q.id(), p["quest_completada"]])
	return errores
```

9. **Probarlo con eventos falsos.** Sin mundo, sin enemigos, sin NPC:

```gdscript
extends SceneTree

func _init() -> void:
	var bus := EventosJuego.new()
	var diario := Diario.new()
	assert(diario.cargar("res://datos/quests.json").is_empty(), "las quests no validan")
	diario.conectar(bus)

	assert(diario.estado(&"la_guarida") == Quest.Estado.LOCKED, "la cadena no empieza bloqueada")
	assert(diario.aceptar(&"lobos_del_camino"))

	for i in 5:
		bus.enemigo_muerto.emit(&"lobo", Vector2.ZERO)
	assert(diario.estado(&"lobos_del_camino") == Quest.Estado.COMPLETED,
		"los objetivos obligatorios no completaron la quest")
	# La cadena se desbloquea sola al completar el prerrequisito.
	assert(diario.estado(&"la_guarida") == Quest.Estado.AVAILABLE, "la cadena no avanzó")

	# Secuencial: matar al alfa antes de llegar NO cuenta.
	diario.aceptar(&"la_guarida")
	bus.enemigo_muerto.emit(&"lobo_alfa", Vector2.ZERO)
	assert(diario._quests[&"la_guarida"].progreso["jefe"] == 0,
		"un objetivo secuencial avanzó fuera de orden")

	print("== 5 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Añade el tipo `escoltar` con un objetivo que falla si el NPC muere.
2. Implementa quests repetibles (diarias) con un contador de reinicios.
3. Añade objetivos con rama: "mata al bandido **o** convéncelo" (uno u otro completa).
4. Muestra en el HUD la quest rastreada con su progreso, alimentado solo por señales.
5. Implementa "abandonar quest" devolviendo el estado a `AVAILABLE` y reseteando el progreso.
6. Genera un diagrama Graphviz de las cadenas de misiones a partir de los prerrequisitos.
7. Añade un informe que detecte quests inalcanzables (prerrequisito que nunca se cumple).

## 📝 Reto verificable

Implementa el sistema con **al menos seis quests** formando dos cadenas, que cubran los seis tipos de objetivo, con objetivos opcionales, una quest secuencial, una con límite de tiempo y recompensas de items, oro, XP y desbloqueos.

**Criterio de aceptación**: una prueba headless con **al menos 20 aserciones** demuestra que: (a) el sistema avanza objetivos **solo** emitiendo eventos del bus, sin llamar a ningún método del diario; (b) una transición inválida (`ENTREGADA → ACTIVE`) es rechazada y registrada; (c) un objetivo secuencial no avanza si los anteriores no están completos; (d) los objetivos opcionales no bloquean la finalización pero sí añaden su recompensa; (e) entregar con el inventario lleno devuelve `false` y **deja la quest en COMPLETED**, sin consumir la recompensa; (f) `a_dict()` → `de_dict()` conserva estado, progreso parcial y tiempo restante; (g) el validador detecta objetivo con tipo desconocido, id duplicado, prerrequisito inexistente y quest de objetivos todos opcionales.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Añadir una quest obliga a tocar el código de los enemigos | Los objetivos se comprueban en gameplay. Publica eventos y que los escuche el diario. |
| El progreso de "3 de 10" se pierde al recargar | Solo se guardó el estado. Guarda también el diccionario de progreso. |
| Una quest aparece completada y activa a la vez | No hay máquina de estados. Define transiciones válidas y recházalo todo lo demás. |
| El jugador pierde la recompensa por inventario lleno | Se entregó sin comprobar el hueco. Comprueba `cabe()` para todos los items antes de transicionar. |
| Los objetivos de una misión secuencial se completan en desorden | Falta la comprobación de anteriores. Corta el bucle cuando un obligatorio previo no está completo. |
| Matar un lobo avanza cinco quests a la vez | Es correcto si las cinco lo piden; si no, revisa que el `objetivo` sea específico. |
| La cadena no avanza al completar la primera misión | Falta `_reevaluar_disponibles()` tras completar. |
| Un save viejo peta al cargar quests borradas | No se filtró por existencia. Avisa y descarta, como en el inventario. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué un bus de eventos y no llamadas directas?** Porque las llamadas directas obligan a que el código de los lobos conozca el sistema de quests. Con el bus, el lobo dice "he muerto" y le da igual quién escuche: el diario, los logros, la telemetría y el sistema de sonido. Es el mismo desacople de la [clase 293](../293-arquitectura-de-gameplay-a-escala/README.md), y aquí se ve su rentabilidad.

**❓ ¿Guardo las quests bloqueadas?** No. Se recalculan de los prerrequisitos al cargar. Guardar solo lo que se aparta del estado por defecto mantiene el save pequeño y hace que añadir quests en un parche funcione sin migración.

**❓ ¿Y si borro una quest en un parche?** El save la traerá y el sistema no la conocerá. Avisa y descártala (como arriba), o añade un alias en la migración ([clase 307](../307-save-system-de-produccion/README.md)). Lo que no puedes hacer es reventar la carga.

**❓ ¿Completed y Entregada no son lo mismo?** No, y separarlas evita un bug muy típico: si al cumplir el último objetivo entregas la recompensa automáticamente, el jugador puede perderla si tiene el inventario lleno. Con dos estados, el juego puede decir "vuelve a hablar con el guardia" y reintentar cuantas veces haga falta.

**❓ ¿Puedo generar quests proceduralmente?** Sí: las quests son datos, así que un generador solo tiene que producir el mismo diccionario. Pásalo por el **mismo validador** que el contenido escrito a mano — y eso vale también para las generadas por IA ([clase 333](../../parte-20-ia-generativa-y-desarrollo-asistido-por-ia/333-dialogo-quests-y-contenido-generativo/README.md)).

## 🔗 Referencias

- Robert Nystrom — *Game Programming Patterns*, Observer: <https://gameprogrammingpatterns.com/observer.html>
- Godot Docs — Señales personalizadas y `Callable`: <https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html>
- Godot Docs — `JSON`: <https://docs.godotengine.org/en/stable/classes/class_json.html>
- GDC Vault — charlas sobre herramientas de misiones y diseño de contenido: <https://www.gdcvault.com/>
- Jason Gregory — *Game Engine Architecture*: <https://www.gameenginebook.com/>

## ⬅️ Clase anterior

[Clase 304 - Sistemas de diálogo](../304-sistemas-de-dialogo/README.md)

## ➡️ Siguiente clase

[Clase 306 - Facciones, reputación y relaciones](../306-facciones-reputacion-y-relaciones/README.md)
