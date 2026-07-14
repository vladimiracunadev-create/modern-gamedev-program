# Clase 046 — Del 2D al 3D: qué cambia (ejes, cámaras y mallas)

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot 4 — Introduction to 3D*
> ⏱️ Duración estimada: **50 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Comprender qué cambia realmente al pasar de un juego 2D a uno 3D en Godot 4: la aparición del eje Z y la profundidad, cámaras que tienen posición y orientación en el espacio, mallas tridimensionales en lugar de sprites planos, y un modelo de iluminación que ahora sí importa. La meta no es dominar todavía cada nodo, sino construir un mapa mental sólido para no perderse cuando abras por primera vez el viewport 3D.

Al terminar habrás creado tu primer proyecto 3D funcional: una escena con un cubo iluminado, encuadrado por una cámara, y habrás movido esa cámara por código para sentir cómo se navega el espacio tridimensional.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar las diferencias fundamentales entre trabajar en 2D y en 3D (profundidad, eje Z, orientación de cámara).
2. Identificar los nodos 3D básicos de Godot 4 y su equivalente conceptual en 2D.
3. Crear un proyecto 3D desde cero con una escena que tenga `Node3D` como raíz.
4. Añadir una `MeshInstance3D`, una `Camera3D` y una `DirectionalLight3D`, y ejecutar la escena.
5. Mover la cámara por código usando `_process` y observar el resultado en tiempo de ejecución.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | El eje Z y la profundidad | Es la dimensión nueva; define qué está cerca o lejos de la cámara. |
| 2 | Sistema de coordenadas Y-up | Godot usa Y hacia arriba en 3D; confundirlo rompe posiciones y físicas. |
| 3 | Cámaras con posición y orientación | En 3D la cámara es un objeto en el mundo, no un rectángulo de viewport. |
| 4 | Mallas vs sprites | Los objetos se dibujan con geometría (vértices y caras), no imágenes planas. |
| 5 | Iluminación | Sin luces una escena 3D se ve negra o plana; la luz da volumen. |
| 6 | Coste de rendimiento | El 3D consume más GPU/CPU; conviene saberlo desde el inicio. |
| 7 | Cuándo elegir 2D o 3D | No todo juego necesita 3D; la decisión afecta todo el proyecto. |

## 📖 Definiciones y características

- **Eje Z**: tercera dimensión perpendicular al plano XY que representa la profundidad. Clave: en Godot 3D el "adelante" de la cámara mira hacia -Z.
- **Y-up**: convención donde el eje Y apunta hacia arriba. Clave: difiere del 2D (donde Y crece hacia abajo en pantalla), así que reajusta tu intuición.
- **Malla (Mesh)**: conjunto de vértices, aristas y caras que definen la superficie de un objeto 3D. Clave: sustituye al sprite como unidad visual.
- **Camera3D**: nodo que define desde dónde y hacia dónde se observa la escena. Clave: si no hay ninguna activa, no se ve nada.
- **DirectionalLight3D**: luz que ilumina como el sol, con rayos paralelos y una dirección global. Clave: su rotación, no su posición, determina el ángulo de la luz.
- **Node3D**: nodo base de todo objeto con transformación en el espacio 3D. Clave: es el equivalente 3D de `Node2D`.
- **WorldEnvironment**: recurso que controla cielo, niebla, tonemapping y glow de toda la escena. Clave: define la "atmósfera" global.
- **Draw call**: cada instrucción de dibujo que la CPU envía a la GPU. Clave: en 3D se multiplican y afectan el rendimiento.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x instalado desde <https://godotengine.org/download>. Trabajaremos con la documentación oficial de introducción al 3D en <https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html> y la referencia de nodos 3D en <https://docs.godotengine.org/en/stable/classes/class_node3d.html>. Ten a mano también la guía del viewport 3D en <https://docs.godotengine.org/en/stable/tutorials/3d/using_transforms.html>. No necesitas ningún modelo externo todavía: usaremos mallas primitivas que el propio editor genera.

## 🧪 Laboratorio guiado

Vamos a crear un proyecto 3D limpio y montar la escena mínima para ver un cubo iluminado.

1. Abre Godot y crea un **proyecto nuevo** con renderizador **Forward+** (o Mobile si tu GPU es modesta). Nómbralo `lab3d_046`.

2. En la pestaña *Escena*, pulsa **Otro nodo** y elige **Node3D**. Renómbralo a `Mundo`. Guarda la escena como `mundo.tscn`.

3. Añade tres hijos a `Mundo`: un **MeshInstance3D**, una **Camera3D** y una **DirectionalLight3D**.

4. Selecciona la `MeshInstance3D`. En el *Inspector*, en la propiedad **Mesh**, elige **Nuevo BoxMesh**. Aparecerá un cubo en el origen.

5. Para controlar todo por código, adjunta un script a `Mundo`. Este script coloca la cámara, orienta la luz y anima la cámara alrededor del cubo:

```gdscript
extends Node3D

@onready var camara: Camera3D = $Camera3D
@onready var luz: DirectionalLight3D = $DirectionalLight3D
@onready var cubo: MeshInstance3D = $MeshInstance3D

var angulo: float = 0.0
@export var radio: float = 4.0
@export var velocidad_orbita: float = 0.6

func _ready() -> void:
	# El cubo permanece en el origen del mundo.
	cubo.position = Vector3.ZERO

	# La luz direccional ilumina según su rotación, no su posición.
	luz.rotation_degrees = Vector3(-50, -30, 0)

	# Colocamos la cámara y hacemos que mire al cubo.
	camara.position = Vector3(0, 3, radio)
	camara.look_at(cubo.global_position, Vector3.UP)

func _process(delta: float) -> void:
	# Orbitamos la cámara alrededor del cubo en el plano XZ.
	angulo += velocidad_orbita * delta
	var x := radio * sin(angulo)
	var z := radio * cos(angulo)
	camara.position = Vector3(x, 3, z)

	# En cada cuadro reorientamos la cámara hacia el cubo.
	camara.look_at(cubo.global_position, Vector3.UP)
```

6. Pulsa **F6** (ejecutar escena actual). Deberías ver el cubo iluminado desde arriba mientras la cámara gira lentamente a su alrededor. Observa cómo la cara iluminada cambia según el ángulo: eso es la profundidad y la luz trabajando juntas.

7. Experimenta: cambia `radio` y `velocidad_orbita` en el Inspector y vuelve a ejecutar. Modifica la `rotation_degrees` de la luz para ver cómo cambian las sombras del volumen.

## ✍️ Ejercicios

1. Cambia el `BoxMesh` por un `SphereMesh` y comprueba cómo la iluminación revela mejor la curvatura que en el cubo.
2. Añade una segunda `MeshInstance3D` desplazada en el eje Z y observa cuál queda delante según la posición de la cámara.
3. Modifica la altura de la cámara (la componente Y) durante la órbita para que suba y baje con una función `sin`.
4. Invierte el sentido de la órbita usando `-velocidad_orbita` y verifica que la cámara sigue mirando al cubo.
5. Añade un `WorldEnvironment` con un `Environment` que use un cielo procedimental y compara el aspecto con el fondo gris por defecto.
6. Reemplaza `DirectionalLight3D` por un `OmniLight3D` colocado cerca del cubo y describe la diferencia en la iluminación.

## 📝 Reto verificable

Construye una escena donde **dos** cubos de distinto tamaño orbiten a distinta velocidad alrededor de un cubo central fijo, todo controlado por código, mientras la cámara permanece quieta mirando al centro. **Criterio de aceptación**: al ejecutar, los dos cubos giran de forma visiblemente distinta sin que ninguno se salga del encuadre, la cámara nunca deja de apuntar al cubo central, y todo el movimiento se define en `_process` usando `delta`.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Pantalla completamente negra o vacía | No hay `Camera3D` activa o mira hacia el lado contrario. Añade una cámara y usa `look_at` hacia el objeto. |
| El cubo se ve pero sin volumen, plano y gris | Falta iluminación. Añade una `DirectionalLight3D` y ajusta su `rotation_degrees`. |
| `Invalid call to look_at` con vectores alineados | El objetivo está justo encima/debajo y coincide con `Vector3.UP`. Desplaza la cámara para que no queden colineales. |
| El objeto no aparece donde esperabas | Confundiste el eje Y (arriba) con el Z (profundidad). Recuerda: Y-up en 3D. |
| Todo se mueve a velocidades distintas en cada PC | Olvidaste multiplicar por `delta`. Escala siempre el movimiento por `delta` en `_process`. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué mi cámara mira al lado contrario del objeto?** Porque en Godot la cámara "mira" hacia su eje -Z local. Usa `look_at(objetivo, Vector3.UP)` para orientarla correctamente sin calcular ángulos a mano.

**❓ ¿Necesito siempre una luz en una escena 3D?** Prácticamente sí. Sin luces (ni luz ambiental del `Environment`) las superficies se ven negras o planas. Una `DirectionalLight3D` es el punto de partida más simple.

**❓ ¿El eje Y hacia arriba también aplica en 2D?** No. En 2D el eje Y crece hacia abajo de la pantalla; en 3D crece hacia arriba. Es uno de los ajustes mentales más importantes al empezar.

**❓ ¿Puedo mezclar 2D y 3D en el mismo juego?** Sí, con `SubViewport` y elementos de interfaz sobre la escena 3D, pero conviene dominar cada mundo por separado antes de combinarlos.

## 🔗 Referencias

- Godot Docs — Introduction to 3D: <https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html>
- Godot Docs — Using 3D transforms: <https://docs.godotengine.org/en/stable/tutorials/3d/using_transforms.html>
- Godot Docs — Clase Camera3D: <https://docs.godotengine.org/en/stable/classes/class_camera3d.html>
- Godot Docs — Clase DirectionalLight3D: <https://docs.godotengine.org/en/stable/classes/class_directionallight3d.html>

## ➡️ Siguiente clase

[Clase 047 - Escenas 3D en Godot: Node3D, transformaciones y gizmo](../047-escenas-3d-en-godot-node3d-transformaciones-y-gizmo/README.md)
