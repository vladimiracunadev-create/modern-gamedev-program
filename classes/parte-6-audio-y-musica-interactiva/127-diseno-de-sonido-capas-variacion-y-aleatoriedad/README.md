# Clase 127 — Diseño de sonido: capas, variación y aleatoriedad

> Parte: **6 — Audio y música interactiva** · Fuente: *Documentación de audio de Godot 4 (AudioStreamRandomizer) + Karen Collins, "Game Sound"*
> ⏱️ Duración estimada: **50 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Combatir la **fatiga por repetición**: ese momento en que un mismo sonido de pasos o disparo, oído cien veces idéntico, delata que es un juego. Aprenderás dos técnicas de diseño de sonido que se usan en todos los estudios: la **variación** (alterar pitch y elegir entre varias muestras al azar) y las **capas** (construir un evento sonoro sumando componentes: golpe + cola + eco). En Godot 4 lo resolveremos con el recurso `AudioStreamRandomizer`, pensado justo para esto.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar por qué la repetición literal rompe la inmersión y cómo evitarla.
- Configurar un `AudioStreamRandomizer` con varias muestras y variación de pitch.
- Distinguir los modos de reproducción aleatoria (aleatorio puro vs sin repetir).
- Construir un sonido por capas combinando varios reproductores.
- Ajustar rangos de pitch y volumen aleatorios para que suenen naturales, no caóticos.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Fatiga por repetición | Un SFX idéntico repetido delata el "truco" y cansa |
| 2 | Variación de pitch | Un cambio sutil de tono hace único cada disparo |
| 3 | Múltiples muestras | Varias grabaciones del mismo evento evitan el clon exacto |
| 4 | `AudioStreamRandomizer` | El recurso de Godot que centraliza la aleatoriedad |
| 5 | Modos de selección | Evitar que salga dos veces seguidas la misma muestra |
| 6 | Capas (layering) | Un impacto real = golpe + cuerpo + cola |
| 7 | Rangos naturales | Demasiada variación suena artificial; hay que dosificar |

## 📖 Definiciones y características

- **Fatiga por repetición**: cansancio o pérdida de inmersión al oír el mismo sonido idéntico muchas veces. Clave: se combate con variación, no con más volumen.
- **AudioStreamRandomizer**: recurso que envuelve varios streams y aplica pitch/volumen aleatorio al reproducir. Clave: se asigna a `.stream` como si fuera un audio normal.
- **Variación de pitch**: rango de tono aleatorio (`random_pitch`) alrededor de 1.0. Clave: valores como 0.9–1.1 dan naturalidad sin desafinar.
- **Variación de volumen**: rango de dB aleatorio (`random_volume_offset_db`). Clave: pequeñas diferencias imitan la energía variable de un gesto real.
- **Modo de reproducción**: `PLAYBACK_RANDOM_NO_REPEATS` evita repetir la última muestra. Clave: elimina el molesto "dos iguales seguidos".
- **Capa (layer)**: componente de un sonido compuesto (ataque, cuerpo, cola). Clave: se mezclan reproduciéndolos a la vez con volúmenes propios.
- **Ataque y cola**: el golpe inicial percusivo y el resto que decae. Clave: separar capas permite variar cada parte por independiente.

## 🧰 Herramientas y preparación

Consigue de tres a cinco variaciones de un mismo efecto: por ejemplo, cuatro muestras de pasos sobre grava, o tres de un disparo. Si no las tienes grabadas, en [freesound.org](https://freesound.org/) suelen venir en packs. Impórtalas como **WAV** con *Loop* `Disabled`. Para las capas necesitarás además una "cola" (un breve *tail* reverberante o un eco). Ten abierta la [referencia de AudioStreamRandomizer](https://docs.godotengine.org/en/stable/classes/class_audiostreamrandomizer.html). Crea una carpeta `audio/pasos/` y coloca ahí tus muestras.

## 🧪 Laboratorio guiado

Crearemos un sonido de pasos (o disparo) que **nunca suena igual dos veces**, y luego un impacto por capas. El resultado es claramente audible: al mantener pulsada una tecla oirás pasos con tonos y muestras distintas.

**Paso 1 — Crea el AudioStreamRandomizer.** Añade un `AudioStreamPlayer` llamado `PasosPlayer`. En su propiedad `Stream`, en vez de arrastrar un WAV, haz clic y elige *New AudioStreamRandomizer*. Ábrelo.

**Paso 2 — Añade las muestras.** Dentro del randomizer, en *Streams*, pulsa *Add* varias veces y arrastra cada WAV de pasos a un hueco. Ajusta el peso (*weight*) si quieres que unas salgan más que otras; déjalos iguales por ahora.

**Paso 3 — Configura la variación.** En el inspector del randomizer:

- *Playback Mode*: `Random (No Repeats)` para no repetir la última.
- *Random Pitch*: `1.1` (esto da un rango aproximado de 0.9–1.1).
- *Random Volume Offset dB*: `4.0` (±2 dB aprox.).

**Paso 4 — Dispara los pasos por código.** Adjunta este script al nodo raíz:

```gdscript
extends Node

@onready var pasos_player: AudioStreamPlayer = $PasosPlayer

var _tiempo_paso := 0.0
const INTERVALO := 0.4   # segundos entre pasos al caminar

func _process(delta: float) -> void:
	# Mientras se mantenga pulsada la tecla, generamos pasos rítmicos.
	if Input.is_action_pressed("ui_accept"):
		_tiempo_paso -= delta
		if _tiempo_paso <= 0.0:
			pasos_player.play()   # el Randomizer elige muestra + pitch + volumen
			_tiempo_paso = INTERVALO
	else:
		_tiempo_paso = 0.0   # al soltar, el siguiente paso suena de inmediato
```

**Paso 5 — Escucha la diferencia.** Corre la escena y mantén pulsada **Espacio**. Cada paso suena con una muestra y un tono ligeramente distinto: es la variación en acción. Ahora pon *Random Pitch* en `1.0` y *Random Volume Offset* en `0.0`, vuelve a correr y compara: sonará mecánico y repetitivo.

**Paso 6 — Añade capas a un impacto.** Crea otro `AudioStreamPlayer` llamado `ColaPlayer` con la muestra de cola/eco. Modifica el script para que un impacto suene como golpe + cola:

```gdscript
@onready var cola_player: AudioStreamPlayer = $ColaPlayer

func reproducir_impacto() -> void:
	# Capa 1: el golpe seco y variado (usa su propio Randomizer).
	pasos_player.play()
	# Capa 2: la cola reverberante, algo más baja, para dar "cuerpo".
	cola_player.volume_db = -8.0
	cola_player.play()
```

**Resultado visible:** pasos que suenan orgánicos y distintos entre sí, y un impacto compuesto por dos capas que juntas suenan más rico que cualquiera por separado.

## ✍️ Ejercicios

1. Añade una quinta muestra al randomizer y ajusta su *weight* para que salga con menos frecuencia.
2. Prueba *Playback Mode* en `Random` (con repeticiones) y explica qué molestia reaparece.
3. Sube *Random Pitch* a `1.5` y describe por qué suena poco realista.
4. Crea un randomizer de disparo y otro de casquillo, y dispáralos juntos con un pequeño retraso entre capas.
5. Usa `create_tween()` para bajar `volume_db` de la cola gradualmente y simular que el eco se aleja.
6. Añade variación de volumen a los pasos y compara con y sin ella manteniendo el mismo pitch.

## 📝 Reto verificable

Diseña un efecto de "arma" por capas y con variación: una capa de ataque con un `AudioStreamRandomizer` de al menos tres muestras (modo sin repeticiones, pitch aleatorio) y una capa de cola/cuerpo que suene simultáneamente a menor volumen. Un botón o tecla debe disparar el conjunto.

**Criterio de aceptación**: al disparar diez veces seguidas, ninguna suena idéntica a la anterior (muestra o tono cambian), se perciben claramente las dos capas, y la variación de pitch se mantiene en un rango natural (no desafina de forma evidente).

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Los pasos suenan mecánicos e iguales | Pitch y volumen aleatorios en 0; sube *Random Pitch* a ~1.1 |
| A veces sale la misma muestra dos veces seguidas | *Playback Mode* en `Random`; cámbialo a `Random (No Repeats)` |
| El sonido desafina de forma rara | *Random Pitch* demasiado alto; bájalo hacia 1.05–1.15 |
| Las capas suenan como dos sonidos separados | Las disparas con demasiado desfase; reprodúcelas casi a la vez |
| El randomizer no suena | Olvidaste asignarlo al `.stream` del player o no tiene streams dentro |
| La cola tapa el golpe | La capa de cola va muy alta; bájala varios dB respecto al ataque |

## ❓ Preguntas frecuentes

**¿Cuántas muestras necesito para que no se note la repetición?**
Con 3–5 buenas muestras y variación de pitch basta para la mayoría de eventos frecuentes como pasos o disparos.

**¿Puedo poner un AudioStreamRandomizer dentro de otro?**
Sí, un stream del randomizer puede ser otro randomizer, lo que permite jerarquías de variación, aunque rara vez hace falta.

**¿La variación de pitch cambia la duración del sonido?**
Sí: subir el pitch acorta y sube el tono; bajarlo alarga y lo grava. Por eso conviene mantener rangos pequeños en sonidos rítmicos.

**¿Las capas gastan mucho rendimiento?**
Cada capa es una voz de audio más. Con unas pocas capas no hay problema; solo importa si disparas cientos de sonidos simultáneos.

## 🔗 Referencias

- [AudioStreamRandomizer — referencia de clase](https://docs.godotengine.org/en/stable/classes/class_audiostreamrandomizer.html)
- [Audio en Godot 4 — documentación oficial](https://docs.godotengine.org/en/stable/tutorials/audio/index.html)
- [GDC — The Sound of Grand Theft Auto V (variación y capas)](https://www.gdcvault.com/)
- [Freesound — packs de variaciones](https://freesound.org/)

## ➡️ Siguiente clase

[Clase 128 - Buses, efectos y mezcla dinámica](../128-buses-efectos-y-mezcla-dinamica/README.md)
