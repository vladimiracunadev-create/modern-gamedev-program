# Clase 120 — Director de IA y dificultad dinámica

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Charla de Valve "The AI Director" (Left 4 Dead) + Documentación de Godot 4 (Autoload, Timer)*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Construir un **Director de IA** al estilo *Left 4 Dead*: un sistema global que **mide la presión** que siente el jugador y **modula el ritmo** del juego decidiendo cuándo y cuántos enemigos aparecen. Al terminar tendrás un `Autoload` llamado `Director` que estima la intensidad a partir de la vida y del tiempo desde el último combate, aplica **DDA (ajuste dinámico de dificultad)** y respeta un ciclo de **pacing** de tensión y descanso, todo verificable en consola.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar qué es un director de IA y por qué separa la *decisión de ritmo* de la *lógica de cada enemigo*.
- Definir una señal de **intensidad** a partir de variables observables del jugador (vida, daño reciente, tiempo sin combate).
- Diseñar una máquina de estados de **pacing**: acumulación → pico → descanso.
- Implementar **DDA** que suba o baje la presión sin tocar el código de los enemigos.
- Exponer el Director como **Autoload** y comunicarse con el mundo mediante señales.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es un director de IA | Centraliza el control del ritmo global de la partida |
| 2 | Señal de intensidad | Traduce el estado del jugador a un número accionable |
| 3 | Pacing tensión-descanso | Evita el agotamiento y la monotonía |
| 4 | DDA (ajuste dinámico) | Adapta la dificultad a cada jugador en tiempo real |
| 5 | Autoload como Director | Un único punto de verdad accesible desde todo el juego |
| 6 | Presupuesto de spawns | Limita cuántos enemigos existen para no romper el ritmo |
| 7 | Señales de spawn | Desacopla el "qué decidir" del "quién ejecuta" |
| 8 | Telemetría y tuning | Sin medir no puedes equilibrar |

## 📖 Definiciones y características

- **Director de IA**: sistema global que orquesta ritmo, spawns y recursos. Clave: no controla el movimiento de cada enemigo, solo *cuándo y cuánto* aparece.
- **Intensidad**: valor de 0 a 1 que estima cuánta presión percibe el jugador. Clave: sube con el daño recibido y baja con el tiempo tranquilo.
- **Pacing**: estructura del ritmo emocional. Clave: alternar picos de tensión con valles de descanso mantiene el interés.
- **DDA**: ajuste dinámico de dificultad. Clave: modifica parámetros en vivo según el desempeño, sin menú de dificultad fijo.
- **Presupuesto de población**: número máximo de enemigos activos. Clave: acota el coste y protege el ritmo.
- **Autoload (singleton)**: nodo cargado globalmente en Godot 4. Clave: accesible por nombre desde cualquier escena.
- **Estado de descanso**: fase deliberada de baja presión. Clave: da respiro y hace que el siguiente pico se sienta más fuerte.
- **Señal (`signal`)**: mecanismo de eventos de Godot. Clave: el Director *emite* y las escenas *reaccionan*, sin acoplarse.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x. Vamos a registrar un script como **Autoload** en `Proyecto → Configuración del proyecto → Autoload`, con el nombre `Director`. El Director usará un `Timer` interno para su ciclo de decisión y `signal` para pedir spawns; una escena de prueba escuchará esas señales e imprimirá los eventos. No hace falta arte: basta un `Node2D` raíz que simule al jugador con variables. Ten a mano la referencia de [Singletons (Autoload)](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) y de la clase [Timer](https://docs.godotengine.org/en/stable/classes/class_timer.html).

## 🧪 Laboratorio guiado

Vamos a crear un Director que, cada segundo, mide la presión del jugador y decide un **presupuesto de enemigos** a generar. El resultado observable serán mensajes en consola del tipo *"PACING: descanso"* y *"SPAWN x3"*.

**Paso 1 — El estado global del jugador.** Creamos un pequeño Autoload `EstadoJugador` con las variables que el Director observará. Regístralo como Autoload con nombre `EstadoJugador`:

```gdscript
extends Node
# Autoload: EstadoJugador — datos observables por el Director.

@export var vida_max: float = 100.0
var vida: float = 100.0
var tiempo_desde_combate: float = 0.0  # segundos sin recibir daño

func recibir_dano(cantidad: float) -> void:
    vida = clampf(vida - cantidad, 0.0, vida_max)
    tiempo_desde_combate = 0.0

func _process(delta: float) -> void:
    tiempo_desde_combate += delta
```

**Paso 2 — El Director como Autoload.** Crea `director.gd`, regístralo como Autoload `Director`. Declara señales y el ciclo de decisión con un `Timer`:

```gdscript
extends Node
# Autoload: Director — mide intensidad y modula spawns.

signal solicitar_spawn(cantidad: int)
signal cambio_pacing(estado: String)

enum Pacing { ACUMULACION, PICO, DESCANSO }

@export var poblacion_max: int = 8      # techo de enemigos vivos
@export var descanso_min: float = 6.0   # duración mínima del respiro

var _estado: Pacing = Pacing.ACUMULACION
var _intensidad: float = 0.0
var _enemigos_vivos: int = 0
var _tiempo_en_estado: float = 0.0

func _ready() -> void:
    var reloj := Timer.new()
    reloj.wait_time = 1.0
    reloj.autostart = true
    reloj.timeout.connect(_decidir)
    add_child(reloj)
```

**Paso 3 — Estimar la intensidad.** La intensidad sube cuando el jugador está débil y en combate reciente; baja con el tiempo tranquilo:

```gdscript
func _estimar_intensidad() -> float:
    var falta_vida := 1.0 - (EstadoJugador.vida / EstadoJugador.vida_max)
    # Cuanto más reciente el combate, más presión (satura a los 8 s).
    var recencia := clampf(1.0 - EstadoJugador.tiempo_desde_combate / 8.0, 0.0, 1.0)
    # Mezcla ponderada: la vida pesa más que la recencia.
    return clampf(0.6 * falta_vida + 0.4 * recencia, 0.0, 1.0)
```

**Paso 4 — La máquina de pacing y la decisión de spawn.** Cada segundo actualizamos el estado y, según él, pedimos enemigos:

```gdscript
func _decidir() -> void:
    _intensidad = _estimar_intensidad()
    _tiempo_en_estado += 1.0

    match _estado:
        Pacing.ACUMULACION:
            _spawn_hasta(_presupuesto())
            if _intensidad >= 0.75:
                _ir_a(Pacing.PICO)
        Pacing.PICO:
            _spawn_hasta(poblacion_max)          # oleada fuerte
            if _intensidad <= 0.35:
                _ir_a(Pacing.DESCANSO)            # el jugador se recuperó
        Pacing.DESCANSO:
            # No generamos nada: respiro deliberado.
            if _tiempo_en_estado >= descanso_min:
                _ir_a(Pacing.ACUMULACION)

func _presupuesto() -> int:
    # DDA: menos enemigos si la intensidad ya es alta.
    var margen := 1.0 - _intensidad
    return int(round(poblacion_max * margen))

func _spawn_hasta(objetivo: int) -> void:
    var faltan := objetivo - _enemigos_vivos
    if faltan > 0:
        _enemigos_vivos += faltan
        solicitar_spawn.emit(faltan)
        print("SPAWN x", faltan, " | intensidad=", "%.2f" % _intensidad)

func _ir_a(nuevo: Pacing) -> void:
    _estado = nuevo
    _tiempo_en_estado = 0.0
    cambio_pacing.emit(Pacing.keys()[nuevo])
    print("PACING: ", Pacing.keys()[nuevo])

func notificar_muerte_enemigo() -> void:
    _enemigos_vivos = maxi(0, _enemigos_vivos - 1)
```

**Paso 5 — Escena de prueba.** Un `Node2D` que simula daño y escucha al Director:

```gdscript
extends Node2D

func _ready() -> void:
    Director.solicitar_spawn.connect(_on_spawn)
    Director.cambio_pacing.connect(func(e): print(">> nuevo pacing: ", e))

func _on_spawn(cantidad: int) -> void:
    print("El mundo instancia ", cantidad, " enemigos")

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):   # Espacio = recibir un golpe
        EstadoJugador.recibir_dano(25.0)
        print("¡Golpe! vida=", EstadoJugador.vida)
```

**Resultado observable:** al pulsar Espacio varias veces la vida baja, la intensidad sube y verás `PACING: pico` con oleadas mayores; si dejas de pulsar, tras unos segundos aparece `PACING: descanso` y los spawns se detienen. Acabas de modular el ritmo sin tocar la IA de ningún enemigo.

## ✍️ Ejercicios

1. Añade una señal `solicitar_recursos` que, en `DESCANSO`, pida soltar un botiquín cerca del jugador.
2. Suaviza la intensidad promediando las últimas 3 lecturas para evitar saltos bruscos.
3. Introduce un `enum Perfil { CASUAL, NORMAL, EXPERTO }` que escale `poblacion_max` como capa de DDA por perfil.
4. Registra en un `Array` la intensidad por segundo e imprime su máximo y su media al cerrar (telemetría).
5. Haz que el `PICO` no pueda repetirse hasta pasados 15 s, garantizando descansos entre oleadas.
6. Expón `@export var frecuencia_decision: float` y conecta su cambio a `wait_time` del `Timer`.

## 📝 Reto verificable

Amplía el Director para que module también un **recurso de munición**: cuando la intensidad supere 0.8 durante más de 3 segundos seguidos, emite `solicitar_recursos("municion", posicion)` una sola vez por pico. La escena de prueba debe imprimir el evento y no repetirlo dentro del mismo pico.

**Criterio de aceptación**: en una sesión donde se mantiene daño alto, la consola muestra exactamente **una** entrega de munición por cada entrada en estado `PICO`, y ninguna durante `DESCANSO`; el código del enemigo permanece sin cambios.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El Director genera enemigos sin parar | No decrementas `_enemigos_vivos`; llama a `notificar_muerte_enemigo()` al morir cada uno |
| `Director` es `null` al acceder | No lo registraste en Autoload o escribiste mal el nombre; revisa Configuración del proyecto |
| La intensidad nunca baja | `tiempo_desde_combate` no avanza; asegúrate de tener `_process` en `EstadoJugador` |
| El pacing salta de descanso a pico al instante | Falta el umbral de histéresis; usa niveles distintos para subir (0.75) y bajar (0.35) |
| Oleadas gigantes de golpe | `poblacion_max` demasiado alto o `_presupuesto()` ignora la intensidad; verifica el `margen` |
| Las señales no llegan | Conectaste antes de que el Autoload existiera; conéctalas en `_ready()` de la escena |

## ❓ Preguntas frecuentes

**¿El Director sustituye a la IA de cada enemigo?**
No. El Director decide *ritmo y población*; cada enemigo mantiene su propia FSM o behavior tree para moverse y atacar.

**¿Por qué usar histéresis (dos umbrales) en el pacing?**
Para evitar el parpadeo entre estados cuando la intensidad oscila alrededor de un único valor. Subir con 0.75 y bajar con 0.35 estabiliza las transiciones.

**¿DDA es lo mismo que un selector de dificultad?**
No. El selector fija parámetros al empezar; el DDA los ajusta *en vivo* según cómo le va al jugador, de forma casi invisible.

**¿Dónde defino la intensidad "real"?**
Depende de tu juego. Vida y recencia de combate son un buen inicio; puedes sumar munición baja, distancia al objetivo o tiempo bajo fuego.

## 🔗 Referencias

- [Singletons (Autoload) — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)
- [Clase Timer — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_timer.html)
- [Señales — Godot Docs](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)
- [The AI Systems of Left 4 Dead (Valve, AIIDE 2009)](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)

## ⬅️ Clase anterior

[Clase 119 - IA de combate: cobertura, flanqueo y coordinación](../119-ia-de-combate-cobertura-flanqueo-y-coordinacion/README.md)

## ➡️ Siguiente clase

[Clase 121 - IA para NPCs y vida ambiental](../121-ia-para-npcs-y-vida-ambiental/README.md)
