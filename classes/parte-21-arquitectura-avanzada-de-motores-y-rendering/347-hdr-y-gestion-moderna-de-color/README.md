# Clase 347 — HDR y gestión moderna de color

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Akenine-Möller et al., «Real-Time Rendering» (color y tone mapping) · Estándares ITU-R BT.709 y BT.2100*
> ⏱️ Duración estimada: **115 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender por qué los colores de tu juego se ven distintos en cada pantalla, y qué hacer al respecto. Es un tema que la mayoría de desarrolladores evita hasta que un jugador reporta que "todo está lavado" en su monitor nuevo, y entonces descubre que el problema lleva ahí desde el principio.

Vas a estudiar la cadena completa: **flujo lineal** (por qué no se puede sumar luz en sRGB), **espacios de color** (qué colores puede representar una pantalla), **HDR** (qué cambia cuando el brillo llega a 1.000 nits en vez de 100), **tone mapping** (cómo se comprime un rango enorme en lo que la pantalla puede mostrar) y **exposición** (cómo se decide qué es "blanco"). Y verás por qué hacerlo bien no es una cuestión estética sino de **corrección**: con un flujo mal montado, la iluminación de tu juego está literalmente mal calculada.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar por qué la iluminación debe calcularse en espacio lineal.
2. Distinguir espacio de color, gamma, rango dinámico y brillo absoluto.
3. Identificar los errores clásicos del flujo de color y sus síntomas.
4. Explicar qué cambia técnicamente al mostrar en HDR.
5. Comparar operadores de tone mapping y elegir según la intención artística.
6. Implementar exposición automática con adaptación temporal.
7. Diseñar la calibración que se ofrece al jugador y por qué.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Luz vs percepción | La raíz de todo el asunto. |
| 2 | Gamma y sRGB | Por qué las texturas no están en lineal. |
| 3 | Flujo lineal | Sin él, la iluminación está mal calculada. |
| 4 | Espacios de color | Qué colores puede mostrar una pantalla. |
| 5 | Rango dinámico | De 100 nits a 1.000: qué cambia. |
| 6 | Brillo absoluto | En HDR, un valor significa nits reales. |
| 7 | Tone mapping | Comprimir el rango de la escena al de la pantalla. |
| 8 | Exposición | Decidir qué es blanco en cada momento. |
| 9 | Curva EOTF (PQ, HLG) | Cómo se codifica el HDR. |
| 10 | Calibración del jugador | Cada pantalla es distinta; hay que preguntarle. |

## 📖 Definiciones y características

- **Luz lineal**: valores proporcionales a la energía luminosa. Clave: es el único espacio donde sumar y multiplicar luz tiene sentido físico.
- **Gamma**: función no lineal que relaciona el valor almacenado con la luz emitida. Clave: existe porque el ojo percibe el brillo de forma no lineal.
- **sRGB**: espacio de color estándar con su curva de transferencia. Clave: es lo que hay en casi todas las texturas y monitores SDR.
- **Corrección gamma**: conversión entre lineal y sRGB. Clave: hacerla dos veces o ninguna son los dos errores clásicos.
- **Textura sRGB**: textura de color que debe convertirse a lineal al leerse. Clave: solo las de **color**; las de datos (normal, roughness) **no**.
- **Espacio de color (gamut)**: conjunto de colores representables. Clave: Rec.709 (SDR) es mucho menor que Rec.2020 (HDR).
- **Primarios**: los colores base que definen el gamut. Clave: el mismo valor RGB es un color distinto en gamuts distintos.
- **Rango dinámico**: relación entre lo más brillante y lo más oscuro representable. Clave: es lo que define SDR frente a HDR.
- **Nit (cd/m²)**: unidad de brillo. Clave: SDR asume ~100 nits de blanco; HDR llega a 1.000 o más.
- **HDR (high dynamic range)**: mostrar un rango de brillo mucho mayor. Clave: no es "más colorido", es **más rango**.
- **EOTF**: función que traduce el valor codificado a luz emitida. Clave: en HDR define el brillo **absoluto**.
- **PQ (ST 2084)**: EOTF de brillo absoluto usada en HDR10. Clave: un valor significa un número concreto de nits.
- **HLG**: EOTF de brillo relativo, compatible con SDR. Clave: usada en difusión; se adapta a la pantalla.
- **Tone mapping**: comprimir el rango de la escena al de la pantalla. Clave: es una decisión **artística**, no solo técnica.
- **Reinhard, ACES, AgX**: operadores de tone mapping habituales. Clave: cada uno tiene un carácter distinto.
- **Exposición**: escala que decide qué valor de escena se muestra como blanco. Clave: como en una cámara real.
- **Adaptación (eye adaptation)**: ajuste progresivo de la exposición. Clave: imita el ojo y evita saltos bruscos.
- **Clipping**: valores que superan el máximo y se recortan. Clave: se pierde detalle en las luces.
- **Banding**: escalones visibles en degradados. Clave: falta de bits; se mitiga con dithering.

## 🧰 Herramientas y preparación

Godot 4.x con `WorldEnvironment` (tonemap, exposición, glow), texturas con y sin `sRGB` en sus ajustes de importación, y un monitor HDR si lo tienes (no es imprescindible: casi todo el contenido se verifica en SDR). Trabajaremos en `res://color/`. La [documentación de entorno y post-procesado de Godot](https://docs.godotengine.org/en/4.3/tutorials/3d/environment_and_post_processing.html) cubre los ajustes; aquí se explica qué hacen y por qué.

## 🧪 Laboratorio guiado

1. **Por qué lineal.** El experimento que lo demuestra en una línea:

```text
Dos luces, cada una de intensidad 0,5. ¿Cuánta luz hay donde se suman?

EN LINEAL (correcto):
  0,5 + 0,5 = 1,0  → el doble de luz. Físicamente correcto.

EN sRGB (incorrecto):
  El valor 0,5 en sRGB es ~0,214 de luz real.
  0,5 + 0,5 = 1,0 en sRGB = 1,0 de luz real
  Pero debería ser 0,214 + 0,214 = 0,428 de luz → valor sRGB ~0,70
  Error: se muestra 1,0 (blanco puro) donde debería haber 0,70.

Resultado: las zonas de luces solapadas se queman, las penumbras se ven mal
y el 50 % de gris no está donde debería. Y todo el balance de iluminación de
la escena está calculado sobre valores incorrectos.
```

```gdscript
extends SceneTree   # color/demo_lineal.gd

const GAMMA := 2.2

static func srgb_a_lineal(c: float) -> float:
	# La curva sRGB real tiene un tramo lineal cerca del negro; la
	# aproximación por gamma 2.2 basta para entender el efecto.
	return pow(c, GAMMA) if c > 0.0 else 0.0

static func lineal_a_srgb(c: float) -> float:
	return pow(c, 1.0 / GAMMA) if c > 0.0 else 0.0

func _init() -> void:
	print("== Sumar dos luces de 0,5 ==")
	var correcto := lineal_a_srgb(srgb_a_lineal(0.5) + srgb_a_lineal(0.5))
	print("  en lineal (correcto):  %.3f en sRGB" % correcto)
	print("  en sRGB (incorrecto):  %.3f en sRGB" % minf(1.0, 0.5 + 0.5))
	print("  error: %.1f%%" % (abs(1.0 - correcto) / correcto * 100.0))
	quit()
```

2. **El flujo completo.** Qué se convierte y dónde:

```text
┌─ TEXTURAS ────────────────────────────────────────────────────────┐
│  Albedo, emisión  → guardadas en sRGB  → SE CONVIERTEN a lineal   │
│  Normal, rough,   → guardadas en lineal → NO se convierten        │
│  metallic, AO, height, máscaras                                    │
└───────────────────────────────┬───────────────────────────────────┘
                                ▼
┌─ ILUMINACIÓN Y SHADING ───────────────────────────────────────────┐
│  TODO en lineal, en punto flotante (16 bits por canal)            │
│  Los valores pueden superar 1,0: el sol es ~100, una bombilla ~5  │
└───────────────────────────────┬───────────────────────────────────┘
                                ▼
┌─ POST-PROCESADO ──────────────────────────────────────────────────┐
│  Bloom, desenfoque, GI: en LINEAL, porque suman luz               │
└───────────────────────────────┬───────────────────────────────────┘
                                ▼
┌─ EXPOSICIÓN ──────────────────────────────────────────────────────┐
│  Escalar la escena: decidir qué valor será "blanco"               │
└───────────────────────────────┬───────────────────────────────────┘
                                ▼
┌─ TONE MAPPING ────────────────────────────────────────────────────┐
│  Comprimir [0, ∞) al rango de la pantalla. Decisión ARTÍSTICA.    │
└───────────────────────────────┬───────────────────────────────────┘
                                ▼
┌─ CODIFICACIÓN DE SALIDA ──────────────────────────────────────────┐
│  SDR: convertir a sRGB.   HDR: aplicar PQ o HLG con su gamut.     │
└───────────────────────────────┬───────────────────────────────────┘
                                ▼
┌─ UI ──────────────────────────────────────────────────────────────┐
│  Se compone AL FINAL, ya en el espacio de salida                  │
└───────────────────────────────────────────────────────────────────┘
```

Los dos puntos donde casi todo el mundo se equivoca: **marcar como sRGB una textura de datos** (una normal map convertida es una normal map rota) y **aplicar tone mapping a la UI** (que hace el blanco del HUD gris y los colores lavados).

3. **Los errores clásicos y su síntoma:**

| Error | Síntoma visible | Arreglo |
|---|---|---|
| Texturas de color sin marcar sRGB | Todo se ve oscuro y con contraste excesivo | Marcar sRGB en la importación |
| Normal map marcada como sRGB | Iluminación de superficie sutilmente mal, difícil de ver | Desmarcar sRGB en mapas de datos |
| Doble corrección gamma | Todo lavado, blancuzco | Corregir una sola vez, al final |
| Sin corrección | Todo oscuro y muy contrastado | Aplicarla al final |
| Bloom en sRGB | Halos débiles y de color raro | Post-procesado en lineal |
| Búfer de 8 bits en lineal | Banding en las sombras | Punto flotante de 16 bits |
| UI dentro del tone mapping | HUD lavado, blancos grises | Componer la UI después |
| Colores elegidos a ojo en el editor | Se ven distintos al ejecutar | Elegirlos con el flujo ya montado |

4. **HDR: qué cambia realmente.** Es más rango, no más color:

```text
SDR (Rec.709 + sRGB):
  Blanco de referencia:  ~100 nits
  Rango:                 ~100:1 útil
  Bits por canal:        8
  Gamut:                 Rec.709

HDR10 (Rec.2020 + PQ):
  Blanco de referencia:  ~203 nits (papel blanco)
  Máximo:                1.000-10.000 nits
  Rango:                 ~10.000:1
  Bits por canal:        10
  Gamut:                 Rec.2020 (mucho mayor)

Lo que esto significa en el juego:
  - El sol puede ser DE VERDAD deslumbrante, no un parche blanco.
  - Un reflejo especular brilla sin quemar toda la imagen.
  - Las sombras conservan detalle con luces brillantes en la misma escena.
  - Los colores saturados (neones, fuego) no se recortan.
```

Y el detalle que lo complica: en HDR con PQ, **un valor significa nits absolutos**. Un blanco de UI a 1.000 nits en una habitación a oscuras es literalmente cegador. Por eso la UI en HDR se limita al blanco de referencia y no al máximo.

5. **Tone mapping.** Cuatro operadores y su carácter:

```glsl
// Reinhard: el más simple. Comprime todo pero desatura las luces, y el
// resultado tiende a verse lavado.
vec3 reinhard(vec3 c) {
    return c / (1.0 + c);
}

// Reinhard extendido: respeta el blanco hasta un valor dado.
vec3 reinhard_ext(vec3 c, float blanco) {
    return (c * (1.0 + c / (blanco * blanco))) / (1.0 + c);
}

// ACES (aproximación de Narkowicz): contraste cinematográfico, luces que
// tienden a naranja al saturarse. Es el estándar de facto en juegos.
vec3 aces(vec3 c) {
    const float a = 2.51, b = 0.03, cc = 2.43, d = 0.59, e = 0.14;
    return clamp((c * (a * c + b)) / (c * (cc * c + d) + e), 0.0, 1.0);
}

// Filmic (Uncharted 2, Hable): control fino de sombras, medios y luces.
vec3 filmic(vec3 x) {
    const float A = 0.15, B = 0.50, C = 0.10, D = 0.20, E = 0.02, F = 0.30;
    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}
```

| Operador | Carácter | Luces | Cuándo |
|---|---|---|---|
| Ninguno (clamp) | Duro | Se queman de golpe | Nunca en 3D |
| Reinhard | Suave, lavado | Desaturadas | Rápido y poco más |
| Reinhard extendido | Controlable | Mejor que el simple | Cuando quieras un blanco concreto |
| Filmic (Hable) | Contrastado | Buen rolloff | Estética cinematográfica |
| ACES | Cinematográfico | Tienden a cálido | El más usado en juegos |
| AgX | Neutro, moderno | Conserva el tono al saturar | Cuando el color debe mantenerse fiel |

La elección **es artística**, no técnica: ACES da un look de cine que puede no encajar con un juego de colores planos, y AgX conserva mejor los tonos saturados. Godot 4 ofrece Linear, Reinhard, Filmic, ACES y AgX en `WorldEnvironment`.

6. **La exposición automática.** Cómo se decide qué es blanco:

```gdscript
class_name ExposicionAutomatica
extends RefCounted

# Imita el ojo: al pasar de una cueva a la luz, deslumbra un momento y luego
# se adapta. Sin adaptación temporal, el cambio es un salto brusco y molesto.
var velocidad_oscurecer := 2.5     # adaptarse a MÁS luz es rápido
var velocidad_aclarar := 0.8       # a MENOS luz, lento (como el ojo real)
var exposicion_min := 0.05
var exposicion_max := 8.0
var clave := 0.18                  # gris medio: el objetivo de exposición

var _actual := 1.0

func actualizar(luminancia_media: float, delta: float) -> float:
	# La media se calcula en LOG: la percepción del brillo es logarítmica, y
	# una media aritmética la dominan cuatro píxeles muy brillantes.
	var objetivo := clampf(clave / maxf(luminancia_media, 0.0001),
						   exposicion_min, exposicion_max)
	var vel := velocidad_oscurecer if objetivo < _actual else velocidad_aclarar
	# Interpolación exponencial: independiente del framerate.
	_actual = lerpf(_actual, objetivo, 1.0 - exp(-vel * delta))
	return _actual

static func luminancia(c: Color) -> float:
	# Coeficientes Rec.709: el verde aporta la mayor parte del brillo percibido.
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
```

```glsl
// El histograma de luminancia, que es como se hace en producción: más
// robusto que la media porque permite ignorar el 20 % más oscuro y el 5 %
// más brillante, que es donde están el cielo y las fuentes de luz directas.
shared uint histograma[256];

void main() {
    float lum = dot(texture(escena, uv).rgb, vec3(0.2126, 0.7152, 0.0722));
    // El bin en escala LOG: reparte los bins de forma perceptualmente útil.
    uint bin = uint(clamp((log2(lum) + 10.0) / 16.0, 0.0, 1.0) * 255.0);
    atomicAdd(histograma[bin], 1u);
}
```

7. **La calibración del jugador.** Porque cada pantalla es distinta:

```text
┌─ Calibración de imagen ───────────────────────────────────────────┐
│                                                                    │
│   Ajusta el BRILLO hasta que apenas distingas el logo de la        │
│   izquierda, y el de la derecha no se vea en absoluto.             │
│                                                                    │
│        ▓▓▓▓                        ░░░░                            │
│      (apenas visible)          (invisible)                         │
│                                                                    │
│   Brillo:  [ ────────●──────── ]                                   │
│                                                                    │
│   ── Solo en pantallas HDR ──────────────────────────────────────  │
│   Brillo máximo de tu pantalla:  [ 1000 ] nits                     │
│     Sube hasta que el cuadro deje de ganar brillo.                 │
│   Blanco de la interfaz:         [ 203 ] nits                      │
│     Que el HUD sea cómodo de leer, no deslumbrante.                │
└────────────────────────────────────────────────────────────────────┘
```

Los tres ajustes que hay que ofrecer, y por qué:

| Ajuste | Qué resuelve | Por qué no se puede automatizar |
|---|---|---|
| Brillo / gamma | Ver en sombras según la luz de la habitación | Depende del entorno físico del jugador |
| Brillo máximo (HDR) | Que las luces no se recorten ni queden apagadas | Cada panel HDR tiene un máximo distinto |
| Blanco de UI (HDR) | Que el HUD no deslumbre en escenas oscuras | Preferencia personal y del panel |

8. **Probarlo.** El color se verifica con números, no a ojo:

```gdscript
extends SceneTree

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	# 1) Ida y vuelta sRGB ↔ lineal.
	for v in [0.0, 0.05, 0.2, 0.5, 0.8, 1.0]:
		var ida := srgb_a_lineal(v)
		check.call(abs(lineal_a_srgb(ida) - v) < 0.001,
			"sRGB↔lineal es reversible en %.2f" % v)

	# 2) Sumar en lineal da un resultado distinto (y correcto).
	var suma_lineal := lineal_a_srgb(srgb_a_lineal(0.5) * 2.0)
	check.call(abs(suma_lineal - 1.0) > 0.05,
		"sumar en lineal difiere de sumar en sRGB")

	# 3) Los operadores de tone mapping son monótonos: más luz, más brillo.
	for op in ["reinhard", "aces", "filmic"]:
		var monotono := true
		var previo := -1.0
		for i in 100:
			var v := _tonemap(op, float(i) * 0.2)
			if v < previo: monotono = false
			previo = v
		check.call(monotono, "%s es monótono creciente" % op)

	# 4) Y acotados en [0, 1].
	for op in ["reinhard", "aces", "filmic"]:
		var acotado := _tonemap(op, 1000.0) <= 1.001 and _tonemap(op, 0.0) >= -0.001
		check.call(acotado, "%s acota la salida en [0,1]" % op)

	# 5) La luminancia usa los coeficientes correctos.
	check.call(abs(ExposicionAutomatica.luminancia(Color(0, 1, 0)) - 0.7152) < 0.001,
		"el verde aporta el 71,52 %% de la luminancia")

	# 6) La adaptación converge y no oscila.
	var e := ExposicionAutomatica.new()
	var v := 1.0
	for i in 300:
		v = e.actualizar(0.5, 0.016)
	check.call(abs(v - e.objetivo_para(0.5)) < 0.01, "la exposición converge")

	# 7) Adaptarse a más luz es más rápido que a menos.
	var e2 := ExposicionAutomatica.new()
	var frames_oscurecer := _frames_hasta_converger(e2, 0.05, 2.0)
	var e3 := ExposicionAutomatica.new()
	var frames_aclarar := _frames_hasta_converger(e3, 2.0, 0.05)
	check.call(frames_oscurecer < frames_aclarar,
		"adaptarse a más luz es más rápido, como el ojo")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

## ✍️ Ejercicios

1. Ejecuta la demo de suma de luces y calcula el error exacto para varios valores.
2. Marca una normal map como sRGB en tu proyecto y observa el cambio en la iluminación.
3. Compara los cinco operadores de tone mapping sobre la misma escena con luces intensas.
4. Implementa exposición automática y ajusta las velocidades hasta que se sienta natural.
5. Implementa el histograma de luminancia en compute shader y compáralo con la media.
6. Diseña la pantalla de calibración de tu juego con los tres ajustes.
7. Si tienes un monitor HDR, compara la misma escena en SDR y HDR y anota qué cambia.

## 📝 Reto verificable

Implementa una demostración de gestión de color con: conversiones sRGB↔lineal verificables, comparativa de **al menos cuatro** operadores de tone mapping, exposición automática con histograma y adaptación asimétrica, UI compuesta fuera del tone mapping, y pantalla de calibración con brillo y (si hay HDR) brillo máximo y blanco de UI.

**Criterio de aceptación**: una prueba headless con **al menos 15 aserciones** demuestra que: (a) las conversiones sRGB↔lineal son reversibles con error menor de 0,001 en al menos seis valores; (b) sumar dos valores de 0,5 en lineal da un resultado distinto del que da sumarlos en sRGB, con el error calculado; (c) los cuatro operadores de tone mapping son monótonos crecientes y acotan la salida en `[0,1]` para entradas de 0 a 1.000; (d) la luminancia usa los coeficientes Rec.709 exactos; (e) la exposición automática converge y no oscila tras 300 frames; (f) la adaptación a más luz tarda **menos frames** que a menos luz; (g) la UI no pasa por el tone mapping, comprobable porque un blanco puro de UI sale como blanco puro; (h) todas las texturas de datos del proyecto (normal, roughness, metallic) están importadas **sin** sRGB, comprobable con un script que revise los `.import`.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Todo se ve lavado y sin contraste | Doble corrección gamma. Corrige una sola vez, al final. |
| Todo se ve oscuro y muy contrastado | Falta la corrección, o las texturas de color no están marcadas sRGB. |
| La iluminación de superficies se ve rara sin saber por qué | Una normal map marcada como sRGB. Desmárcala. |
| El HUD se ve gris en vez de blanco | La UI pasa por el tone mapping. Componla después. |
| Banding en los degradados del cielo | Búfer de 8 bits. Usa punto flotante de 16 y añade dithering. |
| Los colores del editor no coinciden con el juego | Se eligieron sin el flujo montado. Configura primero, colorea después. |
| En HDR el HUD deslumbra | La UI se manda al brillo máximo. Limítala al blanco de referencia. |
| El bloom se ve débil y de color raro | Post-procesado en sRGB. Todo el post que suma luz va en lineal. |
| La exposición automática marea | Adaptación demasiado rápida o simétrica. Asimétrica y más lenta al aclarar. |

## ❓ Preguntas frecuentes

**❓ ¿Godot ya hace esto por mí?** En buena parte sí: el renderizador trabaja en lineal, aplica tone mapping y convierte a sRGB al final. Lo que **tú** tienes que hacer bien es marcar correctamente las texturas (color sí, datos no), elegir el tone mapping con criterio, decidir la exposición y sacar la UI del pipeline de tone mapping. Ahí es donde se rompe la mayoría de los proyectos.

**❓ ¿Merece la pena soportar HDR?** Si tu juego tiene contrastes fuertes (interiores oscuros con exteriores luminosos, fuego, neones), la diferencia es notable para quien tenga la pantalla. El coste principal no es técnico sino de **validación**: hay que probar en pantallas HDR reales, que se comportan de forma muy distinta entre sí. Un plan razonable es hacer bien el flujo lineal —que beneficia a todo el mundo— y añadir HDR después.

**❓ ¿Qué tone mapping elijo?** ACES si quieres un look cinematográfico estándar y no quieres pensarlo más. AgX si tus colores saturados importan (neones, magia, arte estilizado) y no quieres que viren al saturarse. Filmic si necesitas control fino. Y pruébalo con **tu** arte: lo que funciona en una escena realista puede arruinar una estilizada.

**❓ ¿Por qué la exposición automática es tan difícil de ajustar?** Porque compite con la intención artística: si un pasillo está diseñado para sentirse oscuro y la exposición lo aclara, has perdido la escena. Soluciones habituales: acotar el rango de exposición por zona, ignorar el cielo en el histograma y dar control al diseñador para fijarla en momentos concretos.

**❓ ¿Cómo pruebo el color sin ojo entrenado?** Con números, como en el paso 8: reversibilidad de las conversiones, monotonía de los operadores, coeficientes correctos. Y con imágenes de referencia: renderiza una carta de color conocida y comprueba que los valores salen donde deben. Lo que no se puede automatizar es si **se ve bien**, y para eso están las revisiones con el equipo de arte.

## 🔗 Referencias

- Akenine-Möller, Haines & Hoffman — *Real-Time Rendering*, capítulo de color y tone mapping: <https://www.realtimerendering.com/> · uso: respalda el Tema 7 «Tone mapping»
- Godot Docs — Entorno y post-procesado (tonemap, exposición, glow): <https://docs.godotengine.org/en/4.3/tutorials/3d/environment_and_post_processing.html> · uso: se instala o se consulta en la preparación
- Godot Docs — Importación de imágenes y ajuste sRGB: <https://docs.godotengine.org/en/4.3/tutorials/assets_pipeline/importing_images.html> · uso: respalda el Tema 2 «Gamma y sRGB»
- ITU-R BT.709 — parámetros de SDR: <https://www.itu.int/rec/R-REC-BT.709> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- ITU-R BT.2100 — parámetros de HDR (PQ y HLG): <https://www.itu.int/rec/R-REC-BT.2100> · uso: respalda el Tema 9 «Curva EOTF (PQ, HLG)»
- ACES — Academy Color Encoding System: <https://acescentral.com/> · uso: respalda el Tema 4 «Espacios de color»

## ⬅️ Clase anterior

[Clase 346 - Upscaling y resolución dinámica](../346-upscaling-y-resolucion-dinamica/README.md)

## ➡️ Siguiente clase

[Clase 348 - Global illumination y ray tracing moderno](../348-global-illumination-y-ray-tracing-moderno/README.md)
