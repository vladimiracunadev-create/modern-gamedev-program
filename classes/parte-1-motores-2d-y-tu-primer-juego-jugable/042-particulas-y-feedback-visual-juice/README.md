# Clase 042 — Partículas y feedback visual (juice)

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4 (Particle systems)*
> ⏱️ Duración estimada: **95 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Aprender a añadir **"juice"**: ese conjunto de pequeños efectos de feedback que hacen que un juego pase de correcto a satisfactorio. Un salto que exprime el sprite, polvo que se levanta al aterrizar, chispas al recoger una moneda, una explosión al derrotar un enemigo y un destello blanco al recibir daño. Nada de esto cambia las reglas del juego, pero cambia por completo cómo se siente.

Trabajarás con **GPUParticles2D** y **CPUParticles2D**, con animaciones de **squash & stretch** hechas con `create_tween()`, con un **hit-stop** (micro-pausa) y con el **flash de daño**. Combinarás estos recursos con el sonido de la clase anterior para que cada acción del jugador tenga una respuesta audiovisual clara. Al terminar, tu plataformas se sentirá notablemente más pulido.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar qué es el "juice" y por qué mejora la percepción de un juego.
2. Crear sistemas de partículas con **GPUParticles2D** y **CPUParticles2D** (`emitting`, `one_shot`, `amount`, `lifetime`).
3. Emitir polvo al aterrizar y una explosión one-shot al derrotar a un enemigo.
4. Aplicar **squash & stretch** al saltar usando `create_tween()`.
5. Implementar un **flash de daño** y un **hit-stop** breve para reforzar los golpes.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Concepto de "juice" | Es lo que hace un juego satisfactorio sin cambiar sus reglas. |
| 2 | GPUParticles2D vs CPUParticles2D | Eliges según rendimiento y plataforma de destino. |
| 3 | Propiedades clave de partículas | `amount`, `lifetime`, `one_shot`, `emitting` controlan el efecto. |
| 4 | Polvo al correr y aterrizar | Da peso y contacto con el suelo al personaje. |
| 5 | Explosión one-shot al morir | Recompensa visual clara al derrotar enemigos. |
| 6 | Squash & stretch con tween | Deforma el sprite para dar vida al salto. |
| 7 | Flash de daño | Comunica al instante que el jugador fue golpeado. |
| 8 | Hit-stop y screen shake | Micro-pausa y vibración que refuerzan el impacto. |

## 📖 Definiciones y características

- **Juice**: capa de feedback (visual, sonoro, de cámara) que hace las acciones satisfactorias. Clave: es acumulativo, muchos detalles pequeños suman.
- **GPUParticles2D**: sistema de partículas procesado en la GPU mediante un `ParticleProcessMaterial`. Clave: eficiente para grandes cantidades, requiere GPU compatible.
- **CPUParticles2D**: mismo efecto calculado en la CPU, configurable con propiedades directas. Clave: más compatible (web/móviles) y fácil de ajustar por script.
- **emitting**: booleano que activa o detiene la emisión de partículas. Clave: para efectos puntuales lo pones en `true` un instante.
- **one_shot**: si es `true`, emite una sola ráfaga y se detiene sola. Clave: perfecto para explosiones.
- **Squash & stretch**: principio de animación que estira y aplasta un objeto para dar elasticidad. Clave: se logra animando `scale` con un tween.
- **Tween**: objeto que interpola una propiedad a lo largo del tiempo (`create_tween()`). Clave: encadena y suaviza animaciones sin `_process`.
- **Hit-stop**: pausa muy breve del juego al conectar un golpe. Clave: enfatiza el impacto (usa `Engine.time_scale` o un `await` corto).

## 🧰 Herramientas y preparación

Continúa con tu proyecto `PlataformasCurso`. No necesitas descargar assets: las partículas se generan por defecto con un punto de color, y puedes darles textura opcional con `res://icon.svg`. Ten a mano la documentación de partículas 2D: <https://docs.godotengine.org/en/stable/tutorials/2d/particle_systems_2d.html> y la de tweens: <https://docs.godotengine.org/en/stable/tutorials/animation/tween.html>. Recomendado tener ya integrado el sonido de la Clase 041 para combinar efectos.

## 🧪 Laboratorio guiado

Añadiremos polvo al aterrizar, explosión al derrotar un enemigo, squash & stretch al saltar y flash de daño.

1. **Polvo al aterrizar con CPUParticles2D.** Añade al jugador un hijo **CPUParticles2D** llamado `Polvo`. En el Inspector: **Emitting** desactivado, **One Shot** activado, **Amount** `12`, **Lifetime** `0.4`. En **Direction** apunta hacia arriba `(0, -1)`, **Spread** `40`, **Initial Velocity** entre `40` y `90`, **Gravity** `(0, 200)`. Colócalo en los pies del sprite.

2. **Disparar el polvo al tocar suelo.** En el script del jugador, detecta el momento de aterrizaje comparando el estado anterior con el actual:

```gdscript
extends CharacterBody2D

const FUERZA_SALTO := -420.0
var _estaba_en_aire := false

@onready var polvo: CPUParticles2D = $Polvo
@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(delta: float) -> void:
	# ... aplicar gravedad y movimiento horizontal ...
	var en_suelo := is_on_floor()
	# Detectamos la transición aire -> suelo (aterrizaje).
	if en_suelo and _estaba_en_aire:
		aterrizar()
	_estaba_en_aire = not en_suelo
	move_and_slide()

func aterrizar() -> void:
	polvo.restart()      # reinicia y emite la ráfaga one-shot
	Sfx.reproducir("salto")  # reutiliza SFX de la clase anterior
```

3. **Squash & stretch al saltar.** Cuando el jugador salta, deformamos su escala con un tween para dar elasticidad:

```gdscript
func saltar() -> void:
	velocity.y = FUERZA_SALTO
	Sfx.reproducir("salto")
	# Estira vertical al impulsarse y vuelve al tamaño normal.
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.7, 1.3), 0.08)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.12)
```

Llama a `saltar()` desde tu input de salto en lugar de fijar `velocity.y` directamente.

4. **Explosión one-shot al derrotar un enemigo.** Crea una escena `res://efectos/explosion.tscn` con raíz **GPUParticles2D** llamada `Explosion`. En el Inspector crea un **ParticleProcessMaterial** nuevo, activa **One Shot**, **Amount** `24`, **Lifetime** `0.6`, dirección radial (**Spread** `180`) y una **Initial Velocity** de `120`. Asigna un script para autolimpiarse:

```gdscript
extends GPUParticles2D

func _ready() -> void:
	emitting = true
	one_shot = true
	# Se libera sola cuando termina toda la vida de las partículas.
	await get_tree().create_timer(lifetime + 0.2).timeout
	queue_free()
```

5. **Instanciar la explosión al morir el enemigo.** En el script del enemigo, al ser derrotado, coloca la explosión en su posición antes de liberarse:

```gdscript
const EXPLOSION := preload("res://efectos/explosion.tscn")

func morir() -> void:
	var fx := EXPLOSION.instantiate()
	fx.global_position = global_position
	get_parent().add_child(fx)   # vive fuera del enemigo que se libera
	Sfx.reproducir("dano")
	queue_free()
```

6. **Flash blanco al recibir daño.** Un `modulate` blanco intenso y su retorno comunican el golpe. En el script del jugador:

```gdscript
func recibir_dano(cantidad: int) -> void:
	vida -= cantidad
	Sfx.reproducir("dano")
	flash_dano()
	hit_stop()

func flash_dano() -> void:
	# Sube el brillo y regresa al color normal.
	var tween := create_tween()
	sprite.modulate = Color(4, 4, 4)   # sobreexpone a blanco
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
```

7. **Hit-stop (micro-pausa).** Congela brevemente el tiempo para enfatizar el impacto usando `Engine.time_scale`:

```gdscript
func hit_stop() -> void:
	Engine.time_scale = 0.05     # casi congelado
	# El timer ignora la escala de tiempo para medir en segundos reales.
	await get_tree().create_timer(0.08, true, false, true).timeout
	Engine.time_scale = 1.0
```

8. **Probar todo junto.** Ejecuta con **F5**. Salta (verás el estirado y el polvo al caer), recoge monedas y deja que un enemigo te golpee (flash + hit-stop) o derrótalo (explosión). La combinación de partículas, tween, flash y sonido es exactamente el "juice" que buscábamos.

## ✍️ Ejercicios

1. Añade partículas de **polvo al correr**: emite continuamente mientras el jugador se mueve por el suelo y detén la emisión al parar.
2. Crea chispas al recoger una moneda instanciando un pequeño `CPUParticles2D` one-shot en su posición.
3. Ajusta el squash & stretch para que también haya un pequeño aplaste (`Vector2(1.3, 0.7)`) al aterrizar.
4. Convierte la explosión del enemigo a **CPUParticles2D** y compara la compatibilidad de cara a la exportación web.
5. Cambia el color de las partículas de explosión mediante un **gradiente** en el material.
6. Añade un leve **screen shake** moviendo la cámara con un tween al recibir daño.

## 📝 Reto verificable

Crea un componente reutilizable `EfectoImpacto` que combine tres cosas al ejecutarse: un flash blanco sobre el sprite objetivo, un hit-stop de `0.08 s` y la instanciación de una explosión de partículas one-shot en la posición del impacto. Debe poder llamarse tanto cuando el jugador recibe daño como cuando un enemigo es derrotado.

**Criterio de aceptación**: al golpear o ser golpeado, se ve el flash, el juego se congela un instante y aparece la explosión, todo sincronizado con el SFX, sin que ningún nodo quede huérfano ni provoque errores en el Output.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| GPUParticles2D no se ve en el build web | La GPU/driver no soporta el modo. Usa **CPUParticles2D** para web. |
| Las partículas no emiten | Olvidaste poner `emitting = true` o llamar a `restart()`. Actívalo al disparar el efecto. |
| La explosión desaparece al morir el enemigo | La instanciaste como hija del enemigo que se libera. Añádela al **padre** con `get_parent().add_child(fx)`. |
| El hit-stop nunca termina | El timer se paró junto al juego. Créalo con `ignore_time_scale = true` (4.º argumento). |
| El sprite queda deformado tras el salto | El tween se interrumpió. Asegúrate de volver siempre a `scale = Vector2(1, 1)` al final. |
| El flash deja el sprite blanco permanente | No animaste el retorno de `modulate`. Devuélvelo a `Color.WHITE` con un tween. |

## ❓ Preguntas frecuentes

**❓ ¿GPU o CPU para partículas?** GPUParticles2D es más eficiente para muchas partículas, pero CPUParticles2D es más compatible (web y equipos modestos). Para un plataformas 2D sencillo y su export web, CPU suele ser la opción segura.

**❓ ¿Por qué usar tween y no una animación en _process?** El tween interpola por ti, se autolimpia y encadena pasos con una sola línea; en `_process` tendrías que llevar contadores de tiempo a mano.

**❓ ¿El hit-stop no arruina la fluidez?** Bien dosificado (menos de 0.1 s) el cerebro lo percibe como contundencia, no como un tirón. La clave es que sea muy breve y solo en impactos importantes.

**❓ ¿El "juice" no es solo decoración prescindible?** Es feedback: comunica al jugador que su acción tuvo efecto. Sin él, saltar o golpear se siente vacío aunque la mecánica funcione perfectamente.

## 🔗 Referencias

- Godot Docs — Particle systems (2D): <https://docs.godotengine.org/en/stable/tutorials/2d/particle_systems_2d.html>
- Godot Docs — CPUParticles2D: <https://docs.godotengine.org/en/stable/classes/class_cpuparticles2d.html>
- Godot Docs — GPUParticles2D: <https://docs.godotengine.org/en/stable/classes/class_gpuparticles2d.html>
- Godot Docs — Tween: <https://docs.godotengine.org/en/stable/tutorials/animation/tween.html>
- Godot Docs — Using Tweens (create_tween): <https://docs.godotengine.org/en/stable/classes/class_tween.html>

## ⬅️ Clase anterior

[Clase 041 - Sonido y música en 2D: efectos y bucle musical](../041-sonido-y-musica-en-2d-efectos-y-bucle-musical/README.md)

## ➡️ Siguiente clase

[Clase 043 - Guardado y carga de progreso](../043-guardado-y-carga-de-progreso/README.md)
