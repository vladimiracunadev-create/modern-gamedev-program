# Clase 115 — Steering y evitación de obstáculos (flocking)

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Craig W. Reynolds, "Steering Behaviors For Autonomous Characters" (GDC 1999) + Buckland, "Programming Game AI by Example"*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dominar los **comportamientos de dirección (steering)** como base del movimiento orgánico de la IA. Al terminar podrás implementar *seek* y *arrive*, evitar obstáculos con **raycasts tipo bigote (whiskers)**, y combinar las tres reglas de **flocking de Reynolds** —separación, alineación y cohesión— para mover un grupo de *boids* que se desplaza junto y esquiva obstáculos, todo manipulando el vector `velocity` de `CharacterBody2D`.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Implementar los steerings básicos *seek* y *arrive* como fuerzas sobre la velocidad.
- Evitar obstáculos usando `RayCast2D` en configuración de bigotes.
- Escribir las tres reglas de flocking y ponderarlas para lograr una bandada creíble.
- Sumar varias fuerzas de steering y limitarlas con `limit_length`.
- Ajustar pesos para obtener distintos "caracteres" de bandada (nervioso, cohesionado, disperso).

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Fuerza de steering | Es la diferencia entre la velocidad actual y la deseada: base de todo |
| 2 | Seek y Arrive | Perseguir un punto y frenar suavemente al llegar |
| 3 | Suma y límite de fuerzas | Varios comportamientos combinados sin descontrol |
| 4 | Evitación con whiskers | Rodear obstáculos sin depender de un navmesh |
| 5 | Separación | Impide que los boids se amontonen |
| 6 | Alineación | Hace que apunten en la misma dirección que sus vecinos |
| 7 | Cohesión | Mantiene el grupo unido hacia su centro |
| 8 | Ponderación de reglas | Define el carácter emergente de la bandada |

## 📖 Definiciones y características

- **Steering behavior**: fuerza que empuja la velocidad hacia un estado deseado. Clave: `fuerza = velocidad_deseada - velocidad_actual`.
- **Seek**: buscar un objetivo yendo a máxima velocidad hacia él. Clave: la deseada apunta directo al blanco.
- **Arrive**: como *seek* pero reduciendo la velocidad dentro de un radio de frenado. Clave: evita el vaivén al llegar.
- **Whiskers (bigotes)**: dos o tres raycasts orientados hacia adelante y a los lados. Clave: detectan obstáculos antes de chocar.
- **Separación**: fuerza que aleja de vecinos demasiado cercanos. Clave: proporcional a `1/distancia`.
- **Alineación**: fuerza hacia la velocidad promedio de los vecinos. Clave: sincroniza direcciones.
- **Cohesión**: fuerza hacia el centro de masa de los vecinos. Clave: mantiene el grupo compacto.
- **Boid**: agente individual que solo conoce a sus vecinos locales. Clave: el comportamiento global emerge de reglas locales simples.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x**. Usaremos `CharacterBody2D` para cada boid y `RayCast2D` para los bigotes. Crea `res://ia/steering/`. Repasa la [documentación de CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html), [RayCast2D](https://docs.godotengine.org/en/stable/classes/class_raycast2d.html) y la [charla original de Reynolds](https://www.red3d.com/cwr/steer/). No usaremos navmesh: aquí el movimiento es puramente por fuerzas, ideal para bandadas grandes y baratas.

## 🧪 Laboratorio guiado

Crearemos una escena con un `Node2D` raíz llamado `Bandada`, y muchos boids instanciados que se muevan juntos y esquiven obstáculos estáticos.

### Paso 1 — Steering base en un boid

Cada boid es un `CharacterBody2D` con un `RayCast2D`. Empezamos con *seek* y *arrive*:

```gdscript
class_name Boid
extends CharacterBody2D

@export var velocidad_max: float = 180.0
@export var fuerza_max: float = 320.0
@export var radio_frenado: float = 60.0

func _seek(objetivo: Vector2) -> Vector2:
	var deseada: Vector2 = (objetivo - global_position).normalized() * velocidad_max
	return deseada - velocity

func _arrive(objetivo: Vector2) -> Vector2:
	var hacia: Vector2 = objetivo - global_position
	var dist: float = hacia.length()
	if dist < 0.001:
		return -velocity
	# Escala la rapidez según la cercanía dentro del radio de frenado.
	var rapidez: float = velocidad_max
	if dist < radio_frenado:
		rapidez = velocidad_max * (dist / radio_frenado)
	var deseada: Vector2 = hacia.normalized() * rapidez
	return deseada - velocity
```

### Paso 2 — Evitación con bigotes

Añadimos tres raycasts (centro e inclinados). Este método devuelve una fuerza que empuja lejos del obstáculo detectado:

```gdscript
@onready var bigotes: Array[RayCast2D] = [
	$RayCentro, $RayIzq, $RayDer
]

func _evitar_obstaculos() -> Vector2:
	# Orientamos los bigotes hacia la dirección de avance.
	var direccion: Vector2 = velocity.normalized()
	if direccion == Vector2.ZERO:
		direccion = Vector2.RIGHT
	var fuerza: Vector2 = Vector2.ZERO
	for ray in bigotes:
		ray.target_position = direccion.rotated(ray.rotation) * 70.0
		ray.force_raycast_update()
		if ray.is_colliding():
			var normal: Vector2 = ray.get_collision_normal()
			# Empuja en la dirección de la normal para desviarse.
			fuerza += normal * fuerza_max
	return fuerza
```

### Paso 3 — Las tres reglas de flocking

El boid consulta a sus vecinos (los demás hijos de `Bandada`). Para claridad, pasamos la lista de vecinos como parámetro:

```gdscript
@export var radio_vecindario: float = 90.0
@export var radio_separacion: float = 40.0

func _flocking(vecinos: Array) -> Vector2:
	var separacion: Vector2 = Vector2.ZERO
	var alineacion: Vector2 = Vector2.ZERO
	var cohesion: Vector2 = Vector2.ZERO
	var cuenta: int = 0

	for otro in vecinos:
		if otro == self:
			continue
		var offset: Vector2 = otro.global_position - global_position
		var dist: float = offset.length()
		if dist > radio_vecindario or dist < 0.001:
			continue
		cuenta += 1
		# Separación: más fuerte cuanto más cerca está el vecino.
		if dist < radio_separacion:
			separacion -= offset.normalized() * (radio_separacion - dist)
		# Alineación: acumulamos las velocidades de los vecinos.
		alineacion += otro.velocity
		# Cohesión: acumulamos posiciones para hallar el centro.
		cohesion += otro.global_position

	if cuenta == 0:
		return Vector2.ZERO

	alineacion = (alineacion / cuenta).normalized() * velocidad_max - velocity
	cohesion = ((cohesion / cuenta) - global_position).normalized() * velocidad_max - velocity
	# Ponderamos cada regla; ajusta estos pesos para cambiar el carácter.
	return separacion * 1.6 + alineacion * 1.0 + cohesion * 0.8
```

### Paso 4 — Combinar todo en el movimiento

Sumamos las fuerzas, las limitamos y actualizamos `velocity`:

```gdscript
var objetivo_grupo: Vector2 = Vector2.ZERO  # lo fija la Bandada (ej. el ratón)

func actualizar(vecinos: Array, delta: float) -> void:
	var fuerza: Vector2 = Vector2.ZERO
	fuerza += _arrive(objetivo_grupo) * 0.5
	fuerza += _flocking(vecinos)
	fuerza += _evitar_obstaculos()
	# Limitamos la fuerza total para que ningún boid acelere sin control.
	fuerza = fuerza.limit_length(fuerza_max)
	velocity += fuerza * delta
	velocity = velocity.limit_length(velocidad_max)
	# Giramos el sprite hacia donde nos movemos.
	if velocity.length() > 1.0:
		rotation = atan2(velocity.y, velocity.x)
	move_and_slide()
```

Y el gestor `Bandada` recorre los boids cada frame físico:

```gdscript
extends Node2D

@onready var boids: Array = get_children().filter(func(n): return n is Boid)

func _physics_process(delta: float) -> void:
	var objetivo: Vector2 = get_global_mouse_position()
	for b in boids:
		b.objetivo_grupo = objetivo
		b.actualizar(boids, delta)
```

Ejecuta con 20-30 boids. Observable: la bandada se mueve como un banco de peces hacia el ratón, sin amontonarse y rodeando los obstáculos.

## ✍️ Ejercicios

1. Sube el peso de separación a 3.0 y describe cómo cambia la bandada.
2. Anula la cohesión (peso 0) y observa que el grupo se dispersa.
3. Añade un cuarto bigote apuntando más abierto y compara la evitación.
4. Convierte `_seek` en *flee* invirtiendo el signo de la velocidad deseada.
5. Limita el vecindario a los 5 boids más cercanos en vez de por radio.
6. Colorea cada boid según su rapidez usando `modulate`.

## 📝 Reto verificable

Implementa una bandada de **al menos 30 boids** que persiga al ratón por un mapa con **tres obstáculos** circulares. La bandada debe permanecer visualmente cohesionada (sin dispersarse en individuos aislados) y ningún boid debe quedar atascado dentro de un obstáculo.

**Criterio de aceptación**: durante 30 segundos de ejecución continua, la distancia promedio entre boids vecinos se mantiene por debajo de `radio_vecindario`, ningún boid solapa un obstáculo, y todos siguen al cursor cuando se mueve.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Boids que vibran en el sitio | Fuerzas contradictorias sin límite. Aplica `limit_length` a la fuerza total. |
| La bandada explota y se dispersa | Separación demasiado alta o cohesión nula. Reequilibra los pesos. |
| Los bigotes no detectan nada | No llamaste a `force_raycast_update()` tras mover `target_position`. Añádelo. |
| Todos los boids se apilan | No excluyes `self` del bucle de vecinos. Añade `if otro == self: continue`. |
| Movimiento demasiado brusco | Sumaste la fuerza sin multiplicar por `delta`. Escala por `delta`. |

## ❓ Preguntas frecuentes

**¿Steering o navmesh?** Steering da movimiento orgánico local y barato para muchos agentes; el navmesh garantiza rutas óptimas en mapas complejos. A menudo se combinan: navmesh para la ruta, steering para el detalle.

**¿Por qué usar velocidad y no `move_toward` directo?** Las fuerzas se suman de forma natural; con `move_toward` es difícil mezclar varios comportamientos.

**¿Cómo hago vecindarios eficientes con cientos de boids?** Usa una rejilla espacial o `Area2D` para consultar solo boids cercanos, en vez de recorrer todos.

**¿La evitación con whiskers reemplaza al avoidance del NavigationAgent?** Para grupos simples sí; para escenarios con muchos agentes y obstáculos, el avoidance del servidor escala mejor.

## 🔗 Referencias

- Reynolds — Steering Behaviors For Autonomous Characters: <https://www.red3d.com/cwr/steer/>
- Reynolds — Boids: <https://www.red3d.com/cwr/boids/>
- Godot Docs — CharacterBody2D: <https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html>
- Godot Docs — RayCast2D: <https://docs.godotengine.org/en/stable/classes/class_raycast2d.html>

## ⬅️ Clase anterior

[Clase 114 - Navmesh y navegación en Godot (2D y 3D)](../114-navmesh-y-navegacion-en-godot-2d-y-3d/README.md)

## ➡️ Siguiente clase

[Clase 116 - Percepción: visión, oído y memoria del agente](../116-percepcion-vision-oido-y-memoria-del-agente/README.md)
