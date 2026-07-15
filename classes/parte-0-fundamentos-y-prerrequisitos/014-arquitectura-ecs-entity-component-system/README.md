# Clase 014 — Arquitectura ECS (Entity-Component-System)

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Jason Gregory, Game Engine Architecture; docs de Bevy/EnTT*
> ⏱️ Duración estimada: **110 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Cuando un juego tiene miles de entidades, el modelo clásico de objetos con herencia se vuelve rígido y lento. La arquitectura **ECS (Entity-Component-System)** propone otra idea: las entidades son solo identificadores, los datos viven en **componentes**, y la lógica vive en **sistemas** que recorren entidades. Es un enfoque **orientado a datos** que favorece el rendimiento y la escalabilidad.

En esta clase entenderás qué es ECS y por qué lo usan Unity DOTS, Bevy o flecs; verás la diferencia con la POO y con el modelo de nodos/GameObject de Godot/Unity. Implementarás un **mini-ECS** en Python: componentes guardados en diccionarios por entidad y un `MovementSystem` que actualiza la posición de las entidades que tienen `Position` y `Velocity`.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Definir Entity, Component y System y el rol de cada uno.
2. Explicar por qué ECS es un enfoque orientado a datos y su ventaja de rendimiento.
3. Contrastar ECS con la herencia de POO y con el modelo de nodos/GameObject.
4. Implementar un mini-ECS con almacenamiento de componentes por entidad.
5. Escribir un sistema que itere solo las entidades con los componentes requeridos.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Entity = id | Una entidad es solo un número, no un objeto pesado. |
| 2 | Component = datos | Separar datos puros de la lógica. |
| 3 | System = lógica | La lógica recorre conjuntos de componentes. |
| 4 | Orientación a datos | Mejor uso de caché y rendimiento a escala. |
| 5 | ECS vs POO/herencia | Composición flexible sin jerarquías rígidas. |
| 6 | ECS vs nodos/GameObject | Distinto modelo mental de composición. |
| 7 | Ejemplos reales | Unity DOTS, Bevy, flecs, EnTT. |

## 📖 Definiciones y características

- **Entity**: identificador único (un id). Clave: no contiene datos ni lógica por sí mismo.
- **Component**: bloque de datos puros (posición, velocidad). Clave: sin comportamiento.
- **System**: función/clase que procesa entidades con ciertos componentes. Clave: aquí vive la lógica.
- **Orientación a datos (DOD)**: diseñar según cómo se accede a los datos. Clave: aprovecha la caché de CPU.
- **Composición**: armar entidades combinando componentes. Clave: más flexible que la herencia.
- **Query/consulta**: seleccionar entidades que tienen ciertos componentes. Clave: el sistema itera solo lo relevante.
- **Archetype**: agrupación de entidades con el mismo conjunto de componentes. Clave: almacenamiento contiguo (en ECS avanzados).
- **DOTS/Bevy/flecs**: implementaciones ECS reales. Clave: prueban el enfoque a escala de producción.

## 🧰 Herramientas y preparación

Usaremos Python 3.10+ (<https://www.python.org/downloads/>), que ya trae todo lo necesario; no requiere librerías externas para el laboratorio. Editor recomendado: Visual Studio Code (<https://code.visualstudio.com/>). Como referencia conceptual usamos *Game Engine Architecture* de Jason Gregory (<https://www.gameenginebook.com/>) y la documentación de motores ECS reales: Bevy (<https://bevyengine.org/learn/>), flecs (<https://www.flecs.dev/flecs/>) y EnTT (<https://github.com/skypjack/entt/wiki>). Para ver ECS en producción, revisa Unity DOTS/Entities: <https://docs.unity3d.com/Packages/com.unity.entities@latest>.

## 🧪 Laboratorio guiado

### Paso 1 — El mundo: entidades y almacenamiento de componentes

El "mundo" reparte ids de entidad y guarda los componentes en diccionarios `{entidad: dato}`, uno por tipo. Crea `mini_ecs.py`:

```python
class Mundo:
    def __init__(self):
        self._siguiente_id = 0
        # Un diccionario por TIPO de componente: {tipo: {entidad_id: componente}}
        self._componentes = {}

    def crear_entidad(self) -> int:
        eid = self._siguiente_id
        self._siguiente_id += 1
        return eid   # una entidad es solo un id

    def agregar(self, entidad: int, componente) -> None:
        tipo = type(componente)
        self._componentes.setdefault(tipo, {})[entidad] = componente

    def obtener(self, entidad: int, tipo):
        return self._componentes.get(tipo, {}).get(entidad)

    def entidades_con(self, *tipos):
        # Devuelve las entidades que tienen TODOS los tipos pedidos
        if not tipos:
            return
        conjuntos = [set(self._componentes.get(t, {})) for t in tipos]
        comunes = set.intersection(*conjuntos) if conjuntos else set()
        for eid in sorted(comunes):
            yield eid
```

### Paso 2 — Componentes: solo datos

Los componentes no tienen lógica, solo campos:

```python
from dataclasses import dataclass

@dataclass
class Position:
    x: float
    y: float

@dataclass
class Velocity:
    dx: float
    dy: float
```

### Paso 3 — Un sistema: MovementSystem

El sistema recorre solo las entidades que tienen `Position` y `Velocity` y actualiza la posición:

```python
def movement_system(mundo: Mundo, dt: float) -> None:
    # Consulta: solo entidades con AMBOS componentes
    for eid in mundo.entidades_con(Position, Velocity):
        pos = mundo.obtener(eid, Position)
        vel = mundo.obtener(eid, Velocity)
        pos.x += vel.dx * dt
        pos.y += vel.dy * dt
```

### Paso 4 — Montar el mundo y correr la simulación

```python
def main():
    mundo = Mundo()

    # Entidad 0: se mueve (tiene Position + Velocity)
    jugador = mundo.crear_entidad()
    mundo.agregar(jugador, Position(0.0, 0.0))
    mundo.agregar(jugador, Velocity(2.0, 1.0))

    # Entidad 1: tambien se mueve
    enemigo = mundo.crear_entidad()
    mundo.agregar(enemigo, Position(10.0, 5.0))
    mundo.agregar(enemigo, Velocity(-1.0, 0.0))

    # Entidad 2: solo tiene Position -> el MovementSystem la IGNORA
    roca = mundo.crear_entidad()
    mundo.agregar(roca, Position(3.0, 3.0))

    dt = 1.0  # 1 segundo por "frame" para ver numeros claros
    for frame in range(3):
        movement_system(mundo, dt)
        print(f"--- frame {frame + 1} ---")
        for eid in (jugador, enemigo, roca):
            p = mundo.obtener(eid, Position)
            print(f"entidad {eid}: pos=({p.x:.1f}, {p.y:.1f})")

if __name__ == "__main__":
    main()
```

### Paso 5 — Ejecutar y observar

```bash
python mini_ecs.py
```

Verás cómo el jugador y el enemigo cambian de posición cada frame, mientras la roca (que no tiene `Velocity`) permanece quieta: el sistema solo procesó las entidades que cumplían la consulta. Ese es el corazón de ECS: los sistemas iteran conjuntos de componentes, no objetos concretos.

## ✍️ Ejercicios

1. Añade un componente `Health` y un `DamageSystem` que reste vida a las entidades que lo tengan.
2. Crea un `RenderSystem` que imprima solo las entidades con `Position` (simulando dibujo).
3. Añade un método `eliminar_entidad(eid)` al `Mundo` que borre sus componentes de todos los diccionarios.
4. Da al enemigo también un `Health` y comprueba que un sistema lo procesa y otro no.
5. Mide con `time.perf_counter()` cuánto tarda mover 100 000 entidades durante 10 frames.
6. Explica en comentarios por qué separar datos (componentes) de lógica (sistemas) ayuda al rendimiento.

## 📝 Reto verificable

Amplía el mini-ECS con un componente `Bounds(min_x, max_x)` y un sistema `bounce_system` que, para las entidades con `Position`, `Velocity` y `Bounds`, invierta la componente `dx` de la velocidad cuando la posición salga de los límites (efecto rebote). Simula al menos 8 frames con dos entidades y muestra sus posiciones.

**Criterio de aceptación**: el programa corre con `python mini_ecs.py`, las entidades con los tres componentes rebotan dentro de sus límites, y las entidades sin `Bounds` no se ven afectadas por el `bounce_system`, demostrando que el sistema itera solo la consulta correcta.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| `KeyError` al obtener un componente | La entidad no tiene ese tipo. Usa `.get()` o valida con `entidades_con(...)`. |
| El sistema procesa entidades sin el componente | No filtraste con la consulta. Itera con `entidades_con(Position, Velocity)`. |
| La posición no cambia | El componente es una copia, no una referencia. Con `@dataclass` mutable, modifica sus campos, no reasignes. |
| `TypeError: unhashable type` al usar tipos como clave | Usa la clase (`type(componente)`) como clave, no una instancia. |
| Confundir ECS con herencia | Estás poniendo lógica en el componente. Los componentes son solo datos; la lógica va en sistemas. |
| Rendimiento peor que POO en el ejemplo | En un mini-ECS con diccionarios es normal; la ventaja real aparece con almacenamiento contiguo a gran escala. |

## ❓ Preguntas frecuentes

**❓ ¿En qué se diferencia ECS de la POO con herencia?** En POO cada objeto agrupa datos y métodos y hereda de una jerarquía. En ECS los datos (componentes) se separan de la lógica (sistemas) y las entidades se componen; no hay jerarquías rígidas.

**❓ ¿ECS es lo mismo que los GameObject de Unity o los nodos de Godot?** No. Un GameObject/nodo es un objeto que contiene componentes y lógica. En ECS puro la entidad es solo un id y la lógica vive fuera, en sistemas; Unity DOTS es su versión ECS real.

**❓ ¿Por qué se dice que ECS es "orientado a datos"?** Porque organiza los datos según cómo se van a procesar, permitiendo recorrerlos de forma contigua en memoria, lo que mejora el uso de la caché de CPU y el rendimiento a gran escala.

**❓ ¿Necesito un motor especial para usar ECS?** No para aprenderlo, como en este laboratorio. Para producción existen implementaciones optimizadas como Unity DOTS, Bevy (Rust), flecs y EnTT (C++).

## 🔗 Referencias

- Jason Gregory, *Game Engine Architecture*, 3ª ed., sección de modelos de objetos de juego y arquitecturas orientadas a datos.
- Bevy, "ECS" (Bevy Book): <https://bevyengine.org/learn/book/getting-started/ecs/>
- flecs, documentación y manual: <https://www.flecs.dev/flecs/md_docs_2Quickstart.html>
- Unity, "Entities (DOTS)": <https://docs.unity3d.com/Packages/com.unity.entities@latest>

## ⬅️ Clase anterior

[Clase 013 - Patrones de diseño en juegos: State, Observer, Component y más](../013-patrones-de-diseno-en-juegos-state-observer-component-y-mas/README.md)

## ➡️ Siguiente clase

[Clase 015 - Git y control de versiones para proyectos de juegos (con LFS)](../015-git-y-control-de-versiones-para-proyectos-de-juegos-con-lfs/README.md)
