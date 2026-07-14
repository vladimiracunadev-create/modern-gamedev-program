# Clase 088 — El lenguaje de shaders de Godot: estructura y tipos

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Documentación del lenguaje de shaders de Godot 4 (Shading language)*
> ⏱️ Duración estimada: **50 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Dominar la **anatomía de un shader de Godot 4**: la declaración `shader_type`, las funciones de etapa (`vertex`, `fragment`, `light`), los tipos de datos (`float`, `vec2/3/4`, `mat`, `sampler2D`), los **uniforms** con sus *hints*, los **varyings** para pasar datos de vertex a fragment y el `render_mode`. Al terminar podrás leer cualquier shader ajeno sabiendo qué hace cada bloque, y escribir uno propio de tipo `canvas_item` que tiñe un sprite con un color que controlas desde GDScript.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Declarar el `shader_type` correcto según el objeto a sombrear.
- Distinguir las responsabilidades de `vertex()`, `fragment()` y `light()`.
- Usar los tipos escalares y vectoriales del lenguaje y sus constructores.
- Declarar `uniform` con hints (`source_color`, `hint_range`, `filter_linear`).
- Controlar un uniform desde GDScript con `set_shader_parameter`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | `shader_type` | Sin él el shader ni siquiera compila |
| 2 | Funciones de etapa | Definen dónde escribes cada tipo de lógica |
| 3 | Tipos escalares y vectoriales | Son el vocabulario básico de todo shader |
| 4 | Constructores y *swizzling* | Permiten armar y reordenar vectores con soltura |
| 5 | Uniforms y hints | Exponen parámetros ajustables desde el editor y el código |
| 6 | Varyings | Pasan datos calculados de vertex a fragment |
| 7 | `render_mode` | Ajusta el comportamiento global del material |
| 8 | Puente con GDScript | Permite animar el shader desde la lógica del juego |

## 📖 Definiciones y características

- **`shader_type`**: primera línea obligatoria que fija el dominio (`spatial`, `canvas_item`, `particles`, `sky`). Clave: cambia qué built-ins existen.
- **`vertex()`**: procesa cada vértice; puedes mover `VERTEX`. Clave: se ejecuta antes de la rasterización.
- **`fragment()`**: produce el color por píxel (`ALBEDO`/`COLOR`). Clave: aquí va casi todo el trabajo visual.
- **`light()`**: personaliza cómo la luz afecta al material. Clave: opcional; solo si quieres iluminación custom.
- **Tipos**: `float`, `int`, `bool`, `vec2/3/4`, `mat2/3/4`, `sampler2D`. Clave: los vectores admiten *swizzling* (`col.rgb`, `uv.xy`).
- **`uniform`**: variable de solo lectura fijada desde fuera del shader. Clave: es el canal para parametrizar y animar.
- **Hint**: anotación tras `:` que da semántica a un uniform (`source_color`, `hint_range`, `filter_linear`). Clave: activa el color picker o los sliders correctos.
- **`varying`**: variable que `vertex()` escribe y `fragment()` lee, interpolada por la GPU. Clave: transporta datos entre etapas.

## 🧰 Herramientas y preparación

Trabajaremos con un **shader `canvas_item`** aplicado a un `Sprite2D`, así que necesitas una imagen cualquiera (un PNG con transparencia va perfecto para notar el tinte). Abre Godot 4.x, crea una escena 2D y ten a mano el editor de shaders integrado. Como referencia permanente usa la [guía del lenguaje de shading de Godot](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html) y la lista de built-ins de [canvas_item](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html). No necesitas nada más que el editor.

## 🧪 Laboratorio guiado

Objetivo: teñir un sprite con un color controlado por uniform y animarlo desde GDScript.

**Paso 1 — Escena.** Crea una escena 2D con raíz `Node2D`. Añade un `Sprite2D` y arrástrale una textura en su propiedad **Texture**.

**Paso 2 — Material y shader.** Con el `Sprite2D` seleccionado, ve a **CanvasItem → Material → New ShaderMaterial**. Entra al ShaderMaterial y en **Shader** elige **New Shader**, tipo `canvas_item`, nómbralo `tinte.gdshader`.

**Paso 3 — Escribir el shader.** Analiza cada sección mientras la escribes:

```glsl
shader_type canvas_item;

// --- Uniforms: parámetros ajustables desde el Inspector y desde GDScript ---
uniform vec4 tinte : source_color = vec4(1.0, 0.4, 0.2, 1.0); // color picker
uniform float mezcla : hint_range(0.0, 1.0) = 0.5;            // slider 0..1

// --- Varying: dato calculado en vertex y usado en fragment ---
varying vec2 uv_local;

void vertex() {
    // Copiamos la UV para demostrar el paso de datos entre etapas.
    uv_local = UV;
}

void fragment() {
    // TEXTURE es la textura del sprite; la muestreamos con la UV.
    vec4 base = texture(TEXTURE, UV);
    // Mezclamos el color original con el tinte según 'mezcla'.
    vec3 color = mix(base.rgb, tinte.rgb, mezcla);
    COLOR = vec4(color, base.a); // conservamos el alpha original
}
```

Al guardar, el sprite se tiñe. Prueba mover el slider **mezcla** y el color **tinte** en el Inspector: verás el efecto en vivo.

**Paso 4 — Controlar desde GDScript.** Añade un script al `Sprite2D` para animar el tinte con el tiempo:

```gdscript
extends Sprite2D

func _process(delta: float) -> void:
    var t := (sin(Time.get_ticks_msec() / 500.0) + 1.0) / 2.0  # 0..1
    var mat := material as ShaderMaterial
    mat.set_shader_parameter("mezcla", t)
    mat.set_shader_parameter("tinte", Color(t, 0.4, 1.0 - t))
```

Ejecuta: el sprite pulsa entre su color original y el tinte, y el tinte cambia de matiz. El nombre del parámetro (`"mezcla"`, `"tinte"`) **debe coincidir exactamente** con el del uniform.

**Resultado visible:** un sprite cuyo color late y se desplaza controlado por código.

## ✍️ Ejercicios

1. Añade un uniform `float brillo : hint_range(0.0, 2.0) = 1.0` y multiplícalo por el color final.
2. Cambia el `shader_type` a `spatial` y observa qué errores aparecen: explica por qué `TEXTURE`/`COLOR` dejan de servir.
3. Usa *swizzling* para invertir los canales rojo y azul del color base (`base.bgr`).
4. Declara un `uniform vec2 desplazamiento` y súmalo a la UV antes de muestrear.
5. Desde GDScript, cambia el tinte al pulsar una tecla en vez de con el tiempo.
6. Añade un `render_mode blend_add;` y describe cómo cambia la mezcla del sprite.

## 📝 Reto verificable

Crea un shader `canvas_item` con **al menos tres uniforms** (un `source_color`, un `hint_range` y un `sampler2D` con `filter_linear`) y un script que modifique dos de ellos en tiempo de ejecución con `set_shader_parameter`.

**Criterio de aceptación**: el sprite reacciona visiblemente a los tres uniforms desde el Inspector, y al ejecutar la escena dos de esos uniforms cambian por código sin errores en consola; los nombres pasados a `set_shader_parameter` coinciden con los declarados.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| "shader_type debe ser la primera línea" | Pusiste código o un comentario mal ubicado antes; muévelo debajo |
| El color no se ve como picker | Falta el hint `: source_color` en el uniform `vec4` |
| `set_shader_parameter` no hace nada | El nombre no coincide con el uniform, o `material` no es ShaderMaterial |
| "TEXTURE no existe" | Estás en `shader_type spatial`; TEXTURE es built-in de `canvas_item` |
| El sprite pierde transparencia | Escribiste `COLOR.a = 1.0`; conserva `base.a` |
| El slider no aparece | El `hint_range` está mal escrito o falta el `=` con valor por defecto |

## ❓ Preguntas frecuentes

**¿Cuándo uso `spatial` y cuándo `canvas_item`?**
`spatial` para materiales 3D (mallas), `canvas_item` para 2D (sprites, controles, TileMap). El `shader_type` decide qué built-ins tienes.

**¿Qué diferencia hay entre un uniform y un varying?**
El uniform viene de fuera (editor/GDScript) y es igual para todo el objeto; el varying se calcula en `vertex()` y se interpola por fragmento.

**¿`set_shader_parameter` es caro?**
Es barato para animar valores por frame. Lo costoso sería recompilar el shader, cosa que no ocurre al cambiar uniforms.

**¿Puedo tener varias funciones además de vertex/fragment/light?**
Sí, puedes definir funciones auxiliares propias y llamarlas desde las de etapa, igual que en C.

## 🔗 Referencias

- [Lenguaje de shading de Godot 4](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html)
- [Shaders canvas_item — built-ins](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html)
- [Uniforms y su uso desde código](https://docs.godotengine.org/en/stable/tutorials/shaders/shaders_style_guide.html)
- [The Book of Shaders — uniforms](https://thebookofshaders.com/03/)

## ➡️ Siguiente clase

[Clase 089 - Vertex shaders: deformar geometría](../089-vertex-shaders-deformar-geometria/README.md)
