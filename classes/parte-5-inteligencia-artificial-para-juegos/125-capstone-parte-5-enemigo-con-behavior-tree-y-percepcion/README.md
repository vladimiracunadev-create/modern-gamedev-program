# Clase 125 — Capstone Parte 5: enemigo con behavior tree y percepción

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *"Behavior Trees for AI" (Chris Simpson, Gamasutra) + Documentación de Godot 4 (NavigationAgent2D, RayCast2D, Area2D)*
> ⏱️ Duración estimada: **75 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Integrar toda la Parte 5 en un **enemigo completo**: un **behavior tree** con **blackboard**, **percepción** (cono de visión + memoria), **pathfinding** con `NavigationAgent2D` y **barks**, recorriendo los estados **patrulla → alerta → combate → búsqueda → pierde**. Al terminar tendrás el enemigo ensamblado, un diagrama del árbol en texto/tabla, el snippet del blackboard y una **definition of done** con checklist de playtesting.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Construir un **behavior tree** con nodos `Secuencia`, `Selector` y hojas de acción/condición usando `class_name` y `RefCounted`.
- Compartir estado entre nodos mediante un **blackboard** (`Dictionary`).
- Implementar **percepción**: cono de visión con `Area2D` + `RayCast2D` y **memoria** de la última posición vista.
- Integrar **pathfinding** con `NavigationAgent2D` para perseguir y buscar.
- Redactar una **especificación, checklist y definition of done** y validarlas con playtesting.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Behavior tree | Escala mejor que una FSM cuando hay muchas conductas |
| 2 | Blackboard | Desacopla los nodos compartiendo datos en un solo sitio |
| 3 | Cono de visión | Percepción creíble: solo ve lo que tiene delante |
| 4 | RayCast de línea de visión | Evita ver a través de paredes |
| 5 | Memoria | Buscar la última posición vista da inteligencia percibida |
| 6 | NavigationAgent2D | Persigue y busca sorteando obstáculos |
| 7 | Estados de alto nivel | Patrulla→alerta→combate→búsqueda→pierde |
| 8 | Definition of done | Cierra el capstone con criterios verificables |

## 📖 Definiciones y características

- **Behavior tree (BT)**: árbol de nodos que se evalúa cada tick devolviendo ÉXITO/FALLO/EN_CURSO. Clave: modular y fácil de extender.
- **Selector**: nodo que prueba hijos hasta que uno tenga éxito. Clave: implementa prioridades ("si ves al jugador, combate; si no, patrulla").
- **Secuencia**: nodo que ejecuta hijos hasta que uno falle. Clave: encadena pasos que deben cumplirse en orden.
- **Blackboard**: `Dictionary` compartido con el estado del agente. Clave: los nodos leen/escriben aquí en vez de acoplarse entre sí.
- **Cono de visión**: región angular frente al enemigo. Clave: percepción realista y explotable por el jugador.
- **Línea de visión (LoS)**: `RayCast2D` que comprueba si hay muro entre enemigo y objetivo. Clave: impide "ver" a través de paredes.
- **Memoria**: última posición conocida del objetivo. Clave: permite buscar cuando se pierde de vista.
- **NavigationAgent2D**: componente de pathfinding de Godot 4. Clave: calcula rutas evitando obstáculos.

## 🧰 Herramientas y preparación

Con Godot 4.x montaremos el enemigo como `CharacterBody2D` con estos hijos: un `Area2D` con forma de cono (el sentido de visión), un `RayCast2D` para la línea de visión, un `NavigationAgent2D` para las rutas y varios `Marker2D` como ruta de patrulla. El BT se implementa en scripts con `class_name` heredando de `RefCounted`; el blackboard es un `Dictionary`. Necesitas una `NavigationRegion2D` con su malla horneada. Consulta [NavigationAgent2D](https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html) y [RayCast2D](https://docs.godotengine.org/en/stable/classes/class_raycast2d.html).

## 🧪 Laboratorio guiado

Ensamblaremos el enemigo por capas: primero el blackboard, luego los nodos del BT, después la percepción, y por último el árbol completo con los cinco estados.

**Diagrama del behavior tree (texto).** Prioridad de arriba a abajo dentro del Selector raíz:

| Nivel | Nodo | Tipo | Condición / Acción |
|-------|------|------|--------------------|
| 0 | Raíz | Selector | Elige la primera rama viable |
| 1 | Combate | Secuencia | ¿Ve al jugador? → acercarse y atacar |
| 1 | Búsqueda | Secuencia | ¿Hay última posición? → ir allí y mirar |
| 1 | Patrulla | Secuencia | (por defecto) → ir al siguiente POI |

**Paso 1 — El blackboard.** Un `Dictionary` con todo el estado compartido, inicializado en el enemigo:

```gdscript
# Dentro de enemigo.gd (extends CharacterBody2D)
var blackboard := {
    "objetivo": null,                 # Node2D del jugador si es visible
    "ultima_pos": Vector2.ZERO,       # memoria: dónde se le vio por última vez
    "tiene_memoria": false,           # ¿hay una pista que seguir?
    "estado": "patrulla",             # solo para depurar/barks
    "poi_index": 0
}
```

**Paso 2 — Nodos base del BT.** Un contrato común y los compuestos `Secuencia` y `Selector`:

```gdscript
class_name NodoBT
extends RefCounted

enum Estado { EXITO, FALLO, EN_CURSO }

# Cada nodo procesa un tick con el contexto (enemigo) y el blackboard.
func tick(_agente, _bb: Dictionary) -> int:
    return Estado.FALLO

# --- Secuencia: ejecuta hijos hasta que uno falle. ---
class_name Secuencia
extends NodoBT
var hijos: Array[NodoBT] = []
func tick(agente, bb: Dictionary) -> int:
    for h in hijos:
        var r := h.tick(agente, bb)
        if r != Estado.EXITO:
            return r      # falla o queda en curso: detiene la secuencia
    return Estado.EXITO

# --- Selector: prueba hijos hasta que uno no falle (prioridad). ---
class_name Selector
extends NodoBT
var hijos: Array[NodoBT] = []
func tick(agente, bb: Dictionary) -> int:
    for h in hijos:
        var r := h.tick(agente, bb)
        if r != Estado.FALLO:
            return r      # el primero que no falla, gana
    return Estado.FALLO
```

> Nota: cada `class_name` va en su propio archivo `.gd`; aquí se muestran juntos por brevedad.

**Paso 3 — La percepción (cono + línea de visión).** En el enemigo, actualizamos el blackboard cada physics frame:

```gdscript
@onready var vista: Area2D = $ConoVision
@onready var rayo: RayCast2D = $RayCast2D

func _percibir() -> void:
    for cuerpo in vista.get_overlapping_bodies():
        if not cuerpo.is_in_group("jugador"):
            continue
        # Línea de visión: ¿hay muro entre nosotros?
        rayo.target_position = to_local(cuerpo.global_position)
        rayo.force_raycast_update()
        var libre := not rayo.is_colliding() or rayo.get_collider() == cuerpo
        if libre:
            blackboard["objetivo"] = cuerpo
            blackboard["ultima_pos"] = cuerpo.global_position
            blackboard["tiene_memoria"] = true
            return
    blackboard["objetivo"] = null   # no visible este frame
```

**Paso 4 — Hojas de acción con pathfinding.** Combate, búsqueda y patrulla usan `NavigationAgent2D`:

```gdscript
class_name AccionPerseguir
extends NodoBT

func tick(agente, bb: Dictionary) -> int:
    if bb["objetivo"] == null:
        return Estado.FALLO
    bb["estado"] = "combate"
    agente.ir_hacia(bb["objetivo"].global_position)
    if agente.global_position.distance_to(bb["objetivo"].global_position) < 40.0:
        agente.atacar()
    return Estado.EN_CURSO

# --- Búsqueda: si hay memoria, va a la última posición vista. ---
class_name AccionBuscar
extends NodoBT
func tick(agente, bb: Dictionary) -> int:
    if not bb["tiene_memoria"]:
        return Estado.FALLO
    bb["estado"] = "busqueda"
    agente.ir_hacia(bb["ultima_pos"])
    if agente.global_position.distance_to(bb["ultima_pos"]) < 12.0:
        bb["tiene_memoria"] = false   # llegó y no encontró nada -> pierde
        return Estado.EXITO
    return Estado.EN_CURSO

# --- Patrulla: conducta por defecto. ---
class_name AccionPatrullar
extends NodoBT
func tick(agente, bb: Dictionary) -> int:
    bb["estado"] = "patrulla"
    agente.patrullar()
    return Estado.EN_CURSO
```

**Paso 5 — Ensamblar el árbol y el movimiento.** En el enemigo, construimos el BT y lo ejecutamos cada tick:

```gdscript
@onready var agente_nav: NavigationAgent2D = $NavigationAgent2D
@export var velocidad: float = 110.0
@export var patrulla: Array[NodePath] = []
var _arbol: NodoBT

func _ready() -> void:
    # Selector raíz con prioridad: combate > búsqueda > patrulla.
    var raiz := Selector.new()
    raiz.hijos = [AccionPerseguir.new(), AccionBuscar.new(), AccionPatrullar.new()]
    _arbol = raiz

func _physics_process(_delta: float) -> void:
    _percibir()
    _arbol.tick(self, blackboard)

func ir_hacia(destino: Vector2) -> void:
    agente_nav.target_position = destino
    var siguiente := agente_nav.get_next_path_position()
    velocity = (siguiente - global_position).normalized() * velocidad
    move_and_slide()

func patrullar() -> void:
    if patrulla.is_empty():
        return
    var marca := get_node(patrulla[blackboard["poi_index"]]) as Node2D
    ir_hacia(marca.global_position)
    if global_position.distance_to(marca.global_position) < 12.0:
        blackboard["poi_index"] = (blackboard["poi_index"] + 1) % patrulla.size()

func atacar() -> void:
    pass                       # aquí dispararías o aplicarías daño

func _bark(texto: String) -> void:
    print(name, ": ", texto)   # engánchalo a un Label flotante si quieres
```

**Resultado observable:** el enemigo patrulla entre POI; cuando el jugador entra en su cono de visión sin muros de por medio, cambia a combate y lo persigue con pathfinding; si lo pierde, va a la última posición vista (búsqueda) y, al no encontrarlo, vuelve a patrullar. El campo `blackboard["estado"]` refleja la transición patrulla → combate → búsqueda → patrulla en consola.

**Checklist / Definition of Done:**

- [ ] El enemigo patrulla en bucle entre todos los POI.
- [ ] Detecta al jugador solo dentro del cono y sin muros de por medio.
- [ ] Persigue con `NavigationAgent2D` sorteando obstáculos.
- [ ] Al perder la vista, va a la última posición conocida (memoria).
- [ ] Tras buscar sin éxito, regresa a patrulla.
- [ ] Emite al menos un bark al pasar a alerta/combate.
- [ ] La semilla de patrulla/POI es determinista y reproducible.

## ✍️ Ejercicios

1. Añade un estado de **alerta** intermedio: al detectar, el enemigo se detiene 0.5 s y emite "¿Quién anda ahí?" antes de perseguir.
2. Implementa un **decorador** `Cooldown` que impida atacar más de una vez por segundo.
3. Añade **cobertura**: si su vida baja, busca el `Marker2D` de cobertura más cercano antes de volver al combate.
4. Dibuja el cono de visión con `_draw()` para depurar la percepción visualmente.
5. Haz que la memoria caduque: si pasan 6 s sin ver al jugador durante la búsqueda, abandona la pista.
6. Añade un nodo `Inversor` y úsalo para expresar "si NO ve al jugador, patrulla".

## 📝 Reto verificable

Amplía el behavior tree con una rama de **flanqueo**: cuando el enemigo ve al jugador pero hay un muro entre ambos (línea de visión bloqueada aunque esté dentro del cono), en vez de quedarse quieto debe rodear usando `NavigationAgent2D` hacia la última posición libre conocida. Integra la rama respetando la prioridad del Selector.

**Criterio de aceptación**: en un escenario con una columna, el enemigo no atraviesa el muro con la mirada, rodea la columna vía pathfinding y reengancha al jugador; la consola muestra la secuencia de estados y el árbol sigue devolviendo un único resultado por tick sin errores.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El enemigo ve a través de paredes | No compruebas la línea de visión; usa `RayCast2D` con `force_raycast_update()` |
| Se queda clavado sin moverse | La `NavigationRegion2D` no está horneada o el `target_position` no se actualiza |
| El BT nunca sale de patrulla | El Selector no reordena por prioridad; combate debe ir antes que patrulla |
| Persigue eternamente sin memoria | No limpias `tiene_memoria` al llegar a la última posición; márcala en `AccionBuscar` |
| Barks repetidos en bucle | Emites el bark cada tick; dispáralo solo en el **cambio** de estado |
| El agente tiembla junto al jugador | Umbral de ataque muy pequeño; añade histéresis o distancia de parada |

## ❓ Preguntas frecuentes

**¿Por qué un behavior tree y no una FSM para este enemigo?**
Con cinco conductas y prioridades, el BT es más modular: añadir una rama (flanqueo, cobertura) no obliga a reconectar todas las transiciones como en una FSM.

**¿Qué gana el enemigo con memoria?**
Inteligencia percibida. Ir a la última posición vista, en lugar de "olvidar" al instante, hace que el jugador sienta que lo están buscando de verdad.

**¿El blackboard debe ser global?**
No. Cada enemigo tiene su propio `Dictionary` blackboard. Un dato verdaderamente global (como el Director de la clase 120) sí iría en un Autoload aparte.

**¿Cómo integro esto con el Director de la clase 120?**
El Director decide *cuántos* enemigos y *cuándo* aparecen; cada enemigo, con su BT y percepción, decide *cómo* comportarse. Son capas complementarias.

## 🔗 Referencias

- [Clase NavigationAgent2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html)
- [Clase RayCast2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_raycast2d.html)
- [Behavior trees for AI: How they work (Chris Simpson)](https://www.gamedeveloper.com/programming/behavior-trees-for-ai-how-they-work)
- [Navegación 2D — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_2d.html)

## ⬅️ Clase anterior

[Clase 124 - Machine learning en juegos: panorama (ML-Agents y RL)](../124-machine-learning-en-juegos-panorama-ml-agents-y-rl/README.md)

## ➡️ Siguiente clase

[Clase 126 - Fundamentos de audio para juegos (repaso aplicado)](../../parte-6-audio-y-musica-interactiva/126-fundamentos-de-audio-para-juegos-repaso-aplicado/README.md)
