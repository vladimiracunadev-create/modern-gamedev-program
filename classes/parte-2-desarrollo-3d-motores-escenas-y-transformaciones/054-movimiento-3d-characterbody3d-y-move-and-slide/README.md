# Clase 054 — Movimiento 3D: CharacterBody3D y move_and_slide

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Godot Engine 4 — Documentación oficial: Using CharacterBody2D/3D*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Mover un personaje por un entorno 3D en Godot 4 usando **CharacterBody3D**: aplicar **gravedad** al vector `velocity`, desplazar con teclado mediante `Input.get_vector`, hacer que el movimiento sea **relativo a la cámara**, añadir **salto** y resolver colisiones con `move_and_slide()`.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Configurar un `CharacterBody3D` con su `CollisionShape3D` de cápsula.
2. Aplicar gravedad al eje Y de `velocity` usando la constante del proyecto.
3. Leer entrada de teclado con `Input.get_vector` y convertirla en dirección 3D.
4. Orientar el movimiento respecto a la cámara para un control intuitivo.
5. Implementar salto y desplazamiento resolviendo colisiones con `move_and_slide()`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | CharacterBody3D | Cuerpo pensado para personajes controlados por código. |
| 2 | velocity (Vector3) | Almacena la velocidad que `move_and_slide` aplica. |
| 3 | Gravedad del proyecto | Mantener coherencia física con el resto del juego. |
| 4 | Input.get_vector | Lee ejes de movimiento normalizados de una vez. |
| 5 | Movimiento relativo a cámara | Que "adelante" sea hacia donde mira la cámara. |
| 6 | is_on_floor | Saber si el personaje pisa suelo para saltar. |
| 7 | Salto | Impulso vertical controlado. |
| 8 | move_and_slide | Mueve y desliza el cuerpo resolviendo colisiones. |

## 📖 Definiciones y características

- **CharacterBody3D**: cuerpo cinemático para personajes; no lo empuja la física, lo mueves tú. Clave: expone `velocity` y `move_and_slide()`.
- **velocity**: propiedad `Vector3` que representa unidades por segundo. Clave: `move_and_slide()` la usa y actualiza tras colisiones.
- **move_and_slide()**: mueve el cuerpo según `velocity` y desliza sobre superficies. Clave: en Godot 4 se llama **sin argumentos**.
- **is_on_floor()**: devuelve `true` si el cuerpo toca suelo. Clave: requiere haber llamado `move_and_slide()` antes.
- **Input.get_vector**: retorna un `Vector2` combinando cuatro acciones. Clave: normaliza diagonales automáticamente.
- **Gravedad del proyecto**: valor en `physics/3d/default_gravity`. Clave: se lee con `ProjectSettings.get_setting(...)`.
- **transform.basis**: base de orientación del nodo. Clave: `-basis.z` es el "adelante" local.
- **up_direction**: eje que `move_and_slide` considera "arriba". Clave: por defecto `Vector3.UP`, define qué es suelo.

## 🧰 Herramientas y preparación

Usa **Godot 4.x** con un suelo (`StaticBody3D` con `CollisionShape3D` de caja o plano) y una cámara que mire al personaje. Define en el **Input Map** cuatro acciones: `mover_izquierda`, `mover_derecha`, `mover_adelante`, `mover_atras`, y una acción `saltar`. Revisa la guía en <https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html> (aplica igual a 3D) y la API en <https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html>. Motor: <https://godotengine.org/download>.

## 🧪 Laboratorio guiado

1. Crea una escena con raíz `CharacterBody3D` llamada `Jugador`. Añádele un `CollisionShape3D` con forma **CapsuleShape3D** y un `MeshInstance3D` con una cápsula visible.
2. Añade un `Camera3D` como hijo, ligeramente atrás y arriba (`position = Vector3(0, 3, 6)`, mirando al jugador), o usa una cámara externa fija por ahora.
3. Coloca al jugador sobre un suelo con colisión en la escena principal.
4. Asigna este script al nodo `Jugador`:

```gdscript
extends CharacterBody3D

@export var velocidad: float = 5.0
@export var fuerza_salto: float = 4.5

# Gravedad tomada de la configuración del proyecto para coherencia física.
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camara: Camera3D = $Camera3D

func _physics_process(delta: float) -> void:
	# 1. Aplicar gravedad si no está en el suelo.
	if not is_on_floor():
		velocity.y -= gravedad * delta

	# 2. Salto.
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = fuerza_salto

	# 3. Leer entrada (x = izquierda/derecha, y = adelante/atras).
	var entrada := Input.get_vector("mover_izquierda", "mover_derecha",
		"mover_adelante", "mover_atras")

	# 4. Convertir a dirección relativa a la cámara (ignorando la inclinación).
	var adelante := camara.global_transform.basis.z
	var derecha := camara.global_transform.basis.x
	adelante.y = 0.0
	derecha.y = 0.0
	adelante = adelante.normalized()
	derecha = derecha.normalized()

	# entrada.y positivo = atras; adelante local de la cámara es -z.
	var direccion := (derecha * entrada.x - adelante * entrada.y).normalized()

	# 5. Aplicar velocidad horizontal.
	if direccion != Vector3.ZERO:
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
	else:
		velocity.x = move_toward(velocity.x, 0.0, velocidad)
		velocity.z = move_toward(velocity.z, 0.0, velocidad)

	# 6. Mover y resolver colisiones (sin argumentos en Godot 4).
	move_and_slide()
```

5. Ejecuta. Muévete con las teclas asignadas: la cápsula se desplaza en el plano, cae por gravedad y salta al pulsar `saltar` solo si pisa el suelo.
6. Observa que "adelante" siempre es hacia donde apunta la cámara, gracias a la proyección de la base sobre el plano horizontal.

## ✍️ Ejercicios

1. Añade una velocidad de carrera con `Shift` que multiplique `velocidad`.
2. Implementa doble salto contando cuántas veces se ha saltado en el aire.
3. Suaviza la aceleración usando `move_toward` también al arrancar.
4. Muestra en pantalla si `is_on_floor()` es verdadero o falso.
5. Limita la velocidad máxima horizontal con `Vector2(velocity.x, velocity.z).limit_length()`.
6. Añade una rampa al escenario y verifica que el personaje la sube deslizando.

## 📝 Reto verificable

Crea un nivel con suelo, una rampa y un escalón bajo. El personaje debe moverse relativo a la cámara con WASD, saltar solo desde el suelo y subir la rampa sin atravesarla, usando gravedad del proyecto y `move_and_slide()` sin argumentos.

**Criterio de aceptación**: el personaje camina en todas direcciones respecto a la cámara, cae por gravedad, salta únicamente pisando suelo y sube la rampa sin quedar atascado ni traspasar geometría.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| `move_and_slide()` da error de argumentos | En Godot 4 se llama sin parámetros; quita los argumentos del estilo Godot 3. |
| El personaje atraviesa el suelo | Falta `CollisionShape3D` en el jugador o en el suelo. |
| `is_on_floor()` siempre falso | Se consulta antes de `move_and_slide()`; muévelo después. |
| El salto se dispara en el aire | No verificas `is_on_floor()` antes de saltar. |
| Adelante no coincide con la cámara | No proyectas la base al plano (falta poner `y = 0` y normalizar). |
| Se cae muy lento o muy rápido | Gravedad mal leída; usa `physics/3d/default_gravity`. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué `move_and_slide()` ya no lleva argumentos?** En Godot 4 la velocidad se guarda en la propiedad `velocity` del nodo, así que el método la lee directamente.

**❓ ¿Cuál es el "adelante" de la cámara?** En espacio local el frente es `-basis.z`; por eso restamos `adelante * entrada.y` tras proyectar al plano.

**❓ ¿Debo mover en `_process` o `_physics_process`?** En `_physics_process`, porque el movimiento físico debe ir a paso fijo y consistente.

**❓ ¿Cómo evito diagonales más rápidas?** `Input.get_vector` ya normaliza el vector de entrada, y volvemos a normalizar la dirección resultante.

## 🔗 Referencias

- CharacterBody3D — API oficial: <https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html>
- Using CharacterBody: <https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html>
- Input examples: <https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html>

## ⬅️ Clase anterior

[Clase 053 - WorldEnvironment: cielo, niebla y tonemapping](../053-worldenvironment-cielo-niebla-y-tonemapping/README.md)

## ➡️ Siguiente clase

[Clase 055 - Controlador en primera persona (FPS)](../055-controlador-en-primera-persona-fps/README.md)
