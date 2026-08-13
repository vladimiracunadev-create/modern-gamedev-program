# Clase 349 — GPU-driven rendering

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Akenine-Möller et al., «Real-Time Rendering» · Documentación de Vulkan y DirectX 12 sobre indirect drawing y mesh shaders*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender el cambio arquitectónico que hizo posible dibujar cientos de miles de objetos: **que la GPU decida qué se dibuja**. En el modelo tradicional, la CPU recorre la escena, decide qué es visible y emite una llamada de dibujo por objeto. Eso pone un techo duro: unos pocos miles de draw calls por frame, porque cada una tiene un coste fijo en CPU y en el driver.

El modelo *GPU-driven* invierte el flujo: la CPU sube **todos** los datos de la escena una vez y emite **una** llamada indirecta; la GPU hace el culling, construye la lista de lo visible y se dibuja a sí misma. El límite deja de ser la CPU y pasa a ser lo que la GPU puede procesar, que es órdenes de magnitud más.

Vas a estudiar las cuatro piezas —**dibujo indirecto**, **culling en GPU**, **acceso bindless** y **mesh shaders**— y las vas a aplicar en Godot con lo que sí está disponible: `MultiMesh`, compute shaders y buffers de almacenamiento.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar el coste real de una draw call y dónde está el techo.
2. Explicar el dibujo indirecto y qué permite exactamente.
3. Implementar culling en compute shader y escribir el resultado en un buffer.
4. Explicar el acceso bindless y por qué es requisito del modelo.
5. Explicar mesh y task shaders y qué problema resuelven.
6. Aplicar el modelo en Godot con `MultiMesh` y compute shaders.
7. Medir la diferencia y saber cuándo el modelo tradicional basta.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Coste de una draw call | Es el techo que este modelo elimina. |
| 2 | Dibujo indirecto | Los parámetros vienen de un buffer, no de la CPU. |
| 3 | Culling en GPU | Miles de tests en paralelo en vez de en serie. |
| 4 | Culling jerárquico de profundidad | Descartar lo tapado, sin la CPU. |
| 5 | Compactación | Convertir "visible sí/no" en una lista densa. |
| 6 | Bindless | Acceder a cualquier textura sin rebindear. |
| 7 | Mesh shaders | Geometría generada y descartada en GPU. |
| 8 | Meshlets | La unidad de trabajo del modelo moderno. |
| 9 | Aplicarlo en Godot | Qué se puede hacer hoy y cómo. |
| 10 | Cuándo no hace falta | La mayoría de los juegos. |

## 📖 Definiciones y características

- **Draw call**: orden de dibujar un conjunto de geometría. Clave: cuesta en CPU y en el driver, al margen de lo que dibuje.
- **Coste por draw call**: entre 5 y 50 µs de CPU según API y driver. Clave: con 10.000, la CPU no hace otra cosa.
- **Cambio de estado**: cambiar shader, textura o buffer entre draws. Clave: suele ser más caro que la propia draw call.
- **Batching**: agrupar objetos que comparten estado en una llamada. Clave: la solución tradicional, y tiene límite.
- **Instancing**: dibujar N copias de la misma malla en una llamada. Clave: excelente para lo repetido, inútil para lo variado.
- **Dibujo indirecto (indirect draw)**: los parámetros de la llamada se leen de un buffer de GPU. Clave: es lo que permite que la GPU decida cuánto dibujar.
- **Multi-draw indirect**: muchas llamadas descritas en un buffer, emitidas de una vez. Clave: la base del modelo.
- **Buffer de comandos de GPU**: buffer que contiene los parámetros de dibujo. Clave: lo escribe un compute shader, no la CPU.
- **Culling en GPU**: descartar objetos invisibles en un compute shader. Clave: paralelo, y sin devolver nada a la CPU.
- **Frustum culling**: descartar lo que queda fuera de la cámara. Clave: el más básico y el más rentable.
- **Occlusion culling**: descartar lo tapado por otra geometría. Clave: en GPU se hace con una pirámide de profundidad.
- **HZB (hierarchical Z-buffer)**: pirámide de mipmaps del búfer de profundidad. Clave: permite probar oclusión de un objeto en una lectura.
- **Compactación (stream compaction)**: convertir un array disperso en uno denso. Clave: se hace con contadores atómicos.
- **Bindless**: acceder a recursos por índice, sin vincularlos previamente. Clave: sin él, cada material obligaría a una llamada distinta.
- **Mesh shader**: sustituye a vertex y geometry shaders con un modelo de cómputo. Clave: puede generar y descartar geometría en GPU.
- **Task (amplification) shader**: decide cuántos mesh shaders lanzar. Clave: es donde se hace el culling de meshlets.
- **Meshlet**: grupo pequeño de triángulos (~64-128) con sus datos de culling. Clave: es la unidad del pipeline moderno.
- **GPU-driven rendering**: modelo donde la GPU decide qué se dibuja. Clave: elimina el cuello de CPU.

## 🧰 Herramientas y preparación

Godot 4.x con `RenderingDevice` (acceso de bajo nivel), compute shaders y `MultiMesh`. Trabajaremos en `res://gpu_driven/`. Godot no expone hoy mesh shaders ni bindless completo desde GDScript, así que esos se explican conceptualmente y se implementa **lo que sí es posible**: culling en compute shader que alimenta un `MultiMesh`, que captura la idea central. Necesitas GPU con soporte de compute (prácticamente cualquiera de la última década).

## 🧪 Laboratorio guiado

1. **El techo de la CPU.** El número que justifica todo el modelo:

```text
Coste típico de una draw call (CPU + driver): ~10-30 µs
Presupuesto de frame a 60 fps:                16.600 µs
Presupuesto para dibujar (la mitad):           8.000 µs

  → Techo práctico: ~500-1.500 draw calls por frame.

Un bosque con 50.000 árboles de 8 especies:
  Sin instancing:  50.000 draw calls  = 750 ms   → 1,3 fps
  Con instancing:       8 draw calls  =   0,2 ms → perfecto,
                                                   pero se dibujan TODOS,
                                                   incluidos los 45.000 que
                                                   no se ven.
  GPU-driven:           1 draw call indirecta → la GPU descarta los invisibles
                                                y dibuja solo los ~5.000 visibles.
```

Ahí está la clave: el instancing resuelve el problema de la CPU pero **no puede hacer culling por instancia**, porque eso exigiría que la CPU decidiera, que es lo que queríamos evitar. GPU-driven resuelve las dos cosas.

2. **El modelo, comparado:**

```text
TRADICIONAL (la CPU decide)
  CPU: recorrer escena → cull → ordenar → 1 draw call por objeto
   │    (serie, en CPU, y hay que hacerlo entero antes de empezar)
   ▼
  GPU: dibujar lo que le mandan

GPU-DRIVEN (la GPU decide)
  CPU: subir TODA la escena a un buffer (una vez) → 1 dispatch + 1 draw indirecto
   │
   ▼
  GPU: [compute] cull de 100.000 objetos en paralelo
       [compute] compactar los visibles en una lista densa
       [compute] escribir el buffer de comandos de dibujo
       [draw indirecto] dibujar exactamente esa lista
```

3. **El buffer de escena.** Todo en GPU, en formato plano:

```glsl
// Los datos de TODOS los objetos, subidos una vez. Nada de esto vuelve a la
// CPU: el modelo entero se apoya en que la comunicación es de ida.
struct ObjetoEscena {
    mat4  transformada;
    vec4  esfera_envolvente;   // xyz = centro en mundo, w = radio
    uint  indice_malla;
    uint  indice_material;
    uint  banderas;            // proyecta sombra, es transparente, ...
    float distancia_lod;
};

layout(set = 0, binding = 0, std430) readonly buffer Escena {
    ObjetoEscena objetos[];
};

// Salida del culling: la lista compacta de lo que SÍ se dibuja.
layout(set = 0, binding = 1, std430) writeonly buffer Visibles {
    uint indices_visibles[];
};

// Contador atómico: cuántos han pasado el culling. Es lo que después va al
// campo `instanceCount` del comando de dibujo indirecto.
layout(set = 0, binding = 2, std430) buffer Contador {
    uint n_visibles;
};
```

4. **El culling en compute shader.** Miles de tests en paralelo:

```glsl
#[compute]
#version 450

layout(local_size_x = 64) in;

layout(push_constant) uniform Camara {
    vec4 planos[6];        // frustum
    vec3 pos_camara;
    float lod_distancia;
} camara;

void main() {
    uint i = gl_GlobalInvocationID.x;
    if (i >= objetos.length()) return;

    vec4 esfera = objetos[i].esfera_envolvente;

    // ── 1. FRUSTUM CULLING ──────────────────────────────────────────────
    // Esfera contra los 6 planos. Barato y descarta la mayor parte.
    for (int p = 0; p < 6; p++) {
        if (dot(camara.planos[p].xyz, esfera.xyz) + camara.planos[p].w < -esfera.w) {
            return;                            // fuera de cámara: no se dibuja
        }
    }

    // ── 2. CULLING POR DISTANCIA ────────────────────────────────────────
    float dist = distance(camara.pos_camara, esfera.xyz);
    if (dist > camara.lod_distancia) return;

    // ── 3. OCCLUSION CULLING con la pirámide de profundidad ─────────────
    // Se proyecta la esfera a pantalla, se elige el nivel de mip cuyo texel
    // cubra el objeto entero, y se compara con la profundidad más cercana
    // guardada ahí. Una sola lectura descarta un objeto tapado.
    vec4 caja_pantalla = proyectar_esfera(esfera, camara);
    float mip = ceil(log2(max(caja_pantalla.z - caja_pantalla.x,
                              caja_pantalla.w - caja_pantalla.y)));
    float prof_hzb = textureLod(piramide_profundidad, (caja_pantalla.xy + caja_pantalla.zw) * 0.5, mip).r;
    if (profundidad_minima_de(esfera, camara) > prof_hzb) {
        return;                                 // tapado: no se dibuja
    }

    // ── 4. COMPACTACIÓN ─────────────────────────────────────────────────
    // El incremento atómico devuelve una posición ÚNICA por hilo. Así los
    // miles de hilos que pasan el culling escriben en una lista densa sin
    // pisarse y sin ninguna sincronización explícita.
    uint slot = atomicAdd(n_visibles, 1u);
    indices_visibles[slot] = i;
}
```

Un detalle importante del punto 4: como el orden en que los hilos llegan al `atomicAdd` **no está definido**, la lista resultante no tiene un orden determinista. Da igual para dibujar opacos (el z-buffer resuelve), pero **no** para transparencias, que hay que ordenar después.

5. **El buffer de comandos.** Lo que convierte el resultado en un dibujo:

```glsl
#[compute]
#version 450

// Un comando de dibujo indirecto tiene exactamente esta forma. Escribirlo
// desde un compute shader es lo que hace que la GPU "se dibuje a sí misma".
struct ComandoIndirecto {
    uint indices_por_instancia;
    uint n_instancias;          // ← lo rellena el culling
    uint primer_indice;
    int  offset_vertice;
    uint primera_instancia;
};

layout(set = 0, binding = 3, std430) writeonly buffer Comandos {
    ComandoIndirecto comandos[];
};

void main() {
    if (gl_GlobalInvocationID.x != 0u) return;
    comandos[0].indices_por_instancia = indices_de_la_malla;
    comandos[0].n_instancias = n_visibles;     // el contador del paso anterior
    comandos[0].primer_indice = 0u;
    comandos[0].offset_vertice = 0;
    comandos[0].primera_instancia = 0u;
}
```

```cpp
// Y en la CPU: una sola llamada, y sin saber cuántos objetos se van a dibujar.
vkCmdDrawIndexedIndirect(cmd, buffer_comandos, 0, 1, sizeof(ComandoIndirecto));
```

6. **Bindless.** Por qué es requisito del modelo:

```text
SIN BINDLESS: cada material distinto obliga a vincular sus texturas antes de
dibujar. Y vincular es una operación de CPU. Resultado: aunque el culling esté
en GPU, hay que volver a la CPU por cada material → el cuello vuelve.

  for cada material:
      vincular texturas    ← CPU
      dibujar indirecto    ← GPU decide cuántos, pero solo de ESE material

CON BINDLESS: todas las texturas están accesibles a la vez, por índice. El
shader lee el índice de material del objeto y accede directamente.

  layout(set = 1, binding = 0) uniform sampler2D texturas[];   // sin tamaño fijo

  void fragment() {
      uint m = objetos[gl_InstanceIndex].indice_material;
      vec4 albedo = texture(texturas[materiales[m].albedo], UV);
  }

  → UNA sola llamada para toda la escena, con miles de materiales distintos.
```

7. **Mesh shaders y meshlets.** El siguiente escalón:

```text
PIPELINE CLÁSICO
  Vertex shader (1 vértice) → Ensamblado → Rasterización → Fragment shader
  Limitación: procesa TODOS los vértices del objeto aunque solo se vea un trozo.

PIPELINE CON MESH SHADERS
  Task/Amplification shader → decide cuántos meshlets procesar (y descarta)
       ↓
  Mesh shader → genera hasta ~256 vértices y ~256 triángulos por grupo
       ↓
  Rasterización → Fragment shader

MESHLET: grupo de ~64-128 triángulos con:
  - su caja envolvente         → permite culling por meshlet
  - un cono de normales        → permite descartar los que dan la espalda
  - índices locales compactos  → cabe en memoria compartida del grupo

Lo que permite:
  - Culling con granularidad de 64 triángulos, no de objeto entero.
  - Descartar la mitad trasera de una malla sin procesar sus vértices.
  - LOD continuo por meshlet en vez de por malla.
  - Geometría generada en GPU (teselado procedural sin pasar por la CPU).
```

8. **Aplicarlo en Godot.** Lo que sí se puede hacer hoy:

```gdscript
class_name CullingGPU
extends RefCounted

# Godot no expone draw indirecto ni bindless desde GDScript, pero SÍ compute
# shaders y MultiMesh. Con eso se implementa la idea central: el culling ocurre
# en GPU y su resultado alimenta un dibujado por instancias.

var _rd: RenderingDevice
var _shader: RID
var _buffer_objetos: RID
var _buffer_visibles: RID
var _buffer_contador: RID
var _multimesh: MultiMesh

func preparar(objetos: PackedFloat32Array, n: int) -> void:
	_rd = RenderingServer.get_rendering_device()
	var codigo := load("res://gpu_driven/cull.glsl")
	_shader = _rd.shader_create_from_spirv(codigo.get_spirv())

	# La escena se sube UNA VEZ. No vuelve a viajar por el bus cada frame.
	_buffer_objetos = _rd.storage_buffer_create(objetos.size() * 4, objetos.to_byte_array())
	_buffer_visibles = _rd.storage_buffer_create(n * 4)
	_buffer_contador = _rd.storage_buffer_create(4)

func cull(camara: Camera3D) -> int:
	# Reiniciar el contador.
	_rd.buffer_update(_buffer_contador, 0, 4, PackedInt32Array([0]).to_byte_array())

	var lista := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(lista, _pipeline)
	_rd.compute_list_bind_uniform_set(lista, _uniform_set, 0)
	_rd.compute_list_set_push_constant(lista, _planos_frustum(camara), 96)
	# 64 objetos por grupo de trabajo: el tamaño típico de un warp/wavefront.
	_rd.compute_list_dispatch(lista, ceili(_n / 64.0), 1, 1)
	_rd.compute_list_end()
	_rd.submit()
	_rd.sync()

	# LEER el contador de vuelta es lo único que rompe el modelo puro: obliga
	# a sincronizar CPU y GPU. En un motor real, este número no vuelve nunca:
	# alimenta directamente el draw indirecto.
	var bytes := _rd.buffer_get_data(_buffer_contador)
	var n_visibles := bytes.decode_u32(0)
	_multimesh.visible_instance_count = n_visibles
	return n_visibles
```

9. **Medir la diferencia:**

```gdscript
extends SceneTree   # gpu_driven/benchmark.gd

func _init() -> void:
	print("== 100.000 objetos, cámara viendo ~8 % de la escena ==")
	print("  método                     CPU ms   GPU ms   dibujados")
	for metodo in ["nodos_individuales", "multimesh_todo",
				   "cull_cpu_multimesh", "cull_gpu_multimesh"]:
		var r := _medir(metodo, 100000)
		print("  %-26s %6.2f   %6.2f   %9d"
			% [metodo, r["cpu_ms"], r["gpu_ms"], r["dibujados"]])
	quit()
```

Resultados típicos, que ilustran el argumento entero:

```text
== 100.000 objetos, cámara viendo ~8 % de la escena ==
  método                     CPU ms   GPU ms   dibujados
  nodos_individuales         890.00     4.20      100000     ← CPU imposible
  multimesh_todo               0.30    18.60      100000     ← GPU desperdiciada
  cull_cpu_multimesh          12.40     1.80        8100     ← CPU al límite
  cull_gpu_multimesh           0.40     2.10        8100     ← ambas cómodas
```

10. **Cuándo NO hace falta.** La parte honesta:

| Situación | ¿GPU-driven? | Por qué |
|---|---|---|
| Menos de 1.000 objetos | ❌ | El modelo tradicional va sobrado |
| Juego 2D | ❌ | El batching normal basta |
| Mundo abierto con vegetación densa | ✅ | Es su caso de uso canónico |
| Multitudes de miles de personajes | ✅ | Con animación en GPU |
| Escena de interior detallada | ⚠️ | Suele bastar con culling normal |
| Móvil | ⚠️ | Compute sí, mesh shaders casi nunca |
| Proyecto pequeño con equipo pequeño | ❌ | El coste de complejidad no compensa |

## ✍️ Ejercicios

1. Mide el coste real de una draw call en tu máquina dibujando N objetos triviales.
2. Compara 10.000 nodos individuales con un `MultiMesh` de 10.000 instancias.
3. Implementa frustum culling en compute shader y comprueba que descarta lo correcto.
4. Añade culling por distancia y mide cuántos objetos se descartan en una escena real.
5. Implementa la compactación con contador atómico y verifica que no se pierde ninguno.
6. Compara culling en CPU y en GPU con 100.000 objetos, midiendo ambos tiempos.
7. Documenta qué parte del modelo GPU-driven **no** puedes implementar en Godot hoy y por qué.

## 📝 Reto verificable

Implementa un sistema de renderizado con culling en GPU: buffer de escena subido una vez, compute shader con frustum culling, culling por distancia y compactación atómica, resultado alimentando un `MultiMesh`, y un banco de pruebas que compare cuatro métodos con 100.000 objetos.

**Criterio de aceptación**: (a) el culling en GPU descarta **exactamente el mismo conjunto** de objetos que una implementación de referencia en CPU, comprobado como conjunto de índices sobre 100 posiciones de cámara distintas; (b) la compactación no pierde ni duplica ningún índice, verificado comparando el contador con el tamaño del conjunto; (c) con 100.000 objetos y una cámara que ve menos del 10 %, el culling en GPU consume **menos de 1 ms de CPU**; (d) el banco de pruebas mide y compara los cuatro métodos, imprimiendo tiempos de CPU y GPU y objetos dibujados; (e) el sistema funciona con un número de objetos que **no** es múltiplo del tamaño del grupo de trabajo (comprobación de los límites); (f) el proyecto documenta qué partes del modelo (draw indirecto, bindless, mesh shaders) no están disponibles en el motor y qué se hace en su lugar.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El culling en GPU es más lento que en CPU | Se lee el resultado de vuelta cada frame. Es la sincronización, no el culling. |
| Faltan objetos por dibujar | El dispatch no cubre los últimos: `ceil(n / grupo)`, y comprobar `i >= n` en el shader. |
| Se dibujan objetos que deberían descartarse | Planos del frustum mal calculados o en el espacio equivocado. |
| Las transparencias se ven mal ordenadas | La compactación atómica no es determinista. Ordénalas después. |
| El rendimiento no mejora nada | El cuello no eran las draw calls. Perfila antes de rediseñar. |
| Crash con un número de objetos concreto | Buffer dimensionado sin margen, o desbordamiento del contador. |
| Objetos que parpadean al girar | HZB del frame anterior con reproyección incorrecta. |
| Compute y dibujo se pisan | Falta la barrera de memoria entre escribir el buffer y leerlo al dibujar. |

## ❓ Preguntas frecuentes

**❓ ¿Se puede hacer GPU-driven completo en Godot?** Hoy no desde GDScript: falta draw indirecto expuesto y bindless completo. Lo que **sí** puedes hacer —culling en compute que alimenta un `MultiMesh`— captura la idea central y da la mayor parte de la ganancia práctica. Para el modelo completo hace falta un renderizador propio o esperar a que el motor lo exponga.

**❓ ¿Merece la pena para mi juego?** Casi seguro que no, y conviene decirlo: por debajo de unos miles de objetos visibles, el modelo tradicional con batching e instancing va sobrado, y este añade una complejidad considerable. Su caso son mundos abiertos con vegetación densa, multitudes y escenas con centenares de miles de instancias.

**❓ ¿Los mesh shaders sustituyen al pipeline clásico?** Lo complementan y, a medio plazo, lo sustituyen en el hardware que los soporta. Hoy hay que mantener los dos caminos, porque una parte grande del público (y prácticamente todo el móvil) no los tiene. Entenderlos importa para leer documentación moderna y para saber hacia dónde va el hardware.

**❓ ¿Por qué leer el contador de vuelta rompe el modelo?** Porque obliga a **sincronizar** CPU y GPU: la CPU se para hasta que la GPU termina, y ahí se pierde el paralelismo entre ambas. En un motor con draw indirecto ese número nunca vuelve: se escribe en el buffer de comandos y la GPU lo consume directamente. Es la diferencia entre "culling acelerado por GPU" y "GPU-driven de verdad".

**❓ ¿Cómo depuro un culling en GPU?** Comparando siempre contra una implementación de referencia en CPU, como pide el reto: el mismo conjunto de índices para las mismas entradas. Y visualizando: pintar de color los objetos descartados por cada criterio (frustum, distancia, oclusión) hace evidente cuál se está pasando de listo.

## 🔗 Referencias

- Akenine-Möller, Haines & Hoffman — *Real-Time Rendering*, capítulo de pipeline y culling: <https://www.realtimerendering.com/>
- Vulkan Docs — Indirect drawing: <https://docs.vulkan.org/spec/latest/chapters/drawing.html>
- Microsoft — Mesh shaders en DirectX 12: <https://learn.microsoft.com/windows/win32/direct3d12/mesh-shader-pipeline>
- Godot Docs — Compute shaders y `RenderingDevice`: <https://docs.godotengine.org/en/stable/tutorials/shaders/compute_shaders.html>
- Godot Docs — `MultiMesh`: <https://docs.godotengine.org/en/stable/classes/class_multimesh.html>
- NVIDIA — Introduction to Turing Mesh Shaders: <https://developer.nvidia.com/blog/introduction-turing-mesh-shaders/>

## ⬅️ Clase anterior

[Clase 348 - Global illumination y ray tracing moderno](../348-global-illumination-y-ray-tracing-moderno/README.md)

## ➡️ Siguiente clase

[Clase 350 - Shader compilation y stutter](../350-shader-compilation-y-stutter/README.md)
