# Clase 079 — Proyectiles: balística, gravedad y predicción

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Eric Lengyel, Mathematics for 3D Game Programming · Documentación oficial de Godot 4 (RigidBody3D)*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dominar la física de proyectiles con gravedad: lanzar un objeto que describe una parábola, calcular la velocidad inicial necesaria para acertar a un punto dado, y predecir la posición futura de un blanco móvil para "adelantar" el disparo (*lead*). Combinarás simulación con `RigidBody3D` y las fórmulas de balística resueltas en GDScript.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Lanzar un proyectil con gravedad usando impulsos y explicar por qué su trayectoria es una parábola.
2. Derivar y aplicar la fórmula del alcance para obtener la velocidad inicial que acierta a una posición.
3. Elegir entre trayectoria tensa y trayectoria en arco cuando hay dos soluciones de ángulo.
4. Predecir la posición futura de un blanco móvil resolviendo el tiempo de intercepción.
5. Diagnosticar disparos que fallan por gravedad, escala o desincronización de física.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Movimiento parabólico | Todo proyectil con gravedad sigue una parábola |
| 2 | Descomposición de velocidad | Separar componentes horizontal y vertical |
| 3 | Tiempo de vuelo | Clave para saber dónde caerá el proyectil |
| 4 | Cálculo de velocidad inicial | Apuntar a un punto exacto, no "a ojo" |
| 5 | Dos soluciones de ángulo | Tiro tenso vs. tiro en arco (mortero) |
| 6 | Predicción de intercepción | Acertar a un enemigo que se mueve |
| 7 | Lead (adelanto) | Disparar donde *estará*, no donde está |
| 8 | Limitaciones | Sin solución si el objetivo está fuera de alcance |

## 📖 Definiciones y características

- **Proyectil**: cuerpo bajo la única influencia de la gravedad tras el lanzamiento (ignorando arrastre).
- **Trayectoria parabólica**: la posición cumple `p(t) = p₀ + v₀·t + ½·g·t²`.
- **Componente horizontal/vertical**: la velocidad se separa en avance (constante) y altura (afectada por la gravedad).
- **Tiempo de vuelo**: instante en que el proyectil alcanza la altura del objetivo.
- **Velocidad inicial (v₀)**: vector que hay que imprimir al proyectil para que pase por un punto dado.
- **Solución baja/alta**: dos ángulos posibles para el mismo alcance; el bajo es rápido y tenso, el alto es lento y en arco.
- **Lead / adelanto**: desplazar la mira hacia donde el blanco estará cuando el proyectil llegue.
- **Intercepción**: resolver el tiempo `t` en que proyectil y blanco móvil coinciden en el espacio.

## 🧰 Herramientas y preparación

Necesitas Godot 4.2+. Prepara una escena 3D con un cañón (un `Node3D` de origen), un proyectil como `RigidBody3D` con `CollisionShape3D`, y un objetivo. Verifica el valor de gravedad en *Project Settings → Physics → 3D → Default Gravity* (por defecto 9.8) porque las fórmulas deben usar ese mismo valor. Para depurar, dibuja la trayectoria prevista con puntos. Recuerda que la gravedad de Godot apunta hacia `-Y`. Consulta: <https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html> y el capítulo de cinemática de Lengyel.

## 🧪 Laboratorio guiado

### Paso 1 — Lanzar con gravedad

```gdscript
extends Node3D

@export var proyectil: PackedScene
@export var velocidad_salida: float = 20.0

func disparar(direccion: Vector3) -> void:
	var p: RigidBody3D = proyectil.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_position = global_position
	# Impulso inicial: la gravedad hará el resto (parábola).
	p.apply_central_impulse(direccion.normalized() * velocidad_salida * p.mass)
```

**Observable**: el proyectil sale recto y va cayendo describiendo un arco; a mayor `velocidad_salida`, más lejos llega antes de tocar el suelo.

### Paso 2 — Calcular la velocidad para acertar a un punto

Dado un objetivo y un ángulo de lanzamiento elegido, calculamos la rapidez necesaria. Trabajamos con la componente horizontal (distancia en el plano XZ) y la vertical (diferencia de altura).

```gdscript
# Devuelve el vector velocidad inicial para pasar por 'objetivo'
# con un 'angulo' de elevación dado. Vacío si no hay solución.
func velocidad_para_acertar(origen: Vector3, objetivo: Vector3,
		angulo_rad: float, gravedad: float) -> Vector3:
	var delta := objetivo - origen
	var dir_horiz := Vector3(delta.x, 0.0, delta.z)
	var dist := dir_horiz.length()          # alcance horizontal
	var altura := delta.y                    # desnivel (puede ser negativo)

	var cos_a := cos(angulo_rad)
	var tan_a := tan(angulo_rad)
	# Denominador de la ecuación balística.
	var denom := 2.0 * cos_a * cos_a * (dist * tan_a - altura)
	if denom <= 0.0:
		return Vector3.ZERO                  # sin solución con ese ángulo
	# Rapidez que satisface la ecuación balística para ese ángulo.
	var rapidez := sqrt(gravedad * dist * dist / denom)

	# Componer el vector final: horizontal + vertical.
	var v_horiz := dir_horiz.normalized() * rapidez * cos_a
	var v_vert := Vector3.UP * rapidez * sin(angulo_rad)
	return v_horiz + v_vert
```

**Observable**: aplica el vector devuelto como impulso (`impulso = v * mass`) y el proyectil impacta el objetivo. Cambia `angulo_rad` (p. ej. 30° vs 70°) para tiro tenso o en arco hacia el mismo blanco.

### Paso 3 — Predecir un blanco móvil (lead)

Si el blanco se mueve, apuntar a su posición actual falla. Estimamos dónde estará cuando llegue el proyectil y apuntamos ahí. Una aproximación robusta: iterar el tiempo de vuelo.

```gdscript
# Estima la posición de intercepción de un blanco que se mueve
# a 'vel_blanco' constante, con proyectil de rapidez 'rapidez_proj'.
func predecir_intercepcion(origen: Vector3, pos_blanco: Vector3,
		vel_blanco: Vector3, rapidez_proj: float) -> Vector3:
	var t := 0.0
	var punto := pos_blanco
	# Iteramos: con cada estimación de tiempo, refinamos el punto.
	for _i in range(6):
		var dist := origen.distance_to(punto)
		t = dist / rapidez_proj              # tiempo aproximado de vuelo
		punto = pos_blanco + vel_blanco * t  # dónde estará el blanco
	return punto
```

**Observable**: dispara a un objetivo que se desplaza lateralmente usando `predecir_intercepcion` como punto de mira; el proyectil lo alcanza en movimiento, mientras que apuntar a la posición actual falla por detrás.

## ✍️ Ejercicios

1. Dibuja la trayectoria prevista con 20 puntos evaluando `p(t) = p₀ + v₀·t + ½·g·t²`.
2. Devuelve las **dos** soluciones de ángulo para un alcance dado y deja elegir tenso o en arco.
3. Detecta y comunica cuándo el objetivo está fuera de alcance (sin solución real).
4. Combina la predicción de blanco móvil con el cálculo balístico para un mortero que anticipa al enemigo.
5. Añade arrastre simple (linear_damp) y observa cómo la fórmula ideal empieza a fallar.
6. Haz un indicador visual que muestre el punto de impacto estimado en tiempo real.

## 📝 Reto verificable

Implementa una torreta que dispare proyectiles con gravedad a un objetivo móvil: debe calcular la velocidad inicial para el alcance y adelantar el tiro según la velocidad del blanco, acertando de forma consistente mientras el blanco se mueve a velocidad constante.

**Criterio de aceptación**: con el blanco desplazándose lateralmente a velocidad constante, la torreta acierta en al menos 8 de 10 disparos; los proyectiles describen una parábola visible y el punto de mira se adelanta al blanco (no le dispara donde ya estuvo).

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El proyectil cae demasiado corto | La gravedad de la fórmula no coincide con la del proyecto. Usa el mismo valor. |
| Impulso vs. velocidad confundidos | `apply_central_impulse` recibe cantidad de movimiento. Multiplica la velocidad por `mass`. |
| Nunca acierta a blanco móvil | Apuntas a la posición actual. Usa la predicción de intercepción. |
| `sqrt` de número negativo | Objetivo fuera de alcance con ese ángulo. Comprueba el denominador antes de la raíz. |
| Trayectoria plana | La gravedad del cuerpo está desactivada (`gravity_scale = 0`). Actívala. |

## ❓ Preguntas frecuentes

**¿Simular con RigidBody o calcular la parábola a mano?** Para pocos proyectiles, `RigidBody3D` es cómodo; para cientos de balas, calcula la posición con la ecuación y sáltate la física del motor.

**¿Por qué dos ángulos para el mismo blanco?** El alcance es simétrico: un ángulo bajo (rápido y tenso) y otro alto (lento y en arco) llegan al mismo punto.

**¿La predicción funciona si el blanco acelera?** La versión iterativa asume velocidad constante; con aceleración, incorpora el término `½·a·t²` en la estimación.

**¿Afecta el arrastre del aire?** Las fórmulas ideales lo ignoran; con `linear_damp` alto, ajusta empíricamente o simula por pasos.

## 🔗 Referencias

- Godot Docs — RigidBody3D: <https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html>
- Godot Docs — Vector3 (math): <https://docs.godotengine.org/en/stable/classes/class_vector3.html>
- Eric Lengyel, *Mathematics for 3D Game Programming and Computer Graphics*, cinemática de proyectiles.
- Fiedler, *Gaffer On Games* — integración de movimiento: <https://gafferongames.com/post/integration_basics/>

## ➡️ Siguiente clase

[Clase 080 - Movimiento con curvas: Bézier, splines y paths](../080-movimiento-con-curvas-bezier-splines-y-paths/README.md)
