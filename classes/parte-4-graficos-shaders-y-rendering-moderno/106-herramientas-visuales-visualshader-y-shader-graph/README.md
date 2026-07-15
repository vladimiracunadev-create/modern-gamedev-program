# Clase 106 — Herramientas visuales: VisualShader y Shader Graph

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Documentación de VisualShader de Godot 4 + Referencia de nodos del editor de shaders*
> ⏱️ Duración estimada: **45 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Dominar el **VisualShader** de Godot 4: el editor de nodos que genera un shader sin escribir código. Al terminar sabrás cuándo conviene el grafo frente al código, reconocerás los nodos más comunes (entradas, texturas, aritmética, `Mix`, `Fresnel`), sabrás exponer **uniforms visuales**, leerás el **código generado** para entender la equivalencia con el lenguaje de Godot, y trazarás el paralelo conceptual con **Shader Graph de Unity** y **el material graph de Unreal**.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Crear un `VisualShader` de tipo spatial o canvas_item y conectar nodos hasta una salida.
- Elegir entre grafo visual y código según legibilidad, colaboración y complejidad.
- Usar nodos comunes: entradas (`UV`, `Time`), `Texture2D`, `Mix`, `Vector`, `Fresnel`.
- Exponer parámetros como uniforms visuales y controlarlos desde el Inspector o código.
- Leer el shader generado y mapear cada nodo a su línea equivalente en texto.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es un VisualShader | Genera el mismo shader que el código, con nodos |
| 2 | Grafo vs código | Cada enfoque gana en distintos contextos de equipo |
| 3 | Nodos de entrada | `UV`, `Time`, `Normal` alimentan el grafo |
| 4 | Nodos de operación | `Mix`, `Add`, `Multiply`, `Fresnel` construyen el efecto |
| 5 | Uniforms visuales | Exponen parámetros ajustables sin tocar nodos |
| 6 | Nodos de salida | `Output` define `ALBEDO`, `ALPHA`, etc. |
| 7 | Leer el código generado | Confirma qué produce el grafo y ayuda a aprender |
| 8 | Paralelo con Unity/Unreal | El concepto de grafo de materiales es transversal |

## 📖 Definiciones y características

- **VisualShader**: recurso de Godot que representa un shader como grafo de nodos. Clave: al guardarse genera código de shader real.
- **Nodo**: caja con entradas y salidas que ejecuta una operación. Clave: se conectan puertos compatibles (float, vec2, vec3).
- **Puerto**: conector tipado de un nodo. Clave: unir tipos incompatibles requiere un nodo de conversión.
- **Uniform visual**: nodo que expone un parámetro editable desde fuera. Clave: equivale a `uniform` en código y aparece en el Inspector.
- **Nodo Output**: destino final del grafo (`ALBEDO`, `ALPHA`, `EMISSION`). Clave: sin conexión a él, no se ve nada.
- **`Mix` (lerp)**: interpola entre dos valores según un factor. Clave: base de degradados y disoluciones.
- **`Fresnel`**: intensifica el borde según el ángulo de vista. Clave: da brillo de contorno con un solo nodo.
- **Código generado**: el shader de texto que Godot escribe desde el grafo. Clave: se puede leer para verificar y aprender.

## 🧰 Herramientas y preparación

Trabajarás dentro del editor de Godot 4, sin salir a un archivo `.gdshader`. Crea un `ShaderMaterial` y, en su propiedad **Shader**, elige **New VisualShader**. Se abre el panel de grafo en la parte inferior; con clic derecho o el botón **Add Node** insertas nodos. Ten a mano la lista de nodos disponibles en la [documentación de VisualShader de Godot](https://docs.godotengine.org/en/stable/tutorials/shaders/visual_shaders.html). Para el paralelo conceptual, es útil ojear la [documentación de Shader Graph de Unity](https://docs.unity3d.com/Packages/com.unity.shadergraph@latest). No necesitas escribir código salvo para leer el que Godot genera automáticamente.

## 🧪 Laboratorio guiado

Reconstruiremos un **degradado con disolución** primero en código y luego con VisualShader, comparando ambos.

**Paso 1 — La versión en código (referencia).** Crea un `MeshInstance3D` con un `PlaneMesh` y un `ShaderMaterial`. Como referencia, este es el efecto que buscamos: un degradado vertical sobre las UV que se "disuelve" según un uniform.

```glsl
shader_type spatial;

uniform float corte : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    // Degradado vertical usando la coordenada V.
    float grad = UV.y;
    // Color base interpolado entre dos tonos.
    vec3 color = mix(vec3(0.1, 0.2, 0.8), vec3(0.9, 0.7, 0.1), grad);
    ALBEDO = color;
    // Disolución dura: descarta píxeles bajo el corte.
    if (grad < corte) {
        discard;
    }
}
```

**Paso 2 — Crear el VisualShader.** En un nuevo `MeshInstance3D`, asigna un `ShaderMaterial` y en **Shader** elige **New VisualShader** de tipo `spatial`. Se abre el editor de grafo con el nodo **Output** ya presente.

**Paso 3 — El degradado.** Añade un nodo de entrada **Input → UV** (da un `vec2`). Inserta un nodo **VectorDecompose** (o `Swizzle`) para extraer la componente **Y**: ese float es tu degradado vertical. Conéctalo hacia donde lo necesites.

**Paso 4 — La mezcla de color.** Añade un nodo **Mix** (interpolación) con dos entradas de color: un `ColorConstant` azul y otro amarillo. Usa la **Y** del UV como factor de la mezcla. La salida del `Mix` va al puerto **Albedo** del nodo Output.

**Paso 5 — La disolución con uniform visual.** Crea un nodo **FloatParameter** (uniform visual) llamado `corte`, con rango 0–1. Añade un nodo **Comparison / Step** que compare la Y del UV contra `corte`, y lleva el resultado al puerto **Alpha Scissor Threshold** del Output (o multiplícalo en **Alpha** activando transparencia). Al mover `corte` en el Inspector, el plano se recorta como en la versión en código.

**Paso 6 — Leer el código generado.** Con el VisualShader seleccionado, en el menú del recurso elige mostrar el shader generado (o inspecciona el `.tres`). Verás algo equivalente a:

```glsl
// Fragmento generado (simplificado) por el VisualShader:
shader_type spatial;
uniform float corte;

void fragment() {
    float grad = UV.y;
    vec3 color = mix(vec3(0.1, 0.2, 0.8), vec3(0.9, 0.7, 0.1), grad);
    ALBEDO = color;
    ALPHA_SCISSOR_THRESHOLD = corte; // recorte por alfa
}
```

**Paso 7 — Controlar el uniform desde código.** Como cualquier ShaderMaterial, el uniform visual se ajusta por API:

```gdscript
# Animar el corte de disolución de 0 a 1 a lo largo del tiempo.
var mat: ShaderMaterial = $MeshInstance3D.get_active_material(0)
func _process(delta: float) -> void:
    var t: float = fmod(Time.get_ticks_msec() / 1000.0, 1.0)
    mat.set_shader_parameter("corte", t)
```

**Resultado observable:** dos planos con el mismo degradado; en el del VisualShader mueves el uniform `corte` (a mano o animado) y el plano se disuelve exactamente igual que su gemelo escrito en código.

## ✍️ Ejercicios

1. Cambia los dos `ColorConstant` del `Mix` y observa cómo cambia el degradado sin tocar código.
2. Sustituye la Y del UV por la X y describe cómo gira la orientación del degradado.
3. Añade un nodo **Time** y súmalo a la UV para animar el degradado; compáralo con hacerlo en código.
4. Expón un segundo `FloatParameter` para la suavidad del borde usando `SmoothStep` en vez de `Step`.
5. Lee el código generado y señala qué línea corresponde a cada nodo de tu grafo.
6. Reescribe a mano, en un `.gdshader`, el shader que generó tu grafo y confirma que se ve igual.

## 📝 Reto verificable

Reproduce **un mismo efecto de disolución** en dos versiones: una escrita en código y otra en VisualShader, ambas con un uniform `corte` en rango 0–1. Deben verse idénticas al barrer el uniform y ambas deben poder animarse desde GDScript con `set_shader_parameter`.

**Criterio de aceptación**: al animar `corte` de 0 a 1, los dos planos se disuelven de forma indistinguible; entregas una captura de tu grafo VisualShader **y** el código generado, señalando qué nodo produce cada línea clave.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El grafo no se ve en pantalla | No conectaste nada al nodo **Output** (Albedo/Alpha) |
| No puedo unir dos puertos | Tipos incompatibles (float vs vec3); añade un nodo de conversión/swizzle |
| El uniform no aparece en el Inspector | Usaste una constante en vez de un `*Parameter`; cámbialo por un uniform visual |
| La disolución no recorta | Olvidaste enviar el umbral a `Alpha Scissor Threshold` o activar transparencia |
| El código generado se ve enredado | Es normal: el grafo prioriza corrección sobre legibilidad; léelo por bloques |
| Cambios no se guardan | El VisualShader es un recurso; guarda la escena/recurso tras editarlo |

## ❓ Preguntas frecuentes

**¿El VisualShader es menos potente que el código?**
Cubre la mayoría de casos, pero para lógica muy específica el código es más directo. Además existe un nodo de **Expression** para escribir GLSL dentro del grafo.

**¿Cuándo conviene el grafo sobre el código?**
Cuando iteras visualmente, colaboras con artistas técnicos o quieres ver el resultado de cada nodo. El código gana en efectos complejos y control de versiones limpio.

**¿El grafo genera un shader "peor" en rendimiento?**
No inherentemente: produce código equivalente. El coste depende de qué nodos uses (lookups, branches), igual que en código escrito a mano.

**¿Se parece al Shader Graph de Unity o al de Unreal?**
Conceptualmente sí: nodos de entrada, operaciones y una salida de material. Cambian los nombres y algunos nodos, pero el modelo mental es el mismo.

## 🔗 Referencias

- [VisualShaders — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/shaders/visual_shaders.html)
- [Lenguaje de shaders de Godot (código equivalente)](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html)
- [Shader Graph — Unity Docs](https://docs.unity3d.com/Packages/com.unity.shadergraph@latest)
- [Material Editor — Unreal Engine Docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-material-editor-user-guide)

## ⬅️ Clase anterior

[Clase 105 - Optimización de shaders y coste en GPU](../105-optimizacion-de-shaders-y-coste-en-gpu/README.md)

## ➡️ Siguiente clase

[Clase 107 - Capstone Parte 4: set de shaders y post-procesado](../107-capstone-parte-4-set-de-shaders-y-post-procesado/README.md)
