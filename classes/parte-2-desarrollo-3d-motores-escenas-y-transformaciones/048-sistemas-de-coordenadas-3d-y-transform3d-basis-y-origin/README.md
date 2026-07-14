# Clase 048 — Sistemas de coordenadas 3D y Transform3D (basis y origin)

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot 4 — Matrices and transforms*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Abrir la caja negra del `Transform3D` y entender que toda transformación en Godot 3D se descompone en dos piezas: el `origin` (un `Vector3` con la posición) y el `basis` (una `Basis` de 3×3 que contiene la rotación y la escala). Comprender la `basis` te da superpoderes: podrás mover un objeto en su propio "adelante" sin importar hacia dónde apunte, orientar objetos con `look_at`, y convertir puntos entre el espacio local y el global.

Este es el fundamento matemático que hace posible controladores de personaje, cámaras y torretas que apuntan. En el laboratorio imprimirás y manipularás estos valores directamente.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Descomponer un `Transform3D` en su `basis` (rotación+escala) y su `origin` (posición).
2. Identificar los vectores base locales de un objeto (ejes X, Y, Z propios) a partir de la `basis`.
3. Mover un objeto a lo largo de su eje local usando `transform.basis`.
4. Distinguir `transform` de `global_transform` y convertir puntos con `to_local` y `to_global`.
5. Orientar un objeto hacia otro con `look_at` y explicar qué hace internamente.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Anatomía de Transform3D | Saber que es basis + origin desmitifica las transformaciones. |
| 2 | La Basis 3×3 | Contiene rotación y escala; es el corazón de la orientación. |
| 3 | Vectores base locales (x/y/z) | Definen el "derecha", "arriba" y "atrás" propios del objeto. |
| 4 | Adelante = -basis.z | Convención de Godot para el frente de un objeto y la cámara. |
| 5 | transform vs global_transform | Uno es relativo al padre, otro absoluto; confundirlos causa bugs. |
| 6 | to_local / to_global | Convertir puntos entre espacios es esencial para colocar objetos. |
| 7 | look_at | Orientar hacia un objetivo sin trigonometría manual. |

## 📖 Definiciones y características

- **Transform3D**: estructura que combina `basis` y `origin` para posicionar y orientar un objeto. Clave: `transform.origin` es la posición.
- **Basis**: matriz 3×3 formada por tres vectores columna (x, y, z) que codifican rotación y escala. Clave: sus columnas son los ejes locales del objeto.
- **origin**: `Vector3` con la posición del objeto en el espacio de su padre. Clave: equivale a `position`.
- **Vector base local**: cada columna de la basis (`basis.x`, `basis.y`, `basis.z`) apunta en la dirección de un eje propio del objeto. Clave: normalizados si no hay escala.
- **Adelante local**: en Godot el frente de un objeto es `-transform.basis.z`. Clave: la cámara mira en esa dirección.
- **global_transform**: el `Transform3D` absoluto respecto al mundo. Clave: úsalo cuando el objeto tiene padres transformados.
- **to_local / to_global**: métodos que convierten un punto del mundo al espacio local del nodo y viceversa. Clave: imprescindibles para colocar objetos relativos.
- **look_at**: método que reorienta la `basis` para que el `-Z` local apunte a un punto dado. Clave: requiere un vector "arriba" de referencia.

## 🧰 Herramientas y preparación

Usaremos Godot 4.x. La lectura de referencia es la guía de matrices y transformaciones en <https://docs.godotengine.org/en/stable/tutorials/math/matrices_and_transforms.html>, junto con las clases <https://docs.godotengine.org/en/stable/classes/class_transform3d.html> y <https://docs.godotengine.org/en/stable/classes/class_basis.html>. Ten a mano también la referencia de `Vector3` en <https://docs.godotengine.org/en/stable/classes/class_vector3.html>. Crea una escena 3D nueva con dos objetos separados para el laboratorio.

## 🧪 Laboratorio guiado

Vamos a inspeccionar y manipular la `basis` y el `origin` de un objeto, moverlo por su eje local y hacer que mire a otro.

1. Crea una escena con un `Node3D` raíz `Escena`. Añade dos `MeshInstance3D`: una llamada `Nave` (con un `BoxMesh` alargado en Z para que se note su frente) y otra llamada `Objetivo` (con un `SphereMesh`). Añade también `Camera3D` y `DirectionalLight3D`.

2. Coloca `Objetivo` en `Vector3(4, 0, -3)` y `Nave` en el origen.

3. Adjunta este script a `Nave`. Imprime la descomposición del transform, mueve la nave hacia su propio adelante y la orienta hacia el objetivo:

```gdscript
extends MeshInstance3D

@export var objetivo_path: NodePath
@export var velocidad: float = 2.0

@onready var objetivo: Node3D = get_node(objetivo_path)

func _ready() -> void:
	# Descomponemos el transform en sus dos piezas.
	var t := transform
	print("origin (posición): ", t.origin)
	print("basis.x (derecha local): ", t.basis.x)
	print("basis.y (arriba local):  ", t.basis.y)
	print("basis.z (atrás local):   ", t.basis.z)
	# El frente del objeto es -basis.z.
	print("adelante local: ", -t.basis.z)

func _process(delta: float) -> void:
	# 1) Orientamos la nave hacia el objetivo cada cuadro.
	look_at(objetivo.global_position, Vector3.UP)

	# 2) Avanzamos en el eje local "adelante" (-basis.z),
	#    que tras el look_at apunta justo al objetivo.
	var adelante := -global_transform.basis.z
	global_position += adelante * velocidad * delta

	# 3) Convertimos la posición del objetivo al espacio local
	#    de la nave para saber a qué distancia frontal está.
	var local := to_local(objetivo.global_position)
	if Engine.get_physics_frames() % 60 == 0:
		print("Objetivo en espacio local de la nave: ", local)
```

4. En el Inspector de `Nave`, asigna la propiedad **Objetivo Path** al nodo `Objetivo`. Coloca la cámara para ver ambos objetos y ejecuta con **F6**.

5. Observa la consola: verás el `origin` en `(0,0,0)`, y los tres vectores base de una nave sin rotar (`basis.x ≈ (1,0,0)`, `basis.y ≈ (0,1,0)`, `basis.z ≈ (0,0,1)`), por lo que su adelante es `(0,0,-1)`. En el viewport, la nave gira para encarar la esfera y se desplaza hacia ella siguiendo su propio "adelante".

6. Cuando la nave llegue, el valor de `to_local` del objetivo tenderá a `(0, 0, -distancia)`: la componente Z negativa confirma que el objetivo está justo delante en el espacio local de la nave.

## ✍️ Ejercicios

1. Rota manualmente la `Nave` 90° en Y desde el editor y vuelve a leer `basis.x` y `-basis.z`; confirma que ahora apuntan a otros ejes del mundo.
2. Sustituye `look_at` por asignar directamente `basis` y comprueba la diferencia de control.
3. Mueve la nave en su eje local **derecha** (`+basis.x`) en lugar de adelante y describe la trayectoria.
4. Usa `to_global(Vector3(0, 0, -1))` para calcular un punto un metro delante de la nave y coloca ahí un pequeño marcador.
5. Imprime `global_transform.origin` y `transform.origin` cuando la nave es hija de otro `Node3D` desplazado, y explica la diferencia.
6. Detén el avance cuando `to_local(objetivo).length()` sea menor que 0.5 para que la nave se frene al llegar.

## 📝 Reto verificable

Programa una "torreta" (un `Node3D` con un cañón alargado como hijo) que apunte permanentemente a un objetivo móvil que tú desplaces por código, sin que la base de la torreta se traslade. **Criterio de aceptación**: el cañón siempre encara al objetivo usando `look_at`, la boca del cañón (`-basis.z`) coincide visualmente con la dirección al objetivo, y en consola se imprime la posición del objetivo convertida al espacio local de la torreta mostrando una Z negativa constante mientras apunta.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El objeto avanza "hacia atrás" | Usaste `+basis.z` como adelante. El frente en Godot es `-basis.z`. |
| `look_at` lanza error con vectores colineales | El objetivo está alineado con `Vector3.UP`. Usa otro vector de referencia o desplaza ligeramente el objetivo. |
| La orientación se desvía al tener padres rotados | Usaste `transform.basis` (local) en vez de `global_transform.basis`. Para movimiento en el mundo usa el global. |
| La escala del objeto "contamina" el movimiento | La `basis` incluye escala; sus columnas no están normalizadas. Usa `basis.z.normalized()` si necesitas solo dirección. |
| `to_local` devuelve valores inesperados | Confundiste espacio local con global. `to_local` espera un punto en coordenadas de mundo. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué el "adelante" es -Z y no +Z?** Es una convención heredada de OpenGL que Godot mantiene: la cámara y los objetos miran hacia su -Z local. Interiorizarlo evita muchos bugs de orientación.

**❓ ¿La basis solo guarda rotación?** No. Guarda rotación **y** escala combinadas. Si escalas un nodo, las columnas de la basis dejan de tener longitud 1. Normalízalas si solo quieres direcciones.

**❓ ¿Cuándo uso `transform` y cuándo `global_transform`?** Usa `transform` para operar relativo al padre y `global_transform` para operar respecto al mundo. Si el objeto no tiene padres transformados, coinciden.

**❓ ¿`look_at` mueve el objeto?** No, solo cambia su orientación (la basis). El `origin` permanece igual; el objeto gira sobre sí mismo para encarar el objetivo.

## 🔗 Referencias

- Godot Docs — Matrices and transforms: <https://docs.godotengine.org/en/stable/tutorials/math/matrices_and_transforms.html>
- Godot Docs — Clase Transform3D: <https://docs.godotengine.org/en/stable/classes/class_transform3d.html>
- Godot Docs — Clase Basis: <https://docs.godotengine.org/en/stable/classes/class_basis.html>
- Godot Docs — Clase Vector3: <https://docs.godotengine.org/en/stable/classes/class_vector3.html>

## ➡️ Siguiente clase

[Clase 049 - Mallas, materiales y MeshInstance3D](../049-mallas-materiales-y-meshinstance3d/README.md)
