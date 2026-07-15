# Clase 119 — IA de combate: cobertura, flanqueo y coordinación

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Game AI Pro (caps. "Tactical Position Selection" y "Squad Coordination") + charlas GDC sobre IA de shooters*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Construir una IA de combate que se sienta táctica: enemigos que **buscan cobertura** frente al jugador, evalúan **flanqueo**, y se **coordinan como escuadrón** repartiendo permisos de ataque (tokens) para no amontonarse y disparar todos a la vez. Al terminar sabrás puntuar puntos de cobertura con `RayCast`, elegir posiciones de flanco, y usar un gestor de escuadrón que otorga y recupera tokens de ataque.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Evaluar puntos de cobertura según si bloquean la línea del jugador (`RayCast`).
- Elegir la mejor cobertura combinando protección, distancia y flanqueo.
- Implementar un gestor de escuadrón con roles y tokens de ataque limitados.
- Coordinar enemigos para que se turnen al disparar en vez de saturar al jugador.
- Explicar por qué la coordinación por tokens mejora la experiencia de combate.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Puntos de cobertura | Posiciones candidatas donde protegerse |
| 2 | Evaluación de cobertura | Decidir si un punto realmente tapa del jugador |
| 3 | Distancia y ángulo | Ponderar cercanía y flanqueo al elegir |
| 4 | Flanqueo | Atacar desde ángulos que el jugador no cubre |
| 5 | Roles de escuadrón | Repartir funciones (atacante, flanco, reserva) |
| 6 | Tokens de ataque | Limitar cuántos disparan a la vez |
| 7 | Coordinación emergente | Combate que respira y no abruma |

## 📖 Definiciones y características

- **Punto de cobertura**: posición marcada donde un agente puede protegerse. Clave: normalmente `Marker2D` colocados junto a muros.
- **Cobertura válida**: un punto cubre si un `RayCast` desde él hacia el jugador choca con un muro. Clave: se recalcula porque depende de dónde esté el jugador.
- **Flanqueo**: atacar desde un ángulo lateral respecto a la orientación del jugador. Clave: se mide con el ángulo entre el frente del jugador y el vector al enemigo.
- **Gestor de escuadrón**: nodo que conoce a todos los miembros y coordina decisiones. Clave: centraliza los tokens.
- **Token de ataque**: permiso limitado para disparar. Clave: solo N tokens disponibles obligan a turnarse.
- **Rol**: función asignada (atacante, flanco, reserva). Clave: evita que todos hagan lo mismo.
- **Coordinación por tokens**: patrón donde un miembro pide token, ataca y lo devuelve. Clave: el jugador nunca recibe fuego de todos a la vez.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x**. Los enemigos son `CharacterBody2D` con `NavigationAgent2D` (de la clase 114) para moverse a la cobertura, y un `RayCast2D` para validar protección y línea de tiro. El gestor de escuadrón será un `Node` (o autoload). Crea `res://ia/combate/`. Coloca `Marker2D` como puntos de cobertura junto a los muros. Repasa [Marker2D](https://docs.godotengine.org/en/stable/classes/class_marker2d.html) y las señales entre nodos.

## 🧪 Laboratorio guiado

Crearemos tres enemigos que buscan cobertura frente al jugador y se turnan para atacar usando dos tokens.

### Paso 1 — Evaluar puntos de cobertura

Cada punto de cobertura se puntúa según si protege del jugador y su conveniencia:

```gdscript
class_name EvaluadorCobertura
extends RefCounted

# 'puntos' es un Array[Vector2] con posiciones candidatas.
# Devuelve la mejor posición o la actual si ninguna sirve.
static func mejor_cobertura(puntos: Array, desde: Vector2, jugador: Vector2, mundo: World2D) -> Vector2:
	var mejor: Vector2 = desde
	var mejor_score: float = -INF
	for p in puntos:
		if not _protege(p, jugador, mundo):
			continue
		var score: float = _puntuar(p, desde, jugador)
		if score > mejor_score:
			mejor_score = score
			mejor = p
	return mejor

# ¿El muro tapa la línea entre este punto y el jugador?
static func _protege(punto: Vector2, jugador: Vector2, mundo: World2D) -> bool:
	var params := PhysicsRayQueryParameters2D.create(punto, jugador)
	params.collision_mask = 1  # capa de muros
	var hit: Dictionary = mundo.direct_space_state.intersect_ray(params)
	# Protege si el rayo hacia el jugador choca con algo (un muro) por el camino.
	return not hit.is_empty()

static func _puntuar(punto: Vector2, desde: Vector2, jugador: Vector2) -> float:
	# Preferimos cobertura cercana a nosotros y no demasiado lejos del jugador.
	var coste_mov: float = desde.distance_to(punto)
	var dist_jugador: float = punto.distance_to(jugador)
	# Zona de tiro cómoda alrededor de 250 px.
	var comodidad: float = -abs(dist_jugador - 250.0)
	return comodidad - coste_mov * 0.3
```

### Paso 2 — El gestor de escuadrón con tokens

```gdscript
extends Node
class_name Escuadron

@export var tokens_ataque: int = 2  # máximo de atacantes simultáneos
var _tokens_libres: int = 0
var _miembros: Array = []

func _ready() -> void:
	_tokens_libres = tokens_ataque

func registrar(miembro: Node) -> void:
	if miembro not in _miembros:
		_miembros.append(miembro)

# Un miembro pide permiso para atacar.
func pedir_token() -> bool:
	if _tokens_libres > 0:
		_tokens_libres -= 1
		return true
	return false

# Lo devuelve al terminar su ráfaga.
func devolver_token() -> void:
	_tokens_libres = min(_tokens_libres + 1, tokens_ataque)

# Comprueba si una posición flanquea al jugador según su orientación.
func flanquea(pos_enemigo: Vector2, jugador: Node2D) -> bool:
	var hacia: Vector2 = (pos_enemigo - jugador.global_position).normalized()
	var frente: Vector2 = Vector2.RIGHT.rotated(jugador.rotation)
	# Flanqueo si el enemigo está a más de ~60° del frente del jugador.
	return frente.dot(hacia) < 0.5
```

### Paso 3 — El enemigo táctico

```gdscript
extends CharacterBody2D

enum Estado { BUSCAR_COBERTURA, EN_COBERTURA, ATACAR }

@export var jugador: Node2D
@export var escuadron: Escuadron
@export var puntos_cobertura: Array[Node]  # Marker2D en la escena
@export var velocidad: float = 130.0

@onready var agente: NavigationAgent2D = $NavigationAgent2D
var _estado: int = Estado.BUSCAR_COBERTURA
var _tiene_token: bool = false

func _ready() -> void:
	escuadron.registrar(self)

func _physics_process(_delta: float) -> void:
	match _estado:
		Estado.BUSCAR_COBERTURA:
			_ir_a_cobertura()
		Estado.EN_COBERTURA:
			_evaluar_ataque()
		Estado.ATACAR:
			_atacar()

func _ir_a_cobertura() -> void:
	var pos: Array = puntos_cobertura.map(func(m): return m.global_position)
	var destino: Vector2 = EvaluadorCobertura.mejor_cobertura(
		pos, global_position, jugador.global_position, get_world_2d())
	agente.target_position = destino
	if agente.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		_estado = Estado.EN_COBERTURA
		return
	var siguiente: Vector2 = agente.get_next_path_position()
	velocity = (siguiente - global_position).normalized() * velocidad
	move_and_slide()

func _evaluar_ataque() -> void:
	# Pedimos un token: si hay libre, salimos a atacar; si no, esperamos turno.
	if escuadron.pedir_token():
		_tiene_token = true
		_estado = Estado.ATACAR

func _atacar() -> void:
	# Aquí dispararías al jugador (instanciar proyectil, animación, etc.).
	print(name, " ataca (flanqueo=", escuadron.flanquea(global_position, jugador), ")")
	# Tras la ráfaga devolvemos el token para que otro pueda atacar.
	await get_tree().create_timer(1.2).timeout
	escuadron.devolver_token()
	_tiene_token = false
	_estado = Estado.BUSCAR_COBERTURA
```

Ejecuta con tres enemigos y `tokens_ataque = 2`. Observable: como máximo **dos** enemigos disparan a la vez; el tercero espera en cobertura hasta que se libere un token, y el log indica cuándo un enemigo ataca desde un flanco.

## ✍️ Ejercicios

1. Baja `tokens_ataque` a 1 y comprueba que los enemigos atacan estrictamente por turnos.
2. Añade un bono de puntuación a las coberturas que además flanquean al jugador.
3. Da un rol "reserva" al miembro que no consigue token para que reposicione en vez de esperar.
4. Colorea cada enemigo según su estado (buscar/cubierto/atacando).
5. Haz que un punto de cobertura deje de ser válido si el jugador se mueve al otro lado.
6. Registra en pantalla cuántos tokens quedan libres cada frame.

## 📝 Reto verificable

Diseña un escenario con **cuatro enemigos**, varios muros con puntos de cobertura y un jugador móvil. Los enemigos deben mantenerse en cobertura válida frente al jugador y coordinar el fuego con **un máximo de dos atacantes simultáneos**, priorizando posiciones de flanqueo cuando existan.

**Criterio de aceptación**: en ningún instante disparan más de dos enemigos a la vez, cada enemigo ocupa una cobertura que realmente lo protege (verificable con el raycast), y al menos uno ataca desde un flanco cuando hay una cobertura de flanco disponible.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Todos atacan a la vez | No pides/devuelves tokens correctamente. Verifica el flujo `pedir_token`/`devolver_token`. |
| Los enemigos se amontonan | Varias IA eligen el mismo punto. Marca coberturas como ocupadas al reservarlas. |
| La cobertura no protege | El raycast usa la máscara equivocada o va del jugador al punto. Ve del punto al jugador con la capa de muros. |
| Un token se pierde para siempre | Devuelves el token en una rama que no siempre se ejecuta. Devuélvelo también al cambiar de estado por interrupción. |
| El enemigo tiembla en la cobertura | Sigues moviéndote tras llegar. Detén la velocidad cuando `is_navigation_finished()`. |

## ❓ Preguntas frecuentes

**¿Por qué limitar los atacantes con tokens?** Un jugador abrumado por fuego simultáneo lo percibe como injusto; turnarse mantiene la tensión y la legibilidad del combate.

**¿Dónde coloco los puntos de cobertura?** Manualmente con `Marker2D` junto a muros, o generándolos por código analizando el borde de los obstáculos.

**¿El gestor debe ser un autoload?** Puede serlo si hay un único escuadrón, pero para varios grupos conviene una instancia de `Escuadron` por grupo.

**¿Cómo combino esto con GOAP o utility?** La utilidad/GOAP decide *qué* meta (atacar, cubrirse); esta capa táctica resuelve *dónde* posicionarse y *cuándo* le toca disparar.

## 🔗 Referencias

- Game AI Pro — Tactical Position Selection: <http://www.gameaipro.com/>
- Godot Docs — PhysicsRayQueryParameters2D: <https://docs.godotengine.org/en/stable/classes/class_physicsrayqueryparameters2d.html>
- Godot Docs — NavigationAgent2D: <https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html>
- Godot Docs — Marker2D: <https://docs.godotengine.org/en/stable/classes/class_marker2d.html>

## ⬅️ Clase anterior

[Clase 118 - GOAP: planificación orientada a objetivos](../118-goap-planificacion-orientada-a-objetivos/README.md)

## ➡️ Siguiente clase

[Clase 120 - Director de IA y dificultad dinámica](../120-director-de-ia-y-dificultad-dinamica/README.md)
