# Clase 094 — Normal mapping y detalle de superficie

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Godot Engine 4.x — Spatial shaders (NORMAL_MAP) e Importing images*
> ⏱️ Duración estimada: **60 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Añadir relieve a superficies planas sin sumar un solo polígono usando **normal mapping**. Entenderás que un normal map guarda direcciones en **espacio tangente** codificadas como color, cómo Godot lo aplica con `NORMAL_MAP`, y por qué el detalle solo se aprecia cuando la luz se mueve. Verás un plano liso comportarse como ladrillo, tela o metal repujado bajo una luz en movimiento, y conocerás qué es el **parallax mapping** como paso siguiente.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar qué información guarda un **normal map** y por qué es azulado.
2. Describir el **espacio tangente** y por qué permite reutilizar un mapa en cualquier cara.
3. Aplicar un normal map con **`NORMAL_MAP`** en un shader spatial de Godot 4.
4. Controlar la **intensidad** del relieve con `NORMAL_MAP_DEPTH`.
5. Distinguir cuándo conviene normal mapping y cuándo hace falta **parallax** o geometría real.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Normales por vértice vs por textura | El detalle fino no cabe en la malla |
| 2 | Codificación RGB de un normal map | Explica el característico color azul |
| 3 | Espacio tangente | Hace el mapa reutilizable y portátil |
| 4 | `NORMAL_MAP` en Godot | Godot hace la transformación de espacio por ti |
| 5 | Intensidad del relieve | Ajusta cuánto "sobresale" el detalle |
| 6 | Importar como Normal Map | Evita colores mal interpretados |
| 7 | Parallax (mención) | Añade profundidad aparente real |

## 📖 Definiciones y características

- **Normal map**: textura que guarda una dirección de normal por píxel en los canales RGB. Clave: azul dominante porque Z (hacia fuera) es ~1.
- **Espacio tangente**: sistema local a la superficie (tangente, bitangente, normal). Clave: permite usar el mismo mapa en cualquier orientación de la cara.
- **`NORMAL_MAP`**: entrada del shader spatial que recibe el color RGB del mapa. Clave: Godot lo convierte de tangente a vista automáticamente.
- **`NORMAL_MAP_DEPTH`**: multiplicador de intensidad del relieve. Clave: 1.0 normal, >1 exagera, 0 lo anula.
- **`hint_normal`**: hint del uniform que indica que la textura es un normal map lineal. Clave: sin él, el color se malinterpreta.
- **Relieve percibido**: ilusión creada al alterar cómo la luz golpea cada píxel. Clave: solo se ve al mover luz o cámara.
- **Parallax mapping**: desplaza las UV según altura para simular profundidad real. Clave: normal map "gira" la luz, parallax "mueve" la textura.
- **Silueta**: el borde de la malla no cambia con normal map. Clave: por eso una esfera de pocos polígonos sigue viéndose facetada en el contorno.

## 🧰 Herramientas y preparación

Usa **Godot 4.x**, proyecto 3D. Necesitas una escena con un `MeshInstance3D` con un `PlaneMesh` (o `QuadMesh`) grande, un `OmniLight3D` que puedas mover y una `Camera3D`. Consigue un normal map (por ejemplo de ladrillo o piedra); al importarlo, en la pestaña Import marca que es un **Normal Map**. Revisa los [Spatial shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html) y [Importing images](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html). Lo observable: el plano liso muestra sombras de relieve que se desplazan cuando mueves la luz.

## 🧪 Laboratorio guiado

Aplicaremos un normal map a un plano y animaremos la luz para revelar el relieve.

**Paso 1 — Shader base con albedo y normal.** Crea un `ShaderMaterial` en el plano:

```glsl
shader_type spatial;

uniform sampler2D albedo_tex : source_color, hint_default_white;
uniform sampler2D normal_tex : hint_normal;
uniform float profundidad : hint_range(0.0, 4.0) = 1.0;
uniform vec2 tiling = vec2(4.0, 4.0);

void fragment() {
	vec2 uv = UV * tiling;              // repetir el patrón varias veces
	ALBEDO = texture(albedo_tex, uv).rgb;
	NORMAL_MAP = texture(normal_tex, uv).rgb;   // aquí ocurre la magia
	NORMAL_MAP_DEPTH = profundidad;             // intensidad del relieve
	ROUGHNESS = 0.7;
}
```

**Paso 2 — Asignar la textura.** En el inspector del material, arrastra tu normal map al uniform `normal_tex` y (si tienes) una difusa a `albedo_tex`. Si no tienes albedo, deja el blanco por defecto.

**Paso 3 — Mover la luz para revelar el relieve.** Adjunta un script al `OmniLight3D`:

```gdscript
extends OmniLight3D

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	# La luz orbita sobre el plano para que el relieve "respire".
	global_position = Vector3(cos(t) * 3.0, 2.0, sin(t) * 3.0)
```

Ejecuta (F6). El plano, geométricamente liso, muestra ladrillos con sombras que se mueven al orbitar la luz: eso es el normal map alterando `N·L` por píxel.

**Paso 4 — Jugar con la intensidad.** Anima `profundidad` desde GDScript:

```gdscript
func _process(delta: float) -> void:
	var d: float = 1.0 + sin(Time.get_ticks_msec() * 0.002) * 1.5
	material.set_shader_parameter("profundidad", max(d, 0.0))
```

Con `profundidad` alta el relieve se exagera (parece tallado); con 0 el plano vuelve a verse liso, demostrando que todo el efecto vive en la normal.

**Paso 5 — Combinar con roughness texturizado (opcional).** Para más realismo, deja que un mapa controle también lo pulido de cada zona:

```glsl
uniform sampler2D rough_tex : hint_default_white;
// dentro de fragment(), tras leer el normal:
// ROUGHNESS = texture(rough_tex, uv).r;   // zonas oscuras = pulidas
```

Así los surcos entre ladrillos pueden verse mates y las caras más lisas, reforzando la ilusión de relieve real sin tocar la geometría.

## ✍️ Ejercicios

1. Pon `profundidad` en 0 y confirma que el plano se ve completamente liso bajo la luz.
2. Duplica el `tiling` a `vec2(8.0, 8.0)` y observa el patrón repetirse más veces.
3. Detén la luz y mueve la cámara: comprueba que el relieve casi no cambia (el normal map depende de la luz).
4. Aplica el mismo mapa a una esfera y observa que la silueta sigue siendo lisa.
5. Combina el normal map con `ROUGHNESS` texturizado para simular zonas más pulidas.
6. Invierte el canal verde del mapa (`1.0 - g`) y explica por qué el relieve se ve "hundido".

## 📝 Reto verificable

Crea un muro de piedra: un `PlaneMesh` con normal map de roca, `tiling` ajustable y una `profundidad` controlable en tiempo real con las teclas de flecha (arriba/abajo suman/restan intensidad). Una luz debe orbitar el muro.

**Criterio de aceptación**: al pulsar las flechas cambia visiblemente la profundidad del relieve; con la luz orbitando, las sombras internas de la piedra se desplazan de forma coherente; y al poner la profundidad en 0 el muro se ve plano, demostrando que el detalle proviene solo del normal map.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El relieve se ve invertido (hundido en vez de saliente) | Convención de canal Y distinta; invierte el verde o reimporta con la opción adecuada |
| Colores raros / relieve nulo | Uniform sin `hint_normal` o textura no marcada como Normal Map al importar |
| No se aprecia nada de detalle | La luz no se mueve; el normal map solo luce con luz o cámara en movimiento |
| El patrón se estira | Falta tiling o las UV de la malla son incorrectas; multiplica `UV` por un factor |
| La silueta sigue facetada | Normal map no cambia geometría; usa más polígonos o parallax si necesitas contorno |

## ❓ Preguntas frecuentes

**¿Por qué los normal maps son azules?** Porque la mayoría de píxeles apuntan hacia afuera (Z≈1), que se codifica como azul; los desvíos en X/Y tiñen de rojo/verde.

**¿Necesito calcular tangentes yo?** No. Godot genera tangentes al importar la malla y hace la conversión de espacio; tú solo escribes `NORMAL_MAP`.

**¿Cuándo no basta el normal map?** Cuando el detalle debe verse en la silueta o desde ángulos rasantes con profundidad real: ahí entra parallax o geometría/displacement.

**¿Qué es parallax entonces?** Una técnica que desplaza las UV según un mapa de altura para simular profundidad; el borde sigue plano, pero la superficie parece tener volumen al mirar de lado.

**¿Puedo animar el normal map?** Sí: sumando un desplazamiento a las UV con `TIME` (por ejemplo agua) o mezclando dos mapas, se logra relieve en movimiento sin cambiar la malla.

## 🔗 Referencias

1. Godot Engine — Spatial shaders (NORMAL_MAP): <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html>
2. Godot Engine — Importing images (Normal Map): <https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html>
3. Godot Engine — Standard Material 3D (Normal): <https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html>

## ➡️ Siguiente clase

[Clase 095 - Shaders 2D: efectos sobre sprites (disolución y outline)](../095-shaders-2d-efectos-sobre-sprites-disolucion-y-outline/README.md)
