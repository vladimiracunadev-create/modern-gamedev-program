# Clase 126 — Fundamentos de audio para juegos (repaso aplicado)

> Parte: **6 — Audio y música interactiva** · Fuente: *Documentación de audio de Godot 4 + Karen Collins, "Game Sound" (MIT Press)*
> ⏱️ Duración estimada: **45 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Refrescar los conceptos de audio digital que de verdad afectan a un juego —muestreo, profundidad de bits, formatos, canales, decibelios y latencia— pero de forma **aplicada**, tocando cada idea desde Godot 4. Al terminar sabrás por qué un SFX corto va en WAV y la música en OGG, cómo activar el bucle correcto en el importador, qué reproductor usar en cada caso y cómo pensar el volumen en dB en lugar de en porcentajes. Es la base sobre la que se apoya toda la parte 6.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar sample rate, bit depth y canales, y decidir cuándo importan en un juego.
- Elegir entre WAV y OGG según el uso (SFX corto vs música larga) y justificarlo.
- Configurar el bucle (loop) de un audio en el panel de importación de Godot.
- Reproducir sonido con `AudioStreamPlayer` y controlar su volumen en decibelios.
- Convertir entre escala lineal y dB con `linear_to_db()` y `db_to_linear()`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Sample rate y bit depth | Definen la fidelidad y el peso del archivo en memoria |
| 2 | WAV vs OGG (Vorbis) | Uno se descomprime en RAM, el otro hace streaming |
| 3 | Mono vs estéreo | El SFX posicional debe ser mono para que Godot lo espacialice |
| 4 | Decibelios y percepción | El oído es logarítmico; el volumen se piensa en dB |
| 5 | Latencia y buffer de audio | El sonido debe sonar "a tiempo" con la acción |
| 6 | Reproductores de Godot 4 | Elegir global, 2D o 3D según el contexto |
| 7 | Importación y loop | El bucle se define al importar, no al reproducir |

## 📖 Definiciones y características

- **Sample rate**: número de muestras por segundo (44 100 Hz o 48 000 Hz). Clave: más muestras = más agudos representables y más peso.
- **Bit depth**: bits por muestra (16 o 24 bits). Clave: define el rango dinámico; 16 bits basta para casi todo juego.
- **WAV**: audio sin comprimir. Clave: se carga entero en RAM y suena con latencia mínima; ideal para SFX cortos.
- **OGG Vorbis**: audio comprimido con pérdida. Clave: pesa poco y admite streaming; ideal para música larga.
- **Mono/estéreo**: uno o dos canales. Clave: para audio posicional 2D/3D usa mono, o Godot no podrá calcular el paneo.
- **Decibelio (dB)**: unidad logarítmica relativa. Clave: `0 dB` es sin cambio, valores negativos bajan; `-6 dB` ≈ mitad de amplitud percibida.
- **Latencia**: retraso entre disparar el sonido y oírlo. Clave: buffers grandes dan estabilidad pero retrasan; hay que equilibrar.
- **Loop**: marca de repetición continua. Clave: en Godot se activa en el panel *Import*, no por código.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x (idealmente 4.3 o superior) y dos archivos de audio de dominio libre: un efecto corto en formato **WAV** (por ejemplo, un "click", un salto o una moneda) y una pieza de música en **OGG** pensada para repetirse en bucle. Puedes obtenerlos en [freesound.org](https://freesound.org/) o en la biblioteca de [Kenney](https://kenney.nl/assets?q=audio). Crea un proyecto nuevo, arrastra ambos archivos a una carpeta `audio/` dentro del proyecto y ten a la vista el panel *Import* (pestaña junto a *Scene*). Repasa la [documentación de audio de Godot 4](https://docs.godotengine.org/en/stable/tutorials/audio/index.html) y la [referencia de AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html).

## 🧪 Laboratorio guiado

Vamos a importar un SFX y una música, reproducirlos y controlar su volumen en dB. El resultado será **audible**: oirás el efecto al pulsar una tecla y la música en bucle de fondo.

**Paso 1 — Importa el SFX en bucle correcto.** Selecciona tu archivo WAV en el panel *FileSystem* y abre la pestaña *Import*. Un SFX de "click" **no** debe repetirse, así que deja *Loop Mode* en `Disabled`. Si fuese un sonido continuo (motor, viento), elegirías `Forward`. Pulsa *Reimport*.

**Paso 2 — Importa la música en loop.** Selecciona el archivo OGG. En su pestaña *Import*, activa *Loop* para que la música se repita sin cortes. Los OGG guardan un punto de bucle propio; deja *Loop Offset* en `0` salvo que tengas una intro. Pulsa *Reimport*.

**Paso 3 — Arma la escena.** Crea una escena con un `Node` raíz llamado `AudioDemo`. Añade dos hijos `AudioStreamPlayer`: renómbralos `SfxPlayer` y `MusicPlayer`. Arrastra el WAV a la propiedad `Stream` de `SfxPlayer` y el OGG a la de `MusicPlayer`.

**Paso 4 — Escribe el script.** Adjunta este script al nodo raíz:

```gdscript
extends Node

@onready var sfx_player: AudioStreamPlayer = $SfxPlayer
@onready var music_player: AudioStreamPlayer = $MusicPlayer

func _ready() -> void:
	# La música arranca al iniciar y se repite (loop activado al importar).
	music_player.volume_db = -12.0   # música de fondo, algo por debajo
	music_player.play()

	# Demostramos la conversión lineal <-> dB en consola.
	var lineal := 0.5                       # 50 % de amplitud
	var en_db := linear_to_db(lineal)       # ~ -6.02 dB
	print("0.5 lineal equivale a %.2f dB" % en_db)
	print("-6 dB equivale a %.3f lineal" % db_to_linear(-6.0))

func _unhandled_input(event: InputEvent) -> void:
	# Al pulsar Espacio disparamos el efecto corto.
	if event.is_action_pressed("ui_accept"):
		sfx_player.pitch_scale = 1.0   # tono normal
		sfx_player.volume_db = 0.0     # a plena señal
		sfx_player.play()
```

**Paso 5 — Ejecuta y escucha.** Corre la escena. Deberías oír la música en bucle de fondo y, cada vez que pulses **Espacio**, el efecto corto. En la consola verás cómo `0.5` lineal son unos `-6 dB`, la prueba de que la escala no es proporcional sino logarítmica.

**Paso 6 — Experimenta con el volumen.** Cambia `music_player.volume_db` a `-24.0` y luego a `0.0`. Nota que la diferencia percibida entre `-24` y `-12` es enorme, mientras que entre `-3` y `0` apenas se aprecia: así funciona el oído.

**Resultado visible:** música en bucle sonando, un SFX disparado por teclado y dos líneas en consola que demuestran la relación lineal/dB.

## ✍️ Ejercicios

1. Importa el mismo SFX dos veces, uno con *Loop* `Disabled` y otro `Forward`, y compara el resultado al reproducirlos.
2. Añade un segundo `AudioStreamPlayer` y reproduce dos SFX a la vez para comprobar que Godot los mezcla.
3. Escribe una función que reciba un porcentaje (0–100) y lo convierta a dB con `linear_to_db()`.
4. Baja la música a `-40 dB` y sube el SFX a `+6 dB`: describe qué ocurre y por qué `+6` puede saturar.
5. Reemplaza la música OGG por un WAV largo y observa el aumento de uso de RAM en el monitor de depuración.
6. Cambia `pitch_scale` del SFX a `0.5` y `2.0`, y explica cómo afecta al tono y a la duración.

## 📝 Reto verificable

Crea una escena de "banco de pruebas de audio" con un `AudioStreamPlayer` para música (OGG en loop) y otro para SFX (WAV sin loop). La música debe iniciarse automáticamente a `-15 dB`, y tres teclas distintas deben disparar el mismo SFX a tres volúmenes diferentes (`-12`, `-6` y `0 dB`) calculados y aplicados desde código.

**Criterio de aceptación**: al ejecutar, la música suena en bucle sin cortes, cada tecla reproduce el efecto a un volumen claramente distinto, y el proyecto usa el formato correcto para cada tipo (OGG para música, WAV para SFX).

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La música no se repite | No activaste *Loop* en el panel *Import*; reimporta con el bucle habilitado |
| El SFX suena "arrastrado" o con eco al repetir | Dejaste *Loop* `Forward` en un sonido de un solo golpe; ponlo en `Disabled` |
| El juego consume mucha RAM | Cargas música larga como WAV; usa OGG para streaming |
| Subo `volume_db` a 100 y satura o no cambia | dB no es porcentaje; el rango útil suele ir de `-80` a `+6`, no a 100 |
| El audio suena con retraso perceptible | Latencia alta; reduce el tamaño de buffer en *Project Settings → Audio* |
| No se oye nada | El `Stream` está vacío o el `volume_db` está en `-80`; asigna el stream y sube el volumen |

## ❓ Preguntas frecuentes

**¿44 100 o 48 000 Hz para mi juego?**
Cualquiera va bien. 48 kHz es el estándar de vídeo y audio profesional; 44,1 kHz es el de CD. Lo importante es ser consistente para evitar remuestreos.

**¿Por qué mi SFX 3D no se oye desplazado a un lado?**
Probablemente es estéreo. El audio posicional debe ser mono; convierte el archivo a mono o reimpórtalo como tal.

**¿0 dB es el máximo?**
`0 dB` significa "sin cambio respecto a la señal original", no un tope. Puedes subir con valores positivos, pero por encima de `0` en el bus Master arriesgas *clipping* (saturación).

**¿Debo usar MP3 en Godot 4?**
Godot 4 soporta MP3, pero OGG Vorbis suele dar mejor relación calidad/peso y bucles más limpios. Reserva MP3 para cuando ya tengas assets en ese formato.

## 🔗 Referencias

- [Audio en Godot 4 — documentación oficial](https://docs.godotengine.org/en/stable/tutorials/audio/index.html)
- [AudioStreamPlayer — referencia de clase](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html)
- [Importar audio en Godot](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html)
- [Freesound — biblioteca de sonidos libres](https://freesound.org/)

## ➡️ Siguiente clase

[Clase 127 - Diseño de sonido: capas, variación y aleatoriedad](../127-diseno-de-sonido-capas-variacion-y-aleatoriedad/README.md)
