# Clase 064 — Instanciado y escenas 3D reutilizables

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot 4 — Instancing*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dominar el patrón más importante para construir mundos 3D: convertir escenas en "prefabs" reutilizables e instanciarlas por código en cualquier posición. En lugar de colocar a mano cada moneda, caja o enemigo, diseñas la escena una vez y la duplicas cuantas veces necesites, comunicándote con cada copia mediante señales.

Al terminar habrás creado dos escenas independientes —un coleccionable que emite una señal al recogerse y un enemigo autónomo— y las instanciarás varias veces por código en posiciones dadas, manteniendo un contador global que reacciona a cada recogida.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar qué es una escena reutilizable (prefab) y por qué mejora el mantenimiento del proyecto.
2. Instanciar una escena por código con `preload().instantiate()` y `add_child()`.
3. Posicionar instancias en el mundo mediante `position` / `global_position`.
4. Comunicar una instancia con el mundo usando señales (`signal`, `emit()`, `connect()`).
5. Usar escenas heredadas para crear variantes de un mismo prefab base.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Escenas como prefabs | Encapsulan comportamiento y arte reutilizable en un solo archivo. |
| 2 | preload vs load | Determina cuándo se carga el recurso: en compilación o en ejecución. |
| 3 | instantiate() y add_child() | Son los dos pasos para meter una copia viva en el árbol. |
| 4 | Posicionar instancias | Sin colocarlas, todas nacen en el origen y se superponen. |
| 5 | Señales entre instancia y mundo | Permiten avisar "me recogieron" sin acoplar código. |
| 6 | Escenas heredadas | Crean variantes (enemigo rápido, lento) sin duplicar todo. |
| 7 | queue_free() y ciclo de vida | Liberar instancias evita fugas y objetos fantasma. |

## 📖 Definiciones y características

- **Prefab / escena reutilizable**: archivo `.tscn` diseñado para instanciarse muchas veces. Clave: cambiarlo actualiza todas sus copias.
- **preload()**: carga un recurso en tiempo de compilación y lo guarda en una variable. Clave: es más rápido en ejecución que `load()`.
- **instantiate()**: crea una copia viva (nodo) a partir de una `PackedScene`. Clave: la copia aún no está en el árbol hasta hacer `add_child()`.
- **add_child()**: inserta un nodo como hijo, activándolo en la escena. Clave: sin él, la instancia existe pero no se ve ni procesa.
- **signal**: declaración de un evento propio que un nodo puede emitir. Clave: desacopla quién avisa de quién reacciona.
- **emit()**: dispara una señal, opcionalmente con argumentos. Clave: en Godot 4 se llama como `mi_senal.emit(args)`.
- **Escena heredada**: escena nueva basada en otra que hereda su estructura. Clave: ideal para variantes que comparten la mayoría del comportamiento.
- **queue_free()**: marca un nodo para eliminarse al final del cuadro. Clave: es la forma segura de destruir instancias.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x desde <https://godotengine.org/download>. La guía base es "Instancing" en <https://docs.godotengine.org/en/stable/getting_started/step_by_step/instancing.html> y la referencia de `PackedScene` en <https://docs.godotengine.org/en/stable/classes/class_packedscene.html>. Para señales revisa <https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html>. Trabajaremos con mallas primitivas para que puedas centrarte en el patrón de instanciado y no en el arte.

## 🧪 Laboratorio guiado

Crearemos dos prefabs y un mundo que los instancia por código.

1. **Prefab Coleccionable.** Crea una escena con raíz `Area3D` llamada `Coleccionable`. Añádele un `CollisionShape3D` (`SphereShape3D`) y un `MeshInstance3D` con `SphereMesh` pequeño. Guárdala como `coleccionable.tscn` y adjunta este script:

```gdscript
extends Area3D

signal recogido(puntos: int)

@export var valor: int = 10
@export var velocidad_giro: float = 2.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	rotate_y(velocidad_giro * delta)  # gira para llamar la atención

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		recogido.emit(valor)
		queue_free()
```

2. **Prefab Enemigo.** Crea otra escena con raíz `CharacterBody3D` llamada `Enemigo`, con su `CollisionShape3D` (`CapsuleShape3D`) y un `MeshInstance3D` con `CapsuleMesh`. Guárdala como `enemigo.tscn` y adjúntale un movimiento de patrulla simple:

```gdscript
extends CharacterBody3D

@export var velocidad: float = 2.0
@export var distancia_patrulla: float = 4.0
var origen_x: float
var direccion: float = 1.0

func _ready() -> void:
	origen_x = global_position.x

func _physics_process(_delta: float) -> void:
	velocity.x = direccion * velocidad
	move_and_slide()
	if absf(global_position.x - origen_x) >= distancia_patrulla:
		direccion *= -1.0  # invierte al llegar al extremo
```

3. **El mundo.** Crea la escena principal con raíz `Node3D` llamada `Mundo`. Añádele suelo (`StaticBody3D` + forma + malla), `Camera3D` y `DirectionalLight3D`. Añade un `CharacterBody3D` `Jugador` y ponlo en el grupo `jugador` (panel *Nodo → Grupos*). Reusa el script de movimiento de clases previas.

4. **Instanciar por código.** Adjunta este script a `Mundo`. Precarga ambos prefabs e instancia varios en posiciones dadas, conectando la señal de cada coleccionable a un contador:

```gdscript
extends Node3D

const ESCENA_COLECCIONABLE := preload("res://coleccionable.tscn")
const ESCENA_ENEMIGO := preload("res://enemigo.tscn")

var puntos: int = 0

func _ready() -> void:
	var posiciones_monedas := [
		Vector3(-4, 1, 0), Vector3(-2, 1, 0),
		Vector3(0, 1, 0), Vector3(2, 1, 0), Vector3(4, 1, 0),
	]
	for pos in posiciones_monedas:
		_crear_coleccionable(pos)

	var posiciones_enemigos := [Vector3(-3, 1, -5), Vector3(3, 1, -5)]
	for pos in posiciones_enemigos:
		_crear_enemigo(pos)

func _crear_coleccionable(posicion: Vector3) -> void:
	var moneda := ESCENA_COLECCIONABLE.instantiate()
	moneda.position = posicion
	moneda.recogido.connect(_on_recogido)
	add_child(moneda)

func _crear_enemigo(posicion: Vector3) -> void:
	var enemigo := ESCENA_ENEMIGO.instantiate()
	enemigo.position = posicion
	add_child(enemigo)

func _on_recogido(valor: int) -> void:
	puntos += valor
	print("Puntos: ", puntos)
```

5. Ejecuta con **F6**. Verás cinco esferas girando en línea y dos enemigos patrullando. Al mover al jugador sobre una esfera, esta desaparece y la consola imprime el total actualizado. Nada de esto se colocó a mano: todo nació por código.

6. **Escena heredada (variante).** En el panel de archivos, haz clic derecho sobre `enemigo.tscn` → *Nueva escena heredada*. Guárdala como `enemigo_rapido.tscn` y solo cambia `velocidad` a `4.0` en el Inspector. Instánciala junto a los demás para tener una variante sin duplicar código.

## ✍️ Ejercicios

1. Instancia los coleccionables en un círculo usando `sin`/`cos` en lugar de una lista fija de posiciones.
2. Haz que el contador de puntos se muestre en un `Label` de una interfaz en pantalla, no solo en consola.
3. Crea una escena heredada `MonedaOro` con `valor = 50` y un color distinto, e instánciala.
4. Añade un sonido o un efecto (por ejemplo un `Tween` de escala) antes del `queue_free()` al recoger.
5. Instancia enemigos en posiciones aleatorias dentro de un rango usando `randf_range`.
6. Emite una segunda señal `todos_recogidos` cuando el contador llegue al total de monedas.

## 📝 Reto verificable

Crea un "recolector": instancia por código **al menos 8** coleccionables en posiciones distintas y **2** enemigos que patrullan. Cuando el jugador recoja todas las monedas, imprime "Nivel completado" y elimina los enemigos con `queue_free()`. El total debe calcularse automáticamente según cuántas monedas se instanciaron. **Criterio de aceptación**: al ejecutar, todas las monedas aparecen por código (ninguna colocada a mano), cada recogida actualiza el contador vía señal, y al llegar al total se imprime el mensaje y los enemigos desaparecen.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Todas las instancias aparecen en el mismo punto | Olvidaste asignar `position` antes de `add_child()`. Coloca cada instancia. |
| La señal `recogido` no llega al mundo | Conectaste después o nunca. Usa `instancia.recogido.connect(fn)` antes de `add_child`. |
| `Attempt to call instantiate on null` | El `preload` apunta a una ruta que no existe. Verifica la ruta `res://`. |
| La instancia no se ve ni se mueve | Falta `add_child()`. Instanciar sola no la mete en el árbol. |
| El coleccionable no detecta al jugador | El jugador no está en el grupo `jugador`. Añádelo en *Nodo → Grupos*. |
| Cambiar el prefab no afecta a las copias | Editaste una instancia local, no la escena. Abre y edita el `.tscn` original. |

## ❓ Preguntas frecuentes

**❓ ¿Cuál es la diferencia entre `preload` y `load`?** `preload` carga el recurso al compilar el script (más rápido en ejecución, ruta fija). `load` lo carga en tiempo de ejecución (útil si la ruta se decide dinámicamente). Para prefabs conocidos, usa `preload`.

**❓ ¿Por qué mi instancia no aparece aunque la instancié?** Casi siempre falta `add_child()`. `instantiate()` solo crea el nodo en memoria; hasta que no lo añades al árbol no se procesa ni se dibuja.

**❓ ¿Cuándo conviene una escena heredada frente a un `@export`?** Usa `@export` para ajustes que cambian por instancia (velocidad, valor). Usa escenas heredadas cuando la variante cambia estructura o varios valores a la vez y quieres tratarla como un prefab propio.

**❓ ¿Debo liberar las instancias manualmente?** Sí cuando dejan de servir (una moneda recogida, un enemigo muerto). Usa `queue_free()`; liberar a tiempo evita acumular nodos invisibles que consumen memoria.

## 🔗 Referencias

- Godot Docs — Instancing: <https://docs.godotengine.org/en/stable/getting_started/step_by_step/instancing.html>
- Godot Docs — Signals: <https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html>
- Godot Docs — Clase PackedScene: <https://docs.godotengine.org/en/stable/classes/class_packedscene.html>
- Godot Docs — Using signals (código): <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#signals>

## ➡️ Siguiente clase

[Clase 065 - Nivel 3D: GridMap, kits modulares y blockout](../065-nivel-3d-gridmap-kits-modulares-y-blockout/README.md)
