# Clase 074 — Raycasts y shapecasts: usos avanzados

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Christer Ericson, Real-Time Collision Detection · Documentación oficial de Godot 4 (Ray-casting)*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dominar el uso de rayos y barridos de forma (*shapecasts*) en Godot 4 para resolver problemas frecuentes de jugabilidad: detectar el suelo bajo los pies, distinguir una pared de un borde, comprobar la línea de visión entre un enemigo y el jugador, y verificar si un cuerpo cabe en un hueco antes de moverlo. Vas a combinar nodos `RayCast3D`/`RayCast2D`, `ShapeCast3D` y consultas de rayo por código con `PhysicsRayQueryParameters3D`.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Configurar `RayCast3D` con `target_position`, máscaras de colisión y leer el punto y normal del impacto.
2. Explicar cuándo un rayo (sin grosor) falla y cuándo conviene usar un `ShapeCast3D` que sí tiene volumen.
3. Implementar un detector de bordes que evite que un personaje caiga de una plataforma.
4. Resolver la línea de visión enemigo→jugador filtrando obstáculos con máscaras de colisión.
5. Lanzar rayos por código con `intersect_ray()` sin necesidad de un nodo `RayCast` en la escena.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Rayo vs. barrido de forma | Un rayo es infinitamente fino; puede "colarse" entre geometría |
| 2 | `target_position` es local | Un error de espacio de coordenadas rompe la dirección del rayo |
| 3 | Punto y normal de impacto | La normal decide si una superficie es suelo, rampa o pared |
| 4 | Máscaras y capas de colisión | Filtrar qué detecta cada rayo evita falsos positivos |
| 5 | Detección de bordes | Base de la IA que no se tira al vacío y del *ledge grab* |
| 6 | Línea de visión (LoS) | Núcleo del sigilo y de la percepción de enemigos |
| 7 | `ShapeCast3D` para huecos | Comprobar si un cuerpo *cabe* antes de teletransportarlo |
| 8 | Consultas por código | Rayos puntuales sin ensuciar el árbol de nodos |

## 📖 Definiciones y características

- **RayCast3D/2D**: nodo que proyecta un segmento desde su origen hasta `target_position` (en espacio local) cada fotograma de física.
- **is_colliding()**: devuelve `true` si el rayo tocó algo dentro de su alcance en el último *tick* de física.
- **get_collision_point()**: punto global exacto del primer impacto; **get_collision_normal()**: vector normal de la superficie tocada.
- **ShapeCast3D**: barre una *forma* (esfera, cápsula, caja) a lo largo de un vector; detecta como si moviéramos un volumen, no un punto.
- **Máscara de colisión** (`collision_mask`): conjunto de capas que el rayo *puede* golpear; todo lo demás lo ignora.
- **PhysicsRayQueryParameters3D**: describe un rayo (origen, fin, máscara, exclusiones) para una consulta puntual vía `direct_space_state`.
- **collide_with_areas / collide_with_bodies**: banderas que deciden si el rayo detecta `Area3D`, cuerpos físicos, o ambos.
- **exclude**: lista de RIDs a ignorar; imprescindible para que un rayo no se golpee a sí mismo.

## 🧰 Herramientas y preparación

Necesitas Godot 4.2 o superior. Crea una escena 3D con un `CharacterBody3D` (el personaje), un piso de `StaticBody3D` con huecos y algunas paredes. Activa **Debug → Visible Collision Shapes** para ver los rayos dibujados en tiempo de ejecución; es la herramienta más útil de esta clase porque los rayos mal orientados se detectan a simple vista. Repasa la documentación oficial de *Ray-casting* y la de `ShapeCast3D`. Consulta: <https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html> y <https://docs.godotengine.org/en/stable/classes/class_shapecast3d.html>.

## 🧪 Laboratorio guiado

### Paso 1 — Detector de bordes con RayCast3D

Coloca dos `RayCast3D` como hijos del personaje, uno frente a cada pie, apuntando hacia abajo. Si un rayo deja de golpear el suelo, ese pie está sobre el vacío.

```gdscript
extends CharacterBody3D

@onready var borde_frontal: RayCast3D = $BordeFrontal

func _physics_process(_delta: float) -> void:
	# target_position es LOCAL: 1.5 m hacia abajo desde el nodo.
	borde_frontal.target_position = Vector3(0, -1.5, 0)
	borde_frontal.force_raycast_update() # actualiza ya, sin esperar al tick

	if not borde_frontal.is_colliding():
		# No hay suelo delante: freno el avance para no caer.
		velocity.x = 0.0
		velocity.z = 0.0
		print("¡Borde detectado! Detengo el avance.")
```

**Observable**: mueve el personaje hacia el hueco del piso; en cuanto el rayo frontal pierde el suelo, el avance se detiene y verás el mensaje en consola.

### Paso 2 — Línea de visión con máscara de obstáculos

El enemigo lanza un rayo hacia el jugador. Si el rayo llega al jugador sin chocar antes con una pared, hay visión directa. Usamos una consulta por código para no depender de un nodo.

```gdscript
extends Node3D

@export var jugador: Node3D
@export var mascara_obstaculos: int = 1 # capa de paredes/entorno

func hay_linea_de_vision() -> bool:
	var espacio := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position, jugador.global_position)
	query.collision_mask = mascara_obstaculos
	query.exclude = [self.get_rid()] # no golpearme a mí mismo

	var res := espacio.intersect_ray(query)
	# Sin impacto = nada bloquea = veo al jugador.
	# Con impacto = una pared se interpuso antes.
	return res.is_empty()
```

**Observable**: al esconder al jugador tras una pared (que esté en la capa de obstáculos) la función devuelve `false`; al salir a campo abierto devuelve `true`.

### Paso 3 — ShapeCast3D: ¿cabe el salto?

Antes de teletransportar al personaje a un hueco estrecho, barremos una cápsula del tamaño del cuerpo. Si el barrido colisiona, el personaje no cabe.

```gdscript
@onready var barrido: ShapeCast3D = $ShapeCast3D

func puede_ocupar(destino_local: Vector3) -> bool:
	barrido.target_position = destino_local
	barrido.force_shapecast_update()
	# is_colliding() true = la forma chocó por el camino: NO cabe.
	return not barrido.is_colliding()
```

Asigna al `ShapeCast3D` una `CapsuleShape3D` con el radio y alto del personaje. **Observable**: apunta el barrido a un pasadizo más angosto que la cápsula y la función devuelve `false`; ensancha el pasadizo y devuelve `true`.

## ✍️ Ejercicios

1. Añade un segundo rayo de borde en el pie trasero y solo frena si **ambos** pies pierden el suelo (permite asomarse al borde).
2. Dibuja con `DebugDraw` o un `MeshInstance3D` una esfera en `get_collision_point()` para visualizar dónde impacta cada rayo.
3. Usa `get_collision_normal()` para clasificar la superficie: si `normal.y > 0.7` es suelo, si `abs(normal.y) < 0.3` es pared.
4. Convierte la línea de visión en un cono: solo cuenta si el ángulo entre la mirada del enemigo y la dirección al jugador es menor de 45°.
5. Cambia el `ShapeCast3D` por una `BoxShape3D` y compara resultados en un hueco con esquinas.
6. Mide el coste: lanza 100 rayos por código en un bucle y usa el *profiler* para ver cuántos milisegundos consume.

## 📝 Reto verificable

Construye un enemigo patrullero que (a) recorra una plataforma sin caerse gracias a rayos de borde y (b) dispare una alerta solo cuando tenga línea de visión al jugador filtrando paredes con máscara. Cuando pierda la visión, debe seguir patrullando.

**Criterio de aceptación**: el enemigo nunca cae de la plataforma, la alerta se activa únicamente con visión directa (no a través de paredes) y se desactiva al romperse la línea de visión; todo verificable en pantalla con los *collision shapes* visibles.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El rayo no detecta nada | `target_position` está en cero o el rayo apunta al espacio global. Recuerda que es **local**; ajusta la dirección. |
| El rayo se golpea a sí mismo | Falta `exclude`/`add_exception`. Excluye el cuerpo propietario del rayo. |
| Detecta a través de paredes | La `collision_mask` incluye la capa equivocada o ninguna. Configura las capas del entorno. |
| `is_colliding()` va un fotograma tarde | El rayo se actualiza en el *tick* de física. Llama a `force_raycast_update()` tras mover el nodo. |
| El ShapeCast "atraviesa" objetos finos | La forma o el `margin` son demasiado pequeños. Aumenta el radio o el margen. |

## ❓ Preguntas frecuentes

**¿Rayo o shapecast?** Usa rayo para líneas de visión y disparos puntuales; usa shapecast cuando el volumen importe (¿cabe el personaje?, ¿toca el hombro la pared?).

**¿Puedo tener varios impactos con un rayo?** `intersect_ray()` devuelve solo el primero. Para varios usa `ShapeCast3D` (guarda todos) o repite la consulta excluyendo lo ya golpeado.

**¿Por qué mi rayo por código no ve las Area3D?** Por defecto `collide_with_areas` es `false`. Actívalo en los parámetros de la consulta.

**¿El raycast cuesta mucho rendimiento?** Uno es barato; miles por fotograma no. Reutiliza resultados y evita lanzar rayos cada *frame* si no cambia nada.

## 🔗 Referencias

- Godot Docs — Ray-casting: <https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html>
- Godot Docs — ShapeCast3D: <https://docs.godotengine.org/en/stable/classes/class_shapecast3d.html>
- Godot Docs — PhysicsDirectSpaceState3D: <https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate3d.html>
- Christer Ericson, *Real-Time Collision Detection*, cap. 5 (pruebas de intersección de rayos).

## ➡️ Siguiente clase

[Clase 075 - Motores de física: broadphase y narrowphase](../075-motores-de-fisica-broadphase-y-narrowphase/README.md)
