# Clase 144 — Mover jugadores en red: replicación de estado

> Parte: **7 — Multijugador y networking** · Fuente: *Documentación de networking de Godot 4 (High-level Multiplayer) + Glenn Fiedler, "Gaffer On Games"*
> ⏱️ Duración estimada: **50 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Conseguir que varios jugadores se vean moverse en una misma escena de red. Vas a dar a cada avatar la **autoridad** de su cliente dueño, replicar su posición hacia los demás y entender por qué, si envías el estado "en crudo", los jugadores remotos se ven a saltos (el "teletransporte"). Trabajarás con `MultiplayerSynchronizer` y también con un RPC de estado manual para que veas ambos caminos y sepas cuándo conviene cada uno.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Asignar autoridad de red a cada avatar con `set_multiplayer_authority()` y comprobarla con `is_multiplayer_authority()`.
- Replicar la posición de un jugador usando `MultiplayerSynchronizer`.
- Enviar estado manualmente con un `@rpc` no fiable y entender su coste.
- Explicar por qué el movimiento remoto se ve "a saltos" sin suavizado.
- Probar el resultado abriendo dos instancias del juego y viéndolas sincronizadas.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Autoridad por avatar | Cada cliente solo debe mover su propio jugador |
| 2 | Enviar input vs enviar estado | Define quién simula y qué viaja por la red |
| 3 | `MultiplayerSynchronizer` | Replica propiedades sin escribir RPCs a mano |
| 4 | RPC de estado con `unreliable` | La posición se manda muchas veces; perder una no importa |
| 5 | Tick fijo en `_physics_process` | Un ritmo estable evita jitter al enviar |
| 6 | El problema del teletransporte | Sin interpolar, el remoto salta entre paquetes |
| 7 | `get_unique_id` e `is_server` | Identificar quién eres en la sesión |

## 📖 Definiciones y características

- **Autoridad de red (multiplayer authority):** el peer que "manda" sobre un nodo. Solo él decide su estado; los demás lo reciben. Se fija con `set_multiplayer_authority(id)`.
- **Replicación de estado:** enviar el resultado de la simulación (posición, rotación) en lugar de la entrada que lo produjo.
- **`MultiplayerSynchronizer`:** nodo que replica automáticamente las propiedades que le configures desde la autoridad hacia el resto.
- **Reliable vs unreliable:** un canal fiable reintenta y ordena; uno no fiable es más rápido y se usa para datos que se repiten cada tick.
- **Tick fijo:** usar `_physics_process(delta)` como reloj estable (por defecto 60 Hz) para simular y enviar a ritmo constante.
- **Teletransporte (snapping):** salto visual del avatar remoto porque se coloca de golpe en cada paquete recibido, sin transición.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x (idealmente 4.2+). Vamos a crear una escena de jugador con un `CharacterBody2D`, y una escena principal que arranque como servidor o cliente. Para probar de verdad el multijugador, ejecuta **dos instancias** del proyecto: en Godot ve a *Debug → Run Multiple Instances → Run 2 Instances*. Repasa la [guía de high-level multiplayer de Godot](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html) y el nodo [`MultiplayerSynchronizer`](https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html). Ten a mano un puerto libre (usaremos `9999`).

## 🧪 Laboratorio guiado

**1. Arranque de red.** Crea `Main.gd` en un nodo raíz `Node2D` con un `MultiplayerSpawner` que apunte a la escena `Player.tscn`.

```gdscript
extends Node2D

const PUERTO := 9999
const PLAYER_SCENE := preload("res://Player.tscn")

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_conectado)
    multiplayer.peer_disconnected.connect(_on_peer_desconectado)

func alojar() -> void:
    var peer := ENetMultiplayerPeer.new()
    peer.create_server(PUERTO)
    multiplayer.multiplayer_peer = peer
    _crear_avatar(1) # el servidor también juega

func unirse(ip: String = "127.0.0.1") -> void:
    var peer := ENetMultiplayerPeer.new()
    peer.create_client(ip, PUERTO)
    multiplayer.multiplayer_peer = peer

func _on_peer_conectado(id: int) -> void:
    if multiplayer.is_server():
        _crear_avatar(id)

func _on_peer_desconectado(id: int) -> void:
    var nodo := get_node_or_null(str(id))
    if nodo:
        nodo.queue_free()

func _crear_avatar(id: int) -> void:
    var avatar := PLAYER_SCENE.instantiate()
    avatar.name = str(id) # el nombre debe coincidir en todos los peers
    add_child(avatar)
```

**2. El avatar y su autoridad.** En `Player.gd`, la clave es que cada avatar pertenece al peer cuyo id es su nombre.

```gdscript
extends CharacterBody2D

const VELOCIDAD := 220.0

func _ready() -> void:
    set_multiplayer_authority(name.to_int())

func _physics_process(_delta: float) -> void:
    if not is_multiplayer_authority():
        return # los remotos no se auto-mueven; su estado llega por la red
    var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    velocity = dir * VELOCIDAD
    move_and_slide()
```

**3. Replicar con `MultiplayerSynchronizer`.** Añade un nodo `MultiplayerSynchronizer` como hijo del avatar. En su *Replication config* agrega la propiedad `position`. Con eso, la posición viaja desde la autoridad al resto sin más código. Ejecuta dos instancias, aloja en una y únete en la otra: al mover un avatar, se mueve en ambas ventanas.

**4. Alternativa: RPC de estado manual.** Para entender qué hace el synchronizer por dentro, replica tú la posición con un RPC no fiable enviado cada tick.

```gdscript
@rpc("authority", "call_remote", "unreliable")
func recibir_estado(pos: Vector2) -> void:
    position = pos # llega de golpe: aquí nace el "teletransporte"

func _physics_process(_delta: float) -> void:
    if is_multiplayer_authority():
        var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
        velocity = dir * VELOCIDAD
        move_and_slide()
        recibir_estado.rpc(position) # difunde a todos los peers
```

**5. Observa el problema.** Baja el ritmo de envío (manda `recibir_estado.rpc()` solo 1 de cada 6 físicas) y verás el avatar remoto dar saltos. Ese es el motivo de las clases 145 y 146: predicción e interpolación. Por ahora, quédate con que **replicar posición funciona, pero no basta para verse fluido**.

## ✍️ Ejercicios

1. Añade la propiedad `rotation` al `MultiplayerSynchronizer` y haz que el avatar mire hacia donde se mueve.
2. Muestra sobre cada avatar una etiqueta con su `get_multiplayer_authority()` para ver de quién es.
3. Cambia el RPC de `unreliable` a `reliable` y describe qué notas en el movimiento y por qué.
4. Impide que un cliente mueva un avatar que no es suyo (verifica la autoridad antes de leer input).
5. Registra con `Time.get_ticks_msec()` cada cuántos ms llega un paquete de estado.
6. Haz que al desconectarse un peer, su avatar desaparezca en todas las instancias (ya iniciado en el lab).

## 📝 Reto verificable

Construye una sala donde 3 avatares (servidor + 2 clientes) se muevan simultáneamente. Cada cliente controla solo el suyo, la posición se replica con `MultiplayerSynchronizer`, y al desconectar un cliente su avatar se elimina en el resto.

**Criterio de aceptación**: con dos instancias corriendo, mover un avatar en una ventana se refleja en la otra en menos de ~100 ms percibidos; un cliente no puede mover el avatar ajeno; cerrar una instancia borra su avatar en la que queda.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El avatar remoto no se mueve | Falta `set_multiplayer_authority()` o la propiedad no está en el synchronizer. Revisa el *Replication config* |
| Todos mueven el mismo avatar | No compruebas `is_multiplayer_authority()` antes de leer input |
| "Node not found" al replicar | Los nombres de nodo difieren entre peers; asigna `avatar.name = str(id)` igual en todos |
| Movimiento a saltos | Envías estado en crudo sin interpolar; es esperado, se resuelve en la clase 146 |
| Nada se conecta | Puerto ocupado o firewall; cambia el puerto y confirma `create_server`/`create_client` sin error |

## ❓ Preguntas frecuentes

**¿Envío el input o el estado?** Aquí enviamos estado (posición). Es simple y directo, pero permite trampas y no predice. En la clase 148 pasaremos a enviar intención con servidor autoritativo.

**¿`MultiplayerSynchronizer` o RPC manual?** El synchronizer es cómodo y suficiente para muchos juegos. El RPC manual da control fino (qué, cuándo, con qué fiabilidad). Empieza por el synchronizer.

**¿Por qué `unreliable` para la posición?** Porque la mandas muchas veces por segundo; perder un paquete no importa, ya llega el siguiente, y evitas el coste de reintentos.

**¿El servidor también es jugador?** En este esquema sí (id 1). Es el modelo "host". Un servidor dedicado no tendría avatar propio.

## 🔗 Referencias

- Godot Docs — High-level multiplayer: <https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html>
- Godot Docs — MultiplayerSynchronizer: <https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html>
- Godot Docs — ENetMultiplayerPeer: <https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html>
- Gaffer On Games — Networked Physics: <https://gafferongames.com/post/networked_physics_2004/>

## ➡️ Siguiente clase

[Clase 145 - Predicción del cliente y reconciliación](../145-prediccion-del-cliente-y-reconciliacion/README.md)
