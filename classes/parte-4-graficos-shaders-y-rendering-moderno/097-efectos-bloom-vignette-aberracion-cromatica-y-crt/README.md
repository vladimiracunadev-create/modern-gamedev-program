# Clase 097 — Efectos: bloom, vignette, aberración cromática y CRT

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Godot Engine 4.x — Environment (Glow) y Screen-reading shaders*
> ⏱️ Duración estimada: **70 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir un conjunto de efectos de post-proceso combinables que dan personalidad visual a un juego: **bloom/glow** (vía `Environment` y comprensión por shader), **vignette** (oscurecer los bordes según la distancia al centro), **aberración cromática** (desplazar los canales RGB por separado) y un look **CRT** con scanlines y curvatura. Todo se apoya en el setup de la clase anterior: un `ColorRect` fullscreen dentro de un `CanvasLayer` que lee la pantalla.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Activar **glow/bloom** con `WorldEnvironment` y explicar de dónde sale el resplandor.
2. Programar una **vignette** basada en la distancia de `SCREEN_UV` al centro.
3. Implementar **aberración cromática** muestreando R, G y B con offsets distintos.
4. Crear un efecto **CRT** con scanlines por `sin` y una ligera curvatura de pantalla.
5. **Combinar** los efectos con uniforms que permitan encender/apagar cada uno.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Glow/bloom por Environment | La vía correcta y barata en Godot |
| 2 | Bloom conceptual por shader | Entender qué hace el motor por dentro |
| 3 | Vignette | Enfoca la mirada y da drama |
| 4 | Aberración cromática | Toque de lente/retro sin coste alto |
| 5 | Scanlines CRT | Estética de monitor antiguo |
| 6 | Curvatura de pantalla | Completa la ilusión del tubo CRT |
| 7 | Combinar efectos | Un shader modular por uniforms |

## 📖 Definiciones y características

- **Bloom/Glow**: resplandor que sangra desde las zonas más brillantes. Clave: en Godot se activa en `Environment`, no hace falta shader.
- **Umbral de glow (HDR threshold)**: brillo mínimo para que un píxel resplandezca. Clave: solo lo muy luminoso florece.
- **Vignette**: oscurecimiento radial hacia los bordes. Clave: `length(SCREEN_UV - 0.5)` mide la distancia al centro.
- **Aberración cromática**: separación de canales RGB como una lente barata. Clave: cada canal se muestrea con un offset distinto.
- **Scanline**: línea oscura horizontal repetida, típica del CRT. Clave: se genera con `sin(SCREEN_UV.y * n)`.
- **Curvatura CRT**: deformación que abomba la imagen. Clave: se aplica distorsionando `SCREEN_UV` desde el centro.
- **Efecto combinable**: cada efecto controlado por un uniform de intensidad. Clave: 0 lo apaga sin quitar el nodo.
- **`SCREEN_UV` centrada**: `SCREEN_UV - 0.5` pone el origen en el centro. Clave: base de vignette y curvatura.

## 🧰 Herramientas y preparación

Usa **Godot 4.x**. Reutiliza el setup de la clase 096: un `CanvasLayer` con un `ColorRect` en Full Rect y un `ShaderMaterial`. Para el bloom, añade un `WorldEnvironment` con un `Environment`; activa **Glow** y sube el umbral. Ten a mano una escena con algún objeto brillante (emisivo) para que el bloom tenga qué hacer florecer. Consulta [Glow del Environment](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html) y [Screen-reading shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html). Lo observable: la escena con resplandor, bordes oscurecidos, franjas de color y líneas de monitor antiguo.

## 🧪 Laboratorio guiado

Activaremos glow por Environment y luego programaremos vignette + aberración + CRT en un solo shader.

**Paso 1 — Bloom con Environment.** Añade un `WorldEnvironment`, crea un `Environment` y en la sección **Glow** actívalo. Sube `Glow → HDR Threshold` a ~1.0 y da algo de `Intensity`. Pon un material con `EMISSION` fuerte en un objeto (ver clase 092). Ejecuta: las zonas emisivas resplandecen. Este bloom lo hace el motor; tu shader no necesita recrearlo.

**Paso 2 — Shader combinado: vignette.** En el `ColorRect`:

```glsl
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_fuerza : hint_range(0.0, 2.0) = 0.8;
uniform float vignette_radio : hint_range(0.0, 1.0) = 0.75;

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;

	// Distancia al centro para oscurecer bordes.
	float d = length(SCREEN_UV - vec2(0.5));
	float vig = smoothstep(vignette_radio, vignette_radio - 0.45, d);
	col *= mix(1.0, vig, vignette_fuerza);

	COLOR = vec4(col, 1.0);
}
```

**Paso 3 — Aberración cromática y CRT.** Amplía el `fragment()`:

```glsl
uniform float aberracion : hint_range(0.0, 0.01) = 0.003;
uniform float scanline_fuerza : hint_range(0.0, 1.0) = 0.3;
uniform float curvatura : hint_range(0.0, 0.5) = 0.1;

void fragment() {
	// 1) Curvatura CRT: abombar las UV desde el centro.
	vec2 uv = SCREEN_UV - 0.5;
	uv *= 1.0 + curvatura * dot(uv, uv);
	uv += 0.5;

	// 2) Aberración cromática: cada canal con su offset.
	float r = texture(screen_tex, uv + vec2(aberracion, 0.0)).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - vec2(aberracion, 0.0)).b;
	vec3 col = vec3(r, g, b);

	// 3) Vignette.
	float d = length(uv - vec2(0.5));
	float vig = smoothstep(vignette_radio, vignette_radio - 0.45, d);
	col *= mix(1.0, vig, vignette_fuerza);

	// 4) Scanlines: franjas oscuras horizontales.
	float linea = sin(uv.y * 800.0) * 0.5 + 0.5;
	col *= mix(1.0, linea, scanline_fuerza);

	COLOR = vec4(col, 1.0);
}
```

Ejecuta (F6): la escena luce como un monitor CRT, con bordes oscuros, franjas de color en los contornos y líneas de barrido. Sube `curvatura` para abombar más la imagen.

**Paso 4 — Combinables desde GDScript.** Enciende cada efecto por separado:

```gdscript
extends ColorRect

func modo_retro(activo: bool) -> void:
	material.set_shader_parameter("scanline_fuerza", 0.3 if activo else 0.0)
	material.set_shader_parameter("aberracion", 0.003 if activo else 0.0)
	material.set_shader_parameter("curvatura", 0.1 if activo else 0.0)
```

Pon todo a 0 y el shader se vuelve transparente al render; sube uno a uno para ver la contribución de cada efecto.

## ✍️ Ejercicios

1. Aumenta el `HDR Threshold` del glow y observa cómo menos zonas florecen.
2. Sube `aberracion` a 0.008 y describe el efecto tipo "gafas 3D" en los bordes.
3. Cambia la frecuencia de scanlines (`uv.y * N`) y encuentra la que parece pantalla de baja resolución.
4. Haz que la vignette lata suavemente con `sin(TIME)` para simular latido bajo estrés.
5. Anima la aberración con la vida del jugador: a menos vida, más separación de canales.
6. Añade un leve ruido temporal (grano) multiplicando el color por un `fract(sin(...))` variable con `TIME`.

## 📝 Reto verificable

Crea un "modo arcade" que combine bloom (por Environment), vignette, aberración cromática y scanlines CRT con curvatura, todo activable con una sola tecla, y una intensidad global que module los cuatro a la vez.

**Criterio de aceptación**: al activar el modo, la escena adquiere resplandor en las zonas brillantes, bordes oscurecidos, separación RGB visible en los contornos y líneas de barrido con ligera curvatura; al desactivarlo, la imagen vuelve al render limpio; y un único parámetro de intensidad sube o baja los cuatro efectos de forma coherente.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| No hay bloom aunque el Environment tiene Glow | Ningún objeto supera el umbral HDR; usa `EMISSION` fuerte o baja el threshold |
| La aberración se ve solo en el centro | El offset es constante; escálalo por la distancia al centro para más efecto en bordes |
| Las scanlines parpadean feo (moiré) | Frecuencia mal ajustada a la resolución; prueba valores y activa filtro lineal |
| La curvatura muestra bordes negros | Al abombar, las UV salen de 0–1; recorta con `if` o oscurece fuera de rango |
| Todo se ve demasiado oscuro | Vignette + scanlines se suman; baja `vignette_fuerza` o `scanline_fuerza` |

## ❓ Preguntas frecuentes

**¿Bloom por shader o por Environment?** En Godot 4 usa el Glow del `Environment`: es multi-paso, con blur real y HDR, difícil de igualar con un shader simple. El shader ayuda a entender el concepto.

**¿Por qué separar R, G y B?** Simula la dispersión cromática de una lente real; el ojo lee esos flecos de color como "objetivo barato" o estética retro.

**¿La curvatura afecta al rendimiento?** Es solo aritmética sobre las UV, muy barata. Lo caro es leer la pantalla varias veces (aberración hace tres muestreos).

**¿Puedo aplicar esto solo al juego y no a la UI?** Sí: pon la UI en un `CanvasLayer` por encima del `ColorRect` de post-proceso para que no la afecte.

## 🔗 Referencias

1. Godot Engine — Environment y post-processing (Glow): <https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html>
2. Godot Engine — Screen-reading shaders: <https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html>
3. Godot Engine — Custom post-processing: <https://docs.godotengine.org/en/stable/tutorials/shaders/custom_postprocessing.html>

## ➡️ Siguiente clase

[Clase 098 - Sombras: shadow mapping y calidad](../098-sombras-shadow-mapping-y-calidad/README.md)
