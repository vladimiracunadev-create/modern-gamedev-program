# Parte 1 — Motores 2D y tu primer juego jugable

> [⬅️ Volver al programa](../../README.md) · [📚 Índice completo](../README.md) · [⏮️ Parte anterior](../parte-0-fundamentos-y-prerrequisitos/README.md)

**20 clases** · rango 026–045 · De un sprite en pantalla a un **plataformas 2D completo y jugable** con Godot 4

**Fuentes de referencia de esta parte:**

- Documentación oficial de [Godot Engine 4.x](https://docs.godotengine.org/en/stable/).
- Robert Nystrom, *Game Programming Patterns* — máquina de estados, componentes y game loop.
- Steve Rabin (ed.), *Introduction to Game Development* (2ª ed.) — sistemas 2D.
- GDC talks sobre *game feel* y *juice* (Jan Willem Nijman, *The Art of Screenshake*).
- Steve Swink, *Game Feel: A Game Designer's Guide to Virtual Sensation*.

---

## 🎯 ¿De qué trata esta parte?

Aquí dejas de leer sobre juegos y **haces uno**. Partiendo de los fundamentos de la Parte 0, esta parte te lleva paso a paso por Godot 4 —el motor 2D open source más usado hoy— hasta terminar con un **plataformas 2D completo y jugable**: un personaje que corre y salta con buen tacto, enemigos que patrullan y persiguen, un nivel construido con tilemaps, monedas que recoger, vida y daño, un HUD, menús con pausa, sonido, partículas, guardado de progreso y un ejecutable que puedes compartir.

El hilo es **incremental**: cada clase añade una pieza al mismo proyecto. Empezamos por la anatomía de un motor 2D (escenas, nodos, el árbol) y el primer sprite; seguimos con el game loop real, el input, y un movimiento de personaje con *game feel* (aceleración, coyote time, salto variable). Luego llegan animación, cámara, colisiones y física, tilemaps, una máquina de estados limpia para el jugador, enemigos con IA básica, combate, UI, audio, *juice* y persistencia. Cerramos exportando a Windows y web, y con un **capstone** que integra todo en un juego terminado.

Aunque usamos Godot como motor principal (gratis, ligero y moderno), cada concepto —nodo/escena, señal, cuerpo cinemático, capa de colisión— tiene su equivalente directo en Unity y Unreal, que señalamos para que el conocimiento sea transferible.

## 🧩 Problemas que resuelve

- No saber por dónde empezar un juego real más allá de tutoriales sueltos que no se conectan.
- Personajes que se mueven "raro": sin peso, sin control fino, con saltos que se sienten mal.
- Colisiones que fallan, atraviesan paredes o se enganchan en esquinas.
- Código de gameplay que se convierte en un `if` gigante imposible de mantener (lo resolvemos con una máquina de estados).
- Enemigos que no reaccionan, niveles imposibles de editar, UI que no se actualiza.
- Juegos que se sienten "secos" por falta de *juice* (partículas, screenshake, sonido, feedback).
- No poder compartir tu juego porque nunca aprendiste a exportarlo.

## 🎓 Resultados de aprendizaje

Al terminar la parte, el alumno podrá:

- Estructurar un juego en Godot con escenas, nodos, señales y scripts organizados.
- Programar un controlador de personaje 2D con tacto profesional (aceleración, coyote time, salto variable).
- Animar sprites, seguir al jugador con una cámara y aplicar screenshake.
- Usar el sistema de colisiones y física 2D: cuerpos, áreas, capas y máscaras.
- Construir niveles con tilemaps y una máquina de estados limpia para el jugador.
- Implementar enemigos con IA básica, combate, salud, daño, recolectables y HUD.
- Añadir menús, pausa, sonido, música, partículas y guardado de progreso.
- Exportar el juego a un ejecutable de Windows y a la web (HTML5), y publicarlo.

## 🧱 Prerrequisitos

- Haber cubierto la [Parte 0](../parte-0-fundamentos-y-prerrequisitos/README.md), en especial: game loop (002), vectores (004), delta time (022), programación (008–010) y el entorno montado (016).
- Godot 4.x instalado (clase 016). No se necesita nada de pago.
- Ganas de iterar: un buen *game feel* se consigue ajustando y probando muchas veces.

## 📚 Las 20 clases

| # | Clase |
|---|---|
| 026 | [Anatomía de un motor 2D: escenas, nodos y árbol](026-anatomia-de-un-motor-2d-escenas-nodos-y-arbol/README.md) |
| 027 | [Godot: interfaz, proyecto y primer sprite en pantalla](027-godot-interfaz-proyecto-y-primer-sprite-en-pantalla/README.md) |
| 028 | [El game loop en la práctica: _process, _physics_process y señales](028-el-game-loop-en-la-practica-process-physics-process-y-senales/README.md) |
| 029 | [Input: teclado, ratón, gamepad y mapeo de acciones](029-input-teclado-raton-gamepad-y-mapeo-de-acciones/README.md) |
| 030 | [Movimiento de personaje 2D: velocidad, aceleración y control](030-movimiento-de-personaje-2d-velocidad-aceleracion-y-control/README.md) |
| 031 | [Sprites, animación por frames y AnimationPlayer](031-sprites-animacion-por-frames-y-animationplayer/README.md) |
| 032 | [Cámaras 2D: seguimiento, límites y screen shake](032-camaras-2d-seguimiento-limites-y-screen-shake/README.md) |
| 033 | [Colisiones 2D: cuerpos, áreas y capas](033-colisiones-2d-cuerpos-areas-y-capas/README.md) |
| 034 | [Física 2D: RigidBody, gravedad y plataformas](034-fisica-2d-rigidbody-gravedad-y-plataformas/README.md) |
| 035 | [Tilemaps y diseño de niveles 2D](035-tilemaps-y-diseno-de-niveles-2d/README.md) |
| 036 | [Máquina de estados del jugador: idle, run, jump, fall](036-maquina-de-estados-del-jugador-idle-run-jump-fall/README.md) |
| 037 | [Enemigos e IA básica 2D: patrullas y persecución](037-enemigos-e-ia-basica-2d-patrullas-y-persecucion/README.md) |
| 038 | [Salud, daño y combate 2D](038-salud-dano-y-combate-2d/README.md) |
| 039 | [Recolectables, puntuación y HUD](039-recolectables-puntuacion-y-hud/README.md) |
| 040 | [Menús, pausa y flujo de escenas](040-menus-pausa-y-flujo-de-escenas/README.md) |
| 041 | [Sonido y música en 2D: efectos y bucle musical](041-sonido-y-musica-en-2d-efectos-y-bucle-musical/README.md) |
| 042 | [Partículas y feedback visual (juice)](042-particulas-y-feedback-visual-juice/README.md) |
| 043 | [Guardado y carga de progreso](043-guardado-y-carga-de-progreso/README.md) |
| 044 | [Empaquetado y exportación del juego 2D (Windows y web)](044-empaquetado-y-exportacion-del-juego-2d-windows-y-web/README.md) |
| 045 | [Capstone Parte 1: un plataformas 2D completo jugable](045-capstone-parte-1-un-plataformas-2d-completo-jugable/README.md) |

---

> Al terminar la Parte 1 tendrás **tu primer juego completo y publicable**. La Parte 2 dará el salto a las tres dimensiones: escenas 3D, cámaras, transformaciones y un controlador en tercera persona.
