# Clase 017 — Gráficos por computadora: cómo se dibuja un frame

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Akenine-Möller et al., Real-Time Rendering*
> ⏱️ Duración estimada: **95 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Cada imagen que ves en un juego se construye decenas de veces por segundo mediante una secuencia de etapas llamada **pipeline de render**. Entender ese recorrido —de vértices a triángulos, de triángulos a píxeles— te permite razonar sobre rendimiento, escribir shaders y diagnosticar por qué algo se dibuja mal o lento.

En esta clase recorrerás el pipeline gráfico: aplicación, procesamiento de geometría (vertex), rasterización, procesamiento de fragmentos (pixel) y salida. Verás el papel de la **GPU** frente a la **CPU**, qué es un **shader**, qué es el **framebuffer** y por qué las **draw calls** importan. Cerrarás escribiendo un shader mínimo en Godot que pinte un color y luego un degradado usando coordenadas UV.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Enumerar en orden las etapas del pipeline de render y describir qué hace cada una.
2. Distinguir el rol de la CPU y de la GPU en el dibujado de un frame.
3. Diferenciar un vertex shader de un fragment shader.
4. Explicar qué es una draw call y por qué reducirlas mejora el rendimiento.
5. Escribir un fragment shader en Godot que use coordenadas UV para generar un degradado.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Etapas del pipeline | Es el camino que sigue todo lo que se dibuja. |
| 2 | CPU vs GPU | Reparto de trabajo; la GPU procesa en paralelo. |
| 3 | Vértices y primitivas | Los triángulos son la unidad de la geometría 3D/2D. |
| 4 | Rasterización | Convierte triángulos en fragmentos (candidatos a píxel). |
| 5 | Shaders | Programas que corren en la GPU por vértice y por fragmento. |
| 6 | Framebuffer | Memoria donde se compone la imagen final. |
| 7 | Draw calls | Cada llamada tiene costo; reducirlas sube los FPS. |
| 8 | 2D como el mismo pipeline | Los sprites son quads texturizados. |

## 📖 Definiciones y características

- **Pipeline de render**: secuencia de etapas que transforma geometría en píxeles en pantalla. Clave: aplicación → geometría → rasterización → fragmentos → salida.
- **Vértice**: punto con posición y atributos (color, UV, normal). Clave: define las esquinas de las primitivas.
- **Primitiva**: forma básica ensamblada con vértices; casi siempre un triángulo. Clave: la GPU está optimizada para triángulos.
- **Rasterización**: proceso que determina qué fragmentos cubre cada triángulo. Clave: genera los candidatos a píxel.
- **Fragmento**: dato por-píxel candidato antes de las pruebas de profundidad y mezcla. Clave: puede acabar o no en el framebuffer.
- **Shader**: pequeño programa ejecutado en la GPU. Clave: el *vertex shader* transforma vértices, el *fragment shader* calcula el color.
- **Framebuffer**: buffer de memoria que almacena el color (y profundidad) de la imagen. Clave: su contenido es lo que se muestra.
- **Draw call**: orden de la CPU a la GPU para dibujar un lote de geometría. Clave: muchas draw calls saturan la CPU y bajan los FPS.

## 🧰 Herramientas y preparación

Usarás **Godot 4** (<https://godotengine.org/>), que emplea su propio lenguaje de shaders llamado **Godot Shading Language** (archivos `.gdshader`), con sintaxis muy parecida a GLSL. No necesitas instalar nada extra: el editor de shaders está integrado. La referencia teórica es *Real-Time Rendering* de Akenine-Möller, Haines y Hoffman (<https://www.realtimerendering.com/>). Para profundizar en la sintaxis de shaders de Godot consulta su documentación (<https://docs.godotengine.org/en/stable/tutorials/shaders/index.html>). El recurso interactivo *The Book of Shaders* (<https://thebookofshaders.com/>) ayuda a visualizar el trabajo del fragment shader.

## 🧪 Laboratorio guiado

### Paso 1 — Preparar un nodo con material de shader

Crea un proyecto 2D en Godot. Añade un nodo **ColorRect** como hijo de la raíz y en el inspector fíjale un tamaño visible (por ejemplo 400×400) con **Layout > Custom Minimum Size**. En su propiedad **Material** elige **New ShaderMaterial**, y dentro de ese material, en **Shader**, elige **New Shader** (tipo *Canvas Item*). Se abre el editor de shaders en la parte inferior.

### Paso 2 — Pintar un color plano (fragment shader mínimo)

Escribe el shader más simple posible: un fragment shader que asigna un color fijo.

```glsl
shader_type canvas_item;

void fragment() {
    // COLOR es la salida del fragment shader (RGBA)
    COLOR = vec4(0.2, 0.6, 1.0, 1.0); // azul
}
```

Guarda: el `ColorRect` se pinta de azul. Cada píxel dentro del rectángulo ejecutó esta función `fragment()` una vez.

### Paso 3 — Usar coordenadas UV para un degradado

Las coordenadas **UV** van de `0.0` a `1.0` a lo ancho y alto de la superficie. Úsalas para variar el color por posición:

```glsl
shader_type canvas_item;

void fragment() {
    // UV.x va de 0 (izquierda) a 1 (derecha); UV.y de 0 (arriba) a 1 (abajo)
    COLOR = vec4(UV.x, UV.y, 0.5, 1.0);
}
```

Ahora verás un degradado: el rojo aumenta hacia la derecha y el verde hacia abajo. Observas directamente que el fragment shader corre **por píxel** y que cada uno recibe su propio valor de UV.

### Paso 4 — Un degradado horizontal controlado

Interpola entre dos colores según `UV.x` con `mix()`:

```glsl
shader_type canvas_item;

void fragment() {
    vec3 izquierda = vec3(0.9, 0.2, 0.3); // rojo
    vec3 derecha   = vec3(0.2, 0.4, 0.9); // azul
    vec3 color = mix(izquierda, derecha, UV.x);
    COLOR = vec4(color, 1.0);
}
```

El resultado transiciona de rojo a azul de izquierda a derecha: has controlado la salida de la etapa de fragmentos con matemática simple.

## ✍️ Ejercicios

1. Modifica el degradado del Paso 3 para que use `UV.y` en el canal rojo en vez de `UV.x`.
2. Crea un degradado vertical con `mix()` usando `UV.y` como factor.
3. Dibuja una franja: si `UV.x < 0.5` pinta un color, si no, otro (usa un `if`).
4. Investiga y explica en dos líneas qué etapa del pipeline produce el valor de `UV` que recibe el fragment.
5. Añade un `uniform float velocidad;` y descríbelo (no hace falta animar todavía).
6. Cuenta cuántas draw calls muestra el monitor de Godot (**Debug > Monitors**) con uno y con diez ColorRect.

## 📝 Reto verificable

Crea una escena con un `ColorRect` cuyo `ShaderMaterial` genere un degradado diagonal: el color debe depender simultáneamente de `UV.x` y `UV.y`. El shader debe usar `mix()` al menos una vez y compilar sin errores. **Criterio de aceptación**: al abrir la escena se ve un degradado que cambia tanto en horizontal como en vertical, y el panel del editor de shaders no muestra errores de compilación.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| `Expected 'shader_type'...` | Falta la primera línea `shader_type canvas_item;`; agrégala. |
| El rectángulo sale negro | El material no está asignado al nodo o `COLOR` no se escribe; revisa la asignación del ShaderMaterial. |
| No se ve nada en pantalla | El `ColorRect` tiene tamaño 0; asigna un *Custom Minimum Size*. |
| `Constructor 'vec4'... arguments` | Número de componentes incorrecto; `vec4` requiere 4 valores. |
| El degradado no cambia | Usaste una constante en vez de `UV`; verifica que empleas `UV.x`/`UV.y`. |

## ❓ Preguntas frecuentes

**❓ ¿El lenguaje de shaders de Godot es GLSL?** Es muy similar, pero es el *Godot Shading Language*, con funciones y variables integradas propias como `COLOR` y `UV`.

**❓ ¿Por qué todo se dibuja con triángulos?** Un triángulo siempre es plano y convexo, lo que hace la rasterización simple y rápida; la GPU está diseñada para procesarlos masivamente.

**❓ ¿La GPU reemplaza a la CPU?** No. La CPU prepara los datos y emite las draw calls; la GPU ejecuta el trabajo paralelo de vértices y fragmentos.

**❓ ¿Por qué me insisten en reducir draw calls?** Cada draw call cuesta trabajo de CPU; con miles por frame la CPU se vuelve el cuello de botella y los FPS caen.

## 🔗 Referencias

- Real-Time Rendering (sitio oficial): <https://www.realtimerendering.com/>
- Godot — Shaders (documentación): <https://docs.godotengine.org/en/stable/tutorials/shaders/index.html>
- Godot — Your first canvas_item shader: <https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_2d_shader.html>
- The Book of Shaders: <https://thebookofshaders.com/>
- Khronos — The Graphics Pipeline: <https://www.khronos.org/opengl/wiki/Rendering_Pipeline_Overview>

## ➡️ Siguiente clase

[Clase 018 - Sistemas de coordenadas y espacios: local, mundo, cámara, pantalla](../018-sistemas-de-coordenadas-y-espacios-local-mundo-camara-pantalla/README.md)
