# Clase 076 — Juntas y restricciones (joints): bisagras y resortes

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Ian Millington, Game Physics Engine Development · Documentación oficial de Godot 4 (Joints)*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Aprender a conectar cuerpos rígidos con **joints** (juntas) en Godot 4 para construir mecanismos: una puerta con bisagra, una cadena de eslabones y un resorte amortiguado. Entenderás qué grados de libertad restringe cada tipo de junta, cómo aplicar límites y motores, y por qué el orden de conexión y el reposo de los cuerpos importan.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diferenciar `PinJoint3D`, `HingeJoint3D` y `Generic6DOFJoint3D` según los grados de libertad que fijan.
2. Montar una puerta funcional con `HingeJoint3D`, límites de ángulo y opcionalmente un motor.
3. Construir una cadena de eslabones encadenando varios `PinJoint3D` entre `RigidBody3D`.
4. Crear un resorte amortiguado en 2D con `DampedSpringJoint2D` y ajustar su rigidez y amortiguación.
5. Diagnosticar juntas inestables (jitter, explosiones) y aplicar masas y anclajes correctos.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es una restricción | Reduce grados de libertad entre dos cuerpos |
| 2 | PinJoint (punto fijo) | Base de cadenas, péndulos y colgantes |
| 3 | HingeJoint (bisagra) | Puertas, palancas, ruedas de compuerta |
| 4 | Límites de ángulo | Evitan que una puerta gire 360° |
| 5 | Motores en juntas | Mover una bisagra activamente (compuertas automáticas) |
| 6 | Resortes y amortiguación | Suspensiones, trampolines, cuerdas elásticas |
| 7 | Cadenas de eslabones | Propagación de fuerzas a través de varios cuerpos |
| 8 | Estabilidad numérica | Masas y anclajes mal puestos "explotan" el sistema |

## 📖 Definiciones y características

- **Joint (junta)**: nodo que impone una restricción entre dos cuerpos físicos (o un cuerpo y el mundo).
- **PinJoint3D**: fija un punto común entre dos cuerpos; permite rotación libre alrededor de ese punto (como una rótula).
- **HingeJoint3D**: permite rotación en **un** solo eje, como la bisagra de una puerta; admite límites y motor.
- **Generic6DOFJoint3D**: junta configurable donde eliges qué ejes de traslación y rotación se restringen o liberan.
- **DampedSpringJoint2D**: une dos cuerpos con un resorte de longitud de reposo, rigidez (`stiffness`) y amortiguación (`damping`).
- **Límite (limit)**: rango angular o lineal permitido por la junta; fuera de él, la junta empuja de vuelta.
- **Motor de junta**: aplica una velocidad objetivo a la junta para moverla activamente.
- **Anclaje (node_a / node_b)**: los dos cuerpos que conecta; si `node_b` queda vacío, se ancla al mundo.

## 🧰 Herramientas y preparación

Necesitas Godot 4.2+. Trabaja en 3D con `RigidBody3D` para la puerta y la cadena, y en 2D con `RigidBody2D` para el resorte. Activa **Debug → Visible Collision Shapes** y considera bajar la gravedad temporalmente en *Project Settings* para observar el reposo con calma. Un marco de referencia (el poste de la puerta) debe ser un `StaticBody3D` o un `RigidBody3D` en modo estático para servir de anclaje fijo. Consulta la documentación de juntas: <https://docs.godotengine.org/en/stable/classes/class_hingejoint3d.html> y <https://docs.godotengine.org/en/stable/classes/class_dampedspringjoint2d.html>.

## 🧪 Laboratorio guiado

### Paso 1 — Puerta con HingeJoint3D

Necesitas un poste estático (`marco`) y una hoja (`RigidBody3D`). El `HingeJoint3D` los conecta y limita el giro.

```gdscript
extends Node3D

@onready var bisagra: HingeJoint3D = $HingeJoint3D

func _ready() -> void:
	bisagra.node_a = $Marco.get_path()   # cuerpo estático (poste)
	bisagra.node_b = $Hoja.get_path()    # la puerta que gira

	# Limito el giro entre -90° y +90° para que no dé la vuelta.
	bisagra.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	bisagra.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-90))
	bisagra.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(90))

func abrir_con_motor() -> void:
	# Motor: empuja la puerta a abrirse sola.
	bisagra.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
	bisagra.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 2.0)
	bisagra.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 8.0)
```

**Observable**: empuja la hoja con otro objeto y oscilará dentro de ±90° sin dar vueltas; al llamar `abrir_con_motor()` la puerta se abre por sí sola.

### Paso 2 — Cadena de eslabones con PinJoint3D

Instanciamos varios eslabones y unimos cada uno al anterior con un `PinJoint3D`. El primero se ancla a un punto fijo.

```gdscript
@export var eslabon: PackedScene
@export var n_eslabones: int = 6

func construir_cadena(ancla: Node3D) -> void:
	var anterior: PhysicsBody3D = ancla
	for i in range(n_eslabones):
		var nuevo: RigidBody3D = eslabon.instantiate()
		nuevo.position = ancla.position + Vector3(0, -0.5 * (i + 1), 0)
		add_child(nuevo)

		var pin := PinJoint3D.new()
		add_child(pin)
		# Coloco el pin en la unión entre los dos cuerpos.
		pin.global_position = (anterior.global_position + nuevo.global_position) * 0.5
		pin.node_a = anterior.get_path()
		pin.node_b = nuevo.get_path()
		anterior = nuevo
```

**Observable**: la cadena cuelga del ancla y se balancea de forma realista; si empujas el último eslabón, el movimiento se propaga hacia arriba.

### Paso 3 — Resorte amortiguado en 2D

```gdscript
extends Node2D

@onready var resorte: DampedSpringJoint2D = $DampedSpringJoint2D

func _ready() -> void:
	resorte.node_a = $Techo.get_path()   # anclaje fijo
	resorte.node_b = $Peso.get_path()    # RigidBody2D colgante
	resorte.rest_length = 80.0           # longitud en reposo (px)
	resorte.stiffness = 20.0             # rigidez: mayor = más duro
	resorte.damping = 1.0                # amortiguación: frena la oscilación
```

**Observable**: el peso rebota y se estabiliza en la longitud de reposo; sube `stiffness` para un resorte más duro y `damping` para que deje de oscilar antes.

## ✍️ Ejercicios

1. Añade un `PARAM_MOTOR_TARGET_VELOCITY` negativo para cerrar la puerta automáticamente tras un retardo.
2. Cambia la masa de la hoja de la puerta y observa cómo afecta a la fuerza necesaria para abrirla.
3. Haz que la cadena termine en una bola pesada (mayor `mass`) y compara el balanceo.
4. Con el resorte, prueba `damping = 0` y explica por qué oscila indefinidamente.
5. Sustituye un `PinJoint3D` de la cadena por un `HingeJoint3D` limitado y describe la diferencia de movimiento.
6. Usa un `Generic6DOFJoint3D` para crear una junta que solo permita deslizamiento vertical (como un pistón).

## 📝 Reto verificable

Construye un puente colgante jugable: una serie de tablones (`RigidBody3D`) unidos por `PinJoint3D` entre dos torres estáticas, sobre el que un `CharacterBody3D` pueda caminar y hacer que el puente se hunda y se balancee de forma estable.

**Criterio de aceptación**: el personaje cruza el puente sin que este "explote" ni atraviese los tablones; el puente se comba bajo el peso y vuelve a su forma al pasar el personaje, todo sin jitter perceptible.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La junta "explota" al iniciar | Los cuerpos se superponen o el anclaje está mal ubicado. Sepáralos y coloca el joint en la unión real. |
| La cadena tiembla (jitter) | Diferencias de masa enormes entre eslabones o pocas iteraciones. Iguala masas y sube el sub-stepping. |
| La puerta gira sin límite | No activaste `FLAG_USE_LIMIT`. Habilítalo y define límites inferior/superior. |
| El resorte no reacciona | `node_a`/`node_b` sin asignar o `stiffness` muy baja. Asigna ambos cuerpos y sube la rigidez. |
| Un cuerpo del joint no se mueve | Está en modo estático o `freeze` activo. Solo un extremo debe ser el anclaje fijo. |

## ❓ Preguntas frecuentes

**¿Qué junta uso para una rueda que rota libremente?** `HingeJoint3D` con el eje alineado al giro y sin límites; para tracción, activa el motor.

**¿Por qué mi cadena atraviesa el suelo?** Las juntas no dan colisión; cada eslabón necesita su propio `CollisionShape3D` y capas correctas.

**¿Puedo conectar un joint al mundo fijo?** Sí: deja `node_a` apuntando a un `StaticBody3D` (o un cuerpo en modo estático) que actúe de anclaje.

**¿Resorte con DampedSpringJoint o con código?** El nodo cubre casos comunes; para control fino (fuerza `F = -k·x - c·v`) aplica tú la fuerza con `apply_central_force`.

## 🔗 Referencias

- Godot Docs — HingeJoint3D: <https://docs.godotengine.org/en/stable/classes/class_hingejoint3d.html>
- Godot Docs — DampedSpringJoint2D: <https://docs.godotengine.org/en/stable/classes/class_dampedspringjoint2d.html>
- Godot Docs — Generic6DOFJoint3D: <https://docs.godotengine.org/en/stable/classes/class_generic6dofjoint3d.html>
- Ian Millington, *Game Physics Engine Development*, capítulos sobre restricciones y contactos.

## ⬅️ Clase anterior

[Clase 075 - Motores de física: broadphase y narrowphase](../075-motores-de-fisica-broadphase-y-narrowphase/README.md)

## ➡️ Siguiente clase

[Clase 077 - Ragdolls y física de personajes](../077-ragdolls-y-fisica-de-personajes/README.md)
