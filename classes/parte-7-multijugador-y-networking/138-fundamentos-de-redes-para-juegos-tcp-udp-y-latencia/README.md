# Clase 138 — Fundamentos de redes para juegos: TCP, UDP y latencia

> Parte: **7 — Multijugador y networking** · Fuente: *Glazer & Madhav, "Multiplayer Game Programming" + Glenn Fiedler, "Gaffer On Games"*
> ⏱️ Duración estimada: **50 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender la capa de transporte sobre la que se construye todo juego en red antes de tocar la MultiplayerAPI. Al terminar sabrás por qué la inmensa mayoría de los juegos en tiempo real usan **UDP** y no TCP, qué significan **latencia (RTT/ping)**, **jitter**, **pérdida de paquetes** y **ancho de banda**, y cómo **ENet** —el transporte que Godot usa por defecto— añade fiabilidad opcional sobre UDP. Montarás un servidor y un cliente ENet mínimos que imprimen la conexión, y medirás el RTT real entre dos instancias.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar las diferencias entre TCP y UDP y cuándo conviene cada uno.
- Definir RTT/ping, jitter, pérdida de paquetes y ancho de banda con sus unidades.
- Justificar por qué los juegos de acción prefieren UDP con fiabilidad selectiva.
- Crear un servidor y un cliente ENet mínimos en Godot 4 con `ENetMultiplayerPeer`.
- Medir el RTT enviando un ping por RPC y calculando el tiempo de ida y vuelta.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Modelo de capas y transporte | Sitúa dónde vive el netcode de un juego |
| 2 | TCP: fiable, ordenado, con retransmisión | Explica su latencia impredecible bajo pérdida |
| 3 | UDP: datagramas sin garantías | Es la base de casi todo juego en tiempo real |
| 4 | Head-of-line blocking | Razón técnica clave para huir de TCP en acción |
| 5 | Latencia, RTT y ping | La métrica que define la sensación de "responder" |
| 6 | Jitter y pérdida de paquetes | Provocan el movimiento "a saltos" y desincronía |
| 7 | Ancho de banda y tasa de envío | Limita cuántas actualizaciones puedes mandar |
| 8 | ENet sobre UDP | Fiabilidad opcional por canal sin renunciar a UDP |

## 📖 Definiciones y características

- **TCP**: protocolo orientado a conexión, fiable y ordenado. Clave: retransmite lo perdido, pero eso introduce *stalls* impredecibles.
- **UDP**: protocolo de datagramas sin conexión ni garantías. Clave: rápido y sin bloqueo, tú decides qué fiabilidad añadir encima.
- **RTT (Round-Trip Time)**: tiempo que tarda un paquete en ir y volver. Clave: el "ping" que ves en un juego es aproximadamente el RTT.
- **Jitter**: variación del RTT entre paquetes. Clave: alto jitter obliga a *buffers* de interpolación más grandes.
- **Pérdida de paquetes**: porcentaje de datagramas que nunca llegan. Clave: en UDP no se reenvían salvo que tú lo pidas.
- **Ancho de banda**: datos por segundo que soporta el enlace. Clave: limita la frecuencia y el tamaño de tus *snapshots*.
- **Head-of-line blocking**: en TCP, un paquete perdido frena a todos los siguientes. Clave: fatal para estado que se sobrescribe cada tick.
- **ENet**: librería de red sobre UDP con canales y fiabilidad configurable. Clave: es el transporte por defecto de la MultiplayerAPI de Godot.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x** (estable) y la posibilidad de lanzar **dos instancias** del proyecto para simular servidor y cliente en la misma máquina (`localhost` / `127.0.0.1`). En el editor puedes activar *Debug → Run Multiple Instances → 2* para abrir dos ventanas de un golpe. Ten a mano la [documentación de alto nivel de multijugador de Godot 4](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html) y los artículos [UDP vs TCP](https://gafferongames.com/post/udp_vs_tcp/) de Gaffer On Games. No hace falta abrir puertos en el router: todo el laboratorio corre en local.

## 🧪 Laboratorio guiado

Vamos a levantar un servidor/cliente ENet mínimo que imprima la conexión y, además, mida el RTT con un ping por RPC. Crea una escena `Red.tscn` con un nodo raíz `Node` llamado `Red` y adjúntale este script.

```gdscript
extends Node

const PUERTO := 9999
const MAX_CLIENTES := 8

func _ready() -> void:
	# Conectamos señales de la MultiplayerAPI antes de crear el peer.
	multiplayer.peer_connected.connect(_on_peer_conectado)
	multiplayer.peer_disconnected.connect(_on_peer_desconectado)
	multiplayer.connected_to_server.connect(_on_conectado_al_servidor)
	multiplayer.connection_failed.connect(_on_conexion_fallida)

	# El primer argumento de línea de comandos decide el rol.
	if "--server" in OS.get_cmdline_args():
		_iniciar_servidor()
	else:
		_iniciar_cliente()

func _iniciar_servidor() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PUERTO, MAX_CLIENTES)
	if error != OK:
		push_error("No se pudo abrir el servidor: %s" % error)
		return
	multiplayer.multiplayer_peer = peer
	print("[SERVIDOR] Escuchando en el puerto %d. ID=%d" % [PUERTO, multiplayer.get_unique_id()])

func _iniciar_cliente() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client("127.0.0.1", PUERTO)
	if error != OK:
		push_error("No se pudo crear el cliente: %s" % error)
		return
	multiplayer.multiplayer_peer = peer
	print("[CLIENTE] Intentando conectar a 127.0.0.1:%d..." % PUERTO)

func _on_peer_conectado(id: int) -> void:
	print("Peer conectado: %d" % id)

func _on_peer_desconectado(id: int) -> void:
	print("Peer desconectado: %d" % id)

func _on_conectado_al_servidor() -> void:
	print("[CLIENTE] Conectado. Mi ID=%d" % multiplayer.get_unique_id())
	# Al conectar, disparamos una medición de RTT.
	_medir_rtt()

func _on_conexion_fallida() -> void:
	print("[CLIENTE] Conexión fallida.")
```

Ahora añadimos la medición de RTT. La idea es: el cliente guarda una marca de tiempo, pide al servidor un "pong", y al recibir la respuesta calcula cuánto tardó el viaje completo.

```gdscript
var _t_envio_ms := 0

func _medir_rtt() -> void:
	_t_envio_ms = Time.get_ticks_msec()
	# Pedimos al servidor (id 1) que nos devuelva un pong.
	ping.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func ping() -> void:
	# Se ejecuta en el servidor: responde al emisor original.
	var emisor := multiplayer.get_remote_sender_id()
	pong.rpc_id(emisor)

@rpc("any_peer", "call_remote", "reliable")
func pong() -> void:
	# Se ejecuta en el cliente: cerramos el cronómetro.
	var rtt := Time.get_ticks_msec() - _t_envio_ms
	print("[CLIENTE] RTT medido: %d ms" % rtt)
```

**Cómo probarlo con dos instancias:** ejecuta una instancia con el argumento `--server` (en *Project Settings → Run* o vía terminal `godot --path . -- --server`) y otra sin argumentos como cliente. Verás en la consola del servidor `Peer conectado`, en el cliente `Conectado` y el `RTT medido`. En `localhost` el RTT será de pocos milisegundos; ese mismo número entre dos máquinas reales sería tu ping.

> Idea extra: para *simular* condiciones adversas puedes usar `Time.get_ticks_msec()` y un temporizador que retrase artificialmente el envío del `pong`, o herramientas del sistema (clumsy en Windows, `tc netem` en Linux) para inyectar latencia y pérdida y observar cómo sube el RTT.

## ✍️ Ejercicios

1. Modifica el laboratorio para medir el RTT cada segundo con un `Timer` y muestra el promedio de las últimas 5 mediciones.
2. Cambia el modo del RPC `pong` a `"unreliable"` y razona qué pasaría bajo pérdida de paquetes.
3. Añade un contador que muestre cuántos peers hay conectados usando `multiplayer.get_peers()`.
4. Imprime en el servidor la IP y el puerto del cliente conectado (pista: los canales de ENet exponen esa info por peer).
5. Calcula el jitter: guarda las últimas 10 mediciones de RTT y muestra la diferencia entre el máximo y el mínimo.
6. Investiga y explica en un comentario por qué `create_server` puede fallar con `ERR_ALREADY_IN_USE`.

## 📝 Reto verificable

Construye una pequeña "sala de espera de red": un servidor que acepte hasta 4 clientes, y una etiqueta en pantalla (en cada cliente) que muestre en tiempo real *su* ping al servidor actualizado cada segundo, más el número de jugadores conectados.

**Criterio de aceptación**: al abrir 3 instancias (1 servidor + 2 clientes), cada cliente muestra un ping numérico que se refresca cada segundo y el conteo "Jugadores: 2" correcto; al cerrar un cliente, el conteo baja a 1 en todos.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| `multiplayer_peer` no hace nada | Olvidaste `multiplayer.multiplayer_peer = peer`; el peer se crea pero no se asigna |
| El cliente nunca conecta | El servidor no está corriendo o el puerto difiere; verifica que ambos usen el mismo `PUERTO` |
| `create_server` devuelve error | El puerto ya está en uso por otra instancia; cámbialo o cierra la anterior |
| RTT siempre 0 | Marcaste el tiempo después de recibir, no antes de enviar; guarda `_t_envio_ms` justo antes del `rpc_id` |
| El RPC no se ejecuta | La función no tiene la anotación `@rpc` o el nombre difiere entre peers |

## ❓ Preguntas frecuentes

- **¿Por qué no usar TCP si es "más fiable"?** Porque su fiabilidad ordenada provoca *head-of-line blocking*: un paquete perdido congela todo el flujo, y en un juego el estado nuevo ya invalidó al viejo.
- **¿ENet es UDP o TCP?** ENet corre sobre UDP y te deja elegir por canal si un mensaje es fiable u ordenado, lo mejor de ambos mundos.
- **¿El ping y el RTT son lo mismo?** En la práctica sí; el ping mostrado suele ser el RTT medio. La latencia "de un sentido" es aproximadamente la mitad.
- **¿Cuánto ping es aceptable?** Para acción rápida, por debajo de 60–80 ms se siente bien; a partir de 150 ms notarás la falta de respuesta sin técnicas de predicción.

## 🔗 Referencias

- Documentación oficial: [High-level multiplayer (Godot 4)](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)
- Glenn Fiedler: [UDP vs. TCP](https://gafferongames.com/post/udp_vs_tcp/)
- Valve Developer Wiki: [Source Multiplayer Networking](https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking)
- Documentación de [ENetMultiplayerPeer](https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html)

## ➡️ Siguiente clase

[Clase 139 - Modelos de arquitectura: P2P, cliente-servidor y autoritativo](../139-modelos-de-arquitectura-p2p-cliente-servidor-autoritativo/README.md)
