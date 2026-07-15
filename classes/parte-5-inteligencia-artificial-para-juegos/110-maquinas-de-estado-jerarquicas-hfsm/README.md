# Clase 110 — Máquinas de estado jerárquicas (HFSM)

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Ian Millington, "Artificial Intelligence for Games" (2ª ed.) + Steve Rabin, "Game AI Pro"*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Resolver la **explosión de estados** que sufre una FSM plana cuando crece. Al terminar entenderás por qué añadir comportamientos a una FSM normal multiplica las transiciones, y refactorizarás el enemigo de la clase anterior a una **máquina de estados jerárquica**: superestados (`Calma`, `Alerta`) que agrupan subestados (`Idle`/`Patrulla`, `Persigue`/`Ataque`) y comparten transiciones heredadas, reduciendo drásticamente el número de conexiones que debes mantener.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar la explosión combinatoria de transiciones en una FSM plana.
- Diseñar una jerarquía de superestados y subestados para un agente.
- Implementar transiciones heredadas (del superestado a todos sus hijos).
- Refactorizar una FSM plana a HFSM sin perder comportamiento.
- Decidir qué comportamientos agrupar bajo un superestado común.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Explosión de estados | Es el problema concreto que la HFSM resuelve |
| 2 | Superestados y subestados | La idea central de la jerarquía |
| 3 | Estados anidados | Permiten un estado activo en cada nivel |
| 4 | Transiciones heredadas | Una regla del padre vale para todos los hijos |
| 5 | Estado inicial de un superestado | Al entrar al padre hay que elegir un hijo |
| 6 | Calma vs Alerta | Ejemplo canónico de agrupación por contexto |
| 7 | Refactor desde FSM plana | Cómo migrar sin romper lo que ya funciona |

## 📖 Definiciones y características

- **HFSM**: FSM cuyos estados pueden contener otras FSM. Clave: hay un estado activo por nivel de la jerarquía.
- **Superestado**: estado que agrupa subestados relacionados (p. ej. `Alerta`). Clave: define transiciones comunes a todos sus hijos.
- **Subestado**: estado dentro de un superestado (p. ej. `Persigue` dentro de `Alerta`). Clave: se ejecuta solo si su padre está activo.
- **Transición heredada**: transición definida en el superestado que aplica a cualquier subestado. Clave: evita repetir la misma regla en cada hijo.
- **Estado inicial del superestado**: subestado que se activa al entrar al padre. Clave: sin él, la jerarquía no sabe por dónde empezar.
- **Explosión de estados**: crecimiento cuadrático de transiciones al añadir estados. Clave: la principal razón para pasar a HFSM.
- **Anidamiento**: contención de una FSM dentro de un estado. Clave: puede tener varios niveles de profundidad.

## 🧰 Herramientas y preparación

Reutiliza la escena del enemigo `CharacterBody2D` de la clase 109 (con su `RayCast2D` y el jugador en el grupo `player`). Necesitas Godot 4.x. No hace falta ningún nodo nuevo: el cambio es de arquitectura del script. Ten a mano el diagrama de estados que dibujaste antes, porque lo vas a reorganizar en dos bloques. Como apoyo conceptual, revisa el capítulo de *hierarchical state machines* en *Artificial Intelligence for Games* y los artículos de FSM/HFSM en [Game AI Pro](http://www.gameaipro.com/). Repasa `class_name` y `RefCounted` en la [documentación de GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html).

## 🧪 Laboratorio guiado

Refactorizaremos el enemigo a dos superestados: **Calma** (`Idle`, `Patrulla`) y **Alerta** (`Persigue`, `Ataque`). La transición "veo/pierdo al jugador" pasa a ser heredada entre superestados.

**Paso 1 — Reorganiza el diagrama.** Agrupa: en `Calma` van `Idle` y `Patrulla`; en `Alerta` van `Persigue` y `Ataque`. La regla "si veo al jugador → Alerta" y "si lo pierdo un tiempo → Calma" son transiciones **entre superestados**, no entre subestados individuales. Con esto pasas de ~8 transiciones a media docena.

**Paso 2 — Estructura de datos anidada.** Modelamos la jerarquía con dos `enum` (uno de superestados, otro de subestados) y una función que resuelve cada nivel:

```gdscript
extends CharacterBody2D

enum Super { CALMA, ALERTA }
enum Sub { IDLE, PATRULLA, PERSIGUE, ATAQUE }

@export var velocidad: float = 80.0
@export var rango_vision: float = 220.0
@export var rango_ataque: float = 40.0
@export var puntos_patrulla: Array[Vector2] = [Vector2(-150, 0), Vector2(150, 0)]
@export var memoria_seg: float = 2.0   # cuánto recuerda tras perder de vista

@onready var vision: RayCast2D = $RayCast2D

var superestado: Super = Super.CALMA
var subestado: Sub = Sub.PATRULLA
var jugador: Node2D
var origen: Vector2
var indice: int = 0
var tiempo_sin_ver: float = 0.0

func _ready() -> void:
	origen = global_position
	jugador = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	_actualizar_superestado(delta)   # transiciones HEREDADAS (nivel alto)
	_actualizar_subestado()          # comportamiento del subestado activo
	move_and_slide()
```

**Paso 3 — Transiciones heredadas (nivel superestado).** Esta única función gobierna el salto Calma↔Alerta para *todos* los subestados, en vez de repetir la regla en cada uno:

```gdscript
func _actualizar_superestado(delta: float) -> void:
	if _ve_al_jugador():
		tiempo_sin_ver = 0.0
		if superestado == Super.CALMA:
			superestado = Super.ALERTA
			subestado = Sub.PERSIGUE   # estado inicial del superestado Alerta
	elif superestado == Super.ALERTA:
		tiempo_sin_ver += delta
		if tiempo_sin_ver >= memoria_seg:
			superestado = Super.CALMA
			subestado = Sub.PATRULLA   # estado inicial del superestado Calma
```

**Paso 4 — Subestados (nivel bajo).** Cada superestado resuelve internamente cuál de sus hijos corre:

```gdscript
func _actualizar_subestado() -> void:
	match superestado:
		Super.CALMA:
			match subestado:
				Sub.IDLE: _idle()
				Sub.PATRULLA: _patrullar()
		Super.ALERTA:
			match subestado:
				Sub.PERSIGUE: _perseguir()
				Sub.ATAQUE: _atacar()

func _idle() -> void:
	velocity = Vector2.ZERO

func _patrullar() -> void:
	var destino := origen + puntos_patrulla[indice]
	velocity = global_position.direction_to(destino) * velocidad
	if global_position.distance_to(destino) < 8.0:
		indice = (indice + 1) % puntos_patrulla.size()

func _perseguir() -> void:
	velocity = global_position.direction_to(jugador.global_position) * velocidad
	if global_position.distance_to(jugador.global_position) <= rango_ataque:
		subestado = Sub.ATAQUE

func _atacar() -> void:
	velocity = Vector2.ZERO
	if global_position.distance_to(jugador.global_position) > rango_ataque:
		subestado = Sub.PERSIGUE

func _ve_al_jugador() -> bool:
	if jugador == null:
		return false
	if global_position.distance_to(jugador.global_position) > rango_vision:
		return false
	vision.target_position = to_local(jugador.global_position)
	vision.force_raycast_update()
	if vision.is_colliding():
		return vision.get_collider() == jugador
	return true
```

**Paso 5 — Observa la ganancia.** La transición Persigue↔Ataque vive dentro de `Alerta`, y "perder al jugador" se maneja **una sola vez** en el superestado, aplicando a `Persigue` y a `Ataque` por igual. En una FSM plana habrías escrito esa condición en cada subestado.

**Resultado visible:** el mismo enemigo funcional que antes, pero con la memoria (`memoria_seg`) heredada por todo el superestado `Alerta`: no vuelve a `Calma` en cuanto te escondes un instante, sino tras el tiempo definido.

## ✍️ Ejercicios

1. Añade un subestado `BUSCA` dentro de `Alerta` que corra durante `memoria_seg` antes de volver a `Calma`.
2. Cuenta las transiciones de tu FSM plana original y compáralas con las de la HFSM.
3. Haz que en `Calma` el enemigo alterne entre `Idle` y `Patrulla` cada pocos segundos con un `Timer`.
4. Añade un tercer superestado `Herido` con transición heredada desde cualquier estado si la vida baja.
5. Dibuja el diagrama jerárquico con los dos niveles y marca qué transiciones son heredadas.
6. Explica qué pasa con `tiempo_sin_ver` si vuelves a ver al jugador antes de que expire la memoria.

## 📝 Reto verificable

Refactoriza el enemigo a una HFSM con tres superestados (`Calma`, `Alerta`, `Herido`), cada uno con al menos dos subestados, y con la transición "veo al jugador" implementada **una sola vez** como transición heredada del nivel superestado.

**Criterio de aceptación**: el comportamiento observable equivale o mejora al de la FSM plana, la condición de detección aparece escrita una única vez, y demuestras (diagrama + logs) que un cambio de superestado arrastra correctamente a sus subestados.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Al entrar a `Alerta` el enemigo no hace nada | No fijaste el subestado inicial del superestado; asígnalo en la transición |
| Repites la misma condición en cada subestado | No aprovechas la herencia; súbela al nivel superestado |
| El enemigo vuelve a `Calma` en cuanto parpadea la visión | Falta la memoria; usa `tiempo_sin_ver` y `memoria_seg` |
| Cambias de superestado pero el subestado viejo sigue activo | Olvidaste resetear `subestado` al transitar de padre |
| La jerarquía se vuelve confusa con muchos niveles | Limita a 2-3 niveles; más profundidad conviene expresarla como behavior tree |
| `delta` sin usar en superestado | La memoria depende del tiempo; acumula `delta`, no cuentes frames |

## ❓ Preguntas frecuentes

**¿Cuál es la ventaja real frente a una FSM plana?**
Menos transiciones que mantener. Una regla del superestado cubre a todos sus hijos, evitando duplicación y errores.

**¿Cuántos niveles de anidamiento conviene tener?**
Dos o tres. Si necesitas más, probablemente un behavior tree exprese mejor esa lógica (próximas clases).

**¿La HFSM sustituye a los behavior trees?**
No. Es un peldaño intermedio: escala más que la FSM plana pero menos que un BT bien diseñado para comportamientos muy ramificados.

**¿Puedo tener transiciones entre subestados de superestados distintos?**
Sí, pero es señal de que quizá la agrupación no es la ideal. Lo natural es transitar entre subestados del mismo padre y entre superestados.

## 🔗 Referencias

- [Artificial Intelligence for Games — HFSM (CRC Press)](https://www.routledge.com/Artificial-Intelligence-for-Games/Millington/p/book/9780367670566)
- [Game AI Pro — artículos de máquinas de estado](http://www.gameaipro.com/)
- [GDScript básico — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- [CharacterBody2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)

## ⬅️ Clase anterior

[Clase 109 - Máquinas de estado finito (FSM) para IA](../109-maquinas-de-estado-finito-fsm-para-ia/README.md)

## ➡️ Siguiente clase

[Clase 111 - Behavior Trees: fundamentos](../111-behavior-trees-fundamentos/README.md)
