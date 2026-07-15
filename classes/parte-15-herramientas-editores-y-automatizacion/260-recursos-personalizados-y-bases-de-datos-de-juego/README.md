# Clase 260 — Recursos personalizados y bases de datos de juego

> Parte: **15 — Herramientas, editores y automatización (tooling)** · Fuente: *Documentación de Godot 4 (Resources, Creating your own resources) y clases `Resource`, `ResourceLoader`*
> ⏱️ Duración estimada: **75 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Un **recurso personalizado** es un tipo de dato tuyo que Godot trata como ciudadano de primera clase: se edita en el Inspector, se guarda como archivo `.tres`, se referencia entre escenas y se carga con `load()`. Es la forma idiomática de modelar armas, objetos, habilidades o niveles como **datos reutilizables** en lugar de constantes dispersas por el código. Cierra el círculo del tooling: en la clase anterior generamos recursos desde datos crudos; ahora los diseñamos, agrupamos y consumimos.

En esta clase creamos un recurso `Arma` con `class_name` y `@export`, lo organizamos con `@export_group` para un Inspector limpio, y construimos una **base de datos de armas** como un recurso que contiene un `Array[Arma]`. Aprenderás a guardar cada arma como `.tres`, a montar la base de datos, a **consumirla desde el juego** con `ResourceLoader.load()`, y a aprovechar la **herencia de recursos** para variantes (un arma épica que extiende una base).

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Definir un recurso personalizado con `class_name ... extends Resource` y propiedades `@export`.
2. Organizar propiedades en el Inspector con `@export_group` y otras anotaciones.
3. Guardar y cargar recursos `.tres` con `ResourceSaver` y `ResourceLoader`.
4. Modelar una base de datos de juego como recurso que agrega un `Array` de recursos.
5. Consumir la base de datos desde código de juego y crear variantes por herencia.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es un `Resource` personalizado | Datos tipados, editables y reutilizables. |
| 2 | `class_name` + `@export` | Registra el tipo y expone sus campos en el Inspector. |
| 3 | Archivos `.tres` | Persistencia legible y versionable de instancias. |
| 4 | `@export_group` y organización | Inspector legible cuando hay muchas propiedades. |
| 5 | Base de datos como recurso | Un solo archivo agrupa todo el catálogo. |
| 6 | Cargar con `ResourceLoader` | Acceso a los datos desde el juego. |
| 7 | Herencia de recursos | Variantes que reutilizan una base común. |
| 8 | Referencias entre recursos | Un recurso puede apuntar a otro (arma → efecto). |

## 📖 Definiciones y características

- **`Resource`**: clase base de datos serializable en Godot. Clave: se comparte por referencia y se guarda como archivo.
- **Recurso personalizado**: subclase de `Resource` con `class_name` propio. Clave: aparece en el diálogo "New Resource" y en los `@export` tipados.
- **`.tres`**: formato de texto para guardar una instancia de recurso. Clave: legible y apto para control de versiones (diffs claros).
- **`@export_group(nombre)`**: agrupa las propiedades siguientes bajo un encabezado plegable en el Inspector. Clave: mejora la legibilidad de recursos grandes.
- **Base de datos de juego**: recurso que contiene un `Array` (o `Dictionary`) de otros recursos. Clave: centraliza el catálogo en un único `.tres`.
- **`ResourceLoader.load(ruta)`**: carga un recurso desde disco (cacheado). Clave: `load()` es el atajo habitual y devuelve el mismo tipo.
- **Herencia de recursos**: un `.tres` puede basarse en otro `.tres` heredando y sobreescribiendo campos. Clave: evita duplicar datos comunes entre variantes.
- **Referencia por recurso**: un `@export` cuyo tipo es otro recurso. Clave: modela relaciones (un arma que referencia un efecto de estado).

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x**. No hace falta ningún plugin: los recursos personalizados son parte del núcleo. Trabajaremos casi todo desde el Inspector y una pequeña escena de consumo. Ten a mano una carpeta `res://datos/armas/` para los `.tres`.

Lee la guía oficial de creación de recursos propios, que muestra el flujo completo: <https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html>. La referencia de la clase base está en `Resource`: <https://docs.godotengine.org/en/stable/classes/class_resource.html>. Para las anotaciones de exportación y grupos: <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html>.

## 🧪 Laboratorio guiado

Crearemos el recurso `Arma`, varios `.tres`, una base de datos que los agrupa, y una escena que consulta esa base en el juego.

1. Define el recurso `arma.gd` con `class_name`, campos `@export` y grupos para un Inspector ordenado. La herencia de `Resource` es lo que lo hace guardable:

```gdscript
@tool
class_name Arma
extends Resource

@export var id: StringName = &""
@export var nombre: String = "Arma"

@export_group("Combate")
@export var dano: int = 10
@export var cadencia: float = 1.0          # disparos por segundo
@export_range(0.0, 100.0) var alcance: float = 20.0

@export_group("Presentación")
@export var icono: Texture2D
@export var descripcion: String = ""
```

2. Crea instancias como `.tres` **desde el editor**: en el panel FileSystem, clic derecho → *New Resource* → busca `Arma`. Rellena los campos en el Inspector y guarda como `res://datos/armas/espada.tres`, `arco.tres`, etc. Observa cómo `@export_group` pliega "Combate" y "Presentación" por separado.

3. Modela la **base de datos** como su propio recurso `base_datos_armas.gd`, que agrega un `Array[Arma]` tipado y ofrece una búsqueda por id:

```gdscript
@tool
class_name BaseDatosArmas
extends Resource

@export var armas: Array[Arma] = []

func obtener(id: StringName) -> Arma:
	for a in armas:
		if a.id == id:
			return a
	return null

func ids() -> Array[StringName]:
	var lista: Array[StringName] = []
	for a in armas:
		lista.append(a.id)
	return lista
```

4. Crea un `.tres` de la base: *New Resource* → `BaseDatosArmas`, guárdalo como `res://datos/armas_db.tres`. En su Inspector, expande `armas`, fija el tamaño del array y **arrastra** cada `.tres` de arma a un slot. Ahora un único archivo describe todo el catálogo.

5. **Consume la base desde el juego**. Crea una escena con un `Node` y este script, que carga la base con `load()` y consulta un arma concreta:

```gdscript
extends Node

@export var db: BaseDatosArmas   # arrástrale armas_db.tres en el Inspector

func _ready() -> void:
	# Alternativa por código si no lo asignas en el Inspector:
	if db == null:
		db = ResourceLoader.load("res://datos/armas_db.tres") as BaseDatosArmas

	print("Armas en la base: ", db.ids())
	var espada := db.obtener(&"espada")
	if espada:
		print("%s hace %d de daño, alcance %.0f"
			% [espada.nombre, espada.dano, espada.alcance])
```

6. Aprovecha la **herencia de recursos** para una variante sin duplicar datos. Duplica `espada.tres` como `espada_epica.tres`; en su Inspector, en el desplegable de recurso base o editando el `.tres`, hazlo heredar de `espada.tres` y **sobrescribe solo** `nombre` y `dano`. En el juego, `espada_epica` reutiliza alcance y cadencia de la base pero con daño aumentado.

Ejecuta con **F5**: en el Output verás la lista de ids y las estadísticas del arma consultada. Has separado por completo el catálogo (datos `.tres`) del código que lo usa.

La lección observable: añadir un arma nueva no toca código; basta crear un `.tres` y añadirlo a la base.

## ✍️ Ejercicios

1. Añade un campo `tipo` con `@export_enum("Cuerpo a cuerpo", "Distancia")` y filtra la base por tipo.
2. Añade a `Arma` una referencia `@export var efecto: EfectoEstado` (otro recurso) y consúmela.
3. Crea un recurso `Objeto` distinto y una `BaseDatosObjetos`, reutilizando el mismo patrón.
4. Implementa en la base un método `aleatoria() -> Arma` que devuelva un arma al azar.
5. Usa `@export_range` con paso e `is_greater` para acotar `cadencia` a valores válidos.
6. Guarda una nueva arma desde código con `ResourceSaver.save()` y recárgala para verificar.

## 📝 Reto verificable

Diseña un recurso personalizado propio (arma, objeto, hechizo o carta) con `class_name`, al menos cinco `@export` organizados con `@export_group`, y una base de datos-recurso que agregue un `Array` de ese tipo con un método de búsqueda por id. Crea al menos tres instancias `.tres`, una de ellas por **herencia** de otra, y una escena que cargue la base y consulte un elemento en `_ready()`.

**Criterio de aceptación**: la base de datos `.tres` lista y devuelve los elementos por id al ejecutar; la instancia heredada reutiliza los campos de su base y solo sobrescribe los previstos; y añadir un elemento nuevo al catálogo no requiere modificar ninguna línea de código de consumo.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El recurso no aparece en "New Resource" | Falta `class_name` o el script no extiende `Resource`. Añade ambos y reescanea el FileSystem. |
| Todas las instancias comparten el mismo valor | Un `Resource` se comparte por referencia; asignaste la misma instancia. Crea `.tres` distintos o usa `duplicate()`. |
| `@export var db` sale vacío en runtime | No lo asignaste en el Inspector. Arrastra el `.tres` o cárgalo con `ResourceLoader.load()`. |
| El `Array[Arma]` acepta cualquier recurso | Declaraste `Array` sin tipar. Usa `Array[Arma]` para que el Inspector filtre. |
| La variante heredada no cambia nada | No sobrescribiste campos o no heredó bien. Verifica el recurso base y marca solo los campos a cambiar. |

## ❓ Preguntas frecuentes

**❓ ¿`.tres` o `.res` para mis datos?** `.tres` es texto: legible y con diffs limpios en control de versiones, ideal en desarrollo. `.res` es binario: más compacto y rápido de cargar, preferible para builds finales grandes.

**❓ ¿Por qué dos armas cambian a la vez al editar una?** Estás compartiendo la misma instancia de recurso. Godot comparte recursos por referencia; usa archivos separados o `recurso.duplicate()` para copias independientes.

**❓ ¿Base de datos como un `Array` o como `Dictionary`?** Un `Array[Arma]` es simple y se edita cómodo en el Inspector; un `Dictionary` da búsqueda O(1) por id. Muchos proyectos exponen el array y construyen un diccionario en `_ready()` para consultar rápido.

**❓ ¿La herencia de recursos es como la herencia de clases?** Se parece: el `.tres` hijo toma los valores del padre y sobrescribe los que definas. Es herencia de **datos**, no de comportamiento; el script sigue siendo el mismo `class_name`.

## 🔗 Referencias

- Godot Docs — Resources: <https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html>
- Godot Docs — `Resource`: <https://docs.godotengine.org/en/stable/classes/class_resource.html>
- Godot Docs — GDScript exports (`@export_group`, `@export_range`): <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html>
- Godot Docs — `ResourceLoader`: <https://docs.godotengine.org/en/stable/classes/class_resourceloader.html>

## ⬅️ Clase anterior

[Clase 259 - Generación y validación de datos (data-driven)](../259-generacion-y-validacion-de-datos-data-driven/README.md)

## ➡️ Siguiente clase

[Clase 261 - Automatización de builds y exportación por CLI](../261-automatizacion-de-builds-y-exportacion-por-cli/README.md)
