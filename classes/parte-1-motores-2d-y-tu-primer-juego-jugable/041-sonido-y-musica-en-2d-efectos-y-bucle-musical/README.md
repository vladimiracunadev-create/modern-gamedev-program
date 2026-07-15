# Clase 041 — Sonido y música en 2D: efectos y bucle musical

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4 (Audio)*
> ⏱️ Duración estimada: **90 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Darle voz a tu plataformas. Hasta ahora el juego se mueve pero es mudo; en esta clase incorporarás **efectos de sonido (SFX)** y **música de fondo** usando el sistema de audio de Godot 4. Aprenderás la diferencia entre reproducir un sonido "global" y uno "posicional" que se atenúa con la distancia, cómo organizar el volumen mediante **buses de audio** (Master, Music, SFX) y cómo mantener la música sonando de forma continua aunque cambies de escena.

Al terminar tendrás un **Autoload de música** que no se corta entre pantallas y efectos de sonido disparados por señales en los eventos clave: saltar, recoger una moneda y recibir daño. Es la capa que hace que el juego "se sienta" vivo, y la base sobre la que en la próxima clase añadiremos partículas y feedback visual.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Importar correctamente archivos **WAV** para SFX y **OGG con loop** para música.
2. Distinguir cuándo usar **AudioStreamPlayer** (global) frente a **AudioStreamPlayer2D** (posicional con atenuación).
3. Configurar **buses de audio** Master, Music y SFX y ajustar sus volúmenes con `AudioServer`.
4. Reproducir SFX en eventos del juego (salto, moneda, daño) conectando **señales**.
5. Crear un **Autoload** de música que persista y no se reinicie al cambiar de escena.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Formatos de audio (WAV vs OGG) | Cada uno sirve a un propósito: SFX cortos vs música larga. |
| 2 | AudioStreamPlayer global | Reproduce sonidos que se oyen igual en toda la pantalla. |
| 3 | AudioStreamPlayer2D posicional | Aporta sensación de espacio: el sonido depende de la posición. |
| 4 | Buses de audio | Permiten controlar volúmenes por categoría (música/efectos). |
| 5 | Loop de música en OGG | La música debe repetirse sin cortes ni silencios. |
| 6 | SFX por señales | Desacopla el sonido de la lógica: se dispara ante eventos. |
| 7 | Autoload de música | Mantiene la banda sonora entre escenas sin reiniciarla. |
| 8 | Control de volumen en runtime | Base de un futuro menú de ajustes de sonido. |

## 📖 Definiciones y características

- **AudioStreamPlayer**: nodo que reproduce audio sin posición espacial; se oye igual en toda la escena. Clave: ideal para música y UI.
- **AudioStreamPlayer2D**: reproduce audio con posición en el mundo 2D y **atenuación** según la distancia al oyente. Clave: úsalo para sonidos de objetos del mundo.
- **Bus de audio**: canal por el que pasa el sonido antes de llegar al Master; permite agrupar y ajustar volúmenes. Clave: separa Music y SFX del Master.
- **volume_db**: volumen expresado en decibelios; `0` es el nivel nominal y valores negativos lo bajan. Clave: `-80` equivale a silencio.
- **WAV**: formato sin compresión, carga instantánea; perfecto para efectos cortos. Clave: importa con Loop **desactivado** para SFX.
- **OGG Vorbis**: formato comprimido para pistas largas; se importa con **Loop activado** para la música. Clave: evita cortes al repetir.
- **Autoload (Singleton)**: escena o script que Godot carga una sola vez y mantiene viva sobre todas las escenas. Clave: perfecto para un reproductor de música persistente.
- **AudioServer**: API global para manipular buses en tiempo de ejecución (`set_bus_volume_db`, índices de bus). Clave: base de los ajustes de volumen.

## 🧰 Herramientas y preparación

Necesitas tu proyecto `PlataformasCurso` de las clases anteriores y **Godot 4.x**. Consigue algunos efectos cortos en formato WAV (salto, moneda, daño) y una pista de música en OGG; puedes generar SFX libres de derechos con herramientas como **jsfxr** (<https://sfxr.me>) y encontrar música con licencia libre. Coloca los archivos en una carpeta `res://audio/`. Ten a mano la documentación oficial de audio: <https://docs.godotengine.org/en/stable/tutorials/audio/audio_streams.html> y la de buses: <https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html>.

## 🧪 Laboratorio guiado

Configuraremos los buses, un Autoload de música persistente y SFX disparados por señales.

1. **Importar la música con loop.** Copia tu pista OGG a `res://audio/musica_nivel.ogg`. Selecciónala en el panel **FileSystem**, ve a la pestaña **Import** (arriba a la derecha), activa **Loop** y pulsa **Reimport**. Repite para los WAV de SFX, pero deja **Loop desactivado** en ellos.

2. **Crear los buses de audio.** Abre el panel **Audio** (barra inferior del editor). Pulsa **Add Bus** dos veces y renómbralos `Music` y `SFX`. Ambos deben enviar su salida a **Master** (columna "Send"). Así podrás bajar la música sin tocar los efectos.

3. **Crear el Autoload de música.** Crea un script `res://audio/musica.gd`:

```gdscript
extends Node

# Reproductor de música persistente. Vive sobre todas las escenas.
@onready var reproductor: AudioStreamPlayer = $Reproductor

func _ready() -> void:
	# Al arrancar el juego, iniciamos la banda sonora una sola vez.
	reproducir(preload("res://audio/musica_nivel.ogg"))

func reproducir(pista: AudioStream) -> void:
	# Evita reiniciar si ya suena la misma pista.
	if reproductor.stream == pista and reproductor.playing:
		return
	reproductor.stream = pista
	reproductor.play()

func detener() -> void:
	reproductor.stop()
```

4. **Montar la escena del Autoload.** Crea una escena nueva con raíz `Node` llamada `Musica`, añádele un hijo **AudioStreamPlayer** renombrado `Reproductor` y asígnale en el Inspector el **Bus** `Music`. Adjunta el script `musica.gd` a la raíz y guarda como `res://audio/musica.tscn`.

5. **Registrar el Autoload.** Ve a **Project → Project Settings → Globals → Autoload**, selecciona `res://audio/musica.tscn`, nómbralo `Musica` y pulsa **Add**. Ahora es un singleton global. Ejecuta con **F5**: la música suena. Cambia de escena y comprobarás que **no se reinicia**.

6. **Crear un gestor de SFX.** Muchos efectos son globales (moneda, daño). Crea un Autoload similar `res://audio/sfx.gd`:

```gdscript
extends Node

# Precargamos los efectos una vez para no leer disco en cada disparo.
var sonidos := {
	"salto": preload("res://audio/salto.wav"),
	"moneda": preload("res://audio/moneda.wav"),
	"dano": preload("res://audio/dano.wav"),
}

@onready var reproductor: AudioStreamPlayer = $Reproductor

func reproducir(nombre: String) -> void:
	if not sonidos.has(nombre):
		push_warning("SFX inexistente: " + nombre)
		return
	reproductor.stream = sonidos[nombre]
	reproductor.play()
```

Móntalo igual que el de música (raíz `Node`, hijo `AudioStreamPlayer` en el bus **SFX**) y regístralo como Autoload `Sfx`.

7. **Disparar SFX en eventos del jugador.** En el script del jugador, llama al gestor en los momentos correctos:

```gdscript
func _physics_process(delta: float) -> void:
	# ... lógica de movimiento previa ...
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = FUERZA_SALTO
		Sfx.reproducir("salto")   # SFX global al saltar
	move_and_slide()

func recibir_dano(cantidad: int) -> void:
	vida -= cantidad
	Sfx.reproducir("dano")
```

8. **Sonido posicional en la moneda.** Para que la moneda suene según dónde esté, dale su propio **AudioStreamPlayer2D**. En el script de la moneda, al ser recogida:

```gdscript
extends Area2D

@onready var sonido: AudioStreamPlayer2D = $SonidoMoneda

func _on_body_entered(cuerpo: Node2D) -> void:
	if cuerpo.is_in_group("jugador"):
		sonido.play()          # suena desde la posición de la moneda
		$Sprite2D.visible = false
		set_deferred("monitoring", false)
		# Esperamos a que termine el sonido antes de liberar el nodo.
		await sonido.finished
		queue_free()
```

Asigna el `AudioStreamPlayer2D` al bus **SFX** en su Inspector. Ejecuta con **F5** y prueba: saltar, recoger monedas y recibir daño deben sonar, con la música de fondo continua.

## ✍️ Ejercicios

1. Baja el volumen de la música a `-10 dB` desde el Inspector del `Reproductor` y compáralo con los SFX.
2. Añade un SFX de aterrizaje que suene solo cuando el jugador pasa de estar en el aire a `is_on_floor()`.
3. Crea una función global `Sfx.silenciar(mute: bool)` que active/desactive el mute del bus SFX con `AudioServer.set_bus_mute`.
4. Cambia la música al entrar a un segundo nivel llamando a `Musica.reproducir(...)` con otra pista OGG.
5. Ajusta la propiedad **Max Distance** del `AudioStreamPlayer2D` de la moneda y describe cómo cambia la atenuación.
6. Añade un pequeño retardo aleatorio de tono (`pitch_scale`) al SFX de moneda para que no suene idéntico cada vez.

## 📝 Reto verificable

Implementa un control de volumen por bus. Crea en el Autoload `Sfx` (o uno nuevo `AudioConfig`) dos funciones: `set_volumen_musica(porcentaje: float)` y `set_volumen_sfx(porcentaje: float)`, que reciban un valor de `0.0` a `1.0` y lo apliquen al bus correcto usando `AudioServer.get_bus_index("Music")` y `AudioServer.set_bus_volume_db(idx, linear_to_db(porcentaje))`.

**Criterio de aceptación**: al llamar `set_volumen_musica(0.5)` la música baja de volumen sin afectar a los SFX, y `set_volumen_sfx(0.0)` deja los efectos en silencio mientras la música sigue sonando.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La música se corta y reinicia al cambiar de escena | Pusiste el AudioStreamPlayer dentro de la escena del nivel. Muévelo a un **Autoload**. |
| La música no se repite: suena una vez y calla | El OGG se importó sin **Loop**. Selecciónalo, activa Loop en la pestaña Import y reimporta. |
| El SFX de moneda no se oye porque el nodo se libera antes | Llamaste a `queue_free()` sin esperar. Usa `await sonido.finished` antes de liberar. |
| "Invalid access to property 'stream'" | El nodo Audio no existe o el `$Ruta` está mal escrito. Verifica el nombre en el panel Scene. |
| Bajar el Master no separa música de efectos | Todos los sonidos van al mismo bus. Asigna cada player a **Music** o **SFX** en su Inspector. |
| El WAV se oye recortado o con clic | Se importó con Loop activado. Desactiva Loop para SFX cortos. |

## ❓ Preguntas frecuentes

**❓ ¿Cuándo uso AudioStreamPlayer2D en lugar del normal?** Cuando quieres que el sonido dependa de la posición en el mundo: un enemigo lejano suena más flojo. Para música y UI usa el `AudioStreamPlayer` global.

**❓ ¿Por qué WAV para efectos y OGG para música?** El WAV carga al instante y es perfecto para sonidos cortos y frecuentes; el OGG está comprimido y ahorra mucho espacio en pistas largas de música.

**❓ ¿Qué es exactamente un bus de audio?** Es un canal intermedio: agrupas varios sonidos en él (por ejemplo todos los SFX) y ajustas su volumen o efectos en conjunto antes de mezclarlos en el Master.

**❓ ¿Por qué la música va en un Autoload?** Porque un Autoload se instancia una sola vez y sobrevive a los cambios de escena, así la banda sonora no se reinicia cada vez que cargas un nivel nuevo.

## 🔗 Referencias

- Godot Docs — Audio streams: <https://docs.godotengine.org/en/stable/tutorials/audio/audio_streams.html>
- Godot Docs — Audio buses: <https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html>
- Godot Docs — AudioStreamPlayer2D: <https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer2d.html>
- Godot Docs — Singletons (Autoload): <https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html>
- Godot Docs — AudioServer: <https://docs.godotengine.org/en/stable/classes/class_audioserver.html>

## ⬅️ Clase anterior

[Clase 040 - Menús, pausa y flujo de escenas](../040-menus-pausa-y-flujo-de-escenas/README.md)

## ➡️ Siguiente clase

[Clase 042 - Partículas y feedback visual (juice)](../042-particulas-y-feedback-visual-juice/README.md)
