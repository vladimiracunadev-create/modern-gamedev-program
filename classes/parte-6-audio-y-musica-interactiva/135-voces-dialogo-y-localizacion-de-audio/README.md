# Clase 135 — Voces, diálogo y localización de audio

> Parte: **6 — Audio y música interactiva** · Fuente: *Godot Docs — Internationalizing games + AudioStreamPlayer y sistema de traducción de Godot 4*
> ⏱️ Duración estimada: **50 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Diseñar un sistema de voces y diálogo que suene profesional: barks reactivos, subtítulos sincronizados con la voz y soporte de localización para reproducir la pista del idioma activo con su subtítulo traducido. Aprenderás además a gestionar prioridad y colas para que las líneas no se solapen. Al terminar tendrás un gestor de diálogo que elige la voz por locale, muestra el subtítulo a tiempo y encola líneas sin pisarse.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Distinguir voz de diálogo, bark y narración, y cuándo usar cada uno.
- Seleccionar el stream de voz correcto según el idioma activo (locale).
- Mostrar subtítulos traducidos con `tr()` sincronizados con la reproducción.
- Implementar una cola de diálogo que evite el solapamiento de líneas.
- Aplicar prioridad para que una línea importante interrumpa a un bark menor.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Voz, diálogo y barks | Cada categoría tiene reglas distintas de mezcla y prioridad |
| 2 | Localización de audio | Un juego global necesita la voz en el idioma del jugador |
| 3 | Selección por locale | Elegir el archivo correcto sin cambiar la lógica del juego |
| 4 | Subtítulos con `tr()` | Accesibilidad y traducción del texto que acompaña la voz |
| 5 | Sincronía voz-subtítulo | El texto debe aparecer y desaparecer con la línea hablada |
| 6 | Cola de diálogo | Evita que dos líneas se pisen y suenen ininteligibles |
| 7 | Prioridad e interrupción | Una alerta debe poder cortar un comentario ambiental |
| 8 | El bus de voz | La voz suele tener su propio bus con ducking para destacar |

## 📖 Definiciones y características

- **Voz / diálogo**: líneas habladas por personajes, normalmente guionizadas. Clave: alta prioridad y claridad, suelen atenuar la música.
- **Bark**: frase corta y reactiva ("¡Por aquí!", "¡Recargando!"). Clave: frecuente y de baja prioridad; se descarta si algo más importante suena.
- **Locale**: identificador de idioma/región (`es`, `en`, `pt_BR`). Clave: `TranslationServer.get_locale()` te dice cuál está activo.
- **`tr(clave)`**: función de Godot que devuelve la traducción de una clave según el locale. Clave: los subtítulos usan claves, no texto fijo.
- **Sincronía de subtítulo**: mostrar el texto mientras la voz suena y ocultarlo al terminar. Clave: apóyate en la señal `finished` o en la duración del stream.
- **Cola de diálogo**: estructura FIFO que reproduce líneas una tras otra. Clave: nunca dos voces del mismo hablante a la vez.
- **Prioridad**: valor que decide si una línea nueva espera, se descarta o interrumpe a la actual. Clave: separa lo crítico de lo ambiental.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x, un par de clips de voz por línea (uno por idioma, por ejemplo `hola_es.ogg` y `hola_en.ogg`) y un archivo de traducciones para los subtítulos (un CSV importado como `.translation`, o `.po`). Configura los idiomas en *Project Settings → Localization* y revisa cómo Godot elige el locale. Ten a mano el tutorial de [internacionalización de juegos](https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html), la guía de [importar traducciones](https://docs.godotengine.org/en/stable/tutorials/i18n/importing_translations.html) y la [referencia de AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html). Crea un `Label` para los subtítulos y, si puedes, un bus "Voz" separado del bus de música.

## 🧪 Laboratorio guiado

Construiremos un `DialogueManager` que, al pedir una línea por su clave, reproduce la voz del idioma activo, muestra el subtítulo traducido y encola las peticiones para no solaparlas.

**Paso 1 — Escena.** Crea una escena con un `Node` raíz (`DialogueManager`), un `AudioStreamPlayer` hijo llamado `Voz` (asigna su `bus` a "Voz" si lo creaste) y un `Label` para el subtítulo. Adjunta el script al raíz.

**Paso 2 — Estructura de una línea y la cola.** Cada línea guarda su clave de subtítulo, la ruta base de la voz y su prioridad. Las voces por idioma se nombran por convención `nombre_<locale>.ogg`:

```gdscript
extends Node

@onready var _voz: AudioStreamPlayer = $Voz
@onready var _subtitulo: Label = $Subtitulo

# Cada elemento: { "clave": String, "voz_base": String, "prioridad": int }
var _cola: Array[Dictionary] = []
var _reproduciendo: bool = false

func _ready() -> void:
	_subtitulo.text = ""
	_voz.finished.connect(_on_voz_terminada)
```

**Paso 3 — Encolar con prioridad.** Al pedir una línea, si algo suena y la nueva tiene mayor prioridad, la interrumpe; si no, se pone en cola:

```gdscript
func decir(clave: String, voz_base: String, prioridad: int = 0) -> void:
	var linea := { "clave": clave, "voz_base": voz_base, "prioridad": prioridad }
	if _reproduciendo and prioridad > 0:
		# Interrumpe la línea actual: la nueva es más importante.
		_cola.push_front(linea)
		_voz.stop()
		_on_voz_terminada()  # avanza la cola de inmediato
	else:
		_cola.push_back(linea)
		if not _reproduciendo:
			_avanzar_cola()
```

**Paso 4 — Seleccionar el stream por locale.** Aquí ocurre la localización: se construye la ruta con el idioma activo y, si no existe esa voz, se cae a un idioma por defecto:

```gdscript
func _cargar_voz(voz_base: String) -> AudioStream:
	var locale := TranslationServer.get_locale().substr(0, 2)  # "es_ES" -> "es"
	var ruta := "res://audio/voces/%s_%s.ogg" % [voz_base, locale]
	if not ResourceLoader.exists(ruta):
		ruta = "res://audio/voces/%s_%s.ogg" % [voz_base, "en"]  # fallback
	return load(ruta)
```

**Paso 5 — Reproducir voz + subtítulo.** El subtítulo usa `tr()` sobre la clave, de modo que también se traduce según el locale:

```gdscript
func _avanzar_cola() -> void:
	if _cola.is_empty():
		_reproduciendo = false
		_subtitulo.text = ""
		return
	var linea: Dictionary = _cola.pop_front()
	_reproduciendo = true
	_voz.stream = _cargar_voz(linea["voz_base"])
	_voz.play()
	_subtitulo.text = tr(linea["clave"])  # subtítulo localizado
```

**Paso 6 — Encadenar al terminar.** Cuando la voz acaba, se limpia el subtítulo y se pasa a la siguiente línea. Así la cola nunca solapa:

```gdscript
func _on_voz_terminada() -> void:
	_subtitulo.text = ""
	_avanzar_cola()
```

**Paso 7 — Probar.** Desde otro nodo, encola varias líneas y una alerta prioritaria:

```gdscript
# En cualquier script con acceso al manager:
manager.decir("DLG_SALUDO", "hola", 0)
manager.decir("DLG_INTRO", "intro", 0)      # espera su turno
manager.decir("DLG_ALERTA", "alerta", 1)    # interrumpe: prioridad alta
```

Cambia el locale en *Project Settings* (o con `TranslationServer.set_locale("en")`) y vuelve a ejecutar: oirás la voz en inglés y el subtítulo en inglés, sin tocar la lógica.

**Resultado visible:** líneas que se reproducen una tras otra con subtítulo sincronizado, en el idioma activo, y una alerta que corta al resto.

## ✍️ Ejercicios

1. Añade un tercer idioma y comprueba que el fallback funciona cuando falta una voz.
2. Muestra el nombre del hablante junto al subtítulo con su propia clave traducida.
3. Descarta barks (prioridad 0) si ya hay más de dos en cola, para no acumular ruido.
4. Sincroniza el subtítulo por tramos (varias líneas de texto dentro de una voz larga) usando temporizadores.
5. Aplica ducking al bus de música desde el bus de Voz mientras alguien habla.
6. Registra en consola qué voz (idioma) se cargó realmente para cada línea.

## 📝 Reto verificable

Entrega un `DialogueManager` que reproduzca una conversación de al menos cuatro líneas con subtítulos sincronizados, funcione en dos idiomas (voz y texto cambian con el locale) y gestione una cola con al menos una interrupción por prioridad.

**Criterio de aceptación**: al cambiar el locale, tanto la voz como el subtítulo cambian de idioma; las líneas nunca se solapan (una termina antes de empezar la siguiente salvo interrupción explícita); y una línea prioritaria corta correctamente a una de menor prioridad.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El subtítulo muestra la clave, no el texto | Falta la traducción para esa clave/locale o no importaste el `.translation` |
| Dos voces suenan a la vez | No compruebas `_reproduciendo` antes de reproducir; encola en vez de llamar `play()` directo |
| Error al cargar la voz de un idioma | Falta el archivo de ese locale y no hay fallback; añade la comprobación con `ResourceLoader.exists` |
| La alerta no interrumpe | No manejas la prioridad; al interrumpir, detén la voz y avanza la cola |
| El subtítulo queda pegado en pantalla | No lo limpias en `finished`; vacía el `Label` al terminar y al quedar la cola vacía |

## ❓ Preguntas frecuentes

**¿Debo traducir también el audio o basta con subtítulos?**
Depende del presupuesto. Muchos juegos localizan solo el texto y dejan la voz en un idioma; este sistema soporta ambas cosas y cae al idioma por defecto si falta una voz.

**¿`tr()` funciona en tiempo real al cambiar el locale?**
`tr()` devuelve la traducción del locale actual cada vez que se llama. Si cambias el idioma, las líneas nuevas ya salen traducidas; para las visibles, vuelve a asignar el texto.

**¿Cómo evito que los barks saturen el canal?**
Dales prioridad 0 y limita cuántos pueden estar en cola; descarta los sobrantes. Reserva la interrupción para líneas críticas.

**¿Dónde encaja el bus de Voz?**
En un bus propio con ducking sobre la música, para que el diálogo se entienda siempre por encima del fondo.

## 🔗 Referencias

- [Internacionalizar juegos — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html)
- [Importar traducciones — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/i18n/importing_translations.html)
- [AudioStreamPlayer — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html)
- [TranslationServer — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_translationserver.html)

## ➡️ Siguiente clase

[Clase 136 - Optimización de audio: memoria y streaming](../136-optimizacion-de-audio-memoria-y-streaming/README.md)
