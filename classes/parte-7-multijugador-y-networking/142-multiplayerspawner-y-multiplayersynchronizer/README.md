# Clase 142 — MultiplayerSpawner y MultiplayerSynchronizer

> Parte: **7 — Multijugador y networking** · Fuente: *Documentación oficial de Godot 4 (Scene Replication) + ejemplos de la comunidad*
> ⏱️ Duración estimada: **55 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Replicar el mundo sin escribir RPCs a mano usando los dos nodos de replicación de Godot 4: **MultiplayerSpawner** (para instanciar escenas replicadas: jugadores, balas) y **MultiplayerSynchronizer** (para sincronizar propiedades con un `SceneReplicationConfig`). Al terminar spawnearás un jugador por cada peer que se conecta y sincronizarás su posición automáticamente, entendiendo el papel de la **autoridad** en cada nodo.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Configurar un MultiplayerSpawner con su `spawn_path` y escenas spawnables.
- Instanciar jugadores en el servidor y verlos replicados en todos los clientes.
- Configurar un MultiplayerSynchronizer y su `SceneReplicationConfig`.
- Asignar autoridad por nodo con `set_multiplayer_authority()`.
- Combinar spawner y synchronizer para mover jugadores en red sin RPCs manuales.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Replicación de escena en Godot 4 | Automatiza lo que antes eran decenas de RPCs |
| 2 | MultiplayerSpawner y spawn_path | Define dónde y qué se instancia en red |
| 3 | Escenas spawnables | Lista blanca de lo que el spawner puede crear |
| 4 | `spawn()` en el servidor | Solo la autoridad instancia; los clientes reciben |
| 5 | MultiplayerSynchronizer | Replica propiedades marcadas cada tick |
| 6 | SceneReplicationConfig | Qué propiedades se envían y con qué frecuencia |
| 7 | Autoridad por nodo | Quién manda sobre cada jugador |
| 8 | Input local + sincronía | Cada quien mueve el suyo, todos lo ven |

## 📖 Definiciones y características

- **MultiplayerSpawner**: nodo que replica la creación y borrado de escenas hijas bajo una ruta. Clave: solo el servidor debe llamar a `spawn()`; los clientes lo replican solos.
- **spawn_path**: ruta del nodo bajo el cual aparecerán las instancias replicadas. Clave: debe existir en todos los pares con la misma jerarquía.
- **Escenas spawnables**: lista de escenas que el spawner tiene permiso de instanciar. Clave: es una lista blanca por seguridad y validación.
- **MultiplayerSynchronizer**: nodo que replica automáticamente las propiedades de su `SceneReplicationConfig`. Clave: envía desde la autoridad hacia los demás.
- **SceneReplicationConfig**: recurso que lista propiedades a replicar (p. ej. `position`) y su modo (siempre / al spawnear). Clave: se edita en el inspector del synchronizer.
- **set_multiplayer_authority(id)**: asigna qué peer controla un nodo. Clave: el jugador de cada cliente debe tener a ese cliente como autoridad.
- **is_multiplayer_authority()**: `true` si este par manda sobre el nodo. Clave: úsalo para leer input solo en el dueño del personaje.
- **Autoridad**: concepto de "quién decide" el estado de un nodo concreto. Clave: el synchronizer solo acepta cambios que vengan de la autoridad.

## 🧰 Herramientas y preparación

**Godot 4.x** y **dos instancias**. Crearás dos escenas: `Jugador.tscn` (un `CharacterBody2D` o `Node2D` con `Sprite2D` y un `MultiplayerSynchronizer`) y `Mundo.tscn` (con un `Node2D` contenedor `Jugadores` y un `MultiplayerSpawner`). Configura el `spawn_path` del spawner apuntando a `Jugadores` y añade `Jugador.tscn` a *Auto Spawn List*. En el `MultiplayerSynchronizer` del jugador, crea un `SceneReplicationConfig` y añade la propiedad `position`. Guía: [Scene replication de Godot 4](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#replication).

## 🧪 Laboratorio guiado

**1) El mundo y el spawner.** Script en el nodo raíz de `Mundo.tscn`. El servidor spawnéa un jugador cuando alguien conecta; el spawner replica esa instancia a todos.

```gdscript
extends Node2D

const ESCENA_JUGADOR := preload("res://Jugador.tscn")
const PUERTO := 9996

@onready var _spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var _contenedor: Node2D = $Jugadores

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_conectado)
	multiplayer.peer_disconnected.connect(_on_peer_desconectado)
	if "--server" in OS.get_cmdline_args():
		var peer := ENetMultiplayerPeer.new()
		peer.create_server(PUERTO, 8)
		multiplayer.multiplayer_peer = peer
		# El propio servidor también tiene su jugador (id 1).
		_crear_jugador(1)
	else:
		var peer := ENetMultiplayerPeer.new()
		peer.create_client("127.0.0.1", PUERTO)
		multiplayer.multiplayer_peer = peer

func _on_peer_conectado(id: int) -> void:
	if multiplayer.is_server():
		_crear_jugador(id)

func _on_peer_desconectado(id: int) -> void:
	if multiplayer.is_server() and _contenedor.has_node(str(id)):
		_contenedor.get_node(str(id)).queue_free()

func _crear_jugador(id: int) -> void:
	# Solo el servidor instancia; el spawner replica al resto.
	var jugador := ESCENA_JUGADOR.instantiate()
	jugador.name = str(id)  # nombre = id para localizarlo luego
	_contenedor.add_child(jugador, true)
	# La autoridad del jugador es el peer al que pertenece.
	jugador.set_multiplayer_authority(id)
```

**2) El jugador que se mueve.** Script en `Jugador.tscn`. Solo la autoridad lee input; el `MultiplayerSynchronizer` replica `position` al resto automáticamente.

```gdscript
extends CharacterBody2D

const VELOCIDAD := 220.0

func _physics_process(_delta: float) -> void:
	# Solo el dueño de este jugador procesa su input.
	if not is_multiplayer_authority():
		return
	var direccion := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direccion * VELOCIDAD
	move_and_slide()
```

No hace falta ningún RPC de posición: el `MultiplayerSynchronizer` del jugador, con `position` en su `SceneReplicationConfig`, envía la posición desde la autoridad a todos los demás cada tick.

**Cómo probarlo con dos instancias:** lanza servidor (`--server`) y cliente. Verás dos jugadores en ambas ventanas. Mueve con las flechas en la ventana del servidor: su jugador (id 1) se mueve en las dos. Mueve en el cliente: su jugador se mueve en las dos. Cada instancia solo controla el suyo (por `is_multiplayer_authority()`), pero ve moverse a todos gracias al synchronizer.

> Detalle de autoridad: por defecto la autoridad de un nodo recién añadido es el servidor. Al llamar `set_multiplayer_authority(id)` sobre el jugador, ese cliente pasa a mandar sobre su personaje y su synchronizer envía la posición.

## ✍️ Ejercicios

1. Añade `rotation` al `SceneReplicationConfig` y haz que el jugador mire hacia su dirección de movimiento.
2. Da a cada jugador un color aleatorio al spawnear y replícalo (pista: añade la propiedad al config o pásala al instanciar).
3. Crea un `MultiplayerSpawner` extra para balas y spawnéalas desde el servidor al pulsar disparo.
4. Muestra un `Label` con el id encima de cada jugador.
5. Ajusta el `replication_interval` del synchronizer y observa el efecto en la fluidez.
6. Maneja la desconexión: comprueba que el jugador se borra en todos los clientes, no solo en el servidor.

## 📝 Reto verificable

Monta una arena donde cada peer tiene su cuadrado controlable, todos spawneados por MultiplayerSpawner y sincronizados con MultiplayerSynchronizer. Añade balas: al pulsar espacio, el servidor spawnéa una bala en la posición del jugador que disparó y la replica a todos.

**Criterio de aceptación**: con 1 servidor + 1 cliente, ambos ven dos cuadrados; cada quien mueve solo el suyo pero ve moverse al otro con fluidez; al disparar en cualquiera de los dos, aparece una bala en ambas ventanas en la posición correcta.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El cliente no ve al jugador spawneado | La escena no está en la lista spawnable del spawner, o el `spawn_path` no coincide |
| La posición no se replica | Falta añadir `position` al `SceneReplicationConfig` del synchronizer |
| Todos controlan al mismo jugador | No asignaste autoridad; usa `set_multiplayer_authority(id)` por jugador |
| El cliente puede mover jugadores ajenos | No compruebas `is_multiplayer_authority()` antes de leer input |
| Nombres de nodo duplicados | Instanciaste sin `name` único; usa `jugador.name = str(id)` y `add_child(nodo, true)` |

## ❓ Preguntas frecuentes

- **¿Quién debe llamar a spawn/instanciar?** Solo el servidor (la autoridad del spawner). Los clientes reciben la instancia replicada automáticamente.
- **¿Necesito RPCs con estos nodos?** Para posición y propiedades, no: el synchronizer lo hace. Reserva los RPCs para eventos puntuales (disparo, daño).
- **¿Por qué mi jugador se "teletransporta" en el cliente?** Estás moviendo el nodo también en el cliente sin ser su autoridad; deja que solo la autoridad lo mueva y el synchronizer lo replique.
- **¿El synchronizer usa envío fiable?** Envía delta de propiedades de forma eficiente; para estado que cambia cada tick es lo adecuado. Para eventos críticos, combínalo con RPC `reliable`.

## 🔗 Referencias

- [Scene replication (Godot 4)](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#replication)
- [Clase MultiplayerSpawner](https://docs.godotengine.org/en/stable/classes/class_multiplayerspawner.html)
- [Clase MultiplayerSynchronizer](https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html)
- [Clase SceneReplicationConfig](https://docs.godotengine.org/en/stable/classes/class_scenereplicationconfig.html)

## ⬅️ Clase anterior

[Clase 141 - RPCs: llamadas remotas y sincronización](../141-rpcs-llamadas-remotas-y-sincronizacion/README.md)

## ➡️ Siguiente clase

[Clase 143 - Un chat y lobby en red paso a paso](../143-un-chat-y-lobby-en-red-paso-a-paso/README.md)
