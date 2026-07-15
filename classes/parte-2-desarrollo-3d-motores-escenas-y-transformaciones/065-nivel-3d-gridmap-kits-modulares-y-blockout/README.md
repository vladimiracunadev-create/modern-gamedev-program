# Clase 065 — Nivel 3D: GridMap, kits modulares y blockout

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot 4 — Using GridMaps y CSG tools*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Aprender a construir niveles 3D de forma rápida y ordenada usando dos flujos complementarios: el **blockout** con nodos CSG para prototipar volúmenes y probar el diseño antes de invertir en arte, y el **GridMap** con una `MeshLibrary` para "pintar" niveles con piezas modulares reutilizables. Es el puente entre la idea y el nivel jugable.

Al terminar habrás bloqueado un pequeño nivel con `CSGBox3D`/`CSGCombiner3D`, habrás generado una `MeshLibrary` a partir de piezas simples y habrás pintado con `GridMap` una versión modular navegable de ese mismo espacio.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar la diferencia entre blockout (greybox) y arte final, y por qué se prototipa primero.
2. Construir volúmenes de nivel con `CSGBox3D`, `CSGCombiner3D` y operaciones booleanas.
3. Crear una `MeshLibrary` a partir de escenas o mallas para usarla como kit modular.
4. Pintar un nivel con `GridMap` usando esa librería y colisiones.
5. Aplicar principios básicos de diseño de nivel 3D (circulación, escala, hitos visuales).

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Blockout / greybox | Permite validar el diseño sin gastar tiempo en arte. |
| 2 | Nodos CSG | Construyen y restan volúmenes rápidamente para prototipar. |
| 3 | Operaciones booleanas CSG | Unir, restar e intersecar crea huecos, puertas y pasillos. |
| 4 | MeshLibrary | Es el catálogo de piezas modulares que usa el GridMap. |
| 5 | GridMap | Coloca piezas en una rejilla 3D como un editor de tiles 3D. |
| 6 | Modularidad y escala | Piezas que encajan en la rejilla aceleran el montaje. |
| 7 | Flujo greybox → arte | Reemplazar piezas sin rehacer el nivel entero. |

## 📖 Definiciones y características

- **Blockout (greybox)**: versión del nivel hecha con volúmenes grises simples para probar espacio y recorrido. Clave: se centra en jugabilidad, no en estética.
- **CSGBox3D**: caja de geometría sólida constructiva que se combina con otras. Clave: ideal para prototipar muros, suelos y rampas.
- **CSGCombiner3D**: nodo raíz que agrupa hijos CSG y aplica sus operaciones. Clave: sin él, las operaciones booleanas entre piezas no se resuelven juntas.
- **Operación CSG (union, subtraction, intersection)**: modo que define cómo un CSG afecta a los anteriores. Clave: `subtraction` abre huecos como puertas o ventanas.
- **MeshLibrary**: recurso que guarda un conjunto de mallas (con colisión) numeradas como un catálogo. Clave: es la fuente de piezas del `GridMap`.
- **GridMap**: nodo que coloca piezas de una `MeshLibrary` en una rejilla 3D de tamaño fijo. Clave: acelera enormemente construir niveles modulares.
- **Modularidad**: diseñar piezas que encajan por múltiplos de la celda. Clave: si las medidas no cuadran, aparecen huecos y solapes.
- **Cell size**: tamaño de cada celda del `GridMap`. Clave: debe coincidir con la escala de tus piezas modulares.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x desde <https://godotengine.org/download>. Las guías clave son "Using GridMaps" en <https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html> y "Prototyping levels with CSG" en <https://docs.godotengine.org/en/stable/tutorials/3d/csg_tools.html>. Para exportar la librería revisa la sección de creación de `MeshLibrary` en la misma guía de GridMaps. Trabajaremos con cajas y mallas primitivas: el objetivo es el flujo, no el modelado.

## 🧪 Laboratorio guiado

Haremos primero un blockout con CSG y luego una versión modular con GridMap.

### Parte A — Blockout con CSG

1. Crea una escena con raíz `Node3D` llamada `Blockout`, con `Camera3D` y `DirectionalLight3D`. Añade un `CSGCombiner3D` llamado `Estructura`.

2. Dentro de `Estructura`, añade un `CSGBox3D` grande y plano como suelo (por ejemplo `size = Vector3(20, 1, 20)`). Añade cuatro `CSGBox3D` verticales como muros perimetrales.

3. Para abrir una puerta en un muro, añade otro `CSGBox3D` que atraviese el muro y ponle **Operation = Subtraction** en el Inspector. El hueco aparecerá al instante: eso es el poder del CSG para prototipar.

4. Puedes ajustar todo por código desde `Estructura` para probar variantes de tamaño rápidamente:

```gdscript
extends CSGCombiner3D

func _ready() -> void:
	# Genera un pasillo de N segmentos de muro por código para probar longitudes.
	var largo := 6
	for i in largo:
		var muro := CSGBox3D.new()
		muro.size = Vector3(1, 3, 4)
		muro.position = Vector3(-5, 1.5, -i * 4)
		add_child(muro)
	print("Blockout generado con ", largo, " segmentos")
```

5. Ejecuta y recorre el espacio con la cámara. Ajusta medidas hasta que el recorrido "se sienta" bien. Este greybox es desechable: solo valida el diseño.

### Parte B — MeshLibrary + GridMap

6. Crea una escena aparte por cada pieza modular (por ejemplo `piso.tscn`, `muro.tscn`). Cada una: un `Node3D` raíz con un `MeshInstance3D` (`BoxMesh` a escala de celda) y un `StaticBody3D` con `CollisionShape3D` para que el jugador no las atraviese. Diséñalas para una celda de **2×2×2**.

7. Crea una escena `Node3D` llamada `KitLibreria`. Añade tus piezas como hijos instanciados. Con la raíz seleccionada, ve al menú **Escena → Convertir en… → MeshLibrary** y guárdala como `kit.meshlib`. Cada pieza queda numerada en la librería.

8. Crea la escena principal `Node3D` `NivelModular` con `Camera3D` y `DirectionalLight3D`. Añade un nodo **GridMap**. En su Inspector, asigna `kit.meshlib` a la propiedad **Mesh Library** y pon **Cell → Size = (2, 2, 2)** para que coincida con tus piezas.

9. Con el `GridMap` seleccionado, en el panel inferior aparece la paleta de piezas. Selecciona el "piso" y pinta una plataforma; selecciona el "muro" y levanta paredes alrededor. Estás construyendo el nivel como si fuera un editor de tiles, pero en 3D.

10. También puedes colocar celdas por código, útil para generación procedimental:

```gdscript
extends GridMap

func _ready() -> void:
	# item 0 = piso, item 1 = muro (según el orden en la MeshLibrary).
	var piso := 0
	for x in range(-4, 5):
		for z in range(-4, 5):
			set_cell_item(Vector3i(x, 0, z), piso)
	# Borde de muros en una fila.
	var muro := 1
	for x in range(-4, 5):
		set_cell_item(Vector3i(x, 1, -4), muro)
```

11. Ejecuta con **F6**. Recorre el nivel: las piezas encajan por celda, tienen colisión y forman un espacio navegable. Cambiar una pieza de la `MeshLibrary` por arte final actualiza todas las celdas que la usan sin rehacer el mapa.

## ✍️ Ejercicios

1. Amplía el blockout CSG con una rampa (un `CSGBox3D` rotado) y comprueba el recorrido.
2. Usa una operación `Subtraction` para abrir una ventana en un muro CSG.
3. Añade una tercera pieza (una columna) a la `MeshLibrary` y píntala en el GridMap.
4. Genera por código un pasillo recto de 10 celdas con `set_cell_item`.
5. Cambia el `cell_size` a 4 y ajusta las piezas para que encajen; observa qué se rompe si no cuadran.
6. Reemplaza la malla de una pieza por otra con material distinto y verifica que todo el nivel se actualiza.

## 📝 Reto verificable

Diseña una sala jugable en **dos pasadas**: primero un blockout completo con CSG (suelo, muros, una puerta por `Subtraction` y una rampa) y luego reconstruye esa misma sala con `GridMap` y una `MeshLibrary` de al menos **3** piezas, con colisiones funcionales. **Criterio de aceptación**: el blockout permite recorrer la sala y validar la puerta y la rampa; la versión GridMap reproduce el mismo espacio con piezas modulares que encajan sin huecos ni solapes, tiene colisión (el jugador no atraviesa muros) y al menos parte del mapa se pinta y otra parte se genera por código con `set_cell_item`.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La resta CSG no abre el hueco | El `CSGBox3D` a restar no es hijo del `CSGCombiner3D` o no está en modo Subtraction. Colócalo dentro y cambia Operation. |
| Las piezas del GridMap dejan huecos o se solapan | El `cell_size` no coincide con el tamaño de las piezas. Ajústalos para que encajen. |
| La paleta del GridMap aparece vacía | No asignaste una `MeshLibrary` válida a la propiedad Mesh Library. Asígnala. |
| El jugador atraviesa los muros del GridMap | Las piezas se exportaron sin `StaticBody3D`/`CollisionShape3D`. Añade colisión antes de generar la librería. |
| Cambiar una pieza no actualiza el nivel | Editaste una instancia, no la escena de la pieza o la librería. Regenera la `MeshLibrary`. |
| CSG lento con muchas operaciones | El CSG recalcula geometría; no lo uses para el nivel final, solo para blockout. |

## ❓ Preguntas frecuentes

**❓ ¿Debo entregar el nivel final en CSG?** No. El CSG es excelente para prototipar, pero recalcula geometría y no rinde bien a gran escala. Úsalo para el greybox y pasa a `GridMap` o mallas importadas para el nivel definitivo.

**❓ ¿Por qué mis piezas no encajan en el GridMap?** Porque su tamaño no es múltiplo del `cell_size`. Diseña las piezas a la medida exacta de la celda (o un múltiplo) para que la rejilla las alinee sin huecos.

**❓ ¿Cómo añado colisión a las piezas del kit?** Cada pieza debe incluir un `StaticBody3D` con su `CollisionShape3D` antes de convertir la escena en `MeshLibrary`. El GridMap conserva esa colisión.

**❓ ¿Puedo mezclar GridMap con instancias sueltas?** Sí. Lo habitual es usar `GridMap` para la estructura repetitiva (suelos, muros) e instanciar props únicos (coleccionables, enemigos) por código encima, como viste en la clase anterior.

## 🔗 Referencias

- Godot Docs — Using GridMaps: <https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html>
- Godot Docs — Prototyping levels with CSG: <https://docs.godotengine.org/en/stable/tutorials/3d/csg_tools.html>
- Godot Docs — Clase GridMap: <https://docs.godotengine.org/en/stable/classes/class_gridmap.html>
- Godot Docs — Clase MeshLibrary: <https://docs.godotengine.org/en/stable/classes/class_meshlibrary.html>

## ⬅️ Clase anterior

[Clase 064 - Instanciado y escenas 3D reutilizables](../064-instanciado-y-escenas-3d-reutilizables/README.md)

## ➡️ Siguiente clase

[Clase 066 - Optimización 3D básica: LOD, occlusion y draw calls](../066-optimizacion-3d-basica-lod-occlusion-y-draw-calls/README.md)
