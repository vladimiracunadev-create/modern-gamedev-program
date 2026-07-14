# Clase 066 — Optimización 3D básica: LOD, occlusion y draw calls

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot 4 — Optimization using MultiMesh y Occlusion culling*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Entender por qué un nivel 3D puede ir lento aunque "no se vea tan cargado" y aprender las herramientas básicas para acelerarlo: reducir **draw calls** agrupando objetos iguales con `MultiMeshInstance3D`, bajar detalle en la distancia con **LOD** vía `visibility_range`, ocultar lo que no se ve con **occlusion culling**, y leer el monitor de rendimiento para medir en lugar de adivinar.

Al terminar habrás sembrado cientos de objetos de dos formas —como nodos individuales y como un solo `MultiMeshInstance3D`— y compararás FPS y draw calls en el profiler para comprobar con números la diferencia.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar qué es un draw call y por qué su número afecta al rendimiento.
2. Usar `MultiMeshInstance3D` para dibujar miles de objetos iguales en pocas llamadas.
3. Configurar LOD con `visibility_range` para reducir detalle a distancia.
4. Activar occlusion culling con `OccluderInstance3D` para no dibujar lo tapado.
5. Leer el monitor de rendimiento (FPS, draw calls, primitivas) para comparar soluciones.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Draw calls | Cada una cuesta CPU; muchas pequeñas hunden el FPS. |
| 2 | Batching e instancing | Agrupar objetos iguales reduce drásticamente las llamadas. |
| 3 | MultiMeshInstance3D | Dibuja miles de copias con una sola malla y una llamada. |
| 4 | visibility_range (LOD) | Baja detalle lejano para ahorrar geometría. |
| 5 | Occlusion culling | Evita dibujar lo que otro objeto tapa. |
| 6 | VisibleOnScreenNotifier3D | Activa/desactiva lógica según si algo está en pantalla. |
| 7 | Monitor de rendimiento | Permite medir en vez de suponer dónde está el coste. |

## 📖 Definiciones y características

- **Draw call**: instrucción que la CPU envía a la GPU para dibujar algo. Clave: reducir su número suele importar más que reducir polígonos.
- **Batching / instancing**: técnica de dibujar muchos objetos iguales juntos. Clave: convierte miles de llamadas en unas pocas.
- **MultiMeshInstance3D**: nodo que renderiza muchas instancias de una misma malla con transformaciones individuales. Clave: ideal para césped, rocas, árboles o multitudes.
- **visibility_range**: rango de distancias en que un `GeometryInstance3D` es visible. Clave: base del LOD; combina versiones de alto y bajo detalle por distancia.
- **OccluderInstance3D**: nodo que define geometría que oculta lo que hay detrás. Clave: activa el occlusion culling para no dibujar lo tapado.
- **VisibleOnScreenNotifier3D**: nodo que avisa cuando su caja entra o sale de la pantalla. Clave: sirve para apagar lógica de objetos fuera de vista.
- **FPS (cuadros por segundo)**: medida principal de fluidez. Clave: si cae, algo cuesta demasiado por cuadro.
- **Monitor de rendimiento**: panel del depurador con métricas en vivo (FPS, draw calls, memoria). Clave: es tu instrumento para decidir qué optimizar.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x desde <https://godotengine.org/download>. Las guías clave son "Optimization using MultiMesh" en <https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html>, "Occlusion culling" en <https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html> y "Visibility ranges (HLOD)" en <https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html>. El monitor de rendimiento está en el editor bajo la pestaña **Depurador → Monitores** al ejecutar el juego.

## 🧪 Laboratorio guiado

Compararemos dos formas de dibujar muchos objetos y luego añadiremos LOD.

1. Crea una escena `Node3D` `PruebaRendimiento` con `Camera3D` y `DirectionalLight3D`. Añade un `Label` en un `CanvasLayer` para mostrar el FPS en pantalla.

2. **Versión lenta: nodos individuales.** Adjunta este script a la raíz para sembrar 2000 cubos como nodos separados (muchas draw calls):

```gdscript
extends Node3D

@export var cantidad: int = 2000
@onready var etiqueta: Label = $CanvasLayer/Label

func _ready() -> void:
	var malla := BoxMesh.new()
	for i in cantidad:
		var nodo := MeshInstance3D.new()
		nodo.mesh = malla
		nodo.position = _posicion_aleatoria()
		add_child(nodo)

func _posicion_aleatoria() -> Vector3:
	return Vector3(randf_range(-25, 25), randf_range(0, 5), randf_range(-25, 25))

func _process(_delta: float) -> void:
	etiqueta.text = "FPS: %d" % Engine.get_frames_per_second()
```

3. Ejecuta y abre **Depurador → Monitores**. Observa **Raster → Draw Calls** y el FPS. Con nodos individuales cada cubo tiende a sumar llamadas y el número sube mucho.

4. **Versión rápida: MultiMeshInstance3D.** Crea otra escena `PruebaMultiMesh` igual, pero siembra los mismos 2000 cubos en un solo `MultiMeshInstance3D`:

```gdscript
extends Node3D

@export var cantidad: int = 2000
@onready var etiqueta: Label = $CanvasLayer/Label

func _ready() -> void:
	var multi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = cantidad
	for i in cantidad:
		var t := Transform3D(Basis(), _posicion_aleatoria())
		mm.set_instance_transform(i, t)
	multi.multimesh = mm
	add_child(multi)

func _posicion_aleatoria() -> Vector3:
	return Vector3(randf_range(-25, 25), randf_range(0, 5), randf_range(-25, 25))

func _process(_delta: float) -> void:
	etiqueta.text = "FPS: %d" % Engine.get_frames_per_second()
```

5. Ejecuta esta segunda escena y vuelve a mirar **Draw Calls** y FPS. Verás que las llamadas caen drásticamente (los 2000 cubos se dibujan en muy pocas) y el FPS sube. Ese es el efecto del instancing: misma malla, una llamada.

6. **LOD con visibility_range.** En una escena aparte, crea dos versiones de un objeto: `MeshInstance3D` de alto detalle (por ejemplo `SphereMesh` con muchos segmentos) y otra de bajo detalle. En el Inspector de cada una, bajo **Visibility Range**:
   - Alta: `Begin = 0`, `End = 20`.
   - Baja: `Begin = 20`, `End = 200`.
   Al alejar la cámara más de 20 unidades, Godot cambia automáticamente a la malla de bajo detalle, ahorrando geometría lejana.

7. **Occlusion culling (opcional).** Añade un `OccluderInstance3D` grande (por ejemplo con un `BoxOccluder3D`) entre la cámara y un grupo de objetos. En **Proyecto → Ajustes → Rendering → Occlusion Culling** activa "Use Occlusion Culling". Godot dejará de dibujar lo que quede tapado por el oclusor, reduciendo aún más el trabajo.

8. Anota tus resultados en una tabla propia: FPS y draw calls de la versión con nodos vs la de MultiMesh. Los números, no la intuición, justifican la optimización.

## ✍️ Ejercicios

1. Sube la `cantidad` a 10000 en ambas escenas y compara cuál sigue siendo jugable.
2. Añade rotación aleatoria a cada instancia del `MultiMesh` usando `Basis` en el `Transform3D`.
3. Configura tres niveles de LOD (alta, media, baja) con rangos de `visibility_range` encadenados.
4. Usa un `VisibleOnScreenNotifier3D` para imprimir en consola cuándo un objeto entra o sale de pantalla.
5. Mide el impacto del occlusion culling activándolo y desactivándolo con muchos objetos tras un muro.
6. Muestra en el `Label` también el número de draw calls usando `Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)`.

## 📝 Reto verificable

Crea una demo comparativa con un botón o tecla que alterne entre dibujar **3000** objetos como nodos individuales y como un único `MultiMeshInstance3D`, mostrando en pantalla el FPS y los draw calls de cada modo. Añade además LOD por `visibility_range` a un objeto destacado. **Criterio de aceptación**: al ejecutar, ambos modos dibujan la misma cantidad de objetos; el panel muestra que el modo MultiMesh tiene muchos menos draw calls y mejor (o igual) FPS; y al alejar la cámara del objeto con LOD se observa el cambio a menor detalle. Debes reportar los números medidos.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El MultiMesh no muestra nada | Falta asignar `mesh`, `instance_count` o `transform_format`. Configúralos antes de asignar el `multimesh`. |
| Todas las instancias del MultiMesh en el origen | No llamaste a `set_instance_transform` por instancia. Asigna una transformación a cada una. |
| El LOD no cambia de malla | `visibility_range` mal configurado o solapado. Asegura que los rangos Begin/End no se pisen. |
| El occlusion culling no reduce nada | No activaste "Use Occlusion Culling" en Ajustes o falta un `OccluderInstance3D`. Activa ambos. |
| El FPS no mejora con MultiMesh | El cuello de botella no eran las draw calls sino los polígonos. Mide primero en el monitor. |
| Los monitores no aparecen | Debes ejecutar el juego y abrir Depurador → Monitores mientras corre. |

## ❓ Preguntas frecuentes

**❓ ¿Qué reduce más el coste: menos polígonos o menos draw calls?** Depende, y por eso se mide. En escenas con muchos objetos pequeños e iguales, reducir draw calls (con `MultiMeshInstance3D`) suele dar el mayor salto. El monitor te dice cuál es tu cuello de botella.

**❓ ¿Cuándo uso MultiMesh y cuándo GridMap?** `MultiMeshInstance3D` es para muchísimas copias de una malla sin colisión propia (vegetación, escombros, multitudes). `GridMap` es para estructura de nivel modular con colisión. No compiten: se complementan.

**❓ ¿El LOD con `visibility_range` sirve para cualquier malla?** Sí, cualquier `GeometryInstance3D` lo soporta. La técnica de intercambiar dos mallas (alta y baja) por distancia es "HLOD manual"; también existe generación automática de LOD al importar modelos.

**❓ ¿El occlusion culling siempre conviene?** No siempre. Tiene un coste propio y brilla en escenas con muchos objetos ocultos tras geometría grande (interiores, ciudades). En espacios abiertos y despejados puede aportar poco.

## 🔗 Referencias

- Godot Docs — Optimization using MultiMesh: <https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html>
- Godot Docs — Occlusion culling: <https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html>
- Godot Docs — Visibility ranges (HLOD): <https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html>
- Godot Docs — Clase MultiMeshInstance3D: <https://docs.godotengine.org/en/stable/classes/class_multimeshinstance3d.html>

## ➡️ Siguiente clase

[Clase 067 - Capstone Parte 2: un nivel 3D explorable en tercera persona](../067-capstone-parte-2-un-nivel-3d-explorable-en-tercera-persona/README.md)
