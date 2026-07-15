# Clase 055 — Controlador en primera persona (FPS)

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Godot Engine 4 — Documentación oficial: Mouse and input coordinates, CharacterBody3D*
> ⏱️ Duración estimada: **65 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Construir un **controlador en primera persona** completo en Godot 4: capturar el ratón para el **mouse look**, girar el **cuerpo** en el eje Y y la **cabeza/cámara** en el eje X con un **clamp** para no voltear la vista, moverse con WASD y saltar, separando el nodo de la cabeza del cuerpo.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Capturar y liberar el ratón con `Input.MOUSE_MODE_CAPTURED`.
2. Implementar mouse look leyendo `event.relative` en `_unhandled_input`.
3. Separar la rotación horizontal (cuerpo) de la vertical (cabeza) y limitar el pitch con `clamp`.
4. Integrar el movimiento WASD relativo a la orientación del cuerpo.
5. Estructurar la jerarquía de nodos cuerpo → cabeza → cámara de forma robusta.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Captura del ratón | Permite mirar libremente sin salir de la ventana. |
| 2 | _unhandled_input | Lugar adecuado para leer el movimiento del ratón. |
| 3 | event.relative | Delta del ratón para rotar la vista. |
| 4 | Yaw en el cuerpo | Girar horizontalmente todo el personaje. |
| 5 | Pitch en la cabeza | Mirar arriba/abajo sin inclinar el cuerpo. |
| 6 | Clamp del pitch | Evita voltear la cámara boca abajo. |
| 7 | Movimiento relativo al cuerpo | Adelante = hacia donde mira el jugador. |
| 8 | Jerarquía de nodos | Orden cuerpo→cabeza→cámara para rotaciones limpias. |

## 📖 Definiciones y características

- **MOUSE_MODE_CAPTURED**: oculta y fija el cursor al centro, entregando solo deltas. Clave: imprescindible para un FPS.
- **_unhandled_input(event)**: recibe eventos no consumidos por la UI. Clave: ideal para `InputEventMouseMotion`.
- **event.relative**: `Vector2` con el desplazamiento del ratón desde el último frame. Clave: base del mouse look.
- **Yaw**: rotación horizontal (eje Y). Clave: se aplica al `CharacterBody3D` (cuerpo).
- **Pitch**: rotación vertical (eje X). Clave: se aplica a la cabeza, no al cuerpo.
- **clamp**: acota un valor entre mínimo y máximo. Clave: limita el pitch a unos ±89°.
- **deg_to_rad**: convierte grados a radianes. Clave: `rotation` está en radianes.
- **Nodo cabeza**: `Node3D` intermedio que sostiene la cámara. Clave: aísla el pitch del yaw.

## 🧰 Herramientas y preparación

Usa **Godot 4.x** con un nivel simple (suelo con colisión, algunas paredes y cajas como referencia visual). Define en el **Input Map** las acciones `mover_izquierda`, `mover_derecha`, `mover_adelante`, `mover_atras` y `saltar`. Consulta la captura del ratón en <https://docs.godotengine.org/en/stable/tutorials/inputs/mouse_and_input_coordinates.html> y la API de `Input` en <https://docs.godotengine.org/en/stable/classes/class_input.html>. Descarga el motor: <https://godotengine.org/download>.

## 🧪 Laboratorio guiado

1. Crea una escena con raíz `CharacterBody3D` llamada `JugadorFPS`. Agrégale un `CollisionShape3D` con `CapsuleShape3D`.
2. Añade como hijo un `Node3D` llamado `Cabeza`, situado a la altura de los ojos (`position = Vector3(0, 1.6, 0)`). Dentro de `Cabeza`, añade una `Camera3D`.
3. Verifica la jerarquía: `JugadorFPS` (yaw) → `Cabeza` (pitch) → `Camera3D`.
4. Asigna este script al nodo `JugadorFPS`:

```gdscript
extends CharacterBody3D

@export var velocidad: float = 5.0
@export var fuerza_salto: float = 4.5
@export var sensibilidad: float = 0.003

var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var cabeza: Node3D = $Cabeza

func _ready() -> void:
	# Capturar el ratón al iniciar.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Yaw: girar el cuerpo en Y.
		rotate_y(-event.relative.x * sensibilidad)
		# Pitch: girar la cabeza en X con clamp.
		cabeza.rotate_x(-event.relative.y * sensibilidad)
		cabeza.rotation.x = clamp(cabeza.rotation.x,
			deg_to_rad(-89.0), deg_to_rad(89.0))
	# Liberar el ratón con Escape.
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravedad * delta

	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = fuerza_salto

	# Entrada de teclado.
	var entrada := Input.get_vector("mover_izquierda", "mover_derecha",
		"mover_adelante", "mover_atras")

	# Dirección relativa a la orientación del cuerpo.
	# -transform.basis.z es el "adelante" local tras el yaw.
	var direccion := (transform.basis * Vector3(entrada.x, 0.0, entrada.y)).normalized()

	if direccion != Vector3.ZERO:
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
	else:
		velocity.x = move_toward(velocity.x, 0.0, velocidad)
		velocity.z = move_toward(velocity.z, 0.0, velocidad)

	move_and_slide()
```

5. Ejecuta. Mueve el ratón: el cuerpo gira horizontalmente y la cámara mira arriba/abajo sin pasar de ±89°. Camina con las teclas relativas a hacia donde mires y salta desde el suelo.
6. Pulsa **Escape** para recuperar el cursor; vuelve a hacer clic en la ventana o reinicia para recapturarlo.

## ✍️ Ejercicios

1. Añade una acción para recapturar el ratón al hacer clic dentro de la ventana.
2. Expón la `sensibilidad` en un menú y ajústala en vivo.
3. Añade balanceo de cámara (head bob) al caminar usando una onda seno.
4. Implementa agacharse reduciendo la altura de la cápsula y de la cabeza.
5. Muestra un punto de mira (crosshair) centrado con un `Control`.
6. Limita la velocidad al agacharse y en el aire.

## 📝 Reto verificable

Entrega un controlador FPS jugable en un nivel con paredes: mouse look con pitch clampeado a ±89°, movimiento WASD relativo a la vista, salto desde el suelo y liberación/recaptura del ratón con Escape/clic.

**Criterio de aceptación**: el jugador mira con el ratón sin voltear la cámara, se mueve relativo a su orientación, salta solo desde el suelo, y el ratón se libera con Escape y se recaptura al hacer clic, sin errores en consola.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El cursor se ve y no rota | Falta `Input.mouse_mode = Input.MOUSE_MODE_CAPTURED`. |
| La cámara se voltea boca abajo | No hay `clamp` del pitch; acótalo con `deg_to_rad(±89)`. |
| El cuerpo se inclina al mirar arriba | Aplicas el pitch al cuerpo; debe ir en la cabeza. |
| El movimiento no sigue la vista | No multiplicas por `transform.basis`; usa la base del cuerpo. |
| El ratón nunca se libera | No manejas `ui_cancel`; añade el cambio a `MOUSE_MODE_VISIBLE`. |
| Giro demasiado rápido o brusco | Sensibilidad alta; reduce el multiplicador. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué separar cabeza y cuerpo?** Así el yaw rota todo el personaje (y con él el movimiento) mientras el pitch solo inclina la vista, evitando inclinar el cuerpo.

**❓ ¿Por qué usar `_unhandled_input` y no `_input`?** Para que la UI pueda consumir eventos primero; el mouse look solo actúa sobre lo que no capturó la interfaz.

**❓ ¿`event.relative` depende de los FPS?** Es el delta acumulado del ratón entre eventos; multiplicarlo por la sensibilidad da un giro consistente.

**❓ ¿Puedo usar `rotation_degrees` en la cabeza?** Sí, pero recuerda que `clamp` y `deg_to_rad` trabajan en radianes si operas sobre `rotation.x`.

## 🔗 Referencias

- Mouse and input coordinates: <https://docs.godotengine.org/en/stable/tutorials/inputs/mouse_and_input_coordinates.html>
- Input — API oficial: <https://docs.godotengine.org/en/stable/classes/class_input.html>
- CharacterBody3D: <https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html>

## ⬅️ Clase anterior

[Clase 054 - Movimiento 3D: CharacterBody3D y move_and_slide](../054-movimiento-3d-characterbody3d-y-move-and-slide/README.md)

## ➡️ Siguiente clase

[Clase 056 - Controlador en tercera persona con cámara orbital](../056-controlador-en-tercera-persona-con-camara-orbital/README.md)
