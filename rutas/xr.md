# 🥽 Desarrollador XR (VR/AR)

> Un nicho pequeño, técnicamente exigente y con una regla que no se negocia: si baja de
> los fotogramas objetivo, alguien se marea. De verdad.
>
> **Nivel de entrada:** intermedio (exige 3D sólido) · **Foco:** presencia, confort y rendimiento · **Hito faro:** una experiencia XR mínima que se pueda probar sin malestar

## 🧭 Qué es y por qué importa

El desarrollador XR construye experiencias donde el jugador **está dentro**. Eso cambia todas las reglas: la cámara no la controlas tú, la interfaz vive en el espacio, la escala importa de verdad y el rendimiento deja de ser una cuestión de comodidad para ser una de salud.

Importa porque es la única área donde el confort del usuario es un requisito técnico duro. En un juego de pantalla, 45 fps es molesto; en un visor, es náusea. Ese límite reordena todo el trabajo: primero cumples el presupuesto de fotograma, luego haces el juego.

Hay que ser honesto sobre el mercado: es un nicho. Menos puestos que en móvil o gameplay, muy concentrados en unos pocos estudios, con formación empresarial y simulación como parte importante del empleo real (no todo son juegos). A cambio, la competencia es menor y la especialización se nota.

## 🗓️ Un día en el puesto

- **Ponerte el visor. Muchas veces.** No hay forma de evaluar XR sin probarlo, y probar cuesta minutos cada vez.
- **Perseguir el presupuesto de fotograma.** Renderizas dos ojos: cada milisegundo cuenta el doble.
- **Ajustar interacción:** agarrar, soltar, pulsar, apuntar. Lo que en pantalla es un clic, aquí es un problema de física y de expectativa.
- **Trabajar el confort:** locomoción (teletransporte frente a desplazamiento continuo), viñeteado, evitar mover la cámara del usuario nunca.
- **Diseñar UI espacial:** distancia cómoda de lectura, tamaño angular, qué sigue a la cabeza y qué se queda en el mundo.
- **Probar con gente ajena.** Tú te acostumbras; los demás no. El nuevo usuario es el detector de mareo.

## 🧠 Qué necesitas saber

### Conocimiento técnico

- **3D sólido, sin atajos.** Transformaciones, espacios y jerarquías. XR es 3D puro ([Parte 2](../classes/parte-2-desarrollo-3d-motores-escenas-y-transformaciones/README.md)).
- **Física e interacción creíble:** agarres, colisiones de manos, objetos que pesan ([Parte 3](../classes/parte-3-fisica-y-matematicas-de-juegos-aplicadas/README.md)).
- **Rendimiento antes que nada:** presupuesto de ~11 ms para dos ojos a 90 fps, foveated rendering, batching agresivo ([Parte 14](../classes/parte-14-optimizacion-profiling-y-rendimiento/README.md)).
- **Hardware XR:** visores, tipos de tracking, controles, límites de cada plataforma ([Parte 13](../classes/parte-13-vr-ar-y-experiencias-inmersivas/README.md)).
- **Confort y accesibilidad:** el catálogo de causas de mareo y sus mitigaciones. Es conocimiento específico y no se improvisa.
- **Audio espacial**, que aporta a la presencia tanto o más que el apartado visual ([Parte 6](../classes/parte-6-audio-y-musica-interactiva/README.md)).

### Herramientas del oficio

- **Godot 4 con OpenXR**, o Unity con XR Interaction Toolkit / Unreal.
- Un **visor real**. Es la única herramienta imprescindible: sin él no puedes trabajar en esto.
- Perfiladores específicos de la plataforma (por ejemplo los de Quest) y captura de fotograma.
- Un **espacio físico despejado** para probar. Suena a broma y no lo es.

### Habilidades no técnicas

- **Sensibilidad al confort ajeno.** Tu tolerancia no es la del usuario, y aumenta con la costumbre.
- **Disciplina de rendimiento.** Decir que no a un efecto porque cuesta 2 ms es el trabajo, no un obstáculo.
- **Diseño desde la presencia:** pensar en qué siente alguien que está ahí dentro, no en qué se ve.
- **Explicar límites.** Buena parte del rol es gestionar expectativas de quien nunca se ha puesto un visor.

## 📚 Tu ruta en el programa

1. 📚 [**Parte 0**](../classes/parte-0-fundamentos-y-prerrequisitos/README.md) (001–025) y 📚 [**Parte 1**](../classes/parte-1-motores-2d-y-tu-primer-juego-jugable/README.md) (026–045).
2. 📚 [**Parte 2 — 3D**](../classes/parte-2-desarrollo-3d-motores-escenas-y-transformaciones/README.md) (046–067). **Obligatorio**: XR es 3D puro, sin excepciones.
3. 📚 [**Parte 3 — Física**](../classes/parte-3-fisica-y-matematicas-de-juegos-aplicadas/README.md) (068–085). Interacción creíble con las manos.
4. 📚 [**Parte 14 — Optimización**](../classes/parte-14-optimizacion-profiling-y-rendimiento/README.md) (240–254). **Antes** de XR: los 90 fps no se negocian.
5. 📚 [**Parte 13 — VR/AR**](../classes/parte-13-vr-ar-y-experiencias-inmersivas/README.md) (228–239). **El núcleo de esta ruta.**
6. 🎯 **Hito**: una experiencia VR o AR mínima ([clase 239](../classes/parte-13-vr-ar-y-experiencias-inmersivas/239-capstone-parte-13-una-experiencia-vr-o-ar-minima/README.md)).
7. 📚 [**Parte 6 — Audio espacial**](../classes/parte-6-audio-y-musica-interactiva/README.md) (126–137) · 📚 [**Parte 17**](../classes/parte-17-capstones-y-preparacion-profesional-portfolio/README.md).

➡️ Cuando el cuello de botella deje de ser tu código y pase a ser el motor, continúa en [**Programador de motor / rendimiento**](motor-rendimiento.md) ([Parte 21](../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/README.md)).

## 🎓 Qué te contrata

- **Una experiencia probable en un visor concreto**, con su APK o build lista. En XR nadie contrata por capturas.
- **Un vídeo con grabación desde dentro** más una vista externa. Sin el vídeo no se entiende qué hiciste.
- **Datos de rendimiento**: fps sostenidos, tiempo de fotograma por ojo, en qué visor y a qué resolución.
- **Un apartado de confort:** qué opciones de locomoción ofreces y por qué elegiste esas. Es lo que distingue a un profesional de un entusiasta.

## 📈 Progresión de carrera y salario

1. **Junior XR developer** — implementas interacciones dentro de un framework ya montado.
2. **XR developer** — te haces cargo de la interacción, el confort y el presupuesto de fotograma.
3. **Senior** — defines la arquitectura de la experiencia y decides plataformas objetivo.
4. **Especialización:** simulación y formación empresarial (donde está buena parte del empleo estable), [rendimiento](motor-rendimiento.md) o dirección técnica.

Rangos **orientativos** (brutos anuales):

- **LATAM:** entrada aproximada USD 12.000–24.000; con experiencia USD 25.000–50.000+.
- **España:** entrada aproximada 22.000–30.000 €; senior 40.000–58.000 €+.
- **Remoto / USD:** seniors por encima de USD 85.000–120.000, con menos oferta que en otras rutas.

Nota de mercado: el sector XR ha vivido ciclos fuertes de expansión y contracción. Es prudente combinarlo con una base sólida de 3D general, que se traslada a cualquier otro puesto.

## ⚠️ Mitos y errores comunes

- **«Si funciona en pantalla, funciona en VR.»** No. Cambia la cámara, la interfaz, la escala y el presupuesto.
- **«Optimizo después.»** En XR, optimizar después significa rehacer. El presupuesto es el punto de partida.
- **«A mí no me marea.»** Te acostumbraste. Prueba con alguien que se lo ponga por primera vez.
- **«El teletransporte es de cobardes.»** Es una decisión de accesibilidad. Ofrece opciones, no dogmas.
- **«Mover la cámara del jugador para el efecto dramático.»** Nunca. Es la causa número uno de malestar.
- **«XR es solo juegos.»** Formación, simulación, salud e industria son una parte enorme del empleo real.

## 🚀 Siguientes pasos

1. Haz la **Parte 2** entera hasta que las transformaciones 3D te resulten evidentes. En XR no hay atajo por aquí.
2. Haz la **Parte 14** **antes** que la 13. Aprender XR sin saber optimizar es aprender a fallar.
3. Consigue acceso a un visor, aunque sea prestado, antes de empezar la **Parte 13**.
4. Construye una experiencia de **cinco minutos** con una sola interacción, muy pulida. Es lo que se enseña.
5. Ofrece **dos modos de locomoción** desde el principio y documenta por qué.
6. Haz que cinco personas distintas la prueben y anota, sin excusas, quién se sintió mal y cuándo.

---

- ⬅️ [Volver al índice de rutas](./README.md)
- 🏠 [Inicio del programa](../README.md)
