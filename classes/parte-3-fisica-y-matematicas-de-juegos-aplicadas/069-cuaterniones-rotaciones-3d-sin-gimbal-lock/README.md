# Clase 069 — Cuaterniones: rotaciones 3D sin gimbal lock

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Godot Engine 4.x — Using 3D transforms y clase Quaternion*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Entender por qué las rotaciones con ángulos de Euler fallan (gimbal lock) y cómo los **cuaterniones** las resuelven. Trabajaremos la intuición, no el álgebra pesada: te bastará saber crear un cuaternión a partir de un eje y un ángulo, componer rotaciones e interpolar suavemente entre orientaciones con `slerp`. Usaremos `Quaternion` y `Basis` de Godot 4.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar con un ejemplo qué es el **gimbal lock** y por qué aparece con Euler.
2. Construir un cuaternión con la forma **eje-ángulo** `Quaternion(eje, angulo)`.
3. **Componer** dos rotaciones multiplicando cuaterniones y respetar el orden.
4. Interpolar entre dos orientaciones con **`slerp`** para lograr giros suaves.
5. Convertir entre `Quaternion` y `Basis`, y aplicar el resultado al `transform` de un nodo 3D.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Rotaciones con Euler | Es lo intuitivo, pero tiene una trampa |
| 2 | Gimbal lock | Bloquea un eje y arruina cámaras y naves |
| 3 | Intuición del cuaternión | Eje de giro + cantidad de giro |
| 4 | Construcción eje-ángulo | Forma más práctica de crearlos |
| 5 | Composición por multiplicación | Encadenar rotaciones sin acumular error |
| 6 | Interpolación con slerp | Giros suaves de cámara y personajes |
| 7 | Quaternion ↔ Basis en Godot | Aplicar la rotación al mundo 3D |

## 📖 Definiciones y características

- **Ángulos de Euler**: tres rotaciones sucesivas (pitch, yaw, roll). Clave: dependen del orden y sufren gimbal lock.
- **Gimbal lock**: pérdida de un grado de libertad cuando dos ejes se alinean. Clave: ocurre cerca de ±90° en un eje.
- **Cuaternión**: representación de una rotación como eje unitario + ángulo, codificada en cuatro números. Clave: no sufre gimbal lock.
- **Eje-ángulo**: `Quaternion(eje_normalizado, angulo_rad)`. Clave: el eje **debe** estar normalizado.
- **Composición**: multiplicar cuaterniones combina rotaciones. Clave: `q2 * q1` aplica primero `q1`; el orden importa.
- **Slerp**: interpolación esférica que recorre el arco más corto entre dos orientaciones a velocidad constante. Clave: ideal para cámaras.
- **Basis**: matriz 3x3 que representa orientación (y escala). Clave: `Quaternion` y `Basis` son intercambiables en Godot.
- **Cuaternión unitario**: de longitud 1; solo estos representan rotaciones puras. Clave: usa `.normalized()` tras muchas operaciones.

## 🧰 Herramientas y preparación

Usa **Godot 4.x** con un proyecto 3D. Crea una escena con un `Node3D` raíz, un `MeshInstance3D` (una caja o cápsula sirve para ver la orientación) y una cámara. Consulta la referencia de [Quaternion](https://docs.godotengine.org/en/stable/classes/class_quaternion.html) y el tutorial [Using 3D transforms](https://docs.godotengine.org/en/stable/tutorials/3d/using_transforms.html). El giro será lo observable: verás la malla interpolar suavemente entre dos poses.

## 🧪 Laboratorio guiado

Rotaremos una malla suavemente entre dos orientaciones y luego demostraremos el problema de Euler.

**Paso 1 — Definir dos orientaciones con eje-ángulo.** Adjunta este script al `MeshInstance3D`.

```gdscript
extends MeshInstance3D

var q_inicio: Quaternion
var q_fin: Quaternion
var t := 0.0

func _ready() -> void:
	# Orientación inicial: sin rotar.
	q_inicio = Quaternion.IDENTITY
	# Orientación final: 120° alrededor de un eje diagonal.
	var eje := Vector3(1, 1, 0).normalized()
	q_fin = Quaternion(eje, deg_to_rad(120.0))
```

**Paso 2 — Interpolar con slerp cada frame.**

```gdscript
func _physics_process(delta: float) -> void:
	t = min(t + delta * 0.5, 1.0)  # avanza durante 2 segundos
	var q := q_inicio.slerp(q_fin, t)
	transform.basis = Basis(q)  # aplica la rotación a la malla
```

Ejecuta la escena (F6). La malla gira de forma fluida, sin tirones, y se detiene en la pose final. Cambia `t` para que rebote (invierte la dirección al llegar a 1) y observa el giro de ida y vuelta.

**Paso 3 — Componer rotaciones.** Añade un giro extra de 45° sobre Y sin recalcular todo:

```gdscript
	var giro_extra := Quaternion(Vector3.UP, deg_to_rad(45.0))
	var q_total := giro_extra * q  # primero q, luego el giro extra
	transform.basis = Basis(q_total)
```

**Paso 4 — Demostrar gimbal lock con Euler.** En un script aparte, rota con Euler llevando el pitch a 90° y observa que yaw y roll se vuelven el mismo eje:

```gdscript
func demostrar_gimbal() -> void:
	var pitch := deg_to_rad(90.0)  # eje X al límite
	var yaw := deg_to_rad(30.0)
	var roll := deg_to_rad(30.0)
	var b := Basis.from_euler(Vector3(pitch, yaw, roll))
	# Con pitch = 90°, cambiar yaw o roll produce el MISMO giro visible:
	print("euler recuperado: ", b.get_euler())  # los ejes se confunden
```

Verás que al recuperar los ángulos, yaw y roll ya no son independientes: eso es gimbal lock. El cuaternión del Paso 1-2 nunca tiene ese problema.

## ✍️ Ejercicios

1. Crea un cuaternión que gire 90° alrededor de `Vector3.RIGHT` y aplícalo a la malla.
2. Interpola con `slerp` entre tres poses en secuencia (A→B→C) usando dos tramos.
3. Compara visualmente `slerp` con una interpolación lineal ingenua de Euler y describe la diferencia.
4. Compón dos giros y verifica que `q2 * q1` difiere de `q1 * q2` (la rotación no es conmutativa).
5. Normaliza un cuaternión tras multiplicarlo 100 veces y compara su longitud antes y después.
6. Convierte un `Basis` de la cámara a `Quaternion` con `transform.basis.get_rotation_quaternion()`.

## 📝 Reto verificable

Programa una torreta 3D que apunte suavemente a un objetivo: cada frame calcula el cuaternión que mira hacia el objetivo (`Quaternion` desde una `Basis` construida con `looking_at`) e interpola desde la orientación actual con `slerp` a velocidad configurable.

**Criterio de aceptación**: al mover el objetivo a una nueva posición, la torreta gira sin saltos y queda apuntando al objetivo en menos de 2 segundos, sin bloquearse aunque el objetivo pase justo por encima (pitch cercano a 90°).

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La rotación sale deformada o escala la malla | Pasaste un cuaternión no normalizado; usa `.normalized()` |
| El giro va por el camino largo | Los cuaterniones tienen doble cobertura; `slerp` de Godot ya elige el arco corto, revisa que no niegues uno |
| El orden de la rotación es incorrecto | Recuerda: `q2 * q1` aplica `q1` primero; invierte el orden |
| `Quaternion(eje, ang)` da resultados raros | El eje no estaba normalizado; llama `.normalized()` |
| Cerca de 90° la cámara "salta" | Estás usando Euler; migra a cuaterniones o a `looking_at` |

## ❓ Preguntas frecuentes

**¿Necesito entender el álgebra de cuaterniones?** No para usarlos. Basta con crear eje-ángulo, multiplicar para componer e interpolar con `slerp`. La intuición "eje + cuánto giro" es suficiente.

**¿Cuándo uso Euler entonces?** Para exponer valores legibles en el editor o entradas simples (girar 90° en un eje). Para rotaciones dinámicas y cámaras, cuaterniones.

**¿`slerp` o `lerp` entre cuaterniones?** `slerp` mantiene velocidad angular constante y sigue el arco esférico; `lerp` (o `nlerp`) es más rápido pero puede acelerar en el medio. Para cámaras suaves, `slerp`.

**¿`Basis` y `Quaternion` son lo mismo?** Representan la misma orientación. `Basis` es una matriz (puede incluir escala); `Quaternion` es compacto y estable para interpolar. Godot convierte entre ambos.

## 🔗 Referencias

1. Godot Engine — Clase Quaternion: <https://docs.godotengine.org/en/stable/classes/class_quaternion.html>
2. Godot Engine — Using 3D transforms: <https://docs.godotengine.org/en/stable/tutorials/3d/using_transforms.html>
3. Godot Engine — Clase Basis: <https://docs.godotengine.org/en/stable/classes/class_basis.html>

## ➡️ Siguiente clase

[Clase 070 - Integración numérica en la práctica (Euler y Verlet)](../070-integracion-numerica-en-la-practica-euler-y-verlet/README.md)
