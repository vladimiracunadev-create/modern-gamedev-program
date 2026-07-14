# Clase 004 — Matemáticas para juegos I: vectores y álgebra lineal

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Eric Lengyel, Mathematics for 3D Game Programming and Computer Graphics*
> ⏱️ Duración estimada: **100 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Dominar la herramienta matemática más usada en videojuegos: el vector. Posiciones, direcciones, velocidades, disparos y colisiones se expresan con vectores. Aprenderás suma, escalado, magnitud, normalización, producto punto y producto cruz, y para qué sirve cada uno en un juego.

Esto importa porque casi toda la lógica de movimiento, IA y física se reduce a operaciones vectoriales. Sin ellas, "mover al enemigo hacia el jugador" o "saber si algo está delante" es imposible de programar bien.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. **Operar** vectores: suma, resta y escalado, con resultados numéricos correctos.
2. **Calcular** la magnitud y normalizar un vector a longitud 1.
3. **Aplicar** el producto punto para medir ángulo y detectar frente/espalda.
4. **Usar** el producto cruz 2D para saber orientación (izquierda/derecha) y área.
5. **Implementar** una clase `Vec2` y resolver problemas típicos de juego con ella.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es un vector | Representa posición, dirección y velocidad |
| 2 | Suma, resta y escalado | Mueven y combinan entidades |
| 3 | Magnitud (longitud) | Mide distancias y velocidades |
| 4 | Normalización | Da direcciones puras de longitud 1 |
| 5 | Producto punto (dot) | Mide ángulos y detecta frente/espalda |
| 6 | Producto cruz | Da perpendicular, área y orientación |
| 7 | Distancia entre puntos | Base de rangos, colisiones y IA |

## 📖 Definiciones y características

- **Vector**: magnitud con dirección, escrito `(x, y)`. Clave: puede ser posición o dirección según el contexto.
- **Suma de vectores**: `(a+c, b+d)`. Clave: mover una posición por un desplazamiento.
- **Escalado**: multiplicar por un número `k·(x, y)`. Clave: cambia longitud sin cambiar dirección (si k>0).
- **Magnitud**: `√(x² + y²)`. Clave: longitud del vector; distancia si va de A a B.
- **Normalizar**: dividir por la magnitud para obtener longitud 1. Clave: separa dirección de rapidez.
- **Producto punto (dot)**: `a·b = ax·bx + ay·by`. Clave: >0 mismo sentido, 0 perpendicular, <0 opuesto.
- **Producto cruz 2D**: `ax·by − ay·bx` (escalar). Clave: signo indica giro; magnitud, el área.
- **Vector unitario**: vector de magnitud 1. Clave: representa dirección pura.

## 🧰 Herramientas y preparación

Necesitas Python 3.10 o superior <https://www.python.org/downloads>. Solo usaremos el módulo estándar `math`; no requiere librerías externas. Verifica con `python --version`. La referencia teórica es *Mathematics for 3D Game Programming and Computer Graphics* de Eric Lengyel <https://foundationsofgameenginedev.com>. Ten a mano papel para dibujar los vectores mientras compruebas los resultados numéricos.

## 🧪 Laboratorio guiado

Construirás una clase `Vec2` y resolverás tres problemas reales de juego: ¿el enemigo está delante?, ¿a qué distancia está?, ¿cómo moverse hacia un objetivo a velocidad constante?

**Paso 1 — Crea la clase `Vec2`.** Archivo `vec2.py`:

```python
import math

class Vec2:
    def __init__(self, x=0.0, y=0.0):
        self.x = float(x)
        self.y = float(y)

    def __add__(self, o):      # suma: a + b
        return Vec2(self.x + o.x, self.y + o.y)

    def __sub__(self, o):      # resta: a - b  (vector de o hacia self)
        return Vec2(self.x - o.x, self.y - o.y)

    def __mul__(self, k):      # escalado: v * k
        return Vec2(self.x * k, self.y * k)

    def length(self):          # magnitud
        return math.hypot(self.x, self.y)

    def normalized(self):      # vector unitario (dirección)
        L = self.length()
        if L == 0:
            return Vec2(0, 0)
        return Vec2(self.x / L, self.y / L)

    def dot(self, o):          # producto punto
        return self.x * o.x + self.y * o.y

    def cross(self, o):        # producto cruz 2D (escalar)
        return self.x * o.y - self.y * o.x

    def __repr__(self):
        return f"Vec2({self.x:.3f}, {self.y:.3f})"
```

**Paso 2 — Comprueba las operaciones básicas.** Añade al final del archivo (o en `pruebas.py`):

```python
a = Vec2(3, 4)
b = Vec2(1, 2)
print("a + b =", a + b)             # Vec2(4.000, 6.000)
print("a - b =", a - b)             # Vec2(2.000, 2.000)
print("a * 2 =", a * 2)             # Vec2(6.000, 8.000)
print("|a|   =", a.length())        # 5.0  (3-4-5)
print("norm a=", a.normalized())    # Vec2(0.600, 0.800)  -> longitud 1
```

El vector `(3, 4)` tiene magnitud exactamente 5, y su normalizado `(0.6, 0.8)` tiene longitud 1. Verifícalo: `0.6² + 0.8² = 0.36 + 0.64 = 1`.

**Paso 3 — ¿El enemigo está delante del jugador?** Usamos el producto punto entre la dirección a la que mira el jugador y el vector hacia el enemigo. Si `dot > 0`, está delante.

```python
jugador_pos  = Vec2(0, 0)
jugador_mira = Vec2(1, 0).normalized()   # mira hacia +X (derecha)

enemigo_a = Vec2(5, 1)    # a la derecha y un poco arriba -> delante
enemigo_b = Vec2(-4, 2)   # a la izquierda -> detrás

def esta_delante(pos, mira, objetivo):
    hacia = (objetivo - pos).normalized()
    d = mira.dot(hacia)
    return d, d > 0

for nombre, e in [("A", enemigo_a), ("B", enemigo_b)]:
    d, delante = esta_delante(jugador_pos, jugador_mira, e)
    print(f"Enemigo {nombre}: dot={d:+.3f} -> {'DELANTE' if delante else 'DETRAS'}")
```

Salida esperada:

```text
Enemigo A: dot=+0.981 -> DELANTE
Enemigo B: dot=-0.894 -> DETRAS
```

El signo del producto punto decide frente o espalda; su valor (cercano a 1) indica cuán alineado está.

**Paso 4 — Distancia entre dos entidades.** La distancia es la magnitud del vector diferencia:

```python
def distancia(p, q):
    return (p - q).length()

print("dist =", distancia(Vec2(0, 0), Vec2(3, 4)))   # 5.0
print("dist =", distancia(Vec2(2, 1), Vec2(5, 5)))   # 5.0 (3,4 otra vez)
```

Úsalo para rangos: "si `distancia(jugador, enemigo) < 3`, el enemigo ataca".

**Paso 5 — Mover hacia un objetivo a velocidad constante.** Normalizamos la dirección y la escalamos por `velocidad * dt`:

```python
def mover_hacia(pos, objetivo, velocidad, dt):
    direccion = (objetivo - pos).normalized()
    return pos + direccion * (velocidad * dt)

pos = Vec2(0, 0)
objetivo = Vec2(10, 0)
velocidad = 5.0   # unidades por segundo
dt = 1.0          # un frame de 1 segundo

for paso in range(3):
    pos = mover_hacia(pos, objetivo, velocidad, dt)
    print(f"paso {paso+1}: {pos}  dist restante={distancia(pos, objetivo):.2f}")
```

Salida:

```text
paso 1: Vec2(5.000, 0.000)  dist restante=5.00
paso 2: Vec2(10.000, 0.000) dist restante=0.00
paso 3: Vec2(15.000, 0.000) dist restante=5.00
```

Nota el paso 3: sin comprobar la llegada, la entidad se pasa del objetivo. En los ejercicios corregirás esto.

**Paso 6 — Orientación con producto cruz.** El signo del cruz 2D dice si el objetivo está a la izquierda o a la derecha de tu mirada:

```python
mira = Vec2(1, 0)
izq  = Vec2(0, 1)     # arriba
der  = Vec2(0, -1)    # abajo
print("cross izq =", mira.cross(izq))   # +1  -> a la izquierda
print("cross der =", mira.cross(der))   # -1  -> a la derecha
```

## ✍️ Ejercicios

1. Corrige `mover_hacia` para que la entidad no sobrepase el objetivo (si el paso es mayor que la distancia restante, colócala exactamente en el objetivo).
2. Añade a `Vec2` un método `distance_to(o)` y reescribe la función `distancia` usándolo.
3. Calcula el ángulo en grados entre dos vectores usando `dot` y `math.acos` (recuerda dividir por las magnitudes).
4. Dado un jugador que mira en `(1, 0)` y un cono de visión de 90°, decide si un enemigo está dentro del cono usando el producto punto.
5. Usa el producto cruz para determinar si tres puntos forman un giro horario o antihorario.
6. Implementa `clamp_length(v, max_len)` que limite la magnitud de un vector sin cambiar su dirección.

## 📝 Reto verificable

Entrega `vec2.py` con la clase completa y un script `demo.py` que resuelva los tres problemas del laboratorio: detectar frente/espalda de dos enemigos, imprimir la distancia jugador-enemigo, y mover una entidad hacia un objetivo sin sobrepasarlo, mostrando la posición en cada frame hasta llegar.

**Criterio de aceptación**: `python demo.py` imprime el `dot` con signo correcto para cada enemigo (delante/detrás), una distancia numérica correcta (verificable a mano con Pitágoras), y la entidad llega exactamente al objetivo sin sobrepasarlo (distancia restante final = 0.00).

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| `ZeroDivisionError` en `normalized` | El vector es `(0,0)`. Devuelve `(0,0)` si la longitud es 0 (ya está en el código). |
| La entidad "vibra" alrededor del objetivo | El paso sobrepasa el objetivo. Limita el paso a la distancia restante. |
| Ángulo da `nan` con `acos` | El coseno salió fuera de [−1, 1] por error numérico. Recórtalo con `max(-1, min(1, c))`. |
| Restar en el orden equivocado | `objetivo - pos` va de pos hacia objetivo; `pos - objetivo` es el opuesto. Verifica la dirección. |
| Movimiento depende de los FPS | Olvidaste `* dt`. Escala siempre por delta time. |

## ❓ Preguntas frecuentes

**❓ ¿Cuándo un vector es una posición y cuándo una dirección?** Depende del uso. `(5, 3)` puede ser "el punto (5,3)" o "muévete 5 a la derecha y 3 arriba". La resta de dos posiciones da una dirección.

**❓ ¿Por qué normalizar antes de mover?** Para separar dirección de rapidez. Así controlas la velocidad con un número aparte y el movimiento es uniforme en todas direcciones.

**❓ ¿El producto punto sirve en 3D igual?** Sí, la fórmula solo suma un término `az·bz`. El significado (ángulo, frente/espalda) es idéntico.

**❓ ¿Por qué el cruz en 2D da un número y no un vector?** Porque el resultado apunta fuera del plano (eje Z); en 2D nos quedamos con esa componente escalar, cuyo signo indica la orientación.

## 🔗 Referencias

- Eric Lengyel, *Mathematics for 3D Game Programming and Computer Graphics* — <https://foundationsofgameenginedev.com>
- Módulo `math` de Python — <https://docs.python.org/3/library/math.html>
- Freya Holmér, "The Beauty of Bézier / Vectors" (canal educativo de matemáticas para juegos) — <https://www.youtube.com/@Acegikmo>

## ➡️ Siguiente clase

[Clase 005 - Matemáticas para juegos II: matrices y transformaciones](../005-matematicas-para-juegos-ii-matrices-y-transformaciones/README.md)
