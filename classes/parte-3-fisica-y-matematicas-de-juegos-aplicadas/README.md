# Parte 3 — Física y matemáticas de juegos aplicadas

> [⬅️ Volver al programa](../../README.md) · [📚 Índice completo](../README.md) · [⏮️ Parte anterior](../parte-2-desarrollo-3d-motores-escenas-y-transformaciones/README.md) · [⏭️ Parte siguiente](../parte-4-graficos-shaders-y-rendering-moderno/README.md)

**18 clases** · rango 068–085 · Las matemáticas y la física que hacen creíble un juego: cuaterniones, colisiones, respuesta a impulsos, joints, ragdolls, vehículos, proyectiles, curvas, easing y steering

**Fuentes de referencia de esta parte:**

- Ian Millington, *Game Physics Engine Development* (2ª ed., CRC Press).
- Christer Ericson, *Real-Time Collision Detection* (Morgan Kaufmann).
- Eric Lengyel, *Mathematics for 3D Game Programming and Computer Graphics*.
- Glenn Fiedler, *Gaffer On Games* (serie de artículos sobre física y networking).

---

## 🎯 ¿De qué trata esta parte?

Los motores traen física integrada, pero para hacer un juego que se sienta bien —proyectiles que aciertan, coches que se controlan, personajes que reaccionan a los golpes— hay que entender qué ocurre por debajo. Esta parte toma las matemáticas de la Parte 0 y las aplica a problemas reales de física de juegos: cómo se representan y componen las rotaciones en 3D con **cuaterniones** (y por qué evitan el *gimbal lock*), cómo se detectan y resuelven **colisiones** (AABB, esferas, SAT, impulsos y restitución), y cómo la fricción, el arrastre y la amortiguación dan peso al movimiento.

Después construimos sistemas concretos: **joints** y restricciones, **ragdolls**, física de **vehículos**, **proyectiles** con balística y predicción, movimiento a lo largo de **curvas** (Bézier, splines), **interpolación y easing** para transiciones suaves, y **steering behaviors** (seek, flee, arrive, wander) que son la base del movimiento de agentes. Cerramos con determinismo y física de paso fijo (clave para multijugador y replays) y un **capstone** de física jugable.

## 🧩 Problemas que resuelve

- Rotaciones 3D que "saltan" o se bloquean (gimbal lock) por usar ángulos de Euler mal.
- Colisiones que atraviesan objetos rápidos (tunneling) o rebotan de forma poco natural.
- Movimiento sin peso: todo acelera y frena de golpe, sin inercia ni amortiguación.
- Vehículos incontrolables, ragdolls que explotan, proyectiles que no aciertan a blancos móviles.
- Transiciones bruscas por no usar interpolación ni curvas de easing.
- Física que "corre distinto" en cada PC o partida por no ser determinista.

## 🎓 Resultados de aprendizaje

Al terminar la parte, el alumno podrá:

- Usar cuaterniones para rotaciones 3D estables y componerlas correctamente.
- Implementar detección y respuesta de colisiones con impulsos y restitución.
- Modelar fricción, arrastre y amortiguación para dar peso al movimiento.
- Construir joints, ragdolls, vehículos y sistemas de proyectiles.
- Mover objetos a lo largo de curvas y aplicar interpolación y easing.
- Programar steering behaviors reutilizables para agentes.
- Diseñar una simulación determinista de paso fijo apta para multijugador/replays.

## 🧱 Prerrequisitos

- Partes 0, 1 y 2 (vectores, matrices, integración numérica, física 2D/3D del motor).
- Soltura con vectores y transformaciones; ganas de razonar con matemáticas aplicadas.
- Godot 4.x (los laboratorios usan su motor de física 2D/3D y GDScript).

## 📚 Las 18 clases

| # | Clase |
|---|---|
| 068 | [Repaso aplicado: vectores y transformaciones en el motor](068-repaso-aplicado-vectores-y-transformaciones-en-el-motor/README.md) |
| 069 | [Cuaterniones: rotaciones 3D sin gimbal lock](069-cuaterniones-rotaciones-3d-sin-gimbal-lock/README.md) |
| 070 | [Integración numérica en la práctica (Euler y Verlet)](070-integracion-numerica-en-la-practica-euler-y-verlet/README.md) |
| 071 | [Detección de colisiones: AABB, esferas y SAT](071-deteccion-de-colisiones-aabb-esferas-y-sat/README.md) |
| 072 | [Respuesta a colisiones: impulsos y restitución](072-respuesta-a-colisiones-impulsos-y-restitucion/README.md) |
| 073 | [Fricción, arrastre y amortiguación](073-friccion-arrastre-y-amortiguacion/README.md) |
| 074 | [Raycasts y shapecasts: usos avanzados](074-raycasts-y-shapecasts-usos-avanzados/README.md) |
| 075 | [Motores de física: broadphase y narrowphase](075-motores-de-fisica-broadphase-y-narrowphase/README.md) |
| 076 | [Juntas y restricciones (joints): bisagras y resortes](076-juntas-y-restricciones-joints-bisagras-y-resortes/README.md) |
| 077 | [Ragdolls y física de personajes](077-ragdolls-y-fisica-de-personajes/README.md) |
| 078 | [Vehículos: física de ruedas y suspensión](078-vehiculos-fisica-de-ruedas-y-suspension/README.md) |
| 079 | [Proyectiles: balística, gravedad y predicción](079-proyectiles-balistica-gravedad-y-prediccion/README.md) |
| 080 | [Movimiento con curvas: Bézier, splines y paths](080-movimiento-con-curvas-bezier-splines-y-paths/README.md) |
| 081 | [Interpolación y easing (lerp, slerp y tweens)](081-interpolacion-y-easing-lerp-slerp-y-tweens/README.md) |
| 082 | [Steering behaviors: seek, flee, arrive y wander](082-steering-behaviors-seek-flee-arrive-y-wander/README.md) |
| 083 | [Física de partículas y telas (soft bodies)](083-fisica-de-particulas-y-telas-soft-bodies/README.md) |
| 084 | [Determinismo y física fija para multijugador](084-determinismo-y-fisica-fija-para-multijugador/README.md) |
| 085 | [Capstone Parte 3: un mini-juego de física](085-capstone-parte-3-un-mini-juego-de-fisica/README.md) |

---

> Con la física dominada, la [Parte 4](../parte-4-graficos-shaders-y-rendering-moderno/README.md) entra en lo visual: el pipeline de render, shaders y post-procesado modernos.
