# Clase 141 — RPCs: llamadas remotas y sincronización

> Parte: **7 — Multijugador y networking** · Fuente: *Documentación oficial de Godot 4 (RPC) + Glazer & Madhav, "Multiplayer Game Programming"*
> ⏱️ Duración estimada: **55 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Aprender la herramienta central de comunicación en Godot: los **RPC (Remote Procedure Calls)**. Al terminar sabrás anotar funciones con `@rpc` y elegir sus modos (`any_peer`/`authority`, `call_local`/`call_remote`, `reliable`/`unreliable`), distinguir `rpc()` (a todos) de `rpc_id()` (a uno), identificar al emisor con `get_remote_sender_id()` y, sobre todo, **validar en el servidor**. Construirás una acción compartida (un contador) que se propaga por RPC y luego su variante autoritativa.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Anotar funciones con `@rpc` y explicar cada uno de sus tres modos.
- Diferenciar `rpc()` de `rpc_id()` y elegir el adecuado por caso de uso.
- Usar `get_remote_sender_id()` para saber quién invocó un RPC.
- Elegir fiabilidad (`reliable`/`unreliable`) según el tipo de mensaje.
- Validar en el servidor un RPC recibido antes de aplicar sus efectos.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Anatomía de `@rpc` | Define quién puede llamar y cómo viaja |
| 2 | Modo de emisor: any_peer vs authority | Controla si un cliente puede invocar |
| 3 | call_local vs call_remote | Decide si el emisor también ejecuta |
| 4 | Fiabilidad: reliable/unreliable/ordered | Ancho de banda vs garantía de entrega |
| 5 | `rpc()` vs `rpc_id()` | Broadcast frente a mensaje dirigido |
| 6 | `get_remote_sender_id()` | Saber quién pidió la acción |
| 7 | Validación en el servidor | La única defensa real contra trampas |
| 8 | Patrón "input al servidor, efecto a todos" | Base de todo juego autoritativo |

## 📖 Definiciones y características

- **`@rpc`**: anotación que marca una función como invocable en remoto. Clave: sin ella, `mi_func.rpc()` no hace nada.
- **any_peer**: cualquier par puede invocar el RPC en otros. Clave: úsalo para input de clientes hacia el servidor, validando siempre.
- **authority**: solo el par con autoridad del nodo puede invocarlo. Clave: ideal para que el servidor difunda estado sin que un cliente lo falsifique.
- **call_local**: además de enviarse, la función se ejecuta también en el emisor. Clave: útil cuando el que dispara también debe ver el efecto.
- **reliable / unreliable / unreliable_ordered**: garantías de entrega y orden. Clave: usa `reliable` para eventos importantes y `unreliable` para estado que se sobrescribe.
- **`rpc(args)`**: invoca la función en todos los pares conectados. Clave: broadcast; combina con `call_local` si el emisor también debe correrla.
- **`rpc_id(id, args)`**: invoca la función en un par concreto. Clave: `rpc_id(1, ...)` es el patrón "mando esto al servidor".
- **`get_remote_sender_id()`**: dentro de un RPC, el id de quien lo originó. Clave: imprescindible para validar y responder al emisor correcto.

## 🧰 Herramientas y preparación

**Godot 4.x** y **dos instancias**. Reutiliza el patrón de conexión de las clases anteriores (crear servidor con `--server`, cliente sin argumentos). Ten abierta la [documentación de RPC de Godot 4](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#remote-procedure-calls). Añade a tu escena un `Button` (`BtnAccion`) y un `Label` (`Marcador`) para ver el contador compartido. Recuerda: los nombres de los nodos con `@rpc` deben coincidir en todos los pares porque el RPC se resuelve por ruta de nodo.

## 🧪 Laboratorio guiado

**Parte A — Contador compartido "confiado" (para entender el broadcast).** Cualquier cliente pulsa y todos incrementan. Escena `Contador` con `BtnAccion` y `Marcador`.

```gdscript
extends Node

var _valor := 0
@onready var _marcador: Label = $Marcador

func _ready() -> void:
	$BtnAccion.pressed.connect(_on_boton)
	# (Se asume peer ya creado como en clases previas.)

func _on_boton() -> void:
	# call_local hace que el emisor también ejecute incrementar().
	incrementar.rpc()

@rpc("any_peer", "call_local", "reliable")
func incrementar() -> void:
	_valor += 1
	_marcador.text = "Total: %d" % _valor
```

Con dos instancias, pulsar el botón en cualquiera sube el marcador en ambas. Funciona, pero **cada cliente tiene su propio `_valor`** y podrían divergir si alguien pierde un paquete o hace trampa. Vamos a arreglarlo.

**Parte B — Contador autoritativo (el servidor manda).** El cliente pide al servidor incrementar; el servidor valida, actualiza su valor real y difunde el número autoritativo a todos.

```gdscript
extends Node

var _valor := 0
@onready var _marcador: Label = $Marcador

func _ready() -> void:
	$BtnAccion.pressed.connect(_on_boton)

func _on_boton() -> void:
	# El cliente NO incrementa: solo solicita al servidor (id 1).
	solicitar_incremento.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func solicitar_incremento() -> void:
	# Se ejecuta SOLO en el servidor.
	if not multiplayer.is_server():
		return
	var quien := multiplayer.get_remote_sender_id()
	# Validación de ejemplo: podrías comprobar cooldown, permisos, etc.
	_valor += 1
	print("[SERVIDOR] Peer %d incrementó. Valor real=%d" % [quien, _valor])
	# El servidor difunde el valor autoritativo a todos (incluido él).
	fijar_valor.rpc(_valor)

@rpc("authority", "call_local", "reliable")
func fijar_valor(nuevo: int) -> void:
	# authority: solo el servidor puede llamar esto; los clientes lo obedecen.
	_valor = nuevo
	_marcador.text = "Total: %d" % _valor
```

**Cómo probarlo con dos instancias:** lanza servidor y cliente. En la versión autoritativa, pulsa el botón en el cliente: el marcador **no** cambia hasta que el servidor procesa y difunde `fijar_valor`. Así, aunque un cliente modificara su código, jamás podría inventar un valor: el `fijar_valor` es `authority` y solo lo emite el servidor. Ese es el patrón de oro: **input con `any_peer` + `rpc_id(1)`, estado con `authority` + `rpc()`**.

## ✍️ Ejercicios

1. Añade un cooldown de 500 ms por peer en el servidor: rechaza solicitudes demasiado seguidas usando `get_remote_sender_id()`.
2. Convierte `fijar_valor` a `unreliable` y explica en un comentario por qué aquí sería arriesgado.
3. Haz que el servidor también difunda **quién** hizo el último incremento y muéstralo en el marcador.
4. Crea un RPC `reiniciar` que solo el servidor pueda invocar (modo `authority`) y pruébalo.
5. Registra en el servidor un `Dictionary` id→número de clics y muestra un ranking.
6. Cambia el botón para enviar un valor de "cantidad" y valida en el servidor que esté entre 1 y 5.

## 📝 Reto verificable

Construye un "pulsador de equipo": cada cliente pulsa un botón para sumar puntos a un marcador global, pero el servidor solo acepta como máximo 2 pulsaciones por segundo por jugador (anti-spam). El marcador autoritativo se muestra idéntico en todas las instancias.

**Criterio de aceptación**: con 1 servidor + 2 clientes, pulsar rápido en un cliente incrementa como mucho 2 por segundo para ese jugador; el marcador es idéntico en las tres instancias en todo momento; un cliente no puede alterar el total salvo mediante el RPC validado.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El RPC no se ejecuta | Falta la anotación `@rpc` o el nombre/ruta del nodo difiere entre pares |
| El emisor no ve el efecto | Usaste `call_remote`; añade `call_local` si el emisor también debe ejecutar |
| Un cliente puede falsear el estado | Difundes con `any_peer`; el estado autoritativo debe ir con `authority` |
| `get_remote_sender_id()` devuelve 0 | Lo llamaste fuera de un contexto de RPC; solo es válido dentro del método invocado |
| El estado diverge entre clientes | Cada cliente calcula su valor; centraliza el cálculo en el servidor |

## ❓ Preguntas frecuentes

- **¿Cuándo uso `unreliable`?** Para datos que se reemplazan cada tick (posición, rotación): si uno se pierde, el siguiente lo corrige y ahorras ancho de banda.
- **¿`call_local` envía por la red al propio emisor?** No: ejecuta la función localmente además de enviarla a los demás; es una comodidad, no un viaje de red extra.
- **¿Puede un cliente llamar un RPC `authority`?** No en el nodo cuya autoridad no posee; Godot descarta esas llamadas, por eso es seguro para difundir estado.
- **¿Los argumentos de un RPC pueden ser cualquier cosa?** Deben ser tipos serializables por Godot (números, strings, arrays, dictionaries, vectores...). Evita pasar nodos u objetos complejos.

## 🔗 Referencias

- [RPC en high-level multiplayer (Godot 4)](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#remote-procedure-calls)
- [Anotaciones de GDScript (@rpc)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html)
- Gabriel Gambetta: [Client-Server Game Architecture](https://www.gabrielgambetta.com/client-server-game-architecture.html)
- [Clase MultiplayerAPI](https://docs.godotengine.org/en/stable/classes/class_multiplayerapi.html)

## ⬅️ Clase anterior

[Clase 140 - El multijugador de alto nivel de Godot (MultiplayerAPI)](../140-el-multijugador-de-alto-nivel-de-godot-multiplayerapi/README.md)

## ➡️ Siguiente clase

[Clase 142 - MultiplayerSpawner y MultiplayerSynchronizer](../142-multiplayerspawner-y-multiplayersynchronizer/README.md)
