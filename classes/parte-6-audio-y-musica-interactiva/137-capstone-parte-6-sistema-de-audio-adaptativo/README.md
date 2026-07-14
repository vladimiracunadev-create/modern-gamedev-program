# Clase 137 — Capstone Parte 6: sistema de audio adaptativo

> Parte: **6 — Audio y música interactiva** · Fuente: *Integración de la Parte 6 — Godot Docs (AudioServer, AudioStreamInteractive, AudioStreamRandomizer, buses) + patrón Autoload*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Integrar todo lo aprendido en la Parte 6 en un único **AudioManager** (Autoload) que orqueste el audio de un pequeño nivel: buses con ducking, SFX con variación mediante `AudioStreamRandomizer`, audio 3D posicional, música adaptativa por capas verticales con transición a combate, y un pool optimizado con límite de voces. Al terminar tendrás una especificación clara, un checklist, una definición de "hecho" y un guion de playtesting, además del esqueleto del Autoload ensamblado y funcionando.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Diseñar la arquitectura de un sistema de audio centralizado como Autoload.
- Combinar buses con ducking, SFX con variación y audio 3D en un mismo sistema.
- Orquestar música adaptativa (capas verticales + transición a combate) desde código.
- Aplicar un pool con límite de voces dentro del gestor global.
- Verificar el sistema con un checklist y una definición de "hecho" objetivos.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | AudioManager como Autoload | Un único punto de control evita audio disperso y duplicado |
| 2 | Buses y ducking | La mezcla dinámica hace que la voz y los SFX destaquen |
| 3 | Variación con Randomizer | Evita la fatiga de oír siempre el mismo clip |
| 4 | Audio 3D posicional | Sitúa el sonido en el espacio y da información al jugador |
| 5 | Música adaptativa vertical | Añadir/quitar capas comunica intensidad sin cortar la pista |
| 6 | Transición a combate | Cambiar de estado musical de forma fluida y a tiempo |
| 7 | Pool con límite de voces | Mantiene el rendimiento bajo carga |
| 8 | Especificación y DoD | Sin criterios, "terminado" es una opinión |

## 📖 Definiciones y características

- **AudioManager (Autoload)**: singleton global registrado en *Project Settings → Autoload*. Clave: accesible desde cualquier escena sin instanciarlo.
- **Ducking**: atenuar un bus (música) cuando otro suena (voz/impacto), con un `AudioEffectCompressor` en sidechain o bajando `volume_db` por código. Clave: claridad en momentos importantes.
- **AudioStreamRandomizer**: recurso que elige un stream y varía tono/volumen al azar. Clave: variación sin lógica manual por cada disparo.
- **AudioStreamPlayer3D**: reproductor con posición en el mundo y atenuación por distancia. Clave: espacialidad real.
- **AudioStreamInteractive**: recurso de música adaptativa con clips y transiciones entre ellos. Clave: cambiar de sección musical desde código de forma controlada.
- **Capas verticales**: pistas superpuestas (base, percusión, tensión) que se activan/silencian. Clave: intensidad gradual sin reiniciar la música.
- **Definition of Done (DoD)**: lista de condiciones que hacen la tarea aceptable. Clave: cierra la discusión sobre si está listo.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x y los recursos de las clases previas: SFX cortos (WAV) para el Randomizer, un clip de audio 3D, y música organizada en capas o como `AudioStreamInteractive` con un clip de exploración y otro de combate. Configura los buses en *Audio* (Master, Musica, SFX, Voz) y prepara el ducking en el bus Musica. Registra el `AudioManager` como Autoload en *Project Settings → Autoload*. Ten a mano las referencias de [AudioStreamRandomizer](https://docs.godotengine.org/en/stable/classes/class_audiostreamrandomizer.html), [AudioStreamInteractive](https://docs.godotengine.org/en/stable/classes/class_audiostreaminteractive.html), [AudioStreamPlayer3D](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html) y la guía de [buses de audio](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html).

## 🧪 Laboratorio guiado

Ensamblaremos el `AudioManager` como Autoload que expone una API limpia: reproducir SFX (con pool y variación), reproducir SFX 3D, controlar capas de música y transicionar a combate con ducking.

**Paso 1 — Registrar el Autoload.** Crea `res://audio/audio_manager.gd`, y en *Project Settings → Autoload* añádelo con el nombre `AudioManager`. Así podrás llamar `AudioManager.sfx(...)` desde cualquier parte.

**Paso 2 — Esqueleto y pool.** El gestor crea su pool de SFX y guarda referencias a los buses:

```gdscript
extends Node
# Autoload: AudioManager. Punto único de control del audio del juego.

@export var max_voces_sfx: int = 12

var _pool: Array[AudioStreamPlayer] = []
var _idx_musica: int = -1   # índice del bus Musica
var _en_combate: bool = false

func _ready() -> void:
	_idx_musica = AudioServer.get_bus_index("Musica")
	for i in max_voces_sfx:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
```

**Paso 3 — SFX con variación y pool.** El `stream` puede ser un `AudioStreamRandomizer`, que ya varía tono y clip por sí mismo. El pool aporta el límite de voces:

```gdscript
func sfx(stream: AudioStream, volumen_db: float = 0.0) -> void:
	var p := _voz_libre()
	if p == null:
		return  # presupuesto agotado: descartamos este disparo
	p.stream = stream            # idealmente un AudioStreamRandomizer
	p.volume_db = volumen_db
	p.play()

func _voz_libre() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing:
			return p
	return null
```

**Paso 4 — SFX 3D posicional.** Para sonidos situados en el mundo, instancia un `AudioStreamPlayer3D` temporal en una posición y libéralo al terminar:

```gdscript
func sfx_3d(stream: AudioStream, posicion: Vector3, padre: Node3D) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.bus = "SFX"
	padre.add_child(p)
	p.global_position = posicion
	p.finished.connect(p.queue_free)  # se autolibera al acabar
	p.play()
```

**Paso 5 — Ducking hacia combate.** Al entrar en combate, atenuamos el bus de música un instante (ducking) y subimos la capa de tensión. Aquí lo hacemos por código sobre el `volume_db` del bus:

```gdscript
func entrar_combate() -> void:
	if _en_combate:
		return
	_en_combate = true
	# Duck breve de la música para marcar el cambio.
	var v := AudioServer.get_bus_volume_db(_idx_musica)
	AudioServer.set_bus_volume_db(_idx_musica, v - 6.0)
	var t := create_tween()
	t.tween_method(
		func(db: float) -> void: AudioServer.set_bus_volume_db(_idx_musica, db),
		v - 6.0, v, 0.6
	)
	_activar_capa_combate(true)

func salir_combate() -> void:
	_en_combate = false
	_activar_capa_combate(false)
```

**Paso 6 — Capas verticales.** Con `AudioStreamInteractive` cambias de clip (exploración ↔ combate) respetando la transición definida en el recurso; con capas manuales, subes/bajas el volumen de una pista de tensión:

```gdscript
@onready var _musica: AudioStreamPlayer = $Musica  # su stream: AudioStreamInteractive

func _activar_capa_combate(activar: bool) -> void:
	var reproductor := _musica.get_stream_playback()  # AudioStreamPlaybackInteractive
	if reproductor:
		# Cambia al clip por su nombre definido en el recurso interactivo.
		reproductor.switch_to_clip_by_name("combate" if activar else "exploracion")
```

**Paso 7 — Probar el sistema completo.** Desde el gameplay, llama a la API del Autoload:

```gdscript
# En cualquier escena, sin instanciar nada:
AudioManager.sfx(preload("res://audio/sfx/impacto.tres"))       # Randomizer
AudioManager.sfx_3d(preload("res://audio/sfx/paso.wav"), pos, self)
AudioManager.entrar_combate()   # duck + capa de combate
# ...al terminar la pelea:
AudioManager.salir_combate()
```

Verás y oirás: SFX que suenan distintos cada vez, pasos localizados en el espacio 3D, y la música que se ensombrece un momento y sube su capa de tensión al entrar en combate, todo sin superar el límite de voces.

**Resultado visible:** un nivel jugable donde el audio reacciona al estado del juego desde un único gestor, con variación, espacialidad, ducking y música adaptativa.

## 📋 Tabla de features del AudioManager

| Feature | Clase de origen | Método del gestor |
|---------|-----------------|-------------------|
| Pool con límite de voces | 136 | `sfx()` / `_voz_libre()` |
| Variación de SFX | 127 | stream `AudioStreamRandomizer` |
| Audio 3D posicional | 129 | `sfx_3d()` |
| Buses y ducking | 128 | `entrar_combate()` |
| Música adaptativa vertical | 130 | `_activar_capa_combate()` |
| Transición a combate | 131 | `entrar_combate()` / `salir_combate()` |

## ✅ Checklist / Definition of Done

- [ ] El `AudioManager` está registrado como Autoload y es accesible globalmente.
- [ ] Existen los buses Master, Musica, SFX y Voz con enrutado correcto.
- [ ] Los SFX usan `AudioStreamRandomizer` y suenan con variación audible.
- [ ] El pool nunca supera `max_voces_sfx` voces simultáneas.
- [ ] Hay al menos un SFX 3D que se atenúa con la distancia y se autolibera.
- [ ] Al entrar en combate se aplica ducking y sube la capa/clip de combate.
- [ ] La transición exploración↔combate es fluida, sin cortes bruscos.
- [ ] No hay fugas: los nodos temporales se liberan con `queue_free`.

## ✍️ Ejercicios

1. Añade un bus de Voz con ducking sobre Musica y reproduce una línea que atenúe la música.
2. Sustituye el ducking por código por un `AudioEffectCompressor` en sidechain y compara.
3. Añade una tercera capa musical (percusión) que entre a mitad de combate.
4. Expón el volumen de cada bus en un menú de opciones que persista entre sesiones.
5. Añade prioridad al pool para que impactos importantes roben voces a pasos menores.
6. Mide el número máximo de voces en una escena de estrés y ajusta `max_voces_sfx`.

## 📝 Reto verificable

Ensambla un mini-nivel jugable donde, controlado por el `AudioManager`, el jugador provoca SFX con variación, escucha sonidos 3D posicionados, y al entrar en una zona de combate la música cambia con ducking y capa de tensión, volviendo a la exploración al salir. Entrega el Autoload, los buses configurados y el checklist marcado.

**Criterio de aceptación**: todas las casillas del checklist se cumplen; la transición a combate ocurre sin corte perceptible y con ducking audible; los SFX repetidos suenan distintos; los sonidos 3D se atenúan con la distancia; y bajo una ráfaga de SFX no se superan las voces del pool ni aparecen fugas de nodos.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| `AudioManager` no existe en runtime | No lo registraste como Autoload; añádelo en Project Settings |
| El ducking se queda "pegado" bajo | No restauras el volumen; usa un tween que vuelva al valor original |
| Los SFX 3D se acumulan y no se liberan | Falta `finished.connect(queue_free)`; autolibéralos al terminar |
| La transición a combate corta la música | Cambias de clip sin transición; define transiciones en el `AudioStreamInteractive` |
| Todos los SFX suenan idénticos | El stream es un WAV fijo, no un `AudioStreamRandomizer`; usa el recurso de variación |
| Chasquidos bajo mucha carga | El pool es demasiado pequeño o no limitas voces; ajusta `max_voces_sfx` |

## ❓ Preguntas frecuentes

**¿Por qué centralizar el audio en un Autoload?**
Porque tener un único punto de control evita reproductores dispersos, facilita la mezcla global y permite cambiar el estado sonoro (combate, pausa) desde cualquier escena con una sola llamada.

**¿Ducking por código o con compresor sidechain?**
Ambos valen. Por código es simple y explícito; el `AudioEffectCompressor` en sidechain es más orgánico y estándar en producción. Empieza por código y evoluciona.

**¿AudioStreamInteractive reemplaza a manejar capas a mano?**
Facilita las transiciones entre secciones (clips) con reglas definidas en el recurso. Para capas verticales finas puedes seguir combinándolo con control de volumen por pista.

**¿Cómo sé que el sistema está "terminado"?**
Cuando cumple la Definition of Done: todas las casillas del checklist marcadas y el reto verificable superado en un playtest real.

## 🔗 Referencias

- [AudioStreamRandomizer — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_audiostreamrandomizer.html)
- [AudioStreamInteractive — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_audiostreaminteractive.html)
- [AudioStreamPlayer3D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html)
- [Buses de audio (mezcla y efectos) — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html)
- [Singletons (Autoload) — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)

## ➡️ Siguiente clase

[Clase 138 - Fundamentos de redes para juegos: TCP, UDP y latencia](../../parte-7-multijugador-y-networking/138-fundamentos-de-redes-para-juegos-tcp-udp-y-latencia/README.md)
