# Clase 113 — Pathfinding: A* explicado y aplicado

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Ian Millington, "Artificial Intelligence for Games" (2ª ed.) + Amit Patel, "Red Blob Games: Introduction to A*"*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Entender el algoritmo de búsqueda de caminos más importante de los videojuegos —**A\*** (A estrella)— desde su base matemática hasta su aplicación práctica. Al terminar sabrás qué son el coste `g`, la heurística `h` y la función `f = g + h`, por qué la heurística debe ser **admisible**, y habrás implementado A\* sobre una grilla con `AStarGrid2D` de Godot 4, moviendo un agente por el camino calculado mientras esquiva muros y visualizas la ruta en pantalla.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar los conceptos de grafo, coste g, heurística h y f = g + h.
- Justificar por qué una heurística admisible garantiza el camino óptimo.
- Configurar y consultar `AStarGrid2D` para obtener un camino en una grilla.
- Mover un `CharacterBody2D` siguiendo el camino punto a punto.
- Visualizar la ruta calculada y los muros para depurar.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Grafos y grillas | A* opera sobre nodos conectados por aristas |
| 2 | Coste g (recorrido real) | Mide lo que ya costó llegar a un nodo |
| 3 | Heurística h (estimación) | Guía la búsqueda hacia el objetivo |
| 4 | f = g + h | El criterio con que A* elige el siguiente nodo |
| 5 | Admisibilidad | Condición para que el camino sea óptimo |
| 6 | AStarGrid2D | La implementación lista de Godot para grillas |
| 7 | Seguir el camino | Convertir una lista de puntos en movimiento |

## 📖 Definiciones y características

- **Grafo**: conjunto de nodos unidos por aristas con coste. Clave: una grilla de baldosas es un grafo donde cada celda es un nodo.
- **Coste g**: coste real acumulado desde el inicio hasta un nodo. Clave: se conoce con certeza, no se estima.
- **Heurística h**: estimación del coste restante hasta la meta. Clave: guía la búsqueda; Manhattan o euclídea son típicas.
- **Función f**: `f = g + h`, prioridad de exploración de un nodo. Clave: A* expande siempre el nodo con menor `f`.
- **Admisibilidad**: la heurística nunca sobreestima el coste real. Clave: si se cumple, A* encuentra el camino óptimo.
- **AStarGrid2D**: clase de Godot que resuelve A* sobre una grilla rectangular. Clave: marcas celdas sólidas y pides el camino.
- **AStar2D/AStar3D**: variantes para grafos arbitrarios de puntos. Clave: úsalas cuando la topología no es una grilla regular.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x. Trabajaremos en 2D con una grilla lógica: define un tamaño de celda (por ejemplo 32 px) y un tamaño de grilla (por ejemplo 20×15). El agente será un `CharacterBody2D`. Para visualizar, usaremos `_draw()` en un `Node2D` que pinte los muros y la ruta. Repasa la clase [AStarGrid2D](https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html) y, para la teoría, la excelente guía interactiva de [Red Blob Games sobre A*](https://www.redblobgames.com/pathfinding/a-star/introduction.html). No necesitas navmesh para este laboratorio: la grilla es toda tu representación del mundo.

## 🧪 Laboratorio guiado

Implementaremos A\* con `AStarGrid2D`, marcaremos muros, pediremos un camino y moveremos un agente por él, dibujando la ruta.

**Paso 1 — Escena.** Crea un `Node2D` raíz `Mundo`. Añade un `CharacterBody2D` `Agente` con `Sprite2D` y `CollisionShape2D`. El dibujo de la grilla lo hará el propio `Mundo` con `_draw()`.

**Paso 2 — Configurar AStarGrid2D.** En el script del `Mundo`, crea la grilla, define su región y celda, marca algunos muros como sólidos y actualiza:

```gdscript
extends Node2D

const TAM_CELDA := 32
const COLUMNAS := 20
const FILAS := 15

var astar: AStarGrid2D
var muros: Array[Vector2i] = [
	Vector2i(5, 3), Vector2i(5, 4), Vector2i(5, 5), Vector2i(5, 6),
	Vector2i(5, 7), Vector2i(10, 8), Vector2i(11, 8), Vector2i(12, 8),
]
var camino: PackedVector2Array = []

func _ready() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, COLUMNAS, FILAS)
	astar.cell_size = Vector2(TAM_CELDA, TAM_CELDA)
	# Diagonal permitida solo si ambas celdas ortogonales están libres.
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	# Heurística Manhattan: admisible en grillas sin diagonales baratas.
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()   # obligatorio antes de marcar sólidos y pedir caminos

	for celda in muros:
		astar.set_point_solid(celda, true)

	_calcular_camino(Vector2i(1, 1), Vector2i(18, 12))
```

**Paso 3 — Pedir el camino.** `get_point_path` devuelve los puntos en coordenadas de mundo (centrados por `cell_size`):

```gdscript
func _calcular_camino(desde: Vector2i, hasta: Vector2i) -> void:
	if astar.is_in_boundsv(desde) and astar.is_in_boundsv(hasta):
		camino = astar.get_point_path(desde, hasta)
		queue_redraw()   # repinta para mostrar la nueva ruta
```

**Paso 4 — Visualizar grilla, muros y ruta.** El `_draw()` hace observable todo el algoritmo:

```gdscript
func _draw() -> void:
	# Muros en gris oscuro
	for celda in muros:
		var r := Rect2(Vector2(celda) * TAM_CELDA, Vector2(TAM_CELDA, TAM_CELDA))
		draw_rect(r, Color(0.2, 0.2, 0.2))
	# Ruta como línea y puntos verdes
	if camino.size() > 1:
		draw_polyline(camino, Color.LIME_GREEN, 3.0)
		for p in camino:
			draw_circle(p, 4.0, Color.YELLOW)
```

**Paso 5 — Mover el agente por el camino.** Adjunta este script al `Agente`, pasándole el camino desde el `Mundo` (o expón un método). Sigue punto a punto:

```gdscript
extends CharacterBody2D

@export var velocidad: float = 120.0
var ruta: PackedVector2Array = []
var indice: int = 0

func seguir(nueva_ruta: PackedVector2Array) -> void:
	ruta = nueva_ruta
	indice = 0
	if ruta.size() > 0:
		global_position = ruta[0]

func _physics_process(_delta: float) -> void:
	if indice >= ruta.size():
		velocity = Vector2.ZERO
		return
	var objetivo := ruta[indice]
	if global_position.distance_to(objetivo) < 4.0:
		indice += 1   # llegó a este waypoint, va al siguiente
	else:
		velocity = global_position.direction_to(objetivo) * velocidad
	move_and_slide()
```

**Paso 6 — Conectar todo.** En `_ready` del `Mundo`, tras calcular el camino, llama a `$Agente.seguir(camino)`. Ejecuta: verás la grilla con muros grises, la ruta verde con nodos amarillos rodeando los muros, y el agente recorriéndola.

**Resultado visible:** una ruta A\* dibujada en verde que esquiva los muros, y un agente que la recorre de inicio a fin sin atravesar obstáculos.

## ✍️ Ejercicios

1. Cambia la heurística a `HEURISTIC_EUCLIDEAN` y observa si la ruta cambia con diagonales.
2. Recalcula el camino en tiempo real hacia la posición del ratón al hacer clic.
3. Añade más muros formando un laberinto y comprueba que A* lo resuelve.
4. Pinta de otro color el nodo inicial y el final en `_draw()`.
5. Prohíbe las diagonales (`DIAGONAL_MODE_NEVER`) y compara la longitud de la ruta.
6. Mide e imprime cuántos puntos tiene el camino en dos configuraciones distintas.

## 📝 Reto verificable

Construye un mapa en grilla con al menos un obstáculo en forma de "U" que obligue a rodear, calcula la ruta con `AStarGrid2D`, dibújala y haz que un agente la recorra. El objetivo debe poder elegirse con un clic del ratón y la ruta debe recalcularse.

**Criterio de aceptación**: al hacer clic en una celda libre, se dibuja una ruta que rodea la "U" sin atravesar muros y el agente la sigue hasta el final. Si haces clic sobre un muro o fuera de la grilla, el programa no falla (se ignora o se avisa).

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| `get_point_path` devuelve vacío | No llamaste a `astar.update()` tras configurar la región |
| Los muros no bloquean | Marcaste sólidos antes de `update()`; márcalos después |
| El agente atraviesa muros | Sigues el destino directo en vez de los waypoints del camino |
| Error "point out of bounds" | Coordenada fuera de `region`; valida con `is_in_boundsv` |
| La ruta usa diagonales imposibles | Modo diagonal permisivo; usa `DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES` |
| La heurística sobreestima y la ruta es rara | Elegiste una heurística no admisible para tu métrica; usa Manhattan sin diagonales |

## ❓ Preguntas frecuentes

**¿Qué diferencia hay entre A* y Dijkstra?**
Dijkstra explora por coste real (`g`) sin dirección; A* añade la heurística `h` para dirigirse a la meta, por lo que suele expandir muchos menos nodos.

**¿Cuándo uso AStarGrid2D y cuándo AStar2D?**
`AStarGrid2D` para grillas regulares (tilemaps). `AStar2D`/`AStar3D` para grafos arbitrarios: waypoints dispersos, mallas de navegación de puntos, mapas hexagonales.

**¿Qué significa que la heurística sea admisible?**
Que nunca sobreestima el coste real restante. Si se cumple, A* garantiza la ruta más corta; si se viola, puede encontrar una peor.

**¿A* recalcula toda la ruta cada vez que me muevo?**
En su forma básica sí. Para objetivos móviles se recalcula periódicamente o se usan variantes incrementales; en Godot suele bastar recalcular cuando el destino cambia de celda.

## 🔗 Referencias

- [AStarGrid2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html)
- [AStar2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_astar2d.html)
- [Red Blob Games — Introduction to A*](https://www.redblobgames.com/pathfinding/a-star/introduction.html)
- [Amit's A* Pages (Stanford)](http://theory.stanford.edu/~amitp/GameProgramming/)

## ⬅️ Clase anterior

[Clase 112 - Behavior Trees: construir un enemigo completo](../112-behavior-trees-construir-un-enemigo-completo/README.md)

## ➡️ Siguiente clase

[Clase 114 - Navmesh y navegación en Godot (2D y 3D)](../114-navmesh-y-navegacion-en-godot-2d-y-3d/README.md)
