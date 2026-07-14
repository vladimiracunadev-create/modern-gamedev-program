# Clase 058 — RigidBody3D, fuerzas e interacción física

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot Engine 4.x — RigidBody3D*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dominar el cuerpo dinámico `RigidBody3D`: cómo la masa, la fricción y el rebote (`PhysicsMaterial`) modelan su comportamiento, y cómo aplicarle impulsos y fuerzas (`apply_central_impulse`, `apply_force`) para empujar, disparar y derribar objetos de forma realista.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Distinguir cuándo conviene `RigidBody3D` frente a `CharacterBody3D`.
- Configurar masa, `linear_damp`, fricción y rebote mediante `PhysicsMaterial`.
- Aplicar impulsos instantáneos y fuerzas continuas y saber cuándo usar cada uno.
- Hacer que un `CharacterBody3D` empuje objetos dinámicos a través de las colisiones.
- Construir y derribar una torre de cajas disparando una esfera con impulso.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | RigidBody3D vs CharacterBody3D | Simulación automática vs control manual |
| 2 | Masa e inercia | Determinan cuánto cuesta mover el objeto |
| 3 | PhysicsMaterial | Fricción y rebote realistas |
| 4 | apply_central_impulse | Cambio de velocidad instantáneo (disparos, golpes) |
| 5 | apply_force / apply_central_force | Empuje continuo (viento, motores) |
| 6 | Damping | Frenado del movimiento y giro |
| 7 | Empuje por contacto | Interacción CharacterBody3D → RigidBody3D |
| 8 | Modos de RigidBody3D | freeze, sleeping y su efecto en rendimiento |

## 📖 Definiciones y características

- **RigidBody3D**: cuerpo cuyo movimiento resuelve el motor a partir de fuerzas, gravedad y colisiones. Clave: nunca fijes su `global_position` cada frame; rompes la simulación.
- **mass**: masa en kg del cuerpo. Clave: a mayor masa, más impulso hace falta para moverlo la misma cantidad.
- **PhysicsMaterial**: recurso con `friction` (0–1) y `bounce` (0–1). Clave: se asigna en la propiedad `physics_material_override`.
- **apply_central_impulse(v)**: suma un impulso (Vector3) al centro de masa, cambiando la velocidad al instante. Clave: úsalo una sola vez, ideal para disparos o saltos.
- **apply_central_force(v)**: aplica fuerza continua cada frame de física. Clave: llámalo en `_physics_process`; su efecto depende de la masa.
- **linear_damp / angular_damp**: amortiguación del movimiento lineal y de giro. Clave: valores altos frenan el objeto sin colisiones.
- **freeze**: congela la simulación del cuerpo. Clave: útil para "activar" cajas solo cuando hace falta.
- **can_sleep**: permite que el cuerpo se duerma al detenerse. Clave: ahorra CPU en escenas con muchos objetos.

## 🧰 Herramientas y preparación

Godot 4.x con un nivel base (suelo `StaticBody3D` de la clase anterior sirve). Prepara una escena reutilizable `Caja.tscn` con `RigidBody3D` + `MeshInstance3D` (`BoxMesh`) + `CollisionShape3D` (`BoxShape3D`). Crea un `PhysicsMaterial` en el sistema de archivos. Revisa la [referencia de RigidBody3D](https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html) y [Physics materials](https://docs.godotengine.org/en/stable/classes/class_physicsmaterial.html).

## 🧪 Laboratorio guiado

Construiremos una torre de cajas y una esfera-proyectil que las derriba.

**1) La caja reutilizable.** Crea `Caja.tscn`: raíz `RigidBody3D` (`mass = 1.0`), hijo `MeshInstance3D` con `BoxMesh` (0.5³) y `CollisionShape3D` con `BoxShape3D` de igual tamaño. Asigna un `PhysicsMaterial` con `friction = 0.8`, `bounce = 0.0` en `physics_material_override`.

**2) Apilar la torre por código.** En el nivel, adjunta a un `Node3D` llamado `Torre`:

```gdscript
extends Node3D

@export var caja: PackedScene
@export var filas := 6
@export var lado := 0.5

func _ready() -> void:
	for i in filas:
		var c := caja.instantiate() as RigidBody3D
		add_child(c)
		# Apilar con una pizca de separación para que caigan y asienten
		c.global_position = global_position + Vector3(0, lado * 0.5 + i * lado, 0)
```

Asigna `Caja.tscn` al export `caja`. Al ejecutar, las cajas caen y se asientan formando una torre estable.

**3) El proyectil.** Crea `Proyectil.tscn`: `RigidBody3D` (`mass = 2.0`) con `SphereMesh` y `SphereShape3D`. Añade un script para que se autodestruya:

```gdscript
extends RigidBody3D

func _ready() -> void:
	# Desaparece a los 5 segundos para no acumular objetos
	await get_tree().create_timer(5.0).timeout
	queue_free()
```

**4) Disparar con impulso.** En un nodo controlador con `Camera3D`, añade:

```gdscript
extends Node3D

@export var proyectil: PackedScene
@export var fuerza_disparo := 18.0
@onready var camara: Camera3D = $Camera3D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("disparar"):
		_disparar()

func _disparar() -> void:
	var bala := proyectil.instantiate() as RigidBody3D
	get_tree().current_scene.add_child(bala)
	# Sale desde delante de la cámara, en la dirección a la que mira
	var dir := -camara.global_transform.basis.z
	bala.global_position = camara.global_position + dir * 1.0
	bala.apply_central_impulse(dir * fuerza_disparo * bala.mass)
```

Define la acción `disparar` (clic izquierdo) en Input Map. Al disparar, la esfera vuela y derriba la torre.

**5) Empujar cajas caminando.** Usa el `CharacterBody3D` de la clase 057. Para que empuje las cajas al chocar, tras `move_and_slide()`:

```gdscript
for i in get_slide_collision_count():
	var col := get_slide_collision(i)
	var cuerpo := col.get_collider()
	if cuerpo is RigidBody3D:
		# Empuja en la dirección del choque, escalado por masa
		cuerpo.apply_central_impulse(-col.get_normal() * 2.0)
```

**6) Observable.** Caminas contra la torre y la desplazas; disparas la esfera y las cajas salen volando y ruedan. Sube `bounce` a `0.6` en el `PhysicsMaterial` y observa cómo las cajas rebotan.

## ✍️ Ejercicios

1. Duplica la masa de las cajas y comprueba cuánto más impulso de disparo necesitas para derribarlas.
2. Aplica `apply_central_force` con gravedad invertida a una caja y hazla "flotar".
3. Sube `linear_damp` de las cajas a 3.0 y describe el cambio al empujarlas.
4. Cambia `friction` a 0.0 y observa cómo las cajas patinan por el suelo.
5. Activa `freeze` en las cajas y despiértalas solo cuando el proyectil entra en un `Area3D` cercano.
6. Mide (con `print`) la `linear_velocity` del proyectil justo antes del impacto.

## 📝 Reto verificable

Crea una escena de "bolos": diez cajas apiladas en pirámide y una bola pesada que el jugador dispara desde la cámara con impulso. La bola debe derribar al menos la mitad de las cajas de un disparo bien dirigido, y las cajas deben asentarse y dormirse tras caer.

**Criterio de aceptación**: al disparar, la bola vuela recta desde la cámara, impacta la pirámide y derriba ≥5 cajas; tras unos segundos los cuerpos quedan quietos (dormidos) y el proyectil se autodestruye.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El cuerpo tiembla o atraviesa el suelo | Modificas `position` cada frame en un RigidBody3D. Usa impulsos/fuerzas o `AnimatableBody3D`. |
| El impulso no tiene efecto | Lo aplicas antes de `add_child` (aún fuera del árbol). Añádelo primero, luego aplica el impulso. |
| Las cajas explotan al aparecer | Se instancian solapadas. Sepáralas al apilar (deja holgura). |
| El disparo va en dirección equivocada | Usas `basis.z` en vez de `-basis.z`. En Godot el "adelante" de la cámara es `-Z`. |
| Todo va muy lento | Demasiados cuerpos activos. Activa `can_sleep` y usa `freeze` cuando corresponda. |

## ❓ Preguntas frecuentes

**¿Impulso o fuerza?** Impulso para efectos instantáneos (disparo, golpe); fuerza para empujes sostenidos (viento, motor).

**¿Puedo escalar un RigidBody3D?** Evita escalar el nodo; ajusta el tamaño de la malla y de la forma para no distorsionar la física.

**¿Por qué el empuje del personaje es débil?** `CharacterBody3D` no transmite masa; debes aplicar el impulso tú mismo en las colisiones, como en el lab.

**¿Cómo hago que un objeto sea dinámico solo al tocarlo?** Empiézalo con `freeze = true` y ponlo en `false` cuando entre en juego.

## 🔗 Referencias

- [RigidBody3D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html)
- [PhysicsMaterial — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_physicsmaterial.html)
- [Rigid body physics tutorial](https://docs.godotengine.org/en/stable/tutorials/physics/rigid_body.html)

## ➡️ Siguiente clase

[Clase 059 - Raycasting 3D: selección, disparos y detección de suelo](../059-raycasting-3d-seleccion-disparos-y-deteccion-de-suelo/README.md)
