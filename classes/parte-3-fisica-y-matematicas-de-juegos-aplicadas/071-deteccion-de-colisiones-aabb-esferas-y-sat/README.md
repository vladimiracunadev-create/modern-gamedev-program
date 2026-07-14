# Clase 071 — Detección de colisiones: AABB, esferas y SAT

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Geometría de colisiones para juegos — apuntes de aula y práctica con Python*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Aprender a **detectar** contactos entre formas, el primer paso de toda física. Cubriremos las pruebas más usadas: AABB vs AABB (cajas alineadas), círculo/esfera vs esfera, punto dentro de una forma y el **teorema de los ejes separadores (SAT)** para polígonos convexos rotados. Programaremos todo en Python puro para ver claramente la geometría, sin motor de por medio.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Implementar la prueba **AABB vs AABB** con solapamiento en cada eje.
2. Detectar colisión **círculo-círculo** comparando distancia y suma de radios.
3. Verificar si un **punto** está dentro de un círculo o de una caja.
4. Explicar la idea del **SAT** y por qué basta con proyectar sobre unos pocos ejes.
5. Implementar un **SAT básico** para dos rectángulos rotados y obtener el solapamiento.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | AABB: cajas alineadas | La prueba más barata y frecuente |
| 2 | Círculo/esfera vs esfera | Ideal para personajes y proyectiles |
| 3 | Punto en forma | Clics, selección y triggers |
| 4 | Idea del SAT | Colisión exacta de polígonos convexos |
| 5 | Ejes candidatos y proyección | Núcleo del algoritmo SAT |
| 6 | Solapamiento mínimo | Base para separar y responder |
| 7 | Broadphase (intuición) | Descartar pares lejanos antes del test caro |

## 📖 Definiciones y características

- **AABB (Axis-Aligned Bounding Box)**: caja cuyos lados son paralelos a los ejes. Clave: la prueba es solo comparar intervalos.
- **Solapamiento en un eje**: dos intervalos se cruzan si el mínimo de uno es menor que el máximo del otro y viceversa. Clave: si un eje no solapa, no hay colisión.
- **Test círculo-círculo**: hay colisión si la distancia entre centros es menor que la suma de radios. Clave: compara distancias al cuadrado para evitar la raíz.
- **Punto en forma**: prueba de contención. Clave: en círculo es distancia < radio; en AABB, dentro de ambos intervalos.
- **SAT (Separating Axis Theorem)**: dos convexos no colisionan si existe un eje donde sus proyecciones no se solapan. Clave: para polígonos basta probar las normales de sus lados.
- **Proyección sobre un eje**: rango [min, max] al proyectar todos los vértices. Clave: se compara con el rango del otro polígono.
- **Broadphase**: fase previa que descarta pares imposibles con pruebas baratas (AABB). Clave: evita correr SAT contra todo.

## 🧰 Herramientas y preparación

Usaremos **Python 3.10+** ([python.org](https://www.python.org)) con solo la librería estándar; un par de tuplas hacen de vectores. El resultado observable son valores booleanos (colisiona o no) y el solapamiento numérico. Al final indicamos cómo estas pruebas se relacionan con `Area2D` y las formas de colisión de Godot, que hacen lo mismo internamente. Ten a mano papel para dibujar los rectángulos y verificar a mano.

## 🧪 Laboratorio guiado

**Paso 1 — AABB vs AABB.** Una caja como `(x, y, ancho, alto)` con esquina superior izquierda en `(x, y)`.

```python
def aabb_vs_aabb(a, b):
    ax, ay, aw, ah = a
    bx, by, bw, bh = b
    return (ax < bx + bw and ax + aw > bx and
            ay < by + bh and ay + ah > by)

print(aabb_vs_aabb((0, 0, 4, 4), (3, 3, 4, 4)))  # True (se solapan)
print(aabb_vs_aabb((0, 0, 4, 4), (5, 0, 4, 4)))  # False (separadas en X)
```

**Paso 2 — Círculo vs círculo.** Comparamos distancias al cuadrado.

```python
def circulo_vs_circulo(c1, r1, c2, r2):
    dx = c2[0] - c1[0]
    dy = c2[1] - c1[1]
    dist2 = dx * dx + dy * dy
    suma = r1 + r2
    return dist2 <= suma * suma

print(circulo_vs_circulo((0, 0), 2, (3, 0), 2))  # True (dist 3 < 4)
print(circulo_vs_circulo((0, 0), 1, (3, 0), 1))  # False (dist 3 > 2)
```

**Paso 3 — SAT para dos rectángulos rotados.** Cada rectángulo se da como lista de 4 vértices. Probamos las normales de sus lados como ejes.

```python
import math

def normales(vertices):
    ejes = []
    n = len(vertices)
    for i in range(n):
        x1, y1 = vertices[i]
        x2, y2 = vertices[(i + 1) % n]
        # borde
        ex, ey = x2 - x1, y2 - y1
        # normal perpendicular, normalizada
        long = math.hypot(ex, ey)
        ejes.append((-ey / long, ex / long))
    return ejes

def proyectar(vertices, eje):
    puntos = [vx * eje[0] + vy * eje[1] for vx, vy in vertices]
    return min(puntos), max(puntos)

def sat(poli_a, poli_b):
    solape_min = float("inf")
    for eje in normales(poli_a) + normales(poli_b):
        min_a, max_a = proyectar(poli_a, eje)
        min_b, max_b = proyectar(poli_b, eje)
        if max_a < min_b or max_b < min_a:
            return False, 0.0  # eje separador encontrado: NO colisionan
        solape = min(max_a, max_b) - max(min_a, min_b)
        solape_min = min(solape_min, solape)
    return True, solape_min
```

**Paso 4 — Probar SAT con un rectángulo rotado 45°.**

```python
def rect(cx, cy, w, h, ang):
    hw, hh = w / 2, h / 2
    esquinas = [(-hw, -hh), (hw, -hh), (hw, hh), (-hw, hh)]
    c, s = math.cos(ang), math.sin(ang)
    return [(cx + x * c - y * s, cy + x * s + y * c) for x, y in esquinas]

a = rect(0, 0, 2, 2, 0)
b = rect(2, 0, 2, 2, math.radians(45))  # diamante que roza a "a"
colisiona, overlap = sat(a, b)
print("colisiona:", colisiona, " solapamiento:", round(overlap, 3))
```

Ejecuta y mueve `b` a `x = 3` para confirmar que deja de colisionar. El SAT detecta correctamente el contacto aunque un rectángulo esté rotado, algo que AABB no puede.

## ✍️ Ejercicios

1. Escribe `punto_en_aabb(px, py, caja)` y `punto_en_circulo(px, py, centro, r)`.
2. Añade una fase **broadphase**: antes de correr SAT, descarta pares cuyos AABB no se solapan.
3. Extiende `circulo_vs_circulo` a 3D (esfera vs esfera) agregando la coordenada Z.
4. Modifica `sat` para que también devuelva el **eje** de menor solapamiento (útil para separar).
5. Prueba SAT con un triángulo contra un cuadrado (SAT funciona con cualquier convexo).
6. Mide con `time` cuántos pares por segundo procesa SAT con y sin broadphase para 1000 formas.

## 📝 Reto verificable

Implementa una función `colision(forma_a, forma_b)` que reciba formas etiquetadas (`"aabb"`, `"circulo"`, `"poligono"`) y despache a la prueba correcta, devolviendo `(colisiona: bool, solapamiento: float)`. Incluye el caso poligono-poligono con SAT.

**Criterio de aceptación**: para dos cuadrados unitarios centrados en `(0,0)` y `(0.5,0)` devuelve `True` con solapamiento `0.5`; para los mismos separados a `(2,0)` devuelve `False`; y un círculo de radio 1 en `(0,0)` con otro en `(1.5,0)` radio 1 devuelve `True`.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| AABB detecta colisión cuando solo se tocan los bordes | Decide si el contacto exacto cuenta; usa `<` o `<=` de forma consistente |
| Círculo-círculo lento | Estás usando `sqrt`; compara `dist2 <= (r1+r2)**2` |
| SAT falla con polígonos cóncavos | SAT solo sirve para convexos; descompón el cóncavo en convexos |
| El solapamiento sale negativo o enorme | Olvidaste normalizar los ejes; hazlo antes de proyectar |
| SAT no detecta un rectángulo rotado | Faltan las normales del segundo polígono; incluye ambos conjuntos de ejes |

## ❓ Preguntas frecuentes

**¿Por qué AABB si SAT es más general?** AABB es órdenes de magnitud más barato. Se usa como broadphase para descartar la mayoría de pares antes del test exacto.

**¿SAT sirve en 3D?** Sí, pero además de las normales de las caras hay que probar los productos cruzados de aristas. La idea (buscar un eje separador) es la misma.

**¿Qué pasa con formas cóncavas?** SAT no las cubre. Se descomponen en piezas convexas o se usan mallas de colisión, como hace Godot con los `CollisionPolygon`.

**¿Esto lo hace Godot por mí?** Sí; `Area2D`, `CharacterBody2D` y las formas de colisión implementan estas pruebas. Programarlas a mano te da la intuición para depurar y para casos personalizados.

## 🔗 Referencias

1. Godot Engine — Physics introduction (áreas y formas): <https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html>
2. Wikipedia — Hyperplane separation theorem (SAT): <https://en.wikipedia.org/wiki/Hyperplane_separation_theorem>
3. MDN — 2D collision detection: <https://developer.mozilla.org/en-US/docs/Games/Techniques/2D_collision_detection>

## ➡️ Siguiente clase

[Clase 072 - Respuesta a colisiones: impulsos y restitución](../072-respuesta-a-colisiones-impulsos-y-restitucion/README.md)
