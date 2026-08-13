# Clase 344 — Grandes mundos y world partition

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Documentación de World Partition de Unreal Engine (referencia conceptual) · Gregory, «Game Engine Architecture»*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir un mundo que **no cabe en memoria**. Un mundo abierto de 16 × 16 km no es un nivel grande: es un problema arquitectónico distinto, con tres retos que no aparecen en un juego de niveles.

El primero es la **memoria**: solo puede estar cargado lo cercano, y eso lo resuelve el streaming de la clase anterior. El segundo es la **precisión de coma flotante**: a 20 kilómetros del origen, un `float` de 32 bits ya no distingue milímetros y las cosas empiezan a temblar. El tercero es la **persistencia**: si el jugador deja un objeto tirado en una región y vuelve dos horas después, tiene que seguir ahí — pero esa región ha estado descargada todo ese tiempo.

Vas a implementar los tres: particionado en celdas con jerarquía, **rebase de origen**, estado persistente por región y niveles de detalle a distancia. Y verás por qué un mundo abierto obliga a diseñar el contenido de otra manera, no solo a programar de otra manera.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diseñar el particionado de un mundo grande en celdas y niveles jerárquicos.
2. Explicar la pérdida de precisión de los flotantes y sus síntomas.
3. Implementar **rebase de origen** y adaptar los sistemas que lo notan.
4. Implementar persistencia por región con estado diferencial.
5. Diseñar niveles de detalle por distancia, incluyendo simulación reducida.
6. Implementar simulación a distancia de entidades no cargadas.
7. Verificar la coherencia del mundo tras recorrerlo y volver.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Celdas y jerarquía | La unidad de carga y de trabajo. |
| 2 | Precisión de flotantes | El problema que sorprende a todo el mundo. |
| 3 | Rebase de origen | La solución, y lo que rompe al aplicarla. |
| 4 | Estado por región | Lo que el jugador cambió debe sobrevivir a la descarga. |
| 5 | Estado diferencial | Guardar solo lo que difiere del original. |
| 6 | LOD de mundo | Lo lejano se ve, pero no con todo el detalle. |
| 7 | HLOD | Agrupar lo lejano en una sola malla. |
| 8 | Simulación a distancia | Los NPC de lejos siguen existiendo, más barato. |
| 9 | Costuras entre celdas | Donde aparecen los agujeros visibles. |
| 10 | Verificación | Recorrer y volver debe dejarlo todo igual. |

## 📖 Definiciones y características

- **World partition**: división del mundo en celdas cargables independientemente. Clave: sustituye a los niveles como unidad.
- **Celda**: región cuadrada o cúbica del mundo con su contenido. Clave: su tamaño es un compromiso entre granularidad y sobrecarga.
- **Jerarquía de celdas**: niveles de celda de distinto tamaño. Clave: permite detalle cerca y agrupación lejos.
- **Precisión de coma flotante**: un `float32` tiene ~7 dígitos significativos. Clave: a 10 km del origen, la resolución es de milímetros; a 100 km, de centímetros.
- **Jitter (temblor)**: vibración visible por falta de precisión. Clave: es el síntoma característico de estar lejos del origen.
- **Z-fighting**: parpadeo entre superficies coplanares. Clave: se agrava con la distancia y con un plano cercano mal elegido.
- **Rebase de origen (origin shifting)**: mover el mundo para que el jugador esté cerca del origen. Clave: mantiene la precisión donde importa.
- **Coordenada global**: posición absoluta en el mundo, en doble precisión o en (celda, offset). Clave: es la fuente de verdad.
- **Coordenada local**: posición relativa al origen actual. Clave: es la que usa el motor.
- **Estado persistente de región**: cambios del jugador en una celda descargada. Clave: se guarda aparte del contenido original.
- **Estado diferencial**: solo lo que difiere del estado inicial. Clave: un mundo entero de estados completos no cabe en un save.
- **LOD de mundo**: versión simplificada de una celda lejana. Clave: permite ver el horizonte sin cargarlo todo.
- **HLOD (hierarchical LOD)**: malla única que sustituye a un grupo de objetos lejanos. Clave: reduce draw calls drásticamente.
- **Simulación a distancia**: actualización barata de entidades en celdas descargadas. Clave: mantiene el mundo vivo sin coste.
- **Costura (seam)**: unión entre celdas. Clave: donde aparecen los agujeros y los saltos de iluminación.
- **Celda siempre cargada**: contenido global (audio ambiente, sistemas de juego). Clave: no depende de la posición.

## 🧰 Herramientas y preparación

Godot 4.x con el gestor de recursos de la [clase 343](../343-resource-management-y-streaming-asincrono/README.md). Trabajaremos en `res://mundo/`. Como referencia conceptual, la [documentación de World Partition de Unreal](https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition-in-unreal-engine) describe un sistema de producción completo; aquí construimos el modelo para entenderlo y para aplicarlo en un motor que no lo trae de serie.

## 🧪 Laboratorio guiado

1. **El problema de la precisión.** Los números, que son más agresivos de lo que parece:

```text
float32: 24 bits de mantisa → ~7 dígitos decimales significativos

Distancia al origen    Resolución representable
─────────────────────────────────────────────
        1 m            0,00000006 m  (60 nm)
      100 m            0,000008 m
    1.000 m            0,00006 m     (0,06 mm)
   10.000 m            0,0009 m      (~1 mm)    ← empieza a notarse
  100.000 m            0,0078 m      (~8 mm)    ← temblor visible
1.000.000 m            0,0625 m      (6 cm)     ← injugable
```

A 10 km del origen, una animación que mueve un dedo 0,5 mm **no se mueve**: el valor se redondea al mismo flotante. Y una cámara que rota produce saltos, porque las posiciones intermedias no son representables.

```gdscript
extends SceneTree   # mundo/precision_demo.gd

func _init() -> void:
	print("== Pérdida de precisión con la distancia ==")
	for d in [1.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0]:
		var p := Vector3(d, 0, 0)
		var movido := p + Vector3(0.001, 0, 0)      # mover 1 mm
		var real := (movido.x - p.x) * 1000.0
		print("  a %10.0f m · mover 1 mm → se movió %.4f mm" % [d, real])
	quit()
```

2. **El rebase de origen.** La solución, y su implicación:

```gdscript
class_name RebaseOrigen
extends Node

signal origen_cambiado(desplazamiento: Vector3)

const UMBRAL := 2000.0             # rebase cuando el jugador se aleja 2 km

var origen_global := Vector3.ZERO  # dónde está el origen local en el mundo
var _jugador: Node3D

func _process(_d: float) -> void:
	if _jugador.global_position.length() < UMBRAL:
		return
	# El jugador se ha alejado: se mueve TODO el mundo para que vuelva a
	# estar cerca del origen local. El jugador no se entera; el mundo sí.
	var desplazamiento := -_jugador.global_position
	_desplazar_todo(desplazamiento)
	origen_global -= desplazamiento
	origen_cambiado.emit(desplazamiento)

func _desplazar_todo(d: Vector3) -> void:
	# Todo lo que tiene posición en el mundo: nodos, partículas, física,
	# audio, efectos. Lo que se olvide, se queda atrás y se nota.
	for n in get_tree().get_nodes_in_group("mundo"):
		if n is Node3D:
			n.global_position += d

func a_global(local: Vector3) -> Vector3:
	return local + origen_global

func a_local(global: Vector3) -> Vector3:
	return global - origen_global
```

**Lo que rompe un rebase**, y por qué esta es la parte difícil:

| Sistema | Qué pasa | Solución |
|---|---|---|
| Partículas ya emitidas | Se quedan en el sitio viejo | Desplazarlas también, o reiniciar el sistema |
| Trails y estelas | Se estiran hasta el infinito | Desplazar sus puntos históricos |
| Física en vuelo | Velocidades intactas, posiciones movidas | Correcto: solo se desplaza posición |
| Cámara con suavizado | Salta bruscamente | Desplazar también su objetivo interno |
| Posiciones guardadas en scripts | Apuntan al sitio viejo | Guardar en coordenadas **globales**, no locales |
| Navmesh | Sigue al mundo si es hijo | Comprobar que se desplaza con él |
| Audio 3D posicional | Los sonidos se quedan atrás | Desplazar los emisores |
| Replays y red | Las posiciones dejan de coincidir | Grabar y transmitir en coordenadas globales |

La regla que resume todo: **guarda siempre en coordenadas globales, trabaja en locales, y convierte en los bordes**.

3. **La alternativa: coordenadas (celda, offset).** Sin rebase, y sin límite:

```gdscript
class_name PosicionMundo
extends RefCounted

# Enteros para la celda y float para el offset dentro de ella. La precisión es
# constante en TODO el mundo, por grande que sea, y no hace falta rebase.
const TAM_CELDA := 1024.0

var celda: Vector3i
var offset: Vector3          # siempre en [0, TAM_CELDA)

static func desde_global(g: Vector3) -> PosicionMundo:
	var p := PosicionMundo.new()
	p.celda = Vector3i(floori(g.x / TAM_CELDA), floori(g.y / TAM_CELDA), floori(g.z / TAM_CELDA))
	p.offset = g - Vector3(p.celda) * TAM_CELDA
	return p

func a_local(celda_origen: Vector3i) -> Vector3:
	# La posición relativa al origen actual: pequeña, y por tanto precisa.
	return Vector3(celda - celda_origen) * TAM_CELDA + offset

func distancia_a(otra: PosicionMundo) -> float:
	var dc := Vector3(celda - otra.celda) * TAM_CELDA
	return (dc + offset - otra.offset).length()

func normalizar() -> void:
	# Mantener el offset dentro de la celda: si no, la precisión vuelve a
	# depender de lo lejos que esté el objeto de su celda.
	var extra := Vector3i(floori(offset.x / TAM_CELDA), floori(offset.y / TAM_CELDA),
						  floori(offset.z / TAM_CELDA))
	celda += extra
	offset -= Vector3(extra) * TAM_CELDA
```

| | Rebase de origen | Coordenadas (celda, offset) |
|---|---|---|
| Complejidad | Media, con muchos casos que romper | Alta al principio, luego uniforme |
| Precisión | Buena cerca del origen local | **Constante en todo el mundo** |
| Multijugador | Difícil: cada cliente tiene su origen | Natural: la coordenada es absoluta |
| Integración con el motor | Directa (posiciones normales) | Requiere conversión en los bordes |
| Recomendación | Mundos de hasta ~50 km | Mundos mayores o planetarios |

4. **El particionado con jerarquía:**

```gdscript
class_name ParticionMundo
extends RefCounted

# Tres niveles: detalle cerca, agrupación lejos. Cada nivel es 4× el anterior.
const NIVELES := [
	{"tam": 128.0, "radio": 300.0,  "detalle": "completo"},
	{"tam": 512.0, "radio": 1500.0, "detalle": "hlod"},
	{"tam": 2048.0, "radio": 8000.0, "detalle": "impostor"},
]

var _celdas := {}                # nivel -> {Vector2i -> InfoCelda}

func celdas_necesarias(pos_global: Vector3) -> Dictionary:
	var necesarias := {}
	for nivel in NIVELES.size():
		var cfg: Dictionary = NIVELES[nivel]
		var tam := float(cfg["tam"])
		var radio := float(cfg["radio"])
		var alcance := int(ceil(radio / tam))
		var centro := Vector2i(floori(pos_global.x / tam), floori(pos_global.z / tam))
		for y in range(centro.y - alcance, centro.y + alcance + 1):
			for x in range(centro.x - alcance, centro.x + alcance + 1):
				var c := Vector2i(x, y)
				var d := _distancia_a_celda(pos_global, c, tam)
				if d > radio:
					continue
				# Una celda cubierta por un nivel MÁS detallado no se carga en
				# el nivel grueso: si no, se dibujaría dos veces.
				if _cubierta_por_nivel_menor(c, nivel, necesarias):
					continue
				necesarias["%d:%d,%d" % [nivel, x, y]] = {"nivel": nivel, "celda": c, "dist": d}
	return necesarias
```

5. **El estado persistente por región.** El reto que más se subestima:

```gdscript
class_name EstadoRegiones
extends RefCounted

# El mundo original viene con el juego y no cambia. Lo que el JUGADOR cambia
# se guarda aparte, y solo lo que DIFIERE: guardar el estado completo de un
# mundo de 16×16 km no cabe en ningún save.
var _diferencias := {}           # "celda" -> {id_objeto -> cambios}

func anotar(celda: Vector2i, id_objeto: String, cambios: Dictionary) -> void:
	var clave := "%d,%d" % [celda.x, celda.y]
	var region: Dictionary = _diferencias.get(clave, {})
	var previo: Dictionary = region.get(id_objeto, {})
	previo.merge(cambios, true)
	region[id_objeto] = previo
	_diferencias[clave] = region

func aplicar_al_cargar(celda: Vector2i, nodos: Dictionary) -> int:
	"""Al cargar una celda, se aplica encima lo que el jugador cambió."""
	var clave := "%d,%d" % [celda.x, celda.y]
	var region: Dictionary = _diferencias.get(clave, {})
	var aplicados := 0
	for id in region:
		var n = nodos.get(id)
		if n == null:
			# El objeto ya no existe en el contenido (un parche lo quitó).
			# Se descarta el cambio y se registra: no se rompe la carga.
			push_warning("estado huérfano en %s: %s" % [clave, id])
			continue
		_aplicar(n, region[id])
		aplicados += 1
	return aplicados

func capturar_al_descargar(celda: Vector2i, nodos: Dictionary, originales: Dictionary) -> void:
	"""Antes de descargar, se guarda lo que difiere del estado original."""
	for id in nodos:
		var d := _diferencia(nodos[id], originales.get(id, {}))
		if not d.is_empty():
			anotar(celda, id, d)
```

| Qué cambia el jugador | ¿Se guarda? | Cómo |
|---|---|---|
| Un cofre abierto | ✅ | Bandera booleana |
| Un enemigo muerto | ✅ | Bandera + momento (para el respawn) |
| Un objeto movido | ✅ | Posición y rotación |
| Un objeto destruido | ✅ | Bandera de destruido |
| Una construcción del jugador | ✅ | Objeto completo (no estaba en el original) |
| Un NPC desplazado por su rutina | ⚠️ | Solo si importa; si no, se recalcula |
| Hierba pisada | ❌ | Efímero: se descarta |
| Cadáveres antiguos | ❌ | Con caducidad: se limpian |

6. **Simulación a distancia.** Los NPC de lejos siguen existiendo:

```gdscript
class_name SimulacionADistancia
extends RefCounted

# Una entidad descargada NO desaparece: se simula de forma barata, con un
# tick cada varios segundos en vez de cada frame. Es lo que hace que el mundo
# se sienta vivo sin costar nada.
const PERIODO := 5.0

var _entidades := {}             # id -> {celda, tipo, estado, ultimo_tick}
var _t := 0.0

func tick(delta: float, tiempo_juego: float) -> void:
	_t += delta
	if _t < PERIODO:
		return
	_t = 0.0
	for id in _entidades:
		var e: Dictionary = _entidades[id]
		if e["cargada"]:
			continue              # si está cargada, se simula de verdad
		_simular_barato(e, tiempo_juego)

func _simular_barato(e: Dictionary, ahora: float) -> void:
	match str(e["tipo"]):
		"comerciante":
			# No se simula el camino: se calcula DÓNDE debería estar según la
			# hora. Al cargarse la celda, aparece en el sitio correcto.
			e["pos"] = _posicion_en_ruta(e, ahora)
		"cultivo":
			e["crecimiento"] = minf(1.0, float(e["crecimiento"]) + PERIODO / 3600.0)
		"enemigo_muerto":
			if ahora - float(e["muerto_en"]) > 600.0:
				e["vivo"] = true      # respawn a los 10 minutos, sin coste
		"campamento":
			e["recursos"] = maxi(0, int(e["recursos"]) - 1)
```

7. **Las costuras.** Donde aparecen los agujeros visibles:

```gdscript
# Problema 1: agujeros entre terrenos de celdas adyacentes por LOD distinto.
func _coser_bordes(celda_a: Celda, celda_b: Celda) -> void:
	# El borde compartido debe usar SIEMPRE la resolución del LOD más bajo de
	# los dos: si no, los vértices no coinciden y se ve el cielo entre ellos.
	var lod := maxi(celda_a.lod, celda_b.lod)
	celda_a.forzar_lod_en_borde(_direccion(celda_a, celda_b), lod)
	celda_b.forzar_lod_en_borde(_direccion(celda_b, celda_a), lod)

# Problema 2: objetos que cruzan el límite de dos celdas.
func _asignar_celda(objeto: Objeto) -> Vector2i:
	# Se asigna por el CENTRO del objeto, y la celda extiende sus límites de
	# carga para incluir lo que sobresale. Con la asignación por esquina, un
	# edificio a caballo desaparece a mitad.
	return _celda_de(objeto.aabb.get_center())

# Problema 3: iluminación que salta al cambiar de celda.
# La solución es que la iluminación indirecta NO se hornee por celda de forma
# independiente: se usan probes con una rejilla global, o GI en tiempo real
# (clase 348).
```

8. **Verificar la coherencia.** El test que de verdad importa:

```gdscript
extends SceneTree

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	var mundo := Mundo.nuevo("res://mundo/prueba.json")

	# 1) Ir, cambiar algo, irse muy lejos, volver: debe seguir igual.
	mundo.mover_jugador(Vector3(0, 0, 0))
	mundo.abrir_cofre("cofre_042")
	mundo.mover_jugador(Vector3(50000, 0, 50000))     # la celda se descarga
	mundo.actualizar_hasta_estable()
	mundo.mover_jugador(Vector3(0, 0, 0))
	mundo.actualizar_hasta_estable()
	check.call(mundo.cofre_abierto("cofre_042"), "el estado sobrevive a la descarga")

	# 2) Precisión: a 50 km, moverse 1 mm debe seguir funcionando.
	mundo.mover_jugador(Vector3(50000, 0, 0))
	var antes := mundo.pos_local_jugador()
	mundo.mover_jugador_relativo(Vector3(0.001, 0, 0))
	check.call(mundo.pos_local_jugador() != antes,
		"a 50 km sigue habiendo precisión milimétrica")

	# 3) El rebase no pierde nada.
	var n_antes := mundo.contar_objetos()
	mundo.forzar_rebase()
	check.call(mundo.contar_objetos() == n_antes, "el rebase no pierde objetos")
	check.call(mundo.distancia_jugador_a("faro_norte") == mundo.distancia_esperada("faro_norte"),
		"las distancias globales se conservan tras el rebase")

	# 4) Recorrido largo: sin fugas ni crecimiento indefinido.
	var mem := OS.get_static_memory_usage()
	for i in 200:
		mundo.mover_jugador(Vector3(i * 500.0, 0, sin(i) * 2000.0))
		mundo.actualizar_hasta_estable()
	var crecimiento := float(OS.get_static_memory_usage()) / mem
	check.call(crecimiento < 1.3, "recorrer 100 km no dispara la memoria (×%.2f)" % crecimiento)

	# 5) La simulación a distancia avanza.
	var cultivo := mundo.estado("cultivo_norte")
	mundo.avanzar_tiempo(3600.0)
	check.call(mundo.estado("cultivo_norte")["crecimiento"] > cultivo["crecimiento"],
		"las entidades descargadas siguen simulándose")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

## ✍️ Ejercicios

1. Ejecuta la demo de precisión y anota a qué distancia empieza a fallar el milímetro.
2. Implementa el rebase y encuentra qué sistema de tu proyecto se rompe primero.
3. Implementa coordenadas (celda, offset) y compara la complejidad con el rebase.
4. Diseña el particionado de tu mundo: tamaños de celda y radios por nivel.
5. Implementa estado diferencial y mide cuánto ocupa el save tras dos horas de juego.
6. Añade simulación a distancia para un tipo de entidad y comprueba la coherencia al volver.
7. Provoca una costura entre celdas con LOD distinto y arréglala.

## 📝 Reto verificable

Implementa un sistema de mundo grande con: particionado jerárquico de **al menos tres niveles**, rebase de origen o coordenadas (celda, offset), estado persistente diferencial por región, LOD de mundo con HLOD para lo lejano, simulación a distancia de al menos dos tipos de entidad y costura correcta entre celdas de distinto LOD.

**Criterio de aceptación**: una prueba headless con **al menos 18 aserciones** demuestra que: (a) un cambio hecho en una celda sobrevive a descargarla y volver, incluso tras 50 km de distancia; (b) a 50 km del origen el jugador conserva precisión milimétrica; (c) el rebase (o el sistema de coordenadas) no pierde ni duplica ningún objeto, y las **distancias globales** entre objetos se conservan exactamente; (d) recorrer 100 km cargando y descargando no incrementa la memoria más de un 30 % sobre la línea base; (e) las entidades en celdas descargadas siguen evolucionando según su simulación barata y su estado es coherente al recargarse; (f) el save de estado diferencial tras modificar 500 objetos ocupa menos que un save de estado completo del mundo; (g) dos celdas adyacentes con LOD distinto comparten exactamente los mismos vértices en su borde.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Todo tiembla al alejarse del origen | Pérdida de precisión. Rebase o coordenadas (celda, offset). |
| Tras el rebase las partículas se quedan atrás | No se desplazaron. Enumera **todos** los sistemas con posición. |
| Un objeto movido vuelve a su sitio al recargar la zona | No se capturó el estado al descargar. Diferencial antes de liberar. |
| El save ocupa cientos de MB | Se guarda el estado completo del mundo. Solo lo que difiere. |
| Se ve el cielo entre dos trozos de terreno | Costura por LOD distinto. Fuerza el LOD menor en el borde compartido. |
| Un edificio a caballo entre celdas desaparece a medias | Asignación por esquina. Asigna por centro y extiende los límites. |
| Los NPC aparecen donde los dejaste hace dos horas | Sin simulación a distancia. Añádela para los que importen. |
| La memoria sube al recorrer el mundo | No se descarga, o el presupuesto no se aplica. Revisa el gestor (clase 343). |
| El multijugador desincroniza al rebasar | Se transmiten coordenadas locales. Transmite siempre globales. |

## ❓ Preguntas frecuentes

**❓ ¿A partir de qué tamaño hace falta esto?** El streaming empieza a hacer falta cuando el mundo no cabe en memoria, y eso depende del detalle: puede ser a 1 km² o a 100. La **precisión** empieza a notarse a partir de unos 5-10 km del origen. Por debajo de eso, un nivel grande normal funciona.

**❓ ¿Rebase o coordenadas (celda, offset)?** Rebase si tu mundo llega a decenas de kilómetros y es single-player: es más fácil de integrar con el motor. Coordenadas si el mundo es enorme o planetario, o si hay multijugador — porque una coordenada absoluta es la misma para todos los clientes y un origen local no.

**❓ ¿Cómo pruebo un mundo grande sin construirlo?** Genera el contenido proceduralmente para las pruebas: lo que se está verificando es el **sistema** (carga, descarga, persistencia, precisión), no el contenido. Es exactamente lo que hace el test del paso 8, y corre en segundos.

**❓ ¿Y la iluminación horneada?** Es uno de los puntos difíciles: hornear por celda de forma independiente produce saltos visibles en las costuras. Las soluciones habituales son una rejilla global de probes que no dependa del particionado, o iluminación indirecta en tiempo real ([clase 348](../348-global-illumination-y-ray-tracing-moderno/README.md)).

**❓ ¿Esto cambia el diseño del contenido?** Mucho, y conviene saberlo antes de empezar. En un mundo particionado, el contenido tiene que estar **distribuido**: un evento que necesite cargadas cinco celdas a la vez no es viable, una vista que abarque 8 km necesita HLOD desde el principio, y las misiones no pueden asumir que un NPC lejano está simulado con detalle. Diseñar el mundo y diseñar el particionado son la misma tarea.

## 🔗 Referencias

- Unreal Engine Docs — World Partition (referencia conceptual de un sistema de producción): <https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition-in-unreal-engine>
- Jason Gregory — *Game Engine Architecture*, capítulos de mundos y streaming: <https://www.gameenginebook.com/>
- Godot Docs — `Node3D` y transformaciones globales: <https://docs.godotengine.org/en/stable/classes/class_node3d.html>
- Godot Docs — Problemas de precisión en mundos grandes: <https://docs.godotengine.org/en/stable/tutorials/3d/large_world_coordinates.html>
- Akenine-Möller et al. — *Real-Time Rendering*, capítulo de LOD y culling: <https://www.realtimerendering.com/>

## ⬅️ Clase anterior

[Clase 343 - Resource Management y streaming asíncrono](../343-resource-management-y-streaming-asincrono/README.md)

## ➡️ Siguiente clase

[Clase 345 - Rendering temporal](../345-rendering-temporal/README.md)
