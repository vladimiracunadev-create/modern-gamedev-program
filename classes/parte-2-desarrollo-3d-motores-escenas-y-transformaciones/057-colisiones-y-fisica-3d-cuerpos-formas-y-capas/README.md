# Clase 057 — Colisiones y física 3D: cuerpos, formas y capas

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot Engine 4.x — Physics introduction*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Entender los tres tipos de cuerpo físico en 3D de Godot 4 (`StaticBody3D`, `CharacterBody3D`, `RigidBody3D`), aprender a asignarles la forma de colisión adecuada con `CollisionShape3D`, y organizar el escenario con capas y máscaras nombradas para que cada elemento colisione solo con lo que debe.

Estos son los cimientos de cualquier juego 3D jugable: sin colisiones bien montadas, el personaje atraviesa paredes, los objetos se cuelan por el suelo y el rendimiento se hunde. Al terminar tendrás un nivel de prueba funcional y un criterio claro para decidir cuerpo y forma en cada situación.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Elegir el tipo de cuerpo correcto (estático, cinemático o dinámico) según el rol del objeto.
- Asignar formas primitivas (box, sphere, capsule) y compuestas (convex, trimesh) con criterio de rendimiento.
- Explicar por qué el suelo estático usa `trimesh` y un objeto móvil nunca debería usarla.
- Nombrar las capas de física 3D en Project Settings y aplicarlas con `collision_layer` / `collision_mask`.
- Montar un nivel jugable con suelo, obstáculos y un personaje con cápsula que colisiona correctamente.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | StaticBody3D | Geometría fija del mundo: suelos, muros, rampas |
| 2 | CharacterBody3D | Movimiento controlado por código, base del personaje jugable |
| 3 | RigidBody3D | Objetos simulados por el motor de física |
| 4 | CollisionShape3D | Toda colisión necesita una forma; sin ella no hay contacto |
| 5 | Formas primitivas | Box/Sphere/Capsule son baratas y estables |
| 6 | Convex vs Trimesh | Decisión clave entre precisión y coste/estabilidad |
| 7 | Capas y máscaras | Controlan qué colisiona con qué sin código |
| 8 | Nombres de capas 3D | Legibilidad y mantenimiento del proyecto |

## 📖 Definiciones y características

- **StaticBody3D**: cuerpo que no se mueve por física. Clave: ideal para geometría del nivel; puede usar `trimesh` porque nunca colisiona contra otro trimesh.
- **CharacterBody3D**: cuerpo cinemático movido con `velocity` y `move_and_slide()`. Clave: no reacciona a fuerzas; tú decides su velocidad cada frame.
- **RigidBody3D**: cuerpo dinámico simulado (gravedad, impulsos, rebotes). Clave: no muevas su `position` a mano; usa fuerzas o impulsos.
- **CollisionShape3D**: nodo hijo que aporta la forma de colisión. Clave: sin al menos un `CollisionShape3D` con `shape` asignado, el cuerpo no colisiona.
- **Forma convex**: envoltura convexa que aproxima una malla. Clave: barata y estable para objetos dinámicos; no reproduce concavidades.
- **Forma trimesh (ConcavePolygonShape3D)**: colisión triángulo a triángulo de la malla. Clave: precisa pero solo válida en cuerpos estáticos.
- **collision_layer**: bitmask que indica en qué capas *está* el cuerpo. Clave: "quién soy".
- **collision_mask**: bitmask que indica con qué capas *choca* el cuerpo. Clave: "con quién me importa chocar".

## 🧰 Herramientas y preparación

Necesitas Godot 4.x y un proyecto 3D. Abre **Project > Project Settings > General > Layer Names > 3D Physics** para renombrar las capas 1, 2 y 3 como `World`, `Player` y `Enemy`. Ten a mano un `MeshInstance3D` con un plano o un modelo de suelo. Activa **Debug > Visible Collision Shapes** para ver las formas mientras pruebas. Consulta la [introducción a física](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html) y [collision layers and masks](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html#collision-layers-and-masks).

Regla mental para elegir cuerpo: si el objeto **nunca se mueve**, `StaticBody3D`; si lo mueves tú con lógica de juego (el personaje jugable, plataformas controladas), `CharacterBody3D`; si quieres que el motor lo simule con gravedad, choques y rebotes (barriles, escombros, proyectiles físicos), `RigidBody3D`. Esta decisión condiciona qué forma de colisión puedes usar después.

## 🧪 Laboratorio guiado

Montaremos un nivel: suelo con colisión trimesh, dos obstáculos estáticos y un personaje con cápsula.

**1) Nombrar las capas.** En Project Settings > Layer Names > 3D Physics, escribe: capa 1 = `World`, capa 2 = `Player`, capa 3 = `Enemy`.

**2) Suelo estático con trimesh.** Crea un `StaticBody3D` llamado `Suelo` con un `MeshInstance3D` (un `PlaneMesh` grande o modelo importado). Añade un `CollisionShape3D`. En el inspector, con el `MeshInstance3D` seleccionado, usa el menú **Mesh > Create Trimesh Static Body** o asigna manualmente un `ConcavePolygonShape3D` generado desde la malla. En el `StaticBody3D`, activa solo la capa `World` en `collision_layer`.

**3) Obstáculos.** Añade dos `StaticBody3D` con `BoxShape3D`, situados sobre el suelo, también en la capa `World`.

**4) Personaje con cápsula.** Crea un `CharacterBody3D` llamado `Jugador`, con `MeshInstance3D` (una cápsula visual) y un `CollisionShape3D` con `CapsuleShape3D` (radio 0.4, altura 1.8). Ponlo en `collision_layer = Player` y `collision_mask = World` (choca con el mundo, no consigo mismo). Añade un `Camera3D` como hijo a la altura de los ojos.

La cápsula es la forma preferida para personajes porque su base redondeada sube escalones y bordes sin engancharse, algo que una caja hace mal. Mantén el radio menor que la mitad del ancho de los pasillos más estrechos por los que deba pasar.

**5) Script de movimiento mínimo.** Adjunta al `Jugador`:

```gdscript
extends CharacterBody3D

@export var velocidad := 5.0
@export var gravedad := 20.0

func _physics_process(delta: float) -> void:
	# Gravedad manual
	if not is_on_floor():
		velocity.y -= gravedad * delta
	else:
		velocity.y = 0.0

	# Entrada horizontal (define ui_left/right/up/down o teclas WASD)
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var mov := (transform.basis * Vector3(dir.x, 0.0, dir.y)).normalized()
	velocity.x = mov.x * velocidad
	velocity.z = mov.z * velocidad

	move_and_slide()

	# Reportar contra qué chocamos este frame
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		print("Choque contra: ", col.get_collider().name)
```

**6) Observable.** Ejecuta la escena. El personaje camina por el suelo trimesh, no atraviesa las cajas y la consola imprime el nombre del cuerpo contra el que choca. Si desactivas la capa `World` en el `collision_mask` del jugador, caerá al vacío: prueba de que la máscara controla las colisiones.

**7) Experimento de máscaras.** Añade un `StaticBody3D` extra en la capa `Enemy` en medio del camino. Mientras la máscara del jugador no incluya `Enemy`, lo atravesará; al activar `Enemy` en su `collision_mask`, empezará a chocar contra él. Este pequeño cambio, sin tocar código, demuestra por qué las capas nombradas son la herramienta central para organizar las colisiones de un nivel.

## ✍️ Ejercicios

1. Cambia la forma del personaje de cápsula a caja y observa cómo sube/baja escalones y bordes de forma distinta.
2. Añade una tercera capa `Enemy` y crea un `StaticBody3D` en esa capa; ajusta la máscara del jugador para que lo ignore y luego para que choque.
3. Sustituye el suelo trimesh por un `BoxShape3D` gigante y comenta las diferencias de coste que esperarías en un nivel grande.
4. Intenta asignar un `ConcavePolygonShape3D` a un `RigidBody3D` y anota el aviso o comportamiento que produce Godot.
5. Usa `Debug > Visible Collision Shapes` en el menú y verifica visualmente cada forma.
6. Añade un `CollisionShape3D` extra al personaje (por ejemplo, un sensor bajo los pies) y describe cuándo tendría sentido.

## 📝 Reto verificable

Construye un pequeño patio cerrado: suelo trimesh, cuatro muros `StaticBody3D` con `BoxShape3D` y un personaje con cápsula que puede recorrerlo sin salirse. Nombra las capas `World` y `Player`, y configura las máscaras para que el personaje solo colisione con `World`. Añade una rampa de acceso (otro `StaticBody3D`) por la que el personaje pueda subir sin quedarse atascado.

**Criterio de aceptación**: el personaje se mueve dentro del patio, no atraviesa ningún muro ni el suelo, y con `Visible Collision Shapes` activo se ven la cápsula y las cajas; la consola muestra el nombre del muro al empujarlo.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El personaje atraviesa el suelo | Falta `CollisionShape3D` con `shape`, o la máscara no incluye `World`. Asigna forma y ajusta `collision_mask`. |
| El objeto no colisiona con nada | `collision_layer` o `collision_mask` en 0. Activa las capas correctas en el inspector. |
| FPS bajos con muchos objetos | Uso de `trimesh` en cuerpos móviles. Cambia a `convex` o a una primitiva. |
| Trimesh no colisiona contra otro trimesh | Es una limitación del motor: dos concave no chocan. Usa convex/primitiva en al menos uno. |
| El personaje "vibra" contra el suelo | Cápsula demasiado hundida o `velocity.y` sin resetear en suelo. Ajusta altura y pon `velocity.y = 0`. |
| Dos cuerpos que deberían chocar se ignoran | Las máscaras no son recíprocas donde hace falta. Recuerda: A choca con B si `A.mask` incluye la capa de B. |
| La forma no aparece en el editor | El `CollisionShape3D` no tiene `shape` asignado. Crea la `Shape` en el inspector. |

## ❓ Preguntas frecuentes

**¿Puedo mover un `StaticBody3D` por código?** Puedes cambiar su transform, pero el motor no lo trata como movimiento físico; para plataformas móviles usa `AnimatableBody3D`.

**¿Por qué mi `move_and_slide()` no acepta parámetros?** En Godot 4 usa `velocity` (propiedad) y se llama sin argumentos, a diferencia de Godot 3.

**¿Cuántas capas puedo nombrar?** Hay 32 capas de física 3D; nómbralas para no perderte con los bits.

**¿Convex o varias primitivas?** Para formas simples, varias primitivas (varios `CollisionShape3D`) suelen ser más estables y baratas que una convex generada. Reserva las convex generadas automáticamente para piezas cuya silueta no puedas aproximar bien con cajas y esferas.

**¿Puedo tener varias formas en un mismo cuerpo?** Sí: añade varios `CollisionShape3D` como hijos y el cuerpo las combinará como una sola colisión compuesta.

**¿La escala del nodo afecta a la forma?** Escalar el cuerpo deforma las formas y puede desestabilizar la física; ajusta el tamaño en las propiedades de la `Shape`, no con `scale`.

## 🔗 Referencias

- [Physics introduction — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html)
- [Using CharacterBody2D/3D](https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html)
- [Collision shapes (3D)](https://docs.godotengine.org/en/stable/tutorials/physics/collision_shapes_3d.html)

## ➡️ Siguiente clase

[Clase 058 - RigidBody3D, fuerzas e interacción física](../058-rigidbody3d-fuerzas-e-interaccion-fisica/README.md)
