# Clase 007 — Física básica para juegos: cinemática, fuerzas e integración

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Ian Millington, Game Physics Engine Development*
> ⏱️ Duración estimada: **100 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Casi todo lo que se mueve en un juego —un salto, una bala, una caja que cae, un coche que frena— se describe con tres cantidades: posición, velocidad y aceleración. Entender cómo se relacionan y cómo avanzarlas frame a frame (integración) es la base de cualquier motor de física.

En esta clase construirás un mini-simulador en Python: aplicarás gravedad, verás por qué la integración de Euler semi-implícita es estable mientras la explícita "gana energía", y añadirás drag para frenar el movimiento de forma realista. Todo imprimiendo la trayectoria numérica frame a frame.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Distinguir posición, velocidad y aceleración y cómo se derivan unas de otras.
2. Aplicar `F = m·a` para obtener aceleración a partir de fuerzas y masa.
3. Implementar integración de Euler explícita y semi-implícita, y explicar por qué la segunda es más estable.
4. Simular un salto con gravedad e impulso inicial, imprimiendo la altura por frame.
5. Añadir drag (resistencia) para amortiguar la velocidad de forma controlada.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Posición, velocidad, aceleración | Son el estado mínimo de todo cuerpo en movimiento. |
| 2 | Gravedad | Fuerza constante que da peso a los objetos. |
| 3 | F = m·a | Convierte fuerzas acumuladas en aceleración. |
| 4 | Integración de Euler explícita | La forma más simple... y también inestable. |
| 5 | Euler semi-implícita | El estándar práctico en juegos por su estabilidad. |
| 6 | Drag / fricción | Frena el movimiento y evita velocidades infinitas. |
| 7 | Salto como impulso | Un cambio instantáneo de velocidad hacia arriba. |

## 📖 Definiciones y características

- **Posición**: dónde está el objeto. Clave: cambia según la velocidad y el paso de tiempo `dt`.
- **Velocidad**: cuánto cambia la posición por segundo. Clave: se acumula por la aceleración.
- **Aceleración**: cuánto cambia la velocidad por segundo. Clave: surge de las fuerzas dividido por la masa.
- **dt (delta time)**: tiempo entre frames. Clave: multiplica cada integración para independizar de los FPS.
- **F = m·a**: segunda ley de Newton. Clave: `a = F / m`, así sumas fuerzas y obtienes aceleración.
- **Euler explícito**: usa la velocidad vieja para mover. Clave: simple pero puede añadir energía y explotar.
- **Euler semi-implícito**: actualiza la velocidad primero y con ella mueve. Clave: estable, casi el mismo coste.
- **Drag**: fuerza opuesta al movimiento. Clave: multiplicar la velocidad por un factor <1 cada frame la amortigua.

## 🧰 Herramientas y preparación

Necesitas Python 3.10+ con la librería estándar (nada externo). Descárgalo de <https://www.python.org/downloads/> y verifica con `python --version`. Un editor como Visual Studio Code <https://code.visualstudio.com/> facilita ejecutar los scripts. El libro de referencia es *Game Physics Engine Development* de Ian Millington; su web de recursos es <https://www.gamephysicsengine.com/>. La documentación de Python está en <https://docs.python.org/3/>.

## 🧪 Laboratorio guiado

### Paso 1 — Estado de una partícula y gravedad

Crea `fisica_lab.py`:

```python
GRAVEDAD = -9.8   # m/s^2, hacia abajo
DT = 0.1          # 10 frames por segundo (para ver números claros)

# Estado inicial: en el suelo, saltando hacia arriba
pos_y = 0.0
vel_y = 15.0      # impulso del salto (m/s hacia arriba)
```

### Paso 2 — Salto con Euler semi-implícito

En el semi-implícito **primero** actualizamos la velocidad con la aceleración y **luego** movemos la posición con esa velocidad nueva:

```python
print("=== Euler SEMI-IMPLICITO ===")
pos_y, vel_y = 0.0, 15.0
frame = 0
while pos_y >= 0.0:
    vel_y += GRAVEDAD * DT     # 1) velocidad primero
    pos_y += vel_y * DT        # 2) posicion con la velocidad nueva
    frame += 1
    print(f"Frame {frame:2d}: altura = {pos_y:6.2f} m, vel = {vel_y:6.2f} m/s")
print(f"Aterrizo en el frame {frame}\n")
```

Verás la altura subir, frenarse en el pico y volver a bajar hasta cruzar el suelo.

### Paso 3 — Comparar con Euler explícito

En el explícito movemos con la velocidad **vieja** y luego actualizamos la velocidad:

```python
print("=== Euler EXPLICITO ===")
pos_y, vel_y = 0.0, 15.0
frame = 0
while pos_y >= 0.0 and frame < 40:
    pos_y += vel_y * DT        # 1) posicion con la velocidad vieja
    vel_y += GRAVEDAD * DT     # 2) velocidad despues
    frame += 1
    print(f"Frame {frame:2d}: altura = {pos_y:6.2f} m, vel = {vel_y:6.2f} m/s")
```

Compara ambas trayectorias: el explícito llega un poco más alto y tarda más en caer porque "gana" energía en cada paso. Con dt grandes o resortes, esa energía extra hace que la simulación explote. Por eso los juegos prefieren el semi-implícito.

### Paso 4 — Fuerzas con F = m·a

En vez de fijar la aceleración, acumulamos fuerzas y dividimos por la masa:

```python
masa = 2.0
def acumular_fuerzas():
    peso = masa * GRAVEDAD     # F = m*g
    return peso

pos_y, vel_y = 0.0, 15.0
for frame in range(1, 6):
    fuerza = acumular_fuerzas()
    accel = fuerza / masa       # a = F / m  -> vuelve a dar GRAVEDAD
    vel_y += accel * DT
    pos_y += vel_y * DT
    print(f"Frame {frame}: altura {pos_y:.2f}, vel {vel_y:.2f}")
```

### Paso 5 — Añadir drag

El drag resta energía multiplicando la velocidad por un factor menor que 1 cada frame:

```python
DRAG = 0.9   # 10% de la velocidad se pierde por frame
pos_y, vel_y = 0.0, 15.0
frame = 0
while pos_y >= 0.0:
    vel_y += GRAVEDAD * DT
    vel_y *= DRAG              # amortiguacion
    pos_y += vel_y * DT
    frame += 1
    print(f"Frame {frame:2d}: altura {pos_y:6.2f}, vel {vel_y:6.2f}")
print("Con drag el salto es mas bajo y cae mas suave.")
```

## ✍️ Ejercicios

1. Cambia el impulso inicial a 20 m/s y mide en qué frame se alcanza la altura máxima.
2. Reduce `DT` a 0.016 (60 FPS) y comprueba que la trayectoria es más suave.
3. Extiende la simulación a 2D añadiendo `pos_x` y `vel_x` con velocidad horizontal constante (un salto en parábola).
4. Prueba `DRAG = 0.98` y `DRAG = 0.7`; describe cómo cambia la altura del salto.
5. Con un `DT` grande (0.5), compara qué integrador explota antes.
6. Implementa una función `paso_semi_implicito(pos, vel, accel, dt)` reutilizable que devuelva `(pos, vel)` nuevos.

## 📝 Reto verificable

Simula un salto en 2D con Euler semi-implícito: impulso vertical de 12 m/s, velocidad horizontal de 4 m/s, gravedad -9.8 y `DT = 0.1`. Imprime `(x, y)` por frame hasta que aterrice y reporta el alcance horizontal total y la altura máxima.

**Criterio de aceptación**: la salida muestra una parábola (Y sube y baja mientras X crece de forma lineal), la altura máxima ronda los 7 m y el objeto aterriza con `y < 0`; usar el semi-implícito hace que la subida y bajada sean casi simétricas.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| La simulación "explota" a velocidades enormes | Usaste Euler explícito con dt grande. Cambia a semi-implícito o reduce `dt`. |
| El salto es cada vez más alto en cada bucle | Sumas la gravedad con signo positivo. La gravedad apunta hacia abajo: negativa. |
| El objeto nunca cae | Olvidaste aplicar la aceleración a la velocidad, o el `dt` es 0. |
| La física va distinta según los FPS | No multiplicaste por `dt`. Todo cambio debe escalarse por el paso de tiempo. |
| El drag detiene el objeto de golpe | Factor de drag demasiado bajo. Usa valores cercanos a 1 (0.9–0.99). |

## ❓ Preguntas frecuentes

**❓ ¿Por qué el semi-implícito es más estable que el explícito?** Porque actualiza la velocidad antes de mover; eso hace que la energía del sistema no crezca sin control, evitando que resortes y colisiones exploten.

**❓ ¿Qué es `dt` y por qué debo multiplicar por él?** Es el tiempo entre frames. Multiplicar por `dt` hace que la simulación avance lo mismo independientemente de si el juego corre a 30 o 144 FPS.

**❓ ¿La gravedad siempre vale 9.8?** No; 9.8 m/s² es la de la Tierra, pero en un juego eliges el valor que se sienta bien. Muchos juegos usan valores mayores para saltos más "arcade".

**❓ ¿Un salto es una fuerza o un impulso?** Un impulso: un cambio instantáneo de velocidad hacia arriba en el instante del salto, no una fuerza sostenida mientras estás en el aire.

## 🔗 Referencias

- Ian Millington, *Game Physics Engine Development*, 2ª ed., capítulos de partículas e integración.
- Glenn Fiedler, "Integration Basics": <https://gafferongames.com/post/integration_basics/>
- Documentación de Python: <https://docs.python.org/3/>
- Second law of Newton (F = ma): <https://en.wikipedia.org/wiki/Newton%27s_laws_of_motion>

## ➡️ Siguiente clase

[Clase 008 - Programación fundamentos con C#: tipos, control de flujo y funciones](../008-programacion-fundamentos-con-c-sharp-tipos-control-de-flujo-y-funciones/README.md)
