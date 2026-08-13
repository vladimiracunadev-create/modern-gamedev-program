# 🎮 Programador de gameplay

> Haces que el juego **se sienta** bien. No lo que hace, sino cómo responde: el salto,
> el golpe, la cámara, ese medio segundo entre pulsar y que pase algo.
>
> **Nivel de entrada:** inicial-intermedio · **Foco:** sensación y respuesta · **Hito faro:** un juego propio jugable y exportado

## 🧭 Qué es y por qué importa

El programador de gameplay implementa las reglas y, sobre todo, la **respuesta** del juego: movimiento, cámara, combate, controles, interacción. Es el rol que traduce «el salto se siente flotante» en un cambio concreto de gravedad ascendente y descendente, tiempo de coyote y buffer de entrada.

Importa porque es lo primero que juzga un jugador y lo último que se puede arreglar con arte. Un juego precioso con un control impreciso se abandona en cinco minutos; uno feo con un control excelente se juega horas. La diferencia rara vez está en una idea genial: está en decenas de ajustes pequeños que solo aparecen jugando tu propio juego una y otra vez.

Conviene decirlo pronto: es el rol **más demandado** de la industria y también el que más se subestima. Se parece poco a «programar»: se parece a afinar un instrumento. Escribes cien líneas, las juegas, cambias tres números, las vuelves a jugar. Si esa iteración te aburre, este no es tu sitio.

## 🗓️ Un día en el puesto

- **Revisar la lista de feedback.** De diseño, de QA o de un playtest: «el enemigo se siente injusto», «no sé cuándo puedo esquivar». Traducir esas frases a causas técnicas es la mitad del trabajo.
- **Implementar o ajustar una mecánica.** Casi nunca desde cero: casi siempre encima de algo que ya existe y que otros tocan a la vez.
- **Jugar lo que acabas de escribir.** Muchas veces. Un programador de gameplay que no juega su código entrega números plausibles y sensaciones malas.
- **Ajustar valores con diseño.** Velocidades, tiempos de recuperación, ventanas de invulnerabilidad. Lo ideal es exponerlos como datos para que diseño los toque sin ti.
- **Arreglar bugs de interacción.** Los peores del oficio: el que solo pasa si saltas mientras el ascensor baja y estás recibiendo daño.
- **Revisar código ajeno.** Gameplay es la zona donde más manos se cruzan, y donde peor envejece el código.

Trabajo muy iterativo, con mucho contacto con diseño y arte, y con la satisfacción inmediata de ver lo que haces en pantalla. También con la frustración de cambiar treinta veces algo que «ya funcionaba».

## 🧠 Qué necesitas saber

### Conocimiento técnico

- **Vectores y transformaciones**, sin miedo. Producto punto para saber si algo está delante, interpolación para suavizar, ángulos para apuntar. Es el idioma del oficio ([Parte 0](../classes/parte-0-fundamentos-y-prerrequisitos/README.md)).
- **El game loop y `delta`.** Por qué `_process` y `_physics_process` no son intercambiables, y por qué multiplicar por delta no es una superstición.
- **Detección y respuesta a colisiones**, incluida la diferencia entre lo que el motor resuelve y lo que resuelves tú.
- **Máquinas de estados** para el personaje. Casi todo controlador que crece sin ellas acaba en una montaña de booleanos contradictorios.
- **Game feel**: coyote time, buffer de entrada, tiempo de impacto, sacudida de cámara, curvas de aceleración. Todo lo que el jugador nota sin poder nombrar.
- **Cámaras**, que son la mitad de la sensación de un juego 3D y casi nadie lo cree hasta que le toca.

### Herramientas del oficio

- **Godot 4** como motor principal del programa, y **Unity/Unreal** como los que encontrarás en estudios.
- El **profiler** del motor: no para optimizar todavía, sino para saber qué cuesta lo que escribes.
- **Git**, y en serio ([clase 015](../classes/parte-0-fundamentos-y-prerrequisitos/015-git-y-control-de-versiones-para-proyectos-de-juegos-con-lfs/README.md)): gameplay es donde más conflictos de merge se producen.
- Un **mando**. Muchos problemas de control solo se notan con uno en la mano.

### Habilidades no técnicas

- **Saber jugar con criterio.** Distinguir «no me gusta» de «esto está mal» y explicar por qué.
- **Aceptar feedback sin defender el código.** Si el salto se siente mal, se siente mal, por elegante que sea tu implementación.
- **Comunicarte con diseño.** Traducir intenciones en parámetros y devolver alternativas cuando lo pedido no funciona.
- **Paciencia con la iteración.** El buen game feel es un proceso de pulido, no un acierto.

## 📚 Tu ruta en el programa

1. 📚 [**Parte 0 — Fundamentos**](../classes/parte-0-fundamentos-y-prerrequisitos/README.md) (001–025). Vectores, game loop, POO y patrones. No lo saltes: todo lo demás lo asume.
2. 📚 [**Parte 1 — Motores 2D**](../classes/parte-1-motores-2d-y-tu-primer-juego-jugable/README.md) (026–045), con el 🧪 [lab de plataformas 2D](../labs/plataformas-2d/README.md). Aquí construyes tu primer juego completo.
3. 🎯 **Hito**: un plataformas propio con buen game feel, exportado y jugable.
4. 📚 [**Parte 2 — 3D**](../classes/parte-2-desarrollo-3d-motores-escenas-y-transformaciones/README.md) (046–067) con el 🧪 [lab 3D](../labs/3d-tercera-persona/README.md). Control relativo a cámara y `SpringArm3D`.
5. 📚 [**Parte 3 — Física aplicada**](../classes/parte-3-fisica-y-matematicas-de-juegos-aplicadas/README.md) (068–085). Colisiones, steering y easing.
6. 📚 [**Parte 5 — IA de juegos**](../classes/parte-5-inteligencia-artificial-para-juegos/README.md) (108–125) con el 🧪 [lab de IA](../labs/ia-enemigo/README.md). Un enemigo que decide es gameplay tanto como el jugador.
7. 📚 [**Parte 8 — Game design**](../classes/parte-8-game-design-y-diseno-de-niveles/README.md) (156–171). Para entender *por qué* te piden lo que te piden.
8. 📚 [**Parte 14 — Optimización**](../classes/parte-14-optimizacion-profiling-y-rendimiento/README.md) (240–254) y [**Parte 17 — Capstone**](../classes/parte-17-capstones-y-preparacion-profesional-portfolio/README.md).

➡️ Cuando tu juego crezca hasta necesitar inventario, stats, habilidades y quests, continúa en [**Programador de sistemas de gameplay**](sistemas-gameplay.md).

## 🎓 Qué te contrata

En esta industria no hay certificaciones que valgan: **te contrata lo que has hecho**.

- **Un juego jugable, terminado y publicado.** Uno pequeño y pulido vale más que tres prototipos ambiciosos a medias.
- **Un vídeo de 30 segundos** que muestre el control en movimiento. Nadie va a instalar tu build en la primera criba.
- **El código público**, ordenado y legible. En gameplay, tu código lo tocarán otros: se nota enseguida si escribes pensando en ellos.
- **Un desglose de game feel**: qué probaste, qué descartaste y por qué. Demuestra criterio, que es lo que separa a un junior de un senior.

## 📈 Progresión de carrera y salario

1. **Junior gameplay programmer** — implementas tareas acotadas dentro de sistemas que ya existen.
2. **Gameplay programmer** — te haces cargo de una mecánica o de un personaje de principio a fin.
3. **Senior** — decides arquitectura de sistemas de gameplay, mentorizas y hablas de tú a tú con diseño.
4. **Especialización o liderazgo:** [sistemas de gameplay](sistemas-gameplay.md), [motor/rendimiento](motor-rendimiento.md), lead de gameplay o [arquitecto técnico](arquitecto-tecnico.md).

Rangos **orientativos** (brutos anuales; varían enormemente por país, tamaño de estudio e inglés):

- **LATAM:** entrada aproximada USD 10.000–22.000; con experiencia USD 22.000–45.000+.
- **España:** entrada aproximada 20.000–28.000 €; senior 38.000–55.000 €+.
- **Remoto / USD (estudios de EE. UU./Europa):** seniors por encima de USD 80.000–110.000, con competencia global.

Aviso honesto del sector: los videojuegos pagan **por debajo** del software empresarial equivalente y tienen ciclos de despidos duros. Se entra por vocación, y conviene saberlo antes, no después.

## ⚠️ Mitos y errores comunes

- **«Programar juegos es como programar cualquier cosa.»** Casi: lo que cambia es que el criterio de éxito es una sensación, no una salida correcta.
- **«El game feel se arregla al final.»** No. Si el control base está mal, todo lo que construyas encima hereda el problema.
- **«Necesito hacer mi propio motor.»** No para este rol. Aprende uno bien; el motor propio es otro oficio ([Parte 21](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/README.md)).
- **«Con que funcione basta.»** Gameplay es el código que más manos toca y más cambia. El que no se puede leer se acaba reescribiendo.
- **«Hay que optimizar desde el principio.»** Primero que se sienta bien; luego mide ([Parte 14](../classes/parte-14-optimizacion-profiling-y-rendimiento/README.md)). Al revés se pierde el tiempo y la sensación.
- **«Mi portfolio son diez prototipos.»** Diez cosas empezadas dicen que no sabes terminar. Una terminada dice lo contrario.

## 🚀 Siguientes pasos

1. Haz la **Parte 0** entera aunque te pique la impaciencia. Los vectores vuelven en cada clase posterior.
2. Completa el 🧪 [lab de plataformas 2D](../labs/plataformas-2d/README.md) desde `inicio/` sin mirar la solución hasta atascarte de verdad.
3. Coge tu plataformas y **dedícale una semana solo a game feel**. Anota cada cambio y su efecto: ese documento es material de portfolio.
4. Publícalo en itch.io. Terminar y publicar enseña cosas que ningún tutorial cubre.
5. Repite en 3D con el 🧪 [lab 3D](../labs/3d-tercera-persona/README.md) y compara qué cambia y qué no.
6. Cuando el proyecto te pida inventario o progresión, salta a [sistemas de gameplay](sistemas-gameplay.md).

---

- ⬅️ [Volver al índice de rutas](./README.md)
- 🏠 [Inicio del programa](../README.md)
