# Clase 348 — Global illumination y ray tracing moderno

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Akenine-Möller et al., «Real-Time Rendering» (global illumination) · Pharr, Jakob & Humphreys, «Physically Based Rendering»*
> ⏱️ Duración estimada: **125 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender cómo se calcula la **luz indirecta**: la que rebota. Una habitación iluminada por una ventana no está iluminada solo por el rectángulo de sol en el suelo — está iluminada por toda la luz que ese rectángulo rebota hacia el techo, las paredes y de vuelta. Sin luz indirecta, las sombras son negras y la escena parece un decorado con focos.

Vas a recorrer el abanico completo de técnicas, desde lo horneado hasta el path tracing, entendiendo el compromiso de cada una: qué calidad da, qué cuesta, qué restricciones impone (¿se puede mover la luz? ¿se puede mover la geometría?) y qué hardware necesita. Y verás la clave de por qué el ray tracing en tiempo real es viable hoy: **no se trazan suficientes rayos**, se trazan poquísimos y se acumulan y filtran a lo largo del tiempo — exactamente lo de la [clase 345](../345-rendering-temporal/README.md).

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar qué es la iluminación indirecta y por qué importa visualmente.
2. Comparar lightmaps, probes, GI en espacio de pantalla, voxel GI y ray tracing.
3. Explicar las limitaciones de cada técnica y qué las causa.
4. Explicar el papel del BVH y de la aceleración por hardware.
5. Explicar por qué el ray tracing en tiempo real necesita denoising temporal.
6. Elegir la técnica adecuada según proyecto, plataforma y restricciones.
7. Configurar y comparar las opciones de GI de Godot midiendo su coste.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Luz directa e indirecta | La segunda es la que hace que una escena parezca real. |
| 2 | La ecuación del rendering | El problema que todas estas técnicas aproximan. |
| 3 | Lightmaps | Máxima calidad, cero dinamismo. |
| 4 | Probes de irradiancia | El compromiso más usado. |
| 5 | GI en espacio de pantalla | Barata y con una limitación evidente. |
| 6 | Voxel GI | Dinámica, con coste de memoria y fugas. |
| 7 | Ray tracing por hardware | Qué acelera exactamente. |
| 8 | Denoising | Sin él, el ray tracing en tiempo real es ruido. |
| 9 | Rendering híbrido | Lo que hacen los juegos de verdad. |
| 10 | Elegir con criterio | Depende del proyecto, no de la moda. |

## 📖 Definiciones y características

- **Iluminación directa**: la que llega de la fuente al objeto sin rebotar. Clave: es la fácil y la que todos los motores hacen bien.
- **Iluminación global (GI)**: incluye los rebotes. Clave: es lo caro y lo que da realismo.
- **Ecuación del rendering**: formulación integral de cuánta luz sale de un punto. Clave: es recursiva, y por eso el problema es difícil.
- **Irradiancia**: luz que llega a un punto por unidad de área. Clave: es lo que suelen almacenar los probes.
- **Radiancia**: luz que viaja en una dirección concreta. Clave: es lo que necesitan los reflejos.
- **Lightmap**: textura con la luz indirecta precalculada sobre la superficie. Clave: calidad máxima, geometría y luces estáticas.
- **Horneado (baking)**: proceso offline que calcula el lightmap. Clave: minutos u horas; por eso no vale para lo dinámico.
- **Probe de irradiancia**: punto del espacio que guarda la luz que llega desde todas las direcciones. Clave: los objetos dinámicos interpolan entre probes.
- **Armónicos esféricos (SH)**: representación compacta de la luz direccional. Clave: 9 coeficientes por canal bastan para irradiancia difusa.
- **SSGI / SSAO / SSR**: técnicas en espacio de pantalla. Clave: baratas, y solo ven lo que está en pantalla.
- **Voxel GI**: la escena se voxeliza y la luz se propaga por el volumen. Clave: dinámica, con coste de memoria y fugas de luz.
- **SDFGI**: GI basada en campos de distancia con cascadas. Clave: la opción dinámica de Godot para exteriores grandes.
- **Ray tracing**: trazar rayos y calcular sus intersecciones. Clave: es el método correcto, y el caro.
- **BVH de aceleración**: estructura que hace viable el trazado. Clave: sin ella, cada rayo probaría contra toda la geometría (clase 342).
- **RT por hardware**: unidades dedicadas al recorrido del BVH y a las intersecciones. Clave: aceleran eso, no el sombreado.
- **Rayos por píxel (spp)**: cuántos rayos se trazan. Clave: en tiempo real, 0,5-2; en cine, miles.
- **Denoising**: reconstruir una imagen limpia a partir de una muy ruidosa. Clave: es lo que hace posible el RT en tiempo real.
- **Path tracing**: seguir el camino completo de la luz con múltiples rebotes. Clave: la referencia de calidad; en tiempo real solo en escenas acotadas.
- **Rendering híbrido**: rasterización para lo directo, RT para efectos concretos. Clave: es lo que hacen los juegos reales.
- **Fuga de luz (light leaking)**: luz que atraviesa geometría que debería bloquearla. Clave: artefacto característico de probes y voxels.

## 🧰 Herramientas y preparación

Godot 4.x con sus tres sistemas de GI: `LightmapGI` (horneado), `VoxelGI` (dinámica, interiores) y `SDFGI` (dinámica, exteriores grandes), más `ReflectionProbe` y SSAO/SSIL. Trabajaremos en `res://gi/` con una escena de comparación. Necesitas GPU para la parte visual; los cálculos de armónicos esféricos y el análisis de coste se pueden verificar sin ella. Documentación: [iluminación global en Godot](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/index.html).

## 🧪 Laboratorio guiado

1. **Qué aporta la luz indirecta.** El experimento que lo hace evidente:

```text
Habitación con una ventana, suelo blanco, techo blanco:

SOLO DIRECTA:
  - Rectángulo de sol en el suelo, brillante.
  - Todo lo demás: NEGRO. El techo, negro. Las paredes en sombra, negras.
  - Los objetos fuera del rectángulo, invisibles.
  → Parece un decorado con un foco.

CON INDIRECTA (1 rebote):
  - El rectángulo de sol ilumina el techo desde abajo.
  - Las paredes reciben luz rebotada del suelo.
  - Los objetos en sombra son visibles, con luz suave.
  → Parece una habitación.

CON INDIRECTA (varios rebotes):
  - La luz se reparte por toda la habitación.
  - Aparece el color bleeding: un suelo rojo tiñe de rojo el techo.
  → Parece una fotografía.
```

Y el dato que conviene tener presente: **en un interior, la luz indirecta suele aportar más del 60 % de la iluminación total**. No es un detalle de acabado.

2. **El abanico de técnicas.** La tabla que ordena la clase:

| Técnica | Calidad | Coste runtime | Luces dinámicas | Geometría dinámica | Memoria | Hardware |
|---|---|---|---|---|---|---|
| Solo directa | ✗ | Mínimo | ✅ | ✅ | — | Cualquiera |
| Ambiente constante | Muy baja | Cero | ✅ | ✅ | — | Cualquiera |
| **Lightmaps** | **Máxima** | **Casi cero** | ❌ | ❌ (solo recibe) | Texturas | Cualquiera |
| Probes de irradiancia | Buena | Muy bajo | ❌ (horneados) | ✅ | Baja | Cualquiera |
| SSAO / SSIL | Baja (contacto) | Bajo | ✅ | ✅ | Baja | GPU media |
| SSGI | Media | Medio | ✅ | ✅ | Media | GPU media |
| **Voxel GI** | Buena | Medio-alto | ✅ | ⚠️ parcial | **Alta** | GPU media-alta |
| **SDFGI** | Buena | Medio-alto | ✅ | ⚠️ parcial | Media | GPU media-alta |
| **RT (1 rebote)** | Muy buena | Alto | ✅ | ✅ | Media | **GPU con RT** |
| **Path tracing** | Referencia | Muy alto | ✅ | ✅ | Media | GPU con RT potente |

Las tres decisiones que fija esta tabla: **¿se mueven las luces?**, **¿se mueve la geometría?** y **¿qué hardware mínimo soportas?**. Con esas tres respuestas, la elección casi se hace sola.

3. **Lightmaps.** Calidad máxima, cero dinamismo:

```text
Proceso de horneado:
  1. Cada superficie estática recibe coordenadas UV únicas (UV2, sin solaparse).
  2. Se trazan miles de rayos desde cada texel hacia el hemisferio.
  3. Se acumula la luz que llega, con sus rebotes.
  4. Se guarda en una textura por objeto o en un atlas.

Runtime: una lectura de textura. Es literalmente gratis.

Restricciones:
  - Ni la geometría ni las luces se pueden mover: si se mueven, el lightmap
    deja de corresponder con la escena y se ve mal (una sombra donde no hay nada).
  - Los objetos dinámicos NO reciben lightmap: necesitan probes.
  - Horneado de minutos u horas → la iteración de iluminación es lenta.
  - Ocupa memoria de textura, y en mundos grandes mucha.
```

```gdscript
# Verificable sin GPU: un lightmap sin UV2 correcto no sirve de nada, y es el
# error más común. Este script lo detecta antes de hornear tres horas.
func validar_uv2(malla: ArrayMesh) -> Array[String]:
	var errores: Array[String] = []
	for s in malla.get_surface_count():
		var arrays := malla.surface_get_arrays(s)
		var uv2 = arrays[Mesh.ARRAY_TEX_UV2]
		if uv2 == null:
			errores.append("superficie %d: sin UV2 (no se puede hornear)" % s)
			continue
		for uv in uv2:
			if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
				errores.append("superficie %d: UV2 fuera de [0,1]" % s)
				break
	return errores
```

4. **Probes de irradiancia y armónicos esféricos.** El compromiso más usado:

```gdscript
class_name ArmonicosEsfericos
extends RefCounted

# 9 coeficientes por canal (orden 2) bastan para representar la irradiancia
# DIFUSA con muy poco error: la función es suave por naturaleza. Para reflejos
# especulares no basta, y por eso hacen falta reflection probes aparte.
var coef := []          # 9 × Color

func _init() -> void:
	coef.resize(9)
	coef.fill(Color.BLACK)

static func base(d: Vector3) -> PackedFloat32Array:
	# Base de armónicos esféricos hasta orden 2.
	return PackedFloat32Array([
		0.282095,                                     # Y00
		0.488603 * d.y, 0.488603 * d.z, 0.488603 * d.x,   # Y1-1, Y10, Y11
		1.092548 * d.x * d.y,                         # Y2-2
		1.092548 * d.y * d.z,                         # Y2-1
		0.315392 * (3.0 * d.z * d.z - 1.0),           # Y20
		1.092548 * d.x * d.z,                         # Y21
		0.546274 * (d.x * d.x - d.y * d.y),           # Y22
	])

func acumular(direccion: Vector3, radiancia: Color, peso: float) -> void:
	var b := base(direccion)
	for i in 9:
		coef[i] += radiancia * b[i] * peso

func evaluar(normal: Vector3) -> Color:
	var b := base(normal)
	# Coeficientes de convolución con el coseno: convierten radiancia en
	# irradiancia difusa. Son constantes conocidas, no hay que calcularlas.
	const A := [3.141593, 2.094395, 2.094395, 2.094395,
				0.785398, 0.785398, 0.785398, 0.785398, 0.785398]
	var r := Color.BLACK
	for i in 9:
		r += coef[i] * b[i] * A[i]
	return Color(maxf(r.r, 0.0), maxf(r.g, 0.0), maxf(r.b, 0.0))
```

La **fuga de luz** es su artefacto característico: si un probe está dentro de una pared y un objeto cercano interpola desde él, recibe la luz del otro lado. Se mitiga colocando los probes con criterio, con oclusión por probe, o usando probes con información de visibilidad.

5. **Espacio de pantalla.** Barato, con una limitación evidente:

```glsl
// SSAO/SSGI: se muestrea el búfer de profundidad alrededor del píxel para
// estimar cuánta luz le llega. Muy barato, y con un límite claro.
float oclusion_ambiental(vec2 uv, vec3 normal, float radio) {
    float oclusion = 0.0;
    float prof = texture(profundidad, uv).r;
    for (int i = 0; i < N_MUESTRAS; i++) {
        vec2 offset = _muestra_hemisferio(i, normal) * radio;
        float prof_muestra = texture(profundidad, uv + offset).r;
        // Si lo que hay en esa dirección está MÁS CERCA de la cámara, tapa.
        if (prof_muestra < prof - 0.01) {
            oclusion += 1.0;
        }
    }
    return 1.0 - oclusion / float(N_MUESTRAS);
}
```

```text
LA limitación, y no tiene solución dentro de la técnica:

  Solo se ve lo que está EN PANTALLA. Por tanto:
    - Un objeto fuera de cámara no proyecta oclusión ni aporta rebote.
    - Un objeto tapado por otro no contribuye.
    - Al girar la cámara, la iluminación indirecta CAMBIA. Es incorrecto y
      se nota, sobre todo en los bordes de la pantalla.

  Por eso el espacio de pantalla se usa como COMPLEMENTO (detalle de contacto)
  y no como fuente principal de GI.
```

6. **Ray tracing por hardware.** Qué acelera exactamente:

```text
Lo que hace una unidad de RT por hardware:
  1. Recorrer el BVH (la estructura de la clase 342) muy rápido.
  2. Calcular intersecciones rayo-triángulo en paralelo.

Lo que NO hace:
  - Sombrear el punto de impacto (eso lo hacen los shaders normales).
  - Construir el BVH (lo construye el driver, y cuesta).
  - Eliminar el ruido (eso es el denoiser).

Estructura de aceleración en dos niveles:
  TLAS (top level)     → instancias del mundo, con su transformada
    └─ BLAS (bottom)   → geometría de cada malla, en su espacio local

  Mover un objeto = actualizar su entrada en el TLAS (barato).
  Deformar una malla (animación) = reconstruir su BLAS (caro).
  ← Por eso los personajes animados son lo más costoso del RT.
```

7. **Por qué hace falta denoising.** El dato que lo explica todo:

```text
Rayos por píxel necesarios para una imagen limpia por fuerza bruta: ~1.000
Rayos por píxel viables en tiempo real:                             0,5 - 2

  Con 1 rayo/píxel, la imagen es PURO RUIDO. Inutilizable.

El pipeline real:
  1. Trazar 1 rayo por píxel               → imagen extremadamente ruidosa
  2. Filtrado espacial guiado por normal,  → reduce el ruido usando vecinos
     profundidad y material                   de la MISMA superficie
  3. Acumulación temporal con motion       → suma muestras de frames pasados
     vectors (clase 345)                      → equivale a decenas de rayos
  4. Filtrado final y nitidez              → resultado utilizable

  Y de ahí sale la conclusión: el ray tracing en tiempo real HEREDA todos los
  artefactos del rendering temporal. El ghosting en reflejos y las estelas en
  las sombras RT son exactamente el problema de la clase 345.
```

8. **Rendering híbrido.** Lo que hacen los juegos de verdad:

```text
Ningún juego traza todo con rayos. Se combinan técnicas por efecto:

  Geometría y luz directa    → rasterización (rápida y madura)
  Sombras                    → shadow maps, o RT si el presupuesto llega
  Reflejos                   → SSR primero; RT donde SSR falla (fuera de pantalla)
  Oclusión ambiental         → SSAO, o RTAO
  GI difusa                  → probes/SDFGI, o RT con 1 rebote
  Refracción y cáusticas     → aproximaciones; RT completo casi nunca

Y con niveles de calidad por hardware:
  Bajo:   directa + probes horneados + SSAO
  Medio:  + SSGI + SSR
  Alto:   + SDFGI o Voxel GI
  Ultra:  + reflejos RT + sombras RT
```

9. **Comparar en Godot, midiendo.** No a ojo:

```gdscript
extends SceneTree   # gi/comparar.gd

const CONFIGS := [
	{"nombre": "solo_directa", "gi": "ninguna", "ssao": false},
	{"nombre": "ambiente",     "gi": "ambiente", "ssao": false},
	{"nombre": "ssao",         "gi": "ambiente", "ssao": true},
	{"nombre": "lightmap",     "gi": "lightmap", "ssao": true},
	{"nombre": "voxelgi",      "gi": "voxel", "ssao": true},
	{"nombre": "sdfgi",        "gi": "sdfgi", "ssao": true},
]

func _init() -> void:
	print("== Coste y calidad de las técnicas de GI ==")
	print("  técnica         ms/frame   VRAM MB   dinámica   PSNR vs ref")
	var referencia := _renderizar_referencia()      # path traced offline
	for c in CONFIGS:
		var r := _medir(c)
		print("  %-14s %8.2f %9.1f   %-9s %8.2f"
			% [c["nombre"], r["ms"], r["vram_mb"],
			   "sí" if r["dinamica"] else "no", _psnr(referencia, r["imagen"])])
	quit()
```

10. **Elegir con criterio.** El árbol de decisión:

```text
¿Las luces y la geometría son ESTÁTICAS?
├─ SÍ  → Lightmaps + probes para lo dinámico.
│        Es la mejor calidad por el menor coste runtime. Sigue siendo la
│        elección correcta para muchísimos juegos, y no es "anticuada".
└─ NO  → ¿Qué se mueve?
   ├─ Solo objetos (luces fijas) → Lightmaps + probes de irradiancia
   ├─ Ciclo día/noche            → SDFGI o Voxel GI
   ├─ Todo (destrucción, construcción) → SDFGI, o RT si el público lo permite
   └─ ¿Y el hardware mínimo?
      ├─ Móvil / gama baja  → Probes horneados + SSAO. Nada más.
      ├─ Consola actual     → SDFGI o Voxel GI, RT opcional
      └─ PC de gama alta    → RT como opción de calidad, nunca como requisito
```

## ✍️ Ejercicios

1. Monta una escena de habitación con ventana y compárala con y sin GI.
2. Hornea un lightmap y mide el tiempo de horneado y el coste en runtime.
3. Implementa la evaluación de armónicos esféricos y verifica que una luz uniforme da irradiancia uniforme.
4. Provoca una fuga de luz colocando mal un probe y arréglala.
5. Compara SSAO, VoxelGI y SDFGI en la misma escena midiendo ms/frame y VRAM.
6. Gira la cámara con SSGI activado y observa cómo cambia la iluminación indirecta.
7. Diseña los cuatro niveles de calidad gráfica de tu juego con las técnicas de cada uno.

## 📝 Reto verificable

Construye una escena de comparación de técnicas de iluminación global con **al menos cinco configuraciones**, medición de coste (ms/frame y VRAM), comparación objetiva de calidad frente a una referencia, validación de UV2 para lightmaps, implementación verificable de armónicos esféricos y documentación del árbol de decisión aplicado a tu proyecto.

**Criterio de aceptación**: (a) una prueba headless verifica que la base de armónicos esféricos es correcta: una radiancia **uniforme** en todas las direcciones produce irradiancia uniforme al evaluarla en cualquier normal, con error menor del 1 %; (b) el validador de UV2 detecta mallas sin UV2 y con UV2 fuera de `[0,1]`; (c) el banco de comparación mide ms/frame y VRAM de las cinco configuraciones e imprime la tabla; (d) la calidad se compara objetivamente contra una imagen de referencia con PSNR; (e) se documenta, para cada técnica, si soporta luces dinámicas y geometría dinámica, comprobado moviendo ambas en la escena; (f) el proyecto define **al menos tres** niveles de calidad gráfica con su combinación de técnicas y su hardware objetivo; (g) el README documenta el árbol de decisión aplicado y por qué se eligió la técnica principal.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Las sombras son completamente negras | No hay iluminación indirecta. Añade probes, GI o al menos ambiente. |
| Un objeto dinámico se ve plano en una escena horneada | Los lightmaps no le afectan. Necesita probes de irradiancia. |
| Luz que atraviesa una pared | Fuga de luz de probes o voxels. Recoloca, ajusta resolución o usa oclusión. |
| La iluminación cambia al girar la cámara | Es SSGI: solo ve lo que está en pantalla. Complementa con GI no dependiente de vista. |
| El horneado tarda horas y hay que iterar | Hornea a baja calidad para iterar y a alta solo para la build. |
| El lightmap se ve con costuras o manchas | UV2 solapadas o mal generadas. Valídalas antes de hornear. |
| Los reflejos RT tienen ghosting | Es el denoising temporal. Los mismos artefactos de la clase 345. |
| RT activo mata el rendimiento con personajes | Reconstruir el BLAS de mallas animadas es caro. Limita cuáles participan. |
| VoxelGI consume toda la VRAM | Resolución de voxels demasiado alta. Bájala o usa SDFGI. |

## ❓ Preguntas frecuentes

**❓ ¿Los lightmaps están anticuados?** En absoluto. Siguen dando la mejor calidad por el menor coste en runtime, y para un juego con iluminación estática son la elección correcta. Lo que ha cambiado es que ahora hay alternativas dinámicas viables — no que las horneadas hayan dejado de ser buenas. Muchos juegos con excelente iluminación de los últimos años usan lightmaps.

**❓ ¿Merece la pena el ray tracing?** Como **opción de calidad** en PC de gama alta, sí: mejora reflejos, sombras y GI de forma notable. Como **requisito**, casi nunca: dejas fuera a la mayoría de tu público. La regla práctica es que el juego debe verse bien sin RT y mejor con él.

**❓ ¿Por qué el RT es tan caro si el hardware lo acelera?** Porque el hardware acelera **el trazado**, no el sombreado ni el denoising. Con 1 rayo por píxel a 4K son 8 millones de rayos por frame, cada uno con su sombreado, más el filtrado espacial y la acumulación temporal. La aceleración es enorme comparada con hacerlo en software, y aun así el presupuesto sigue siendo justo.

**❓ ¿Qué elijo para un proyecto pequeño?** Lightmaps para lo estático, probes para lo dinámico, SSAO para el detalle de contacto. Es la combinación con mejor relación calidad/esfuerzo, funciona en cualquier hardware y su coste en runtime es mínimo. Solo cambia si necesitas luces dinámicas de verdad.

**❓ ¿Cómo pruebo esto en CI sin GPU?** No puedes probar la imagen, y conviene decirlo claro. Lo que **sí** se verifica sin GPU es lo que se comprueba en el reto: la corrección de los armónicos esféricos, la validez de las UV2, la configuración de los niveles de calidad y que las escenas cargan e importan limpias. La comprobación visual se documenta y se hace en una máquina con GPU, antes de cada release.

## 🔗 Referencias

- Akenine-Möller, Haines & Hoffman — *Real-Time Rendering*, capítulo de iluminación global: <https://www.realtimerendering.com/>
- Pharr, Jakob & Humphreys — *Physically Based Rendering* (libro completo en abierto): <https://www.pbr-book.org/>
- Godot Docs — Iluminación global (LightmapGI, VoxelGI, SDFGI): <https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/index.html>
- Godot Docs — `LightmapGI` y horneado: <https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_lightmap_gi.html>
- Ramamoorthi & Hanrahan — *An Efficient Representation for Irradiance Environment Maps* (armónicos esféricos): <https://cseweb.ucsd.edu/~ravir/papers/envmap/>
- NVIDIA — Ray Tracing Gems (volúmenes en abierto): <https://www.realtimerendering.com/raytracinggems/>

## ⬅️ Clase anterior

[Clase 347 - HDR y gestión moderna de color](../347-hdr-y-gestion-moderna-de-color/README.md)

## ➡️ Siguiente clase

[Clase 349 - GPU-driven rendering](../349-gpu-driven-rendering/README.md)
