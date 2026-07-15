# Clase 116 — Percepción: visión, oído y memoria del agente

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Millington, "AI for Games" (3ª ed., cap. World Interfacing / Sensory Systems) + Documentación de Godot 4 (RayCast, Timer, señales)*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dotar a un enemigo de **sentidos** para que reaccione al jugador de forma creíble. Al terminar sabrás construir un **cono de visión** (usando producto punto + rango + un `RayCast` de línea de vista), un sistema de **oído** basado en eventos de sonido por distancia, y una **memoria** que guarda la última posición vista y la olvida con un `Timer`. El enemigo solo detectará al jugador cuando esté dentro del cono, con línea despejada, y lo perseguirá por memoria aunque lo pierda de vista.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Determinar si un objetivo está dentro de un cono de visión con `dot()` y un ángulo umbral.
- Confirmar línea de vista despejada con un `RayCast2D` hacia el objetivo.
- Emitir y recibir eventos de sonido audibles según la distancia.
- Almacenar la última posición conocida en un blackboard sencillo.
- Implementar el olvido de esa posición con un `Timer` reiniciable.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Cono de visión (ángulo) | Define el campo visual realista del enemigo |
| 2 | Rango de visión | Limita hasta dónde alcanza la vista |
| 3 | Línea de vista (raycast) | Evita "ver" a través de paredes |
| 4 | Oído por eventos | Permite detectar sin ver, mediante ruidos |
| 5 | Última posición conocida | El enemigo persigue hacia donde vio al jugador |
| 6 | Olvido con Timer | Hace que la IA "pierda el rastro" con el tiempo |
| 7 | Estados de percepción | Coordinar patrulla / alerta / búsqueda |

## 📖 Definiciones y características

- **Cono de visión**: sector angular frente al agente donde puede ver. Clave: se prueba con el ángulo entre su frente y el vector al objetivo.
- **Producto punto (dot)**: mide el coseno del ángulo entre dos vectores normalizados. Clave: `dot > cos(mitad_angulo)` significa "dentro del cono".
- **Línea de vista (LoS)**: comprobación de que no hay obstáculos entre agente y objetivo. Clave: un `RayCast2D` que colisione con paredes pero no con el jugador la invalida.
- **Evento de sonido**: notificación de que algo hizo ruido en una posición con cierto volumen. Clave: audible solo si `distancia < alcance`.
- **Última posición conocida**: coordenada donde se vio por última vez al objetivo. Clave: guía la búsqueda cuando ya no hay visión.
- **Olvido**: descarte de la memoria tras un tiempo sin percepción. Clave: un `Timer` de un disparo que se reinicia con cada avistamiento.
- **Blackboard**: `Dictionary` compartido con el estado percibido. Clave: desacopla los sensores de la lógica de decisión.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x**. El enemigo será un `CharacterBody2D` con un `RayCast2D` para la línea de vista y un `Timer` para el olvido. El jugador es otro `CharacterBody2D`. Crea `res://ia/percepcion/`. Consulta [Vector2.dot](https://docs.godotengine.org/en/stable/classes/class_vector2.html#class-vector2-method-dot), [RayCast2D](https://docs.godotengine.org/en/stable/classes/class_raycast2d.html) y [Timer](https://docs.godotengine.org/en/stable/classes/class_timer.html). Usaremos capas de colisión: pon las paredes en una capa que el raycast detecte.

## 🧪 Laboratorio guiado

Construiremos un enemigo que patrulla, detecta al jugador solo dentro de su cono con línea despejada, recuerda dónde lo vio y olvida tras 3 segundos.

### Paso 1 — Estructura y blackboard

```text
Enemigo (CharacterBody2D)
├── RayVista (RayCast2D)
├── TimerOlvido (Timer, one_shot = true, wait_time = 3.0)
└── ConoVisual (Polygon2D, solo decorativo)
```

```gdscript
extends CharacterBody2D

@export var jugador: Node2D
@export var rango_vision: float = 320.0
@export var angulo_vision_grados: float = 60.0  # ángulo TOTAL del cono
@export var velocidad: float = 120.0

@onready var ray_vista: RayCast2D = $RayVista
@onready var timer_olvido: Timer = $TimerOlvido

# Blackboard simple con lo que el enemigo "sabe".
var pizarra: Dictionary = {
	"ve_jugador": false,
	"ultima_pos": Vector2.ZERO,
	"tiene_memoria": false,
}
var _mirando: Vector2 = Vector2.RIGHT

func _ready() -> void:
	timer_olvido.one_shot = true
	timer_olvido.timeout.connect(_on_olvido)
```

### Paso 2 — El cono de visión con línea de vista

```gdscript
func _puede_ver_jugador() -> bool:
	if jugador == null:
		return false
	var hacia: Vector2 = jugador.global_position - global_position
	var dist: float = hacia.length()
	# 1) Rango.
	if dist > rango_vision or dist < 0.001:
		return false
	# 2) Ángulo: comparamos con el coseno de la mitad del cono.
	var dir_obj: Vector2 = hacia / dist
	var coseno: float = _mirando.dot(dir_obj)
	var umbral: float = cos(deg_to_rad(angulo_vision_grados / 2.0))
	if coseno < umbral:
		return false
	# 3) Línea de vista: el rayo no debe chocar con una pared antes del jugador.
	ray_vista.target_position = hacia
	ray_vista.force_raycast_update()
	if ray_vista.is_colliding():
		var col: Object = ray_vista.get_collider()
		# Si lo primero que golpea NO es el jugador, la vista está bloqueada.
		return col == jugador
	return true
```

### Paso 3 — Percepción, memoria y olvido

```gdscript
func _physics_process(_delta: float) -> void:
	var visto: bool = _puede_ver_jugador()
	pizarra["ve_jugador"] = visto

	if visto:
		# Actualizamos la memoria y reiniciamos el temporizador de olvido.
		pizarra["ultima_pos"] = jugador.global_position
		pizarra["tiene_memoria"] = true
		timer_olvido.start()  # reinicia la cuenta a 3 s
		_perseguir(jugador.global_position)
	elif pizarra["tiene_memoria"]:
		# No lo vemos, pero recordamos dónde estaba: vamos hacia allí.
		_perseguir(pizarra["ultima_pos"])
	else:
		_patrullar()

func _perseguir(destino: Vector2) -> void:
	var hacia: Vector2 = destino - global_position
	if hacia.length() > 6.0:
		_mirando = hacia.normalized()
		velocity = _mirando * velocidad
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func _patrullar() -> void:
	# Marcador de posición: aquí iría tu lógica de ruta de patrulla.
	velocity = Vector2.ZERO
	move_and_slide()

func _on_olvido() -> void:
	# Se acabó el tiempo sin ver al jugador: se olvida la última posición.
	pizarra["tiene_memoria"] = false
```

### Paso 4 — Oído por eventos

El jugador emite un ruido (al disparar o correr) mediante una señal global. El enemigo lo escucha si está en rango:

```gdscript
# En un autoload 'Eventos' (Node):  signal sonido_emitido(pos, volumen)

# En el enemigo, dentro de _ready():
func conectar_oido() -> void:
	Eventos.sonido_emitido.connect(_on_sonido)

func _on_sonido(pos: Vector2, volumen: float) -> void:
	var dist: float = global_position.distance_to(pos)
	# El alcance audible crece con el volumen del evento.
	if dist <= volumen:
		# Investigamos el ruido aunque no veamos al jugador.
		pizarra["ultima_pos"] = pos
		pizarra["tiene_memoria"] = true
		timer_olvido.start()
```

Ejecuta: acércate por el frente del enemigo y te perseguirá; escóndete tras una pared y, aunque estés en rango, no te verá. Al perderte de vista, irá a tu última posición y, tras 3 segundos, se detendrá.

## ✍️ Ejercicios

1. Dibuja el cono de visión con un `Polygon2D` que refleje `angulo_vision_grados`.
2. Cambia el color del enemigo según el estado: patrulla (verde), persigue (rojo), busca (amarillo).
3. Reduce el `wait_time` del olvido a 1 s y describe el cambio de comportamiento.
4. Haz que el jugador emita un sonido más fuerte al correr que al caminar.
5. Añade un segundo raycast desplazado para que las paredes finas no fallen la LoS.
6. Registra en consola cada transición patrulla→persigue→busca.

## 📝 Reto verificable

Crea una sala con **dos columnas** que bloqueen la vista. El enemigo debe: (a) ignorar al jugador fuera de su cono aunque esté cerca, (b) perderlo cuando se oculte tras una columna, (c) caminar hasta la última posición conocida, y (d) olvidarla tras el tiempo configurado y volver a patrullar.

**Criterio de aceptación**: el enemigo nunca reacciona al jugador oculto tras una columna (LoS bloqueada), persigue solo dentro del cono con línea despejada, y `pizarra["tiene_memoria"]` pasa a `false` exactamente cuando el `Timer` termina.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El enemigo ve a través de paredes | El raycast no detecta la capa de las paredes. Ajusta `collision_mask`. |
| Detecta al jugador a 360° | Usas solo rango, sin el test de ángulo. Añade la comparación de `dot()`. |
| Nunca detecta al jugador | El jugador también es golpeado por el raycast como colisión previa, o `_mirando` no se actualiza. Excluye o verifica el collider. |
| El olvido no ocurre | El `Timer` no es `one_shot` o lo reinicias cada frame. Solo reinícialo al ver. |
| El cono apunta siempre a la derecha | No actualizas `_mirando` al moverte. Asígnalo con la dirección de avance. |

## ❓ Preguntas frecuentes

**¿Por qué `dot` y no `angle_to`?** Ambos sirven; `dot` con un umbral precomputado evita llamadas trigonométricas por frame y es más barato.

**¿La línea de vista debe salir de los ojos o del centro?** Del punto que represente la vista; para 2D suele bastar el origen del enemigo, pero puedes desplazar el `RayCast2D`.

**¿Cómo evito que el raycast choque con el propio enemigo?** Usa `add_exception(self)` o coloca el enemigo en una capa que el rayo no incluya.

**¿La memoria debería ser una lista de posiciones?** Para búsqueda avanzada sí: guardar varias posiciones permite patrones de rastreo, pero una sola basta para el comportamiento base.

## 🔗 Referencias

- Godot Docs — Vector2.dot(): <https://docs.godotengine.org/en/stable/classes/class_vector2.html>
- Godot Docs — RayCast2D: <https://docs.godotengine.org/en/stable/classes/class_raycast2d.html>
- Godot Docs — Timer: <https://docs.godotengine.org/en/stable/classes/class_timer.html>
- Godot Docs — Using signals: <https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html>

## ⬅️ Clase anterior

[Clase 115 - Steering y evitación de obstáculos (flocking)](../115-steering-y-evitacion-de-obstaculos-flocking/README.md)

## ➡️ Siguiente clase

[Clase 117 - Toma de decisiones: utility AI](../117-toma-de-decisiones-utility-ai/README.md)
