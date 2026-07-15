# Clase 092 — Iluminación en shaders: Lambert, Phong y especular

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Godot Engine 4.x — Shading language y Custom lighting (spatial)*
> ⏱️ Duración estimada: **65 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Escribir tu propia iluminación dentro de un shader `spatial` de Godot 4 en lugar de dejar que el motor lo haga por ti. Implementarás el difuso de **Lambert** (`N·L`), el especular de **Blinn-Phong** (con el vector medio) y sumarás un término **ambient**, todo dentro de la función `light()`. Al final entenderás qué calcula cada línea de una BRDF simple y por qué una superficie se ve mate, brillante o metálica según esos términos.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar el modelo **difuso de Lambert** y calcular `N·L` en un shader.
2. Implementar **especular Blinn-Phong** usando el vector medio (halfway) y `pow`.
3. Escribir una función **`light()`** custom que reciba `NORMAL`, `LIGHT`, `VIEW` y `ATTENUATION`.
4. Sumar un término **ambient** para evitar zonas totalmente negras.
5. Exponer color, brillo y dureza especular como **uniforms** ajustables desde el editor.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Modelo de iluminación local | Base de todo sombreado en tiempo real |
| 2 | Difuso Lambert (N·L) | Define cómo cae la luz sobre superficies mate |
| 3 | Vectores N, L, V, H | Sin ellos no hay iluminación correcta |
| 4 | Especular Phong vs Blinn-Phong | El halfway es más estable y barato |
| 5 | Término ambient | Rellena sombras para que nada quede negro puro |
| 6 | La función `light()` en Godot | Punto de entrada para iluminación custom |
| 7 | Atenuación y color de luz | Integrar varias luces sin romper el resultado |

## 📖 Definiciones y características

- **Iluminación local**: se calcula por fragmento usando solo la luz directa, sin rebotes globales. Clave: rápida y suficiente para la mayoría de juegos.
- **Normal (N)**: vector perpendicular a la superficie. Clave: en `light()` se llama `NORMAL` y ya viene en espacio de vista.
- **Difuso Lambert**: intensidad proporcional a `max(dot(N, L), 0.0)`. Clave: no depende de dónde esté la cámara.
- **Vector medio (H)**: `normalize(L + V)`. Clave: corazón del especular Blinn-Phong.
- **Especular Blinn-Phong**: `pow(max(dot(N, H), 0.0), brillo)`. Clave: `brillo` alto = reflejo pequeño y nítido.
- **Ambient**: luz constante añadida a todo. Clave: simula el rebote indirecto de forma barata.
- **`ATTENUATION`**: factor de sombra/distancia que Godot pasa a `light()`. Clave: multiplícalo o las sombras no aparecen.
- **`DIFFUSE_LIGHT` / `SPECULAR_LIGHT`**: salidas que acumulas dentro de `light()`. Clave: Godot suma lo que escribas por cada luz.

## 🧰 Herramientas y preparación

Usa **Godot 4.x** con un proyecto 3D. Crea una escena con un `Node3D` raíz, un `MeshInstance3D` con una esfera (buena para ver el degradado de luz), un `DirectionalLight3D` y una `Camera3D`. Añade al `MeshInstance3D` un **material nuevo → Shader Material → Shader nuevo**. Ten a mano la referencia del [Shading language](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html) y de los [Spatial shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html), donde se documenta la función `light()`. Lo observable será la esfera pasando de mate a brillante según muevas la luz.

## 🧪 Laboratorio guiado

Construiremos, paso a paso, un shader con difuso Lambert + especular Blinn-Phong + ambient controlados por uniforms.

**Paso 1 — Declarar el shader y sus uniforms.** En el shader del `MeshInstance3D`:

```glsl
shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 color_base : source_color = vec4(0.8, 0.2, 0.2, 1.0);
uniform vec4 color_ambiente : source_color = vec4(0.05, 0.05, 0.08, 1.0);
uniform float brillo : hint_range(1.0, 128.0) = 32.0;
uniform float fuerza_especular : hint_range(0.0, 2.0) = 0.6;
```

**Paso 2 — Fijar el color en `fragment()`.** Solo pasamos el albedo; la luz la haremos nosotros.

```glsl
void fragment() {
	ALBEDO = color_base.rgb;
	// Apagamos el especular por defecto del motor; lo calculamos en light().
	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
}
```

**Paso 3 — Escribir la iluminación en `light()`.** Aquí vive todo el modelo.

```glsl
void light() {
	// Difuso Lambert: cuánto encara la superficie a la luz.
	float n_dot_l = max(dot(NORMAL, LIGHT), 0.0);
	vec3 difuso = ALBEDO * LIGHT_COLOR * n_dot_l * ATTENUATION;

	// Especular Blinn-Phong con el vector medio.
	vec3 halfway = normalize(LIGHT + VIEW);
	float n_dot_h = max(dot(NORMAL, halfway), 0.0);
	float esp = pow(n_dot_h, brillo) * fuerza_especular;
	vec3 especular = LIGHT_COLOR * esp * ATTENUATION;

	DIFFUSE_LIGHT += difuso;
	SPECULAR_LIGHT += especular;
}
```

**Paso 4 — Añadir el ambient.** El término constante se suma mejor en `fragment()` sobre `EMISSION` para que sea independiente de cada luz:

```glsl
void fragment() {
	ALBEDO = color_base.rgb;
	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
	EMISSION = color_base.rgb * color_ambiente.rgb; // relleno de sombras
}
```

Ejecuta la escena (F6) y rota el `DirectionalLight3D`. Verás la esfera con un lado iluminado (Lambert), un punto de brillo que se mueve con la cámara (especular) y sombras que nunca son negro absoluto (ambient). Sube `brillo` a 100 y el reflejo se vuelve un punto pequeño y nítido; bájalo a 4 y se ensancha como plástico mate.

## ✍️ Ejercicios

1. Cambia `brillo` en tiempo real desde GDScript con `set_shader_parameter("brillo", valor)` y observa el reflejo estrecharse.
2. Sustituye Blinn-Phong por Phong clásico (`reflect(-LIGHT, NORMAL)` contra `VIEW`) y compara el resultado.
3. Multiplica el ambient por `ALBEDO` variando su intensidad y explica qué zona cambia.
4. Añade un segundo `OmniLight3D` y confirma que `light()` se ejecuta y acumula por cada luz.
5. Expón la fuerza del difuso como uniform y demuestra qué pasa al ponerla en 0 (queda solo especular + ambient).
6. Recorta el especular a cero cuando `n_dot_l` sea 0 para evitar brillos en la cara oscura.

## 📝 Reto verificable

Crea un material "escudo de energía" con difuso tenue, un especular muy marcado (`brillo` ≥ 64) de color distinto al difuso, y un ambient azulado. El brillo especular debe seguir a la cámara al orbitar la esfera, y las caras que no reciben luz deben conservar el tinte ambient sin volverse negras.

**Criterio de aceptación**: al orbitar la cámara alrededor de la malla con la luz fija, el punto de brillo se desplaza sobre la superficie; al girar la luz, la frontera luz/sombra se mueve según `N·L`; y en ninguna orientación aparece negro puro (0,0,0).

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Todo se ve negro | Olvidaste sumar a `DIFFUSE_LIGHT`/`SPECULAR_LIGHT` o no hay luz en la escena; añade una y acumula |
| El especular ilumina la cara oscura | No recortaste con `n_dot_l`; multiplica el especular por `step(0.0, dot(NORMAL, LIGHT))` |
| Las sombras no afectan al brillo | Faltó multiplicar por `ATTENUATION`; inclúyelo en difuso y especular |
| El reflejo es enorme y lechoso | `brillo` demasiado bajo; súbelo (32–128) para un punto nítido |
| El color se ve lavado | Ambient demasiado fuerte; baja `color_ambiente` a valores ~0.05 |

## ❓ Preguntas frecuentes

**¿Por qué Blinn-Phong y no Phong?** Blinn-Phong usa el vector medio `H`, es más estable en ángulos rasantes y algo más barato. Da reflejos más realistas con menos artefactos.

**¿`NORMAL` y `LIGHT` están en qué espacio?** En `light()` de Godot ambos están en espacio de vista y ya normalizados, así que `dot(NORMAL, LIGHT)` es directamente el coseno.

**¿Puedo escribir `light()` sin `fragment()`?** Sí, pero conviene fijar `ALBEDO` en `fragment()`; `light()` lo lee para tintar el difuso.

**¿Esto sustituye a PBR?** Es un modelo didáctico. PBR (siguiente clase) añade conservación de energía y parámetros físicos; aquí ves el mecanismo interno.

## 🔗 Referencias

1. Godot Engine — Spatial shaders (función light): <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html>
2. Godot Engine — Shading language: <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html>
3. Godot Engine — Your first shader (3D): <https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_3d_shader.html>

## ⬅️ Clase anterior

[Clase 091 - Texturas en shaders: sampling, tiling y mezcla](../091-texturas-en-shaders-sampling-tiling-y-mezcla/README.md)

## ➡️ Siguiente clase

[Clase 093 - PBR: modelo físico de materiales (metallic/roughness)](../093-pbr-modelo-fisico-de-materiales-metallic-roughness/README.md)
