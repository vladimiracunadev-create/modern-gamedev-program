# ⚙️ Lab: Ingeniería avanzada

> [⬅️ Volver a los laboratorios](../README.md) · [📚 Parte 21](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/README.md) · [🎓 Clase 352 (capstone)](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/352-capstone-parte-21-ingenieria-avanzada-verificable/README.md)

Banco de pruebas de las cuatro técnicas que sostienen un motor moderno: **disposición de datos**, **gestión de memoria**, **particionamiento espacial** y **paralelismo**. Cada una está implementada dos veces —la forma natural y la forma rápida— y el proyecto **mide las dos y comprueba que dan el mismo resultado**.

Ese es el punto entero del laboratorio. Una optimización que cambia el resultado no es una optimización, es un bug rápido; y una optimización sin medición no es ingeniería, es superstición. Aquí no hay ninguna cifra escrita a mano: todas las que verás las produce tu máquina.

## 🎯 La demostración

```bash
godot --headless --path labs/advanced-engineering/solucion --script res://pruebas/ingenieria_test.gd
```

```text
  DOD 100000 partículas: SoA 16.14 ms · AoS 61.74 ms · ×3.8
  Memoria 10k objetos: pool 22.49 ms · nuevos 32.56 ms · ×1.4
  Espacial 5000 objetos, 200 consultas: fuerza bruta 85.05 ms · rejilla 1.73 ms · ×49.2
  Jobs 200000 elementos (8 núcleos): secuencial 210.15 ms · paralelo 131.04 ms · ×1.60
== 33 comprobaciones, 0 fallos ==
```

**Tus números serán distintos, y eso es correcto.** Dependen de tu CPU, de tu caché y de cuántos núcleos tengas. Lo que no cambia es el orden de magnitud de cada mejora, y es informativo por sí mismo:

- La rejilla gana **por complejidad** (de O(n) por consulta a O(vecinos)): la mejora es enorme y crece con el número de objetos.
- SoA gana **por memoria** (líneas de caché aprovechadas en vez de desperdiciadas): entre ×3 y ×5, sin cambiar ni una operación aritmética.
- El pool gana **poco de media** y muchísimo en el peor caso: lo que elimina no es el coste, es la **varianza** que produce los tirones.
- El paralelismo gana **solo si hay trabajo suficiente por elemento**. Con la carga de este banco y 8 núcleos sale ×1.6, muy lejos del ×8 teórico. Si sustituyes el cálculo por una simple multiplicación, el paralelo **pierde**: la sobrecarga de repartir se come la ganancia. Compruébalo, es la lección de la [clase 341](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/341-job-systems-y-task-graphs/README.md).

## 📦 Qué hay dentro

| Pieza | Archivo | Clase |
|---|---|---|
| AoS frente a SoA, con datos fríos separados | `dod/particulas.gd` | [339](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/339-data-oriented-design/README.md) |
| Swap-remove para compactar sin huecos | `dod/particulas.gd` | [339](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/339-data-oriented-design/README.md) |
| Pool de objetos con conteo de desbordes | `memoria/pool.gd` | [340](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/340-allocators-y-gestion-avanzada-de-memoria/README.md) |
| Arena / stack allocator con marcas | `memoria/arena.gd` | [340](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/340-allocators-y-gestion-avanzada-de-memoria/README.md) |
| Reparto en grupos sobre `WorkerThreadPool` | `jobs/paralelo.gd` | [341](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/341-job-systems-y-task-graphs/README.md) |
| Grafo de tareas con detección de ciclos | `jobs/grafo_tareas.gd` | [341](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/341-job-systems-y-task-graphs/README.md) |
| Rejilla uniforme + fuerza bruta de referencia | `espacial/rejilla.gd` | [342](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/342-particionamiento-espacial/README.md) |
| Hash espacial para mundos sin límites | `espacial/hash_espacial.gd` | [342](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/342-particionamiento-espacial/README.md) |
| Medición con calentamiento y mediana | `pruebas/ayuda.gd` | [243](../../classes/parte-14-optimizacion-profiling-y-rendimiento/243-optimizacion-de-cpu-logica-scripts-y-llamadas/README.md) |

## ✅ Qué verifica la CI

**33 comprobaciones, y ninguna es un `assert` sobre milisegundos** salvo la comparación relativa final, que se adapta al número de núcleos de la máquina. Un test que falla según el hardware acaba desactivado, y un test desactivado no protege nada.

- **Corrección antes que velocidad**: SoA y AoS producen las mismas posiciones y vidas tras 30 pasos; la rejilla devuelve **exactamente** los mismos ids que la fuerza bruta, ordenados, incluso con coordenadas negativas.
- **Compactación**: swap-remove elimina las muertas, mantiene el resto, no deja huecos y conserva la suma total de vidas de las supervivientes.
- **Memoria**: el pool reutiliza instancias (el número de creados no crece), cuenta los desbordes cuando se queda corto, limpia al devolver y rechaza objetos ajenos; la arena asigna, marca, libera hasta la marca y registra desbordes en vez de crecer en silencio.
- **Espacial**: la rejilla detecta cuándo un objeto **no** cambia de celda al moverse (el caso mayoritario), y el hash espacial coincide con la rejilla.
- **Grafo de tareas**: respeta el orden de dependencias, agrupa en niveles lo que puede correr a la vez y **detecta ciclos** en vez de colgarse.
- **Paralelismo determinista**: el resultado paralelo es idéntico al secuencial (comparado por hash de la salida completa) y **50 ejecuciones seguidas dan exactamente lo mismo**. Una carrera aparece una vez de cada mil, así que una sola pasada no probaría nada.

## 🧪 El proyecto de partida

`inicio/` es el mismo proyecto con **seis TODO** numerados. Compila y arranca desde el primer momento; lo que no hace es funcionar:

```bash
godot --headless --path labs/advanced-engineering/inicio --quit-after 60
```

```text
  correcto: SoA==AoS=true · rejilla==fuerza_bruta=false (29 objetos en el radio)
```

| TODO | Dónde | Qué se aprende |
|---|---|---|
| 1 | `dod/particulas.gd` · `compactar` | Swap-remove sin dejar huecos, y por qué no se avanza el índice tras intercambiar |
| 2 | `memoria/pool.gd` · `obtener` / `devolver` | Reutilizar de verdad, e indexar por identidad y no por contenido |
| 3 | `espacial/rejilla.gd` · `consultar_radio` | La celda es una aproximación: falta la comprobación exacta de distancia |
| 4 | `espacial/rejilla.gd` · `_celda` | `int()` trunca hacia cero: el fallo solo aparece en coordenadas negativas |
| 5 | `jobs/paralelo.gd` · `trabajo_paralelo` | Repartir en grupos y **esperar**: sin la espera el fallo es intermitente |
| 6 | `jobs/paralelo.gd` · `_contar_trozo` | Acumulador local: escribir en el array compartido produce falso compartido |

El TODO 4 merece atención especial. Es el único cuyo síntoma **no aparece** en una prueba rápida: con coordenadas positivas todo funciona, y el bug se manifiesta meses después en la mitad negativa del mapa. Ese es el perfil típico de los fallos de esta parte del programa.

## 🔍 Qué NO cubre

- **No hay GPU.** Todo el laboratorio es CPU. Las clases [345](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/345-rendering-temporal/README.md)–[351](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/351-apis-graficas-modernas/README.md) explican rendering temporal, upscaling, HDR, GI, GPU-driven y stutter de shaders, pero medirlos exige una ventana y hardware concreto: no se puede verificar en una CI sin pantalla.
- **No hay streaming ni particionado de mundo** ([343](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/343-resource-management-y-streaming-asincrono/README.md) y [344](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/344-grandes-mundos-y-world-partition/README.md)): requieren assets reales y disco, no estructuras en memoria.
- **GDScript no es C++.** Los factores que medirás son reales y las técnicas son las mismas, pero un motor nativo obtiene mucho más de SoA y de los allocators, porque controla la memoria de verdad. Aquí se aprende el **patrón** y el **método de medición**; el techo lo pone el lenguaje.
- **No hay BVH ni quadtree implementados**, solo rejilla y hash espacial. La [clase 342](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/342-particionamiento-espacial/README.md) explica cuándo cada uno gana; ampliarlo es un buen ejercicio, y la fuerza bruta ya está ahí como criterio de corrección.
