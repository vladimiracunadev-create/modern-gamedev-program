# Clase 100 — Agua, olas y superficies animadas

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Godot Docs — Spatial shader (vertex/fragment) + técnica de olas Gerstner*
> ⏱️ Duración estimada: **60 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir un shader de agua `spatial` en Godot 4 que desplace vértices con **olas** (suma de senos / Gerstner) en `vertex()`, calcule el **color por profundidad** con un factor **Fresnel**, y anime las **normales** haciendo scroll de un normal map para dar sensación de superficie viva y con reflejos.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Desplazar vértices en `vertex()` combinando varias ondas senoidales.
2. Explicar la diferencia entre una ola senoidal simple y una ola de Gerstner.
3. Calcular un término Fresnel con `dot(NORMAL, VIEW)` y usarlo para el color.
4. Animar normales haciendo scroll de un normal map con `TIME`.
5. Exponer parámetros (amplitud, velocidad, color) como uniforms ajustables.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Desplazar `VERTEX` en `vertex()` | Es lo que crea el relieve de las olas |
| 2 | Suma de senos | Ondas creíbles combinando frecuencias |
| 3 | Olas de Gerstner | Crestas afiladas y movimiento circular realista |
| 4 | Recalcular normales | Sin ellas la iluminación de la ola es plana |
| 5 | Fresnel | Bordes reflectantes, centro transparente |
| 6 | Scroll de normal maps | Micro-oleaje y brillos animados |
| 7 | Color por profundidad | Aguas someras claras, profundas oscuras |
| 8 | Uniforms de ajuste | Iterar el look sin recompilar |

## 📖 Definiciones y características

- **`vertex()`**: función del shader que corre por vértice; ahí modificamos `VERTEX` para deformar la malla.
- **Suma de senos**: sumar varias ondas `sin` con distinta dirección, frecuencia y fase para un oleaje no repetitivo.
- **Ola de Gerstner**: modelo donde los puntos describen círculos; desplaza también en el plano horizontal, dando crestas puntiagudas y valles anchos.
- **Fresnel**: reflectividad que crece cuando miramos la superficie de canto; `pow(1.0 - dot(N, V), p)`.
- **Normal map scroll**: mover las UV del normal map con `TIME` para simular ondulaciones finas sin más geometría.
- **`ROUGHNESS`/`METALLIC`**: en agua, rugosidad baja y algo de reflejo dan aspecto húmedo.
- **`ALPHA` + `depth_draw`**: el agua es translúcida; combina transparencia con Fresnel.
- **Uniform `hint_range`**: permite mover parámetros con un deslizador en el inspector.

## 🧰 Herramientas y preparación

Godot 4.x, Forward+. Necesitas un `MeshInstance3D` con un `PlaneMesh` **subdividido** (Subdivide Width/Depth altos, p. ej. 100×100) para que las olas de vértice se vean; una malla sin subdivisiones no se deforma. Crea una `NoiseTexture2D` o usa un normal map de agua. Añade una `DirectionalLight3D` y un `WorldEnvironment` con cielo para tener reflejos.

- Spatial shader: <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html>
- Tutorial de shaders 3D: <https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_shader_in_3d.html>

## 🧪 Laboratorio guiado

Haremos el agua por capas: primero las olas, luego color y por último normales animadas.

**Paso 1 — Malla subdividida.** Crea el `PlaneMesh` (tamaño 20×20) con `Subdivide Width = 100` y `Subdivide Depth = 100`. Asígnale un `ShaderMaterial`.

**Paso 2 — Olas en `vertex()` (Gerstner simplificada).**

```glsl
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque;

uniform float amplitud : hint_range(0.0, 1.0) = 0.25;
uniform float frecuencia : hint_range(0.1, 4.0) = 1.2;
uniform float velocidad : hint_range(0.0, 4.0) = 1.5;

// Una ola de Gerstner: desplaza en X, Z y Y según dirección D.
vec3 gerstner(vec2 pos, vec2 D, float amp, float freq, float t) {
	float k = freq;
	float f = k * dot(D, pos) - velocidad * t;
	float a = amp;
	return vec3(D.x * a * cos(f), a * sin(f), D.y * a * cos(f));
}

void vertex() {
	vec2 p = VERTEX.xz;
	vec3 desp = vec3(0.0);
	desp += gerstner(p, normalize(vec2(1.0, 0.3)), amplitud, frecuencia, TIME);
	desp += gerstner(p, normalize(vec2(-0.4, 1.0)), amplitud * 0.5, frecuencia * 1.9, TIME);
	VERTEX += desp;
	// Aproximar la normal desde la pendiente de las olas.
	NORMAL = normalize(vec3(-desp.x, 1.0, -desp.z));
}
```

Ejecuta: la superficie ya ondula.

**Paso 3 — Color por profundidad y Fresnel (`fragment()`).** Añade debajo:

```glsl
uniform vec4 color_somero : source_color = vec4(0.1, 0.5, 0.6, 1.0);
uniform vec4 color_profundo : source_color = vec4(0.02, 0.12, 0.25, 1.0);
uniform float fuerza_fresnel : hint_range(0.0, 5.0) = 3.0;

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fuerza_fresnel);
	ALBEDO = mix(color_profundo.rgb, color_somero.rgb, fresnel);
	ROUGHNESS = 0.05;
	METALLIC = 0.0;
	ALPHA = mix(0.75, 1.0, fresnel); // más opaco en los bordes reflectantes
}
```

Los bordes en ángulo brillan y aclaran (Fresnel); el centro es más profundo y translúcido.

**Paso 4 — Normales animadas.** Añade micro-oleaje con un normal map en scroll:

```glsl
uniform sampler2D normal_map : hint_normal;
uniform float escala_normal : hint_range(0.0, 10.0) = 4.0;

// dentro de fragment(), antes de asignar ALBEDO:
void fragment_normales() {}
```

Integra en `fragment()`:

```glsl
	vec2 uv1 = UV * escala_normal + vec2(TIME * 0.03, TIME * 0.02);
	vec2 uv2 = UV * escala_normal * 1.7 - vec2(TIME * 0.02, TIME * 0.04);
	vec3 n1 = texture(normal_map, uv1).rgb;
	vec3 n2 = texture(normal_map, uv2).rgb;
	NORMAL_MAP = mix(n1, n2, 0.5); // dos capas para romper la repetición
```

**Paso 5 — Ajustar con uniforms.** Mueve `amplitud`, `frecuencia`, `velocidad`, `fuerza_fresnel` y los colores en el inspector hasta lograr el aspecto deseado. Prueba desde GDScript:

```gdscript
extends MeshInstance3D
func _ready() -> void:
	var mat := get_active_material(0) as ShaderMaterial
	mat.set_shader_parameter("amplitud", 0.35)
	mat.set_shader_parameter("velocidad", 2.0)
```

**Resultado visible**: un lago que ondula, con crestas afiladas, brillos en los bordes y micro-oleaje animado.

## ✍️ Ejercicios

1. Añade una tercera ola de Gerstner con otra dirección y compara el resultado.
2. Sube mucho `amplitud` y observa cómo, sin recalcular normales bien, la luz se ve plana.
3. Cambia el `color_profundo` a un verde turbio para simular un pantano.
4. Anima `fuerza_fresnel` desde GDScript y describe el efecto en los reflejos.
5. Reduce las subdivisiones del plano a 10×10 y explica por qué las olas se ven facetadas.
6. Añade **espuma**: aclara el color cuando `desp.y` supera un umbral (crestas).

## 📝 Reto verificable

Entrega un shader de agua con **al menos dos** olas de Gerstner, color por profundidad con Fresnel, y normales animadas con scroll, todo controlable por uniforms desde el inspector.

**Criterio de aceptación**: la superficie ondula de forma no repetitiva; al mover la cámara los bordes en ángulo reflejan/aclaran por Fresnel; y modificar `amplitud` y `velocidad` en el inspector cambia visiblemente el oleaje en tiempo real.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El agua no ondula | El plano no está subdividido; sube `Subdivide Width/Depth` |
| Iluminación plana pese a las olas | No recalculas `NORMAL`; deriva la normal del desplazamiento o usa normal map |
| El normal map no se nota | Falta `hint_normal` o `NORMAL_MAP` sin asignar; revisa el uniform |
| Todo brilla igual, sin Fresnel | Usaste una constante; calcula `pow(1 - dot(NORMAL,VIEW), p)` |
| Repetición obvia del oleaje | Una sola frecuencia; suma ondas con frecuencias/direcciones distintas |
| El agua tapa objetos sumergidos | `depth_draw` incorrecto o `ALPHA=1`; ajusta transparencia |

## ❓ Preguntas frecuentes

**¿Senos o Gerstner?** Los senos son más simples pero dan crestas redondeadas. Gerstner desplaza también horizontalmente y produce crestas puntiagudas más realistas.

**¿Por qué necesito tanta subdivisión?** El desplazamiento ocurre por vértice; con pocos vértices la ola se ve poligonal. Más subdivisiones = curva más suave (a más coste).

**¿Cómo consigo reflejos reales?** Baja `ROUGHNESS` y usa un cielo en el `WorldEnvironment`; para reflejos precisos añade un `ReflectionProbe` o SSR en el entorno.

**¿Puedo mover el agua sin tocar vértices?** Solo el micro-detalle, con normal maps en scroll. El relieve grande (olas) requiere desplazar `VERTEX`.

## 🔗 Referencias

- Godot — Spatial shader: <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html>
- Godot — Tu primer shader 3D: <https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_shader_in_3d.html>
- Godot — Shading language (built-ins): <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html>

## ➡️ Siguiente clase

[Clase 101 - Partículas en GPU y shaders de partículas](../101-particulas-en-gpu-y-shaders-de-particulas/README.md)
