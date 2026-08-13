# Clase 309 — Modding y arquitectura extensible

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Documentación de sistemas de plugins y `ResourcePack` de Godot 4 · Charlas de GDC sobre soporte a mods y comunidades*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Diseñar una arquitectura donde **otros puedan extender tu juego sin recompilarlo**. Un juego moddeable vive más años, tiene comunidad y recibe contenido que tú no habrías hecho nunca. Pero también abre una superficie que hay que tratar con cuidado: un mod es código y datos de terceros que se ejecutan en el ordenador de tus jugadores.

Aquí vas a separar **motor / juego / contenido**, diseñar un formato de mod con manifiesto y versión de API, implementar carga de packs de contenido con `ResourcePack`, resolver conflictos entre mods, y —lo más importante— establecer una política de permisos y sandboxing **explícita y honesta**: qué puede hacer un mod, qué no, qué se le pide al usuario y qué se le dice claramente. No vamos a fingir que un sandbox de GDScript es seguridad real; vamos a diseñar sabiendo dónde está el límite.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Separar motor, juego y contenido, y explicar qué capa expone la API de mods.
2. Diseñar un **manifiesto de mod** con id, versión, dependencias y versión de API requerida.
3. Implementar carga de mods de datos (JSON) y de contenido (`ResourcePack`).
4. Resolver conflictos y orden de carga entre mods de forma determinista.
5. Versionar la API de mods y aplicar una política de compatibilidad.
6. Enumerar honestamente los límites del sandboxing en GDScript y diseñar en consecuencia.
7. Definir permisos, avisos al usuario y aislamiento de fallos de un mod.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Motor / juego / contenido | Sin esta separación no hay nada que moddear. |
| 2 | Mods de datos vs de código | Riesgo, potencia y validación completamente distintos. |
| 3 | Manifiesto | Es el contrato entre el mod y el juego. |
| 4 | Versión de API | Permite evolucionar el juego sin romper todos los mods. |
| 5 | Orden de carga | Dos mods que tocan lo mismo necesitan una regla determinista. |
| 6 | Fusión y parches de datos | Sustituir todo el catálogo es peor que parchear una entrada. |
| 7 | Dependencias entre mods | Un mod puede necesitar otro; hay que resolver el grafo. |
| 8 | Sandboxing y sus límites | Prometer seguridad que no tienes es peor que no prometer nada. |
| 9 | Permisos y consentimiento | El usuario debe saber qué está instalando. |
| 10 | Aislamiento de fallos | Un mod roto no puede tumbar el juego ni corromper el save. |

## 📖 Definiciones y características

- **Mod**: paquete externo que añade o modifica contenido del juego. Clave: se instala sin tocar el ejecutable.
- **Mod de datos**: solo aporta archivos de datos (items, recetas, diálogos). Clave: validable con los mismos validadores del juego, y sin ejecución de código.
- **Mod de contenido**: aporta también assets (texturas, sonidos, escenas). Clave: se distribuye en un `.pck` y se monta en el sistema de archivos virtual.
- **Mod de código (script mod)**: aporta scripts que se ejecutan. Clave: máxima potencia y máximo riesgo; exige consentimiento explícito.
- **Manifiesto (`mod.json`)**: archivo con id, nombre, versión, autor, dependencias y `api_version`. Clave: si falta o no valida, el mod no se carga.
- **Versión de API**: número que identifica el contrato que el juego ofrece a los mods. Clave: permite decir "este mod es de la API 2 y ya vamos por la 4".
- **Compatibilidad semántica**: política por la que cambios menores no rompen mods y los mayores sí. Clave: hay que publicarla y respetarla.
- **`ResourcePack`**: paquete `.pck` que Godot monta sobre `res://` en tiempo de ejecución. Clave: es el mecanismo nativo de contenido añadido.
- **Orden de carga (load order)**: secuencia en que se aplican los mods. Clave: determina quién gana en un conflicto, y debe ser visible y editable.
- **Conflicto**: dos mods modifican la misma entrada. Clave: detectarlo y avisar es mejor que resolverlo en silencio.
- **Parche de datos**: modificación puntual de una entrada existente (`"pocion_menor.valor": 20`). Clave: mucho más compatible que sustituir el archivo entero.
- **Dependencia**: mod requerido por otro. Clave: hay que ordenar topológicamente y detectar ciclos.
- **Sandbox**: entorno de ejecución restringido para código no confiable. Clave: en GDScript **no existe** un sandbox real; conviene decirlo.
- **Permiso**: capacidad concreta que un mod declara necesitar (leer archivos, red). Clave: sirve para informar al usuario, no para impedir nada por sí solo.
- **Aislamiento de fallos**: capturar los errores de un mod para que no tumben el juego. Clave: se consigue con validación previa y desactivación automática.
- **Contenido firmado**: paquete con firma verificable del autor. Clave: es la única defensa técnica seria, y depende de una plataforma que la gestione.

## 🧰 Herramientas y preparación

Necesitas los catálogos y validadores de las clases 294, 300, 301, 304 y 305. Trabajaremos en `res://infraestructura/mods/` y los mods en `user://mods/`. Documentación: [`ProjectSettings.load_resource_pack`](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html), [exportación de PCK](https://docs.godotengine.org/en/stable/tutorials/export/exporting_pcks.html) y [`DirAccess`](https://docs.godotengine.org/en/stable/classes/class_diraccess.html).

La [clase 265](../../parte-15-herramientas-editores-y-automatizacion/265-editores-de-niveles-y-contenido-in-game/README.md) construyó un editor de contenido in-game: es la puerta natural para que la comunidad **cree** mods, y esta clase es la que los **carga**.

## 🧪 Laboratorio guiado

1. **Las tres capas.** Sin esto, no hay nada que moddear:

```text
motor/        Godot. No lo tocas ni lo expones.
juego/        Sistemas: inventario, combate, quests. La API de mods vive aquí.
contenido/    items.json, recetas.json, diálogos, assets. Lo que un mod aporta.
```

El juego base debe cargar **su propio contenido por el mismo camino que el de un mod**. Si el contenido oficial se carga con un atajo, el sistema de mods estará siempre a medio probar.

2. **El manifiesto:**

```json
{
  "id": "mas_armas",
  "nombre": "Más armas",
  "version": "1.2.0",
  "autor": "Comunidad",
  "descripcion": "Añade 30 armas nuevas y sus recetas.",
  "api_version": 2,
  "prioridad": 100,
  "dependencias": [{ "id": "biblioteca_materiales", "min": "1.0.0" }],
  "contenido": {
    "packs": ["assets.pck"],
    "datos": ["items.json", "recetas.json"],
    "parches": ["parches.json"]
  },
  "permisos": ["datos"],
  "scripts": []
}
```

3. **El cargador.** Descubrir, validar, ordenar y aplicar:

```gdscript
class_name GestorDeMods
extends RefCounted

const API_VERSION := 2
const API_MINIMA_SOPORTADA := 1
const DIR_MODS := "user://mods"

signal mod_cargado(id: StringName, version: String)
signal mod_rechazado(id: StringName, motivo: String)
signal conflicto(clave: String, ganador: StringName, perdedor: StringName)

var _mods := {}                  # id -> manifiesto
var _orden: Array[StringName] = []
var _origen := {}                # "items/pocion_menor" -> id del mod que la puso

func descubrir() -> void:
	DirAccess.make_dir_recursive_absolute(DIR_MODS)
	for carpeta in DirAccess.get_directories_at(DIR_MODS):
		var ruta := "%s/%s/mod.json" % [DIR_MODS, carpeta]
		if not FileAccess.file_exists(ruta):
			mod_rechazado.emit(StringName(carpeta), "falta mod.json")
			continue
		var m = JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())
		if typeof(m) != TYPE_DICTIONARY:
			mod_rechazado.emit(StringName(carpeta), "mod.json ilegible")
			continue
		var motivo := _validar_manifiesto(m, carpeta)
		if motivo != "":
			mod_rechazado.emit(StringName(str(m.get("id", carpeta))), motivo)
			continue
		m["_carpeta"] = "%s/%s" % [DIR_MODS, carpeta]
		_mods[StringName(str(m["id"]))] = m

func _validar_manifiesto(m: Dictionary, carpeta: String) -> String:
	for campo in ["id", "nombre", "version", "api_version"]:
		if not m.has(campo):
			return "falta el campo obligatorio '%s'" % campo
	if not str(m["id"]).is_valid_identifier():
		return "el id debe ser snake_case sin espacios"
	var api := int(m["api_version"])
	if api > API_VERSION:
		return "requiere la API %d y el juego ofrece la %d (actualiza el juego)" % [api, API_VERSION]
	if api < API_MINIMA_SOPORTADA:
		return "usa la API %d, ya no soportada (mínima: %d)" % [api, API_MINIMA_SOPORTADA]
	if _mods.has(StringName(str(m["id"]))):
		return "id duplicado con otro mod instalado"
	return ""
```

4. **Dependencias y orden de carga.** Orden topológico, con desempate estable:

```gdscript
func resolver_orden() -> Array[String]:
	var errores: Array[String] = []
	var visitando := {}
	var listo := {}
	_orden.clear()

	var visitar := func(id: StringName, self_ref: Callable) -> void:
		if listo.has(id):
			return
		if visitando.has(id):
			errores.append("ciclo de dependencias en '%s'" % id)
			return
		visitando[id] = true
		for dep in _mods[id].get("dependencias", []):
			var did := StringName(str(dep["id"]))
			if not _mods.has(did):
				errores.append("'%s' necesita '%s', que no está instalado" % [id, did])
				continue
			if _comparar_version(str(_mods[did]["version"]), str(dep.get("min", "0.0.0"))) < 0:
				errores.append("'%s' necesita '%s' >= %s (hay %s)"
					% [id, did, dep.get("min", "0.0.0"), _mods[did]["version"]])
			self_ref.call(did, self_ref)
		visitando.erase(id)
		listo[id] = true
		_orden.append(id)

	# Desempate por prioridad y luego por id: el orden debe ser el MISMO en
	# todas las máquinas, o dos jugadores con los mismos mods verán cosas
	# distintas y no habrá forma de reproducir el bug.
	var ids := _mods.keys()
	ids.sort_custom(func(a, b):
		var pa := int(_mods[a].get("prioridad", 100))
		var pb := int(_mods[b].get("prioridad", 100))
		return String(a) < String(b) if pa == pb else pa < pb)
	for id in ids:
		visitar.call(id, visitar)
	return errores

static func _comparar_version(a: String, b: String) -> int:
	var pa := a.split("."); var pb := b.split(".")
	for i in 3:
		var x := int(pa[i]) if i < pa.size() else 0
		var y := int(pb[i]) if i < pb.size() else 0
		if x != y:
			return -1 if x < y else 1
	return 0
```

5. **Aplicar el contenido.** Packs primero, datos después, parches al final:

```gdscript
func aplicar(base: BaseDeItems) -> Array[String]:
	var errores: Array[String] = []
	for id in _orden:
		var m: Dictionary = _mods[id]
		var carpeta := str(m["_carpeta"])

		# 1) Assets: se montan sobre res:// y quedan disponibles como cualquier otro.
		for pack in m.get("contenido", {}).get("packs", []):
			var ruta := "%s/%s" % [carpeta, pack]
			if not ProjectSettings.load_resource_pack(ruta, true):
				errores.append("'%s': no se pudo montar el pack '%s'" % [id, pack])

		# 2) Datos nuevos: pasan por el MISMO cargador y el MISMO validador que
		#    el contenido oficial. Sin excepciones.
		for archivo in m.get("contenido", {}).get("datos", []):
			var previos := base.todos().size()
			var errs := base.cargar_desde_json("%s/%s" % [carpeta, archivo])
			for e in errs:
				errores.append("'%s'/%s: %s" % [id, archivo, e])
			_registrar_origen(id, base, previos)

		# 3) Parches: modifican entradas existentes sin sustituir el archivo.
		for archivo in m.get("contenido", {}).get("parches", []):
			errores.append_array(_aplicar_parches(id, base, "%s/%s" % [carpeta, archivo]))

		mod_cargado.emit(id, str(m["version"]))
	errores.append_array(ValidadorDeItems.validar(base))   # validación FINAL, con todo dentro
	return errores

func _aplicar_parches(id: StringName, base: BaseDeItems, ruta: String) -> Array[String]:
	var errores: Array[String] = []
	if not FileAccess.file_exists(ruta):
		return ["'%s': parche inexistente %s" % [id, ruta]]
	var d = JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())
	for clave in d.get("items", {}):
		var iid := StringName(str(clave))
		if not base.existe(iid):
			errores.append("'%s': parche a item inexistente '%s'" % [id, iid])
			continue
		var anterior: StringName = _origen.get("items/%s" % iid, &"base")
		if anterior != &"base" and anterior != id:
			conflicto.emit("items/%s" % iid, id, anterior)   # se avisa, no se oculta
		var def := base.obtener(iid)
		for campo in d["items"][clave]:
			# Lista BLANCA de campos parcheables: un parche no puede cambiar el id
			# ni inyectar propiedades arbitrarias.
			if campo in ["nombre", "descripcion", "valor", "max_stack", "rareza", "tags"]:
				def.set(campo, d["items"][clave][campo])
			else:
				errores.append("'%s': campo no parcheable '%s'" % [id, campo])
		_origen["items/%s" % iid] = id
	return errores

func _registrar_origen(id: StringName, base: BaseDeItems, desde: int) -> void:
	var todos := base.todos()
	for i in range(desde, todos.size()):
		_origen["items/%s" % todos[i].id] = id
```

6. **Los límites del sandboxing, dichos sin rodeos.** GDScript **no tiene** un modo restringido: un script de mod puede abrir archivos, hacer peticiones de red y llamar a `OS.execute`. Lo que sí puedes hacer, y debes:

```gdscript
func puede_cargar_scripts(m: Dictionary) -> bool:
	var scripts: Array = m.get("scripts", [])
	if scripts.is_empty():
		return true
	# Un mod con scripts NO se carga sin consentimiento explícito y por mod.
	# El aviso es literal, no un eufemismo: el usuario debe entender el riesgo.
	return _consentimientos.get(StringName(str(m["id"])), false)

const AVISO := """Este mod incluye código que se ejecutará con los mismos
permisos que el juego: puede leer y escribir archivos de tu equipo y acceder a
la red. Instálalo solo si confías en su autor.

Mod: %s (%s) — autor: %s"""
```

Las cuatro defensas que **sí** funcionan, por orden de eficacia:

1. **Preferir mods de datos.** Si tu arquitectura es suficientemente data-driven (que es de lo que ha ido toda esta parte), la mayoría de mods no necesitarán código.
2. **Distribuir por una plataforma con moderación** (Steam Workshop, mod.io), que aporta identidad de autor, denuncias y retirada.
3. **Consentimiento informado por mod**, con el texto de arriba, no enterrado en un ajuste global.
4. **Aislamiento de fallos**: validar antes de aplicar y desactivar automáticamente el mod que falle.

```gdscript
func cargar_con_aislamiento(id: StringName, base: BaseDeItems) -> bool:
	# Trabajamos sobre una COPIA: si el mod deja el catálogo inconsistente, el
	# juego se queda con el bueno y el mod se desactiva.
	var copia := BaseDeItems.new()
	copia.cargar_desde_json("res://datos/items.json")
	var errores := _aplicar_uno(id, copia)
	if not errores.is_empty():
		_desactivados[id] = errores
		mod_rechazado.emit(id, "contenido inválido: %s" % errores[0])
		return false
	return true
```

7. **Y el save.** Un mod que añade items deja rastro en la partida:

```gdscript
# En el save, junto a los datos, se guarda qué mods había activos.
func firma_de_mods() -> Array:
	return _orden.map(func(id): return {"id": String(id), "version": str(_mods[id]["version"])})
```

Al cargar una partida con mods que ya no están, el filtro `_base.existe()` de la [clase 295](../295-sistema-de-inventario/README.md) descarta los items desconocidos — pero el jugador **debe saberlo**. Avisa con la lista de mods que faltan antes de cargar, no después de que hayan desaparecido sus cosas.

8. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	var g := GestorDeMods.new()
	var rechazos := []
	g.mod_rechazado.connect(func(id, motivo): rechazos.append([id, motivo]))
	g.descubrir()

	var errores := g.resolver_orden()
	assert(errores.is_empty(), "el orden de mods no resuelve: %s" % str(errores))

	# Determinismo del orden: dos resoluciones dan la misma lista.
	var primera := g._orden.duplicate()
	g.resolver_orden()
	assert(primera == g._orden, "el orden de carga no es determinista")

	var base := BaseDeItems.new()
	base.cargar_desde_json("res://datos/items.json")
	var errs := g.aplicar(base)
	assert(errs.is_empty(), "el contenido de los mods no valida: %s" % str(errs))

	print("== %d mods cargados, %d rechazados ==" % [g._orden.size(), rechazos.size()])
	quit()
```

## ✍️ Ejercicios

1. Implementa una pantalla de gestión de mods con orden editable por arrastre, guardado en `user://`.
2. Añade parches para recetas y diálogos con su propia lista blanca de campos.
3. Detecta y muestra todos los conflictos antes de cargar, no durante.
4. Implementa desactivación automática del mod que provoque un error al validar y muéstralo en la UI.
5. Añade `api_version` a un cambio real de tu juego y escribe la nota de compatibilidad.
6. Genera un `.pck` de ejemplo con `godot --export-pack` y móntalo en runtime.
7. Añade a la pantalla de carga de partida el aviso de mods faltantes con la lista de items que se perderán.

## 📝 Reto verificable

Implementa el gestor de mods con manifiesto, validación, versión de API, dependencias con orden topológico determinista, carga de datos y packs, parches con lista blanca, detección de conflictos, aislamiento de fallos y consentimiento explícito para mods con scripts. Prepara **tres mods de ejemplo**: uno de datos, uno con dependencia del anterior y uno inválido.

**Criterio de aceptación**: una prueba headless con **al menos 15 aserciones** demuestra que: (a) el mod inválido se rechaza con un motivo concreto y **los otros dos se cargan igualmente**; (b) el orden de carga es idéntico en dos resoluciones consecutivas y respeta las dependencias; (c) un mod que declara `api_version` mayor que la del juego se rechaza con un mensaje que menciona ambas versiones; (d) un ciclo de dependencias se detecta y no cuelga; (e) un parche a un campo fuera de la lista blanca produce error y no modifica nada; (f) un mod cuyo contenido no valida queda desactivado y el catálogo del juego sigue siendo el original; (g) un mod con `scripts` no vacío no se carga sin consentimiento registrado.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Un mod roto impide arrancar el juego | Se aplica sin validar. Valida sobre una copia y desactiva el que falle. |
| Dos jugadores con los mismos mods ven cosas distintas | El orden de carga no es determinista. Ordena por prioridad y luego por id. |
| Actualizar el juego rompe todos los mods | No hay versión de API. Añádela y publica la política de compatibilidad. |
| Un mod sustituye el catálogo entero y borra items | Se permitió reemplazar archivos. Prefiere parches con lista blanca. |
| Al desinstalar un mod desaparecen objetos del save | Es inevitable, pero debe avisarse. Guarda la firma de mods y compárala al cargar. |
| Un mod con `id` repetido pisa a otro en silencio | Falta la comprobación de duplicados en el manifiesto. |
| El pack de un mod no carga en la build exportada | Ruta relativa o `.pck` con estructura incorrecta. Usa rutas absolutas de `user://` y revisa la exportación. |
| Se prometió "mods seguros" y alguien distribuyó malware | Se vendió un sandbox que no existe. Sé explícito sobre lo que un script puede hacer. |

## ❓ Preguntas frecuentes

**❓ ¿Puedo hacer un sandbox real en Godot?** No con GDScript tal cual: un script cargado tiene acceso a `FileAccess`, `HTTPRequest` y `OS`. Las opciones reales son (a) limitarte a mods de datos, (b) exponer un lenguaje propio muy restringido que tú interpretes —como el intérprete de diálogo de la [clase 304](../304-sistemas-de-dialogo/README.md), que no ejecuta código— o (c) apoyarte en una plataforma con moderación y firma. Lo que no es una opción es llamar "sandbox" a una lista de funciones que has decidido no documentar.

**❓ ¿Entonces no permito mods de código?** Muchos juegos muy exitosos los permiten, y sus comunidades lo agradecen. La diferencia entre hacerlo bien y mal es el **consentimiento informado**: un aviso claro, por mod, que diga exactamente qué puede hacer ese código. Eso es honesto y es lo que se espera de un juego moderno.

**❓ ¿Y si un mod rompe partidas guardadas?** Guarda la firma de mods en el save, avisa al cargar si falta alguno y aplica el filtro de existencia al deserializar. No puedes evitar que un jugador pierda su espada modeada al desinstalar el mod, pero sí que se entere por un mensaje en lugar de por un hueco en el inventario.

**❓ ¿Cómo versiono la API?** Con un entero simple y una regla publicada: añadir un campo opcional o un tipo nuevo no sube la versión; cambiar el significado de algo existente o quitar una capacidad, sí. Mantén al menos una versión anterior soportada (`API_MINIMA_SOPORTADA`) para que la comunidad tenga tiempo de actualizar.

**❓ ¿Merece la pena si mi juego es pequeño?** La separación motor/juego/contenido merece la pena **siempre**, aunque nunca publiques soporte de mods: es la misma arquitectura que te permite parchear contenido, hacer eventos de LiveOps y validar tus datos en CI. El gestor de mods puede venir después; la arquitectura, no.

## 🔗 Referencias

- Godot Docs — Exportar PCK y contenido adicional: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_pcks.html>
- Godot Docs — `ProjectSettings.load_resource_pack`: <https://docs.godotengine.org/en/stable/classes/class_projectsettings.html>
- Godot Docs — Sistema de archivos virtual (`res://`, `user://`): <https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html>
- mod.io — plataforma de distribución de mods multiplataforma: <https://mod.io/>
- Steam Workshop — documentación para desarrolladores: <https://partner.steamgames.com/doc/features/workshop>
- GDC Vault — charlas sobre soporte a mods y comunidades de creadores: <https://www.gdcvault.com/>

## ⬅️ Clase anterior

[Clase 308 - Commands, input recording y replays](../308-commands-input-recording-y-replays/README.md)

## ➡️ Siguiente clase

[Clase 310 - Capstone Parte 18: un juego sistémico](../310-capstone-parte-18-un-juego-sistemico/README.md)
