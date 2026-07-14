# Clase 121 — IA para NPCs y vida ambiental

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *GDC "AI-driven Dynamic Dialog" (Elan Ruskin, Valve) + Documentación de Godot 4 (CharacterBody2D, Timer)*
> ⏱️ Duración estimada: **50 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dar la sensación de un **mundo vivo** sin un coste alto: NPCs con **rutinas** (recorrer puntos de interés), **vida ambiental** (fauna, transeúntes) y **barks** (frases reactivas cortas). Al terminar tendrás un NPC gobernado por una **FSM simple** (`ir → usar → esperar`) que patrulla puntos de interés y **reacciona al jugador** con barks contextuales, todo observable en pantalla y consola.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Modelar una **rutina de NPC** como una FSM de tres estados con transiciones claras.
- Definir **puntos de interés (POI)** y hacer que el NPC los recorra en orden o al azar.
- Implementar **barks**: frases cortas con cooldown que reaccionan a eventos.
- Mover al NPC con `CharacterBody2D` y `move_and_slide()` sin física innecesaria.
- Equilibrar la ilusión de vida contra el coste de CPU usando temporizadores y "actores baratos".

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Rutinas y horarios | Un NPC con agenda parece tener vida propia |
| 2 | Puntos de interés (POI) | Definen a dónde ir y qué hacer allí |
| 3 | FSM ir→usar→esperar | Estructura mínima y legible para la conducta |
| 4 | Barks reactivos | Frases breves que dan personalidad barata |
| 5 | Cooldown de diálogo | Evita el spam de frases y el ruido |
| 6 | Vida ambiental | Fauna y multitudes llenan el mundo sin lógica pesada |
| 7 | Percepción sencilla | Un Area2D basta para "ve al jugador" |
| 8 | Coste y "actores baratos" | Muchos NPCs exigen lógica ligera |

## 📖 Definiciones y características

- **Rutina**: secuencia de tareas que el NPC repite. Clave: crea la impresión de propósito y horario.
- **Punto de interés (POI)**: posición del mundo con un significado (banco, fuente, tienda). Clave: da destinos con sentido a la rutina.
- **FSM (máquina de estados finitos)**: conjunto de estados y transiciones. Clave: legible y suficiente para conductas cotidianas.
- **Bark**: línea de diálogo corta y reactiva. Clave: barata de producir y muy efectiva para transmitir vida.
- **Cooldown**: tiempo mínimo entre dos barks. Clave: evita que el NPC hable sin parar.
- **Vida ambiental**: agentes decorativos (pájaros, peatones). Clave: pueblan el mundo con lógica casi nula.
- **Percepción por Area2D**: detección de entrada/salida por solapamiento. Clave: dispara reacciones sin cálculos costosos.
- **Actor barato**: agente con lógica mínima escalable a decenas. Clave: permite multitudes sin hundir el rendimiento.

## 🧰 Herramientas y preparación

Usaremos Godot 4.x. El NPC será un `CharacterBody2D` con un `Area2D` hijo como "sentido de proximidad" y varios `Marker2D` en la escena como POI. Los barks se mostrarán con `print()` y, opcionalmente, con un `Label` flotante. La FSM se construye con un `enum` y `match`; para conductas más complejas la formalizaremos en la clase 125. Ten a mano la referencia de [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html) y de [Area2D](https://docs.godotengine.org/en/stable/classes/class_area2d.html).

## 🧪 Laboratorio guiado

Vamos a crear un aldeano que camina entre tres POI: llega, "usa" el punto unos segundos, espera y va al siguiente. Cuando el jugador se acerca, suelta un bark como *"Buen día, viajero"*.

**Paso 1 — La escena.** Crea un `CharacterBody2D` llamado `Aldeano` con hijos: un `Area2D` (con `CollisionShape2D` circular) para la proximidad y, en la escena raíz, tres `Marker2D` (`POI1`, `POI2`, `POI3`). Asigna los POI por `@export`.

**Paso 2 — La FSM y los datos.** En `aldeano.gd`:

```gdscript
extends CharacterBody2D

enum Estado { IR, USAR, ESPERAR }

@export var poi: Array[NodePath] = []      # rutas a los Marker2D
@export var velocidad: float = 60.0
@export var radio_llegada: float = 6.0

var _estado: Estado = Estado.IR
var _indice: int = 0
var _tiempo: float = 0.0
var _barks := [
    "Buen día, viajero.",
    "Hoy hace un buen tiempo.",
    "¿Vienes de la ciudad?"
]
var _bark_en_cooldown: bool = false

func _ready() -> void:
    $Area2D.body_entered.connect(_on_proximidad)
```

**Paso 3 — El movimiento y las transiciones.** En `_physics_process` recorremos la rutina:

```gdscript
func _physics_process(delta: float) -> void:
    match _estado:
        Estado.IR:
            var destino := _destino_actual()
            var dir := (destino - global_position)
            if dir.length() <= radio_llegada:
                velocity = Vector2.ZERO
                _cambiar(Estado.USAR)
            else:
                velocity = dir.normalized() * velocidad
            move_and_slide()

        Estado.USAR:
            # Simula "usar" el punto: barrer, beber, mirar el puesto.
            _tiempo -= delta
            if _tiempo <= 0.0:
                _cambiar(Estado.ESPERAR)

        Estado.ESPERAR:
            _tiempo -= delta
            if _tiempo <= 0.0:
                _indice = (_indice + 1) % poi.size()
                _cambiar(Estado.IR)

func _destino_actual() -> Vector2:
    var marcador := get_node(poi[_indice]) as Node2D
    return marcador.global_position

func _cambiar(nuevo: Estado) -> void:
    _estado = nuevo
    match nuevo:
        Estado.USAR: _tiempo = randf_range(2.0, 4.0)
        Estado.ESPERAR: _tiempo = randf_range(1.0, 2.0)
```

**Paso 4 — Los barks reactivos.** Cuando el jugador entra en el `Area2D`, hablamos con cooldown para no repetir sin fin:

```gdscript
func _on_proximidad(cuerpo: Node) -> void:
    if not cuerpo.is_in_group("jugador"):
        return
    if _bark_en_cooldown:
        return
    var frase: String = _barks[randi_range(0, _barks.size() - 1)]
    print(name, ": ", frase)
    _iniciar_cooldown_bark(4.0)

func _iniciar_cooldown_bark(segundos: float) -> void:
    _bark_en_cooldown = true
    var t := get_tree().create_timer(segundos)
    t.timeout.connect(func(): _bark_en_cooldown = false)
```

**Paso 5 — Vida ambiental barata.** Un pájaro que solo deambula, sin FSM, para poblar el fondo:

```gdscript
extends CharacterBody2D
# Pajaro: actor barato, vuela a un punto aleatorio y repite.

@export var velocidad: float = 90.0
var _objetivo: Vector2

func _ready() -> void:
    _nuevo_objetivo()

func _physics_process(_delta: float) -> void:
    var dir := _objetivo - global_position
    if dir.length() < 8.0:
        _nuevo_objetivo()
    velocity = dir.normalized() * velocidad
    move_and_slide()

func _nuevo_objetivo() -> void:
    _objetivo = global_position + Vector2(randf_range(-120, 120), randf_range(-120, 120))
```

**Resultado observable:** el aldeano camina de POI en POI, se detiene a "usar" cada uno y, cuando acercas al jugador (nodo en el grupo `jugador`), imprime un bark que no se repite hasta pasados 4 segundos. El pájaro deambula de fondo sin lógica de estados.

## ✍️ Ejercicios

1. Añade un cuarto POI y cambia el recorrido de secuencial a aleatorio evitando repetir el último.
2. Muestra el bark en un `Label` flotante sobre el NPC en vez de en consola, y ocúltalo tras 2 s.
3. Da a cada NPC un conjunto de barks distinto vía `@export var barks: Array[String]`.
4. Añade un horario simple: de "día" el NPC recorre POI y de "noche" se queda en un POI "casa".
5. Crea una pequeña bandada reutilizando el pájaro con 8 instancias y separación mínima entre ellas.
6. Emite una señal `poi_alcanzado(indice)` y haz que otro sistema reaccione (p. ej., abrir una tienda).

## 📝 Reto verificable

Implementa **barks contextuales por prioridad**: si el jugador está herido (grupo `jugador` con `vida < 30`), el NPC debe decir una frase de alarma ("¡Estás malherido!") en lugar de un saludo. Usa una regla sencilla tipo *reglas ordenadas*: primero se evalúa la condición de alarma; si no aplica, se elige un saludo normal.

**Criterio de aceptación**: al acercarse con vida baja, el NPC dice siempre la frase de alarma; con vida normal, dice un saludo; en ambos casos se respeta el cooldown y no se repite frase antes de tiempo.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El NPC vibra al llegar al POI | `radio_llegada` demasiado pequeño; auméntalo o pon `velocity = ZERO` al llegar |
| El bark se repite cada frame | No implementaste cooldown; usa `create_timer` para bloquearlo un tiempo |
| `get_node(poi[_indice])` falla | Los `NodePath` de `@export` están vacíos o mal asignados en el inspector |
| El pájaro se va infinitamente | El objetivo se aleja siempre; genera el nuevo objetivo relativo y acótalo a los límites del mapa |
| El NPC no reacciona al jugador | El jugador no está en el grupo `jugador` o el `Area2D` no detecta cuerpos; revisa capas |
| Muchos NPCs bajan los FPS | Lógica pesada por frame; usa temporizadores y reduce cálculos en vida ambiental |

## ❓ Preguntas frecuentes

**¿Por qué una FSM y no un behavior tree para rutinas simples?**
Para tres estados, una FSM es más clara y directa. Los behavior trees (clase 125) brillan cuando hay muchas ramas y prioridades.

**¿Los barks necesitan audio?**
No es obligatorio. Muchos juegos muestran barks solo como texto flotante; el audio es un extra que refuerza la sensación, pero la técnica funciona sin él.

**¿Cómo evito que 50 NPCs saturen la CPU?**
Haz "actores baratos": lógica mínima, temporizadores en vez de cálculos por frame y desactiva la IA de los NPC fuera de la vista de la cámara.

**¿Puedo reutilizar esta FSM para animales?**
Sí. Cambia los POI por zonas de pasto y agua y el patrón `ir→usar→esperar` sirve como rutina de fauna.

## 🔗 Referencias

- [Clase CharacterBody2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)
- [Clase Area2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_area2d.html)
- [Grupos de nodos — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/scripting/groups.html)
- [AI-driven Dynamic Dialog (Elan Ruskin, GDC 2012)](https://www.gdcvault.com/play/1015528/AI-driven-Dynamic-Dialog-through)

## ➡️ Siguiente clase

[Clase 122 - Ruido y generación procedural (Perlin y Simplex)](../122-ruido-y-generacion-procedural-perlin-y-simplex/README.md)
