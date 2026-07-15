# Clase 096 — Screen-space y post-procesado

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Godot Engine 4.x — Screen-reading shaders y Custom post-processing*
> ⏱️ Duración estimada: **65 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Aprender a leer lo que ya está dibujado en pantalla y modificarlo con un shader de **post-procesado**. Verás cómo funciona `hint_screen_texture` junto a `SCREEN_UV`, montarás el patrón estándar de Godot 4 — un **`ColorRect` a pantalla completa dentro de un `CanvasLayer`** encima de todo — y escribirás un shader que aplique un **tinte** de color y una **distorsión de onda** a la imagen completa del juego. Esta es la base de bloom, distorsión de calor, viñeta y decenas de efectos.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar qué es el **post-procesado** y por qué se hace sobre la imagen final.
2. Leer la pantalla con **`hint_screen_texture`** y **`SCREEN_UV`**.
3. Montar el setup **`CanvasLayer` + `ColorRect` fullscreen** para post-proceso.
4. Aplicar un **tinte** de color multiplicando el color de pantalla.
5. Crear una **distorsión de onda** desplazando `SCREEN_UV` con `sin` y `TIME`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es el post-procesado | Efectos globales sobre la imagen final |
| 2 | `hint_screen_texture` | Da acceso a lo ya renderizado |
| 3 | `SCREEN_UV` | Coordenada de pantalla, no del objeto |
| 4 | `ColorRect` fullscreen | El lienzo sobre el que se dibuja el efecto |
| 5 | `CanvasLayer` encima | Garantiza que cubra toda la escena |
| 6 | Tinte de color | Ejemplo mínimo de manipular la pantalla |
| 7 | Distorsión por UV | Base de calor, agua, ondas de choque |

## 📖 Definiciones y características

- **Post-procesado**: efecto aplicado a la imagen ya renderizada, no a objetos individuales. Clave: afecta todo lo visible a la vez.
- **`hint_screen_texture`**: hint que expone la textura de la pantalla actual al shader. Clave: se declara con `filter_linear_mipmap` para muestreo suave.
- **`SCREEN_UV`**: coordenada normalizada (0–1) de la posición del fragmento en la pantalla. Clave: con ella se muestrea la pantalla.
- **`ColorRect`**: nodo 2D rectangular; estirado a pantalla completa es el soporte del shader. Clave: su material lleva el shader de post-proceso.
- **`CanvasLayer`**: capa de dibujo independiente de la cámara. Clave: garantiza que el `ColorRect` quede por encima de todo.
- **Tinte**: multiplicar el color de pantalla por otro para teñir la escena. Clave: `rojo*(1,0.6,0.6)` da ambiente de alarma.
- **Distorsión de UV**: desplazar `SCREEN_UV` antes de muestrear deforma la imagen. Clave: `sin(TIME)` da ondulación animada.
- **Orden de dibujo**: Godot dibuja la escena y luego el `CanvasLayer`; el shader lee lo primero. Clave: por eso el efecto ve el juego completo.

## 🧰 Herramientas y preparación

Usa **Godot 4.x**. Sobre cualquier escena jugable (2D o 3D con una escena de fondo visible), añade un `CanvasLayer` y, dentro, un `ColorRect`. En el inspector del `ColorRect`, pon el Layout en **Full Rect** para que cubra la pantalla, y asígnale un `ShaderMaterial`. Consulta [Screen-reading shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html) y [Custom post-processing](https://docs.godotengine.org/en/stable/tutorials/shaders/custom_postprocessing.html). Lo observable: toda la pantalla se tiñe y ondula como bajo el agua.

## 🧪 Laboratorio guiado

Montaremos el setup de post-proceso y un shader con tinte + onda.

**Paso 1 — Crear el lienzo.** En el árbol de tu escena:

- Añade un `CanvasLayer` como hijo de la raíz.
- Dentro, añade un `ColorRect`.
- Con el `ColorRect` seleccionado, arriba en la barra de layout elige **Full Rect** (o pon anchors a Full Rect). Ahora cubre toda la ventana.
- Asígnale un `ShaderMaterial` con un shader nuevo.

**Paso 2 — Leer la pantalla y aplicar un tinte.** En el shader del `ColorRect`:

```glsl
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec4 tinte : source_color = vec4(1.0, 0.7, 0.7, 1.0);
uniform float mezcla : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec3 pantalla = texture(screen_tex, SCREEN_UV).rgb;   // lo ya dibujado
	vec3 teñido = pantalla * tinte.rgb;                   // multiplicar tinte
	COLOR = vec4(mix(pantalla, teñido, mezcla), 1.0);
}
```

Ejecuta (F6): toda la escena adquiere un tono rojizo. Sube `mezcla` a 1.0 y el tinte domina; a 0.0 vuelve al original.

**Paso 3 — Añadir la distorsión de onda.** Desplaza `SCREEN_UV` antes de muestrear:

```glsl
uniform float amplitud : hint_range(0.0, 0.05) = 0.01;
uniform float frecuencia : hint_range(1.0, 40.0) = 12.0;
uniform float velocidad : hint_range(0.0, 8.0) = 3.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	// Onda vertical dependiente de la posición y del tiempo.
	uv.x += sin(uv.y * frecuencia + TIME * velocidad) * amplitud;

	vec3 pantalla = texture(screen_tex, uv).rgb;
	vec3 teñido = pantalla * tinte.rgb;
	COLOR = vec4(mix(pantalla, teñido, mezcla), 1.0);
}
```

Ahora la pantalla ondula horizontalmente como visto a través de agua o calor. Ajusta `amplitud` y `frecuencia` para más o menos deformación.

**Paso 4 — Encender/apagar el efecto desde GDScript.** Controla la intensidad al vuelo:

```gdscript
extends ColorRect

func activar_submarino(activo: bool) -> void:
	var m: float = 1.0 if activo else 0.0
	material.set_shader_parameter("mezcla", m)
	material.set_shader_parameter("amplitud", 0.015 if activo else 0.0)
```

Llama `activar_submarino(true)` al entrar bajo el agua y `false` al salir. El efecto cubre siempre toda la escena porque el `ColorRect` está en un `CanvasLayer` por encima.

## ✍️ Ejercicios

1. Cambia el tinte a verde para un ambiente tóxico y ajusta `mezcla` a 0.4.
2. Añade una onda en el eje Y además de la de X para deformación en dos direcciones.
3. Haz que la `amplitud` crezca con `sin(TIME)` para simular oleaje que sube y baja.
4. Convierte la pantalla a escala de grises mezclando por `dot(pantalla, vec3(0.299,0.587,0.114))`.
5. Limita la distorsión a la mitad inferior de la pantalla usando `step(0.5, SCREEN_UV.y)`.
6. Expón `frecuencia` en el inspector y encuentra el valor que parece "temblor de daño".

## 📝 Reto verificable

Crea un post-proceso de "confusión" que combine un tinte morado, una distorsión de onda en X e Y y una ligera reducción de saturación, todo activable con una tecla. El efecto debe cubrir el 100% de la pantalla.

**Criterio de aceptación**: al pulsar la tecla, toda la imagen del juego se tiñe de morado, ondula en dos ejes y pierde saturación; al soltarla vuelve exactamente al render original; y en ningún momento aparecen zonas de la escena sin afectar (el `ColorRect` cubre la pantalla completa).

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La pantalla sale negra o vacía | El `ColorRect` no cubre la ventana; ponlo en Full Rect dentro de un `CanvasLayer` |
| No se lee nada de la escena | Falta `hint_screen_texture` en el uniform; decláralo con `filter_linear_mipmap` |
| El efecto no está por encima del juego | El `ColorRect` no está en un `CanvasLayer` superior; añádelo y súbelo en el árbol |
| La distorsión se ve pixelada | Filtro incorrecto; usa `filter_linear_mipmap` en el sampler de pantalla |
| El shader afecta a la UI también | La UI está bajo el mismo `CanvasLayer`; sepárala en otra capa por encima |

## ❓ Preguntas frecuentes

**¿Por qué un `ColorRect` y no la cámara?** En Godot 4 el patrón recomendado para post-proceso 2D/simple es un `ColorRect` fullscreen que lee `hint_screen_texture`; es sencillo y no requiere viewports extra.

**¿`SCREEN_UV` es lo mismo que `UV`?** No. `UV` es local al `ColorRect`; `SCREEN_UV` es la posición en pantalla, que es lo que necesitas para muestrear el render.

**¿Puedo apilar varios efectos?** Sí, con varios `ColorRect` en capas sucesivas, o combinando todo en un solo `fragment()`. Cada capa lee el resultado de la anterior.

**¿Esto funciona en móvil?** Sí, pero leer la pantalla tiene coste; agrupa efectos en un shader y evita muestreos múltiples innecesarios.

## 🔗 Referencias

1. Godot Engine — Screen-reading shaders: <https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html>
2. Godot Engine — Custom post-processing: <https://docs.godotengine.org/en/stable/tutorials/shaders/custom_postprocessing.html>
3. Godot Engine — Canvas item shaders: <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html>

## ⬅️ Clase anterior

[Clase 095 - Shaders 2D: efectos sobre sprites (disolución y outline)](../095-shaders-2d-efectos-sobre-sprites-disolucion-y-outline/README.md)

## ➡️ Siguiente clase

[Clase 097 - Efectos: bloom, vignette, aberración cromática y CRT](../097-efectos-bloom-vignette-aberracion-cromatica-y-crt/README.md)
