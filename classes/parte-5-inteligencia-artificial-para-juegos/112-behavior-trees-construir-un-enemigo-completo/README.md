# Clase 112 — Behavior Trees: construir un enemigo completo

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Steve Rabin, "Game AI Pro" + Documentación de navegación de Godot 4*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Poner el mini-framework de behavior trees de la clase 111 a gobernar un enemigo real y completo en Godot 4. Al terminar tendrás un `CharacterBody2D` cuyo comportamiento (patrullar, perseguir, atacar y buscar la última posición vista) lo decide un behavior tree, con condiciones de percepción (¿ve al jugador?, ¿está en rango?) y un **blackboard** compartido que comunica datos entre nodos e integra el movimiento con navegación.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Diseñar el behavior tree de un enemigo con prioridades claras.
- Implementar un blackboard como memoria compartida entre nodos.
- Escribir condiciones de percepción y acciones de movimiento como hojas del BT.
- Integrar el BT con `NavigationAgent2D` para desplazamientos con rutas.
- Depurar el enemigo trazando qué rama del árbol se ejecuta.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Blackboard compartido | Es la memoria común que usan todas las hojas |
| 2 | Condiciones de percepción | Alimentan las decisiones del árbol con datos del mundo |
| 3 | Acciones de movimiento | Traducen la decisión en desplazamiento real |
| 4 | Prioridades con Selector | Ataque > persecución > búsqueda > patrulla |
| 5 | Última posición vista | Da al enemigo memoria creíble tras perderte |
| 6 | Integración con NavigationAgent2D | Permite rodear obstáculos, no ir en línea recta |
| 7 | Tick por frame en _physics_process | Conecta el árbol con el bucle del juego |

## 📖 Definiciones y características

- **Blackboard**: diccionario compartido donde el BT guarda y lee datos (objetivo, última posición). Clave: desacopla las hojas entre sí.
- **Condición de percepción**: hoja que consulta el mundo (visión, distancia) y devuelve SUCCESS/FAILURE. Clave: es el "sentir" del bucle.
- **Acción de movimiento**: hoja que fija `velocity` y devuelve RUNNING mientras se desplaza. Clave: es el "actuar".
- **Selector de prioridades**: composite raíz que ordena comportamientos de mayor a menor urgencia. Clave: define la personalidad del enemigo.
- **Última posición vista**: punto guardado en el blackboard al perder al jugador. Clave: sustituye la omnisciencia por memoria.
- **NavigationAgent2D**: nodo que calcula la ruta hacia `target_position`. Clave: `get_next_path_position()` da el siguiente punto a seguir.
- **Tick**: evaluación del árbol cada `_physics_process`. Clave: sincroniza IA y física.

## 🧰 Herramientas y preparación

Reutiliza el mini-framework de BT (`bt.gd`, `secuencia.gd`, `selector.gd`, `hojas.gd`, `accion.gd`) de la clase 111. Necesitas Godot 4.x, una escena 2D con muros con colisión y una `NavigationRegion2D` con su polígono horneado (bake) para que la navegación funcione. El enemigo será un `CharacterBody2D` con `RayCast2D`, `NavigationAgent2D` y el jugador en el grupo `player`. Repasa [NavigationAgent2D](https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html) y la guía de [navegación 2D de Godot](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_2d.html). Si aún no horneaste el navmesh, la siguiente clase lo cubre en detalle; aquí basta un polígono simple sobre el suelo transitable.

## 🧪 Laboratorio guiado

El enemigo tendrá esta lógica de prioridades: **si está en rango, ataca; si no, si ve al jugador lo persigue; si lo perdió, va a la última posición vista; si no, patrulla.**

**Paso 1 — Escena.** Crea `NavigationRegion2D` con su `NavigationPolygon` cubriendo el suelo (evitando los muros). Dentro, un `CharacterBody2D` `Enemigo` con `Sprite2D`, `CollisionShape2D`, `RayCast2D` y `NavigationAgent2D`. Coloca al jugador en el grupo `player`.

**Paso 2 — El blackboard.** Un simple `Dictionary` basta. Lo llenamos con percepción cada tick y las hojas lo leen:

```gdscript
extends CharacterBody2D

@export var velocidad: float = 90.0
@export var rango_vision: float = 250.0
@export var rango_ataque: float = 44.0
@export var puntos_patrulla: Array[Vector2] = []

@onready var vision: RayCast2D = $RayCast2D
@onready var nav: NavigationAgent2D = $NavigationAgent2D

var jugador: Node2D
var blackboard: Dictionary = {}
var arbol: BTNode
var indice_patrulla: int = 0

func _ready() -> void:
	jugador = get_tree().get_first_node_in_group("player")
	nav.target_desired_distance = 8.0
	_construir_arbol()

func _physics_process(_delta: float) -> void:
	_percibir()          # SENTIR: rellena el blackboard
	arbol.tick()         # PENSAR: el BT decide y fija velocity
	move_and_slide()     # ACTUAR
```

**Paso 3 — Percepción hacia el blackboard.** Un solo método actualiza todos los datos que el árbol consultará:

```gdscript
func _percibir() -> void:
	var ve := false
	if jugador:
		var d := global_position.distance_to(jugador.global_position)
		if d <= rango_vision:
			vision.target_position = to_local(jugador.global_position)
			vision.force_raycast_update()
			ve = not vision.is_colliding() or vision.get_collider() == jugador
		blackboard["distancia"] = d
	blackboard["ve_jugador"] = ve
	if ve:
		blackboard["ultima_pos"] = jugador.global_position
```

**Paso 4 — Construir el árbol con hojas.** Usamos `BTSelector`, `BTSequence`, `BTCondition` y `BTAction` con callables que leen el blackboard y mueven al agente:

```gdscript
func _construir_arbol() -> void:
	arbol = BTSelector.new([
		# 1) Atacar si está en rango
		BTSequence.new([
			BTCondition.new(func(): return blackboard.get("distancia", INF) <= rango_ataque),
			BTAction.new(_atacar),
		]) as BTNode,
		# 2) Perseguir si lo ve
		BTSequence.new([
			BTCondition.new(func(): return blackboard.get("ve_jugador", false)),
			BTAction.new(_perseguir),
		]) as BTNode,
		# 3) Ir a la última posición vista
		BTSequence.new([
			BTCondition.new(func(): return blackboard.has("ultima_pos")),
			BTAction.new(_ir_ultima_pos),
		]) as BTNode,
		# 4) Patrullar (comportamiento por defecto)
		BTAction.new(_patrullar) as BTNode,
	])
```

**Paso 5 — Las acciones de movimiento con navegación.** Cada acción fija `velocity` usando la ruta del `NavigationAgent2D` y devuelve un estado del BT:

```gdscript
func _mover_hacia(destino: Vector2) -> void:
	nav.target_position = destino
	if nav.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	var siguiente := nav.get_next_path_position()
	velocity = global_position.direction_to(siguiente) * velocidad

func _atacar() -> BTNode.Estado:
	velocity = Vector2.ZERO
	$Sprite2D.modulate = Color.RED
	return BTNode.Estado.SUCCESS

func _perseguir() -> BTNode.Estado:
	$Sprite2D.modulate = Color.ORANGE
	_mover_hacia(jugador.global_position)
	return BTNode.Estado.RUNNING

func _ir_ultima_pos() -> BTNode.Estado:
	$Sprite2D.modulate = Color.YELLOW
	var destino: Vector2 = blackboard["ultima_pos"]
	_mover_hacia(destino)
	if global_position.distance_to(destino) < 12.0:
		blackboard.erase("ultima_pos")   # llegó y olvida
		return BTNode.Estado.SUCCESS
	return BTNode.Estado.RUNNING

func _patrullar() -> BTNode.Estado:
	$Sprite2D.modulate = Color.WHITE
	if puntos_patrulla.is_empty():
		return BTNode.Estado.SUCCESS
	var destino := puntos_patrulla[indice_patrulla]
	_mover_hacia(destino)
	if global_position.distance_to(destino) < 12.0:
		indice_patrulla = (indice_patrulla + 1) % puntos_patrulla.size()
	return BTNode.Estado.RUNNING
```

**Resultado visible:** un enemigo que patrulla (blanco), te persigue rodeando muros al verte (naranja), se detiene a atacar en rango (rojo) y, cuando te escondes, camina hasta tu última posición conocida (amarillo) antes de volver a patrullar. El color del sprite delata qué rama del árbol manda.

## ✍️ Ejercicios

1. Añade una rama de mayor prioridad "huir" cuando la vida esté baja, con su condición y acción.
2. Guarda en el blackboard un `Timer` de cooldown para que el ataque no sea continuo.
3. Haz que en `_ir_ultima_pos` el enemigo espere unos segundos "buscando" antes de rendirse.
4. Sustituye el color del sprite por un `print` del nombre de la rama activa para depurar.
5. Añade `avoidance_enabled = true` al `NavigationAgent2D` y prueba con dos enemigos.
6. Extrae las acciones a clases `BTAction` propias en vez de callables y compara legibilidad.

## 📝 Reto verificable

Entrega un enemigo gobernado por un behavior tree con blackboard que integre navegación (`NavigationAgent2D`), con al menos cinco comportamientos priorizados (huir, atacar, perseguir, buscar última posición, patrullar) y percepción con `RayCast2D` que respete los muros.

**Criterio de aceptación**: el enemigo demuestra los cinco comportamientos en una partida, rodea obstáculos gracias a la navegación (no atraviesa muros), y la rama activa es identificable (color o log). La última posición vista se usa y se olvida correctamente.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El enemigo va en línea recta y choca con muros | No usas la ruta; muévete hacia `get_next_path_position()`, no hacia el objetivo directo |
| `get_next_path_position()` devuelve la posición actual | El navmesh no está horneado o el `target_position` no cambió; revisa la `NavigationRegion2D` |
| El árbol nunca llega a patrullar | Una condición superior siempre triunfa; revisa el orden del Selector |
| Persigue eternamente aunque te escondas | `ve_jugador` no se recalcula o falta la rama de última posición |
| La navegación no arranca el primer frame | El agente necesita un frame para sincronizar el mapa; espera con `await get_tree().physics_frame` en `_ready` si hace falta |
| Ataca sin parar | Falta cooldown; usa un `Timer` en el blackboard |

## ❓ Preguntas frecuentes

**¿Para qué sirve el blackboard si podría leer todo directo?**
Desacopla las hojas: la percepción escribe una vez y muchas acciones leen. Facilita reutilizar subárboles y probar comportamientos con datos simulados.

**¿Por qué las acciones de movimiento devuelven RUNNING?**
Porque tardan varios frames en completarse. `RUNNING` mantiene la rama activa hasta llegar, sin reiniciar la decisión cada frame.

**¿Puedo mezclar BT con FSM?**
Sí, es común: un BT de alto nivel con hojas que internamente son pequeñas FSM, o al revés. Elige según qué exprese más claro cada parte.

**¿El BT recalcula la ruta cada frame?**
Fijar `target_position` con el mismo valor es barato; el `NavigationAgent2D` recalcula solo cuando cambia el destino o el mapa. Aun así, evita cambiarlo innecesariamente.

## 🔗 Referencias

- [NavigationAgent2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html)
- [Introducción a la navegación 2D — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_2d.html)
- [Game AI Pro — behavior trees y blackboards](http://www.gameaipro.com/)
- [Behavior Trees in Robotics and AI (libro abierto)](https://arxiv.org/abs/1709.00084)

## ➡️ Siguiente clase

[Clase 113 - Pathfinding: A* explicado y aplicado](../113-pathfinding-a-estrella-explicado-y-aplicado/README.md)
