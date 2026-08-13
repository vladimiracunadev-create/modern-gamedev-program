# Clase 296 — Equipamiento, loadouts y estadísticas

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Gregory, «Game Engine Architecture» · Documentación del Gameplay Ability System (atributos y modificadores)*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Separar lo que el jugador **lleva** (inventario) de lo que el jugador **usa** (equipo), y construir el sistema de estadísticas que los conecta. Esta clase resuelve un problema que casi todos los proyectos amateur resuelven mal: cuando el ataque del personaje es una variable que cada item suma y resta al equiparse y desequiparse, basta un desequipado mal ordenado para que el jugador se quede con +7 de ataque para siempre.

La solución es dejar de mutar la estadística y **recalcularla**: una `Estadistica` tiene un valor base y una lista de modificadores; su valor final es una función pura de ambos. Quitar un item es quitar su modificador de la lista, no restar un número. Construirás slots con restricciones, equipar/desequipar atómicos apoyados en el inventario de la clase anterior, loadouts intercambiables y un orden de aplicación de modificadores documentado y probado.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Justificar por qué el equipo es un sistema aparte del inventario y qué interfaz los une.
2. Implementar slots tipados con restricciones (`solo armas`, `dos manos ocupa dos slots`).
3. Implementar `equipar` / `desequipar` **atómicos** que no pierdan objetos si el inventario está lleno.
4. Modelar estadísticas base y derivadas con modificadores planos, porcentuales y multiplicativos.
5. Definir y aplicar un **orden de aplicación** de modificadores, y explicar por qué el orden importa.
6. Implementar caché de estadísticas con invalidación, y medir que sigue siendo correcta.
7. Guardar y restaurar loadouts completos.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Inventario vs equipo | Son dos colecciones con reglas distintas; mezclarlas complica las dos. |
| 2 | Slots y restricciones | Impiden estados imposibles (un casco en la mano) desde el sistema, no desde la UI. |
| 3 | Equipar atómico | Equipar implica sacar del inventario y meter lo anterior: puede fallar a mitad. |
| 4 | Estadísticas base | El punto de partida antes de cualquier bonificación. |
| 5 | Modificadores | Son la unidad de cambio: se añaden y se quitan, no se suman a mano. |
| 6 | Plano vs porcentual | `+10` y `+10 %` no son intercambiables y su orden decide el balance. |
| 7 | Orden de aplicación | Sin un orden fijo, dos equipos idénticos dan resultados distintos. |
| 8 | Estadísticas derivadas | Vida máxima a partir de constitución: se calcula, no se guarda. |
| 9 | Caché e invalidación | Recalcular en cada frame es caro; cachear mal es peor. |
| 10 | Loadouts | Cambiar de "build" completa es una operación, no veinte. |

## 📖 Definiciones y características

- **Slot de equipo**: posición tipada (cabeza, torso, mano principal…) que admite un subconjunto de items. Clave: su restricción es una regla de dominio, no un filtro de UI.
- **Equipment**: colección de slots con las reglas de qué puede ir en cada uno. Clave: es independiente del inventario y se guarda aparte.
- **Loadout**: conjunto completo de items equipados, guardable y recuperable como una unidad. Clave: permite alternar builds sin desmontar pieza a pieza.
- **Estadística (attribute)**: valor numérico del personaje con un base y modificadores (ataque, defensa, velocidad). Clave: su valor final se calcula, nunca se muta directamente.
- **Valor base**: punto de partida de una estadística, antes de cualquier modificador. Clave: es lo único que se guarda en el save.
- **Modificador (modifier)**: cambio con nombre aplicado a una estadística, con origen y modo. Clave: se identifica por su origen para poder retirarlo con exactitud.
- **Modificador plano (flat)**: suma o resta un valor absoluto (`+7 ataque`). Clave: domina en niveles bajos y se diluye en niveles altos.
- **Modificador porcentual aditivo**: los porcentajes se suman entre sí antes de aplicarse (`+10 %` y `+20 %` → `+30 %`). Clave: escala de forma predecible y controlable.
- **Modificador multiplicativo**: cada uno multiplica el resultado anterior (`×1,1` y `×1,2` → `×1,32`). Clave: es el que genera builds rotas si se apila sin límite.
- **Orden de aplicación**: secuencia fija (base → planos → porcentuales → multiplicativos) en la que se resuelven los modificadores. Clave: hace el resultado reproducible y explicable al jugador.
- **Origen (source)**: quién puso el modificador (un item, un buff, una habilidad). Clave: sin él no se puede retirar limpiamente.
- **Estadística derivada**: valor calculado a partir de otras (`vida_max = 50 + 10 × constitución`). Clave: se recalcula, no se guarda, para no desincronizarse.
- **Recalcular vs mutar**: estrategia de obtener el valor a partir de sus fuentes en lugar de acumular cambios. Clave: elimina toda una familia de bugs de "se quedó pegado".
- **Invalidación de caché**: marcar el valor cacheado como sucio cuando cambia una fuente. Clave: la caché solo es válida si toda escritura pasa por un punto.
- **Clamp**: acotar el resultado final a un rango razonable. Clave: impide velocidades negativas y defensas del 100 %.

## 🧰 Herramientas y preparación

Necesitas el catálogo (clase 294) y el inventario (clase 295) funcionando; el laboratorio los usa directamente. Trabajaremos en `res://dominio/stats/` y `res://dominio/equipo/`. Añade al catálogo unos cuantos items con efectos de tipo `modificador` como el de la espada de hierro, y al menos un item de dos manos para probar la restricción más incómoda.

## 🧪 Laboratorio guiado

1. **La estadística.** El corazón de la clase. Fíjate en que `valor()` es una **función pura** de `base` y de la lista de modificadores:

```gdscript
class_name Estadistica
extends RefCounted

enum Modo { PLANO, PORCENTUAL, MULTIPLICATIVO }

signal cambio(nuevo: float)

var base: float
var _mods: Array[Dictionary] = []      # {origen, modo, valor}
var _cache := 0.0
var _sucio := true

func _init(base_: float) -> void:
	base = base_

func agregar_mod(origen: StringName, modo: Modo, valor: float) -> void:
	_mods.append({"origen": origen, "modo": modo, "valor": valor})
	_invalidar()

func quitar_mods_de(origen: StringName) -> void:
	# Retiramos por ORIGEN, no por valor: dos items pueden dar +7 y hay que
	# quitar el del item correcto.
	_mods = _mods.filter(func(m): return m["origen"] != origen)
	_invalidar()

func valor() -> float:
	if _sucio:
		_cache = _calcular()
		_sucio = false
	return _cache

func _calcular() -> float:
	var v := base
	# 1) Planos: suman al base.
	for m in _mods:
		if m["modo"] == Modo.PLANO:
			v += m["valor"]
	# 2) Porcentuales: se SUMAN entre ellos y se aplican una vez.
	var pct := 0.0
	for m in _mods:
		if m["modo"] == Modo.PORCENTUAL:
			pct += m["valor"]
	v *= 1.0 + pct
	# 3) Multiplicativos: se componen. Aquí es donde nacen las builds rotas.
	for m in _mods:
		if m["modo"] == Modo.MULTIPLICATIVO:
			v *= m["valor"]
	return maxf(0.0, v)

func _invalidar() -> void:
	_sucio = true
	cambio.emit(valor())
```

Con `base = 10`, un `+5` plano, un `+10 %` y un `+20 %` porcentuales y un `×1,5` multiplicativo: `((10 + 5) × 1,30) × 1,5 = 29,25`. Cambia el orden y sale otra cosa — por eso el orden se documenta y se prueba.

2. **El bloque de estadísticas.** Agrupa las primarias y calcula las derivadas:

```gdscript
class_name Stats
extends RefCounted

signal cambio(clave: StringName, valor: float)

var _stats := {}

func _init() -> void:
	for clave in [&"fuerza", &"constitucion", &"destreza", &"ataque", &"defensa", &"velocidad"]:
		var s := Estadistica.new(10.0 if clave in [&"fuerza", &"constitucion", &"destreza"] else 0.0)
		s.cambio.connect(func(v): cambio.emit(clave, v))
		_stats[clave] = s

func get_stat(clave: StringName) -> Estadistica:
	assert(_stats.has(clave), "estadística desconocida: %s" % clave)
	return _stats[clave]

func valor(clave: StringName) -> float:
	return get_stat(clave).valor()

# Derivadas: se calculan siempre, nunca se guardan. Si se guardaran, un cambio
# de fórmula en un parche dejaría a los personajes viejos con la vida antigua.
func vida_maxima() -> int:
	return int(50.0 + 10.0 * valor(&"constitucion"))

func dano_fisico() -> float:
	return valor(&"ataque") + valor(&"fuerza") * 0.5

func aplicar_efectos(origen: StringName, efectos: Array) -> void:
	for e in efectos:
		if str(e.get("tipo", "")) != "modificador":
			continue
		var clave := StringName(str(e.get("stat", "")))
		if not _stats.has(clave):
			push_warning("efecto sobre stat desconocida: %s" % clave)
			continue
		var modo := {"plano": Estadistica.Modo.PLANO,
					 "porcentual": Estadistica.Modo.PORCENTUAL,
					 "multiplicativo": Estadistica.Modo.MULTIPLICATIVO}.get(
						str(e.get("modo", "plano")), Estadistica.Modo.PLANO)
		get_stat(clave).agregar_mod(origen, modo, float(e.get("valor", 0.0)))

func retirar_origen(origen: StringName) -> void:
	for s in _stats.values():
		s.quitar_mods_de(origen)
```

3. **Los slots.** Cada slot declara qué admite. La restricción vive en el dominio:

```gdscript
class_name Equipo
extends RefCounted

signal slot_cambiado(slot: StringName, id: StringName)

const SLOTS := {
	&"cabeza":  [Item.Tipo.ARMADURA],
	&"torso":   [Item.Tipo.ARMADURA],
	&"mano_principal": [Item.Tipo.ARMA],
	&"mano_secundaria": [Item.Tipo.ARMA, Item.Tipo.ARMADURA],   # arma o escudo
}

var _base: BaseDeItems
var _stats: Stats
var _puesto := {}          # StringName slot -> StringName id

func _init(base: BaseDeItems, stats: Stats) -> void:
	_base = base
	_stats = stats

func admite(slot: StringName, id: StringName) -> bool:
	if not SLOTS.has(slot) or not _base.existe(id):
		return false
	var d := _base.obtener(id)
	if not SLOTS[slot].has(d.tipo):
		return false
	# Un arma a dos manos solo va en la mano principal, y exige la otra libre.
	if d.tiene_tag("dos_manos"):
		return slot == &"mano_principal"
	return true

func equipado(slot: StringName) -> StringName:
	return _puesto.get(slot, &"")
```

4. **Equipar de forma atómica.** Este es el paso donde se pierden objetos si se hace mal, porque intervienen dos sistemas:

```gdscript
func equipar(inv: Inventario, slot: StringName, id: StringName) -> bool:
	if not admite(slot, id) or inv.contar(id) < 1:
		return false

	var anterior: StringName = _puesto.get(slot, &"")
	var d := _base.obtener(id)
	var a_devolver: Array[StringName] = []
	if anterior != &"":
		a_devolver.append(anterior)
	# Dos manos: hay que liberar también la secundaria.
	if d.tiene_tag("dos_manos") and _puesto.get(&"mano_secundaria", &"") != &"":
		a_devolver.append(_puesto[&"mano_secundaria"])

	# Comprobamos ANTES de tocar nada: hueco para lo que sale, contando que el
	# item que entra libera su propia ranura.
	var huecos_necesarios := a_devolver.size()
	if inv.contar(id) == 1 and huecos_necesarios > 0:
		huecos_necesarios -= 1
	if inv.libres() < huecos_necesarios:
		return false          # el inventario no puede recibir lo que se quita

	if not inv.quitar(id, 1):
		return false
	for viejo in a_devolver:
		_desequipar_interno(&"mano_secundaria" if viejo != anterior else slot)
		var restante := inv.agregar(viejo, 1)
		assert(restante == 0, "se ha perdido un item al desequipar: %s" % viejo)

	_puesto[slot] = id
	_stats.aplicar_efectos(_origen(slot), d.efectos)
	slot_cambiado.emit(slot, id)
	return true

func desequipar(inv: Inventario, slot: StringName) -> bool:
	var id: StringName = _puesto.get(slot, &"")
	if id == &"":
		return false
	if not inv.agregar_todo_o_nada(id, 1):
		return false          # inventario lleno: NO se desequipa, no se tira
	_desequipar_interno(slot)
	return true

func _desequipar_interno(slot: StringName) -> void:
	if _puesto.get(slot, &"") == &"":
		return
	_stats.retirar_origen(_origen(slot))   # se retira por origen: nada se queda pegado
	_puesto.erase(slot)
	slot_cambiado.emit(slot, &"")

func _origen(slot: StringName) -> StringName:
	return StringName("equipo:%s" % slot)
```

La clave está en `_origen(slot)`: el modificador se etiqueta con el slot, así que desequipar la mano principal retira **exactamente** sus bonificaciones aunque el mismo item esté también en la otra mano.

5. **Loadouts.** Guardar una build es guardar el diccionario de slots:

```gdscript
func loadout() -> Dictionary:
	return _puesto.duplicate(true)

func aplicar_loadout(inv: Inventario, l: Dictionary) -> bool:
	var copia := inv.instantanea()
	var previo := loadout()
	for slot in SLOTS:
		desequipar(inv, slot)
	for slot in l:
		if not equipar(inv, StringName(slot), StringName(l[slot])):
			inv.restaurar(copia)              # rollback del inventario
			_puesto = previo                  # y del equipo
			for s in SLOTS:
				slot_cambiado.emit(StringName(s), _puesto.get(s, &""))
			return false
	return true
```

6. **Probarlo.** El caso que hay que exigir es el del bug clásico:

```gdscript
extends SceneTree

func _init() -> void:
	var base := BaseDeItems.new(); base.cargar_desde_json("res://datos/items.json")
	var stats := Stats.new()
	var inv := Inventario.new(base, 10)
	var eq := Equipo.new(base, stats)
	inv.agregar(&"espada_hierro", 2)

	var ataque_inicial := stats.valor(&"ataque")
	assert(eq.equipar(inv, &"mano_principal", &"espada_hierro"))
	assert(stats.valor(&"ataque") == ataque_inicial + 7.0, "el modificador no se aplicó")

	# Equipar la segunda espada encima NO debe acumular la bonificación.
	assert(eq.equipar(inv, &"mano_principal", &"espada_hierro"))
	assert(stats.valor(&"ataque") == ataque_inicial + 7.0, "la bonificación se ha duplicado")

	assert(eq.desequipar(inv, &"mano_principal"))
	assert(stats.valor(&"ataque") == ataque_inicial, "el modificador se ha quedado pegado")
	assert(inv.contar(&"espada_hierro") == 2, "se ha perdido una espada por el camino")

	print("== 6 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Añade el slot `anillo_1` / `anillo_2` y una restricción de "único equipado" para items con tag `unico`.
2. Implementa un tope de modificadores multiplicativos (máximo ×3 acumulado) y prueba que el clamp se aplica.
3. Añade una estadística derivada `probabilidad_critico` y muéstrala en una hoja de personaje.
4. Implementa `previsualizar(id, slot)` que devuelva las estadísticas resultantes **sin equipar** (para el tooltip de comparación).
5. Mide con `Time.get_ticks_usec()` el coste de `valor()` con y sin caché para 1.000 llamadas.
6. Añade una regla de nivel requerido y haz que `equipar` la respete.
7. Guarda tres loadouts con nombre y permite alternarlos con una tecla.

## 📝 Reto verificable

Implementa `Estadistica`, `Stats` y `Equipo` con al menos **cuatro slots**, restricción de dos manos, tres modos de modificador con orden documentado, equipar/desequipar atómicos y loadouts guardables.

**Criterio de aceptación**: una prueba headless con **al menos 15 aserciones** demuestra que: (a) equipar y desequipar cualquier secuencia de items deja las estadísticas exactamente en su valor base (sin residuos); (b) intentar desequipar con el inventario lleno devuelve `false` y **no** destruye el item ni retira sus modificadores; (c) equipar un arma de dos manos devuelve el escudo al inventario y falla limpiamente si no hay hueco; (d) con base 10, `+5` plano, `+10 %` y `+20 %` porcentuales y `×1.5` multiplicativo, `valor()` devuelve `29.25`.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El ataque sube y ya no baja al desequipar | Se mutó la variable en vez de gestionar modificadores. Recalcula desde base + mods. |
| Equipar dos veces el mismo item duplica el bonus | No se retiró el modificador del slot antes de aplicar el nuevo. Retira por origen siempre. |
| Al desequipar con el inventario lleno se pierde el item | Se retiró del slot antes de comprobar que cabía. Usa `agregar_todo_o_nada` primero. |
| Dos builds idénticas dan números distintos | El orden de aplicación depende del orden de inserción. Fija el orden en `_calcular()`. |
| La hoja de personaje muestra valores viejos | Se cacheó sin invalidar. Invalida en toda escritura y emite la señal. |
| Un arma a dos manos convive con un escudo | La restricción está solo en la UI. Muévela a `admite()` y a `equipar()`. |
| La vida máxima no cambia al subir constitución | Se guardó la derivada. Calcúlala siempre desde las primarias. |
| Al cargar la partida el personaje tiene el doble de stats | Se guardaron los valores finales y además se reaplicaron los items. Guarda solo bases y equipo; recalcula al cargar. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué los porcentuales se suman y los multiplicativos se componen?** Es una convención de balance, no una ley: los porcentuales aditivos escalan de forma predecible (10 items del +10 % dan +100 %) y los multiplicativos explotan (dan ×2,59). Muchos juegos reservan lo multiplicativo para efectos raros y contados. Lo importante no es qué elijas, sino **elegirlo, documentarlo y probarlo**.

**❓ ¿Por qué no guardar el valor final y ahorrarme el cálculo?** Porque el día que cambies una fórmula en un parche, todos los personajes existentes conservarán los números viejos y no habrá forma de arreglarlo. Guarda **fuentes** (base + equipo + progresión), calcula el resto.

**❓ ¿Esto no es lento?** El cálculo completo de una estadística son unas decenas de operaciones. Con caché e invalidación es despreciable frente a un frame. Si tuvieras 5.000 entidades con stats, ese es otro problema y otra solución: [data-oriented design](../../parte-21-arquitectura-avanzada-de-motores-y-rendering/339-data-oriented-design/README.md).

**❓ ¿Los buffs temporales usan este mismo sistema?** Sí, y es justamente la gracia: un buff es un modificador con un `origen` propio y una duración. Eso es lo que construye la [clase 298](../298-status-effects-buffs-y-debuffs/README.md) encima de esto.

**❓ ¿Cómo enseño al jugador de dónde viene un número?** Guarda el origen legible en el modificador y muéstralo en el tooltip ("Ataque 29 = 10 base +7 espada +12 % anillo"). Un sistema que puede explicarse es un sistema que puede depurarse.

## 🔗 Referencias

- Unreal Engine Docs — Gameplay Attributes and Modifiers (referencia conceptual): <https://dev.epicgames.com/documentation/en-us/unreal-engine/gameplay-attributes-and-gameplay-effects-for-the-gameplay-ability-system-in-unreal-engine>
- Jason Gregory — *Game Engine Architecture*: <https://www.gameenginebook.com/>
- Robert Nystrom — *Game Programming Patterns*, Component: <https://gameprogrammingpatterns.com/component.html>
- Godot Docs — Señales y `Callable`: <https://docs.godotengine.org/en/stable/classes/class_callable.html>
- GDC Vault — charlas sobre sistemas de progresión y balance de stats: <https://www.gdcvault.com/>

## ⬅️ Clase anterior

[Clase 295 - Sistema de inventario](../295-sistema-de-inventario/README.md)

## ➡️ Siguiente clase

[Clase 297 - Ability System: arquitectura de habilidades](../297-ability-system-arquitectura-de-habilidades/README.md)
