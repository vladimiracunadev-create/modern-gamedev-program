# Clase 075 — Motores de física: broadphase y narrowphase

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Ian Millington, Game Physics Engine Development · Christer Ericson, Real-Time Collision Detection*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Entender cómo un motor de física decide qué cuerpos podrían chocar sin comparar todos contra todos. Vas a distinguir las tres etapas —**broadphase** (descarte grueso), **narrowphase** (prueba exacta) y **solver** (resolución)— y a implementar en Python una grilla espacial que reduce drásticamente el número de pares a testear. Medirás cuántas comparaciones te ahorras frente al método ingenuo O(n²).

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar por qué comparar cada par de cuerpos escala como O(n²) y por qué eso no es viable.
2. Describir tres técnicas de broadphase: grilla espacial, *sweep-and-prune* y BVH.
3. Implementar una grilla espacial que agrupe cuerpos por celda y genere solo pares candidatos.
4. Medir empíricamente los pares evitados comparando la grilla con el método ingenuo.
5. Situar el *sub-stepping*, las islas y las iteraciones del solver dentro del ciclo de simulación.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | El problema O(n²) | 1000 cuerpos = ~500.000 pares; inviable por fotograma |
| 2 | Broadphase | Descartar rápido la mayoría de pares imposibles |
| 3 | Grilla espacial uniforme | Simple y muy eficaz cuando los objetos tienen tamaño similar |
| 4 | Sweep-and-prune | Ordena por eje y solapa intervalos; bueno con coherencia temporal |
| 5 | BVH / árboles AABB | Escala bien con objetos de tamaños dispares |
| 6 | Narrowphase | Prueba exacta (SAT, GJK) solo sobre candidatos |
| 7 | Solver e islas | Agrupa contactos conectados y resuelve por iteraciones |
| 8 | Sub-stepping | Pasos de física más pequeños para estabilidad y objetos rápidos |

## 📖 Definiciones y características

- **Broadphase**: fase que produce una lista de *pares candidatos* con AABB baratos; descarta lo que no puede colisionar.
- **Narrowphase**: prueba geométrica exacta sobre cada par candidato; calcula puntos, normal y penetración del contacto.
- **AABB** (*Axis-Aligned Bounding Box*): caja alineada a ejes; solapar dos AABB es una comparación de intervalos, trivial.
- **Grilla espacial**: el mundo se divide en celdas; cada cuerpo se inscribe en las celdas que toca y solo se comparan cuerpos de la misma celda.
- **Sweep-and-prune**: proyecta las AABB sobre un eje, ordena los extremos y detecta solapamientos recorriendo la lista.
- **BVH** (*Bounding Volume Hierarchy*): árbol de cajas englobantes; la consulta desciende y poda ramas que no solapan.
- **Solver / islas**: los contactos conectados forman una "isla" que se resuelve junta con varias iteraciones de restricción.
- **Sub-stepping**: dividir el `delta` en varios pasos menores para simular objetos rápidos sin *tunneling*.

## 🧰 Herramientas y preparación

Este laboratorio es de **matemática pura en Python** (no requiere Godot): así aíslas el algoritmo del motor y ves los números. Necesitas Python 3.10+ y, opcionalmente, `matplotlib` para graficar. La idea trasladada a Godot es que su motor (Godot Physics / Jolt) hace esto por ti; conocerlo te ayuda a diagnosticar caídas de rendimiento cuando hay demasiados cuerpos. Lee el capítulo de broadphase de Ericson y el resumen de Godot sobre rendimiento físico. Consulta: <https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html>.

## 🧪 Laboratorio guiado

> **Lenguaje: Python** (matemática pura, sin dependencias externas).

### Paso 1 — Cuerpos y método ingenuo O(n²)

```python
import random

class Cuerpo:
    def __init__(self, x, y, r):
        self.x, self.y, self.r = x, y, r  # centro y radio

def solapan(a, b):
    dx, dy = a.x - b.x, a.y - b.y
    return (dx * dx + dy * dy) <= (a.r + b.r) ** 2

def pares_ingenuo(cuerpos):
    pares = []
    for i in range(len(cuerpos)):
        for j in range(i + 1, len(cuerpos)):
            pares.append((i, j))  # TODOS los pares, sin filtrar
    return pares
```

### Paso 2 — Broadphase con grilla espacial

Cada cuerpo se asigna a la celda de su centro (asumimos radios pequeños frente al tamaño de celda). Solo comparamos cuerpos que comparten celda o celdas vecinas.

```python
from collections import defaultdict

def celda_de(cuerpo, tam_celda):
    return (int(cuerpo.x // tam_celda), int(cuerpo.y // tam_celda))

def pares_grilla(cuerpos, tam_celda):
    grilla = defaultdict(list)
    for idx, c in enumerate(cuerpos):
        grilla[celda_de(c, tam_celda)].append(idx)

    candidatos = set()
    for (cx, cy), indices in grilla.items():
        # Reviso mi celda y las 8 vecinas (rango 3x3).
        vecinas = [(cx + dx, cy + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)]
        cercanos = [i for v in vecinas for i in grilla.get(v, [])]
        for a in indices:
            for b in cercanos:
                if a < b:  # evita duplicados y auto-pares
                    candidatos.add((a, b))
    return list(candidatos)
```

### Paso 3 — Medir los pares evitados

```python
random.seed(42)
MUNDO, N, RADIO = 1000, 2000, 5
cuerpos = [Cuerpo(random.uniform(0, MUNDO),
                  random.uniform(0, MUNDO), RADIO) for _ in range(N)]

ingenuo = pares_ingenuo(cuerpos)          # O(n^2)
grilla  = pares_grilla(cuerpos, RADIO * 4) # broadphase

# Narrowphase: prueba exacta solo sobre candidatos.
colisiones = sum(1 for i, j in grilla if solapan(cuerpos[i], cuerpos[j]))

print(f"Pares ingenuo:   {len(ingenuo):>10,}")
print(f"Pares grilla:    {len(grilla):>10,}")
print(f"Pares evitados:  {len(ingenuo) - len(grilla):>10,} "
      f"({100 * (1 - len(grilla) / len(ingenuo)):.1f}% menos)")
print(f"Colisiones reales: {colisiones}")
```

**Observable**: con 2000 cuerpos el método ingenuo genera ~2.000.000 de pares y la grilla unos pocos miles, evitando bien por encima del 99%. Sube `N` y verás cómo la brecha crece: ahí está la razón de existir del broadphase.

## ✍️ Ejercicios

1. Varía `tam_celda` (2×, 8×, 16× el radio) y grafica pares candidatos vs. tamaño de celda; encuentra el óptimo.
2. Distribuye los cuerpos en cúmulos en vez de uniformemente y observa cómo empeora la grilla uniforme.
3. Inserta cada cuerpo en **todas** las celdas que su AABB toca (no solo la del centro) para soportar radios grandes.
4. Implementa un *sweep-and-prune* 1D sobre el eje X y compara sus pares con los de la grilla.
5. Cronometra ambos métodos con `time.perf_counter()` para 500, 5000 y 50000 cuerpos.
6. Añade una tercera dimensión (Z) y generaliza la grilla a celdas cúbicas.

## 📝 Reto verificable

Extiende el laboratorio para que, además de contar pares, ejecute la narrowphase real y devuelva la lista de colisiones. Compara que la grilla y el método ingenuo detectan **exactamente el mismo conjunto de colisiones**, aunque la grilla pruebe muchísimos menos pares.

**Criterio de aceptación**: para la misma semilla, el conjunto de colisiones de `pares_grilla` es idéntico al de `pares_ingenuo` (ninguna colisión perdida) y el número de pares candidatos de la grilla es al menos 95% menor con N≥2000.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La grilla pierde colisiones | Cuerpos grandes ocupan varias celdas y solo los inscribes en una. Inscríbelos en todas las que tocan. |
| Aparecen pares duplicados | No filtras `a < b`. Usa un `set` y compara índices ordenados. |
| Celdas demasiado grandes no ayudan | Todo cae en pocas celdas → casi O(n²). Ajusta el tamaño al de los objetos. |
| Celdas demasiado pequeñas cuestan memoria | Diccionario enorme y muchos vecinos vacíos. Busca el punto medio. |
| Cúmulos degradan la grilla | La grilla uniforme sufre con distribuciones no homogéneas; considera BVH. |

## ❓ Preguntas frecuentes

**¿La broadphase decide si hay colisión?** No: solo propone pares *candidatos*. La narrowphase confirma con geometría exacta.

**¿Qué usa Godot?** Godot Physics usa una broadphase basada en árbol/hash; el módulo Jolt usa su propia jerarquía. En ambos, reducir el número de cuerpos activos ayuda al rendimiento.

**¿Qué es una "isla" del solver?** Un grupo de cuerpos conectados por contactos; se resuelve en conjunto para que los impulsos se propaguen entre ellos.

**¿Cuándo necesito sub-stepping?** Con objetos muy rápidos o pilas altas inestables; más sub-pasos = más estabilidad a costa de CPU.

## 🔗 Referencias

- Christer Ericson, *Real-Time Collision Detection*, cap. 7 (broadphase, grids, sweep-and-prune).
- Ian Millington, *Game Physics Engine Development*, parte de detección de colisiones.
- Godot Docs — Physics introduction: <https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html>
- Erin Catto, *Box2D* (documentación técnica sobre solvers e islas): <https://box2d.org/documentation/>

## ⬅️ Clase anterior

[Clase 074 - Raycasts y shapecasts: usos avanzados](../074-raycasts-y-shapecasts-usos-avanzados/README.md)

## ➡️ Siguiente clase

[Clase 076 - Juntas y restricciones (joints): bisagras y resortes](../076-juntas-y-restricciones-joints-bisagras-y-resortes/README.md)
