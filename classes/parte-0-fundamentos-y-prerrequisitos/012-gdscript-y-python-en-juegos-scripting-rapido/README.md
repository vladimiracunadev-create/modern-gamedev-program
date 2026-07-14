# Clase 012 — GDScript y Python en juegos: scripting rápido

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Documentación de Godot (GDScript)*
> ⏱️ Duración estimada: **100 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

No todo el código de un juego necesita el rendimiento extremo de C++. La lógica de juego, los prototipos y las herramientas se escriben mucho más rápido en lenguajes de **scripting** como GDScript (el lenguaje propio de Godot) o Python. Iteras al instante, sin esperar compilaciones largas.

En esta clase compararás lenguajes compilados con interpretados, conocerás la sintaxis pythónica de **GDScript** (con `extends`, variables `@export` y su integración con nodos), y usarás **Python con pygame** para prototipar. Escribirás un script GDScript de ejemplo y un prototipo ejecutable en pygame: una ventana con un cuadrado que se mueve con el teclado.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diferenciar lenguajes compilados de interpretados y su rol en un juego.
2. Leer y escribir un script GDScript con `extends`, `@export` y funciones de ciclo de vida.
3. Explicar cómo un script de Godot se integra con un nodo de la escena.
4. Instalar pygame y ejecutar un prototipo mínimo con ventana y game loop.
5. Decidir cuándo conviene GDScript, Python o un lenguaje compilado.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Compilado vs interpretado | Rendimiento vs velocidad de iteración. |
| 2 | GDScript: sintaxis pythónica | Curva de aprendizaje corta en Godot. |
| 3 | `extends` y nodos | El script da comportamiento a un nodo. |
| 4 | `@export` y tipado opcional | Ajustar valores desde el editor sin tocar código. |
| 5 | `_ready` y `_process` | Ciclo de vida e integración con el frame. |
| 6 | Python + pygame | Prototipar mecánicas sin un motor completo. |
| 7 | Cuándo usar cada lenguaje | Elegir la herramienta adecuada por tarea. |

## 📖 Definiciones y características

- **Lenguaje compilado**: se traduce a código máquina antes de ejecutar (C++). Clave: máximo rendimiento.
- **Lenguaje interpretado/scripting**: se ejecuta línea a línea en runtime (Python, GDScript). Clave: iteración rápida.
- **GDScript**: lenguaje integrado de Godot con sintaxis tipo Python. Clave: acceso directo a nodos y señales.
- **`extends`**: indica de qué tipo de nodo hereda el script. Clave: el script "es" ese nodo.
- **`@export`**: expone una variable en el inspector del editor. Clave: ajustar sin recompilar.
- **`_ready()`**: se llama una vez al entrar el nodo en la escena. Clave: inicialización.
- **`_process(delta)`**: se llama cada frame; `delta` es el tiempo transcurrido. Clave: lógica por frame independiente de FPS.
- **pygame**: librería de Python para 2D con ventana, eventos y dibujo. Clave: prototipar sin motor.

## 🧰 Herramientas y preparación

Para GDScript instala Godot 4.x (<https://godotengine.org/download>), que incluye su propio editor de scripts; no necesitas nada más. Para el prototipo de Python necesitas Python 3.10+ (<https://www.python.org/downloads/>) y la librería pygame, que se instala con `pip install pygame`. Editor recomendado para Python: Visual Studio Code (<https://code.visualstudio.com/>). La referencia principal es la documentación oficial de GDScript (<https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/>) y la de pygame (<https://www.pygame.org/docs/>).

## 🧪 Laboratorio guiado

### Paso 1 — Anatomía de un script GDScript

Este script mueve un `Sprite2D` horizontalmente. En Godot se adjunta a un nodo; aquí lo analizamos línea a línea:

```gdscript
extends Sprite2D           # el script ES un Sprite2D (hereda su comportamiento)

@export var velocidad: float = 200.0   # editable desde el inspector del editor
var direccion: int = 1                  # variable interna, tipado opcional

func _ready() -> void:
    # Se ejecuta una vez cuando el nodo entra en la escena
    print("Sprite listo en la posicion ", position)

func _process(delta: float) -> void:
    # Se ejecuta cada frame; delta = segundos desde el frame anterior
    position.x += velocidad * direccion * delta
    if position.x > 600 or position.x < 0:
        direccion *= -1   # rebota en los bordes
```

Fíjate en `@export`: la `velocidad` aparecerá en el editor de Godot para ajustarla sin tocar el código. El uso de `delta` hace que el movimiento sea el mismo aunque cambien los FPS.

### Paso 2 — Instalar pygame

En una terminal:

```bash
pip install pygame
```

Verifica la instalación:

```bash
python -c "import pygame; print(pygame.version.ver)"
```

### Paso 3 — Prototipo mínimo en pygame: ventana + cuadrado que se mueve

Crea `prototipo.py` con este código completo y ejecutable:

```python
import pygame

pygame.init()
ANCHO, ALTO = 640, 480
pantalla = pygame.display.set_mode((ANCHO, ALTO))
pygame.display.set_caption("Prototipo: cuadrado movil")
reloj = pygame.time.Clock()

# Estado del cuadrado
x, y = ANCHO // 2, ALTO // 2
lado = 40
velocidad = 250  # pixeles por segundo

corriendo = True
while corriendo:
    dt = reloj.tick(60) / 1000.0  # segundos desde el frame anterior

    # 1) Entrada: eventos y teclas
    for evento in pygame.event.get():
        if evento.type == pygame.QUIT:
            corriendo = False
    teclas = pygame.key.get_pressed()
    if teclas[pygame.K_LEFT]:  x -= velocidad * dt
    if teclas[pygame.K_RIGHT]: x += velocidad * dt
    if teclas[pygame.K_UP]:    y -= velocidad * dt
    if teclas[pygame.K_DOWN]:  y += velocidad * dt

    # 2) Mantener el cuadrado dentro de la ventana
    x = max(0, min(ANCHO - lado, x))
    y = max(0, min(ALTO - lado, y))

    # 3) Dibujo
    pantalla.fill((20, 20, 30))                       # fondo
    pygame.draw.rect(pantalla, (80, 200, 120),
                     (x, y, lado, lado))              # cuadrado verde
    pygame.display.flip()

pygame.quit()
```

### Paso 4 — Ejecutar el prototipo

```bash
python prototipo.py
```

Se abre una ventana con un cuadrado verde. Muévelo con las flechas del teclado; observa que rebota contra los bordes gracias al recorte de posición. Cierra la ventana para terminar. Nota cómo el uso de `dt` hace que la velocidad sea consistente igual que con `delta` en GDScript.

## ✍️ Ejercicios

1. En pygame, cambia el color del cuadrado según la dirección de movimiento.
2. Añade una segunda tecla (barra espaciadora) que duplique la velocidad mientras se mantenga pulsada.
3. En el script GDScript, añade un `@export var color: Color` y explica dónde aparecería en el editor.
4. En pygame, dibuja un segundo cuadrado controlado con `W`, `A`, `S`, `D`.
5. Añade al prototipo un contador de FPS en el título con `reloj.get_fps()`.
6. Reescribe el movimiento del prototipo usando una variable `direccion` que rebote sola, como en el GDScript.

## 📝 Reto verificable

Amplía `prototipo.py` para que el cuadrado, además de moverse con las flechas, pierda "energía" con el tiempo: crea una variable `energia` que empiece en 100 y baje 10 por segundo. Muestra la energía en el título de la ventana y, cuando llegue a 0, cambia el color del cuadrado a rojo y detén su movimiento.

**Criterio de aceptación**: el programa corre con `python prototipo.py`, se ve la ventana, el cuadrado responde a las flechas, el título muestra la energía decreciendo con el tiempo (usando `dt`), y al llegar a 0 el cuadrado se vuelve rojo y deja de moverse.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| `ModuleNotFoundError: No module named 'pygame'` | pygame no está instalado en ese Python. Ejecuta `pip install pygame`. |
| La ventana se congela o "no responde" | Falta procesar eventos. Incluye siempre el bucle `for evento in pygame.event.get()`. |
| El cuadrado se mueve a distinta velocidad según el PC | No usaste `dt`. Multiplica los desplazamientos por el delta de tiempo. |
| En GDScript `@export` no aparece en el inspector | El script no está adjunto a un nodo o falta guardar la escena. Adjúntalo y guarda. |
| `Invalid call. Nonexistent function '_process'` mal escrito | Nombre de función de ciclo de vida incorrecto. Debe ser `_process(delta)`. |
| La imagen "parpadea" o no se ve | Olvidaste `pygame.display.flip()` tras dibujar. Añádelo al final del frame. |

## ❓ Preguntas frecuentes

**❓ ¿GDScript es más lento que C++?** Sí, es interpretado, pero para la mayoría de la lógica de juego la diferencia es irrelevante y ganas muchísima velocidad de iteración. Lo crítico en rendimiento se optimiza aparte.

**❓ ¿Puedo hacer un juego completo solo con pygame?** Sí para proyectos 2D pequeños o prototipos, pero pygame no es un motor: tú programas el bucle, colisiones y render. Para proyectos grandes conviene un motor como Godot.

**❓ ¿Por qué GDScript se parece tanto a Python?** Fue diseñado con sintaxis pythónica para ser fácil de aprender, pero es un lenguaje propio de Godot, integrado con sus nodos y señales; no ejecuta librerías de Python.

**❓ ¿Qué significa `_process(delta)`?** Es una función que Godot llama cada frame; `delta` son los segundos transcurridos desde el frame anterior, lo que permite un movimiento independiente de la tasa de fotogramas.

## 🔗 Referencias

- Godot Docs, "GDScript basics": <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html>
- Godot Docs, "Your first script": <https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_first_script.html>
- pygame, documentación oficial: <https://www.pygame.org/docs/>
- pygame, "A Newbie Guide": <https://www.pygame.org/docs/tut/newbieguide.html>

## ➡️ Siguiente clase

[Clase 013 - Patrones de diseño en juegos: State, Observer, Component y más](../013-patrones-de-diseno-en-juegos-state-observer-component-y-mas/README.md)
