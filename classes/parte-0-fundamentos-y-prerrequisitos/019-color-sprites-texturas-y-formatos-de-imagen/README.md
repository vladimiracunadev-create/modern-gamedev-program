# Clase 019 — Color, sprites, texturas y formatos de imagen

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Especificaciones PNG/WebP y documentación de import de Godot*
> ⏱️ Duración estimada: **90 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

El arte de un juego llega al motor como imágenes, pero cómo se codifican esas imágenes (color, canal alfa, formato, filtrado) determina si tu pixel art se ve nítido o borroso y si tu build pesa poco o demasiado. Elegir mal el filtro o el formato es un error silencioso muy común.

En esta clase estudiarás el modelo **RGB(A)**, el canal **alfa** y el alfa premultiplicado; qué es un **sprite** y una **spritesheet/atlas**; el **filtrado** de texturas (nearest para pixel art, linear para arte suave), los **mipmaps**, los formatos (**PNG**, **JPG**, **WebP**) y la cuestión de **power-of-two** y el escalado entero. Lo aplicarás importando un PNG en Godot con filtro *Nearest* y recortando una región con **AtlasTexture**.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Describir el modelo RGBA y el papel del canal alfa.
2. Elegir el filtro correcto (nearest vs linear) según el estilo de arte.
3. Explicar qué es una spritesheet y para qué sirve un atlas.
4. Comparar PNG, JPG y WebP y decidir cuál usar en cada caso.
5. Importar un PNG con filtro Nearest y crear un AtlasTexture recortando una región.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Modelo RGBA | Base de todo color y transparencia en pantalla. |
| 2 | Canal alfa y premultiplicado | Controla transparencia y evita halos en los bordes. |
| 3 | Sprite y spritesheet | Un atlas agrupa muchos sprites en una imagen. |
| 4 | Filtrado nearest/linear | Nitidez del pixel art vs suavizado. |
| 5 | Mipmaps | Reducen aliasing al alejar texturas. |
| 6 | Formatos PNG/JPG/WebP | Peso, pérdida y soporte de alfa. |
| 7 | Power-of-two | Compatibilidad y mipmaps eficientes. |
| 8 | Escalado entero | Mantiene el pixel art sin deformar. |

## 📖 Definiciones y características

- **RGBA**: color definido por rojo, verde, azul y alfa. Clave: cada canal suele ir de 0 a 255 (u 0.0 a 1.0).
- **Canal alfa**: componente que define la opacidad de cada píxel. Clave: 0 es transparente, máximo es opaco.
- **Alfa premultiplicado**: el color ya viene multiplicado por su alfa. Clave: evita halos oscuros/claros en los bordes al mezclar.
- **Sprite**: imagen 2D que representa un objeto del juego. Clave: en Godot se muestra con `Sprite2D`.
- **Spritesheet / atlas**: una sola imagen que contiene muchos sprites o fotogramas. Clave: reduce draw calls y organiza el arte.
- **Filtrado de textura**: cómo se interpola la textura al escalar. Clave: *Nearest* para pixel art, *Linear* para arte suave.
- **Mipmaps**: versiones prereducidas de una textura. Clave: evitan parpadeo/aliasing cuando el objeto se ve pequeño.
- **Power-of-two (POT)**: dimensiones potencia de dos (256, 512, 1024). Clave: favorece mipmaps y compresión en GPU.

## 🧰 Herramientas y preparación

Usarás **Godot 4** (<https://godotengine.org/>) y una imagen PNG de prueba (puede ser una spritesheet de pixel art de dominio público, por ejemplo de <https://kenney.nl/assets> o <https://opengameart.org/>). Para crear o editar sprites puedes usar Krita (<https://krita.org/>) o Aseprite (<https://www.aseprite.org/>). La referencia sobre formatos son las especificaciones oficiales de PNG (<https://www.w3.org/TR/png/>) y WebP (<https://developers.google.com/speed/webp>). Para el pipeline de importación consulta la documentación de Godot sobre importación de imágenes (<https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html>) y sobre `AtlasTexture` (<https://docs.godotengine.org/en/stable/classes/class_atlastexture.html>).

## 🧪 Laboratorio guiado

### Paso 1 — Importar un PNG y elegir el filtro

Copia una spritesheet PNG dentro de la carpeta del proyecto (por ejemplo `res://sprites/hoja.png`). En el panel **FileSystem** haz doble clic en la imagen para abrir la pestaña **Import**. Para pixel art, en **Detect 3D** y **Mipmaps** deja lo básico y, sobre todo, ajusta el filtro. En Godot 4 el filtro se controla por textura y por nodo: selecciona en Import la opción adecuada o, mejor, configúralo en el nodo. Tras cambiar cualquier ajuste de Import pulsa **Reimport**.

### Paso 2 — Mostrar el sprite con filtro Nearest

Añade un **Sprite2D**, asígnale la textura importada y escálalo (por ejemplo `scale = (6, 6)`) para ver los píxeles grandes. Fija el filtro Nearest en el nodo mediante su propiedad **Texture > Filter** = *Nearest*, o por código:

```gdscript
extends Sprite2D

func _ready() -> void:
    # CanvasItem.TEXTURE_FILTER_NEAREST mantiene los píxeles nítidos
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
```

Compara: con *Linear* el arte ampliado se ve borroso; con *Nearest* los píxeles quedan definidos, que es lo que buscas en pixel art.

### Paso 3 — Recortar una región con AtlasTexture

Un **AtlasTexture** muestra solo una región rectangular de una textura mayor (la spritesheet). Crea uno por código apuntando a un fotograma:

```gdscript
extends Sprite2D

func _ready() -> void:
    var hoja: Texture2D = load("res://sprites/hoja.png")

    var atlas := AtlasTexture.new()
    atlas.atlas = hoja
    # region = (x, y, ancho, alto) de la celda dentro de la spritesheet
    atlas.region = Rect2(0, 0, 32, 32)

    texture = atlas
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
```

El sprite ahora muestra únicamente el recorte de 32×32 en la esquina superior izquierda de la hoja.

### Paso 4 — Cambiar de fotograma moviendo la región

Para ver otro sprite de la misma hoja, desplaza `region` a otra celda:

```gdscript
    # Segundo fotograma: una celda a la derecha (x = 32)
    atlas.region = Rect2(32, 0, 32, 32)
```

Cambia `x` en múltiplos del ancho de celda para recorrer la fila; cambia `y` para bajar de fila. Así, con una sola imagen y varios `AtlasTexture`, obtienes todos los fotogramas: la base de las animaciones por spritesheet.

## ✍️ Ejercicios

1. Importa la misma imagen con *Linear* y con *Nearest* y compara el resultado ampliado.
2. Crea tres `AtlasTexture` que muestren tres celdas distintas de la misma spritesheet.
3. Averigua las dimensiones de tu PNG y di si son power-of-two.
4. Exporta la misma imagen a PNG, JPG y WebP y compara el peso en disco y si conservan el alfa.
5. Explica en dos líneas por qué el JPG no sirve para sprites con transparencia.
6. Activa Mipmaps en una textura y describe cuándo notarías su efecto.

## 📝 Reto verificable

A partir de una spritesheet de pixel art, muestra en pantalla al menos cuatro fotogramas distintos usando `AtlasTexture` sobre uno o varios `Sprite2D`, todos con filtro **Nearest** para que se vean nítidos al ampliarlos. Los recortes deben corresponder a celdas reales de la hoja (regiones correctas). **Criterio de aceptación**: se ven cuatro sprites diferentes y nítidos (sin desenfoque) al escalarlos, cada uno recortado de una región distinta de la misma imagen.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El pixel art se ve borroso al ampliar | Filtro *Linear*; cámbialo a *Nearest* en el nodo o en Import y reimporta. |
| El sprite muestra toda la hoja, no una celda | No asignaste `region` al `AtlasTexture` o es demasiado grande; ajusta `Rect2`. |
| Halos oscuros en los bordes transparentes | Alfa sin premultiplicar o mezcla incorrecta; exporta con alfa correcto. |
| El JPG perdió la transparencia | JPG no soporta canal alfa; usa PNG o WebP. |
| La región recorta el sprite equivocado | Offset de celda mal calculado; usa múltiplos exactos del tamaño de celda. |
| Cambios de Import no se aplican | Olvidaste pulsar **Reimport** tras cambiar los ajustes. |

## ❓ Preguntas frecuentes

**❓ ¿Cuándo uso PNG y cuándo WebP?** PNG es sin pérdida y universal, ideal para sprites; WebP ofrece menor peso con o sin pérdida y soporta alfa, útil para reducir el tamaño de la build cuando el motor lo admite.

**❓ ¿Por qué el pixel art necesita filtro Nearest?** *Nearest* toma el color del texel más cercano sin interpolar, manteniendo bordes duros; *Linear* promedia y difumina, arruinando la estética de píxel.

**❓ ¿Sigue importando el power-of-two hoy?** Menos que antes en 2D, pero POT sigue favoreciendo mipmaps y ciertas compresiones de GPU, sobre todo en 3D.

**❓ ¿Qué ventaja tiene un atlas frente a muchos PNG sueltos?** Agrupa sprites en una textura, reduce draw calls y cambios de estado en la GPU, y simplifica la gestión de fotogramas.

## 🔗 Referencias

- Especificación PNG (W3C): <https://www.w3.org/TR/png/>
- WebP (Google Developers): <https://developers.google.com/speed/webp>
- Godot — Importing images: <https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html>
- Godot — AtlasTexture (clase): <https://docs.godotengine.org/en/stable/classes/class_atlastexture.html>
- Kenney — Assets libres: <https://kenney.nl/assets>

## ⬅️ Clase anterior

[Clase 018 - Sistemas de coordenadas y espacios: local, mundo, cámara, pantalla](../018-sistemas-de-coordenadas-y-espacios-local-mundo-camara-pantalla/README.md)

## ➡️ Siguiente clase

[Clase 020 - Audio digital: muestreo, formatos y mezcla](../020-audio-digital-muestreo-formatos-y-mezcla/README.md)
