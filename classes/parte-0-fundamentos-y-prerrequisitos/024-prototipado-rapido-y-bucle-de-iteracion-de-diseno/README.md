# Clase 024 — Prototipado rápido y bucle de iteración de diseño

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Tracy Fullerton, Game Design Workshop*
> ⏱️ Duración estimada: **85 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Ningún diseño de juego es divertido en el papel por primera vez: la diversión se **descubre** construyendo y probando. Por eso el prototipado rápido es la herramienta central del diseñador: convierte ideas en algo jugable en horas, no en meses, para responder pronto la única pregunta que importa: ¿esto se siente bien?

En esta clase aprenderás por qué prototipar temprano, la diferencia entre prototipos de papel y digitales, la técnica del **greyboxing** (formas primitivas sin arte), y el bucle **idea → construir → probar → aprender**. Verás cómo controlar el **scope** y evitar el *feature creep*, cómo aislar una sola mecánica como MVP y cómo medir el *game feel*. En el laboratorio construirás un **dash** configurable en Godot y registrarás variaciones de parámetros para decidir cuál se siente mejor.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar por qué se prototipa temprano y qué significa "encontrar la diversión".
2. Comparar prototipos de papel y digitales y elegir el adecuado según la pregunta.
3. Aplicar greyboxing para probar una mecánica sin depender del arte.
4. Ejecutar el bucle idea → construir → probar → aprender sobre una mecánica.
5. Registrar variaciones de parámetros y justificar cuál mejora el game feel.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Por qué prototipar | Encontrar la diversión antes de invertir. |
| 2 | Papel vs digital | Cada uno responde preguntas distintas. |
| 3 | Greyboxing | Probar mecánicas sin coste de arte. |
| 4 | Bucle de iteración | Idea → construir → probar → aprender. |
| 5 | Scope y feature creep | El enemigo silencioso de terminar. |
| 6 | MVP de una mecánica | Aislar lo mínimo jugable. |
| 7 | Game feel | Lo que hace que una acción sea satisfactoria. |

## 📖 Definiciones y características

- **Prototipo**: versión mínima construida para responder una pregunta de diseño. Clave: desechable, rápido, no bonito.
- **Prototipo de papel**: reglas y fichas físicas sin código. Clave: prueba sistemas y economías en minutos.
- **Greyboxing**: usar formas primitivas (cajas, círculos) en lugar de arte. Clave: separa mecánica de estética.
- **Bucle de iteración**: idea → construir → probar → aprender, repetido. Clave: el aprendizaje guía la siguiente idea.
- **Scope**: alcance de lo que se pretende construir. Clave: mantenerlo pequeño para terminar.
- **Feature creep**: añadir funciones no planeadas que inflan el proyecto. Clave: mata prototipos y agendas.
- **MVP**: producto mínimo viable; la mecánica aislada más pequeña que se puede probar. Clave: foco absoluto.
- **Game feel**: la sensación táctil de una acción (respuesta, peso, timing). Clave: se afina con parámetros, no con arte.

## 🧰 Herramientas y preparación

Trabajarás en **Godot 4** con **GDScript** y una escena 2D mínima. No necesitas arte: un `CharacterBody2D` con un `ColorRect` o `Sprite2D` de placeholder basta (greyboxing puro). Para el registro de iteraciones te sirve una tabla en Markdown o una hoja de cálculo. La referencia base es *Game Design Workshop* de Tracy Fullerton, en concreto sus capítulos sobre prototipado y el proceso iterativo (playtesting). Como apoyo conceptual sobre game feel, el trabajo de Steve Swink, *Game Feel*. El objetivo es construir algo jugable en 30-60 minutos y probar variaciones enseguida.

## 🧪 Laboratorio guiado

### Paso 1 — Escena mínima con greyboxing

Crea un `CharacterBody2D` con un `ColorRect` hijo (un rectángulo de color como cuerpo del jugador) y un `CollisionShape2D`. Sin arte: la caja de color es suficiente para sentir el movimiento.

### Paso 2 — Movimiento base

Adjunta un script y añade movimiento horizontal simple para tener contexto donde probar el dash:

```gdscript
extends CharacterBody2D

@export var speed := 240.0

func _physics_process(_delta: float) -> void:
	var dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * speed
	move_and_slide()
```

Ejecuta y comprueba que la caja se mueve con las flechas. Ya tienes el terreno para la mecánica.

### Paso 3 — Un dash configurable (el MVP de la mecánica)

Añade un dash con parámetros expuestos para poder ajustarlos sin tocar el código cada vez:

```gdscript
@export var dash_speed := 900.0     # fuerza del impulso
@export var dash_time := 0.15       # cuanto dura el dash
@export var dash_cooldown := 0.5    # espera entre dashes

var _dash_left := 0.0
var _cooldown_left := 0.0

func _physics_process(delta: float) -> void:
	_cooldown_left = max(0.0, _cooldown_left - delta)
	var dir := Input.get_axis("ui_left", "ui_right")

	if Input.is_action_just_pressed("ui_accept") and _cooldown_left == 0.0:
		_dash_left = dash_time
		_cooldown_left = dash_cooldown

	if _dash_left > 0.0:
		_dash_left -= delta
		velocity.x = sign(dir if dir != 0 else 1.0) * dash_speed
	else:
		velocity.x = dir * speed
	move_and_slide()
```

Los `@export` hacen que `dash_speed`, `dash_time` y `dash_cooldown` sean editables en el Inspector: puedes tunear el feel en caliente.

### Paso 4 — Iterar variaciones y sentir la diferencia

Ejecuta y prueba tres configuraciones distintas cambiando los valores en el Inspector (idea → construir → probar → aprender). Por ejemplo:

- A: `dash_speed=900, dash_time=0.15, cooldown=0.5` (ágil, controlado).
- B: `dash_speed=1400, dash_time=0.10, cooldown=0.3` (explosivo, arriesgado).
- C: `dash_speed=600, dash_time=0.25, cooldown=0.8` (pesado, lento).

Juega cada una unos segundos y anota qué sensación produce. Ese es el bucle: pequeño cambio, prueba inmediata, conclusión.

### Paso 5 — Registrar las iteraciones

Lleva un registro para no decidir de memoria. Plantilla de tabla:

| Iter | dash_speed | dash_time | cooldown | Sensación | ¿Mantener? |
|------|-----------|-----------|----------|-----------|-----------|
| A | 900 | 0.15 | 0.5 | Ágil y preciso | Sí, base |
| B | 1400 | 0.10 | 0.3 | Rápido pero descontrolado | No |
| C | 600 | 0.25 | 0.8 | Pesado, poco reactivo | No |

Elige la variación ganadora con argumentos ("A da control sin sentirse lento"). Así el game feel se decide con evidencia de juego, no con opiniones abstractas.

## ✍️ Ejercicios

1. Añade un cuarto set de parámetros y compáralo con la variación ganadora.
2. Agrega un pequeño *squash* visual (escala) durante el dash y evalúa si mejora el feel.
3. Prototipa en papel las reglas de una mecánica de puntuación y pruébala con un compañero.
4. Sustituye el dash por un salto configurable (`jump_force`, `gravity`) y registra tres iteraciones.
5. Escribe en dos líneas el MVP de tu idea de juego: una sola mecánica que probar.
6. Enumera dos features que quitarías de tu idea para reducir scope.

## 📝 Reto verificable

Construye en Godot, en menos de 60 minutos y con solo formas primitivas, el prototipo de una única mecánica (dash, salto, gancho o similar) con al menos tres parámetros expuestos como `@export`. Prueba un mínimo de cuatro configuraciones distintas y completa una tabla de registro de iteraciones con columnas de parámetros, sensación y decisión, terminando con la variación elegida y su justificación.

**Criterio de aceptación**: el prototipo es jugable con placeholders (sin arte); expone al menos tres parámetros ajustables desde el Inspector; y el registro documenta cuatro iteraciones con valores concretos y una conclusión razonada sobre cuál se siente mejor y por qué.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| El prototipo tarda días en estar listo | Añadiste arte y sistemas de más. Usa greyboxing y aísla una sola mecánica. |
| Cada prueba requiere editar y recompilar el código | Los parámetros están hardcodeados. Exponlos con `@export` y ajusta en el Inspector. |
| No sabes cuál variación era mejor | Iteraste de memoria. Lleva un registro con valores y sensaciones. |
| El proyecto crece sin terminar nunca | Feature creep. Define el MVP y congela el scope hasta probarlo. |
| El dash "no se siente" pese a los números | Falta feedback. Añade una señal visual (squash, estela) o de timing. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué prototipar antes de planear todo el juego?** Porque no se sabe si una idea es divertida hasta jugarla. Prototipar temprano evita construir durante meses algo que, al probarlo, resulta aburrido; es más barato descubrirlo en una tarde.

**❓ ¿Cuándo uso papel y cuándo digital?** El papel es ideal para reglas, economías y decisiones (juegos por turnos, sistemas). Lo digital es imprescindible para el game feel en tiempo real: timing, respuesta y física que el papel no captura.

**❓ ¿Qué es exactamente el greyboxing?** Construir con formas y bloques neutros en lugar de arte terminado. Permite probar la mecánica y el espacio sin invertir en gráficos que quizá descartes; separa "¿funciona?" de "¿se ve bien?".

**❓ ¿Cómo evito el feature creep?** Escribiendo el MVP antes de empezar y resistiendo cada idea nueva hasta que lo mínimo funcione y sea divertido. Anota las ideas extra en una lista aparte para después, no las metas en el prototipo actual.

## 🔗 Referencias

- Tracy Fullerton, *Game Design Workshop* (4.ª ed.), capítulos de prototipado y playtesting: <https://www.gamedesignworkshop.com/>
- Steve Swink, *Game Feel*: <http://www.game-feel.com/>
- Godot Docs, "GDScript exports (`@export`)": <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html>
- Godot Docs, "CharacterBody2D": <https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html>

## ⬅️ Clase anterior

[Clase 023 - Debugging y profiling: herramientas y mentalidad](../023-debugging-y-profiling-herramientas-y-mentalidad/README.md)

## ➡️ Siguiente clase

[Clase 025 - Metodología, gestión de proyectos y portfolio del desarrollador](../025-metodologia-gestion-de-proyectos-y-portfolio-del-desarrollador/README.md)
