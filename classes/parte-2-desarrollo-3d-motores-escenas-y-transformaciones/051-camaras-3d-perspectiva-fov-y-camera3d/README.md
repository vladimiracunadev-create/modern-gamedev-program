# Clase 051 — Cámaras 3D: perspectiva, FOV y Camera3D

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Godot Engine 4 — Documentación oficial: Camera3D y Using cameras*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Comprender cómo una **Camera3D** define lo que el jugador ve en una escena 3D de Godot 4, dominando la diferencia entre proyección **perspectiva** y **ortográfica**, el papel del **FOV** (campo de visión), los planos **near/far** y el manejo de **múltiples cámaras** mediante la propiedad `current`.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Colocar y orientar una `Camera3D` en una escena y previsualizar su encuadre en el editor.
2. Explicar y aplicar la diferencia entre proyección perspectiva y ortográfica.
3. Ajustar el **FOV** en tiempo de ejecución y describir su efecto sobre la sensación de distancia.
4. Configurar los planos **near** y **far** para controlar el rango visible y evitar artefactos.
5. Alternar entre varias cámaras usando `current` y el método `make_current()`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Nodo Camera3D | Es la ventana del jugador al mundo 3D. |
| 2 | Proyección perspectiva | Reproduce cómo vemos: los objetos lejanos se ven pequeños. |
| 3 | Proyección ortográfica | Sin distorsión de distancia; ideal para vistas tácticas o isométricas. |
| 4 | FOV (campo de visión) | Controla el ángulo visible y la sensación de velocidad o amplitud. |
| 5 | Planos near/far | Definen el rango de profundidad renderizado. |
| 6 | Propiedad `current` | Determina qué cámara está activa cuando hay varias. |
| 7 | Encuadre y composición | Posicionar la cámara comunica intención y legibilidad. |
| 8 | Cámara y viewport | La cámara rellena el `Viewport` que la contiene. |

## 📖 Definiciones y características

- **Camera3D**: nodo que renderiza lo que se encuadra hacia el viewport. Clave: solo una cámara puede estar activa por viewport.
- **Proyección perspectiva**: simula la visión humana con líneas que convergen. Clave: usa `projection = PROJECTION_PERSPECTIVE`.
- **Proyección ortográfica**: proyecta sin convergencia; tamaños constantes con la distancia. Clave: `projection = PROJECTION_ORTHOGONAL` y se controla con `size`.
- **FOV (Field Of View)**: ángulo vertical de visión en grados. Clave: valores altos (90+) dan gran angular; bajos (30) dan efecto teleobjetivo.
- **Near**: plano de recorte cercano. Clave: objetos más cerca que `near` no se dibujan; valores muy pequeños causan *z-fighting*.
- **Far**: plano de recorte lejano. Clave: limita la distancia máxima renderizada por rendimiento.
- **current**: booleano que activa la cámara. Clave: al ponerlo en `true`, desactiva automáticamente las demás.
- **make_current()**: método que activa la cámara por código. Clave: forma limpia de cambiar de cámara en runtime.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x** (recomendado 4.2 o superior) con una escena 3D básica: un `Node3D` raíz, un suelo (`StaticBody3D` con `MeshInstance3D`) y algunos cubos para tener referencia de profundidad. Revisa la documentación oficial del nodo cámara en <https://docs.godotengine.org/en/stable/classes/class_camera3d.html> y la guía de uso en <https://docs.godotengine.org/en/stable/tutorials/3d/using_cameras.html>. Descarga el motor desde <https://godotengine.org/download>.

## 🧪 Laboratorio guiado

1. Crea una escena con raíz `Node3D` llamada `Mundo`. Añade un `MeshInstance3D` con una malla de plano grande como suelo y tres `MeshInstance3D` con cajas a distintas distancias en Z.
2. Agrega dos nodos `Camera3D`: nómbralos `CamFrontal` (en `position = Vector3(0, 2, 6)` mirando al origen) y `CamCenital` (en `position = Vector3(0, 10, 0)`). Para `CamCenital`, en el inspector fija `rotation_degrees = Vector3(-90, 0, 0)`.
3. Selecciona `CamFrontal` y marca **Current** en el inspector para previsualizar su encuadre.
4. Añade un script al nodo `Mundo` para controlar cámara, FOV y proyección en tiempo de ejecución:

```gdscript
extends Node3D

@onready var cam_frontal: Camera3D = $CamFrontal
@onready var cam_cenital: Camera3D = $CamCenital

func _ready() -> void:
	cam_frontal.make_current()
	# Configuración inicial de perspectiva.
	cam_frontal.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam_frontal.fov = 70.0
	cam_frontal.near = 0.05
	cam_frontal.far = 500.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		# Alternar entre las dos cámaras.
		if cam_frontal.current:
			cam_cenital.make_current()
		else:
			cam_frontal.make_current()

func _process(_delta: float) -> void:
	var activa := get_viewport().get_camera_3d()
	# Subir/bajar FOV con las flechas cuando la activa es perspectiva.
	if activa.projection == Camera3D.PROJECTION_PERSPECTIVE:
		if Input.is_action_pressed("ui_up"):
			activa.fov = clamp(activa.fov + 30.0 * _delta, 20.0, 110.0)
		if Input.is_action_pressed("ui_down"):
			activa.fov = clamp(activa.fov - 30.0 * _delta, 20.0, 110.0)
	# Cambiar de proyección con la tecla P.
	if Input.is_action_just_pressed("ui_focus_next"):
		_alternar_proyeccion(activa)

func _alternar_proyeccion(cam: Camera3D) -> void:
	if cam.projection == Camera3D.PROJECTION_PERSPECTIVE:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 8.0
	else:
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
```

5. Ejecuta la escena. Mantén la flecha arriba/abajo y observa cómo al aumentar el **FOV** las cajas lejanas parecen alejarse y el mundo se ensancha; al reducirlo se comprime la profundidad.
6. Pulsa **Enter** (`ui_accept`) para saltar a la vista cenital y **Tab** (`ui_focus_next`) para pasar la cámara activa a ortográfica: verás que las cajas mantienen el mismo tamaño sin importar la distancia.

## ✍️ Ejercicios

1. Añade una tercera cámara lateral y amplía la lógica de alternancia para rotar entre las tres.
2. Muestra en un `Label` el valor actual de `fov`, `near` y `far` de la cámara activa.
3. Configura una cámara ortográfica con `size = 4` y describe qué encuadre táctico produce.
4. Experimenta con `near = 0.001` y `far = 5.0`; documenta los artefactos visuales que aparecen.
5. Crea una transición suave de FOV entre 40 y 90 usando `lerp()` en `_process`.
6. Haz que la cámara frontal siga a una caja móvil manteniendo el encuadre.

## 📝 Reto verificable

Construye una escena con dos cámaras (perspectiva y ortográfica) y un menú por teclas: `1` activa perspectiva con FOV 60, `2` activa ortográfica con `size` 6, y las flechas ajustan el FOV solo cuando la cámara perspectiva está activa.

**Criterio de aceptación**: al ejecutar, cambiar de cámara con `1`/`2` funciona sin errores en consola, el FOV solo se modifica en modo perspectiva y el cambio es visualmente evidente en el encuadre.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| No se ve nada al ejecutar | Ninguna cámara tiene `current = true`; marca una o llama `make_current()`. |
| Los objetos cercanos se recortan | `near` demasiado grande; reduce a 0.05–0.1. |
| Parpadeo entre superficies (*z-fighting*) | `near` demasiado pequeño o `far` enorme; equilibra el rango. |
| El FOV no afecta nada | La cámara está en ortográfica; el FOV solo aplica en perspectiva (usa `size`). |
| Dos cámaras compiten por la vista | Al activar una con `current`, verifica que las demás queden en `false`. |
| Escala rara en ortográfica | Ajusta la propiedad `size`, no el `fov`. |

## ❓ Preguntas frecuentes

**❓ ¿Cuál es un FOV típico para un juego?** Entre 60 y 75 grados en tercera persona; los FPS suelen usar 90 o más para mayor amplitud.

**❓ ¿La proyección ortográfica sirve para juegos?** Sí, es habitual en estrategia, puzles isométricos y vistas 2.5D donde no quieres distorsión de distancia.

**❓ ¿Puedo tener varias cámaras activas a la vez?** No en un mismo viewport. Para vista dividida usa varios `SubViewport`, cada uno con su cámara.

**❓ ¿`current` y `make_current()` hacen lo mismo?** Prácticamente sí; `make_current()` es un método explícito, mientras que `current` es la propiedad que puedes fijar en el inspector o por código.

## 🔗 Referencias

- Camera3D — API oficial: <https://docs.godotengine.org/en/stable/classes/class_camera3d.html>
- Using cameras (tutorial 3D): <https://docs.godotengine.org/en/stable/tutorials/3d/using_cameras.html>
- Introduction to 3D: <https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html>

## ➡️ Siguiente clase

[Clase 052 - Iluminación 3D: tipos de luz y sombras](../052-iluminacion-3d-tipos-de-luz-y-sombras/README.md)
