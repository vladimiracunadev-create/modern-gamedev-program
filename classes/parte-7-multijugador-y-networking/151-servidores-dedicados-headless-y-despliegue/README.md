# Clase 151 — Servidores dedicados: headless y despliegue

> Parte: **7 — Multijugador y networking** · Fuente: *Documentación de Godot 4 (Exporting for dedicated servers, command line tutorial) + prácticas de despliegue en VPS/contenedores*
> ⏱️ Duración estimada: **55 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Aprender a ejecutar tu juego de Godot 4 como un **servidor dedicado headless**: sin ventana, sin render, sin audio, arrancando desde un argumento de línea de comandos y consumiendo el mínimo de recursos. Compararás el modelo **servidor dedicado** frente al **listen server**, detectarás el modo servidor por argumentos y por `DisplayServer`, y desplegarás el proceso localmente para probarlo con un cliente. Es la pieza que convierte un prototipo de escritorio en algo que corre 24/7 en un VPS o un contenedor.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Diferenciar servidor dedicado, listen server y P2P según autoridad y coste.
- Ejecutar el proyecto en modo headless con `godot --headless` sin abrir ventana.
- Detectar el modo servidor a partir de `OS.get_cmdline_args()` y `DisplayServer.get_name()`.
- Estructurar el arranque para elegir escena de servidor o de cliente en tiempo de ejecución.
- Empaquetar y desplegar el servidor localmente (o en contenedor) y validarlo con un cliente.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Dedicado vs listen server | Decide quién tiene autoridad y quién paga el hosting |
| 2 | Modo headless de Godot | Corre sin GPU/ventana: barato y desplegable |
| 3 | Detección por argumentos | Un mismo binario sirve de cliente o servidor |
| 4 | Bucle de tick del servidor | El servidor no renderiza pero sí simula a ritmo fijo |
| 5 | Exportación del binario servidor | Un export template sin render reduce peso y superficie |
| 6 | Despliegue en VPS/contenedor | Lleva el proceso a producción reproducible |
| 7 | Recursos y límites | CPU, RAM y ancho de banda marcan cuántas partidas caben |
| 8 | Logs y observabilidad | Sin ventana, los logs son tus ojos |

## 📖 Definiciones y características

- **Servidor dedicado**: proceso que solo simula la partida, sin jugador local. Clave: autoridad total y neutralidad; nadie tiene ventaja de host.
- **Listen server**: un jugador hace de host y cliente a la vez. Clave: gratis de operar, pero el host tiene ventaja de latencia y puede caer la partida al salir.
- **Headless**: ejecución sin servidor de display ni render. Clave: no necesita GPU y arranca en entornos sin escritorio (VPS, Docker).
- **`--headless`**: bandera de arranque de Godot que activa el driver de display nulo. Clave: es la forma soportada de correr servidores.
- **`OS.get_cmdline_args()`**: devuelve los argumentos pasados al ejecutable. Clave: permite un flag propio como `--server`.
- **Tick rate**: frecuencia con la que el servidor avanza la simulación (p. ej. 30 o 60 Hz). Clave: fija el `physics_ticks_per_second`, no los FPS de render.
- **Export template headless/server**: plantilla de exportación sin componentes gráficos. Clave: binario más ligero y con menos dependencias.
- **VPS/Contenedor**: máquina virtual o imagen reproducible donde vive el proceso. Clave: despliegue consistente y escalable.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x** instalado y accesible como `godot` en tu PATH (en Windows puede ser `Godot_v4.x-stable_win64.exe`). El laboratorio no requiere nube: desplegarás "localmente" ejecutando el servidor como proceso de terminal. Para producción real, la referencia canónica es la guía de Godot sobre servidores dedicados (<https://docs.godotengine.org/en/stable/tutorials/networking/dedicated_servers.html>) y la de línea de comandos (<https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html>). Si más adelante externalizas la infraestructura, backends como **Nakama** (<https://heroiclabs.com/docs/>) o **GodotSteam** (<https://godotsteam.com/>) gestionan el ciclo de vida del servidor por ti. Prepara un `main.gd` como Autoload que decida el rol al arrancar.

## 🧪 Laboratorio guiado

Convertiremos el proyecto en un binario que arranca como **servidor headless** si recibe `--server`, y como cliente en caso contrario. Es observable: verás el servidor imprimir su tick y el cliente conectarse.

**Paso 1 — Arranque que elige rol.** Un Autoload lee los argumentos y detecta headless.

```gdscript
# arranque.gd — Autoload (Project Settings > Autoload)
extends Node

func _ready() -> void:
	var args := OS.get_cmdline_args()
	var es_headless := DisplayServer.get_name() == "headless"
	if args.has("--server") or es_headless:
		print("Iniciando en modo SERVIDOR (headless=%s)" % es_headless)
		_iniciar_servidor()
	else:
		print("Iniciando en modo CLIENTE")
		_iniciar_cliente()

func _iniciar_servidor() -> void:
	# Ritmo de simulación del servidor, independiente de los FPS de render.
	Engine.physics_ticks_per_second = 30
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(9000, 32)
	if err != OK:
		push_error("Fallo al crear servidor: %s" % err)
		get_tree().quit(1)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(func(id): print("Peer conectado: ", id))
	print("Servidor escuchando en :9000")

func _iniciar_cliente() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 9000)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(func(): print("Conectado al servidor"))
```

**Paso 2 — Tick observable del servidor.** Añade un contador que lata cada segundo para confirmar que el bucle vive sin render.

```gdscript
# En arranque.gd
var _acumulado := 0.0
var _tick := 0

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_acumulado += delta
	if _acumulado >= 1.0:
		_acumulado -= 1.0
		_tick += 1
		print("[servidor] tick #%d, peers=%d" % [_tick, multiplayer.get_peers().size()])
```

**Paso 3 — Ejecutar el servidor headless.** Sin ventana, sin GPU.

```bash
# Servidor dedicado, sin render ni audio
godot --headless --path . --server

# En Windows con el ejecutable versionado:
# ./Godot_v4.4-stable_win64.exe --headless --path . --server
```

Verás en consola `Servidor escuchando en :9000` y luego `[servidor] tick #1, peers=0`, `#2`, ... sin abrir ninguna ventana.

**Paso 4 — Conectar un cliente y exportar.** Arranca un cliente normal (con ventana) y luego exporta el binario del servidor.

```bash
# Cliente (misma máquina), abre ventana y conecta
godot --path .

# Exportar el binario del servidor por línea de comandos
# (define antes un preset "Linux/X11" o el de tu plataforma en el editor)
godot --headless --export-release "Linux/X11" ./build/servidor.x86_64
```

Observable: al conectar el cliente, el servidor imprime `Peer conectado: <id>` y el contador de peers sube a 1. El binario exportado en `./build/` se ejecuta igual: `./build/servidor.x86_64 --headless --server`.

## ✍️ Ejercicios

1. Añade un flag `--port=NNNN` parseando `OS.get_cmdline_args()` para elegir el puerto sin recompilar.
2. Haz que el servidor imprima su uso aproximado escribiendo el número de peers y `Engine.get_physics_interpolation_fraction()` cada 5 s.
3. Implementa un cierre limpio: si el servidor recibe la señal de salida, desconecta a los peers antes de `get_tree().quit()`.
4. Crea un preset de exportación "servidor" y documenta qué recursos gráficos podrías excluir.
5. Escribe un `Dockerfile` mínimo que copie el binario exportado y lo ejecute con `--headless --server`.
6. Compara en una tabla dedicado vs listen server para un shooter competitivo y para un cooperativo de 2 jugadores.

## 📝 Reto verificable

Entrega un proyecto que, con **un único código base**, arranque como servidor dedicado headless al pasar `--server` (o al detectar display headless) y como cliente en cualquier otro caso, exportado a un binario ejecutable. El servidor debe simular a un tick fijo y registrar conexiones/desconexiones en el log.

**Criterio de aceptación**: `godot --headless --path . --server` corre sin abrir ventana e imprime ticks periódicos; una instancia cliente se conecta y el servidor registra el peer; el binario exportado reproduce el mismo comportamiento al ejecutarse con `--headless --server`.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Error "This application cannot run without a display" | Faltó `--headless`; añádelo o usa un export template server |
| El servidor consume 100 % de un núcleo | No limitaste el ritmo; fija `Engine.physics_ticks_per_second` y evita bucles busy-wait |
| `--server` no detectado | `OS.get_cmdline_args()` no incluye args del motor; pásalos tras `--` o compara la cadena exacta |
| Cargas texturas/shaders en headless y crashea | El código de servidor no debe instanciar nodos de render; sepáralo por rol |
| El binario exportado no arranca en el VPS | Faltan permisos de ejecución (`chmod +x`) o librerías del sistema |

## ❓ Preguntas frecuentes

**¿Un servidor headless renderiza algo?** No. Con `--headless` el driver de display es nulo: no hay ventana ni GPU, solo simulación y red.

**¿Puedo detectar el modo servidor sin flag propio?** Sí, `DisplayServer.get_name() == "headless"` es fiable cuando arrancas con `--headless`. El flag `--server` da control explícito para casos con display.

**¿A qué FPS corre un servidor?** El render puede ser 0; lo que importa es `physics_ticks_per_second`, el ritmo de la simulación autoritativa (típico 20–60 Hz).

**¿Necesito un export template especial?** Godot ofrece plantillas server; reducen peso y dependencias gráficas, aunque un binario normal con `--headless` también funciona.

## 🔗 Referencias

- Godot Docs — Exporting for dedicated servers: <https://docs.godotengine.org/en/stable/tutorials/networking/dedicated_servers.html>
- Godot Docs — Command line tutorial: <https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html>
- Godot Docs — Feature tags (headless/server): <https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html>
- Heroic Labs — Servidores y despliegue: <https://heroiclabs.com/docs/nakama/getting-started/install/docker/>

## ➡️ Siguiente clase

Continúa con **152 — Backends: Nakama, Steam y servicios gestionados**, donde delegarás auth, salas y almacenamiento a un backend.
