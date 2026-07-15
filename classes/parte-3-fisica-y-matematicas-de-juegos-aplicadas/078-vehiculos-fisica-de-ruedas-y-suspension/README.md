# Clase 078 — Vehículos: física de ruedas y suspensión

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Documentación oficial de Godot 4 (VehicleBody3D) · Ian Millington, Game Physics Engine Development*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Construir un coche controlable en Godot 4 con `VehicleBody3D` y `VehicleWheel3D`. Aprenderás a aplicar fuerza de motor (`engine_force`), dirección (`steering`) y freno (`brake`), a configurar la suspensión de cada rueda, y a entender cómo el centro de masa determina la estabilidad y el riesgo de vuelco.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Montar un vehículo con `VehicleBody3D` y cuatro `VehicleWheel3D` correctamente posicionadas.
2. Controlar aceleración, dirección y freno leyendo la entrada del jugador en `_physics_process`.
3. Configurar la suspensión (rigidez, recorrido, amortiguación) y explicar su efecto en la conducción.
4. Distinguir las ruedas de tracción de las de dirección mediante sus banderas.
5. Ajustar el centro de masa para reducir el vuelco sin perder agarre.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | VehicleBody3D | El chasis: un RigidBody especializado en ruedas |
| 2 | VehicleWheel3D | Cada rueda simula contacto, suspensión y fricción |
| 3 | engine_force | Aplica el par motor a las ruedas de tracción |
| 4 | steering | Ángulo de giro de las ruedas directrices |
| 5 | brake | Frenado; distinto de soltar el acelerador |
| 6 | Suspensión | Absorbe baches y mantiene las ruedas en el suelo |
| 7 | Centro de masa | Bajo = estable; alto = propenso al vuelco |
| 8 | Fricción de rueda | Determina el agarre y el derrape |

## 📖 Definiciones y características

- **VehicleBody3D**: `RigidBody3D` especializado que coordina las ruedas para simular un vehículo; recibe el motor y el freno.
- **VehicleWheel3D**: nodo hijo que representa una rueda; calcula su propio contacto con el suelo y suspensión.
- **engine_force**: fuerza (par) aplicada a las ruedas marcadas como de tracción; positiva acelera, negativa da marcha atrás.
- **steering**: ángulo en radianes que giran las ruedas directrices; interpolarlo suaviza el volante.
- **brake**: fuerza de frenado aplicada a las ruedas; frena hasta detener.
- **use_as_traction**: bandera que marca una rueda como propulsora (recibe `engine_force`).
- **use_as_steering**: bandera que marca una rueda como directriz (recibe `steering`).
- **Suspensión** (`suspension_stiffness`, `suspension_travel`, `damping`): sistema resorte-amortiguador que mantiene el neumático pegado al terreno.

## 🧰 Herramientas y preparación

Necesitas Godot 4.2+. Crea un `VehicleBody3D` con un `CollisionShape3D` (caja) como chasis, una malla visual, y cuatro `VehicleWheel3D` posicionadas en las esquinas inferiores del chasis (la posición **Y** de la rueda marca dónde nace la suspensión). Añade un `MeshInstance3D` a cada rueda. Necesitas un terreno con colisión: un `StaticBody3D` amplio o un `GridMap`/malla de pista. Activa **Debug → Visible Collision Shapes** para ver los rayos de suspensión de cada rueda. Consulta: <https://docs.godotengine.org/en/stable/classes/class_vehiclebody3d.html> y <https://docs.godotengine.org/en/stable/classes/class_vehiclewheel3d.html>.

## 🧪 Laboratorio guiado

### Paso 1 — Configurar las ruedas

En el inspector de cada `VehicleWheel3D`: marca las **delanteras** con `use_as_steering = true`, y las que den tracción (traseras para propulsión trasera, o las cuatro) con `use_as_traction = true`. Ajusta `wheel_radius` al radio de la malla y coloca cada rueda en su esquina.

### Paso 2 — Control del coche

```gdscript
extends VehicleBody3D

@export var fuerza_motor: float = 250.0
@export var giro_max: float = 0.5      # radianes (~28°)
@export var fuerza_freno: float = 8.0

func _physics_process(_delta: float) -> void:
	# Aceleración adelante/atrás.
	var acelerador := Input.get_axis("frenar", "acelerar")
	engine_force = acelerador * fuerza_motor

	# Dirección: interpolo hacia el objetivo para un volante suave.
	var giro_objetivo := Input.get_axis("derecha", "izquierda") * giro_max
	steering = move_toward(steering, giro_objetivo, 2.5 * _delta)

	# Freno de mano con la barra espaciadora.
	brake = fuerza_freno if Input.is_action_pressed("freno_mano") else 0.0
```

**Observable**: el coche acelera y retrocede, gira con un volante que no es instantáneo, y se detiene con el freno de mano. Configura las acciones de entrada en *Project Settings → Input Map*.

### Paso 3 — Ajustar la suspensión

En cada `VehicleWheel3D`, valores de partida razonables:

```gdscript
# En _ready() o desde el inspector, por rueda:
func configurar_suspension(rueda: VehicleWheel3D) -> void:
	rueda.suspension_stiffness = 20.0   # rigidez del resorte
	rueda.suspension_travel = 0.2       # recorrido máximo (m)
	rueda.damping_compression = 0.6     # amortiguación al comprimir
	rueda.damping_relaxation = 0.8      # amortiguación al extender
	rueda.wheel_friction_slip = 3.0     # agarre lateral/longitudinal
```

**Observable**: sube y baja `suspension_stiffness` y verás el coche más firme o más "blando" al pasar baches; reducir `wheel_friction_slip` provoca derrapes.

### Paso 4 — Bajar el centro de masa

Un centro de masa alto vuelca el coche en las curvas. Bájalo desplazando el chasis o usando un `CenterOfMass` explícito.

```gdscript
func _ready() -> void:
	# Coloco el centro de masa por debajo del origen del chasis.
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.4, 0)
```

**Observable**: con el centro de masa bajo, el coche aguanta curvas cerradas sin volcar; súbelo a `+0.4` y volcará con facilidad.

## ✍️ Ejercicios

1. Muestra la velocidad en km/h en pantalla usando `linear_velocity.length() * 3.6`.
2. Implementa tracción total y compárala con tracción trasera en aceleración y derrape.
3. Añade un límite de `engine_force` que decrezca con la velocidad (simula un motor que pierde empuje).
4. Haz que las ruedas traseras derrapen más (menor `wheel_friction_slip`) para un estilo *arcade*.
5. Crea una rampa y ajusta la suspensión para que el aterrizaje no rebote descontrolado.
6. Añade luces de freno que se enciendan cuando `brake > 0`.

## 📝 Reto verificable

Construye un circuito con al menos una curva cerrada y una rampa, y un coche jugable que lo recorra: debe acelerar, frenar, girar con volante suave y no volcar en la curva cerrada a velocidad de crucero.

**Criterio de aceptación**: el coche completa una vuelta al circuito controlado por teclado, mantiene las cuatro ruedas en contacto en terreno plano, no vuelca en la curva cerrada a velocidad normal, y la suspensión absorbe la rampa sin salir despedido de forma incontrolable.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El coche no se mueve | `engine_force` aplicado a ruedas sin `use_as_traction`. Marca las ruedas de tracción. |
| No gira | Ninguna rueda tiene `use_as_steering`. Marca las delanteras como directrices. |
| Vuelca en cada curva | Centro de masa demasiado alto. Bájalo con `center_of_mass`. |
| Rebota como pelota | Suspensión sin amortiguación. Sube `damping_compression`/`damping_relaxation`. |
| Las ruedas atraviesan el suelo | Radio o posición de rueda mal, o suelo sin colisión. Ajusta `wheel_radius` y verifica el terreno. |

## ❓ Preguntas frecuentes

**¿VehicleBody3D o física propia con raycasts?** `VehicleBody3D` es rápido de montar y realista; un modelo *arcade* con raycasts da más control artístico pero cuesta más código.

**¿Por qué mi coche tiembla parado?** Suspensión demasiado rígida o `wheel_friction_slip` muy alto; suaviza ambos.

**¿Cómo hago marcha atrás?** Aplica `engine_force` negativa cuando la velocidad hacia adelante sea baja.

**¿El freno es lo mismo que dejar de acelerar?** No: soltar el acelerador deja rodar por inercia; `brake` aplica una fuerza que detiene activamente.

## 🔗 Referencias

- Godot Docs — VehicleBody3D: <https://docs.godotengine.org/en/stable/classes/class_vehiclebody3d.html>
- Godot Docs — VehicleWheel3D: <https://docs.godotengine.org/en/stable/classes/class_vehiclewheel3d.html>
- Godot Docs — RigidBody3D (centro de masa): <https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html>
- Ian Millington, *Game Physics Engine Development*, sección de vehículos y fuerzas.

## ⬅️ Clase anterior

[Clase 077 - Ragdolls y física de personajes](../077-ragdolls-y-fisica-de-personajes/README.md)

## ➡️ Siguiente clase

[Clase 079 - Proyectiles: balística, gravedad y predicción](../079-proyectiles-balistica-gravedad-y-prediccion/README.md)
