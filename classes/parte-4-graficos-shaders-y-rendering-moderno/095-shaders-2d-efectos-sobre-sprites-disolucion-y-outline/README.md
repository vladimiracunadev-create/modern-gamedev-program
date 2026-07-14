# Clase 095 — Shaders 2D: efectos sobre sprites (disolución y outline)

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Godot Engine 4.x — CanvasItem shaders (2D shading)*
> ⏱️ Duración estimada: **65 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Escribir shaders **`canvas_item`** para dar vida a sprites 2D. Harás un efecto de **disolución** con textura de ruido y `step` (con un borde emisivo brillante), un **outline** muestreando el alfa de píxeles vecinos y un **hit-flash** de daño. Aprenderás a leer la textura del sprite con `texture(TEXTURE, UV)`, a manipular `COLOR` y a controlar el progreso del efecto desde GDScript para dispararlo en el momento justo del juego.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Escribir un shader **`canvas_item`** que lea y modifique el color de un sprite.
2. Implementar una **disolución** con ruido, `step`/`smoothstep` y un borde emisivo.
3. Crear un **contorno (outline)** muestreando el alfa de texels vecinos.
4. Añadir un **hit-flash** que tiñe el sprite de blanco al recibir daño.
5. Controlar el **progreso** de cada efecto desde GDScript con `set_shader_parameter`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | `shader_type canvas_item` | Base de todo shader 2D en Godot |
| 2 | `TEXTURE`, `UV`, `COLOR` | Leer el sprite y devolver el píxel final |
| 3 | Ruido para disolución | Da forma orgánica al desvanecimiento |
| 4 | `step` y `smoothstep` | Crean el umbral y el borde de la disolución |
| 5 | Borde emisivo | Toque visual de fuego/energía al disolver |
| 6 | Muestreo de vecinos | Técnica para detectar el contorno |
| 7 | Uniforms desde GDScript | Sincronizar el efecto con la lógica del juego |

## 📖 Definiciones y características

- **`canvas_item`**: tipo de shader para nodos 2D (Sprite2D, TextureRect, etc.). Clave: trabaja en `fragment()` sobre `COLOR`.
- **`TEXTURE`**: la textura del nodo; se lee con `texture(TEXTURE, UV)`. Clave: `UV` va de 0 a 1 sobre el sprite.
- **`COLOR`**: color de salida del fragmento, ya multiplicado por el modulate. Clave: lo que escribas aquí es el píxel final.
- **Textura de ruido**: patrón pseudoaleatorio (un `NoiseTexture2D`) que guía la disolución. Clave: su valor decide qué píxel desaparece primero.
- **`step(a, x)`**: 0 si `x<a`, 1 si no. Clave: crea el corte duro entre visible y disuelto.
- **`smoothstep(a, b, x)`**: transición suave entre a y b. Clave: útil para el ancho del borde.
- **Outline por vecinos**: si un píxel es transparente pero un vecino no, es contorno. Clave: se muestrea el alfa desplazando `UV`.
- **Hit-flash**: mezcla del color con blanco durante unos frames. Clave: feedback de daño instantáneo y legible.

## 🧰 Herramientas y preparación

Usa **Godot 4.x**, proyecto 2D. Ten un `Sprite2D` con una textura con transparencia (un personaje o icono recortado). Crea un `NoiseTexture2D` (con un `FastNoiseLite` dentro) para la disolución. Añade al `Sprite2D` un `ShaderMaterial`. Consulta [Canvas item shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html) y el tutorial [Your first 2D shader](https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_2d_shader.html). Lo observable: el sprite se desintegra con un borde brillante y muestra un contorno de color.

## 🧪 Laboratorio guiado

Montaremos disolución con borde emisivo y un outline, controlados desde código.

**Paso 1 — Shader de disolución.** Crea el `ShaderMaterial` del sprite:

```glsl
shader_type canvas_item;

uniform sampler2D ruido_tex : repeat_enable;
uniform float progreso : hint_range(0.0, 1.0) = 0.0;
uniform float ancho_borde : hint_range(0.0, 0.2) = 0.05;
uniform vec4 color_borde : source_color = vec4(1.0, 0.6, 0.1, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);          // píxel original del sprite
	float n = texture(ruido_tex, UV).r;       // valor de ruido 0..1

	// Todo píxel con ruido por debajo del progreso desaparece.
	if (n < progreso) {
		discard;                               // no dibujar este fragmento
	}

	// Borde: los píxeles justo por encima del umbral brillan.
	float borde = smoothstep(progreso, progreso + ancho_borde, n);
	vec3 rgb = mix(color_borde.rgb, tex.rgb, borde);

	COLOR = vec4(rgb, tex.a);
}
```

**Paso 2 — Controlar el progreso desde GDScript.** Anima la disolución al pulsar una tecla:

```gdscript
extends Sprite2D

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_accept"):
		var p: float = material.get_shader_parameter("progreso")
		material.set_shader_parameter("progreso", min(p + delta * 0.5, 1.0))
```

Ejecuta la escena y mantén Enter: el sprite se desintegra desde las zonas de ruido bajo, con un reborde naranja incandescente. Sube `ancho_borde` y el fuego del contorno se ensancha.

**Paso 3 — Un shader de outline.** En OTRO sprite (o un segundo material), detecta el contorno por vecinos:

```glsl
shader_type canvas_item;

uniform vec4 color_outline : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float grosor : hint_range(0.0, 8.0) = 2.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * grosor;   // tamaño de un texel * grosor

	// Suma del alfa de los cuatro vecinos.
	float a = 0.0;
	a += texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	a += texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	a += texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	a += texture(TEXTURE, UV - vec2(0.0, px.y)).a;

	// Si yo soy transparente pero un vecino no, soy contorno.
	float es_borde = step(0.001, a) * (1.0 - tex.a);
	COLOR = mix(tex, color_outline, es_borde);
}
```

**Paso 4 — Hit-flash de daño.** Añade a un shader de sprite un tinte blanco controlable:

```glsl
uniform float flash : hint_range(0.0, 1.0) = 0.0;
// dentro de fragment(), tras leer tex:
// COLOR.rgb = mix(tex.rgb, vec3(1.0), flash);
```

Y desde GDScript, un pulso al recibir daño:

```gdscript
func recibir_dano() -> void:
	material.set_shader_parameter("flash", 1.0)
	await get_tree().create_timer(0.08).timeout
	material.set_shader_parameter("flash", 0.0)
```

## ✍️ Ejercicios

1. Invierte la disolución (`n > 1.0 - progreso`) para que el sprite se materialice en vez de desaparecer.
2. Cambia el color del borde a azul eléctrico y sube su intensidad multiplicándolo por 2.
3. Añade al outline un octavo muestreo en diagonales para un contorno más redondo.
4. Haz que el `grosor` del outline lata con `sin(TIME)` para un efecto de selección pulsante.
5. Encadena hit-flash + una pequeña disolución cuando la vida llegue a 0.
6. Expón el `progreso` con una barra de vida: a menos vida, más disuelto el sprite.

## 📝 Reto verificable

Programa un enemigo 2D que, al morir, se disuelva en 0.6 s con borde emisivo y que, mientras vive, muestre un outline de color cuando el ratón está encima (hover). El daño produce un hit-flash blanco de un frame.

**Criterio de aceptación**: al pasar el ratón por encima aparece el contorno; al recibir daño el sprite destella en blanco brevemente; y al morir se desintegra por completo mostrando el borde incandescente antes de desaparecer, todo controlado por parámetros desde GDScript.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La disolución no aparece | El `NoiseTexture2D` no está asignado o su ruido es constante; asigna uno con `FastNoiseLite` |
| El borde no brilla | Con blend normal el emisivo se ve tenue; sube el color o usa `render_mode blend_add` |
| El outline sale por dentro del sprite | Estás pintando donde `tex.a>0`; recuerda multiplicar por `(1.0 - tex.a)` |
| El outline se recorta en el borde de la imagen | El sprite no tiene margen transparente; añade padding a la textura |
| El flash se queda encendido | No reseteaste `flash` a 0; usa un timer o un `await` |

## ❓ Preguntas frecuentes

**¿`discard` o alfa 0?** `discard` descarta el fragmento por completo (útil en disolución); poner alfa 0 aún procesa el píxel. Para cortes duros, `discard` es más claro.

**¿Por qué `TEXTURE_PIXEL_SIZE`?** Da el tamaño de un texel en UV, así el grosor del outline es consistente sin importar la resolución del sprite.

**¿El outline funciona en cualquier sprite?** Necesita margen transparente alrededor del dibujo; si el arte toca el borde de la imagen, el contorno se corta.

**¿Puedo combinar todos los efectos?** Sí, en un mismo `fragment()`: primero lees `TEXTURE`, aplicas hit-flash, luego outline y finalmente la disolución con `discard`.

## 🔗 Referencias

1. Godot Engine — Canvas item shaders: <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html>
2. Godot Engine — Your first 2D shader: <https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_2d_shader.html>
3. Godot Engine — Clase NoiseTexture2D: <https://docs.godotengine.org/en/stable/classes/class_noisetexture2d.html>

## ➡️ Siguiente clase

[Clase 096 - Screen-space y post-procesado](../096-screen-space-y-post-procesado/README.md)
