# 🤖 Desarrollador de IA para juegos

> Las dos IA, en el orden correcto: primero la que **decide**, después la que **habla**.
> Y una regla que gobierna todo lo generativo: el modelo propone, el juego dispone.
>
> **Nivel de entrada:** intermedio · **Foco:** comportamiento y sistemas generativos acotados · **Hito faro:** un NPC con lore verificable que resiste ataques de prompt injection

## 🧭 Qué es y por qué importa

El desarrollador de IA para juegos construye el comportamiento de todo lo que no controla el jugador: enemigos que persiguen, aliados que ayudan, sistemas que reaccionan. Y, desde hace poco, también los sistemas **generativos**: NPC conversacionales, diálogo y contenido asistido por modelos de lenguaje.

Son dos oficios distintos y conviene no mezclarlos. La IA clásica —máquinas de estados, behavior trees, pathfinding, steering— resuelve el comportamiento en tiempo real de forma determinista, depurable y barata. La IA generativa abre lo que antes era imposible: conversaciones abiertas, variación infinita, contenido que reacciona a lo que el jugador escribe.

Importa porque la industria está llena de ruido en este tema y de muy poca claridad sobre dónde aporta cada cosa. Un enemigo que te persigue necesita un A\* que corra a 60 fps y que puedas depurar, no un modelo de lenguaje. Saber elegir es el valor real del rol.

## 🗓️ Un día en el puesto

- **Depurar por qué un enemigo hace algo absurdo.** Casi siempre es prioridad de ramas o una condición de percepción mal puesta.
- **Ajustar percepción y memoria:** cono de visión, tiempo de olvido, último lugar conocido. El realismo aquí es diseño, no simulación.
- **Perseguir el coste.** Cuarenta agentes pensando cada fotograma no caben: presupuestos, escalonado, niveles de detalle de IA.
- **En sistemas generativos:** definir la lista cerrada de intenciones que un NPC puede proponer, y qué valida cada una.
- **Atacar tu propio sistema.** Escribir prompts hostiles e intentar que el NPC regale una espada legendaria. Si lo consigues, arréglalo ([clase 336](../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/336-seguridad-y-moderacion-de-ia-dentro-del-juego/README.md)).
- **Medir el comportamiento**, no la intención: grabar partidas y ver qué decidió realmente el agente.

## 🧠 Qué necesitas saber

### Conocimiento técnico

- **Máquinas de estados y behavior trees**, con sus prioridades y sus fallos típicos ([Parte 5](../classes/parte-5-inteligencia-artificial-para-juegos/README.md)).
- **Pathfinding**: A\*, mallas de navegación, suavizado, y por qué el camino más corto no es el que se ve bien.
- **Steering y percepción:** llegada, evasión, conos de visión, memoria de último avistamiento.
- **Depurabilidad.** Un agente cuyo estado no puedes ver en pantalla es un agente que no puedes arreglar.
- **Abstracción de proveedor** para lo generativo: mock, local o remoto, todos detrás de la misma interfaz ([clase 334](../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/334-proveedores-locales-y-remotos/README.md)).
- **Validación de salida:** intención estructurada, lista cerrada, capacidades mínimas por NPC ([clase 331](../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/331-npc-controlados-por-llm/README.md)).
- **Lore con visibilidad:** filtrar al **recuperar**, no al responder. Lo que entra al contexto se puede extraer ([clase 332](../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/332-rag-memoria-y-lore-del-mundo/README.md)).
- **Coste, latencia y caché**, que es lo que decide si algo es publicable o una demo ([clase 335](../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/335-coste-latencia-cache-y-fallbacks/README.md)).

### Herramientas del oficio

- El sistema de navegación del motor y un **visualizador de estado** propio: rutas, conos, estado actual dibujados en pantalla.
- **Modelos locales** (llama.cpp, Ollama y similares) para desarrollar sin coste ni red.
- Un **proveedor mock determinista** para las pruebas, incluido uno **adversario** que obedezca al atacante — es el único que prueba de verdad tus defensas.
- Un **arnés de evaluación**: sin métricas, «el NPC responde mejor» es una opinión ([clase 337](../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/337-evaluacion-de-sistemas-generativos/README.md)).

### Habilidades no técnicas

- **Criterio para elegir la herramienta.** La mayor parte del valor del rol está en decir «esto no necesita un LLM».
- **Mentalidad de atacante sobre tu propio sistema.** Si no intentas romperlo tú, lo romperá un jugador el primer día.
- **Diseñar la sensación, no la simulación.** Un enemigo «justo» suele ser peor jugador que uno óptimo, a propósito.
- **Honestidad sobre los límites.** Saber explicar qué no puede garantizar un sistema generativo es parte del trabajo.

## 📚 Tu ruta en el programa

1. ✅ **Requisito:** [Parte 0](../classes/parte-0-fundamentos-y-prerrequisitos/README.md) y [Parte 1](../classes/parte-1-motores-2d-y-tu-primer-juego-jugable/README.md).
2. 📚 [**Parte 5 — IA clásica**](../classes/parte-5-inteligencia-artificial-para-juegos/README.md) (108–125) con el 🧪 [lab de IA de enemigos](../labs/ia-enemigo/README.md). **Primero, y no es negociable.**
3. 📚 [**Parte 18 — Sistemas de gameplay**](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/README.md) (293–310). Lo que la IA generativa va a poder tocar (y lo que no).
4. 📚 [**Parte 20 — IA generativa**](../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/README.md) (325–338) con el 🧪 [lab de sistema de IA](../labs/ai-game-system/README.md).
5. 🎯 **Hito**: un NPC con lore verificable que resiste **siete ataques de prompt injection** sin alterar el estado del juego ([clase 338](../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/338-capstone-parte-20-un-npc-con-lore-verificable/README.md)).
6. 📚 [**Parte 19 — Coste, latencia y privacidad**](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md) (311–324). Un proveedor remoto es un servicio remoto.

> **Por qué la Parte 5 va antes.** Quien hace la Parte 20 sin la 5 termina resolviendo con un LLM problemas que un behavior tree resuelve mejor, más barato y de forma reproducible. La Parte 20 **complementa** a la 5; no la sustituye.

## 🎓 Qué te contrata

- **Un enemigo que decide** y lo demuestra: vídeo con el estado del árbol sobreimpreso mientras patrulla, persigue, pierde y busca.
- **Un sistema generativo con sus defensas probadas.** Enseña los ataques que intentaste y por qué fallaron: eso es lo que separa a un profesional de una demo.
- **Números de coste y latencia** por interacción, y la estrategia de caché que los bajó.
- **Un sistema que funciona sin red y sin claves.** Es una señal inmediata de que entiendes cómo se construye algo publicable.

## 📈 Progresión de carrera y salario

1. **Gameplay/AI programmer junior** — implementas comportamientos dentro de un framework de IA existente.
2. **AI programmer** — dueño del comportamiento de una familia de agentes y de sus herramientas de depuración.
3. **Senior** — defines la arquitectura de IA del juego, su presupuesto de CPU y, si aplica, la integración generativa.
4. **Especialización:** IA de sistemas y director de IA, [sistemas de gameplay](sistemas-gameplay.md) o [arquitecto técnico](arquitecto-tecnico.md).

Rangos **orientativos** (brutos anuales):

- **LATAM:** entrada aproximada USD 13.000–26.000; con experiencia USD 28.000–55.000+.
- **España:** entrada aproximada 24.000–32.000 €; senior 44.000–62.000 €+.
- **Remoto / USD:** seniors por encima de USD 90.000–130.000.

El perfil que combina **IA clásica sólida + criterio sobre lo generativo** es hoy escaso y muy buscado, precisamente porque abunda lo contrario.

## ⚠️ Mitos y errores comunes

- **«Un LLM puede controlar todo el NPC.»** Puede proponer. Ejecutar es del juego, siempre y sin excepción.
- **«Lo arreglo con un prompt del sistema mejor.»** Un prompt es una sugerencia, no un límite. La defensa es de arquitectura.
- **«Meto todo el lore en el contexto y le digo que no lo cuente.»** Lo que entra se puede extraer. Filtra al recuperar.
- **«La IA clásica está obsoleta.»** Es lo que corre a 60 fps con cuarenta agentes y se puede depurar. No se va a ninguna parte.
- **«Pruebo con el modelo real y ya.»** No es determinista y necesita red: la prueba fallará por motivos ajenos y acabará desactivada. Mocks.
- **«La IA buena es la que gana.»** La IA buena es la que hace que el jugador se lo pase bien. Suelen ser cosas distintas.

## 🚀 Siguientes pasos

1. Haz la **Parte 5** completa y el 🧪 [lab de IA de enemigos](../labs/ia-enemigo/README.md) hasta que el árbol recorra sus ramas sin sorpresas.
2. Dibuja en pantalla el estado del agente. Si no puedes verlo, no puedes arreglarlo.
3. Haz la **Parte 18** al menos hasta el sistema de inventario: es lo que tu NPC generativo va a poder tocar.
4. Completa el 🧪 [lab de sistema de IA](../labs/ai-game-system/README.md) desde `inicio/` y observa cómo **el mismo ataque** funciona o falla según la arquitectura.
5. Escribe **tus propios ataques** contra tu NPC. Cinco como mínimo. Documenta cuáles pasaron.
6. Monta un proveedor local y mide coste y latencia reales antes de proponer nada a nadie.

---

- ⬅️ [Volver al índice de rutas](./README.md)
- 🏠 [Inicio del programa](../README.md)
