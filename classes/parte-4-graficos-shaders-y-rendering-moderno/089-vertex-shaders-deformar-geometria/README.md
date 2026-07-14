# Clase 089 — Vertex shaders: deformar geometría

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Documentación de shaders spatial de Godot 4 + The Book of Shaders (funciones de ruido y ondas)*
> ⏱️ Duración estimada: **50 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Aprender a **mover geometría en la GPU** desde la función `vertex()`. En vez de animar objetos con la CPU, desplazaremos los vértices de una malla directamente en el shader usando `VERTEX` y `TIME`. Construirás una superficie que ondula como agua o una bandera, con **amplitud y frecuencia controlables por uniforms**, y entenderás la base de efectos como viento en vegetación y billboards.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Modificar la posición de los vértices escribiendo en `VERTEX` dentro de `vertex()`.
- Animar geometría con `TIME` usando `sin`/`cos` para crear ondas.
- Exponer amplitud y frecuencia como uniforms ajustables.
- Explicar por qué deformar en GPU es más eficiente que mover vértices desde la CPU.
- Reconocer el patrón de viento en vegetación y la idea del billboard.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | La función `vertex()` | Es el único lugar donde puedes mover geometría |
| 2 | El built-in `VERTEX` | Contiene la posición de cada vértice a modificar |
| 3 | Ondas con `sin(TIME)` | Base de toda animación procedural de superficies |
| 4 | Uniforms de control | Permiten afinar el efecto sin recompilar |
| 5 | Densidad de malla | Sin suficientes vértices no hay curva suave |
| 6 | Viento en vegetación | Aplicación real del desplazamiento por vertex |
| 7 | Billboard | Truco de vertex para orientar quads a la cámara |

## 📖 Definiciones y características

- **`vertex()`**: función que corre una vez por vértice antes de rasterizar. Clave: aquí se deforma la malla.
- **`VERTEX`**: posición del vértice en espacio de objeto (`vec3`). Clave: modificarla mueve la geometría.
- **`TIME`**: segundos transcurridos, disponible en todas las etapas. Clave: hace que la deformación se anime.
- **Amplitud**: cuánto se desplaza el vértice (altura de la ola). Clave: valores altos exageran el efecto.
- **Frecuencia**: cuántas ondas caben por unidad de espacio. Clave: controla si las olas son largas o apretadas.
- **Subdivisión de malla**: número de vértices de la superficie. Clave: sin subdivisiones el `PlaneMesh` no se curva.
- **Viento en vegetación**: desplazar más la punta que la base según la altura del vértice. Clave: produce balanceo natural.
- **Billboard**: técnica de vertex que hace que un quad mire siempre a la cámara. Clave: usada para partículas e impostores.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x con renderer **Forward+**. Usaremos un `PlaneMesh` **subdividido** (muchos vértices) porque un plano de 4 esquinas no puede curvarse. Ten a mano el Inspector para ajustar **Subdivide Width/Depth** de la malla y los uniforms del material. Como referencia, revisa los built-ins de vertex en la [documentación del shader spatial](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html) y la lógica de ondas en [The Book of Shaders](https://thebookofshaders.com/05/).

## 🧪 Laboratorio guiado

Objetivo: una superficie plana que ondula suavemente como agua.

**Paso 1 — Malla subdividida.** Escena 3D con `Node3D`. Añade `MeshInstance3D` con `PlaneMesh`. En la malla, pon **Size** a (4, 4) y sube **Subdivide Width** y **Subdivide Depth** a 64 cada uno. Sin esta subdivisión el efecto no se verá. Añade `Camera3D` en ángulo y una `DirectionalLight3D`.

**Paso 2 — Material y shader.** En la malla: **Material Override → New ShaderMaterial → Shader → New Shader**, tipo `spatial`, nombre `agua.gdshader`.

**Paso 3 — Escribir el vertex shader.**

```glsl
shader_type spatial;

uniform float amplitud : hint_range(0.0, 1.0) = 0.2;
uniform float frecuencia : hint_range(0.1, 10.0) = 2.0;
uniform float velocidad : hint_range(0.0, 5.0) = 1.0;
uniform vec3 color_agua : source_color = vec3(0.1, 0.5, 0.8);

void vertex() {
    // VERTEX está en espacio de objeto. Elevamos VERTEX.y con una onda
    // que depende de la posición X (y algo de Z) y avanza con el tiempo.
    float onda = sin(VERTEX.x * frecuencia + TIME * velocidad);
    onda += 0.5 * sin(VERTEX.z * frecuencia * 1.3 + TIME * velocidad * 0.8);
    VERTEX.y += onda * amplitud;
}

void fragment() {
    ALBEDO = color_agua;
    ROUGHNESS = 0.2;   // superficie algo brillante
    METALLIC = 0.0;
}
```

Guarda y ejecuta: el plano ondula. Ajusta **amplitud**, **frecuencia** y **velocidad** en el Inspector y observa el cambio en vivo.

**Paso 4 — Variante bandera (viento por altura).** Cambia la línea de `VERTEX.y` por un desplazamiento en Z que crece con la altura del vértice, útil para banderas o hierba:

```glsl
    // Cuanto más arriba está el vértice (VERTEX.y), más se mueve: efecto tela.
    float factor = clamp(VERTEX.y, 0.0, 1.0);
    VERTEX.z += sin(VERTEX.y * frecuencia + TIME * velocidad) * amplitud * factor;
```

Con el plano puesto vertical (rótalo 90° en X), verás ondear la "tela" más en la punta que en la base.

**Resultado visible:** una malla que ondula de forma animada y controlable, sin una sola línea de GDScript.

## ✍️ Ejercicios

1. Añade un tercer término de onda con otra frecuencia para que el agua se vea menos repetitiva.
2. Expón la dirección de la onda como `uniform vec2 direccion` y úsala en el argumento del `sin`.
3. Colorea las crestas más claras que los valles usando `VERTEX.y` en `fragment()` (pásalo con un varying).
4. Reduce **Subdivide** a 4 y explica por qué el efecto se ve facetado.
5. Combina amplitud animada: multiplica `amplitud` por `(sin(TIME) + 1.0)` para olas que crecen y menguan.
6. Investiga cómo se orientaría un quad hacia la cámara (billboard) y describe qué cálculo iría en `vertex()`.

## 📝 Reto verificable

Crea una **bandera ondeante** a partir de un plano vertical subdividido: el borde fijo (base) no se mueve y la punta ondea con el viento, con **amplitud y velocidad** controlables por uniforms.

**Criterio de aceptación**: al ejecutar, la tela ondula de forma continua, el lado anclado permanece prácticamente quieto y la punta se desplaza más; cambiar los uniforms de amplitud y velocidad altera visiblemente el movimiento sin recompilar el shader.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El plano no se curva | El `PlaneMesh` no está subdividido; sube Subdivide Width/Depth |
| La ola no se anima | Olvidaste incluir `TIME` en el argumento del `sin` |
| El movimiento es facetado | Pocos vértices; aumenta la subdivisión de la malla |
| "VERTEX no disponible en fragment" | `VERTEX` se modifica en `vertex()`; para usarlo en fragment pásalo con un varying |
| La malla vibra de forma caótica | Frecuencia demasiado alta respecto a la densidad de vértices; bájala |
| La iluminación se ve plana | No recalculas normales; para un pulido, ajusta `NORMAL` o usa menos amplitud |

## ❓ Preguntas frecuentes

**¿Por qué deformar en el vertex shader y no mover el nodo desde GDScript?**
Porque la GPU procesa miles de vértices en paralelo cada frame; hacerlo en CPU sería mucho más lento y no escalaría a mallas densas.

**¿Las normales se actualizan solas al mover VERTEX?**
No. Godot no recalcula automáticamente la normal exacta de la superficie deformada; para iluminación precisa tendrías que recalcular `NORMAL` tú mismo.

**¿Puedo mover VERTEX en cualquier eje?**
Sí, `VERTEX` es un `vec3`; puedes alterar x, y y z. Elige el eje según el efecto (altura para agua, profundidad para tela).

**¿Sirve esto para vegetación con viento?**
Exactamente. El patrón de desplazar más los vértices altos (las hojas) que los bajos (el tronco) es la base del viento en follaje.

## 🔗 Referencias

- [Shader spatial: built-ins de vertex — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html)
- [Tutorial de shaders de Godot: vertex processing](https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_3d_shader.html)
- [The Book of Shaders — funciones de forma y ondas](https://thebookofshaders.com/05/)
- [The Book of Shaders — algoritmos de patrones](https://thebookofshaders.com/09/)

## ➡️ Siguiente clase

[Clase 090 - Fragment shaders: color por píxel y UVs](../090-fragment-shaders-color-por-pixel-y-uvs/README.md)
