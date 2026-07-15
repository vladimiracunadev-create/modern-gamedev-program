# Clase 060 — Animación 3D: esqueletos, skinning y AnimationPlayer

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot Engine 4.x — Introduction to the animation features*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Comprender cómo un personaje 3D cobra vida: el esqueleto (`Skeleton3D`), el skinning que deforma la malla siguiendo los huesos, y el `AnimationPlayer` que reproduce las animaciones importadas de un archivo glTF. Reproduciremos idle, walk y run según el estado de movimiento del personaje.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar qué son `Skeleton3D`, los huesos y el skinning en un modelo animado.
- Importar un personaje glTF con sus animaciones y localizar su `AnimationPlayer`.
- Reproducir animaciones con `play("nombre")` y encadenarlas.
- Ajustar la velocidad de reproducción con `speed_scale` y el custom blend.
- Cambiar de idle a walk/run según la velocidad del `CharacterBody3D`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Skeleton3D y huesos | Estructura que deforma la malla |
| 2 | Skinning | Vincula vértices a huesos con pesos |
| 3 | Animaciones glTF | Los modelos traen sus clips listos |
| 4 | AnimationPlayer | Nodo que almacena y reproduce clips |
| 5 | play() y blends | Transiciones suaves entre clips |
| 6 | animation_finished | Encadenar acciones al terminar un clip |
| 7 | speed_scale | Adaptar la velocidad a la del personaje |
| 8 | Loop de animación | Idle/walk/run deben repetirse sin cortes |

## 📖 Definiciones y características

- **Skeleton3D**: nodo que contiene la jerarquía de huesos que deforma una malla con skin. Clave: viene incluido al importar un modelo riggeado.
- **Hueso (bone)**: articulación con transform propia; su movimiento arrastra los vértices asignados. Clave: no se anima a mano en runtime salvo casos avanzados (IK).
- **Skinning**: proceso que asocia cada vértice a uno o más huesos con pesos. Clave: se define en el modelador (Blender) y se importa.
- **AnimationPlayer**: nodo que guarda clips (`Animation`) y los reproduce sobre el árbol. Clave: cada clip tiene nombre, duración y modo de bucle.
- **play(nombre, custom_blend)**: reproduce un clip; `custom_blend` funde con el anterior. Clave: un blend de 0.2 s evita saltos bruscos.
- **animation_finished(nombre)**: señal al acabar un clip no en bucle. Clave: ideal para volver a idle tras un ataque.
- **speed_scale**: multiplicador global de velocidad del reproductor. Clave: acelera walk para que "pegue" con la velocidad real.
- **loop_mode**: define si el clip se repite. Clave: idle/walk/run deben estar en loop; una acción puntual, no.

## 🧰 Herramientas y preparación

Godot 4.x y un personaje glTF con animaciones (por ejemplo, modelos de [Mixamo](https://www.mixamo.com/) exportados a glTF, o los de [Kenney](https://kenney.nl/assets)). Coloca el `.glb`/`.gltf` en el proyecto; Godot generará un nodo raíz con `Skeleton3D`, la malla y un `AnimationPlayer`. Consulta la [introducción a animación](https://docs.godotengine.org/en/stable/tutorials/animation/introduction.html) e [importar animaciones](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html).

## 🧪 Laboratorio guiado

Daremos movimiento a un personaje: idle quieto, walk al caminar, run al ir rápido.

**1) Importar y preparar.** Arrastra el `.glb` a la escena o instáncialo. Ábrelo (doble clic) y, si hace falta, marca las animaciones como **Loop** en las importaciones (pestaña Import > animación > Loop Mode). Verifica los nombres de los clips en el `AnimationPlayer`: por ejemplo `Idle`, `Walk`, `Run`.

**2) Estructura de escena.** Crea `Jugador` (`CharacterBody3D`) con `CollisionShape3D` (cápsula) y añade como hijo la escena del modelo importado. Localiza su `AnimationPlayer` (suele estar dentro del modelo). Añade una `Camera3D`.

**3) Script de locomoción con animación.** Adjunta al `Jugador`:

```gdscript
extends CharacterBody3D

@export var vel_caminar := 2.0
@export var vel_correr := 6.0
@export var gravedad := 20.0
@onready var anim: AnimationPlayer = $Modelo/AnimationPlayer

var _estado := ""

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravedad * delta
	else:
		velocity.y = 0.0

	var corriendo := Input.is_action_pressed("correr")
	var vel := vel_correr if corriendo else vel_caminar
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var mov := (transform.basis * Vector3(dir.x, 0.0, dir.y)).normalized()
	velocity.x = mov.x * vel
	velocity.z = mov.z * vel

	move_and_slide()
	_actualizar_animacion(mov, corriendo)

func _actualizar_animacion(mov: Vector3, corriendo: bool) -> void:
	var nuevo := "Idle"
	if mov.length() > 0.1:
		nuevo = "Run" if corriendo else "Walk"
	if nuevo != _estado:
		_estado = nuevo
		anim.play(nuevo, 0.2)  # blend de 0.2 s
```

Ajusta la ruta `$Modelo/AnimationPlayer` a tu jerarquía real.

**4) Ajustar la velocidad de reproducción.** Para que los pies no "patinen", escala la animación con la velocidad real:

```gdscript
	# dentro de _actualizar_animacion, tras play/estado
	if _estado == "Walk":
		anim.speed_scale = velocity.length() / vel_caminar
	elif _estado == "Run":
		anim.speed_scale = velocity.length() / vel_correr
	else:
		anim.speed_scale = 1.0
```

**5) Observable.** El personaje está en idle al detenerse, camina con animación de walk al moverse y cambia a run al mantener la tecla `correr`, con transiciones suaves gracias al blend. La malla se deforma correctamente siguiendo el esqueleto.

## ✍️ Ejercicios

1. Conecta la señal `animation_finished` a un clip de "saludo" que vuelva a idle al terminar.
2. Reproduce una animación de salto al pulsar `ui_accept` cuando `is_on_floor()`.
3. Ajusta el `custom_blend` a 0.05 y a 0.5 y compara la suavidad de la transición.
4. Muestra en un `Label` el clip actual (`anim.current_animation`).
5. Añade una animación de "aterrizaje" que se dispare al volver a tocar suelo tras caer.
6. Invierte el `speed_scale` a negativo en un clip y observa la reproducción hacia atrás.

## 📝 Reto verificable

Crea un personaje que se anime coherentemente en tres estados —quieto, caminar y correr— con transiciones suaves, y que además reproduzca una animación puntual (por ejemplo, "wave") al pulsar una tecla, volviendo automáticamente a idle al terminar.

**Criterio de aceptación**: al moverse cambia entre Idle/Walk/Run sin saltos visibles y sin patinaje evidente de pies; al pulsar la tecla de saludo se reproduce el clip completo una vez y el personaje regresa a Idle sin quedarse congelado.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La animación no repite | Clip sin loop. Marca Loop Mode en Import o en el `AnimationPlayer`. |
| `play("Walk")` no hace nada | Nombre incorrecto o `AnimationPlayer` mal referenciado. Verifica nombres y ruta `@onready`. |
| Transiciones bruscas | Sin blend. Usa `play(nombre, 0.2)`. |
| Los pies patinan | Velocidad de clip fija. Ajusta `speed_scale` según `velocity.length()`. |
| La malla se deforma raro | Escala del import distinta o esqueleto mal exportado. Revisa el pipeline glTF (clase 050). |

## ❓ Preguntas frecuentes

**¿Dónde está el `AnimationPlayer` de mi modelo?** Godot lo crea dentro de la escena importada; ábrela y busca el nodo, luego referencia su ruta.

**¿Puedo renombrar los clips?** Sí, desde el `AnimationPlayer`, pero recuerda actualizar tus `play()`.

**¿Por qué necesito blend?** Sin blend, cambiar de clip corta la pose actual y salta a la nueva; el blend interpola entre ambas.

**¿Idle/Walk/Run bastan?** Para locomoción básica sí; para mezclas continuas por velocidad conviene `AnimationTree`, que veremos en la clase 061.

## 🔗 Referencias

- [Introduction to the animation features — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/animation/introduction.html)
- [Importing 3D scenes — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/index.html)
- [Skeleton3D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html)

## ⬅️ Clase anterior

[Clase 059 - Raycasting 3D: selección, disparos y detección de suelo](../059-raycasting-3d-seleccion-disparos-y-deteccion-de-suelo/README.md)

## ➡️ Siguiente clase

[Clase 061 - AnimationTree y blending de animaciones](../061-animationtree-y-blending-de-animaciones/README.md)
