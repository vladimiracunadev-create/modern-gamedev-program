# Clase 072 — Respuesta a colisiones: impulsos y restitución

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Dinámica de impactos para juegos — apuntes de aula y práctica con Python*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Ya sabemos **detectar** colisiones; ahora toca **resolverlas**. Aprenderás a calcular la normal de colisión, corregir la penetración y aplicar un **impulso** que cambie las velocidades según el **coeficiente de restitución** (rebote) y la **masa** de cada cuerpo. Todo respetando la conservación del momento. Lo implementaremos en Python para el choque de dos círculos.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Calcular la **normal de colisión** y la **profundidad de penetración** entre dos círculos.
2. Aplicar **resolución posicional** para separar cuerpos que se solapan.
3. Derivar y aplicar el **impulso** que resuelve el choque en la dirección normal.
4. Interpretar el **coeficiente de restitución** entre 0 (pegajoso) y 1 (elástico).
5. Verificar la **conservación del momento** antes y después del impacto.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Normal de colisión | Dirección en la que se resuelve el choque |
| 2 | Penetración y separación | Evita que los cuerpos queden encajados |
| 3 | Velocidad relativa | Solo importa la componente normal |
| 4 | Impulso | Cambio instantáneo de velocidad |
| 5 | Restitución | Controla cuánto rebota |
| 6 | Masa y masa inversa | Reparte el efecto entre cuerpos |
| 7 | Conservación del momento | Verifica que la física es correcta |

## 📖 Definiciones y características

- **Normal de colisión**: vector unitario que une los centros (círculos) o perpendicular a la superficie. Clave: el impulso actúa a lo largo de ella.
- **Penetración**: cuánto se solapan las formas. Clave: hay que corregirla o los cuerpos se hunden.
- **Resolución posicional**: mover cada cuerpo a lo largo de la normal, en proporción a su masa inversa. Clave: separa sin añadir energía.
- **Velocidad relativa normal**: proyección de `(v_b - v_a)` sobre la normal. Clave: si es positiva (se alejan), no hay que aplicar impulso.
- **Coeficiente de restitución (e)**: fracción de velocidad conservada tras el rebote, de 0 a 1. Clave: 0 = choque plástico, 1 = elástico perfecto.
- **Impulso (j)**: magnitud del cambio de momento aplicado en la normal. Clave: se reparte según las masas inversas.
- **Masa inversa (1/m)**: forma cómoda de manejar objetos "infinitamente pesados" (masa inversa 0 = inmóvil). Clave: simplifica las fórmulas.
- **Conservación del momento**: la suma `m*v` total no cambia en el impacto. Clave: sirve como test de corrección.

## 🧰 Herramientas y preparación

Usaremos **Python 3.10+** ([python.org](https://www.python.org)) con la librería estándar; representamos vectores como tuplas y definimos pequeñas funciones auxiliares. Lo observable son las velocidades antes/después y el momento total, que imprimiremos. Al final se muestra cómo `RigidBody2D` y `PhysicsMaterial.bounce` de Godot aplican exactamente esta idea sin que la programes.

## 🧪 Laboratorio guiado

Resolveremos el choque de dos círculos con masa y restitución.

**Paso 1 — Utilidades vectoriales y estado.**

```python
import math

def sub(a, b): return (a[0] - b[0], a[1] - b[1])
def add(a, b): return (a[0] + b[0], a[1] + b[1])
def escala(a, s): return (a[0] * s, a[1] * s)
def dot(a, b): return a[0] * b[0] + a[1] * b[1]
def longitud(a): return math.hypot(a[0], a[1])

class Circulo:
    def __init__(self, pos, vel, radio, masa):
        self.pos = pos
        self.vel = vel
        self.radio = radio
        self.inv_masa = 0.0 if masa == 0 else 1.0 / masa
```

**Paso 2 — Resolver el choque con impulso y restitución.**

```python
def resolver(a, b, e):
    delta = sub(b.pos, a.pos)
    dist = longitud(delta)
    solape = a.radio + b.radio - dist
    if solape <= 0 or dist == 0:
        return  # no colisionan
    normal = escala(delta, 1.0 / dist)  # de a hacia b

    # 1) Resolucion posicional: separar segun masa inversa.
    inv_total = a.inv_masa + b.inv_masa
    if inv_total == 0:
        return
    correccion = escala(normal, solape / inv_total)
    a.pos = sub(a.pos, escala(correccion, a.inv_masa))
    b.pos = add(b.pos, escala(correccion, b.inv_masa))

    # 2) Velocidad relativa a lo largo de la normal.
    v_rel = sub(b.vel, a.vel)
    vn = dot(v_rel, normal)
    if vn > 0:
        return  # ya se estan separando

    # 3) Impulso escalar.
    j = -(1 + e) * vn / inv_total
    impulso = escala(normal, j)
    a.vel = sub(a.vel, escala(impulso, a.inv_masa))
    b.vel = add(b.vel, escala(impulso, b.inv_masa))
```

**Paso 3 — Probar restitución 0 vs 1.**

```python
def momento_total(a, b):
    ma = 0 if a.inv_masa == 0 else 1 / a.inv_masa
    mb = 0 if b.inv_masa == 0 else 1 / b.inv_masa
    return add(escala(a.vel, ma), escala(b.vel, mb))

for e in (1.0, 0.0):
    a = Circulo((0, 0), (2, 0), 1, 1)   # se mueve a la derecha
    b = Circulo((1.5, 0), (0, 0), 1, 1) # en reposo, solapado
    print("momento antes:", momento_total(a, b))
    resolver(a, b, e)
    print(f"e={e}  vel_a={a.vel}  vel_b={b.vel}")
    print("momento despues:", momento_total(a, b), "\n")
```

Al ejecutar verás que con **e = 1** (elástico, masas iguales) las velocidades se intercambian: `a` queda casi quieto y `b` sale a ~2. Con **e = 0** (plástico) ambos terminan con la misma velocidad (~1), pegados. En ambos casos, **el momento total antes y después coincide**: la física es correcta.

## ✍️ Ejercicios

1. Cambia las masas a 1 y 3 y observa cómo el cuerpo pesado apenas cambia de velocidad.
2. Fija `b` como pared inmóvil (masa 0) y comprueba que solo rebota `a`.
3. Prueba `e = 0.5` y verifica que el rebote es intermedio.
4. Añade un bucle de simulación con gravedad y varios pasos para ver los círculos rebotar y asentarse.
5. Calcula la energía cinética antes y después con distintos `e` y comprueba que solo `e = 1` la conserva.
6. Extiende `resolver` a esferas 3D añadiendo la coordenada Z a las utilidades.

## 📝 Reto verificable

Implementa una mini-simulación de **N círculos** en una caja: en cada paso, integra el movimiento, detecta pares en colisión y resuélvelos con `resolver`, y rebota contra las paredes. Expón la restitución como parámetro global.

**Criterio de aceptación**: con `e = 1` y sin gravedad, la energía cinética total del sistema se mantiene dentro de ±3% tras 500 pasos; con `e = 0`, los círculos tienden a agruparse y moverse juntos sin atravesarse.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Los cuerpos se quedan pegados y vibran | Falta la resolución posicional; sepáralos según masa inversa |
| Se aplica impulso aunque se alejan | No comprobaste `vn > 0`; sáltate el impulso en ese caso |
| Un cuerpo "inmóvil" se mueve | Su masa inversa no es 0; asígnala explícitamente |
| La energía crece sin control | `e > 1`; restríngelo al rango [0, 1] |
| División por cero | `dist == 0` (centros coincidentes) o `inv_total == 0`; protégelos |

## ❓ Preguntas frecuentes

**¿Por qué masa inversa y no masa?** Permite representar objetos inmóviles con `1/m = 0` y simplifica las fórmulas del impulso, que siempre dividen por la masa.

**¿Qué hace exactamente la restitución?** Escala cuánta velocidad relativa se conserva tras el impacto. `e = 1` devuelve toda (elástico), `e = 0` no devuelve nada (plástico).

**¿Por qué separar posiciones aparte del impulso?** El impulso corrige velocidades, no el solapamiento ya existente. Sin la corrección posicional, los cuerpos se hunden entre sí.

**¿Godot hace esto solo?** Sí. `RigidBody2D`/`RigidBody3D` con un `PhysicsMaterial` (`bounce` = restitución) aplican impulsos equivalentes. Programarlo te da control para lógica de juego personalizada.

## 🔗 Referencias

1. Godot Engine — RigidBody2D: <https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html>
2. Godot Engine — PhysicsMaterial (bounce): <https://docs.godotengine.org/en/stable/classes/class_physicsmaterial.html>
3. Wikipedia — Coefficient of restitution: <https://en.wikipedia.org/wiki/Coefficient_of_restitution>

## ➡️ Siguiente clase

[Clase 073 - Fricción, arrastre y amortiguación](../073-friccion-arrastre-y-amortiguacion/README.md)
