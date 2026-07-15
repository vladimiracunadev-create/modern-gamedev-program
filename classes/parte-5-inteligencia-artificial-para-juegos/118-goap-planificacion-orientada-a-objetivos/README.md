# Clase 118 — GOAP: planificación orientada a objetivos

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Jeff Orkin, "Three States and a Plan: The A.I. of F.E.A.R." (GDC 2006) + Game AI Pro (cap. GOAP)*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Entender e implementar **GOAP (Goal-Oriented Action Planning)**: en lugar de programar a mano cada secuencia de acciones, defines acciones con **precondiciones** y **efectos**, un **objetivo** (estado del mundo deseado) y un **planificador** que busca la cadena de acciones que lo alcanza. Al terminar tendrás un mini-GOAP en GDScript que produce el plan para "eliminar al jugador" encadenando *recoger arma → acercarse → atacar*, y sabrás cuándo GOAP supera a un árbol de comportamiento.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Modelar el estado del mundo como un `Dictionary` de hechos booleanos.
- Definir acciones con precondiciones, efectos y coste.
- Implementar un planificador por búsqueda (backward/forward) sobre estados.
- Generar y ejecutar un plan como secuencia ordenada de acciones.
- Explicar las diferencias entre GOAP y un Behavior Tree.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Estado del mundo | El planificador razona sobre hechos, no sobre nodos |
| 2 | Acciones (precond/efecto) | Unidad básica que el planner encadena |
| 3 | Objetivo (goal) | Define qué estado queremos alcanzar |
| 4 | Búsqueda del plan | Encuentra la secuencia válida (y barata) |
| 5 | Coste y plan óptimo | Permite preferir soluciones eficientes |
| 6 | Ejecución del plan | Recorre las acciones y reacciona a fallos |
| 7 | GOAP vs Behavior Tree | Elegir la herramienta según flexibilidad requerida |

## 📖 Definiciones y características

- **Estado del mundo**: conjunto de hechos que describen la situación. Clave: aquí, un `Dictionary` de `String -> bool`.
- **Precondición**: hechos que deben cumplirse para ejecutar una acción. Clave: si no se cumplen, la acción no es aplicable.
- **Efecto**: cambios que la acción aplica al estado. Clave: acercan (o alejan) del objetivo.
- **Objetivo**: subconjunto de hechos deseados. Clave: el plan termina cuando el estado los satisface.
- **Planificador**: buscador que encadena acciones desde el estado actual al objetivo. Clave: suele ser A* sobre el espacio de estados.
- **Coste**: peso de cada acción. Clave: el planner minimiza el coste total del plan.
- **Plan**: lista ordenada de acciones a ejecutar. Clave: se recalcula si el mundo cambia y lo invalida.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x**. Todo el planificador es GDScript puro con `class_name` y `RefCounted`; el agente puede ser un `CharacterBody2D` que ejecute el plan. Crea `res://ia/goap/`. Repasa `Dictionary`, `Array`, y el algoritmo de búsqueda en anchura/A*. Consulta la [charla de Orkin sobre F.E.A.R.](https://alumni.media.mit.edu/~jorkin/goap.html). Empezaremos con una búsqueda por anchura (BFS) por claridad y luego mencionaremos el coste.

## 🧪 Laboratorio guiado

Construiremos el planificador y probaremos que genera el plan para eliminar al jugador partiendo de "sin arma y lejos".

### Paso 1 — La acción GOAP

```gdscript
class_name AccionGOAP
extends RefCounted

var nombre: String = ""
var precondiciones: Dictionary = {}  # hechos requeridos
var efectos: Dictionary = {}         # hechos que aplica
var coste: float = 1.0

func _init(p_nombre: String, precond: Dictionary, efec: Dictionary, p_coste: float = 1.0) -> void:
	nombre = p_nombre
	precondiciones = precond
	efectos = efec
	coste = p_coste

# ¿Es aplicable esta acción en el estado dado?
func aplicable(estado: Dictionary) -> bool:
	for clave in precondiciones:
		if estado.get(clave, false) != precondiciones[clave]:
			return false
	return true

# Devuelve un NUEVO estado con los efectos aplicados.
func aplicar(estado: Dictionary) -> Dictionary:
	var nuevo: Dictionary = estado.duplicate(true)
	for clave in efectos:
		nuevo[clave] = efectos[clave]
	return nuevo
```

### Paso 2 — El planificador (búsqueda hacia adelante)

```gdscript
class_name PlanificadorGOAP
extends RefCounted

# Devuelve un Array de AccionGOAP en orden, o [] si no hay plan.
func planificar(inicial: Dictionary, objetivo: Dictionary, acciones: Array) -> Array:
	# Cada nodo de la frontera: { "estado":..., "plan":..., "coste":... }
	var frontera: Array = [{"estado": inicial, "plan": [], "coste": 0.0}]
	var visitados: Array = []

	while not frontera.is_empty():
		# Sacamos el nodo de menor coste (comportamiento tipo A*/Dijkstra).
		frontera.sort_custom(func(a, b): return a["coste"] < b["coste"])
		var nodo: Dictionary = frontera.pop_front()
		var estado: Dictionary = nodo["estado"]
		if _cumple(estado, objetivo):
			return nodo["plan"]
		var firma: String = str(estado)
		if firma in visitados:
			continue
		visitados.append(firma)

		for accion in acciones:
			if accion.aplicable(estado):
				var siguiente: Dictionary = accion.aplicar(estado)
				var plan_nuevo: Array = nodo["plan"].duplicate()
				plan_nuevo.append(accion)
				frontera.append({
					"estado": siguiente,
					"plan": plan_nuevo,
					"coste": nodo["coste"] + accion.coste,
				})
	return []  # sin plan posible

func _cumple(estado: Dictionary, objetivo: Dictionary) -> bool:
	for clave in objetivo:
		if estado.get(clave, false) != objetivo[clave]:
			return false
	return true
```

### Paso 3 — Definir acciones y objetivo

```gdscript
extends Node

func _ready() -> void:
	var acciones: Array = [
		AccionGOAP.new(
			"recoger_arma",
			{"tiene_arma": false},
			{"tiene_arma": true},
			1.0),
		AccionGOAP.new(
			"acercarse_jugador",
			{"cerca_jugador": false},
			{"cerca_jugador": true},
			2.0),
		AccionGOAP.new(
			"atacar",
			{"tiene_arma": true, "cerca_jugador": true},
			{"jugador_eliminado": true},
			1.0),
	]

	var estado_inicial: Dictionary = {
		"tiene_arma": false,
		"cerca_jugador": false,
		"jugador_eliminado": false,
	}
	var objetivo: Dictionary = {"jugador_eliminado": true}

	var planner: PlanificadorGOAP = PlanificadorGOAP.new()
	var plan: Array = planner.planificar(estado_inicial, objetivo, acciones)

	# Imprime: recoger_arma -> acercarse_jugador -> atacar
	var nombres: Array = plan.map(func(a): return a.nombre)
	print("Plan: ", " -> ".join(nombres))
```

Ejecuta: la consola muestra `Plan: recoger_arma -> acercarse_jugador -> atacar`. Observable: si cambias el estado inicial a `"tiene_arma": true`, el plan se acorta a `acercarse_jugador -> atacar` automáticamente, sin tocar el código.

### Paso 4 — Ejecutar el plan en el agente

```gdscript
class_name EjecutorPlan
extends RefCounted

var plan: Array = []
var indice: int = 0

func iniciar(nuevo_plan: Array) -> void:
	plan = nuevo_plan
	indice = 0

func paso(agente: Node) -> bool:
	# Devuelve true cuando el plan terminó.
	if indice >= plan.size():
		return true
	var accion: AccionGOAP = plan[indice]
	# Aquí conectarías cada nombre de acción con su comportamiento real:
	match accion.nombre:
		"recoger_arma": pass    # mover al arma y recogerla
		"acercarse_jugador": pass  # navegar hacia el jugador
		"atacar": pass          # disparar
	print("Ejecutando: ", accion.nombre)
	indice += 1
	return indice >= plan.size()
```

## ✍️ Ejercicios

1. Añade una acción `buscar_municion` (precond `tiene_municion:false`, efecto `true`) y haz que `atacar` la requiera.
2. Sube el coste de `acercarse_jugador` a 5 y comprueba si aparece una ruta alternativa más barata.
3. Introduce dos armas: una cercana barata y otra lejana potente; deja que el coste decida.
4. Haz que el planner devuelva también el coste total del plan.
5. Invalida el plan a mitad de ejecución (el jugador huye) y fuerza un re-planeo.
6. Sustituye la firma `str(estado)` por un hash propio y mide si acelera.

## 📝 Reto verificable

Amplía el mini-GOAP a **al menos cinco acciones** (incluye recoger munición y buscar cobertura) y define dos objetivos distintos: "eliminar al jugador" y "sobrevivir" (`a_salvo: true`). El planner debe producir planes válidos y diferentes para cada objetivo desde el mismo estado inicial.

**Criterio de aceptación**: para el objetivo "eliminar al jugador" el plan termina en `atacar` con todas las precondiciones satisfechas en orden; para "sobrevivir" el plan no incluye `atacar`; y cambiar el estado inicial acorta el plan sin modificar las definiciones de acciones.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El planner nunca encuentra plan | Ningún efecto produce el hecho del objetivo. Verifica que alguna acción lo genere. |
| Bucle infinito / cuelgue | No marcas estados visitados. Registra la firma del estado y descártalos. |
| El plan repite acciones sin sentido | Efectos que no cambian el estado (ya estaba en ese valor). Asegura que aporten progreso. |
| Muta el estado original | Aplicaste efectos sin `duplicate(true)`. Trabaja siempre sobre copias. |
| Plan subóptimo | Ignoras el coste y sacas el primer nodo. Ordena la frontera por coste. |

## ❓ Preguntas frecuentes

**¿GOAP o Behavior Tree?** El BT es explícito y predecible (tú diseñas la lógica); GOAP es emergente (defines piezas y el planner las combina). GOAP brilla cuando hay muchas formas de lograr un objetivo.

**¿Es caro planificar cada frame?** Sí; se planifica solo al cambiar el objetivo o cuando el plan se invalida, no en cada frame.

**¿Cómo represento estados no booleanos (munición=7)?** Con GOAP clásico se discretiza (`tiene_municion: bool`); variantes numéricas existen pero complican la búsqueda.

**¿Por qué F.E.A.R. usó GOAP?** Para que enemigos con las mismas acciones mostraran tácticas variadas (flanquear, cubrirse) sin scripts a medida por escenario.

## 🔗 Referencias

- Orkin — GOAP y la IA de F.E.A.R.: <https://alumni.media.mit.edu/~jorkin/goap.html>
- Game AI Pro — capítulos sobre GOAP: <http://www.gameaipro.com/>
- Godot Docs — Dictionary: <https://docs.godotengine.org/en/stable/classes/class_dictionary.html>
- Godot Docs — RefCounted: <https://docs.godotengine.org/en/stable/classes/class_refcounted.html>

## ⬅️ Clase anterior

[Clase 117 - Toma de decisiones: utility AI](../117-toma-de-decisiones-utility-ai/README.md)

## ➡️ Siguiente clase

[Clase 119 - IA de combate: cobertura, flanqueo y coordinación](../119-ia-de-combate-cobertura-flanqueo-y-coordinacion/README.md)
