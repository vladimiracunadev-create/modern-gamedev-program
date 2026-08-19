# Clase 351 — APIs gráficas modernas

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Documentación oficial de Vulkan, DirectX 12, Metal y WebGPU · Khronos Group*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender **qué hace un motor cuando le pides "dibuja esto"**. Las cuatro APIs gráficas modernas —Vulkan, DirectX 12, Metal y WebGPU— comparten un mismo modelo mental, y aprender ese modelo es lo que te permite leer documentación técnica, entender por qué el motor hace lo que hace, y elegir con criterio si algún día escribes un renderizador.

Esta clase **no es un tutorial de ninguna API concreta**, y esa es una decisión deliberada: un curso que enseñe Vulkan línea a línea envejece con la versión y no te sirve si trabajas con Metal. Lo que se enseña son los **conceptos comunes** —command buffers, colas, sincronización, descriptores, pipelines, memoria— con el vocabulario de cada API, para que puedas moverte entre ellas.

Y también qué te da Godot por encima de todo esto, y cuándo bajar a ese nivel merece la pena — que es mucho menos a menudo de lo que la gente cree.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar la diferencia entre API implícita y explícita, y por qué se cambió.
2. Describir el modelo común de las cuatro APIs modernas.
3. Explicar command buffers, colas y envío, y por qué permiten paralelismo.
4. Explicar la sincronización explícita y las barreras de memoria.
5. Explicar descriptores, layouts y gestión de memoria.
6. Comparar las cuatro APIs y saber cuál usar en cada plataforma.
7. Situar lo que ofrece Godot y decidir cuándo bajar a `RenderingDevice`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Implícito vs explícito | Explica el cambio de generación. |
| 2 | Command buffer | La unidad de trabajo grabable. |
| 3 | Colas | Dónde se ejecuta y qué puede solaparse. |
| 4 | Sincronización | La responsabilidad que la API te devolvió. |
| 5 | Barreras de memoria | Lo que garantiza que se vea lo escrito. |
| 6 | Descriptores | Cómo el shader accede a los recursos. |
| 7 | Render pass | Agrupar el trabajo sobre unos destinos. |
| 8 | Memoria | Tipos, heaps y quién reserva. |
| 9 | Comparativa | Qué API en qué plataforma. |
| 10 | Godot encima | Qué te ahorra y cuándo bajar. |

## 📖 Definiciones y características

- **API implícita**: el driver gestiona estado, sincronización y memoria (OpenGL, DX11). Clave: fácil de usar, impredecible y difícil de paralelizar.
- **API explícita**: la aplicación gestiona todo (Vulkan, DX12, Metal, WebGPU). Clave: más código, más control y mucho mejor rendimiento multihilo.
- **Command buffer**: lista de comandos grabada y enviada después. Clave: se puede grabar en paralelo desde varios hilos.
- **Grabación (recording)**: llenar un command buffer. Clave: no ejecuta nada; solo escribe.
- **Envío (submit)**: mandar command buffers a una cola. Clave: es lo que dispara el trabajo en GPU.
- **Cola (queue)**: canal por el que la GPU recibe trabajo. Clave: gráficos, cómputo y transferencia pueden solaparse.
- **Familia de colas**: conjunto de colas con las mismas capacidades. Clave: no todo el hardware tiene colas separadas.
- **Sincronización**: garantizar el orden entre operaciones. Clave: es la fuente principal de errores en estas APIs.
- **Fence**: sincronización GPU→CPU. Clave: para saber cuándo se puede reutilizar un recurso.
- **Semáforo**: sincronización GPU→GPU entre envíos. Clave: encadena trabajo sin volver a la CPU.
- **Barrera de memoria (pipeline barrier)**: garantiza visibilidad y orden entre etapas. Clave: sin ella, un shader puede leer lo que otro aún no escribió.
- **Transición de layout**: cambiar el formato interno de una imagen según su uso. Clave: una textura de destino y una de lectura no se guardan igual.
- **Descriptor**: referencia a un recurso accesible desde un shader. Clave: es el puente entre tus buffers y el código de GPU.
- **Descriptor set**: grupo de descriptores que se vincula de una vez. Clave: se organizan por frecuencia de cambio.
- **Pipeline layout**: describe qué descriptor sets espera un pipeline. Clave: debe coincidir con el shader.
- **Render pass**: agrupación de operaciones sobre unos destinos concretos. Clave: crucial en móvil, donde permite operar en memoria interna.
- **Swapchain**: cadena de imágenes que se presentan en pantalla. Clave: su gestión es el "hola mundo" de estas APIs.
- **Heap de memoria**: región con propiedades (visible por CPU, local de GPU). Clave: elegir mal el heap cuesta ancho de banda.
- **Staging buffer**: buffer intermedio para subir datos a memoria de GPU. Clave: la memoria rápida de GPU no suele ser visible por CPU.

## 🧰 Herramientas y preparación

Godot 4.x y su clase [`RenderingDevice`](https://docs.godotengine.org/en/4.3/classes/class_renderingdevice.html), que expone una abstracción muy parecida a Vulkan y permite tocar estos conceptos sin salir del motor. Trabajaremos en `res://rd/`. Documentación de referencia: [Vulkan](https://docs.vulkan.org/), [DirectX 12](https://learn.microsoft.com/windows/win32/direct3d12/), [Metal](https://developer.apple.com/metal/) y [WebGPU](https://www.w3.org/TR/webgpu/). Ninguna es necesaria para seguir la clase.

## 🧪 Laboratorio guiado

1. **El cambio de modelo.** Por qué se pasó de implícito a explícito:

```text
OpenGL / DX11 (implícito)
  glBindTexture(...);  glUseProgram(...);  glDrawArrays(...);
       ↓
  El DRIVER: valida, gestiona estado, decide sincronización, quizá recompila,
             quizá reordena, y todo desde UN hilo (el contexto es de un hilo).

  Problema: el 30-50 % del tiempo de CPU se iba en el driver, y no se podía
  paralelizar. En una máquina de 16 núcleos, uno trabajaba.

Vulkan / DX12 / Metal / WebGPU (explícito)
  Hilo 1 ──► grabar command buffer A ─┐
  Hilo 2 ──► grabar command buffer B ─┼──► enviar a la cola ──► GPU
  Hilo 3 ──► grabar command buffer C ─┘

  El driver hace muy poco: la aplicación ya le da trabajo casi listo.
  A cambio, la aplicación es responsable de la sincronización y la memoria.
```

2. **El vocabulario, traducido.** La tabla que permite leer cualquier documentación:

| Concepto | Vulkan | DirectX 12 | Metal | WebGPU |
|---|---|---|---|---|
| Dispositivo | `VkDevice` | `ID3D12Device` | `MTLDevice` | `GPUDevice` |
| Cola | `VkQueue` | `ID3D12CommandQueue` | `MTLCommandQueue` | `GPUQueue` |
| Command buffer | `VkCommandBuffer` | `ID3D12GraphicsCommandList` | `MTLCommandBuffer` | `GPUCommandEncoder` |
| Pipeline | `VkPipeline` | `ID3D12PipelineState` | `MTLRenderPipelineState` | `GPURenderPipeline` |
| Buffer | `VkBuffer` | `ID3D12Resource` | `MTLBuffer` | `GPUBuffer` |
| Textura | `VkImage` | `ID3D12Resource` | `MTLTexture` | `GPUTexture` |
| Descriptores | `VkDescriptorSet` | Descriptor heap + tables | Argument buffer | `GPUBindGroup` |
| Sincronización GPU→CPU | `VkFence` | `ID3D12Fence` | `MTLFence` / completion | (implícita) |
| Sincronización GPU→GPU | `VkSemaphore` | `ID3D12Fence` | `MTLEvent` | (implícita) |
| Barrera | `vkCmdPipelineBarrier` | `ResourceBarrier` | (mayormente automática) | (automática) |
| Render pass | `VkRenderPass` | (implícito) | `MTLRenderPassDescriptor` | `GPURenderPassEncoder` |
| Shaders | SPIR-V | DXIL / HLSL | MSL | WGSL |

La conclusión práctica: **son la misma API con cuatro nombres**. Quien sabe Vulkan lee DX12 en una tarde.

3. **Grabar y enviar.** El ciclo básico:

```text
POR FRAME:
  1. Esperar el fence del frame N-2   (que su command buffer ya no se usa)
  2. Adquirir imagen del swapchain
  3. Reiniciar el command buffer
  4. GRABAR:
       begin render pass (destinos, qué limpiar, qué conservar)
         bind pipeline
         bind descriptor sets
         bind vertex/index buffers
         draw / draw indexed / draw indirect
       end render pass
  5. ENVIAR a la cola, con:
       - semáforo de espera:  "hasta que la imagen esté disponible"
       - semáforo de señal:   "cuando termines, avisa"
       - fence:               "avísame a mí (CPU) cuando acabes"
  6. Presentar (esperando el semáforo de señal)
```

```gdscript
# El mismo ciclo en Godot con RenderingDevice: los nombres cambian, la
# estructura es idéntica.
func _dibujar_con_rd() -> void:
	var rd := RenderingServer.get_rendering_device()

	var lista := rd.draw_list_begin(
		_framebuffer,
		RenderingDevice.INITIAL_ACTION_CLEAR,   # qué hacer al empezar
		RenderingDevice.FINAL_ACTION_READ,      # qué hacer al terminar
		RenderingDevice.INITIAL_ACTION_CLEAR,
		RenderingDevice.FINAL_ACTION_DISCARD,   # la profundidad no se conserva
		PackedColorArray([Color.BLACK]))

	rd.draw_list_bind_render_pipeline(lista, _pipeline)
	rd.draw_list_bind_uniform_set(lista, _uniform_set, 0)
	rd.draw_list_bind_vertex_array(lista, _vertex_array)
	rd.draw_list_bind_index_array(lista, _index_array)
	rd.draw_list_draw(lista, true, 1)

	rd.draw_list_end()
	rd.submit()
	rd.sync()
```

Las acciones inicial y final del paso `draw_list_begin` **no son un detalle**: en GPU móviles (de arquitectura *tiled*), declarar que la profundidad se descarta al terminar evita escribirla a memoria principal, y eso puede ser la mitad del ancho de banda del frame.

4. **Las colas.** Dónde está el paralelismo real:

```text
La GPU no es un solo procesador: tiene motores que pueden trabajar a la vez.

  Cola de GRÁFICOS     ──► rasterización, draw calls
  Cola de CÓMPUTO      ──► compute shaders
  Cola de TRANSFERENCIA──► copias CPU↔GPU y GPU↔GPU

Sin usarlas, todo va en serie:
  [gráficos frame N] → [subir texturas] → [gráficos frame N+1] → ...

Usándolas (async compute):
  Gráficos:      [sombras N][opacos N][post N     ][sombras N+1]...
  Cómputo:              [culling N+1][GI N        ][culling N+2]
  Transferencia:   [subir texturas de la zona nueva            ]
                   ↑ todo esto ocurre A LA VEZ

  Ganancia típica: 10-25 % del frame time. A cambio, la sincronización se
  complica bastante: un recurso escrito por cómputo y leído por gráficos
  necesita un semáforo Y una barrera.
```

5. **La sincronización.** La responsabilidad que la API te devolvió:

```cpp
// El error más común y más difícil de depurar: leer algo que la GPU aún no
// ha terminado de escribir. No da error, no crashea: da resultados que
// dependen del hardware, del driver y de la suerte.

// ❌ SIN BARRERA
vkCmdDispatch(cmd, ...);                    // compute escribe en un buffer
vkCmdDrawIndexed(cmd, ...);                 // el vertex shader lo lee
// La GPU puede empezar el draw ANTES de que el compute acabe.

// ✅ CON BARRERA
vkCmdDispatch(cmd, ...);
VkMemoryBarrier barrera{};
barrera.srcAccessMask = VK_ACCESS_SHADER_WRITE_BIT;   // lo que se escribió
barrera.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;    // lo que se va a leer
vkCmdPipelineBarrier(cmd,
    VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,             // espera a esta etapa
    VK_PIPELINE_STAGE_VERTEX_SHADER_BIT,              // antes de esta
    0, 1, &barrera, 0, nullptr, 0, nullptr);
vkCmdDrawIndexed(cmd, ...);
```

| Herramienta | Sincroniza | Cuándo se usa |
|---|---|---|
| **Barrera de pipeline** | Etapas dentro de un command buffer | Compute escribe → gráficos lee |
| **Semáforo** | Entre envíos de GPU | Cola de cómputo → cola de gráficos |
| **Fence** | GPU → CPU | Saber que el frame N-2 terminó |
| **Transición de layout** | Uso de una imagen | Destino de render → textura de lectura |
| **Evento / timeline semaphore** | Granularidad fina | Dependencias complejas |

Metal y WebGPU automatizan buena parte de esto: WebGPU **no expone barreras** y las infiere del uso declarado. Es menos control y muchísimos menos errores.

6. **Descriptores.** Cómo el shader llega a tus datos:

```text
El shader dice: "quiero la textura del binding 0 del set 1"
Tú tienes que haber preparado eso antes.

  Descriptor  = un puntero con tipo a un recurso
  Set         = un grupo de descriptores que se vincula de una vez
  Layout      = la descripción de qué contiene cada set

Organización por FRECUENCIA DE CAMBIO (esto es lo importante):

  Set 0 — por FRAME    → matrices de cámara, tiempo, luces globales
                          se vincula 1 vez por frame
  Set 1 — por MATERIAL → texturas y parámetros del material
                          se vincula al cambiar de material
  Set 2 — por OBJETO   → transformada, índices
                          se vincula por objeto (o va en push constants)

  Ordenarlos al revés (lo que más cambia en el set 0) obliga a revincular
  todo constantemente, y es una de las causas más comunes de mal rendimiento
  en un renderizador propio.
```

7. **Memoria.** Quién reserva y dónde:

```text
En una API explícita, TÚ reservas la memoria y decides su tipo.

  DEVICE_LOCAL              → memoria de la GPU. Rápida. No visible por CPU.
  HOST_VISIBLE              → visible por CPU. Más lenta para la GPU.
  HOST_VISIBLE + COHERENT   → sin necesidad de flush manual.
  HOST_CACHED               → lectura rápida desde CPU.

Subir una textura a memoria rápida:
  1. Reservar un STAGING buffer en HOST_VISIBLE
  2. Copiar los datos con la CPU
  3. Reservar la imagen en DEVICE_LOCAL
  4. Grabar un comando de copia staging → imagen (en la cola de transferencia)
  5. Barrera de transición: destino de copia → lectura de shader
  6. Liberar el staging cuando el fence confirme que la copia acabó

  ← Seis pasos para "cargar una textura". Esto es lo que Godot te ahorra.

Y la regla que casi todo el mundo aprende a base de golpes: NO se hace una
reserva de memoria por recurso. El límite de reservas del driver es bajo
(unos miles). Se reservan bloques grandes y se subdividen — que es
exactamente el pool allocator de la clase 340, aplicado a memoria de GPU.
```

8. **La comparativa.** Qué API en qué plataforma:

| | Vulkan | DirectX 12 | Metal | WebGPU |
|---|---|---|---|---|
| Plataformas | Windows, Linux, Android, (macOS vía capa) | Windows, Xbox | macOS, iOS | Navegadores, y nativo vía implementaciones |
| Verbosidad | **Muy alta** | Alta | Media | **Baja** |
| Control | Máximo | Máximo | Alto | Medio |
| Sincronización | Manual | Manual | Semi-automática | **Automática** |
| Shaders | SPIR-V (GLSL/HLSL) | DXIL (HLSL) | MSL | WGSL |
| Curva de aprendizaje | Empinada | Empinada | Moderada | Suave |
| Ray tracing | ✅ | ✅ | ✅ | En desarrollo |
| Mesh shaders | ✅ | ✅ | ✅ | No |
| Portabilidad | Alta | Baja | Ninguna | **Máxima** |

```text
¿Qué usar si escribes un renderizador?
  Solo Windows y Xbox               → DirectX 12
  Solo Apple                        → Metal
  Multiplataforma nativa            → Vulkan (+ capa de traducción en Apple)
  Web, o portabilidad máxima        → WebGPU
  Quieres publicar un juego         → USA UN MOTOR. En serio.
```

9. **Qué te da Godot encima.** Y cuándo bajar:

```gdscript
# UNA línea de GDScript...
$MiObjeto.material_override = mi_material

# ...equivale aproximadamente a:
#   - crear o reutilizar el pipeline con ese shader y ese estado
#   - crear el descriptor set con las texturas y uniforms del material
#   - transicionar los layouts de esas texturas si hacía falta
#   - grabar los comandos de bind y draw en el command buffer del frame
#   - gestionar la sincronización con lo anterior
#   - liberar todo cuando corresponda, sin liberar nada que la GPU aún use
```

| Situación | ¿Bajar a `RenderingDevice`? | Por qué |
|---|---|---|
| Hacer un juego | ❌ | El motor hace esto mejor que tú |
| Un efecto que el motor no ofrece | ⚠️ | Prueba primero con shaders normales |
| Compute shader para simulación | ✅ | Es el caso de uso natural |
| Culling en GPU (clase 349) | ✅ | Necesitas buffers y compute |
| Un renderizador propio | ✅ | Es exactamente para eso |
| Aprender cómo funciona | ✅ | Y es una razón perfectamente buena |

10. **Tocarlo con las manos.** Un compute shader completo en Godot:

```gdscript
extends SceneTree   # rd/compute_minimo.gd

func _init() -> void:
	# Todos los conceptos de la clase, en 25 líneas y sin salir del motor.
	var rd := RenderingServer.create_local_rendering_device()

	# 1. SHADER: fuente → SPIR-V → objeto de shader.
	var codigo: RDShaderFile = load("res://rd/duplicar.glsl")
	var shader := rd.shader_create_from_spirv(codigo.get_spirv())

	# 2. BUFFER: memoria de GPU con datos iniciales.
	var entrada := PackedFloat32Array([1, 2, 3, 4, 5, 6, 7, 8])
	var buffer := rd.storage_buffer_create(entrada.size() * 4, entrada.to_byte_array())

	# 3. DESCRIPTORES: el puente entre el buffer y el shader.
	var uniforme := RDUniform.new()
	uniforme.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniforme.binding = 0
	uniforme.add_id(buffer)
	var uniform_set := rd.uniform_set_create([uniforme], shader, 0)

	# 4. PIPELINE: shader + estado, listo para ejecutar.
	var pipeline := rd.compute_pipeline_create(shader)

	# 5. GRABAR la lista de comandos.
	var lista := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(lista, pipeline)
	rd.compute_list_bind_uniform_set(lista, uniform_set, 0)
	rd.compute_list_dispatch(lista, 1, 1, 1)
	rd.compute_list_end()

	# 6. ENVIAR y SINCRONIZAR (el fence, en versión simplificada).
	rd.submit()
	rd.sync()

	var salida := rd.buffer_get_data(buffer).to_float32_array()
	print("entrada: ", entrada)
	print("salida:  ", salida)          # cada valor duplicado
	assert(salida[3] == entrada[3] * 2.0, "el compute shader no hizo su trabajo")
	print("== 1 comprobación, 0 fallos ==")
	quit()
```

```glsl
// res://rd/duplicar.glsl
#[compute]
#version 450

layout(local_size_x = 8) in;

layout(set = 0, binding = 0, std430) restrict buffer Datos {
    float valores[];
} datos;

void main() {
    uint i = gl_GlobalInvocationID.x;
    if (i >= datos.valores.length()) return;
    datos.valores[i] *= 2.0;
}
```

## ✍️ Ejercicios

1. Ejecuta el compute mínimo y modifícalo para que calcule algo distinto.
2. Traduce el vocabulario de un tutorial de Vulkan a los términos de DX12 usando la tabla.
3. Implementa un compute shader que sume dos buffers y comprueba el resultado.
4. Añade una segunda pasada de compute y razona qué barrera haría falta entre ambas.
5. Compara el número de líneas de un "triángulo en pantalla" en Vulkan, WebGPU y Godot.
6. Diseña la organización de descriptor sets por frecuencia de cambio para un renderizador.
7. Documenta un efecto de tu proyecto que **no** puedas hacer sin bajar a `RenderingDevice`.

## 📝 Reto verificable

Implementa un pequeño sistema de cómputo en GPU con `RenderingDevice` que ejercite los conceptos de la clase: creación de shader desde SPIR-V, buffers de almacenamiento, descriptor sets, pipeline, grabación de lista de comandos, envío y lectura de resultados; con **al menos dos pasadas de compute encadenadas** y comprobación de corrección contra una implementación de referencia en CPU.

**Criterio de aceptación**: (a) el compute shader produce **exactamente** el mismo resultado que la implementación de referencia en CPU para al menos 10.000 elementos; (b) las dos pasadas encadenadas producen el resultado correcto, demostrando que la segunda ve lo que escribió la primera; (c) el sistema funciona con un número de elementos que **no** es múltiplo del tamaño del grupo de trabajo; (d) todos los recursos se liberan explícitamente y no hay fugas tras 100 ejecuciones, comprobable con los monitores de memoria; (e) el proyecto incluye una tabla de equivalencias de vocabulario entre las cuatro APIs; (f) el README documenta qué conceptos de la clase aparecen en el código y en qué línea; (g) la prueba corre en CI en máquinas con GPU y **se salta con un mensaje claro** cuando no hay dispositivo de cómputo disponible.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Resultados que cambian entre ejecuciones | Falta una barrera entre escritura y lectura. |
| Funciona en una GPU y en otra no | Sincronización insuficiente que una GPU perdona. Añade las barreras correctas. |
| Crash al liberar un recurso | La GPU aún lo estaba usando. Espera al fence antes de liberar. |
| "Validation layer" lleno de errores | Es lo esperado al aprender: **léelos**, son la mejor documentación que hay. |
| Faltan los últimos elementos del resultado | El dispatch no cubre el total. `ceil(n / grupo)` y comprobar el índice. |
| Rendimiento peor que con la API antigua | Reservas por recurso, o descriptor sets mal organizados. |
| El buffer llega vacío a la CPU | Falta `sync()`, o se lee antes de que la GPU termine. |
| Se reserva memoria por cada textura | Límite de reservas del driver. Pool de bloques grandes. |

## ❓ Preguntas frecuentes

**❓ ¿Debo aprender Vulkan?** Para hacer juegos, no: usa un motor. Merece la pena si vas a trabajar en tecnología de motores, si necesitas un efecto que ningún motor ofrece, o si quieres entender de verdad lo que ocurre por debajo — que es una razón perfectamente válida y es lo que esta clase intenta darte sin el coste de aprender la API entera.

**❓ ¿Cuál es la más fácil?** WebGPU, con diferencia: sincronización automática, mucha menos verbosidad y una API diseñada con veinte años de aprendizaje. Metal es la segunda. Vulkan y DX12 son las más verbosas y las que más control dan. Si quieres aprender los conceptos, empezar por WebGPU es una buena estrategia.

**❓ ¿Por qué Godot usa Vulkan y no las demás?** Por portabilidad: Vulkan cubre Windows, Linux y Android de forma nativa, y macOS/iOS a través de una capa de traducción. Mantener cuatro backends completos es un coste enorme para cualquier proyecto, y por eso los motores eligen uno principal y traducen el resto.

**❓ ¿Cuánto se gana de verdad con una API explícita?** En CPU, mucho: el tiempo de driver baja drásticamente y la grabación se paraleliza. En un juego limitado por CPU, la diferencia es notable. En uno limitado por GPU, casi nada — el trabajo de la GPU es el mismo. Esa distinción es la que decide si tu proyecto se beneficiaría, y se responde perfilando.

**❓ ¿Puedo escribir un renderizador propio en Godot?** Con `RenderingDevice`, en buena medida sí: tienes acceso a buffers, pipelines, compute y listas de comandos. Lo que no tienes es acceso a todo (mesh shaders, bindless completo, ray tracing por hardware) ni sustituir el renderizador del motor por completo. Para un efecto o un sistema concreto, es más que suficiente.

## 🔗 Referencias

- Khronos — Especificación y guía de Vulkan: <https://docs.vulkan.org/> · uso: se instala o se consulta en la preparación
- Microsoft — Documentación de DirectX 12: <https://learn.microsoft.com/windows/win32/direct3d12/directx-12-programming-guide> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Apple — Metal: <https://developer.apple.com/metal/> · uso: se instala o se consulta en la preparación
- W3C — Especificación de WebGPU: <https://www.w3.org/TR/webgpu/> · uso: se instala o se consulta en la preparación
- Godot Docs — `RenderingDevice`: <https://docs.godotengine.org/en/4.3/classes/class_renderingdevice.html> · uso: se instala o se consulta en la preparación
- Godot Docs — Compute shaders: <https://docs.godotengine.org/en/4.3/tutorials/shaders/compute_shaders.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Akenine-Möller et al. — *Real-Time Rendering*, capítulo del pipeline gráfico: <https://www.realtimerendering.com/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 350 - Shader compilation y stutter](../350-shader-compilation-y-stutter/README.md)

## ➡️ Siguiente clase

[Clase 352 - Capstone Parte 21: ingeniería avanzada verificable](../352-capstone-parte-21-ingenieria-avanzada-verificable/README.md)
