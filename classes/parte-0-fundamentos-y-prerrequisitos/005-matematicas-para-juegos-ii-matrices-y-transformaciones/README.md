# Clase 005 — Matemáticas para juegos II: matrices y transformaciones

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Eric Lengyel, Mathematics for 3D Game Programming and Computer Graphics*
> ⏱️ Duración estimada: **110 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Comprender las matrices como transformaciones geométricas: mover (trasladar), girar (rotar) y cambiar de tamaño (escalar) objetos. Verás cómo una matriz representa una transformación completa, cómo se componen varias en una sola y por qué el orden de composición importa.

Esto importa porque cada objeto en un juego 2D o 3D vive gracias a su matriz de transformación (model matrix). Cámara, sprites, huesos de animación: todo son matrices multiplicándose. Entenderlas es entender cómo se coloca cualquier cosa en pantalla.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. **Construir** matrices 3x3 de traslación, rotación y escala en 2D.
2. **Explicar** por qué se usan coordenadas homogéneas y matrices 3x3 en 2D (4x4 en 3D).
3. **Componer** transformaciones multiplicando matrices en el orden correcto.
4. **Transformar** un conjunto de puntos y comparar coordenadas antes/después.
5. **Demostrar** con números que rotar-luego-trasladar ≠ trasladar-luego-rotar.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Matriz como transformación | Es cómo se coloca todo objeto en el mundo |
| 2 | Matriz identidad | Punto de partida neutro de toda transformación |
| 3 | Traslación | Mueve el objeto sin rotarlo |
| 4 | Rotación | Gira el objeto alrededor del origen |
| 5 | Escala | Cambia el tamaño |
| 6 | Coordenadas homogéneas | Permiten meter la traslación en la matriz |
| 7 | Composición y orden | Combina transformaciones; el orden cambia el resultado |
| 8 | Model matrix | Transformación total de un objeto |

## 📖 Definiciones y características

- **Matriz de transformación**: arreglo que transforma coordenadas al multiplicar un punto. Clave: una matriz = una transformación.
- **Matriz identidad**: no cambia nada (diagonal de unos). Clave: neutro de la multiplicación.
- **Traslación**: desplazamiento por `(tx, ty)`. Clave: requiere coordenadas homogéneas para expresarse como matriz.
- **Rotación**: giro por un ángulo θ alrededor del origen. Clave: usa senos y cosenos.
- **Escala**: multiplica tamaño por `(sx, sy)`. Clave: valores <1 encogen, >1 agrandan.
- **Coordenadas homogéneas**: añadir un 1 al punto `(x, y, 1)`. Clave: permiten combinar traslación y rotación en una sola matriz.
- **Composición**: multiplicar matrices para encadenar transformaciones. Clave: `M = A·B` aplica B primero, luego A.
- **Model matrix**: matriz que sitúa un objeto en el mundo. Clave: producto de escala, rotación y traslación.

## 🧰 Herramientas y preparación

Necesitas Python 3.10 o superior <https://www.python.org/downloads>. Usaremos NumPy para multiplicar matrices con comodidad; instálalo con `pip install numpy` <https://numpy.org>. Si prefieres no instalar nada, el laboratorio incluye también una versión con listas puras. La referencia teórica es *Mathematics for 3D Game Programming and Computer Graphics* de Eric Lengyel <https://foundationsofgameenginedev.com>.

## 🧪 Laboratorio guiado

Construirás matrices 3x3 en 2D, transformarás un triángulo y demostrarás numéricamente que el orden de composición importa.

**Paso 1 — Instala y comprueba NumPy.** En la terminal:

```bash
pip install numpy
python -c "import numpy; print(numpy.__version__)"
```

**Paso 2 — Representa puntos en coordenadas homogéneas.** Un punto `(x, y)` se escribe como columna `(x, y, 1)`. El `1` es lo que permite que la traslación funcione como matriz. Archivo `transformaciones.py`:

```python
import numpy as np

def punto(x, y):
    return np.array([x, y, 1.0])     # coordenada homogénea
```

**Paso 3 — Construye las matrices básicas 3x3.**

```python
import numpy as np

def identidad():
    return np.identity(3)

def traslacion(tx, ty):
    return np.array([
        [1, 0, tx],
        [0, 1, ty],
        [0, 0, 1 ],
    ], dtype=float)

def rotacion(grados):
    r = np.radians(grados)
    c, s = np.cos(r), np.sin(r)
    return np.array([
        [c, -s, 0],
        [s,  c, 0],
        [0,  0, 1],
    ], dtype=float)

def escala(sx, sy):
    return np.array([
        [sx, 0,  0],
        [0,  sy, 0],
        [0,  0,  1],
    ], dtype=float)
```

**Paso 4 — Transforma un punto.** Multiplicar matriz por punto (columna) aplica la transformación:

```python
p = np.array([1.0, 0.0, 1.0])      # el punto (1, 0)
T = traslacion(3, 2)
print("trasladado:", (T @ p)[:2])  # [4. 2.]  -> (1+3, 0+2)

R = rotacion(90)
print("rotado 90:", np.round((R @ p)[:2], 3))  # [0. 1.] -> (1,0) gira a (0,1)

S = escala(2, 2)
print("escalado:", (S @ p)[:2])    # [2. 0.]
```

El operador `@` es multiplicación de matrices en NumPy. Observa que rotar `(1,0)` 90° da `(0,1)`, justo lo esperado.

**Paso 5 — Transforma un triángulo completo.** Definimos tres vértices y les aplicamos una misma matriz:

```python
triangulo = [punto(0, 0), punto(2, 0), punto(1, 2)]

def aplicar(M, puntos):
    return [ (M @ p)[:2] for p in puntos ]

M = traslacion(5, 0) @ rotacion(90)   # rota y LUEGO traslada
print("Original:")
for p in triangulo:
    print("  ", p[:2])
print("Transformado (R luego T):")
for q in aplicar(M, triangulo):
    print("  ", np.round(q, 3))
```

Salida aproximada:

```text
Original:
   [0. 0.]
   [2. 0.]
   [1. 2.]
Transformado (R luego T):
   [5. 0.]
   [5. 2.]
   [3. 1.]
```

**Paso 6 — Demuestra que el orden importa.** Compara "rotar luego trasladar" contra "trasladar luego rotar" sobre el mismo punto `(1, 0)`:

```python
p = punto(1, 0)

RT = rotacion(90) @ traslacion(3, 0)   # aplica traslacion PRIMERO, luego rotacion
TR = traslacion(3, 0) @ rotacion(90)   # aplica rotacion PRIMERO, luego traslacion

print("R*T aplicado:", np.round((RT @ p)[:2], 3))
print("T*R aplicado:", np.round((TR @ p)[:2], 3))
```

Salida:

```text
R*T aplicado: [0. 4.]
T*R aplicado: [0. 1.]
```

Los resultados son distintos: `(0, 4)` frente a `(0, 1)`. Esto prueba que la multiplicación de matrices **no es conmutativa**: el orden de las transformaciones cambia el resultado. Recuerda la regla: en `A @ B`, se aplica **B primero** y luego A (se lee de derecha a izquierda).

**Paso 7 — Versión sin NumPy (opcional).** Si no instalaste NumPy, esta función multiplica matriz 3x3 por vector con listas:

```python
def mat_por_vec(M, v):
    return [ sum(M[i][k] * v[k] for k in range(3)) for i in range(3) ]

T = [[1,0,3],[0,1,2],[0,0,1]]
print(mat_por_vec(T, [1, 0, 1]))   # [4, 2, 1]
```

## ✍️ Ejercicios

1. Construye la matriz que escala un objeto al doble y luego lo traslada a `(10, 5)`. Aplica al punto `(1, 1)` y verifica a mano.
2. Rota el triángulo del laboratorio 45° alrededor del origen e imprime los tres vértices redondeados.
3. Demuestra numéricamente que `A @ identidad() == A` para una matriz de rotación cualquiera.
4. Escribe una función `model_matrix(tx, ty, grados, sx, sy)` que componga escala, rotación y traslación en ese orden y devuelva una sola matriz 3x3.
5. Rota un objeto 90° cuatro veces seguidas y comprueba que vuelve a su posición original (matriz resultante ≈ identidad).
6. Explica en un comentario por qué necesitamos matrices 3x3 en 2D y no bastan las 2x2.

## 📝 Reto verificable

Entrega `transformaciones.py` con las funciones `identidad`, `traslacion`, `rotacion`, `escala` y `model_matrix`, más una demo que: (a) transforme un triángulo y muestre coordenadas antes/después, y (b) imprima el resultado de "rotar-luego-trasladar" y "trasladar-luego-rotar" sobre un mismo punto, evidenciando que difieren.

**Criterio de aceptación**: al ejecutar el script, las matrices producen resultados correctos (verificables a mano: trasladar `(1,0)` por `(3,2)` da `(4,2)`; rotar `(1,0)` 90° da `(0,1)`), y los dos órdenes de composición imprimen coordenadas distintas, confirmando la no conmutatividad.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La traslación "no hace nada" | Usaste matriz 2x2 o punto sin el `1` homogéneo. Usa 3x3 y `(x, y, 1)`. |
| El objeto gira alrededor del punto equivocado | La rotación es siempre respecto al origen. Traslada al origen, rota y devuelve. |
| Resultado inesperado al componer | Confundes el orden. En `A @ B` se aplica B primero. Lee de derecha a izquierda. |
| Ángulos raros | Pasaste grados donde se esperaban radianes. Convierte con `np.radians`. |
| `ValueError: shapes not aligned` | Dimensiones incompatibles. Asegura matrices 3x3 y vectores de longitud 3. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué 3x3 en 2D y 4x4 en 3D?** Porque la traslación no es una operación lineal pura; añadiendo una coordenada extra (homogénea) se puede expresar como multiplicación de matriz. Por eso 2D usa 3x3 y 3D usa 4x4.

**❓ ¿En qué orden compongo escala, rotación y traslación?** Lo habitual es `T @ R @ S`: primero escala, luego rota, luego traslada. Así el objeto se escala y gira en el origen antes de moverse.

**❓ ¿Por qué la multiplicación se lee de derecha a izquierda?** Porque el punto está a la derecha: `(A @ B) @ p = A @ (B @ p)`, así que B toca al punto primero.

**❓ ¿Los motores usan esto internamente?** Sí. La `model matrix` de Godot, Unity o Unreal es exactamente esta composición; la GPU multiplica cada vértice por ella.

## 🔗 Referencias

- Eric Lengyel, *Mathematics for 3D Game Programming and Computer Graphics* — <https://foundationsofgameenginedev.com>
- Documentación de NumPy — <https://numpy.org/doc/stable/>
- 3Blue1Brown, "Essence of Linear Algebra" (transformaciones lineales) — <https://www.3blue1brown.com/topics/linear-algebra>

## ⬅️ Clase anterior

[Clase 004 - Matemáticas para juegos I: vectores y álgebra lineal](../004-matematicas-para-juegos-i-vectores-y-algebra-lineal/README.md)

## ➡️ Siguiente clase

[Clase 006 - Matemáticas para juegos III: trigonometría, ángulos y rotaciones](../006-matematicas-para-juegos-iii-trigonometria-angulos-y-rotaciones/README.md)
