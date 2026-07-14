# Clase 152 — Backends: Nakama, Steam y servicios gestionados

> Parte: **7 — Multijugador y networking** · Fuente: *Documentación de Heroic Labs Nakama + GodotSteam (godotsteam.com) + Steamworks SDK*
> ⏱️ Duración estimada: **55 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender qué resuelve un **backend de juego** y por qué casi nadie construye desde cero la autenticación, el matchmaking, las salas, el almacenamiento de datos y los leaderboards. Compararás **Nakama** (Heroic Labs), una plataforma open source con SDK para Godot, y **Steam** vía **GodotSteam** (lobbies, P2P, matchmaking). En el laboratorio te conectarás a Nakama para autenticar a un jugador y crear o unirte a una sala, con snippets reales de la SDK. Al terminar sabrás cuándo apoyarte en un backend y cuándo tu propio servidor headless basta.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Enumerar los servicios típicos de un backend: auth, matchmaking, salas, storage y leaderboards.
- Explicar el modelo de Nakama (cliente, sesión, socket) y cómo encaja con Godot 4.
- Describir el modelo de Steam (lobbies y P2P) expuesto por GodotSteam.
- Autenticar un usuario y unirse a una sala usando la SDK de Nakama desde GDScript.
- Decidir con criterio entre backend gestionado, self-hosted o servidor propio.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué aporta un backend | Evita reinventar auth, salas y persistencia |
| 2 | Autenticación y sesiones | Identidad estable entre dispositivos y partidas |
| 3 | Matchmaking gestionado | Colas y emparejamiento sin operar tu propio matcher |
| 4 | Salas (match) y sockets | El canal en tiempo real donde ocurre el juego |
| 5 | Storage y leaderboards | Progreso, inventario y competición persistentes |
| 6 | Nakama con Godot | SDK open source, self-host o Heroic Cloud |
| 7 | Steam con GodotSteam | Lobbies y P2P nativos del ecosistema Steam |
| 8 | Cuándo usar cada uno | Plataforma objetivo y control marcan la elección |

## 📖 Definiciones y características

- **Backend de juego (BaaS)**: servicio que ofrece funciones online listas (auth, salas, datos). Clave: reduce meses de infraestructura a llamadas de SDK.
- **Nakama**: servidor open source de Heroic Labs con módulos de auth, matchmaking, chat, storage y leaderboards. Clave: puedes self-hostearlo (Docker) o usar Heroic Cloud.
- **Sesión (Nakama)**: token que representa a un usuario autenticado. Clave: se refresca y viaja en cada petición.
- **Socket (Nakama)**: conexión en tiempo real para matchmaking, salas y chat. Clave: separa el REST (datos) del realtime (juego).
- **Match (Nakama)**: sala de juego autoritativa o relayed donde los jugadores intercambian estado. Clave: es el equivalente gestionado a tu servidor de salas.
- **Lobby (Steam)**: agrupación de jugadores identificada por un `SteamID`, con metadatos y chat. Clave: descubrimiento y reunión previa a la partida.
- **Steam P2P / Networking**: transporte que enruta paquetes entre miembros usando la red de Steam (incluye relay). Clave: NAT traversal resuelto por Valve.
- **GodotSteam**: módulo/GDExtension que expone la API de Steamworks a Godot 4. Clave: puente sin el cual Godot no habla con Steam.

## 🧰 Herramientas y preparación

Para Nakama, la vía más simple de probar en local es levantar el servidor con **Docker** siguiendo la guía oficial (<https://heroiclabs.com/docs/nakama/getting-started/install/docker/>) e instalar el **SDK de Nakama para Godot** desde el AssetLib o su repositorio (<https://github.com/heroiclabs/nakama-godot>). La documentación de referencia está en <https://heroiclabs.com/docs/>. Para Steam necesitas una cuenta de Steamworks, un `App ID` (durante el desarrollo puedes usar el 480 de prueba) y **GodotSteam** (<https://godotsteam.com/>), disponible como GDExtension o build del motor. Ambos coexisten con la API de alto nivel de Godot: puedes usar `SteamMultiplayerPeer` (de GodotSteam) como `multiplayer.multiplayer_peer` y seguir usando `@rpc`. El laboratorio se centra en Nakama por ser multiplataforma y open source.

## 🧪 Laboratorio guiado

Nos conectaremos a un Nakama local, autenticaremos un jugador de forma anónima por dispositivo y nos uniremos a una sala en tiempo real. Es observable: verás en consola el `user_id` y la entrada al match.

**Paso 1 — Levantar Nakama en local.**

```bash
# Descarga el docker-compose oficial de Nakama y arranca servidor + base de datos
docker compose up -d
# Consola de administración disponible en http://127.0.0.1:7351
```

**Paso 2 — Crear el cliente e iniciar sesión.** El SDK de Godot expone `Nakama.create_client(...)`. La autenticación por dispositivo no pide contraseña: ideal para empezar.

```gdscript
# nakama_backend.gd — Autoload
extends Node

const CLAVE_SERVIDOR := "defaultkey"   # clave por defecto del server local
const HOST := "127.0.0.1"
const PUERTO := 7350

var _cliente               # NakamaClient
var _sesion                # NakamaSession
var _socket                # NakamaSocket

func _ready() -> void:
	_cliente = Nakama.create_client(CLAVE_SERVIDOR, HOST, PUERTO, "http")
	await _autenticar()

func _autenticar() -> void:
	var device_id := OS.get_unique_id()
	_sesion = await _cliente.authenticate_device_async(device_id)
	if _sesion.is_exception():
		push_error("Auth falló: %s" % _sesion.get_exception().message)
		return
	print("Autenticado. user_id = ", _sesion.user_id)
```

**Paso 3 — Abrir el socket en tiempo real.** El socket es el canal para salas y matchmaking.

```gdscript
# En nakama_backend.gd
func abrir_socket() -> void:
	_socket = Nakama.create_socket_from(_cliente)
	var conectado = await _socket.connect_async(_sesion)
	if conectado.is_exception():
		push_error("Socket falló: %s" % conectado.get_exception().message)
		return
	print("Socket en tiempo real conectado")
	_socket.received_match_state.connect(_on_estado_match)

func _on_estado_match(estado) -> void:
	var datos := (estado.data as String)
	print("Estado recibido de op %d: %s" % [estado.op_code, datos])
```

**Paso 4 — Crear o unirse a una sala y enviar estado.**

```gdscript
# En nakama_backend.gd
var _match_id := ""

func crear_sala() -> void:
	var partida = await _socket.create_match_async()
	if partida.is_exception():
		push_error("No se creó la sala: %s" % partida.get_exception().message)
		return
	_match_id = partida.match_id
	print("Sala creada. match_id = ", _match_id)

func unirse_sala(match_id: String) -> void:
	var partida = await _socket.join_match_async(match_id)
	if partida.is_exception():
		push_error("No se pudo unir: %s" % partida.get_exception().message)
		return
	_match_id = partida.match_id
	print("Unido a la sala con %d jugadores" % partida.presences.size())

func enviar_movimiento(pos: Vector2) -> void:
	# op_code propio (1 = movimiento); datos como JSON
	var datos := JSON.stringify({"x": pos.x, "y": pos.y})
	await _socket.send_match_state_async(_match_id, 1, datos)
```

Observable: al arrancar imprime `Autenticado. user_id = ...`; tras `crear_sala()` verás el `match_id`, que puedes pasar a otra instancia para `unirse_sala(match_id)`; al enviar movimientos, la otra instancia imprime `Estado recibido de op 1: {"x":...,"y":...}`.

## ✍️ Ejercicios

1. Cambia la autenticación por dispositivo a autenticación por email + contraseña (`authenticate_email_async`).
2. Muestra el nombre de usuario: tras autenticar, llama a la cuenta (`get_account_async`) e imprime `username`.
3. Escribe un valor en el storage de Nakama (p. ej. `{"nivel": 3}`) y vuelve a leerlo.
4. Envía y renderiza el movimiento del otro jugador parseando el JSON de `received_match_state`.
5. Añade un op_code 2 para "disparo" y diferéncialo del movimiento en `_on_estado_match`.
6. Investiga y describe en un párrafo cómo harías lo mismo con GodotSteam usando `SteamMultiplayerPeer` y lobbies.

## 📝 Reto verificable

Entrega un cliente Godot que **autentica contra Nakama, abre el socket en tiempo real, crea una sala y permite que una segunda instancia se una por `match_id`**, intercambiando al menos un tipo de mensaje de estado (movimiento) entre ambas.

**Criterio de aceptación**: con Nakama corriendo en Docker, la instancia A imprime su `user_id` y un `match_id`; la instancia B se une con ese `match_id` y su contador de jugadores es 2; cuando A envía un movimiento, B lo imprime a partir de `received_match_state` con las coordenadas correctas.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| `create_client` no existe / `Nakama` desconocido | El plugin de Nakama no está instalado o el Autoload `Nakama` no se registró |
| Auth devuelve excepción de conexión | Nakama no está levantado o el host/puerto/clave no coinciden con el server |
| El socket no recibe estados | No abriste el socket antes de unirte, o no conectaste `received_match_state` |
| Los datos llegan vacíos | Enviaste el estado sin serializar; usa `JSON.stringify` y parsea al recibir |
| GodotSteam no inicializa | Falta el `App ID` (usa 480 en pruebas) o el cliente de Steam no está abierto |

## ❓ Preguntas frecuentes

**¿Nakama reemplaza mi servidor headless?** Puede: ofrece matches relayed y matches autoritativos con lógica en el servidor. Para lógica pesada propia, a veces combinas ambos.

**¿Puedo usar Nakama y la API `@rpc` de Godot juntas?** Sí, pero son transportes distintos: con Nakama envías estado por su socket; con `@rpc` necesitas un `MultiplayerPeer`. Elige uno como canal de juego.

**¿GodotSteam solo sirve si publico en Steam?** Sus lobbies y P2P están atados al ecosistema Steam, así que sí: es la opción cuando tu plataforma objetivo es Steam.

**¿Nakama es de pago?** Es open source y puedes self-hostearlo gratis (Docker). Heroic Labs ofrece además Heroic Cloud como servicio gestionado de pago.

## 🔗 Referencias

- Heroic Labs — Documentación de Nakama: <https://heroiclabs.com/docs/>
- Nakama Godot client (GitHub): <https://github.com/heroiclabs/nakama-godot>
- GodotSteam — Documentación: <https://godotsteam.com/>
- Steamworks — Lobbies y matchmaking: <https://partner.steamgames.com/doc/features/multiplayer/matchmaking>

## ➡️ Siguiente clase

Continúa con **153 — Testing de red: simular latencia y pérdida**, donde pondrás tu multijugador bajo condiciones adversas.
