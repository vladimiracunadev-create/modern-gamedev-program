# Clase 033 — Colisiones 2D: cuerpos, áreas y capas

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4*
> ⏱️ Duración estimada: **95 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Tu jugador ya se mueve y salta, pero para que un plataformas tenga sentido necesita **colisionar** con el mundo de forma controlada: pisar suelo, chocar con paredes, activar trampas, recoger objetos. En esta clase entenderás los cuatro tipos de cuerpo de Godot 4 (`StaticBody2D`, `CharacterBody2D`, `RigidBody2D`, `Area2D`), qué hace cada uno y cuándo usarlo.

El corazón de la clase es el **sistema de capas y máscaras** (`collision_layer` / `collision_mask`): cómo nombrarlas en *Project Settings* y usarlas como bitmask para decidir qué colisiona con qué. Cerrarás con un `Area2D` "zona de peligro" que detecta al jugador mediante la señal `body_entered` — la base de trampas, pinchos y checkpoints.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Distinguir `StaticBody2D`, `CharacterBody2D`, `RigidBody2D` y `Area2D` y elegir el adecuado.
2. Asignar `CollisionShape2D` con formas de rectángulo, círculo y cápsula a cada cuerpo.
3. Nombrar capas de colisión en *Project Settings* y configurar `collision_layer` vs `collision_mask`.
4. Usar `Area2D` con la señal `body_entered(body)` para crear triggers.
5. Leer las colisiones de `move_and_slide()` con `get_slide_collision()`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Tipos de cuerpo 2D | Cada uno modela un comportamiento físico distinto |
| 2 | `CollisionShape2D` y formas | Sin forma no hay colisión; la forma define el "cuerpo" |
| 3 | `collision_layer` (en qué capa estoy) | Indica a quién puedo ser detectado |
| 4 | `collision_mask` (a quién detecto) | Indica con qué capas interactúo |
| 5 | Nombrar capas en Project Settings | Bitmask legible: World, Player, Enemy, Pickup |
| 6 | `Area2D` y `body_entered` | Triggers sin física (daño, recogida, zonas) |
| 7 | `get_slide_collision()` | Inspeccionar contra qué chocó el movimiento |

## 📖 Definiciones y características

- **StaticBody2D**: cuerpo inmóvil que colisiona pero no se mueve por física. Clave: ideal para suelo, paredes y plataformas fijas.
- **CharacterBody2D**: cuerpo de control directo mediante `velocity` y `move_and_slide()`. Clave: para personajes que quieres controlar tú, no la simulación.
- **RigidBody2D**: cuerpo simulado por el motor (gravedad, fuerzas, rebotes). Clave: para cajas, barriles y objetos "sueltos".
- **Area2D**: región que detecta entradas/salidas sin frenar cuerpos. Clave: triggers vía `body_entered`/`area_entered`.
- **CollisionShape2D**: nodo hijo que aporta la geometría de colisión (rectángulo, círculo, cápsula). Clave: sin él, el cuerpo no colisiona.
- **collision_layer**: bitmask de las capas en las que "vive" el cuerpo. Clave: responde "¿en qué capa estoy?".
- **collision_mask**: bitmask de las capas que el cuerpo detecta. Clave: responde "¿a quién veo?".
- **body_entered**: señal de `Area2D` emitida cuando un `PhysicsBody2D` entra en la zona. Clave: recibe el `body` como argumento.

## 🧰 Herramientas y preparación

Continúa con la escena `Player` (`CharacterBody2D`) de clases anteriores. Abre *Proyecto → Ajustes del proyecto → Nombres de capas → 2D Physics* para nombrar las capas antes de configurarlas. Referencias: guía de [física e introducción a colisiones](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html) y [Area2D](https://docs.godotengine.org/en/stable/classes/class_area2d.html).

## 🧪 Laboratorio guiado

### Paso 1 — Nombrar las capas de colisión

Ve a *Proyecto → Ajustes del proyecto → Nombres de capas → 2D Physics* y asigna:

- Capa 1 → `World`
- Capa 2 → `Player`
- Capa 3 → `Enemy`
- Capa 4 → `Pickup`

Nombrarlas hace que las casillas del Inspector muestren texto en lugar de números anónimos.

### Paso 2 — Crear el suelo con StaticBody2D

En tu escena de nivel, añade un **StaticBody2D** llamado `Suelo` con un `CollisionShape2D` de forma **RectangleShape2D** ancho y bajo. En el Inspector del `Suelo`:

- **Collision → Layer**: activa solo `World`.
- **Collision → Mask**: puedes dejarla vacía (el suelo no necesita "detectar", solo ser detectado).

### Paso 3 — Configurar el cuerpo del jugador

Selecciona el `Player` (`CharacterBody2D`). Dale un `CollisionShape2D` con forma **CapsuleShape2D** (buena para personajes). En el Inspector:

- **Collision → Layer**: activa `Player`.
- **Collision → Mask**: activa `World` (para pisar el suelo) y `Enemy` si quieres chocar con enemigos.

Ejecuta: el jugador ya se para sobre el suelo. Puedes inspeccionar contra qué choca:

```gdscript
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravedad * delta
	velocity.x = Input.get_axis("mover_izquierda", "mover_derecha") * velocidad
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = -fuerza_salto

	move_and_slide()

	# Inspeccionar las colisiones ocurridas en este frame
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var otro := col.get_collider()
		if otro:
			print("Choqué con: ", otro.name, " normal: ", col.get_normal())
```

### Paso 4 — Crear una Area2D "zona de peligro"

Añade a la escena de nivel un **Area2D** llamado `ZonaPeligro` con un `CollisionShape2D` (rectángulo) colocado sobre unos pinchos o un foso. Configura:

- **Collision → Layer**: déjala vacía o en una capa propia de "trampas".
- **Collision → Mask**: activa `Player` (queremos detectar al jugador).

Crea un script y conecta la señal `body_entered`:

```gdscript
extends Area2D

signal jugador_en_peligro   # útil para que otros nodos reaccionen

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Filtra por grupo o por tipo para evitar falsos positivos
	if body.is_in_group("jugador"):
		print("¡El jugador entró en la zona de peligro!")
		jugador_en_peligro.emit()
```

Para que el filtro funcione, selecciona el `Player`, abre la pestaña *Nodo → Grupos* y añádelo al grupo `jugador` (o hazlo por código con `add_to_group("jugador")` en su `_ready()`).

### Paso 5 — Probar

Ejecuta y camina hacia la `ZonaPeligro`: en la consola aparece el aviso solo cuando el jugador entra (no otros cuerpos). Con `get_slide_collision()` verás también los choques contra el suelo y las paredes. Ya tienes los cimientos de trampas, checkpoints y recogidas.

## ✍️ Ejercicios

1. Crea un `Area2D` "Moneda" en la capa `Pickup` que al detectar al jugador imprima "moneda recogida" y se elimine con `queue_free()`.
2. Añade una pared `StaticBody2D` y confirma con `get_slide_collision()` que la normal apunta horizontalmente.
3. Configura un enemigo `CharacterBody2D` en la capa `Enemy` y haz que el jugador lo detecte por máscara.
4. Usa la señal `body_exited` para imprimir cuándo el jugador sale de la zona de peligro.
5. Cambia la forma de colisión del jugador a `RectangleShape2D` y observa cómo afecta al enganche en esquinas.
6. Crea una `Area2D` "checkpoint" que guarde la posición del jugador cuando entra.

## 📝 Reto verificable

Monta un mini-nivel con: suelo `StaticBody2D` (capa `World`), jugador `CharacterBody2D` (capa `Player`, máscara `World`+`Pickup`), una moneda `Area2D` (capa `Pickup`) que se recoge con `body_entered`, y una zona de peligro `Area2D` que detecta al jugador y emite una señal. Las capas deben estar **nombradas** en Project Settings.

**Criterio de aceptación**: el jugador camina sobre el suelo sin atravesarlo; al tocar la moneda esta desaparece e imprime un mensaje; al entrar en la zona de peligro se emite la señal e imprime el aviso; ningún otro cuerpo dispara falsos positivos gracias al filtrado por capa/grupo.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El jugador atraviesa el suelo | Falta `CollisionShape2D` en algún cuerpo o la máscara del jugador no incluye `World` |
| `body_entered` nunca se dispara | La `collision_mask` del `Area2D` no incluye la capa del jugador; actívala |
| Se dispara con cualquier cosa | No filtras el `body`; comprueba `is_in_group()` o el tipo antes de reaccionar |
| `Signal already connected` | Conectas la señal por código y también en el editor; deja solo una |
| El `RigidBody2D` no cae ni choca | Le falta forma o la capa/máscara no coinciden con el mundo; revísalas |
| Empujar cuerpos con `CharacterBody2D` no funciona | `CharacterBody2D` no aplica fuerzas; usa `RigidBody2D` para objetos empujables (clase 034) |

## ❓ Preguntas frecuentes

**❓ ¿Cuál es la diferencia real entre `layer` y `mask`?** `collision_layer` dice en qué capas *estás* (quién puede detectarte). `collision_mask` dice qué capas *detectas tú*. Para que A choque con B, la máscara de A debe incluir la capa de B (y a menudo viceversa).

**❓ ¿Por qué nombrar las capas?** Los números son opacos y frágiles. Nombrarlas en Project Settings hace el proyecto legible y evita errores al configurar máscaras en decenas de nodos.

**❓ ¿`Area2D` frena a los cuerpos?** No. Un `Area2D` solo detecta; no aporta colisión sólida. Para bloquear el paso usa un cuerpo (`StaticBody2D`, etc.).

**❓ ¿Cuándo uso grupos y cuándo capas?** Las capas filtran *físicamente* qué colisiona; los grupos son etiquetas lógicas para tu código. Suelen combinarse: la máscara reduce candidatos y el grupo confirma el tipo en el callback.

## 🔗 Referencias

- [Introducción a la física y colisiones — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html)
- [Area2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_area2d.html)
- [CharacterBody2D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)
- [Capas y máscaras de colisión — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html#collision-layers-and-masks)

## ➡️ Siguiente clase

[Clase 034 - Física 2D: RigidBody, gravedad y plataformas](../034-fisica-2d-rigidbody-gravedad-y-plataformas/README.md)
