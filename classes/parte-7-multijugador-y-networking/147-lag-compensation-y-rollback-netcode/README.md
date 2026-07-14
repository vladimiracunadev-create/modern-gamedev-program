# Clase 147 — Lag compensation y rollback netcode

> Parte: **7 — Multijugador y networking** · Fuente: *Valve, "Latency Compensating Methods" (Yahn Bernier, GDC) + documentación de GGPO / rollback*
> ⏱️ Duración estimada: **55 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Resolver la injusticia que genera la latencia en dos escenarios clásicos. En shooters, la **lag compensation**: rebobinar el mundo al instante en que el cliente disparó para validar el impacto sobre lo que él realmente veía. En juegos de pelea, el **rollback netcode**: guardar estados, y al llegar un input remoto tardío, rebobinar y **re-simular** los ticks afectados. Ambos comparten idea: guardar historia y volver atrás. Verás por qué el **determinismo** es la base del rollback.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar por qué sin lag compensation el jugador con ping alto "falla" tiros que veía acertados.
- Mantener un historial de posiciones pasadas por entidad para rebobinar el mundo.
- Validar un disparo en el tiempo del cliente (rewind → comprobar hit → restaurar).
- Describir el ciclo del rollback netcode: guardar estado, detectar input tardío, re-simular.
- Justificar por qué el rollback exige simulación determinista.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Injusticia por latencia | Con ping alto disparas a fantasmas del pasado |
| 2 | Historial del mundo | Guardar posiciones pasadas permite rebobinar |
| 3 | Rewind para hit-detection | Validar el tiro en lo que el cliente veía |
| 4 | Restaurar el presente | Tras validar, el mundo vuelve a "ahora" |
| 5 | Rollback netcode | Re-simular ticks al llegar inputs tardíos |
| 6 | Guardado y re-simulación | El coste real del rollback está aquí |
| 7 | Determinismo | Misma entrada + mismo estado = mismo resultado |

## 📖 Definiciones y características

- **Lag compensation:** técnica del servidor para rebobinar el estado de las entidades al instante que el cliente vio, y validar acciones (disparos) sobre ese estado.
- **Historial (snapshot history):** buffer circular de posiciones/estados pasados por entidad, indexado por tiempo o tick.
- **Rewind & restore:** colocar temporalmente las entidades en su pasado, comprobar el hit, y devolverlas al presente.
- **Rollback netcode:** esquema (típico de fighting games) que predice inputs remotos y, al recibir el input real, rebobina al tick correcto y re-simula hasta el presente.
- **Determinismo:** propiedad de que la simulación produzca exactamente el mismo resultado dados el mismo estado inicial e inputs; imprescindible para el rollback.
- **Ventana de compensación:** límite máximo de tiempo hacia atrás que el servidor acepta rebobinar (evita abusos con ping falso alto).

## 🧰 Herramientas y preparación

Godot 4.x. El servidor mantiene, por cada avatar, un historial de posiciones con marca de tick/tiempo. Para lag compensation trabajamos en el servidor; para rollback ilustramos el ciclo con pseudocódigo GDScript sobre una simulación determinista (usa enteros o pasos fijos, evita floats acumulativos donde puedas). Necesitas dos instancias para el disparo, y entender bien `_physics_process` como tick fijo. Revisa el paper de Valve "Latency Compensating Methods" y la introducción a rollback de GGPO.

## 🧪 Laboratorio guiado

**1. El servidor guarda historial por avatar.** En cada tick físico, el servidor archiva la posición con su tick.

```gdscript
# En el nodo servidor que gestiona a los jugadores
const MAX_HISTORIAL := 64 # ~1 s a 60 Hz
var historial: Dictionary = {} # id_jugador -> Array de {tick, pos}
var tick_servidor := 0

func _physics_process(_delta: float) -> void:
    if not multiplayer.is_server():
        return
    tick_servidor += 1
    for jugador in get_tree().get_nodes_in_group("jugadores"):
        var id := jugador.name.to_int()
        var buf: Array = historial.get(id, [])
        buf.append({"tick": tick_servidor, "pos": jugador.position})
        if buf.size() > MAX_HISTORIAL:
            buf.pop_front()
        historial[id] = buf
```

**2. Recuperar el mundo en un tick pasado.** Dada la marca temporal del disparo del cliente, buscamos la posición más cercana en el historial.

```gdscript
func pos_en_tick(id: int, tick_objetivo: int) -> Vector2:
    var buf: Array = historial.get(id, [])
    var mejor := Vector2.ZERO
    var mejor_dif := 1 << 30
    for e in buf:
        var dif: int = abs(e["tick"] - tick_objetivo)
        if dif < mejor_dif:
            mejor_dif = dif
            mejor = e["pos"]
    return mejor
```

**3. Validar el disparo con rewind.** El cliente envía su disparo sellado con el tick en el que disparó. El servidor rebobina a los objetivos, comprueba el impacto y restaura.

```gdscript
const VENTANA_MAX_TICKS := 30 # límite anti-abuso (~0.5 s)
const RADIO_HIT := 24.0

@rpc("any_peer", "call_remote", "reliable")
func disparar(origen: Vector2, dir: Vector2, tick_cliente: int) -> void:
    if not multiplayer.is_server():
        return
    # No permito rebobinar más allá de la ventana
    if tick_servidor - tick_cliente > VENTANA_MAX_TICKS:
        tick_cliente = tick_servidor - VENTANA_MAX_TICKS

    var tirador := multiplayer.get_remote_sender_id()
    for jugador in get_tree().get_nodes_in_group("jugadores"):
        var id := jugador.name.to_int()
        if id == tirador:
            continue
        # Rebobino ESTE objetivo al instante que vio el tirador
        var pos_pasada := pos_en_tick(id, tick_cliente)
        if _rayo_impacta(origen, dir, pos_pasada, RADIO_HIT):
            aplicar_dano.rpc_id(id, 20) # hit validado en el tiempo del cliente
    # No hace falta "restaurar" porque no movimos los nodos:
    # trabajamos con las posiciones del historial, no con los nodos vivos.

func _rayo_impacta(o: Vector2, dir: Vector2, centro: Vector2, radio: float) -> bool:
    var d := dir.normalized()
    var t := (centro - o).dot(d)
    if t < 0.0:
        return false
    var punto := o + d * t
    return punto.distance_to(centro) <= radio
```

> Nota: aquí validamos contra las **posiciones guardadas** en el historial, que es más seguro y barato que mover los nodos reales. Si necesitaras física real (raycast del motor), moverías temporalmente los cuerpos a su pasado y los restaurarías tras el `PhysicsDirectSpaceState2D` query.

**4. El ciclo del rollback (pseudocódigo determinista).** Para fighting games, el cliente predice el input remoto; al llegar el real, si difería, rebobina y re-simula.

```gdscript
# Estado guardado por tick: estados[tick] = snapshot serializable
var estados: Dictionary = {}
var inputs_confirmados: Dictionary = {} # tick -> {local, remoto}

func avanzar_tick(t: int) -> void:
    estados[t] = capturar_estado()       # guardo ANTES de simular
    var ent := inputs_confirmados.get(t, {"local": leer_local(), "remoto": predecir_remoto(t)})
    simular(ent["local"], ent["remoto"]) # paso determinista

func llega_input_remoto(t: int, real) -> void:
    var previsto = inputs_confirmados.get(t, {}).get("remoto", null)
    inputs_confirmados[t] = {"local": estados_input_local(t), "remoto": real}
    if previsto != real:
        # ROLLBACK: restauro el estado del tick t y re-simulo hasta ahora
        restaurar_estado(estados[t])
        for tt in range(t, tick_actual + 1):
            avanzar_tick(tt) # re-simulación con el input correcto
```

**5. Compruébalo.** Para la lag compensation, con dos instancias y latencia simulada, dispara a un objetivo que se mueve: sin compensación fallarías (el objetivo ya no está donde lo veías); con `pos_en_tick` el hit se valida donde el tirador lo veía. Para el rollback, imprime cuándo ocurre un rollback y cuántos ticks re-simula.

## ✍️ Ejercicios

1. Dibuja fantasmas semitransparentes de las posiciones históricas de un objetivo para "ver" el rewind.
2. Haz configurable `VENTANA_MAX_TICKS` y demuestra que un tick de disparo demasiado viejo se recorta.
3. Registra cuántos ticks re-simula cada rollback y su coste en ms con `Time.get_ticks_msec()`.
4. Rompe el determinismo a propósito (usa `randf()` en `simular`) y observa cómo el rollback diverge.
5. Añade un contador de hits validados vs disparados para medir el efecto de la compensación.
6. Interpola el historial (en vez de tomar el tick más cercano) para un rewind más preciso.

## 📝 Reto verificable

Implementa lag compensation para un disparo: el servidor guarda el historial de posiciones, recibe el disparo sellado con el tick del cliente, rebobina a los objetivos y valida el impacto, con una ventana máxima anti-abuso.

**Criterio de aceptación**: con latencia simulada, disparar a un objetivo en movimiento acierta cuando el tirador lo veía sobre la mira, y falla si apuntaba a vacío; un tick de disparo más antiguo que la ventana se recorta al límite; los hits se resuelven en el servidor, nunca en el cliente.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Los tiros fallan pese a apuntar bien | No rebobinas: validas contra la posición actual, no la que veía el cliente |
| Jugadores reciben daño "imposible" | Ventana de compensación sin límite; añade `VENTANA_MAX_TICKS` |
| El rollback produce estados distintos cada vez | La simulación no es determinista (floats/aleatoriedad). Usa pasos fijos y semillas controladas |
| Caídas de rendimiento con rollback | Re-simulas demasiados ticks; limita la profundidad de rollback |
| Historial vacío al validar | Guardas el historial en el cliente en vez del servidor, o no agrupas los avatares en "jugadores" |

## ❓ Preguntas frecuentes

**¿Lag compensation y rollback son lo mismo?** Comparten la idea de rebobinar. La compensación es del servidor para validar acciones (shooters); el rollback re-simula toda la partida al llegar inputs tardíos (fighting games).

**¿No es injusto para el que recibe el disparo?** Es un compromiso: se favorece al tirador ("favor the shooter"). La ventana máxima acota el abuso. Casi todos los shooters lo aceptan.

**¿Por qué el rollback necesita determinismo?** Porque re-simula los mismos ticks; si el mismo input diera resultados distintos, cliente y servidor divergirían irremediablemente.

**¿Puedo hacer rollback en Godot?** Sí, pero requiere serializar y restaurar todo el estado de juego cada tick y una simulación estrictamente determinista, lo que es exigente. Para muchos juegos, predicción + interpolación bastan.

## 🔗 Referencias

- Valve — Latency Compensating Methods (Yahn Bernier): <https://developer.valvesoftware.com/wiki/Latency_Compensating_Methods_in_Client/Server_In-game_Protocol_Design_and_Optimization>
- GGPO — Rollback networking (concepto): <https://www.ggpo.net/>
- Gaffer On Games — Deterministic Lockstep: <https://gafferongames.com/post/deterministic_lockstep/>
- Godot Docs — High-level multiplayer: <https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html>

## ➡️ Siguiente clase

[Clase 148 - Servidor autoritativo y anti-cheat básico](../148-servidor-autoritativo-y-anti-cheat-basico/README.md)
