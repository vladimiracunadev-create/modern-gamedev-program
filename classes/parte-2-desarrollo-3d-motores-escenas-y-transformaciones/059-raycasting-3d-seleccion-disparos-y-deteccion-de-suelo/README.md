# Clase 059 — Raycasting 3D: selección, disparos y detección de suelo

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot Engine 4.x — Ray-casting*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Aprender a lanzar rayos en 3D de dos formas —con el nodo `RayCast3D` para chequeos continuos y con `intersect_ray` para consultas puntuales— y aplicarlos a tres problemas clásicos: seleccionar objetos bajo el ratón, disparar hitscan desde la cámara y detectar el suelo o la pendiente bajo el personaje.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Usar `RayCast3D` con `target_position`, `is_colliding()`, `get_collider()` y `get_collision_point()`.
- Realizar consultas puntuales con `PhysicsRayQueryParameters3D` y `direct_space_state.intersect_ray`.
- Convertir la posición del ratón en un rayo del mundo con `project_ray_origin` / `project_ray_normal`.
- Implementar un disparo hitscan que marca el punto de impacto.
- Detectar suelo y calcular la inclinación de la pendiente con la normal de colisión.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | RayCast3D (nodo) | Chequeo continuo cada frame de física |
| 2 | target_position local | Define largo y dirección del rayo |
| 3 | intersect_ray | Rayos puntuales bajo demanda |
| 4 | Selección con el ratón | Interacción típica de estrategia/edición |
| 5 | Hitscan | Disparo instantáneo sin proyectil físico |
| 6 | Normal de colisión | Orientar impactos y medir pendientes |
| 7 | Capas de colisión en rayos | Filtrar qué puede golpear el rayo |
| 8 | collide_with_areas/bodies | Elegir si el rayo detecta áreas o cuerpos |

## 📖 Definiciones y características

- **RayCast3D**: nodo que lanza un rayo desde su origen hasta `target_position` (en espacio local). Clave: se actualiza en física; lee resultados en `_physics_process`.
- **target_position**: extremo del rayo relativo al nodo. Clave: `Vector3(0, -2, 0)` lanza 2 m hacia abajo.
- **is_colliding()**: devuelve si el rayo golpeó algo este frame. Clave: consúltalo antes de `get_collider()`.
- **get_collision_point()**: punto de impacto en coordenadas globales. Clave: úsalo para colocar marcas o efectos.
- **get_collision_normal()**: normal de la superficie golpeada. Clave: mide pendientes y orienta decals.
- **intersect_ray(params)**: consulta puntual sobre el `direct_space_state`. Clave: devuelve un diccionario vacío si no golpea nada.
- **PhysicsRayQueryParameters3D**: define origen, destino y máscara del rayo puntual. Clave: `create(from, to)` construye lo básico.
- **project_ray_origin / project_ray_normal**: proyectan la posición 2D del ratón a un rayo 3D desde la cámara. Clave: base de toda selección con clic.

## 🧰 Herramientas y preparación

Godot 4.x con una escena 3D que tenga cámara, suelo y algunos objetos seleccionables (`StaticBody3D` con `BoxShape3D`). Ten activo `Debug > Visible Collision Shapes`. Consulta [Ray-casting](https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html) y la clase [PhysicsRayQueryParameters3D](https://docs.godotengine.org/en/stable/classes/class_physicsrayqueryparameters3d.html).

## 🧪 Laboratorio guiado

Haremos disparo hitscan desde la cámara que marca el impacto, y selección de objetos con clic.

**1) Marca de impacto.** Crea una pequeña escena `Marca.tscn` (un `MeshInstance3D` con `SphereMesh` de radio 0.1, material rojo). La instanciaremos en cada disparo.

**2) Disparo hitscan por código.** En el controlador con `Camera3D`, adjunta:

```gdscript
extends Node3D

@export var marca: PackedScene
@export var alcance := 100.0
@onready var camara: Camera3D = $Camera3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_disparar_hitscan(event.position)

func _disparar_hitscan(pos_raton: Vector2) -> void:
	var espacio := get_world_3d().direct_space_state
	var origen := camara.project_ray_origin(pos_raton)
	var destino := origen + camara.project_ray_normal(pos_raton) * alcance
	var consulta := PhysicsRayQueryParameters3D.create(origen, destino)
	consulta.collision_mask = 1  # solo capa World, por ejemplo
	var res := espacio.intersect_ray(consulta)
	if res:  # diccionario no vacío = hubo impacto
		var m := marca.instantiate() as Node3D
		get_tree().current_scene.add_child(m)
		m.global_position = res.position
		print("Impacto en ", res.collider.name, " normal ", res.normal)
```

Al hacer clic, aparece una esfera roja exactamente donde el rayo golpea, y la consola imprime el objeto y la normal.

**3) Selección con clic (resaltar).** Reutiliza el rayo para resaltar el objeto seleccionado. Da a los seleccionables un método `resaltar(activo)`. En el controlador:

```gdscript
var seleccionado: Node = null

func _seleccionar(pos_raton: Vector2) -> void:
	var espacio := get_world_3d().direct_space_state
	var origen := camara.project_ray_origin(pos_raton)
	var destino := origen + camara.project_ray_normal(pos_raton) * alcance
	var res := espacio.intersect_ray(PhysicsRayQueryParameters3D.create(origen, destino))
	if seleccionado and seleccionado.has_method("resaltar"):
		seleccionado.resaltar(false)
	seleccionado = null
	if res and res.collider.has_method("resaltar"):
		seleccionado = res.collider
		seleccionado.resaltar(true)
```

**4) Detección de suelo con nodo RayCast3D.** En el personaje, añade un `RayCast3D` hijo con `target_position = Vector3(0, -1.2, 0)` (algo más largo que media cápsula). En su script:

```gdscript
@onready var rayo_suelo: RayCast3D = $RayCast3D

func _physics_process(_delta: float) -> void:
	if rayo_suelo.is_colliding():
		var normal := rayo_suelo.get_collision_normal()
		# Ángulo de la pendiente respecto a la vertical
		var pendiente := rad_to_deg(normal.angle_to(Vector3.UP))
		if pendiente > 40.0:
			print("Pendiente empinada: ", round(pendiente), "°")
```

**5) Observable.** Disparas y aparecen marcas en muros y suelo con la normal correcta; al hacer clic sobre una caja se resalta; al pisar una rampa muy inclinada, la consola avisa de la pendiente.

## ✍️ Ejercicios

1. Orienta la marca de impacto para que se alinee con la normal de la superficie (usa `look_at` con la normal).
2. Añade `consulta.exclude = [self]` para que el rayo no golpee al propio tirador.
3. Cambia el `collision_mask` del disparo para que solo golpee enemigos y no el escenario.
4. Convierte el hitscan a `RayCast3D` nodo fijo delante de la cámara y compara continuidad vs consulta puntual.
5. Activa `collide_with_areas` en una consulta y detecta un `Area3D` como zona de disparo.
6. Muestra la distancia al impacto (`origen.distance_to(res.position)`) en un `Label`.

## 📝 Reto verificable

Implementa una "linterna de inspección": un rayo desde la cámara que, cada frame, muestre en un `Label` el nombre del objeto que hay en el centro de la pantalla y la distancia a él; al hacer clic, coloca una marca persistente en ese punto.

**Criterio de aceptación**: apuntando al centro, el `Label` actualiza en tiempo real el nombre y la distancia del objeto enfocado; al hacer clic se deja una marca exactamente en la superficie apuntada, orientada según su normal.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| `intersect_ray` siempre vacío | Origen/destino iguales o máscara sin capa. Verifica dirección y `collision_mask`. |
| `RayCast3D` no detecta nada | `enabled` en false o rayo demasiado corto. Actívalo y alarga `target_position`. |
| El rayo golpea al propio jugador | No excluyes el cuerpo. Usa `exclude = [self]` o ajusta capas. |
| La marca aparece en el aire | Lees `res.position` cuando el diccionario está vacío. Comprueba `if res:` primero. |
| Selección con clic errática | Usas coordenadas de mundo en lugar de `event.position` (pantalla). Pasa la posición del ratón. |

## ❓ Preguntas frecuentes

**¿RayCast3D o intersect_ray?** El nodo es cómodo para chequeos fijos y continuos (suelo, pared frontal); `intersect_ray` es mejor para eventos puntuales como un disparo.

**¿Por qué el rayo atraviesa un `Area3D`?** Por defecto los rayos ignoran áreas; activa `collide_with_areas`.

**¿El nodo RayCast3D se actualiza al instante?** Se actualiza en el paso de física; si necesitas un valor inmediato tras mover, llama `force_raycast_update()`.

**¿Cómo limito qué golpea?** Con `collision_mask`, igual que en los cuerpos; usa las capas nombradas de la clase 057.

## 🔗 Referencias

- [Ray-casting — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html)
- [RayCast3D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_raycast3d.html)
- [PhysicsDirectSpaceState3D](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate3d.html)

## ⬅️ Clase anterior

[Clase 058 - RigidBody3D, fuerzas e interacción física](../058-rigidbody3d-fuerzas-e-interaccion-fisica/README.md)

## ➡️ Siguiente clase

[Clase 060 - Animación 3D: esqueletos, skinning y AnimationPlayer](../060-animacion-3d-esqueletos-skinning-y-animationplayer/README.md)
