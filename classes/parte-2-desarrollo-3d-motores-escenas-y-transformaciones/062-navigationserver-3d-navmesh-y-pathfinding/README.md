# Clase 062 — NavigationServer 3D: navmesh y pathfinding

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot Engine 4.x — 3D navigation overview*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dar a los enemigos la capacidad de moverse inteligentemente por el nivel. Aprenderás a hornear (bake) un navmesh con `NavigationRegion3D`, a usar `NavigationAgent3D` para calcular rutas y a mover un enemigo que persigue al jugador con `get_next_path_position()`, respetando obstáculos.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar qué es un navmesh y por qué evita el pathfinding sobre geometría cruda.
- Configurar un `NavigationRegion3D` y hornear la malla de navegación del nivel.
- Añadir un `NavigationAgent3D` a un enemigo y fijar su `target_position`.
- Mover al enemigo hacia el objetivo con `get_next_path_position()` e `is_navigation_finished()`.
- Añadir obstáculos que el pathfinding esquiva al recalcular la ruta.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Navmesh | Representación caminable del nivel |
| 2 | NavigationRegion3D | Nodo que contiene y hornea el navmesh |
| 3 | Bake del navmesh | Genera la malla a partir de la geometría |
| 4 | NavigationAgent3D | Calcula la ruta y el siguiente punto |
| 5 | target_position | Destino que el agente persigue |
| 6 | get_next_path_position | Punto intermedio hacia el que moverse |
| 7 | Obstáculos | Bloqueos estáticos y dinámicos |
| 8 | avoidance | Evitar otros agentes en movimiento |

## 📖 Definiciones y características

- **Navmesh (navigation mesh)**: superficie poligonal que marca dónde se puede caminar. Clave: el pathfinding corre sobre ella, no sobre toda la geometría.
- **NavigationRegion3D**: nodo que aloja un `NavigationMesh` y participa en la red de navegación. Clave: se hornea desde el editor o por código.
- **Bake**: proceso que genera el navmesh a partir de la geometría fuente y parámetros (radio del agente, pendiente máxima). Clave: rehazlo si cambias el nivel.
- **NavigationAgent3D**: nodo hijo del enemigo que resuelve la ruta hacia `target_position`. Clave: no mueve al enemigo; te da el siguiente punto.
- **target_position**: destino en coordenadas globales. Clave: actualízalo para perseguir un objetivo móvil.
- **get_next_path_position()**: siguiente punto del camino hacia el que avanzar. Clave: calcula la dirección restando la posición actual.
- **is_navigation_finished()**: indica si el agente llegó al destino. Clave: detén el movimiento cuando sea true.
- **NavigationObstacle3D**: obstáculo dinámico que los agentes evitan. Clave: para bloqueos que se mueven en runtime.

## 🧰 Herramientas y preparación

Godot 4.x con un nivel 3D (suelo y muros estáticos, como el de la clase 057). El personaje jugador servirá como objetivo. Ten a mano un enemigo simple (`CharacterBody3D` con cápsula y malla). Como la navegación se actualiza en física, usaremos `_physics_process`. Consulta [3D navigation overview](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_3d.html) y [Using NavigationAgents](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html).

## 🧪 Laboratorio guiado

Hornearemos un navmesh y haremos que un enemigo persiga al jugador esquivando muros.

**1) Crear la región de navegación.** Añade un `NavigationRegion3D` como padre de la geometría caminable (suelo y muros). En su propiedad `NavigationMesh`, crea un nuevo `NavigationMesh`. Ajusta `Agent > Radius` (~0.5, el radio del enemigo) y `Agent > Max Slope` (~45°).

**2) Hornear.** Con el `NavigationRegion3D` seleccionado, pulsa **Bake NavigationMesh** en la barra superior del editor. Verás una superficie azul cubriendo el suelo transitable, con huecos alrededor de los muros. Si mueves geometría, vuelve a hornear.

**3) El enemigo.** Crea `Enemigo` (`CharacterBody3D`) con `CollisionShape3D` (cápsula), un `MeshInstance3D` y, como hijo, un `NavigationAgent3D`. En el agente ajusta `Path Desired Distance` y `Target Desired Distance` (~0.5).

**4) Script de persecución.** Adjunta al `Enemigo`:

```gdscript
extends CharacterBody3D

@export var velocidad := 3.5
@export var gravedad := 20.0
@export var objetivo_path: NodePath  # el jugador
@onready var agente: NavigationAgent3D = $NavigationAgent3D

var _objetivo: Node3D

func _ready() -> void:
	_objetivo = get_node(objetivo_path)
	# Esperar un frame a que la navegación esté lista
	await get_tree().physics_frame

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravedad * delta
	else:
		velocity.y = 0.0

	if _objetivo:
		agente.target_position = _objetivo.global_position

	if agente.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var siguiente := agente.get_next_path_position()
	var dir := (siguiente - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	velocity.x = dir.x * velocidad
	velocity.z = dir.z * velocidad

	# Mirar hacia donde se mueve
	if dir.length() > 0.01:
		look_at(global_position + dir, Vector3.UP)

	move_and_slide()
```

Asigna en `objetivo_path` la ruta al jugador.

**5) Observable.** El enemigo rodea los muros para alcanzar al jugador en lugar de empotrarse contra ellos; si mueves al jugador, recalcula la ruta y lo sigue. Al llegar cerca, se detiene (`is_navigation_finished()`).

**6) Obstáculo dinámico.** Añade un `NavigationObstacle3D` a una caja móvil; el enemigo ajustará su trayectoria para bordearla sin necesidad de re-hornear.

## ✍️ Ejercicios

1. Reduce el `Agent > Radius` del navmesh y observa cómo el enemigo pasa por huecos más estrechos.
2. Añade un segundo enemigo y activa `avoidance` en ambos agentes para que no se solapen.
3. Dibuja el path actual leyendo `agente.get_current_navigation_path()` en un `ImmediateMesh` o con prints.
4. Haz que el enemigo patrulle entre dos puntos cuando el jugador está lejos y persiga cuando está cerca.
5. Sube `Max Slope` y añade una rampa; comprueba que el navmesh la incluye tras re-hornear.
6. Detén la persecución si no hay ruta válida (`agente.is_target_reachable()` es false).

## 📝 Reto verificable

Monta un nivel con al menos dos muros y un obstáculo, hornea el navmesh y crea un enemigo que persiga al jugador esquivando los muros, se detenga al alcanzarlo y reanude la persecución si el jugador se aleja.

**Criterio de aceptación**: el enemigo nunca atraviesa muros, rodea el obstáculo para llegar al jugador, se detiene a la distancia deseada al alcanzarlo y vuelve a moverse cuando el jugador se aparta; al depurar, la ruta cambia al mover al jugador.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El enemigo no se mueve | Navmesh sin hornear o agente sin `target_position`. Hornea y fija el destino cada frame. |
| Atraviesa muros igualmente | La geometría de los muros no estaba bajo el `NavigationRegion3D` al hornear. Reorganiza y re-hornea. |
| Se mueve pero llega tarde/erra | Lees `get_next_path_position()` sin esperar a que la nav esté lista. Usa `await get_tree().physics_frame` en `_ready`. |
| Vibra al llegar | `Target Desired Distance` muy pequeña. Súbela un poco. |
| Ignora un obstáculo móvil | Falta `NavigationObstacle3D` o `avoidance` desactivado. Añádelo/actívalo. |

## ❓ Preguntas frecuentes

**¿Debo re-hornear siempre que muevo algo?** Para cambios estáticos, sí. Para obstáculos que se mueven en runtime, usa `NavigationObstacle3D` en vez de re-hornear.

**¿El agente mueve al personaje?** No; solo calcula el camino. Tú aplicas la velocidad y llamas a `move_and_slide()`.

**¿Por qué falla en el primer frame?** El servidor de navegación se sincroniza en física; espera un `physics_frame` antes de pedir rutas.

**¿Cómo evito que dos enemigos se pisen?** Activa `avoidance` en sus `NavigationAgent3D` y ajusta sus radios.

## 🔗 Referencias

- [3D navigation overview — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_3d.html)
- [Using NavigationAgents — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html)
- [NavigationRegion3D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_navigationregion3d.html)

## ➡️ Siguiente clase

[Clase 063 - Áreas, triggers y detección en 3D](../063-areas-triggers-y-deteccion-en-3d/README.md)
