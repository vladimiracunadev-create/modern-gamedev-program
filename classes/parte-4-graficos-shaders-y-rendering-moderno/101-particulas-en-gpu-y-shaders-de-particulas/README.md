# Clase 101 — Partículas en GPU y shaders de partículas

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Godot Docs — GPUParticles3D / ParticleProcessMaterial / Particle shaders*
> ⏱️ Duración estimada: **60 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Crear sistemas de partículas simuladas en GPU con `GPUParticles3D`/`GPUParticles2D`, configurar su comportamiento con un **ParticleProcessMaterial** (emisión, velocidad, gravedad, escala y color por vida) y escribir un **shader `shader_type particles`** con `start()`/`process()` para control total, incluyendo animación de **flipbook** (atlas).

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diferenciar `GPUParticles` (GPU) de `CPUParticles` y cuándo usar cada uno.
2. Configurar emisión, velocidad, gravedad, escala y color por vida en un `ParticleProcessMaterial`.
3. Escribir un shader `shader_type particles` con `start()` y `process()`.
4. Usar `COLOR`, `VELOCITY`, `TRANSFORM` y `LIFETIME` dentro del shader de partículas.
5. Animar un atlas de flipbook para partículas de humo/fuego.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | GPU vs CPU particles | Miles de partículas sin frenar la CPU |
| 2 | ParticleProcessMaterial | Configuración rápida sin escribir shader |
| 3 | Emisión y `Amount` | Controla densidad y presupuesto |
| 4 | Velocidad y gravedad | Definen la trayectoria (chispas, humo) |
| 5 | Color/escala por vida | Vida visual de la partícula |
| 6 | `shader_type particles` | Control total con `start()`/`process()` |
| 7 | Flipbook / atlas | Animar sprites de humo y fuego |
| 8 | Draw pass y material de dibujo | Cómo se ve cada partícula |

## 📖 Definiciones y características

- **`GPUParticles3D`**: nodo que simula partículas en la GPU; escala a miles con bajo coste de CPU.
- **`ParticleProcessMaterial`**: material que define la simulación (emisión, fuerzas, curvas por vida) sin escribir código.
- **`shader_type particles`**: shader de simulación con `start()` (al nacer) y `process()` (cada frame).
- **`start()`**: se ejecuta una vez cuando la partícula nace; se inicializan `TRANSFORM`, `VELOCITY`, `COLOR`.
- **`process()`**: se ejecuta cada frame; actualiza posición, color y escala según `DELTA` y `LIFETIME`.
- **Draw pass**: la malla o quad que representa visualmente cada partícula; lleva su propio material de dibujo.
- **Flipbook**: atlas de fotogramas; se recorre variando las UV con la vida para animar la partícula.
- **`EMISSION_TRANSFORM`**: transform del emisor, útil para colocar las partículas en el mundo dentro del shader.

## 🧰 Herramientas y preparación

Godot 4.x, Forward+ (los `GPUParticles` requieren GPU con compute; en Compatibility hay limitaciones). Añade un `GPUParticles3D` a la escena. Necesitas un `QuadMesh` como *Draw Pass Mesh* y un `StandardMaterial3D` o `ShaderMaterial` para dibujar cada partícula. Para el flipbook, ten una textura de atlas (por ejemplo 4×4 fotogramas de humo).

- GPUParticles3D: <https://docs.godotengine.org/en/stable/tutorials/3d/particles/index.html>
- Particle shaders: <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/particle_shader.html>

## 🧪 Laboratorio guiado

Primero un sistema con `ParticleProcessMaterial`, luego un shader de partículas propio con color por vida.

**Paso 1 — Nodo y draw pass.** Crea `GPUParticles3D`. En `Draw Passes > Pass 1` asigna un `QuadMesh` de 0.3×0.3. Pon `Amount = 200` y `Lifetime = 2.0`.

**Paso 2 — ParticleProcessMaterial (humo/chispas).** En `Process Material` crea un `ParticleProcessMaterial` y configura:

- `Emission Shape = Sphere`, radio pequeño.
- `Direction = (0, 1, 0)`, `Spread = 20°`.
- `Initial Velocity = 1.5 – 3.0`.
- `Gravity = (0, -1, 0)` para chispas que caen, o `(0, 1.5, 0)` para humo que sube.
- `Scale Curve`: de grande a pequeño (o al revés para humo que se expande).
- `Color Ramp`: de naranja opaco a transparente (chispas) — activa un `GradientTexture1D`.

Dale Play: ya tienes chispas o humo básico.

**Paso 3 — Material de dibujo con color por vida.** Asigna al draw pass un `ShaderMaterial` con este shader `spatial` que multiplica por `COLOR` (que viene de la simulación) y usa aditivo para brillo:

```glsl
shader_type spatial;
render_mode blend_add, cull_disabled, unshaded, depth_draw_opaque;

uniform sampler2D textura : source_color;

void fragment() {
	vec4 tex = texture(textura, UV);
	ALBEDO = tex.rgb * COLOR.rgb; // COLOR llega del sistema de partículas
	ALPHA = tex.a * COLOR.a;
}
```

**Paso 4 — Shader de partículas propio (`shader_type particles`).** Para control total, sustituye el `ParticleProcessMaterial` por un `ShaderMaterial` con:

```glsl
shader_type particles;

uniform float vel_inicial = 3.0;
uniform vec4 color_nace : source_color = vec4(1.0, 0.7, 0.2, 1.0);
uniform vec4 color_muere : source_color = vec4(0.8, 0.1, 0.0, 0.0);

void start() {
	// Posición y velocidad iniciales (una vez, al nacer).
	vec3 dir = normalize(vec3(
		fract(sin(float(INDEX) * 12.9898) * 43758.5453) - 0.5,
		1.0,
		fract(sin(float(INDEX) * 78.233) * 43758.5453) - 0.5
	));
	VELOCITY = dir * vel_inicial;
	TRANSFORM[3].xyz = EMISSION_TRANSFORM[3].xyz; // nacer en el emisor
	COLOR = color_nace;
}

void process() {
	// Gravedad y avance por frame.
	VELOCITY += vec3(0.0, -4.0, 0.0) * DELTA;
	TRANSFORM[3].xyz += VELOCITY * DELTA;
	// Color por vida: interpola de nace a muere.
	float t = 1.0 - (CUSTOM.y > 0.0 ? 0.0 : 0.0); // placeholder legible
	float vida = 1.0 - (float(INDEX) * 0.0); // ver nota abajo
	COLOR = mix(color_nace, color_muere, clamp(1.0 - VELOCITY.y * 0.0, 0.0, 1.0));
}
```

> Nota práctica: el progreso de vida se obtiene de forma robusta con `float f = fract(TIME);` o, más habitual, usando la rampa de color por vida del `ParticleProcessMaterial`. En un shader puro, guarda el tiempo de nacimiento en `CUSTOM` en `start()` y compáralo con `TIME` en `process()`:

```glsl
void start() {
	CUSTOM.x = TIME;          // guardo cuándo nací
}
void process() {
	float edad = TIME - CUSTOM.x;
	float vida = clamp(edad / 2.0, 0.0, 1.0); // 2.0 = lifetime
	COLOR = mix(color_nace, color_muere, vida);
	VELOCITY += vec3(0.0, -4.0, 0.0) * DELTA;
	TRANSFORM[3].xyz += VELOCITY * DELTA;
}
```

**Paso 5 — Flipbook.** Si tu textura es un atlas 4×4, anima el fotograma según la vida en el shader de dibujo:

```glsl
shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded;
uniform sampler2D atlas : source_color;
uniform int columnas = 4;
uniform int filas = 4;

void fragment() {
	int total = columnas * filas;
	int f = int(COLOR.a * float(total - 1)); // usa un canal como progreso
	vec2 celda = vec2(float(f % columnas), float(f / columnas));
	vec2 uv = (UV + celda) / vec2(float(columnas), float(filas));
	vec4 c = texture(atlas, uv);
	ALBEDO = c.rgb;
	ALPHA = c.a;
}
```

**Resultado visible**: un surtidor de chispas o una columna de humo que cambia de color a lo largo de su vida y, opcionalmente, reproduce una animación de flipbook.

## ✍️ Ejercicios

1. Cambia `Gravity` para pasar de chispas que caen a humo que asciende.
2. Ajusta `Spread` y `Initial Velocity` para un cono de chispas más cerrado.
3. Usa un `Color Ramp` que vaya de blanco a rojo a transparente y descríbelo.
4. En el shader de partículas, guarda la edad en `CUSTOM.x` y escala la partícula con la vida.
5. Sube `Amount` a 2000 y mide FPS; compáralo con `CPUParticles3D` equivalente.
6. Implementa el flipbook con un atlas 4×4 y sincronízalo con el lifetime.

## 📝 Reto verificable

Construye un efecto de **fuego de campamento**: un `GPUParticles3D` con al menos 300 partículas que nacen en la base, ascienden, se hacen más pequeñas y cambian de naranja brillante a rojo/transparente por su vida, con material aditivo.

**Criterio de aceptación**: al reproducir la escena las partículas suben desde el emisor, reducen su escala y transicionan de color a lo largo de la vida sin saltos; el sistema corre a los FPS objetivo con el `Amount` indicado, y el color por vida se controla por rampa o dentro del shader.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| No se ve ninguna partícula | Falta `Draw Pass` mesh o `Amount = 0`; asigna un `QuadMesh` y sube `Amount` |
| Las partículas no se mueven | Sin `Process Material` ni shader de proceso; asigna uno |
| Todas nacen en el mismo punto amontonadas | `Emission Shape = Point`; usa `Sphere`/`Box` con radio |
| El color por vida no cambia | No usas `Color Ramp` ni interpolas en `process()`; añade la rampa |
| El flipbook se ve congelado | No actualizas el fotograma con la vida; calcula la celda por edad |
| FPS cae con muchas partículas | `Amount` alto con quads grandes; reduce tamaño o cantidad |

## ❓ Preguntas frecuentes

**¿GPU o CPU particles?** GPU para miles de partículas y efectos ambientales; CPU cuando necesitas colisiones/lógica en el hilo principal o hardware sin compute.

**¿`start()` y `process()` reemplazan al ParticleProcessMaterial?** Sí: un `ShaderMaterial` de tipo `particles` sustituye al process material y te da control total, a cambio de escribir el código.

**¿Cómo obtengo el progreso de vida en el shader?** Guarda `TIME` en `CUSTOM.x` en `start()` y calcula `edad = TIME - CUSTOM.x` en `process()`, dividiendo por el lifetime.

**¿Las partículas reciben luz?** Con `unshaded` no; si quieres que la luz las afecte, quita `unshaded` en el material de dibujo (más caro).

## 🔗 Referencias

- Godot — Particle systems (3D): <https://docs.godotengine.org/en/stable/tutorials/3d/particles/index.html>
- Godot — Particle shader: <https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/particle_shader.html>
- Godot — ParticleProcessMaterial (clase): <https://docs.godotengine.org/en/stable/classes/class_particleprocessmaterial.html>

## ⬅️ Clase anterior

[Clase 100 - Agua, olas y superficies animadas](../100-agua-olas-y-superficies-animadas/README.md)

## ➡️ Siguiente clase

[Clase 102 - Instancing y MultiMesh: miles de objetos](../102-instancing-y-multimesh-miles-de-objetos/README.md)
