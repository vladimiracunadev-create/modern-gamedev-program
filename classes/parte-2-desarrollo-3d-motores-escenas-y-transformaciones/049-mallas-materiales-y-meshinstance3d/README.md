# Clase 049 — Mallas, materiales y MeshInstance3D

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot 4 — 3D rendering y Standard Material 3D*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Entender qué es realmente una malla (los vértices, caras, normales y coordenadas UV que forman la superficie de un objeto) y cómo `MeshInstance3D` la dibuja en la escena con un material. Aprenderás a crear mallas primitivas por código, a asignarles un `StandardMaterial3D` y a controlar el aspecto físico de cada superficie con propiedades como albedo, metallic, roughness y emission.

El resultado es la capacidad de dar personalidad visual a tus objetos: distinguir un metal pulido de un plástico mate o de una superficie que brilla con luz propia, y cambiar esas propiedades en tiempo de ejecución.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Describir los componentes de una malla (vértices, caras, normales, UV) y el rol de `MeshInstance3D`.
2. Crear mallas primitivas por código (`BoxMesh`, `SphereMesh`) y asignarlas a instancias.
3. Configurar un `StandardMaterial3D` con albedo, metallic, roughness y emission.
4. Asignar materiales por recurso y mediante `material_override`.
5. Modificar propiedades de material en runtime para animar el aspecto de un objeto.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es una malla | Es la unidad de geometría; sin ella no hay nada que dibujar. |
| 2 | Vértices, caras, normales, UV | Definen forma, orientación de superficie e iluminación y texturizado. |
| 3 | MeshInstance3D | El nodo que instancia y renderiza una malla en la escena. |
| 4 | Mallas primitivas | Prototipar rápido sin modelar en Blender. |
| 5 | StandardMaterial3D | El material PBR estándar que da aspecto físico creíble. |
| 6 | Albedo, metallic, roughness, emission | Controlan color, reflejo metálico, rugosidad y luz propia. |
| 7 | material_override vs surface | Dos formas de asignar material con distinto alcance. |

## 📖 Definiciones y características

- **Malla (Mesh)**: recurso que describe una superficie 3D mediante geometría. Clave: es un recurso reutilizable entre varias instancias.
- **Vértice**: punto en el espacio 3D; los vértices forman las esquinas de las caras. Clave: menos vértices, más barato de renderizar.
- **Normal**: vector perpendicular a una cara que indica hacia dónde "mira"; determina cómo recibe la luz. Clave: normales invertidas causan caras oscuras o invisibles.
- **UV**: coordenadas 2D que mapean una textura sobre la malla. Clave: sin buen UV las texturas se ven deformadas.
- **MeshInstance3D**: nodo que dibuja una malla en la escena aplicando su transform y material. Clave: separa geometría (recurso) de posición (nodo).
- **StandardMaterial3D**: material PBR con propiedades físicas. Clave: es el material por defecto para superficies realistas.
- **Albedo**: color base de la superficie. Clave: es el color sin reflejos ni sombras.
- **material_override**: material que sustituye a todos los materiales de superficie de la instancia. Clave: útil para cambiar el aspecto sin tocar el recurso malla.

## 🧰 Herramientas y preparación

Trabaja en Godot 4.x. Las referencias clave son la clase `StandardMaterial3D` en <https://docs.godotengine.org/en/stable/classes/class_standardmaterial3d.html>, la clase `MeshInstance3D` en <https://docs.godotengine.org/en/stable/classes/class_meshinstance3d.html> y la guía de materiales espaciales en <https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html>. Para entender mallas primitivas revisa <https://docs.godotengine.org/en/stable/classes/class_primitivemesh.html>. Crea un proyecto 3D nuevo con iluminación básica.

## 🧪 Laboratorio guiado

Generaremos tres objetos por código, cada uno con un material distinto (metal, plástico y emisivo), y animaremos una propiedad en runtime.

1. Crea una escena con `Node3D` raíz `Materiales`, una `Camera3D`, una `DirectionalLight3D` y un `WorldEnvironment` con un cielo simple para que los metales tengan algo que reflejar.

2. Adjunta este script al nodo raíz. Crea tres `MeshInstance3D` por código, cada una con su malla y material:

```gdscript
extends Node3D

var emisivo_mat: StandardMaterial3D
var pulso: float = 0.0

func _ready() -> void:
	# --- Objeto 1: esfera metálica pulida ---
	var metal := MeshInstance3D.new()
	metal.mesh = SphereMesh.new()
	var mat_metal := StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.8, 0.8, 0.85)
	mat_metal.metallic = 1.0
	mat_metal.roughness = 0.1  # bajo = pulido y reflectante
	metal.material_override = mat_metal
	metal.position = Vector3(-2.5, 0, 0)
	add_child(metal)

	# --- Objeto 2: cubo de plástico mate ---
	var plastico := MeshInstance3D.new()
	plastico.mesh = BoxMesh.new()
	var mat_plastico := StandardMaterial3D.new()
	mat_plastico.albedo_color = Color(0.9, 0.2, 0.2)
	mat_plastico.metallic = 0.0
	mat_plastico.roughness = 0.8  # alto = mate, sin reflejos nítidos
	plastico.material_override = mat_plastico
	plastico.position = Vector3(0, 0, 0)
	add_child(plastico)

	# --- Objeto 3: esfera emisiva (brilla con luz propia) ---
	var emisivo := MeshInstance3D.new()
	emisivo.mesh = SphereMesh.new()
	emisivo_mat = StandardMaterial3D.new()
	emisivo_mat.albedo_color = Color(0.1, 0.1, 0.1)
	emisivo_mat.emission_enabled = true
	emisivo_mat.emission = Color(0.1, 0.6, 1.0)
	emisivo_mat.emission_energy_multiplier = 2.0
	emisivo.material_override = emisivo_mat
	emisivo.position = Vector3(2.5, 0, 0)
	add_child(emisivo)

func _process(delta: float) -> void:
	# Animamos la intensidad de emisión en runtime: un latido.
	pulso += delta * 2.0
	var energia := 1.5 + 1.5 * abs(sin(pulso))
	emisivo_mat.emission_energy_multiplier = energia
```

3. Ajusta la `Camera3D` para ver los tres objetos en fila (por ejemplo `position = Vector3(0, 1.5, 6)` y un `look_at` al origen). Ejecuta con **F6**.

4. Observa las diferencias: la esfera de la izquierda refleja el entorno como un metal pulido; el cubo rojo se ve mate y difuso; la esfera de la derecha late con luz azul propia, iluminando incluso sin recibir la luz direccional.

5. Experimenta en caliente: sube `roughness` del metal a `0.6` y verás cómo pierde nitidez en los reflejos. Baja la `emission_energy_multiplier` base y el latido se hará más sutil.

## ✍️ Ejercicios

1. Crea un cuarto objeto con `metallic = 0.5` y `roughness = 0.3` y describe dónde queda entre metal y plástico.
2. Cambia el `albedo_color` del plástico por código cada segundo usando un temporizador o `Engine.get_physics_frames()`.
3. Activa la transparencia (`transparency = BaseMaterial3D.TRANSPARENCY_ALPHA` y un alpha < 1 en el albedo) en una esfera y observa el efecto.
4. Aplica el **mismo** recurso `StandardMaterial3D` a dos instancias y confirma que cambiarlo afecta a ambas.
5. Sustituye `material_override` por asignar el material a la superficie 0 con `set_surface_override_material(0, mat)` y comenta la diferencia.
6. Anima el `roughness` del metal entre 0.05 y 0.9 con una función seno y describe el resultado visual.

## 📝 Reto verificable

Construye una "vitrina de materiales" con al menos cinco esferas idénticas en fila, cada una con un `StandardMaterial3D` que varíe progresivamente el `metallic` de 0.0 a 1.0 (0, 0.25, 0.5, 0.75, 1.0), todas generadas por código. **Criterio de aceptación**: al ejecutar se aprecia una transición clara de aspecto plástico a metálico a lo largo de la fila, cada material es un recurso independiente, y la escena incluye iluminación y un `WorldEnvironment` con cielo para que los reflejos metálicos sean visibles.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El metal se ve negro y sin reflejos | No hay `WorldEnvironment` con cielo que reflejar. Añade un `Environment` con sky. |
| Todos los objetos comparten el mismo material sin querer | Reutilizaste la misma instancia de material. Crea un `StandardMaterial3D.new()` por objeto. |
| La emisión no se ve | Olvidaste `emission_enabled = true` o la energía es 0. Actívala y sube `emission_energy_multiplier`. |
| El objeto se ve plano y sin sombreado | La malla no tiene normales correctas o falta luz. Usa mallas primitivas y añade una `DirectionalLight3D`. |
| Cambiar `material_override` no afecta nada | Estás modificando otro material (el de superficie). `material_override` tiene prioridad; edita el mismo recurso que asignaste. |

## ❓ Preguntas frecuentes

**❓ ¿Cuál es la diferencia entre `material_override` y el material de superficie?** El de superficie se define por cada superficie de la malla; `material_override` reemplaza a todos ellos en esa instancia sin alterar el recurso malla. Úsalo para cambios rápidos por instancia.

**❓ ¿Qué significan metallic y roughness juntos?** `metallic` indica cuánto se comporta la superficie como metal (refleja el entorno); `roughness` indica cuán difusos son esos reflejos. Metal bajo + roughness alto = plástico mate; metal alto + roughness bajo = espejo.

**❓ ¿La emisión ilumina otros objetos?** El material emisivo brilla por sí mismo, pero no ilumina la escena como una luz real salvo que uses técnicas adicionales (como GI). Para iluminar de verdad usa un nodo de luz.

**❓ ¿Puedo reutilizar una malla entre muchas instancias?** Sí, y es recomendable. La malla es un recurso; varias `MeshInstance3D` pueden compartir la misma geometría con distinta posición y material.

## 🔗 Referencias

- Godot Docs — Standard Material 3D: <https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html>
- Godot Docs — Clase MeshInstance3D: <https://docs.godotengine.org/en/stable/classes/class_meshinstance3d.html>
- Godot Docs — Clase StandardMaterial3D: <https://docs.godotengine.org/en/stable/classes/class_standardmaterial3d.html>
- Godot Docs — Clase PrimitiveMesh: <https://docs.godotengine.org/en/stable/classes/class_primitivemesh.html>

## ⬅️ Clase anterior

[Clase 048 - Sistemas de coordenadas 3D y Transform3D (basis y origin)](../048-sistemas-de-coordenadas-3d-y-transform3d-basis-y-origin/README.md)

## ➡️ Siguiente clase

[Clase 050 - Importar modelos 3D: glTF, Blender y el pipeline](../050-importar-modelos-3d-gltf-blender-y-el-pipeline/README.md)
