# Clase 139 — Modelos de arquitectura: P2P, cliente-servidor y autoritativo

> Parte: **7 — Multijugador y networking** · Fuente: *Glazer & Madhav, "Multiplayer Game Programming" + charlas de GDC sobre netcode (Valve, Riot)*
> ⏱️ Duración estimada: **50 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Elegir con criterio la arquitectura de red de tu juego antes de escribir la lógica de juego, porque ese cambio es carísimo a mitad de proyecto. Al terminar distinguirás **P2P (con lockstep)** de **cliente-servidor**, entenderás la diferencia crucial entre un **servidor autoritativo** y uno que **confía en el cliente**, conocerás la **host-migración** y montarás el **esqueleto de un servidor autoritativo** en Godot 4 donde el servidor decide y los clientes solo envían input.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Comparar P2P y cliente-servidor en latencia, seguridad, coste y escalabilidad.
- Explicar por qué un servidor autoritativo es la base para prevenir trampas.
- Describir el lockstep determinista y sus riesgos (desincronización).
- Definir qué es la host-migración y cuándo es necesaria.
- Implementar el esqueleto de un servidor autoritativo que procesa input de clientes.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | P2P y topología de malla | Modelo simple pero frágil y difícil de asegurar |
| 2 | Lockstep determinista | Base de RTS; todo cliente simula lo mismo |
| 3 | Cliente-servidor (estrella) | Un árbitro central simplifica estado y seguridad |
| 4 | Servidor autoritativo | El servidor es la única fuente de verdad |
| 5 | Cliente confiado vs validado | Diferencia entre juego trampeable y seguro |
| 6 | Host (listen server) vs dedicado | Quién hace de servidor y sus implicaciones |
| 7 | Host-migración | Qué ocurre si el anfitrión se cae |
| 8 | Seguridad y superficie de ataque | Nunca confíes en datos del cliente |

## 📖 Definiciones y características

- **P2P (peer-to-peer)**: cada jugador se conecta con todos los demás sin servidor central. Clave: simple para 2 jugadores, pero el tráfico crece con el cuadrado de peers.
- **Lockstep**: todos simulan el mismo estado ejecutando los mismos inputs en el mismo orden. Clave: exige determinismo total o los clientes divergen.
- **Cliente-servidor**: los clientes hablan solo con un servidor que coordina el estado. Clave: topología en estrella, fácil de razonar y asegurar.
- **Servidor autoritativo**: el servidor calcula el estado real; el cliente solo sugiere acciones. Clave: es imposible confiar en un cliente que puedes modificar.
- **Cliente confiado**: el servidor acepta lo que el cliente afirma (posición, daño). Clave: cómodo de programar, trivial de trampear.
- **Listen server (host)**: un jugador hace de servidor y de cliente a la vez. Clave: barato, pero ese jugador tiene ventaja de latencia cero.
- **Servidor dedicado**: proceso servidor sin jugador local, normalmente headless. Clave: justo para todos y necesario para competitivo.
- **Host-migración**: transferir el rol de servidor a otro peer si el anfitrión cae. Clave: compleja; requiere que el nuevo host tenga el estado.

## 🧰 Herramientas y preparación

Con **Godot 4.x** basta. Vamos a esbozar arquitecturas y luego montar un esqueleto autoritativo probado con **dos instancias** en `localhost`. Ten a la vista la [guía de multijugador de alto nivel de Godot](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html) y, como lectura de arquitectura, la charla clásica de [Source Multiplayer Networking](https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking). Antes de programar, dibuja en papel las tres topologías (malla P2P, estrella cliente-servidor y autoritativo con flechas de input/estado): ese diagrama guiará tu código.

## 🧪 Laboratorio guiado

Montaremos el **esqueleto de un servidor autoritativo**. Regla de oro: el cliente **no mueve nada por su cuenta**; solo manda su intención de movimiento al servidor, y el servidor calcula la posición real y la reparte. Crea `Autoritativo.tscn` con un `Node` raíz `Juego`.

```gdscript
extends Node

const PUERTO := 9998
const VELOCIDAD := 200.0

# El servidor guarda el estado de cada jugador: id -> posición.
var _estado: Dictionary = {}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_conectado)
	multiplayer.peer_disconnected.connect(_on_peer_desconectado)
	if "--server" in OS.get_cmdline_args():
		_iniciar_servidor()
	else:
		_iniciar_cliente()

func _iniciar_servidor() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(PUERTO, 8)
	multiplayer.multiplayer_peer = peer
	print("[SERVIDOR] Autoritativo listo.")

func _iniciar_cliente() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", PUERTO)
	multiplayer.multiplayer_peer = peer
	print("[CLIENTE] Conectando...")

func _on_peer_conectado(id: int) -> void:
	if multiplayer.is_server():
		_estado[id] = Vector2.ZERO
		print("[SERVIDOR] Jugador %d entra. Estado inicial (0,0)." % id)

func _on_peer_desconectado(id: int) -> void:
	if multiplayer.is_server():
		_estado.erase(id)
```

Ahora el flujo autoritativo. El cliente lee su teclado y **solo envía el vector de input** al servidor por RPC. El servidor valida, integra la posición y difunde el estado a todos.

```gdscript
func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() and multiplayer.multiplayer_peer != null:
		# CLIENTE: mando mi intención, no mi posición.
		var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if input != Vector2.ZERO:
			enviar_input.rpc_id(1, input)

	if multiplayer.is_server():
		# SERVIDOR: reparte el estado ya calculado.
		difundir_estado.rpc(_estado)

@rpc("any_peer", "call_remote", "reliable")
func enviar_input(direccion: Vector2) -> void:
	# Se ejecuta SOLO en el servidor.
	var id := multiplayer.get_remote_sender_id()
	if not _estado.has(id):
		return
	# Validación: normalizamos para que nadie "acelere" mandando vectores gigantes.
	direccion = direccion.limit_length(1.0)
	_estado[id] += direccion * VELOCIDAD * get_physics_process_delta_time()

@rpc("authority", "call_remote", "unreliable_ordered")
func difundir_estado(estado: Dictionary) -> void:
	# Se ejecuta en los clientes: aquí actualizarías sprites por id.
	for id in estado:
		print("Jugador %d -> %s" % [id, estado[id]])
```

**Cómo probarlo con dos instancias:** lanza una con `--server` y otra como cliente. Al pulsar las flechas en el cliente verás cómo el **servidor** es quien recalcula y difunde la posición (los prints de `difundir_estado` aparecen en el cliente con coordenadas que crecen). Nota clave: si un cliente intentara "teletransportarse", no podría, porque nunca envía posición, solo dirección, y el servidor la limita.

## ✍️ Ejercicios

1. Sustituye los `print` por `Sprite2D` reales instanciados por id para *ver* moverse a cada jugador.
2. Añade validación de velocidad máxima: si un cliente enviara input más rápido que el tick, ignóralo.
3. Convierte el `difundir_estado` para que solo mande jugadores que cambiaron de posición.
4. Añade un modo "cliente confiado" (el cliente manda su posición) y demuestra en un comentario cómo se trampea.
5. Implementa una detección simple de anfitrión caído: si `server_disconnected` se dispara, muestra "El host se cayó".
6. Dibuja el diagrama de secuencia input→servidor→difusión y comenta cada flecha en el código.

## 📝 Reto verificable

Extiende el esqueleto a un mini "captura la bandera" de posiciones: dos jugadores mueven su punto por el servidor autoritativo, y cuando dos puntos están a menos de 20 px el servidor declara "colisión" y lo anuncia a todos por RPC. Toda la lógica de distancia debe correr en el servidor.

**Criterio de aceptación**: con 1 servidor + 2 clientes, mover ambos puntos hasta juntarlos hace que **los dos clientes** impriman "¡Colisión!" simultáneamente; ningún cálculo de colisión ocurre en el cliente.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El cliente se mueve solo pero el servidor no lo sabe | Estás moviendo en el cliente; en autoritativo el cliente solo envía input |
| Todos ven posiciones distintas | La lógica de simulación corre en varios sitios; céntrala en el servidor |
| `enviar_input` se ejecuta en el cliente | Falta comprobar `multiplayer.is_server()` o usaste `rpc()` en vez de `rpc_id(1, ...)` |
| El juego es trampeable | Estás confiando datos del cliente; valida y recalcula siempre en el servidor |
| Nadie se mueve al soltar teclas | Solo envías input si `input != Vector2.ZERO`; es correcto, pero recuerda que el estado no se resetea solo |

## ❓ Preguntas frecuentes

- **¿P2P está muerto?** No: para 2 jugadores cooperativos o para RTS con lockstep sigue siendo válido; simplemente no escala ni es fácil de asegurar.
- **¿Un listen server es autoritativo?** Puede serlo: el jugador-host ejecuta el código de servidor. Es autoritativo, pero con la ventaja injusta de latencia cero para el host.
- **¿Necesito host-migración?** Solo si no tienes servidor dedicado y quieres que la partida sobreviva a la caída del anfitrión; es compleja, así que evalúa si de verdad la necesitas.
- **¿Puedo empezar con cliente confiado y "asegurar luego"?** Es mala idea: reescribir a autoritativo toca casi todo. Diseña autoritativo desde el inicio si habrá competitividad.

## 🔗 Referencias

- [High-level multiplayer (Godot 4)](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)
- Valve: [Source Multiplayer Networking](https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking)
- Gabriel Gambetta: [Fast-Paced Multiplayer](https://www.gabrielgambetta.com/client-server-game-architecture.html)
- Glenn Fiedler: [What every programmer needs to know about networking](https://gafferongames.com/post/what_every_programmer_needs_to_know_about_game_networking/)

## ➡️ Siguiente clase

[Clase 140 - El multijugador de alto nivel de Godot (MultiplayerAPI)](../140-el-multijugador-de-alto-nivel-de-godot-multiplayerapi/README.md)
