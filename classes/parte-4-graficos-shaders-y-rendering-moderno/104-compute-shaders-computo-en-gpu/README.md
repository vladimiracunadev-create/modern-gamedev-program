# Clase 104 — Compute shaders: cómputo en GPU

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Documentación de Compute Shaders de Godot 4 + Especificación GLSL de Khronos (compute)*
> ⏱️ Duración estimada: **55 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender qué es un **compute shader** y usarlo para procesar datos masivos en paralelo fuera del pipeline de dibujo. Al terminar habrás escrito un shader de cómputo en **GLSL** con `#[compute]`, lo habrás ejecutado en Godot 4 mediante un **RenderingDevice local**, subido un array de números a un *storage buffer*, lanzado el trabajo con un *dispatch* y leído el resultado de vuelta en GDScript. Verás que esto es GLSL de compute puro, **no** el lenguaje de shaders de Godot (`shader_type`).

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar cuándo un compute shader supera a la CPU: cómputo masivo y paralelo (partículas, simulación, imagen).
- Distinguir el flujo `RenderingDevice` (GLSL compute) del lenguaje de shaders visual de Godot.
- Configurar un pipeline de cómputo: shader, buffer, *uniform set*, pipeline y *compute list*.
- Elegir un `local_size` y calcular cuántos *workgroups* despachar para N elementos.
- Leer resultados de la GPU con `buffer_get_data` y validarlos contra la CPU.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es un compute shader | Es cómputo general en GPU, sin fragmentos ni píxeles |
| 2 | Paralelismo SIMD y workgroups | Explica por qué miles de datos se procesan a la vez |
| 3 | `local_size` e invocaciones | Define el tamaño del grupo de trabajo en el shader |
| 4 | Storage buffers (SSBO) | Es cómo entran y salen los datos de la GPU |
| 5 | RenderingDevice local | La API de Godot 4 para lanzar cómputo sin dibujar |
| 6 | Uniform set y pipeline | Conectan el buffer con el shader compilado |
| 7 | Dispatch y sincronización | Ordena el trabajo y espera a que termine |
| 8 | Leer resultados a CPU | Sin esto no ves el fruto del cálculo |

## 📖 Definiciones y características

- **Compute shader**: programa de GPU que no dibuja; opera sobre buffers de datos arbitrarios. Clave: se usa para cómputo masivo paralelo.
- **Workgroup**: bloque de invocaciones que se ejecutan juntas. Clave: su tamaño lo fija `layout(local_size_x=...) in;`.
- **Invocación**: una ejecución del shader para un índice concreto. Clave: se identifica con `gl_GlobalInvocationID`.
- **SSBO (storage buffer)**: bloque de memoria GPU de lectura/escritura. Clave: es el canal de datos entre GDScript y el shader.
- **RenderingDevice**: interfaz de bajo nivel de Godot 4 sobre Vulkan. Clave: `create_local_rendering_device()` crea uno independiente del render de pantalla.
- **Pipeline de cómputo**: shader compilado listo para ejecutarse. Clave: se crea con `compute_pipeline_create`.
- **Dispatch**: orden de ejecutar N workgroups en X, Y, Z. Clave: `compute_list_dispatch(list, gx, gy, gz)`.
- **`submit`/`sync`**: envían el trabajo y esperan el resultado. Clave: sin `sync` el buffer de salida puede no estar listo.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x con el renderer **Forward+** o **Mobile** (ambos exponen `RenderingDevice`; el backend Compatibility/OpenGL **no** soporta compute). Trabajaremos con dos archivos: un `.glsl` para el shader de cómputo y un `.gd` de setup. El shader GLSL de compute se guarda como recurso de texto y se carga con `load()` como `RDShaderFile`. Ten a mano la [guía oficial de compute shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/compute_shaders.html) y la referencia de la clase [RenderingDevice](https://docs.godotengine.org/en/stable/classes/class_renderingdevice.html). No necesitas escena visual: bastará con un `Node` y su `_ready()`.

## 🧪 Laboratorio guiado

Vamos a **multiplicar por un factor cada número de un array** en la GPU y leer el resultado. Es el "hola mundo" del cómputo: fácil de verificar contra la CPU.

**Paso 1 — El shader de cómputo.** Crea un archivo `multiplicar.glsl` con este contenido. La primera línea `#[compute]` le dice a Godot que es un shader de cómputo:

```glsl
#[compute]
#version 450

// 64 invocaciones por workgroup en el eje X.
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

// Buffer de datos en el binding 0 del set 0: lectura y escritura.
layout(set = 0, binding = 0, std430) restrict buffer DatosBuffer {
    float datos[];
}
datos_buffer;

// Factor constante que aplicamos a cada elemento.
layout(push_constant, std430) uniform Parametros {
    float factor;
    uint  n; // cantidad real de elementos
}
params;

void main() {
    // Índice global único de esta invocación.
    uint i = gl_GlobalInvocationID.x;
    if (i >= params.n) {
        return; // no salirse del array si N no es múltiplo de 64
    }
    datos_buffer.datos[i] = datos_buffer.datos[i] * params.factor;
}
```

**Paso 2 — Crear el RenderingDevice y compilar el shader.** En un `Node`, en `_ready()`:

```gdscript
extends Node

func _ready() -> void:
    # 1) Dispositivo de render local, independiente de la pantalla.
    var rd := RenderingServer.create_local_rendering_device()

    # 2) Cargar y compilar el shader GLSL de compute.
    var shader_file: RDShaderFile = load("res://multiplicar.glsl")
    var spirv: RDShaderSPIRV = shader_file.get_spirv()
    var shader: RID = rd.shader_create_from_spirv(spirv)
```

**Paso 3 — Subir el array a un storage buffer.** Convertimos los floats a bytes y creamos el SSBO:

```gdscript
    var entrada := PackedFloat32Array([1, 2, 3, 4, 5, 6, 7, 8])
    var n := entrada.size()
    var bytes := entrada.to_byte_array()

    # Buffer de almacenamiento con los datos iniciales.
    var buffer: RID = rd.storage_buffer_create(bytes.size(), bytes)

    # Describir el buffer como uniform en binding 0.
    var uniform := RDUniform.new()
    uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
    uniform.binding = 0
    uniform.add_id(buffer)
    var uniform_set: RID = rd.uniform_set_create([uniform], shader, 0)
```

**Paso 4 — Pipeline, push constant y dispatch.** Empaquetamos el factor y N como *push constant* y lanzamos los workgroups necesarios:

```gdscript
    var pipeline: RID = rd.compute_pipeline_create(shader)

    # Push constant: factor (float) + n (uint). Rellenamos a 16 bytes.
    var push := PackedByteArray()
    push.resize(16)
    push.encode_float(0, 3.0)   # factor = 3.0
    push.encode_u32(4, n)       # cantidad de elementos
    # bytes 8..15 quedan como padding

    # Cuántos workgroups: ceil(n / 64).
    var grupos := int(ceil(float(n) / 64.0))

    var lista := rd.compute_list_begin()
    rd.compute_list_bind_compute_pipeline(lista, pipeline)
    rd.compute_list_bind_uniform_set(lista, uniform_set, 0)
    rd.compute_list_set_push_constant(lista, push, push.size())
    rd.compute_list_dispatch(lista, grupos, 1, 1)
    rd.compute_list_end()

    # Enviar el trabajo a la GPU y esperar a que termine.
    rd.submit()
    rd.sync()
```

**Paso 5 — Leer el resultado.** Recuperamos los bytes del buffer y los convertimos de vuelta a floats:

```gdscript
    var salida_bytes := rd.buffer_get_data(buffer)
    var salida := salida_bytes.to_float32_array()
    print("Entrada: ", entrada)
    print("Salida : ", salida) # cada valor multiplicado por 3
```

**Resultado observable:** la consola imprime `[1, 2, 3, 4, 5, 6, 7, 8]` y luego `[3, 6, 9, 12, 15, 18, 21, 24]`. Acabas de ejecutar código de propósito general en la GPU y recuperar sus datos.

## ✍️ Ejercicios

1. Cambia el `factor` a `0.5` y confirma que la salida es la mitad de la entrada.
2. Modifica el array para que tenga **200 elementos** y verifica que el `ceil(n/64)` despacha 4 workgroups sin desbordar.
3. Agrega un segundo buffer de solo lectura (binding 1) y haz que el shader sume ambos arrays elemento a elemento.
4. Sustituye la multiplicación por `datos[i] = sqrt(datos[i]);` y compara con `sqrt()` en GDScript.
5. Mide con `Time.get_ticks_usec()` el tiempo del `dispatch` frente a un bucle equivalente en CPU sobre 1.000.000 de elementos.
6. Cambia `local_size_x` a `256` y ajusta el cálculo de workgroups; comprueba que el resultado sigue siendo correcto.

## 📝 Reto verificable

Escribe un compute shader que reciba un array de N floats y devuelva, en un **segundo buffer de salida**, el valor escalado y desplazado `y = a*x + b`, con `a` y `b` pasados por *push constant*. Verifica en GDScript que los resultados coinciden con el cálculo hecho en CPU para al menos 3 valores.

**Criterio de aceptación**: el programa imprime lado a lado la salida de GPU y la de CPU para los mismos datos, y ambas coinciden con tolerancia `0.0001`; el shader usa `gl_GlobalInvocationID` y protege el acceso con `if (i >= n) return;`.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| `buffer_get_data` devuelve datos sin cambiar | Falta `rd.submit()` seguido de `rd.sync()`; el trabajo no se ejecutó |
| Godot no compila el `.glsl` | Olvidaste `#[compute]` o `#version 450` en las primeras líneas |
| Escritura fuera de rango / crash | No proteges con `if (i >= n) return;` cuando N no es múltiplo de `local_size` |
| `RenderingDevice` es `null` | Estás en el backend Compatibility/OpenGL; usa Forward+ o Mobile |
| Resultados basura o desplazados | Desalineación `std430` o *push constant* sin padding a múltiplos de 16 bytes |
| Solo se procesa parte del array | Despachaste pocos workgroups; usa `ceil(n / local_size_x)` |

## ❓ Preguntas frecuentes

**¿Un compute shader se escribe en el lenguaje de shaders de Godot?**
No. Es **GLSL** de compute (con `#[compute]` y `#version 450`) ejecutado vía `RenderingDevice`, distinto de `shader_type spatial/canvas_item`.

**¿Qué diferencia hay entre `local_size` y el dispatch?**
`local_size` es cuántas invocaciones tiene cada workgroup (fijado en el shader); el dispatch decide **cuántos workgroups** lanzas. El total de hilos es su producto.

**¿Puedo usar el mismo RenderingDevice del render principal?**
Para trabajo aislado conviene `create_local_rendering_device()`. Es independiente y evita interferir con el dispositivo que dibuja la pantalla.

**¿Cuándo NO vale la pena un compute shader?**
Con pocos datos, el coste de subir y bajar buffers supera al cálculo. Brilla cuando hay decenas de miles de elementos independientes.

## 🔗 Referencias

- [Compute shaders — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/shaders/compute_shaders.html)
- [Using compute shaders (ejemplo paso a paso) — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_compute_shader.html)
- [Clase RenderingDevice — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_renderingdevice.html)
- [Compute Shader — Khronos OpenGL Wiki](https://www.khronos.org/opengl/wiki/Compute_Shader)

## ➡️ Siguiente clase

[Clase 105 - Optimización de shaders y coste en GPU](../105-optimizacion-de-shaders-y-coste-en-gpu/README.md)
