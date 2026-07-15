# Clase 035 — Tilemaps y diseño de niveles 2D

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4*
> ⏱️ Duración estimada: **100 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Hasta ahora tus niveles son unos pocos `StaticBody2D` colocados a mano. Eso no escala: un plataformas real tiene cientos de bloques. La solución son los **tilemaps**: pintas el nivel con "azulejos" (tiles) reutilizables a partir de una imagen. En Godot 4.3+ esto se hace con `TileMapLayer` alimentado por un recurso `TileSet`.

En esta clase crearás un `TileSet` desde una imagen, le darás **colisión física por tile**, pintarás un nivel jugable con un `TileMapLayer` y probarás el **autotiling** con terrenos para que los bordes encajen solos. Terminarás entendiendo por qué el tilemap supera a colocar sprites uno a uno y qué principios de **diseño de nivel** (legibilidad, dificultad progresiva) aplicar.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Crear un `TileSet` desde una imagen y definir sus tiles y regiones.
2. Añadir colisión física por tile dentro del `TileSet`.
3. Pintar un nivel jugable con `TileMapLayer` y organizar capas.
4. Usar terrenos/autotiling básico para que los bordes conecten automáticamente.
5. Aplicar principios de diseño de nivel: legibilidad y dificultad progresiva.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | `TileSet` desde imagen | Fuente de todos los tiles reutilizables |
| 2 | Regiones y tamaño de tile | Definen cómo se recorta la imagen en azulejos |
| 3 | Colisión física por tile | El nivel colisiona sin colocar cuerpos a mano |
| 4 | `TileMapLayer` (4.3+) | Nodo que pinta el nivel; sustituye al viejo `TileMap` |
| 5 | Capas de tilemap | Separar fondo, colisión y decoración |
| 6 | Terrenos / autotiling | Los bordes encajan automáticamente al pintar |
| 7 | Diseño de nivel | Legibilidad y curva de dificultad hacen el nivel jugable |

## 📖 Definiciones y características

- **TileSet**: recurso que agrupa los tiles (recortes de imagen) y sus datos (colisión, terrenos). Clave: se comparte entre varios `TileMapLayer`.
- **TileMapLayer**: nodo de Godot 4.3+ que dibuja una capa de tiles usando un `TileSet`. Clave: reemplaza las capas internas del antiguo `TileMap`.
- **Tamaño de tile**: dimensiones en píxeles de cada azulejo (p. ej. 16×16). Clave: debe coincidir con la cuadrícula de tu imagen.
- **Colisión por tile**: polígono de colisión definido dentro del `TileSet` para un tile. Clave: se activa por *Physics Layer* del TileSet.
- **Physics Layer del TileSet**: capa de física que reciben los tiles con colisión. Clave: se mapea a `collision_layer` (World).
- **Terreno (Terrain)**: conjunto de tiles con reglas de conexión para autotiling. Clave: pinta bordes coherentes sin elegir tile a tile.
- **Autotiling**: selección automática del tile correcto según los vecinos. Clave: ahorra horas y evita costuras visuales.
- **Legibilidad**: claridad de qué es suelo, peligro y camino. Clave: el jugador debe "leer" el nivel de un vistazo.

## 🧰 Herramientas y preparación

Necesitas Godot **4.3 o superior** (por `TileMapLayer`) y una imagen de tiles (tileset) — por ejemplo packs gratuitos de [Kenney](https://kenney.nl/assets) — con cuadrícula regular (16×16 o 32×32). Continúa el proyecto de plataformas con tu `Player`. Referencias: [Usar TileMaps](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html) y [Usar TileSets](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html).

## 🧪 Laboratorio guiado

### Paso 1 — Añadir un TileMapLayer y crear el TileSet

En tu escena de nivel, añade un nodo **TileMapLayer**. En su Inspector, en la propiedad **Tile Set**, elige *Nuevo TileSet*. Haz clic sobre el recurso para abrirlo en el panel inferior. Configura el **Tile Size** (p. ej. `16, 16`) para que coincida con tu imagen.

### Paso 2 — Cargar la imagen y crear los tiles

En el panel **TileSet** (abajo), pestaña *Tiles*, pulsa el botón **+** para añadir un *Atlas* y arrastra tu imagen de tileset. Godot preguntará si quiere crear automáticamente los tiles según la cuadrícula: acepta. Ahora tienes todos los azulejos disponibles para pintar.

### Paso 3 — Dar colisión física a los tiles de suelo

1. En el panel TileSet, selecciona el **TileSet** raíz y ve a *Physics Layers*: pulsa **Agregar elemento** para crear una *Physics Layer 0*. En su *Collision Layer* activa `World` (la capa nombrada en la clase 033).
2. Cambia a modo **Select** en el atlas, selecciona los tiles sólidos (suelo, plataformas) y en la pestaña *Physics* dibuja el polígono de colisión (por defecto un cuadrado que cubre el tile). Puedes usar *Reset to default tile shape* para el cuadrado completo.

Ahora todos los tiles de suelo que pintes tendrán colisión sin colocar cuerpos manualmente.

### Paso 4 — Pintar el nivel

Selecciona el nodo `TileMapLayer` en la escena y aparecerá el panel **TileMap** con tu paleta. Elige un tile y pinta una plataforma horizontal, algunos escalones y un par de plataformas flotantes. Coloca tu `Player` encima y ejecuta: el personaje camina y salta sobre los tiles gracias a la colisión del `TileSet`.

Para separar responsabilidades, puedes usar **varios `TileMapLayer`** hermanos: uno `Fondo` (sin colisión, decoración) y otro `Colision` (suelo sólido). Ordénalos en el árbol para controlar el dibujado.

### Paso 5 — Autotiling con terrenos

1. En el panel TileSet, selecciona el TileSet raíz → *Terrain Sets*: añade un *Terrain Set* con modo *Match Corners and Sides* y dentro un *Terrain* llamado `Tierra`.
2. Selecciona los tiles de suelo en el atlas y, en la pestaña *Terrains*, píntalos indicando qué esquinas/lados pertenecen al terreno `Tierra`.
3. En el panel TileMap, cambia a la pestaña **Terrains**, elige `Tierra` y pinta: Godot elegirá automáticamente los tiles de borde, esquina y relleno correctos.

### Paso 6 — Notas de diseño de nivel

Al pintar, aplica principios básicos:

- **Legibilidad**: que el suelo transitable contraste con el fondo; el peligro (pinchos) debe verse distinto.
- **Dificultad progresiva**: los primeros saltos, cortos y seguros; introduce un mecanismo (plataforma móvil, one-way) de forma aislada antes de combinarlo.
- **Ritmo**: alterna tramos exigentes con zonas de respiro.
- **Guía visual**: usa la disposición de plataformas para dirigir la mirada hacia dónde ir.

## ✍️ Ejercicios

1. Crea un segundo `TileMapLayer` de fondo (sin colisión) y píntalo detrás del de colisión.
2. Añade tiles de pinchos con una `Physics Layer` distinta y combínalos con una `Area2D` de peligro (clase 033).
3. Diseña un tramo que enseñe el salto largo de forma segura y luego lo exija sobre un foso.
4. Usa el terreno `Tierra` para pintar una colina y verifica que los bordes conectan solos.
5. Cambia el `Tile Size` a 32×32 con otra imagen y reajusta las colisiones.
6. Crea una plataforma one-way como tile específico y colócala con el tilemap.

## 📝 Reto verificable

Construye un nivel jugable completo usando `TileMapLayer` y un `TileSet` con colisión: al menos una capa de fondo decorativa y una capa de colisión con suelo, escalones y plataformas flotantes. Usa terrenos/autotiling para el suelo principal y aplica una curva de dificultad legible (fácil → introduce mecánica → la combina).

**Criterio de aceptación**: el jugador recorre el nivel caminando y saltando sobre tiles con colisión real (sin cuerpos colocados a mano); el suelo pintado con terreno muestra bordes y esquinas correctos; el fondo no colisiona; y el recorrido presenta una progresión de dificultad clara y legible.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El jugador atraviesa los tiles | El TileSet no tiene *Physics Layer* o los tiles no tienen polígono; añádelos en el editor del TileSet |
| No encuentro `TileMap` con capas antiguas | En 4.3+ se usa `TileMapLayer` (un nodo por capa); no busques el nodo `TileMap` monolítico |
| Los tiles se ven cortados o desplazados | El `Tile Size` no coincide con la cuadrícula de la imagen; ajústalo |
| El autotiling pinta tiles incorrectos | Mal definidas las esquinas/lados del terreno; revisa la pestaña *Terrains* del TileSet |
| La colisión está en la capa equivocada | La *Physics Layer* del TileSet no apunta a `World`; corrige su `collision_layer` |
| El fondo tapa al jugador o al suelo | Orden de nodos incorrecto; coloca el `TileMapLayer` de fondo antes en el árbol |

## ❓ Preguntas frecuentes

**❓ ¿`TileMap` o `TileMapLayer`?** En Godot 4.3+ el flujo recomendado es `TileMapLayer`: cada capa es su propio nodo, más flexible y explícito. El antiguo `TileMap` con capas internas quedó obsoleto.

**❓ ¿Por qué un tilemap y no muchos sprites?** El tilemap comparte una sola textura y datos de colisión, se pinta en bloque, rinde mejor y es infinitamente más rápido de editar que colocar y configurar cientos de nodos.

**❓ ¿La colisión va en el TileSet o en el TileMapLayer?** El polígono de colisión se define **por tile en el TileSet**; el `TileMapLayer` solo lo instancia al pintar. Así todos los tiles iguales comparten la misma colisión.

**❓ ¿Qué es exactamente el autotiling?** Es la selección automática del tile adecuado (borde, esquina, relleno) según los vecinos, usando las reglas de terreno que definiste. Pintas "tierra" y Godot pone el tile correcto en cada celda.

## 🔗 Referencias

- [Usar TileMaps — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html)
- [Usar TileSets — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)
- [TileMapLayer — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html)
- [TileSet — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_tileset.html)

## ⬅️ Clase anterior

[Clase 034 - Física 2D: RigidBody, gravedad y plataformas](../034-fisica-2d-rigidbody-gravedad-y-plataformas/README.md)

## ➡️ Siguiente clase

[Clase 036 - Máquina de estados del jugador: idle, run, jump, fall](../036-maquina-de-estados-del-jugador-idle-run-jump-fall/README.md)
