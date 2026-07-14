# Clase 018 — Sistemas de coordenadas y espacios: local, mundo, cámara, pantalla

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Eric Lengyel, Mathematics for 3D Game Programming and Computer Graphics*
> ⏱️ Duración estimada: **90 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Un objeto en un juego no tiene "una" posición: tiene varias según el espacio en el que lo mires. Su posición **local** (relativa a su padre), su posición en el **mundo**, su posición vista desde la **cámara** y su posición final en **pantalla** (píxeles). Confundir estos espacios es una de las causas más frecuentes de bugs de colocación e input.

En esta clase entenderás la jerarquía de transformaciones padre/hijo, la diferencia entre espacio local y mundo, el espacio de cámara/vista y el espacio de pantalla. En 2D verás por qué el eje **Y crece hacia abajo** y cómo convertir la posición del ratón a coordenadas de mundo. Lo comprobarás en Godot moviendo un padre y observando a sus hijos, y colocando un marcador donde clicas.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diferenciar posición local (`position`) de posición de mundo (`global_position`).
2. Explicar cómo una jerarquía padre/hijo compone transformaciones.
3. Describir el espacio de cámara/vista y el espacio de pantalla en píxeles.
4. Justificar por qué en 2D el eje Y apunta hacia abajo.
5. Convertir la posición del ratón a coordenadas de mundo y colocar un objeto allí.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Espacio local | Coordenadas relativas al nodo padre. |
| 2 | Espacio de mundo | Coordenadas globales absolutas de la escena. |
| 3 | Jerarquía padre/hijo | Mover el padre transforma a todos los hijos. |
| 4 | Espacio de cámara/vista | Todo se expresa relativo a la cámara. |
| 5 | Espacio de pantalla | Píxeles del viewport; origen arriba-izquierda. |
| 6 | Eje Y en 2D | Y hacia abajo; afecta el sentido del movimiento. |
| 7 | Ratón → mundo | Traducir clics a posiciones jugables. |
| 8 | `to_local`/`to_global` | Convertir entre espacios de forma segura. |

## 📖 Definiciones y características

- **Espacio local**: sistema de coordenadas relativo al nodo padre. Clave: en Godot es la propiedad `position`.
- **Espacio de mundo (global)**: coordenadas absolutas en la escena. Clave: es `global_position`, resultado de acumular las transformaciones de los padres.
- **Transformación**: combinación de traslación, rotación y escala aplicada a un nodo. Clave: se hereda de padre a hijo.
- **Jerarquía de escena**: árbol de nodos donde cada hijo se ubica respecto a su padre. Clave: mover el padre mueve a los hijos.
- **Espacio de cámara/vista**: coordenadas relativas a la cámara del jugador. Clave: la cámara define qué porción del mundo se ve.
- **Espacio de pantalla**: coordenadas en píxeles del viewport, origen arriba-izquierda. Clave: la posición del ratón llega en este espacio.
- **Eje Y hacia abajo (2D)**: en pantalla, Y aumenta al bajar. Clave: sumar a `y` mueve el objeto hacia abajo.
- **`get_global_mouse_position()`**: función de Godot que da la posición del ratón ya convertida a mundo. Clave: evita conversiones manuales de píxeles a mundo.

## 🧰 Herramientas y preparación

Usarás **Godot 4** (<https://godotengine.org/>) con GDScript. Trabajarás con nodos **Node2D**, **Sprite2D** y **Camera2D**. La referencia teórica es *Mathematics for 3D Game Programming and Computer Graphics* de Eric Lengyel (<https://foundationsofgameenginedev.com/>). Consulta también la documentación de Godot sobre `Node2D` y transformaciones 2D (<https://docs.godotengine.org/en/stable/tutorials/2d/2d_transforms.html>) y sobre el sistema de coordenadas (<https://docs.godotengine.org/en/stable/tutorials/2d/2d_movement.html>). No necesitas assets externos: basta el `icon.svg` que trae cada proyecto.

## 🧪 Laboratorio guiado

### Paso 1 — Montar una jerarquía padre/hijo

Crea un proyecto 2D. Estructura la escena así: un **Node2D** llamado `Padre`, y como hijo suyo un **Sprite2D** llamado `Hijo` con el `icon.svg` como textura. En el editor, coloca `Hijo` con `position = (100, 0)` respecto al padre. Añade a `Padre` un script con este contenido:

```gdscript
extends Node2D

func _ready() -> void:
    var hijo := $Hijo
    print("Hijo position (local):  ", hijo.position)
    print("Hijo global_position:   ", hijo.global_position)
```

### Paso 2 — Observar local vs global al mover el padre

Coloca el `Padre` en `(300, 200)` desde el inspector y ejecuta. La consola mostrará que `position` del hijo sigue siendo `(100, 0)` (relativa al padre) mientras que `global_position` es `(400, 200)`: la suma de la posición del padre más la local del hijo. Mover el padre cambia el `global_position` del hijo pero no su `position` local.

### Paso 3 — Confirmar que el eje Y va hacia abajo

Añade movimiento al padre para verlo en vivo:

```gdscript
func _process(delta: float) -> void:
    # Sumar a y mueve el nodo HACIA ABAJO en pantalla
    position.y += 50.0 * delta
```

Ejecuta: el conjunto padre-hijo desciende. Sumar a `y` baja el objeto porque en 2D el eje Y crece hacia abajo, al contrario que en las gráficas matemáticas clásicas.

### Paso 4 — Convertir el ratón a mundo y colocar un marcador

Agrega un **Camera2D** como hijo de la raíz (para tener un espacio de cámara claro) y un **Sprite2D** llamado `Marcador`. En el script de la raíz, coloca el marcador donde se hace clic:

```gdscript
extends Node2D

@onready var marcador: Sprite2D = $Marcador

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        # get_global_mouse_position() ya devuelve coordenadas de MUNDO
        var mundo := get_global_mouse_position()
        marcador.global_position = mundo
        print("Clic en pantalla: ", event.position, "  -> mundo: ", mundo)
```

Ejecuta y haz clic: el `Marcador` salta exactamente bajo el cursor. La consola muestra la posición en **pantalla** (`event.position`, en píxeles) y la posición en **mundo** ya convertida. Si mueves la cámara, verás que un mismo píxel de pantalla corresponde a distintas coordenadas de mundo.

## ✍️ Ejercicios

1. Rota el `Padre` 45° y observa cómo cambia el `global_position` del hijo sin que cambie su `position`.
2. Usa `to_local()` sobre el padre para convertir un punto de mundo a local e imprímelo.
3. Añade un segundo hijo y comprueba que ambos se mueven juntos al mover el padre.
4. Desplaza la `Camera2D` y verifica que el mismo clic en pantalla da una posición de mundo distinta.
5. Muestra en pantalla, con un `Label`, la posición del ratón en mundo actualizada cada frame.
6. Explica en dos líneas la diferencia entre `event.position` y `get_global_mouse_position()`.

## 📝 Reto verificable

Construye una escena con una `Camera2D` desplazable (por ejemplo, con las flechas) y un marcador que siga al ratón en coordenadas de **mundo**. Al hacer clic, deja una "huella" (instancia o marca) en esa posición de mundo, de modo que si mueves la cámara las huellas permanezcan ancladas al mundo, no a la pantalla. **Criterio de aceptación**: las huellas colocadas no se desplazan respecto al mundo cuando mueves la cámara, y el marcador coincide siempre con el cursor.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El marcador aparece desfasado del cursor | Usaste `event.position` (pantalla) como mundo; usa `get_global_mouse_position()`. |
| Mover el padre no mueve al hijo | El nodo no es realmente hijo en el árbol; revisa la jerarquía de la escena. |
| El objeto "sube" al sumar a `y` | Suposición de eje Y hacia arriba; en 2D sumar a `y` baja el objeto. |
| `global_position` no cambia | Modificaste `position` de un nodo sin padre transformado; ambos coinciden si el padre está en el origen. |
| Las huellas se mueven con la cámara | Fijaste su posición en espacio de pantalla; asigna `global_position` en mundo. |

## ❓ Preguntas frecuentes

**❓ ¿Cuándo uso `position` y cuándo `global_position`?** Usa `position` para ubicar respecto al padre y `global_position` cuando necesitas la posición absoluta en la escena, por ejemplo para colisiones o distancias entre objetos de distintas ramas.

**❓ ¿Por qué el eje Y apunta hacia abajo en 2D?** Hereda la convención de las pantallas y los sistemas de imagen, cuyo origen `(0,0)` está en la esquina superior izquierda y crece hacia abajo.

**❓ ¿`get_global_mouse_position()` tiene en cuenta la cámara?** Sí. Devuelve la posición del ratón ya transformada al espacio de mundo, considerando el desplazamiento y zoom de la `Camera2D` activa.

**❓ ¿Qué hacen `to_local()` y `to_global()`?** Convierten un punto entre el espacio de mundo y el espacio local de un nodo, útil cuando necesitas expresar una coordenada relativa a un objeto concreto.

## 🔗 Referencias

- Foundations of Game Engine Development (Eric Lengyel): <https://foundationsofgameenginedev.com/>
- Godot — Transforms 2D: <https://docs.godotengine.org/en/stable/tutorials/2d/2d_transforms.html>
- Godot — Node2D (clase): <https://docs.godotengine.org/en/stable/classes/class_node2d.html>
- Godot — CanvasItem get_global_mouse_position: <https://docs.godotengine.org/en/stable/classes/class_canvasitem.html>

## ➡️ Siguiente clase

[Clase 019 - Color, sprites, texturas y formatos de imagen](../019-color-sprites-texturas-y-formatos-de-imagen/README.md)
