# 🚀 Indie avanzado

> Ya publicaste. Ahora el problema no es terminar: es que lo terminado **aguante** parches,
> jugadores reales y una base de código que tendrás que tocar dentro de un año.
>
> **Nivel de entrada:** intermedio, con un juego publicado · **Foco:** sostener lo que ya existe · **Hito faro:** un juego con guardado migrable, telemetría respetuosa y un plan de parches que no rompa partidas

## 🧭 Qué es y por qué importa

El indie avanzado es el mismo desarrollador en solitario, pero con un juego vivo. Cambia todo: ya hay jugadores con partidas guardadas, ya hay reseñas, ya hay un parche pendiente y ya existe la posibilidad real de romperle la campaña a alguien que lleva cuarenta horas.

Importa porque la mayoría del material para indies termina en «publica tu juego», y ahí es donde empiezan los problemas interesantes: cómo cambiar el balance sin invalidar partidas, cómo saber dónde abandona la gente sin espiarla, cómo añadir contenido sin que el código se convierta en algo que ya no te atreves a tocar.

También cambia el uso del tiempo. En solitario no hay equipo que absorba la complejidad: cada sistema que añades lo mantienes tú, para siempre. La ingeniería, aquí, no es lujo: es lo que permite que sigas avanzando en el año dos.

## 🗓️ Un día en el puesto

- **Leer lo que dicen los jugadores** y separar lo que es un bug de lo que es una expectativa.
- **Preparar un parche** comprobando que las partidas de la versión anterior siguen cargando. Cada vez.
- **Mirar los números** —dónde abandonan, qué no se usa— con la telemetría mínima que decidiste registrar.
- **Refactorizar lo justo.** Solo lo que te está frenando ahora, no lo que te molesta estéticamente.
- **Añadir contenido** en datos, no en código, para que la próxima adición cueste minutos y no días.
- **Trabajar la comunidad:** devlog, respuestas, notas de parche que se entiendan.

## 🧠 Qué necesitas saber

### Conocimiento técnico

- **Sistemas data-driven.** Lo que más te va a rendir en solitario: contenido en archivos, no en código ([Parte 18](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/README.md)).
- **Guardado versionado con migraciones.** El día del primer parche es tarde para empezar ([clase 307](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/307-save-system-de-produccion/README.md)).
- **Escritura atómica y copias de seguridad:** temporal, checksum y renombrado. Una partida corrupta es una reseña negativa garantizada ([clase 313](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/313-cloud-saves-cross-save-y-resolucion-de-conflictos/README.md)).
- **Telemetría con consentimiento** y taxonomía cerrada: lo mínimo que responda a una pregunta concreta ([clase 317](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/317-telemetria-privacidad-y-gobernanza-de-datos/README.md)).
- **Parches y recuperación:** cómo revertir cuando algo sale mal ([clase 323](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/323-parches-delivery-y-recuperacion/README.md)).
- **Rendimiento con criterio:** datos, memoria y estructuras espaciales bastan para casi todo ([clases 339–342](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/339-data-oriented-design/README.md)).
- **IA generativa como herramienta de desarrollo**, que es donde más rinde a quien trabaja solo ([Parte 20](../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/README.md)).

### Herramientas del oficio

- **CI propia**, aunque sea mínima: que cada commit construya y pase cuatro pruebas ([Parte 15](../classes/parte-15-herramientas-editores-y-automatizacion/README.md)).
- **Un arnés de pruebas** para tus sistemas, como el del 🧪 [lab de sistemas de gameplay](../labs/gameplay-systems/README.md). En solitario, las pruebas son el compañero de equipo que no tienes.
- **Un canal de reporte de errores** que te llegue con contexto (versión, plataforma, guardado).
- **Copias de seguridad automáticas** de tu proyecto y de tus claves de firma. Ambas se pierden igual de fácil.

### Habilidades no técnicas

- **Priorizar entre voces contradictorias.** Los jugadores piden cosas incompatibles; decidir es tu trabajo.
- **Sostener el ritmo largo.** El año dos de un proyecto es menos emocionante y más decisivo que el primero.
- **Comunicar cambios.** Unas notas de parche claras evitan la mitad de las quejas.
- **Saber cuándo cerrar.** No todos los juegos merecen tres años. Terminar de mantener también es una decisión.

## 📚 Tu ruta en el programa

1. ✅ **Requisito:** la ruta de [**Desarrollador indie**](indie.md) completa, con un juego publicado.
2. 📚 [**Parte 18 — Sistemas de gameplay**](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/README.md) (293–310). **Empieza aquí**: es lo que más cuesta reescribir después.
3. 📚 [**Parte 19 — Confiabilidad**](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md) (311–324). Céntrate en guardado, telemetría con consentimiento y parches.
4. 📚 [**Parte 21 — Rendimiento**](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/README.md) (339–352). Las clases 339–342 primero; el rendering avanzado puede esperar.
5. 📚 [**Parte 20 — IA generativa**](../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/README.md) (325–338). **La parte de desarrollo asistido es la que más rinde en solitario.**
6. 🎯 **Hito**: tu juego publicado con guardado migrable, telemetría respetuosa y un plan de parches que no rompa partidas.

## 🎓 Qué te contrata (o te sostiene)

- **Un juego que lleva vivo un año** con su historial de parches. Es una carta de presentación mejor que cualquier prototipo.
- **Unas notas de parche bien escritas.** Dicen mucho de cómo trabajas.
- **La prueba de que las partidas viejas siguen cargando** tras tres versiones. Casi nadie lo hace, y se nota.
- Si en algún momento buscas empleo, este perfil encaja directo en [sistemas de gameplay](sistemas-gameplay.md) o [backend y online](backend-online.md): has hecho su trabajo, solo que sin el título.

## 📈 Progresión y dinero

1. **Primer juego publicado** — aprendizaje y reputación, rara vez ingresos que sostengan.
2. **Juego mantenido con actualizaciones** — la retención y las reseñas mejoran con el tiempo, y con ellas la cola de ventas.
3. **Segundo juego con audiencia previa** — el salto real: vender a quien ya te conoce cambia por completo los números.
4. **Micro-estudio o carrera híbrida** — contratar y coordinar, o combinar proyectos propios con empleo.

Realidad económica: el mayor multiplicador para un indie no es la calidad técnica, es **tener audiencia antes de lanzar**. Mantener un juego vivo y comunicarlo bien es, en la práctica, marketing sostenido que además mejora el producto. Sigue planificando con ingresos conservadores.

## ⚠️ Mitos y errores comunes

- **«Ya está publicado, ya está hecho.»** El primer día empieza la parte larga.
- **«Parcheo el balance y ya.»** Cambiar un dato que vive dentro de los guardados rompe partidas. Migra, siempre.
- **«Necesito analítica completa.»** Necesitas **tres preguntas concretas** y los eventos mínimos que las respondan, con consentimiento.
- **«Refactorizo todo antes de seguir.»** Refactoriza solo lo que te está frenando hoy. Lo demás es procrastinación con buena letra.
- **«Las pruebas son para equipos grandes.»** Al revés: en solitario nadie más va a notar lo que rompiste.
- **«Guardo la clave de firma en el proyecto.»** Nunca. Y guárdala fuera, en más de un sitio: perderla significa que tus usuarios tendrán que desinstalar y reinstalar.

## 🚀 Siguientes pasos

1. Añade **guardado versionado con migraciones** a tu juego publicado. Hoy, antes del siguiente parche.
2. Saca todo el contenido que puedas a **datos**. Mide cuánto tarda ahora añadir un objeto nuevo.
3. Monta una **CI mínima** que construya el juego y corra tus pruebas en cada commit.
4. Define **tres preguntas** que quieras responder con telemetría y registra solo eso, con consentimiento explícito.
5. Haz el 🧪 [lab de sistemas de gameplay](../labs/gameplay-systems/README.md) y lleva a tu juego los dos patrones que más te duelan.
6. Escribe un **plan de parches**: qué se puede cambiar en caliente, qué exige migración y qué no se tocará nunca.

---

- ⬅️ [Volver al índice de rutas](./README.md)
- 🏠 [Inicio del programa](../README.md)
