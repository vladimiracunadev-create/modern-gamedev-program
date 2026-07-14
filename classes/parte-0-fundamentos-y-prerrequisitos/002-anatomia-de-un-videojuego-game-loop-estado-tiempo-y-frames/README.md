# Clase 002 — Anatomía de un videojuego: game loop, estado, tiempo y frames

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Robert Nystrom, Game Programming Patterns (Game Loop)*
> ⏱️ Duración estimada: **90 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Entender el corazón de todo videojuego: el **game loop**, el bucle que ejecuta continuamente input → update → render. Verás por qué un juego no es un programa que "termina", sino uno que avanza en el tiempo cuadro a cuadro (frame a frame) y cómo se separa la lógica (update) de lo que se dibuja (render).

Esto importa porque cada motor, sin excepción, tiene un game loop en su núcleo. Comprenderlo te permite razonar sobre FPS, movimiento consistente y por qué el tiempo se mide, no se supone.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. **Explicar** las tres fases del game loop y el orden en que se ejecutan.
2. **Diferenciar** entre update (lógica) y render (dibujo) y por qué se separan.
3. **Calcular** los FPS a partir del tiempo por frame (delta time).
4. **Implementar** un game loop mínimo en Python que anime una entidad.
5. **Justificar** por qué no se usa un `sleep` fijo para controlar el tiempo del juego.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es el game loop | Es la estructura que hace "correr" el juego |
| 2 | Fases input → update → render | Ordena qué se hace en cada frame |
| 3 | Frame y FPS | Mide el rendimiento y la fluidez |
| 4 | Delta time (Δt) | Hace el movimiento independiente del hardware |
| 5 | Estado del juego | Guarda la información que evoluciona en el tiempo |
| 6 | Separar update de render | Permite lógica estable y dibujo flexible |
| 7 | Por qué no usar sleep fijo | Evita movimiento inconsistente entre máquinas |

## 📖 Definiciones y características

- **Game loop**: bucle que repite input, update y render mientras el juego corre. Clave: nunca "termina" hasta que se cierra.
- **Frame (cuadro)**: una iteración completa del loop. Clave: unidad de tiempo del juego.
- **FPS (frames por segundo)**: cuántos frames se procesan por segundo. Clave: 60 FPS ≈ 16.6 ms por frame.
- **Delta time (Δt)**: segundos transcurridos desde el frame anterior. Clave: multiplica velocidades para independizarlas del hardware.
- **Update**: fase que avanza la lógica y el estado. Clave: aquí ocurre "la simulación".
- **Render**: fase que dibuja el estado actual. Clave: no debe modificar la lógica.
- **Estado del juego**: conjunto de datos que cambian (posición, vida, puntaje). Clave: es lo que update transforma.
- **Frame rate independiente**: comportamiento igual sin importar los FPS. Clave: se logra usando Δt.

## 🧰 Herramientas y preparación

Necesitas Python 3.10 o superior instalado <https://www.python.org/downloads>. Verifica con `python --version` en la terminal. No hace falta ninguna librería externa: usaremos solo el módulo estándar `time`. Como marco conceptual, lee el capítulo "Game Loop" de *Game Programming Patterns* de Robert Nystrom, disponible gratis en línea <https://gameprogrammingpatterns.com/game-loop.html>.

## 🧪 Laboratorio guiado

Construirás un game loop de consola que simula una pelota rebotando en una línea de 1 dimensión, mide FPS reales y separa update de render.

**Paso 1 — El bucle más simple.** Crea `loop_basico.py`. Observa la estructura input → update → render:

```python
import time

running = True
frame = 0

while running:
    # 1) INPUT: aquí leeríamos teclado/mouse (omitido en consola)
    # 2) UPDATE: avanzar la lógica
    frame += 1
    # 3) RENDER: mostrar el estado
    print(f"Frame {frame}")
    if frame >= 5:
        running = False
```

Ejecuta con `python loop_basico.py`. Verás cinco frames y el programa termina. Ese es el esqueleto de todo juego.

**Paso 2 — Añade estado: la pelota.** La pelota tiene una posición `x` y una velocidad. Rebota entre 0 y 20:

```python
import time

# --- Estado del juego ---
x = 0.0            # posición
vx = 15.0          # velocidad en unidades por segundo
MIN_X, MAX_X = 0.0, 20.0
```

**Paso 3 — Usa delta time.** El movimiento se calcula con `x += vx * dt`, no con `x += vx`. Así avanza igual sin importar cuántos FPS logre la máquina. Programa completo `pelota.py`:

```python
import time

# --- Estado del juego ---
x = 0.0
vx = 15.0                 # unidades por segundo
MIN_X, MAX_X = 0.0, 20.0

running = True
frame = 0
prev = time.perf_counter()      # reloj de alta resolución
start = prev
DURACION = 3.0                  # correr 3 segundos

def update(x, vx, dt):
    x += vx * dt
    # rebote: invertir velocidad al tocar los bordes
    if x >= MAX_X:
        x = MAX_X
        vx = -vx
    elif x <= MIN_X:
        x = MIN_X
        vx = -vx
    return x, vx

def render(x, fps):
    pos = int(x)
    barra = "." * pos + "O" + "." * (int(MAX_X) - pos)
    print(f"[{barra}] x={x:5.1f}  fps={fps:5.1f}")

while running:
    now = time.perf_counter()
    dt = now - prev             # delta time real de este frame
    prev = now
    frame += 1

    # INPUT: (sin entrada en este ejemplo de consola)
    # UPDATE
    x, vx = update(x, vx, dt)
    # RENDER
    fps = 1.0 / dt if dt > 0 else 0.0
    render(x, fps)

    if now - start >= DURACION:
        running = False

print(f"\nTotal de frames: {frame} en {DURACION:.0f}s -> promedio {frame/DURACION:.1f} FPS")
```

**Paso 4 — Ejecuta y observa.** Corre `python pelota.py`. Verás la `O` moverse de un lado a otro y rebotar. Al final se imprime algo como:

```text
[O...................] x=  0.0  fps= ...
[.....O..............] x=  5.1  fps=  ...
[..........O.........] x= 10.2  ...
Total de frames: 74213 en 3s -> promedio 24737.7 FPS
```

Los FPS serán altísimos porque no hay dibujo pesado; lo importante es que la posición depende de Δt, no del número de frames.

**Paso 5 — Comprueba la independencia del hardware.** Añade `time.sleep(0.05)` justo antes del `render` para simular una máquina lenta (≈20 FPS). La pelota tarda lo mismo en cruzar de un lado a otro, porque `vx * dt` compensa el menor número de frames. Ese es el punto central: **el tiempo se mide, no se cuenta en frames**.

## ✍️ Ejercicios

1. Modifica la pelota para que rebote también contra un límite inferior distinto (por ejemplo entre 5 y 15).
2. Añade una segunda pelota con velocidad distinta y muéstralas en la misma línea.
3. Calcula e imprime el FPS mínimo y máximo observados durante la ejecución.
4. Separa el código en dos funciones puras `update` y `render` sin variables globales (pásalas por parámetro).
5. Explica en un comentario del código qué pasaría si usaras `x += vx` en lugar de `x += vx * dt`.
6. Haz que la simulación termine cuando la pelota haya rebotado exactamente 4 veces (usa un contador de rebotes).

## 📝 Reto verificable

Entrega `pelota.py` con un game loop que: (a) mueva una pelota usando delta time, (b) la haga rebotar en ambos bordes, (c) imprima los FPS por frame y (d) al finalizar muestre el total de frames, la duración y el FPS promedio.

**Criterio de aceptación**: al ejecutar `python pelota.py`, el movimiento usa `vx * dt` (no `vx` a secas), la pelota rebota sin salirse de `[MIN_X, MAX_X]`, y al añadir un `sleep` que reduzca los FPS el tiempo total de cruce se mantiene aproximadamente igual (± 10 %).

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La pelota va más rápido en un PC potente | Usaste `x += vx` sin Δt. Multiplica siempre por `dt`. |
| `ZeroDivisionError` al calcular FPS | `dt` fue 0. Protege con `if dt > 0` antes de dividir. |
| La pelota se "escapa" del rango | No corriges la posición al rebotar. Fija `x` al borde antes de invertir `vx`. |
| Uso de `time.time()` da FPS erráticos | Baja resolución. Usa `time.perf_counter()`. |
| El programa nunca termina | Falta condición de salida. Usa una duración o un contador de frames. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué no controlo la velocidad con `sleep(0.016)` fijo?** Porque el propio update y render tardan un tiempo variable; un sleep fijo no garantiza 60 FPS reales y produce movimiento inconsistente. Medir Δt es robusto.

**❓ ¿Update y render siempre corren al mismo ritmo?** No necesariamente. Motores avanzados usan update a paso fijo y render libre, pero el principio de separarlos ya aparece aquí.

**❓ ¿Qué es un "frame drop"?** Un frame que tarda más de lo normal, bajando los FPS momentáneamente. Con Δt la simulación se mantiene correcta aunque haya drops.

**❓ ¿Esto aplica a Godot o Unity?** Sí. En Godot recibes `delta` en `_process`, en Unity `Time.deltaTime`. Es el mismo concepto que acabas de implementar.

## 🔗 Referencias

- Robert Nystrom, *Game Programming Patterns* — capítulo "Game Loop" <https://gameprogrammingpatterns.com/game-loop.html>
- Documentación de Python `time` — <https://docs.python.org/3/library/time.html>
- Godot: método `_process(delta)` — <https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html>

## ➡️ Siguiente clase

[Clase 003 - Historia y géneros: qué define la jugabilidad](../003-historia-y-generos-que-define-la-jugabilidad/README.md)
