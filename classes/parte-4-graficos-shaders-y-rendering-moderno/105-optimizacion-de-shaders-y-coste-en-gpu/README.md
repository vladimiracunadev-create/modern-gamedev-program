# Clase 105 — Optimización de shaders y coste en GPU

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Akenine-Möller et al., "Real-Time Rendering" (4ª ed.) + Documentación de optimización y depuración de Godot 4*
> ⏱️ Duración estimada: **50 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Aprender **por qué un shader cuesta lo que cuesta** y cómo bajar ese coste sin perder calidad visible. Al terminar sabrás que el fragment se ejecuta por cada píxel, entenderás el impacto del **overdraw**, los **branches** dinámicos y los **texture lookups**, sabrás mover cálculos de fragment a vertex, usar precisión reducida (`mediump`) y **medir** el tiempo de GPU con el monitor de rendimiento de Godot 4 para confirmar que tu optimización realmente sirvió.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar por qué el fragment shader domina el coste al crecer la resolución.
- Identificar overdraw, branches divergentes y lookups de textura como focos de coste.
- Refactorizar un cálculo constante por vértice moviéndolo de `fragment()` a `vertex()`.
- Reemplazar un `if` costoso por funciones aritméticas (`mix`, `step`, `smoothstep`).
- Medir el tiempo de GPU por frame y comparar antes/después de optimizar.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | El fragment corre por píxel | A 1080p son ~2 millones de ejecuciones por frame |
| 2 | Overdraw | Píxeles dibujados y luego tapados: trabajo desperdiciado |
| 3 | Branches dinámicos | La divergencia entre hilos serializa el warp y cuesta |
| 4 | Texture lookups | El acceso a memoria de textura es lento; menos es más |
| 5 | Precisión (`mediump`) | Menos bits = más throughput donde no se nota |
| 6 | Vertex vs fragment | Lo constante por vértice no debe recalcularse por píxel |
| 7 | Interpolación `varying` | Pasar datos precomputados del vertex al fragment |
| 8 | Medir el tiempo de GPU | Sin medir, "optimizar" es adivinar |

## 📖 Definiciones y características

- **Coste de fragment**: tiempo total = coste por píxel × número de píxeles cubiertos. Clave: crece con la resolución y el overdraw.
- **Overdraw**: dibujar varias veces el mismo píxel por capas superpuestas. Clave: transparencias y partículas lo disparan.
- **Branch divergente**: cuando hilos vecinos toman ramas distintas de un `if`. Clave: la GPU ejecuta ambas ramas y descarta.
- **Texture lookup**: lectura de un téxel con `texture()`. Clave: cada muestreo tiene latencia; encadenarlos duele.
- **`mediump`**: calificador de precisión media (16 bits). Clave: acelera en GPUs móviles donde `highp` es caro.
- **`varying`**: valor calculado en vertex e interpolado hacia fragment. Clave: mueve trabajo de por-píxel a por-vértice.
- **`smoothstep`/`step`/`mix`**: funciones sin ramas que sustituyen a `if`. Clave: producen transiciones sin divergencia.
- **Tiempo de GPU**: milisegundos que la tarjeta tarda en el frame. Clave: es la métrica que hay que bajar, no las FPS a ojo.

## 🧰 Herramientas y preparación

Trabajarás sobre una escena 3D con un plano o quad grande a pantalla completa para amplificar el coste de fragment. Usarás el monitor **Depurar → Monitores** de Godot 4 y, en concreto, la métrica de tiempo de render. Para lecturas más precisas del tiempo de GPU, activa **Project Settings → Debug → Settings → Frame Profiler** o consulta `Performance.get_monitor(Performance.TIME_PROCESS)` y los monitores de render. Ten a mano la [guía de optimización de shaders de Godot](https://docs.godotengine.org/en/stable/tutorials/performance/index.html). Idealmente ejecuta a resolución alta (por ejemplo ventana grande) para que las diferencias sean visibles.

## 🧪 Laboratorio guiado

Partimos de un shader **deliberadamente caro** y lo optimizamos por etapas, midiendo cada paso.

**Paso 1 — Escena amplificadora.** Crea un `MeshInstance3D` con un `PlaneMesh` grande orientado hacia la cámara (o un `QuadMesh`) que ocupe casi toda la pantalla. Así el fragment se ejecuta en muchísimos píxeles y el coste es medible.

**Paso 2 — El shader costoso.** Asigna un `ShaderMaterial` con este shader. Tiene tres pecados: un branch por píxel, lookups repetidos y un cálculo constante hecho por píxel.

```glsl
shader_type spatial;

uniform sampler2D textura_base;
uniform float umbral = 0.5;

void fragment() {
    // PECADO 1: cálculo constante recomputado por píxel.
    float energia = pow(2.0, 3.0) * 0.125; // siempre vale 1.0

    // PECADO 2: cuatro lookups a la misma textura.
    vec3 c1 = texture(textura_base, UV).rgb;
    vec3 c2 = texture(textura_base, UV + vec2(0.01, 0.0)).rgb;
    vec3 c3 = texture(textura_base, UV + vec2(0.0, 0.01)).rgb;
    vec3 c4 = texture(textura_base, UV + vec2(0.01, 0.01)).rgb;
    vec3 color = (c1 + c2 + c3 + c4) * 0.25;

    // PECADO 3: branch dinámico por píxel.
    if (color.r > umbral) {
        color = color * 1.5;
    } else {
        color = color * 0.5;
    }

    ALBEDO = color * energia;
}
```

**Paso 3 — Medir la línea base.** Ejecuta la escena y abre **Depurar → Monitores**. Anota el tiempo de render/GPU por frame con la ventana grande. Este número es tu referencia.

**Paso 4 — Quitar el branch.** Sustituye el `if/else` por una mezcla aritmética con `mix` y `step`, que no divergen:

```glsl
    // Sin branch: factor = 1.5 si r>umbral, si no 0.5.
    float factor = mix(0.5, 1.5, step(umbral, color.r));
    color *= factor;
```

**Paso 5 — Reducir lookups y precomputar.** Un solo lookup suele bastar para el look; y el valor "energia" es constante, así que sale del shader:

```glsl
shader_type spatial;

uniform sampler2D textura_base : source_color;
uniform float umbral = 0.5;

void fragment() {
    // Un único texture lookup en vez de cuatro.
    vec3 color = texture(textura_base, UV).rgb;

    // Branch reemplazado por aritmética.
    float factor = mix(0.5, 1.5, step(umbral, color.r));

    // 'energia' era constante (1.0): eliminado.
    ALBEDO = color * factor;
}
```

**Paso 6 — Mover lo constante por vértice.** Si necesitaras un valor que depende de la posición del objeto pero no del píxel (por ejemplo un tinte por altura), calcúlalo en `vertex()` y pásalo con un `varying`:

```glsl
shader_type spatial;

varying float tinte; // interpolado del vertex al fragment

void vertex() {
    // Se calcula una vez por vértice, no por píxel.
    tinte = clamp(VERTEX.y * 0.5 + 0.5, 0.0, 1.0);
}

void fragment() {
    ALBEDO = vec3(tinte, 0.4, 1.0 - tinte);
}
```

**Paso 7 — Medir de nuevo.** Ejecuta y compara el tiempo de GPU con tu línea base del Paso 3. Deberías ver una bajada clara: menos lookups y sin branch por píxel.

**Resultado observable:** el mismo (o casi el mismo) aspecto visual, pero con un tiempo de render por frame menor en el monitor. La optimización se demuestra con el número, no con la sensación.

## ✍️ Ejercicios

1. Duplica la resolución de la ventana y observa cómo escala el tiempo de fragment; relaciónalo con "corre por píxel".
2. Vuelve a poner los cuatro lookups y mide: ¿cuántos ms cuesta cada lookup extra?
3. Sustituye un `if` de tu propio shader por `smoothstep` y compara el aspecto del borde.
4. Añade un `QuadMesh` semitransparente encima del plano y observa el overdraw en el monitor.
5. Marca un `varying` como `mediump` y razona dónde se nota (o no) la pérdida de precisión.
6. Precomputa en un uniform un valor que hoy calculas por píxel y mide la diferencia.

## 📝 Reto verificable

Toma un shader con al menos **tres lookups de textura y un branch por píxel** y entrégalo optimizado a **un lookup y cero branches dinámicos**, conservando un aspecto visualmente equivalente. Aporta las dos mediciones de tiempo de GPU (antes y después) tomadas del monitor de Godot.

**Criterio de aceptación**: el shader optimizado se ve equivalente al original (captura comparativa), no contiene `if` dependiente de datos por píxel, y el tiempo de render por frame medido es **menor** que la línea base en la misma resolución y escena.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| "Optimicé pero no cambió nada" | No medías el cuello real; el coste estaba en overdraw o en la CPU, no en tu shader |
| El branch sigue costando | Reemplaza `if` dependiente de datos por `mix`/`step`/`smoothstep` |
| FPS parecen iguales | Estás capado por VSync; mira el **tiempo de GPU**, no las FPS |
| Banding tras usar `mediump` | La precisión media no basta ahí; vuelve a `highp` en ese cálculo |
| Se ve peor tras quitar lookups | Quitaste muestreos necesarios; conserva los que aportan al look |
| Coste sube con transparencias | Overdraw: reduce capas, área del quad o usa `render_mode` opaco donde puedas |

## ❓ Preguntas frecuentes

**¿Por qué el fragment shader es normalmente el más caro?**
Porque se ejecuta una vez por cada fragmento cubierto. A resoluciones altas eso son millones de ejecuciones por frame; el vertex corre muchísimas menos veces.

**¿Todos los `if` son malos en un shader?**
No. Un `if` sobre un **uniform** (igual para todos los píxeles) es barato. El caro es el que depende de datos que varían entre píxeles vecinos y provoca divergencia.

**¿`mediump` siempre acelera?**
Ayuda sobre todo en GPUs móviles. En escritorio el impacto es menor y arriesgas *banding*; úsalo donde la precisión no se note (colores, no posiciones).

**¿Cómo sé si mi problema es overdraw?**
Sube el tiempo cuando hay capas transparentes o partículas apiladas. Reduce el área dibujada o el número de capas y observa si el tiempo de GPU baja.

## 🔗 Referencias

- [Optimización de rendimiento — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/performance/index.html)
- [Depuración y monitores de rendimiento — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/the_profiler.html)
- [Lenguaje de shaders de Godot: precisión y funciones](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html)
- [Real-Time Rendering — sitio oficial del libro](https://www.realtimerendering.com/)

## ⬅️ Clase anterior

[Clase 104 - Compute shaders: cómputo en GPU](../104-compute-shaders-computo-en-gpu/README.md)

## ➡️ Siguiente clase

[Clase 106 - Herramientas visuales: VisualShader y Shader Graph](../106-herramientas-visuales-visualshader-y-shader-graph/README.md)
