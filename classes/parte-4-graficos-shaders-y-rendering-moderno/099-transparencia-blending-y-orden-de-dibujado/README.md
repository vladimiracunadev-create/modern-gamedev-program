# Clase 099 — Transparencia, blending y orden de dibujado

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Godot Docs — Shading language / Spatial shader render modes*
> ⏱️ Duración estimada: **55 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Dominar la transparencia en Godot 4: la diferencia entre **alpha blending** y **alpha scissor/hash**, los modos de mezcla `blend_mix` y `blend_add`, el problema del **orden de dibujado** de las superficies translúcidas, y cómo controlarlo con `depth_draw`, `render_priority` y el descarte de fragmentos.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar por qué la transparencia depende del orden de dibujado y la profundidad.
2. Escribir shaders `canvas_item`/`spatial` con `ALPHA` y elegir `blend_mix` o `blend_add`.
3. Usar **alpha scissor** para eliminar artefactos de orden en bordes duros.
4. Ajustar `depth_draw_opaque` y `render_priority` para forzar el orden correcto.
5. Diferenciar cuándo usar aditivo (fuego) frente a mezcla normal (humo, cristal).

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Alpha blending clásico | Base de todo material translúcido |
| 2 | Alpha scissor / hash | Evita el problema de orden con recorte |
| 3 | `blend_mix` vs `blend_add` | Definen el aspecto de humo vs fuego |
| 4 | El problema del orden | Explica los artefactos de transparencias solapadas |
| 5 | `depth_draw` y depth write | Controla si el translúcido escribe profundidad |
| 6 | `render_priority` | Fuerza el orden entre materiales transparentes |
| 7 | Fresnel para bordes | Da realismo a cristales y burbujas |
| 8 | Coste de overdraw | Muchas capas transparentes son caras |

## 📖 Definiciones y características

- **Alpha blending**: el color final mezcla el fragmento con lo ya dibujado según `ALPHA`. Requiere ordenar de atrás hacia adelante.
- **Alpha scissor**: descarta el fragmento si `ALPHA` cae por debajo de un umbral; el resultado es opaco/recortado y no sufre problemas de orden.
- **`blend_mix`**: mezcla estándar `src*a + dst*(1-a)`; ideal para humo, vidrio, decals suaves.
- **`blend_add`**: suma `src + dst`; brilla y se satura hacia el blanco; ideal para fuego, magia, destellos.
- **Orden de dibujado**: las superficies transparentes se ordenan por su profundidad respecto a la cámara; un orden incorrecto produce que una capa lejana "tape" a una cercana.
- **`depth_draw_opaque`**: modo por defecto; los transparentes normalmente **no** escriben en el depth buffer para poder mezclarse.
- **`render_priority`**: entero por material; mayor prioridad se dibuja después (encima) entre transparentes.
- **Fresnel**: factor que aumenta hacia los bordes según el ángulo de vista; se calcula con `dot(NORMAL, VIEW)`.

## 🧰 Herramientas y preparación

Godot 4.x, renderizador Forward+. Prepara una escena con dos `MeshInstance3D` (dos quads o dos planos) que se solapen desde la cámara, para poder ver artefactos de orden. Crearás dos `ShaderMaterial`: uno para humo (`blend_mix`) y otro para fuego (`blend_add`). Ten abierto el editor de shaders de Godot.

- Shading language: <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html>
- Spatial shader (render modes): <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html>

## 🧪 Laboratorio guiado

Crearemos dos materiales translúcidos animados y resolveremos un artefacto de orden en vivo.

**Paso 1 — Shader de humo (`blend_mix`).** Crea un `MeshInstance3D` con un `QuadMesh` y asígnale un `ShaderMaterial` con este shader:

```glsl
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque, unshaded;

uniform vec4 color_humo : source_color = vec4(0.6, 0.6, 0.65, 1.0);
uniform float densidad : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D ruido;

void fragment() {
	float n = texture(ruido, UV + vec2(0.0, -TIME * 0.05)).r;
	ALBEDO = color_humo.rgb;
	// El humo se atenúa hacia los bordes del quad y con el ruido.
	float borde = smoothstep(0.5, 0.0, length(UV - vec2(0.5)));
	ALPHA = clamp(n * densidad * borde, 0.0, 1.0);
}
```

Asigna cualquier textura de ruido al uniform `ruido` (una `NoiseTexture2D`).

**Paso 2 — Shader de fuego (`blend_add`).** Duplica el material y cambia el render_mode y el color:

```glsl
shader_type spatial;
render_mode blend_add, cull_disabled, depth_draw_opaque, unshaded;

uniform sampler2D ruido;
uniform vec4 color_base : source_color = vec4(1.0, 0.5, 0.1, 1.0);

void fragment() {
	vec2 uv = UV + vec2(0.0, -TIME * 0.4);
	float n = texture(ruido, uv).r;
	// Gradiente vertical: más caliente abajo.
	float alto = smoothstep(1.0, 0.0, UV.y);
	float llama = clamp(n * alto * 1.5, 0.0, 1.0);
	ALBEDO = color_base.rgb;
	ALPHA = llama;
}
```

Con `blend_add` las zonas se **suman** y tiran al blanco: parece fuego. Compara lado a lado con el humo.

**Paso 3 — Provocar el problema de orden.** Coloca dos quads de humo casi en el mismo plano y muévete con la cámara. Verás que, según el ángulo, uno "recorta" al otro de forma incorrecta: eso es el artefacto de orden.

**Paso 4 — Alpha scissor.** Para un borde duro (una hoja, una reja) usa recorte en vez de mezcla:

```glsl
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D textura : source_color;
uniform float umbral : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 c = texture(textura, UV);
	if (c.a < umbral) {
		discard; // recorte: el fragmento no se dibuja y no depende del orden
	}
	ALBEDO = c.rgb;
}
```

Con `discard` no hay mezcla: desaparece el problema de orden para bordes definidos.

**Paso 5 — `render_priority`.** Si necesitas que el fuego se dibuje **siempre encima** del humo, en el inspector del material del fuego sube `Render Priority` (por ejemplo a `1`). Entre transparentes, mayor prioridad = se dibuja después.

**Resultado visible**: dos efectos (humo suave y fuego brillante) animados, y un caso de artefacto de orden corregido con scissor y prioridad.

## ✍️ Ejercicios

1. Cambia `blend_add` por `blend_mix` en el fuego y describe cómo pierde el brillo.
2. Anima `densidad` del humo con un uniform desde GDScript usando `set_shader_parameter`.
3. Usa `smoothstep` para que el borde del humo sea más o menos difuso; compara valores.
4. Aplica alpha scissor con `umbral` variable y observa cómo "crece" la silueta.
5. Coloca tres quads translúcidos y ajusta `render_priority` para un orden estable.
6. Añade un factor Fresnel al humo para que se vea más denso en los bordes.

## 📝 Reto verificable

Crea una fogata: un plano de **fuego** con `blend_add` y, detrás, un plano de **humo** con `blend_mix`, de modo que el fuego siempre se vea por delante del humo sin parpadeos ni artefactos de orden al girar la cámara 360°.

**Criterio de aceptación**: al orbitar la cámara alrededor de la fogata no aparecen recortes incorrectos entre humo y fuego; el fuego usa aditivo, el humo usa mezcla, y el orden está garantizado por `render_priority` documentado en el shader o el inspector.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Una capa transparente tapa mal a otra | Problema de orden; usa `render_priority` o alpha scissor |
| El fuego se ve gris y apagado | Estás en `blend_mix`; cambia a `blend_add` |
| Bordes de hojas con halo raro | Mezcla en bordes duros; usa `discard`/alpha scissor |
| El translúcido oculta objetos detrás | Escribe profundidad indebidamente; usa `depth_draw_opaque` (no `always`) |
| Parpadeo (z-fighting) entre dos planos | Están coplanares; sepáralos un poco o usa `render_priority` |
| FPS baja con muchas partículas alfa | Overdraw; reduce capas o tamaño de los quads |

## ❓ Preguntas frecuentes

**¿Por qué el motor no ordena perfecto los transparentes?** Ordena por objeto/profundidad del centro, no por píxel; superficies que se interpenetran no tienen un orden único correcto. Por eso existen scissor y prioridad.

**¿`discard` es gratis?** No; puede desactivar optimizaciones de profundidad temprana, pero evita el coste y los artefactos de la mezcla ordenada. Úsalo para bordes duros.

**¿Cuándo uso `depth_draw_always`?** Rara vez; solo cuando quieres que el translúcido escriba profundidad (por ejemplo, cristal opaco por dentro). Suele causar más problemas que soluciones.

**¿Aditivo sirve para vidrio?** No; el vidrio oscurece y refleja, así que va con `blend_mix` y Fresnel. El aditivo es para cosas que **emiten** luz.

## 🔗 Referencias

- Godot — Shading language: <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html>
- Godot — Spatial shader (render modes): <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html>
- Godot — StandardMaterial3D (transparencia): <https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html>

## ➡️ Siguiente clase

[Clase 100 - Agua, olas y superficies animadas](../100-agua-olas-y-superficies-animadas/README.md)
