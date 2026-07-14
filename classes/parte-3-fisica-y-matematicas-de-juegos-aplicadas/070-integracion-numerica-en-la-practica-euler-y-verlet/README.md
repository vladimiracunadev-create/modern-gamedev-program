# Clase 070 — Integración numérica en la práctica (Euler y Verlet)

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Simulación de física para juegos — apuntes de aula y práctica con Godot 4 / Python*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Comprender cómo un motor "hace avanzar" el tiempo: la **integración numérica**. Compararemos tres métodos —Euler explícito, Euler semi-implícito y Verlet— sobre una misma partícula, veremos con números por qué unos "explotan" y otros conservan mejor la energía, y aprenderás por qué las telas y sistemas de partículas suelen usar Verlet con paso fijo.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar qué significa **integrar** posición y velocidad a partir de la aceleración.
2. Implementar **Euler explícito** y **semi-implícito** y notar la diferencia de estabilidad.
3. Implementar **Verlet en posición** y explicar por qué no guarda velocidad explícita.
4. Justificar el uso de un **paso de tiempo fijo** (`delta` constante) en la simulación.
5. Comparar numéricamente los tres métodos en un oscilador o una caída y elegir el adecuado.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es integrar en un juego | El motor solo conoce fuerzas; debe deducir movimiento |
| 2 | Euler explícito | El más simple, pero inestable |
| 3 | Euler semi-implícito | Casi gratis y mucho más estable |
| 4 | Verlet en posición | Estabilidad para partículas y telas |
| 5 | Estabilidad y energía | Por qué unos sistemas "explotan" |
| 6 | Paso de tiempo fijo | Reproducibilidad y estabilidad |
| 7 | Elegir el método | Cada juego pide un compromiso distinto |

## 📖 Definiciones y características

- **Integración numérica**: avanzar el estado (posición, velocidad) un pequeño paso `dt` usando la aceleración. Clave: es una aproximación, no exacta.
- **Euler explícito**: usa la velocidad **actual** para mover la posición y luego actualiza la velocidad. Clave: acumula energía y se vuelve inestable.
- **Euler semi-implícito (simpléctico)**: actualiza la velocidad **primero** y usa la nueva para mover la posición. Clave: casi el mismo código, mucho más estable.
- **Verlet en posición**: calcula la nueva posición a partir de las **dos posiciones anteriores** y la aceleración. Clave: la velocidad queda implícita en la diferencia de posiciones.
- **Paso fijo (`dt` constante)**: integrar siempre con el mismo intervalo. Clave: hace la simulación determinista y estable.
- **Estabilidad**: capacidad del método de no divergir. Clave: depende del método y del tamaño de `dt`.
- **Conservación de energía**: cuánto se aleja la simulación de la física real. Clave: Verlet y semi-implícito conservan mejor que Euler explícito.

## 🧰 Herramientas y preparación

Para este lab usaremos **Python** (solo la librería estándar) porque queremos ver los **números** de las trayectorias sin depender del render. Necesitas Python 3.10+ ([python.org](https://www.python.org)). Opcionalmente puedes graficar con `matplotlib`, pero el lab imprime tablas en consola para que sea autocontenido. Al final se indica cómo trasladar Verlet a Godot dentro de `_physics_process(delta)` con paso fijo.

## 🧪 Laboratorio guiado

Simularemos un **oscilador armónico** (un resorte): aceleración `a = -k*x`. La energía real debería mantenerse constante; veremos cuál método la respeta.

**Paso 1 — Los tres integradores.** Guarda esto como `integradores.py`.

```python
def euler_explicito(x, v, k, dt):
    a = -k * x
    x_nuevo = x + v * dt        # usa la v ANTIGUA
    v_nuevo = v + a * dt
    return x_nuevo, v_nuevo

def euler_semi_implicito(x, v, k, dt):
    a = -k * x
    v_nuevo = v + a * dt        # primero la velocidad
    x_nuevo = x + v_nuevo * dt  # usa la v NUEVA
    return x_nuevo, v_nuevo

def verlet(x, x_prev, k, dt):
    a = -k * x
    x_nuevo = 2 * x - x_prev + a * dt * dt
    return x_nuevo, x  # nueva posicion, y la actual pasa a ser "prev"
```

**Paso 2 — Ejecutar y medir la energía.** La energía del resorte es `E = 0.5*v^2 + 0.5*k*x^2`.

```python
def energia(x, v, k):
    return 0.5 * v * v + 0.5 * k * x * x

k, dt, pasos = 1.0, 0.1, 200

# Estado inicial comun.
xe, ve = 1.0, 0.0   # Euler explicito
xs, vs = 1.0, 0.0   # semi-implicito
xv, xv_prev = 1.0, 1.0  # Verlet: en reposo, prev = actual

print(f"{'paso':>4} {'E_expl':>10} {'E_semi':>10} {'E_verlet':>10}")
for i in range(pasos):
    xe, ve = euler_explicito(xe, ve, k, dt)
    xs, vs = euler_semi_implicito(xs, vs, k, dt)
    xv_new, xv_prev = verlet(xv, xv_prev, k, dt)
    xv = xv_new
    if i % 40 == 0:
        v_verlet = (xv - xv_prev) / dt  # velocidad implicita
        print(f"{i:>4} {energia(xe, ve, k):>10.4f} "
              f"{energia(xs, vs, k):>10.4f} {energia(xv, v_verlet, k):>10.4f}")
```

**Paso 3 — Observar.** Al ejecutar `python integradores.py` verás algo como:

```text
paso     E_expl     E_semi   E_verlet
   0     1.0000     0.9950     0.9950
  40     1.4859     1.0000     0.9975
  80     2.2076     1.0000     0.9975
 160     4.8586     1.0000     0.9975
```

La energía de **Euler explícito crece sin parar** (el resorte se "carga" solo hasta explotar). El **semi-implícito** oscila alrededor de un valor estable. **Verlet** se mantiene casi constante. Esa es la razón práctica por la que Euler explícito casi nunca se usa en juegos.

**Paso 4 — Verlet en Godot.** El mismo esquema dentro de un `CharacterBody2D` con paso fijo:

```gdscript
var pos_prev: Vector2
var pos_actual: Vector2

func _physics_process(delta: float) -> void:
	var a := Vector2(0, 980)  # gravedad
	var pos_nueva := 2.0 * pos_actual - pos_prev + a * delta * delta
	pos_prev = pos_actual
	pos_actual = pos_nueva
	global_position = pos_actual
```

## ✍️ Ejercicios

1. Cambia `dt` a `0.5` y observa cómo Euler explícito explota mucho antes.
2. Simula una **caída con gravedad** (`a = -9.8`, sin resorte) con los tres métodos y compara posiciones tras 1 segundo.
3. Añade una velocidad inicial al Verlet inicializando `x_prev = x - v0*dt`.
4. Mide cuántos pasos tarda Euler explícito en duplicar su energía para `dt = 0.1` y `dt = 0.05`.
5. Grafica las tres trayectorias con `matplotlib` y comenta las diferencias.
6. Implementa una restricción de distancia entre dos puntos Verlet (base de una tela) y verifica que la barra mantiene su longitud.

## 📝 Reto verificable

Construye una simulación Verlet de una **cadena de 5 puntos** unidos por restricciones de distancia, con gravedad y un extremo fijado. En cada paso: integra por Verlet y luego aplica varias iteraciones de corrección de restricciones para mantener las distancias.

**Criterio de aceptación**: la cadena cuelga y se estabiliza formando una catenaria; tras 300 pasos, la distancia entre puntos consecutivos se mantiene dentro de ±2% de la longitud objetivo, y el punto fijado no se mueve.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La simulación "explota" a valores enormes | Euler explícito con `dt` grande; usa semi-implícito o reduce `dt` |
| Verlet no arranca con velocidad | Inicializaste `x_prev = x`; para velocidad `v0`, usa `x_prev = x - v0*dt` |
| El movimiento cambia con los FPS | Estás integrando en `_process`; usa `_physics_process` con paso fijo |
| La energía decae hasta detenerse | Introdujiste amortiguación no deseada en la corrección de restricciones |
| Verlet "tiembla" | Demasiadas o muy pocas iteraciones de restricción; ajusta el número |

## ❓ Preguntas frecuentes

**¿Por qué no usar siempre el método más preciso?** Los juegos priorizan estabilidad y velocidad sobre exactitud física. Semi-implícito y Verlet son baratos y "se sienten bien", que es lo que importa.

**¿Verlet guarda velocidad?** No de forma explícita: la velocidad está implícita en `(x - x_prev)/dt`. Por eso es cómodo aplicar restricciones moviendo posiciones directamente.

**¿Por qué paso de tiempo fijo?** Con `dt` variable la simulación deja de ser reproducible y puede volverse inestable. Godot llama `_physics_process` con `delta` fijo justamente por esto.

**¿Cuándo elijo cada uno?** Semi-implícito para cuerpos rígidos generales; Verlet para partículas, cuerdas y telas donde importan las restricciones de posición.

## 🔗 Referencias

1. Godot Engine — `_physics_process` y paso fijo: <https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html>
2. Wikipedia — Verlet integration: <https://en.wikipedia.org/wiki/Verlet_integration>
3. Wikipedia — Semi-implicit Euler method: <https://en.wikipedia.org/wiki/Semi-implicit_Euler_method>

## ➡️ Siguiente clase

[Clase 071 - Detección de colisiones: AABB, esferas y SAT](../071-deteccion-de-colisiones-aabb-esferas-y-sat/README.md)
