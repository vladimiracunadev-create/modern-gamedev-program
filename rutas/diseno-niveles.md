# 🧩 Diseñador de niveles / diseñador técnico

> Diseñas la experiencia **y** las herramientas que la construyen. El puente entre lo que
> el equipo de diseño quiere y lo que el motor sabe hacer.
>
> **Nivel de entrada:** inicial-intermedio · **Foco:** espacio, ritmo y herramientas · **Hito faro:** un nivel greyboxeado con intención, y la herramienta que lo hizo posible

## 🧭 Qué es y por qué importa

El diseñador de niveles construye el espacio donde ocurre el juego: por dónde va el jugador, qué ve primero, dónde se pelea, dónde descansa, cuándo aprende algo nuevo. El diseñador **técnico** añade la otra mitad: las herramientas, los datos y los sistemas que permiten que ese diseño se itere sin llamar a un programador cada vez.

Importa porque el nivel es donde todos los sistemas se encuentran. Un buen diseño de nivel puede hacer que una mecánica mediocre brille, y un mal nivel puede enterrar una excelente. Y porque, en la práctica, **la velocidad de iteración decide la calidad**: el equipo que puede probar veinte variantes de una sala llega a una mejor que el que solo puede probar tres.

Es un rol híbrido y muy empleable precisamente por eso: entiende de diseño lo suficiente para discutir y de programación lo suficiente para no depender de nadie.

## 🗓️ Un día en el puesto

- **Bloquear (greybox) una zona nueva** con formas simples. Sin arte, sin luces, solo espacio y recorrido.
- **Jugarla veinte veces** y contar segundos: cuánto tarda el jugador en entender qué hacer, dónde se pierde, dónde se aburre.
- **Ver a alguien jugarla sin ayuda.** El momento más incómodo y más útil de la semana.
- **Ajustar la colocación** de enemigos, recursos y puntos de guardado. Nunca es la primera versión.
- **Construir o arreglar herramientas:** un editor de spawns, un validador que avise si un nivel no se puede completar, un importador de datos ([Parte 15](../classes/parte-15-herramientas-editores-y-automatizacion/README.md)).
- **Documentar la intención.** Un nivel sin intención escrita se pierde en la primera revisión ajena.

## 🧠 Qué necesitas saber

### Conocimiento técnico

- **Lo suficiente de programación** para no depender de nadie: scripting del motor, escenas, señales, datos ([Parte 0](../classes/parte-0-fundamentos-y-prerrequisitos/README.md) y [Parte 1](../classes/parte-1-motores-2d-y-tu-primer-juego-jugable/README.md)).
- **Tilemaps y prototipado rápido** en 2D; **blockout y GridMap** en 3D ([Parte 2](../classes/parte-2-desarrollo-3d-motores-escenas-y-transformaciones/README.md)).
- **Teoría de diseño de niveles:** líneas de visión, landmarks, guía por composición, pacing, dificultad ([Parte 8](../classes/parte-8-game-design-y-diseno-de-niveles/README.md)).
- **Diseño data-driven:** que el contenido viva en datos y no en código, para poder iterar sin compilar ([clase 259](../classes/parte-15-herramientas-editores-y-automatizacion/259-generacion-y-validacion-de-datos-data-driven/README.md)).
- **Herramientas de editor:** plugins, gizmos, inspectores personalizados ([Parte 15](../classes/parte-15-herramientas-editores-y-automatizacion/README.md)).
- **UI y legibilidad**, porque la mitad de las decisiones de nivel se comunican por interfaz ([Parte 10](../classes/parte-10-ui-ux-accesibilidad-y-localizacion/README.md)).

### Herramientas del oficio

- El **editor del motor**, dominado de verdad: atajos, snapping, escenas heredadas, instancias.
- **Tiled** para 2D; **Blender** para blockouts 3D si el motor se te queda corto.
- **Hojas de cálculo** para el balance y la colocación de contenido. Sí, otra vez.
- Un **grabador de partidas o mapa de calor** propio: saber dónde muere y dónde se atasca la gente vale más que cualquier opinión.

### Habilidades no técnicas

- **Observar sin intervenir.** Cuando ves a alguien jugar, cállate. Su confusión es el dato.
- **Aceptar que tu nivel favorito puede estar mal.** El apego al propio diseño es el mayor enemigo del oficio.
- **Comunicar intención** en un documento corto que otros puedan seguir.
- **Colaborar con arte y programación** sin quedar atrapado en medio.

## 📚 Tu ruta en el programa

1. 📚 [**Parte 0**](../classes/parte-0-fundamentos-y-prerrequisitos/README.md) (001–025). Lo suficiente para no depender de nadie.
2. 📚 [**Parte 1**](../classes/parte-1-motores-2d-y-tu-primer-juego-jugable/README.md) (026–045). Tilemaps y prototipado, con el 🧪 [lab de plataformas 2D](../labs/plataformas-2d/README.md).
3. 📚 [**Parte 8 — Game design y niveles**](../classes/parte-8-game-design-y-diseno-de-niveles/README.md) (156–171). **El núcleo de esta ruta.**
4. 🎯 **Hito**: un nivel diseñado y greyboxeado con intención ([clase 171](../classes/parte-8-game-design-y-diseno-de-niveles/171-capstone-parte-8-disenar-y-greyboxear-un-nivel-completo/README.md)).
5. 📚 [**Parte 2**](../classes/parte-2-desarrollo-3d-motores-escenas-y-transformaciones/README.md) (046–067). Blockout y GridMap en 3D.
6. 📚 [**Parte 15 — Tooling**](../classes/parte-15-herramientas-editores-y-automatizacion/README.md) (255–266). Construye tus propias herramientas.
7. 📚 [**Parte 10 — UI/UX**](../classes/parte-10-ui-ux-accesibilidad-y-localizacion/README.md) (188–199) · 📚 [**Parte 17**](../classes/parte-17-capstones-y-preparacion-profesional-portfolio/README.md).

➡️ Si lo que te atrae es el contenido sistémico —quests, facciones, economía, progresión—, continúa en [**Programador de sistemas de gameplay**](sistemas-gameplay.md) ([Parte 18](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/README.md)).

## 🎓 Qué te contrata

- **Un nivel jugable** con su documento de intención al lado: qué querías provocar y cómo lo conseguiste.
- **El proceso, no solo el resultado:** greybox → iteración → versión final, con lo que cambiaste tras cada playtest.
- **Una herramienta que hiciste** para acelerar tu propio trabajo. Esto es lo que distingue a un diseñador técnico.
- **Notas de playtest reales**, aunque sean de tres amigos. Demuestra método, que es lo que se contrata.

## 📈 Progresión de carrera y salario

1. **Junior level designer** — construyes zonas dentro de una guía de estilo y un kit ya existentes.
2. **Level designer / technical designer** — diseñas zonas completas y las herramientas que las soportan.
3. **Senior** — defines el lenguaje de nivel del juego, el kit y los estándares de iteración.
4. **Especialización:** lead de diseño, [sistemas de gameplay](sistemas-gameplay.md) o dirección de diseño.

Rangos **orientativos** (brutos anuales):

- **LATAM:** entrada aproximada USD 9.000–20.000; con experiencia USD 20.000–42.000+.
- **España:** entrada aproximada 18.000–26.000 €; senior 35.000–50.000 €+.
- **Remoto / USD:** seniors por encima de USD 70.000–100.000.

El diseño de niveles paga algo menos que la programación pura, y tiene más competencia por puesto. El perfil **técnico** —el que además construye herramientas— es el que rompe ese techo.

## ⚠️ Mitos y errores comunes

- **«Diseñar niveles es decorar.»** La decoración va al final. El trabajo es el recorrido, el ritmo y la información.
- **«Empiezo poniendo arte para verlo bonito.»** El arte temprano te impide tirar el nivel, y casi siempre hay que tirarlo.
- **«Si yo lo entiendo, se entiende.»** Tú conoces la solución. Necesitas ver a alguien que no.
- **«Más grande es mejor.»** Los espacios enormes y vacíos son el error más común de quien empieza.
- **«Las herramientas las hacen los programadores.»** En un equipo pequeño, no. Y saber hacerlas es tu ventaja competitiva.
- **«El playtest es para el final.»** Cuanto antes duela, más barato sale.

## 🚀 Siguientes pasos

1. Haz las **Partes 0 y 1** y construye un nivel completo con el 🧪 [lab de plataformas 2D](../labs/plataformas-2d/README.md).
2. Coge ese nivel y **rehazlo desde cero** con lo que aprendas en la **Parte 8**. Compara ambos: ahí está tu aprendizaje.
3. Haz que **tres personas** lo jueguen delante de ti sin decirles nada. Anota cada duda y cada muerte.
4. Escribe un documento de intención de una página y adjúntalo. Vale tanto como el nivel.
5. Construye **una herramienta** que te ahorre tiempo, por pequeña que sea ([Parte 15](../classes/parte-15-herramientas-editores-y-automatizacion/README.md)).
6. Repite en 3D con un blockout. Cambia todo menos el método.

---

- ⬅️ [Volver al índice de rutas](./README.md)
- 🏠 [Inicio del programa](../README.md)
