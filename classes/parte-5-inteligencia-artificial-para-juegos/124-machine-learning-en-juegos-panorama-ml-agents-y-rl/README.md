# Clase 124 — Machine learning en juegos: panorama (ML-Agents y RL)

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Documentación de Unity ML-Agents + Sutton & Barto "Reinforcement Learning: An Introduction"*
> ⏱️ Duración estimada: **50 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Obtener un **panorama honesto** del machine learning en videojuegos: qué aporta, qué no, y cuándo las **técnicas clásicas** (FSM, behavior trees, pathfinding) siguen siendo la mejor opción. Nos centraremos en el **aprendizaje por refuerzo (RL)** y su tríada agente-recompensa-entorno, mencionaremos **ML-Agents (Unity)** y los addons de RL para Godot, y como laboratorio **conceptual** diseñaremos la función de recompensa y el espacio de observación/acción de un agente sencillo, sin entrenarlo.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar la diferencia entre IA "que aprende" (ML) e IA "programada" (clásica) en juegos.
- Describir el bucle de **RL**: agente, entorno, estado, acción, recompensa.
- Diseñar un **espacio de observación** y un **espacio de acción** para un problema concreto.
- Redactar una **función de recompensa** con premios y penalizaciones equilibrados.
- Justificar **cuándo NO usar ML** y preferir FSM/BT/pathfinding.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | ML vs IA clásica | Aclara expectativas y evita sobreingeniería |
| 2 | Bucle de RL | Es el modelo mental base del aprendizaje por refuerzo |
| 3 | Observaciones | Lo que el agente "ve" define lo que puede aprender |
| 4 | Acciones | El repertorio de decisiones del agente |
| 5 | Función de recompensa | Es el corazón del diseño y la fuente de casi todos los fallos |
| 6 | ML-Agents y addons Godot | Dónde vive hoy el RL aplicable a juegos |
| 7 | Coste y reproducibilidad | Entrenar es caro, lento y difícil de depurar |
| 8 | Cuándo NO usar ML | La decisión más valiosa suele ser no usarlo |

## 📖 Definiciones y características

- **Machine learning (ML)**: sistemas que ajustan su conducta a partir de datos o experiencia. Clave: no se programan reglas explícitas, se aprenden.
- **Aprendizaje por refuerzo (RL)**: un agente aprende por ensayo y error maximizando recompensa. Clave: no necesita ejemplos etiquetados, sino una señal de recompensa.
- **Agente**: la entidad que decide y actúa. Clave: su política mapea observación → acción.
- **Entorno**: el mundo con el que interactúa el agente. Clave: en juegos, tu propia escena.
- **Observación**: vector de datos que percibe el agente. Clave: demasiadas o mal elegidas dificultan el aprendizaje.
- **Recompensa**: número que premia o castiga cada paso. Clave: recompensas mal diseñadas producen conductas absurdas.
- **Política**: la estrategia aprendida (a menudo una red neuronal). Clave: es el "cerebro" resultante del entrenamiento.
- **ML-Agents**: framework de RL de Unity. Clave: referencia estándar de la industria; en Godot se usan addons de la comunidad.

## 🧰 Herramientas y preparación

Esta clase es **conceptual y de diseño**: no entrenaremos nada ni instalaremos frameworks pesados. Conviene conocer el marco de referencia: **[Unity ML-Agents](https://github.com/Unity-Technologies/ml-agents)** es el más maduro y documentado; en Godot 4 existen addons de la comunidad (por ejemplo *Godot RL Agents*) que conectan la escena con librerías de Python como Stable-Baselines3. Como apoyo, escribiremos en GDScript la **estructura de datos** de observaciones/acciones y una función de recompensa comentada, para razonar el diseño aunque el aprendizaje real ocurra fuera de Godot.

## 🧪 Laboratorio guiado

Diseñaremos, sin entrenar, un agente que debe **llegar a una meta evitando lava**. El "laboratorio" es especificar bien el problema: observaciones, acciones y recompensa. Escribiremos esa especificación como código GDScript legible.

**Paso 1 — Definir el espacio de observación.** ¿Qué necesita "ver" el agente para decidir? Lo mínimo suficiente:

```gdscript
extends RefCounted
class_name EspecAgente
# Especificación de diseño (no entrena; documenta el problema).

# Observaciones: vector normalizado que el agente percibe cada paso.
static func observaciones(agente: Node2D, meta: Node2D, peligro: Node2D) -> PackedFloat32Array:
    var obs := PackedFloat32Array()
    # Dirección normalizada hacia la meta (2 valores).
    var a_meta := (meta.global_position - agente.global_position).normalized()
    obs.append(a_meta.x)
    obs.append(a_meta.y)
    # Distancia normalizada a la meta (1 valor).
    obs.append(agente.global_position.distance_to(meta.global_position) / 1000.0)
    # Dirección al peligro más cercano (2 valores).
    var a_peligro := (peligro.global_position - agente.global_position).normalized()
    obs.append(a_peligro.x)
    obs.append(a_peligro.y)
    return obs   # 5 observaciones
```

**Paso 2 — Definir el espacio de acción.** Elegimos acciones discretas simples: mover en 4 direcciones o quedarse quieto:

```gdscript
enum Accion { QUIETO, ARRIBA, ABAJO, IZQUIERDA, DERECHA }

# El agente entrenado produciría un índice de este enum cada paso.
static func aplicar_accion(agente: CharacterBody2D, accion: int, velocidad: float) -> void:
    var dir := Vector2.ZERO
    match accion:
        Accion.ARRIBA: dir = Vector2.UP
        Accion.ABAJO: dir = Vector2.DOWN
        Accion.IZQUIERDA: dir = Vector2.LEFT
        Accion.DERECHA: dir = Vector2.RIGHT
    agente.velocity = dir * velocidad
    agente.move_and_slide()
```

**Paso 3 — Diseñar la función de recompensa.** El punto más delicado: premiar el progreso, castigar el fracaso y evitar el "reward hacking":

```gdscript
# Recompensa por paso. Se acumularía durante el entrenamiento.
static func recompensa(
        agente: Node2D, meta: Node2D,
        dist_anterior: float, choco_lava: bool, alcanzo_meta: bool) -> float:
    if alcanzo_meta:
        return 1.0            # gran premio terminal
    if choco_lava:
        return -1.0           # castigo terminal
    var dist := agente.global_position.distance_to(meta.global_position)
    # Recompensa densa: premia acercarse, castiga alejarse.
    var progreso := (dist_anterior - dist) * 0.01
    # Pequeña penalización por paso para incentivar rapidez.
    return progreso - 0.001
```

**Paso 4 — Esbozar el bucle de episodio.** Cómo encajaría en un entorno de entrenamiento (pseudo-integración con un addon):

```gdscript
# Boceto del bucle. En un addon real, el framework llama a estos pasos.
func _paso_de_entrenamiento(agente, meta, peligro, dist_anterior) -> Dictionary:
    var obs := EspecAgente.observaciones(agente, meta, peligro)
    # La política (red neuronal, entrenada aparte) elige la acción:
    var accion := _politica_decide(obs)          # devuelve un int (enum Accion)
    EspecAgente.aplicar_accion(agente, accion, 120.0)

    var choco := agente.global_position.distance_to(peligro.global_position) < 16.0
    var llego := agente.global_position.distance_to(meta.global_position) < 16.0
    var r := EspecAgente.recompensa(agente, meta, dist_anterior, choco, llego)
    return { "obs": obs, "recompensa": r, "terminado": choco or llego }

func _politica_decide(_obs: PackedFloat32Array) -> int:
    # Marcador de posición: aquí iría la política aprendida.
    return EspecAgente.Accion.QUIETO
```

**Resultado observable:** no hay entrenamiento en vivo, pero obtienes un artefacto concreto: una especificación clara del problema (5 observaciones, 5 acciones, recompensa con premio +1 / castigo -1 / progreso denso). Este documento ejecutable es lo que llevarías a ML-Agents o a un addon de RL de Godot. La reflexión clave: para "llegar a la meta evitando lava", un `NavigationAgent` con un `RayCast` cuesta minutos y funciona; entrenar una política cuesta horas y es difícil de depurar.

## ✍️ Ejercicios

1. Añade a las observaciones la **velocidad actual** del agente y discute si ayuda o solo añade ruido.
2. Reescribe el espacio de acción como **continuo** (un `Vector2` de -1 a 1) y comenta las diferencias.
3. Detecta un caso de "reward hacking": ¿qué pasa si premias solo estar cerca de la meta sin castigar la lava?
4. Redacta en 5 líneas cuándo, para tu juego, usarías un behavior tree en vez de RL.
5. Investiga *Godot RL Agents* y describe qué componentes conecta entre Godot y Python.
6. Diseña la recompensa para un agente que debe **recoger 3 monedas** antes de salir; enumera premios y castigos.

## 📝 Reto verificable

Escribe una especificación completa (observaciones, acciones y función de recompensa comentada, en GDScript como en el laboratorio) para un agente que debe **patrullar y perseguir** a un jugador. Luego redacta un párrafo argumentando si ese comportamiento debería resolverse con RL o con un behavior tree, con al menos tres razones concretas.

**Criterio de aceptación**: la especificación define un vector de observación con tamaño fijo y justificado, un espacio de acción explícito y una recompensa con al menos un premio terminal y una penalización; el párrafo concluye razonadamente (para este caso, la respuesta esperada es **BT/FSM**, por coste, control y depurabilidad).

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El agente aprende una conducta absurda | "Reward hacking": la recompensa premia algo no deseado; rediseña premios y castigos |
| El entrenamiento no converge | Espacio de observación ruidoso o enorme; reduce y normaliza las observaciones |
| Se espera ML donde bastaba una FSM | Sobreingeniería; para conductas deterministas usa técnicas clásicas |
| Resultados irreproducibles | No fijaste semillas ni versión del entorno; documenta seed y dependencias |
| Confundir RL con aprendizaje supervisado | RL usa recompensa, no ejemplos etiquetados; ajusta el marco mental |
| Coste de cómputo inasumible | Entrenar exige mucho tiempo/GPU; evalúa si el ROI justifica el esfuerzo |

## ❓ Preguntas frecuentes

**¿El ML reemplazará a las FSM y los behavior trees en juegos?**
No en general. La mayoría de la IA de juego comercial sigue siendo clásica porque es controlable, barata y depurable. El ML brilla en nichos concretos (comportamientos emergentes, ajuste de parámetros, testeo automático).

**¿Puedo entrenar agentes directamente dentro de Godot?**
No de forma nativa. Se usan addons de la comunidad que conectan la escena de Godot con librerías de Python (como Stable-Baselines3). El estándar mejor documentado sigue siendo Unity ML-Agents.

**¿Qué es lo más difícil del RL?**
Diseñar la función de recompensa. Una recompensa mal pensada lleva al agente a explotar atajos indeseados en vez de aprender lo que querías.

**¿Cuándo NO debo usar ML?**
Cuando el comportamiento es determinista o especificable con reglas, cuando necesitas control fino, cuando el tiempo de desarrollo importa, o cuando no puedes permitirte el coste de entrenar y depurar. En esos casos, FSM/BT/pathfinding ganan.

## 🔗 Referencias

- [Unity ML-Agents Toolkit — GitHub](https://github.com/Unity-Technologies/ml-agents)
- [Godot RL Agents — GitHub](https://github.com/edbeeching/godot_rl_agents)
- [Reinforcement Learning: An Introduction (Sutton & Barto, libro abierto)](http://incompleteideas.net/book/the-book-2nd.html)
- [Stable-Baselines3 — Documentación](https://stable-baselines3.readthedocs.io/)

## ⬅️ Clase anterior

[Clase 123 - Generación procedural de niveles](../123-generacion-procedural-de-niveles/README.md)

## ➡️ Siguiente clase

[Clase 125 - Capstone Parte 5: enemigo con behavior tree y percepción](../125-capstone-parte-5-enemigo-con-behavior-tree-y-percepcion/README.md)
