# Clase 136 — Optimización de audio: memoria y streaming

> Parte: **6 — Audio y música interactiva** · Fuente: *Godot Docs — Importing audio samples + referencias de AudioStreamWAV, AudioStreamOggVorbis y AudioStreamPlayer*
> ⏱️ Duración estimada: **50 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Aprender a que el audio no se coma la memoria ni el CPU: elegir entre WAV y OGG con criterio, activar streaming para la música, limitar el número de voces simultáneas y reutilizar reproductores con un pool. Al terminar habrás construido un pool de `AudioStreamPlayer` para SFX con límite de voces que puedes medir, y habrás configurado la música para que se transmita desde disco en lugar de cargarse entera en RAM.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Decidir entre WAV y OGG según el compromiso entre RAM, CPU y latencia.
- Activar streaming en la música y explicar qué problema resuelve.
- Limitar la polifonía para no saturar el mezclador con demasiadas voces.
- Implementar un pool de reproductores reutilizables para SFX.
- Medir el uso del pool y ajustar su tamaño y la distancia de corte.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | WAV vs OGG | El formato define cuánta RAM y cuánto CPU cuesta cada sonido |
| 2 | Streaming de música | Evita cargar canciones enteras en memoria |
| 3 | Límite de voces (polifonía) | Demasiadas voces saturan el CPU y ensucian la mezcla |
| 4 | Presupuesto de audio | Fijar un tope de voces y memoria guía todas las decisiones |
| 5 | Pool de reproductores | Reutilizar nodos evita crear/destruir en caliente |
| 6 | Distancia de corte | No reproducir lo que el jugador no oiría ahorra voces |
| 7 | Robo de voz (voice stealing) | Qué hacer cuando el pool está lleno |
| 8 | Medir para decidir | Sin datos, la "optimización" es adivinar |

## 📖 Definiciones y características

- **WAV (AudioStreamWAV)**: audio descomprimido. Clave: baja latencia y CPU casi nulo al reproducir, pero ocupa mucha RAM; ideal para SFX cortos y frecuentes.
- **OGG (AudioStreamOggVorbis)**: audio comprimido Vorbis. Clave: poca RAM/disco a cambio de descomprimir en CPU; ideal para música y voces largas.
- **Streaming**: reproducir leyendo desde disco por trozos en vez de cargar todo. Clave: música de minutos con memoria casi constante.
- **Polifonía**: número de voces que un reproductor o bus puede sonar a la vez. Clave: limitarla protege el CPU y la claridad.
- **Presupuesto de audio**: tope acordado de voces simultáneas y memoria. Clave: convierte decisiones sueltas en una política.
- **Pool de reproductores**: conjunto fijo de `AudioStreamPlayer` reutilizables. Clave: cero asignaciones en runtime y control total del máximo de voces.
- **Distancia de corte**: radio más allá del cual un sonido no se reproduce. Clave: descarta lo inaudible antes de gastar una voz.
- **Robo de voz**: reemplazar el sonido más viejo o menos importante cuando el pool está lleno. Clave: prioriza lo relevante sin exceder el presupuesto.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x, un puñado de SFX cortos (impactos, pasos) que importarás como WAV, y una canción larga que importarás como OGG con streaming activado. En el inspector de importación de Godot puedes marcar *Loop* y, para el OGG, comprobar que el recurso es un `AudioStreamOggVorbis` con streaming. Revisa la guía de [importar samples de audio](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html), la [referencia de AudioStreamWAV](https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html) y la de [AudioStreamOggVorbis](https://docs.godotengine.org/en/stable/classes/class_audiostreamoggvorbis.html). Abre el *Monitor* del depurador (pestaña *Debugger → Monitors*) para observar memoria y número de nodos mientras pruebas el pool.

## 🧪 Laboratorio guiado

Construiremos un pool de reproductores para SFX con un tope de voces y robo del más viejo, y configuraremos la música con streaming. Contaremos las voces activas para medir el efecto del límite.

**Paso 1 — Escena.** Crea una escena con un `Node` raíz (`SfxPool`). Adjunta un script. La música vivirá en un `AudioStreamPlayer` aparte con el OGG en streaming asignado en `stream`.

**Paso 2 — Crear el pool.** En `_ready`, instancia N reproductores hijos de una sola vez. Ese N es tu presupuesto de voces para SFX:

```gdscript
extends Node

@export var max_voces: int = 8            # presupuesto de polifonía para SFX
@export var bus_sfx: String = "SFX"

var _pool: Array[AudioStreamPlayer] = []
var _voces_activas: int = 0

func _ready() -> void:
	for i in max_voces:
		var p := AudioStreamPlayer.new()
		p.bus = bus_sfx
		add_child(p)
		# Al terminar, la voz vuelve a estar libre.
		p.finished.connect(_on_voz_libre)
		_pool.append(p)

func _on_voz_libre() -> void:
	_voces_activas = maxi(_voces_activas - 1, 0)
```

**Paso 3 — Reproducir con reutilización.** Busca un reproductor libre; si no hay, roba el que lleva más tiempo sonando. Nunca creas nodos nuevos:

```gdscript
func reproducir(sfx: AudioStream, volumen_db: float = 0.0, pitch: float = 1.0) -> void:
	var libre := _buscar_libre()
	if libre == null:
		libre = _robar_mas_viejo()   # pool lleno: voice stealing
	else:
		_voces_activas += 1
	libre.stream = sfx
	libre.volume_db = volumen_db
	libre.pitch_scale = pitch
	libre.play()

func _buscar_libre() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing:
			return p
	return null

func _robar_mas_viejo() -> AudioStreamPlayer:
	# Estrategia simple: el primero de la lista. Reordenamos para rotar.
	var victima: AudioStreamPlayer = _pool.pop_front()
	_pool.push_back(victima)
	victima.stop()
	return victima
```

**Paso 4 — Distancia de corte.** Antes de gastar una voz, descarta lo que el jugador no oiría. Pásale la posición del emisor y del oyente:

```gdscript
func reproducir_posicional(sfx: AudioStream, origen: Vector2, oyente: Vector2, corte: float = 800.0) -> void:
	if origen.distance_to(oyente) > corte:
		return   # inaudible: no gastamos voz
	# Atenúa por distancia de forma simple (más lejos, más bajo).
	var d := origen.distance_to(oyente)
	var vol := lerpf(0.0, -40.0, clampf(d / corte, 0.0, 1.0))
	reproducir(sfx, vol)
```

**Paso 5 — Medir.** Expón el número de voces activas para verlo mientras disparas SFX en ráfaga:

```gdscript
func _process(_delta: float) -> void:
	# En un juego real, dibújalo en un Label de depuración.
	# Aquí basta con imprimir cada cierto tiempo o al pulsar una tecla.
	pass

func voces_activas() -> int:
	return _voces_activas
```

**Paso 6 — Música con streaming.** Verifica en el inspector que el OGG de la música tiene streaming (es el comportamiento de `AudioStreamOggVorbis`) y arráncala aparte del pool:

```gdscript
# En el nodo de música (otro AudioStreamPlayer):
# $Musica.stream es un AudioStreamOggVorbis (se transmite desde disco).
# $Musica.play()  -> memoria casi constante aunque la canción dure minutos.
```

**Paso 7 — Probar.** Dispara 20 SFX en un instante: verás que nunca suenan más de `max_voces` a la vez porque el pool roba las voces más viejas, y que la memoria se mantiene estable gracias al streaming de la música. Sube y baja `max_voces` y observa el cambio en densidad sonora y en el monitor.

**Resultado visible:** una ráfaga de SFX limitada a N voces simultáneas, con memoria estable y voces robadas de forma controlada.

## ✍️ Ejercicios

1. Añade una prioridad por SFX y roba primero las voces de menor prioridad.
2. Compara la RAM del proyecto importando un SFX largo como WAV y como OGG; anota ambos valores.
3. Muestra en un `Label` las voces activas y el tamaño del pool en tiempo real.
4. Convierte la reproducción posicional a `AudioStreamPlayer2D` con atenuación real por distancia.
5. Haz configurable la distancia de corte por tipo de sonido y justifica dos valores distintos.
6. Añade una pequeña variación de `pitch_scale` aleatoria para que los SFX repetidos no cansen.

## 📝 Reto verificable

Entrega un sistema de audio con un pool de SFX de tamaño configurable (con robo de voz y distancia de corte) y música en streaming, más un panel de depuración que muestre las voces activas. Demuestra que, ante una ráfaga de peticiones, nunca se superan las voces del presupuesto.

**Criterio de aceptación**: al lanzar más SFX que `max_voces` en un frame, el contador de voces activas nunca excede `max_voces`; la música larga se reproduce sin que la memoria crezca de forma sostenida; y los sonidos fuera de la distancia de corte no consumen voces.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La memoria se dispara con la música | La importaste como WAV o sin streaming; usa OGG con streaming para pistas largas |
| Chasquidos y CPU alto con muchos SFX | Sin límite de voces; introduce un pool con tope y robo del más viejo |
| Crear un `AudioStreamPlayer` por cada disparo tironea | Asignar/liberar nodos en caliente es caro; reutiliza un pool fijo |
| Suenan sonidos que deberían ser inaudibles | No aplicas distancia de corte; descarta por distancia antes de reproducir |
| El contador de voces se desincroniza | No decrementas en `finished`; conecta la señal y ajusta el conteo al terminar |

## ❓ Preguntas frecuentes

**¿Cuándo uso WAV y cuándo OGG?**
WAV para SFX cortos y muy repetidos (baja latencia, CPU casi nulo, más RAM). OGG para música y voces largas (poca RAM y disco, algo de CPU al descomprimir).

**¿El streaming añade latencia a los SFX?**
Para SFX cortos no conviene: prefieres WAV descomprimido. El streaming es para pistas largas donde la memoria importa más que arrancar al instante.

**¿Qué tamaño de pool elijo?**
Depende del presupuesto y del juego. Empieza pequeño (8-16 voces para SFX), mide en escenas densas y ajústalo hasta que no oigas cortes molestos.

**¿Qué es "robar" una voz?**
Cuando el pool está lleno y llega un sonido nuevo, reemplazas el menos importante o el más viejo. Así respetas el tope sin perder los sonidos relevantes.

## 🔗 Referencias

- [Importar samples de audio — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html)
- [AudioStreamWAV — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html)
- [AudioStreamOggVorbis — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_audiostreamoggvorbis.html)
- [AudioStreamPlayer — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html)

## ⬅️ Clase anterior

[Clase 135 - Voces, diálogo y localización de audio](../135-voces-dialogo-y-localizacion-de-audio/README.md)

## ➡️ Siguiente clase

[Clase 137 - Capstone Parte 6: sistema de audio adaptativo](../137-capstone-parte-6-sistema-de-audio-adaptativo/README.md)
