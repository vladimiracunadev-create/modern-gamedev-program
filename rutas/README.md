# 🧭 Rutas guiadas por rol

> [⬅️ Volver al programa](../README.md) · [📚 Índice completo](../classes/README.md) · [✅ Mi progreso](https://vladimiracunadev-create.github.io/modern-gamedev-program/autoevaluaciones/progreso.html)

El programa tiene **352 clases**; **no todas son para todos a la vez**. Estas rutas ordenan el recorrido según el rol al que apuntas: qué partes hacer, en qué orden y con qué laboratorio practicar.

Todas asumen que **empiezas por la Parte 0** (fundamentos): es el cimiento común y no se salta. Y todas pasan por la **Parte 17** (capstone y portfolio): lo que te consigue el trabajo es un juego terminado, no un certificado.

Las **Partes 18–21** son especialización de ingeniería y llegan después del capstone, no antes. No las hagas por completismo: cada una responde a un problema que reconocerás cuando lo tengas delante — un inventario que se corrompe, un backend que se cae, un NPC que regala espadas legendarias, un bucle que no baja de 40 ms.

> Leyenda: 📚 parte del curso · 🧪 laboratorio ejecutable · 🎯 hito.

---

## 🎮 Programador de gameplay

El rol más demandado: haces que el juego *se sienta* bien.

1. 📚 **Parte 0** — Fundamentos (001–025) · foco en vectores, game loop, POO y patrones
2. 📚 **Parte 1** — Motores 2D (026–045) · 🧪 [Lab plataformas 2D](../labs/plataformas-2d/README.md)
3. 🎯 **Hito**: un plataformas propio con buen *game feel*, exportado y jugable
4. 📚 **Parte 2** — 3D (046–067) · 🧪 [Lab 3D en tercera persona](../labs/3d-tercera-persona/README.md)
5. 📚 **Parte 3** — Física aplicada (068–085) · colisiones, steering, easing
6. 📚 **Parte 5** — IA de juegos (108–125) · FSM, behavior trees, pathfinding · 🧪 [Lab IA](../labs/ia-enemigo/README.md)
7. 📚 **Parte 8** — Game design (156–171) · para entender *por qué* diseñas así
8. 📚 **Parte 14** — Optimización (240–254) · 📚 **Parte 17** — Capstone y portfolio
9. ➡️ **Continúa en** [Programador de sistemas de gameplay](#-programador-de-sistemas-de-gameplay) si tu juego ha crecido hasta necesitar inventario, stats y quests

## 🎨 Programador gráfico / técnico

Shaders, rendering y el *look* del juego.

1. 📚 **Parte 0** (001–025) · foco en matemáticas (004–006), pipeline (017), color y texturas (019)
2. 📚 **Parte 1** (026–045) · base práctica del motor
3. 📚 **Parte 2** (046–067) · escenas 3D, luces, materiales · 🧪 [Lab 3D](../labs/3d-tercera-persona/README.md)
4. 📚 **Parte 4** — Gráficos y shaders (086–107) · **el núcleo de esta ruta** · 🧪 [Lab shaders](../labs/shaders/README.md)
5. 🎯 **Hito**: un set de shaders y post-procesado propio (clase 107)
6. 📚 **Parte 3** (068–085) · matemáticas de la que se apoya el render
7. 📚 **Parte 14** — Optimización (240–254) · coste en GPU, draw calls
8. 📚 **Parte 9** — Arte (172–187) · hablar el idioma de los artistas · 📚 **Parte 17**

## 🕹️ Desarrollador indie (solo dev)

Lo haces todo tú: hay que ser eficiente y **terminar**.

1. 📚 **Parte 0** (001–025) · 📚 **Parte 1** (026–045) · 🧪 [Lab plataformas 2D](../labs/plataformas-2d/README.md)
2. 📚 **Parte 8** — Game design (156–171) · lo que hace que tu juego sea divertido
3. 📚 **Parte 9** — Arte (172–187) · lo justo para tener un juego coherente
4. 📚 **Parte 6** — Audio (126–137) · 📚 **Parte 10** — UI/UX (188–199)
5. 📚 **Parte 15** — Tooling (255–266) · automatiza para no ahogarte
6. 📚 **Parte 16** — Producción y publicación (267–280) · **no te la saltes: aquí se vende**
7. 🎯 **Hito**: juego publicado en itch.io/Steam · 📚 **Parte 17** — Capstone y portfolio

## 📱 Desarrollador móvil / web

Alcance masivo, restricciones duras.

1. 📚 **Parte 0** (001–025) · 📚 **Parte 1** (026–045)
2. 📚 **Parte 10** — UI/UX, accesibilidad, i18n (188–199) · crítico en pantallas pequeñas
3. 📚 **Parte 11** — Móvil y plataformas (200–213) · export, táctil, batería, tiendas
4. 📚 **Parte 12** — Web y HTML5 (214–227) · WASM, Phaser, Three.js, PWA
5. 📚 **Parte 14** — Optimización (240–254) · **imprescindible** en móvil/web
6. 📚 **Parte 16** — Monetización y publicación (267–280) · 📚 **Parte 17**

## 🌐 Programador de multijugador

De los roles más difíciles y mejor pagados.

1. 📚 **Parte 0** (001–025) · foco en redes básicas y determinismo (022)
2. 📚 **Parte 1** (026–045) · 📚 **Parte 2** (046–067) · base de gameplay
3. 📚 **Parte 3** — Física y determinismo (068–085) · especialmente la clase 084
4. 📚 **Parte 7** — Multijugador (138–155) · **el núcleo**: RPCs, predicción, rollback · 🧪 [Lab multijugador](../labs/multijugador/README.md)
5. 🎯 **Hito**: un juego en red cliente-servidor autoritativo (clase 155)
6. 📚 **Parte 14** — Optimización (240–254) · 📚 **Parte 15** — servidores y CI (255–266)
7. 📚 **Parte 17** — Capstone y portfolio
8. ➡️ **Continúa en** [Ingeniero de backend y online](#️-ingeniero-de-backend-y-online): la Parte 7 te da el juego en red, la Parte 19 te da el servicio que sigue en pie a las tres de la mañana

## 🧩 Diseñador de niveles / diseñador técnico

Diseñas la experiencia y las herramientas que la construyen.

1. 📚 **Parte 0** (001–025) · lo suficiente para no depender de nadie
2. 📚 **Parte 1** (026–045) · tilemaps y prototipado
3. 📚 **Parte 8** — Game design y niveles (156–171) · **el núcleo**
4. 🎯 **Hito**: un nivel diseñado y greyboxeado con intención (clase 171)
5. 📚 **Parte 2** (046–067) · blockout y GridMap en 3D
6. 📚 **Parte 15** — Tooling (255–266) · construye tus propias herramientas
7. 📚 **Parte 10** — UI/UX (188–199) · 📚 **Parte 17**

## 🥽 Desarrollador XR (VR/AR)

Nicho en crecimiento con exigencias técnicas altas.

1. 📚 **Parte 0** (001–025) · 📚 **Parte 1** (026–045)
2. 📚 **Parte 2** — 3D (046–067) · **obligatorio**: XR es 3D puro
3. 📚 **Parte 3** — Física (068–085) · interacción creíble
4. 📚 **Parte 14** — Optimización (240–254) · **antes** de XR: los 90 fps no se negocian
5. 📚 **Parte 13** — VR/AR (228–239) · **el núcleo**
6. 📚 **Parte 6** — Audio espacial (126–137) · 📚 **Parte 17**

---

**🔧 Rutas de especialización (Partes 18–21).** Las seis que siguen **empiezan donde terminan las anteriores**. Todas dan por supuesto que ya tienes un juego terminado: son la diferencia entre saber hacer un juego y saber sostener uno.

---

## 🎒 Programador de sistemas de gameplay

El rol que diseña las reglas que otros usan. Inventario, stats, habilidades, quests y economía: sistemas que se combinan entre sí y que **nadie puede reescribir a mitad de producción**.

1. ✅ **Requisito**: [Programador de gameplay](#-programador-de-gameplay) completo, incluida la Parte 5
2. 📚 **Parte 18** — Arquitectura de gameplay (293–310) · **el núcleo** · 🧪 [Lab sistemas de gameplay](../labs/gameplay-systems/README.md)
3. 🎯 **Hito**: inventario con transacciones atómicas y guardado con migraciones encadenadas (clase 310)
4. 📚 **Parte 8** — Game design (156–171) · si te la saltaste: diseñarás sistemas sin saber para qué
5. 📚 **Parte 16** — Economía y LiveOps (267–280) · lo que pasa cuando tus sistemas tienen dinero dentro
6. 📚 **Parte 19** — Confiabilidad (311–324) · si el inventario vive en un servidor, es otro problema

## ☁️ Ingeniero de backend y online

Lo que la gente ve cuando tu juego falla. Este rol se mide en incidentes evitados, no en funciones entregadas.

1. ✅ **Requisito**: [Programador de multijugador](#-programador-de-multijugador), o Parte 7 al menos
2. 📚 **Parte 15** — Tooling, CI y automatización (255–266) · la base del oficio
3. 📚 **Parte 19** — Producción y confiabilidad (311–324) · **el núcleo** · 🧪 [Lab runtime de producción](../labs/production-runtime/README.md)
4. 🎯 **Hito**: un cliente que sobrevive a un servidor hostil — reintentos, circuit breaker, idempotencia y degradación (clase 324)
5. 📚 **Parte 18** — Sistemas de gameplay (293–310) · para entender qué estás autorizando en el servidor
6. 📚 **Parte 16** — Publicación y LiveOps (267–280) · parches, telemetría y recuperación

## 🤖 Desarrollador de IA para juegos

Las dos IA, en el orden correcto: primero la que decide, después la que habla.

1. ✅ **Requisito**: Parte 0 y Parte 1
2. 📚 **Parte 5** — IA clásica (108–125) · **primero, y no es negociable** · 🧪 [Lab IA de enemigos](../labs/ia-enemigo/README.md)
3. 📚 **Parte 18** — Sistemas de gameplay (293–310) · lo que la IA generativa va a poder tocar (y lo que no)
4. 📚 **Parte 20** — IA generativa (325–338) · 🧪 [Lab sistema de IA](../labs/ai-game-system/README.md)
5. 🎯 **Hito**: un NPC con lore verificable que resiste siete ataques de prompt injection sin alterar el estado del juego (clase 338)
6. 📚 **Parte 19** — Coste, latencia y privacidad (311–324) · un proveedor remoto es un servicio remoto

> **Por qué la Parte 5 va antes.** Un enemigo que te persigue necesita un A\* que corra a 60 fps y que puedas depurar, no un modelo de lenguaje. Quien hace la Parte 20 sin la 5 termina resolviendo con un LLM problemas que un behavior tree resuelve mejor, más barato y de forma reproducible.

## ⚙️ Programador de motor / rendimiento

El rol que mide antes de opinar. Aquí no se optimiza lo que parece lento: se optimiza lo que el profiler señala.

1. ✅ **Requisito**: Parte 3 (física y matemáticas) y Parte 14 (optimización)
2. 📚 **Parte 14** — Optimización y profiling (240–254) · reléela: es el método
3. 📚 **Parte 21** — Arquitectura avanzada (339–352) · **el núcleo** · 🧪 [Lab ingeniería avanzada](../labs/advanced-engineering/README.md)
4. 🎯 **Hito**: cuatro optimizaciones medidas en tu máquina, cada una comprobada contra una implementación de referencia obviamente correcta (clase 352)
5. 📚 **Parte 4** — Gráficos y shaders (086–107) · para las clases 345–351, que son de rendering
6. 📚 **Parte 15** — Tooling (255–266) · pruebas de regresión de rendimiento en CI

## 🏛️ Arquitecto técnico de juegos

No es un rol de entrada. Es el que decide qué NO se construye, y para eso hay que haber construido bastante.

1. ✅ **Requisito**: al menos dos rutas de especialización completas
2. 📚 **Parte 18** — Sistemas y sus acoplamientos (293–310)
3. 📚 **Parte 19** — Confiabilidad, amenazas y release engineering (311–324)
4. 📚 **Parte 21** — Coste real de las decisiones de arquitectura (339–352)
5. 📚 **Parte 16** — Producción: scope, milestones y presupuesto (267–280)
6. 📚 **Parte 20** — IA generativa (325–338) · sobre todo las clases de evaluación y seguridad
7. 🎯 **Hito**: un documento de arquitectura de tu propio juego con las decisiones justificadas **y las descartadas explicadas**

## 🚀 Indie avanzado

Ya publicaste. Ahora el problema no es terminar, es que lo terminado aguante: parches, jugadores reales y una base de código que tendrás que tocar dentro de un año.

1. ✅ **Requisito**: [Desarrollador indie](#️-desarrollador-indie-solo-dev) completo, con un juego publicado
2. 📚 **Parte 18** — Sistemas de gameplay (293–310) · **empieza aquí**: es lo que más cuesta reescribir después
3. 📚 **Parte 19** — Confiabilidad (311–324) · céntrate en guardado, telemetría con consentimiento y parches
4. 📚 **Parte 21** — Rendimiento (339–352) · las clases 339–342 primero; el rendering avanzado puede esperar
5. 📚 **Parte 20** — IA generativa (325–338) · **la parte de desarrollo asistido es la que más te rinde en solitario**
6. 🎯 **Hito**: tu juego publicado con guardado migrable, telemetría respetuosa y un plan de parches que no rompa partidas

---

## 💡 Cómo usar una ruta

- **Sigue el orden dentro de la ruta**, no el número de clase. Las rutas saltan partes a propósito.
- **Marca tu avance** en el [seguimiento de progreso](https://vladimiracunadev-create.github.io/modern-gamedev-program/autoevaluaciones/progreso.html).
- **Comprueba que lo dominas** con la [autoevaluación](https://vladimiracunadev-create.github.io/modern-gamedev-program/autoevaluaciones/quiz.html) de cada parte antes de pasar a la siguiente.
- **Haz los hitos 🎯**. Una parte "leída" no cuenta; una parte con algo construido, sí.
