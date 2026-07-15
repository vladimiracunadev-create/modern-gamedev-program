# Clase 148 — Servidor autoritativo y anti-cheat básico

> Parte: **7 — Multijugador y networking** · Fuente: *Glenn Fiedler, "Gaffer On Games" (What every programmer needs to know about game networking) + guías de seguridad de servidores autoritativos*
> ⏱️ Duración estimada: **50 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Interiorizar la regla de oro del multijugador competitivo: **nunca confíes en el cliente**. El cliente solo envía **intención** (quiero moverme en esta dirección, quiero recoger esto, quiero disparar); es el **servidor** quien decide y valida el resultado. Moverás la lógica de daño y recogida al servidor, y añadirás validaciones (rango, velocidad máxima, sanity checks) que rechacen acciones imposibles. Verás en la práctica por qué dejar decidir al cliente abre la puerta a las trampas.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar por qué el cliente solo debe enviar intención y el servidor validar todo.
- Mover la lógica de daño y de recogida de ítems al servidor.
- Validar movimiento con límites de velocidad y distancia por tick.
- Añadir sanity checks (rango de acción, cooldowns) para rechazar acciones imposibles.
- Demostrar con un ejemplo por qué un cliente manipulado no rompe el estado del juego.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Cliente = intención | El cliente propone; el servidor dispone |
| 2 | Servidor autoritativo | Única fuente de verdad del estado |
| 3 | Validación de velocidad | Detecta speedhacks y teletransportes |
| 4 | Validación de rango | Impide recoger/atacar desde lejos |
| 5 | Sanity checks y cooldowns | Rechazan acciones imposibles o repetidas |
| 6 | `get_remote_sender_id` | Saber quién pide para autorizar por identidad |
| 7 | Por qué no confiar en el cliente | Cualquier binario puede ser manipulado |

## 📖 Definiciones y características

- **Servidor autoritativo:** el servidor mantiene el estado oficial y valida cada acción; los clientes solo lo reflejan.
- **Intención (input/comando):** lo que el cliente quiere hacer, no el resultado ya calculado.
- **Validación de rango:** comprobar que el objetivo de una acción está a una distancia plausible del actor.
- **Validación de velocidad:** limitar cuánto puede moverse un avatar por tick para descartar movimientos imposibles.
- **Sanity check:** comprobación de coherencia (valores dentro de rango, cooldown respetado, recurso existente) antes de aplicar una acción.
- **Autorización por identidad:** usar `multiplayer.get_remote_sender_id()` para saber quién envía y permitir solo lo que le corresponde.

## 🧰 Herramientas y preparación

Godot 4.x, dos instancias. Partimos de avatares en red con predicción. La diferencia de esta clase es **dónde vive la lógica**: los RPCs de acción se ejecutan solo si `multiplayer.is_server()`. Necesitas un ítem recogible y un sistema de vida. Ten presente que en un servidor real las constantes de validación (velocidad máxima, alcance) se calibran con el diseño del juego. Lectura base: el artículo de Glenn Fiedler sobre servidor autoritativo e input.

## 🧪 Laboratorio guiado

**1. El cliente envía intención, no estado.** En vez de mandar su posición ya calculada, el cliente manda su dirección de input; el servidor simula.

```gdscript
# CLIENTE
func _physics_process(_delta: float) -> void:
    if not is_multiplayer_authority():
        return
    var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    pedir_mover.rpc_id(1, dir) # solo la INTENCIÓN va al servidor
```

**2. El servidor valida y aplica el movimiento.** Rechaza direcciones fuera de rango y limita el desplazamiento por tick (anti speedhack).

```gdscript
# SERVIDOR
const VELOCIDAD := 220.0
const MAX_PASO := 6.0 # px por tick permitidos con margen

@rpc("any_peer", "call_remote", "unreliable_ordered")
func pedir_mover(dir: Vector2) -> void:
    if not multiplayer.is_server():
        return
    var id := multiplayer.get_remote_sender_id()
    # Sanity check: la dirección no puede tener módulo > 1
    if dir.length() > 1.001:
        dir = dir.normalized()
    var delta := 1.0 / Engine.physics_ticks_per_second
    var desplazamiento := dir * VELOCIDAD * delta
    # Anti-teletransporte: nunca más de MAX_PASO por tick
    if desplazamiento.length() > MAX_PASO:
        desplazamiento = desplazamiento.normalized() * MAX_PASO
    position += desplazamiento
    # La posición autoritativa se replica por MultiplayerSynchronizer
```

**3. Recogida de ítems validada en el servidor.** El cliente pide recoger; el servidor comprueba distancia y existencia antes de conceder.

```gdscript
const ALCANCE_RECOGIDA := 48.0

@rpc("any_peer", "call_remote", "reliable")
func pedir_recoger(item_path: NodePath) -> void:
    if not multiplayer.is_server():
        return
    var item := get_node_or_null(item_path)
    if item == null:
        return # ya no existe: la petición llega tarde o es falsa
    var id := multiplayer.get_remote_sender_id()
    var jugador := get_node_or_null(str(id))
    if jugador == null:
        return
    # Validación de rango: no puedes recoger algo lejano
    if jugador.position.distance_to(item.position) > ALCANCE_RECOGIDA:
        push_warning("Recogida rechazada: fuera de rango (peer %d)" % id)
        return
    item.queue_free() # el servidor decide; se replica al resto
    dar_item.rpc_id(id, item.get("tipo"))
```

**4. Daño calculado y validado en el servidor.** El cliente solo declara que dispara; el servidor decide si hay daño (idealmente con la lag compensation de la clase 147) y aplica vida.

```gdscript
const COOLDOWN_DISPARO_MS := 250
var ultimo_disparo: Dictionary = {} # id -> ms

@rpc("any_peer", "call_remote", "reliable")
func pedir_disparar(objetivo_id: int) -> void:
    if not multiplayer.is_server():
        return
    var id := multiplayer.get_remote_sender_id()
    var ahora := Time.get_ticks_msec()
    # Sanity check: respetar cadencia (anti rapid-fire)
    if ahora - int(ultimo_disparo.get(id, -100000)) < COOLDOWN_DISPARO_MS:
        return
    ultimo_disparo[id] = ahora
    var tirador := get_node_or_null(str(id))
    var victima := get_node_or_null(str(objetivo_id))
    if tirador == null or victima == null:
        return
    # Validación de rango de arma
    if tirador.position.distance_to(victima.position) > 600.0:
        return
    victima.vida = max(0, victima.vida - 20)
    actualizar_vida.rpc(objetivo_id, victima.vida) # verdad autoritativa
```

**5. Demuestra por qué el cliente no decide.** Modifica el cliente para que intente moverse a velocidad triple (multiplica `dir` por 3) o recoger un ítem a 500 px. Observa que el servidor **recorta** la velocidad y **rechaza** la recogida: el estado del juego se mantiene íntegro pese al cliente manipulado. Esa es toda la idea.

## ✍️ Ejercicios

1. Registra en el servidor cada acción rechazada con el `peer_id` y el motivo.
2. Añade un límite de vida máxima y valida que la vida nunca suba por encima al curar.
3. Implementa un "presupuesto de movimiento" acumulado por segundo en vez de por tick.
4. Haz que recoger un ítem inexistente (borrado) simplemente se ignore sin error.
5. Añade un cooldown de recogida por jugador y demuéstralo con recogidas rápidas.
6. Marca a un peer como "sospechoso" tras N rechazos y muéstralo en el log del servidor.

## 📝 Reto verificable

Mueve la lógica de daño y de recogida al servidor. El cliente solo envía intención; el servidor valida rango, velocidad y cooldown, y rechaza acciones imposibles. Un cliente manipulado no debe poder moverse a velocidad imposible ni recoger a distancia.

**Criterio de aceptación**: con dos instancias, forzar en el cliente velocidad x3 no acelera el avatar (el servidor lo recorta); una petición de recogida fuera de `ALCANCE_RECOGIDA` se rechaza y se registra; el daño solo se aplica desde el servidor tras pasar rango y cooldown.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El cliente aún "decide" el daño | El RPC aplica efecto sin comprobar `multiplayer.is_server()` |
| Speedhack no detectado | No limitas el desplazamiento por tick; añade `MAX_PASO` |
| Recogidas a distancia | Falta validación de rango antes de conceder el ítem |
| Rapid-fire posible | No hay cooldown por jugador; guarda el último `Time.get_ticks_msec()` por id |
| El servidor confía en la posición del cliente | Recibes posición en vez de intención; envía input y simula en el servidor |

## ❓ Preguntas frecuentes

**¿Validar todo no sobrecarga el servidor?** Las validaciones son baratas (comparaciones de distancia y tiempo). El coste real es aceptable frente a tener un juego tramposeable.

**¿Y la predicción de la clase 145?** Compatible: el cliente predice para sentir respuesta, pero el servidor sigue validando. Si el cliente miente, la reconciliación lo corrige y la validación lo frena.

**¿Debo cifrar los mensajes?** El cifrado ayuda contra sniffing/tampering en tránsito, pero no sustituye la validación: aunque el canal sea seguro, el cliente puede estar modificado.

**¿Dónde pongo las constantes de límite?** En el servidor. Nunca dejes que el cliente envíe sus propios límites de velocidad o alcance; los define y aplica el servidor.

## 🔗 Referencias

- Gaffer On Games — What every programmer needs to know about game networking: <https://gafferongames.com/post/what_every_programmer_needs_to_know_about_game_networking/>
- Valve — Source Multiplayer Networking (server authority): <https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking>
- Godot Docs — RPC y MultiplayerAPI: <https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html>
- Gabriel Gambetta — Client-Server Game Architecture: <https://www.gabrielgambetta.com/client-server-game-architecture.html>

## ⬅️ Clase anterior

[Clase 147 - Lag compensation y rollback netcode](../147-lag-compensation-y-rollback-netcode/README.md)

## ➡️ Siguiente clase

[Clase 149 - Serialización eficiente y ancho de banda](../149-serializacion-eficiente-y-ancho-de-banda/README.md)
