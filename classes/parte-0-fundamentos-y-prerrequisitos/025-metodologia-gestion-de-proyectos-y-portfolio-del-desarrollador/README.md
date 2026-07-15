# Clase 025 — Metodología, gestión de proyectos y portfolio del desarrollador

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Clinton Keith, Agile Game Development*
> ⏱️ Duración estimada: **95 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Tener buenas ideas no basta: hay que **organizar** el trabajo para terminarlo y **mostrarlo** para que cuente. Los estudios de videojuegos adoptaron versiones ligeras de **agile/scrum** porque el desarrollo es incierto y iterativo, y estructuran el proyecto en **milestones** reconocibles: vertical slice, alpha, beta y gold. Un tablero **kanban** hace visible qué falta, qué se está haciendo y qué está listo.

En esta clase montarás un flujo de trabajo real, entenderás cómo estimar y mantener un scope realista, y por qué las **game jams** son el mejor gimnasio para practicar. Además construirás la base de tu **portfolio** —itch.io, GitHub, devlogs— y sabrás qué buscan los estudios al revisarlo. En el laboratorio crearás un tablero kanban, esbozarás una página de itch.io y redactarás un mini game design document de una página.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar los principios de un scrum ligero aplicado a juegos y su ciclo iterativo.
2. Distinguir los milestones vertical slice, alpha, beta y gold.
3. Montar un tablero kanban con columnas y tarjetas reales para un proyecto.
4. Estimar tareas y ajustar el scope para que sea realista.
5. Estructurar un portfolio (itch.io, GitHub, devlog) y un mini GDD de una página.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Agile/scrum ligero | Desarrollar con incertidumbre e iteración. |
| 2 | Milestones | Metas claras que marcan el avance. |
| 3 | Kanban | Visualizar el flujo de trabajo. |
| 4 | Estimación y scope | Prometer lo que se puede cumplir. |
| 5 | Game jams | Practicar el ciclo completo en poco tiempo. |
| 6 | Portfolio | Que el trabajo sea visible y evaluable. |
| 7 | Qué miran los estudios | Enfocar lo que de verdad importa. |

## 📖 Definiciones y características

- **Scrum ligero**: marco iterativo con ciclos cortos (sprints) y revisión frecuente. Clave: adaptar el plan según lo aprendido.
- **Vertical slice**: fragmento jugable con calidad final de una porción pequeña. Clave: demuestra la visión del juego.
- **Alpha**: todas las mecánicas presentes aunque sin pulir. Clave: el juego es "jugable de principio a fin".
- **Beta**: contenido completo, foco en bugs y balance. Clave: feature freeze, solo se arregla.
- **Gold**: versión final lista para publicar. Clave: sin bloqueadores conocidos.
- **Kanban**: tablero con columnas (Por hacer / En curso / Hecho). Clave: límite de trabajo en curso y visibilidad.
- **Scope**: alcance comprometido del proyecto. Clave: realista o el proyecto no termina.
- **Devlog**: bitácora pública del desarrollo. Clave: muestra proceso y constancia a estudios y comunidad.

## 🧰 Herramientas y preparación

Para el tablero usarás **GitHub Projects** (<https://github.com/features/issues>) o **Trello** (<https://trello.com>); ambos son gratuitos y con columnas arrastrables. Para publicar juegos y esbozar tu vitrina, **itch.io** (<https://itch.io>), el escaparate estándar del desarrollo independiente. Tu código va en **GitHub** (<https://github.com>). Para el mini GDD basta un documento Markdown o Google Docs. La referencia base es *Agile Game Development* de Clinton Keith, sobre scrum aplicado a estudios. Para practicar el ciclo completo, busca game jams en itch.io o en Ludum Dare (<https://ldjam.com>).

## 🧪 Laboratorio guiado

### Paso 1 — Definir el proyecto y sus milestones

Elige un juego pequeño (por ejemplo, un plataformas de una pantalla) y escribe sus cuatro milestones en una nota:

- **Vertical slice**: un nivel pulido con el personaje, un enemigo y el salto sintiéndose bien.
- **Alpha**: todos los niveles y mecánicas presentes, sin pulir.
- **Beta**: contenido completo, corrigiendo bugs y balance.
- **Gold**: build final publicable en itch.io.

Tener las metas nombradas convierte "hacer un juego" en objetivos verificables.

### Paso 2 — Crear el tablero kanban

En GitHub Projects (o Trello) crea un tablero con tres columnas: **Por hacer**, **En curso**, **Hecho**. Añade tarjetas reales y pequeñas, cada una una tarea que quepa en una sesión:

```text
Por hacer:  "Movimiento horizontal del jugador"
            "Salto con delta time"
            "Un enemigo que patrulla"
            "Pantalla de inicio"
En curso:   "Diseño del nivel 1 (greybox)"
Hecho:      "Proyecto Godot inicializado"
```

La regla clave: limita cuántas tarjetas hay en *En curso* a la vez (por ejemplo, dos) para no dispersarte. Mueve las tarjetas conforme avanzas.

### Paso 3 — Estimar y ajustar el scope

Asigna a cada tarjeta una talla simple (S, M, L) según el esfuerzo. Suma las tallas y compáralas con el tiempo real que tienes. Si no cabe, **recorta**: mueve tarjetas a una columna "Después / v2". Un scope honesto que se termina vale más que uno ambicioso que se abandona.

### Paso 4 — Esbozar la página de itch.io

Redacta el contenido de tu futura página de itch.io (aún sin publicar): título del juego, una frase gancho, tres capturas o placeholders, controles, y una breve descripción. Estructura sugerida:

```text
Título:      Salto Neón
Gancho:      "Un plataformas veloz de una sola pantalla."
Controles:   Flechas para mover, Espacio para saltar, Shift para dash.
Descripción: Esquiva, salta y llega a la meta antes de que...
Capturas:    [placeholder1] [placeholder2] [placeholder3]
```

Esta ficha es tu carta de presentación; los estudios y jugadores deciden en segundos si prueban tu juego.

### Paso 5 — Redactar el mini GDD (una página)

Escribe un documento de diseño de una sola página con estas secciones:

```markdown
# GDD — Salto Neón (1 pagina)
## Concepto
Plataformas de una pantalla, veloz y preciso.
## Pilar de diseno
El movimiento se siente increible (dash + salto ajustado).
## Mecanicas
- Mover, saltar, dash con cooldown.
- Enemigos que patrullan; tocarlos reinicia.
## Alcance (scope)
5 niveles de una pantalla. Sin jefes.
## Estilo
Greybox ahora; neon minimalista despues.
## Exito
Un nivel completable que "engancha" en el primer minuto.
```

Una página obliga a priorizar: si algo no cabe, probablemente no es esencial. Este GDD guía qué tarjetas van al kanban.

## ✍️ Ejercicios

1. Divide una tarjeta grande ("Sistema de enemigos") en tres tarjetas pequeñas.
2. Asigna tallas S/M/L a diez tarjetas y calcula si caben en dos semanas.
3. Escribe la frase gancho de tu juego en menos de doce palabras.
4. Añade una columna "En revisión" al kanban y explica qué tarjetas pasarían por ella.
5. Busca una game jam próxima y anota su tema, duración y reglas.
6. Redacta la sección "Éxito" de tu GDD: cómo sabrás que el juego funciona.

## 📝 Reto verificable

Crea un tablero kanban real (GitHub Projects o Trello) para un proyecto de juego pequeño, con al menos las columnas Por hacer / En curso / Hecho y un mínimo de ocho tarjetas concretas repartidas entre ellas, cada una con una talla de estimación. Complementa con un mini GDD de una página (concepto, pilar, mecánicas, scope, estilo y éxito) y un esbozo de la página de itch.io (título, gancho, controles y descripción).

**Criterio de aceptación**: el tablero tiene tres o más columnas y ocho o más tarjetas estimadas, con el trabajo en curso limitado a un máximo definido; el GDD cabe en una página e incluye las seis secciones; y la ficha de itch.io contiene título, frase gancho, controles y descripción.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| El proyecto nunca llega a alpha | Scope demasiado grande. Recorta tarjetas a una columna "v2" y prioriza el vertical slice. |
| El tablero tiene todo en "En curso" | No limitas el trabajo simultáneo. Fija un máximo (p. ej. 2) y termina antes de empezar. |
| Las tarjetas son enormes y vagas | Falta desglose. Parte cada tarea en subtareas de una sesión. |
| El GDD tiene veinte páginas | Sobre-documentaste. Fuérzalo a una página; lo esencial cabe. |
| El portfolio son solo tutoriales copiados | No muestra criterio propio. Publica proyectos originales, aunque pequeños, con un devlog. |

## ❓ Preguntas frecuentes

**❓ ¿Sirve scrum para un desarrollador solo?** Sí, en versión ligera. No necesitas ceremonias completas, pero sí ciclos cortos, un tablero visible y revisar el avance con frecuencia para ajustar el plan a lo que vas aprendiendo.

**❓ ¿Qué diferencia hay entre alpha y beta?** En alpha todas las mecánicas y contenidos existen pero sin pulir; el juego se puede jugar de principio a fin. En beta hay *feature freeze*: no se añade nada nuevo, solo se corrigen bugs y se ajusta el balance.

**❓ ¿Por qué son útiles las game jams?** Porque comprimen el ciclo completo —idea, prototipo, publicación— en pocos días, entrenan a acotar el scope y producen juegos terminados para el portfolio. La restricción de tiempo obliga a decidir qué es esencial.

**❓ ¿Qué buscan los estudios en un portfolio?** Proyectos terminados y jugables, evidencia de proceso (devlogs, commits regulares en GitHub) y criterio propio. Prefieren un juego pequeño pulido y original a muchos tutoriales sin acabar.

## 🔗 Referencias

- Clinton Keith, *Agile Game Development with Scrum*: <https://www.agilegamedevelopment.com/>
- itch.io, "Creating and managing your game page": <https://itch.io/docs/creators/design>
- GitHub Docs, "About Projects": <https://docs.github.com/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects>
- Ludum Dare, game jam periódica: <https://ldjam.com/>

## ⬅️ Clase anterior

[Clase 024 - Prototipado rápido y bucle de iteración de diseño](../024-prototipado-rapido-y-bucle-de-iteracion-de-diseno/README.md)

## ➡️ Siguiente clase

[Clase 026 - Anatomía de un motor 2D: escenas, nodos y árbol](../../parte-1-motores-2d-y-tu-primer-juego-jugable/026-anatomia-de-un-motor-2d-escenas-nodos-y-arbol/README.md)
