# 🎨 Programador gráfico / técnico

> Escribes lo que la GPU ejecuta millones de veces por fotograma. Shaders, iluminación,
> post-procesado y el *look* que hace que un juego se reconozca en una captura.
>
> **Nivel de entrada:** intermedio (exige matemáticas cómodas) · **Foco:** rendering y GPU · **Hito faro:** un set de shaders propio con su desglose técnico

## 🧭 Qué es y por qué importa

El programador gráfico traduce una intención visual en código que corre en la GPU: cómo se ilumina una escena, cómo se ve el agua, qué pasa en el borde de una silueta, cuánto cuesta cada efecto en milisegundos. Es un rol **mitad artista, mitad ingeniero**: hay que entender lo que el director de arte quiere y lo que la tarjeta puede dar.

Importa porque el aspecto de un juego no es una capa de pintura: es una decisión técnica sostenida. Un estilo visual coherente y barato vale más que uno espectacular que baja a 20 fps, y quien decide eso eres tú. También es el rol que salva proyectos cuando el arte, tal y como está hecho, no cabe en el presupuesto de la plataforma objetivo.

Es un camino más estrecho y más profundo que gameplay. Menos puestos, más especializados, y con una barrera de entrada real: si las matemáticas te incomodan, aquí duelen. A cambio, es de los perfiles más difíciles de sustituir.

## 🗓️ Un día en el puesto

- **Trabajar un efecto concreto:** disolución, agua, niebla volumétrica, contorno. Empieza en una referencia visual y termina en un `.gdshader`.
- **Perseguir milisegundos.** Medir el coste en GPU de lo que existe y decidir qué se recorta y qué se rehace.
- **Hablar con arte.** Explicar por qué esa referencia de ArtStation no es viable, y proponer la versión que sí lo es.
- **Depurar cosas invisibles.** Un shader no se rompe con un stack trace: se rompe pintando negro. Se depura por bisección y sacando valores a color.
- **Escribir herramientas** para el equipo de arte: materiales parametrizados, previsualizaciones, validadores de assets.
- **Probar en el hardware objetivo.** Lo que vuela en tu equipo puede arrastrarse en un móvil o en una consola portátil.

Trabajo silencioso, muy visual y con ciclos largos de prueba y error. La recompensa es inmediata y adictiva: cambias una línea y la pantalla entera cambia.

## 🧠 Qué necesitas saber

### Conocimiento técnico

- **Álgebra lineal aplicada:** matrices de transformación, espacios (modelo, mundo, vista, clip), normales y por qué se transforman distinto ([Parte 0](../classes/parte-0-fundamentos-y-prerrequisitos/README.md) y [Parte 3](../classes/parte-3-fisica-y-matematicas-de-juegos-aplicadas/README.md)).
- **El pipeline de render** de principio a fin: qué hace el vértice, qué hace el fragmento y qué pasa entremedias.
- **Shaders** en GLSL/HLSL: UV, ruido, máscaras, blending, y cómo se piensa «por píxel» en vez de «por objeto».
- **Iluminación y PBR:** qué es realmente la rugosidad, por qué el metal no tiene color difuso, cómo mienten las texturas.
- **Espacios de color y HDR:** lineal frente a sRGB, tone mapping, y por qué tu efecto se ve distinto al exportar ([clase 347](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/347-hdr-y-gestion-moderna-de-color/README.md)).
- **Coste en GPU:** draw calls, overdraw, ancho de banda, resolución. Y la técnica moderna que lo cambia todo: rendering temporal, upscaling y GPU-driven ([Parte 21](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/README.md)).

### Herramientas del oficio

- El **editor de shaders** de Godot, y los equivalentes de Unity (Shader Graph/HLSL) y Unreal (material editor).
- **RenderDoc** o el capturador del motor: ver el fotograma paso a paso es la única forma seria de depurar rendering.
- El **profiler de GPU**, distinto del de CPU y con otras preguntas.
- **Blender**, al menos para entender cómo llegan las mallas, las UV y las normales.

### Habilidades no técnicas

- **Vocabulario visual.** Saber nombrar lo que ves: contraste, valor, temperatura, silueta. Sin eso no puedes hablar con arte.
- **Traducir referencias** en descomposiciones técnicas: «esto son tres capas y una máscara de ruido», no «esto es magia».
- **Aceptar restricciones.** El presupuesto de fotograma no se negocia con argumentos, se negocia con mediciones.
- **Documentar.** Un shader sin explicación es un shader que nadie se atreve a tocar.

## 📚 Tu ruta en el programa

1. 📚 [**Parte 0 — Fundamentos**](../classes/parte-0-fundamentos-y-prerrequisitos/README.md) (001–025), con foco en matemáticas, pipeline gráfico y color y texturas.
2. 📚 [**Parte 1 — Motores 2D**](../classes/parte-1-motores-2d-y-tu-primer-juego-jugable/README.md) (026–045). Base práctica del motor: necesitas algo donde poner tus shaders.
3. 📚 [**Parte 2 — 3D**](../classes/parte-2-desarrollo-3d-motores-escenas-y-transformaciones/README.md) (046–067) con el 🧪 [lab 3D](../labs/3d-tercera-persona/README.md). Escenas, luces y materiales.
4. 📚 [**Parte 4 — Gráficos y shaders**](../classes/parte-4-graficos-shaders-y-rendering-moderno/README.md) (086–107) con el 🧪 [lab de shaders](../labs/shaders/README.md). **El núcleo de esta ruta.**
5. 🎯 **Hito**: un set de shaders y post-procesado propio ([clase 107](../classes/parte-4-graficos-shaders-y-rendering-moderno/107-capstone-parte-4-set-de-shaders-y-post-procesado/README.md)).
6. 📚 [**Parte 3 — Física y matemáticas**](../classes/parte-3-fisica-y-matematicas-de-juegos-aplicadas/README.md) (068–085). Las matemáticas en las que se apoya el render.
7. 📚 [**Parte 14 — Optimización**](../classes/parte-14-optimizacion-profiling-y-rendimiento/README.md) (240–254). Coste en GPU y draw calls.
8. 📚 [**Parte 9 — Arte**](../classes/parte-9-arte-animacion-y-pipeline-de-assets/README.md) (172–187). Hablar el idioma de los artistas · [**Parte 17**](../classes/parte-17-capstones-y-preparacion-profesional-portfolio/README.md).

➡️ Para el rendering moderno de verdad —temporal, upscaling, HDR, GI, GPU-driven y stutter de shaders— continúa en [**Programador de motor / rendimiento**](motor-rendimiento.md) ([Parte 21](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/README.md)).

## 🎓 Qué te contrata

- **Un breakdown visual.** Cada efecto con su antes/después, las capas por separado y su coste en milisegundos. Es el formato que la industria espera.
- **Shaders publicados** en un repositorio, comentados y con capturas. Un shader sin captura no lo mira nadie.
- **Un caso de optimización real:** «esta escena iba a 34 fps, la dejé en 60, esto es lo que hice y esto lo que sacrifiqué».
- **Coherencia estética.** Diez shaders sueltos impresionan menos que cinco que claramente pertenecen al mismo juego.

## 📈 Progresión de carrera y salario

1. **Junior graphics / technical artist** — implementas materiales y efectos dentro de un estilo ya definido.
2. **Graphics programmer** — defines efectos y sostienes el presupuesto de fotograma.
3. **Senior / rendering engineer** — tocas el pipeline: pases de render, iluminación global, integración de upscalers.
4. **Especialización:** rendering engineer de motor, technical art lead o [arquitecto técnico](arquitecto-tecnico.md).

Rangos **orientativos** (brutos anuales; muy dependientes de país y estudio):

- **LATAM:** entrada aproximada USD 12.000–24.000; con experiencia USD 25.000–50.000+.
- **España:** entrada aproximada 22.000–30.000 €; senior 42.000–60.000 €+.
- **Remoto / USD:** seniors de rendering por encima de USD 90.000–130.000; es de los perfiles mejor pagados del sector, y de los más escasos.

## ⚠️ Mitos y errores comunes

- **«Los shaders son magia.»** Son una función que devuelve un color, ejecutada muchísimas veces. Todo lo demás es composición.
- **«Copio uno de Shadertoy y listo.»** Los de Shadertoy están escritos para impresionar sin restricciones. En un juego pagas su coste millones de veces por fotograma.
- **«Mejor gráfica = mejor juego.»** El estilo coherente gana al realismo mediocre, y cuesta menos.
- **«Optimizo cuando esté hecho.»** En GPU, algunas decisiones de arquitectura visual no se pueden deshacer al final sin rehacer el arte.
- **«No necesito saber de arte.»** Sin vocabulario visual no puedes recibir un encargo ni defender una alternativa.
- **«El motor ya lo hace todo.»** Hasta que necesitas algo que no está, o que está pero no cabe en tu presupuesto de fotograma.

## 🚀 Siguientes pasos

1. Haz las clases de matemáticas de la **Parte 0** hasta que las transformaciones te resulten aburridas de tan claras.
2. Completa el 🧪 [lab de shaders](../labs/shaders/README.md) desde `inicio/`, y luego **rompe** cada shader a propósito para ver qué hace cada línea.
3. Elige una referencia visual que te guste y **descomponla por escrito** antes de escribir código. Ese documento es la mitad de un breakdown.
4. Publica tres shaders con capturas y explicación. Empieza por uno sencillo bien explicado, no por el más vistoso.
5. Mide siempre. Un efecto sin coste declarado es un efecto que nadie puede aprobar.
6. Cuando quieras entender por qué el motor hace lo que hace, entra en la [**Parte 21**](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/README.md).

---

- ⬅️ [Volver al índice de rutas](./README.md)
- 🏠 [Inicio del programa](../README.md)
