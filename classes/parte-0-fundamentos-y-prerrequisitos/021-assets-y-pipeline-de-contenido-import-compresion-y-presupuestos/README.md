# Clase 021 — Assets y pipeline de contenido: import, compresión y presupuestos

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Jason Gregory, Game Engine Architecture (asset pipeline)*
> ⏱️ Duración estimada: **95 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Un juego no es solo código: son cientos o miles de **assets** (imágenes, sonidos, fuentes, modelos) que deben viajar desde la herramienta de creación hasta la memoria de la máquina que ejecuta el juego. Ese viaje —el **pipeline de contenido**— transforma un formato de autoría (un `.png` exportado de Aseprite, un `.wav` grabado) en un formato optimizado que el motor puede cargar rápido y sin desperdiciar memoria.

En esta clase entenderás qué ocurre cuando importas un asset, por qué la **compresión de texturas** afecta de forma distinta a la VRAM y al disco, y cómo definir **presupuestos** simples de memoria y tamaño para que el proyecto no se descontrole. En el laboratorio organizarás una estructura de carpetas real en Godot, importarás varios assets, observarás los archivos derivados `.import` y medirás su peso.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Definir qué es un asset y describir las etapas del pipeline de importación (fuente → formato de motor).
2. Explicar la diferencia entre el tamaño en disco y el consumo en VRAM de una textura.
3. Organizar una estructura de carpetas coherente para sprites, audio y fuentes.
4. Identificar los archivos derivados (`.import`) de Godot y cuándo se regeneran (reimport).
5. Elaborar una tabla de presupuesto de tamaños para un conjunto de assets.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es un asset | Todo el contenido no-código del juego. |
| 2 | Pipeline de importación | Convierte formatos de autoría en formatos de motor. |
| 3 | Compresión de texturas | Reduce VRAM/disco a cambio de calidad o CPU. |
| 4 | VRAM vs disco | Un PNG pequeño puede ocupar mucho en memoria. |
| 5 | Presupuestos | Evitan que el juego no quepa o vaya lento. |
| 6 | Nomenclatura y carpetas | Encontrar y mantener miles de archivos. |
| 7 | Reimport y derivados | Godot regenera `.import` al cambiar ajustes. |

## 📖 Definiciones y características

- **Asset**: cualquier recurso de contenido (textura, sonido, fuente, malla, animación). Clave: se crea fuera del motor y se importa.
- **Formato de autoría**: el formato original editable (`.png`, `.wav`, `.aseprite`). Clave: cómodo para crear, no óptimo para ejecutar.
- **Formato de motor**: la versión optimizada que carga el juego. Clave: la genera la importación.
- **Reimport**: reprocesar un asset cuando cambia el archivo o sus ajustes. Clave: regenera los derivados.
- **Archivo `.import`**: metadato de Godot con los ajustes de importación de cada asset. Clave: se versiona, no se borra.
- **VRAM**: memoria de la GPU donde viven las texturas listas para dibujar. Clave: su tamaño no equivale al del PNG en disco.
- **Compresión con pérdida**: reduce tamaño descartando detalle (JPEG, VRAM comprimida). Clave: irreversible, cuidado con el arte nítido.
- **Presupuesto (budget)**: límite acordado de memoria o tamaño por categoría. Clave: se decide temprano y se vigila.

## 🧰 Herramientas y preparación

Usarás **Godot 4** (<https://godotengine.org/download>), que trae un importador integrado y visible en el panel *Importación*. Ten a mano un puñado de assets de prueba: dos o tres imágenes `.png` (por ejemplo un sprite de 32×32 y un fondo grande), un sonido corto `.wav` u `.ogg` y una fuente `.ttf` libre (por ejemplo de <https://fonts.google.com>). Para inspeccionar tamaños te basta el explorador de archivos del sistema o la terminal. La referencia conceptual es *Game Engine Architecture* de Jason Gregory (capítulo sobre el asset conditioning pipeline) y la documentación de importación de Godot: <https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/import_process.html>.

## 🧪 Laboratorio guiado

### Paso 1 — Crear una estructura de carpetas clara

Dentro de un proyecto Godot nuevo, crea desde el panel *Sistema de archivos* (o por terminal) esta jerarquía bajo `res://`:

```bash
mkdir -p assets/sprites assets/audio assets/fonts
```

La regla es una carpeta por tipo de contenido, en minúsculas y sin espacios. Una nomenclatura consistente (`player_idle.png`, `enemy_hit.wav`) evita colisiones y facilita las búsquedas cuando haya cientos de archivos.

### Paso 2 — Importar varios assets

Copia tus archivos de prueba a las carpetas correspondientes (`assets/sprites/`, `assets/audio/`, `assets/fonts/`) usando el explorador del sistema. Al volver a Godot, el editor detecta los archivos nuevos y los **importa automáticamente**, generando un archivo `.import` junto a cada uno. Selecciona una textura y abre la pestaña *Importación* (arriba a la derecha): verás opciones como *Compress > Mode*.

### Paso 3 — Observar los archivos derivados `.import`

Activa la vista de archivos ocultos en tu explorador o revisa la carpeta con la terminal:

```bash
ls -la assets/sprites/
# player_idle.png
# player_idle.png.import   <- derivado generado por Godot
```

Abre `player_idle.png.import` con un editor de texto: es un archivo legible que guarda los ajustes de importación. **No se borra ni se edita a mano**; se versiona en Git junto al asset para que el equipo comparta la misma configuración.

### Paso 4 — Provocar un reimport y ver el efecto

En la pestaña *Importación* de una textura grande, cambia *Compress > Mode* de `Lossless` a `VRAM Compressed` y pulsa **Reimportar**. Godot reprocesa el asset: el `.import` cambia y la representación interna se actualiza. La compresión VRAM reduce el consumo de memoria de la GPU a cambio de algo de calidad; es ideal para fondos, mala idea para pixel art nítido.

### Paso 5 — Medir tamaños y definir un presupuesto

Anota el tamaño en disco de cada archivo fuente y estima su coste en VRAM. Una textura RGBA sin comprimir ocupa `ancho × alto × 4 bytes` en memoria, independientemente de lo que pese el PNG:

```bash
du -h assets/sprites/*.png assets/audio/* assets/fonts/*
```

Con esos datos, completa una tabla de presupuesto sencilla:

| Categoría | Presupuesto objetivo | Uso actual | Notas |
|-----------|----------------------|-----------|-------|
| Sprites | ≤ 8 MB VRAM | 3.2 MB | Comprimir fondos |
| Audio | ≤ 5 MB disco | 1.1 MB | `.ogg` para música |
| Fuentes | ≤ 1 MB disco | 0.3 MB | Una sola familia |

Un fondo de 2048×2048 RGBA ocupa `2048 × 2048 × 4 = 16 MB` en VRAM aunque el PNG pese 400 KB: por eso el presupuesto se razona en memoria, no solo en disco.

## ✍️ Ejercicios

1. Calcula la VRAM de una textura RGBA de 1024×1024 y compárala con el peso de su `.png`.
2. Importa la misma imagen en modo `Lossless` y `VRAM Compressed` y describe la diferencia visual.
3. Renombra tres assets siguiendo una convención `categoria_nombre_estado` y justifícala.
4. Añade una carpeta `assets/shaders/` a la estructura y explica qué contendría.
5. Amplía la tabla de presupuesto con una fila para "música" separada de "efectos".
6. Abre un archivo `.import` y explica dos de los campos que contiene.

## 📝 Reto verificable

Organiza un mini-proyecto en Godot con la estructura `assets/sprites`, `assets/audio` y `assets/fonts`, importa al menos cinco assets reales (imágenes, un sonido y una fuente), aplica compresión VRAM a las texturas grandes y elabora una tabla de presupuesto con columnas *categoría*, *presupuesto objetivo*, *uso actual* y *notas*.

**Criterio de aceptación**: cada asset importado tiene su archivo `.import` correspondiente; al menos una textura usa `VRAM Compressed`; y la tabla de presupuesto muestra para cada categoría un objetivo numérico y el uso medido en disco o VRAM, con el uso por debajo del objetivo.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| El PNG pesa poco pero el juego consume mucha VRAM | La textura se descomprime en memoria (`ancho×alto×4`). Usa `VRAM Compressed` en fondos grandes. |
| Pixel art se ve borroso tras importar | Se aplicó filtrado o compresión con pérdida. Desactiva el filtro y usa `Lossless`. |
| Borraste un `.import` y el asset dejó de cargar | Ese derivado guarda los ajustes. Deja que Godot lo regenere al reimportar. |
| Archivos duplicados con nombres como `sprite (1).png` | Falta convención de nombres. Renombra con un esquema consistente sin espacios. |
| Cambios de compresión no se aplican | Olvidaste pulsar *Reimportar* tras cambiar los ajustes. Reimporta el asset. |

## ❓ Preguntas frecuentes

**❓ ¿Debo versionar los archivos `.import` en Git?** Sí. Guardan cómo se importa cada asset y aseguran que todo el equipo obtenga el mismo resultado. Lo que no se versiona es la carpeta de caché `.godot/`, que se regenera.

**❓ ¿Por qué un PNG pequeño puede ocupar mucha memoria?** Porque en disco está comprimido, pero la GPU necesita los píxeles descomprimidos. Una textura RGBA ocupa cuatro bytes por píxel en VRAM sin importar cuánto pese el archivo.

**❓ ¿Cuándo conviene compresión con pérdida?** En fondos, fotos y arte de tono suave, donde una ligera pérdida no se nota. Evítala en pixel art, interfaces y texto, donde los bordes nítidos son parte del diseño.

**❓ ¿Para qué sirve un presupuesto de assets tan temprano?** Para tomar decisiones antes de acumular problemas. Saber que dispones de, por ejemplo, 8 MB de VRAM para sprites guía qué resolución y compresión elegir desde el principio.

## 🔗 Referencias

- Jason Gregory, *Game Engine Architecture*, "The Asset Conditioning Pipeline": <https://www.gameenginebook.com/>
- Godot Docs, "Import process": <https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/import_process.html>
- Godot Docs, "Importing images": <https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html>
- Godot Docs, "Importing audio samples": <https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html>

## ⬅️ Clase anterior

[Clase 020 - Audio digital: muestreo, formatos y mezcla](../020-audio-digital-muestreo-formatos-y-mezcla/README.md)

## ➡️ Siguiente clase

[Clase 022 - Delta time, fixed timestep y determinismo](../022-delta-time-fixed-timestep-y-determinismo/README.md)
