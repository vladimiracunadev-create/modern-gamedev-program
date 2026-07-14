# Clase 020 — Audio digital: muestreo, formatos y mezcla

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Teoría de audio digital y documentación de Audio de Godot*
> ⏱️ Duración estimada: **90 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

El sonido da vida a un juego, pero también es una fuente frecuente de decisiones técnicas mal entendidas: qué frecuencia de muestreo usar, cuándo comprimir, cómo controlar el volumen sin que todo suene mal. Entender el audio digital te permite elegir formatos correctos para efectos y música y mezclarlos con **buses** en lugar de ajustar volúmenes a mano.

En esta clase verás el **muestreo** (sample rate 44.1/48 kHz), la **profundidad de bits**, el **PCM**, los formatos (**WAV** sin comprimir para SFX, **OGG/MP3** para música), **mono vs estéreo**, los **buses de audio** y la mezcla, el **volumen en dB**, la **latencia** y el **audio 2D posicional**. Lo aplicarás en Godot importando un WAV y un OGG, configurando buses Master/Music/SFX y reproduciendo desde GDScript.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar qué son el sample rate, la profundidad de bits y el PCM.
2. Elegir WAV para efectos y OGG/MP3 para música justificando la decisión.
3. Configurar buses de audio (Master, Music, SFX) y enrutar sonidos a ellos.
4. Reproducir audio desde GDScript y ajustar el volumen por bus en decibelios.
5. Distinguir audio mono, estéreo y posicional 2D.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Muestreo (sample rate) | Determina qué frecuencias se pueden reproducir. |
| 2 | Profundidad de bits / PCM | Define el rango dinámico y la calidad. |
| 3 | WAV vs OGG/MP3 | Sin comprimir para SFX, comprimido para música. |
| 4 | Mono vs estéreo | Uso de canales y coste en memoria. |
| 5 | Buses de audio | Agrupar y mezclar sonidos por categoría. |
| 6 | Volumen en dB | Escala logarítmica del sonido. |
| 7 | Latencia | Retardo entre disparo y sonido. |
| 8 | Audio 2D posicional | El sonido varía según la posición en escena. |

## 📖 Definiciones y características

- **Muestreo (sample rate)**: número de muestras por segundo, en Hz. Clave: 44.1 kHz y 48 kHz son los estándares.
- **Profundidad de bits**: bits por muestra (p. ej. 16 bits). Clave: más bits, mayor rango dinámico.
- **PCM**: representación digital sin comprimir de la onda. Clave: es lo que contiene un WAV típico.
- **WAV**: formato sin pérdida ni compresión. Clave: ideal para efectos cortos por su baja latencia de decodificación.
- **OGG/MP3**: formatos comprimidos con pérdida. Clave: adecuados para música larga por su bajo peso.
- **Bus de audio**: canal de mezcla que agrupa sonidos y aplica volumen/efectos. Clave: en Godot todo pasa por el bus **Master**.
- **Decibelio (dB)**: unidad logarítmica de volumen; 0 dB es el nivel de referencia. Clave: valores negativos bajan el volumen.
- **Audio 2D posicional**: sonido cuyo volumen/paneo depende de la posición de su emisor. Clave: en Godot lo da `AudioStreamPlayer2D`.

## 🧰 Herramientas y preparación

Usarás **Godot 4** (<https://godotengine.org/>) con dos archivos de audio: un **WAV** corto para un efecto (SFX) y un **OGG** para música con bucle. Puedes conseguir sonidos libres en <https://freesound.org/> o <https://opengameart.org/>. Para editar y convertir audio usa **Audacity** (<https://www.audacityteam.org/>), que exporta a WAV y OGG. La referencia es la documentación de audio de Godot (<https://docs.godotengine.org/en/stable/tutorials/audio/index.html>), en concreto los buses (<https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html>) y la reproducción de streams (<https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html>).

## 🧪 Laboratorio guiado

### Paso 1 — Importar SFX (WAV) y música (OGG)

Copia los archivos al proyecto, por ejemplo `res://audio/salto.wav` y `res://audio/tema.ogg`. Selecciona `tema.ogg` en FileSystem, abre la pestaña **Import** y activa **Loop** para que la música se repita; pulsa **Reimport**. El WAV puede quedarse sin loop (un efecto no se repite). Godot decodifica el OGG en memoria y reproduce el WAV directamente.

### Paso 2 — Crear los buses Master, Music y SFX

Abre el panel **Audio** (pestaña inferior junto a Output/Debugger). Verás el bus **Master**. Pulsa **Add Bus** dos veces y renómbralos **Music** y **SFX**. Deja su salida (**Send**) hacia **Master**. Así, bajar el Master baja todo, y puedes controlar música y efectos por separado.

### Paso 3 — Reproducir desde GDScript enrutando a cada bus

Añade dos nodos **AudioStreamPlayer**: uno para música y otro para SFX. Asigna sus streams y su bus, o hazlo por código:

```gdscript
extends Node

@onready var musica: AudioStreamPlayer = $Musica
@onready var sfx: AudioStreamPlayer = $Sfx

func _ready() -> void:
    musica.stream = load("res://audio/tema.ogg")
    musica.bus = "Music"        # enruta la música al bus Music
    musica.play()

    sfx.stream = load("res://audio/salto.wav")
    sfx.bus = "SFX"             # enruta el efecto al bus SFX

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):  # Enter/Espacio
        sfx.play()                            # dispara el efecto
```

Ejecuta: la música suena en bucle y al pulsar Espacio se reproduce el efecto.

### Paso 4 — Ajustar el volumen por bus en decibelios

Controla el volumen de cada bus por su índice en el AudioServer. Recuerda que el volumen es logarítmico: `-6 dB` es aproximadamente la mitad de sonoridad percibida.

```gdscript
func bajar_musica() -> void:
    var idx := AudioServer.get_bus_index("Music")
    AudioServer.set_bus_volume_db(idx, -12.0)  # baja la música 12 dB

func silenciar_sfx(silenciar: bool) -> void:
    var idx := AudioServer.get_bus_index("SFX")
    AudioServer.set_bus_mute(idx, silenciar)   # silencia solo los efectos
```

Comprueba que bajar el bus **Music** no afecta al volumen de los efectos: esa es la ventaja de mezclar por buses en lugar de ajustar cada sonido.

## ✍️ Ejercicios

1. Convierte tu WAV a OGG en Audacity y compara el peso en disco.
2. Añade un tercer bus **UI** y enruta a él un sonido de clic.
3. Cambia el volumen del bus Master a `-6 dB` y describe el efecto en toda la mezcla.
4. Usa `AudioStreamPlayer2D` y mueve su nodo para oír el cambio de volumen/paneo posicional.
5. Explica en dos líneas por qué usarías WAV para un disparo y OGG para la música de fondo.
6. Fuerza un WAV a mono en Audacity y compara su tamaño con la versión estéreo.

## 📝 Reto verificable

Crea una escena con música en bucle enrutada al bus **Music** y al menos un efecto enrutado al bus **SFX**, más un control (por teclado) que baje o silencie solo el bus de música sin afectar los efectos. Los formatos deben ser coherentes: OGG para la música y WAV para el efecto. **Criterio de aceptación**: la música suena en bucle, el efecto se dispara al pulsar una tecla, y al bajar/silenciar el bus Music los efectos siguen sonando con normalidad.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La música no se repite | No activaste **Loop** en el Import del OGG; márcalo y reimporta. |
| `Invalid bus name` o silencio | El nombre del bus no coincide (mayúsculas); usa el nombre exacto del panel Audio. |
| El efecto suena con retardo | Latencia por decodificar formato comprimido; usa WAV para SFX cortos. |
| Bajar Master no cambia nada | El bus del reproductor no envía a Master; revisa el enrutado **Send**. |
| Distorsión / clipping | Suma de volúmenes supera 0 dB; baja el nivel de los buses. |
| El audio posicional no cambia | Usaste `AudioStreamPlayer` (no posicional); usa `AudioStreamPlayer2D`. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué WAV para efectos y OGG para música?** El WAV no necesita decodificarse, así que dispara efectos con latencia mínima; la música es larga y el OGG la comprime mucho ahorrando memoria y tamaño de build.

**❓ ¿44.1 o 48 kHz?** Ambas son válidas; 44.1 kHz es el estándar histórico y 48 kHz el habitual en vídeo. Lo importante es mantener coherencia y no sobredimensionar sin necesidad.

**❓ ¿Por qué el volumen se mide en dB negativos?** La escala en decibelios es logarítmica y 0 dB es el nivel de referencia (sin atenuación); los valores negativos reducen el volumen de forma perceptualmente natural.

**❓ ¿Qué gano usando buses en vez de ajustar cada sonido?** Controlas categorías completas (música, efectos, UI) con un solo mando, aplicas efectos por grupo y ofreces al jugador ajustes de volumen separados.

## 🔗 Referencias

- Godot — Audio (índice de tutoriales): <https://docs.godotengine.org/en/stable/tutorials/audio/index.html>
- Godot — Audio buses: <https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html>
- Godot — AudioStreamPlayer (clase): <https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html>
- Audacity (editor de audio): <https://www.audacityteam.org/>
- Freesound (sonidos libres): <https://freesound.org/>

## ➡️ Siguiente clase

[Clase 021 - Assets y pipeline de contenido: import, compresión y presupuestos](../021-assets-y-pipeline-de-contenido-import-compresion-y-presupuestos/README.md)
