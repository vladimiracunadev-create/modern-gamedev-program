# Clase 111 — Behavior Trees: fundamentos

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Steve Rabin, "Game AI Pro" (artículo de behavior trees) + Ian Millington, "Artificial Intelligence for Games"*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Entender e implementar desde cero la estructura de decisión estándar de la industria para enemigos complejos: el **behavior tree**. Al terminar sabrás qué es un nodo composite (Sequence, Selector), un decorator (Inverter, Repeater) y un leaf (Action, Condition), qué significan los estados **SUCCESS / FAILURE / RUNNING**, y habrás construido un mini-BT en GDScript con clases `RefCounted` que ejecuta una lógica real y observable por consola.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar por qué un behavior tree escala mejor que una FSM.
- Distinguir nodos composite, decorator y leaf y su función.
- Implementar Sequence, Selector, Inverter y Action/Condition en GDScript.
- Usar los tres estados de retorno SUCCESS, FAILURE y RUNNING correctamente.
- Ejecutar (tick) un árbol y trazar el flujo de la evaluación.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es un behavior tree | Reemplaza el enredo de transiciones de la FSM |
| 2 | Estados SUCCESS/FAILURE/RUNNING | El lenguaje común de todos los nodos |
| 3 | Composite: Sequence | Ejecuta hijos en orden hasta que uno falla |
| 4 | Composite: Selector | Prueba hijos hasta que uno tiene éxito |
| 5 | Decorator: Inverter/Repeater | Modifican el resultado o repiten un hijo |
| 6 | Leaf: Action y Condition | Donde ocurre el trabajo real |
| 7 | El tick del árbol | Cómo se evalúa cada frame de arriba abajo |

## 📖 Definiciones y características

- **Behavior tree (BT)**: árbol que se evalúa por *ticks* para decidir la acción del agente. Clave: el flujo lo definen los nodos, no transiciones sueltas.
- **Estado de retorno**: cada nodo devuelve `SUCCESS`, `FAILURE` o `RUNNING`. Clave: `RUNNING` permite acciones que duran varios frames.
- **Sequence**: composite que ejecuta hijos en orden; falla si uno falla, tiene éxito si todos triunfan. Clave: es un "Y" lógico.
- **Selector (Fallback)**: composite que prueba hijos hasta que uno triunfa. Clave: es un "O" lógico, ideal para prioridades.
- **Decorator**: nodo con un solo hijo que altera su resultado o ejecución (Inverter, Repeater). Clave: reutiliza lógica sin duplicarla.
- **Action (leaf)**: hoja que ejecuta un comportamiento (moverse, atacar). Clave: puede devolver `RUNNING` mientras trabaja.
- **Condition (leaf)**: hoja que consulta el mundo y devuelve `SUCCESS`/`FAILURE`. Clave: nunca devuelve `RUNNING`.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x. Este laboratorio es de arquitectura pura: crearemos varias clases `RefCounted` con `class_name`, sin depender de nodos de escena, y un `Node` raíz que haga el tick cada frame. Ten claro el concepto de herencia en GDScript y el uso de `Array` tipados. Como lectura de apoyo, el artículo clásico "Behavior Trees for AI: How They Work" y los capítulos de BT en [Game AI Pro](http://www.gameaipro.com/) explican la teoría; aquí la implementamos. Repasa [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html) y la herencia con `extends` en la documentación de GDScript.

## 🧪 Laboratorio guiado

Construiremos un mini-framework de BT con clases y lo probaremos con un árbol que decide entre "beber" (si tiene sed) o "trabajar".

**Paso 1 — El nodo base y los estados.** Crea `bt.gd` con la clase base y el enum de estados:

```gdscript
# bt.gd
class_name BTNode
extends RefCounted

enum Estado { SUCCESS, FAILURE, RUNNING }

# tick() se llama en cada evaluación; cada nodo lo sobrescribe.
func tick() -> Estado:
	return Estado.FAILURE
```

**Paso 2 — Composites: Sequence y Selector.** Ambos guardan una lista de hijos y difieren en la lógica de recorrido:

```gdscript
# secuencia.gd
class_name BTSequence
extends BTNode

var hijos: Array[BTNode] = []

func _init(lista: Array[BTNode] = []) -> void:
	hijos = lista

# Sequence = "Y": corre hijos en orden; si uno falla, falla todo.
func tick() -> Estado:
	for hijo in hijos:
		var r := hijo.tick()
		if r != Estado.SUCCESS:
			return r   # propaga FAILURE o RUNNING y se detiene
	return Estado.SUCCESS
```

```gdscript
# selector.gd
class_name BTSelector
extends BTNode

var hijos: Array[BTNode] = []

func _init(lista: Array[BTNode] = []) -> void:
	hijos = lista

# Selector = "O": prueba hijos; el primero que triunfa gana.
func tick() -> Estado:
	for hijo in hijos:
		var r := hijo.tick()
		if r != Estado.FAILURE:
			return r   # devuelve SUCCESS o RUNNING y se detiene
	return Estado.FAILURE
```

**Paso 3 — Decorator: Inverter.** Un decorator envuelve a un solo hijo y transforma su resultado:

```gdscript
# inverter.gd
class_name BTInverter
extends BTNode

var hijo: BTNode

func _init(h: BTNode) -> void:
	hijo = h

# Invierte SUCCESS<->FAILURE; RUNNING pasa sin tocar.
func tick() -> Estado:
	var r := hijo.tick()
	if r == Estado.SUCCESS:
		return Estado.FAILURE
	if r == Estado.FAILURE:
		return Estado.SUCCESS
	return Estado.RUNNING
```

**Paso 4 — Leaves: Condition y Action con callables.** Para no crear una clase por comportamiento, aceptamos un `Callable`:

```gdscript
# hojas.gd
class_name BTCondition
extends BTNode

var prueba: Callable   # debe devolver bool

func _init(fn: Callable) -> void:
	prueba = fn

func tick() -> Estado:
	return Estado.SUCCESS if prueba.call() else Estado.FAILURE
```

```gdscript
# accion.gd
class_name BTAction
extends BTNode

var accion: Callable   # debe devolver un BTNode.Estado

func _init(fn: Callable) -> void:
	accion = fn

func tick() -> Estado:
	return accion.call()
```

**Paso 5 — Montar y tickear el árbol.** Crea un `Node` raíz con este script y ejecútalo:

```gdscript
extends Node

var sed: bool = true

func _ready() -> void:
	# Selector: primero intenta "si tiene sed, beber"; si no, trabaja.
	var arbol := BTSelector.new([
		BTSequence.new([
			BTCondition.new(func(): return sed),
			BTAction.new(_beber),
		]) as BTNode,
		BTAction.new(_trabajar) as BTNode,
	])

	for frame in 3:
		print("Tick ", frame, " -> ", BTNode.Estado.keys()[arbol.tick()])
		sed = false   # tras el primer tick ya no tiene sed

func _beber() -> BTNode.Estado:
	print("  Bebo agua. Sed saciada.")
	return BTNode.Estado.SUCCESS

func _trabajar() -> BTNode.Estado:
	print("  Trabajo tranquilo.")
	return BTNode.Estado.SUCCESS
```

**Resultado visible:** en consola, el primer tick imprime "Bebo agua" (había sed) y los siguientes imprimen "Trabajo tranquilo", demostrando cómo el Selector prioriza la rama de beber solo cuando su condición se cumple.

## ✍️ Ejercicios

1. Añade un `BTRepeater` que repita a su hijo N veces y pruébalo con una acción que imprima.
2. Crea una condición `hay_enemigo_cerca` y una acción `huir`, y combínalas en una Sequence.
3. Invierte una condición con `BTInverter` para expresar "si NO tiene sed".
4. Añade un tercer comportamiento de menor prioridad (`descansar`) al Selector raíz.
5. Haz que `_trabajar` devuelva `RUNNING` en los primeros dos ticks y `SUCCESS` al tercero.
6. Dibuja el árbol del laboratorio con sus composites, condiciones y acciones.

## 📝 Reto verificable

Construye un behavior tree con al menos un Selector, dos Sequences, un decorator (Inverter o Repeater) y cuatro hojas (dos Condition, dos Action), que resuelva una lógica de "sobrevivir" (buscar comida si hay hambre, huir si hay peligro, si no explorar) y que imprima por consola la decisión de cada tick.

**Criterio de aceptación**: el árbol se ejecuta sin errores durante varios ticks, cambia de decisión al cambiar las condiciones simuladas, y usas correctamente al menos una vez cada tipo de nodo (composite, decorator, leaf).

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Una Condition devuelve RUNNING | Las condiciones solo devuelven SUCCESS/FAILURE; corrige el nodo |
| El Selector nunca prueba el segundo hijo | El primero devuelve SUCCESS o RUNNING; revisa si esa es tu intención |
| Error "Callable is null" al tickear | Pasaste una función inexistente; verifica el nombre del `Callable` |
| El árbol siempre falla | Confundiste Sequence (Y) con Selector (O); revisa la semántica |
| RUNNING se pierde y reinicia la acción | No propagas RUNNING hacia arriba; los composites deben devolverlo |
| Array de hijos sin tipar da warnings | Declara `Array[BTNode]` y castea con `as BTNode` si es necesario |

## ❓ Preguntas frecuentes

**¿Por qué un BT escala mejor que una FSM?**
Porque la lógica es composicional: añades una rama sin tocar transiciones existentes. En una FSM, cada estado nuevo puede requerir muchas transiciones.

**¿Qué aporta el estado RUNNING?**
Permite acciones que duran varios frames (caminar hasta un punto) sin bloquear el árbol: el nodo dice "sigo en ello" y se retoma en el próximo tick.

**¿Cada frame se evalúa todo el árbol?**
En la versión simple sí, desde la raíz. Implementaciones avanzadas recuerdan el nodo `RUNNING` para reanudar, optimización que verás más adelante.

**¿Diferencia entre Selector y un `if/elif`?**
Conceptualmente parecidos, pero el Selector es un dato componible: puedes reordenar prioridades, insertar decorators y reutilizar subárboles sin reescribir condicionales.

## 🔗 Referencias

- [Game AI Pro — behavior trees](http://www.gameaipro.com/)
- [RefCounted — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)
- [Callable — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_callable.html)
- [Behavior Trees in Robotics and AI (libro abierto)](https://arxiv.org/abs/1709.00084)

## ➡️ Siguiente clase

[Clase 112 - Behavior Trees: construir un enemigo completo](../112-behavior-trees-construir-un-enemigo-completo/README.md)
