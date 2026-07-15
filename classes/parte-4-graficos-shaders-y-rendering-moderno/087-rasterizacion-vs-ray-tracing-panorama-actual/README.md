# Clase 087 — Rasterización vs ray tracing: panorama actual

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Akenine-Möller et al., "Real-Time Rendering" (4ª ed.) + Pharr, Jakob & Humphreys, "Physically Based Rendering"*
> ⏱️ Duración estimada: **45 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Comprender las dos grandes familias de algoritmos para generar imágenes 3D: la **rasterización** (proyectar geometría y colorear píxeles, lo que hacen los juegos en tiempo real) y el **ray/path tracing** (seguir rayos de luz, base del cine y de los reflejos fotorrealistas). Al terminar sabrás por qué la rasterización domina el tiempo real, qué aporta el ray tracing, cuánto cuesta y cómo razonar el *presupuesto* de una escena comparando configuraciones de iluminación en Godot 4.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar con sus palabras cómo la rasterización convierte triángulos en píxeles.
- Explicar la idea central del ray tracing y del path tracing siguiendo rayos.
- Justificar cuándo conviene cada técnica según coste y calidad.
- Estimar el impacto en rendimiento de activar sombras y más luces en una escena.
- Leer pseudocódigo de una intersección rayo-esfera y entender qué calcula.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Cómo rasteriza la GPU | Es el método que usan tus juegos cada frame |
| 2 | Idea del ray tracing | Explica reflejos, refracciones y sombras exactas |
| 3 | Path tracing y ruido | Es el salto a fotorrealismo del cine y del render offline |
| 4 | Coste en tiempo real | Determina qué te puedes permitir a 60 FPS |
| 5 | RT híbrido en motores | Muchos juegos mezclan rasterización + rayos puntuales |
| 6 | Estado en Godot 4 | Sitúa qué puedes y qué no puedes hacer hoy |
| 7 | Intersección rayo-esfera | Es el "hola mundo" matemático del trazado de rayos |

## 📖 Definiciones y características

- **Rasterización**: proyecta cada triángulo a la pantalla y rellena los píxeles que cubre. Clave: es "por objeto", muy rápida y paralela.
- **Ray casting**: lanzar un rayo por píxel y ver qué objeto golpea. Clave: es "por píxel", el punto de partida del ray tracing.
- **Ray tracing**: además del primer impacto, lanza rayos secundarios para sombras y reflejos. Clave: calcula visibilidad exacta.
- **Path tracing**: sigue muchos rebotes aleatorios de luz por píxel y promedia. Clave: converge a fotorrealismo pero necesita muchas muestras.
- **Ruido (noise)**: granulado que aparece con pocas muestras en path tracing. Clave: se reduce con más rayos o con *denoisers*.
- **Presupuesto de frame**: milisegundos disponibles por cuadro (16.6 ms a 60 FPS). Clave: cada sombra o luz consume parte de él.
- **RT híbrido**: rasterizar la imagen y usar rayos solo para reflejos/sombras selectivos. Clave: equilibrio calidad/coste usado en consolas actuales.
- **Global illumination (GI)**: luz indirecta que rebota entre superficies. Clave: es cara; los motores la aproximan (SDFGI, lightmaps).

## 🧰 Herramientas y preparación

Trabajaremos en Godot 4.x con el renderer **Forward+**. No hay soporte de ray tracing por hardware nativo en el flujo estándar de shaders de Godot 4, así que el objetivo práctico es **medir el coste de la iluminación rasterizada** (sombras, número de luces) y razonar sobre él; el ray tracing lo abordaremos de forma conceptual y con pseudocódigo GLSL. Ten abierto el panel **Depurar → Monitores** para leer los tiempos. Referencias vivas: la [documentación de iluminación de Godot](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html) y el resumen conceptual de trazado en [Real-Time Rendering](https://www.realtimerendering.com/).

## 🧪 Laboratorio guiado

**Parte A — Comparar el coste de la iluminación (práctico).**

**Paso 1.** Crea una escena 3D con un plano (`MeshInstance3D` + `PlaneMesh`) como suelo y varias esferas encima (`SphereMesh`). Añade una `Camera3D`.

**Paso 2.** Añade una `DirectionalLight3D`. En su Inspector, deja **Shadow → Enabled** en *off*. Ejecuta y anota los milisegundos de frame en los monitores.

**Paso 3.** Activa **Shadow → Enabled** en la luz. Vuelve a ejecutar y anota el nuevo tiempo. Verás que las sombras rasterizadas (shadow mapping) cuestan tiempo extra: la GPU renderiza la escena una vez más desde la luz.

**Paso 4.** Añade tres o cuatro `OmniLight3D` con sombras. Anota el tiempo con cada luz añadida. Construye una pequeña tabla:

| Configuración | Tiempo de frame aprox. |
|---------------|------------------------|
| 1 luz, sin sombras | (tu medición) |
| 1 luz, con sombras | (tu medición) |
| 4 luces, con sombras | (tu medición) |

Razona: cada sombra añade pasadas de render; por eso los juegos limitan cuántas luces proyectan sombras.

**Parte B — Ray-sphere en pseudocódigo GLSL (conceptual).**

Este es el cálculo que haría un trazador de rayos para saber si un rayo golpea una esfera. Léelo y comenta qué hace cada línea:

```glsl
// Devuelve la distancia t al primer impacto, o -1.0 si no hay impacto.
// ro = origen del rayo, rd = dirección (normalizada)
// centro y radio definen la esfera.
float intersecta_esfera(vec3 ro, vec3 rd, vec3 centro, float radio) {
    vec3 oc = ro - centro;
    float a = dot(rd, rd);              // = 1.0 si rd está normalizada
    float b = 2.0 * dot(oc, rd);
    float c = dot(oc, oc) - radio * radio;
    float discriminante = b * b - 4.0 * a * c;
    if (discriminante < 0.0) {
        return -1.0;                    // el rayo no toca la esfera
    }
    return (-b - sqrt(discriminante)) / (2.0 * a); // impacto más cercano
}
```

Observa que es geometría de una ecuación cuadrática: si el **discriminante** es negativo, el rayo pasa de largo. Un rasterizador nunca hace este cálculo por píxel; por eso es más barato, pero tampoco te da reflejos exactos gratis.

**Resultado visible:** una escena iluminada cuyo tiempo de frame cambia de forma medible al activar sombras y añadir luces, más tu comprensión escrita del test rayo-esfera.

## ✍️ Ejercicios

1. Explica en tres frases por qué la rasterización es "por objeto" y el ray tracing "por píxel".
2. Con tus mediciones, calcula el sobrecoste porcentual de activar sombras en una luz.
3. Modifica el pseudocódigo para que devuelva también el punto de impacto (`ro + t * rd`).
4. Enumera dos efectos visuales que el ray tracing hace de forma natural y la rasterización aproxima con trucos.
5. Investiga qué es un *denoiser* y por qué el path tracing lo necesita en tiempo real.
6. Explica por qué a 60 FPS solo tienes ~16.6 ms por frame y qué implica para el número de luces con sombra.

## 📝 Reto verificable

Elabora una **tabla comparativa medida** de al menos cuatro configuraciones de iluminación (variando número de luces y sombras on/off) en una misma escena, e incluye un párrafo que explique la tendencia y en qué punto empezarías a preocuparte por el presupuesto de frame.

**Criterio de aceptación**: la tabla tiene mediciones reales tomadas de los monitores de Godot, muestra que las sombras y las luces adicionales aumentan el tiempo de frame, y el párrafo relaciona esas cifras con el límite de 16.6 ms para 60 FPS.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| No noto diferencia al activar sombras | La escena es trivial; añade más geometría y esferas para que el coste se note |
| "Voy a hacer ray tracing en el fragment shader" | Trazar toda la escena por píxel es carísimo; en tiempo real se usa RT híbrido y GI aproximada |
| El discriminante da resultados raros | `rd` no está normalizada; normalízala antes de llamar la función |
| Los FPS bajan a 5 con muchas luces | Demasiadas luces con sombra; limita cuántas proyectan sombras |
| Confundir path tracing con rasterización | Son familias distintas; path tracing sigue rebotes de luz, rasterización proyecta triángulos |
| Espero reflejos perfectos con rasterización | Necesitan trucos (screen-space reflections, probes); no salen "gratis" |

## ❓ Preguntas frecuentes

**¿Por qué los juegos no usan solo ray tracing si se ve mejor?**
Porque seguir suficientes rayos por píxel a 60 FPS aún es demasiado caro; se usa de forma híbrida y selectiva.

**¿Godot 4 hace ray tracing por hardware?**
El flujo estándar de shaders no expone RT por hardware. Godot ofrece GI aproximada (como SDFGI y lightmaps) sobre rasterización.

**¿Qué es "path tracing" frente a "ray tracing"?**
Path tracing es un ray tracing que sigue muchos rebotes aleatorios y promedia; produce iluminación global realista a cambio de mucho cómputo.

**¿El pseudocódigo rayo-esfera se usa en juegos?**
La misma matemática aparece en detección de colisiones y raycasts de gameplay, aunque el render de la imagen siga rasterizando.

## 🔗 Referencias

- [Luces y sombras en Godot 4](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
- [SDFGI: iluminación global en Godot](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_sdfgi.html)
- [Real-Time Rendering — recursos](https://www.realtimerendering.com/)
- [The Book of Shaders — formas y distancias](https://thebookofshaders.com/07/)

## ⬅️ Clase anterior

[Clase 086 - El pipeline de render moderno en profundidad](../086-el-pipeline-de-render-moderno-en-profundidad/README.md)

## ➡️ Siguiente clase

[Clase 088 - El lenguaje de shaders de Godot: estructura y tipos](../088-el-lenguaje-de-shaders-de-godot-estructura-y-tipos/README.md)
