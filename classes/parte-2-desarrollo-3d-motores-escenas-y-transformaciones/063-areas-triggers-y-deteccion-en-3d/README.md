# Clase 063 — Áreas, triggers y detección en 3D

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot 4 — Physics introduction (Area3D)*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Aprender a usar `Area3D` como detector de eventos en el espacio 3D: zonas que reaccionan cuando algo entra o sale de ellas sin bloquear el movimiento como lo haría un muro sólido. Con esta herramienta construirás la lógica invisible que hace vivir un nivel: checkpoints que recuerdan por dónde ibas, zonas de daño que restan vida, puertas que se abren al acercarte y disparadores de eventos.

Al terminar habrás montado una escena jugable con un `CharacterBody3D` que atraviesa tres áreas distintas —un checkpoint, una zona de daño y una puerta automática— y verás por consola y en pantalla cómo cada una responde a tu presencia.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar la diferencia entre un `Area3D` (detección) y un cuerpo sólido (`StaticBody3D`/`CharacterBody3D`) que bloquea el paso.
2. Conectar y usar las señales `body_entered`, `body_exited` y `area_entered` de un `Area3D`.
3. Configurar capas y máscaras de colisión para que un área solo detecte lo que le interesa.
4. Implementar un checkpoint que guarda la última posición segura del jugador.
5. Construir una zona de daño y una puerta automática que reaccionan a la entrada del jugador.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Area3D como disparador | Es el nodo que detecta presencia sin frenar el movimiento. |
| 2 | Señales body_entered / body_exited | Son el mecanismo por el que el área te avisa de quién entra o sale. |
| 3 | CollisionShape3D | Define la forma y el tamaño exacto de la zona detectada. |
| 4 | Capas y máscaras de colisión | Permiten que un área ignore lo que no debe detectar. |
| 5 | monitoring y monitorable | Activan o desactivan la detección de un área en tiempo real. |
| 6 | Checkpoints | Guardan progreso y evitan repetir todo el nivel al morir. |
| 7 | Zonas de daño y puertas | Son los usos clásicos que dan interactividad al nivel. |

## 📖 Definiciones y características

- **Area3D**: nodo que detecta cuándo cuerpos u otras áreas entran o salen de su volumen, sin ejercer colisión física. Clave: no empuja ni detiene, solo informa.
- **CollisionShape3D**: hijo obligatorio de un `Area3D` que define su forma (caja, esfera, cápsula). Clave: sin una forma asignada, el área no detecta nada.
- **body_entered(body)**: señal que se emite cuando un `PhysicsBody3D` (como un `CharacterBody3D`) entra en el área. Clave: recibe como argumento el cuerpo que entró.
- **body_exited(body)**: señal complementaria que se emite al salir. Clave: útil para "apagar" efectos como el daño continuo.
- **Capa de colisión (collision_layer)**: etiqueta que dice "en qué capas existe" un objeto. Clave: es lo que otros detectan de él.
- **Máscara de colisión (collision_mask)**: define "qué capas escanea" un objeto. Clave: un área solo ve capas que estén en su máscara.
- **monitoring**: propiedad booleana que activa o desactiva la detección de un área. Clave: ponerla en `false` desactiva una puerta o trampa ya usada.
- **Checkpoint**: punto de control que guarda una posición de reaparición. Clave: se implementa detectando al jugador con un `Area3D`.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x desde <https://godotengine.org/download>. La referencia central de esta clase es la clase `Area3D` en <https://docs.godotengine.org/en/stable/classes/class_area3d.html> y la introducción a la física en <https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html>. Para entender capas y máscaras revisa <https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html#collision-layers-and-masks>. Reutilizaremos un `CharacterBody3D` simple como jugador; si vienes de clases anteriores puedes emplear el que ya tengas.

## 🧪 Laboratorio guiado

Montaremos un pequeño nivel con un jugador y tres áreas que reaccionan a él.

1. Crea una escena con raíz `Node3D` llamada `Nivel`. Añade un suelo: un `StaticBody3D` con un `CollisionShape3D` (forma `BoxShape3D` ancha y plana) y un `MeshInstance3D` con `BoxMesh` para verlo. Agrega también una `Camera3D` y una `DirectionalLight3D`.

2. Añade el jugador. Crea un `CharacterBody3D` llamado `Jugador` con su `CollisionShape3D` (una `CapsuleShape3D`) y un `MeshInstance3D` con `CapsuleMesh`. Adjúntale este script de movimiento:

```gdscript
extends CharacterBody3D

@export var velocidad: float = 5.0
var vida: int = 100
var punto_reaparicion: Vector3 = Vector3.ZERO

func _physics_process(_delta: float) -> void:
	var entrada := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity.x = entrada.x * velocidad
	velocity.z = entrada.y * velocidad
	move_and_slide()

func aplicar_dano(cantidad: int) -> void:
	vida -= cantidad
	print("Vida: ", vida)
	if vida <= 0:
		reaparecer()

func guardar_checkpoint(posicion: Vector3) -> void:
	punto_reaparicion = posicion
	print("Checkpoint guardado en ", posicion)

func reaparecer() -> void:
	vida = 100
	global_position = punto_reaparicion
	print("Reapareces en el último checkpoint")
```

3. **Checkpoint.** Añade un `Area3D` llamado `Checkpoint` con un `CollisionShape3D` (`BoxShape3D`). Colócalo a un lado del suelo. Adjúntale este script y conecta su señal `body_entered` desde el panel *Nodo → Señales* hacia la función `_on_body_entered`:

```gdscript
extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("guardar_checkpoint"):
		body.guardar_checkpoint(global_position)
		monitoring = false  # ya usado, no volver a disparar
```

4. **Zona de daño.** Añade otro `Area3D` llamado `ZonaDano` con su forma. Este daña de forma continua mientras el jugador permanezca dentro, usando `body_entered` y `body_exited`:

```gdscript
extends Area3D

@export var dano_por_tick: int = 10
var cuerpos_dentro: Array[Node3D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var reloj := Timer.new()
	reloj.wait_time = 1.0
	reloj.autostart = true
	reloj.timeout.connect(_aplicar_dano)
	add_child(reloj)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("aplicar_dano"):
		cuerpos_dentro.append(body)

func _on_body_exited(body: Node3D) -> void:
	cuerpos_dentro.erase(body)

func _aplicar_dano() -> void:
	for cuerpo in cuerpos_dentro:
		cuerpo.aplicar_dano(dano_por_tick)
```

5. **Puerta automática.** Añade un `Area3D` llamado `SensorPuerta` con su forma, y como hermano un `MeshInstance3D` llamado `HojaPuerta` (un `BoxMesh` vertical). El área anima la puerta hacia arriba al entrar y la baja al salir con un `Tween`:

```gdscript
extends Area3D

@onready var hoja: MeshInstance3D = $"../HojaPuerta"
var y_cerrada: float
var y_abierta: float

func _ready() -> void:
	y_cerrada = hoja.position.y
	y_abierta = y_cerrada + 3.0
	body_entered.connect(func(_b): _mover_puerta(y_abierta))
	body_exited.connect(func(_b): _mover_puerta(y_cerrada))

func _mover_puerta(destino_y: float) -> void:
	var tween := create_tween()
	tween.tween_property(hoja, "position:y", destino_y, 0.5)
```

6. Ejecuta con **F6**. Mueve al jugador con las flechas: al cruzar el checkpoint verás el mensaje en consola; al pisar la zona de daño la vida bajará cada segundo; al acercarte a la puerta, la hoja subirá sola y volverá a bajar al alejarte. Todo esto ocurre sin que ninguna área frene tu movimiento.

## ✍️ Ejercicios

1. Añade un segundo checkpoint más adelante y comprueba que reaparecer usa siempre el último cruzado.
2. Haz que la `ZonaDano` cambie el color del `MeshInstance3D` del jugador mientras esté dentro (usa un `StandardMaterial3D`).
3. Configura la capa y máscara de la puerta para que solo detecte al jugador y no a un enemigo de otra capa.
4. Convierte la puerta en una que solo se abra una vez (usa `monitoring = false` tras abrirse).
5. Añade una `Area3D` "meta" que al entrar imprima "Nivel completado" y detenga el movimiento del jugador.
6. Usa `body_exited` en el checkpoint para imprimir un mensaje cuando el jugador se aleja.

## 📝 Reto verificable

Construye una sala con **tres** áreas encadenadas: un checkpoint inicial, una zona de daño que el jugador debe cruzar perdiendo vida, y una puerta final que solo se abre si el jugador llega con vida mayor que cero. Si muere en la zona de daño, debe reaparecer en el checkpoint con la vida restaurada. **Criterio de aceptación**: al ejecutar, cruzar el checkpoint guarda la posición; atravesar la zona resta vida cada segundo; morir reaparece al jugador en el checkpoint con vida 100; y la puerta final se abre solo cuando el jugador llega vivo, verificable por consola y en pantalla.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El área nunca dispara la señal | Falta el `CollisionShape3D` o no tiene forma asignada. Añade la forma al área. |
| Detecta objetos que no debería | Máscara de colisión mal configurada. Ajusta `collision_mask` para incluir solo la capa del jugador. |
| El jugador choca contra el área como si fuera muro | Confundiste `Area3D` con `StaticBody3D`. El `Area3D` no bloquea; usa un cuerpo sólido si quieres colisión. |
| `body_entered` no llega al script del jugador | El cuerpo no tiene el método esperado. Verifica con `body.has_method("...")` antes de llamarlo. |
| La zona de daño sigue dañando tras salir | Olvidaste conectar `body_exited` o quitar el cuerpo del array. Usa `cuerpos_dentro.erase(body)`. |
| La puerta no encuentra la hoja | Ruta relativa incorrecta en `$"../HojaPuerta"`. Verifica que la hoja sea hermana del área. |

## ❓ Preguntas frecuentes

**❓ ¿Cuál es la diferencia real entre Area3D y un cuerpo sólido?** El `Area3D` solo informa de entradas y salidas; nunca detiene ni empuja. Un `StaticBody3D` o `CharacterBody3D` sí impide atravesarlo. Usa áreas para lógica (triggers) y cuerpos para geometría física.

**❓ ¿Por qué mi área detecta al jugador y también a las paredes?** Porque su máscara incluye la capa de las paredes. Separa jugador y entorno en capas distintas y deja en la máscara del área solo la capa del jugador.

**❓ ¿Puedo detectar otras áreas en vez de cuerpos?** Sí, con la señal `area_entered(area)`. Es útil, por ejemplo, para que una zona de agua detecte un proyectil que también es un `Area3D`.

**❓ ¿Cómo desactivo un trigger que ya se usó?** Pon su propiedad `monitoring` en `false`. El área dejará de emitir señales hasta que la vuelvas a activar.

## 🔗 Referencias

- Godot Docs — Clase Area3D: <https://docs.godotengine.org/en/stable/classes/class_area3d.html>
- Godot Docs — Physics introduction: <https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html>
- Godot Docs — Collision layers and masks: <https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html#collision-layers-and-masks>
- Godot Docs — Clase CollisionShape3D: <https://docs.godotengine.org/en/stable/classes/class_collisionshape3d.html>

## ⬅️ Clase anterior

[Clase 062 - NavigationServer 3D: navmesh y pathfinding](../062-navigationserver-3d-navmesh-y-pathfinding/README.md)

## ➡️ Siguiente clase

[Clase 064 - Instanciado y escenas 3D reutilizables](../064-instanciado-y-escenas-3d-reutilizables/README.md)
