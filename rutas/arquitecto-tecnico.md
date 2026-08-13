# 🏛️ Arquitecto técnico de juegos

> No es un rol de entrada. Es el que decide **qué NO se construye**, y para eso hay que
> haber construido bastante como para saber lo que cuesta cada decisión.
>
> **Nivel de entrada:** senior · **Foco:** decisiones y sus consecuencias · **Hito faro:** un documento de arquitectura con las alternativas descartadas explicadas

## 🧭 Qué es y por qué importa

El arquitecto técnico define cómo se estructura un juego: qué sistemas existen, cómo se comunican, qué se compra y qué se construye, qué es autoritativo, qué se puede cambiar tarde y qué queda congelado el primer mes. Su producto no es código: son **decisiones documentadas** y las restricciones que las sostienen.

Importa porque los proyectos rara vez fracasan por una función mal escrita. Fracasan porque el guardado no se puede migrar, porque el inventario acopló a media docena de sistemas, porque el multijugador se dejó para el final o porque nadie midió si el diseño cabía en la plataforma objetivo. Todas esas son decisiones que se toman —o no se toman— al principio.

Es explícitamente un rol de destino, no de entrada. Se llega tras varias especializaciones, porque la autoridad aquí viene de haber pagado personalmente el precio de decisiones equivocadas.

## 🗓️ Un día en el puesto

- **Escuchar una petición y traducirla a coste.** «Queremos que el mundo sea abierto» significa streaming, particionado, presupuesto de memoria y seis meses.
- **Escribir un ADR** (registro de decisión de arquitectura): el problema, las opciones, la elegida y **por qué se descartaron las otras**.
- **Revisar acoplamientos.** ¿Por qué la UI conoce al sistema de combate? Ese hilo, tirado a tiempo, ahorra un trimestre.
- **Prototipar el riesgo.** Antes de comprometer una arquitectura, construir la parte pequeña que puede tumbarla.
- **Negociar alcance con producción** y con diseño, con números en la mano.
- **Enseñar.** Buena parte del trabajo es que el equipo tome buenas decisiones sin ti.

## 🧠 Qué necesitas saber

### Conocimiento técnico

- **Acoplamiento y sus formas.** Eventos, interfaces, datos compartidos, y dónde poner la costura ([Parte 18](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/README.md)).
- **Lo que no se puede cambiar tarde:** modelo de autoridad en red, formato de guardado, sistema de contenido, plataforma objetivo.
- **Confiabilidad y operación:** qué implica de verdad tener servicios en producción durante años ([Parte 19](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md)).
- **Coste real del rendimiento:** qué decisiones de arquitectura fijan un techo y cuáles no ([Parte 21](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/README.md)).
- **Producción:** alcance, hitos, presupuesto y la aritmética de un equipo ([Parte 16](../classes/parte-16-produccion-publicacion-monetizacion-y-liveops/README.md)).
- **Evaluación de lo generativo**, que hoy es una de las preguntas que más llegan mal planteadas ([clases 337](../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/337-evaluacion-de-sistemas-generativos/README.md) y [336](../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/336-seguridad-y-moderacion-de-ia-dentro-del-juego/README.md)).

### Herramientas del oficio

- **ADR**: un formato corto y versionado junto al código. La herramienta más barata y la más ignorada.
- **Diagramas que alguien lee**: pocos, actualizados y a la altura de abstracción correcta.
- **Prototipos desechables** para responder preguntas caras antes de comprometerse.
- **Métricas de proyecto:** tiempo de build, tiempo de iteración, tasa de fallos. La salud del proyecto se mide.

### Habilidades no técnicas

- **Decir que no con alternativas.** Un «no» sin propuesta es un obstáculo; con propuesta es arquitectura.
- **Escribir para el futuro.** Quien lea tu decisión dentro de dos años no tendrá el contexto que tú tienes hoy.
- **Autoridad sin imponer.** Las decisiones que el equipo no entiende se erosionan solas.
- **Aceptar que te equivocarás.** La honestidad sobre las decisiones que salieron mal es lo que hace creíbles las demás.

## 📚 Tu ruta en el programa

1. ✅ **Requisito:** al menos **dos rutas de especialización completas** ([sistemas de gameplay](sistemas-gameplay.md), [backend y online](backend-online.md), [IA para juegos](ia-juegos.md) o [motor y rendimiento](motor-rendimiento.md)).
2. 📚 [**Parte 18 — Sistemas y sus acoplamientos**](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/README.md) (293–310).
3. 📚 [**Parte 19 — Confiabilidad, amenazas y release engineering**](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md) (311–324).
4. 📚 [**Parte 21 — Coste real de las decisiones de arquitectura**](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/README.md) (339–352).
5. 📚 [**Parte 16 — Producción: alcance, hitos y presupuesto**](../classes/parte-16-produccion-publicacion-monetizacion-y-liveops/README.md) (267–280).
6. 📚 [**Parte 20 — IA generativa**](../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/README.md) (325–338), sobre todo las clases de evaluación y seguridad.
7. 🎯 **Hito**: un documento de arquitectura de tu propio juego con las decisiones justificadas **y las descartadas explicadas**.

## 🎓 Qué te contrata

- **Un documento de arquitectura real** de un proyecto que hiciste, con sus ADR. Es el entregable del rol.
- **Una decisión que salió mal**, contada con honestidad: qué asumiste, qué pasó y qué harías distinto. Es la pregunta clásica de entrevista para este puesto.
- **Evidencia de haber construido**: los proyectos de tus especializaciones previas. Sin eso, la arquitectura es opinión.
- **Un caso de reducción de alcance** que salvó un proyecto. Decir que no, bien, es la habilidad central.

## 📈 Progresión de carrera y salario

1. **Senior en una especialidad** — el punto de partida obligatorio.
2. **Lead técnico** — responsable de un área y de las personas que la construyen.
3. **Arquitecto técnico / principal engineer** — decisiones transversales al proyecto.
4. **Director técnico (CTO/Technical Director)** — decisiones transversales al estudio: tecnología, equipo y presupuesto.

Rangos **orientativos** (brutos anuales):

- **LATAM:** USD 35.000–80.000+, con mucha dispersión según el tipo de estudio.
- **España:** 50.000–80.000 €+.
- **Remoto / USD:** frecuentemente por encima de USD 130.000–180.000.

Aviso: son puestos escasos. En estudios pequeños el rol lo asume el lead o el fundador técnico, y solo aparece como puesto propio a partir de cierto tamaño.

## ⚠️ Mitos y errores comunes

- **«El arquitecto no programa.»** El que deja de programar pierde el contacto con el coste real de sus decisiones.
- **«Más abstracción es mejor arquitectura.»** La abstracción prematura es deuda con intereses. Generaliza al segundo caso, no al primero.
- **«Lo decido yo y lo comunico.»** Una decisión que el equipo no comparte se erosiona en tres sprints.
- **«El diagrama es la arquitectura.»** La arquitectura es lo que el código hace. El diagrama caduca la semana que viene.
- **«Elijo la mejor tecnología.»** Eliges la que el equipo puede sostener durante los próximos dos años. No es lo mismo.
- **«Se puede arreglar después.»** Algunas cosas sí. El modelo de autoridad, el formato de guardado y la plataforma objetivo, no.

## 🚀 Siguientes pasos

1. No empieces aquí. Vuelve a [sistemas de gameplay](sistemas-gameplay.md), [backend](backend-online.md), [IA](ia-juegos.md) o [motor](motor-rendimiento.md) y **termina dos**.
2. Escribe un **ADR** para una decisión que ya tomaste en un proyecto tuyo, con las alternativas que descartaste.
3. Coge tu juego más grande y **dibuja sus dependencias reales**. Casi siempre son peores de lo que recuerdas.
4. Haz la **Parte 16** entera: sin la aritmética de producción, la arquitectura vive en el vacío.
5. Elige un riesgo técnico del próximo proyecto y **prototípalo primero**, antes de comprometer nada.
6. Documenta tu peor decisión técnica y qué te enseñó. Ese texto vale más que cualquier diagrama.

---

- ⬅️ [Volver al índice de rutas](./README.md)
- 🏠 [Inicio del programa](../README.md)
