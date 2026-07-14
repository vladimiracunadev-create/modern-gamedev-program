# Clase 131 — Música adaptativa: transiciones horizontales

> Parte: **6 — Audio y música interactiva** · Fuente: *Documentación de audio de Godot 4 (AudioStreamInteractive, 4.3+) + GDC talks sobre horizontal re-sequencing*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Pasar de un tema a otro —de exploración a combate, de calma a jefe— **sin cortes bruscos**. Es el *horizontal re-sequencing*: en lugar de sumar capas (vertical), cambiamos el segmento que suena. Verás dos enfoques: el **crossfade** (fundir un tema con otro solapándolos) y la **transición en beat/compás** (esperar al siguiente punto musical para saltar, que suena mucho más natural). En Godot 4.3+ el recurso `AudioStreamInteractive` formaliza clips y transiciones con reglas de sincronización.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Distinguir el re-sequencing horizontal del layering vertical y cuándo usar cada uno.
- Implementar un crossfade entre dos temas con tweens sobre `volume_db`.
- Explicar por qué transicionar en el siguiente compás suena mejor que cortar al instante.
- Configurar un `AudioStreamInteractive` con clips y transiciones sincronizadas.
- Disparar el cambio de tema desde un evento del juego (entrar en combate).

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Re-sequencing horizontal | Cambiar de segmento en vez de sumar capas |
| 2 | Crossfade | Solución simple: solapar y fundir dos temas |
| 3 | Transición en beat/compás | Saltar en un punto musical evita el corte feo |
| 4 | `AudioStreamInteractive` | Recurso que gestiona clips y transiciones (4.3+) |
| 5 | Modos de transición | Inmediata, en compás, al final del clip |
| 6 | Fill/puente | Un pequeño clip de enlace suaviza el salto |
| 7 | Disparo desde gameplay | El estado del juego pide el cambio de música |

## 📖 Definiciones y características

- **Re-sequencing horizontal**: reordenar/segmentar la música en el tiempo para adaptarla. Clave: cambia *qué* suena, no *cuántas* capas.
- **Crossfade**: fundido cruzado; una pista baja mientras otra sube. Clave: fácil, pero puede sonar "aguado" si los temas no encajan.
- **Transición en beat**: esperar al siguiente pulso/compás para cambiar. Clave: respeta el ritmo y se percibe intencional, no accidental.
- **AudioStreamInteractive**: recurso de Godot 4.3+ que contiene varios clips y define transiciones entre ellos. Clave: centraliza reglas de sincronía.
- **Clip**: cada segmento musical (exploración, combate) dentro del recurso interactivo. Clave: se identifica por índice o nombre.
- **Modo de transición**: cuándo ocurre el cambio (inmediato, siguiente compás, fin de clip). Clave: define lo natural que suena.
- **Fill / puente**: clip corto de enlace que se intercala en la transición. Clave: rellena el hueco y da sensación de continuidad musical.

## 🧰 Herramientas y preparación

Consigue dos temas del mismo proyecto musical, idealmente al **mismo tempo** y en tonalidades compatibles: `exploracion.ogg` y `combate.ogg`, ambos en bucle. Para el enfoque manual con crossfade bastan dos `AudioStreamPlayer`. Para el enfoque con `AudioStreamInteractive` necesitas **Godot 4.3 o superior**; comprueba tu versión en *Help → About*. Revisa la [referencia de AudioStreamInteractive](https://docs.godotengine.org/en/stable/classes/class_audiostreaminteractive.html) y la [guía de música interactiva](https://docs.godotengine.org/en/stable/tutorials/audio/index.html). Coloca los OGG en `audio/musica/`.

## 🧪 Laboratorio guiado

Haremos primero un crossfade manual y luego una transición sincronizada con `AudioStreamInteractive`. Resultado audible: la música pasa de exploración a combate al "entrar en pelea" sin un corte abrupto.

**Paso 1 — Crossfade manual: escena.** Crea un nodo `MusicaHorizontal` con dos hijos `AudioStreamPlayer`: `Exploracion` y `Combate`, cada uno con su OGG en loop y bus `Music`. Ambos arrancarán a la vez, pero uno silenciado.

**Paso 2 — Script del crossfade.** El truco: reproducir ambos temas sincronizados desde el inicio y solo cruzar sus volúmenes. Así el combate ya está "en su sitio" temporal cuando entra:

```gdscript
extends Node

@onready var exploracion: AudioStreamPlayer = $Exploracion
@onready var combate: AudioStreamPlayer = $Combate

const SILENCIO := -60.0
var _en_combate := false

func _ready() -> void:
	exploracion.volume_db = 0.0
	combate.volume_db = SILENCIO
	# Ambos suenan desde el mismo instante para que el salto sea coherente.
	exploracion.play()
	combate.play()

func cambiar_a_combate(activo: bool) -> void:
	if activo == _en_combate:
		return
	_en_combate = activo
	var tween := create_tween().set_parallel(true)   # fundimos las dos a la vez
	tween.tween_property(exploracion, "volume_db", SILENCIO if activo else 0.0, 1.0)
	tween.tween_property(combate, "volume_db", 0.0 if activo else SILENCIO, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		cambiar_a_combate(not _en_combate)   # alterna con Espacio
```

**Paso 3 — Pruébalo.** Corre la escena y pulsa **Espacio**. La música de exploración se funde con la de combate en un segundo, y al volver a pulsar regresa. Como ambos temas comparten reloj, el cambio respeta el compás automáticamente.

**Paso 4 — Enfoque profesional: AudioStreamInteractive.** Crea un `AudioStreamPlayer` llamado `MusicaInteractiva`. En su `Stream`, elige *New AudioStreamInteractive*. Ábrelo: en *Clips*, añade dos y asigna `exploracion.ogg` y `combate.ogg`. Ponles nombre `explorar` y `pelear`.

**Paso 5 — Define las transiciones.** En el editor del `AudioStreamInteractive`, abre la matriz de transiciones. Configura de `explorar` a `pelear` con *From Time* = `Next Beat` (o `Next Bar` para el compás) y *Fade Mode* = `Crossfade`. Haz lo mismo de `pelear` a `explorar`. Esto obliga a que el salto ocurra en un punto musical, no a mitad de nota.

**Paso 6 — Dispara la transición por código.** Controla el clip activo con la API del reproductor interactivo:

```gdscript
extends Node

@onready var musica: AudioStreamPlayer = $MusicaInteractiva

func _ready() -> void:
	musica.play()
	# Arrancamos en el clip de exploración por su nombre.
	musica.get_stream_playback().switch_to_clip_by_name("explorar")

func entrar_en_combate() -> void:
	# La transición respeta el "Next Beat/Bar" definido en el recurso.
	musica.get_stream_playback().switch_to_clip_by_name("pelear")

func salir_de_combate() -> void:
	musica.get_stream_playback().switch_to_clip_by_name("explorar")
```

**Paso 7 — Compara los dos enfoques.** Con el crossfade manual controlas todo pero la sincronía al compás depende de arrancar juntos. Con `AudioStreamInteractive`, Godot espera al siguiente beat/compás y aplica el crossfade por ti: el salto suena claramente más musical.

**Resultado visible:** la música cambia de exploración a combate al dispararse un evento, primero por crossfade y luego con una transición cuantizada al compás que se percibe intencional y limpia.

## ✍️ Ejercicios

1. Cambia la duración del crossfade manual a `0.2` y a `3.0` s y describe el efecto en la sensación de urgencia.
2. En el `AudioStreamInteractive`, prueba *From Time* `Immediate` vs `Next Bar` y compara la naturalidad.
3. Añade un tercer clip (`jefe`) y define transiciones desde combate y exploración hacia él.
4. Configura un clip de *fill*/puente y actívalo como transición entre exploración y combate.
5. Conecta `entrar_en_combate()` a la detección de un enemigo cercano en vez de a una tecla.
6. Combina lo aprendido: usa capas verticales dentro del clip de combate para variar su intensidad.

## 📝 Reto verificable

Implementa un cambio de música entre dos estados de juego (exploración y combate) usando **transición en el siguiente compás**, ya sea con `AudioStreamInteractive` (clips + transiciones cuantizadas) o con un crossfade manual sobre temas sincronizados. El cambio debe dispararse desde un evento del juego y poder ir y volver.

**Criterio de aceptación**: al activar el combate la música cambia de tema sin un corte abrupto y respetando el pulso (la transición cae en un beat/compás, no a mitad de frase); al salir del combate vuelve al tema de exploración de forma igualmente limpia; y el disparo del cambio proviene de un evento de gameplay, no de reiniciar la música.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El cambio de tema suena a "corte" seco | Transicionas de forma inmediata; usa `Next Beat`/`Next Bar` o un crossfade |
| El crossfade suena aguado o desafinado | Los temas tienen distinto tempo o tonalidad; usa piezas compatibles |
| `AudioStreamInteractive` no aparece | Tu versión es anterior a 4.3; actualiza Godot o usa el crossfade manual |
| El combate empieza desde el principio del tema y desincroniza | Reinicias el player; mantén ambos sonando o deja que el recurso gestione la sincronía |
| `switch_to_clip_by_name` da error | El nombre no coincide con el del clip; revisa mayúsculas y espacios |
| La transición no espera al compás | *From Time* está en `Immediate`; cámbialo a `Next Bar` en la matriz |

## ❓ Preguntas frecuentes

**¿Horizontal o vertical: cuál uso?**
Vertical (capas) para intensidad continua sobre una misma pieza; horizontal (segmentos) para cambios de sección claros como exploración→combate. Muchos juegos combinan ambos.

**¿El crossfade manual es "peor" que AudioStreamInteractive?**
No necesariamente; es más laborioso y menos preciso al compás, pero funciona en cualquier versión de Godot y ofrece control total. `AudioStreamInteractive` te ahorra la lógica de sincronización.

**¿Qué es un clip de "fill"?**
Un fragmento musical corto (un redoble, un acorde de enlace) que se intercala durante la transición para tapar la costura entre secciones y darle continuidad.

**¿Puedo transicionar al final del clip en lugar de al siguiente compás?**
Sí: `AudioStreamInteractive` permite *From Time* = `End of Clip`, útil cuando cada segmento es una frase completa que quieres dejar terminar.

## 🔗 Referencias

- [AudioStreamInteractive — referencia de clase](https://docs.godotengine.org/en/stable/classes/class_audiostreaminteractive.html)
- [Audio interactivo en Godot 4 — documentación](https://docs.godotengine.org/en/stable/tutorials/audio/index.html)
- [AudioStreamPlayer — referencia de clase](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html)
- [GDC — Horizontal re-sequencing en música adaptativa](https://www.gdcvault.com/)

## ➡️ Siguiente clase

[Clase 132 - Middleware de audio: FMOD](../132-middleware-de-audio-fmod/README.md)
