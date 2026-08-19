# Clase 316 — Observabilidad de juegos

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *OpenTelemetry · Google, «Site Reliability Engineering» (monitoring y alerting)*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Poder responder a la pregunta "¿qué está pasando en producción?" **sin adivinar**. Un juego publicado corre en miles de máquinas que no controlas, con drivers, sistemas y hardware que no tienes. Cuando algo falla, o tienes instrumentación o tienes reseñas de una estrella diciendo "se cierra solo".

Vas a instrumentar un juego con los tres pilares de la observabilidad —**logs estructurados**, **métricas** y **trazas**— más lo que es específico de los juegos: **crash reporting** con stack traces simbolizadas y minidumps. Y vas a aprender la distinción que más problemas ahorra: **logging de depuración** (para ti, mientras desarrollas, verboso y libre) frente a **telemetría de producción** (para operar, estructurada, con esquema, con volumen acotado y con implicaciones de privacidad).

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Distinguir logs, métricas y trazas, y elegir el pilar adecuado para cada pregunta.
2. Implementar logging estructurado con niveles, campos y muestreo.
3. Implementar métricas de juego (contadores, gauges, histogramas) con agregación local.
4. Propagar un **correlation id** entre cliente y servidor y explicar para qué sirve.
5. Capturar y enviar informes de crash con contexto útil y sin datos personales.
6. Explicar qué son los símbolos y por qué sin ellos un stack trace es inútil.
7. Definir alertas basadas en síntomas y evitar la fatiga de alertas.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Los tres pilares | Cada uno responde a un tipo distinto de pregunta. |
| 2 | Log estructurado | Un log que no se puede consultar es un log que no existe. |
| 3 | Niveles y muestreo | El volumen es el enemigo: cuesta dinero y esconde lo importante. |
| 4 | Métricas | Responden "¿cuánto?" y "¿va peor que ayer?" con poco volumen. |
| 5 | Histogramas y percentiles | La media miente; el p99 es la experiencia de tus peores sesiones. |
| 6 | Trazas y correlation id | Permiten seguir una operación entre cliente y servidor. |
| 7 | Crash reporting | El evento más valioso, y el más fácil de perder. |
| 8 | Símbolos | Sin ellos, el stack trace son direcciones sin nombre. |
| 9 | Debug vs producción | Dos sistemas distintos con requisitos opuestos. |
| 10 | Alertas | Alertar de síntomas, no de causas; y solo de lo accionable. |

## 📖 Definiciones y características

- **Observabilidad**: capacidad de entender el estado interno de un sistema desde sus salidas. Clave: no es "tener logs", es poder responder preguntas que no previste.
- **Log estructurado**: registro con campos nombrados en vez de texto libre. Clave: se puede filtrar, agrupar y agregar.
- **Nivel de log**: severidad (`trace`, `debug`, `info`, `warn`, `error`, `fatal`). Clave: permite ajustar volumen sin cambiar código.
- **Muestreo (sampling)**: enviar solo una fracción de los eventos repetidos. Clave: mantiene el coste acotado sin perder la señal.
- **Métrica**: valor numérico agregado en el tiempo. Clave: barato en volumen y perfecto para tendencias.
- **Contador**: métrica que solo crece (partidas jugadas, errores). Clave: se consulta por su tasa de cambio.
- **Gauge**: métrica que sube y baja (memoria, jugadores conectados). Clave: interesa su valor actual.
- **Histograma**: distribución de valores en cubos. Clave: es lo que permite calcular percentiles.
- **Percentil (p50, p95, p99)**: valor por debajo del cual cae ese porcentaje de muestras. Clave: el p99 describe la experiencia de los peores casos, que es donde está el problema.
- **Traza (trace)**: registro del recorrido de una operación por varios componentes. Clave: responde "¿dónde se fue el tiempo?".
- **Span**: cada tramo de una traza, con inicio, fin y atributos. Clave: se anidan para formar la traza.
- **Correlation id**: identificador que acompaña a una operación por todos los sistemas. Clave: es lo que une el log del cliente con el del servidor.
- **Crash report**: informe de un cierre inesperado con pila, versión y contexto. Clave: el dato más valioso de producción.
- **Stack trace**: pila de llamadas en el momento del fallo. Clave: solo es legible con los símbolos correspondientes.
- **Símbolos (debug symbols)**: información que traduce direcciones a nombres de función y líneas. Clave: se guardan por build y **no** se distribuyen con el juego.
- **Minidump**: volcado reducido del estado del proceso al fallar. Clave: permite depurar a posteriori con el depurador.
- **Cardinalidad**: número de valores distintos de una etiqueta. Clave: etiquetar por `player_id` hace explotar el coste de las métricas.
- **Alerta por síntoma**: alerta basada en lo que el jugador nota. Clave: alertar de causas produce ruido y falsos positivos.
- **Fatiga de alertas**: efecto de recibir tantas alertas que se ignoran. Clave: una alerta que nadie atiende es peor que ninguna.

## 🧰 Herramientas y preparación

Trabajaremos en `res://infraestructura/observabilidad/`. No necesitas contratar nada: el laboratorio escribe a un `SinkLocal` (archivo en `user://`) y a un `SinkMock` que la CI puede inspeccionar. Documentación de referencia conceptual: [OpenTelemetry](https://opentelemetry.io/docs/what-is-opentelemetry/) (el estándar abierto de logs, métricas y trazas) y la [clase 278](../../parte-16-produccion-publicacion-monetizacion-y-liveops/278-analitica-de-juego-y-telemetria/README.md), que introdujo la analítica de producto; esta clase es su hermana técnica, orientada a **operar** y no a **entender el comportamiento**.

## 🧪 Laboratorio guiado

1. **Los tres pilares, y qué pregunta responde cada uno.** Elegir mal es la causa de la mitad de los problemas de coste:

| Pregunta | Pilar | Por qué |
|---|---|---|
| ¿Cuántos jugadores han crasheado hoy? | Métrica | Es un número agregado |
| ¿Por qué crasheó *este* jugador? | Log + crash report | Hace falta el detalle del caso |
| ¿Dónde se van los 3 s de la carga? | Traza | Hay que ver el reparto por tramos |
| ¿Va peor que la semana pasada? | Métrica | Es una tendencia |
| ¿Qué hizo el jugador antes del fallo? | Log (breadcrumbs) | Es una secuencia |

2. **El log estructurado.** Campos, no frases:

```gdscript
class_name Log
extends RefCounted

enum Nivel { TRACE, DEBUG, INFO, WARN, ERROR, FATAL }

const NOMBRES := ["trace", "debug", "info", "warn", "error", "fatal"]

static var nivel_minimo: Nivel = Nivel.INFO
static var _sinks: Array = []
static var _contexto := {}          # campos que acompañan a TODOS los eventos
static var _vistos := {}            # para el muestreo de repetidos

static func contexto(clave: String, valor: Variant) -> void:
	_contexto[clave] = valor

static func emitir(n: Nivel, evento: String, campos: Dictionary = {}) -> void:
	if n < nivel_minimo:
		return
	# Muestreo de repetidos: el mismo evento 10.000 veces no aporta 10.000
	# veces más información, y sí cuesta 10.000 veces más.
	var clave := "%s|%d" % [evento, n]
	var cuenta := int(_vistos.get(clave, 0)) + 1
	_vistos[clave] = cuenta
	if cuenta > 10 and cuenta % 100 != 0:
		return

	var registro := {
		"t": Time.get_unix_time_from_system(),
		"nivel": NOMBRES[n],
		"evento": evento,            # nombre ESTABLE: se agrupa por él
		"repeticiones": cuenta,
	}
	registro.merge(_contexto)
	registro.merge(campos, true)
	for s in _sinks:
		s.escribir(registro)

static func info(evento: String, campos: Dictionary = {}) -> void:  emitir(Nivel.INFO, evento, campos)
static func warn(evento: String, campos: Dictionary = {}) -> void:  emitir(Nivel.WARN, evento, campos)
static func error(evento: String, campos: Dictionary = {}) -> void: emitir(Nivel.ERROR, evento, campos)
```

Compara las dos formas de registrar lo mismo:

```gdscript
print("El jugador Ana no pudo comprar la poción porque no tenía oro")   # ilegible para una máquina

Log.warn("compra_rechazada", {"motivo": "sin_saldo", "sku": "pocion_menor",
							  "precio": 15, "saldo": 8})               # agrupable y contable
```

Con la segunda puedes preguntar "¿cuántas compras se rechazan por saldo y de qué SKU?" sin escribir una expresión regular.

3. **Las métricas.** Agregación local y envío por lotes:

```gdscript
class_name Metricas
extends RefCounted

var _contadores := {}
var _gauges := {}
var _histogramas := {}

const CUBOS_MS := [1.0, 2.0, 4.0, 8.0, 16.0, 33.0, 66.0, 133.0, 500.0, 1000.0]

func incrementar(nombre: String, etiquetas := {}, n := 1) -> void:
	var clave := _clave(nombre, etiquetas)
	_contadores[clave] = int(_contadores.get(clave, 0)) + n

func fijar(nombre: String, valor: float, etiquetas := {}) -> void:
	_gauges[_clave(nombre, etiquetas)] = valor

func observar(nombre: String, valor: float, etiquetas := {}) -> void:
	var clave := _clave(nombre, etiquetas)
	var h: Array = _histogramas.get(clave, [])
	if h.is_empty():
		h.resize(CUBOS_MS.size() + 1)
		h.fill(0)
	var i := 0
	while i < CUBOS_MS.size() and valor > CUBOS_MS[i]:
		i += 1
	h[i] = int(h[i]) + 1
	_histogramas[clave] = h

func _clave(nombre: String, etiquetas: Dictionary) -> String:
	# CARDINALIDAD: nunca etiquetar por player_id, sesión, posición ni nada
	# con miles de valores. Cada combinación distinta es una serie temporal
	# más que alguien paga.
	var partes := PackedStringArray([nombre])
	var claves := etiquetas.keys(); claves.sort()
	for k in claves:
		assert(not str(k) in ["player_id", "sesion", "correlation_id"],
			"etiqueta de alta cardinalidad en una métrica: %s" % k)
		partes.append("%s=%s" % [k, etiquetas[k]])
	return "|".join(partes)

func percentil(nombre: String, p: float, etiquetas := {}) -> float:
	var h: Array = _histogramas.get(_clave(nombre, etiquetas), [])
	if h.is_empty():
		return 0.0
	var total := 0
	for c in h: total += int(c)
	var objetivo := int(total * p)
	var acumulado := 0
	for i in h.size():
		acumulado += int(h[i])
		if acumulado >= objetivo:
			return CUBOS_MS[i] if i < CUBOS_MS.size() else CUBOS_MS[-1] * 2.0
	return CUBOS_MS[-1] * 2.0
```

4. **Instrumentar el frame.** Lo que de verdad importa medir en un juego:

```gdscript
func _process(delta: float) -> void:
	# El frame time va a histograma, NO a media: una media de 16 ms puede
	# esconder un tirón de 300 ms cada dos segundos, que es justo lo que el
	# jugador nota.
	_metricas.observar("frame_time_ms", delta * 1000.0,
		{"escena": _escena_actual, "calidad": _preset_grafico})

	if delta > 0.1:
		# Un tirón grande sí merece un log con contexto.
		Log.warn("tiron_de_frame", {"ms": delta * 1000.0, "escena": _escena_actual,
								   "entidades": get_tree().get_node_count()})

func _cada_60s() -> void:
	_metricas.fijar("memoria_mb", OS.get_static_memory_usage() / 1048576.0)
	_metricas.fijar("jugadores_en_partida", _partida.jugadores.size())
```

5. **Trazas y correlation id.** Para seguir una operación de punta a punta:

```gdscript
class_name Traza
extends RefCounted

var id: String = ""
var _spans: Array[Dictionary] = []
var _abiertos := {}

static func nueva(rng: RandomNumberGenerator) -> Traza:
	var t := Traza.new()
	t.id = "%08x%08x" % [rng.randi(), rng.randi()]
	return t

func abrir(nombre: String) -> void:
	_abiertos[nombre] = Time.get_ticks_usec()

func cerrar(nombre: String, atributos := {}) -> void:
	if not _abiertos.has(nombre):
		return
	var us := Time.get_ticks_usec() - int(_abiertos[nombre])
	_abiertos.erase(nombre)
	var s := {"span": nombre, "ms": us / 1000.0, "trace_id": id}
	s.merge(atributos)
	_spans.append(s)

func volcar() -> void:
	for s in _spans:
		Log.info("span", s)
```

```gdscript
# El correlation id viaja en la cabecera de la petición y el servidor lo
# registra. Así, cuando un jugador reporta "no pude comprar", buscas ese id y
# ves las dos mitades de la historia.
func comprar(sku: StringName) -> void:
	var tr := Traza.nueva(_rng)
	tr.abrir("compra_total")
	tr.abrir("validacion_local")
	var ok := _validar(sku)
	tr.cerrar("validacion_local", {"ok": ok})

	tr.abrir("peticion_backend")
	var r := await _backend.pedir_con_cabeceras(
		"/comprar", {"sku": sku}, {"X-Correlation-Id": tr.id})
	tr.cerrar("peticion_backend", {"codigo": r.codigo})

	tr.cerrar("compra_total", {"resultado": r.ok})
	tr.volcar()
```

6. **Crash reporting.** El informe más valioso, y el que hay que capturar con cuidado:

```gdscript
class_name Crash
extends RefCounted

const MAX_MIGAS := 30

static var _migas: Array[Dictionary] = []

static func miga(evento: String, datos := {}) -> void:
	# Breadcrumbs: los últimos pasos antes del fallo. Son lo que convierte
	# "crasheó en el frame 40.213" en "crasheó al abrir el mapa tras morir".
	_migas.append({"t": Time.get_ticks_msec(), "evento": evento, "datos": datos})
	if _migas.size() > MAX_MIGAS:
		_migas.pop_front()

static func informe(mensaje: String, pila: Array) -> Dictionary:
	return {
		"tipo": "crash",
		"mensaje": mensaje,
		"pila": pila,
		"build": ProjectSettings.get_setting("application/config/version", "desconocida"),
		"motor": Engine.get_version_info()["string"],
		"so": OS.get_name(),
		"cpu": OS.get_processor_name(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"memoria_mb": OS.get_static_memory_usage() / 1048576.0,
		"tiempo_sesion": Time.get_ticks_msec() / 1000.0,
		"migas": _migas.duplicate(),
		# Nada de nombre, correo, IP ni ruta de usuario: ver clase 317.
		"jugador_anonimo": _id_anonimo(),
	}
```

En Godot, los errores de script se pueden capturar con `get_stack()` dentro de un manejador; para los cierres nativos (motor, driver) hacen falta minidumps del sistema o un servicio de crash reporting. Lo importante conceptualmente es esto:

- Los **símbolos** de cada build se archivan al publicar (clase [322](../322-build-y-release-engineering/README.md)) y **no** se distribuyen.
- Sin símbolos, la pila es una lista de direcciones y no sirve de nada.
- Un crash report sin la **versión exacta de la build** tampoco sirve: no sabrás con qué símbolos leerlo.

7. **Alertas que se pueden atender.** Menos y mejores:

| Alerta | ¿Buena? | Por qué |
|---|---|---|
| "CPU del servidor al 85 %" | ✗ | Es una causa, y puede ser normal |
| "Tasa de crash > 1 % de sesiones (5 min)" | ✓ | Síntoma que el jugador nota |
| "p99 de latencia de compra > 3 s" | ✓ | Síntoma medible y accionable |
| "Ha aparecido un error nuevo" | ✗ | Ruido: siempre hay errores nuevos |
| "Errores 5xx > 2 % durante 10 min" | ✓ | Umbral y ventana claros |
| "Sesiones iniciadas caen un 50 % vs la semana pasada" | ✓ | Detecta fallos que no dan error |

Regla práctica: **si al recibir la alerta no hay nada que hacer, no debería ser una alerta**. Debería ser un panel.

8. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	var sink := SinkMock.new()
	Log._sinks = [sink]
	Log.nivel_minimo = Log.Nivel.INFO
	Log.contexto("build", "1.4.2")

	Log.emitir(Log.Nivel.DEBUG, "no_deberia_salir")
	assert(sink.registros.is_empty(), "el nivel mínimo no filtró")

	Log.warn("compra_rechazada", {"motivo": "sin_saldo"})
	assert(sink.registros.size() == 1)
	assert(sink.registros[0]["build"] == "1.4.2", "el contexto global no se adjuntó")
	assert(sink.registros[0]["evento"] == "compra_rechazada")

	# Muestreo: 1.000 repeticiones no producen 1.000 registros.
	for i in 1000:
		Log.warn("repetido", {})
	assert(sink.contar("repetido") < 30, "el muestreo no acotó el volumen")

	# Métricas: percentiles sobre histograma.
	var m := Metricas.new()
	for i in 100:
		m.observar("frame_time_ms", 16.0 if i < 99 else 500.0)
	assert(m.percentil("frame_time_ms", 0.5) <= 16.0)
	assert(m.percentil("frame_time_ms", 0.99) > 100.0, "el p99 no refleja el tirón")

	# Cardinalidad: una etiqueta acotada sí; `player_id` dispara el assert de
	# `_clave()` (compruébalo a mano descomentando la línea siguiente).
	m.incrementar("partidas", {"modo": "arena"})
	# m.incrementar("partidas", {"player_id": "plr_1"})   # <- debe abortar
	assert(m._contadores.size() == 1, "la métrica etiquetada no se registró")

	print("== 7 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Implementa `SinkArchivo` con rotación por tamaño y borrado de los más antiguos.
2. Añade envío por lotes cada 60 s con reintento y cola persistente si no hay red.
3. Instrumenta el tiempo de carga de tu juego con spans y averigua dónde se va.
4. Añade un panel de depuración en el juego que muestre p50/p95/p99 de frame time en vivo.
5. Implementa breadcrumbs automáticos para cambios de escena y errores.
6. Define las cinco alertas de tu juego con umbral, ventana y acción concreta.
7. Escribe un test que falle si algún nombre de evento de log no está en una lista blanca.

## 📝 Reto verificable

Implementa observabilidad completa: logs estructurados con niveles, contexto global y muestreo; métricas con contadores, gauges e histogramas con percentiles; trazas con spans y correlation id; y crash reports con breadcrumbs, contexto de máquina y build.

**Criterio de aceptación**: una prueba headless con **al menos 16 aserciones** demuestra que: (a) los eventos por debajo del nivel mínimo no se emiten; (b) 1.000 repeticiones del mismo evento producen menos de 30 registros; (c) todos los registros llevan el contexto global; (d) el p99 de un histograma con un 1 % de valores altos refleja el valor alto y el p50 no; (e) intentar etiquetar una métrica con `player_id` falla el `assert`; (f) una traza con tres spans anidados produce tres registros con el mismo `trace_id` y tiempos coherentes; (g) el crash report incluye build, SO, GPU y las últimas 30 migas, y **no** contiene nombre de usuario, correo, IP ni rutas absolutas del sistema.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La factura de logs se dispara | Se envía todo sin muestrear ni filtrar. Nivel mínimo, muestreo y lotes. |
| No se puede buscar nada en los logs | Son frases de texto libre. Log estructurado con nombres de evento estables. |
| La media de frame time es buena y el juego va a tirones | La media esconde la cola. Usa histogramas y mira p95/p99. |
| Las métricas cuestan una fortuna | Alta cardinalidad en las etiquetas. Nunca etiquetes por jugador ni sesión. |
| Los crashes llegan con la pila ilegible | Faltan símbolos de esa build. Archívalos al publicar y guárdalos por versión. |
| El crash report no dice qué hacía el jugador | Faltan breadcrumbs. Registra los últimos eventos relevantes. |
| Nadie atiende las alertas | Fatiga: hay demasiadas y muchas no son accionables. Alerta de síntomas, no de causas. |
| Un log escribe el nombre del jugador | Se mezcló depuración con producción. Los datos personales no van a telemetría (clase 317). |
| El logging hace tirones | Se escribe a disco en el hilo principal en cada evento. Encola y vuelca en segundo plano. |

## ❓ Preguntas frecuentes

**❓ ¿Logs o métricas?** Métricas para "¿cuánto y cómo evoluciona?", logs para "¿qué pasó exactamente en este caso?". Empieza por métricas —son mucho más baratas— y usa logs para el detalle. Si necesitas un log por cada partida de cada jugador para hacer un recuento, eso era una métrica.

**❓ ¿Puedo mandar todos los logs de depuración a producción?** No, por tres razones: coste (crece con el número de jugadores), ruido (lo importante se pierde) y privacidad (los logs de depuración suelen contener datos que no deben salir del dispositivo). Son dos sistemas distintos, y conviene que ni siquiera compartan API.

**❓ ¿Qué es exactamente un símbolo y por qué me importa?** Es el archivo que asocia direcciones de memoria del binario con nombres de función y líneas de código. Los binarios de release se publican sin ellos (para reducir tamaño y no regalar información), pero se archivan al construir. Sin el símbolo de **esa build exacta**, un crash trae direcciones que no se pueden traducir.

**❓ ¿Necesito trazas en un juego single-player?** Para operaciones locales, casi nunca: basta con medir tiempos. Las trazas brillan cuando una operación cruza procesos o máquinas (cliente → backend → base de datos), que es donde la pregunta "¿dónde se fue el tiempo?" no tiene respuesta obvia.

**❓ ¿Cómo evito recoger datos personales sin darme cuenta?** Con una lista blanca: define qué campos pueden salir y rechaza el resto en el propio emisor. Es más fiable que revisar caso por caso, y es exactamente el enfoque de la [clase 317](../317-telemetria-privacidad-y-gobernanza-de-datos/README.md).

## 🔗 Referencias

- OpenTelemetry — qué es y modelo de logs, métricas y trazas: <https://opentelemetry.io/docs/what-is-opentelemetry/> · uso: se instala o se consulta en la preparación
- Google — *Site Reliability Engineering*, capítulos de monitorización y alerting: <https://sre.google/books/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `OS` (información de sistema y memoria): <https://docs.godotengine.org/en/4.3/classes/class_os.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `Engine` y `RenderingServer` (versión y adaptador de vídeo): <https://docs.godotengine.org/en/4.3/classes/class_renderingserver.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — Depuración y `get_stack`: <https://docs.godotengine.org/en/4.3/tutorials/scripting/debug/index.html> · uso: respalda el Tema 9 «Debug vs producción»

## ⬅️ Clase anterior

[Clase 315 - Remote Config, feature flags y experimentos](../315-remote-config-feature-flags-y-experimentos/README.md)

## ➡️ Siguiente clase

[Clase 317 - Telemetría, privacidad y gobernanza de datos](../317-telemetria-privacidad-y-gobernanza-de-datos/README.md)
