# Clase 294 — Items y base de datos de objetos

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Nystrom, «Game Programming Patterns» (Type Object) · Documentación de Resources de Godot 4*
> ⏱️ Duración estimada: **110 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir el **catálogo de objetos** del juego: la base de datos que dice qué es una poción, qué es una espada larga y qué es una llave oxidada, separada por completo del código que las usa. Es la pieza sobre la que se apoyan el inventario, el equipo, el loot, el crafting, las recompensas de quest y la tienda — es decir, casi toda la Parte 18.

Definirás una `ItemDefinition` con id estable, nombre, descripción, tipo, rareza, apilamiento, valor, etiquetas, icono, efectos y metadatos; la escribirás en **dos formatos** (recursos de Godot y JSON) para entender qué gana cada uno; y montarás un **validador** que la CI pueda ejecutar para que un catálogo roto se detecte antes de que un jugador se encuentre con un objeto sin nombre. Al terminar tendrás la distinción más importante de esta parte grabada: **definición** (dato compartido e inmutable) frente a **instancia** (estado en tiempo de ejecución de un objeto concreto).

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Distinguir **definición** de **instancia** y decidir en cuál va cada campo.
2. Diseñar **IDs estables** y explicar por qué el nombre visible nunca puede ser la clave.
3. Modelar un `ItemDefinition` completo con tipo, rareza, stack, valor, tags, icono y efectos.
4. Implementar una `BaseDeItems` que cargue el catálogo, lo indexe por id y falle ruidosamente ante un id desconocido.
5. Escribir un **esquema** y un validador que detecte ids duplicados, campos ausentes, rangos inválidos y referencias rotas.
6. Elegir entre `Resource` y JSON según quién edita el contenido y cómo se distribuye.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Definición vs instancia | Confundirlas es la causa nº 1 de bugs de duplicación de objetos. |
| 2 | IDs estables | Un id que cambia rompe todos los guardados existentes. |
| 3 | Campos de una ItemDefinition | Un modelo completo desde el principio evita 12 migraciones después. |
| 4 | Tipos y rarezas | Son enumeraciones de dominio, no cadenas sueltas repetidas. |
| 5 | Tags | La forma barata de responder preguntas que no previste ("todo lo inflamable"). |
| 6 | Stack y apilamiento | Determina cómo se comporta el inventario entero. |
| 7 | Efectos como datos | Un item no ejecuta código: declara qué efectos aplica. |
| 8 | Resource vs JSON | Editor cómodo frente a contenido que se puede parchear y modear. |
| 9 | Validación del catálogo | Un catálogo es contenido: como el código, necesita su CI. |

## 📖 Definiciones y características

- **ItemDefinition**: dato inmutable y compartido que describe una clase de objeto (todas las «Poción menor» son la misma definición). Clave: existe una sola en memoria para miles de objetos.
- **ItemStack (instancia)**: pareja de `id` + `cantidad` (más estado propio si lo hay) que representa objetos concretos en un inventario. Clave: es lo único que se guarda en el save.
- **ID estable**: identificador textual corto e inmutable (`pocion_menor`) que nunca cambia una vez publicado. Clave: es la clave de todos los guardados y referencias cruzadas.
- **Type Object (patrón)**: patrón que mueve a datos lo que si no serían subclases. Clave: añadir un objeto nuevo no requiere una clase nueva.
- **Rareza**: categoría de escasez (común, raro, épico…) que afecta a loot, precio y presentación. Clave: es un dato del catálogo, no una decisión de la UI.
- **Tag**: etiqueta libre asociada a un item (`arma`, `metal`, `consumible`). Clave: permite consultas que no se previeron al diseñar el esquema.
- **Stack máximo (`max_stack`)**: cuántas unidades caben en una misma ranura. Clave: `1` significa "no apilable" y simplifica el inventario entero.
- **Catálogo (base de datos de items)**: colección completa de definiciones indexada por id. Clave: se carga una vez al arrancar y es de solo lectura.
- **Esquema**: descripción formal de qué campos existen, de qué tipo y con qué restricciones. Clave: convierte un error de contenido en un error de validación.
- **Validación de contenido**: comprobación automática de que el catálogo es coherente antes de ejecutar el juego. Clave: los datos rotos deben fallar en CI, no en la partida del jugador.
- **Referencia rota**: campo que apunta a un id, escena o textura que no existe. Clave: es el fallo más común al editar contenido a mano.
- **Recurso personalizado (`Resource`)**: objeto de datos de Godot editable en el inspector y serializable a `.tres`. Clave: cómodo para el equipo, pero atado al motor.
- **Contenido data-driven**: contenido que vive en archivos y no en código. Clave: permite parches y mods sin recompilar.
- **Icono / metadata de presentación**: ruta al arte y textos de la definición. Clave: van en la definición, pero la presentación es la única que los usa.
- **Efecto declarativo**: descripción de un efecto (`{"tipo": "curar", "valor": 25}`) que otro sistema interpreta. Clave: mantiene el catálogo libre de lógica.

## 🧰 Herramientas y preparación

Godot 4.x y un editor de texto. Trabajaremos en `res://datos/` (el catálogo) y `res://dominio/items/` (el código). Documentación de apoyo: [Resources](https://docs.godotengine.org/en/4.3/tutorials/scripting/resources.html), [`@export`](https://docs.godotengine.org/en/4.3/tutorials/scripting/gdscript/gdscript_exports.html), [`ResourceLoader`](https://docs.godotengine.org/en/4.3/classes/class_resourceloader.html) y [`JSON`](https://docs.godotengine.org/en/4.3/classes/class_json.html). Si vienes de la [clase 260](../../parte-15-herramientas-editores-y-automatizacion/260-recursos-personalizados-y-bases-de-datos-de-juego/README.md) esto es su continuación natural: allí se aprendió el mecanismo, aquí se construye el sistema completo con validación.

## 🧪 Laboratorio guiado

1. **Las enumeraciones de dominio.** Antes que nada, cierra el vocabulario. Una cadena `"arma"` escrita a mano en 40 sitios acabará escrita `"Arma"` en el sitio 41:

```gdscript
class_name Item
extends RefCounted

enum Tipo { CONSUMIBLE, ARMA, ARMADURA, MATERIAL, CLAVE, MISCELANEA }
enum Rareza { COMUN, POCO_COMUN, RARO, EPICO, LEGENDARIO }

# Multiplicadores de precio por rareza: dato de balance, en un solo sitio.
const PESO_RAREZA := {
	Rareza.COMUN: 1.0, Rareza.POCO_COMUN: 2.0, Rareza.RARO: 5.0,
	Rareza.EPICO: 12.0, Rareza.LEGENDARIO: 40.0,
}
```

2. **La definición.** Un `Resource` con todo lo que describe una clase de objeto — y nada de estado de partida:

```gdscript
class_name ItemDefinition
extends Resource

@export var id: StringName = &""              # clave estable; NUNCA se cambia
@export var nombre: String = ""               # texto visible (se localiza aparte)
@export_multiline var descripcion: String = ""
@export var tipo: Item.Tipo = Item.Tipo.MISCELANEA
@export var rareza: Item.Rareza = Item.Rareza.COMUN
@export_range(1, 999) var max_stack: int = 1
@export var valor: int = 0                    # precio base en la moneda principal
@export var tags: PackedStringArray = []
@export var icono: String = ""                # ruta res:// (String, no Texture2D: ver FAQ)
@export var efectos: Array[Dictionary] = []   # [{"tipo": "curar", "valor": 25}]
@export var metadata: Dictionary = {}         # extensible sin tocar el esquema

func apilable() -> bool:
	return max_stack > 1

func tiene_tag(t: String) -> bool:
	return tags.has(t)

func precio_venta() -> int:
	# Vender da la mitad: un sink de economía, no un descuido (clase 303).
	return int(valor * 0.5)
```

3. **El catálogo en JSON.** Es el formato que usaremos como fuente de verdad porque se puede parchear, diffear en git y cargar desde un mod (clase 309). `res://datos/items.json`:

```json
{
  "version": 1,
  "items": [
    {
      "id": "pocion_menor",
      "nombre": "Poción menor",
      "descripcion": "Restaura 25 puntos de vida.",
      "tipo": "CONSUMIBLE",
      "rareza": "COMUN",
      "max_stack": 20,
      "valor": 15,
      "tags": ["consumible", "curacion"],
      "icono": "res://arte/items/pocion_menor.png",
      "efectos": [{ "tipo": "curar", "valor": 25 }]
    },
    {
      "id": "espada_hierro",
      "nombre": "Espada de hierro",
      "descripcion": "Fiable y pesada.",
      "tipo": "ARMA",
      "rareza": "COMUN",
      "max_stack": 1,
      "valor": 80,
      "tags": ["arma", "metal", "filo"],
      "icono": "res://arte/items/espada_hierro.png",
      "efectos": [{ "tipo": "modificador", "stat": "ataque", "modo": "plano", "valor": 7 }]
    }
  ]
}
```

4. **La base de datos.** Carga, indexa y —esto es lo importante— **falla con nombre** cuando alguien pide un id que no existe:

```gdscript
class_name BaseDeItems
extends RefCounted

var _por_id := {}                     # StringName -> ItemDefinition

func cargar_desde_json(ruta: String) -> Array[String]:
	var errores: Array[String] = []
	if not FileAccess.file_exists(ruta):
		return ["no existe el catálogo: " + ruta]
	var texto := FileAccess.open(ruta, FileAccess.READ).get_as_text()
	var datos = JSON.parse_string(texto)
	if typeof(datos) != TYPE_DICTIONARY or not datos.has("items"):
		return ["el catálogo no es un objeto con clave 'items': " + ruta]

	for bruto in datos["items"]:
		var def := _desde_diccionario(bruto, errores)
		if def == null:
			continue
		if _por_id.has(def.id):
			errores.append("id duplicado: %s" % def.id)
			continue
		_por_id[def.id] = def
	return errores

func obtener(id: StringName) -> ItemDefinition:
	# Devolver null aquí produce un crash tres sistemas más allá, sin pista de
	# quién lo pidió. Preferimos morir aquí y con el id en el mensaje.
	assert(_por_id.has(id), "item desconocido: %s" % id)
	return _por_id.get(id)

func existe(id: StringName) -> bool:
	return _por_id.has(id)

func todos() -> Array:
	return _por_id.values()

func con_tag(tag: String) -> Array:
	return _por_id.values().filter(func(d): return d.tiene_tag(tag))

func _desde_diccionario(b: Dictionary, errores: Array[String]) -> ItemDefinition:
	var id := StringName(str(b.get("id", "")))
	if id == &"":
		errores.append("item sin id: %s" % JSON.stringify(b))
		return null
	var d := ItemDefinition.new()
	d.id = id
	d.nombre = str(b.get("nombre", ""))
	d.descripcion = str(b.get("descripcion", ""))
	d.tipo = Item.Tipo.get(str(b.get("tipo", "MISCELANEA")), Item.Tipo.MISCELANEA)
	d.rareza = Item.Rareza.get(str(b.get("rareza", "COMUN")), Item.Rareza.COMUN)
	d.max_stack = int(b.get("max_stack", 1))
	d.valor = int(b.get("valor", 0))
	d.tags = PackedStringArray(b.get("tags", []))
	d.icono = str(b.get("icono", ""))
	d.efectos = b.get("efectos", []) as Array[Dictionary]
	d.metadata = b.get("metadata", {})
	return d
```

5. **El validador.** Esto es lo que separa un catálogo de un montón de JSON. Cada regla que compruebes aquí es un bug que nunca llegará a una partida:

```gdscript
class_name ValidadorDeItems
extends RefCounted

const TIPOS_EFECTO := ["curar", "dano", "modificador", "estado"]

static func validar(base: BaseDeItems) -> Array[String]:
	var errores: Array[String] = []
	for d in base.todos():
		var donde := "item '%s'" % d.id

		if not str(d.id).is_valid_identifier():
			errores.append("%s: el id debe ser snake_case sin espacios" % donde)
		if d.nombre.strip_edges() == "":
			errores.append("%s: falta el nombre visible" % donde)
		if d.max_stack < 1:
			errores.append("%s: max_stack debe ser >= 1" % donde)
		if d.tipo == Item.Tipo.ARMA and d.max_stack != 1:
			errores.append("%s: las armas no se apilan (max_stack debe ser 1)" % donde)
		if d.valor < 0:
			errores.append("%s: el valor no puede ser negativo" % donde)
		if d.icono != "" and not ResourceLoader.exists(d.icono):
			errores.append("%s: icono inexistente '%s'" % [donde, d.icono])

		for e in d.efectos:
			var t := str(e.get("tipo", ""))
			if not TIPOS_EFECTO.has(t):
				errores.append("%s: tipo de efecto desconocido '%s'" % [donde, t])
			if t in ["curar", "dano"] and int(e.get("valor", 0)) <= 0:
				errores.append("%s: el efecto '%s' necesita un valor positivo" % [donde, t])
	return errores
```

6. **Ejecutarlo sin abrir el juego.** El validador es un script headless: eso es lo que permite meterlo en CI.

```gdscript
extends SceneTree   # godot --headless --script res://herramientas/validar_items.gd

func _init() -> void:
	var base := BaseDeItems.new()
	var errores := base.cargar_desde_json("res://datos/items.json")
	errores.append_array(ValidadorDeItems.validar(base))
	for e in errores:
		printerr("  - ", e)
	print("== catálogo: %d items, %d error(es) ==" % [base.todos().size(), errores.size()])
	quit(1 if errores.size() > 0 else 0)
```

7. **La instancia.** Y ahora la otra mitad: lo que de verdad se guarda. Fíjate en lo poco que es:

```gdscript
class_name ItemStack
extends RefCounted

var id: StringName
var cantidad: int

func _init(id_: StringName, cantidad_: int = 1) -> void:
	id = id_
	cantidad = max(0, cantidad_)

func a_dict() -> Dictionary:
	return {"id": String(id), "cantidad": cantidad}

static func de_dict(d: Dictionary) -> ItemStack:
	return ItemStack.new(StringName(str(d.get("id", ""))), int(d.get("cantidad", 0)))
```

Un guardado no contiene nombres, iconos ni descripciones: contiene `{"id": "pocion_menor", "cantidad": 3}`. Por eso puedes renombrar «Poción menor» a «Poción curativa» en un parche sin tocar un solo save — y por eso **el id no se cambia jamás**.

8. **Comprobación final.** Añade a mano un item con `"max_stack": 0` y otro con un id repetido, ejecuta el validador y verifica que los detecta **los dos** e informa de la línea conceptual. Después arréglalos y confirma que sale `0 error(es)`.

## ✍️ Ejercicios

1. Añade el campo `peso: float` y una regla de validación que impida pesos negativos.
2. Implementa `BaseDeItems.buscar(texto)` que filtre por nombre sin distinguir mayúsculas ni acentos.
3. Añade un tipo `MONEDA` y una regla que exija `max_stack >= 999` para ese tipo.
4. Escribe una función que exporte el catálogo a CSV para que diseño lo revise en una hoja de cálculo.
5. Haz que el validador avise (aviso, no error) de items cuyo `valor` se aparte más de un 300 % de la media de su rareza.
6. Convierte el catálogo JSON en `.tres` con un script y compara ambos flujos: cuál prefieres para editar y cuál para parchear.
7. Añade un campo `nivel_requerido` y valida que ningún item de rareza COMUN lo tenga por encima de 5.

## 📝 Reto verificable

Construye un catálogo con **al menos 20 items** que cubra los seis tipos y las cinco rarezas, cárgalo con `BaseDeItems` y valida con `ValidadorDeItems` incluyendo **como mínimo 8 reglas** distintas (id, nombre, stack, valor, icono, tipos de efecto, coherencia arma/stack y una regla propia).

**Criterio de aceptación**: (a) `godot --headless --script res://herramientas/validar_items.gd` imprime `== catálogo: 20 items, 0 error(es) ==` y devuelve código de salida 0; (b) al introducir a propósito un id duplicado, un `max_stack` de 0 y un icono inexistente, el mismo comando devuelve código 1 y lista **exactamente esos tres** errores con el id del item afectado; (c) `obtener()` con un id inexistente falla con un mensaje que incluye el id pedido.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Al cargar un save viejo los objetos "desaparecen" | Se renombró un id. Los ids son inmutables; para renombrar, añade un alias en la migración (clase 307). |
| Dos jugadores modifican el mismo item y se afectan entre sí | Se está mutando la `ItemDefinition` compartida. La definición es de solo lectura; el estado va en la instancia. |
| "Invalid access to property 'nombre' on a base object of type 'Nil'" | `obtener()` devolvió `null` por un id mal escrito. Usa el `assert` con el id en el mensaje para localizarlo. |
| El catálogo se recarga en cada uso y el juego va a tirones | Se está llamando a `cargar_desde_json` dentro de un bucle. Cárgalo una vez en el arranque y guárdalo en el servicio. |
| Los iconos no aparecen en la build exportada | Rutas a archivos no incluidos en el export, o `.png` sin `.import`. Valida `ResourceLoader.exists` y revisa los filtros de exportación. |
| Un item nuevo rompe el loot sin dar error | La tabla de loot referencia un id que ya no existe. Amplía el validador para comprobar referencias cruzadas (clase 300). |
| El enum se guarda como número y al reordenarlo todo cambia | Se serializó el valor del enum. Guarda siempre el **nombre** (`"ARMA"`), nunca su índice. |

## ❓ Preguntas frecuentes

**❓ ¿`Resource` o JSON?** `Resource` gana en comodidad de edición (inspector, arrastrar texturas, autocompletado). JSON gana en todo lo demás: diffs legibles, parches, mods, generación por script y validación fuera del editor. Un patrón habitual y sensato es **JSON como fuente de verdad** y un importador que genere `.tres` para la edición cómoda.

**❓ ¿Por qué el icono es `String` y no `Texture2D`?** Porque una definición cargada desde un mod o desde JSON puede referirse a un archivo que aún no existe, y porque cargar 500 texturas al arrancar solo para tener el catálogo es un desperdicio. La presentación carga el icono cuando lo necesita (streaming, [clase 343](../../parte-21-arquitectura-avanzada-de-motores-y-rendering/343-resource-management-y-streaming-asincrono/README.md)).

**❓ ¿Los efectos no deberían ser código?** No en la definición. Si el item ejecutara código, un mod podría ejecutar cualquier cosa y el catálogo dejaría de ser dato. El item **declara** `{"tipo": "curar", "valor": 25}` y un sistema conocido lo interpreta — es la base de la seguridad de mods de la [clase 309](../309-modding-y-arquitectura-extensible/README.md).

**❓ ¿Cuántos campos meto de entrada?** Los que ves en la tabla de arriba. Son los que aparecen en prácticamente todos los juegos con inventario, y añadirlos después obliga a migrar guardados. Para lo verdaderamente específico está `metadata`.

**❓ ¿Y las traducciones del nombre?** El catálogo guarda una **clave** o el texto en el idioma base, y la capa de localización (Parte 10) lo traduce en presentación. No metas 12 idiomas en el catálogo.

## 🔗 Referencias

- Robert Nystrom — *Game Programming Patterns*, Type Object: <https://gameprogrammingpatterns.com/type-object.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — Resources: <https://docs.godotengine.org/en/4.3/tutorials/scripting/resources.html> · uso: se instala o se consulta en la preparación
- Godot Docs — GDScript exports: <https://docs.godotengine.org/en/4.3/tutorials/scripting/gdscript/gdscript_exports.html> · uso: se instala o se consulta en la preparación
- Godot Docs — `JSON`: <https://docs.godotengine.org/en/4.3/classes/class_json.html> · uso: se instala o se consulta en la preparación
- Godot Docs — `ResourceLoader`: <https://docs.godotengine.org/en/4.3/classes/class_resourceloader.html> · uso: se instala o se consulta en la preparación
- JSON Schema — especificación de esquemas de datos: <https://json-schema.org/> · uso: respalda el Tema 7 «Efectos como datos»

## ⬅️ Clase anterior

[Clase 293 - Arquitectura de gameplay a escala](../293-arquitectura-de-gameplay-a-escala/README.md)

## ➡️ Siguiente clase

[Clase 295 - Sistema de inventario](../295-sistema-de-inventario/README.md)
