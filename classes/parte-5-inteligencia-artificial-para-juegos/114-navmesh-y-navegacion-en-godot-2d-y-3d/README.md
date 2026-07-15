# Clase 114 — Navmesh y navegación en Godot (2D y 3D)

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Documentación oficial de Godot 4 — Navigation (NavigationServer2D/3D) + Millington, "AI for Games" (3ª ed., cap. Pathfinding)*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Aprender a mover agentes por un escenario usando el sistema de navegación nativo de Godot 4. Al terminar sabrás **hornear (bake)** una malla de navegación con `NavigationRegion2D`/`NavigationRegion3D`, mover un agente con `NavigationAgent2D`/`NavigationAgent3D` siguiendo la ruta calculada por el servidor, activar la **evitación local** para esquivar obstáculos, y decidir cuándo conviene un navmesh frente a una búsqueda A* sobre grilla.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Hornear una malla de navegación en 2D y en 3D a partir de la geometría de la escena.
- Configurar un `NavigationAgent` con `target_position` y consumir `get_next_path_position()` en `_physics_process`.
- Activar `avoidance_enabled` y resolver el movimiento mediante la señal `velocity_computed`.
- Introducir obstáculos dinámicos con `NavigationObstacle` y conectar zonas con `NavigationLink`.
- Explicar la diferencia conceptual entre un navmesh de polígonos y un A* sobre grilla.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Malla de navegación (navmesh) | Es la representación caminable del mundo sobre la que se calcula toda ruta |
| 2 | Bake de `NavigationRegion` | Sin hornear, el agente no tiene superficie donde moverse |
| 3 | `NavigationAgent` y rutas | Traduce un destino en una secuencia de puntos alcanzables |
| 4 | Evitación local (avoidance) | Evita que varios agentes o obstáculos se atraviesen entre sí |
| 5 | Obstáculos dinámicos | Permite bloquear zonas en tiempo real sin re-hornear todo |
| 6 | Enlaces de navegación (links) | Conectan islas separadas: saltos, escaleras, teletransportes |
| 7 | Navmesh vs A* de grilla | Elegir la técnica correcta según el tipo de mapa |

## 📖 Definiciones y características

- **Navmesh**: conjunto de polígonos convexos que describen el área transitable. Clave: la ruta se calcula entre polígonos, no celda a celda.
- **NavigationRegion2D/3D**: nodo que contiene un navmesh y lo registra en el `NavigationServer`. Clave: se hornea desde el editor o por código con `bake_navigation_mesh()`.
- **NavigationAgent2D/3D**: nodo hijo del personaje que pide la ruta al servidor y la entrega punto a punto. Clave: no mueve nada por sí mismo, solo aconseja la siguiente posición.
- **target_position**: propiedad del agente con el destino global deseado. Clave: al asignarla se recalcula la ruta de forma asíncrona.
- **Avoidance**: capa de evitación local (basada en RVO) que ajusta la velocidad para no colisionar. Clave: separa "hacia dónde ir" (ruta) de "cómo llegar sin chocar" (velocidad segura).
- **NavigationObstacle2D/3D**: define un área que los agentes con avoidance deben rodear. Clave: ideal para obstáculos móviles sin re-bake.
- **NavigationLink2D/3D**: conexión explícita entre dos puntos que el navmesh no une por sí solo. Clave: habilita rutas discontinuas.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x** (estable). Trabajaremos con dos escenas separadas: una 2D y una 3D. Ten a mano la documentación de [NavigationServer2D](https://docs.godotengine.org/en/stable/classes/class_navigationserver2d.html), [NavigationAgent2D](https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html) y la guía [Using NavigationAgents](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html). Crea una carpeta `res://ia/navegacion/` para los scripts. En **Project Settings → Navigation** puedes activar la visualización de depuración para ver los polígonos horneados.

## 🧪 Laboratorio guiado

Construiremos un agente 2D que persigue al cursor esquivando un obstáculo móvil, y luego replicaremos la idea en 3D.

### Paso 1 — Escena 2D y bake del navmesh

Crea una escena con esta jerarquía:

```text
Mundo2D (Node2D)
├── NavigationRegion2D
│   └── (polígono horneado)
├── Agente (CharacterBody2D)
│   └── NavigationAgent2D
└── ObstaculoMovil (NavigationObstacle2D dentro de un Node2D)
```

En `NavigationRegion2D` crea un nuevo `NavigationPolygon` en el inspector, dibuja el contorno del área caminable (deja un hueco central) y pulsa **Bake NavigationPolygon**. Verás el polígono relleno: esa es la superficie transitable.

### Paso 2 — Script del agente con evitación

```gdscript
extends CharacterBody2D

@export var velocidad: float = 220.0
@onready var agente: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	# La ruta se calcula en el servidor; esperamos un frame para que exista.
	agente.avoidance_enabled = true
	agente.radius = 16.0
	# Al terminar el cálculo de evitación, el servidor nos da una velocidad segura.
	agente.velocity_computed.connect(_on_velocidad_calculada)

func _physics_process(_delta: float) -> void:
	# El destino es la posición del ratón en coordenadas globales.
	agente.target_position = get_global_mouse_position()

	if agente.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var siguiente: Vector2 = agente.get_next_path_position()
	var deseada: Vector2 = (siguiente - global_position).normalized() * velocidad
	# En vez de mover directamente, entregamos la velocidad deseada al sistema de evitación.
	agente.set_velocity(deseada)

func _on_velocidad_calculada(velocidad_segura: Vector2) -> void:
	# Esta velocidad ya rodea obstáculos y otros agentes.
	velocity = velocidad_segura
	move_and_slide()
```

Ejecuta y mueve el ratón: el agente sigue la ruta horneada. Observable: al pasar cerca del obstáculo, **lo rodea** en vez de atravesarlo.

### Paso 3 — Obstáculo dinámico

Da movimiento al obstáculo para comprobar la evitación en tiempo real:

```gdscript
extends Node2D
# Nodo que contiene un NavigationObstacle2D con su 'radius' configurado.

@export var amplitud: float = 140.0
@export var velocidad: float = 1.5
var _base: Vector2

func _ready() -> void:
	_base = position

func _process(delta: float) -> void:
	# Vaivén horizontal: el agente debe re-esquivarlo cada frame.
	var t: float = Time.get_ticks_msec() / 1000.0
	position.x = _base.x + sin(t * velocidad) * amplitud
```

### Paso 4 — Versión 3D

En una escena 3D, usa `NavigationRegion3D` con un `NavigationMesh`. Añade suelo y paredes como `MeshInstance3D` hijos y pulsa **Bake NavigationMesh**. El agente cambia poco:

```gdscript
extends CharacterBody3D

@export var velocidad: float = 4.0
@onready var agente: NavigationAgent3D = $NavigationAgent3D
@export var objetivo: Node3D  # asigna un Marker3D en el inspector

func _ready() -> void:
	agente.avoidance_enabled = true
	agente.velocity_computed.connect(_on_velocidad_calculada)

func _physics_process(_delta: float) -> void:
	agente.target_position = objetivo.global_position
	if agente.is_navigation_finished():
		return
	var siguiente: Vector3 = agente.get_next_path_position()
	var deseada: Vector3 = (siguiente - global_position).normalized() * velocidad
	agente.set_velocity(deseada)

func _on_velocidad_calculada(velocidad_segura: Vector3) -> void:
	velocity = velocidad_segura
	move_and_slide()
```

Observable: el agente 3D camina desde su posición hasta el `Marker3D` rodeando muros.

## ✍️ Ejercicios

1. Cambia el `radius` del agente 2D a 40 y observa cómo mantiene mayor distancia de los obstáculos.
2. Añade un segundo agente idéntico y comprueba que la evitación impide que se solapen.
3. Coloca dos plataformas 2D separadas por un hueco y únelas con un `NavigationLink2D`.
4. Re-hornea el navmesh 3D tras añadir una columna nueva y verifica que el agente la rodea.
5. Sustituye el `target_position` del ratón por clics: fija el destino solo al hacer clic izquierdo.
6. Mide el tiempo de ruta añadiendo un `print` de `agente.get_current_navigation_path().size()`.

## 📝 Reto verificable

Crea un nivel 2D con **tres salas** conectadas por pasillos y un `NavigationLink2D` que represente una "puerta secreta" entre la primera y la tercera sala. Un agente debe navegar de la sala 1 a la sala 3, y un obstáculo móvil en el pasillo central debe forzar la evitación al menos una vez.

**Criterio de aceptación**: al ejecutar, el agente llega a la sala 3 usando el enlace secreto cuando este ofrece la ruta más corta, nunca atraviesa el obstáculo móvil, y `is_navigation_finished()` devuelve `true` al llegar.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El agente no se mueve | Olvidaste hornear la región o el destino cae fuera del navmesh. Re-bake y verifica que `target_position` esté sobre el polígono. |
| El agente atraviesa obstáculos | `avoidance_enabled` está en `false` o no usas `velocity_computed`. Actívalo y mueve solo dentro del callback. |
| Movimiento tembloroso | Estás moviendo con `get_next_path_position` **y** con la velocidad de evitación a la vez. Usa solo la ruta del callback. |
| La ruta ignora el enlace | El `NavigationLink` no comparte capas (`navigation_layers`) con el agente. Iguala las capas. |
| `get_next_path_position` devuelve la posición actual | Pediste la ruta el mismo frame que asignaste el destino. Espera un frame físico o usa `await`. |

## ❓ Preguntas frecuentes

**¿El navmesh se re-hornea solo si muevo geometría?** No. El bake es un proceso explícito; para cambios en tiempo real usa `NavigationObstacle` o re-hornea por código.

**¿Puedo usar `move_and_slide()` sin avoidance?** Sí. Sin evitación, mueves directamente con la velocidad hacia `get_next_path_position()`; los choques los resuelve la física de colisión, no el navegador.

**¿Cuándo prefiero A* de grilla en vez de navmesh?** En mapas de celdas (tácticos por turnos, tower defense) donde el movimiento es discreto; el navmesh brilla en espacios continuos y abiertos.

**¿La evitación garantiza que nunca haya colisiones?** No al 100%. Es una capa local predictiva; combínala con cuerpos de colisión para casos extremos.

## 🔗 Referencias

- Godot Docs — Navigation overview: <https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_2d.html>
- Godot Docs — Using NavigationAgents: <https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html>
- Godot Docs — Using NavigationObstacles: <https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationobstacles.html>
- Godot Docs — Using NavigationLinks: <https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationlinks.html>

## ⬅️ Clase anterior

[Clase 113 - Pathfinding: A* explicado y aplicado](../113-pathfinding-a-estrella-explicado-y-aplicado/README.md)

## ➡️ Siguiente clase

[Clase 115 - Steering y evitación de obstáculos (flocking)](../115-steering-y-evitacion-de-obstaculos-flocking/README.md)
