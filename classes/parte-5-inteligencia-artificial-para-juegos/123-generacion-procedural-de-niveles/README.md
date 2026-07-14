# Clase 123 — Generación procedural de niveles

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Documentación de Godot 4 (TileMapLayer) + "Procedural Content Generation in Games" (Shaker, Togelius, Nelson)*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Generar **niveles jugables por código**: mazmorras con **salas y pasillos** y cuevas con **autómatas celulares**, garantizando **conectividad** y **reproducibilidad**. Al terminar habrás generado una mazmorra sobre un `TileMapLayer` colocando salas sin solapamiento, conectándolas con pasillos, y sabrás alternar a un generador de cuevas con autómata celular, todo controlado por una **semilla**.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Comparar enfoques de generación de niveles: **colocación de salas**, **BSP**, **drunkard walk** y **autómatas celulares**.
- Colocar salas sin solapamiento y conectarlas con pasillos en L.
- Garantizar **conectividad** entre todas las salas del nivel.
- Implementar un autómata celular para esculpir cuevas orgánicas.
- Sembrar la generación con `RandomNumberGenerator` para resultados repetibles.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Salas + pasillos | Enfoque directo y controlable para mazmorras |
| 2 | BSP | Divide el espacio para repartir salas ordenadamente |
| 3 | Drunkard walk | Cava túneles orgánicos con un "caminante" |
| 4 | Autómatas celulares | Generan cuevas naturales por reglas locales |
| 5 | Conectividad garantizada | Un nivel sin conexión es injugable |
| 6 | Rejilla lógica vs tiles | Separa los datos del dibujo |
| 7 | Semilla reproducible | Permite depurar y compartir niveles |
| 8 | Post-proceso | Rellenar huecos y colocar entrada/salida |

## 📖 Definiciones y características

- **Colocación de salas**: crear rectángulos y unirlos con pasillos. Clave: simple, legible y fácil de ajustar.
- **BSP (partición binaria del espacio)**: dividir recursivamente el mapa en zonas. Clave: reparte salas sin solapes de forma natural.
- **Drunkard walk**: un agente que avanza al azar excavando. Clave: produce cuevas y túneles conectados por construcción.
- **Autómata celular**: rejilla que evoluciona por reglas de vecindad. Clave: la regla "4-5" transforma ruido en cuevas.
- **Conectividad**: propiedad de que toda zona sea alcanzable. Clave: se asegura conectando cada sala a la anterior.
- **Rejilla lógica**: matriz de enteros (0=muro, 1=suelo). Clave: se genera y valida sin depender del render.
- **Semilla**: entero que fija la aleatoriedad. Clave: mismo `seed` → mismo nivel.
- **Post-proceso**: limpieza tras generar (bordes, entrada, salida). Clave: convierte el borrador en nivel jugable.

## 🧰 Herramientas y preparación

Con Godot 4.x trabajaremos sobre una **rejilla lógica** (`Array` de `Array` de `int`) y solo al final la volcaremos a un **`TileMapLayer`** con al menos dos tiles: muro y suelo. Toda la aleatoriedad pasará por un `RandomNumberGenerator` con `seed`, para poder reproducir cualquier nivel. Ten a mano la clase [TileMapLayer](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html) y la referencia de [RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html).

## 🧪 Laboratorio guiado

Vamos a generar una mazmorra: colocamos hasta N salas rectangulares que no se solapen y las unimos con pasillos, conectando cada nueva sala con la anterior para garantizar que todo sea alcanzable.

**Paso 1 — Rejilla y semilla.** En un nodo con hijo `TileMapLayer` llamado `Mapa`:

```gdscript
extends Node2D

const MURO := 0
const SUELO := 1

@export var ancho: int = 60
@export var alto: int = 40
@export var max_salas: int = 12
@export var sala_min: int = 5
@export var sala_max: int = 10
@export var semilla: int = 2024

var _rng := RandomNumberGenerator.new()
var _grid: Array = []
var _salas: Array[Rect2i] = []

func _ready() -> void:
    _rng.seed = semilla
    _generar_mazmorra()
    _pintar()
```

**Paso 2 — Inicializar todo como muro.** La rejilla arranca sólida y vamos "excavando":

```gdscript
func _init_grid() -> void:
    _grid.clear()
    for y in alto:
        var fila: Array = []
        for x in ancho:
            fila.append(MURO)
        _grid.append(fila)
```

**Paso 3 — Colocar salas sin solapamiento y conectarlas.** Cada sala válida se cava; la unimos a la anterior con un pasillo en L:

```gdscript
func _generar_mazmorra() -> void:
    _init_grid()
    _salas.clear()
    for i in max_salas:
        var w := _rng.randi_range(sala_min, sala_max)
        var h := _rng.randi_range(sala_min, sala_max)
        var x := _rng.randi_range(1, ancho - w - 1)
        var y := _rng.randi_range(1, alto - h - 1)
        var nueva := Rect2i(x, y, w, h)

        if _solapa(nueva):
            continue  # descartamos y probamos otra en la próxima vuelta
        _cavar_sala(nueva)
        if _salas.size() > 0:
            _conectar(_salas.back().get_center(), nueva.get_center())
        _salas.append(nueva)

func _solapa(r: Rect2i) -> bool:
    var margen := r.grow(1)   # 1 celda de separación entre salas
    for s in _salas:
        if margen.intersects(s):
            return true
    return false

func _cavar_sala(r: Rect2i) -> void:
    for y in range(r.position.y, r.end.y):
        for x in range(r.position.x, r.end.x):
            _grid[y][x] = SUELO
```

**Paso 4 — Pasillos en L (garantizan conexión).** Un tramo horizontal y otro vertical entre centros:

```gdscript
func _conectar(a: Vector2i, b: Vector2i) -> void:
    # Orden aleatorio para variar la forma de la L.
    if _rng.randf() < 0.5:
        _tunel_h(a.x, b.x, a.y)
        _tunel_v(a.y, b.y, b.x)
    else:
        _tunel_v(a.y, b.y, a.x)
        _tunel_h(a.x, b.x, b.y)

func _tunel_h(x1: int, x2: int, y: int) -> void:
    for x in range(mini(x1, x2), maxi(x1, x2) + 1):
        _grid[y][x] = SUELO

func _tunel_v(y1: int, y2: int, x: int) -> void:
    for y in range(mini(y1, y2), maxi(y1, y2) + 1):
        _grid[y][x] = SUELO
```

**Paso 5 — Volcar a tiles.** Pintamos la rejilla lógica en el `TileMapLayer`:

```gdscript
func _pintar() -> void:
    $Mapa.clear()
    for y in alto:
        for x in ancho:
            var atlas := Vector2i(1, 0) if _grid[y][x] == SUELO else Vector2i(0, 0)
            $Mapa.set_cell(Vector2i(x, y), 0, atlas)
    print("Mazmorra: ", _salas.size(), " salas, semilla ", semilla)
```

**Variante — Cueva por autómata celular.** Sustituye la generación por ruido inicial + reglas de vecindad:

```gdscript
func _generar_cueva(prob_muro: float, pasos: int) -> void:
    _init_grid()
    for y in alto:
        for x in ancho:
            var borde := x == 0 or y == 0 or x == ancho - 1 or y == alto - 1
            _grid[y][x] = MURO if (borde or _rng.randf() < prob_muro) else SUELO
    for _p in pasos:
        _paso_automata()

func _paso_automata() -> void:
    var copia := _grid.duplicate(true)
    for y in range(1, alto - 1):
        for x in range(1, ancho - 1):
            var muros := _vecinos_muro(x, y)
            # Regla 4-5: nace/persiste muro si hay 5+ vecinos muro.
            copia[y][x] = MURO if muros >= 5 else SUELO
    _grid = copia

func _vecinos_muro(cx: int, cy: int) -> int:
    var n := 0
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            if dx == 0 and dy == 0:
                continue
            if _grid[cy + dy][cx + dx] == MURO:
                n += 1
    return n
```

**Resultado observable:** al ejecutar verás una mazmorra de salas rectangulares unidas por pasillos, todas alcanzables. Si llamas a `_generar_cueva(0.45, 5)` y luego `_pintar()`, obtienes en su lugar una cueva orgánica. Con la misma semilla, el nivel se reproduce idéntico.

## ✍️ Ejercicios

1. Marca la primera sala como "entrada" y la última como "salida" con tiles distintos.
2. Añade un contador y muestra en consola cuántas salas se descartaron por solapamiento.
3. Cambia los pasillos en L por pasillos de 2 celdas de ancho.
4. En la cueva, elimina las "islas" de suelo desconectadas quedándote solo con la región más grande.
5. Expón `semilla` por `@export` y regenera con una tecla usando una semilla aleatoria.
6. Implementa una variante **drunkard walk**: un caminante que excava dando pasos aleatorios hasta cubrir un % del mapa.

## 📝 Reto verificable

Genera una mazmorra y **verifica la conectividad** por código: haz un *flood fill* desde el centro de la primera sala y comprueba que alcanza el centro de todas las demás. Si alguna queda aislada, conéctala con un pasillo adicional.

**Criterio de aceptación**: tras generar, un recorrido flood fill desde la sala inicial alcanza el 100% de las salas; con la misma semilla el nivel es idéntico entre ejecuciones; la consola imprime "conectividad: OK".

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Salas superpuestas | No compruebas solapamiento con margen; usa `Rect2i.grow(1)` e `intersects` |
| Salas inalcanzables | No conectas cada nueva sala con la anterior; añade el pasillo al colocarla |
| Índices fuera de rango | Cavas hasta el borde; deja `1` celda de margen en `randi_range` |
| El nivel cambia cada vez | No fijaste `_rng.seed`; asígnalo antes de generar |
| La cueva sale toda muros o todo suelo | `prob_muro` extrema o pocos pasos; prueba 0.45 y 4-6 iteraciones |
| Autómata que no cambia nada | Modificas `_grid` mientras lo lees; escribe en una copia y sustituye al final |

## ❓ Preguntas frecuentes

**¿Cuándo usar salas y cuándo autómatas celulares?**
Salas + pasillos para mazmorras estructuradas (mira Rogue, Nethack); autómatas celulares para cuevas orgánicas. Muchos juegos combinan ambos.

**¿Cómo garantizo que el nivel siempre se pueda terminar?**
Conectando por construcción (cada sala se une a la anterior) y validando con un flood fill. Si algo queda aislado, lo conectas en post-proceso.

**¿Qué ventaja da separar rejilla lógica y tiles?**
Puedes generar, validar y depurar el nivel como datos, sin depender del render. El `TileMapLayer` es solo la última capa de presentación.

**¿El BSP es mejor que la colocación aleatoria de salas?**
El BSP reparte el espacio de forma más uniforme y evita zonas vacías, a cambio de más código. La colocación aleatoria es más simple y suficiente para empezar.

## 🔗 Referencias

- [Clase TileMapLayer — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html)
- [Clase RandomNumberGenerator — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html)
- [Cellular Automata Method for Cave Generation — RogueBasin](https://www.roguebasin.com/index.php/Cellular_Automata_Method_for_Generating_Random_Cave-Like_Levels)
- [Procedural Content Generation in Games (libro abierto)](https://www.pcgbook.com/)

## ➡️ Siguiente clase

[Clase 124 - Machine learning en juegos: panorama (ML-Agents y RL)](../124-machine-learning-en-juegos-panorama-ml-agents-y-rl/README.md)
