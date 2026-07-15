# Clase 090 — Fragment shaders: color por píxel y UVs

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *The Book of Shaders (formas, distancias) + Documentación de shaders canvas_item de Godot 4*
> ⏱️ Duración estimada: **50 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Aprender a **pintar cada píxel de forma procedural** en la función `fragment()` usando las coordenadas `UV` (que van de 0 a 1). Sin ninguna textura, dibujarás un **degradado**, un **círculo** con `distance` y `step`, y un **patrón de tablero de ajedrez**. Estas tres técnicas son los ladrillos con los que se construyen máscaras, viñetas, íconos y efectos 2D más adelante.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Usar `UV` para generar color según la posición del píxel.
- Crear degradados lineales y radiales combinando componentes de la UV.
- Dibujar un círculo con `distance`/`length` y bordes con `step` o `smoothstep`.
- Construir patrones repetitivos con `floor`, `fract` y `mod`.
- Diferenciar bordes duros (`step`) de bordes suaves (`smoothstep`).

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | La función `fragment()` | Es donde se decide el color de cada píxel |
| 2 | El sistema UV (0..1) | Da a cada píxel una coordenada normalizada |
| 3 | Degradados | Primer efecto puramente procedural |
| 4 | Distancia y círculos | Base de máscaras radiales y viñetas |
| 5 | `step` vs `smoothstep` | Controlan bordes duros o antialiaseados |
| 6 | Patrones con `fract`/`floor` | Permiten repetir formas como el tablero |
| 7 | Composición de campos | Combinar formas para crear íconos y máscaras |

## 📖 Definiciones y características

- **`fragment()`**: se ejecuta por cada fragmento; asigna `COLOR` (en 2D). Clave: aquí ocurre todo el dibujo procedural.
- **`UV`**: coordenada normalizada del píxel, `(0,0)` a `(1,1)`. Clave: es tu "papel milimetrado" para pintar.
- **Degradado**: color que varía de forma continua con la posición. Clave: sale directo de usar `UV.x` o `UV.y` como factor.
- **`distance(a, b)` / `length(v)`**: distancia euclídea entre puntos. Clave: define círculos midiendo distancia al centro.
- **`step(borde, x)`**: devuelve 0 o 1 según `x` supere `borde`. Clave: crea límites nítidos sin transición.
- **`smoothstep(a, b, x)`**: transición suave de 0 a 1 entre `a` y `b`. Clave: da bordes antialiaseados.
- **`fract(x)`**: parte decimal de `x`. Clave: repite el rango 0..1 para crear celdas/patrones.
- **`floor(x)`**: redondea hacia abajo. Clave: identifica en qué celda del patrón está el píxel.

## 🧰 Herramientas y preparación

Trabajaremos con un shader `canvas_item` sobre un `ColorRect` (un rectángulo de UI que ocupa área y tiene UV de 0 a 1), ideal porque no necesita textura. Abre Godot 4.x, crea una escena con un nodo `Control` o `Node2D` y añade un `ColorRect` grande. Ten a mano la sección de funciones GLSL de la [referencia del lenguaje de Godot](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html#built-in-functions) y los capítulos de formas de [The Book of Shaders](https://thebookofshaders.com/07/).

## 🧪 Laboratorio guiado

Objetivo: un solo shader que muestre degradado, círculo y tablero, seleccionable con un uniform.

**Paso 1 — Escena.** Escena con raíz `Control`. Añade un `ColorRect`, ponle un tamaño amplio (por ejemplo 512×512) con anclas al centro.

**Paso 2 — Material y shader.** En el `ColorRect`: **Material → New ShaderMaterial → Shader → New Shader**, tipo `canvas_item`, nombre `procedural.gdshader`.

**Paso 3 — Degradado.** Empieza con lo más simple:

```glsl
shader_type canvas_item;

void fragment() {
    // UV.x va de 0 (izquierda) a 1 (derecha): degradado horizontal.
    vec3 color = vec3(UV.x);
    COLOR = vec4(color, 1.0);
}
```

Verás una rampa de negro a blanco. Cambia a `vec3(UV.x, UV.y, 0.5)` para un degradado de dos ejes con color.

**Paso 4 — Círculo con distancia y step.** Sustituye `fragment()`:

```glsl
shader_type canvas_item;

uniform float radio : hint_range(0.0, 0.5) = 0.3;
uniform vec4 color_figura : source_color = vec4(1.0, 0.8, 0.1, 1.0);

void fragment() {
    // Distancia del píxel al centro (0.5, 0.5).
    float d = distance(UV, vec2(0.5));
    // step: 1.0 dentro del radio, 0.0 fuera (borde duro).
    float dentro = 1.0 - step(radio, d);
    // Alternativa suave (borde antialiaseado):
    // float dentro = 1.0 - smoothstep(radio - 0.01, radio + 0.01, d);
    COLOR = vec4(color_figura.rgb, color_figura.a * dentro);
}
```

Aparece un círculo. Descomenta la línea de `smoothstep` y compara: el borde deja de escalonarse.

**Paso 5 — Tablero de ajedrez.** Reemplaza `fragment()`:

```glsl
shader_type canvas_item;

uniform float casillas : hint_range(1.0, 20.0) = 8.0;

void fragment() {
    // Escalamos la UV y tomamos el índice entero de cada celda.
    vec2 celda = floor(UV * casillas);
    // Suma par/impar => patrón alternado.
    float tono = mod(celda.x + celda.y, 2.0);
    COLOR = vec4(vec3(tono), 1.0);
}
```

Obtienes un tablero de `casillas` × `casillas`. Súbelo o bájalo desde el Inspector.

**Resultado visible:** tres efectos procedurales (degradado, círculo suave y tablero) generados solo con matemática sobre `UV`.

## ✍️ Ejercicios

1. Convierte el degradado horizontal en radial usando `distance(UV, vec2(0.5))` como factor.
2. Anima el radio del círculo con `TIME` para que lata.
3. Dibuja un anillo (círculo hueco) restando dos `smoothstep` de radios distintos.
4. Colorea el tablero con dos colores custom en vez de blanco/negro usando `mix`.
5. Desplaza el tablero con `TIME` sumándolo a `UV` antes del `floor`.
6. Combina círculo + tablero: usa el círculo como máscara del patrón.

## 📝 Reto verificable

Crea un **"semáforo procedural"**: tres círculos (rojo, amarillo, verde) dibujados con `distance`/`smoothstep` sobre un `ColorRect`, cada uno en su posición, con bordes suaves y sin usar ninguna textura.

**Criterio de aceptación**: se ven tres círculos nítidos y antialiaseados en las posiciones correctas; los bordes usan `smoothstep` (no escalonan) y todo el dibujo se genera en `fragment()` a partir de `UV`, sin `sampler2D`.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El círculo se ve cuadrado/escalonado | Usaste `step`; cambia a `smoothstep` para suavizar el borde |
| Todo el rect es de un color plano | No usaste `UV` en el cálculo; el color no depende de la posición |
| El tablero se ve como líneas, no cuadros | Olvidaste `floor`; sin él `fract`/`mod` no forman celdas |
| El círculo aparece descentrado | Mediste distancia a `vec2(0.0)`; usa `vec2(0.5)` para el centro |
| No hay transparencia donde debería | El `COLOR.a` está fijo en 1.0; multiplícalo por la máscara |
| `mod` da resultados inesperados | Recuerda que trabaja con floats; asegúrate de escalar la UV antes |

## ❓ Preguntas frecuentes

**¿Por qué la UV va de 0 a 1 y no en píxeles?**
Es una convención normalizada: así el shader funciona igual sin importar la resolución del rectángulo o la textura.

**¿`step` o `smoothstep` para bordes?**
`step` da un corte duro (útil para máscaras binarias); `smoothstep` interpola y evita el aliasing en bordes curvos.

**¿Puedo dibujar cualquier forma solo con matemática?**
Sí. Combinando distancias, `step`/`smoothstep` y operaciones lógicas (min/max) puedes construir campos de distancia (SDF) para casi cualquier figura.

**¿Esto sirve en 3D también?**
El mismo razonamiento sobre UV aplica en shaders `spatial`; aquí usamos `canvas_item` por comodidad para ver el resultado 2D.

## 🔗 Referencias

- [Funciones integradas del lenguaje de shaders de Godot](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html)
- [The Book of Shaders — dibujar formas](https://thebookofshaders.com/07/)
- [The Book of Shaders — patrones](https://thebookofshaders.com/09/)
- [Tu primer shader canvas_item — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_canvasitem_shader.html)

## ⬅️ Clase anterior

[Clase 089 - Vertex shaders: deformar geometría](../089-vertex-shaders-deformar-geometria/README.md)

## ➡️ Siguiente clase

[Clase 091 - Texturas en shaders: sampling, tiling y mezcla](../091-texturas-en-shaders-sampling-tiling-y-mezcla/README.md)
