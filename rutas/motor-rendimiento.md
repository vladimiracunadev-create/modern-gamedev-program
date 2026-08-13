# ⚙️ Programador de motor / rendimiento

> El rol que **mide antes de opinar**. Aquí no se optimiza lo que parece lento:
> se optimiza lo que el profiler señala, y se comprueba que el resultado no cambió.
>
> **Nivel de entrada:** avanzado · **Foco:** datos, memoria, paralelismo y rendering · **Hito faro:** cuatro optimizaciones medidas y verificadas contra su referencia

## 🧭 Qué es y por qué importa

El programador de motor/rendimiento trabaja por debajo del gameplay: cómo están dispuestos los datos en memoria, cómo se reparte el trabajo entre núcleos, qué estructuras hacen viables diez mil entidades, cómo se dibuja un fotograma y por qué a veces se queda medio segundo congelado.

Importa porque el rendimiento decide qué juego es posible. Un sistema que solo aguanta doscientas entidades limita el diseño; el mismo sistema con los datos bien dispuestos aguanta veinte mil y abre géneros enteros. Y porque el rendimiento percibido no es la media: es el **peor fotograma**, y eso rara vez se arregla por casualidad.

Es el rol más exigente técnicamente del programa y el que más se apoya en método. La habilidad central no es conocer trucos: es **medir bien** y comprobar que la versión rápida da exactamente el mismo resultado que la lenta.

## 🗓️ Un día en el puesto

- **Perfilar.** Antes de tocar nada, saber dónde se va el tiempo. La intuición sobre rendimiento es famosamente mala, incluida la tuya.
- **Formular una hipótesis y medirla.** «Creo que esto falla por caché»: pruébalo con un experimento, no con un argumento.
- **Escribir la versión rápida y compararla con la lenta.** Si el resultado cambia, no es una optimización: es un bug rápido.
- **Perseguir la varianza.** El fotograma de 40 ms que aparece una vez cada trescientos es más importante que la media.
- **Reducir asignaciones** en el bucle caliente: pools, arenas, reutilización.
- **Investigar el stutter.** Compilación de shaders, carga de recursos, recolección de basura ([clase 350](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/350-shader-compilation-y-stutter/README.md)).
- **Defender presupuestos** ante gameplay y arte, con números en vez de opiniones.

## 🧠 Qué necesitas saber

### Conocimiento técnico

- **Cómo funciona la memoria de verdad:** líneas de caché, localidad, prefetch. La diferencia entre AoS y SoA no es estilo, son factores de 3× a 5× ([clase 339](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/339-data-oriented-design/README.md)).
- **Asignadores:** pools y arenas, y por qué lo que eliminan no es el coste medio sino la **varianza** ([clase 340](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/340-allocators-y-gestion-avanzada-de-memoria/README.md)).
- **Paralelismo con criterio:** job systems, grafos de tareas, acumuladores locales, falso compartido — y cuándo el paralelismo **pierde** ([clase 341](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/341-job-systems-y-task-graphs/README.md)).
- **Particionamiento espacial:** rejillas, hash espacial, quadtrees, BVH. Ganar por complejidad es ganar de verdad ([clase 342](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/342-particionamiento-espacial/README.md)).
- **Streaming y mundos grandes**, donde el problema deja de ser la CPU y pasa a ser el disco ([clases 343](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/343-resource-management-y-streaming-asincrono/README.md) y [344](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/344-grandes-mundos-y-world-partition/README.md)).
- **Rendering moderno:** temporal, upscaling, HDR, iluminación global, GPU-driven ([clases 345–349](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/345-rendering-temporal/README.md)).
- **APIs gráficas modernas** y qué cambia realmente con Vulkan/DX12/Metal ([clase 351](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/351-apis-graficas-modernas/README.md)).

### Herramientas del oficio

- El **profiler de CPU y el de GPU**, que responden preguntas distintas y se usan en momentos distintos.
- **Medición con calentamiento y mediana**, no media: un pico del sistema operativo no debe decidir el resultado.
- Una **implementación de referencia obviamente correcta** contra la que comparar. Es la herramienta más importante y la que más se olvida.
- **RenderDoc** o el capturador del motor; **Tracy** o similar para trazas de fotograma.

### Habilidades no técnicas

- **Escepticismo, empezando por ti.** «Esto debería ser más rápido» no es un dato.
- **Rigor experimental:** un cambio cada vez, mismo escenario, varias repeticiones.
- **Comunicar con números.** Este rol convence con tablas, no con adjetivos.
- **Saber cuándo parar.** Optimizar lo que ya no está en el camino crítico es tiempo perdido y riesgo añadido.

## 📚 Tu ruta en el programa

1. ✅ **Requisito:** [Parte 3](../classes/parte-3-fisica-y-matematicas-de-juegos-aplicadas/README.md) (física y matemáticas) y [Parte 14](../classes/parte-14-optimizacion-profiling-y-rendimiento/README.md) (optimización).
2. 📚 [**Parte 14 — Optimización y profiling**](../classes/parte-14-optimizacion-profiling-y-rendimiento/README.md) (240–254). Reléela: no es contenido, es el método.
3. 📚 [**Parte 21 — Arquitectura avanzada**](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/README.md) (339–352). **El núcleo**, con el 🧪 [lab de ingeniería avanzada](../labs/advanced-engineering/README.md).
4. 🎯 **Hito**: cuatro optimizaciones medidas en tu máquina, cada una comprobada contra una implementación de referencia obviamente correcta ([clase 352](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/352-capstone-parte-21-ingenieria-avanzada-verificable/README.md)).
5. 📚 [**Parte 4 — Gráficos y shaders**](../classes/parte-4-graficos-shaders-y-rendering-moderno/README.md) (086–107). Necesaria para las clases 345–351, que son de rendering.
6. 📚 [**Parte 15 — Tooling**](../classes/parte-15-herramientas-editores-y-automatizacion/README.md) (255–266). Pruebas de regresión de rendimiento en CI ([clase 321](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/321-performance-regression-testing/README.md)).

> **Lo que este programa no puede darte.** Las clases 345–351 explican rendering moderno, pero **no tienen laboratorio**: medirlas exige hardware gráfico concreto y una pantalla, y una CI sin GPU no puede verificarlas. Prometer un badge verde ahí sería mentir. El laboratorio cubre las cuatro técnicas de CPU, que sí se pueden verificar de verdad.

## 🎓 Qué te contrata

- **Una tabla de mediciones** de tu máquina: antes, después, factor, y con qué método mediste.
- **La prueba de equivalencia.** Enseñar que la versión rápida da el mismo resultado que la lenta es lo que separa a un ingeniero de alguien que toca cosas.
- **Un caso de varianza:** un stutter localizado, su causa y su arreglo. Más valioso que cualquier mejora de media.
- **Un resultado negativo bien contado.** «Paralelicé esto y salió 3,6× más lento; aquí está por qué» demuestra más criterio que diez éxitos.

## 📈 Progresión de carrera y salario

1. **Gameplay programmer con perfil de rendimiento** — la entrada habitual: nadie contrata a un junior de motor.
2. **Performance / engine programmer** — dueño del presupuesto de fotograma de un subsistema.
3. **Senior engine programmer** — tocas el motor: pipeline de render, sistema de jobs, gestión de memoria.
4. **Especialización:** rendering engineer, tools/engine architect o [arquitecto técnico](arquitecto-tecnico.md).

Rangos **orientativos** (brutos anuales):

- **LATAM:** entrada aproximada USD 16.000–30.000; con experiencia USD 35.000–70.000+.
- **España:** entrada aproximada 28.000–38.000 €; senior 50.000–75.000 €+.
- **Remoto / USD:** seniors de motor frecuentemente por encima de USD 110.000–160.000. Es el techo salarial técnico del sector.

Es también la ruta con más **C++** en el empleo real. GDScript sirve para aprender el patrón y el método; los puestos de motor exigen el lenguaje nativo.

## ⚠️ Mitos y errores comunes

- **«Sé dónde está el cuello de botella.»** Casi nunca. Mide primero; la intuición acierta menos de lo que duele admitir.
- **«Esto es más rápido, seguro.»** Sin comparar contra la referencia, puede ser más rápido **y** estar mal.
- **«Paralelizar siempre gana.»** Si el trabajo por elemento es pequeño, repartirlo cuesta más de lo que ahorra. Mídelo.
- **«La media bajó, ya está.»** El jugador nota el peor fotograma, no la media. Persigue percentiles altos.
- **«Optimizo desde el principio.»** Optimizar sin datos es superstición cara. Primero que funcione y esté medido.
- **«GDScript no sirve para esto.»** Sirve para aprender el patrón y el método, que es lo transferible. El techo lo pone el lenguaje, y eso también hay que verlo.

## 🚀 Siguientes pasos

1. Haz la **Parte 14** entera y perfila un juego tuyo. Escribe dónde **creías** que estaba el problema y dónde estaba.
2. Completa el 🧪 [lab de ingeniería avanzada](../labs/advanced-engineering/README.md) y anota **tus** números: serán distintos de los del README, y eso es lo correcto.
3. En ese lab, cambia el cálculo por elemento por una simple multiplicación y observa cómo el paralelismo **pierde**. Esa es la lección.
4. Coge un sistema tuyo con muchas entidades y pásalo a SoA. Mide antes y después, y comprueba la equivalencia.
5. Añade una **prueba de regresión de rendimiento** a tu CI ([clase 321](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/321-performance-regression-testing/README.md)).
6. Si apuntas a puestos de motor, empieza a portar tus experimentos a **C++**.

---

- ⬅️ [Volver al índice de rutas](./README.md)
- 🏠 [Inicio del programa](../README.md)
