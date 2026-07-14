# Clase 091 — Texturas en shaders: sampling, tiling y mezcla

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Documentación de shaders de Godot 4 (uniforms sampler2D) + The Book of Shaders (texturas)*
> ⏱️ Duración estimada: **55 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Aprender a **leer texturas** dentro de un shader con `texture(sampler, uv)` y a manipular la UV para conseguir efectos: **tiling** (repetir con `UV * escala` y `fract`), **scroll** (desplazar con `UV + TIME`), **mezcla de dos texturas** con `mix` y una **máscara**, y **distorsión** de UV. Terminarás con un efecto tipo **lava o agua** que combina texturas en movimiento, la base de casi cualquier material animado de un juego.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Declarar uniforms `sampler2D` con hints de filtrado y muestrearlos con `texture`.
- Repetir una textura (tiling) escalando la UV y usar `fract` para envolverla.
- Animar una textura desplazando la UV con `TIME` (scroll).
- Mezclar dos texturas con `mix` controlado por una máscara.
- Distorsionar la UV con otra textura para efectos de calor/agua.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | `texture(TEXTURE, UV)` | Es la operación básica de leer color de una imagen |
| 2 | Uniforms `sampler2D` | Permiten pasar texturas adicionales al shader |
| 3 | Tiling | Repite detalle sin agrandar la imagen |
| 4 | Scroll con `TIME` | Da movimiento a superficies (agua, cintas) |
| 5 | Mezcla con `mix` y máscara | Combina materiales (tierra/hierba, óxido) |
| 6 | Distorsión de UV | Crea calor, refracción y ondas de agua |
| 7 | Filtrado y wrap | Controlan nitidez y cómo se repite la textura |

## 📖 Definiciones y características

- **`texture(sampler, uv)`**: lee el color (`vec4`) de una textura en la coordenada dada. Clave: es el muestreo fundamental.
- **`sampler2D` uniform**: canal para pasar una textura extra al shader. Clave: se asigna en el Inspector o por código.
- **Tiling**: multiplicar la UV por un factor para repetir la imagen. Clave: `UV * 4.0` repite 4×4 veces.
- **`fract(uv)`**: fuerza la UV al rango 0..1 repitiendo. Clave: envuelve el tiling de forma explícita.
- **Scroll**: sumar un desplazamiento animado a la UV (`UV + TIME * vel`). Clave: mueve la textura por la superficie.
- **Máscara**: textura o valor que dice cuánto de cada capa mostrar. Clave: alimenta el tercer argumento de `mix`.
- **`mix(a, b, t)`**: interpola entre `a` y `b` según `t` (0..1). Clave: mezcla colores o texturas.
- **Filtrado (`filter_linear`/`filter_nearest`)**: suaviza o mantiene píxeles duros al muestrear. Clave: `nearest` para pixel-art, `linear` para suave.

## 🧰 Herramientas y preparación

Necesitas **dos texturas**: una base (por ejemplo, un patrón de lava/roca) y otra que sirva de máscara o segunda capa (por ejemplo, grietas o nubes). Cualquier par de PNG te sirve para practicar. Trabajaremos con un shader `canvas_item` sobre un `Sprite2D` o `ColorRect`. Abre Godot 4.x y ten a mano el Inspector para arrastrar las texturas a los uniforms. Consulta cómo se declaran los uniforms de textura en la [referencia del lenguaje de Godot](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html#uniforms) y el capítulo de texturas en [The Book of Shaders](https://thebookofshaders.com/09/).

## 🧪 Laboratorio guiado

Objetivo: un efecto de lava/agua que mezcla dos texturas y hace scroll de una con el tiempo.

**Paso 1 — Escena.** Escena con `Node2D`. Añade un `Sprite2D` grande con cualquier textura (servirá como lienzo; la sustituiremos vía shader). Alternativamente usa un `ColorRect`.

**Paso 2 — Material y shader.** En el nodo: **Material → New ShaderMaterial → Shader → New Shader**, tipo `canvas_item`, nombre `lava.gdshader`.

**Paso 3 — Muestreo básico y tiling.**

```glsl
shader_type canvas_item;

uniform sampler2D textura_base : filter_linear, repeat_enable;
uniform float escala : hint_range(1.0, 10.0) = 3.0;

void fragment() {
    // Escalamos la UV para repetir (tiling) la textura 'escala' veces.
    vec2 uv = UV * escala;
    COLOR = texture(textura_base, uv);
}
```

Arrastra una textura al uniform **Textura Base** en el Inspector. Verás la imagen repetida `escala` veces. El hint `repeat_enable` permite que el tiling envuelva correctamente.

**Paso 4 — Scroll y mezcla con máscara.** Amplía el shader con una segunda textura y una máscara animada:

```glsl
shader_type canvas_item;

uniform sampler2D textura_base : filter_linear, repeat_enable;
uniform sampler2D textura_capa : filter_linear, repeat_enable;
uniform sampler2D mascara : filter_linear;
uniform float escala : hint_range(1.0, 10.0) = 3.0;
uniform float velocidad : hint_range(0.0, 2.0) = 0.3;
uniform vec4 tinte_calor : source_color = vec4(1.0, 0.5, 0.1, 1.0);

void fragment() {
    // Scroll: desplazamos la UV de cada capa con TIME a distinta velocidad.
    vec2 uv_a = UV * escala + vec2(TIME * velocidad, 0.0);
    vec2 uv_b = UV * escala + vec2(0.0, TIME * velocidad * 0.6);

    vec3 capa_a = texture(textura_base, uv_a).rgb;
    vec3 capa_b = texture(textura_capa, uv_b).rgb;

    // La máscara (canal rojo) decide cuánto se ve de cada capa.
    float m = texture(mascara, UV).r;
    vec3 mezcla = mix(capa_a, capa_b, m);

    // Tinte cálido para acentuar el aspecto de lava.
    mezcla *= tinte_calor.rgb;
    COLOR = vec4(mezcla, 1.0);
}
```

Asigna las tres texturas en el Inspector. Ejecuta: las capas se desplazan en direcciones distintas y se funden según la máscara, creando un flujo tipo lava.

**Paso 5 — Distorsión de UV (opcional).** Antes de muestrear `textura_base`, distorsiona su UV con la otra textura para dar ondulación:

```glsl
    float d = texture(textura_capa, UV + TIME * 0.05).r;
    vec2 uv_dist = uv_a + (d - 0.5) * 0.1; // empuja la UV según la textura
    vec3 capa_a = texture(textura_base, uv_dist).rgb;
```

La superficie ahora ondula como calor o agua.

**Resultado visible:** un material animado que fluye y se mezcla, controlable con escala, velocidad y tinte.

## ✍️ Ejercicios

1. Cambia el filtrado de `textura_base` a `filter_nearest` y explica el efecto en el detalle.
2. Usa `fract(UV * escala)` en lugar de solo `UV * escala` y compara el resultado en los bordes.
3. Anima el tinte con `TIME` para que la lava "palpite" entre naranja y rojo.
4. Invierte la máscara (`1.0 - m`) y observa cómo se intercambian las capas.
5. Haz que las dos capas hagan scroll en direcciones opuestas para más profundidad.
6. Desde GDScript, cambia `velocidad` con `set_shader_parameter` según una variable de gameplay.

## 📝 Reto verificable

Construye un **material de agua o lava en movimiento** que mezcle **dos texturas** mediante una **máscara** y aplique **scroll animado** con `TIME` a al menos una de ellas, con escala y velocidad ajustables por uniforms.

**Criterio de aceptación**: al ejecutar la escena, la superficie muestra dos texturas fundidas por la máscara y al menos una capa se desplaza de forma continua; cambiar los uniforms de escala y velocidad altera visiblemente el tiling y el movimiento sin recompilar.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La textura no se repite, se estira en el borde | Falta `repeat_enable` en el uniform o no aplicaste tiling |
| El sprite sale gris/negro | No asignaste la textura al uniform `sampler2D` en el Inspector |
| El scroll no se mueve | Olvidaste sumar `TIME` a la UV, o `velocidad` está en 0 |
| La mezcla ignora la máscara | Usaste un canal equivocado; verifica `.r`/`.g` según tu máscara |
| Pixel-art se ve borroso | Filtrado `linear`; cambia a `filter_nearest` |
| La distorsión "salta" en los bordes | La UV distorsionada se sale del rango; reduce la intensidad o usa `repeat_enable` |

## ❓ Preguntas frecuentes

**¿`TEXTURE` y un `sampler2D` uniform son lo mismo?**
`TEXTURE` es la textura propia del sprite (built-in en `canvas_item`); un uniform `sampler2D` es una textura extra que tú pasas para capas o máscaras.

**¿Por qué escalar la UV repite la textura?**
Porque muestrear en coordenadas mayores que 1 vuelve a recorrer la imagen desde 0 (con wrap activado), repitiéndola en mosaico.

**¿Qué hace `filter_linear` frente a `filter_nearest`?**
`linear` interpola entre téxeles y suaviza; `nearest` toma el téxel más cercano y conserva bordes duros, ideal para pixel-art.

**¿Puedo mezclar más de dos texturas?**
Sí: encadena `mix` o usa varias máscaras. Es la base de los materiales de terreno con múltiples capas.

## 🔗 Referencias

- [Uniforms y sampler2D en el lenguaje de Godot](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html)
- [Shaders canvas_item — built-ins de textura](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html)
- [The Book of Shaders — texturas](https://thebookofshaders.com/09/)
- [The Book of Shaders — ruido para máscaras](https://thebookofshaders.com/11/)

## ➡️ Siguiente clase

[Clase 092 - Iluminación en shaders: Lambert, Phong y especular](../092-iluminacion-en-shaders-lambert-phong-y-especular/README.md)
