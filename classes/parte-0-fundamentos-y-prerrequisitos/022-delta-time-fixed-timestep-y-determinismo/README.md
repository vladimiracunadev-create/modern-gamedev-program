# Clase 022 — Delta time, fixed timestep y determinismo

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Glenn Fiedler, "Fix Your Timestep!"; Robert Nystrom, Game Programming Patterns*
> ⏱️ Duración estimada: **90 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Los juegos se ejecutan a distintas velocidades: una máquina potente puede dibujar 240 cuadros por segundo y otra apenas 30. Si mueves un personaje sumando una cantidad fija por cuadro, en la máquina rápida volará y en la lenta irá a paso de tortuga. La solución es multiplicar el movimiento por **delta time**, el tiempo transcurrido desde el cuadro anterior, para que la velocidad sea la misma en cualquier hardware.

Pero la física necesita algo más: un **paso fijo (fixed timestep)** que garantice estabilidad y repetibilidad. En esta clase entenderás por qué se multiplica por delta, cómo Godot separa el proceso de dibujo del proceso de física (`_process` vs `_physics_process`), qué es un acumulador con interpolación y por qué el **determinismo** —obtener siempre el mismo resultado con las mismas entradas— importa en multijugador y repeticiones (replays), complicado por la aritmética de coma flotante.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar por qué el movimiento debe multiplicarse por `delta` para ser independiente del framerate.
2. Distinguir `_process` (variable) de `_physics_process` (paso fijo) en Godot.
3. Describir el patrón acumulador y para qué sirve la interpolación entre pasos de física.
4. Definir determinismo y por qué es crítico en multijugador y replays.
5. Argumentar por qué los `float` dificultan el determinismo entre máquinas.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Delta time | Velocidad igual en cualquier framerate. |
| 2 | Frame time variable | Los cuadros no duran siempre lo mismo. |
| 3 | Fixed timestep | Física estable y repetible. |
| 4 | `_process` vs `_physics_process` | Godot separa render y física. |
| 5 | Acumulador | Ejecutar N pasos fijos por cuadro. |
| 6 | Interpolación | Suavizar el render entre pasos. |
| 7 | Determinismo | Multijugador y replays fiables. |
| 8 | Floats y precisión | Por qué el mismo cálculo puede diferir. |

## 📖 Definiciones y características

- **Delta time (`delta`)**: segundos transcurridos desde el cuadro anterior. Clave: multiplicador que normaliza la velocidad.
- **Framerate (FPS)**: cuadros dibujados por segundo. Clave: variable según carga y hardware.
- **Fixed timestep**: intervalo constante (p. ej. 1/60 s) para actualizar la física. Clave: estabilidad y repetibilidad.
- **`_process(delta)`**: función de Godot que corre cada cuadro de render. Clave: `delta` variable.
- **`_physics_process(delta)`**: función que corre a frecuencia fija (60 Hz por defecto). Clave: `delta` constante.
- **Acumulador**: variable que suma el tiempo sobrante para decidir cuántos pasos fijos ejecutar. Clave: desacopla física de render.
- **Interpolación**: mezclar el estado previo y el actual para dibujar entre pasos. Clave: movimiento suave sin tirones.
- **Determinismo**: misma entrada produce siempre la misma salida. Clave: base de replays y multijugador con lockstep.

## 🧰 Herramientas y preparación

Trabajarás en **Godot 4** con **GDScript**. Crea un proyecto 2D vacío. Necesitarás un nodo visible (por ejemplo un `Sprite2D` o un `ColorRect`) para observar el movimiento, y el monitor de FPS que puedes forzar desde *Proyecto > Ajustes del proyecto > Application > Run > Max FPS* o mediante `Engine.max_fps`. Las lecturas de referencia son el artículo clásico *Fix Your Timestep!* de Glenn Fiedler (<https://gafferongames.com/post/fix_your_timestep/>) y el capítulo *Game Loop* de *Game Programming Patterns* de Robert Nystrom (<https://gameprogrammingpatterns.com/game-loop.html>). La documentación de Godot sobre `_process` y `_physics_process` completa la parte práctica.

## 🧪 Laboratorio guiado

### Paso 1 — Movimiento SIN delta (el error clásico)

Añade un `Sprite2D` a la escena, adjúntale un script y mueve el nodo sumando una cantidad fija por cuadro:

```gdscript
extends Sprite2D

var speed := 4.0  # pixeles por CUADRO (mal)

func _process(_delta: float) -> void:
	position.x += speed  # depende del framerate
```

Ejecuta el juego. El sprite se mueve a cierta velocidad, pero esa velocidad está atada al framerate: cuantos más FPS, más rápido va.

### Paso 2 — Cambiar el FPS y observar el problema

Fuerza el framerate desde el script `_ready` y compara:

```gdscript
func _ready() -> void:
	Engine.max_fps = 30   # prueba luego con 120
```

Con `max_fps = 30` el sprite avanza lento; con `120` vuela. El comportamiento del juego cambia según la máquina: inaceptable.

### Paso 3 — Movimiento CON delta (correcto)

Convierte la velocidad a píxeles **por segundo** y multiplica por `delta`:

```gdscript
extends Sprite2D

var speed := 240.0  # pixeles por SEGUNDO (bien)

func _process(delta: float) -> void:
	position.x += speed * delta  # independiente del framerate
```

Ahora, con 30 o con 120 FPS, el sprite recorre los mismos 240 píxeles cada segundo. `delta` es pequeño cuando hay muchos FPS y grande cuando hay pocos, compensando exactamente la diferencia.

### Paso 4 — Lógica de física en `_physics_process`

Para colisiones y movimiento físico usa el paso fijo, que Godot llama 60 veces por segundo con un `delta` constante:

```gdscript
extends CharacterBody2D

var speed := 240.0

func _physics_process(delta: float) -> void:
	velocity.x = speed
	move_and_slide()  # integracion estable a 60 Hz
```

`_physics_process` recibe siempre el mismo `delta` (1/60 ≈ 0.01667), lo que mantiene la simulación estable y repetible aunque el render fluctúe.

### Paso 5 — Entender el acumulador (concepto)

Internamente, el motor usa un acumulador: suma el tiempo del cuadro y ejecuta tantos pasos fijos como quepan, guardando el resto. Este pseudocódigo ilustra la idea del artículo de Fiedler:

```gdscript
var accumulator := 0.0
const STEP := 1.0 / 60.0

func _process(delta: float) -> void:
	accumulator += delta
	while accumulator >= STEP:
		_simular_paso(STEP)   # siempre el mismo dt fijo
		accumulator -= STEP
	# el sobrante (accumulator) serviria para interpolar el render
```

Godot ya hace esto por ti al separar `_physics_process` de `_process`; entenderlo explica por qué la física es estable y el render fluido.

## ✍️ Ejercicios

1. Mide con un `print` cuántos píxeles recorre el sprite en un segundo con y sin `delta`.
2. Cambia `Engine.max_fps` a 15, 60 y 144 y confirma que la versión con `delta` no varía.
3. Reescribe el movimiento del Paso 3 para que vaya en diagonal a velocidad constante.
4. Explica con tus palabras por qué `_physics_process` recibe un `delta` casi constante.
5. Modifica la constante `STEP` del acumulador a 1/30 y describe el efecto esperado.
6. Investiga qué imprime `Engine.get_physics_ticks_per_second()` y cámbialo a 30.

## 📝 Reto verificable

Crea una escena con dos sprites: uno que se mueva con `position.x += speed` (sin delta) y otro con `position.x += speed * delta`. Añade un control para cambiar `Engine.max_fps` en tiempo de ejecución entre 30 y 120, y demuestra que solo el segundo mantiene la misma velocidad real. Documenta con un `print` la posición de cada sprite tras dos segundos.

**Criterio de aceptación**: al alternar el framerate, el sprite sin `delta` recorre distancias distintas en el mismo tiempo real mientras que el sprite con `delta` recorre siempre la misma distancia (±1 %); el código de física usa `_physics_process`; y el registro impreso evidencia ambos comportamientos.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| El personaje va más rápido en un PC potente | Sumas una cantidad fija por cuadro. Multiplica la velocidad por `delta`. |
| El movimiento con `delta` va lentísimo | Dejaste la velocidad en píxeles-por-cuadro. Súbela a píxeles-por-segundo. |
| La física tiembla o atraviesa paredes | Pones lógica de colisión en `_process`. Muévela a `_physics_process`. |
| Un replay se desincroniza en otra máquina | Dependes de `float` no deterministas o del framerate. Usa paso fijo y evita azar sin semilla. |
| `delta` es enorme el primer cuadro | La carga inicial produce un pico. Ignora el primer `delta` o usa `_physics_process`. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué exactamente se multiplica por `delta`?** Porque convierte una velocidad expresada por segundo en el desplazamiento correcto para la duración real de ese cuadro. Si el cuadro dura poco, `delta` es pequeño y el avance también; el resultado por segundo es constante.

**❓ ¿Cuándo uso `_process` y cuándo `_physics_process`?** Usa `_process` para cosas visuales y de entrada que pueden variar (animaciones, cámara). Usa `_physics_process` para movimiento con colisiones y cualquier simulación que deba ser estable y repetible.

**❓ ¿Qué gana la física con un paso fijo?** Estabilidad y repetibilidad. Los integradores numéricos se comportan mal con pasos de tiempo variables; con un `dt` constante la simulación es predecible y no explota con cuadros largos.

**❓ ¿Por qué los `float` complican el determinismo?** Porque el redondeo de coma flotante puede diferir entre CPUs, compiladores u órdenes de operación. Dos máquinas pueden obtener resultados ligeramente distintos y, acumulados, desincronizar una simulación multijugador o un replay.

## 🔗 Referencias

- Glenn Fiedler, "Fix Your Timestep!": <https://gafferongames.com/post/fix_your_timestep/>
- Robert Nystrom, *Game Programming Patterns*, "Game Loop": <https://gameprogrammingpatterns.com/game-loop.html>
- Godot Docs, "Idle and Physics Processing": <https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html>
- Godot Docs, "CharacterBody2D `move_and_slide`": <https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html>

## ⬅️ Clase anterior

[Clase 021 - Assets y pipeline de contenido: import, compresión y presupuestos](../021-assets-y-pipeline-de-contenido-import-compresion-y-presupuestos/README.md)

## ➡️ Siguiente clase

[Clase 023 - Debugging y profiling: herramientas y mentalidad](../023-debugging-y-profiling-herramientas-y-mentalidad/README.md)
