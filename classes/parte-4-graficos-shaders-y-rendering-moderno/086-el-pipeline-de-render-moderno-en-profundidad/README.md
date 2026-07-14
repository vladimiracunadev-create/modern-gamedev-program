# Clase 086 — El pipeline de render moderno en profundidad

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Akenine-Möller et al., "Real-Time Rendering" (4ª ed.) + Documentación de rendering de Godot 4*
> ⏱️ Duración estimada: **50 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender, de principio a fin, qué le pasa a un triángulo desde que existe en memoria hasta que se convierte en píxeles de color en la pantalla. Al terminar sabrás nombrar cada etapa del pipeline de rasterización, distinguir **qué partes son programables** (vertex y fragment) de las que son fijas, ubicar los espacios de coordenadas por los que viaja cada vértice y explicar por qué las **draw calls** y la elección entre **forward** y **deferred** afectan al rendimiento en Godot 4 sobre Vulkan.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Describir las etapas del pipeline: aplicación → vertex → rasterización → fragment → salida.
- Diferenciar las etapas programables (vertex/fragment) de las de función fija (rasterizador, blending).
- Nombrar los espacios de coordenadas: objeto, mundo, vista, clip y pantalla, y por qué existen.
- Explicar qué es una draw call y cómo su número impacta el frame rate.
- Comparar rendering forward y deferred, y saber cuál usa Godot 4 por defecto.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Etapas del pipeline | Es el mapa mental sobre el que se apoya todo lo demás del curso |
| 2 | Etapas programables vs fijas | Define exactamente dónde puedes escribir código de shader |
| 3 | Espacios de coordenadas | Sin ellos no entiendes qué contiene `VERTEX` en cada función |
| 4 | Matrices de transformación | Convierten un vértice de un espacio al siguiente |
| 5 | Draw calls y batching | Principal cuello de botella de CPU→GPU en juegos reales |
| 6 | Forward vs deferred | Determina cómo se calcula la iluminación de la escena |
| 7 | Vulkan en Godot 4 | Es el backend que ejecuta este pipeline en tu máquina |

## 📖 Definiciones y características

- **Pipeline de render**: secuencia de etapas que transforma geometría en píxeles. Clave: unas etapas son fijas y otras las programas tú.
- **Vertex shader**: programa que se ejecuta **una vez por vértice**. Clave: su tarea típica es proyectar el vértice al espacio de clip.
- **Rasterización**: etapa fija que decide qué píxeles cubre cada triángulo y genera *fragmentos*. Clave: interpola los datos de los vértices (UV, normal, color).
- **Fragment shader**: programa que se ejecuta **una vez por fragmento** candidato a píxel. Clave: produce el color final (`ALBEDO`/`COLOR`).
- **Draw call**: orden que la CPU envía a la GPU para dibujar un lote de geometría. Clave: muchas draw calls saturan la CPU antes que la GPU.
- **Forward rendering**: ilumina cada objeto contra cada luz al dibujarlo. Clave: simple y con buena antialiasing, pero cuesta con muchas luces.
- **Deferred rendering**: primero guarda datos en un *G-buffer* y luego ilumina en pantalla. Clave: escala mejor con muchísimas luces.
- **Espacio de clip**: sistema donde la GPU recorta lo que no cabe en la cámara. Clave: es el destino obligatorio del vertex shader.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x con el **Forward+** renderer activo (es el predeterminado y usa Vulkan). Trabajaremos en una escena 3D vacía, así que crea un proyecto nuevo o abre uno de práctica. Ten a mano el **Inspector** y el menú **Project → Project Settings → Rendering** para observar las opciones del backend. Para profundizar, consulta el capítulo de arquitectura de rendering en la [documentación oficial de Godot](https://docs.godotengine.org/en/stable/tutorials/shaders/introduction_to_shaders.html) y el resumen del pipeline en [Real-Time Rendering](https://www.realtimerendering.com/). No hace falta escribir shaders complejos aún: el objetivo es *ver* dónde encaja cada pieza.

## 🧪 Laboratorio guiado

Vamos a crear el shader más pequeño posible que produce algo visible y a ubicar cada línea dentro del pipeline.

**Paso 1 — Escena base.** Crea una escena 3D con un nodo `Node3D` como raíz. Añade un `MeshInstance3D`, y en su propiedad **Mesh** elige un `BoxMesh`. Añade también una `Camera3D` apuntando al cubo y una `DirectionalLight3D`. Guarda como `pipeline_demo.tscn`.

**Paso 2 — Crear el material y el shader.** Selecciona el `MeshInstance3D`. En el Inspector, en **Material Override → [empty]**, elige **New ShaderMaterial**. Haz clic en el ShaderMaterial recién creado y, en su propiedad **Shader**, elige **New Shader**. Ponle nombre `minimo.gdshader` y tipo `spatial`.

**Paso 3 — Shader mínimo.** Abre el editor de shaders y escribe:

```glsl
shader_type spatial;

// vertex() se ejecuta UNA vez por cada vértice del cubo (8 en un BoxMesh).
// Aquí no tocamos nada: Godot proyecta VERTEX al espacio de clip por nosotros.
void vertex() {
    // VERTEX está en espacio de objeto; el motor lo lleva a clip con las matrices.
}

// fragment() se ejecuta UNA vez por cada fragmento que cubre el cubo en pantalla.
void fragment() {
    ALBEDO = vec3(0.1, 0.6, 1.0); // color base: azul claro
}
```

Al guardar, el cubo se vuelve azul. Acabas de intervenir la etapa **fragment**.

**Paso 4 — Ubicar cada cosa.** Razona en voz alta con esta correspondencia:

| Etapa del pipeline | Qué pasa aquí en tu demo |
|--------------------|--------------------------|
| Aplicación (CPU) | Godot recorre la escena y emite la draw call del cubo |
| Vertex | Se ejecuta `vertex()` por cada vértice; `VERTEX` pasa de objeto a clip |
| Rasterización (fija) | La GPU decide qué píxeles cubre el cubo e interpola datos |
| Fragment | Se ejecuta `fragment()`; asignas `ALBEDO` |
| Salida (fija) | Depth test + blending escriben el píxel final |

**Paso 5 — Ver la draw call.** Ejecuta la escena y abre el panel inferior **Depurar → Monitores** (o el *overlay* de depuración). Observa el contador de **Draw calls**. Duplica el `MeshInstance3D` cinco veces (Ctrl+D) y comprueba cómo sube el número: cada cubo con su material es, típicamente, una draw call más.

**Resultado visible:** un cubo azul cuyo color viene de *tu* código de fragment, y un contador de draw calls que reacciona cuando añades geometría.

## ✍️ Ejercicios

1. Cambia el `ALBEDO` para que el cubo sea rojo y explica por qué el cambio ocurre en la etapa fragment y no en la vertex.
2. Añade un `SphereMesh` con el mismo shader y anota cuántas draw calls hay ahora.
3. En Project Settings → Rendering, cambia el método de renderizado a **Mobile** y anota qué opciones desaparecen respecto a **Forward+**.
4. Escribe en un comentario dentro del shader qué contiene `VERTEX` en `vertex()` y qué contendría después de la proyección.
5. Dibuja en papel el recorrido de un vértice por los cinco espacios de coordenadas.
6. Investiga y explica en dos frases por qué agrupar objetos con el mismo material reduce draw calls.

## 📝 Reto verificable

Construye una escena con **tres mallas distintas** (cubo, esfera y cilindro) que compartan **un único ShaderMaterial** con el shader mínimo azul. Muestra el contador de draw calls antes y después de compartir el material.

**Criterio de aceptación**: las tres mallas se ven azules con el mismo shader, y demuestras (captura o descripción del monitor) que compartir un mismo material no multiplica innecesariamente el trabajo de configuración, explicando en qué etapa del pipeline actúa tu `ALBEDO`.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El shader no compila: "Expected ';'" | Falta `;` al final de una sentencia; revisa cada línea de asignación |
| El cubo se ve negro | No hay luz o pusiste `ALBEDO` sin iluminación; añade una `DirectionalLight3D` |
| "ALBEDO no está disponible" | Escribiste `ALBEDO` dentro de `vertex()`; solo existe en `fragment()` |
| El material no aplica | Olvidaste asignar el ShaderMaterial en **Material Override** de la malla |
| Muchísimas draw calls y caídas de FPS | Cada objeto con material único genera una draw call; reutiliza materiales |
| No aparece nada en pantalla | La `Camera3D` no apunta a la geometría; reposiciónala |

## ❓ Preguntas frecuentes

**¿El vertex shader se ejecuta antes que el fragment shader?**
Sí. Primero se procesan todos los vértices del triángulo, luego se rasteriza y recién ahí corre el fragment por cada píxel cubierto.

**¿Puedo programar la etapa de rasterización?**
No. La rasterización es de función fija: la GPU decide qué píxeles cubre el triángulo. Tú programas vertex y fragment (y `light()`).

**¿Godot 4 usa forward o deferred?**
El renderer **Forward+** es el predeterminado y, pese al nombre, usa un enfoque *clustered forward* que escala bien con muchas luces sobre Vulkan.

**¿Menos draw calls siempre es mejor?**
Generalmente reduce la carga de CPU, pero el equilibrio depende de tu escena. Lo importante es medir con los monitores, no adivinar.

## 🔗 Referencias

- [Introducción a los shaders — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/shaders/introduction_to_shaders.html)
- [Métodos de renderizado en Godot 4](https://docs.godotengine.org/en/stable/tutorials/rendering/index.html)
- [Real-Time Rendering — sitio oficial del libro](https://www.realtimerendering.com/)
- [The Book of Shaders — capítulo introductorio](https://thebookofshaders.com/01/)

## ➡️ Siguiente clase

[Clase 087 - Rasterización vs ray tracing: panorama actual](../087-rasterizacion-vs-ray-tracing-panorama-actual/README.md)
