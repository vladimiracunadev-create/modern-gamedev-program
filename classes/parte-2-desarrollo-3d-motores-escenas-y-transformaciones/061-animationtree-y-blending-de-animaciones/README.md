# Clase 061 — AnimationTree y blending de animaciones

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot Engine 4.x — Using AnimationTree*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Sustituir la lógica manual de `play("...")` por un `AnimationTree`, que mezcla animaciones de forma continua. Aprenderás la diferencia entre `AnimationNodeStateMachine` y `BlendSpace1D/2D`, y montarás un `BlendSpace1D` que funde idle → walk → run según la magnitud de la velocidad del personaje, controlado por código con `set("parameters/...")`.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Configurar un `AnimationTree` sobre un `AnimationPlayer` existente.
- Distinguir cuándo usar StateMachine y cuándo BlendSpace.
- Construir un `BlendSpace1D` con idle, walk y run posicionados en un eje.
- Controlar el blend por código con `set("parameters/blend_position", valor)`.
- Conectar la magnitud de `velocity` del `CharacterBody3D` al parámetro de mezcla.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | AnimationTree | Motor de blending sobre los clips |
| 2 | tree_root | Nodo raíz del grafo de animación |
| 3 | StateMachine | Estados discretos con transiciones |
| 4 | BlendSpace1D | Mezcla continua sobre un eje (velocidad) |
| 5 | BlendSpace2D | Mezcla en dos ejes (dirección + velocidad) |
| 6 | Parámetros por código | Controlar el árbol desde el script |
| 7 | active y anim_player | Enlazar el árbol al reproductor |
| 8 | Blend vs play manual | Suavidad y escalabilidad |

## 📖 Definiciones y características

- **AnimationTree**: nodo que reproduce un grafo de animaciones mezclándolas; usa un `AnimationPlayer` como fuente de clips. Clave: pon `active = true` y asigna `anim_player`.
- **tree_root**: recurso raíz del grafo (`AnimationNodeStateMachine`, `AnimationNodeBlendSpace1D`, etc.). Clave: define la topología del blending.
- **AnimationNodeStateMachine**: estados discretos con transiciones condicionadas. Clave: bueno para acciones (idle/attack/jump) claramente separadas.
- **BlendSpace1D**: mezcla clips situados en un eje según un `blend_position`. Clave: perfecto para locomoción continua por velocidad.
- **BlendSpace2D**: mezcla en un plano (x, y). Clave: útil para strafe (dirección + velocidad).
- **blend_position**: parámetro que define el punto de mezcla. Clave: se lee/escribe con `set("parameters/<nombre>/blend_position", v)`.
- **set("parameters/...", valor)**: API para escribir cualquier parámetro del árbol desde código. Clave: la ruta refleja el nombre del nodo en el grafo.
- **anim_player (NodePath)**: ruta al `AnimationPlayer` que provee los clips. Clave: si está vacío, el árbol no reproduce nada.

## 🧰 Herramientas y preparación

Godot 4.x y el personaje animado de la clase 060 (con `AnimationPlayer` y clips Idle/Walk/Run en loop). Añadirás un `AnimationTree` hermano. Revisa [Using AnimationTree](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html) y la clase [AnimationNodeBlendSpace1D](https://docs.godotengine.org/en/stable/classes/class_animationnodeblendspace1d.html).

## 🧪 Laboratorio guiado

Montaremos un `BlendSpace1D` que mezcla la locomoción según la velocidad.

**1) Añadir el AnimationTree.** En el `Jugador`, agrega un nodo `AnimationTree`. En el inspector, asigna `Anim Player` al `AnimationPlayer` del modelo y marca `Active = true`.

**2) Crear el BlendSpace1D.** En `Tree Root`, elige **New AnimationNodeBlendSpace1D**. Ábrelo (clic en el árbol se muestra en el panel inferior). Verás una línea horizontal (el eje de blend).

**3) Colocar los puntos.** Sobre el eje, añade tres puntos con las animaciones:

- Posición `0.0` → clip `Idle`.
- Posición `2.0` → clip `Walk`.
- Posición `6.0` → clip `Run`.

Las posiciones representan velocidad (m/s). Godot interpolará entre los clips vecinos según `blend_position`.

**4) Conectar la velocidad por código.** En el script del `Jugador`, referencia el árbol y actualiza el parámetro cada frame de física:

```gdscript
extends CharacterBody3D

@export var vel_correr := 6.0
@export var gravedad := 20.0
@export var aceleracion := 10.0
@onready var arbol: AnimationTree = $AnimationTree

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravedad * delta
	else:
		velocity.y = 0.0

	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var mov := (transform.basis * Vector3(dir.x, 0.0, dir.y)).normalized()
	var objetivo := mov * vel_correr
	velocity.x = move_toward(velocity.x, objetivo.x, aceleracion * delta)
	velocity.z = move_toward(velocity.z, objetivo.z, aceleracion * delta)

	move_and_slide()

	# Magnitud horizontal de la velocidad -> punto de mezcla
	var rapidez := Vector2(velocity.x, velocity.z).length()
	arbol.set("parameters/blend_position", rapidez)
```

Verifica la ruta del parámetro: si tu BlendSpace se llama distinto, será `"parameters/<Nombre>/blend_position"`. Con el `Tree Root` directamente como BlendSpace1D, la ruta es `"parameters/blend_position"`.

**5) Observable.** Al empezar a moverse, la animación pasa suavemente de idle a walk y, al ganar velocidad hasta 6 m/s, mezcla hacia run —sin saltos, con transición continua proporcional a la rapidez real. Si sueltas las teclas, `move_toward` frena la velocidad y la animación regresa gradualmente a idle.

**6) (Opcional) StateMachine para acciones.** Para un salto puntual, envuelve el BlendSpace en un `AnimationNodeStateMachine` con estados `Locomocion` (el BlendSpace) y `Salto`, y viaja entre ellos con `arbol.get("parameters/playback").travel("Salto")`.

## ✍️ Ejercicios

1. Cambia las posiciones del BlendSpace a 0/1.5/5 y ajusta la sensación de la transición.
2. Suaviza aún más el parámetro con un `lerp` sobre `blend_position` en lugar de asignarlo directo.
3. Crea un `BlendSpace2D` con caminar en las cuatro direcciones (strafe) y conéctalo a `dir`.
4. Envuelve la locomoción en una StateMachine y añade un estado `Salto` con `travel()`.
5. Muestra en pantalla el valor actual de `blend_position` para depurar.
6. Añade un cuarto punto `Sprint` en posición 9 y una tecla que suba la velocidad máxima.

## 📝 Reto verificable

Implementa un controlador de tercera/primera persona cuyo personaje mezcle idle/walk/run de forma continua mediante un `BlendSpace1D` alimentado por la magnitud real de la velocidad, con aceleración y desaceleración suaves (nada de cambios instantáneos de estado).

**Criterio de aceptación**: al acelerar y frenar, la animación transita de forma fluida por idle→walk→run y de vuelta, proporcional a la velocidad; no hay saltos bruscos entre clips y, detenido, el personaje queda en idle estable.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El árbol no anima | `Active = false` o `Anim Player` sin asignar. Actívalo y enlaza el reproductor. |
| `set("parameters/...")` no hace nada | Ruta del parámetro incorrecta. Copia el nombre exacto del nodo del grafo. |
| Transición a tirones | Escribes `blend_position` con valores ruidosos. Suaviza con `lerp`/`move_toward`. |
| Los clips no mezclan | No están en loop o mal ubicados en el eje. Marca Loop y revisa posiciones. |
| Conflicto con play() manual | Mezclas AnimationTree y `AnimationPlayer.play()`. Con árbol activo, controla todo desde el árbol. |

## ❓ Preguntas frecuentes

**¿StateMachine o BlendSpace?** StateMachine para estados discretos (idle/attack/jump); BlendSpace para mezclas continuas por un parámetro (velocidad, dirección).

**¿Puedo combinarlos?** Sí: una StateMachine cuyos estados contengan BlendSpaces es el patrón habitual de locomoción + acciones.

**¿Por qué el `AnimationPlayer` deja de responder a `play()`?** Con el `AnimationTree` activo, este toma el control; usa la API del árbol.

**¿Cómo sé la ruta del parámetro?** Es `parameters/` seguido del nombre del nodo tal como aparece en el grafo, más la propiedad (`blend_position`, `playback`, etc.).

## 🔗 Referencias

- [Using AnimationTree — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html)
- [AnimationNodeBlendSpace1D — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_animationnodeblendspace1d.html)
- [AnimationNodeStateMachine — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_animationnodestatemachine.html)

## ➡️ Siguiente clase

[Clase 062 - NavigationServer 3D: navmesh y pathfinding](../062-navigationserver-3d-navmesh-y-pathfinding/README.md)
