# Clase 001 — Qué es el desarrollo de videojuegos moderno: motores, disciplinas y pipeline

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Jason Gregory, Game Engine Architecture*
> ⏱️ Duración estimada: **90 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Comprender qué es realmente el desarrollo de videojuegos moderno: no un acto individual de "programar un juego", sino un sistema coordinado de disciplinas, herramientas y etapas. Al terminar sabrás qué es un motor, quién hace qué en un equipo y cómo fluye un proyecto desde la idea hasta el lanzamiento.

Esto importa porque cada decisión técnica que tomarás en el resto del curso (elegir motor, escribir el game loop, modelar assets) tiene sentido dentro de este mapa general. Sin el mapa, se trabaja a ciegas.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. **Definir** qué es un motor de videojuegos y enumerar sus subsistemas principales.
2. **Distinguir** las disciplinas de un equipo de desarrollo y la responsabilidad de cada una.
3. **Describir** las cuatro fases del pipeline de producción y qué se entrega en cada una.
4. **Comparar** al menos tres motores según criterios objetivos (licencia, lenguaje, target).
5. **Esbozar** el pipeline de una idea de juego propia identificando entregables por fase.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es un motor de videojuegos | Es la base técnica sobre la que se construye todo |
| 2 | Subsistemas de un motor | Explica qué resuelve el motor y qué debes resolver tú |
| 3 | Disciplinas del desarrollo | Define roles y evita esperar que "el programador haga todo" |
| 4 | Programación gameplay vs gráfica vs tools | Aclara hacia dónde especializarte |
| 5 | Pipeline de producción | Ordena el trabajo en fases con entregables claros |
| 6 | Panorama de motores actuales | Permite elegir la herramienta correcta por proyecto |
| 7 | Frameworks web y motores propios | Amplía opciones más allá de los grandes motores |
| 8 | Criterios para elegir motor | Convierte la elección en una decisión razonada |

## 📖 Definiciones y características

- **Motor de videojuegos (game engine)**: software reutilizable que provee subsistemas comunes (render, física, audio, input) para no reprogramarlos en cada juego. Clave: reutilización.
- **Subsistema**: módulo del motor con una responsabilidad (p. ej. renderizado). Clave: separación de responsabilidades.
- **Gameplay programming**: código de las reglas y mecánicas del juego. Clave: define qué se siente al jugar.
- **Graphics/engine programming**: código de bajo nivel (render, memoria, rendimiento). Clave: cómo se dibuja y corre.
- **Tools programming**: herramientas internas para artistas y diseñadores. Clave: multiplica la productividad del equipo.
- **Pipeline de producción**: flujo de fases desde la idea al lanzamiento. Clave: orden y entregables.
- **Vertical slice**: fragmento jugable con calidad final que demuestra la visión. Clave: prueba de concepto realista.
- **Asset pipeline**: proceso que convierte arte/audio de origen a formatos que el motor consume. Clave: automatización.

## 🧰 Herramientas y preparación

Para esta clase solo necesitas un navegador. Explorarás los sitios oficiales de los principales motores para formar tu propio criterio: Godot <https://godotengine.org>, Unity <https://unity.com>, Unreal Engine <https://www.unrealengine.com>. Como marco conceptual, la referencia canónica es *Game Engine Architecture* de Jason Gregory <https://www.gameenginebook.com>. Ten a mano una hoja de cálculo o un editor de texto plano para armar tus tablas.

## 🧪 Laboratorio guiado

En este laboratorio construirás tu propio mapa del ecosistema. No hay código ejecutable: el entregable es documentación estructurada que usarás como referencia el resto del curso.

**Paso 1 — Recorre los sitios oficiales.** Abre las tres páginas oficiales y localiza, para cada motor: lenguaje principal de scripting, licencia/costo, plataformas de exportación y un ejemplo de juego publicado. Anota las fuentes exactas.

**Paso 2 — Arma tu tabla comparativa.** Crea un archivo `comparativa-motores.md` y completa esta plantilla con lo que investigaste:

```markdown
| Motor  | Lenguaje       | Licencia          | Targets                     | 2D/3D | Curva |
|--------|----------------|-------------------|-----------------------------|-------|-------|
| Godot  | GDScript/C#    | MIT (libre)       | PC, móvil, web, consolas*   | Ambos | Baja  |
| Unity  | C#             | Gratis con límites| PC, móvil, web, consolas    | Ambos | Media |
| Unreal | C++/Blueprints | Royalty por ingr. | PC, consolas, móvil         | 3D+   | Alta  |
```

*Nota: verifica en la fuente oficial los detalles de consolas y licencias, pues cambian con el tiempo.*

**Paso 3 — Identifica los subsistemas.** Para un juego de plataformas 2D sencillo, lista qué subsistemas del motor usarías y cuáles NO necesitarías (por ejemplo: render 2D sí, física de fluidos no).

```markdown
## Subsistemas para "plataformas 2D"
- Render 2D: SÍ (sprites, cámara)
- Física 2D: SÍ (colisiones, gravedad)
- Audio: SÍ (música, efectos)
- Networking: NO (juego local)
- IA de pathfinding 3D: NO
```

**Paso 4 — Esboza tu pipeline.** Toma una idea de juego propia (una frase basta) y descríbela por fases:

```markdown
## Idea: "Robot recolector en una fábrica abandonada"

### Preproducción
- Documento de una página (pitch), prototipo de movimiento en papel/gris.
- Entregable: prototipo jugable "greybox" del salto y recolección.

### Producción
- Arte final, 10 niveles, sistema de enemigos, audio.
- Entregable: vertical slice del nivel 1 con calidad final.

### Pulido
- Ajuste de dificultad, corrección de bugs, optimización de FPS.
- Entregable: build candidata sin bloqueantes.

### Lanzamiento
- Página de tienda, tráiler, build final firmada.
- Entregable: versión 1.0 publicada.
```

**Paso 5 — Justifica tu elección.** En dos o tres frases, escribe qué motor elegirías para tu idea y por qué, citando al menos dos criterios de tu tabla del Paso 2.

## ✍️ Ejercicios

1. Define con tus palabras la diferencia entre gameplay programming y tools programming, con un ejemplo de cada uno.
2. Enumera cinco subsistemas de un motor y describe en una línea qué resuelve cada uno.
3. Elige un juego que conozcas e identifica en qué fase del pipeline estuvo el trabajo de "balancear la dificultad".
4. Investiga y añade un cuarto motor o framework (por ejemplo Bevy, LÖVE o Phaser) a tu tabla comparativa.
5. Escribe qué disciplina te interesa más y por qué, en un párrafo.
6. Explica por qué un motor propio ("in-house") puede convenir a un estudio grande y no a uno pequeño.

## 📝 Reto verificable

Entrega un documento `mapa-del-proyecto.md` que contenga: (a) tu tabla comparativa de al menos tres motores con las seis columnas, (b) la lista de subsistemas necesarios/no necesarios para una idea concreta, y (c) el pipeline por fases de esa idea con un entregable por fase.

**Criterio de aceptación**: el documento incluye las tres partes, la tabla tiene ≥3 motores con datos verificables citando su fuente oficial, y el pipeline nombra explícitamente las cuatro fases (preproducción, producción, pulido, lanzamiento) con un entregable cada una.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| "Elegí Unreal para mi primer juego 2D y me abruma" | Motor sobredimensionado para el objetivo. Ajusta el motor al alcance real del proyecto. |
| Copiar datos de licencia sin verificar | Las licencias cambian. Cita siempre la página oficial y su fecha de consulta. |
| Confundir motor con framework | Un framework (Phaser, LÖVE) da librerías, no un editor completo. Distínguelos en la tabla. |
| Saltarse la preproducción | Empezar a producir sin prototipo genera retrabajo. Exige un prototipo antes de producir. |
| Creer que un rol hace todo | Reparte responsabilidades; hasta en equipos de una persona conviene separar "sombreros". |

## ❓ Preguntas frecuentes

**❓ ¿Necesito un motor para hacer un juego?** No es obligatorio, pero reprogramar render, física y audio desde cero es lento. Un motor te deja concentrarte en el juego.

**❓ ¿Cuál es el mejor motor?** No existe uno absoluto. El mejor es el que encaja con tu proyecto, tu equipo y tu experiencia; por eso comparamos con criterios.

**❓ ¿Godot es suficiente para un juego comercial?** Sí. Se han publicado juegos comerciales con Godot. La calidad depende más del equipo que del motor.

**❓ ¿Qué disciplina debería aprender primero?** Empieza por gameplay programming: es la que conecta directamente con "hacer que el juego se sienta jugable", que es el foco de este curso.

## 🔗 Referencias

- Jason Gregory, *Game Engine Architecture*, 3rd ed. — <https://www.gameenginebook.com>
- Documentación oficial de Godot — <https://docs.godotengine.org>
- Unity Manual — <https://docs.unity3d.com/Manual/index.html>
- Unreal Engine Documentation — <https://docs.unrealengine.com>

## ➡️ Siguiente clase

[Clase 002 - Anatomía de un videojuego: game loop, estado, tiempo y frames](../002-anatomia-de-un-videojuego-game-loop-estado-tiempo-y-frames/README.md)
