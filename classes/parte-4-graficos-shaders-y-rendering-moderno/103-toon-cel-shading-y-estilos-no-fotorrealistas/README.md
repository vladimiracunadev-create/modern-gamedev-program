# Clase 103 — Toon/cel shading y estilos no fotorrealistas

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Godot Docs — Custom light function (`light()`) / Spatial shader*
> ⏱️ Duración estimada: **60 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Crear un look **no fotorrealista (NPR)** de estilo cómic/anime en Godot 4: cuantizar la iluminación en **bandas** dentro de la función `light()`, añadir un **rim light** para separar la silueta, y dibujar un **outline** con la técnica del *inverted hull* en `vertex()`.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar qué es el NPR y cuándo conviene frente al PBR realista.
2. Escribir una función `light()` que cuantice la difusa en bandas discretas.
3. Añadir un rim light basado en el ángulo de vista para realzar bordes.
4. Implementar un contorno con inverted hull (segundo material que infla la malla).
5. Exponer número de bandas, color y grosor del outline como uniforms.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | NPR vs PBR | Define el lenguaje visual del juego |
| 2 | La función `light()` | Permite reescribir cómo la luz afecta al color |
| 3 | Cuantizar en bandas | El rasgo central del cel shading |
| 4 | Rim light | Separa el personaje del fondo |
| 5 | Inverted hull outline | Técnica clásica de contorno en tiempo real |
| 6 | `cull_front` para el hull | Cómo se dibuja solo la cáscara trasera |
| 7 | Especular por pasos | Brillos "de dibujo" en vez de suaves |
| 8 | Uniforms de estilo | Ajustar el look sin recompilar |

## 📖 Definiciones y características

- **NPR (Non-Photorealistic Rendering)**: renderizado que busca un estilo artístico (cómic, acuarela, tinta) en vez del realismo físico.
- **`light()`**: función del shader spatial que se ejecuta por luz y define cómo contribuye al color; ideal para cel shading.
- **Cuantización (banding)**: convertir la iluminación continua en unos pocos niveles con `floor`/`step`/`smoothstep`.
- **`DIFFUSE_LIGHT`**: acumulador de la luz difusa que escribimos dentro de `light()`.
- **Rim light**: luz de borde que aparece donde la superficie mira de canto a la cámara; `1 - dot(NORMAL, VIEW)`.
- **Inverted hull**: se dibuja la malla dos veces; la segunda, inflada por la normal y con caras frontales descartadas (`cull_front`), forma el contorno.
- **`cull_front`**: descarta las caras frontales; deja ver la "cáscara" trasera inflada como outline.
- **`ATTENUATION`/`LIGHT_COLOR`**: entradas de `light()` con la atenuación y el color de la luz activa.

## 🧰 Herramientas y preparación

Godot 4.x, Forward+. Usa una malla con volumen (una esfera, un `torus` o un personaje simple) y una `DirectionalLight3D`. Necesitarás **dos** materiales: el toon principal y el material del outline (inverted hull). Se pueden aplicar como dos `Surface Material Override` si la malla tiene dos slots, o con un `MeshInstance3D` hijo que solo dibuje el contorno.

- Custom light function: <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html>
- Your first shader in 3D: <https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_shader_in_3d.html>

## 🧪 Laboratorio guiado

Construiremos el toon en tres capas: bandas de luz, rim, y contorno.

**Paso 1 — Toon con bandas en `light()`.** Crea un `ShaderMaterial` en la esfera con:

```glsl
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_toon;

uniform vec4 color_base : source_color = vec4(0.8, 0.3, 0.3, 1.0);
uniform int bandas : hint_range(2, 6) = 3;
uniform float fuerza_rim : hint_range(0.0, 1.0) = 0.5;
uniform vec4 color_rim : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	ALBEDO = color_base.rgb;
}

void light() {
	// Difusa cuantizada en bandas discretas.
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float pasos = float(bandas);
	float nivel = floor(ndotl * pasos) / pasos;
	// Un smoothstep estrecho suaviza levemente el salto entre bandas.
	nivel = mix(nivel, ndotl, 0.05);
	DIFFUSE_LIGHT += color_base.rgb * LIGHT_COLOR.rgb * nivel * ATTENUATION;
}
```

Con 3 bandas la esfera muestra tres tonos planos: eso es cel shading.

**Paso 2 — Añadir rim light.** Amplía `fragment()` para sumar el borde a la emisión (el rim no depende de la luz, solo del ángulo de vista):

```glsl
void fragment() {
	ALBEDO = color_base.rgb;
	float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	rim = smoothstep(0.6, 1.0, rim) * fuerza_rim;
	EMISSION = color_rim.rgb * rim;
}
```

Los bordes se iluminan y el objeto "salta" del fondo.

**Paso 3 — Outline por inverted hull.** Crea un segundo `ShaderMaterial` para el contorno. Este shader **infla** la malla por la normal y descarta las caras frontales, dejando solo la cáscara trasera como línea:

```glsl
shader_type spatial;
render_mode cull_front, unshaded;

uniform float grosor : hint_range(0.0, 0.1) = 0.03;
uniform vec4 color_outline : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void vertex() {
	// Empujar cada vértice hacia afuera a lo largo de su normal.
	VERTEX += NORMAL * grosor;
}

void fragment() {
	ALBEDO = color_outline.rgb;
}
```

Aplícalo como **segundo material**: la forma más simple es duplicar el `MeshInstance3D` como hijo, asignarle solo este material y dejarlo en la misma posición. Al dibujarse con `cull_front`, solo se ve el borde inflado detrás del objeto toon.

**Paso 4 — Ajustar con uniforms y GDScript.** Controla estilo en runtime:

```gdscript
extends MeshInstance3D
func _ready() -> void:
	var mat := get_active_material(0) as ShaderMaterial
	mat.set_shader_parameter("bandas", 4)
	mat.set_shader_parameter("fuerza_rim", 0.7)
```

**Paso 5 — Especular por pasos.** El `render_mode specular_toon` ya recorta el brillo; súbelo con `SPECULAR` o un `METALLIC` bajo para un destello "de dibujo" en vez de suave.

**Resultado visible**: una esfera (o personaje) con sombreado en bandas, borde iluminado y un contorno negro nítido: aspecto de dibujo animado.

## ✍️ Ejercicios

1. Cambia `bandas` de 2 a 6 y describe cómo se acerca al sombreado suave.
2. Ajusta el rango del `smoothstep` del rim para un borde más grueso o fino.
3. Cambia el color del outline y su `grosor`; observa cuándo se ve mal en cóncavos.
4. Aplica el toon a un modelo con partes cóncavas y describe los fallos del hull.
5. Añade una segunda luz y verifica que `light()` acumula ambas en bandas.
6. Haz que el color de banda oscura no sea negro puro sino un tinte frío (sombra azulada).

## 📝 Reto verificable

Aplica un estilo cel shading completo a un modelo: iluminación en **3 o más bandas** vía `light()`, rim light visible y un **outline** por inverted hull de grosor ajustable, todo parametrizado con uniforms.

**Criterio de aceptación**: el modelo muestra tonos planos por bandas (no un degradado suave), un borde iluminado que lo separa del fondo, y un contorno continuo alrededor de la silueta; cambiar `bandas`, `fuerza_rim` y `grosor` en el inspector modifica el look en tiempo real.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El sombreado sigue suave, sin bandas | No cuantizas en `light()`; usa `floor(ndotl * pasos) / pasos` |
| No aparece el contorno | El hull usa `cull_back`; cámbialo a `cull_front` e infla por la normal |
| Outline con huecos en aristas duras | Normales partidas en la malla; suaviza normales o usa outline por post-proceso |
| Rim demasiado agresivo | `smoothstep` con rango ancho; estrecha el intervalo y baja `fuerza_rim` |
| El contorno "come" la silueta | `grosor` excesivo; redúcelo hasta que sea una línea fina |
| Especular en gota suave | Falta `specular_toon`; añádelo al `render_mode` |

## ❓ Preguntas frecuentes

**¿Por qué usar `light()` y no solo `fragment()`?** Porque `light()` corre por cada luz con su color y atenuación; ahí puedes cuantizar la contribución de cada una y respetar sombras.

**¿El inverted hull funciona para todo?** Da buenos contornos en mallas convexas y de normales suaves; en aristas duras o zonas cóncavas puede fallar. Para casos difíciles se usa un outline por post-proceso (detección de bordes).

**¿Puedo controlar dónde cae el borde entre bandas?** Sí: en vez de `floor` uniforme puedes muestrear una textura de rampa (toon ramp) indexada por `ndotl` para un control artístico total.

**¿El rim depende de las luces?** En esta implementación no; se basa en el ángulo de vista y se suma como emisión, por eso funciona incluso a contraluz.

## 🔗 Referencias

- Godot — Spatial shader (light function): <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html>
- Godot — Shading language: <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html>
- Godot — Your first shader in 3D: <https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_shader_in_3d.html>

## ➡️ Siguiente clase

[Clase 104 - Compute shaders: cómputo en GPU](../104-compute-shaders-computo-en-gpu/README.md)
