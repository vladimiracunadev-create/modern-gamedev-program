# Clase 068 — Repaso aplicado: vectores y transformaciones en el motor

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Godot Engine 4.x — Vector math (documentación oficial) y práctica de aula*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Recuperar los conceptos de vectores y transformaciones desde la práctica real del motor, no desde la teoría abstracta. Al terminar sabrás responder preguntas que aparecen todos los días al programar un juego: ¿el enemigo me está mirando de frente?, ¿hacia dónde debo moverme para alcanzar un objetivo?, ¿cómo rebota una velocidad contra una pared? Usaremos `Vector2` y `Vector3` de Godot 4 y sus operaciones nativas.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Distinguir entre un vector de **posición**, uno de **dirección** y uno de **desplazamiento**, y decidir cuándo normalizar.
2. Usar el **producto punto** (`dot`) para medir el ángulo entre direcciones y resolver el problema "de frente vs. de espaldas".
3. Calcular una **dirección hacia un objetivo** y una **distancia** con `.normalized()` y `.length()`.
4. Aplicar la **proyección** de un vector sobre otro para descomponer movimiento.
5. **Reflejar** una velocidad contra una superficie usando su normal (`.bounce()` o la fórmula manual).

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Vector como punto y como flecha | Evita el error de sumar posiciones sin sentido |
| 2 | Normalización de direcciones | Separa "hacia dónde" de "cuánto" |
| 3 | Producto punto y ángulo | Base de visión, IA y iluminación |
| 4 | Frente vs. espalda con signo del dot | Detección de sigilo y ataques por la espalda |
| 5 | Distancia y dirección a un objetivo | Movimiento, seguimiento, rangos de ataque |
| 6 | Proyección de un vector | Deslizamiento sobre superficies |
| 7 | Reflexión de una velocidad | Rebotes de proyectiles y pelotas |

## 📖 Definiciones y características

- **Vector de posición**: par/terna de coordenadas que ubica un punto respecto al origen. Clave: no tiene sentido normalizarlo.
- **Vector de dirección**: flecha de longitud 1 que indica orientación. Clave: siempre pásalo por `.normalized()`.
- **Producto punto (`a.dot(b)`)**: escalar igual a `|a||b|cos(θ)`. Clave: con vectores unitarios, su valor va de -1 (opuestos) a 1 (iguales).
- **Magnitud (`.length()`)**: longitud del vector. Clave: usa `.length_squared()` para comparar distancias sin la raíz cuadrada.
- **Proyección (`a.project(b)`)**: sombra de `a` sobre la dirección de `b`. Clave: descompone velocidad en componentes paralela y perpendicular.
- **Normal**: vector unitario perpendicular a una superficie. Clave: define cómo rebota o desliza un cuerpo.
- **Reflexión (`.bounce(n)`)**: espeja el vector respecto a la superficie de normal `n`. Clave: `bounce` invierte, `reflect` no; revisa cuál usa tu versión.
- **Interpolación (`.lerp(b, t)`)**: mezcla lineal entre dos vectores con `t` en [0,1]. Clave: útil para suavizar movimiento.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x** (descarga en [godotengine.org](https://godotengine.org)). Crea un proyecto 2D vacío y una escena con un `Node2D` raíz. Trabajaremos con un script de prueba que imprime resultados en la consola de salida, así que no hace falta arte: los números son lo observable. Ten a mano la referencia de [Vector2](https://docs.godotengine.org/en/stable/classes/class_vector2.html). Recuerda que en Godot 2D el eje **Y crece hacia abajo**, algo que afecta el signo de los ángulos.

## 🧪 Laboratorio guiado

Vamos a resolver tres problemas reales en un solo script. Crea un `Node2D`, adjúntale este script y observa la consola.

**Paso 1 — ¿El enemigo me ve de frente?** El enemigo mira en una dirección; comparamos con la dirección hacia el jugador.

```gdscript
extends Node2D

func _ready() -> void:
	# Enemigo en (0,0) mirando hacia la derecha.
	var enemigo_pos := Vector2.ZERO
	var enemigo_frente := Vector2.RIGHT  # ya es unitario
	var jugador_pos := Vector2(6, 2)

	# Dirección desde el enemigo hacia el jugador.
	var hacia_jugador := (jugador_pos - enemigo_pos).normalized()
	var d := enemigo_frente.dot(hacia_jugador)
	print("dot = ", d)  # ~0.949

	# Cono de visión: cos(45°) ≈ 0.707. Si dot supera ese umbral, lo ve.
	if d > cos(deg_to_rad(45.0)):
		print("El enemigo VE al jugador de frente")
	elif d < 0.0:
		print("El jugador está a la ESPALDA del enemigo")
	else:
		print("El jugador está de lado")
```

**Paso 2 — Moverse hacia el objetivo con distancia.** Separamos "hacia dónde" de "cuánto falta".

```gdscript
	var distancia := enemigo_pos.distance_to(jugador_pos)
	print("distancia = ", distancia)  # ~6.324
	var paso := hacia_jugador * min(2.0, distancia)  # avanza 2 px o lo que falte
	print("nueva pos = ", enemigo_pos + paso)
```

**Paso 3 — Reflejar una velocidad contra una pared.** Un proyectil golpea una pared vertical (normal apuntando a la izquierda).

```gdscript
	var velocidad := Vector2(5, -3)
	var normal_pared := Vector2.LEFT  # pared a la derecha, normal hacia -X
	var rebote := velocidad.bounce(normal_pared)
	print("velocidad tras rebote = ", rebote)  # (-5, -3): invierte X, conserva Y
```

Ejecuta (F6). Verás en consola el `dot`, la clasificación de visión, la distancia y la velocidad reflejada. Cambia `jugador_pos` a `(-6, 0)` y confirma que ahora aparece "a la ESPALDA" (dot negativo).

## ✍️ Ejercicios

1. Modifica el cono de visión a 30° y prueba con tres posiciones distintas del jugador.
2. Escribe una función `angulo_grados(a, b)` que devuelva el ángulo entre dos vectores usando `a.angle_to(b)` y `rad_to_deg`.
3. Usa `.length_squared()` para comparar cuál de dos enemigos está más cerca sin calcular raíces.
4. Proyecta la velocidad de un jugador sobre la dirección de una rampa con `velocidad.project(dir_rampa)` e imprime la componente de deslizamiento.
5. Refleja `Vector2(4, 4)` contra una normal diagonal `Vector2(-1, -1).normalized()` y verifica el resultado a mano.
6. Convierte todo el lab a 3D usando `Vector3` y una pared con `normal = Vector3.LEFT`.

## 📝 Reto verificable

Crea un script que reciba la posición del jugador, la del enemigo y la dirección de mirada del enemigo, y clasifique la situación en tres categorías impresas en consola: `"VISIBLE"`, `"DE_LADO"` o `"A_ESPALDA"`, usando un cono configurable con `@export var angulo_vision := 60.0`.

**Criterio de aceptación**: con el enemigo en el origen mirando a `Vector2.RIGHT` y `angulo_vision = 60`, un jugador en `(10, 0)` imprime `VISIBLE`, uno en `(0, 10)` imprime `DE_LADO` y uno en `(-10, 0)` imprime `A_ESPALDA`.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El `dot` da valores raros (>1 o muy grandes) | Olvidaste `.normalized()`; el dot solo va en [-1,1] con unitarios |
| El enemigo "ve" en todas direcciones | Comparaste `dot > 0` en vez de `dot > cos(mitad del ángulo)` |
| La distancia sale enorme al comparar | Mezclaste `length()` con `length_squared()`; no compares uno contra otro |
| El rebote invierte el eje equivocado | La normal apunta al lado incorrecto; en 2D recuerda que Y crece hacia abajo |
| `normalized()` de un vector cero da NaN | Verifica `if v.length() > 0.0` antes de normalizar |

## ❓ Preguntas frecuentes

**¿Cuándo normalizo y cuándo no?** Normaliza cuando solo te importa la dirección (mirada, empuje). No normalices posiciones ni cuando la magnitud es información (velocidad, distancia).

**¿`dot` sirve en 3D igual que en 2D?** Sí, la operación y su interpretación (coseno del ángulo) son idénticas en `Vector3`.

**¿Diferencia entre `bounce` y `reflect`?** En Godot, `bounce(n)` devuelve el vector reflejado "hacia afuera" (invertido); `reflect(n)` refleja respecto a la línea de la normal. Para rebotes físicos usa `bounce`.

**¿Por qué usar `length_squared`?** Evita la raíz cuadrada, que es costosa. Para saber solo cuál está más cerca, comparar cuadrados basta y es más rápido.

## 🔗 Referencias

1. Godot Engine — Vector math: <https://docs.godotengine.org/en/stable/tutorials/math/vector_math.html>
2. Godot Engine — Clase Vector2: <https://docs.godotengine.org/en/stable/classes/class_vector2.html>
3. Godot Engine — Clase Vector3: <https://docs.godotengine.org/en/stable/classes/class_vector3.html>
4. Godot Engine — Using transforms: <https://docs.godotengine.org/en/stable/tutorials/math/matrices_and_transforms.html>

## ⬅️ Clase anterior

[Clase 067 - Capstone Parte 2: un nivel 3D explorable en tercera persona](../../parte-2-desarrollo-3d-motores-escenas-y-transformaciones/067-capstone-parte-2-un-nivel-3d-explorable-en-tercera-persona/README.md)

## ➡️ Siguiente clase

[Clase 069 - Cuaterniones: rotaciones 3D sin gimbal lock](../069-cuaterniones-rotaciones-3d-sin-gimbal-lock/README.md)
