# Clase 140 — El multijugador de alto nivel de Godot (MultiplayerAPI)

> Parte: **7 — Multijugador y networking** · Fuente: *Documentación oficial de Godot 4 (High-level Multiplayer y SceneMultiplayer)*
> ⏱️ Duración estimada: **50 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Dominar la puerta de entrada al multijugador en Godot: la **MultiplayerAPI**. Al terminar sabrás crear un servidor o un cliente con `ENetMultiplayerPeer`, gestionar las **señales de conexión** (`peer_connected`, `peer_disconnected`, `connected_to_server`, etc.), leer tu identidad con `multiplayer.get_unique_id()` y entender cómo Godot replica el **árbol de escena** entre pares. Construirás una escena que crea servidor o cliente con botones y muestra en pantalla, en vivo, la lista de peers conectados.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Crear servidor y cliente con `ENetMultiplayerPeer` y asignar `multiplayer.multiplayer_peer`.
- Conectar y reaccionar a todas las señales de la MultiplayerAPI.
- Distinguir el id único (1 = servidor) y usar `is_server()` para ramificar lógica.
- Mantener una lista viva de peers conectados con `get_peers()`.
- Explicar qué significa que el árbol de nodos esté "replicado" entre pares.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es MultiplayerAPI y SceneMultiplayer | El objeto que orquesta toda la red de alto nivel |
| 2 | ENetMultiplayerPeer | El transporte concreto que enchufas a la API |
| 3 | Crear servidor vs cliente | Dos rutas de un mismo código |
| 4 | Señales de conexión | Tu única forma de saber quién entra y sale |
| 5 | Identidad de peer (unique_id) | 1 es el servidor; el resto son clientes |
| 6 | `is_server()` y ramificación | Un solo script, dos comportamientos |
| 7 | El árbol replicado | Base conceptual de spawner y synchronizer |
| 8 | Ciclo de vida de la conexión | Del intento al `connected_to_server` o fallo |

## 📖 Definiciones y características

- **MultiplayerAPI**: objeto (accesible como `multiplayer`) que gestiona RPCs, peers y replicación. Clave: cada árbol de escena tiene una instancia asociada.
- **SceneMultiplayer**: implementación por defecto de MultiplayerAPI en Godot 4. Clave: añade replicación de escena y control de reenvío de RPCs.
- **ENetMultiplayerPeer**: peer concreto sobre ENet/UDP. Clave: se crea como servidor o cliente y se asigna a `multiplayer.multiplayer_peer`.
- **peer_connected(id)**: señal que avisa de un nuevo par. Clave: en el servidor la recibes por cada cliente; en el cliente, por cada otro par.
- **connected_to_server**: señal que confirma tu conexión como cliente. Clave: hasta aquí no puedes asumir que estás dentro.
- **get_unique_id()**: devuelve tu id de red; **1** es siempre el servidor. Clave: úsalo para saber quién eres sin variables extra.
- **is_server()**: `true` si tu id es 1. Clave: la manera limpia de separar código de servidor y cliente.
- **Árbol replicado**: la idea de que ambos extremos comparten la misma jerarquía de nodos. Clave: los RPC y la replicación se resuelven por *ruta de nodo* (NodePath).

## 🧰 Herramientas y preparación

**Godot 4.x** y capacidad de abrir **dos instancias**. Prepara una escena con un `Control` que tenga dos botones (`BtnServidor`, `BtnCliente`), un `LineEdit` para la IP y un `ItemList` o `Label` para mostrar los peers. Ten abierta la [referencia de MultiplayerAPI](https://docs.godotengine.org/en/stable/classes/class_multiplayerapi.html) y la de [SceneMultiplayer](https://docs.godotengine.org/en/stable/classes/class_scenemultiplayer.html). Recuerda activar *Debug → Run Multiple Instances* para probar cómodamente.

## 🧪 Laboratorio guiado

Haremos un "panel de red" que crea servidor o cliente por botones y lista los peers en vivo. Estructura de escena sugerida: `Panel (Control)` con hijos `BtnServidor`, `BtnCliente`, `IpEdit (LineEdit)` y `ListaPeers (Label)`. Script en `Panel`:

```gdscript
extends Control

const PUERTO := 9997

@onready var _lista_peers: Label = $ListaPeers
@onready var _ip_edit: LineEdit = $IpEdit

func _ready() -> void:
	$BtnServidor.pressed.connect(_crear_servidor)
	$BtnCliente.pressed.connect(_crear_cliente)
	multiplayer.peer_connected.connect(_on_peer_conectado)
	multiplayer.peer_disconnected.connect(_on_peer_desconectado)
	multiplayer.connected_to_server.connect(_on_conectado)
	multiplayer.connection_failed.connect(_on_fallo)
	multiplayer.server_disconnected.connect(_on_server_caido)
	_refrescar_lista()

func _crear_servidor() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PUERTO, 16)
	if err != OK:
		_lista_peers.text = "Error al abrir servidor: %d" % err
		return
	multiplayer.multiplayer_peer = peer
	_refrescar_lista()

func _crear_cliente() -> void:
	var ip := _ip_edit.text if _ip_edit.text != "" else "127.0.0.1"
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PUERTO)
	if err != OK:
		_lista_peers.text = "Error al crear cliente: %d" % err
		return
	multiplayer.multiplayer_peer = peer
```

Ahora los manejadores de señales y el refresco de la lista. `multiplayer.get_peers()` devuelve los ids de los demás; añadimos el nuestro para verlo completo.

```gdscript
func _on_peer_conectado(id: int) -> void:
	print("Entra peer %d" % id)
	_refrescar_lista()

func _on_peer_desconectado(id: int) -> void:
	print("Sale peer %d" % id)
	_refrescar_lista()

func _on_conectado() -> void:
	print("Conectado al servidor como %d" % multiplayer.get_unique_id())
	_refrescar_lista()

func _on_fallo() -> void:
	_lista_peers.text = "Conexión fallida."

func _on_server_caido() -> void:
	_lista_peers.text = "El servidor se desconectó."
	multiplayer.multiplayer_peer = null

func _refrescar_lista() -> void:
	if multiplayer.multiplayer_peer == null:
		_lista_peers.text = "Sin conexión."
		return
	var mi_id := multiplayer.get_unique_id()
	var rol := "SERVIDOR" if multiplayer.is_server() else "CLIENTE"
	var texto := "%s · Mi ID: %d\nPeers:\n" % [rol, mi_id]
	for id in multiplayer.get_peers():
		texto += "  - %d\n" % id
	_lista_peers.text = texto
```

**Cómo probarlo con dos instancias:** en la primera pulsa *Crear servidor* (mostrará `SERVIDOR · Mi ID: 1`). En la segunda escribe `127.0.0.1` y pulsa *Crear cliente* (mostrará `CLIENTE · Mi ID: <número>`). En cuanto conecten, la lista de peers se actualiza en ambos: el servidor ve el id del cliente y el cliente ve el id 1. Abre una tercera instancia como cliente y verás cómo todas las listas crecen a la vez.

## ✍️ Ejercicios

1. Muestra un color distinto en la etiqueta según seas servidor o cliente.
2. Deshabilita el botón *Crear servidor* una vez ya hay un peer activo.
3. Añade un botón *Desconectar* que ponga `multiplayer.multiplayer_peer = null` y refresque la lista.
4. Registra en un `Array` la marca de tiempo de entrada de cada peer y muéstrala.
5. Cambia el puerto y la IP para probar entre dos máquinas de la misma red local.
6. Añade un contador total de conexiones históricas que no baje al desconectarse alguien.

## 📝 Reto verificable

Crea un "tablero de presencia": al conectar, cada cliente envía su nombre elegido, y **todos** los peers muestran una lista actualizada `id — nombre` de quién está en línea, que se actualiza al entrar y salir cualquiera.

**Criterio de aceptación**: con 1 servidor y 2 clientes con nombres "Ana" y "Beto", los tres muestran la misma lista con ambos nombres; al cerrar "Beto", su fila desaparece en las tres instancias en menos de un segundo.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| `get_unique_id()` devuelve 1 en el cliente | Aún no asignaste el peer o no llegó `connected_to_server`; espera esa señal |
| La lista no se actualiza | Olvidaste llamar `_refrescar_lista()` dentro de los manejadores de señal |
| El cliente ve "Sin conexión" pese a conectar | Comprobaste `multiplayer_peer == null` antes de que la conexión se completara |
| Todos los peers reciben id 1 | Estás creando servidor en ambas instancias; una debe ser cliente |
| Excepción al leer `$ListaPeers` | La ruta del nodo no coincide con la jerarquía real de la escena |

## ❓ Preguntas frecuentes

- **¿Qué es `multiplayer` exactamente?** Es la MultiplayerAPI asociada al árbol actual; la usas para señales, RPCs e identidad sin instanciar nada.
- **¿El servidor siempre tiene id 1?** Sí, por convención de Godot el servidor es el peer 1; los clientes reciben ids aleatorios positivos.
- **¿`peer_connected` se dispara en el cliente?** Sí: cada cliente recibe la señal por los demás peers que la MultiplayerAPI le informa, no solo el servidor.
- **¿Necesito MultiplayerSpawner ya?** No para este panel; aquí solo gestionamos conexiones. La replicación de nodos llega en la clase 142.

## 🔗 Referencias

- [High-level multiplayer (Godot 4)](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)
- [Clase MultiplayerAPI](https://docs.godotengine.org/en/stable/classes/class_multiplayerapi.html)
- [Clase SceneMultiplayer](https://docs.godotengine.org/en/stable/classes/class_scenemultiplayer.html)
- [Clase ENetMultiplayerPeer](https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html)

## ➡️ Siguiente clase

[Clase 141 - RPCs: llamadas remotas y sincronización](../141-rpcs-llamadas-remotas-y-sincronizacion/README.md)
