# Clase 143 — Un chat y lobby en red paso a paso

> Parte: **7 — Multijugador y networking** · Fuente: *Documentación oficial de Godot 4 + patrones de lobby de la comunidad (demos de red de Godot)*
> ⏱️ Duración estimada: **60 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Integrar todo lo aprendido (conexión, señales, RPCs) en una pieza real que todo juego multijugador necesita: un **lobby con chat**. Al terminar tendrás una sala donde los jugadores se unen por IP, ven la **lista de jugadores** con **nombres** y estado **"listo"**, chatean por texto vía RPC y, cuando todos están listos, el servidor **arranca la partida cambiando de escena en todos** de forma sincronizada.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Construir una interfaz de lobby (unirse por IP, lista de jugadores, chat).
- Registrar nombres de jugador y difundirlos a todos los peers por RPC.
- Implementar un chat de texto sincronizado con `@rpc("any_peer", "call_local")`.
- Gestionar el estado "listo" por jugador y detectar cuándo todos lo están.
- Arrancar la partida cambiando de escena de forma sincronizada en todos los pares.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Anatomía de un lobby | Es la antesala de casi todo juego en red |
| 2 | Unirse por IP y crear sala | El flujo de entrada del jugador |
| 3 | Registro de nombres | Identidad legible frente al id numérico |
| 4 | Lista de jugadores replicada | Todos deben ver a todos |
| 5 | Chat por RPC | Comunicación básica y prueba de sincronía |
| 6 | Estado "listo" | Coordinar el arranque sin prisas |
| 7 | Autoridad del arranque | Solo el servidor decide empezar |
| 8 | Cambio de escena sincronizado | Todos entran a la partida a la vez |

## 📖 Definiciones y características

- **Lobby**: escena previa donde los jugadores se reúnen antes de empezar. Clave: gestiona identidad, chat y preparación.
- **Sala (host)**: el peer servidor que acepta uniones. Clave: mantiene la lista maestra de jugadores.
- **Registro de jugador**: enviar tu nombre al conectar para que todos lo conozcan. Clave: se hace por RPC hacia el servidor, que lo redistribuye.
- **Lista de jugadores**: diccionario id→datos (nombre, listo). Clave: el servidor es la fuente de verdad y la difunde.
- **Chat por RPC**: mensajes de texto propagados con `call_local` para que el emisor también los vea. Clave: prueba visible de que la red funciona.
- **Estado listo**: bandera por jugador que indica que puede empezar. Clave: el servidor arranca solo cuando todos están listos.
- **Arranque sincronizado**: el servidor ordena a todos cambiar de escena. Clave: usa RPC para que nadie empiece antes.
- **`change_scene_to_file`**: cambia la escena activa. Clave: invocado por RPC en cada par para entrar juntos a la partida.

## 🧰 Herramientas y preparación

**Godot 4.x** y **dos instancias**. Prepara `Lobby.tscn` con: `LineEdit` para IP (`IpEdit`), `LineEdit` para nombre (`NombreEdit`), botones `BtnHost` y `BtnUnirse`, una `ItemList` o `Label` (`ListaJugadores`), un `TextEdit`/`Label` de chat (`ChatLog`), un `LineEdit` de mensaje (`MsgEdit`), un botón `BtnEnviar`, un `CheckButton` `Listo` y un `BtnEmpezar`. También una `Partida.tscn` mínima (un `Label` que diga "¡En partida!"). Guía útil: [demo de lobby multijugador de Godot](https://github.com/godotengine/godot-demo-projects/tree/master/networking).

## 🧪 Laboratorio guiado

Un solo script en `Lobby.tscn`. El servidor mantiene `jugadores` (id→{nombre, listo}) y lo difunde. Empezamos por conexión y registro.

```gdscript
extends Control

const PUERTO := 9995

# id -> {"nombre": String, "listo": bool}
var jugadores: Dictionary = {}
var _mi_nombre := "Jugador"

@onready var _lista: Label = $ListaJugadores
@onready var _chat: Label = $ChatLog

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_conectado)
	multiplayer.peer_disconnected.connect(_on_peer_desconectado)
	multiplayer.connected_to_server.connect(_on_conectado)
	$BtnHost.pressed.connect(_host)
	$BtnUnirse.pressed.connect(_unirse)
	$BtnEnviar.pressed.connect(_enviar_chat)
	$Listo.toggled.connect(_on_listo)
	$BtnEmpezar.pressed.connect(_empezar)

func _host() -> void:
	_mi_nombre = $NombreEdit.text if $NombreEdit.text != "" else "Host"
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(PUERTO, 8)
	multiplayer.multiplayer_peer = peer
	# El host se registra a sí mismo (id 1).
	jugadores[1] = {"nombre": _mi_nombre, "listo": false}
	_refrescar_lista()

func _unirse() -> void:
	_mi_nombre = $NombreEdit.text if $NombreEdit.text != "" else "Invitado"
	var ip := $IpEdit.text if $IpEdit.text != "" else "127.0.0.1"
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(ip, PUERTO)
	multiplayer.multiplayer_peer = peer
```

Registro de nombre y lista replicada. Al conectarse, el cliente manda su nombre al servidor; el servidor lo guarda y difunde la lista completa.

```gdscript
func _on_conectado() -> void:
	# Cliente ya dentro: envía su nombre al servidor.
	registrar.rpc_id(1, _mi_nombre)

func _on_peer_conectado(_id: int) -> void:
	if multiplayer.is_server():
		_difundir_jugadores()

func _on_peer_desconectado(id: int) -> void:
	if multiplayer.is_server():
		jugadores.erase(id)
		_difundir_jugadores()

@rpc("any_peer", "call_remote", "reliable")
func registrar(nombre: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	jugadores[id] = {"nombre": nombre, "listo": false}
	_difundir_jugadores()

func _difundir_jugadores() -> void:
	# Solo el servidor difunde la lista maestra a todos.
	sincronizar_jugadores.rpc(jugadores)

@rpc("authority", "call_local", "reliable")
func sincronizar_jugadores(datos: Dictionary) -> void:
	jugadores = datos
	_refrescar_lista()

func _refrescar_lista() -> void:
	var texto := "Jugadores:\n"
	for id in jugadores:
		var marca := "✅" if jugadores[id]["listo"] else "⌛"
		texto += "  %s %s (id %d)\n" % [marca, jugadores[id]["nombre"], id]
	_lista.text = texto
```

Chat por RPC y estado "listo". El chat usa `call_local` para que el emisor también vea su mensaje.

```gdscript
func _enviar_chat() -> void:
	var msg: String = $MsgEdit.text
	if msg == "":
		return
	recibir_chat.rpc(_mi_nombre, msg)
	$MsgEdit.text = ""

@rpc("any_peer", "call_local", "reliable")
func recibir_chat(quien: String, msg: String) -> void:
	_chat.text += "%s: %s\n" % [quien, msg]

func _on_listo(activo: bool) -> void:
	# Cada peer avisa al servidor de su estado listo.
	cambiar_listo.rpc_id(1, activo)

@rpc("any_peer", "call_remote", "reliable")
func cambiar_listo(activo: bool) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if id == 1:
		id = 1  # el host también puede marcarse (ver nota abajo)
	if jugadores.has(id):
		jugadores[id]["listo"] = activo
		_difundir_jugadores()
```

Arranque sincronizado: solo el servidor, y solo si todos están listos, ordena cambiar de escena a todos.

```gdscript
func _empezar() -> void:
	if not multiplayer.is_server():
		return
	for id in jugadores:
		if not jugadores[id]["listo"]:
			_chat.text += "[Sistema] No todos están listos.\n"
			return
	iniciar_partida.rpc()

@rpc("authority", "call_local", "reliable")
func iniciar_partida() -> void:
	get_tree().change_scene_to_file("res://Partida.tscn")
```

> Nota sobre el host: cuando el propio host marca "listo", `_on_listo` llama `cambiar_listo.rpc_id(1, activo)`; como el host ES el peer 1, `get_remote_sender_id()` puede devolver 0 al ejecutarse localmente. Para robustez, en el host actualiza también su estado directamente en `_on_listo` si `multiplayer.is_server()`.

**Cómo probarlo con dos instancias:** en la primera, pon nombre "Host" y pulsa *Host*. En la segunda, pon "Ana", IP `127.0.0.1`, y pulsa *Unirse*. Ambas listas muestran a Host y Ana. Escribe en el chat de cualquiera y aparece en las dos. Marca "listo" en ambas y pulsa *Empezar* en el host: las dos ventanas cambian a `Partida.tscn` a la vez.

## ✍️ Ejercicios

1. Rechaza en el servidor nombres vacíos o duplicados y avisa por chat de sistema.
2. Añade un contador "Listos: 2/3" que se actualice en la lista.
3. Muestra mensajes de sistema al entrar y salir jugadores ("Ana se unió").
4. Deshabilita el botón *Empezar* hasta que todos estén listos.
5. Limita la longitud del mensaje de chat a 120 caracteres validado en el servidor.
6. Añade colores por jugador en el chat según su id.

## 📝 Reto verificable

Completa el lobby: unión por IP, nombres únicos, chat funcional, estado listo por jugador, contador "Listos: X/Y", y arranque que solo procede cuando todos están listos, cambiando a `Partida.tscn` en todos simultáneamente.

**Criterio de aceptación**: con 1 host + 2 clientes, los tres ven la misma lista con nombres y marcas de listo; el chat se refleja en las tres ventanas; el botón *Empezar* solo funciona con los tres listos, y al pulsarlo las tres instancias entran a la partida a la vez.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El cliente no aparece en la lista del host | No llamas `registrar.rpc_id(1, ...)` tras `connected_to_server` |
| El chat solo lo ve el emisor | Usaste `call_remote`; para chat quieres `call_local` para verte a ti mismo |
| Un cliente puede iniciar la partida | `_empezar` no comprueba `is_server()`; solo el servidor debe arrancar |
| La lista diverge entre pares | Los clientes editan su copia; solo el servidor debe modificar `jugadores` y difundir |
| Al empezar, uno se queda en el lobby | Usaste `call_remote` en `iniciar_partida`; usa `call_local` para incluir al host |

## ❓ Preguntas frecuentes

- **¿Por qué el servidor es la fuente de verdad de la lista?** Porque si cada cliente edita su copia acaban divergiendo; centralizar y difundir evita inconsistencias.
- **¿El chat debería ser `reliable`?** Sí: un mensaje de texto no puede perderse sin que se note, a diferencia de la posición de un jugador.
- **¿Cómo paso datos del lobby a la partida?** Guarda `jugadores` en un autoload (singleton) antes del cambio de escena, o vuelve a sincronizarlo tras cargar `Partida.tscn`.
- **¿Puedo usar MultiplayerSpawner para la lista?** Podrías, pero para datos tabulares (nombre, listo) un diccionario difundido por RPC es más simple y claro.

## 🔗 Referencias

- [High-level multiplayer (Godot 4)](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)
- [Godot demo projects — networking](https://github.com/godotengine/godot-demo-projects/tree/master/networking)
- [Clase SceneTree (change_scene_to_file)](https://docs.godotengine.org/en/stable/classes/class_scenetree.html)
- [Clase MultiplayerAPI](https://docs.godotengine.org/en/stable/classes/class_multiplayerapi.html)

## ⬅️ Clase anterior

[Clase 142 - MultiplayerSpawner y MultiplayerSynchronizer](../142-multiplayerspawner-y-multiplayersynchronizer/README.md)

## ➡️ Siguiente clase

[Clase 144 - Mover jugadores en red: replicación de estado](../144-mover-jugadores-en-red-replicacion-de-estado/README.md)
