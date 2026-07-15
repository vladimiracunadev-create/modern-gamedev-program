# Clase 084 — Determinismo y física fija para multijugador

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Gaffer On Games — "Deterministic Lockstep" y Godot 4.x `_physics_process`*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Entender por qué la física de un juego en red o con replays debe ser **determinista** —mismas entradas producen exactamente el mismo resultado en cualquier máquina— y cómo lograrlo en la práctica. Verás cómo el paso variable, el orden de actualización y los floats rompen el determinismo, y cómo el **paso fijo** (`_physics_process`), un orden de actualización estable y una **semilla fija** de aleatoriedad lo restauran. Cerrarás grabando y reproduciendo entradas (un replay simple).

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar qué significa **determinismo** y por qué el netcode lockstep y los replays lo exigen.
2. Distinguir entre **paso variable** (`_process`) y **paso fijo** (`_physics_process`) y sus efectos.
3. Identificar fuentes de **no-determinismo**: orden de actualización, floats, RNG sin semilla.
4. Fijar la **semilla** del generador aleatorio para reproducir secuencias idénticas.
5. Implementar un **replay** grabando entradas por tick y reproduciéndolas.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es determinismo | Base de lockstep, replays y anti-cheat |
| 2 | Paso variable vs. paso fijo | El `delta` inconsistente rompe la simulación |
| 3 | Orden de actualización | Si cambia, el resultado cambia |
| 4 | Floats y su fragilidad | Difieren entre CPUs/compiladores |
| 5 | Enteros / punto fijo | Alternativa determinista al float |
| 6 | Semillas de aleatoriedad | Reproducir el "azar" |
| 7 | Grabación y replay de inputs | Depuración, demos, netcode |

## 📖 Definiciones y características

- **Determinismo**: misma entrada → misma salida, siempre. Clave: permite simular la partida en cada cliente sin enviar estados.
- **Lockstep**: modelo de red que solo transmite entradas; cada máquina simula el resto. Clave: exige determinismo perfecto.
- **Paso fijo**: `_physics_process(delta)` corre a intervalos constantes (p. ej. 60 Hz). Clave: `delta` es siempre el mismo.
- **Paso variable**: `_process(delta)` depende de los FPS. Clave: nunca lo uses para lógica que deba ser reproducible.
- **Orden de actualización**: secuencia en que se procesan las entidades. Clave: fija el orden (por id) o el resultado varía.
- **Punto fijo**: representar decimales con enteros escalados. Clave: evita la divergencia de floats entre plataformas.
- **Semilla (seed)**: valor inicial del RNG. Clave: con la misma semilla, la secuencia "aleatoria" es idéntica.
- **Replay**: registro de entradas por tick que, re-simulado, reproduce la partida. Clave: solo funciona si la simulación es determinista.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x** ([godotengine.org](https://godotengine.org)). Crea un proyecto 2D con un `Node2D` raíz. Trabajaremos con la lógica en `_physics_process` (paso fijo) y compararemos contra hacerlo en `_process`. Para la aleatoriedad usaremos una instancia propia de [RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html) con `seed` explícita, en vez de las funciones globales, para controlar el estado. Ten a mano la doc de [_physics_process](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html). El tick de física por defecto es 60 Hz (Project Settings → Physics → Common → Physics Ticks per Second).

## 🧪 Laboratorio guiado

Provocaremos no-determinismo a propósito y luego lo eliminaremos con paso fijo, semilla fija y replay de inputs.

**Paso 1 — Demostrar no-determinismo con paso variable.** Este script mueve un punto usando `_process`; el resultado depende de los FPS.

```gdscript
extends Node2D

var pos_variable := 0.0

func _process(delta: float) -> void:
	# delta cambia con los FPS: acumulación distinta en cada equipo
	pos_variable += 100.0 * delta
	# Con floats y delta irregular, dos máquinas divergen con el tiempo
```

**Observable**: si limitas los FPS (Project Settings → max_fps) a valores distintos y comparas `pos_variable` tras muchos frames, los totales difieren por acumulación de error. La lógica de juego no debe vivir aquí.

**Paso 2 — Paso fijo determinista.** Mueve la misma lógica a `_physics_process` con un contador de ticks entero como reloj.

```gdscript
var tick := 0
var pos_fija := 0

func _physics_process(_delta: float) -> void:
	tick += 1
	# Trabajar con enteros (punto fijo) elimina la deriva de floats.
	# 100 px/s a 60 Hz = 100/60 -> usamos milésimas de pixel como entero
	pos_fija += 1667  # milipixeles por tick (100 px/s aprox.)
	if tick % 60 == 0:
		print("Tick %d -> pos %d milipx" % [tick, pos_fija])
```

**Observable**: independientemente de los FPS de render, tras 60 ticks el valor es exactamente el mismo en cualquier máquina, porque el paso y la aritmética entera son idénticos.

**Paso 3 — Semilla fija para aleatoriedad reproducible.** Usa un RNG propio sembrado; la secuencia se repite exactamente.

```gdscript
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 12345          # misma semilla -> misma secuencia
	var secuencia := []
	for i in 5:
		secuencia.append(rng.randi_range(0, 99))
	print(secuencia)          # SIEMPRE imprime los mismos 5 numeros
```

**Observable**: ejecutar el juego dos veces imprime idéntica lista. Cambia la semilla y cambia toda la secuencia; sin semilla fija (`randomize()`) cada ejecución diverge.

**Paso 4 — Grabar y reproducir inputs (replay simple).** Guarda la entrada por tick y luego re-simula leyéndola en vez del teclado.

```gdscript
enum Estado { GRABANDO, REPRODUCIENDO }

@export var estado: Estado = Estado.GRABANDO
var _replay: Array[Dictionary] = []
var _idx := 0
var jugador := Vector2i(0, 0)   # posicion en enteros

func _leer_input() -> Vector2i:
	if estado == Estado.GRABANDO:
		var dir := Vector2i(
			int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")),
			int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up")))
		_replay.append({"tick": tick, "dir": dir})
		return dir
	else:
		if _idx < _replay.size():
			var dir: Vector2i = _replay[_idx]["dir"]
			_idx += 1
			return dir
		return Vector2i.ZERO

func _physics_process(_delta: float) -> void:
	tick += 1
	jugador += _leer_input()   # misma lógica al grabar y al reproducir
```

**Observable**: grabas moviéndote unos segundos; al cambiar a `REPRODUCIENDO` y reiniciar el estado, el jugador repite exactamente el mismo recorrido sin tocar el teclado. Esa es la prueba de determinismo.

## ✍️ Ejercicios

1. Guarda el replay a disco con `FileAccess` (JSON) y cárgalo en otra ejecución.
2. Añade un `checksum` (suma de posiciones por tick) y verifica que grabación y reproducción coinciden.
3. Sustituye `randomize()` por RNG sembrado en un spawner y comprueba que los enemigos aparecen igual cada partida.
4. Fuerza un orden de actualización estable ordenando las entidades por un `id` entero antes de procesarlas.
5. Convierte una velocidad float a punto fijo (enteros escalados ×1000) y compara la deriva tras 10.000 ticks.
6. Simula dos "clientes" en la misma escena que reciben los mismos inputs y verifica que sus estados nunca divergen.

## 📝 Reto verificable

Implementa un mini-sistema lockstep local: dos entidades que reciben la **misma** cola de inputs por tick y deben terminar en posiciones idénticas tras 600 ticks. Incluye un checksum por tick que aborte con un mensaje si las dos entidades divergen.

**Criterio de aceptación**: tras 600 ticks ambas entidades reportan el mismo checksum en todos los ticks, el sistema usa `_physics_process` y aritmética entera (o RNG sembrado si hay azar), y al introducir a propósito un `randf()` sin semilla el checksum diverge y el sistema lo detecta.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El replay se desincroniza con el tiempo | Lógica en `_process`; muévela a `_physics_process` |
| Los enemigos aparecen distinto cada partida | Usaste `randomize()`; siembra un RNG propio con `seed` fija |
| Dos clientes divergen lentamente | Acumulación de floats; usa enteros/punto fijo en la lógica crítica |
| El orden de daño cambia el resultado | Iteras entidades en orden no fijo; ordénalas por `id` |
| El replay salta o duplica frames | Grabas por frame de render, no por tick; graba en el paso fijo |

## ❓ Preguntas frecuentes

**¿Los floats son siempre no deterministas?** No siempre, pero pueden diferir entre CPUs, compiladores y órdenes de operación. Para simulaciones que deben coincidir bit a bit entre máquinas, el punto fijo es más seguro.

**¿Determinismo significa que no puede haber azar?** No: el azar sembrado es determinista. Con la misma semilla y el mismo número de llamadas, la secuencia es idéntica en todos lados.

**¿Por qué lockstep envía inputs y no posiciones?** Porque los inputs son diminutos y, si la simulación es determinista, cada cliente reconstruye el mismo estado. Ahorra ancho de banda y habilita replays.

**¿La física de Godot (RigidBody) es determinista?** No se garantiza entre plataformas. Para lockstep estricto se suele implementar una simulación propia y determinista en vez de confiar en el motor de rígidos.

## 🔗 Referencias

- Gaffer On Games — Deterministic Lockstep: <https://gafferongames.com/post/deterministic_lockstep/>
- Godot Docs — Physics introduction (`_physics_process`): <https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html>
- Godot Docs — RandomNumberGenerator: <https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html>
- Gaffer On Games — Floating Point Determinism: <https://gafferongames.com/post/floating_point_determinism/>

## ⬅️ Clase anterior

[Clase 083 - Física de partículas y telas (soft bodies)](../083-fisica-de-particulas-y-telas-soft-bodies/README.md)

## ➡️ Siguiente clase

[Clase 085 - Capstone Parte 3: un mini-juego de física](../085-capstone-parte-3-un-mini-juego-de-fisica/README.md)
