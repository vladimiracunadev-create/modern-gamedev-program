# Clase 130 — Música adaptativa: capas verticales

> Parte: **6 — Audio y música interactiva** · Fuente: *Documentación de audio de Godot 4 + GDC talks sobre música adaptativa (vertical layering)*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Hacer que la música **respire con la acción** sin cambiar de tema. La técnica se llama *layering vertical*: se componen varios *stems* (percusión, melodía, tensión) de la misma pieza, se reproducen **sincronizados en bucle** y se sube o baja el volumen de cada capa según un valor de "intensidad" o "tensión". Cuando el jugador está tranquilo solo suena el colchón; cuando aparece el peligro entran percusión y cuerdas agudas. En Godot lo lograremos con varios `AudioStreamPlayer` sincronizados y `create_tween()` para los fundidos.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar el layering vertical y diferenciarlo de las transiciones horizontales.
- Reproducir varios stems perfectamente sincronizados desde el mismo instante.
- Controlar el volumen de cada capa de forma independiente con tweens (fades).
- Mapear una variable de tensión (0–1) a los volúmenes de las capas.
- Preparar stems (misma duración, tempo y punto de loop) para que encajen.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Stems musicales | Cada capa es una pista independiente del mismo tema |
| 2 | Sincronía de reproducción | Todos deben empezar en el mismo frame o desfasarán |
| 3 | Layering vertical | Añadir/quitar capas cambia la intensidad sin cortar |
| 4 | Variable de tensión | Un número (0–1) que traduce el estado del juego a mezcla |
| 5 | Fades con tween | Entradas y salidas suaves evitan saltos bruscos |
| 6 | Mapeo tensión→volumen | Cada capa entra en un umbral distinto |
| 7 | Loop coherente | Todos los stems deben durar y ciclar igual |

## 📖 Definiciones y características

- **Stem**: pista aislada de una mezcla (solo percusión, solo melodía…). Clave: todos comparten tempo y duración para superponerse.
- **Layering vertical**: sumar o restar capas sobre una base común para variar la intensidad. Clave: la música nunca se detiene ni cambia de tema.
- **Sincronía**: iniciar todos los players en el mismo instante. Clave: si arrancan con desfase, el resultado suena "flojo" o con eco.
- **Tensión/intensidad**: valor normalizado (0.0–1.0) que representa el estado emocional del juego. Clave: es la entrada única de la mezcla.
- **Fade**: transición gradual de volumen. Clave: se hace con `create_tween().tween_property(...)` sobre `volume_db`.
- **Umbral de capa**: nivel de tensión a partir del cual una capa se oye. Clave: escalonar umbrales crea una progresión natural.
- **Silencio efectivo**: bajar una capa a un `volume_db` muy bajo (p. ej. `-60`) en lugar de detenerla. Clave: mantiene la sincronía intacta.

## 🧰 Herramientas y preparación

Necesitas tres stems del mismo tema, **exactamente igual de largos y al mismo tempo**, exportados como OGG en bucle: por ejemplo `base.ogg` (colchón/armonía), `perc.ogg` (percusión) y `tension.ogg` (cuerdas o sintetizador agudo). Si no compones, muchos packs de música de juego incluyen stems por separado; búscalos en [OpenGameArt](https://opengameart.org/) o genera versiones sencillas quitando pistas en un editor. Colócalos en `audio/musica/`. Repasa la [referencia de AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html) y la API de [Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html). Este sistema conviene ponerlo en un **autoload** para que la música persista entre escenas.

## 🧪 Laboratorio guiado

Reproduciremos tres stems sincronizados y controlaremos su volumen con un valor de tensión. Resultado audible: al subir la "tensión" entran percusión y capa aguda; al bajarla se retiran, todo sin cortes.

**Paso 1 — Arma la escena.** Crea un nodo raíz `MusicaAdaptativa` con tres hijos `AudioStreamPlayer`: `Base`, `Perc` y `Tension`. Asigna cada OGG (en loop) a su `Stream`. Enrútalos todos al bus `Music`.

**Paso 2 — Sincroniza el arranque.** La clave es llamar a `play()` de los tres en el mismo `_ready()`, sin esperas entre medias. Adjunta este script al raíz:

```gdscript
extends Node

@onready var base_player: AudioStreamPlayer = $Base
@onready var perc: AudioStreamPlayer = $Perc
@onready var tension: AudioStreamPlayer = $Tension

const SILENCIO := -60.0   # dB prácticamente inaudible, pero la capa sigue sonando
var _tension := 0.0        # 0 = calma, 1 = máxima intensidad

func _ready() -> void:
	# Todas las capas suenan siempre; solo variamos su volumen.
	# Arrancan en el mismo instante para quedar sincronizadas.
	base_player.volume_db = 0.0
	perc.volume_db = SILENCIO
	tension.volume_db = SILENCIO
	base_player.play()
	perc.play()
	tension.play()
```

**Paso 3 — Mapea la tensión a volúmenes.** Añade la función que traduce el valor 0–1 a la mezcla. La base siempre suena; la percusión entra a partir de 0.3 y la capa aguda a partir de 0.6:

```gdscript
func set_tension(valor: float) -> void:
	_tension = clampf(valor, 0.0, 1.0)
	# La percusión aparece en la mitad baja de la tensión.
	var perc_db := _mezclar(_tension, 0.3, 0.6)
	# La capa de tensión aguda aparece solo en la parte alta.
	var tens_db := _mezclar(_tension, 0.6, 1.0)
	_fade(perc, perc_db)
	_fade(tension, tens_db)

# Devuelve 0 dB si la tensión supera el rango, SILENCIO si está por debajo.
func _mezclar(t: float, desde: float, hasta: float) -> float:
	var f := clampf((t - desde) / (hasta - desde), 0.0, 1.0)
	return lerpf(SILENCIO, 0.0, f)

func _fade(player: AudioStreamPlayer, db_objetivo: float) -> void:
	var tween := create_tween()
	tween.tween_property(player, "volume_db", db_objetivo, 0.4)
```

**Paso 4 — Conecta un control.** Para probar, cambia la tensión con dos teclas. Añade al script:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		set_tension(_tension + 0.25)   # más peligro
	elif event.is_action_pressed("ui_down"):
		set_tension(_tension - 0.25)   # más calma
```

**Paso 5 — Ejecuta y sube la tensión.** Corre la escena. Con la flecha arriba, al pasar de 0.3 entra la percusión con un fundido suave; al pasar de 0.6 se suma la capa aguda. Con la flecha abajo se retiran en orden inverso. La base nunca deja de sonar y todo permanece sincronizado.

**Resultado visible:** una única pieza musical que gana y pierde capas según un valor de tensión, con transiciones suaves y sin perder la sincronía entre stems.

## ✍️ Ejercicios

1. Añade un cuarto stem (coro o bajo) con su propio umbral de entrada y ajústalo en `set_tension`.
2. Cambia la duración del fade a `0.1` y a `2.0` s, y comenta cuál se siente mejor y por qué.
3. Sustituye `SILENCIO` de `-60` por `-40` y comprueba si la capa "apagada" se cuela demasiado.
4. Conecta `set_tension` al número de enemigos cercanos en vez de a teclas.
5. Convierte el nodo en un autoload y comprueba que la música sigue al cambiar de escena.
6. Añade un pequeño *retardo de calma*: que la tensión baje sola con el tiempo si no hay peligro.

## 📝 Reto verificable

Implementa un sistema de música por capas verticales con al menos tres stems sincronizados en bucle, controlado por una única variable de tensión (0.0–1.0). Cada capa debe entrar y salir con fundido en un umbral distinto, y la mezcla debe reaccionar a una señal del juego (teclas o un contador simulado de amenaza).

**Criterio de aceptación**: los tres stems suenan sincronizados (sin eco ni desfase perceptible); al variar la tensión las capas entran/salen con fundidos suaves y en umbrales escalonados; y en ningún momento la música se detiene o pierde el compás, ya que las capas silenciadas siguen reproduciéndose a bajo volumen.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Los stems suenan "con eco" o desfasados | Los inicias en momentos distintos; llama a `play()` de todos juntos |
| Al bajar una capa se corta y luego reaparece desincronizada | La detienes con `stop()`; en su lugar baja el `volume_db`, no la pares |
| Las capas no encajan rítmicamente | Tienen distinta duración o tempo; exporta stems idénticos en longitud |
| El cambio de volumen suena a golpe | Asignas `volume_db` directo; usa un tween para el fade |
| Una capa nunca se oye | Su umbral es demasiado alto o el `SILENCIO` demasiado bajo; revisa el mapeo |
| Silencio total al empezar | Olvidaste poner la base a 0 dB; asegúrate de que la capa base arranca audible |

## ❓ Preguntas frecuentes

**¿Por qué no detener las capas que no suenan y ahorrar CPU?**
Porque al volver a reproducirlas perderían la sincronía con el resto. El coste de una voz a `-60 dB` es mínimo comparado con reprogramar el arranque exacto.

**¿Cuántas capas son razonables?**
Entre 3 y 6 suele bastar para transmitir varios niveles de intensidad. Más capas complican la composición sin aportar contraste claro.

**¿Puedo usar `AudioStreamSynchronized` para esto?**
Sí: `AudioStreamSynchronized` reproduce varios streams a la vez garantizando el mismo reloj. Es una alternativa robusta a sincronizar players a mano cuando las capas son fijas.

**¿La tensión debe cambiar de golpe o suavemente?**
Suele ir mejor suavizada. Interpolar la propia variable de tensión (además del volumen) evita que la música "parpadee" ante cambios rápidos del juego.

## 🔗 Referencias

- [AudioStreamPlayer — referencia de clase](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html)
- [AudioStreamSynchronized — referencia de clase](https://docs.godotengine.org/en/stable/classes/class_audiostreamsynchronized.html)
- [Tween — referencia de clase](https://docs.godotengine.org/en/stable/classes/class_tween.html)
- [GDC — Vertical layering en música de juegos](https://www.gdcvault.com/)

## ➡️ Siguiente clase

[Clase 131 - Música adaptativa: transiciones horizontales](../131-musica-adaptativa-transiciones-horizontales/README.md)
