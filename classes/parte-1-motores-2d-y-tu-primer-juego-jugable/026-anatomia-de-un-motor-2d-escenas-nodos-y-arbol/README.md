# Clase 026 — Anatomía de un motor 2D: escenas, nodos y árbol

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4 (Nodes and scenes)*
> ⏱️ Duración estimada: **75 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Entender el paradigma central de Godot 4: los **nodos** como bloques funcionales, las **escenas** como árboles de nodos reutilizables y el **SceneTree** como estructura que ejecuta todo el juego en tiempo real. Este modelo mental es la base sobre la que construiremos, clase a clase, un plataformas 2D completo.

Al terminar sabrás por qué en Godot "todo es un nodo", cómo componer escenas dentro de otras escenas y cómo se traduce esto respecto a los `GameObject` y `Prefab` de Unity. Dejarás creado el proyecto del curso con una escena `Mundo` que contiene una escena `Jugador` reutilizable, lista para crecer.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar la diferencia entre nodo, escena y SceneTree con ejemplos concretos.
2. Crear un proyecto nuevo en Godot 4 y organizar carpetas (`escenas/`, `sprites/`).
3. Construir una escena reutilizable (`Jugador`) y guardarla como archivo `.tscn`.
4. Instanciar una escena dentro de otra (`Jugador` dentro de `Mundo`) y ejecutarla.
5. Dibujar el árbol de nodos resultante y relacionarlo con el concepto de composición.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Nodo como unidad básica | Es el "ladrillo" con el que se arma todo en Godot. |
| 2 | Tipos de nodos (Node2D, Sprite2D…) | Cada tipo aporta una capacidad distinta. |
| 3 | Escena = árbol de nodos | Permite agrupar y reutilizar comportamiento. |
| 4 | Nodo raíz | Define qué es la escena y cómo se instancia. |
| 5 | Instanciar escenas | La reutilización real: un `Jugador` en muchos niveles. |
| 6 | SceneTree y nodo raíz del juego | Es el motor de ejecución en vivo. |
| 7 | Composición vs herencia | Filosofía de diseño de Godot frente a otros motores. |
| 8 | Equivalencias con Unity | Transfiere lo que ya sabes a Prefabs/GameObjects. |

## 📖 Definiciones y características

- **Nodo**: unidad mínima de funcionalidad (dibujar, sonar, colisionar). Clave: cada nodo tiene un tipo que determina sus propiedades y métodos.
- **Escena (`.tscn`)**: conjunto de nodos organizados en árbol y guardado en disco. Clave: puede instanciarse muchas veces como si fuera una plantilla.
- **Nodo raíz**: el nodo superior de una escena; su tipo define el "rol" de la escena. Clave: al instanciarla, este nodo es el punto de anclaje.
- **SceneTree**: estructura viva que contiene la escena en ejecución y reparte los callbacks. Clave: gestiona el ciclo de vida y la señal `ready`.
- **Instancia**: copia funcional de una escena colocada dentro de otra. Clave: cambios en el `.tscn` original se propagan a todas las instancias.
- **Composición por nodos**: construir comportamiento sumando nodos hijos en lugar de heredar clases. Clave: favorece piezas pequeñas y reutilizables.
- **Node2D**: nodo base para el mundo 2D; aporta `position`, `rotation` y `scale`. Clave: casi todo objeto visible 2D hereda de él.
- **Sprite2D**: nodo que dibuja una textura en pantalla. Clave: lo usaremos como marcador visual del jugador.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x** instalado (versión estándar, sin C#, salvo que lo prefieras). Descárgalo desde <https://godotengine.org/download>. No requiere instalación: es un único ejecutable. Abre el **Project Manager**, que es la ventana desde la que se crean y administran proyectos.

Como marcador visual usaremos por ahora un icono que Godot incluye en todo proyecto nuevo (`icon.svg`), así no dependemos de descargar assets. Ten a mano la documentación oficial de nodos y escenas: <https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html>.

## 🧪 Laboratorio guiado

Vamos a crear el proyecto del curso y montar `Mundo` con un `Jugador` reutilizable dentro.

1. En el **Project Manager**, pulsa **New Project**. Nombre: `PlataformasCurso`. Elige una carpeta vacía, renderer **Compatibility** (más ligero) y **Create & Edit**.

2. En el panel **FileSystem** (abajo a la izquierda), haz clic derecho sobre `res://` → **Create Folder** y crea dos carpetas: `escenas` y `sprites`.

3. Crea la escena del jugador. En el panel **Scene** (arriba izquierda) pulsa **+ Other Node**, busca **Node2D** y selecciónalo como raíz. Haz doble clic en su nombre y renómbralo a `Jugador`.

4. Con `Jugador` seleccionado, pulsa el **+** para añadir un hijo **Sprite2D**. En el **Inspector** (derecha), en la propiedad **Texture**, elige **Load** y selecciona `res://icon.svg`. Ya tienes un marcador visible.

5. Guarda la escena con `Ctrl+S` dentro de `escenas/` como `jugador.tscn`. Acabas de crear una **escena reutilizable**.

6. Crea la escena principal. Menú **Scene → New Scene**. Añade un **Node2D** como raíz y renómbralo `Mundo`. Guárdalo como `escenas/mundo.tscn`.

7. Instancia al jugador dentro del mundo. Con `Mundo` seleccionado, pulsa el icono de **cadena/eslabón** ("Instantiate Child Scene") en la barra del panel Scene, elige `jugador.tscn` y acepta. Aparecerá `Jugador` como hijo de `Mundo`, con un icono distinto que indica que es una instancia.

8. Mueve la instancia en el viewport hasta el centro para verla bien. Fíjate en el árbol resultante en el panel Scene:

```text
Mundo (Node2D)
└── Jugador (instancia de jugador.tscn)
    └── Sprite2D
```

9. Añade un pequeño script al mundo para confirmar que el árbol se arma al arrancar. Selecciona `Mundo`, pulsa el icono de **Attach Script**, ruta `escenas/mundo.gd`, y escribe:

```gdscript
extends Node2D

# _ready() se ejecuta cuando el nodo y todos sus hijos entran al SceneTree.
func _ready() -> void:
	print("Mundo listo. Hijos directos: ", get_child_count())
	# Recorremos el árbol para inspeccionar su composición.
	for hijo in get_children():
		print("- ", hijo.name, " (", hijo.get_class(), ")")
```

10. Define `mundo.tscn` como escena principal: menú **Project → Project Settings → Application → Run**, campo **Main Scene** → `escenas/mundo.tscn`. Ejecuta con **F5**. Verás el icono del jugador en pantalla y, en el panel **Output**, el nombre y tipo de los hijos del mundo.

Con esto ya tienes composición real: una escena `Jugador` que podrás instanciar tantas veces como quieras en cualquier nivel.

## ✍️ Ejercicios

1. Instancia un segundo `Jugador` dentro de `Mundo` y colócalo en otra posición. Observa que ambos comparten el mismo `.tscn`.
2. Cambia la textura del `Sprite2D` en `jugador.tscn` y comprueba cómo afecta a todas las instancias.
3. Renombra el nodo raíz `Jugador` y explica por qué el nombre del nodo raíz importa al instanciar.
4. Añade un nodo hijo `Marker2D` al jugador llamado `PuntoDisparo` y descríbelo como futuro punto de origen de balas.
5. Modifica el script para imprimir también la posición global de cada hijo con `hijo.global_position`.
6. Dibuja en papel el árbol de nodos con dos jugadores y explica qué es raíz y qué es instancia.

## 📝 Reto verificable

Crea una tercera escena `Moneda` (raíz `Node2D` con un `Sprite2D`) e instánciala tres veces dentro de `Mundo`, en posiciones distintas. Amplía `mundo.gd` para que al arrancar imprima cuántos hijos son jugadores y cuántos son monedas, distinguiéndolos por su nombre.

**Criterio de aceptación**: al pulsar F5 se ven en pantalla el jugador y las tres monedas, y el Output muestra el conteo correcto de cada tipo sin errores.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Al ejecutar aparece "No main scene has ever been defined" | No configuraste la Main Scene. Ve a Project Settings → Run y asígnala, o pulsa F6 para correr la escena actual. |
| El sprite no se ve en pantalla | La textura está vacía o el nodo está fuera del viewport. Asigna Texture y centra la posición. |
| Editar el jugador no cambia las instancias | Estás editando dentro de `mundo.tscn`, no en `jugador.tscn`. Abre el `.tscn` original para cambios globales. |
| "Attempt to call function on a null instance" | Usaste `$Ruta` a un nodo inexistente o mal escrito. Verifica el nombre exacto en el panel Scene. |
| Se creó el nodo pero no es el raíz esperado | Elegiste mal el tipo de raíz. Borra y recrea la escena con el tipo correcto. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué en Godot "todo es un nodo"?** Porque cada capacidad (dibujar, sonar, colisionar) se implementa como un tipo de nodo, y al combinarlos por composición armas objetos complejos sin herencia rígida.

**❓ ¿Una escena y un nodo son lo mismo?** No. Un nodo es una pieza; una escena es un árbol de nodos guardado en disco que puede instanciarse como plantilla reutilizable.

**❓ ¿Esto se parece a los Prefabs de Unity?** Sí: una escena instanciable equivale a un Prefab, y el nodo raíz cumple el papel del `GameObject` principal del Prefab.

**❓ ¿Qué es exactamente el SceneTree?** Es la estructura en memoria que contiene la escena activa mientras el juego corre y reparte los callbacks como `_ready` y `_process`.

## 🔗 Referencias

- Godot Docs — Nodes and scenes: <https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html>
- Godot Docs — Instancing: <https://docs.godotengine.org/en/stable/getting_started/step_by_step/instancing.html>
- Godot Docs — SceneTree: <https://docs.godotengine.org/en/stable/tutorials/scripting/scene_tree.html>
- Godot Docs — Scene organization: <https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html>

## ➡️ Siguiente clase

[Clase 027 - Godot: interfaz, proyecto y primer sprite en pantalla](../027-godot-interfaz-proyecto-y-primer-sprite-en-pantalla/README.md)
