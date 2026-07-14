# Clase 128 — Buses, efectos y mezcla dinámica

> Parte: **6 — Audio y música interactiva** · Fuente: *Documentación de audio de Godot 4 (Audio Buses, AudioServer, AudioEffect)*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dejar atrás la mezcla plana —donde música, efectos e interfaz suenan al mismo nivel y nada destaca— y montar una **mesa de mezclas** real dentro de Godot con buses (Master, Music, SFX, UI). Aprenderás a insertar efectos (reverb, compresor, EQ, filtro paso-bajo) en cada bus y a hacer **mezcla dinámica**: bajar la música cuando ocurre algo importante (*ducking*) y aplicar un filtro paso-bajo cuando el personaje entra en el agua. Todo controlado desde código con `AudioServer`.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Crear y organizar buses de audio (Master, Music, SFX, UI) y enrutar players a ellos.
- Insertar efectos en un bus y explicar qué hace cada uno (reverb, compresor, EQ, low-pass).
- Ajustar el volumen de un bus por código con `AudioServer.set_bus_volume_db()`.
- Implementar *ducking*: atenuar la música mientras suena un SFX destacado.
- Cambiar la mezcla según el estado del juego (por ejemplo, sumergido bajo el agua).

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Buses de audio | Agrupan sonidos para controlarlos en conjunto |
| 2 | Enrutado (bus de un player) | Cada sonido debe ir al bus correcto |
| 3 | `AudioServer` por código | Permite mezclar en tiempo real según el juego |
| 4 | Reverb y espacio | Da sensación de sala, cueva o exterior |
| 5 | Compresor y EQ | Controlan dinámica y frecuencias para claridad |
| 6 | Low-pass filter | Efecto "bajo el agua" o "sonido amortiguado" |
| 7 | Ducking | La música baja para que se oiga lo importante |
| 8 | Mezcla por estado | La escena cambia y la mezcla debe acompañar |

## 📖 Definiciones y características

- **Bus de audio**: canal de mezcla al que se enrutan players; tiene su propio volumen y efectos. Clave: el bus Master es la salida final.
- **Enrutado**: propiedad `.bus` de cada player que indica a qué canal envía su señal. Clave: si el nombre no coincide, suena por Master.
- **AudioServer**: singleton que gestiona buses y efectos en tiempo de ejecución. Clave: `get_bus_index("SFX")` traduce nombre a índice.
- **AudioEffectReverb**: simula reflexiones de una sala. Clave: úsalo sutil o "inunda" la mezcla.
- **AudioEffectCompressor**: reduce el rango dinámico. Clave: iguala volúmenes y da pegada; base del ducking con *sidechain*.
- **AudioEffectEQ**: ajusta bandas de frecuencia. Clave: quita graves o realza agudos para dar espacio a cada sonido.
- **AudioEffectLowPassFilter**: deja pasar solo las frecuencias bajas. Clave: efecto instantáneo de "amortiguado" o "bajo el agua".
- **Ducking**: bajar automáticamente un bus (música) cuando suena otro (voz/SFX). Clave: mejora la inteligibilidad sin silenciar.

## 🧰 Herramientas y preparación

Abre el panel **Audio** en la parte inferior de Godot (pestaña junto a *Output* y *Debugger*). Ahí crearás los buses. Ten preparada una música en bucle (OGG) y un par de SFX (WAV): uno cotidiano (moneda) y otro "importante" (explosión o alarma) para el ducking. Revisa la [documentación de buses de audio](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html) y la [referencia de AudioServer](https://docs.godotengine.org/en/stable/classes/class_audioserver.html). Consejo: puedes guardar la disposición de buses en un archivo `.tres` con el botón *Save As* del panel Audio para reutilizarla entre escenas.

## 🧪 Laboratorio guiado

Montaremos cuatro buses, insertaremos efectos y programaremos ducking + filtro de agua. Resultado audible: la música baja al sonar la alarma y se "sumerge" al entrar en el agua.

**Paso 1 — Crea los buses.** En el panel *Audio*, pulsa *Add Bus* tres veces y renómbralos `Music`, `SFX` y `UI`. Deja que todos envíen su salida a `Master` (columna *Send*).

**Paso 2 — Enruta los players.** En tu `AudioStreamPlayer` de música, pon la propiedad `Bus` en `Music`. En los de efectos, en `SFX`. Ahora puedes bajar toda la música con una sola perilla.

**Paso 3 — Añade efectos.** Selecciona el bus `SFX`, pulsa *Add Effect* y elige *Reverb* (súbelo poco, ~10 % *wet*). En el bus `Master`, añade un *Compressor* suave para pegar la mezcla. En `Music`, añade un *Low Pass Filter* y, muy importante, **desactívalo** por ahora (clic en el icono del efecto) para activarlo por código.

**Paso 4 — Programa el ducking.** Adjunta este script al nodo raíz de la escena:

```gdscript
extends Node

@onready var alarma: AudioStreamPlayer = $Alarma   # bus = "SFX"

# Guardamos los índices de bus una sola vez para no buscarlos cada frame.
var _music_idx := AudioServer.get_bus_index("Music")

func reproducir_alarma() -> void:
	alarma.play()
	# Ducking: bajamos la música mientras suena la alarma y la restauramos al terminar.
	var tween := create_tween()
	tween.tween_method(_set_music_db, 0.0, -18.0, 0.15)   # baja rápido
	tween.tween_interval(0.6)                             # se mantiene baja
	tween.tween_method(_set_music_db, -18.0, 0.0, 0.5)    # sube suave

func _set_music_db(db: float) -> void:
	AudioServer.set_bus_volume_db(_music_idx, db)
```

**Paso 5 — Programa el filtro de agua.** Añade el control del low-pass del bus Music. El efecto está en el índice `0` de ese bus (fue el primero que añadiste):

```gdscript
func entrar_al_agua(sumergido: bool) -> void:
	# Activamos/desactivamos el Low Pass del bus Music según el estado.
	AudioServer.set_bus_effect_enabled(_music_idx, 0, sumergido)
```

**Paso 6 — Pruébalo.** Llama a `reproducir_alarma()` desde `_unhandled_input` con una tecla y a `entrar_al_agua(true/false)` con otra. Al disparar la alarma, oirás cómo la música se aparta un momento y vuelve. Al "entrar al agua", la música se vuelve grave y apagada al instante.

**Resultado visible:** una mezcla viva donde la música cede protagonismo ante la alarma (ducking) y se filtra al sumergirse, todo sin tocar los archivos de audio.

## ✍️ Ejercicios

1. Añade un bus `Voz` y haz ducking de la música y de los SFX a la vez cuando un personaje habla.
2. Sustituye el low-pass abrupto por un `create_tween()` que baje la frecuencia de corte progresivamente.
3. Inserta un `AudioEffectEQ` en Music y recorta los graves para dejar sitio a una explosión.
4. Añade un *Mute* y un *Solo* por código usando `AudioServer.set_bus_mute()` para depurar la mezcla.
5. Crea un preset "cueva" que suba el reverb del bus SFX y compáralo con el preset normal.
6. Guarda dos configuraciones de buses en archivos `.tres` y cámbialas al pasar de un nivel a otro.

## 📝 Reto verificable

Construye una escena con buses `Master`, `Music`, `SFX` y `UI`. Implementa dos comportamientos: (a) *ducking* de la música al reproducir un SFX marcado como "importante", con restauración suave mediante tween; y (b) un modo "sumergido" que active un low-pass en el bus Music y lo desactive al salir. Ambos se controlan desde código con `AudioServer`.

**Criterio de aceptación**: al disparar el SFX importante, la música baja de forma audible y vuelve a su nivel; al activar el modo sumergido, la música pierde agudos claramente y los recupera al desactivarlo; los volúmenes se ajustan por índice de bus, no cambiando `volume_db` de cada player.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El player no se ve afectado por el bus | Su propiedad `.bus` no coincide con el nombre exacto (sensible a mayúsculas) |
| `get_bus_index` devuelve -1 | El bus no existe o está mal escrito; créalo en el panel Audio |
| El reverb "inunda" todo | *Wet* demasiado alto; bájalo o reduce el tiempo de la sala |
| El low-pass no se activa por código | Índice de efecto equivocado; cuenta desde 0 en el orden del panel |
| El ducking suena a saltos | Cambias `volume_db` de golpe; usa `tween_method` para interpolar |
| La música vuelve al volumen equivocado | Guardas mal el nivel original; restaura siempre a un valor conocido (p. ej. 0 dB) |

## ❓ Preguntas frecuentes

**¿Ducking por código o con el compresor sidechain?**
Ambos valen. El compresor con sidechain es más "profesional" y automático, pero controlar el volumen del bus con un tween es más simple y transparente para empezar.

**¿Cuántos buses debería tener un juego?**
Los típicos son Master, Music, SFX, UI y a veces Voz/Ambiente. Demasiados buses complican la mezcla sin aportar; agrupa por cómo quieres controlarlos.

**¿Los efectos gastan CPU?**
Sí, sobre todo reverbs de calidad. Como se aplican por bus (no por sonido), el coste es fijo y asumible; evita apilar muchos reverbs.

**¿Puedo cambiar el volumen del Master para el control general del juego?**
Sí, `set_bus_volume_db(0, db)` afecta a toda la salida. Es la base de un control de "volumen general" en el menú de opciones.

## 🔗 Referencias

- [Buses de audio — documentación de Godot](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html)
- [AudioServer — referencia de clase](https://docs.godotengine.org/en/stable/classes/class_audioserver.html)
- [Efectos de audio — AudioEffect](https://docs.godotengine.org/en/stable/classes/class_audioeffect.html)
- [Guía de mezcla dinámica y ducking (GDC)](https://www.gdcvault.com/)

## ➡️ Siguiente clase

[Clase 129 - Audio 3D/posicional y atenuación](../129-audio-3d-posicional-y-atenuacion/README.md)
