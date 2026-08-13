# Clase 346 — Upscaling y resolución dinámica

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Akenine-Möller et al., «Real-Time Rendering» · Documentación de FSR (AMD), DLSS (NVIDIA) y XeSS (Intel)*
> ⏱️ Duración estimada: **115 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender la técnica que ha cambiado el diseño de rendimiento de los juegos modernos: **renderizar a menos resolución de la que se muestra**. El coste del rendering escala con el número de píxeles, así que renderizar a 1440p y escalar a 4K cuesta menos de la mitad. La cuestión es cómo hacerlo sin que se note, y ahí es donde entran el upscaling espacial, el temporal y la resolución dinámica.

Vas a estudiar las tres familias, su calidad y su coste, y la **resolución dinámica**: ajustar la resolución de render frame a frame para mantener una tasa objetivo. Esa última es la que puedes implementar tú, en cualquier motor, sin depender de tecnología propietaria — y es la que más rendimiento estable da por línea de código.

El laboratorio usa **alternativas abiertas y verificables**: nada de esta clase requiere una GPU concreta ni un SDK cerrado.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar por qué el coste de render escala con el número de píxeles.
2. Distinguir upscaling espacial, temporal y resolución dinámica.
3. Implementar resolución dinámica con controlador estable.
4. Implementar upscaling espacial con nitidez y comparar filtros.
5. Explicar los requisitos del upscaling temporal y por qué son los mismos que los del TAA.
6. Comparar FSR, DLSS y XeSS conceptualmente y decidir qué integrar.
7. Diseñar la política de presentación al jugador: presets, escala y calidad.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Coste por píxel | Es la base de todo el ahorro. |
| 2 | Escala de render | El parámetro que se ajusta. |
| 3 | Upscaling espacial | Barato, sin requisitos y con techo de calidad. |
| 4 | Upscaling temporal | Mucha mejor calidad, con los requisitos del TAA. |
| 5 | Resolución dinámica | Rendimiento estable en vez de calidad estable. |
| 6 | Controlador | Cómo ajustar sin oscilar. |
| 7 | Elementos que no se escalan | UI y texto deben ir a resolución nativa. |
| 8 | Comparación de tecnologías | Qué aporta cada una y qué exige. |
| 9 | Medición de calidad | Comparar imágenes objetivamente. |
| 10 | Presentación al jugador | Ajustes comprensibles, no siglas. |

## 📖 Definiciones y características

- **Resolución de render**: la resolución a la que se dibuja la escena 3D. Clave: es distinta de la de presentación.
- **Resolución de presentación**: la del monitor o la ventana. Clave: es a la que se compone la UI.
- **Escala de render**: proporción entre ambas (0,5 = mitad de lado, cuarto de píxeles). Clave: el ahorro va con el **cuadrado**.
- **Upscaling**: reconstruir una imagen de mayor resolución a partir de una menor. Clave: la calidad depende de cuánta información se use.
- **Upscaling espacial**: usa solo el frame actual. Clave: barato, sin requisitos, con un techo claro.
- **Upscaling temporal**: usa el frame actual más el historial con jitter. Clave: mucha mejor calidad; necesita motion vectors.
- **Filtro de reconstrucción**: cómo se interpolan los píxeles (bilinear, Lanczos, adaptativo). Clave: determina la nitidez del resultado.
- **Nitidez (sharpening)**: realce de bordes tras escalar. Clave: compensa el suavizado; en exceso produce halos.
- **Resolución dinámica**: ajuste automático de la escala para mantener el frame time. Clave: prioriza fluidez sobre nitidez.
- **Frame time objetivo**: el presupuesto por frame (16,6 ms a 60 fps). Clave: es lo que el controlador intenta cumplir.
- **Controlador**: lógica que decide cuánto subir o bajar la escala. Clave: mal ajustado, oscila y se nota más que el problema.
- **Histéresis y suavizado**: evitar cambios bruscos de escala. Clave: un cambio de escala visible es peor que un frame lento.
- **FSR**: familia de técnicas de AMD, abiertas y multiplataforma. Clave: la versión espacial no requiere hardware especial.
- **DLSS**: upscaling temporal de NVIDIA con red neuronal. Clave: exige hardware NVIDIA reciente.
- **XeSS**: upscaling de Intel, con modo genérico. Clave: funciona en varios fabricantes con distinta calidad.
- **Métrica de calidad de imagen**: PSNR, SSIM o similar. Clave: permite comparar sin depender de impresiones.

## 🧰 Herramientas y preparación

Godot 4.x con `Viewport.scaling_3d_scale` y `scaling_3d_mode` (que incluye FSR), y `Engine.get_frames_per_second()` / `Performance.TIME_PROCESS` para medir. Trabajaremos en `res://escalado/`. La [documentación de escalado 3D de Godot](https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html) cubre lo que el motor ya ofrece; el controlador de resolución dinámica lo construimos nosotros.

## 🧪 Laboratorio guiado

1. **El ahorro, en números.** Va con el cuadrado, y por eso funciona tan bien:

```text
Presentación 3840×2160 (4K) = 8,29 M píxeles

Escala   Resolución render   Píxeles    % del coste   Ahorro
1,00     3840×2160           8,29 M        100 %        —
0,83     3200×1800           5,76 M         69 %       31 %
0,75     2880×1620           4,67 M         56 %       44 %
0,67     2560×1440           3,69 M         44 %       56 %
0,50     1920×1080           2,07 M         25 %       75 %
0,33     1280×720            0,92 M         11 %       89 %
```

Con una escala de 0,67 —que con upscaling temporal decente es casi indistinguible— el coste de la parte que depende de píxeles cae a menos de la mitad. **Ese es el motivo de que esta técnica esté en todas partes.**

Importante: el ahorro solo aplica a lo que escala con píxeles (fragment shaders, post-procesado, fillrate). El coste de CPU, la geometría y las draw calls **no bajan**.

2. **Upscaling espacial.** Lo más simple, y con techo:

```glsl
// Reconstrucción con Lanczos-2 aproximado, mejor que bilinear y barato.
uniform sampler2D fuente;
uniform vec2 tam_fuente;
uniform float nitidez;    // 0.0 - 1.0

vec3 muestrear_lanczos(vec2 uv) {
    vec2 px = uv * tam_fuente - 0.5;
    vec2 f = fract(px);
    vec2 base = (floor(px) + 0.5) / tam_fuente;

    vec3 acumulado = vec3(0.0);
    float peso_total = 0.0;
    for (int y = -1; y <= 2; y++) {
        for (int x = -1; x <= 2; x++) {
            vec2 offset = vec2(float(x), float(y));
            // El peso decae con la distancia al punto exacto: los píxeles
            // cercanos aportan más. Es lo que da nitidez frente a bilinear.
            float w = lanczos2(length(offset - f));
            acumulado += texture(fuente, base + offset / tam_fuente).rgb * w;
            peso_total += w;
        }
    }
    return acumulado / max(peso_total, 0.0001);
}

void fragment() {
    vec3 c = muestrear_lanczos(SCREEN_UV);

    // NITIDEZ: realce por contraste local. Sin ella, cualquier escalado se
    // ve blando; con demasiada, aparecen halos claros alrededor de los bordes.
    if (nitidez > 0.0) {
        vec3 media = vec3(0.0);
        for (int i = 0; i < 4; i++)
            media += texture(fuente, SCREEN_UV + OFFSETS[i] / tam_fuente).rgb;
        media *= 0.25;
        c = clamp(c + (c - media) * nitidez, 0.0, 1.0);
    }
    COLOR = vec4(c, 1.0);
}
```

3. **La resolución dinámica.** La parte que puedes implementar tú, en cualquier motor:

```gdscript
class_name ResolucionDinamica
extends Node

signal escala_cambiada(nueva: float, motivo: String)

@export var fps_objetivo := 60.0
@export var escala_min := 0.50
@export var escala_max := 1.00
@export var paso := 0.05

# Dos umbrales distintos: si se sube y se baja con el mismo, la escala oscila
# en el borde y el cambio constante se nota más que la caída de fps.
var _umbral_bajar_ms := 0.0
var _umbral_subir_ms := 0.0

var _escala := 1.0
var _muestras := PackedFloat32Array()
var _frames_estables := 0
var _viewport: Viewport

const VENTANA := 30                # ~0,5 s a 60 fps
const FRAMES_ANTES_DE_SUBIR := 90  # 1,5 s de estabilidad antes de arriesgar

func _ready() -> void:
	_viewport = get_viewport()
	var objetivo_ms := 1000.0 / fps_objetivo
	_umbral_bajar_ms = objetivo_ms * 0.95      # bajar antes de perder el objetivo
	_umbral_subir_ms = objetivo_ms * 0.75      # subir solo con margen amplio
	_muestras.resize(VENTANA)
	_muestras.fill(objetivo_ms)

func _process(_d: float) -> void:
	# Se mide el tiempo de PROCESO, no el frame time completo: el frame time
	# incluye el vsync, que hace que un juego sobrado parezca justo.
	var ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_muestras[Engine.get_frames_drawn() % VENTANA] = ms

	# La MEDIANA, no la media: un único pico (una carga, un tirón del sistema)
	# no debe bajar la resolución de todo el juego.
	var mediana := _mediana(_muestras)

	if mediana > _umbral_bajar_ms:
		_frames_estables = 0
		# Bajar RÁPIDO: si vamos lentos, hay que arreglarlo ya. La caída de
		# nitidez se percibe mucho menos que el tirón.
		_ajustar(-paso * 2.0, "frame time %.1f ms > %.1f" % [mediana, _umbral_bajar_ms])
	elif mediana < _umbral_subir_ms:
		_frames_estables += 1
		if _frames_estables >= FRAMES_ANTES_DE_SUBIR:
			_frames_estables = 0
			# Subir DESPACIO: si nos pasamos, volveremos a bajar y el jugador
			# verá la resolución bailando.
			_ajustar(paso, "margen estable de %.1f ms" % mediana)
	else:
		_frames_estables = 0

func _ajustar(delta: float, motivo: String) -> void:
	var nueva := clampf(_escala + delta, escala_min, escala_max)
	if is_equal_approx(nueva, _escala):
		return
	_escala = nueva
	_viewport.scaling_3d_scale = _escala
	escala_cambiada.emit(_escala, motivo)
```

4. **Los tres enfoques, comparados.** La tabla que decide:

| | Espacial (FSR 1, Lanczos) | Temporal (FSR 2+, DLSS, XeSS) | Resolución dinámica |
|---|---|---|---|
| Entrada | Frame actual | Frame + historial + motion vectors | (se combina con las otras) |
| Calidad a 0,67 | Aceptable, algo blanda | Muy buena | Depende del upscaler usado |
| Calidad a 0,50 | Notablemente peor | Buena | — |
| Coste del propio paso | ~0,2 ms | ~1-2 ms | ~0 |
| Requisitos | Ninguno | Motion vectors, jitter, historial | Solo medir |
| Artefactos | Blandura, halos | Los del TAA (ghosting) | Cambios de nitidez visibles |
| Hardware | Cualquiera | Depende de la implementación | Cualquiera |
| Se puede implementar solo | ✅ | Difícil, pero posible | ✅ |

La combinación habitual en producción: **resolución dinámica + upscaler temporal**. La primera decide cuántos píxeles se renderizan; el segundo los reconstruye lo mejor posible.

5. **Lo que NO se escala.** El error que arruina el resultado:

```gdscript
# La UI, el texto y el HUD van SIEMPRE a resolución nativa. Escalarlos hace
# el texto ilegible, y es exactamente lo que el jugador nota primero.
func _configurar_viewports() -> void:
	# Viewport 3D: se escala.
	$Mundo3D.scaling_3d_scale = _escala
	$Mundo3D.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2

	# La UI es hija del viewport RAÍZ, no del escalado. Se compone encima,
	# a resolución de presentación, y no se entera de nada.
	# $UI está fuera de $Mundo3D — esa es toda la configuración.
```

| Elemento | ¿Se escala? | Por qué |
|---|---|---|
| Escena 3D | ✅ | Es donde está el coste |
| Post-procesado del mundo | ✅ | Va con la escena |
| HUD y menús | ❌ | El texto se vuelve ilegible |
| Texto de diálogo | ❌ | Legibilidad |
| Subtítulos | ❌ | Accesibilidad |
| Retículas y punteros | ❌ | Precisión visual |
| Sprites 2D del juego | ⚠️ | Depende: si son parte del mundo, sí |

6. **Medir la calidad objetivamente.** Para no decidir por impresiones:

```gdscript
extends SceneTree   # escalado/comparar.gd

func _init() -> void:
	# Se renderiza la MISMA escena a resolución nativa (referencia) y con
	# cada escala + upscaler, y se comparan las imágenes.
	var referencia := _capturar(1.0, "ninguno")
	print("== Calidad de imagen frente a nativa ==")
	print("  escala  método      PSNR    SSIM    ms/frame")
	for escala in [0.83, 0.75, 0.67, 0.50]:
		for metodo in ["bilinear", "lanczos", "fsr"]:
			var img := _capturar(escala, metodo)
			var ms := _medir_frame(escala, metodo)
			# PSNR: cuánto se parece (más alto, mejor). SSIM: parecido
			# ESTRUCTURAL, que correlaciona mejor con la percepción humana.
			print("  %.2f    %-10s  %5.2f  %.4f  %6.2f"
				% [escala, metodo, _psnr(referencia, img), _ssim(referencia, img), ms])
	quit()

static func _psnr(a: Image, b: Image) -> float:
	var mse := 0.0
	for y in a.get_height():
		for x in a.get_width():
			var d := a.get_pixel(x, y) - b.get_pixel(x, y)
			mse += d.r * d.r + d.g * d.g + d.b * d.b
	mse /= float(a.get_width() * a.get_height() * 3)
	return 10.0 * log(1.0 / maxf(mse, 1e-10)) / log(10.0)
```

Referencias prácticas de PSNR frente a la imagen nativa: por encima de 40 dB la diferencia es casi imperceptible; entre 35 y 40 se aprecia comparando; por debajo de 30 se nota jugando.

7. **La presentación al jugador.** Sin siglas y sin obligar a saber de esto:

```gdscript
const PRESETS := {
	"calidad":     {"escala": 1.00, "descripcion": "Máxima nitidez. Requiere más potencia."},
	"equilibrado": {"escala": 0.75, "descripcion": "Buen equilibrio entre nitidez y fluidez."},
	"rendimiento": {"escala": 0.59, "descripcion": "Prioriza la fluidez. Imagen algo más blanda."},
	"maximo":      {"escala": 0.50, "descripcion": "Máxima fluidez para equipos modestos."},
	"automatico":  {"escala": -1.0, "descripcion": "Ajusta solo para mantener los FPS objetivo."},
}
```

```text
┌─ Calidad de imagen ──────────────────────────────────┐
│                                                       │
│  Escalado de resolución:  [ Automático        ▾ ]     │
│    Ajusta la resolución para mantener 60 FPS.         │
│                                                       │
│  FPS objetivo:            [ 60 ▾ ]                    │
│  Resolución mínima:       [ 50% ────●──── 100% ]      │
│                                                       │
│  Nitidez:                 [ ──────●──── ] 60%         │
│                                                       │
│  Ahora mismo: renderizando a 2560×1440 (67%)          │
│               presentando a 3840×2160                 │
└───────────────────────────────────────────────────────┘
```

La última línea —decir en qué resolución se está renderizando **ahora**— es la que convierte una función opaca en algo que el jugador entiende y puede juzgar.

8. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	var rd := ResolucionDinamica.nueva(60.0, 0.5, 1.0)

	# 1) Con frames lentos, la escala baja.
	for i in 60: rd.simular_frame(25.0)          # 25 ms > 16,6
	check.call(rd.escala() < 1.0, "la escala baja con frames lentos")

	# 2) Con frames rápidos y estabilidad, sube.
	var e := rd.escala()
	for i in 200: rd.simular_frame(8.0)
	check.call(rd.escala() > e, "la escala sube con margen sostenido")

	# 3) NO oscila: en el punto justo se mantiene estable.
	rd.reiniciar()
	var cambios := 0
	rd.escala_cambiada.connect(func(_n, _m): cambios += 1)
	for i in 600:
		rd.simular_frame(15.8 + sin(i * 0.3) * 0.6)   # justo por debajo del objetivo
	check.call(cambios <= 3, "no oscila cerca del umbral (hubo %d cambios)" % cambios)

	# 4) Respeta los límites.
	rd.reiniciar()
	for i in 2000: rd.simular_frame(100.0)
	check.call(rd.escala() >= 0.5, "no baja del mínimo configurado")
	rd.reiniciar()
	for i in 2000: rd.simular_frame(1.0)
	check.call(rd.escala() <= 1.0, "no sube del máximo")

	# 5) Un pico aislado no cambia nada: la mediana lo absorbe.
	rd.reiniciar()
	for i in 100: rd.simular_frame(10.0)
	e = rd.escala()
	rd.simular_frame(200.0)                       # un tirón puntual
	for i in 5: rd.simular_frame(10.0)
	check.call(is_equal_approx(rd.escala(), e), "un pico aislado no baja la resolución")

	# 6) El ahorro teórico coincide con el cuadrado de la escala.
	check.call(is_equal_approx(_pixeles_relativos(0.5), 0.25),
		"escala 0,5 = 25 %% de los píxeles")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

## ✍️ Ejercicios

1. Mide el frame time de tu juego a escala 1,0; 0,75; 0,67 y 0,5 y comprueba si el ahorro sigue el cuadrado.
2. Implementa el controlador de resolución dinámica y ajústalo hasta que no oscile.
3. Compara bilinear, Lanczos y FSR a escala 0,67 con PSNR y SSIM.
4. Encuentra el valor de nitidez a partir del cual aparecen halos.
5. Comprueba qué pasa si escalas también la UI y documenta el resultado.
6. Diseña la pantalla de ajustes de tu juego sin usar ninguna sigla.
7. Mide qué parte de tu frame time **no** baja al reducir la resolución (CPU, geometría, draw calls).

## 📝 Reto verificable

Implementa un sistema de escalado con: resolución dinámica con umbrales separados, mediana sobre ventana, subida lenta y bajada rápida; upscaling espacial con Lanczos y nitidez ajustable; UI a resolución nativa; comparador objetivo de calidad con PSNR y SSIM; y ajustes de usuario con presets y estado visible.

**Criterio de aceptación**: una prueba headless con **al menos 15 aserciones** demuestra que: (a) con frame time sostenido por encima del objetivo la escala baja, y con margen sostenido sube; (b) con frame time oscilando **justo** en el umbral durante 600 frames, la escala cambia **3 veces o menos**; (c) un pico aislado de 200 ms no modifica la escala; (d) la escala nunca sale de `[escala_min, escala_max]`; (e) la bajada es más rápida que la subida, comprobable en número de frames hasta reaccionar; (f) el comparador imprime PSNR y SSIM de al menos tres métodos a cuatro escalas; (g) a escala 0,67 con Lanczos, el PSNR frente a nativa supera los 30 dB en la escena de prueba; (h) la UI permanece a resolución de presentación, comprobable porque su viewport no cambia de tamaño.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La resolución baila constantemente | Un solo umbral. Usa umbrales separados, mediana y subida lenta. |
| El texto se ve borroso o ilegible | Se escaló la UI. Sácala del viewport escalado. |
| Bajar la resolución no mejora los FPS | El cuello está en CPU o en draw calls. Perfila antes. |
| Halos claros alrededor de los bordes | Demasiada nitidez. Baja el valor. |
| Un tirón puntual baja la resolución de todo el juego | Se usa la media. Usa la mediana sobre una ventana. |
| El jugador no entiende los ajustes | Siglas sin explicación. Presets con descripción y estado actual. |
| Ghosting tras activar upscaling temporal | Faltan motion vectors. Son los mismos requisitos que el TAA (clase 345). |
| A escala 0,5 la imagen es inaceptable | El espacial tiene ese techo. Sube el mínimo o usa temporal. |

## ❓ Preguntas frecuentes

**❓ ¿Merece la pena implementar resolución dinámica yo mismo?** Sí, y es de las cosas con mejor relación coste/beneficio de esta parte: son unas 60 líneas, funciona en cualquier motor y hardware, y convierte "a veces va a 40 fps" en "siempre va a 60 con algo menos de nitidez". Casi todos los jugadores prefieren eso.

**❓ ¿FSR, DLSS o XeSS?** Depende de a quién quieras llegar. FSR es abierto y multiplataforma, que en la práctica significa que funciona para todo tu público. DLSS da muy buenos resultados pero solo en hardware NVIDIA reciente. XeSS tiene un modo genérico. Lo razonable en producción es **ofrecer varios** y dejar elegir; si solo puedes integrar uno, el abierto llega a más gente.

**❓ ¿Por qué el upscaling temporal es tan superior?** Porque usa **más información**: acumula muestras de varios frames con jitter, así que reconstruye detalle que en un solo frame de baja resolución no existe. El espacial solo puede interpolar lo que tiene. A cambio hereda todos los requisitos y artefactos del TAA ([clase 345](../345-rendering-temporal/README.md)).

**❓ ¿Puedo usar resolución dinámica y upscaling temporal a la vez?** Sí, y es la combinación estándar en consolas y en juegos grandes. La resolución dinámica decide cuántos píxeles se renderizan según el presupuesto, y el upscaler temporal reconstruye lo mejor posible desde ahí. Hay que asegurarse de que el upscaler tolera cambios de resolución de entrada, que no todos hacen igual de bien.

**❓ ¿Y si mi juego es 2D o pixel art?** Entonces esto no aplica: el escalado suaviza, y una estética de píxel nítido es exactamente lo contrario. Lo que sí aplica es la idea general de tener un **presupuesto de frame** y ajustar algo cuando no se cumple; solo que en 2D lo que se ajusta es el número de efectos o de partículas, no la resolución.

## 🔗 Referencias

- Godot Docs — Escalado de resolución 3D: <https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html>
- Godot Docs — `Viewport` (`scaling_3d_scale`, `scaling_3d_mode`): <https://docs.godotengine.org/en/stable/classes/class_viewport.html>
- AMD — FidelityFX Super Resolution (documentación abierta): <https://gpuopen.com/fidelityfx-superresolution/>
- NVIDIA — DLSS para desarrolladores: <https://developer.nvidia.com/rtx/dlss>
- Intel — XeSS: <https://www.intel.com/content/www/us/en/developer/topic-technology/gamedev/xess.html>
- Akenine-Möller et al. — *Real-Time Rendering*, capítulo de muestreo y reconstrucción: <https://www.realtimerendering.com/>

## ⬅️ Clase anterior

[Clase 345 - Rendering temporal](../345-rendering-temporal/README.md)

## ➡️ Siguiente clase

[Clase 347 - HDR y gestión moderna de color](../347-hdr-y-gestion-moderna-de-color/README.md)
