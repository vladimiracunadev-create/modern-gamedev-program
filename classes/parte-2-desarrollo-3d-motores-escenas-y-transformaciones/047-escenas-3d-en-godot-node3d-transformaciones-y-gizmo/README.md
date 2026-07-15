# Clase 047 — Escenas 3D en Godot: Node3D, transformaciones y gizmo

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot 4 — Using 3D transforms*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dominar el nodo `Node3D` como base de todo objeto tridimensional y aprender a manipularlo tanto con el gizmo del editor como por código. Entenderás las tres transformaciones básicas (traslación, rotación y escala), el snapping para alinear con precisión, y sobre todo la jerarquía padre-hijo: cómo el transform de un padre arrastra a sus hijos, que es la base de casi todo en 3D (personajes articulados, vehículos con ruedas, cámaras montadas).

Construirás un "brazo robótico" articulado anidando nodos, y verás con tus propios ojos por qué mover o rotar el padre reorganiza toda la cadena de hijos.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Usar el gizmo del editor para trasladar, rotar y escalar nodos 3D con y sin snapping.
2. Explicar la relación entre transform local y transform global en una jerarquía.
3. Construir una jerarquía padre-hijo de varios `Node3D` anidados con sentido articulado.
4. Manipular `position`, `rotation_degrees` y `scale` por código.
5. Predecir cómo afecta la transformación del padre a la posición y rotación de sus hijos.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Node3D como base | Todo objeto con transform en 3D deriva de él; es el ladrillo fundamental. |
| 2 | El gizmo de traslación/rotación/escala | Es la forma directa de manipular objetos en el viewport. |
| 3 | Snapping | Permite alinear y espaciar con precisión, esencial para nivel modular. |
| 4 | Jerarquía padre-hijo | El transform del padre se propaga a los hijos; base de la animación articulada. |
| 5 | Local vs global | Distinguir el espacio del padre del espacio del mundo evita errores sutiles. |
| 6 | rotation_degrees por código | Rotar sin convertir radianes manualmente agiliza el prototipado. |
| 7 | Navegación del viewport 3D | Moverse por la escena es un requisito para trabajar cómodo en 3D. |

## 📖 Definiciones y características

- **Node3D**: nodo con un `Transform3D` que define posición, rotación y escala. Clave: todos los nodos visuales o físicos 3D heredan de él.
- **Gizmo**: manipulador visual con ejes de colores (X rojo, Y verde, Z azul). Clave: arrastrar un eje limita el movimiento a esa dirección.
- **Snapping**: fijar los pasos de movimiento/rotación/escala a incrementos discretos. Clave: se activa con la tecla de modificador o el botón de imán del editor.
- **Transform local**: la transformación de un nodo relativa a su padre (`transform`, `position`). Clave: cambia con el padre.
- **Transform global**: la transformación absoluta respecto al mundo (`global_transform`, `global_position`). Clave: es lo que realmente ve la cámara.
- **Jerarquía**: relación de anidamiento entre nodos. Clave: mover el padre mueve todos los descendientes.
- **rotation_degrees**: rotación expresada en grados (Vector3). Clave: cómoda para humanos; internamente Godot usa radianes en `rotation`.
- **Pivote**: el origen local alrededor del cual rota y escala un nodo. Clave: colocar bien el pivote es esencial en piezas articuladas.

## 🧰 Herramientas y preparación

Trabajaremos dentro de Godot 4.x. Consulta la guía oficial de transformaciones en <https://docs.godotengine.org/en/stable/tutorials/3d/using_transforms.html> y la referencia de `Node3D` en <https://docs.godotengine.org/en/stable/classes/class_node3d.html>. Para la navegación del viewport y el snapping, revisa la introducción al editor 3D en <https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html>. Reutiliza el proyecto de la clase anterior o crea uno nuevo con renderizador Forward+.

## 🧪 Laboratorio guiado

Construiremos un brazo articulado con tres segmentos anidados: `Base` → `Antebrazo` → `Mano`. Cada uno es hijo del anterior, así que rotar la base arrastra todo.

1. Crea una escena nueva con un `Node3D` raíz llamado `BrazoRobot`.

2. Añade como hijo un `Node3D` llamado `Base`. Dentro de `Base`, añade una `MeshInstance3D` con un `BoxMesh` aplanado (una plataforma) y también un `Node3D` hijo llamado `Antebrazo`.

3. Dentro de `Antebrazo`, añade una `MeshInstance3D` alargada (un `BoxMesh` estirado en Y) y un `Node3D` hijo llamado `Mano`. Dentro de `Mano`, añade otra `MeshInstance3D` pequeña.

4. Coloca cada segmento **por encima** del anterior en el eje Y, de modo que la cadena parezca un brazo apilado. Usa el gizmo con snapping activado para posiciones limpias.

5. Adjunta este script al nodo raíz `BrazoRobot`. Rota los pivotes por código y observa cómo cada rotación afecta a los hijos:

```gdscript
extends Node3D

@onready var base: Node3D = $Base
@onready var antebrazo: Node3D = $Base/Antebrazo
@onready var mano: Node3D = $Base/Antebrazo/Mano

var t: float = 0.0

func _ready() -> void:
	# Los pivotes locales controlan cada articulación.
	base.rotation_degrees = Vector3(0, 0, 0)
	antebrazo.rotation_degrees = Vector3(0, 0, 0)
	mano.rotation_degrees = Vector3(0, 0, 0)

func _process(delta: float) -> void:
	t += delta

	# La base gira sobre su eje vertical: mueve TODO el brazo.
	base.rotation_degrees.y = 40.0 * sin(t * 0.8)

	# El antebrazo se inclina; arrastra a la mano consigo.
	antebrazo.rotation_degrees.z = 30.0 * sin(t * 1.5)

	# La mano solo mueve la punta.
	mano.rotation_degrees.z = 45.0 * sin(t * 2.5)

	# Comprobamos la propagación: la posición global de la mano
	# cambia aunque nunca tocamos su position local.
	if Engine.get_physics_frames() % 60 == 0:
		print("Mano global: ", mano.global_position)
```

6. Añade una `Camera3D` y una `DirectionalLight3D` a la escena (fuera del brazo) para poder ver el resultado, y ejecuta con **F6**.

7. Observa: la rotación de `base` mueve todo el brazo; la de `antebrazo` mueve el antebrazo y la mano; la de `mano` solo la punta. En la consola verás que `global_position` de la mano cambia constantemente aunque su `position` local es fija: eso es el transform heredado en acción.

## ✍️ Ejercicios

1. Cambia el orden de anidamiento (mano como hija de base directamente) y describe cómo cambia el comportamiento.
2. Escala el `Antebrazo` con `scale` y comprueba si la mano hija también se escala.
3. Usa el gizmo con snapping de rotación a 15° para orientar la base manualmente y luego léela por código con `print(base.rotation_degrees)`.
4. Añade un cuarto segmento (una "pinza") anidado en la mano y anímalo con otra función seno.
5. Imprime `mano.position` (local) junto a `mano.global_position` y explica por qué la primera no cambia y la segunda sí.
6. Aplica una traslación al nodo raíz `BrazoRobot` en `_process` y verifica que toda la jerarquía se desplaza junta.

## 📝 Reto verificable

Crea un brazo articulado de al menos tres segmentos que realice un ciclo de "saludo" convincente: la base gira suavemente, el antebrazo se levanta y la mano se agita de lado a lado, todo por código y en bucle. **Criterio de aceptación**: al ejecutar, el movimiento es fluido y jerárquicamente coherente (rotar el segmento inferior arrastra a los superiores), ningún segmento se separa visualmente de la cadena, y toda la animación usa `rotation_degrees` con `delta`.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Al rotar el padre los hijos se separan del brazo | Los pivotes están mal colocados. Ajusta la posición local de cada segmento para que su origen quede en la articulación. |
| `Node not found: "Base/Antebrazo"` | La ruta en `$` no coincide con la jerarquía real. Verifica los nombres y el anidamiento en el árbol de escena. |
| El brazo entero desaparece al escalar | Escalaste el nodo raíz a 0 o con valores negativos. Usa `scale` positivo y distinto de cero. |
| La rotación se ve "a saltos" bruscos | Estás sumando grados sin `delta` o reasignando valores absolutos grandes. Suaviza con funciones continuas y `delta`. |
| Confundir `rotation` con `rotation_degrees` | `rotation` está en radianes. Asignar 40 a `rotation.y` da una rotación enorme. Usa `rotation_degrees` para grados. |

## ❓ Preguntas frecuentes

**❓ ¿Cuál es la diferencia entre `position` y `global_position`?** `position` es relativa al padre; `global_position` es absoluta respecto al mundo. Si el padre se mueve, la primera no cambia pero la segunda sí.

**❓ ¿Por qué el gizmo tiene tres colores?** Cada color es un eje: rojo=X, verde=Y, azul=Z. Arrastrar un eje limita la transformación a esa dirección; el centro permite mover libremente.

**❓ ¿El snapping afecta al código?** No. El snapping es una ayuda del editor para manipular con el ratón. Por código puedes asignar cualquier valor continuo.

**❓ ¿Puedo reutilizar el brazo en otra escena?** Sí. Guarda `BrazoRobot` como su propia escena `.tscn` e instánciala donde la necesites; la jerarquía y el script viajan con ella.

## 🔗 Referencias

- Godot Docs — Using 3D transforms: <https://docs.godotengine.org/en/stable/tutorials/3d/using_transforms.html>
- Godot Docs — Clase Node3D: <https://docs.godotengine.org/en/stable/classes/class_node3d.html>
- Godot Docs — Introduction to 3D (viewport y gizmo): <https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html>
- Godot Docs — Nodes and scene instances: <https://docs.godotengine.org/en/stable/tutorials/scripting/nodes_and_scene_instances.html>

## ⬅️ Clase anterior

[Clase 046 - Del 2D al 3D: qué cambia (ejes, cámaras y mallas)](../046-del-2d-al-3d-que-cambia-ejes-camaras-y-mallas/README.md)

## ➡️ Siguiente clase

[Clase 048 - Sistemas de coordenadas 3D y Transform3D (basis y origin)](../048-sistemas-de-coordenadas-3d-y-transform3d-basis-y-origin/README.md)
