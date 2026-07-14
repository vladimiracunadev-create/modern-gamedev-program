# Clase 083 — Física de partículas y telas (soft bodies)

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Thomas Jakobsen — "Advanced Character Physics" (integración de Verlet) y Godot 4.x SoftBody3D*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Simular cuerpos deformables —cuerdas, telas, gelatinas— con el modelo **masa-resorte** y la **integración de Verlet**, una técnica sencilla y estable que mueve puntos sin almacenar velocidad explícita y mantiene la forma con **constraints de distancia**. Implementarás una cuerda que cuelga y se balancea, entenderás por qué Verlet resiste bien las restricciones, y conocerás cuándo conviene usar el nodo `SoftBody3D` del motor en lugar de programar la simulación.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Describir un sistema **masa-resorte** y qué representan puntos y constraints.
2. Explicar la **integración de Verlet** y por qué deriva la velocidad de la diferencia de posiciones.
3. Aplicar **constraints de distancia** iterativos para mantener la longitud de una cuerda o tela.
4. Implementar en código una cuerda que cuelga, se estira poco y se balancea con gravedad.
5. Decidir entre una simulación propia (Verlet) y el nodo **SoftBody3D** según el caso.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Punto de masa (posición + posición previa) | Unidad básica de Verlet |
| 2 | Integración de Verlet | Estable y simple, sin guardar velocidad |
| 3 | Gravedad y fuerzas externas | Dan movimiento y peso |
| 4 | Constraint de distancia | Mantiene la cuerda/tela unida |
| 5 | Iteraciones de relajación | Más iteraciones = tela más rígida |
| 6 | Puntos fijos (anclajes) | Cuelgan o sujetan la estructura |
| 7 | SoftBody3D del motor | Alternativa lista para malla 3D |

## 📖 Definiciones y características

- **Punto de masa**: partícula con posición actual y posición anterior. Clave: la velocidad está implícita en su diferencia.
- **Integración de Verlet**: `nueva = actual + (actual - previa) + aceleración·dt²`. Clave: no guarda velocidad, absorbe bien las correcciones.
- **Constraint de distancia**: fuerza a dos puntos a mantener una separación fija. Clave: se resuelve empujándolos mitad y mitad.
- **Relajación iterativa**: aplicar los constraints varias veces por frame. Clave: más pasadas endurecen la tela pero cuestan CPU.
- **Anclaje (punto fijo)**: partícula que no se integra. Clave: define de dónde cuelga la cuerda.
- **Amortiguación**: factor que reduce la "velocidad" implícita. Clave: evita oscilaciones eternas.
- **Sistema masa-resorte**: red de puntos unidos por resortes/constraints. Clave: modela cuerdas (cadena) y telas (rejilla).
- **`SoftBody3D`**: nodo de Godot que hace deformable una malla. Clave: usa `simulation_precision` y puntos fijados; ideal para banderas y cojines.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x** ([godotengine.org](https://godotengine.org)) para la parte visual; la lógica de Verlet es matemática pura y también la incluimos en **Python** para estudiarla aislada. En Godot crea un proyecto 2D con un `Node2D` raíz: dibujaremos la cuerda con `_draw()` (líneas y círculos), sin sprites. Ten a mano la documentación de [SoftBody3D](https://docs.godotengine.org/en/stable/classes/class_softbody3d.html) y el clásico artículo de Jakobsen. La cuerda será una lista de puntos unidos por constraints; el anclaje será el primero.

## 🧪 Laboratorio guiado

Simularemos una cuerda con Verlet en Godot y dejaremos una versión en Python puro para comparar el algoritmo sin motor.

**Paso 1 — Estructura de la cuerda (Verlet en Godot).** Adjunta este script a un `Node2D`. Cada punto guarda posición actual y previa.

```gdscript
extends Node2D

@export var num_puntos := 20
@export var seg_long := 18.0        # longitud de cada segmento
@export var gravedad := Vector2(0, 980)
@export var iteraciones := 12       # relajación de constraints

var _pos: PackedVector2Array = []
var _prev: PackedVector2Array = []

func _ready() -> void:
	var origen := Vector2(get_viewport_rect().size.x / 2, 60)
	for i in num_puntos:
		var p := origen + Vector2(0, i * seg_long)
		_pos.append(p)
		_prev.append(p)  # arranca en reposo (sin velocidad)
```

**Paso 2 — Integración y gravedad.** Aplica Verlet a cada punto salvo el anclaje (índice 0).

```gdscript
func _integrar(delta: float) -> void:
	for i in range(1, num_puntos):  # el 0 queda fijo (anclaje)
		var actual := _pos[i]
		# velocidad implícita = actual - previa
		var velocidad := (actual - _prev[i]) * 0.99  # 0.99 = amortiguación
		_prev[i] = actual
		_pos[i] = actual + velocidad + gravedad * delta * delta
```

**Paso 3 — Constraints de distancia (relajación).** Empuja cada par de puntos vecinos hacia su longitud objetivo, varias veces por frame.

```gdscript
func _resolver_constraints() -> void:
	for _iter in iteraciones:
		for i in range(num_puntos - 1):
			var a := _pos[i]
			var b := _pos[i + 1]
			var delta_vec := b - a
			var dist := delta_vec.length()
			if dist == 0.0:
				continue
			var diferencia := (dist - seg_long) / dist
			var correccion := delta_vec * 0.5 * diferencia
			if i != 0:
				_pos[i] = a + correccion       # el anclaje no se corrige
			_pos[i + 1] = b - correccion

func _physics_process(delta: float) -> void:
	_integrar(delta)
	_resolver_constraints()
	queue_redraw()

func _draw() -> void:
	for i in range(num_puntos - 1):
		draw_line(_pos[i], _pos[i + 1], Color.WHITE, 2.0)
	for p in _pos:
		draw_circle(p, 3.0, Color.CYAN)
```

**Observable**: la cuerda cuelga del punto fijo, se estira ligeramente por la gravedad y se balancea si mueves el anclaje. Sube `iteraciones` y la cuerda se ve más rígida; bájalas y se estira como elástico.

**Paso 4 — Verlet en Python puro (para estudiar el algoritmo).** Misma matemática sin motor; imprime la altura del extremo para ver cómo cae y se estabiliza.

```python
# Simulacion de cuerda con Verlet, sin dependencias externas.
GRAVEDAD = (0.0, 9.8)
SEG = 1.0
ITER = 8
DT = 1 / 60

puntos = [(0.0, float(i)) for i in range(10)]   # posiciones actuales
previos = [p for p in puntos]                   # posiciones anteriores

def integrar():
    for i in range(1, len(puntos)):             # 0 es anclaje
        px, py = puntos[i]
        vx = (px - previos[i][0]) * 0.99
        vy = (py - previos[i][1]) * 0.99
        previos[i] = (px, py)
        puntos[i] = (px + vx + GRAVEDAD[0]*DT*DT,
                     py + vy + GRAVEDAD[1]*DT*DT)

def constraints():
    for _ in range(ITER):
        for i in range(len(puntos) - 1):
            ax, ay = puntos[i]
            bx, by = puntos[i+1]
            dx, dy = bx - ax, by - ay
            dist = (dx*dx + dy*dy) ** 0.5 or 1e-9
            diff = (dist - SEG) / dist
            cx, cy = dx*0.5*diff, dy*0.5*diff
            if i != 0:
                puntos[i] = (ax + cx, ay + cy)
            puntos[i+1] = (bx - cx, by - cy)

for paso in range(120):
    integrar()
    constraints()
print("Altura del extremo:", round(puntos[-1][1], 3))
```

**Observable**: el valor impreso crece (la cuerda cae) y luego se estabiliza cerca de `num_puntos * SEG`, confirmando que los constraints mantienen la longitud total.

## ✍️ Ejercicios

1. Ancla también el último punto (dos extremos fijos) para simular una cuerda tendida entre dos postes.
2. Añade viento sumando una fuerza horizontal oscilante en `_integrar`.
3. Convierte la cadena en una **tela**: una rejilla de puntos con constraints horizontales y verticales.
4. Permite "cortar" la cuerda quitando un constraint al hacer clic cerca de él.
5. Haz que el anclaje siga el mouse para columpiar la cuerda.
6. Crea una escena 3D con `SoftBody3D` sobre un `PlaneMesh` (bandera) y fija una arista; compara el resultado con tu Verlet.

## 📝 Reto verificable

Simula una **bandera** con Verlet: una rejilla de al menos 10×6 puntos anclada por su lado izquierdo, afectada por gravedad y un viento variable, dibujada con líneas. La tela no debe "explotar" ni estirarse indefinidamente.

**Criterio de aceptación**: la bandera ondea de forma continua sin que las distancias entre puntos vecinos superen el 120 % de la longitud de reposo, el lado izquierdo permanece fijo, y al subir las iteraciones la tela se ve claramente más rígida sin cambiar la escena.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La tela "explota" hacia el infinito | `dt` demasiado grande o gravedad enorme; usa paso fijo y valores moderados |
| La cuerda se estira como chicle | Pocas iteraciones de constraint; sube `iteraciones` |
| El anclaje se cae | Estás integrando el punto 0; empieza el bucle en índice 1 |
| Oscila para siempre | Falta amortiguación; multiplica la velocidad implícita por ~0.99 |
| División por cero al normalizar | Dos puntos coinciden; salta el constraint si `dist == 0` |

## ❓ Preguntas frecuentes

**¿Por qué Verlet y no Euler con velocidad?** Verlet es más estable frente a constraints rígidos porque la "velocidad" se recalcula desde las posiciones, absorbiendo las correcciones sin acumular energía.

**¿Cuántas iteraciones necesito?** Depende de la rigidez deseada: 4-8 para cuerdas flexibles, 12-20 para telas tensas. Es el principal mando de calidad vs. coste.

**¿Cuándo uso `SoftBody3D` en vez de esto?** Cuando quieres deformar una **malla 3D** (bandera, cojín, gelatina) con colisiones del motor. Para cuerdas 2D o control fino del algoritmo, la simulación propia es más clara.

**¿Debe ir en `_physics_process`?** Sí: usar el paso fijo mantiene la simulación estable e independiente de los FPS de render.

## 🔗 Referencias

- Thomas Jakobsen — Advanced Character Physics (Verlet): <https://www.cs.cmu.edu/afs/cs/academic/class/15462-s13/www/lec_slides/Jakobsen.pdf>
- Godot Docs — SoftBody3D: <https://docs.godotengine.org/en/stable/classes/class_softbody3d.html>
- The Nature of Code — Physics Libraries / particle systems: <https://natureofcode.com/>
- Godot Docs — Custom drawing in 2D (`_draw`): <https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html>

## ➡️ Siguiente clase

[Clase 084 - Determinismo y física fija para multijugador](../084-determinismo-y-fisica-fija-para-multijugador/README.md)
