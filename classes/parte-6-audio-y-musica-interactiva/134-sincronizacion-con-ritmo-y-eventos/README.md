# Clase 134 — Sincronización con ritmo y eventos

> Parte: **6 — Audio y música interactiva** · Fuente: *Godot Docs — Sync the movement with audio + documentación de AudioServer y AudioStreamPlayer*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Sincronizar la lógica del juego con la música al nivel del beat, como exige cualquier juego de ritmo. Aprenderás a calcular en qué beat estás a partir del BPM y la posición de reproducción, a corregir la latencia de salida para que "lo que se ve" cuadre con "lo que se oye", y a disparar eventos y cuantizar acciones exactamente en el pulso. Al terminar tendrás un metrónomo/spawner que emite en cada beat, perfectamente alineado con la canción.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Calcular el tiempo de un beat a partir del BPM y convertir la posición de audio en número de beat.
- Obtener la posición precisa de reproducción con `get_playback_position()` y afinarla con el reloj del mezclador.
- Compensar la latencia de salida usando `AudioServer.get_output_latency()`.
- Emitir eventos justo en cada beat y evitar disparos duplicados o perdidos.
- Cuantizar una acción del jugador al beat más cercano.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | El beat como unidad de tiempo musical | Todo juego de ritmo razona en beats, no en segundos sueltos |
| 2 | De BPM a segundos por beat | Es la conversión base para colocar cualquier evento |
| 3 | `get_playback_position()` | Da el reloj maestro: la música manda, no el `delta` |
| 4 | Afinar con el reloj del mezclador | Corrige el salto de la posición entre frames |
| 5 | Latencia de salida | Sin compensarla, el efecto visual llega antes que el sonido |
| 6 | Disparar en cada beat | Detectar el cruce de beat sin duplicar ni saltar |
| 7 | Cuantización de acciones | Ajustar la entrada del jugador al pulso más cercano |
| 8 | Precisión frame a frame | El `_process` no basta; hay que apoyarse en el audio |

## 📖 Definiciones y características

- **BPM (beats por minuto)**: tempo de la música. Clave: `segundos_por_beat = 60 / BPM`.
- **Beat**: pulso musical, la rejilla temporal sobre la que ocurren los eventos. Clave: se numera desde el inicio de la canción.
- **Posición de reproducción**: segundos transcurridos dentro del stream, vía `AudioStreamPlayer.get_playback_position()`. Clave: es el reloj maestro, más fiable que acumular `delta`.
- **Reloj del mezclador**: `AudioServer.get_time_since_last_mix()` indica cuánto pasó desde el último bloque mezclado. Clave: sumarlo a la posición reduce el jitter entre frames.
- **Latencia de salida**: retardo entre que Godot manda el audio y suena en los altavoces, `AudioServer.get_output_latency()`. Clave: hay que restarla para alinear lo visual con lo audible.
- **Cruce de beat**: momento en que el número de beat actual supera al anterior. Clave: la señal para disparar exactamente una vez por beat.
- **Cuantización**: redondear el instante de una acción al beat (o subdivisión) más cercano. Clave: perdona el error humano y hace que todo "suene a tiempo".

## 🧰 Herramientas y preparación

Necesitas Godot 4.x y una pista musical con un BPM conocido y constante (un loop de 120 BPM funciona bien; anota su BPM exacto). Importa el audio como OGG para música larga. Ten a la vista la [referencia de AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html), la de [AudioServer](https://docs.godotengine.org/en/stable/classes/class_audioserver.html) y el tutorial [Sincronizar el juego con el audio](https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html), que explica por qué conviene usar el reloj del audio en lugar del reloj del frame. Prepara un nodo visual sencillo (un `ColorRect` o un `Sprite2D`) para que el pulso sea observable, no solo audible.

## 🧪 Laboratorio guiado

Construiremos un metrónomo que emite una señal en cada beat, sincronizado con la canción y con la latencia compensada. Un cuadrado parpadeará y aparecerán marcas en consola exactamente en el pulso.

**Paso 1 — Escena.** Crea una escena con un `Node2D` raíz, añade un `AudioStreamPlayer` (con tu canción en `stream`) y un `ColorRect` visible. Adjunta un script al raíz.

**Paso 2 — Datos del tempo.** Declara el BPM y calcula los segundos por beat. Lleva la cuenta del último beat emitido para detectar cruces:

```gdscript
extends Node2D

@export var bpm: float = 120.0
@onready var _player: AudioStreamPlayer = $AudioStreamPlayer
@onready var _cuadro: ColorRect = $ColorRect

var _seg_por_beat: float = 0.0
var _ultimo_beat: int = -1

signal beat(numero: int)  # se emite una vez por beat

func _ready() -> void:
	_seg_por_beat = 60.0 / bpm
	connect("beat", Callable(self, "_on_beat"))
	_player.play()
```

**Paso 3 — Posición corregida.** Cada frame calcula el tiempo de la canción con la posición del stream, más el tiempo del mezclador, menos la latencia de salida. Esa resta es la que alinea el destello con el sonido:

```gdscript
func _tiempo_cancion() -> float:
	# Reloj maestro = posición del stream, afinada con el mezclador
	# y compensando la latencia de la tarjeta de sonido.
	var t := _player.get_playback_position()
	t += AudioServer.get_time_since_last_mix()
	t -= AudioServer.get_output_latency()
	return maxf(t, 0.0)
```

**Paso 4 — Detectar el cruce de beat.** Convierte el tiempo en número de beat con una división entera. Cuando aumenta, emite la señal una sola vez:

```gdscript
func _process(_delta: float) -> void:
	if not _player.playing:
		return
	var beat_actual := int(_tiempo_cancion() / _seg_por_beat)
	if beat_actual > _ultimo_beat:
		_ultimo_beat = beat_actual
		emit_signal("beat", beat_actual)
```

**Paso 5 — Reaccionar al beat.** En el manejador, haz algo observable: parpadea el cuadro e imprime el beat. Aquí también podrías spawnear un enemigo o lanzar un SFX en el pulso:

```gdscript
func _on_beat(numero: int) -> void:
	print("Beat ", numero)
	# Destello: encender y apagar con un pequeño temporizador.
	_cuadro.color = Color.WHITE
	get_tree().create_timer(0.08).timeout.connect(
		func() -> void: _cuadro.color = Color.BLACK
	)
```

**Paso 6 — Cuantizar una acción.** Añade una entrada del jugador y redondéala al beat más cercano para medir su precisión, como haría un juez de ritmo:

```gdscript
func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("golpear"):
		var t := _tiempo_cancion()
		var beat_frac := t / _seg_por_beat
		var beat_cercano := roundf(beat_frac)
		var error_seg := absf(beat_frac - beat_cercano) * _seg_por_beat
		var veredicto := "PERFECTO" if error_seg < 0.05 else "a destiempo"
		print("Golpe en beat %.2f -> %d (%s, %.3f s)" % [beat_frac, int(beat_cercano), veredicto, error_seg])
```

**Paso 7 — Ejecuta.** Verás el cuadro parpadear en el pulso de la música y, al pulsar `golpear`, un veredicto según lo cerca que caíste del beat. Como usamos el reloj del audio y restamos la latencia, el destello coincide con lo que oyes.

**Resultado visible:** un metrónomo que parpadea a tiempo con la canción y evalúa la precisión rítmica de tus pulsaciones.

## ✍️ Ejercicios

1. Añade subdivisiones: emite también en las corcheas (medio beat) con una segunda señal.
2. Marca los tiempos fuertes: acentúa el destello en el beat 1 de cada compás de 4/4.
3. Spawnea un `Sprite2D` que caiga hacia una línea y "acierte" justo en el beat.
4. Expón un margen de acierto configurable y clasifica los golpes en PERFECTO/BIEN/FALLO.
5. Compara la sincronía usando `delta` acumulado frente al reloj del audio; anota la deriva.
6. Añade un compás de cuenta atrás (4 beats) antes de que empiece a spawnear.

## 📝 Reto verificable

Entrega un "spawner rítmico": cada beat aparece un objetivo y el jugador debe pulsar en el beat; el juego muestra en pantalla el número de beat y un contador de aciertos PERFECTO/BIEN/FALLO según el error temporal, con la latencia de salida compensada.

**Criterio de aceptación**: los objetivos aparecen alineados con el pulso audible (sin desfase perceptible), la clasificación de aciertos usa `get_output_latency()` en el cálculo, y el sistema no duplica ni omite beats aunque cambien los FPS.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El destello va adelantado respecto al sonido | No restaste `get_output_latency()`; añádela al cálculo del tiempo |
| Se saltan o repiten beats | Usas `delta` acumulado; cambia al reloj de `get_playback_position()` |
| La sincronía se degrada con el tiempo | Acumulas error de frame; recalcula el beat desde la posición cada frame |
| Un beat dispara varias veces | No guardas el último beat emitido; compara `beat_actual > _ultimo_beat` |
| El primer beat llega tarde | La posición arranca en 0 y la latencia la vuelve negativa; usa `maxf(t, 0.0)` |

## ❓ Preguntas frecuentes

**¿Por qué no uso simplemente `delta` para contar el tiempo?**
Porque el reloj del frame se desvía del audio: pequeños errores se acumulan y en un minuto ya notas el desfase. La posición de reproducción es el reloj fiable.

**¿Qué hace exactamente `get_output_latency()`?**
Devuelve el retardo entre que el motor entrega el audio y suena en el hardware. Restarlo alinea los eventos visuales con lo que el jugador realmente oye.

**¿Y si mi canción tiene BPM variable?**
Este método asume BPM constante. Para tempo variable necesitas un mapa de tempo (lista de cambios) y calcular el beat por tramos.

**¿Sirve esto con FMOD o Wwise?**
El principio es el mismo, pero esos middlewares exponen su propio reloj y marcadores de beat. Aquí trabajamos con la API nativa de Godot.

## 🔗 Referencias

- [Sincronizar el juego con el audio — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html)
- [AudioServer — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_audioserver.html)
- [AudioStreamPlayer — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html)
- [Latencia de audio — concepto general](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html)

## ➡️ Siguiente clase

[Clase 135 - Voces, diálogo y localización de audio](../135-voces-dialogo-y-localizacion-de-audio/README.md)
