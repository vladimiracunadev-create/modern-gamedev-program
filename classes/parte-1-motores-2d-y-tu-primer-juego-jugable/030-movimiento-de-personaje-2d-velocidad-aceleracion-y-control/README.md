# Clase 030 — Movimiento de personaje 2D: velocidad, aceleración y control

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4 (CharacterBody2D, 2D movement)*
> ⏱️ Duración estimada: **95 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Construir un controlador de plataformas 2D con **buen tacto** (game feel) usando `CharacterBody2D` en Godot 4. Pasaremos de un movimiento rígido a uno con aceleración y desaceleración mediante `move_toward`, gravedad basada en `delta`, salto con `velocity.y` negativa y refinamientos como el salto variable, el *coyote time* y el *jump buffer*.

Al terminar tendrás un personaje que corre y salta con sensación profesional, listo para recibir animaciones en la clase 031. Todo el código está tipado, comentado y usa la API correcta de Godot 4 (`velocity`, `move_and_slide()` sin argumentos, `is_on_floor()`).

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Configurar un `CharacterBody2D` con colisionador para un plataformas 2D.
2. Aplicar aceleración y desaceleración horizontales con `move_toward`.
3. Implementar gravedad y salto usando `velocity` y `move_and_slide()`.
4. Programar salto variable cortando el impulso al soltar el botón.
5. Añadir coyote time y jump buffer para mejorar el tacto del salto.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | CharacterBody2D | Cuerpo pensado para control manual del personaje. |
| 2 | `velocity` y `move_and_slide()` | Núcleo del movimiento en Godot 4. |
| 3 | Aceleración con `move_toward` | Da peso y control fino al personaje. |
| 4 | Gravedad con delta | Caída estable e independiente de FPS. |
| 5 | Salto con velocity.y | Impulso vertical controlado. |
| 6 | Salto variable | Altura según cuánto mantienes el botón. |
| 7 | Coyote time | Perdona saltos justo tras salir del borde. |
| 8 | Jump buffer | Recuerda el salto pulsado un instante antes. |

## 📖 Definiciones y características

- **CharacterBody2D**: cuerpo cinemático que mueves por código. Clave: expone `velocity` y no lo empuja la física automáticamente.
- **`velocity`**: `Vector2` con la velocidad deseada del cuerpo. Clave: la modificas y luego llamas a `move_and_slide()`.
- **`move_and_slide()`**: mueve el cuerpo usando `velocity` y resuelve colisiones deslizando. Clave: en Godot 4 va **sin argumentos**.
- **`is_on_floor()`**: `true` si el cuerpo toca suelo tras moverse. Clave: base para decidir si se puede saltar.
- **`move_toward(actual, objetivo, paso)`**: acerca un valor a otro sin pasarse. Clave: produce aceleración/frenado suaves.
- **Gravedad**: aceleración descendente aplicada cada frame. Clave: la leemos del proyecto y la escalamos por `delta`.
- **Coyote time**: ventana breve tras dejar el suelo en la que aún se permite saltar. Clave: evita saltos "perdidos" injustos.
- **Jump buffer**: memoria breve de la pulsación de salto antes de tocar suelo. Clave: hace el salto más responsivo.

## 🧰 Herramientas y preparación

Sigue en `PlataformasCurso` con las acciones de input de la clase 029 ya creadas (`move_left`, `move_right`, `jump`). Necesitarás un suelo para probar: crearemos un `StaticBody2D` simple. Reutiliza el sprite del jugador como marcador.

Apóyate en la guía de movimiento 2D de Godot: <https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html>. La gravedad la tomaremos de `ProjectSettings` (`physics/2d/default_gravity`, por defecto 980).

## 🧪 Laboratorio guiado

Convertiremos al jugador en un `CharacterBody2D` con tacto profesional y le daremos un suelo.

1. Convierte la raíz del jugador. Abre `escenas/jugador.tscn`, haz clic derecho sobre el nodo raíz `Jugador` → **Change Type** → **CharacterBody2D**. Mantén el `Sprite2D` hijo.

2. Añade el colisionador. Con `Jugador` seleccionado, agrega un hijo **CollisionShape2D**. En el Inspector, en **Shape**, crea un **RectangleShape2D** y ajústalo para cubrir el sprite. Guarda con `Ctrl+S`.

3. Crea el suelo en el mundo. Abre `escenas/mundo.tscn`, añade un **StaticBody2D** llamado `Suelo`, con un hijo **CollisionShape2D** (un `RectangleShape2D` ancho y bajo) colocado en la parte inferior de la pantalla. Añádele también un `Sprite2D` o un `ColorRect` para verlo.

4. Coloca la instancia `Jugador` por encima del suelo para que caiga sobre él al arrancar.

5. Reemplaza `escenas/jugador.gd` con el controlador completo comentado:

```gdscript
extends CharacterBody2D
class_name Jugador

# --- Parametros de tacto (ajustables desde el Inspector) ---
@export var velocidad_max: float = 300.0      # velocidad horizontal objetivo
@export var aceleracion: float = 2000.0       # cuan rapido alcanza la velocidad
@export var friccion: float = 2500.0          # cuan rapido frena al soltar
@export var fuerza_salto: float = 520.0       # impulso vertical (positivo, se aplica negativo)
@export var corte_salto: float = 0.45         # factor al soltar el boton (salto variable)
@export var coyote_max: float = 0.10          # ventana de coyote time en segundos
@export var buffer_max: float = 0.10          # ventana de jump buffer en segundos

# Gravedad del proyecto (por defecto 980). Independiente de la resolucion.
var gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var coyote: float = 0.0   # tiempo restante de coyote
var buffer: float = 0.0   # tiempo restante de buffer de salto

func _physics_process(delta: float) -> void:
	_aplicar_gravedad(delta)
	_temporizadores(delta)
	_mover_horizontal(delta)
	_gestionar_salto()
	# En Godot 4 move_and_slide usa 'velocity' y NO recibe argumentos.
	move_and_slide()

func _aplicar_gravedad(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravedad * delta

func _temporizadores(delta: float) -> void:
	# Coyote time: se recarga en el suelo y decrece en el aire.
	if is_on_floor():
		coyote = coyote_max
	else:
		coyote = max(coyote - delta, 0.0)

	# Jump buffer: recuerda la pulsacion durante un instante.
	if Input.is_action_just_pressed("jump"):
		buffer = buffer_max
	else:
		buffer = max(buffer - delta, 0.0)

func _mover_horizontal(delta: float) -> void:
	var eje_x: float = Input.get_axis("move_left", "move_right")
	if eje_x != 0.0:
		# Acelera hacia la velocidad objetivo (da peso al arranque).
		velocity.x = move_toward(velocity.x, eje_x * velocidad_max, aceleracion * delta)
		# Voltea el sprite segun la direccion.
		$Sprite2D.flip_h = eje_x < 0.0
	else:
		# Sin input: frena suavemente hasta cero.
		velocity.x = move_toward(velocity.x, 0.0, friccion * delta)

func _gestionar_salto() -> void:
	# Salta si hay salto en buffer y aun queda coyote (en suelo o recien salido).
	if buffer > 0.0 and coyote > 0.0:
		velocity.y = -fuerza_salto
		buffer = 0.0
		coyote = 0.0

	# Salto variable: al soltar el boton mientras subimos, cortamos el impulso.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= corte_salto
```

6. Ejecuta con F5. El jugador cae por gravedad, aterriza en el suelo, corre con aceleración y salta con la barra espaciadora. Prueba el **salto variable**: un toque corto da un salto bajo; mantener pulsado da un salto alto.

7. Prueba el **coyote time**: camina hasta el borde del suelo y salta un instante después de dejarlo; el personaje aún salta. Prueba el **jump buffer**: pulsa saltar justo antes de aterrizar y el salto se ejecuta al tocar suelo.

8. Ajusta los valores exportados en el Inspector (`aceleracion`, `friccion`, `fuerza_salto`) y prueba en vivo hasta que el tacto te convenza. El *game feel* se logra iterando.

Ya tienes un controlador de plataformas con tacto profesional; en la clase 031 le daremos animaciones de correr y saltar.

## ✍️ Ejercicios

1. Añade una velocidad de correr con la acción `run` que suba `velocidad_max` temporalmente.
2. Limita la velocidad de caída (velocidad terminal) con un `min` sobre `velocity.y`.
3. Reduce el control horizontal en el aire multiplicando la aceleración cuando `not is_on_floor()`.
4. Emite una señal `aterrizo` cuando el jugador pasa de aire a suelo e imprímela.
5. Añade un doble salto contando saltos disponibles que se reinician al tocar suelo.
6. Expón el coyote y buffer en una `Label` de depuración para verlos decrecer.

## 📝 Reto verificable

Ajusta el controlador para que se sienta bien: define valores de aceleración, fricción y salto que permitan cruzar una plataforma y saltar un hueco con precisión. Añade doble salto y una velocidad terminal de caída. Documenta en comentarios por qué elegiste cada valor.

**Criterio de aceptación**: el personaje corre, frena y salta con control fino; el salto variable, el coyote time y el jump buffer funcionan; el doble salto se reinicia al aterrizar; y no atraviesa el suelo ni las paredes.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| "Too many arguments for move_and_slide()" | Sintaxis de Godot 3. En Godot 4 se llama `move_and_slide()` sin argumentos, tras fijar `velocity`. |
| El personaje atraviesa el suelo | Falta el `CollisionShape2D` en el jugador o en el suelo, o su forma es nula. |
| `is_on_floor()` siempre es `false` | Llamas a `move_and_slide()` antes de comprobarlo, o el suelo no es un cuerpo de colisión. |
| El salto no funciona | La acción `jump` no existe en el Input Map o la fuerza es demasiado baja frente a la gravedad. |
| El movimiento se siente resbaladizo o brusco | Aceleración/fricción mal calibradas. Ajústalas desde el Inspector iterando. |
| Cae demasiado rápido o flota | Gravedad del proyecto o `fuerza_salto` desequilibradas. Revisa `default_gravity`. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué `move_and_slide()` no recibe la velocidad como en tutoriales viejos?** Esos usan Godot 3. En Godot 4 fijas la propiedad `velocity` del cuerpo y llamas al método sin argumentos.

**❓ ¿Qué gana el juego con coyote time y jump buffer?** Perdonan errores de milisegundos del jugador, haciendo que el salto se sienta justo y responsivo en lugar de frustrante.

**❓ ¿Por qué usar `move_toward` en vez de asignar la velocidad directa?** Porque interpola gradualmente hacia el objetivo, dando peso al arranque y suavidad al frenado, clave del buen tacto.

**❓ ¿De dónde sale el valor de gravedad?** Lo leemos de `ProjectSettings` (`physics/2d/default_gravity`, 980 por defecto), así respeta la configuración global del proyecto.

## 🔗 Referencias

- Godot Docs — Using CharacterBody2D: <https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html>
- Godot Docs — CharacterBody2D (clase): <https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html>
- Godot Docs — 2D movement overview: <https://docs.godotengine.org/en/stable/tutorials/2d/2d_movement.html>
- Steve Swink, *Game Feel*: <https://www.gamefeelbook.com/>

## ⬅️ Clase anterior

[Clase 029 - Input: teclado, ratón, gamepad y mapeo de acciones](../029-input-teclado-raton-gamepad-y-mapeo-de-acciones/README.md)

## ➡️ Siguiente clase

[Clase 031 - Sprites, animación por frames y AnimationPlayer](../031-sprites-animacion-por-frames-y-animationplayer/README.md)
