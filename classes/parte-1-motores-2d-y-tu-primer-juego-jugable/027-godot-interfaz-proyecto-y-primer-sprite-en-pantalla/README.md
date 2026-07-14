# Clase 027 — Godot: interfaz, proyecto y primer sprite en pantalla

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4 (Editor introduction)*
> ⏱️ Duración estimada: **70 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dominar la interfaz del editor de Godot 4 y dejar el proyecto del curso mostrando el sprite del jugador correctamente en pantalla, con una resolución y un modo de estiramiento adecuados para un plataformas 2D.

Recorreremos los paneles clave (FileSystem, Scene, Inspector, viewport y Output), importaremos un sprite, ajustaremos la ventana del juego en Project Settings y ejecutaremos con F5/F6. Terminarás con un primer script en `_ready()` que confirma que el nodo está vivo dentro del SceneTree.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Identificar y usar los cinco paneles principales del editor de Godot 4.
2. Importar una imagen al proyecto y asignarla a un nodo `Sprite2D`.
3. Configurar la resolución base y el modo de estiramiento en Project Settings.
4. Distinguir entre ejecutar el proyecto (F5) y la escena actual (F6).
5. Escribir un script `_ready()` que imprima un mensaje en el panel Output.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Panel FileSystem | Es tu explorador de assets del proyecto. |
| 2 | Panel Scene | Muestra el árbol de nodos de la escena actual. |
| 3 | Inspector | Edita propiedades de cualquier nodo o recurso. |
| 4 | Viewport 2D | Donde compones y ves la escena. |
| 5 | Panel Output | Muestra prints, avisos y errores. |
| 6 | Importar sprites | Convierte imágenes en texturas usables. |
| 7 | Resolución y estiramiento | Define cómo se ve el juego en distintas pantallas. |
| 8 | F5 vs F6 | Controla qué se ejecuta al probar. |

## 📖 Definiciones y características

- **FileSystem**: panel que lista los archivos bajo `res://`. Clave: arrastrar desde aquí crea nodos y asigna recursos rápido.
- **Inspector**: editor de propiedades del nodo seleccionado. Clave: casi todo lo visual se ajusta aquí sin escribir código.
- **Viewport**: área central donde ves y colocas los nodos. Clave: el modo 2D usa píxeles con el origen arriba-izquierda.
- **Sprite2D**: nodo que dibuja una textura 2D. Clave: su propiedad `centered` decide si el pivote está en el centro.
- **Textura**: recurso de imagen importado (`.png`, `.svg`). Clave: Godot reimporta al detectar cambios en el archivo.
- **Main Scene**: escena que arranca con F5. Clave: es la puerta de entrada del juego empaquetado.
- **Viewport width/height**: resolución base del juego en Project Settings. Clave: referencia para posiciones y cámara.
- **Stretch mode**: cómo se escala la imagen al cambiar el tamaño de ventana. Clave: `canvas_items` mantiene nitidez en 2D.

## 🧰 Herramientas y preparación

Continúa en el proyecto `PlataformasCurso` de la clase anterior. Ten **Godot 4.x** abierto. Si quieres un sprite propio, descarga un PNG pequeño (por ejemplo 32×32 o 64×64 px) o reutiliza el `icon.svg` del proyecto. Para practicar con arte libre puedes visitar <https://kenney.nl/assets> (assets gratuitos y sin restricciones).

Consulta como apoyo la introducción al editor: <https://docs.godotengine.org/en/stable/getting_started/introduction/first_look_at_the_editor.html>. Todo lo de esta clase se hace con el editor gráfico y un script mínimo.

## 🧪 Laboratorio guiado

Vamos a mostrar el sprite del jugador con una resolución definida y a imprimir un mensaje al arrancar.

1. Abre `escenas/mundo.tscn`. Observa los paneles: **Scene** (árbol), **FileSystem** (archivos), **Inspector** (propiedades), viewport central y **Output** (abajo).

2. Si tienes un PNG propio, arrástralo desde el explorador de Windows al panel **FileSystem**, dentro de la carpeta `sprites/`. Godot lo importará como textura automáticamente.

3. Abre `escenas/jugador.tscn`. Selecciona el `Sprite2D` y, en el **Inspector**, cambia **Texture** por tu nuevo PNG (o mantén `icon.svg`). Verifica que **Centered** esté activado para que el pivote quede en el centro.

4. Vuelve a `escenas/mundo.tscn`. Selecciona la instancia `Jugador` y, en el Inspector, ajusta **Transform → Position** a valores como `(576, 324)` para centrarla en una resolución 1152×648.

5. Configura la ventana del juego. Menú **Project → Project Settings → Display → Window**. Ajusta **Viewport Width** a `1152` y **Viewport Height** a `648`.

6. En la misma sección, baja a **Stretch** y pon **Mode** en `canvas_items` y **Aspect** en `keep`. Así el juego escala manteniendo proporción y nitidez.

7. Asegúrate de que **Project → Project Settings → Application → Run → Main Scene** apunta a `escenas/mundo.tscn`.

8. Añade un script al jugador para confirmar que arranca. Abre `jugador.tscn`, selecciona el nodo raíz `Jugador`, **Attach Script**, ruta `escenas/jugador.gd`:

```gdscript
extends Node2D

# Se ejecuta una vez cuando el nodo entra al SceneTree.
func _ready() -> void:
	print("Jugador en pantalla en la posicion: ", global_position)
	# Confirmamos que el sprite hijo tiene textura asignada.
	var sprite := $Sprite2D
	if sprite.texture == null:
		push_warning("El Sprite2D no tiene textura asignada")
	else:
		print("Textura del sprite: ", sprite.texture.resource_path)
```

9. Ejecuta el proyecto con **F5**. Debe abrirse la ventana del juego mostrando el sprite centrado, y el panel **Output** debe imprimir la posición y la ruta de la textura.

10. Prueba **F6** mientras tienes abierto `jugador.tscn`: ejecuta solo esa escena. Compara: F5 corre siempre la Main Scene; F6 corre la escena que estás editando. Redimensiona la ventana del juego y observa cómo el estiramiento mantiene la proporción.

Ya tienes el sprite del jugador en pantalla con una configuración de pantalla profesional para un plataformas 2D.

## ✍️ Ejercicios

1. Cambia la resolución base a 640×360 y ajusta la posición del jugador para que siga centrado.
2. Prueba los tres modos de **Stretch** (`disabled`, `canvas_items`, `viewport`) y describe la diferencia visual.
3. Desactiva **Centered** en el `Sprite2D` y explica cómo cambia el pivote y la posición.
4. Añade al script un `print` con el tamaño de la textura usando `sprite.texture.get_size()`.
5. Importa un segundo sprite y crea una escena `Enemigo` con él, sin script todavía.
6. Cambia el título de la ventana en **Display → Window → Title** y verifica el cambio al ejecutar.

## 📝 Reto verificable

Configura el proyecto a 1280×720 con estiramiento `canvas_items`/`keep`, coloca el sprite del jugador perfectamente centrado y haz que el script imprima al arrancar tanto la resolución del proyecto (leyéndola de `ProjectSettings`) como la posición del jugador.

**Criterio de aceptación**: al pulsar F5 la ventana mide 1280×720, el sprite aparece centrado y el Output muestra la resolución y la posición sin errores ni advertencias.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El sprite se ve borroso o pixelado al escalar | Modo de estiramiento inadecuado. Usa `canvas_items` y revisa el filtro de la textura en Import. |
| "No main scene has ever been defined" | Falta asignar Main Scene en Project Settings → Run. |
| La imagen arrastrada no aparece en FileSystem | Se copió fuera de la carpeta del proyecto. Debe estar bajo `res://`. |
| El sprite aparece en una esquina | `Centered` está desactivado o la posición es (0,0). Ajusta posición o reactiva Centered. |
| Cambios en el PNG no se reflejan | Godot no reimportó. Vuelve a enfocar el editor o revisa la pestaña Import. |

## ❓ Preguntas frecuentes

**❓ ¿Cuál es la diferencia entre F5 y F6?** F5 ejecuta siempre la Main Scene del proyecto; F6 ejecuta la escena que tienes abierta, útil para probar piezas aisladas.

**❓ ¿Qué resolución conviene para un plataformas 2D?** Una base fija (por ejemplo 1152×648 o 640×360) con estiramiento `canvas_items` da control y nitidez consistente en distintas pantallas.

**❓ ¿Puedo usar imágenes SVG como sprites?** Sí. Godot 4 importa SVG como textura y permite escalarlo desde la pestaña Import sin perder calidad.

**❓ ¿Por qué el origen 2D está arriba a la izquierda?** Es la convención de coordenadas de pantalla: X crece a la derecha e Y hacia abajo, algo a tener en cuenta al mover nodos.

## 🔗 Referencias

- Godot Docs — First look at the editor: <https://docs.godotengine.org/en/stable/getting_started/introduction/first_look_at_the_editor.html>
- Godot Docs — Multiple resolutions: <https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html>
- Godot Docs — Importing images: <https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html>
- Godot Docs — Sprite2D: <https://docs.godotengine.org/en/stable/classes/class_sprite2d.html>

## ➡️ Siguiente clase

[Clase 028 - El game loop en la práctica: _process, _physics_process y señales](../028-el-game-loop-en-la-practica-process-physics-process-y-senales/README.md)
