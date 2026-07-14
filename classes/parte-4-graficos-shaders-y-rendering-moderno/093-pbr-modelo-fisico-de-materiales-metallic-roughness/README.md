# Clase 093 — PBR: modelo físico de materiales (metallic/roughness)

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Godot Engine 4.x — Standard Material 3D y Spatial shaders*
> ⏱️ Duración estimada: **65 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender qué es el **renderizado basado en física (PBR)** y el flujo **metallic/roughness** que usa Godot 4. Aprenderás qué representa cada canal (albedo, metallic, roughness, normal, AO), por qué un material metálico se comporta distinto a uno dieléctrico y cómo la **conservación de energía** evita que las superficies "brillen más de lo que reciben". Lo montarás dos veces: con un `StandardMaterial3D` de mapas y con un shader `spatial` que escribe `ALBEDO`, `METALLIC` y `ROUGHNESS` a mano.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar qué es **PBR** y en qué se diferencia del sombreado ad-hoc de la clase anterior.
2. Describir el papel de **albedo, metallic, roughness, normal y AO** en el flujo metallic/roughness.
3. Configurar un **`StandardMaterial3D`** PBR asignando mapas a cada canal.
4. Escribir un **shader spatial** que fije `METALLIC`, `ROUGHNESS` y `ALBEDO` por parámetro.
5. Comparar el comportamiento visual de un **metal** frente a un **dieléctrico** bajo la misma luz.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es PBR | Materiales consistentes bajo cualquier luz |
| 2 | Flujo metallic/roughness | Estándar de la industria y de Godot |
| 3 | Canal albedo | Color base sin luz ni sombras horneadas |
| 4 | Metallic y dieléctricos | Define si refleja el entorno o difunde color |
| 5 | Roughness | Controla lo pulido o áspero de la superficie |
| 6 | Normal y AO | Detalle y oclusión sin geometría extra |
| 7 | Conservación de energía | Evita materiales físicamente imposibles |

## 📖 Definiciones y características

- **PBR**: modelo de sombreado que aproxima cómo la luz interactúa realmente con las superficies. Clave: el mismo material se ve bien bajo cualquier iluminación.
- **Albedo**: color difuso puro, sin sombras ni brillos horneados. Clave: en Godot es `ALBEDO`, texturizado con `source_color`.
- **Metallic**: 0 = dieléctrico (plástico, madera), 1 = metal. Clave: en metal, el color viene del reflejo, no del difuso.
- **Roughness**: 0 = espejo, 1 = mate. Clave: dispersa el reflejo especular; controla el tamaño del brillo.
- **Normal map**: perturba la normal por textura para simular relieve. Clave: se asigna a `NORMAL_MAP` con `hint_normal`.
- **AO (oclusión ambiental)**: oscurece grietas donde la luz indirecta no llega. Clave: multiplica el ambient, no la luz directa.
- **Conservación de energía**: una superficie no refleja más luz de la que recibe. Clave: la BRDF de Godot ya la respeta por ti.
- **Dieléctrico**: material no metálico con reflejo especular tenue (~4%). Clave: metallic 0 y color en el difuso.

## 🧰 Herramientas y preparación

Usa **Godot 4.x**, proyecto 3D. Prepara una escena con un `Node3D`, dos `MeshInstance3D` con esferas (una para metal, otra para dieléctrico), un `DirectionalLight3D` y una `WorldEnvironment` con un cielo procedural: el reflejo del entorno es lo que hace lucir al metal. Puedes usar texturas PBR propias o colores planos. Consulta el [Standard Material 3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html) y la sección de PBR de los [Spatial shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html). Lo observable: dos esferas idénticas de forma pero con comportamiento de luz radicalmente distinto.

## 🧪 Laboratorio guiado

Primero con material estándar, luego con shader propio, para ver que ambos escriben los mismos canales.

**Paso 1 — Un StandardMaterial3D PBR.** Selecciona la primera esfera, crea un `StandardMaterial3D` y ajusta:

```gdscript
# Vía código (o hazlo en el inspector):
var mat := StandardMaterial3D.new()
mat.albedo_color = Color(0.9, 0.75, 0.4)   # oro
mat.metallic = 1.0
mat.roughness = 0.25
$EsferaMetal.material_override = mat
```

Si tienes mapas, arrástralos a Albedo, Metallic, Roughness, Normal Map y AO en el inspector, y activa cada canal.

**Paso 2 — La segunda esfera, dieléctrica.** Repite con metallic 0 para comparar:

```gdscript
var plastico := StandardMaterial3D.new()
plastico.albedo_color = Color(0.1, 0.4, 0.9)  # plástico azul
plastico.metallic = 0.0
plastico.roughness = 0.4
$EsferaPlastico.material_override = plastico
```

Ejecuta (F6): el oro refleja el cielo y apenas tiene color propio difuso; el plástico muestra su azul con un brillo pequeño y claro. Esa es la diferencia metal/dieléctrico.

**Paso 3 — Un shader spatial que escribe los canales PBR.** Crea un `ShaderMaterial` en una tercera esfera:

```glsl
shader_type spatial;

uniform vec4 color_albedo : source_color = vec4(0.9, 0.75, 0.4, 1.0);
uniform float metallic_param : hint_range(0.0, 1.0) = 1.0;
uniform float roughness_param : hint_range(0.0, 1.0) = 0.25;
uniform sampler2D normal_tex : hint_normal;
uniform sampler2D ao_tex : hint_default_white;

void fragment() {
	ALBEDO = color_albedo.rgb;
	METALLIC = metallic_param;
	ROUGHNESS = roughness_param;
	NORMAL_MAP = texture(normal_tex, UV).rgb;   // relieve por textura
	AO = texture(ao_tex, UV).r;                  // oclusión ambiental
}
```

**Paso 4 — Barrer roughness desde GDScript.** Anima el pulido para ver el efecto:

```gdscript
func _process(delta: float) -> void:
	var r: float = (sin(Time.get_ticks_msec() * 0.001) * 0.5) + 0.5
	$EsferaShader.get_active_material(0).set_shader_parameter("roughness_param", r)
```

Verás el reflejo pasar de espejo nítido (roughness 0) a un brillo difuso y amplio (roughness 1). Cambia `metallic_param` entre 0 y 1 y observa cómo el color propio aparece o desaparece.

## ✍️ Ejercicios

1. Pon la esfera-shader con metallic 1 y roughness 0 y compárala con un espejo real del entorno.
2. Sube roughness a 1 con metallic 1 y describe por qué parece metal cepillado.
3. Asigna un normal map real y confirma que el relieve reacciona al girar la luz.
4. Desactiva el AO (multiplica por 1.0) y compara las grietas con y sin oclusión.
5. Crea un material "cobre pulido" solo con uniforms de color, metallic y roughness.
6. Expón `metallic_param` en el inspector y crea tres presets: oro, plástico y goma mate.

## 📝 Reto verificable

Construye una fila de cinco esferas con el mismo shader, variando `roughness_param` de 0.0 a 1.0 en pasos iguales, todas metálicas, bajo un entorno con cielo. Añade una sexta esfera dieléctrica del mismo color para contraste.

**Criterio de aceptación**: la fila metálica muestra una transición clara de reflejo especular nítido (izquierda) a difuso (derecha); la esfera dieléctrica exhibe color difuso propio y un brillo pequeño, evidenciando la diferencia metallic/dieléctrico bajo la misma luz.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El metal se ve negro y sin reflejo | No hay entorno/cielo que reflejar; añade una `WorldEnvironment` con sky |
| El normal map se ve invertido o plano | Textura sin `hint_normal` o sin marcar como Normal Map al importar; corrígelo |
| El albedo trae sombras "pintadas" | Usaste una textura con luz horneada; el albedo debe ser color plano |
| Metallic a 0.5 se ve raro | Los valores intermedios casi no existen en la realidad; usa 0 o 1 salvo transiciones |
| El AO oscurece todo por igual | Estás multiplicándolo sobre la luz directa; el AO solo afecta al ambient |

## ❓ Preguntas frecuentes

**¿PBR es más lento?** Marginalmente; Godot lo tiene optimizado. La ganancia en consistencia visual compensa de sobra.

**¿Qué es "conservación de energía" en la práctica?** Que no puedes tener a la vez difuso fuerte y especular fuerte sin límite; la BRDF reparte la energía. Godot lo gestiona internamente.

**¿Metallic/roughness o specular/glossiness?** Godot usa metallic/roughness, el estándar más común y con menos parámetros que ajustar mal.

**¿Necesito siempre normal y AO?** No. Un color, metallic y roughness ya dan un material creíble; los mapas añaden detalle cuando lo necesitas.

## 🔗 Referencias

1. Godot Engine — Standard Material 3D: <https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html>
2. Godot Engine — Spatial shaders (canales PBR): <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html>
3. Godot Engine — Importing images (normal maps): <https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html>

## ➡️ Siguiente clase

[Clase 094 - Normal mapping y detalle de superficie](../094-normal-mapping-y-detalle-de-superficie/README.md)
