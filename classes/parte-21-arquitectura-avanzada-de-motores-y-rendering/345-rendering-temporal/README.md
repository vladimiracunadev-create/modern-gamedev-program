# Clase 345 — Rendering temporal

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Akenine-Möller et al., «Real-Time Rendering» (temporal methods) · Charlas de SIGGRAPH sobre TAA*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender la idea que sostiene el rendering en tiempo real moderno: **reutilizar el trabajo de los frames anteriores**. Si a 60 fps la imagen cambia poco entre un frame y el siguiente, tirar todo el resultado y recalcularlo desde cero es un desperdicio. Acumular información a lo largo del tiempo permite obtener con un cuarto del coste algo que con fuerza bruta sería imposible.

Es la base del antialiasing moderno (TAA), de las sombras y reflejos con ruido acumulado, de la iluminación global en tiempo real y del upscaling temporal de la clase siguiente. Y es también la fuente de los artefactos que todo jugador conoce aunque no sepa nombrarlos: **ghosting**, imagen borrosa en movimiento, parpadeo en bordes finos y estelas detrás de objetos rápidos.

Vas a estudiar el mecanismo completo —jitter, motion vectors, reproyección, historial y rechazo— y, sobre todo, **por qué falla** y qué se hace para mitigarlo.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar por qué acumular en el tiempo reduce el coste por frame.
2. Describir el ciclo completo de una técnica temporal.
3. Explicar qué son los motion vectors y por qué son imprescindibles.
4. Explicar el jitter de subpíxel y su papel en el antialiasing temporal.
5. Identificar ghosting, parpadeo, borrosidad y desoclusión, y su causa.
6. Aplicar las mitigaciones estándar: clamping de vecindario, rechazo y pesos.
7. Decidir cuándo TAA es la opción correcta y cuándo no.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Coherencia temporal | La observación de la que sale todo. |
| 2 | Historial | El búfer que acumula frames anteriores. |
| 3 | Motion vectors | Sin ellos no se puede reutilizar nada en movimiento. |
| 4 | Reproyección | Encontrar dónde estaba este píxel el frame pasado. |
| 5 | Jitter de subpíxel | Lo que convierte acumulación en antialiasing. |
| 6 | Desoclusión | Lo que aparece detrás de un objeto no tiene historial. |
| 7 | Ghosting | El artefacto característico. |
| 8 | Clamping de vecindario | La mitigación principal. |
| 9 | Rechazo del historial | Cuándo descartar en vez de mezclar. |
| 10 | Cuándo no usarlo | Pixel art, competitivo, VR. |

## 📖 Definiciones y características

- **Coherencia temporal**: la mayor parte de la imagen cambia poco entre frames consecutivos. Clave: es la observación que hace viables estas técnicas.
- **Búfer de historial**: imagen acumulada de frames anteriores. Clave: es el estado que se reutiliza.
- **Acumulación temporal**: mezclar el frame actual con el historial. Clave: reduce ruido y aumenta la resolución efectiva.
- **Factor de mezcla (blend factor)**: cuánto pesa el frame nuevo. Clave: típicamente 0,05–0,15; más bajo acumula mejor y da más ghosting.
- **Motion vector**: desplazamiento en pantalla de cada píxel respecto al frame anterior. Clave: es lo que permite reproyectar.
- **Búfer de velocidad**: textura que guarda los motion vectors. Clave: hay que rellenarla para todo: geometría, cámara, animación y skinning.
- **Reproyección**: buscar en el historial la posición que este píxel ocupaba antes. Clave: si falla, el resultado es basura mezclada.
- **Jitter**: desplazamiento subpíxel de la proyección, distinto cada frame. Clave: convierte la acumulación en supermuestreo.
- **Secuencia de Halton**: sucesión cuasi-aleatoria usada para el jitter. Clave: cubre el píxel de forma uniforme sin agrupaciones.
- **TAA (temporal anti-aliasing)**: antialiasing por acumulación con jitter. Clave: barato y con artefactos característicos.
- **Desoclusión**: superficie que se revela al moverse algo. Clave: no tiene historial válido; hay que detectarla.
- **Ghosting**: estela o rastro de un objeto en movimiento. Clave: historial que no debería haberse mezclado.
- **Clamping de vecindario**: limitar el historial al rango de colores de los píxeles vecinos actuales. Clave: la mitigación más eficaz y barata.
- **Caja AABB de color**: el rango de color del vecindario en un espacio de color. Clave: define el límite del clamping.
- **Rechazo del historial**: descartarlo cuando no es fiable. Clave: mejor un frame con ruido que uno con ghosting.
- **Parpadeo (flickering)**: inestabilidad de píxeles finos. Clave: lo que el TAA suele arreglar, y a veces empeora.
- **Borrosidad en movimiento**: pérdida de detalle al mover la cámara. Clave: el precio del TAA; se mitiga con nitidez posterior.

## 🧰 Herramientas y preparación

Godot 4.x, que trae TAA en el renderizador Forward+ (`Project Settings → Rendering → Anti Aliasing → Use TAA`). Trabajaremos en `res://temporal/` con shaders de pantalla completa para ver el mecanismo. Necesitas GPU para la parte visual; los cálculos de jitter y reproyección se pueden verificar en CPU sin ella. Ten a mano la [documentación de antialiasing de Godot](https://docs.godotengine.org/en/stable/tutorials/3d/3d_antialiasing.html) y la Parte 4 sobre shaders y post-procesado.

## 🧪 Laboratorio guiado

1. **La idea, en un dibujo:**

```text
Sin temporal: cada frame se calcula desde cero
  Frame 1: [calcular todo] → imagen 1
  Frame 2: [calcular todo] → imagen 2       (se tiró todo el trabajo de la 1)

Con temporal: cada frame aporta y acumula
  Frame 1: [calcular 1 muestra/píxel] → historial = imagen 1
  Frame 2: [calcular 1 muestra/píxel] → historial = 0,9 × reproyectar(historial) + 0,1 × nueva
  Frame 3: ...
  Tras 8 frames: calidad de ~8 muestras/píxel al coste de 1.

  Y el precio: si la reproyección falla, se mezcla lo que NO toca.
```

2. **El jitter.** Lo que convierte acumular en antialiasing:

```gdscript
class_name JitterTemporal
extends RefCounted

const N_MUESTRAS := 8

static func halton(indice: int, base: int) -> float:
	# Secuencia de Halton: cuasi-aleatoria y uniforme. Con aleatoriedad pura,
	# las muestras se agrupan y quedan zonas del píxel sin cubrir.
	var f := 1.0
	var r := 0.0
	var i := indice
	while i > 0:
		f /= float(base)
		r += f * float(i % base)
		i /= base
	return r

static func offset(frame: int) -> Vector2:
	var i := (frame % N_MUESTRAS) + 1
	# Centrado en [-0.5, 0.5]: el desplazamiento es de MEDIO píxel como mucho.
	return Vector2(halton(i, 2) - 0.5, halton(i, 3) - 0.5)

static func aplicar(proyeccion: Projection, offset_px: Vector2,
					ancho: int, alto: int) -> Projection:
	# El jitter va en la MATRIZ DE PROYECCIÓN, no moviendo la cámara: mover la
	# cámara cambiaría la posición del mundo y arruinaría los motion vectors.
	var p := proyeccion
	p[2][0] += offset_px.x * 2.0 / float(ancho)
	p[2][1] += offset_px.y * 2.0 / float(alto)
	return p
```

```gdscript
# Verificable sin GPU: las 8 muestras deben cubrir el píxel de forma uniforme.
func _verificar_cobertura() -> Dictionary:
	var cuadrantes := [0, 0, 0, 0]
	for f in JitterTemporal.N_MUESTRAS:
		var o := JitterTemporal.offset(f)
		var q := (1 if o.x > 0.0 else 0) + (2 if o.y > 0.0 else 0)
		cuadrantes[q] += 1
	# Con 8 muestras y Halton, cada cuadrante recibe 1-3. Si alguno recibe 0,
	# esa parte del píxel nunca se muestrea y el antialiasing será peor.
	return {"cuadrantes": cuadrantes, "uniforme": cuadrantes.min() >= 1}
```

3. **Los motion vectors.** Sin ellos no hay nada:

```glsl
// Vertex shader: se necesitan DOS posiciones en pantalla, la de este frame y
// la del anterior. Por eso hace falta guardar la matriz del frame previo.
uniform mat4 vista_proyeccion_anterior;
uniform mat4 modelo_anterior;

varying vec4 pos_clip_actual;
varying vec4 pos_clip_anterior;

void vertex() {
    // IMPORTANTE: la posición actual se calcula SIN jitter para el motion
    // vector. Si se incluyera, el jitter aparecería como movimiento falso.
    pos_clip_actual = PROJECTION_MATRIX_SIN_JITTER * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    pos_clip_anterior = vista_proyeccion_anterior * modelo_anterior * vec4(VERTEX_ANTERIOR, 1.0);
}

void fragment() {
    vec2 ndc_actual = pos_clip_actual.xy / pos_clip_actual.w;
    vec2 ndc_anterior = pos_clip_anterior.xy / pos_clip_anterior.w;
    // Desplazamiento en coordenadas de pantalla [0,1].
    vec2 motion = (ndc_actual - ndc_anterior) * 0.5;
    ALBEDO = vec3(motion, 0.0);
}
```

Lo que hay que recordar es **qué tiene que escribir en el búfer de velocidad**, porque olvidar uno produce ghosting solo en esa clase de objetos:

| Fuente de movimiento | ¿Se escribe? | Si se olvida |
|---|---|---|
| Movimiento de cámara | ✅ | Ghosting global al girar |
| Objetos que se mueven | ✅ | Estela detrás de cada objeto |
| Animación esquelética | ✅ | Ghosting en personajes animados |
| Deformación por shader (viento, olas) | ✅ | Estelas en vegetación y agua |
| Partículas | ✅ | Rastros de partículas |
| Objetos estáticos | ✅ (solo cámara) | — |
| Recorte por alfa (hojas) | ⚠️ | Bordes inestables |

4. **La reproyección y la acumulación:**

```glsl
uniform sampler2D color_actual;
uniform sampler2D historial;
uniform sampler2D velocidad;
uniform sampler2D profundidad;
uniform vec2 tam_pixel;

const float MEZCLA_MIN = 0.05;
const float MEZCLA_MAX = 0.30;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 motion = texture(velocidad, uv).xy;
    vec2 uv_anterior = uv - motion;

    vec3 actual = texture(color_actual, uv).rgb;

    // ── 1. ¿Está el historial fuera de la pantalla? ──────────────────────
    // Es el caso de desoclusión más simple: no había nada ahí que reutilizar.
    if (any(lessThan(uv_anterior, vec2(0.0))) || any(greaterThan(uv_anterior, vec2(1.0)))) {
        COLOR = vec4(actual, 1.0);
        return;
    }

    vec3 hist = texture(historial, uv_anterior).rgb;

    // ── 2. CLAMPING DE VECINDARIO ───────────────────────────────────────
    // La mitigación principal del ghosting: el historial se limita al rango
    // de colores que hay AHORA alrededor de este píxel. Si el historial se
    // sale de ese rango, es que corresponde a otra superficie.
    vec3 minimo = actual;
    vec3 maximo = actual;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec3 v = texture(color_actual, uv + vec2(x, y) * tam_pixel).rgb;
            minimo = min(minimo, v);
            maximo = max(maximo, v);
        }
    }
    vec3 hist_limitado = clamp(hist, minimo, maximo);

    // ── 3. PESO ADAPTATIVO ──────────────────────────────────────────────
    // Cuanto más ha tenido que corregirse el historial, menos se confía en él.
    float correccion = length(hist_limitado - hist) / (length(hist) + 0.001);
    float mezcla = mix(MEZCLA_MIN, MEZCLA_MAX, clamp(correccion * 4.0, 0.0, 1.0));

    // Y con movimiento rápido también se confía menos: la reproyección de un
    // desplazamiento grande es menos fiable.
    float vel = length(motion) / length(tam_pixel);
    mezcla = mix(mezcla, MEZCLA_MAX, clamp(vel / 32.0, 0.0, 1.0));

    COLOR = vec4(mix(hist_limitado, actual, mezcla), 1.0);
}
```

5. **El catálogo de artefactos.** Reconocerlos es media clase:

| Artefacto | Qué se ve | Causa | Mitigación |
|---|---|---|---|
| **Ghosting** | Estela detrás de un objeto | Historial de otra superficie | Clamping de vecindario, motion vectors correctos |
| **Borrosidad en movimiento** | Detalle perdido al girar | Mezcla de muestras desalineadas | Nitidez posterior, mezcla adaptativa |
| **Parpadeo de bordes finos** | Cables y rejas que bailan | Muestreo insuficiente aunque haya jitter | Más muestras, filtrado de reconstrucción |
| **Desoclusión** | Ruido o borrón donde algo se descubre | No hay historial válido | Detectar y usar solo el frame actual |
| **Ghosting de sombras** | Estela en la sombra de algo que se mueve | Las sombras no escriben motion vectors | Escribirlos, o rechazar por profundidad |
| **Estelas en partículas** | Rastro tras chispas y humo | Partículas sin velocidad | Escribir sus motion vectors |
| **Inestabilidad de HUD** | Texto borroso o vibrante | Se aplicó TAA a la UI | Componer la UI **después** del TAA |
| **Ghosting de transparencias** | Estela en cristales y agua | Las transparencias no suelen escribir profundidad ni velocidad | Tratarlas aparte o excluirlas |

6. **El rechazo del historial.** Cuándo descartar en vez de mezclar:

```glsl
bool historial_valido(vec2 uv, vec2 uv_anterior, float prof_actual) {
    // 1) Fuera de pantalla.
    if (any(lessThan(uv_anterior, vec2(0.0))) || any(greaterThan(uv_anterior, vec2(1.0))))
        return false;

    // 2) DISCONTINUIDAD DE PROFUNDIDAD: si lo que había ahí estaba a otra
    //    distancia, es otra superficie. Es la detección de desoclusión.
    float prof_anterior = texture(profundidad_anterior, uv_anterior).r;
    if (abs(prof_actual - prof_anterior) > 0.01 * prof_actual)
        return false;

    // 3) Cambio de identidad: si el motor escribe un id de objeto por píxel,
    //    compararlo es la detección más fiable de todas.
    if (texture(ids, uv).r != texture(ids_anterior, uv_anterior).r)
        return false;

    // 4) Movimiento excesivo: más de ~64 px de desplazamiento hace la
    //    reproyección poco fiable.
    if (length(uv - uv_anterior) > 64.0 * length(tam_pixel))
        return false;

    return true;
}
```

La decisión de fondo, cuando el historial es dudoso: **descartarlo**. Un frame con algo de ruido o aliasing se percibe mucho menos que una estela fantasma, porque el ojo perdona el ruido de alta frecuencia y detecta inmediatamente una forma que no debería estar ahí.

7. **Qué más usa acumulación temporal.** El TAA es solo el caso más visible:

| Técnica | Qué acumula | Sin acumulación |
|---|---|---|
| TAA | Muestras de color con jitter | Aliasing o 8× el coste |
| Sombras suaves | Muestras del área de luz | Ruido o penumbras duras |
| SSAO / SSGI | Muestras de oclusión | Ruido intenso |
| Reflejos en espacio de pantalla | Rayos por píxel | Reflejos muy ruidosos |
| Ray tracing en tiempo real | Rayos por píxel | Inviable: haría falta 100× |
| Volumétricos | Muestras a lo largo del rayo | Bandas visibles |
| Upscaling temporal | Muestras de baja resolución | Imagen simplemente escalada |

Y de ahí sale la conclusión importante de la clase: **el ray tracing en tiempo real solo es posible gracias a la acumulación temporal**. Con 1-2 rayos por píxel la imagen es puro ruido; lo que se ve limpio es el resultado de acumular y filtrar (denoising) a lo largo de varios frames. Es el tema de la [clase 348](../348-global-illumination-y-ray-tracing-moderno/README.md).

8. **Cuándo NO usar TAA.** La parte honesta:

| Caso | ¿TAA? | Alternativa |
|---|---|---|
| Juego 3D moderno, 60 fps | ✅ | Es el estándar por buenas razones |
| Pixel art o estética nítida | ❌ | Nada, o MSAA; el TAA emborrona a propósito |
| Competitivo a alta tasa de refresco | ⚠️ | Muchos jugadores lo desactivan por la borrosidad |
| VR | ⚠️ | El ghosting es mucho más molesto con la cabeza en movimiento |
| Estilo de líneas finas y contraste alto | ⚠️ | El parpadeo puede empeorar |
| Móvil de gama baja | ❌ | El coste del historial en ancho de banda no compensa |
| Juego 2D | ❌ | No aporta nada |

Y una regla de producto: **el TAA se ofrece como opción, no se impone**. Una parte real del público lo desactiva, y merece poder hacerlo.

9. **Probarlo.** Lo que se puede verificar sin GPU:

```gdscript
extends SceneTree

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	# 1) El jitter cubre el píxel de forma uniforme.
	var c := _verificar_cobertura()
	check.call(bool(c["uniforme"]), "las 8 muestras de jitter cubren los 4 cuadrantes")

	# 2) El jitter se mantiene dentro de medio píxel.
	var dentro := true
	for f in 64:
		var o := JitterTemporal.offset(f)
		if abs(o.x) > 0.5 or abs(o.y) > 0.5: dentro = false
	check.call(dentro, "el jitter nunca supera medio píxel")

	# 3) La secuencia es periódica y determinista.
	check.call(JitterTemporal.offset(0) == JitterTemporal.offset(JitterTemporal.N_MUESTRAS),
		"la secuencia de jitter es periódica")

	# 4) Reproyección: un objeto quieto con cámara quieta reproyecta a sí mismo.
	var uv := Vector2(0.5, 0.5)
	check.call(_reproyectar(uv, Vector2.ZERO) == uv, "sin movimiento, la reproyección es identidad")

	# 5) Clamping: un historial fuera del rango del vecindario se limita.
	var vecindario := {"min": Color(0.2, 0.2, 0.2), "max": Color(0.4, 0.4, 0.4)}
	var hist := Color(0.9, 0.1, 0.1)
	var limitado := _clamp_color(hist, vecindario)
	check.call(limitado.r <= 0.4 and limitado.g >= 0.2,
		"el clamping limita el historial al vecindario")

	# 6) Rechazo por discontinuidad de profundidad.
	check.call(not _historial_valido(10.0, 25.0), "una discontinuidad grande rechaza el historial")
	check.call(_historial_valido(10.0, 10.02), "una diferencia pequeña lo acepta")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

## ✍️ Ejercicios

1. Activa y desactiva el TAA en un proyecto 3D y busca los artefactos de la tabla del paso 5.
2. Implementa la secuencia de Halton y comprueba su cobertura frente a aleatoriedad pura.
3. Escribe un shader que visualice el búfer de velocidad como color y observa qué objetos no lo escriben.
4. Implementa acumulación temporal sencilla y varía el factor de mezcla: observa el compromiso.
5. Añade clamping de vecindario y compara el ghosting antes y después.
6. Provoca desoclusión moviendo un objeto grande y observa qué pasa detrás.
7. Documenta en qué casos de tu proyecto ofrecerías TAA como opción y por defecto.

## 📝 Reto verificable

Implementa una demostración de acumulación temporal con jitter de Halton, búfer de velocidad, reproyección, clamping de vecindario, rechazo por profundidad y peso adaptativo; más un modo de visualización de artefactos y una batería de pruebas verificables sin GPU.

**Criterio de aceptación**: (a) una prueba headless con **al menos 12 aserciones** verifica cobertura del jitter en los cuatro cuadrantes, límite de medio píxel, periodicidad, identidad de la reproyección sin movimiento, clamping al vecindario y rechazo por discontinuidad de profundidad; (b) la demo visual permite activar y desactivar cada mitigación por separado y muestra el efecto; (c) sin clamping y con un objeto en movimiento rápido, el ghosting es **visible y reproducible**; con clamping, desaparece; (d) el búfer de velocidad se puede visualizar y todos los objetos móviles de la escena (incluidas partículas y geometría animada) escriben en él; (e) la UI se compone después del TAA y permanece nítida; (f) existe un ajuste de usuario que desactiva el TAA por completo.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Estela detrás de todo lo que se mueve | Faltan motion vectors o el clamping. Ambas cosas. |
| La imagen entera se emborrona al girar | Factor de mezcla demasiado bajo o jitter mal aplicado. |
| Los personajes animados dejan estela y los estáticos no | El skinning no escribe motion vectors. |
| El HUD vibra o se ve borroso | Se aplicó TAA a la UI. Componla después. |
| El agua y los cristales dejan rastro | Las transparencias no escriben profundidad ni velocidad. |
| Las líneas finas siguen parpadeando | Muestreo insuficiente. Más muestras o filtro de reconstrucción. |
| El jitter se ve como vibración del mundo | Se aplicó moviendo la cámara. Va en la matriz de proyección. |
| Los motion vectors incluyen el jitter | Calcúlalos con la proyección sin jitter. |
| Ruido donde algo se descubre | Desoclusión sin detectar. Rechaza por discontinuidad de profundidad. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué el TAA emborrona?** Porque mezcla muestras tomadas en posiciones ligeramente distintas de la escena. Cuando la cámara se mueve, esas muestras corresponden a puntos que ya no coinciden, y el promedio suaviza el detalle. Es inherente a la técnica: se mitiga con nitidez posterior y con mezcla adaptativa, pero no desaparece.

**❓ ¿Por qué no MSAA, que no tiene estos problemas?** Porque MSAA solo antialiasa **bordes de geometría**, y en un juego moderno la mayor parte del aliasing viene de shaders, texturas especulares y transparencias. Además MSAA es caro con rendering diferido. El TAA cubre todo tipo de aliasing por una fracción del coste — y esa es la razón por la que se impuso pese a sus artefactos.

**❓ ¿Qué factor de mezcla uso?** Entre 0,05 y 0,15 como base. Más bajo acumula mejor (mejor antialiasing, más ghosting), más alto responde mejor al movimiento (menos ghosting, más ruido). La solución práctica es **adaptativo**, como en el paso 4: bajo cuando la escena está estable, alto cuando hay movimiento o el historial se ha tenido que corregir.

**❓ ¿Puedo implementar mi propio TAA en Godot?** Puedes, con `SubViewport`, un shader de pantalla completa y jitter en la proyección — y es un ejercicio excelente para entenderlo. Para producción, el TAA integrado del motor está mejor optimizado y ya gestiona los motion vectors de todo el pipeline, que es la parte tediosa.

**❓ ¿Esto es lo mismo que DLSS o FSR?** Comparten el mecanismo: son upscaling **temporal**, es decir, acumulación temporal aplicada a reconstruir una imagen de mayor resolución. Por eso heredan los mismos artefactos y las mismas necesidades (motion vectors, jitter, rechazo del historial). Es el tema de la [clase 346](../346-upscaling-y-resolucion-dinamica/README.md).

## 🔗 Referencias

- Akenine-Möller, Haines & Hoffman — *Real-Time Rendering*, capítulo de antialiasing y métodos temporales: <https://www.realtimerendering.com/>
- Godot Docs — Antialiasing 3D (TAA, FXAA, MSAA): <https://docs.godotengine.org/en/stable/tutorials/3d/3d_antialiasing.html>
- Godot Docs — Shaders de pantalla y post-procesado: <https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html>
- Karis (Epic Games) — *High Quality Temporal Supersampling*, SIGGRAPH: <https://advances.realtimerendering.com/s2014/>
- Wikipedia — Secuencia de Halton: <https://en.wikipedia.org/wiki/Halton_sequence>

## ⬅️ Clase anterior

[Clase 344 - Grandes mundos y world partition](../344-grandes-mundos-y-world-partition/README.md)

## ➡️ Siguiente clase

[Clase 346 - Upscaling y resolución dinámica](../346-upscaling-y-resolucion-dinamica/README.md)
