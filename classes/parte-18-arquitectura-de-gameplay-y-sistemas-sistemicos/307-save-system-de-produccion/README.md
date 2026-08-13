# Clase 307 — Save System de producción

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Gregory, «Game Engine Architecture» · Documentación de `FileAccess` y `DirAccess` de Godot 4*
> ⏱️ Duración estimada: **130 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Convertir el guardado básico de la [clase 043](../../parte-1-motores-2d-y-tu-primer-juego-jugable/043-guardado-y-carga-de-progreso/README.md) —un JSON con cuatro campos— en un **sistema de guardado de producción**: versionado con `SAVE_VERSION`, migraciones entre versiones, escritura atómica, copia de seguridad, validación, ranuras múltiples, autoguardado, checkpoints y recuperación ante corrupción.

Esto no es paranoia. Un save es lo único del juego que **no se puede volver a generar**: si se corrompe la build, el jugador reinstala; si se corrompe su partida de 60 horas, se acabó. Y el fallo más habitual no es un disco roto: es tu propio parche 1.1 añadiendo un campo y dejando de cargar las partidas de la 1.0. Aquí construirás las cinco defensas que evitan las dos cosas, y aprenderás la regla que las resume: **nunca serialices el árbol de escena; serializa el estado de tus sistemas de dominio**.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diseñar un formato de save con `SAVE_VERSION`, metadatos y datos por sistema.
2. Implementar una cadena de **migraciones** que lleve cualquier versión antigua a la actual.
3. Implementar **escritura atómica** (temporal + rename) y explicar qué fallo previene.
4. Implementar copia de seguridad rotativa y recuperación automática ante corrupción.
5. Validar un save (checksum, esquema, rangos) antes de aplicarlo al juego.
6. Implementar ranuras múltiples, autoguardado y checkpoints sin bloquear el juego.
7. Explicar por qué serializar nodos del motor es una trampa y qué hacer en su lugar.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué guardar y qué no | Guardar lo derivado es la primera causa de saves corruptos. |
| 2 | SAVE_VERSION | Sin versión no hay migración posible: solo saves que dejan de cargar. |
| 3 | Migraciones encadenadas | Permite saltar de la v1 a la v7 pasando por todas. |
| 4 | Escritura atómica | Un corte de luz a mitad de escritura no debe dejar el save a medias. |
| 5 | Backup rotativo | La última red antes de perder la partida. |
| 6 | Checksum y validación | Detecta corrupción y manipulación grosera. |
| 7 | Ranuras y metadatos | El menú necesita mostrar nivel y hora sin cargar la partida entera. |
| 8 | Autoguardado | Debe ser barato, frecuente y no producir tirones. |
| 9 | Checkpoints | Save de partida distinto del save de progreso. |
| 10 | Cloud-ready | Un save preparado para la nube desde el día uno cuesta lo mismo. |

## 📖 Definiciones y características

- **Save (partida guardada)**: instantánea del estado necesario para reanudar el juego. Clave: contiene fuentes, nunca valores derivados.
- **`SAVE_VERSION`**: entero que identifica el formato del archivo. Clave: se incrementa en cuanto cambia la estructura, sin excepciones.
- **Migración**: función que transforma un save de la versión N a la N+1. Clave: encadenadas permiten cargar cualquier versión antigua.
- **Escritura atómica**: escribir en un temporal y renombrar al final. Clave: el renombrado es la operación que el sistema de archivos garantiza indivisible.
- **Backup rotativo**: copias de los últimos N guardados. Clave: barata y la única defensa cuando la corrupción viene del propio juego.
- **Checksum**: hash del contenido guardado junto al archivo. Clave: detecta corrupción y ediciones torpes; no es seguridad.
- **Validación de esquema**: comprobación de que las claves y tipos esperados están presentes. Clave: convierte un crash en un mensaje.
- **Ranura (slot)**: espacio de guardado independiente con su propio archivo. Clave: cada una lleva sus metadatos.
- **Metadatos de ranura**: resumen (nivel, zona, tiempo jugado, fecha, captura). Clave: se leen sin cargar la partida entera.
- **Autoguardado**: guardado automático periódico o por evento. Clave: debe escribir en su propia ranura, nunca sobre la del jugador.
- **Checkpoint**: punto de reanudación dentro de una sesión. Clave: puede ser en memoria y no tocar disco.
- **Serialización del árbol de escena**: guardar nodos del motor con `PackedScene` o similar. Clave: rompe entre versiones del juego y del motor; evítalo para partidas.
- **Estado de dominio**: los diccionarios que producen `a_dict()` de tus sistemas. Clave: es lo que sí se guarda.
- **Corrupción**: archivo ilegible, incompleto o incoherente. Clave: hay que asumir que ocurrirá y tener plan.
- **Cloud-ready**: formato con timestamp, id de dispositivo y versión, listo para resolver conflictos. Clave: añadirlo después obliga a migrar todo.
- **Guardado asíncrono**: serializar en el hilo principal y escribir en otro. Clave: evita el tirón del autoguardado.

## 🧰 Herramientas y preparación

Trabajaremos en `res://infraestructura/guardado/`. Necesitas los `a_dict()` / `de_dict()` de todos los sistemas de esta parte: inventario (295), equipo (296), progresión (302), monedero (303), blackboard (304), diario (305) y social (306). Documentación: [`FileAccess`](https://docs.godotengine.org/en/stable/classes/class_fileaccess.html), [`DirAccess`](https://docs.godotengine.org/en/stable/classes/class_diraccess.html) y [rutas de datos](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html).

## 🧪 Laboratorio guiado

1. **El formato.** Metadatos separados de los datos, y la versión lo primero:

```json
{
  "version": 3,
  "meta": {
    "guardado_en": "2026-03-14T18:22:41",
    "tiempo_jugado": 43512.5,
    "nivel": 27,
    "zona": "zona_guarida",
    "build": "1.4.2",
    "dispositivo": "pc-a1b2"
  },
  "datos": {
    "progresion": { "xp": 184000, "puntos": 3, "desbloqueos": ["receta_capa_lobo"] },
    "inventario": { "capacidad": 30, "ranuras": { "0": { "id": "pocion_menor", "cantidad": 7 } } },
    "equipo": { "mano_principal": "espada_hierro" },
    "monedero": { "oro": 4210, "gemas": 12 },
    "quests": { "la_guarida": { "estado": 2, "progreso": { "llegar": 1 } } },
    "social": { "reputacion": { "guardia": 45.0, "bandidos": -60.0 } },
    "narrativa": { "vars": { "herrero_contratado": true } }
  },
  "checksum": "9f2c…"
}
```

2. **El registro de sistemas.** El save no conoce ningún sistema por su nombre: los sistemas se registran.

```gdscript
class_name Guardado
extends RefCounted

const SAVE_VERSION := 3
const DIR := "user://saves"
const MAX_BACKUPS := 3

signal guardado_ok(slot: int)
signal guardado_fallo(slot: int, motivo: String)
signal cargado_ok(slot: int, migrado_desde: int)

# clave -> {leer: Callable() -> Dictionary, escribir: Callable(Dictionary)}
var _sistemas := {}

func registrar(clave: String, leer: Callable, escribir: Callable) -> void:
	_sistemas[clave] = {"leer": leer, "escribir": escribir}

func _ruta(slot: int) -> String:
	return "%s/slot_%d.json" % [DIR, slot]
```

3. **Escritura atómica.** El paso que separa "guardar" de "guardar bien":

```gdscript
func guardar(slot: int, meta: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)

	var datos := {}
	for clave in _sistemas:
		datos[clave] = _sistemas[clave]["leer"].call()

	var payload := {"version": SAVE_VERSION, "meta": meta, "datos": datos}
	payload["checksum"] = _checksum(payload)
	var texto := JSON.stringify(payload, "\t")

	# 1) Escribir a un TEMPORAL. Si el juego se cierra aquí, el save bueno
	#    sigue intacto: nadie ha tocado el archivo real todavía.
	var tmp := _ruta(slot) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		guardado_fallo.emit(slot, "no se pudo abrir el temporal: %d" % FileAccess.get_open_error())
		return false
	f.store_string(texto)
	f.flush()
	f.close()

	# 2) Releer y comprobar ANTES de sustituir. Un disco lleno puede haber
	#    escrito la mitad sin dar error.
	var verif := FileAccess.open(tmp, FileAccess.READ)
	if verif == null or verif.get_as_text() != texto:
		if verif: verif.close()
		DirAccess.remove_absolute(tmp)
		guardado_fallo.emit(slot, "el archivo temporal no se escribió completo")
		return false
	verif.close()

	# 3) Rotar backups y renombrar. El rename es lo único atómico que tenemos.
	_rotar_backups(slot)
	var dir := DirAccess.open(DIR)
	if FileAccess.file_exists(_ruta(slot)):
		dir.copy(_ruta(slot), _ruta(slot) + ".bak1")
	var err := dir.rename(tmp, _ruta(slot))
	if err != OK:
		guardado_fallo.emit(slot, "no se pudo sustituir el save (error %d)" % err)
		return false

	guardado_ok.emit(slot)
	return true

func _rotar_backups(slot: int) -> void:
	var dir := DirAccess.open(DIR)
	for i in range(MAX_BACKUPS, 1, -1):
		var viejo := "%s.bak%d" % [_ruta(slot), i - 1]
		if FileAccess.file_exists(viejo):
			dir.copy(viejo, "%s.bak%d" % [_ruta(slot), i])

func _checksum(payload: Dictionary) -> String:
	var copia := payload.duplicate(true)
	copia.erase("checksum")
	return String(JSON.stringify(copia).sha256_text())
```

4. **Las migraciones.** El corazón del sistema, y lo que hace que un parche no borre partidas:

```gdscript
# Cada función lleva de la versión N a la N+1. Se aplican EN CADENA, así que
# un save de la v1 pasa por migrar_1_a_2 y luego por migrar_2_a_3.
static func _migraciones() -> Dictionary:
	return {
		1: Callable(Guardado, "_m1_a_2"),
		2: Callable(Guardado, "_m2_a_3"),
	}

static func _m1_a_2(d: Dictionary) -> Dictionary:
	# v2 separó el monedero del inventario: antes el oro era un item.
	var inv: Dictionary = d["datos"].get("inventario", {})
	var oro := 0
	for clave in inv.get("ranuras", {}).keys():
		if str(inv["ranuras"][clave].get("id", "")) == "moneda_oro":
			oro += int(inv["ranuras"][clave].get("cantidad", 0))
			inv["ranuras"].erase(clave)
	d["datos"]["monedero"] = {"oro": oro, "gemas": 0}
	return d

static func _m2_a_3(d: Dictionary) -> Dictionary:
	# v3 renombró una facción y añadió el bloque social con valores neutros.
	var social: Dictionary = d["datos"].get("social", {"reputacion": {}})
	var rep: Dictionary = social.get("reputacion", {})
	if rep.has("guardias"):
		rep["guardia"] = rep["guardias"]      # alias: el id cambió en el parche
		rep.erase("guardias")
	social["reputacion"] = rep
	d["datos"]["social"] = social
	return d

static func migrar(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 1))
	var migs := _migraciones()
	while v < SAVE_VERSION:
		if not migs.has(v):
			push_error("no hay migración de la versión %d: el save no se puede cargar" % v)
			return {}
		d = migs[v].call(d)
		v += 1
		d["version"] = v
	return d
```

Regla práctica: **una migración se escribe el mismo día que se cambia el formato**, no cuando llegan los informes. Y no se borra nunca, por vieja que sea.

5. **Cargar, con validación y recuperación:**

```gdscript
func cargar(slot: int) -> bool:
	var candidatos := [_ruta(slot)]
	for i in MAX_BACKUPS:
		candidatos.append("%s.bak%d" % [_ruta(slot), i + 1])

	for ruta in candidatos:
		var d := _leer_y_validar(ruta)
		if d.is_empty():
			continue
		var version_original := int(d.get("version", 1))
		if version_original > SAVE_VERSION:
			# Save de una versión FUTURA (el jugador volvió a una build vieja).
			push_error("save de la versión %d, esta build entiende hasta la %d"
				% [version_original, SAVE_VERSION])
			continue
		d = migrar(d)
		if d.is_empty():
			continue
		_aplicar(d.get("datos", {}))
		if ruta != _ruta(slot):
			push_warning("se ha cargado un backup: el save principal estaba dañado")
		cargado_ok.emit(slot, version_original)
		return true
	return false

func _leer_y_validar(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return {}
	var texto := f.get_as_text()
	f.close()
	var d = JSON.parse_string(texto)
	if typeof(d) != TYPE_DICTIONARY:
		push_warning("save ilegible: %s" % ruta)
		return {}
	if not d.has("version") or not d.has("datos"):
		push_warning("save sin estructura esperada: %s" % ruta)
		return {}
	if d.has("checksum") and String(d["checksum"]) != _checksum(d):
		push_warning("checksum incorrecto (corrupto o editado): %s" % ruta)
		return {}
	return d

func _aplicar(datos: Dictionary) -> void:
	for clave in _sistemas:
		# Un sistema nuevo que no existía en el save recibe un diccionario vacío
		# y aplica sus valores por defecto. Nada de saltarse la llamada.
		_sistemas[clave]["escribir"].call(datos.get(clave, {}))
```

6. **Metadatos sin cargar la partida.** Lo que el menú necesita:

```gdscript
func listar_ranuras(maximo := 3) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for slot in maximo:
		var d := _leer_y_validar(_ruta(slot))
		if d.is_empty():
			salida.append({"slot": slot, "vacia": true})
		else:
			var m: Dictionary = d.get("meta", {})
			salida.append({
				"slot": slot, "vacia": false,
				"nivel": int(m.get("nivel", 1)),
				"zona": str(m.get("zona", "")),
				"tiempo": float(m.get("tiempo_jugado", 0.0)),
				"fecha": str(m.get("guardado_en", "")),
				"version": int(d.get("version", 1)),
			})
	return salida
```

7. **Autoguardado y checkpoints:**

```gdscript
class_name Autoguardado
extends Node

const SLOT_AUTO := 9          # ranura propia: jamás pisa la del jugador

@export var periodo := 120.0
var _t := 0.0
var _guardado: Guardado
var _meta: Callable

func _process(delta: float) -> void:
	_t += delta
	if _t < periodo:
		return
	_t = 0.0
	guardar_ahora()

func guardar_ahora() -> void:
	# Serializar es barato (diccionarios); escribir es lo que puede dar el tirón.
	# En un juego grande, esta llamada va a un WorkerThreadPool.
	_guardado.guardar(SLOT_AUTO, _meta.call())
```

```gdscript
class_name Checkpoints
extends RefCounted

# Un checkpoint NO toca disco: es la misma serialización en memoria. Reanudar
# desde el último punto es instantáneo y no gasta escrituras.
var _pila: Array[Dictionary] = []
var _guardado: Guardado

func marcar(sistemas: Dictionary) -> void:
	var snap := {}
	for clave in sistemas:
		snap[clave] = sistemas[clave]["leer"].call()
	_pila.append(snap)
	if _pila.size() > 5:
		_pila.pop_front()

func revertir(sistemas: Dictionary) -> bool:
	if _pila.is_empty():
		return false
	var snap: Dictionary = _pila.back()
	for clave in sistemas:
		sistemas[clave]["escribir"].call(snap.get(clave, {}))
	return true
```

8. **Probarlo.** Las pruebas de un save son las más rentables del juego:

```gdscript
extends SceneTree

func _init() -> void:
	# Migración encadenada v1 -> v3.
	var viejo := {
		"version": 1,
		"meta": {"nivel": 5},
		"datos": {
			"inventario": {"capacidad": 20, "ranuras": {"0": {"id": "moneda_oro", "cantidad": 250}}},
			"social": {"reputacion": {"guardias": 30.0}},
		},
	}
	var nuevo := Guardado.migrar(viejo.duplicate(true))
	assert(nuevo["version"] == Guardado.SAVE_VERSION)
	assert(nuevo["datos"]["monedero"]["oro"] == 250, "la migración v1→v2 no extrajo el oro")
	assert(not nuevo["datos"]["inventario"]["ranuras"].has("0"), "el oro sigue en el inventario")
	assert(nuevo["datos"]["social"]["reputacion"].has("guardia"), "la migración v2→v3 no renombró la facción")

	# Ida y vuelta completa.
	var g := Guardado.new()
	var estado := {"x": 1}
	g.registrar("prueba", func(): return estado, func(d): estado = d.duplicate())
	assert(g.guardar(0, {"nivel": 1}), "el guardado falló")
	estado = {}
	assert(g.cargar(0) and estado["x"] == 1, "la carga no restauró el estado")

	# Corrupción: se destroza el save y debe recuperarse del backup.
	assert(g.guardar(0, {"nivel": 2}))
	var f := FileAccess.open("user://saves/slot_0.json", FileAccess.WRITE)
	f.store_string("{ esto no es json"); f.close()
	estado = {}
	assert(g.cargar(0), "no se recuperó del backup tras la corrupción")

	print("== 8 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Añade compresión con `FileAccess.open_compressed` y mide el tamaño antes y después.
2. Añade una captura de pantalla en miniatura a los metadatos de cada ranura.
3. Implementa guardado asíncrono con `WorkerThreadPool` y mide el tirón que evita.
4. Añade un modo "importar/exportar partida" a un archivo que el jugador pueda mover.
5. Escribe una prueba que genere saves de las versiones 1 y 2 y compruebe que ambos cargan.
6. Detecta y registra saves con datos imposibles (oro negativo, nivel superior al máximo).
7. Implementa un modo hardcore donde el save se borra al morir, con confirmación.

## 📝 Reto verificable

Implementa el sistema con `SAVE_VERSION`, **al menos tres migraciones encadenadas**, escritura atómica con verificación, tres backups rotativos, checksum, validación de esquema, tres ranuras con metadatos, autoguardado en ranura propia y checkpoints en memoria.

**Criterio de aceptación**: una prueba headless con **al menos 20 aserciones** demuestra que: (a) un save de la versión 1 se carga correctamente tras pasar por todas las migraciones; (b) un save con versión **superior** a `SAVE_VERSION` se rechaza con un mensaje claro y no corrompe nada; (c) corromper el archivo principal hace que se cargue el backup y se avise; (d) alterar un byte del contenido invalida el checksum; (e) tras un guardado interrumpido (simulado dejando solo el `.tmp`), el save anterior sigue siendo cargable; (f) `listar_ranuras()` devuelve los metadatos sin invocar ningún `de_dict()` de los sistemas; (g) un sistema registrado que no existía en el save recibe `{}` y aplica sus valores por defecto sin fallar.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El parche 1.1 no carga partidas de la 1.0 | Se cambió el formato sin subir `SAVE_VERSION` ni escribir migración. Hazlo el mismo día. |
| El save queda a medias tras un cierre forzado | Se escribía directamente sobre el archivo. Temporal + verificación + rename. |
| Cargar una partida vieja peta con "Invalid get index" | No se validó el esquema. Usa `get(clave, defecto)` en todos los `de_dict()`. |
| El juego da un tirón cada dos minutos | Autoguardado síncrono en el hilo principal. Serializa rápido y escribe en un worker. |
| El autoguardado sobrescribió la partida del jugador | Comparte ranura. El autoguardado tiene la suya, siempre. |
| Al añadir un sistema nuevo, los saves viejos fallan | No se llamó a su `de_dict` con `{}`. Aplica todos los sistemas, con diccionario vacío si falta. |
| Se guardaron los nodos y tras un parche no cargan | Se serializó el árbol de escena. Guarda estado de dominio, no nodos. |
| El jugador edita el JSON y se da 999.999 de oro | El checksum detecta la edición torpe, pero en local no hay defensa real. Si importa, la autoridad va al servidor (clase 314). |

## ❓ Preguntas frecuentes

**❓ ¿Por qué no serializar el árbol de escena?** Porque acopla tu save a la estructura de tus escenas y a la versión del motor. El día que muevas un nodo, renombres una propiedad o actualices Godot, los saves dejan de cargar y no hay migración razonable. Guardar `{"xp": 184000}` sobrevive a todo eso.

**❓ ¿El checksum protege contra trampas?** No. Cualquiera puede recalcularlo. Sirve para detectar **corrupción** y ediciones torpes. Si el jugador no debe poder alterar su estado (multijugador, rankings, economía real), la única solución es que el estado autoritativo viva en el servidor ([clase 314](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/314-economia-transaccional-de-servidor/README.md)).

**❓ ¿Cifro el save?** En single-player rara vez compensa: dificulta el modding y el soporte, y no impide nada a quien quiera trampear. Si lo haces, `FileAccess.open_encrypted_with_pass` existe — pero recuerda que la clave está en tu binario.

**❓ ¿Cada cuánto autoguardo?** Cada 1-3 minutos y, sobre todo, **en eventos** (cambio de zona, fin de combate, subida de nivel). El coste real no es el tiempo entre guardados, sino cuánto progreso pierde el jugador si se corta la luz: mídelo en minutos de juego, no en segundos de reloj.

**❓ ¿Y si quiero guardado en la nube?** Este formato ya está preparado: tiene versión, timestamp e id de dispositivo, que son exactamente los tres campos que necesita la resolución de conflictos de la [clase 313](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/313-cloud-saves-cross-save-y-resolucion-de-conflictos/README.md). Añadirlos ahora cuesta tres líneas; añadirlos después cuesta una migración.

## 🔗 Referencias

- Godot Docs — `FileAccess`: <https://docs.godotengine.org/en/stable/classes/class_fileaccess.html>
- Godot Docs — `DirAccess`: <https://docs.godotengine.org/en/stable/classes/class_diraccess.html>
- Godot Docs — Rutas de datos (`user://`): <https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html>
- Godot Docs — `WorkerThreadPool` (guardado asíncrono): <https://docs.godotengine.org/en/stable/classes/class_workerthreadpool.html>
- Jason Gregory — *Game Engine Architecture*, capítulo de serialización y persistencia: <https://www.gameenginebook.com/>

## ⬅️ Clase anterior

[Clase 306 - Facciones, reputación y relaciones](../306-facciones-reputacion-y-relaciones/README.md)

## ➡️ Siguiente clase

[Clase 308 - Commands, input recording y replays](../308-commands-input-recording-y-replays/README.md)
