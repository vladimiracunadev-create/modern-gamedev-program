# Clase 109 — Máquinas de estado finito (FSM) para IA

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Mat Buckland, "Programming Game AI by Example" + Ian Millington, "Artificial Intelligence for Games"*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Implementar la estructura de decisión más usada de la historia de los videojuegos: la **máquina de estados finita**. Al terminar habrás construido un enemigo real en un `CharacterBody2D` que patrulla, detecta al jugador con un `RayCast2D`, lo persigue, lo ataca en rango y vuelve a patrullar cuando lo pierde. Dominarás las dos formas de implementarla —`enum`+`match` y clases de estado con `enter/update/exit`— y sabrás cuándo conviene cada una.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Definir estados y transiciones y expresarlos como un diagrama.
- Implementar una FSM con `enum` y `match` en un `CharacterBody2D`.
- Refactorizar esa FSM al patrón de clases de estado con `enter/update/exit`.
- Usar `RayCast2D` y distancia para disparar transiciones creíbles.
- Depurar una FSM identificando transiciones que faltan o se repiten.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Estados y transiciones | Son los dos únicos conceptos que necesita una FSM |
| 2 | FSM con enum + match | La forma más rápida y legible para pocos estados |
| 3 | enter / update / exit | Estructura cada estado y evita lógica duplicada |
| 4 | Condiciones de transición | Deciden cuándo el agente cambia de comportamiento |
| 5 | Patrón de clases de estado | Escala mejor cuando los estados crecen |
| 6 | Percepción con RayCast2D | Da al enemigo una línea de visión honesta |
| 7 | Patrol → Chase → Attack → Patrol | El ciclo clásico de enemigo de acción |

## 📖 Definiciones y características

- **Máquina de estados finita (FSM)**: sistema que está en exactamente un estado a la vez y transita entre ellos. Clave: un estado activo, transiciones explícitas.
- **Estado**: comportamiento concreto del agente (patrullar, perseguir). Clave: encapsula qué hace el agente *ahora*.
- **Transición**: cambio de un estado a otro al cumplirse una condición. Clave: sin condición clara, la IA "salta" errática.
- **enter/update/exit**: fases de un estado. Clave: `enter` inicializa, `update` corre cada frame, `exit` limpia.
- **RayCast2D**: nodo que detecta el primer cuerpo en una dirección. Clave: perfecto para línea de visión de un enemigo.
- **CharacterBody2D**: cuerpo controlado por código con `velocity` y `move_and_slide()`. Clave: base de casi todo agente 2D en Godot 4.
- **Estado activo**: el único estado que se ejecuta en un frame dado. Clave: garantiza comportamiento determinista y depurable.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x y una escena 2D. Prepara un `CharacterBody2D` para el enemigo con un `Sprite2D` (o `ColorRect`), un `RayCast2D` para la visión y opcionalmente un `Timer` para el cooldown de ataque. Ten en la escena un nodo que represente al jugador dentro de un grupo llamado `player` para poder localizarlo con `get_tree().get_first_node_in_group()`. Repasa el patrón `enum`/`match` en la [documentación de GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html) y el uso de [RayCast2D](https://docs.godotengine.org/en/stable/classes/class_raycast2d.html). Añade un `TileMapLayer` o unos muros con colisión para que la visión pueda bloquearse.

## 🧪 Laboratorio guiado

Construiremos el enemigo dos veces: primero con `enum`+`match` (rápido) y luego mostraremos el salto a clases de estado.

**Paso 1 — Escena del enemigo.** Crea un `CharacterBody2D` llamado `Enemigo`. Añádele hijos: un `Sprite2D`, un `CollisionShape2D` y un `RayCast2D` con su `target_position` apuntando hacia adelante (por ejemplo `Vector2(120, 0)`). Marca `Enabled` en el RayCast.

**Paso 2 — FSM con enum + match.** Adjunta este script al `Enemigo`:

```gdscript
extends CharacterBody2D

enum Estado { PATRULLA, PERSIGUE, ATAQUE }

@export var velocidad: float = 80.0
@export var rango_vision: float = 220.0
@export var rango_ataque: float = 40.0
@export var puntos_patrulla: Array[Vector2] = [Vector2(-150, 0), Vector2(150, 0)]

@onready var vision: RayCast2D = $RayCast2D

var estado: Estado = Estado.PATRULLA
var jugador: Node2D
var indice_patrulla: int = 0
var origen: Vector2

func _ready() -> void:
	origen = global_position
	jugador = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
	match estado:
		Estado.PATRULLA: _patrullar()
		Estado.PERSIGUE: _perseguir()
		Estado.ATAQUE:   _atacar()
	move_and_slide()

func _ve_al_jugador() -> bool:
	if jugador == null:
		return false
	var d := global_position.distance_to(jugador.global_position)
	if d > rango_vision:
		return false
	# Apuntamos el rayo al jugador y comprobamos que no haya un muro en medio.
	vision.target_position = to_local(jugador.global_position)
	vision.force_raycast_update()
	if vision.is_colliding():
		return vision.get_collider() == jugador
	return true

func _distancia_jugador() -> float:
	return global_position.distance_to(jugador.global_position) if jugador else INF

func _patrullar() -> void:
	var destino := origen + puntos_patrulla[indice_patrulla]
	velocity = global_position.direction_to(destino) * velocidad
	if global_position.distance_to(destino) < 8.0:
		indice_patrulla = (indice_patrulla + 1) % puntos_patrulla.size()
	if _ve_al_jugador():
		estado = Estado.PERSIGUE

func _perseguir() -> void:
	velocity = global_position.direction_to(jugador.global_position) * velocidad
	if _distancia_jugador() <= rango_ataque:
		estado = Estado.ATAQUE
	elif not _ve_al_jugador():
		estado = Estado.PATRULLA

func _atacar() -> void:
	velocity = Vector2.ZERO   # se detiene para golpear
	if _distancia_jugador() > rango_ataque:
		estado = Estado.PERSIGUE
```

**Paso 3 — Prueba en movimiento.** Coloca el jugador (un `CharacterBody2D` en el grupo `player`, muévelo con las flechas) en la escena. Ejecuta: el enemigo patrulla entre dos puntos, y cuando entras en su cono de visión sin muro de por medio, te persigue; si te acercas, se detiene a atacar; si te alejas o te escondes tras un muro, vuelve a patrullar.

**Paso 4 — Depuración visual.** Añade en `_physics_process` un `print(Estado.keys()[estado])` temporal para ver en consola cada transición, o pinta el `Sprite2D` de otro color por estado usando `$Sprite2D.modulate`.

**Paso 5 — El salto a clases de estado.** Cuando los estados crecen, `match` se vuelve un bloque enorme. La alternativa es una clase por estado con `enter/update/exit`:

```gdscript
# estado_base.gd — clase base para el patrón de estados
class_name EstadoIA
extends RefCounted

var agente: CharacterBody2D

func _init(a: CharacterBody2D) -> void:
	agente = a

func enter() -> void: pass
func update(_delta: float) -> void: pass
func exit() -> void: pass
```

Cada estado concreto (`EstadoPatrulla`, `EstadoPersigue`) hereda de `EstadoIA`, implementa su `update` y devuelve el siguiente estado. El agente guarda `estado_actual` y en `_physics_process` llama a `estado_actual.update(delta)`. Este patrón es la base de la HFSM de la próxima clase.

**Resultado visible:** un enemigo que patrulla, te caza al verte, se detiene a atacar en rango y regresa a su ruta al perderte, con la línea de visión bloqueada por muros.

## ✍️ Ejercicios

1. Añade un estado `HUIDA` que se active cuando la "vida" del enemigo baje de un umbral.
2. Haz que en `PERSIGUE` el enemigo gire su `Sprite2D` hacia el jugador con `look_at` o `atan2`.
3. Dibuja el diagrama de estados completo con todas las transiciones actuales.
4. Sustituye el ataque instantáneo por uno con `Timer` de cooldown (memoria de golpe).
5. Convierte los estados `PATRULLA` y `PERSIGUE` al patrón de clases de estado.
6. Añade un pequeño retardo antes de que `PERSIGUE` vuelva a `PATRULLA` para que no cambie bruscamente.

## 📝 Reto verificable

Entrega un enemigo con cuatro estados (`PATRULLA`, `PERSIGUE`, `ATAQUE`, `HUIDA`) implementado con FSM, cuya visión use `RayCast2D` y respete los muros, y con al menos una transición basada en un `Timer` (cooldown o memoria).

**Criterio de aceptación**: el enemigo transita correctamente entre los cuatro estados durante una partida, no atraviesa muros con la visión, y demuestras con logs o cambios de color del sprite que cada transición se dispara por su condición.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El enemigo "ve" a través de muros | No compruebas el colisionador del `RayCast2D`; verifica `get_collider() == jugador` |
| Se queda vibrando entre dos estados | Las condiciones de ida y vuelta se solapan; separa los umbrales (histéresis) |
| `move_and_slide()` da error de argumentos | Estás usando la firma de Godot 3; en Godot 4 se llama sin argumentos y usa `velocity` |
| `jugador` es `null` | El nodo del jugador no está en el grupo `player`; añádelo con `add_to_group` |
| El RayCast no detecta nada | Olvidaste `force_raycast_update()` tras mover `target_position` en el mismo frame |
| Todos los estados en una función ilegible | Muchos estados en un `match`; migra al patrón de clases de estado |

## ❓ Preguntas frecuentes

**¿Cuándo uso enum+match y cuándo clases de estado?**
`enum`+`match` para 3-5 estados simples. Clases de estado cuando hay muchos estados, cada uno con lógica de entrada/salida propia.

**¿Por qué `move_and_slide()` no lleva argumentos en Godot 4?**
Porque ahora lee la propiedad `velocity` del cuerpo. En Godot 3 recibía la velocidad como parámetro; ese código ya no compila.

**¿Puedo tener dos estados activos a la vez?**
No en una FSM plana: por definición hay uno solo. Si necesitas concurrencia (moverse y disparar), lo verás con HFSM y behavior trees.

**¿Cómo evito que el enemigo tiemble al cambiar de estado?**
Añade histéresis (umbrales distintos para entrar y salir) o un pequeño temporizador que retrase la transición inversa.

## 🔗 Referencias

- [GDScript básico — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- [RayCast2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_raycast2d.html)
- [CharacterBody2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)
- [Programming Game AI by Example — capítulo de FSM](https://www.jblearning.com/catalog/productdetails/9781556220784)

## ➡️ Siguiente clase

[Clase 110 - Máquinas de estado jerárquicas (HFSM)](../110-maquinas-de-estado-jerarquicas-hfsm/README.md)
