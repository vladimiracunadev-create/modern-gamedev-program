# Clase 102 — Instancing y MultiMesh: miles de objetos

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Godot Docs — Using MultiMesh / MultiMeshInstance3D*
> ⏱️ Duración estimada: **55 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender por qué el **instancing** permite dibujar miles de mallas idénticas en (casi) una sola *draw call*, usar `MultiMeshInstance3D` para sembrar y transformar miles de instancias, dar **transform y color por instancia**, y leer esos datos en el shader con `INSTANCE_CUSTOM`, midiendo la reducción de draw calls.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar qué es una draw call y por qué el instancing la reduce.
2. Configurar un `MultiMesh` con `instance_count`, transform_format y color/custom.
3. Colocar instancias con `set_instance_transform` y variar color con `set_instance_color`.
4. Leer color y datos personalizados en el shader vía `COLOR` e `INSTANCE_CUSTOM`.
5. Medir draw calls y vértices con el monitor de rendimiento de Godot.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es una draw call | Es el cuello de botella al dibujar muchos objetos |
| 2 | Instancing | Una llamada para miles de copias iguales |
| 3 | `MultiMeshInstance3D` | El nodo que implementa instancing en Godot |
| 4 | `instance_count` y buffers | Cuántas instancias y qué datos por instancia |
| 5 | Transform por instancia | Posición/rotación/escala de cada copia |
| 6 | Color y `INSTANCE_CUSTOM` | Variar aspecto sin duplicar mallas |
| 7 | Casos: hierba, multitudes | Dónde brilla el instancing |
| 8 | Medición de rendimiento | Confirmar la ganancia con datos |

## 📖 Definiciones y características

- **Draw call**: orden que la CPU envía a la GPU para dibujar una malla; muchas draw calls saturan la CPU.
- **Instancing**: dibujar N copias de la misma malla con una sola orden, variando solo datos por instancia.
- **`MultiMesh`**: recurso que guarda una malla y un buffer de transforms (y opcionalmente color/custom) por instancia.
- **`MultiMeshInstance3D`**: nodo que renderiza un `MultiMesh` en la escena.
- **`transform_format`**: define si los transforms son 2D o 3D.
- **`use_colors`/`use_custom_data`**: habilitan un color y un `vec4` arbitrario por instancia.
- **`INSTANCE_CUSTOM`**: builtin del shader que expone el `vec4` de datos personalizados de la instancia.
- **`set_instance_transform(i, xform)`**: coloca la instancia `i`; `set_instance_color(i, c)` le da color.

## 🧰 Herramientas y preparación

Godot 4.x. Crea un `MultiMeshInstance3D` y asígnale un `MultiMesh` nuevo con un `QuadMesh` o una malla simple de brizna de hierba (un quad alto). Activa el **monitor de rendimiento** (`Debugger > Monitors`) para ver *Draw Calls* y *Primitives*. Prepara un `ShaderMaterial` para animar/variar las instancias.

- Using MultiMesh: <https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html>
- MultiMesh (clase): <https://docs.godotengine.org/en/stable/classes/class_multimesh.html>

## 🧪 Laboratorio guiado

Sembraremos miles de briznas de hierba y variaremos su color y rotación por instancia.

**Paso 1 — Nodo y recurso.** Añade `MultiMeshInstance3D`. En `Multimesh` crea un `MultiMesh`. Asigna su `Mesh` (un `QuadMesh` de 0.1×0.6, o una malla de hoja). Configura:

- `Transform Format = 3D`
- `Use Colors = On`
- `Use Custom Data = On`
- `Instance Count = 5000`

**Paso 2 — Sembrar con GDScript.** Coloca cada instancia en un área con posición, rotación y escala aleatorias, y un color/dato personalizado:

```gdscript
extends MultiMeshInstance3D

@export var area := 20.0
@export var cantidad := 5000

func _ready() -> void:
	var mm := multimesh
	mm.instance_count = cantidad
	for i in cantidad:
		var pos := Vector3(
			randf_range(-area, area),
			0.0,
			randf_range(-area, area)
		)
		var giro := randf_range(0.0, TAU)
		var alto := randf_range(0.8, 1.3)
		var t := Transform3D(Basis(Vector3.UP, giro).scaled(Vector3(1, alto, 1)), pos)
		mm.set_instance_transform(i, t)
		# Color por instancia: variación de verde.
		var verde := randf_range(0.4, 0.9)
		mm.set_instance_color(i, Color(0.1, verde, 0.1))
		# Custom data: guardo una fase para el viento (x) y un factor (y).
		mm.set_instance_custom_data(i, Color(randf(), randf_range(0.5, 1.0), 0.0, 0.0))
```

Ejecuta: aparece un campo de miles de briznas con distinto tono y giro.

**Paso 3 — Shader que usa `COLOR` e `INSTANCE_CUSTOM`.** Asigna al material de la malla del multimesh:

```glsl
shader_type spatial;
render_mode cull_disabled;

uniform float fuerza_viento : hint_range(0.0, 1.0) = 0.3;

void vertex() {
	// INSTANCE_CUSTOM.x es la fase por instancia; anima la punta (UV.y bajo = base).
	float fase = INSTANCE_CUSTOM.x * 6.2831;
	float sway = sin(TIME * 2.0 + fase) * fuerza_viento;
	// Solo la parte alta de la brizna se mueve (base fija).
	float altura = 1.0 - UV.y;
	VERTEX.x += sway * altura * INSTANCE_CUSTOM.y;
}

void fragment() {
	// COLOR llega de set_instance_color: cada brizna con su verde.
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.9;
}
```

Ahora la hierba se mece con el viento y cada brizna conserva su color: todo con **una** malla.

**Paso 4 — Medir draw calls.** Abre `Debugger > Monitors` y observa `Rendering > Draw Calls In Frame`. Compara: 5000 `MeshInstance3D` separados generarían miles de draw calls; el `MultiMeshInstance3D` las mantiene en un puñado. Anota la diferencia.

**Paso 5 — Escalar.** Sube `cantidad` a 20000 y vuelve a mirar los FPS y las draw calls. Verás que el coste crece por vértices/GPU, pero las draw calls apenas suben.

**Resultado visible**: una pradera con miles de briznas de colores variados meciéndose con el viento y un contador de draw calls que casi no se mueve.

## ✍️ Ejercicios

1. Cambia la malla del multimesh por un cubo y siembra 10000 rocas con escala aleatoria.
2. Usa `set_instance_color` para un degradado de color según la posición X.
3. Guarda en `INSTANCE_CUSTOM.y` la altura y úsala para variar la amplitud del viento.
4. Compara draw calls entre 1000 `MeshInstance3D` y un `MultiMesh` de 1000 instancias.
5. Añade una segunda fase de viento con otra frecuencia para un movimiento más natural.
6. Coloca las instancias sobre un terreno usando un `RayCast` o altura de un `HeightMap`.

## 📝 Reto verificable

Crea un campo de **al menos 8000 briznas** de hierba con `MultiMeshInstance3D`, cada una con color y rotación propios y un vaivén de viento por instancia usando `INSTANCE_CUSTOM`, manteniendo las draw calls por debajo de un puñado.

**Criterio de aceptación**: el monitor muestra que las draw calls no crecen proporcionalmente al número de instancias (siguen en el orden de decenas, no miles); cada brizna tiene color distinto y el viento las mece con fases desfasadas; el conteo antes/después queda documentado.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Todas las instancias en el origen | No llamaste `set_instance_transform`; recórrelas en `_ready` |
| El color por instancia no aparece | `Use Colors = Off` o el shader no usa `COLOR`; actívalo y léelo |
| `INSTANCE_CUSTOM` siempre en cero | `Use Custom Data = Off` o no usas `set_instance_custom_data` |
| Draw calls siguen altas | Usaste muchos nodos separados en vez de un `MultiMesh` |
| Recorte incorrecto de las briznas | Falta `cull_disabled` para geometría de una cara |
| FPS baja con 20k instancias | Coste de vértices/overdraw; simplifica la malla o usa LOD |

## ❓ Preguntas frecuentes

**¿El instancing sirve para mallas distintas?** No: todas las instancias comparten la misma malla y material. Para variedad se usa color/custom por instancia o varios multimesh.

**¿Cómo animo cada instancia distinto?** Con `INSTANCE_CUSTOM`: guardas una fase/semilla por instancia y la usas en el shader para desfasar la animación.

**¿MultiMesh o GPUParticles para hierba?** MultiMesh cuando las posiciones son fijas y persistentes (césped colocado). Partículas cuando nacen/mueren dinámicamente.

**¿Puedo actualizar transforms cada frame?** Sí, pero reescribir miles de transforms por frame cuesta CPU; hazlo solo para las que cambian, o mueve la animación al shader.

## 🔗 Referencias

- Godot — Using MultiMesh: <https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html>
- Godot — MultiMesh (clase): <https://docs.godotengine.org/en/stable/classes/class_multimesh.html>
- Godot — MultiMeshInstance3D (clase): <https://docs.godotengine.org/en/stable/classes/class_multimeshinstance3d.html>

## ➡️ Siguiente clase

[Clase 103 - Toon/cel shading y estilos no fotorrealistas](../103-toon-cel-shading-y-estilos-no-fotorrealistas/README.md)
