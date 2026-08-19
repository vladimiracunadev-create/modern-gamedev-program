# Clase 330 — Pipeline técnico de assets asistido por IA

> Parte: **20 — IA generativa y desarrollo de juegos asistido por IA** · Fuente: *Documentación de importación de assets de Godot 4 · Prácticas de pipeline de contenido en producción*
> ⏱️ Duración estimada: **115 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir el **pipeline** por el que pasa un asset generado antes de llegar al repositorio: `generación → validación → optimización → nomenclatura → importación → revisión humana → repositorio`. Cada flecha es una puerta que puede rechazar el asset, y ese es el punto: sin pipeline, lo que ocurre es que alguien arrastra un PNG de 4096×4096 y 40 MB a `assets/` y nadie se entera hasta que la build pesa 3 GB.

La Parte 9 enseñó el pipeline de assets clásico. Esta clase lo adapta a un flujo donde el volumen de material candidato se multiplica: generar cien variantes de una textura es trivial, y por eso la parte cara deja de ser producir y pasa a ser **filtrar, normalizar y decidir**. El pipeline es lo que hace que ese cambio de escala no ahogue al equipo.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diseñar un pipeline de assets con puertas de validación explícitas.
2. Implementar validación técnica automática (formato, dimensiones, canal alfa, potencia de dos).
3. Implementar optimización y conversión al formato del motor.
4. Aplicar una convención de nomenclatura verificable automáticamente.
5. Integrar la procedencia de la clase 329 como paso obligatorio del pipeline.
6. Diseñar el paso de revisión humana para que sea rápido y decisorio.
7. Verificar el pipeline completo en CI, incluidos los presupuestos de tamaño.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | El pipeline como puertas | Cada paso puede rechazar; eso es lo que lo hace útil. |
| 2 | Zona de cuarentena | Lo generado no entra directamente al repositorio. |
| 3 | Validación técnica | Dimensiones, formato y canales: automatizable al 100 %. |
| 4 | Validación de contenido | Costuras, artefactos, texto espurio: parcialmente automatizable. |
| 5 | Optimización | Compresión y mipmaps: la diferencia entre 40 MB y 2 MB. |
| 6 | Nomenclatura | Un nombre correcto es metadato gratis. |
| 7 | Importación al motor | Ajustes correctos por tipo de asset. |
| 8 | Revisión humana | Rápida, con contexto y decisoria. |
| 9 | Procedencia obligatoria | Sin ella el asset no pasa. |
| 10 | Presupuestos | El pipeline es donde se aplican, no después. |

## 📖 Definiciones y características

- **Pipeline de assets**: secuencia de pasos por la que pasa un recurso desde su creación hasta la build. Clave: cada paso es una puerta con criterio.
- **Cuarentena**: carpeta donde llega lo generado, fuera del repositorio. Clave: impide que entre nada sin pasar el pipeline.
- **Validación técnica**: comprobaciones objetivas y automatizables. Clave: rechaza sin intervención humana y sin discusión.
- **Potencia de dos**: dimensiones tipo 512, 1024, 2048. Clave: requisito de compresión y mipmaps en muchas plataformas.
- **Canal alfa**: transparencia. Clave: un alfa innecesario multiplica el tamaño y el coste de render.
- **Mipmap**: cadena de versiones reducidas de una textura. Clave: mejora rendimiento y calidad a distancia.
- **Compresión de textura**: formato específico de GPU (BCn, ASTC, ETC). Clave: reduce memoria de vídeo, no solo disco.
- **Tileable (sin costura)**: textura que se repite sin junta visible. Clave: es el defecto más frecuente en texturas generadas.
- **Artefacto de generación**: ruido, texto ilegible, deformación característica. Clave: se detecta a ojo, y algunos con heurísticas.
- **Nomenclatura**: convención de nombres con significado. Clave: hace posible automatizar el resto del pipeline.
- **Ajustes de importación**: cómo el motor procesa el archivo (compresión, filtro, mipmaps). Clave: en Godot van en el `.import`.
- **Preset de importación**: conjunto de ajustes por tipo de asset. Clave: evita que cada archivo entre con configuración distinta.
- **Presupuesto de asset**: límite de tamaño o resolución por categoría. Clave: se aplica en el pipeline, no en la revisión final.
- **Atlas**: agrupación de varias imágenes en una textura. Clave: reduce draw calls; se genera en el pipeline.
- **Hoja de contactos (contact sheet)**: mosaico con las variantes generadas. Clave: hace la revisión humana rápida.

## 🧰 Herramientas y preparación

Python con [Pillow](https://pillow.readthedocs.io/) para la validación y optimización de imágenes, Godot 4.x para la importación, y el registro de procedencia de la [clase 329](../329-assets-generativos-y-provenance/README.md). Trabajaremos en `scripts/pipeline/` y en las carpetas `cuarentena/` (ignorada por git) y `assets/`. La [clase 186](../../parte-9-arte-animacion-y-pipeline-de-assets/186-pipeline-de-assets-nomenclatura-lods-y-optimizacion/README.md) de la Parte 9 estableció el pipeline clásico; esta clase lo extiende, no lo sustituye.

## 🧪 Laboratorio guiado

1. **El pipeline, con sus puertas:**

```text
cuarentena/          ← lo generado aterriza aquí (fuera de git)
    │
    ├─ 1. VALIDACIÓN TÉCNICA ──────► rechaza: formato, dimensiones, alfa, tamaño
    │        │                                                      ↓ RECHAZADO
    ├─ 2. VALIDACIÓN DE CONTENIDO ─► avisa: costura, artefactos, uniformidad
    │        │
    ├─ 3. OPTIMIZACIÓN ────────────► redimensiona, comprime, quita alfa inútil
    │        │
    ├─ 4. NOMENCLATURA ────────────► renombra según convención
    │        │
    ├─ 5. PROCEDENCIA ─────────────► exige la entrada en PROCEDENCIA.json
    │        │                                                      ↓ RECHAZADO
    ├─ 6. REVISIÓN HUMANA ─────────► hoja de contactos → aprobado / rechazado
    │        │                                                      ↓ RECHAZADO
    └─ 7. IMPORTACIÓN ─────────────► entra en assets/ con su preset
             │
          assets/    ← ya en el repositorio, con presupuestos comprobados
```

2. **La convención de nomenclatura.** Un nombre correcto es metadato gratis:

```text
{categoria}_{sujeto}_{variante}_{mapa}.{ext}

texturas:  tex_roca_musgo_01_albedo.png
           tex_roca_musgo_01_normal.png
           tex_roca_musgo_01_rough.png
sprites:   spr_enemigo_lobo_idle_01.png
iconos:    ico_item_pocion_menor.png
audio:     sfx_paso_hierba_01.wav
           mus_bosque_dia_loop.ogg
mallas:    msh_prop_barril_lod0.glb
```

```python
NOMBRE = re.compile(
    r"^(tex|spr|ico|sfx|mus|msh|vfx)_[a-z0-9]+(_[a-z0-9]+)*"
    r"(_(albedo|normal|rough|metal|ao|height|emission|lod[0-9]))?"
    r"\.(png|jpg|webp|wav|ogg|glb|gltf)$")

def valida_nombre(f):
    # Sin convención, no se puede automatizar nada: ni el preset de
    # importación, ni el atlas, ni el presupuesto por categoría.
    return bool(NOMBRE.match(f)) and f.lower() == f
```

3. **La validación técnica.** Objetiva, automatizable y sin discusión posible:

```python
#!/usr/bin/env python3
"""Puerta 1: validación técnica de imágenes en cuarentena."""
import os, sys
from PIL import Image

# Reglas POR CATEGORÍA. Un icono y una textura de terreno no tienen los mismos
# requisitos, y una regla única obligaría a poner el listón donde no sirve.
REGLAS = {
    "tex": {"max_lado": 2048, "potencia_dos": True,  "alfa_permitido": False,
            "max_mb": 12, "formatos": {"PNG", "WEBP"}},
    "spr": {"max_lado": 1024, "potencia_dos": False, "alfa_permitido": True,
            "max_mb": 4,  "formatos": {"PNG", "WEBP"}},
    "ico": {"max_lado": 256,  "potencia_dos": True,  "alfa_permitido": True,
            "max_mb": 1,  "formatos": {"PNG"}},
}

def es_potencia_de_dos(n):
    return n > 0 and (n & (n - 1)) == 0

def validar(ruta):
    fallos = []
    nombre = os.path.basename(ruta)
    categoria = nombre.split("_", 1)[0]
    if categoria not in REGLAS:
        return [f"{nombre}: categoría desconocida '{categoria}'"]
    r = REGLAS[categoria]

    mb = os.path.getsize(ruta) / 1048576
    if mb > r["max_mb"]:
        fallos.append(f"{nombre}: {mb:.1f} MB supera el máximo {r['max_mb']} MB")

    with Image.open(ruta) as img:
        if img.format not in r["formatos"]:
            fallos.append(f"{nombre}: formato {img.format} no permitido")
        w, h = img.size
        if max(w, h) > r["max_lado"]:
            fallos.append(f"{nombre}: {w}x{h} supera el lado máximo {r['max_lado']}")
        if r["potencia_dos"] and not (es_potencia_de_dos(w) and es_potencia_de_dos(h)):
            fallos.append(f"{nombre}: {w}x{h} no es potencia de dos")
        tiene_alfa = img.mode in ("RGBA", "LA") or "transparency" in img.info
        if tiene_alfa and not r["alfa_permitido"]:
            # Un alfa que no se usa cuesta un 33 % más de memoria de vídeo
            # y desactiva algunas compresiones. No es un detalle.
            if _alfa_es_opaco(img):
                fallos.append(f"{nombre}: canal alfa completamente opaco (sobra)")
            else:
                fallos.append(f"{nombre}: la categoría '{categoria}' no admite alfa")
    return fallos

def _alfa_es_opaco(img):
    if img.mode != "RGBA":
        return False
    alfa = img.getchannel("A")
    return alfa.getextrema() == (255, 255)
```

4. **La validación de contenido.** Parcialmente automatizable, y lo que se puede automatizar merece la pena:

```python
def costura_horizontal(img, umbral=18.0):
    """Detecta si una textura NO es tileable comparando el borde izquierdo con
    el derecho. Es el defecto nº 1 de las texturas generadas y se detecta con
    una resta: no hace falta mirarla."""
    import numpy as np
    a = np.asarray(img.convert("RGB"), dtype=float)
    izq, der = a[:, 0, :], a[:, -1, :]
    # En una textura tileable, el borde izquierdo y el derecho son casi
    # continuos; si difieren mucho, se verá una junta al repetirla.
    return float(np.abs(izq - der).mean()) > umbral

def demasiado_uniforme(img, umbral=4.0):
    """Una salida casi plana suele ser un fallo de generación."""
    import numpy as np
    return float(np.asarray(img.convert("L"), dtype=float).std()) < umbral

def posible_texto(img):
    """Heurística barata: los artefactos de texto generan muchos bordes finos
    y de alto contraste en zonas pequeñas. Es un AVISO, no un rechazo: quien
    decide es la revisión humana."""
    from PIL import ImageFilter
    import numpy as np
    bordes = np.asarray(img.convert("L").filter(ImageFilter.FIND_EDGES), dtype=float)
    return float((bordes > 128).mean()) > 0.12
```

5. **La optimización.** Donde se recupera la mayor parte del tamaño:

```python
def optimizar(ruta_origen, ruta_destino, categoria):
    """Puerta 3: normaliza y reduce sin tocar la percepción."""
    with Image.open(ruta_origen) as img:
        r = REGLAS[categoria]

        # 1) Quitar el alfa si es completamente opaco.
        if img.mode == "RGBA" and _alfa_es_opaco(img):
            img = img.convert("RGB")

        # 2) Redimensionar al máximo permitido, con LANCZOS.
        if max(img.size) > r["max_lado"]:
            escala = r["max_lado"] / max(img.size)
            img = img.resize((int(img.width * escala), int(img.height * escala)),
                             Image.LANCZOS)

        # 3) Ajustar a potencia de dos si la categoría lo exige.
        if r["potencia_dos"]:
            img = img.resize((_pot2(img.width), _pot2(img.height)), Image.LANCZOS)

        # 4) Guardar optimizado y sin metadatos EXIF (que a veces traen rutas
        #    con el nombre del usuario: ver clase 317).
        limpia = Image.new(img.mode, img.size)
        limpia.putdata(list(img.getdata()))
        limpia.save(ruta_destino, optimize=True, compress_level=9)

    ahorro = 1 - os.path.getsize(ruta_destino) / os.path.getsize(ruta_origen)
    return {"ahorro": ahorro, "bytes": os.path.getsize(ruta_destino)}

def _pot2(n):
    p = 1
    while p * 2 <= n:
        p *= 2
    return p
```

6. **La hoja de contactos.** Lo que hace la revisión humana rápida:

```python
def hoja_de_contactos(rutas, destino, columnas=5, celda=256):
    """Un mosaico con todas las variantes y su nombre. Revisar 40 texturas en
    una imagen es un minuto; abrirlas de una en una, media hora."""
    from PIL import ImageDraw
    filas = (len(rutas) + columnas - 1) // columnas
    hoja = Image.new("RGB", (columnas * celda, filas * (celda + 20)), (24, 24, 28))
    dib = ImageDraw.Draw(hoja)
    for i, ruta in enumerate(rutas):
        with Image.open(ruta) as img:
            mini = img.convert("RGB").resize((celda, celda), Image.LANCZOS)
        x, y = (i % columnas) * celda, (i // columnas) * (celda + 20)
        hoja.paste(mini, (x, y))
        dib.text((x + 4, y + celda + 4), os.path.basename(ruta)[:34], fill=(200, 200, 210))
    hoja.save(destino)
    return destino
```

7. **La importación al motor.** Presets por categoría, no ajustes a mano:

```python
PRESETS_IMPORT = {
    "tex": {
        "compress/mode": 2,              # VRAM comprimida
        "compress/high_quality": False,
        "mipmaps/generate": True,
        "detect_3d/compress_to": 0,
    },
    "spr": {
        "compress/mode": 0,              # sin pérdida: los sprites la notan
        "mipmaps/generate": False,
        "process/fix_alpha_border": True,
    },
    "ico": {
        "compress/mode": 0,
        "mipmaps/generate": False,
    },
}

def escribir_import(ruta_asset, categoria):
    """Genera el .import con el preset de la categoría. Sin esto, cada asset
    entra con lo que Godot adivine y el resultado es inconsistente."""
    ...
```

8. **El pipeline completo, en un comando:**

```python
#!/usr/bin/env python3
"""Procesa la cuarentena y deja en assets/ lo que pase todas las puertas."""
def main():
    entradas = sorted(glob.glob("cuarentena/**/*", recursive=True))
    aceptados, rechazados, avisos = [], [], []

    for ruta in entradas:
        if not os.path.isfile(ruta):
            continue
        nombre = os.path.basename(ruta)

        if not valida_nombre(nombre):
            rechazados.append((nombre, "nomenclatura")); continue
        fallos = validar(ruta)
        if fallos:
            rechazados.append((nombre, "; ".join(fallos))); continue

        categoria = nombre.split("_", 1)[0]
        with Image.open(ruta) as img:
            if categoria == "tex" and costura_horizontal(img):
                avisos.append((nombre, "posible costura: no parece tileable"))
            if demasiado_uniforme(img):
                rechazados.append((nombre, "imagen casi plana")); continue
            if posible_texto(img):
                avisos.append((nombre, "posible texto o artefacto: revisar"))

        # La procedencia NO es opcional: sin ella el asset no entra.
        if not tiene_procedencia(nombre):
            rechazados.append((nombre, "sin entrada en PROCEDENCIA.json")); continue

        destino = os.path.join("assets", carpeta_de(categoria), nombre)
        stats = optimizar(ruta, destino, categoria)
        escribir_import(destino, categoria)
        aceptados.append((nombre, stats))

    hoja_de_contactos([os.path.join("assets", carpeta_de(n.split("_")[0]), n)
                       for n, _ in aceptados], "cuarentena/_revision.png")

    print(f"== {len(aceptados)} aceptado(s), {len(rechazados)} rechazado(s), "
          f"{len(avisos)} aviso(s) ==")
    for n, m in rechazados: print(f"  RECHAZADO  {n}: {m}")
    for n, m in avisos:     print(f"  AVISO      {n}: {m}")
    ahorro = sum(s["ahorro"] for _, s in aceptados) / max(len(aceptados), 1)
    print(f"  ahorro medio de tamaño: {ahorro * 100:.0f}%")
    print("  hoja de contactos para revisión: cuarentena/_revision.png")
    return 0
```

## ✍️ Ejercicios

1. Define las reglas técnicas por categoría de tu proyecto y justifica cada límite.
2. Implementa el detector de costuras y pásalo por tus texturas actuales.
3. Mide el ahorro de tamaño de la optimización sobre 20 assets reales.
4. Genera la hoja de contactos de un lote y cronometra la revisión frente a abrirlos uno a uno.
5. Añade una categoría de audio con sus reglas (duración, canales, frecuencia de muestreo).
6. Integra el pipeline en la CI para que rechace cualquier asset que no cumpla.
7. Añade generación automática de atlas para los sprites que compartan categoría.

## 📝 Reto verificable

Implementa el pipeline completo con **al menos tres categorías** de asset, sus reglas técnicas, validación de contenido con al menos dos heurísticas, optimización con medición de ahorro, nomenclatura verificable, procedencia obligatoria, hoja de contactos e importación con presets.

**Criterio de aceptación**: (a) `python scripts/pipeline/procesar.py` procesa la cuarentena e imprime `== N aceptado(s), M rechazado(s), K aviso(s) ==`; (b) rechaza, indicando el motivo, un asset con nombre incorrecto, uno que supera el tamaño máximo, uno que no es potencia de dos en una categoría que lo exige, uno con alfa completamente opaco y uno sin procedencia; (c) avisa (sin rechazar) de una textura con costura detectable y de una con posible texto; (d) la optimización reduce el tamaño medio **al menos un 30 %** sobre un lote de prueba, sin cambiar las dimensiones finales esperadas; (e) genera la hoja de contactos con todos los aceptados y su nombre legible; (f) los assets aceptados llegan a `assets/` con su `.import` generado según el preset de su categoría; (g) el pipeline está integrado en CI y falla si algún asset de `assets/` no cumple sus reglas.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La build crece 500 MB de golpe | Assets sin pasar por el pipeline. Cuarentena obligatoria y CI que lo verifique. |
| Las texturas se ven con una junta al repetirse | No son tileables. Detector de costura en el pipeline. |
| Una textura ocupa el triple de lo necesario en VRAM | Canal alfa opaco. Detección y eliminación automática. |
| Cada asset tiene ajustes de importación distintos | Se configuró a mano. Presets por categoría. |
| No se puede automatizar nada del pipeline | Nombres inconsistentes. La convención es el prerrequisito. |
| Revisar un lote de 40 variantes lleva media hora | Se abren de una en una. Hoja de contactos. |
| Entró un asset con texto ilegible generado | No hubo revisión humana. Es una puerta obligatoria. |
| El pipeline rechaza assets legítimos | Reglas demasiado estrictas o categoría mal elegida. Ajusta por categoría, no globalmente. |
| Los metadatos EXIF llevan la ruta del usuario | No se limpiaron al guardar. Reescribe la imagen sin metadatos. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué una cuarentena y no generar directamente en `assets/`?** Porque el pipeline debe poder **rechazar**, y no se puede rechazar algo que ya está en el repositorio. La cuarentena está fuera de git precisamente para que su contenido no sea todavía parte del proyecto.

**❓ ¿Merece la pena si genero pocos assets?** La validación técnica y la optimización sí, siempre: detectan el alfa inútil y el PNG de 40 MB, que aparecen igual con assets hechos a mano. La hoja de contactos y las heurísticas de contenido rinden a partir de lotes de diez o más.

**❓ ¿Se puede automatizar la validación de calidad artística?** Las heurísticas detectan defectos **técnicos** (costura, uniformidad, artefactos de alto contraste) y ahorran mucho tiempo. Si encaja con la dirección de arte, si el nivel de detalle es el correcto, si transmite lo que debe: eso lo decide una persona, y por eso la revisión humana es una puerta y no un trámite.

**❓ ¿Y para audio y 3D?** El mismo esquema con otras reglas: para audio, duración, canales, frecuencia, normalización y detección de silencio o clipping; para mallas, número de triángulos, escala, orientación, UVs y LODs. La estructura de puertas es idéntica.

**❓ ¿Esto no ralentiza al equipo de arte?** Bien hecho, lo contrario: el pipeline hace el trabajo aburrido (redimensionar, comprimir, renombrar, configurar la importación) y deja a las personas la decisión. Lo que sí es cierto es que **hay que integrarlo con ellas**, no imponérselo: si rechaza cosas legítimas, se acabará esquivando.

## 🔗 Referencias

- Godot Docs — Importar imágenes y ajustes de importación: <https://docs.godotengine.org/en/4.3/tutorials/assets_pipeline/importing_images.html> · uso: respalda el Tema 1 «El pipeline como puertas»
- Godot Docs — Best practices de importación de assets: <https://docs.godotengine.org/en/4.3/tutorials/assets_pipeline/index.html> · uso: respalda el Tema 1 «El pipeline como puertas»
- Pillow — documentación de la biblioteca de imagen: <https://pillow.readthedocs.io/> · uso: se instala o se consulta en la preparación
- Khronos — glTF, formato estándar de intercambio 3D: <https://www.khronos.org/gltf/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- C2PA — procedencia de contenido (integración con el paso 5): <https://c2pa.org/> · uso: respalda el Tema 4 «Validación de contenido»

## ⬅️ Clase anterior

[Clase 329 - Assets generativos y provenance](../329-assets-generativos-y-provenance/README.md)

## ➡️ Siguiente clase

[Clase 331 - NPC controlados por LLM](../331-npc-controlados-por-llm/README.md)
