# Clase 153 — Testing de red: simular latencia y pérdida

> Parte: **7 — Multijugador y networking** · Fuente: *Documentación de Godot 4 (Multiplayer debug tools) + herramientas de red (clumsy en Windows, tc/netem en Linux)*
> ⏱️ Duración estimada: **50 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Aprender a probar tu juego en red **bajo malas condiciones a propósito**: latencia alta, jitter y pérdida de paquetes. En una LAN todo parece perfecto; los bugs aparecen cuando el ping sube a 150 ms y se pierde un 5 % de los paquetes. Usarás la simulación de red integrada del editor de Godot 4 y herramientas del sistema (**clumsy** en Windows, **tc/netem** en Linux) para reproducir esos escenarios, observar cómo reacciona tu interpolación y predicción, y medir métricas. Al terminar sabrás provocar y diagnosticar los fallos de red antes que tus jugadores.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Justificar por qué probar en condiciones adversas es imprescindible, no opcional.
- Activar la simulación de latencia/pérdida del depurador de red de Godot 4.
- Usar clumsy (Windows) o tc/netem (Linux) para degradar el tráfico del sistema.
- Observar el efecto de la latencia sobre interpolación y predicción de movimiento.
- Instrumentar métricas básicas de red (RTT, paquetes perdidos) para diagnosticar.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Por qué probar en malas condiciones | La red real no es tu LAN; los bugs viven en el lag |
| 2 | Latencia, jitter y pérdida | Cada uno rompe cosas distintas del netcode |
| 3 | Simulación de red del editor Godot | Degradar sin salir del motor, rápido de iterar |
| 4 | clumsy (Windows) | Inyecta lag/pérdida a nivel de sistema |
| 5 | tc/netem (Linux) | Control fino del tráfico en servidores/CI |
| 6 | Efecto sobre interpolación | El suavizado depende de recibir a tiempo |
| 7 | Efecto sobre predicción | El cliente adivina; el lag amplifica el error |
| 8 | Métricas y reproducibilidad | Sin números no hay diagnóstico ni regresión |

## 📖 Definiciones y características

- **Latencia (RTT)**: tiempo de ida y vuelta de un paquete. Clave: fija cuánto se adelanta la predicción y cuánto tarda una corrección.
- **Jitter**: variación de la latencia entre paquetes. Clave: rompe la interpolación porque los estados llegan a intervalos irregulares.
- **Pérdida de paquetes**: fracción de datagramas que no llegan. Clave: en UDP no hay reenvío automático salvo en canales reliable.
- **Simulación de red (Godot)**: opciones del depurador que inyectan latencia y descartes en el peer local. Clave: reproduce condiciones sin herramientas externas.
- **Interpolación**: renderizar posiciones pasadas suavizadas entre estados recibidos. Clave: oculta el jitter a costa de un pequeño retraso visual.
- **Predicción del lado cliente**: simular el propio input de inmediato sin esperar al servidor. Clave: hace el juego responsivo pese a la latencia.
- **clumsy**: utilidad de Windows que intercepta paquetes y les aplica lag, drop o duplicación. Clave: prueba el sistema entero, no solo Godot.
- **netem (tc)**: disciplina de cola de Linux para emular delay, loss y reorder. Clave: estándar para CI y servidores headless.

## 🧰 Herramientas y preparación

Godot 4 incluye un **replicador y opciones de depuración de red** accesibles desde el editor (menú **Debug → Network** en las versiones que lo exponen) para inyectar latencia y pérdida en el peer local; consulta la guía de multijugador de Godot (<https://docs.godotengine.org/en/stable/tutorials/networking/index.html>). En Windows, descarga **clumsy** (<https://jagt.github.io/clumsy/>), una herramienta gratuita que degrada el tráfico por filtros. En Linux o en tu servidor headless, usa **tc/netem** (parte de `iproute2`). Prepara un proyecto simple con dos peers: un jugador local con predicción y un remoto interpolado usando `MultiplayerSynchronizer`, para tener algo observable que romper.

## 🧪 Laboratorio guiado

Vamos a instrumentar métricas, activar la simulación de red y observar cómo el remoto interpolado "salta" cuando degradamos la conexión.

**Paso 1 — Medir el RTT desde GDScript.** Un ping periódico cliente↔servidor con marca de tiempo.

```gdscript
# medidor_red.gd — en el cliente
extends Node

var _rtt_ms := 0.0
var _t := 0.0

func _process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		return
	_t += delta
	if _t >= 0.5:
		_t = 0.0
		ping.rpc_id(1, Time.get_ticks_msec())

@rpc("any_peer", "call_remote", "reliable")
func ping(t_cliente: int) -> void:
	# corre en el servidor: rebota al emisor
	var id := multiplayer.get_remote_sender_id()
	pong.rpc_id(id, t_cliente)

@rpc("authority", "call_remote", "reliable")
func pong(t_cliente: int) -> void:
	_rtt_ms = Time.get_ticks_msec() - t_cliente
	print("RTT = %.0f ms" % _rtt_ms)
```

**Paso 2 — Activar la simulación de red del editor.** En **Debug → Network** (o la sección equivalente de tu versión), fija por ejemplo: latencia entrante/saliente 120 ms, jitter 40 ms, pérdida 5 %. Alternativamente, degrada el sistema completo con clumsy o netem (pasos 4 y 5).

**Paso 3 — Remoto interpolado observable.** Un `MultiplayerSynchronizer` replica la posición; suavizamos hacia el último valor recibido para ver el efecto del jitter.

```gdscript
# remoto.gd — nodo del jugador remoto (autoridad del servidor)
extends CharacterBody2D

@onready var _sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
var _objetivo: Vector2

func _ready() -> void:
	_objetivo = global_position

func _on_synchronizer_synchronized() -> void:
	# nueva posición autoritativa recibida
	_objetivo = global_position

func _physics_process(delta: float) -> void:
	# interpolación simple hacia el último estado; con jitter, verás tirones
	global_position = global_position.lerp(_objetivo, clamp(delta * 12.0, 0.0, 1.0))
```

**Paso 4 — clumsy en Windows.**

```bash
# Con clumsy abierto (GUI), define un filtro que capture tu puerto de juego, p.ej.:
#   udp and (outbound or inbound) and udp.DstPort == 9000
# Activa: Lag 120 ms, Drop 5%, y pulsa Start.
# clumsy no es CLI puro; el filtro se escribe en su ventana.
```

**Paso 5 — tc/netem en Linux.**

```bash
# Añadir 120 ms de latencia con 40 ms de jitter y 5% de pérdida a la interfaz
sudo tc qdisc add dev eth0 root netem delay 120ms 40ms loss 5%

# Ver el estado aplicado
tc qdisc show dev eth0

# Quitar la degradación al terminar
sudo tc qdisc del dev eth0 root
```

Observable: con la red limpia el remoto se desliza suave; al aplicar 120 ms + 5 % de pérdida, el `RTT` impreso sube y el remoto interpolado avanza a tirones y "corrige" de golpe cuando llega un paquete rezagado. Ese comportamiento es exactamente el que debes suavizar o predecir.

## ✍️ Ejercicios

1. Registra el RTT en un buffer y calcula la media y el máximo (jitter percibido) cada 5 s.
2. Cuenta paquetes de estado recibidos por segundo y detecta caídas cuando subes la pérdida.
3. Sube el factor de `lerp` y describe cómo cambia el compromiso suavidad/latencia.
4. Aplica solo jitter (delay 0 100ms) sin pérdida y observa qué rompe la interpolación.
5. Ejecuta el servidor headless bajo netem y prueba dos clientes contra él.
6. Escribe una checklist de escenarios de red que probarás antes de cada release.

## 📝 Reto verificable

Entrega una demo con dos peers donde el jugador remoto se interpola y el cliente mide su RTT en pantalla o consola, y demuestra el comportamiento en **tres perfiles**: red limpia, 100 ms de latencia, y 150 ms + 8 % de pérdida (usando la simulación de Godot, clumsy o netem).

**Criterio de aceptación**: en red limpia el RTT impreso es cercano a 0–5 ms y el remoto se mueve suave; en el perfil degradado el RTT sube por encima de 100 ms y se observan tirones/correcciones en el remoto; el proceso de activar y desactivar la degradación es reproducible y está documentado.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| "Todo va perfecto" y no reproduces bugs | Solo probaste en localhost/LAN; degrada con simulación o netem |
| clumsy no afecta al juego | El filtro no captura el puerto/protocolo correctos; ajústalo al UDP de tu juego |
| netem no hace nada | Interfaz equivocada; usa la real (`ip a`), no `lo` para tráfico externo |
| El remoto tiembla incluso sin lag | Interpolas sobre el mismo frame que replicas; separa recepción de render |
| RTT sale negativo o absurdo | Comparas relojes de máquinas distintas; mide ida y vuelta en el mismo peer |

## ❓ Preguntas frecuentes

**¿No basta con probar en internet real?** Internet real no es reproducible: no puedes forzar exactamente 150 ms y 8 % de pérdida a demanda. La simulación te da escenarios repetibles para regresión.

**¿Latencia o pérdida rompen cosas distintas?** Sí. La latencia retrasa correcciones y desincroniza la predicción; la pérdida crea huecos en el estado que la interpolación debe rellenar.

**¿La simulación de Godot sustituye a netem?** Para iterar rápido en el editor sí; netem/clumsy prueban el stack completo (SO, driver, socket) y sirven en CI y servidores headless.

**¿Debo probar el servidor headless también?** Sí. Corre el servidor bajo netem para ver cómo se comporta la simulación autoritativa cuando los clientes llegan tarde.

## 🔗 Referencias

- Godot Docs — Networking (índice): <https://docs.godotengine.org/en/stable/tutorials/networking/index.html>
- clumsy (Windows): <https://jagt.github.io/clumsy/>
- netem — Emulación de red en Linux: <https://wiki.linuxfoundation.org/networking/netem>
- Godot Docs — MultiplayerSynchronizer: <https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html>

## ⬅️ Clase anterior

[Clase 152 - Backends: Nakama, Steam y servicios gestionados](../152-backends-nakama-steam-y-servicios-gestionados/README.md)

## ➡️ Siguiente clase

Continúa con **154 — Seguridad en multijugador: validación y exploits**, donde blindarás el servidor contra clientes tramposos.
