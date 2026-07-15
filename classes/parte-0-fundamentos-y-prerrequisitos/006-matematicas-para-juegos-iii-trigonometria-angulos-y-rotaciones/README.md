# Clase 006 — Matemáticas para juegos III: trigonometría, ángulos y rotaciones

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Eric Lengyel, Mathematics for 3D Game Programming and Computer Graphics*
> ⏱️ Duración estimada: **90 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

La trigonometría es el puente entre "un ángulo" y "una dirección en el mundo". Cuando una torreta debe apuntar a un enemigo, cuando un proyectil viaja en línea recta o cuando un personaje gira suavemente hacia un objetivo, siempre hay un seno, un coseno o un `atan2` trabajando por debajo.

En esta clase aprenderás a convertir entre ángulos y vectores, a calcular el ángulo hacia un objetivo con `atan2`, a rotar vectores y a interpolar ángulos correctamente resolviendo el problema del "salto" de 360°. Todo con código Python ejecutable que imprime números reales.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Convertir correctamente entre grados y radianes en ambos sentidos.
2. Calcular el ángulo hacia un objetivo usando `atan2(dy, dx)` y explicar por qué se prefiere sobre `atan`.
3. Transformar un ángulo en un vector dirección unitario mediante `(cos θ, sin θ)`.
4. Rotar un vector 2D un ángulo dado aplicando la matriz de rotación.
5. Interpolar entre dos ángulos gestionando el envolvimiento (wrap) para lograr el giro por el camino más corto.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Seno, coseno y tangente | Relacionan ángulos con proporciones de un triángulo. |
| 2 | Radianes vs grados | Las librerías trabajan en radianes; confundirlos rompe todo. |
| 3 | `atan2(dy, dx)` | Da el ángulo hacia un objetivo en los cuatro cuadrantes. |
| 4 | Ángulo → vector dirección | Permite mover proyectiles y mirar hacia donde se apunta. |
| 5 | Rotación de vectores | Base de girar sprites, direcciones y cámaras. |
| 6 | Interpolación de ángulos | Giros suaves de enemigos sin saltos bruscos. |
| 7 | Wrap de ángulos | Evita que el giro dé la vuelta larga (350° vs -10°). |

## 📖 Definiciones y características

- **Radián**: unidad angular donde una vuelta completa son `2π` (~6.283). Clave: es la unidad nativa de `math.sin`, `math.cos`.
- **Seno / coseno**: para un ángulo θ, `cos θ` es la componente X y `sin θ` la componente Y de un vector unitario. Clave: juntos forman la dirección.
- **Tangente**: `tan θ = sin θ / cos θ`, la pendiente. Clave: su inversa da el ángulo desde una pendiente.
- **atan2(y, x)**: función que devuelve el ángulo del vector `(x, y)` en el rango `(-π, π]`. Clave: maneja los signos y cuadrantes correctamente.
- **Vector dirección unitario**: vector de longitud 1 que indica hacia dónde. Clave: se multiplica por la velocidad para mover.
- **Matriz de rotación 2D**: `[cosθ -sinθ; sinθ cosθ]`. Clave: rota cualquier vector alrededor del origen.
- **Wrap angular**: normalizar un ángulo al rango `[-π, π]`. Clave: garantiza el giro por el camino más corto.
- **Lerp**: interpolación lineal `a + (b - a) * t`. Clave: aplicada a ángulos con wrap produce giro suave.

## 🧰 Herramientas y preparación

Solo necesitas Python 3.10+ con su módulo estándar `math` (ya incluido). Instala Python desde <https://www.python.org/downloads/> y verifica con `python --version`. Como editor recomendamos Visual Studio Code <https://code.visualstudio.com/>. La documentación oficial del módulo está en <https://docs.python.org/3/library/math.html>. No hace falta instalar paquetes externos.

## 🧪 Laboratorio guiado

### Paso 1 — Conversión entre grados y radianes

Crea `trig_lab.py`:

```python
import math

def grados_a_rad(g): return g * math.pi / 180.0
def rad_a_grados(r): return r * 180.0 / math.pi

print("90 grados en radianes:", grados_a_rad(90))     # 1.5707...
print("pi radianes en grados:", rad_a_grados(math.pi)) # 180.0
print("cos(0) =", math.cos(0), " sin(0) =", math.sin(0))
print("cos(pi/2) =", round(math.cos(math.pi/2), 4),
      " sin(pi/2) =", round(math.sin(math.pi/2), 4))
```

Ejecuta con `python trig_lab.py`. Observa que `cos(pi/2)` es prácticamente 0 y `sin(pi/2)` es 1.

### Paso 2 — Torreta que apunta a un objetivo con atan2

```python
torreta = (0.0, 0.0)
objetivo = (3.0, 4.0)

dx = objetivo[0] - torreta[0]
dy = objetivo[1] - torreta[1]
angulo = math.atan2(dy, dx)   # ángulo hacia el objetivo, en radianes

print("Angulo hacia objetivo (rad):", round(angulo, 4))
print("Angulo hacia objetivo (grados):", round(rad_a_grados(angulo), 2))
```

Con objetivo `(3, 4)` el ángulo es ~0.927 rad (~53.13°). Prueba con `(-1, 0)` y verás 180°.

### Paso 3 — Convertir el ángulo en dirección y mover un proyectil

```python
velocidad = 5.0
dir_x = math.cos(angulo)   # componente X de la dirección unitaria
dir_y = math.sin(angulo)
print("Direccion unitaria:", round(dir_x, 3), round(dir_y, 3))

pos = [0.0, 0.0]
for frame in range(1, 4):
    pos[0] += dir_x * velocidad
    pos[1] += dir_y * velocidad
    print(f"Frame {frame}: proyectil en ({pos[0]:.2f}, {pos[1]:.2f})")
```

El proyectil avanza en línea recta hacia donde apunta la torreta.

### Paso 4 — Rotar un vector

```python
def rotar(vx, vy, ang):
    c, s = math.cos(ang), math.sin(ang)
    return (vx * c - vy * s, vx * s + vy * c)

rx, ry = rotar(1.0, 0.0, math.pi / 2)   # rotar (1,0) 90 grados
print("(1,0) rotado 90 grados:", round(rx, 3), round(ry, 3))  # ~ (0, 1)
```

### Paso 5 — Enemigo que gira suavemente hacia el jugador (lerp con wrap)

```python
def wrap(a):
    """Normaliza un angulo al rango [-pi, pi]."""
    return math.atan2(math.sin(a), math.cos(a))

def lerp_angulo(actual, objetivo, t):
    diff = wrap(objetivo - actual)   # diferencia por el camino corto
    return wrap(actual + diff * t)

enemigo_ang = grados_a_rad(170)     # mirando casi al oeste
objetivo_ang = grados_a_rad(-170)   # jugador casi al oeste por el otro lado

print("Inicio:", round(rad_a_grados(enemigo_ang), 1), "grados")
for frame in range(1, 6):
    enemigo_ang = lerp_angulo(enemigo_ang, objetivo_ang, 0.5)
    print(f"Frame {frame}: {rad_a_grados(enemigo_ang):.1f} grados")
```

Verás que el enemigo gira solo 20° por el camino corto (cruzando 180°) en lugar de dar la vuelta larga de 340°. Ese es el poder del wrap.

## ✍️ Ejercicios

1. Escribe una función que reciba dos puntos y devuelva la distancia y el ángulo entre ellos.
2. Modifica la torreta para que apunte a un objetivo que se mueve cada frame en `(t, sin(t))`.
3. Rota el vector `(2, 0)` en pasos de 45° y lista las 8 direcciones resultantes.
4. Implementa `lerp_angulo` con un factor `t = 0.1` y cuenta cuántos frames tarda en quedar a menos de 1° del objetivo.
5. Crea una función `angulo_entre(a, b)` que devuelva la diferencia mínima con signo entre dos ángulos.
6. Simula un proyectil con gravedad simple sumando `-0.5` a `dir_y` cada frame y observa la parábola.

## 📝 Reto verificable

Programa una torreta que gire suavemente (lerp de ángulo con wrap, `t = 0.2`) hacia un jugador ubicado en `(-5, 5)` partiendo de un ángulo de 0°, e imprima el ángulo por frame hasta alinearse. Cuando el error angular sea menor a 1°, dispara un proyectil e imprime sus 3 primeras posiciones.

**Criterio de aceptación**: la salida muestra el ángulo convergiendo hacia ~135° por el camino corto, y las posiciones del proyectil avanzan en línea recta hacia el cuadrante superior izquierdo (X negativa, Y positiva).

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| El objeto apunta 90° desviado | Invertiste los argumentos: es `atan2(dy, dx)`, no `atan2(dx, dy)`. |
| Todo se mueve rarísimo con ángulos grandes | Pasaste grados a `math.cos/sin` que esperan radianes. Convierte primero. |
| El enemigo da la vuelta larga al girar | No aplicaste `wrap` a la diferencia de ángulos. |
| `math.atan(dy/dx)` falla o da signo malo | `dx` puede ser 0 (división por cero) o negativo. Usa `atan2`. |
| El proyectil acelera solo | Multiplicaste dirección sin normalizar. `(cos, sin)` ya es unitario; no lo escales dos veces. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué `atan2` y no `atan`?** Porque `atan` solo devuelve ángulos en `(-90°, 90°)` y no distingue cuadrantes; `atan2` usa los signos de X e Y para cubrir la vuelta completa.

**❓ ¿En qué unidad trabajan `math.sin` y `math.cos`?** En radianes. Siempre convierte tus grados antes de usarlas.

**❓ ¿Qué significa que un vector sea unitario?** Que su longitud es 1; así puedes multiplicarlo por la velocidad para controlar cuánto avanza por frame.

**❓ ¿Por qué el wrap usa `atan2(sin(a), cos(a))`?** Porque descompone el ángulo en su dirección y lo reconstruye ya normalizado al rango `[-π, π]`, sin errores de módulo con signos negativos.

## 🔗 Referencias

- Eric Lengyel, *Mathematics for 3D Game Programming and Computer Graphics*, 3ª ed., cap. de trigonometría y transformaciones.
- Documentación del módulo `math` de Python: <https://docs.python.org/3/library/math.html>
- "atan2" explicación y cuadrantes: <https://en.wikipedia.org/wiki/Atan2>
- Red Blob Games, artículos de matemáticas 2D: <https://www.redblobgames.com/>

## ⬅️ Clase anterior

[Clase 005 - Matemáticas para juegos II: matrices y transformaciones](../005-matematicas-para-juegos-ii-matrices-y-transformaciones/README.md)

## ➡️ Siguiente clase

[Clase 007 - Física básica para juegos: cinemática, fuerzas e integración](../007-fisica-basica-para-juegos-cinematica-fuerzas-e-integracion/README.md)
