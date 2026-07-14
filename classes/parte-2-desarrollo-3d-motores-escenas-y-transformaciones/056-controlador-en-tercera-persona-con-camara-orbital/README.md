# Clase 056 — Controlador en tercera persona con cámara orbital

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Godot Engine 4 — Documentación oficial: SpringArm3D y Using CharacterBody3D*
> ⏱️ Duración estimada: **65 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Crear un **controlador en tercera persona** en Godot 4 con una **cámara orbital** controlada por el ratón, usando un **SpringArm3D** para que la cámara no atraviese paredes, movimiento **relativo a la cámara** y un personaje que **rota suavemente** hacia su dirección de desplazamiento.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Montar la jerarquía pivote → SpringArm3D → cámara para una órbita estable.
2. Orbitar la cámara con el ratón y limitar el pitch con `clamp`.
3. Usar `SpringArm3D` para evitar que la cámara traspase la geometría.
4. Mover al personaje relativo a la orientación de la cámara.
5. Rotar el personaje hacia su dirección de movimiento con interpolación suave.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Jerarquía de cámara orbital | Separar personaje, pivote y brazo simplifica la lógica. |
| 2 | SpringArm3D | Retrae la cámara ante obstáculos automáticamente. |
| 3 | Órbita con el ratón | Permite inspeccionar al personaje y el entorno. |
| 4 | Clamp del pitch | Evita ángulos de cámara imposibles. |
| 5 | Movimiento relativo a cámara | Control intuitivo en tercera persona. |
| 6 | Rotación del personaje | El modelo mira hacia donde avanza. |
| 7 | Interpolación de ángulo | Giro suave sin saltos bruscos. |
| 8 | Gravedad y salto | Física básica coherente con el resto. |

## 📖 Definiciones y características

- **SpringArm3D**: nodo que acorta su longitud si detecta colisión entre pivote y cámara. Clave: `spring_length` define la distancia deseada.
- **Pivote (Node3D)**: nodo que gira con el ratón y del que cuelga el brazo. Clave: aísla la órbita del cuerpo.
- **spring_length**: distancia máxima de la cámara al pivote. Clave: la cámara se acerca si hay pared.
- **Órbita**: rotar pivote (yaw) y brazo/pivote (pitch) con `event.relative`. Clave: mismo patrón que el mouse look.
- **look_at**: orienta un nodo hacia un objetivo. Clave: útil para encarar la dirección de avance.
- **lerp_angle**: interpola entre dos ángulos por el camino más corto. Clave: giro suave del personaje.
- **atan2**: obtiene el ángulo de un vector dirección. Clave: convierte `(x, z)` en yaw objetivo.
- **Movimiento relativo a cámara**: proyectar la entrada según el yaw del pivote. Clave: adelante = hacia donde mira la cámara.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x**, un nivel con suelo, paredes y algún obstáculo para probar la retracción del `SpringArm3D`, y un `MeshInstance3D` con forma reconocible (una flecha o cápsula con "frente") para ver hacia dónde mira el personaje. Define las acciones de movimiento y `saltar` en el Input Map. Consulta la API de `SpringArm3D` en <https://docs.godotengine.org/en/stable/classes/class_springarm3d.html> y la guía 3D en <https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html>. Motor: <https://godotengine.org/download>.

## 🧪 Laboratorio guiado

1. Crea una escena con raíz `CharacterBody3D` llamada `JugadorTP`, con su `CollisionShape3D` (cápsula) y un `MeshInstance3D` como `Modelo` cuyo frente apunte a `-Z`.
2. Añade como hijo un `Node3D` llamado `Pivote` a la altura del pecho. Dentro de `Pivote`, añade un `SpringArm3D` con `spring_length = 5.0`. Dentro del brazo, una `Camera3D`.
3. Jerarquía: `JugadorTP` → `Pivote` (yaw+pitch) → `SpringArm3D` → `Camera3D`.
4. Asigna este script al nodo `JugadorTP`:

```gdscript
extends CharacterBody3D

@export var velocidad: float = 5.0
@export var fuerza_salto: float = 4.5
@export var sensibilidad: float = 0.005
@export var giro_suave: float = 10.0

var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var pivote: Node3D = $Pivote
@onready var modelo: Node3D = $Modelo

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Yaw del pivote (orbita horizontal alrededor del jugador).
		pivote.rotate_y(-event.relative.x * sensibilidad)
		# Pitch del pivote con clamp.
		pivote.rotation.x -= event.relative.y * sensibilidad
		pivote.rotation.x = clamp(pivote.rotation.x,
			deg_to_rad(-60.0), deg_to_rad(30.0))
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravedad * delta

	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = fuerza_salto

	var entrada := Input.get_vector("mover_izquierda", "mover_derecha",
		"mover_adelante", "mover_atras")

	# Dirección relativa al yaw del pivote (la cámara).
	var yaw := pivote.rotation.y
	var direccion := Vector3(entrada.x, 0.0, entrada.y).rotated(Vector3.UP, yaw)
	direccion = direccion.normalized()

	if direccion != Vector3.ZERO:
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
		# Rotar el modelo hacia la dirección de avance, suavemente.
		var angulo_objetivo := atan2(direccion.x, direccion.z)
		modelo.rotation.y = lerp_angle(modelo.rotation.y, angulo_objetivo,
			giro_suave * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, velocidad)
		velocity.z = move_toward(velocity.z, 0.0, velocidad)

	move_and_slide()
```

5. Ejecuta. Orbita la cámara con el ratón alrededor del personaje; muévete con las teclas y verás que el modelo gira suavemente para encarar la dirección en que avanzas, siempre relativo a la cámara.
6. Camina hacia una pared con la cámara detrás: el `SpringArm3D` acerca la cámara para no atravesarla y la aleja de nuevo al despejarse.

## ✍️ Ejercicios

1. Añade zoom modificando `spring_length` con la rueda del ratón.
2. Invierte opcionalmente el eje Y de la cámara mediante una variable.
3. Ajusta `spring_length` y `collision_mask` del brazo para afinar la retracción.
4. Suaviza el pitch usando `lerp` en lugar de aplicarlo directo.
5. Añade una animación de correr según la magnitud de la velocidad horizontal.
6. Haz que el personaje no gire cuando la velocidad sea casi cero.

## 📝 Reto verificable

Entrega un controlador en tercera persona: cámara orbital con `SpringArm3D` que evita atravesar paredes, pitch clampeado, movimiento relativo a la cámara, y un modelo que rota suavemente (con `lerp_angle`) hacia la dirección de avance.

**Criterio de aceptación**: la cámara orbita con el ratón sin traspasar la geometría, el personaje se mueve relativo a la cámara y su modelo encara la dirección de avance con un giro suave, sin errores en consola.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La cámara atraviesa paredes | No usas `SpringArm3D` o su `collision_mask` no incluye las paredes. |
| El personaje gira a tirones | Aplicas el ángulo directo; usa `lerp_angle` con `delta`. |
| El giro salta 360° al cruzar ±180° | Usas `lerp` normal; `lerp_angle` toma el camino corto. |
| El movimiento no sigue la cámara | No rotas la entrada por el yaw del pivote. |
| La cámara se voltea | Falta `clamp` en `pivote.rotation.x`. |
| El SpringArm choca con el propio jugador | Excluye el cuerpo con `add_excluded_object` o ajusta la máscara. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué el SpringArm3D cuelga del pivote y no del cuerpo?** Porque el pivote orbita con el ratón; así el brazo y la cámara heredan el yaw y el pitch sin afectar al personaje.

**❓ ¿Qué hace `lerp_angle` distinto de `lerp`?** Interpola tomando el camino angular más corto, evitando giros absurdos al cruzar el límite de ±π.

**❓ ¿Cómo evito que la cámara detecte al propio jugador?** Configura la `collision_mask` del `SpringArm3D` para ignorar la capa del personaje.

**❓ ¿Puedo usar `look_at` en vez de `atan2`?** Sí, pero `look_at` reorienta todo el nodo; con `atan2` + `lerp_angle` controlas solo el yaw de forma suave.

## 🔗 Referencias

- SpringArm3D — API oficial: <https://docs.godotengine.org/en/stable/classes/class_springarm3d.html>
- Introduction to 3D: <https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html>
- CharacterBody3D: <https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html>

## ➡️ Siguiente clase

[Clase 057 - Colisiones y física 3D: cuerpos, formas y capas](../057-colisiones-y-fisica-3d-cuerpos-formas-y-capas/README.md)
