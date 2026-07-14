# Clase 150 — Matchmaking, salas y relay (NAT traversal)

> Parte: **7 — Multijugador y networking** · Fuente: *Documentación de Godot 4 (High-level multiplayer, ENetMultiplayerPeer) + literatura sobre NAT traversal (STUN/TURN, ICE)*
> ⏱️ Duración estimada: **55 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Comprender por qué dos jugadores en redes domésticas casi nunca pueden conectarse "directo" y qué mecanismos resuelven ese problema: **NAT punch-through**, **servidores relay** y un **matchmaker** que empareja jugadores y reparte códigos de sala. Vas a montar un flujo de salas con un pequeño servidor intermediario en Godot 4 que recibe a los clientes, los agrupa por código y los pone a jugar juntos. Al terminar entenderás el mapa completo entre "quiero jugar con un amigo" y "los paquetes llegan".

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar qué es un NAT y por qué impide conexiones entrantes directas entre pares.
- Distinguir entre NAT punch-through, relay (TURN) y conexión directa, y cuándo aplica cada uno.
- Diseñar un flujo de matchmaking basado en códigos de sala y colas por habilidad (skill).
- Implementar en Godot 4 un servidor de salas que empareja dos clientes con `ENetMultiplayerPeer`.
- Reconocer las limitaciones de cada estrategia (Symmetric NAT, coste de ancho de banda del relay).

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es NAT y por qué existe | Explica la escasez de IPv4 y el porqué del bloqueo entrante |
| 2 | Tipos de NAT (cone, symmetric) | Determina si el punch-through es viable o no |
| 3 | NAT punch-through | Permite conexiones P2P sin pagar ancho de banda de servidor |
| 4 | Servidores relay (TURN) | Plan B universal cuando el P2P falla |
| 5 | Matchmaking y colas | Empareja gente por skill, región o modo de juego |
| 6 | Códigos de sala | UX simple para jugar con amigos sin exponer IPs |
| 7 | Autoridad del servidor de salas | Centraliza el estado del lobby antes del gameplay |
| 8 | Trade-offs de cada estrategia | No hay bala de plata: coste vs. compatibilidad |

## 📖 Definiciones y características

- **NAT (Network Address Translation)**: el router traduce las IP privadas de tu LAN a una IP pública única. Clave: bloquea conexiones entrantes no solicitadas, que es justo lo que necesita un peer que quiere recibir.
- **Full-cone NAT**: una vez abierto un puerto saliente, cualquiera puede entrar por él. Clave: es el caso amable para punch-through.
- **Symmetric NAT**: asigna un puerto distinto por cada destino. Clave: rompe el punch-through porque el puerto observado no sirve para un tercero.
- **NAT punch-through**: técnica donde ambos peers envían paquetes simultáneos usando un servidor que les revela sus direcciones públicas (rol de STUN). Clave: crea el agujero en ambos NAT a la vez.
- **Relay / TURN**: servidor intermedio que reenvía todos los paquetes entre peers cuando el P2P es imposible. Clave: siempre funciona, pero paga ancho de banda por cada partida.
- **Matchmaker**: servicio que agrupa jugadores según criterios (skill, latencia, modo) y les entrega una sala. Clave: decide *con quién* juegas antes de decidir *cómo* conectas.
- **Código de sala**: cadena corta (`ABCD`) que identifica una partida privada. Clave: reemplaza compartir IPs, más seguro y usable.
- **Cola por skill (MMR)**: lista ordenada de jugadores esperando; el matchmaker empareja por rating cercano. Clave: partidas equilibradas retienen jugadores.

## 🧰 Herramientas y preparación

Trabajarás con **Godot 4.x** y su API de alto nivel de multijugador (`ENetMultiplayerPeer`, `multiplayer`, `@rpc`). Para el laboratorio no necesitas infraestructura externa: montaremos un **servidor de salas** propio en Godot que hace de matchmaker y de punto de encuentro. En producción esta pieza suele delegarse a un backend gestionado —lo verás en la Clase 152— como **Nakama** de Heroic Labs (<https://heroiclabs.com/docs/>) o los lobbies de **Steam** vía **GodotSteam** (<https://godotsteam.com/>). Para entender la teoría de NAT traversal, consulta la guía de red de alto nivel de Godot (<https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html>). Crea una carpeta `sala/` con dos escenas: `Servidor.tscn` (nodo raíz con `servidor_salas.gd`) y `Cliente.tscn` (con `cliente_salas.gd`).

## 🧪 Laboratorio guiado

Vamos a construir un **servidor de salas** que escucha, agrupa clientes por código y les avisa cuándo la sala está lista. Es la versión mínima y observable de un matchmaker con relay lógico (el servidor reenvía mensajes de lobby).

**Paso 1 — Servidor de salas.** Escucha con ENet y mantiene un diccionario `codigo → [peers]`.

```gdscript
# servidor_salas.gd — Autoload o raíz de Servidor.tscn
extends Node

const PUERTO := 8910
const MAX_CLIENTES := 32

var _salas: Dictionary = {}      # codigo:String -> Array[int] (peer ids)
var _peer_a_sala: Dictionary = {} # peer_id:int -> codigo:String

func _ready() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PUERTO, MAX_CLIENTES)
	if err != OK:
		push_error("No se pudo crear el servidor: %s" % err)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_conectado)
	multiplayer.peer_disconnected.connect(_on_peer_desconectado)
	print("Servidor de salas escuchando en el puerto ", PUERTO)

func _on_peer_conectado(id: int) -> void:
	print("Cliente conectado: ", id)

func _on_peer_desconectado(id: int) -> void:
	var codigo: String = _peer_a_sala.get(id, "")
	if codigo != "" and _salas.has(codigo):
		_salas[codigo].erase(id)
	_peer_a_sala.erase(id)
```

**Paso 2 — Unirse a una sala por código.** El cliente pide entrar; el servidor decide y responde. Fíjate en `@rpc("any_peer")`: la petición viaja del cliente al servidor.

```gdscript
# En servidor_salas.gd
@rpc("any_peer", "call_remote", "reliable")
func pedir_sala(codigo: String) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not _salas.has(codigo):
		_salas[codigo] = []
	if _salas[codigo].size() >= 2:
		responder_estado.rpc_id(id, "LLENA")
		return
	_salas[codigo].append(id)
	_peer_a_sala[id] = codigo
	responder_estado.rpc_id(id, "EN_SALA")
	if _salas[codigo].size() == 2:
		# Sala lista: avisa a ambos con la lista de compañeros.
		for p in _salas[codigo]:
			var otros := _salas[codigo].filter(func(x): return x != p)
			sala_lista.rpc_id(p, otros)

@rpc("authority", "call_remote", "reliable")
func responder_estado(_estado: String) -> void:
	pass  # implementado en el cliente

@rpc("authority", "call_remote", "reliable")
func sala_lista(_companeros: Array) -> void:
	pass  # implementado en el cliente
```

**Paso 3 — Cliente de salas.** Se conecta y solicita un código. Los métodos RPC de respuesta viven aquí con la misma firma.

```gdscript
# cliente_salas.gd — raíz de Cliente.tscn
extends Node

const IP_SERVIDOR := "127.0.0.1"
const PUERTO := 8910

@export var codigo_sala: String = "ABCD"

func _ready() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(IP_SERVIDOR, PUERTO)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_conectado)

func _on_conectado() -> void:
	print("Conectado. Pidiendo sala ", codigo_sala)
	pedir_sala.rpc_id(1, codigo_sala)  # 1 = servidor

@rpc("any_peer", "call_remote", "reliable")
func pedir_sala(_codigo: String) -> void:
	pass  # vive en el servidor

@rpc("authority", "call_remote", "reliable")
func responder_estado(estado: String) -> void:
	print("Estado de sala: ", estado)

@rpc("authority", "call_remote", "reliable")
func sala_lista(companeros: Array) -> void:
	print("¡Sala lista! Compañeros: ", companeros)
	# Aquí cambiarías a la escena de juego.
```

**Paso 4 — Probar con dos clientes.** Arranca el servidor y luego dos instancias de cliente con el mismo código.

```bash
# Terminal 1: servidor
godot --headless --path . Servidor.tscn

# Terminal 2 y 3: dos clientes con el mismo codigo_sala="ABCD"
godot --path . Cliente.tscn
godot --path . Cliente.tscn
```

Observable: cada cliente imprime `Estado de sala: EN_SALA` al entrar y, cuando llega el segundo, ambos imprimen `¡Sala lista!` con el id del compañero. Ese instante es el "match" que en un juego real dispararía el cambio a la escena de partida.

## ✍️ Ejercicios

1. Genera el código de sala en el servidor (4 caracteres aleatorios A-Z) en lugar de recibirlo, y devuélvelo al primer jugador que crea la sala.
2. Añade un modo "matchmaking rápido": una cola donde el servidor empareja a los dos primeros que llegan sin código.
3. Amplía `pedir_sala` para rechazar con estado `"NO_EXISTE"` si el jugador pide unirse a un código inexistente (en vez de crearlo).
4. Guarda un `mmr` (entero) por peer y empareja solo si la diferencia de rating es menor a 200.
5. Implementa un temporizador: si una sala no se llena en 30 s, avisa `"TIMEOUT"` al jugador en espera.
6. Escribe en un párrafo por qué un relay TURN funciona con Symmetric NAT pero el punch-through no.

## 📝 Reto verificable

Construye un **lobby con códigos de sala funcional** donde un anfitrión crea una sala (recibe un código autogenerado), un segundo jugador se une con ese código, y ambos reciben la señal `sala_lista` con la lista de compañeros. El servidor debe manejar salas llenas y desconexiones (liberar el hueco).

**Criterio de aceptación**: con el servidor headless corriendo, dos instancias de cliente que comparten el mismo código imprimen ambas `¡Sala lista!`; una tercera instancia con el mismo código recibe `LLENA`; si un cliente en sala se cierra, otra instancia puede volver a ocupar su lugar.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| `pedir_sala` no llega al servidor | Usaste `rpc()` en vez de `rpc_id(1, ...)`; el servidor siempre es peer 1 |
| El RPC de respuesta no ejecuta | Anotación incorrecta: el que envía el servidor debe ser `@rpc("authority")` y existir con la misma firma en ambos lados |
| "Method not found" al recibir RPC | El método no está declarado en el nodo receptor o el nombre difiere |
| Los clientes no se ven entre sí | El servidor de salas solo empareja; el gameplay P2P exige un peer nuevo o relay explícito |
| Sala nunca se libera | No borraste el peer de `_salas` en `peer_disconnected` |

## ❓ Preguntas frecuentes

**¿El servidor de salas es lo mismo que un servidor de juego?** No. Este solo coordina el emparejamiento (lobby). El gameplay puede seguir en el mismo servidor (autoritativo) o pasar a P2P.

**¿Por qué no comparto mi IP y ya está?** Porque tu NAT bloquea entrantes, tu IP cambia, y exponerla es un riesgo de seguridad (DDoS). Los códigos de sala abstraen todo eso.

**¿Necesito un relay siempre?** No: el punch-through evita el relay cuando ambos NAT lo permiten. El relay es el plan B garantizado, más caro en ancho de banda.

**¿Godot trae NAT punch-through de fábrica?** La API de alto nivel no lo automatiza; se resuelve con un servicio externo (STUN/TURN, Nakama, Steam) o un relay propio. Godot te da el transporte (ENet, WebRTC).

## 🔗 Referencias

- Godot Docs — High-level multiplayer: <https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html>
- Godot Docs — ENetMultiplayerPeer: <https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html>
- Heroic Labs Nakama — Matchmaker: <https://heroiclabs.com/docs/nakama/concepts/matches/>
- RFC 8445 — ICE (NAT traversal): <https://datatracker.ietf.org/doc/html/rfc8445>

## ➡️ Siguiente clase

Continúa con **151 — Servidores dedicados: headless y despliegue**, donde convertirás este servidor en un proceso headless desplegable.
