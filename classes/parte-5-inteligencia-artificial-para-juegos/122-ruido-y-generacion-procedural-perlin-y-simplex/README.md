# Clase 122 — Ruido y generación procedural (Perlin y Simplex)

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Documentación de Godot 4 (FastNoiseLite, TileMapLayer) + Ken Perlin "Improving Noise"*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Entender el **ruido coherente** (Perlin y Simplex) frente al ruido aleatorio, y usarlo para **generar contenido procedural reproducible**. Al terminar habrás generado un **mapa de alturas (heightmap)** con `FastNoiseLite`, aplicado **octavas/fractal (FBM)** para dar detalle, y **pintado un `TileMapLayer`** con biomas (agua, arena, hierba, roca) según umbrales, con una **semilla** que hace el resultado repetible.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Distinguir ruido **aleatorio** de ruido **coherente** y explicar por qué el segundo sirve para terreno.
- Configurar `FastNoiseLite`: `noise_type`, `seed`, `frequency` y `fractal_octaves`.
- Muestrear ruido 2D con `get_noise_2d(x, y)` y entender su rango aproximado [-1, 1].
- Traducir valores de ruido a **biomas** mediante umbrales.
- Garantizar **reproducibilidad** fijando la semilla y usando `RandomNumberGenerator` con `seed`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Aleatorio vs coherente | El terreno necesita continuidad, no ruido blanco |
| 2 | Perlin y Simplex | Son los generadores base de casi todo lo procedural |
| 3 | Frecuencia | Controla el "zoom": islas grandes o detalle fino |
| 4 | Octavas y FBM | Suman capas para dar riqueza natural |
| 5 | Semillas | Hacen el mundo reproducible y compartible |
| 6 | Heightmap | Una rejilla de alturas es la base del terreno |
| 7 | Umbrales y biomas | Convierten un número en agua, arena o roca |
| 8 | TileMapLayer | Pinta el resultado de forma visible y eficiente |

## 📖 Definiciones y características

- **Ruido aleatorio (blanco)**: valores independientes sin relación entre vecinos. Clave: se ve como estática, inútil para terreno.
- **Ruido coherente**: valores suaves donde puntos cercanos dan resultados parecidos. Clave: produce colinas y valles creíbles.
- **Perlin**: ruido de gradiente clásico de Ken Perlin. Clave: suave y barato, base histórica del procedural.
- **Simplex**: evolución de Perlin con menos artefactos direccionales. Clave: escala mejor a más dimensiones.
- **Frecuencia**: cuánto varía el ruido por unidad de distancia. Clave: baja = formas grandes, alta = detalle fino.
- **Octavas (FBM)**: suma de capas de ruido a distintas frecuencias. Clave: `fractal_octaves` añade detalle multiescala.
- **Semilla (`seed`)**: entero que determina el patrón. Clave: misma semilla → mismo mundo.
- **Umbral**: corte que clasifica el valor en categorías. Clave: define dónde empieza el agua o la roca.

## 🧰 Herramientas y preparación

Con Godot 4.x usaremos el recurso **`FastNoiseLite`**, que ofrece Perlin, Simplex, Value y celular en una sola clase. Para pintar necesitamos un **`TileMapLayer`** (nodo de Godot 4.3+ que reemplaza al antiguo `TileMap`) con un `TileSet` que tenga cuatro tiles (agua, arena, hierba, roca) en la *source* 0. Para muestreos aleatorios controlados usaremos `RandomNumberGenerator` con `seed`. Consulta la clase [FastNoiseLite](https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html) y [TileMapLayer](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html).

## 🧪 Laboratorio guiado

Vamos a generar un mundo de 64×64 celdas: calcularemos una altura por celda con ruido fractal y pintaremos el bioma correspondiente. Cambiar la semilla dará un mundo distinto pero **repetible**.

**Paso 1 — Configurar el ruido.** En un script sobre un nodo con un hijo `TileMapLayer` llamado `Mapa`:

```gdscript
extends Node2D

@export var ancho: int = 64
@export var alto: int = 64
@export var semilla: int = 1337

var _ruido := FastNoiseLite.new()

func _ready() -> void:
    _configurar_ruido()
    _generar()

func _configurar_ruido() -> void:
    _ruido.noise_type = FastNoiseLite.TYPE_PERLIN
    _ruido.seed = semilla
    _ruido.frequency = 0.03          # formas medianas
    _ruido.fractal_octaves = 4       # detalle multiescala (FBM)
    _ruido.fractal_lacunarity = 2.0
    _ruido.fractal_gain = 0.5
```

**Paso 2 — Muestrear el heightmap.** `get_noise_2d` devuelve aproximadamente [-1, 1]; lo normalizamos a [0, 1] para razonar con umbrales:

```gdscript
func _altura(x: int, y: int) -> float:
    var n := _ruido.get_noise_2d(float(x), float(y))  # ~[-1, 1]
    return (n + 1.0) * 0.5                             # -> [0, 1]
```

**Paso 3 — Traducir altura a bioma.** Definimos umbrales y devolvemos el índice de tile en el atlas (source 0):

```gdscript
# Coordenadas del atlas en el TileSet (ajústalas a tu recurso).
const AGUA   := Vector2i(0, 0)
const ARENA  := Vector2i(1, 0)
const HIERBA := Vector2i(2, 0)
const ROCA   := Vector2i(3, 0)

func _bioma(h: float) -> Vector2i:
    if h < 0.35:
        return AGUA
    elif h < 0.45:
        return ARENA
    elif h < 0.75:
        return HIERBA
    else:
        return ROCA
```

**Paso 4 — Pintar el TileMapLayer.** Recorremos la rejilla y colocamos cada celda con `set_cell`:

```gdscript
func _generar() -> void:
    $Mapa.clear()
    for y in alto:
        for x in ancho:
            var h := _altura(x, y)
            var atlas := _bioma(h)
            # set_cell(coords, source_id, atlas_coords)
            $Mapa.set_cell(Vector2i(x, y), 0, atlas)
    print("Mundo generado con semilla ", semilla)
```

**Paso 5 — Regenerar con semillas nuevas.** Añadimos control para variar el mundo de forma reproducible con `RandomNumberGenerator`:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):   # Espacio = nuevo mundo
        var rng := RandomNumberGenerator.new()
        rng.randomize()
        semilla = rng.randi()
        _ruido.seed = semilla
        _generar()
```

**Resultado observable:** al ejecutar verás un mapa con lagos azules, playas de arena, praderas verdes y picos de roca formando continentes coherentes. Al pulsar Espacio se genera un mundo distinto; si vuelves a fijar la misma `semilla` obtienes exactamente el mismo mapa.

## ✍️ Ejercicios

1. Cambia `noise_type` a `FastNoiseLite.TYPE_SIMPLEX` y compara la forma de las costas con Perlin.
2. Sube `frequency` a `0.1` y baja a `0.01`; describe cómo cambia el tamaño de los continentes.
3. Añade un quinto bioma "nieve" para alturas superiores a 0.9.
4. Usa un **segundo** `FastNoiseLite` de baja frecuencia como mapa de "humedad" y combina altura+humedad para decidir el bioma.
5. Prueba `fractal_octaves = 1` frente a `6` y anota el efecto en el detalle y el coste.
6. Muestra en pantalla la semilla actual en un `Label` para poder anotar mundos que te gusten.

## 📝 Reto verificable

Genera un mundo de islas: aplica una **máscara radial** que reste altura según la distancia al centro, de modo que los bordes del mapa sean siempre agua. Expón la semilla por `@export` y añade un botón/tecla que la copie para reproducir el mundo.

**Criterio de aceptación**: con la misma semilla, dos ejecuciones producen **exactamente** el mismo mapa; los bordes del mapa son agua en todos los casos; el centro contiene tierra generada con ruido fractal de al menos 3 octavas.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El mapa se ve como estática | Frecuencia altísima o usaste ruido blanco; baja `frequency` y usa Perlin/Simplex |
| El mundo cambia cada ejecución | No fijaste `seed`; asígnalo antes de muestrear |
| Todas las celdas del mismo bioma | Umbrales mal calibrados o no normalizaste a [0, 1]; revisa `_altura` |
| `set_cell` no pinta nada | `source_id` incorrecto o coords de atlas fuera del TileSet; verifica el recurso |
| El detalle no aparece | `fractal_octaves = 1`; súbelo para activar el FBM |
| Rendimiento lento en mapas grandes | Regeneras cada frame; genera una sola vez y solo al cambiar la semilla |

## ❓ Preguntas frecuentes

**¿Perlin o Simplex?**
Ambos sirven. Simplex tiene menos artefactos direccionales y escala mejor a 3D; Perlin es el clásico y suele bastar para 2D. Prueba los dos y elige por resultado visual.

**¿Qué rango devuelve `get_noise_2d`?**
Aproximadamente [-1, 1], pero rara vez toca los extremos. Normaliza a [0, 1] si vas a comparar con umbrales entre 0 y 1.

**¿Por qué mi mundo no es reproducible?**
Casi siempre porque algo usa aleatoriedad sin semilla. Fija `FastNoiseLite.seed` y usa `RandomNumberGenerator` con `seed` explícito para todo lo demás.

**¿Cómo hago que el mundo tenga ríos o cuevas?**
Combina varios ruidos (altura, humedad, temperatura) y añade ruido celular para cuevas. La composición de capas es la clave del procedural rico.

## 🔗 Referencias

- [Clase FastNoiseLite — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html)
- [Clase TileMapLayer — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html)
- [Clase RandomNumberGenerator — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html)
- [Ken Perlin — Improving Noise (SIGGRAPH 2002)](https://mrl.cs.nyu.edu/~perlin/paper445.pdf)

## ➡️ Siguiente clase

[Clase 123 - Generación procedural de niveles](../123-generacion-procedural-de-niveles/README.md)
