# Clase 350 — Shader compilation y stutter

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Documentación de pipeline state objects de Vulkan y DirectX 12 · Documentación de precompilación de shaders de Godot 4*
> ⏱️ Duración estimada: **115 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Diagnosticar y eliminar uno de los problemas más comunes y peor entendidos de los juegos modernos: **el tirón la primera vez que ocurre algo**. Entras en una sala nueva y el juego se congela un cuarto de segundo. Lanzas un hechizo por primera vez y hay un salto. Aparece un enemigo nuevo y el frame se va a 200 ms. Y solo pasa la primera vez.

La causa casi siempre es la misma: **compilación de shaders en tiempo de ejecución**. El shader que escribiste no es lo que ejecuta la GPU; hay que compilarlo para ese hardware concreto, y esa compilación tarda milisegundos o decenas de milisegundos. Si ocurre en mitad de la partida, es un tirón.

Vas a entender por qué existe el problema, por qué se agravó con las APIs modernas, y las tres soluciones reales: **reducir las variantes**, **precompilar** y **calentar la caché** — con la parte incómoda de que ninguna es gratis.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar la cadena de compilación de un shader y en qué punto se paga.
2. Explicar qué es un PSO y por qué las APIs modernas agravaron el problema.
3. Calcular la explosión combinatoria de variantes de un shader.
4. Reducir el número de variantes con técnicas concretas.
5. Implementar precompilación y calentamiento de caché.
6. Diagnosticar un tirón y determinar si es compilación de shaders.
7. Medir el problema y verificar que la solución funciona.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | La cadena de compilación | Explica dónde se paga y cuándo. |
| 2 | PSO | Por qué el problema empeoró con Vulkan y DX12. |
| 3 | Variantes | La explosión combinatoria es el origen. |
| 4 | Reducir variantes | La solución que ataca la causa. |
| 5 | Caché del driver | Existe, y no es suficiente por sí sola. |
| 6 | Caché de la aplicación | La que tú controlas y puedes distribuir. |
| 7 | Precompilación | Compilar antes de necesitarlo. |
| 8 | Calentamiento | Ejercitar el pipeline en un momento seguro. |
| 9 | Diagnóstico | Distinguir este tirón de otros. |
| 10 | El coste de las soluciones | Ninguna es gratis. |

## 📖 Definiciones y características

- **Shader fuente**: el código que escribes (GLSL, HLSL, gdshader). Clave: no es lo que ejecuta la GPU.
- **Representación intermedia**: forma portable compilada (SPIR-V, DXIL). Clave: se genera en tiempo de build.
- **Código nativo de GPU**: instrucciones del hardware concreto. Clave: solo el driver puede generarlo, y es donde se paga.
- **Compilación en runtime**: generar el código nativo durante la partida. Clave: es la causa del tirón.
- **PSO (pipeline state object)**: objeto que agrupa shaders y todo el estado fijo del pipeline. Clave: crearlo es lo caro, y hay que crear uno por combinación.
- **Variante (permutación)**: versión del shader compilada con unas opciones concretas. Clave: su número crece exponencialmente.
- **Explosión combinatoria**: N opciones booleanas producen 2^N variantes. Clave: es el origen del problema.
- **Bifurcación estática**: `#ifdef` que genera variantes distintas. Clave: rápido en GPU, caro en número de variantes.
- **Bifurcación dinámica**: `if` en tiempo de ejecución con un uniform. Clave: una sola variante, algo más lento en GPU.
- **Caché de pipeline del driver**: el driver guarda lo compilado. Clave: ayuda, pero se invalida al actualizar driver o GPU.
- **Caché de la aplicación**: la que tu juego guarda y gestiona. Clave: es la que puedes distribuir y controlar.
- **Precompilación (AOT)**: compilar antes de ejecutar. Clave: elimina el problema donde es posible.
- **Calentamiento (warm-up)**: crear los PSO en un momento controlado. Clave: mueve el coste a una pantalla de carga.
- **Colección de PSO**: lista de las combinaciones que el juego usa. Clave: se recoge jugando, no se adivina.
- **Compilación asíncrona**: compilar en otro hilo mientras se usa un sustituto. Clave: evita el tirón a costa de un frame incorrecto.
- **Stutter**: tirón puntual en el frame time. Clave: mucho más molesto que un framerate bajo pero estable.

## 🧰 Herramientas y preparación

Godot 4.x con `Project Settings → Rendering → Shader Compiler` y las opciones de precompilación disponibles. Trabajaremos en `res://shaders_precarga/`. Para diagnosticar necesitas un gráfico de frame time (el monitor de rendimiento de Godot o `Performance.TIME_PROCESS`) y, si puedes, [RenderDoc](https://renderdoc.org/). Ten a mano la clase [253](../../parte-14-optimizacion-profiling-y-rendimiento/253-herramientas-nativas-de-profiling-renderdoc/README.md).

## 🧪 Laboratorio guiado

1. **La cadena, y dónde se paga:**

```text
TIEMPO DE DESARROLLO
  shader.gdshader / .hlsl
      ↓ compilador del motor
  SPIR-V / DXIL (representación intermedia, portable)
      ↓
  Se distribuye con el juego ✔ (esto es barato y ya está hecho)

TIEMPO DE EJECUCIÓN, en la máquina del jugador
  SPIR-V
      ↓ DRIVER de la GPU                      ← AQUÍ SE PAGA
  Código nativo del hardware concreto
      ↓
  Crear el PSO con TODO el estado             ← Y AQUÍ TAMBIÉN
      ↓
  Dibujar

  Coste: 5-50 ms por PSO, y hasta cientos con shaders complejos.
  A 16,6 ms de presupuesto, UN solo PSO en mitad del juego = tirón visible.
```

2. **Por qué empeoró con las APIs modernas.** No es una regresión casual:

```text
OpenGL / DirectX 11 (implícito)
  El driver mantenía el estado y compilaba cuando le parecía, a veces en
  segundo plano, a veces recompilando por su cuenta. Menos tirones, pero
  el juego no controlaba NADA: los tirones aparecían de forma impredecible.

Vulkan / DirectX 12 (explícito)
  Todo el estado se fija en un PSO que se crea explícitamente:
    shaders + blending + profundidad + rasterización + formato de destino...

  → El juego controla CUÁNDO se compila.
  → Pero también es RESPONSABLE de hacerlo a tiempo.
  → Si no lo hace, el tirón es peor y más evidente.

  Es un cambio de "el driver lo hace mal por ti" a "lo haces tú, bien o mal".
```

3. **La explosión combinatoria.** El origen del problema:

```glsl
// Un shader de material con opciones "razonables":
#ifdef TIENE_NORMAL_MAP
#ifdef TIENE_EMISION
#ifdef TIENE_AO
#ifdef ES_TRANSPARENTE
#ifdef RECIBE_SOMBRAS
#ifdef TIENE_VIENTO
#ifdef ES_SKINNED
#ifdef USA_LIGHTMAP

// 8 opciones booleanas → 2^8 = 256 variantes
// Multiplicado por los estados del pipeline:
//   × 3 modos de blending
//   × 2 modos de cull
//   × 2 formatos de destino (HDR / sombras)
//   = 3.072 PSO POSIBLES
//
// A 20 ms cada uno, compilarlos todos son 61 segundos.
```

```gdscript
extends SceneTree   # shaders_precarga/analizar.gd

func _init() -> void:
	print("== Análisis de variantes ==")
	var opciones := _contar_defines("res://shaders/")
	for shader in opciones:
		var n := opciones[shader]
		var variantes := 1 << n
		var estados := 12                      # blending × cull × destino
		print("  %-28s %2d opciones → %5d variantes × %d estados = %6d PSO"
			% [shader, n, variantes, estados, variantes * estados])
		if variantes * estados > 500:
			print("     ⚠ demasiadas: reduce opciones o pasa a bifurcación dinámica")
	quit()
```

4. **Reducir variantes.** La solución que ataca la causa, no el síntoma:

```glsl
// ❌ ANTES: cada opción duplica el número de variantes.
#ifdef TIENE_NORMAL_MAP
    vec3 n = texture(normal_map, UV).xyz * 2.0 - 1.0;
#else
    vec3 n = vec3(0.0, 0.0, 1.0);
#endif
#ifdef TIENE_AO
    float ao = texture(ao_map, UV).r;
#else
    float ao = 1.0;
#endif

// ✅ DESPUÉS: una sola variante. Las GPU modernas manejan bien una rama
//    uniforme (todos los píxeles del draw toman el mismo camino), y el coste
//    es mucho menor que el de compilar 4 variantes en runtime.
uniform bool tiene_normal_map;
uniform bool tiene_ao;

vec3 n = tiene_normal_map ? (texture(normal_map, UV).xyz * 2.0 - 1.0) : vec3(0.0, 0.0, 1.0);
float ao = tiene_ao ? texture(ao_map, UV).r : 1.0;
```

Las cuatro técnicas, por orden de eficacia:

| Técnica | Reducción | Coste |
|---|---|---|
| **Bifurcación dinámica** en vez de `#ifdef` | 2^N → 1 | Ligera pérdida en GPU |
| **Texturas por defecto** (normal plana, AO blanco) | Elimina la opción entera | Una lectura de textura extra |
| **Empaquetar canales** (AO+rough+metal en un RGB) | Menos opciones y menos lecturas | Trabajo de pipeline de assets |
| **Podar combinaciones imposibles** | 30-70 % típico | Hay que saber cuáles son |

La última merece explicación: de las 3.072 combinaciones del ejemplo, muchísimas **no ocurren nunca** (un material transparente que además use lightmap y esté skinned). Recogiendo las que de verdad se usan, el número real suele estar entre 50 y 300.

5. **Recoger las que se usan.** No se adivinan, se miden:

```gdscript
class_name ColectorPSO
extends RefCounted

# En builds de desarrollo, se registra cada combinación que el juego pide de
# verdad. Ese registro es la lista de precarga: exacta, sin sobras y sin
# faltas.
var _vistas := {}
var _orden: Array[String] = []

func registrar(shader: String, defines: Array, estado: Dictionary) -> void:
	if not OS.is_debug_build():
		return
	var clave := "%s|%s|%s" % [shader, ",".join(defines), _clave_estado(estado)]
	if _vistas.has(clave):
		return
	_vistas[clave] = {"shader": shader, "defines": defines, "estado": estado,
					  "primera_vez": Time.get_ticks_msec()}
	_orden.append(clave)

func exportar(ruta: String) -> void:
	var lista := _orden.map(func(k): return _vistas[k])
	FileAccess.open(ruta, FileAccess.WRITE).store_string(
		JSON.stringify({"version": 1, "pso": lista}, "\t"))
	print("Exportadas %d combinaciones de PSO a %s" % [lista.size(), ruta])
```

El flujo de producción es este: **QA juega el juego entero con una build instrumentada**, se exportan las combinaciones, se revisan y se distribuyen con el juego como lista de precarga. Es tedioso y es lo que funciona.

6. **El calentamiento.** Mover el coste a un momento en que no molesta:

```gdscript
class_name CalentamientoShaders
extends Node

signal progreso(hechos: int, total: int)
signal terminado(ms_total: float)

var _pendientes: Array = []
var _hechos := 0
var _t0 := 0.0

func cargar_lista(ruta: String) -> void:
	var d = JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())
	_pendientes = d.get("pso", [])

func _process(_delta: float) -> void:
	if _pendientes.is_empty():
		return
	if _t0 == 0.0:
		_t0 = Time.get_ticks_msec()

	# Presupuesto POR FRAME: si se compilan todos de golpe, la pantalla de
	# carga se congela y parece que el juego ha muerto. Compilando unos pocos
	# por frame, la barra de progreso se mueve y el juego responde.
	var limite := Time.get_ticks_msec() + 8.0
	while not _pendientes.is_empty() and Time.get_ticks_msec() < limite:
		var pso: Dictionary = _pendientes.pop_front()
		_crear_pso(pso)
		_hechos += 1
		progreso.emit(_hechos, _hechos + _pendientes.size())

	if _pendientes.is_empty():
		terminado.emit(Time.get_ticks_msec() - _t0)

func _crear_pso(pso: Dictionary) -> void:
	# El truco clásico: dibujar un triángulo diminuto (o fuera de pantalla)
	# con esa combinación exacta. Fuerza al driver a compilar y crear el PSO,
	# y no se ve nada.
	var mat := _material_con(pso["shader"], pso["defines"])
	_quad_invisible.material_override = mat
	_quad_invisible.visible = true
	RenderingServer.force_draw()
	_quad_invisible.visible = false
```

7. **La caché de pipeline.** Persistir lo compilado entre sesiones:

```gdscript
class_name CachePipeline
extends RefCounted

const RUTA := "user://cache_pipeline.bin"

# El driver puede devolver un blob binario con lo compilado. Guardarlo hace
# que la SEGUNDA ejecución del juego arranque sin recompilar nada.
func guardar(datos: PackedByteArray, id_gpu: String, version_driver: String) -> void:
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	f.store_pascal_string(id_gpu)
	f.store_pascal_string(version_driver)
	f.store_pascal_string(_version_juego())
	f.store_32(datos.size())
	f.store_buffer(datos)

func cargar(id_gpu: String, version_driver: String) -> PackedByteArray:
	if not FileAccess.file_exists(RUTA):
		return PackedByteArray()
	var f := FileAccess.open(RUTA, FileAccess.READ)
	# La caché es específica de GPU, DRIVER y versión del juego. Usar una
	# caché de otro driver produce, en el mejor caso, que se ignore; en el
	# peor, comportamiento indefinido. Se comprueban las tres cosas.
	if f.get_pascal_string() != id_gpu: return PackedByteArray()
	if f.get_pascal_string() != version_driver: return PackedByteArray()
	if f.get_pascal_string() != _version_juego(): return PackedByteArray()
	return f.get_buffer(f.get_32())
```

Y por eso el jugador nota que **la primera partida tras actualizar el driver vuelve a tener tirones**: la caché se ha invalidado, y es correcto que lo haga.

8. **Diagnosticar.** Distinguir este tirón de los demás:

```gdscript
class_name DetectorStutter
extends Node

signal stutter(ms: float, contexto: Dictionary)

const UMBRAL_FACTOR := 3.0

var _historial := PackedFloat32Array()
var _primeras_veces := {}

func _process(_d: float) -> void:
	var ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_historial.append(ms)
	if _historial.size() > 120:
		_historial.remove_at(0)
	if _historial.size() < 60:
		return

	var mediana := _mediana(_historial)
	if ms > mediana * UMBRAL_FACTOR and ms > 30.0:
		# Se captura el CONTEXTO: sin él, un tirón es un número inútil.
		stutter.emit(ms, {
			"mediana": mediana,
			"escena": get_tree().current_scene.name,
			"materiales_nuevos": _materiales_nuevos_este_frame(),
			"objetos_nuevos": _objetos_instanciados_este_frame(),
			"memoria_delta": _delta_memoria(),
		})
```

| Síntoma | Probable causa | Cómo confirmarlo |
|---|---|---|
| Solo la **primera vez** que aparece algo | Compilación de shaders | Repetir la acción: el segundo no da tirón |
| Solo la primera vez tras actualizar el driver | Caché invalidada | Comprobar la versión del driver |
| Cada vez que aparece, siempre | Carga de recursos | Perfilar E/S y asignaciones |
| Periódico, cada pocos segundos | GC o asignaciones (clase 340) | Contador de asignaciones por frame |
| Al entrar en una zona | Streaming | Perfilar carga de recursos (clase 343) |
| Aleatorio, sin patrón | Sistema operativo, otro proceso | Repetir con el sistema descargado |

La prueba definitiva es sencilla: **repite la misma acción**. Si el primer tirón no se repite, es compilación.

9. **Medirlo y verificar la solución:**

```gdscript
extends SceneTree   # shaders_precarga/medir.gd

func _init() -> void:
	print("== Impacto de la precarga de shaders ==")

	# SIN precarga: se recorre la escena y se cuentan los tirones.
	_limpiar_caches()
	var sin_precarga := _recorrer_escena_midiendo()
	print("  Sin precarga:")
	print("    tirones > 30 ms:  %d" % sin_precarga["tirones"])
	print("    peor frame:       %.1f ms" % sin_precarga["peor"])
	print("    p99 frame time:   %.1f ms" % sin_precarga["p99"])

	# CON precarga: se calienta antes y se repite exactamente el recorrido.
	_limpiar_caches()
	var t0 := Time.get_ticks_msec()
	await _calentar("res://datos/pso_recogidos.json")
	var ms_calentamiento := Time.get_ticks_msec() - t0
	var con_precarga := _recorrer_escena_midiendo()
	print("  Con precarga (%.1f s de calentamiento):" % (ms_calentamiento / 1000.0))
	print("    tirones > 30 ms:  %d" % con_precarga["tirones"])
	print("    peor frame:       %.1f ms" % con_precarga["peor"])
	print("    p99 frame time:   %.1f ms" % con_precarga["p99"])
	quit()
```

10. **El coste de las soluciones.** La parte honesta:

| Solución | Elimina el tirón | Coste |
|---|---|---|
| Reducir variantes | Parcialmente | Algo de rendimiento en GPU |
| Precompilar todo al arrancar | ✅ | **Arranque mucho más largo** (30-120 s) |
| Calentar por zona | ✅ en esa zona | Pantallas de carga más largas |
| Caché persistente | ✅ a partir de la 2.ª sesión | La primera sigue mal |
| Compilación asíncrona con sustituto | ✅ el tirón | Frames con el material equivocado |
| No hacer nada | ❌ | Tirones que el jugador nota y comenta |

No hay una opción sin coste, y por eso la respuesta correcta es una **combinación**: reducir variantes agresivamente, precargar por zona con una lista recogida jugando, cachear entre sesiones y aceptar que el primer arranque tras instalar o actualizar el driver será más largo. Decírselo al jugador en la pantalla de carga ("Preparando shaders, solo la primera vez") es mejor que un tirón sin explicación.

## ✍️ Ejercicios

1. Cuenta las variantes de tus shaders con el analizador y encuentra el peor.
2. Convierte tres `#ifdef` en bifurcación dinámica y mide el efecto en variantes y en GPU.
3. Implementa el colector de PSO y recoge la lista jugando 15 minutos.
4. Implementa el calentamiento con presupuesto por frame y mide cuánto tarda.
5. Mide tirones con y sin precarga usando el mismo recorrido.
6. Implementa la caché persistente y comprueba la diferencia entre la primera y la segunda ejecución.
7. Añade el detector de stutter a tu juego y registra en qué momentos aparece.

## 📝 Reto verificable

Implementa un sistema completo contra el stutter de compilación: analizador de variantes, colector de PSO en debug, calentamiento con presupuesto por frame y barra de progreso, caché persistente validada por GPU/driver/versión, detector de stutter con contexto y un banco de medición que compare con y sin precarga.

**Criterio de aceptación**: (a) el analizador informa del número de variantes por shader y avisa de los que superan un umbral; (b) el colector registra cada combinación **una sola vez** y la exporta a JSON; (c) el calentamiento respeta el presupuesto por frame: ningún frame durante el proceso supera los 20 ms, comprobable midiendo; (d) la caché persistente se **rechaza** si cambia el identificador de GPU, la versión del driver o la versión del juego; (e) el banco de medición demuestra que, sobre el mismo recorrido, la precarga reduce los tirones de más de 30 ms **al menos en un 80 %**; (f) el detector de stutter distingue el primer tirón del repetido, comprobable repitiendo la misma acción; (g) el juego informa al jugador durante el calentamiento con progreso real.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Tirón la primera vez que aparece cada efecto | Compilación en runtime. Precarga con lista recogida. |
| La precarga tarda dos minutos | Se precargan todas las combinaciones posibles. Usa solo las recogidas jugando. |
| La pantalla de carga se congela durante la precarga | Sin presupuesto por frame. Compila unos pocos por frame. |
| Los tirones vuelven tras actualizar el driver | La caché se invalidó, y es correcto. Avisa al jugador. |
| Se precargó y siguen los tirones | La lista está incompleta. Recógela jugando el juego entero, no una zona. |
| El juego arranca lentísimo desde que hay precarga | Se precarga todo al inicio. Hazlo por zona. |
| Reducir variantes empeoró el rendimiento | Bifurcación dinámica no uniforme. Comprueba que la rama es uniforme por draw. |
| La caché de otro jugador no funciona | Es específica de GPU y driver. No se puede compartir. |
| Se confunde con tirón de carga de recursos | Repite la acción: si no se repite, es compilación. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué no se compila todo al instalar?** Porque el código nativo depende de la GPU **y de la versión del driver**, que pueden cambiar después de instalar. Algunas plataformas cerradas (consolas) sí pueden precompilarlo todo, porque el hardware es fijo y conocido — y por eso este problema es mucho menos visible en consola que en PC.

**❓ ¿Cuánto puedo reducir las variantes?** Bastante: pasar de `#ifdef` a bifurcación dinámica y usar texturas por defecto suele reducir un orden de magnitud. El coste en GPU es pequeño **si la rama es uniforme** (todos los píxeles del mismo draw toman el mismo camino), que es el caso habitual con un uniform de material.

**❓ ¿Merece la pena la compilación asíncrona con material sustituto?** Es un compromiso: evitas el tirón, pero durante unos frames el objeto se ve con el material equivocado. Funciona bien con un sustituto neutro y objetos pequeños; se nota mucho con superficies grandes. Muchos juegos la usan combinada con precarga, como red de seguridad para lo que la lista no cubrió.

**❓ ¿Godot sufre esto?** Sí, como cualquier motor sobre APIs modernas, y ha ido añadiendo opciones de precompilación. Lo que **tú** controlas en cualquier caso es lo importante: cuántas variantes generan tus materiales y si calientas los que vas a usar antes de necesitarlos.

**❓ ¿Cómo lo pruebo en CI?** El tirón depende del hardware y del driver, así que la medición real necesita una máquina con GPU. Lo que **sí** corre en CI sin GPU es el analizador de variantes (que falle si un shader supera el umbral) y la validación de la lista de PSO. La medición de tirones se hace en una máquina de prueba antes de cada release, con el banco del paso 9.

## 🔗 Referencias

- Godot Docs — Compilación de shaders y precarga: <https://docs.godotengine.org/en/4.3/tutorials/shaders/shader_reference/shader_preprocessor.html> · uso: respalda el Tema 1 «La cadena de compilación»
- Vulkan Docs — Pipeline cache: <https://docs.vulkan.org/spec/latest/chapters/pipelines.html> · uso: respalda el Tema 5 «Caché del driver»
- Microsoft — Pipeline state objects en DirectX 12: <https://learn.microsoft.com/windows/win32/direct3d12/managing-graphics-pipeline-state-in-direct3d-12> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- RenderDoc — captura y análisis de frames: <https://renderdoc.org/> · uso: se instala o se consulta en la preparación
- Akenine-Möller et al. — *Real-Time Rendering*, capítulo de pipeline: <https://www.realtimerendering.com/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 349 - GPU-driven rendering](../349-gpu-driven-rendering/README.md)

## ➡️ Siguiente clase

[Clase 351 - APIs gráficas modernas](../351-apis-graficas-modernas/README.md)
