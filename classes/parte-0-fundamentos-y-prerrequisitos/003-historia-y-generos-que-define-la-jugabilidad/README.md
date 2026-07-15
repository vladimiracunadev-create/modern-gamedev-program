# Clase 003 — Historia y géneros: qué define la jugabilidad

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Steve Rabin (ed.), Introduction to Game Development*
> ⏱️ Duración estimada: **75 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Recorrer la evolución de los videojuegos y aprender a leer un juego por su género y su jugabilidad. Verás que un género no es una etiqueta de marketing, sino un conjunto de mecánicas núcleo y verbos del jugador que definen cómo se juega.

Esto importa porque, antes de programar, hay que saber qué se está construyendo. Identificar el core loop y los verbos de un juego es el primer paso de diseño de cualquier proyecto.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. **Ordenar** los grandes hitos de la historia de los videojuegos (arcade, consolas, 3D, indie, móvil, online).
2. **Clasificar** un juego en su género principal a partir de sus mecánicas.
3. **Identificar** los verbos del jugador de un juego dado.
4. **Describir** el core loop (bucle de juego) de un título concreto.
5. **Analizar** el bucle de recompensa que motiva a seguir jugando.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Evolución histórica | Explica de dónde vienen las convenciones actuales |
| 2 | Qué es un género | Da vocabulario para hablar de mecánicas |
| 3 | Géneros principales | Permite reconocer patrones de diseño probados |
| 4 | Mecánicas núcleo | Distingue lo esencial de lo accesorio |
| 5 | Verbos del jugador | Define qué puede hacer quien juega |
| 6 | Core loop | Muestra la actividad repetida que sostiene el juego |
| 7 | Bucle de recompensa | Explica por qué el jugador quiere continuar |

## 📖 Definiciones y características

- **Género**: familia de juegos con mecánicas comunes (plataformas, shooter, RPG…). Clave: agrupa por cómo se juega.
- **Mecánica núcleo (core mechanic)**: la acción central y repetida del juego. Clave: si la quitas, el juego deja de existir.
- **Verbo del jugador**: acción que el jugador ejecuta (saltar, disparar, construir). Clave: define la interacción.
- **Core loop (bucle de juego)**: secuencia corta de acciones que se repite constantemente. Clave: es el "latido" del juego.
- **Bucle de recompensa**: ciclo de esfuerzo → recompensa → progreso. Clave: motiva la continuidad.
- **Arcade**: era de máquinas de fichas, partidas cortas y dificultad creciente. Clave: "una moneda más".
- **Indie**: juegos de estudios pequeños o independientes. Clave: innovación con recursos limitados.
- **Roguelike**: género de niveles generados y muerte permanente. Clave: rejugabilidad por aleatoriedad.

## 🧰 Herramientas y preparación

No necesitas software especial: solo un editor de texto para completar plantillas y acceso a tres juegos que conozcas bien (pueden ser gratuitos, de navegador o clásicos). Como referencia teórica usa *Introduction to Game Development* editado por Steve Rabin. Para consultar historia y géneros con datos, la Wikipedia de videojuegos es un punto de partida verificable <https://es.wikipedia.org/wiki/Videojuego>. Este laboratorio es analítico: no hay código, pero sí un producto concreto (una tabla de análisis).

## 🧪 Laboratorio guiado

Analizarás tres juegos que juegues o conozcas, extrayendo su género, verbos, core loop y bucle de recompensa. El entregable es una tabla estructurada.

**Paso 1 — Elige tus tres juegos.** Deben ser de géneros distintos si es posible (por ejemplo: un plataformas, un shooter y un puzzle). Anótalos.

**Paso 2 — Identifica el género y su mecánica núcleo.** Para cada juego responde: ¿cuál es la acción que se repite todo el tiempo? Esa es la mecánica núcleo. Usa esta guía de géneros:

```text
Plataformas  -> saltar y moverse con precisión entre superficies
Shooter      -> apuntar y disparar a objetivos
RPG          -> progresar personaje, decisiones y combate por estadísticas
Estrategia   -> gestionar recursos y unidades para vencer
Puzzle       -> resolver problemas lógicos con reglas fijas
Roguelike    -> avanzar en niveles generados con muerte permanente
Sandbox      -> crear y experimentar sin objetivo impuesto
```

**Paso 3 — Lista los verbos del jugador.** Escribe en infinitivo las acciones que el jugador realiza. Ejemplo para un plataformas: `correr, saltar, agacharse, recoger`.

**Paso 4 — Describe el core loop.** En una frase corta, la secuencia que se repite. Ejemplos:

```text
Plataformas: explorar -> esquivar peligro -> alcanzar meta -> siguiente nivel
Shooter:     detectar enemigo -> cubrirse -> disparar -> recargar -> avanzar
Puzzle:      observar tablero -> planear jugada -> ejecutar -> resolver -> nuevo reto
```

**Paso 5 — Analiza el bucle de recompensa.** ¿Qué gana el jugador al completar el core loop y por qué quiere repetirlo? (puntos, nuevas habilidades, historia, dificultad creciente).

**Paso 6 — Completa la tabla.** Usa esta plantilla en un archivo `analisis-juegos.md`:

```markdown
| Juego        | Género      | Mecánica núcleo        | Verbos                     | Core loop                              | Recompensa                 |
|--------------|-------------|------------------------|----------------------------|----------------------------------------|----------------------------|
| Ejemplo 2048 | Puzzle      | combinar números       | deslizar, combinar         | deslizar -> fusionar -> crece número   | récord y llegar a 2048     |
| (tu juego 1) | ...         | ...                    | ...                        | ...                                    | ...                        |
| (tu juego 2) | ...         | ...                    | ...                        | ...                                    | ...                        |
| (tu juego 3) | ...         | ...                    | ...                        | ...                                    | ...                        |
```

**Paso 7 — Reflexiona.** Escribe un párrafo: ¿qué tienen en común los tres core loops? ¿Cuál te resultó más difícil de reducir a una sola frase y por qué?

## ✍️ Ejercicios

1. Ubica en la línea de tiempo (arcade, consolas, 3D, indie, móvil, online) el momento en que apareció el género de uno de tus juegos.
2. Toma un juego famoso y reduce su core loop a exactamente una frase de cinco pasos como máximo.
3. Escribe cinco verbos del jugador para un juego de estrategia y cinco para uno de plataformas; compara.
4. Encuentra un juego que mezcle dos géneros y explica qué mecánica aporta cada uno.
5. Propón un pequeño cambio en la mecánica núcleo de uno de tus juegos y describe cómo alteraría la experiencia.
6. Identifica un juego cuyo bucle de recompensa sea principalmente narrativo en lugar de numérico.

## 📝 Reto verificable

Entrega `analisis-juegos.md` con la tabla completa de tres juegos (las seis columnas) más el párrafo de reflexión final.

**Criterio de aceptación**: la tabla contiene tres juegos reales con género correcto y consistente con su mecánica núcleo; cada fila tiene al menos tres verbos y un core loop expresado como secuencia de pasos; el párrafo de reflexión relaciona explícitamente los tres core loops.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Confundir género con temática | "Zombies" es tema, no género. Clasifica por mecánica (shooter, survival), no por ambientación. |
| Core loop demasiado largo | Incluyes eventos raros. Deja solo lo que se repite constantemente. |
| Verbos vagos ("jugar", "ganar") | No son acciones concretas. Usa verbos observables como saltar o disparar. |
| Mecánica núcleo mal elegida | Elegiste una acción secundaria. Pregúntate qué se hace el 80 % del tiempo. |
| Recompensa mal identificada | Confundes objetivo final con recompensa por ciclo. Describe qué se gana en cada vuelta del loop. |

## ❓ Preguntas frecuentes

**❓ ¿Un juego puede pertenecer a varios géneros?** Sí, muchos son híbridos (action-RPG, puzzle-plataformas). Identifica el género dominante y qué aporta cada uno.

**❓ ¿El core loop es lo mismo que la historia?** No. El core loop es la actividad repetida de segundos a minutos; la historia es la estructura de largo plazo. Ambos coexisten.

**❓ ¿Por qué estudiar historia si quiero programar?** Porque las convenciones actuales (vidas, checkpoints, HUD) nacieron en eras concretas. Conocerlas te da un repertorio de soluciones.

**❓ ¿Los verbos determinan el género?** En gran medida sí: un juego cuyo verbo central es "saltar con precisión" es un plataformas, sin importar su apariencia.

## 🔗 Referencias

- Steve Rabin (ed.), *Introduction to Game Development* — Cengage/Charles River Media
- Jesse Schell, *The Art of Game Design: A Book of Lenses* — <https://www.schellgames.com>
- Historia del videojuego (referencia general) — <https://es.wikipedia.org/wiki/Historia_de_los_videojuegos>

## ⬅️ Clase anterior

[Clase 002 - Anatomía de un videojuego: game loop, estado, tiempo y frames](../002-anatomia-de-un-videojuego-game-loop-estado-tiempo-y-frames/README.md)

## ➡️ Siguiente clase

[Clase 004 - Matemáticas para juegos I: vectores y álgebra lineal](../004-matematicas-para-juegos-i-vectores-y-algebra-lineal/README.md)
