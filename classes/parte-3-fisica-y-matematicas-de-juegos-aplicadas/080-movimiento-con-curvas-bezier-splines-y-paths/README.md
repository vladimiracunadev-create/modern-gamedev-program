# Clase 080 — Movimiento con curvas: Bézier, splines y paths

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Godot Engine 4.x — Path2D/Path3D, Curve3D (documentación oficial) y práctica de aula*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Aprender a mover objetos siguiendo trayectorias suaves definidas por curvas en lugar de líneas rectas. Entenderás la matemática detrás de una curva de Bézier (construida con interpolaciones lineales anidadas) y usarás las herramientas nativas de Godot 4 —`Path3D` + `PathFollow3D`— para hacer que una cámara, una plataforma móvil o un enemigo recorran un raíl con velocidad controlada. También implementarás una Bézier cúbica "a mano" para no depender de una caja negra.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar cómo una curva de **Bézier** cuadrática y cúbica se obtiene encadenando `lerp` (algoritmo de De Casteljau).
2. Distinguir entre **puntos de control** y **puntos por los que pasa** la curva, y saber cuándo usar splines.
3. Construir un `Path3D` con una `Curve3D` y recorrerlo con un `PathFollow3D` usando `progress` y `progress_ratio`.
4. Controlar la **velocidad** a lo largo de la curva de forma independiente al espaciado de sus puntos.
5. Implementar y muestrear una **Bézier cúbica** con código propio para plataformas, cámaras o proyectiles guiados.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Interpolación lineal como bloque base | Todo lo demás se construye sobre `lerp` |
| 2 | Bézier cuadrática (3 puntos) | Primera curva controlable con una "tangente" |
| 3 | Bézier cúbica (4 puntos) | Estándar de trayectorias y de animación |
| 4 | Algoritmo de De Casteljau | Da intuición geométrica y estabilidad numérica |
| 5 | Splines y continuidad | Encadenar tramos sin "codos" bruscos |
| 6 | Path3D + PathFollow3D | Solución lista del motor para raíles |
| 7 | Longitud de arco vs. parámetro `t` | Evita que el objeto acelere/frene sin querer |

## 📖 Definiciones y características

- **Interpolación lineal (`lerp(a, b, t)`)**: mezcla entre `a` y `b` con `t` en [0,1]. Clave: es el ladrillo de toda curva de Bézier.
- **Punto de control**: punto que "tira" de la curva sin que ésta pase necesariamente por él. Clave: define la forma, no el recorrido exacto.
- **Bézier cuadrática**: curva de 3 puntos (inicio, control, fin). Clave: un solo control, una sola "curvatura".
- **Bézier cúbica**: curva de 4 puntos (inicio, 2 controles, fin). Clave: permite formas en S; es la que usan casi todas las herramientas.
- **De Casteljau**: método que evalúa la curva con `lerp` anidados en vez de la fórmula polinómica. Clave: numéricamente estable y fácil de leer.
- **Spline**: unión de varios tramos Bézier compartiendo extremos. Clave: cuida la continuidad de tangente para que no se noten los empalmes.
- **`Curve3D.sample_baked(offset)`**: devuelve un punto a `offset` metros del inicio usando una tabla "horneada". Clave: parametriza por **longitud**, no por `t`, así la velocidad es uniforme.
- **`PathFollow3D.progress`**: distancia recorrida en metros; `progress_ratio` es la fracción [0,1]. Clave: mueve el hijo automáticamente a lo largo del `Path3D` padre.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x** ([godotengine.org](https://godotengine.org)). Crea un proyecto 3D y una escena con un `Node3D` raíz. Vas a usar dos rutas: la del motor (`Path3D` con `PathFollow3D`) y la manual (una Bézier cúbica evaluada por código). Para ver el objeto añade un `MeshInstance3D` con una `BoxMesh` o `SphereMesh` y una `Camera3D` que mire la escena. Ten a mano la documentación de [Curve3D](https://docs.godotengine.org/en/stable/classes/class_curve3d.html) y [PathFollow3D](https://docs.godotengine.org/en/stable/classes/class_pathfollow3d.html). El editor permite dibujar la curva con el mouse desde el `Path3D`, pero también la crearemos por código para que el laboratorio sea reproducible.

## 🧪 Laboratorio guiado

Construiremos dos escenas comparables: A) un objeto que recorre un `Path3D` a velocidad constante, y B) un objeto que sigue una Bézier cúbica implementada a mano.

**Paso 1 — Crear un `Path3D` por código y recorrerlo.** Añade a la escena un `Node3D` con este script. Crea la curva, mete un `PathFollow3D` y un cubo como hijo, y avanza `progress` en `_physics_process`.

```gdscript
extends Node3D

@export var velocidad := 4.0  # metros por segundo

var _seguidor: PathFollow3D

func _ready() -> void:
	var camino := Path3D.new()
	var curva := Curve3D.new()
	# add_point(posicion, control_entrada, control_salida)
	curva.add_point(Vector3(-6, 0, 0), Vector3.ZERO, Vector3(0, 0, -4))
	curva.add_point(Vector3(0, 3, -6), Vector3(-4, 0, 0), Vector3(4, 0, 0))
	curva.add_point(Vector3(6, 0, 0), Vector3(0, 0, -4), Vector3.ZERO)
	camino.curve = curva
	add_child(camino)

	_seguidor = PathFollow3D.new()
	_seguidor.loop = true
	_seguidor.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	camino.add_child(_seguidor)

	var cubo := MeshInstance3D.new()
	cubo.mesh = BoxMesh.new()
	_seguidor.add_child(cubo)

func _physics_process(delta: float) -> void:
	# progress avanza en metros: velocidad constante real
	_seguidor.progress += velocidad * delta
```

**Observable**: el cubo recorre la curva a velocidad uniforme y se **orienta** hacia la dirección de avance gracias a `ROTATION_ORIENTED`. Cambia `velocidad` y verás que acelera sin deformar la trayectoria.

**Paso 2 — Muestrear por longitud vs. por parámetro.** Sustituye el avance por un muestreo con `sample_baked`, que reparte los puntos por distancia real. Esto importa cuando los puntos de control están desigualmente espaciados.

```gdscript
var _distancia := 0.0

func _physics_process(delta: float) -> void:
	var curva := ($Path3D as Path3D).curve
	_distancia = fmod(_distancia + velocidad * delta, curva.get_baked_length())
	var pos := curva.sample_baked(_distancia)
	$Objeto.position = pos
```

**Observable**: aunque un tramo tenga puntos de control muy juntos, el objeto no se "atasca" ni se dispara: recorre metros iguales por segundo.

**Paso 3 — Bézier cúbica a mano (De Casteljau).** Implementa la curva con `lerp` anidados. Sirve para trayectorias de proyectiles guiados o cámaras cinemáticas sin crear nodos.

```gdscript
extends Node3D

@export var p0 := Vector3(-6, 0, 0)
@export var p1 := Vector3(-2, 4, 0)
@export var p2 := Vector3(2, 4, 0)
@export var p3 := Vector3(6, 0, 0)
@export var duracion := 3.0

var _t := 0.0

func bezier_cubica(a: Vector3, b: Vector3, c: Vector3, d: Vector3, t: float) -> Vector3:
	var ab := a.lerp(b, t)
	var bc := b.lerp(c, t)
	var cd := c.lerp(d, t)
	var abc := ab.lerp(bc, t)
	var bcd := bc.lerp(cd, t)
	return abc.lerp(bcd, t)  # punto final sobre la curva

func _physics_process(delta: float) -> void:
	_t = fmod(_t + delta / duracion, 1.0)
	$Objeto.position = bezier_cubica(p0, p1, p2, p3, _t)
```

**Observable**: el objeto describe un arco suave en forma de campana. Mueve `p1`/`p2` en el inspector y verás cómo los controles "tiran" de la curva sin que el recorrido pase por ellos.

## ✍️ Ejercicios

1. Añade un cuarto punto a la `Curve3D` del Paso 1 y ajusta los controles para cerrar el circuito en bucle sin codos visibles.
2. Modifica el Paso 3 para que `duracion` dependa de la longitud aproximada de la curva (muestrea 20 puntos y suma distancias).
3. Dibuja la curva en pantalla usando `ImmediateMesh` o `draw_line` (en 2D) muestreando 30 puntos de la Bézier.
4. Convierte la Bézier cúbica en cuadrática (3 puntos) y compara visualmente la diferencia de control.
5. Haz que una `Camera3D` sea hija del `PathFollow3D` y siga un carril mientras mira siempre a un objetivo con `look_at`.
6. Encadena dos Béziers cúbicas (spline) compartiendo el punto final; asegura continuidad de tangente reflejando el último control.

## 📝 Reto verificable

Crea una plataforma móvil (`AnimatableBody3D` o `MeshInstance3D`) que recorra un `Path3D` cerrado a velocidad constante y transporte al jugador encima. La velocidad debe poder cambiarse por `@export` en tiempo real.

**Criterio de aceptación**: la plataforma completa una vuelta en un tiempo que coincide (±5 %) con `longitud_horneada / velocidad`, el objeto encima no resbala de forma perceptible, y al duplicar `velocidad` el tiempo de vuelta se reduce a la mitad.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El objeto acelera y frena solo en la curva | Avanzas por `t` en vez de por longitud; usa `sample_baked` o `progress` |
| La plataforma no rota con la curva | Falta `rotation_mode = ROTATION_ORIENTED` en el `PathFollow3D` |
| La curva tiene "picos" al unir tramos | Controles del empalme no son simétricos; refleja el control anterior |
| `sample_baked` devuelve siempre el mismo punto | No horneaste la curva o `baked_length` es 0; añade puntos válidos primero |
| El `PathFollow3D` no mueve nada | No es hijo directo del `Path3D`, o el hijo visual no cuelga del seguidor |

## ❓ Preguntas frecuentes

**¿Cuándo uso `Path3D` y cuándo una Bézier manual?** Usa `Path3D` para raíles editables con el mouse y velocidad uniforme lista. Usa la Bézier manual cuando calculas la trayectoria en tiempo de ejecución (un misil que apunta a un blanco móvil).

**¿La curva pasa por los puntos de control?** En una Bézier no: pasa por el primero y el último; los intermedios solo la moldean. En un spline de Catmull-Rom sí pasaría por todos.

**¿Por qué `progress` en metros y no en 0..1?** Porque metros dan velocidad física real e independiente de la forma. Para fracción usa `progress_ratio`.

**¿Puedo hacer lo mismo en 2D?** Sí: `Path2D` + `PathFollow2D` funcionan igual, y la Bézier manual usa `Vector2` con el mismo código.

## 🔗 Referencias

- Godot Docs — Curve3D: <https://docs.godotengine.org/en/stable/classes/class_curve3d.html>
- Godot Docs — PathFollow3D: <https://docs.godotengine.org/en/stable/classes/class_pathfollow3d.html>
- Godot Docs — Path2D / PathFollow2D: <https://docs.godotengine.org/en/stable/classes/class_path2d.html>
- Freya Holmér — The Beauty of Bézier Curves: <https://www.youtube.com/watch?v=aVwxzDHniEw>

## ⬅️ Clase anterior

[Clase 079 - Proyectiles: balística, gravedad y predicción](../079-proyectiles-balistica-gravedad-y-prediccion/README.md)

## ➡️ Siguiente clase

[Clase 081 - Interpolación y easing (lerp, slerp y tweens)](../081-interpolacion-y-easing-lerp-slerp-y-tweens/README.md)
