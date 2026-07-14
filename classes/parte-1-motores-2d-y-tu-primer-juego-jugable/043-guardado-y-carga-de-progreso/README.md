# Clase 043 — Guardado y carga de progreso

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4 (File system / JSON)*
> ⏱️ Duración estimada: **90 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Hacer que el progreso del jugador sobreviva al cierre del juego. En esta clase implementarás **persistencia** con `FileAccess` y **JSON** escribiendo en la ruta especial `user://`, la carpeta que Godot reserva para datos de usuario en cada plataforma. Guardarás datos como la **puntuación máxima**, el **nivel alcanzado**, las **vidas** y los **ajustes de volumen**, y los recuperarás al iniciar el juego.

Un buen sistema de guardado también es robusto: aprenderás a manejar los casos en que el archivo no existe todavía o está corrupto, para que el juego no se rompa. Al terminar, tu Autoload `GameState` tendrá `guardar_partida()` y `cargar_partida()`, la puntuación máxima persistirá entre sesiones, y el menú mostrará un botón **"Continuar"** solo si existe una partida guardada.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Usar `FileAccess.open` con `WRITE` y `READ` sobre la ruta `user://`.
2. Serializar un diccionario a texto con `JSON.stringify` y reconstruirlo con `JSON.parse_string`.
3. Decidir **qué datos** conviene guardar y estructurarlos en un diccionario.
4. Manejar errores de guardado: archivo inexistente y JSON corrupto.
5. Mostrar un botón **"Continuar"** en el menú solo cuando existe un guardado válido.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Ruta `user://` | Es el único lugar seguro y persistente para escribir por plataforma. |
| 2 | FileAccess (WRITE/READ) | API para abrir, escribir y leer archivos en disco. |
| 3 | JSON.stringify / parse_string | Convierte estructuras de datos a texto y viceversa. |
| 4 | Qué guardar | Definir el "estado" del juego evita guardar de más o de menos. |
| 5 | Manejo de errores | Un guardado ausente o corrupto no debe romper el juego. |
| 6 | GameState como Autoload | Centraliza el estado y las funciones de guardado. |
| 7 | Botón "Continuar" | UX real: solo se ofrece si hay algo que continuar. |
| 8 | Rutas relativas vs absolutas | Explica por qué nunca se usan rutas absolutas del disco. |

## 📖 Definiciones y características

- **`user://`**: prefijo de ruta que Godot traduce a una carpeta de datos por usuario y plataforma (AppData en Windows, `~/.local/share` en Linux). Clave: es escribible y persistente.
- **`res://`**: raíz del proyecto; **solo lectura** una vez exportado el juego. Clave: nunca guardes progreso ahí.
- **FileAccess**: clase para abrir archivos en modo lectura/escritura. Clave: devuelve `null` si falla, hay que comprobarlo.
- **`store_string` / `get_as_text`**: escribe y lee todo el contenido del archivo como texto. Clave: combínalos con JSON.
- **JSON.stringify**: convierte un `Dictionary`/`Array` a una cadena JSON. Clave: acepta un segundo argumento para indentar y hacerlo legible.
- **JSON.parse_string**: parsea texto JSON y devuelve el dato, o `null` si el texto no es válido. Clave: úsalo para detectar corrupción.
- **Diccionario de estado**: estructura clave→valor con todo lo persistente (nivel, puntuación, ajustes). Clave: es la "foto" del progreso.
- **Ruta absoluta**: ruta fija del disco (`C:\...`); nunca usarla porque cambia por equipo y plataforma. Clave: siempre `user://`.

## 🧰 Herramientas y preparación

Continúa con `PlataformasCurso`. No necesitas assets nuevos; sí conviene tener un Autoload `GameState` (créalo si no existe, similar a los Autoloads de audio de la Clase 041) y una escena de **menú** con botones. Para inspeccionar dónde se guarda tu archivo, en el editor ve a **Project → Open User Data Folder**. Documentación de referencia: guardado de juegos <https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html> y `FileAccess` <https://docs.godotengine.org/en/stable/classes/class_fileaccess.html>.

## 🧪 Laboratorio guiado

Implementaremos guardado/carga con JSON en `GameState` y un botón "Continuar" en el menú.

1. **Preparar el Autoload GameState.** Crea `res://sistema/game_state.gd` y regístralo en **Project Settings → Globals → Autoload** con el nombre `GameState`. Define el estado y la ruta de guardado:

```gdscript
extends Node

const RUTA_GUARDADO := "user://save.json"

# Estado persistente del juego con valores por defecto.
var puntuacion_maxima := 0
var nivel_actual := 1
var vidas := 3
var volumen_musica := 1.0
var volumen_sfx := 1.0
```

2. **Escribir guardar_partida().** Empaqueta el estado en un diccionario, conviértelo a JSON y escríbelo en `user://`:

```gdscript
func guardar_partida() -> void:
	var datos := {
		"puntuacion_maxima": puntuacion_maxima,
		"nivel_actual": nivel_actual,
		"vidas": vidas,
		"volumen_musica": volumen_musica,
		"volumen_sfx": volumen_sfx,
	}
	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo == null:
		push_error("No se pudo abrir el guardado: " + str(FileAccess.get_open_error()))
		return
	# El segundo argumento "\t" indenta el JSON para que sea legible.
	archivo.store_string(JSON.stringify(datos, "\t"))
	archivo.close()
```

3. **Leer cargar_partida() con manejo de errores.** Comprueba que el archivo exista y que el JSON sea válido antes de aplicar los datos:

```gdscript
func existe_guardado() -> bool:
	return FileAccess.file_exists(RUTA_GUARDADO)

func cargar_partida() -> bool:
	if not existe_guardado():
		return false   # primera vez que se juega: no hay nada que cargar
	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if archivo == null:
		push_error("No se pudo leer el guardado.")
		return false
	var texto := archivo.get_as_text()
	archivo.close()
	var datos = JSON.parse_string(texto)
	# parse_string devuelve null si el JSON está corrupto.
	if typeof(datos) != TYPE_DICTIONARY:
		push_error("Guardado corrupto, se ignora.")
		return false
	# Usamos get(clave, defecto) por si falta algún campo en versiones viejas.
	puntuacion_maxima = int(datos.get("puntuacion_maxima", 0))
	nivel_actual = int(datos.get("nivel_actual", 1))
	vidas = int(datos.get("vidas", 3))
	volumen_musica = float(datos.get("volumen_musica", 1.0))
	volumen_sfx = float(datos.get("volumen_sfx", 1.0))
	return true
```

4. **Cargar al iniciar el juego.** En `_ready()` del propio `GameState`, intenta cargar el progreso una sola vez:

```gdscript
func _ready() -> void:
	if cargar_partida():
		print("Progreso cargado. Récord: ", puntuacion_maxima)
	else:
		print("Sin guardado previo, empezando de cero.")
```

5. **Actualizar la puntuación máxima.** Cuando termina una partida, compara y guarda solo si se batió el récord:

```gdscript
func registrar_puntuacion(puntos: int) -> void:
	if puntos > puntuacion_maxima:
		puntuacion_maxima = puntos
		guardar_partida()   # persistimos el nuevo récord al instante
```

6. **Botón "Continuar" condicional en el menú.** En el script del menú principal, muestra u oculta el botón según exista guardado:

```gdscript
extends Control

@onready var boton_continuar: Button = $VBox/Continuar

func _ready() -> void:
	# Solo ofrecemos "Continuar" si hay una partida guardada.
	boton_continuar.visible = GameState.existe_guardado()

func _on_continuar_pressed() -> void:
	# Retomamos el nivel guardado.
	get_tree().change_scene_to_file("res://escenas/nivel_%d.tscn" % GameState.nivel_actual)

func _on_nueva_partida_pressed() -> void:
	GameState.nivel_actual = 1
	GameState.puntuacion_maxima = GameState.puntuacion_maxima  # se conserva el récord
	get_tree().change_scene_to_file("res://escenas/nivel_1.tscn")
```

7. **Guardar los ajustes de volumen.** Conecta los controles de volumen de tu menú de ajustes para que actualicen `GameState` y guarden:

```gdscript
func _on_slider_musica_changed(valor: float) -> void:
	GameState.volumen_musica = valor
	# Reutiliza el AudioServer de la Clase 041 para aplicarlo en vivo.
	var idx := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(idx, linear_to_db(valor))
	GameState.guardar_partida()
```

8. **Probar la persistencia.** Ejecuta con **F5**, sube el récord y ajusta el volumen. Cierra por completo el juego y vuelve a abrirlo: el récord y los ajustes deben seguir ahí, y el botón "Continuar" debe aparecer. Abre **Project → Open User Data Folder** y verás tu `save.json` legible.

## ✍️ Ejercicios

1. Añade un campo `monedas_totales` al diccionario de guardado y muéstralo en el HUD al cargar.
2. Implementa un botón **"Borrar datos"** que elimine el guardado con `DirAccess.remove_absolute` y oculte "Continuar".
3. Guarda también la marca de tiempo con `Time.get_datetime_string_from_system()` y muéstrala como "Última partida".
4. Añade un número de **versión** al guardado (`"version": 1`) y prepara `cargar_partida()` para migrar formatos futuros.
5. Provoca a propósito un JSON corrupto editando el archivo a mano y comprueba que el juego arranca sin romperse.
6. Separa los ajustes en un segundo archivo `user://config.json` independiente del progreso de partida.

## 📝 Reto verificable

Implementa un sistema de **tres ranuras de guardado** (`user://save_1.json`, `save_2.json`, `save_3.json`). El menú debe listar las tres ranuras mostrando "Vacía" o el nivel y la puntuación de cada una, permitir guardar en la ranura elegida y cargar desde ella. Reutiliza `guardar_partida()` y `cargar_partida()` parametrizando la ruta.

**Criterio de aceptación**: se puede guardar en la ranura 2, cerrar el juego, reabrirlo y cargar exactamente esa ranura recuperando su nivel y puntuación, mientras las otras ranuras conservan su propio estado o siguen vacías, todo sin errores en el Output.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El progreso no persiste tras cerrar | Guardaste en `res://` (solo lectura al exportar). Usa siempre `user://`. |
| "Cannot call method 'store_string' on a null value" | `FileAccess.open` devolvió `null`. Comprueba el resultado antes de usarlo. |
| El juego crashea al arrancar por un guardado dañado | No validaste el parse. Verifica `typeof(datos) == TYPE_DICTIONARY` antes de aplicarlo. |
| Los números se cargan como texto o fallan comparaciones | JSON devuelve floats; convierte con `int(...)`/`float(...)` al leer. |
| Funciona en el editor pero no en el .exe con ruta absoluta | Usaste una ruta `C:\...`. Nunca uses rutas absolutas; solo `user://`. |
| "Continuar" aparece aunque no haya partida | Comprobaste mal la existencia. Usa `FileAccess.file_exists(RUTA_GUARDADO)`. |

## ❓ Preguntas frecuentes

**❓ ¿Dónde queda físicamente el archivo `user://save.json`?** En una carpeta por-usuario que depende del sistema (en Windows dentro de `AppData`). Ábrela desde **Project → Open User Data Folder** para inspeccionarla.

**❓ ¿Por qué JSON y no un formato binario?** JSON es legible, fácil de depurar y suficiente para un plataformas 2D. Para datos muy grandes o que quieras ofuscar, Godot ofrece recursos binarios, pero aquí no hace falta.

**❓ ¿Qué pasa si el jugador edita el JSON para hacer trampas?** En un juego local es un riesgo asumible; si te preocupa, puedes cifrar el archivo con `FileAccess.open_encrypted_with_pass`, pero para este curso el JSON plano es suficiente.

**❓ ¿Debo guardar en cada frame?** No. Guarda en momentos concretos (fin de nivel, nuevo récord, cambio de ajuste). Escribir a disco cada frame es innecesario y puede causar tirones.

## 🔗 Referencias

- Godot Docs — Saving games: <https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html>
- Godot Docs — File paths (user://): <https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html>
- Godot Docs — FileAccess: <https://docs.godotengine.org/en/stable/classes/class_fileaccess.html>
- Godot Docs — JSON: <https://docs.godotengine.org/en/stable/classes/class_json.html>
- Godot Docs — Background loading / IO: <https://docs.godotengine.org/en/stable/tutorials/io/index.html>

## ➡️ Siguiente clase

[Clase 044 - Empaquetado y exportación del juego 2D (Windows y web)](../044-empaquetado-y-exportacion-del-juego-2d-windows-y-web/README.md)
