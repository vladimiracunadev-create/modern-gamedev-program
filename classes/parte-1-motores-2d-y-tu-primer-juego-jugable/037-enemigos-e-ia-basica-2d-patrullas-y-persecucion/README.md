# Clase 037 — Enemigos e IA básica 2D: patrullas y persecución

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4*
> ⏱️ Duración estimada: **95 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Construir un enemigo con inteligencia artificial básica en 2D. Será un `CharacterBody2D` que **patrulla** entre bordes, **detecta** al jugador mediante un `Area2D` de visión y lo **persigue** cuando entra en su rango, usando `RayCast2D` para no caer de las plataformas.

Al terminar tendrás una escena `Enemigo` reutilizable con su propia máquina de estados (`PATROL`, `CHASE`, `ATTACK`), aplicando el patrón FSM que aprendiste para el jugador. Este enemigo es la primera pieza del sistema de combate que completaremos en las siguientes clases.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Modelar un enemigo como `CharacterBody2D` con FSM propia.
2. Implementar una patrulla que se dé la vuelta al detectar bordes y paredes.
3. Detectar al jugador con un `Area2D` de visión y sus señales `body_entered`/`body_exited`.
4. Perseguir al jugador moviéndose hacia su posición horizontal.
5. Usar `RayCast2D` para consultar el entorno y evitar caídas.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Enemigo como CharacterBody2D | Reutiliza la física de movimiento del jugador. |
| 2 | Patrulla ir y volver | Da vida al nivel sin scripting complejo. |
| 3 | Detección de borde con RayCast2D | Evita que el enemigo se despeñe. |
| 4 | Detección de pared con RayCast2D | Permite girar ante obstáculos. |
| 5 | Área de visión | Define el rango en que el enemigo "ve" al jugador. |
| 6 | Persecución | Convierte al enemigo en una amenaza activa. |
| 7 | FSM del enemigo | Organiza patrulla, persecución y ataque. |
| 8 | Capas y máscaras de colisión | Aseguran que solo el jugador dispare la visión. |

## 📖 Definiciones y características

- **CharacterBody2D**: cuerpo cinemático controlado por código. Clave: `move_and_slide()` mueve según `velocity`.
- **RayCast2D**: nodo que lanza un rayo y reporta si colisiona. Clave: `is_colliding()` se consulta tras `_physics_process`.
- **Area2D de visión**: zona sin física sólida que detecta cuerpos que entran. Clave: emite `body_entered` con el cuerpo detectado.
- **Patrulla**: recorrido de vaivén entre límites. Clave: invierte la dirección al faltar suelo o topar pared.
- **Persecución**: movimiento dirigido hacia el objetivo. Clave: usa el signo de la diferencia de posición.
- **Máscara de colisión**: define qué capas detecta un nodo. Clave: sin la máscara correcta la visión no dispara.
- **Objetivo (target)**: referencia al jugador detectado. Clave: se guarda al entrar y se limpia al salir.
- **Estado ATTACK**: fase previa al daño por contacto. Clave: la resolución de daño llega en la clase siguiente.

## 🧰 Herramientas y preparación

Trabaja en `PlataformasCurso`. Necesitas la escena `Jugador` en el grupo `"jugador"` o en una capa de colisión propia (por ejemplo la capa 2, "Player"). Configura en **Project Settings > Layer Names > 2D Physics** nombres claros: capa 1 `World`, capa 2 `Player`, capa 3 `Enemy`. Consulta la documentación de `RayCast2D` (<https://docs.godotengine.org/en/stable/classes/class_raycast2d.html>) y de `Area2D` (<https://docs.godotengine.org/en/stable/classes/class_area2d.html>).

Añade al `Jugador` al grupo `jugador` desde la pestaña **Node > Groups** para identificarlo con facilidad desde el enemigo.

## 🧪 Laboratorio guiado

Crearemos una escena `Enemigo` que patrulla, detecta y persigue.

1. Crea una nueva escena con raíz `CharacterBody2D` llamada `Enemigo`. Añade como hijos: `AnimatedSprite2D`, `CollisionShape2D`, dos `RayCast2D` (`RayoSuelo` y `RayoPared`) y un `Area2D` llamado `Vision` con su propio `CollisionShape2D`. Configura la capa del enemigo en 3 y en `Vision` la **máscara** solo en la capa 2 (Player).

2. Orienta los rayos: `RayoPared` con `target_position = (16, 0)` (hacia delante) y `RayoSuelo` con `target_position = (16, 20)` (hacia delante y abajo, para "sentir" el borde). Guarda la escena como `escenas/enemigo.tscn`.

3. Añade el script al nodo raíz con el `enum`, constantes y referencias.

```gdscript
extends CharacterBody2D

enum Estado { PATROL, CHASE, ATTACK }

const VELOCIDAD_PATRULLA := 45.0
const VELOCIDAD_PERSECUCION := 80.0
const GRAVEDAD := 900.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var rayo_pared: RayCast2D = $RayoPared
@onready var rayo_suelo: RayCast2D = $RayoSuelo
@onready var vision: Area2D = $Vision

var estado: Estado = Estado.PATROL
var direccion: int = 1
var objetivo: Node2D = null
```

4. Conecta las señales del área de visión en `_ready` y define sus manejadores. Al entrar el jugador pasamos a `CHASE`; al salir volvemos a `PATROL`.

```gdscript
func _ready() -> void:
	vision.body_entered.connect(_on_vision_body_entered)
	vision.body_exited.connect(_on_vision_body_exited)

func _on_vision_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		objetivo = body
		estado = Estado.CHASE

func _on_vision_body_exited(body: Node2D) -> void:
	if body == objetivo:
		objetivo = null
		estado = Estado.PATROL
```

5. Implementa `_physics_process`: gravedad, despacho por estado, orientación de sprite y rayos según `direccion`, y movimiento.

```gdscript
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVEDAD * delta

	match estado:
		Estado.PATROL:
			_patrullar()
		Estado.CHASE:
			_perseguir()
		Estado.ATTACK:
			velocity.x = 0.0

	sprite.flip_h = direccion < 0
	rayo_pared.target_position.x = 16 * direccion
	rayo_suelo.target_position.x = 16 * direccion
	move_and_slide()
```

6. Escribe la patrulla. Si no hay suelo delante (borde) o hay pared, invierte la dirección.

```gdscript
func _patrullar() -> void:
	velocity.x = direccion * VELOCIDAD_PATRULLA
	sprite.play("walk")
	var hay_borde := not rayo_suelo.is_colliding()
	var hay_pared := rayo_pared.is_colliding()
	if is_on_floor() and (hay_borde or hay_pared):
		direccion *= -1
```

7. Escribe la persecución: acércate al jugador en horizontal; si desaparece la referencia, vuelve a patrullar.

```gdscript
func _perseguir() -> void:
	if objetivo == null:
		estado = Estado.PATROL
		return
	sprite.play("walk")
	direccion = 1 if objetivo.global_position.x > global_position.x else -1
	velocity.x = direccion * VELOCIDAD_PERSECUCION
	if abs(objetivo.global_position.x - global_position.x) < 12.0:
		estado = Estado.ATTACK
```

8. Instancia varios `Enemigo` en tu nivel, colócalos sobre plataformas y ejecuta. Verifica que patrullan sin caerse, giran al llegar a una pared y te persiguen al entrar en su rango de visión.

## ✍️ Ejercicios

1. Dibuja un `CollisionShape2D` con forma de sector amplio para que la visión sea un cono frontal.
2. Añade un temporizador que, tras 2 s sin ver al jugador, regrese lentamente al punto de patrulla original.
3. Reproduce una animación `alert` de medio segundo al pasar de PATROL a CHASE.
4. Limita la persecución a la plataforma actual: si aparece un borde, no lo cruces aunque persigas.
5. Expón `@export var velocidad_persecucion` para ajustar la dificultad por instancia sin tocar el script.
6. Haz que el enemigo mire en la dirección de patrulla inicial según un `@export var direccion_inicial`.

## 📝 Reto verificable

Crea un segundo tipo de enemigo "volador" que ignore la gravedad y los `RayCast2D`, patrulle entre dos `Marker2D` colocados en la escena del nivel y, al detectar al jugador, lo persiga en las dos dimensiones (X e Y) hasta cierta distancia. **Criterio de aceptación**: el enemigo volador oscila entre ambos marcadores en bucle, al entrar el jugador en su visión cambia a persecución diagonal siguiéndolo, y al salir del rango retoma la patrulla entre los marcadores sin quedarse atascado.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| La visión nunca dispara | La máscara de `Vision` no incluye la capa del jugador; corrígela en el inspector. |
| El enemigo se cae de la plataforma | `RayoSuelo` mal orientado o sin llegar al suelo; ajusta su `target_position`. |
| `body_entered` detecta al propio enemigo | El área también mira su capa; deja la máscara solo en Player. |
| Gira en el sitio sin avanzar | Invierte dirección cada frame porque el rayo topa consigo mismo; aléjalo del cuerpo. |
| Persigue aun fuera de pantalla | No limpias `objetivo` en `body_exited`; compara `body == objetivo`. |

## ❓ Preguntas frecuentes

**❓ ¿Área de visión o distancia para detectar?** El `Area2D` es más natural y barato: solo reacciona cuando el jugador entra. La distancia por código sirve si quieres un radio omnidireccional exacto.

**❓ ¿Por qué dos RayCast2D y no uno?** Uno mira la pared (frente) y otro el borde (frente-abajo). Cumplen roles distintos y combinarlos en uno daría lecturas ambiguas.

**❓ ¿Debo activar el rayo con `force_raycast_update`?** Solo si necesitas su lectura el mismo frame en que lo mueves. En patrulla normal basta con leerlo en el siguiente `_physics_process`.

**❓ ¿El estado ATTACK ya hace daño?** Todavía no. Aquí solo detiene al enemigo junto al jugador; el daño real lo implementaremos con hitbox/hurtbox en la clase 038.

## 🔗 Referencias

- Godot — RayCast2D: <https://docs.godotengine.org/en/stable/classes/class_raycast2d.html>
- Godot — Area2D: <https://docs.godotengine.org/en/stable/classes/class_area2d.html>
- Godot — Physics introduction (capas y máscaras): <https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html>
- Godot — CharacterBody2D: <https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html>

## ➡️ Siguiente clase

[Clase 038 - Salud, daño y combate 2D](../038-salud-dano-y-combate-2d/README.md)
