# Clase 081 — Interpolación y easing (lerp, slerp y tweens)

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Godot Engine 4.x — Tween, Math functions (documentación oficial) y práctica de aula*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dominar la interpolación como herramienta para que todo lo que se mueve en tu juego se sienta vivo. Verás la diferencia entre `lerp` (posiciones/escalas) y `slerp` (rotaciones), entenderás qué es una **curva de easing** y por qué el movimiento lineal parece robótico, y usarás el sistema **Tween** de Godot 4 para animar propiedades con transiciones y ceros de forma declarativa: un menú que aparece con un "pop", una cámara que llega suave, una barra de vida que baja con carácter.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Aplicar `lerp`, `Vector2/3.lerp` y `lerp_angle` para transiciones de posición, escala y ángulo.
2. Explicar por qué `slerp` (`Quaternion.slerp`) es correcto para rotaciones y `lerp` no.
3. Reconocer los tipos de **easing** (in, out, in-out) y las transiciones sine, elastic y bounce.
4. Crear animaciones con `create_tween().tween_property(...)` encadenando `.set_trans()` y `.set_ease()`.
5. Comparar movimiento lineal vs. eased y justificar cuál usar según la sensación buscada.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | `lerp` y el parámetro `t` | Base de toda transición suave |
| 2 | `lerp_angle` y el problema del ±180° | Evita giros por el "camino largo" |
| 3 | `slerp` en rotaciones | Interpola orientación sin deformar |
| 4 | Curvas de easing (in/out/in-out) | Controla la aceleración percibida |
| 5 | Transiciones sine, elastic, bounce | Dan personalidad y feedback |
| 6 | Tween declarativo en Godot | Anima sin escribir `_process` a mano |
| 7 | Encadenar y paralelizar tweens | Coreografías de UI y cámara |

## 📖 Definiciones y características

- **`lerp(a, b, t)`**: interpolación lineal; con `t=0` da `a`, con `t=1` da `b`. Clave: `t` fuera de [0,1] extrapola (útil y peligroso).
- **`Vector2/3.lerp(otro, t)`**: mezcla componente a componente. Clave: recto entre dos puntos, ideal para posición y escala.
- **`lerp_angle(a, b, t)`**: interpola ángulos por el arco más corto. Clave: usa radianes y respeta el envoltorio en ±π.
- **`slerp` (spherical linear)**: interpola sobre la esfera unidad; `Quaternion.slerp` gira a velocidad angular constante. Clave: nunca uses `lerp` crudo en quaterniones.
- **Easing**: función que remapea `t` para que el avance no sea uniforme. Clave: "in" arranca lento, "out" frena al final, "in-out" ambas.
- **`ease(t, curva)`**: helper de Godot que aplica una curva potencia a `t`. Clave: `curva<1` suaviza, `curva>1` acentúa.
- **`smoothstep(a, b, x)`**: interpolación con arranque y frenado suaves (S). Clave: perfecta para umbrales y fundidos.
- **`Tween`**: objeto que anima propiedades en el tiempo. Clave: se crea con `create_tween()`, es de un solo uso y corre solo.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x** ([godotengine.org](https://godotengine.org)). Crea un proyecto 2D con un `Node2D` raíz y añade un `Sprite2D` (sirve el ícono por defecto) y un `Button`. Trabajaremos casi todo con **Tween**, que en Godot 4 se crea desde código con `create_tween()` (ya no es un nodo como en Godot 3). Ten a mano la documentación de [Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html) y la lista de constantes `TRANS_*` y `EASE_*`. Recuerda que un `Tween` empieza a correr automáticamente en el siguiente frame y muere al terminar; guarda su referencia solo si necesitas pausarlo o detenerlo.

## 🧪 Laboratorio guiado

Animaremos posición, escala y rotación, compararemos lineal vs. eased y crearemos un "pop" de UI con elastic.

**Paso 1 — Mover con Tween y elegir transición.** Adjunta este script al `Node2D`. Mueve el `Sprite2D` de izquierda a derecha con una transición suave.

```gdscript
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.position = Vector2(100, 300)
	var tw := create_tween()
	tw.tween_property(sprite, "position", Vector2(700, 300), 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
```

**Observable**: el sprite arranca lento, acelera en el medio y frena al llegar. Cambia `TRANS_SINE` por `TRANS_LINEAR` y notarás el arranque/parada bruscos y "robóticos".

**Paso 2 — Comparar lineal vs. eased lado a lado.** Duplica el sprite (uno arriba, otro abajo) y anímalos con distinta transición para ver la diferencia en simultáneo.

```gdscript
func comparar(a: Node2D, b: Node2D) -> void:
	var t1 := create_tween()
	t1.tween_property(a, "position:x", 700.0, 2.0).set_trans(Tween.TRANS_LINEAR)
	var t2 := create_tween()
	t2.tween_property(b, "position:x", 700.0, 2.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
```

**Observable**: el lineal mantiene velocidad constante; el eased "out" llega rápido y desacelera. Fíjate cómo el segundo parece que "aterriza" en su destino.

**Paso 3 — "Pop" de UI con elastic.** Haz que un botón aparezca creciendo desde cero con un rebote elástico al pulsar.

```gdscript
func _on_button_pressed() -> void:
	var panel := $Panel
	panel.scale = Vector2.ZERO
	panel.pivot_offset = panel.size / 2.0  # crece desde el centro
	var tw := create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
```

**Observable**: el panel salta de tamaño y oscila brevemente antes de asentarse. Prueba `TRANS_BOUNCE` para un efecto de "pelota que cae".

**Paso 4 — Encadenar y paralelizar.** Una coreografía: el sprite se mueve, luego gira, mientras la escala cambia en paralelo.

```gdscript
func coreografia() -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "position:x", 600.0, 1.0).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(sprite, "rotation", TAU, 0.8)  # después del anterior
	tw.parallel().tween_property(sprite, "scale", Vector2(2, 2), 0.8)  # a la vez que la rotación
```

**Observable**: primero se desplaza, luego gira una vuelta completa mientras crece: la rotación y la escala ocurren juntas gracias a `parallel()`.

## ✍️ Ejercicios

1. Anima la `modulate:a` (alfa) de un sprite de 0 a 1 con `TRANS_SINE` para un fundido de entrada.
2. Usa `lerp_angle` en `_process` para que un cañón gire suavemente hacia el mouse y compáralo con un Tween de `rotation`.
3. Crea un menú con tres botones que aparezcan escalonados (delay creciente) usando `set_delay()`.
4. Haz una barra de vida (`ProgressBar`) que baje con `TRANS_BACK` `EASE_OUT` para dar sensación de golpe.
5. Interpola la orientación de un `Node3D` con `Quaternion.slerp` entre dos rotaciones y compárala con un `lerp` de ángulos de Euler.
6. Usa `smoothstep` para controlar la opacidad de niebla según la distancia del jugador a un punto.

## 📝 Reto verificable

Construye un "toast" de notificación: un panel que entra deslizándose desde fuera de la pantalla con `TRANS_BACK EASE_OUT`, permanece 2 segundos y sale con `EASE_IN`. Todo debe hacerse con un único encadenamiento de Tween (usa `tween_interval` para la espera).

**Criterio de aceptación**: el toast entra, espera y sale sin usar `_process`, la salida usa la transición inversa a la entrada, y al dispararlo dos veces seguidas no quedan tweens huérfanos que dejen el panel a medio camino.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La rotación 3D se "aplana" o tiembla | Interpolaste con `lerp` de Euler; usa `Quaternion.slerp` |
| El giro va por el camino largo | Usaste `lerp` de ángulo crudo; cambia a `lerp_angle` |
| El Tween no hace nada | Lo creaste pero no llamaste `tween_property`, o el nodo fue liberado |
| El "pop" crece desde una esquina | Falta `pivot_offset` centrado antes de escalar |
| Dos animaciones se pisan | Un Tween nuevo no cancela al anterior; guarda y llama `kill()` primero |

## ❓ Preguntas frecuentes

**¿Cuál es la diferencia entre `lerp` y `slerp`?** `lerp` va en línea recta entre dos valores; `slerp` va por el arco de una esfera, manteniendo velocidad angular constante. Para rotaciones (quaterniones) siempre `slerp`.

**¿`Tween` es un nodo en Godot 4?** No. Se crea con `create_tween()` desde un nodo del árbol y corre ligado a ese nodo. Esto cambió respecto a Godot 3.

**¿Cuándo uso `ease()`/`smoothstep` en vez de un Tween?** Cuando ya calculas `t` a mano (por ejemplo, en `_process`) y solo quieres remapear la curva sin crear una animación completa.

**¿El easing afecta el rendimiento?** No de forma perceptible: son funciones matemáticas baratas. El coste real está en cuántos nodos animas, no en la curva elegida.

## 🔗 Referencias

- Godot Docs — Tween: <https://docs.godotengine.org/en/stable/classes/class_tween.html>
- Godot Docs — @GlobalScope (lerp, ease, smoothstep, lerp_angle): <https://docs.godotengine.org/en/stable/classes/class_@globalscope.html>
- Godot Docs — Quaternion: <https://docs.godotengine.org/en/stable/classes/class_quaternion.html>
- Easings.net — catálogo visual de curvas de easing: <https://easings.net/>

## ➡️ Siguiente clase

[Clase 082 - Steering behaviors: seek, flee, arrive y wander](../082-steering-behaviors-seek-flee-arrive-y-wander/README.md)
