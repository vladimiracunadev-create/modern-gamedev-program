# Clase 342 — Particionamiento espacial

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Akenine-Möller et al., «Real-Time Rendering» (spatial data structures) · Ericson, «Real-Time Collision Detection»*
> ⏱️ Duración estimada: **125 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Responder rápido a la pregunta que un juego hace miles de veces por frame: **¿qué hay cerca de aquí?**. Sin estructura espacial, la respuesta cuesta O(n) por consulta y O(n²) si todas las entidades preguntan — con 2.000 entidades son cuatro millones de comprobaciones por frame, y eso no cabe en 16 ms.

Vas a implementar y **comparar midiendo** las cinco estructuras que se usan en producción: rejilla uniforme, hashing espacial, quadtree, octree y BVH. Cada una gana en un caso distinto, y el objetivo de la clase no es que memorices cuál es "la mejor" —no la hay—, sino que sepas elegir según la distribución de tus objetos, su movilidad y el tipo de consulta.

Las aplicaciones van mucho más allá de las colisiones: culling de render, percepción de IA, consultas de audio, selección de objetivos y particionado de mundos grandes usan exactamente lo mismo.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar por qué la fuerza bruta escala mal y a partir de cuántos objetos.
2. Implementar rejilla uniforme, hashing espacial, quadtree, octree y BVH.
3. Elegir la estructura adecuada según distribución, movilidad y consulta.
4. Implementar las tres consultas fundamentales: radio, caja y rayo.
5. Gestionar objetos en movimiento sin reconstruir la estructura entera.
6. Medir y comparar las estructuras sobre datos realistas.
7. Aplicar la estructura a culling de render y percepción de IA.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | El coste de la fuerza bruta | Marca a partir de dónde hace falta estructura. |
| 2 | Rejilla uniforme | La más simple y muy difícil de superar con objetos uniformes. |
| 3 | Hashing espacial | Rejilla infinita sin reservar memoria para el vacío. |
| 4 | Quadtree / Octree | Se adaptan a distribuciones desiguales. |
| 5 | BVH | La estructura de referencia para rayos y geometría estática. |
| 6 | Consultas | Radio, caja y rayo: las tres que cubren casi todo. |
| 7 | Objetos en movimiento | Es lo que decide la estructura más veces. |
| 8 | Reconstrucción vs actualización | Dos estrategias con costes muy distintos. |
| 9 | Aplicaciones | Colisión, culling, IA, audio: la misma estructura. |
| 10 | Medición | La única forma de elegir bien. |

## 📖 Definiciones y características

- **Particionamiento espacial**: organizar objetos según su posición para acelerar consultas por proximidad. Clave: convierte O(n) en algo cercano a O(1) o O(log n).
- **Fase amplia (broad phase)**: descarte rápido de pares que no pueden colisionar. Clave: es donde se usan estas estructuras.
- **Fase estrecha (narrow phase)**: comprobación exacta de los pares supervivientes. Clave: cara, y por eso importa que lleguen pocos.
- **Rejilla uniforme**: división del espacio en celdas del mismo tamaño. Clave: insertar y consultar son O(1); desperdicia memoria si el espacio es grande y vacío.
- **Tamaño de celda**: parámetro crítico de la rejilla. Clave: idealmente, del orden del objeto medio o del radio de consulta.
- **Hashing espacial**: rejilla infinita donde la celda se calcula por hash. Clave: sin límites de mundo y sin memoria para lo vacío.
- **Colisión de hash**: dos celdas distintas caen en el mismo cubo. Clave: hay que comprobar la posición real, no fiarse del cubo.
- **Quadtree**: árbol donde cada nodo se divide en 4 (2D). Clave: se adapta a la densidad.
- **Octree**: equivalente en 3D, con 8 hijos. Clave: mismo principio, más memoria.
- **Subdivisión adaptativa**: dividir solo donde hay objetos. Clave: es la ventaja de los árboles frente a la rejilla.
- **BVH (bounding volume hierarchy)**: árbol de volúmenes envolventes anidados. Clave: la mejor para rayos y geometría estática.
- **AABB**: caja alineada a los ejes. Clave: el volumen envolvente más barato de probar.
- **SAH (surface area heuristic)**: criterio para construir un BVH de calidad. Clave: construcción más lenta, consultas más rápidas.
- **Refit**: actualizar los volúmenes de un BVH sin cambiar su topología. Clave: barato; se degrada si los objetos se mueven mucho.
- **Reconstrucción**: rehacer la estructura desde cero. Clave: cara, pero a veces es lo más rápido con muchos objetos móviles.
- **Consulta de radio**: qué hay a menos de R. Clave: la más usada en IA y audio.
- **Consulta de rayo (raycast)**: primer objeto que corta un rayo. Clave: disparos, línea de visión, selección con ratón.
- **Frustum culling**: descartar lo que no ve la cámara. Clave: aplicación directa en render.

## 🧰 Herramientas y preparación

Godot 4.x. Trabajaremos en `res://espacial/`. Godot ya trae estructuras espaciales en sus servidores de física y render, pero implementarlas es lo que te permite elegirlas con criterio y construirlas cuando el motor no cubra tu caso (por ejemplo, percepción de IA con miles de agentes). Ten a mano la clase [247](../../parte-14-optimizacion-profiling-y-rendimiento/247-optimizacion-de-fisicas-y-colisiones/README.md) y la [248](../../parte-14-optimizacion-profiling-y-rendimiento/248-culling-lod-y-streaming-de-mundo/README.md).

## 🧪 Laboratorio guiado

1. **El coste de no tener estructura:**

```text
Consultas de "¿quién está a menos de R?" para TODAS las entidades:

  n        fuerza bruta (n²/2)     rejilla (≈ n × k)    factor
  100            5.000                    ~900            5×
  500          125.000                  ~4.500           28×
 2.000        2.000.000                 ~18.000          111×
10.000       50.000.000                 ~90.000          555×

A 16 ms de presupuesto y ~2 ns por comprobación:
  2.000 entidades por fuerza bruta = 4 ms  (un cuarto del frame, solo en esto)
 10.000 entidades por fuerza bruta = 100 ms (imposible)
```

El punto de inflexión práctico está alrededor de **200-500 objetos**. Por debajo, la fuerza bruta gana por simplicidad y por caché.

2. **La rejilla uniforme.** La primera que hay que probar, casi siempre:

```gdscript
class_name RejillaUniforme
extends RefCounted

var _celdas := {}                  # Vector2i -> PackedInt32Array de ids
var _tamano_celda := 64.0
var _pos_x := PackedFloat32Array()
var _pos_y := PackedFloat32Array()
var _celda_de := {}                # id -> Vector2i (para mover sin buscar)

func _init(tamano_celda: float) -> void:
	_tamano_celda = tamano_celda

func _celda(x: float, y: float) -> Vector2i:
	# floor, no int(): con coordenadas negativas, int() trunca hacia cero y
	# mete en la misma celda puntos que están en celdas distintas.
	return Vector2i(int(floor(x / _tamano_celda)), int(floor(y / _tamano_celda)))

func insertar(id: int, x: float, y: float) -> void:
	var c := _celda(x, y)
	var lista: PackedInt32Array = _celdas.get(c, PackedInt32Array())
	lista.append(id)
	_celdas[c] = lista
	_celda_de[id] = c

func mover(id: int, x: float, y: float) -> void:
	var nueva := _celda(x, y)
	var vieja: Vector2i = _celda_de.get(id, nueva)
	if nueva == vieja:
		return                     # el 90 % de los movimientos NO cambian de celda
	_quitar_de(vieja, id)
	insertar(id, x, y)

func consultar_radio(x: float, y: float, r: float) -> PackedInt32Array:
	var salida := PackedInt32Array()
	# Solo las celdas que el círculo toca.
	var min_c := _celda(x - r, y - r)
	var max_c := _celda(x + r, y + r)
	var r2 := r * r
	for cy in range(min_c.y, max_c.y + 1):
		for cx in range(min_c.x, max_c.x + 1):
			var lista: PackedInt32Array = _celdas.get(Vector2i(cx, cy), PackedInt32Array())
			for id in lista:
				# Comprobación EXACTA: la celda es una aproximación, no el
				# resultado. Sin esto se devuelven objetos de las esquinas.
				var dx := _pos_x[id] - x
				var dy := _pos_y[id] - y
				if dx * dx + dy * dy <= r2:
					salida.append(id)
	return salida
```

**El tamaño de celda es el parámetro que decide todo:**

```text
Celda demasiado pequeña:  muchas celdas vacías, muchas que recorrer por consulta
Celda demasiado grande:   pocas celdas, muchos objetos por celda → casi fuerza bruta
Celda ≈ radio de consulta: se tocan ~4 celdas (2D) o ~8 (3D). Es el punto dulce.
```

3. **Hashing espacial.** Rejilla infinita sin reservar el vacío:

```gdscript
class_name HashEspacial
extends RefCounted

const P1 := 73856093
const P2 := 19349663
const P3 := 83492791

var _cubos := {}
var _n_cubos := 4096
var _tamano_celda := 64.0

func _hash(cx: int, cy: int, cz: int) -> int:
	# Hash clásico de coordenadas de celda (Teschner et al.). Permite un mundo
	# ILIMITADO sin reservar memoria para las regiones vacías.
	return int(abs((cx * P1) ^ (cy * P2) ^ (cz * P3))) % _n_cubos

func insertar(id: int, pos: Vector3) -> void:
	var c := _coord(pos)
	var h := _hash(c.x, c.y, c.z)
	var lista: PackedInt32Array = _cubos.get(h, PackedInt32Array())
	lista.append(id)
	_cubos[h] = lista

func consultar_radio(pos: Vector3, r: float) -> PackedInt32Array:
	var salida := PackedInt32Array()
	var vistos := {}
	var cmin := _coord(pos - Vector3.ONE * r)
	var cmax := _coord(pos + Vector3.ONE * r)
	var r2 := r * r
	for z in range(cmin.z, cmax.z + 1):
		for y in range(cmin.y, cmax.y + 1):
			for x in range(cmin.x, cmax.x + 1):
				for id in _cubos.get(_hash(x, y, z), PackedInt32Array()):
					# COLISIÓN DE HASH: dos celdas lejanas pueden caer en el
					# mismo cubo. Hay que comprobar la posición real Y evitar
					# duplicados, porque un id puede aparecer por dos cubos.
					if vistos.has(id):
						continue
					vistos[id] = true
					if _posiciones[id].distance_squared_to(pos) <= r2:
						salida.append(id)
	return salida
```

4. **Quadtree.** Cuando la distribución es muy desigual:

```gdscript
class_name Quadtree
extends RefCounted

const MAX_OBJETOS := 8
const MAX_PROFUNDIDAD := 8

var limites: Rect2
var profundidad := 0
var _objetos: Array[int] = []
var _hijos: Array = []            # 4 cuadrantes, o vacío si es hoja

func insertar(id: int, pos: Vector2) -> bool:
	if not limites.has_point(pos):
		return false
	if _hijos.is_empty():
		_objetos.append(id)
		# Se subdivide SOLO cuando hace falta: esa es la ventaja frente a la
		# rejilla, que reserva celdas aunque estén vacías.
		if _objetos.size() > MAX_OBJETOS and profundidad < MAX_PROFUNDIDAD:
			_subdividir()
		return true
	for h in _hijos:
		if h.insertar(id, pos):
			return true
	return false

func _subdividir() -> void:
	var m := limites.size * 0.5
	for i in 4:
		var q := Quadtree.new()
		q.limites = Rect2(limites.position + Vector2(m.x * (i % 2), m.y * (i / 2)), m)
		q.profundidad = profundidad + 1
		_hijos.append(q)
	# Reubicar lo que ya había: los objetos bajan a los hijos.
	for id in _objetos:
		for h in _hijos:
			if h.insertar(id, _pos[id]):
				break
	_objetos.clear()

func consultar_caja(caja: Rect2, salida: Array[int]) -> void:
	if not limites.intersects(caja):
		return                     # descarte de una rama entera: la ganancia
	if _hijos.is_empty():
		for id in _objetos:
			if caja.has_point(_pos[id]):
				salida.append(id)
		return
	for h in _hijos:
		h.consultar_caja(caja, salida)
```

5. **BVH.** La estructura de referencia para rayos y geometría estática:

```gdscript
class_name BVH
extends RefCounted

class Nodo extends RefCounted:
	var caja: AABB
	var izq: Nodo = null
	var der: Nodo = null
	var objetos: PackedInt32Array = PackedInt32Array()
	func es_hoja() -> bool: return izq == null

var raiz: Nodo = null
var _cajas: Array[AABB] = []

func construir(cajas: Array[AABB]) -> void:
	_cajas = cajas
	var ids := PackedInt32Array(range(cajas.size()))
	raiz = _construir(ids)

func _construir(ids: PackedInt32Array) -> Nodo:
	var n := Nodo.new()
	n.caja = _envolvente(ids)
	if ids.size() <= 4:
		n.objetos = ids
		return n

	# Partir por el eje MÁS LARGO de la envolvente: es la heurística simple
	# que da resultados razonables. SAH da mejores árboles y cuesta más
	# construirlos: merece la pena si el árbol es estático.
	var t := n.caja.size
	var eje := 0
	if t.y > t.x: eje = 1
	if t.z > t[eje]: eje = 2
	var orden := Array(ids)
	orden.sort_custom(func(a, b): return _centro(a)[eje] < _centro(b)[eje])
	var mitad := orden.size() / 2
	n.izq = _construir(PackedInt32Array(orden.slice(0, mitad)))
	n.der = _construir(PackedInt32Array(orden.slice(mitad)))
	return n

func raycast(origen: Vector3, dir: Vector3, max_dist: float) -> Dictionary:
	var mejor := {"id": -1, "dist": max_dist}
	_raycast(raiz, origen, dir, mejor)
	return mejor

func _raycast(n: Nodo, o: Vector3, d: Vector3, mejor: Dictionary) -> void:
	if n == null or n.caja.intersects_ray(o, d) == null:
		return
	if n.es_hoja():
		for id in n.objetos:
			var t := _interseccion_exacta(id, o, d)
			if t >= 0.0 and t < float(mejor["dist"]):
				mejor["id"] = id
				mejor["dist"] = t
		return
	# Visitar primero el hijo más cercano: si acierta, el otro se descarta
	# entero por distancia. Es la optimización que hace rápido un BVH.
	var d_izq := _dist_a_caja(n.izq, o)
	var d_der := _dist_a_caja(n.der, o)
	if d_izq < d_der:
		_raycast(n.izq, o, d, mejor)
		if d_der < float(mejor["dist"]): _raycast(n.der, o, d, mejor)
	else:
		_raycast(n.der, o, d, mejor)
		if d_izq < float(mejor["dist"]): _raycast(n.izq, o, d, mejor)
```

6. **La tabla de decisión.** El resultado práctico de la clase:

| Estructura | Insertar | Consulta radio | Raycast | Objetos móviles | Distribución desigual | Memoria |
|---|---|---|---|---|---|---|
| Fuerza bruta | O(1) | O(n) | O(n) | ✅ ideal | ✅ indiferente | Mínima |
| Rejilla uniforme | O(1) | **O(k)** | Regular | ✅ **muy buena** | ❌ mala | Alta si hay vacío |
| Hashing espacial | O(1) | O(k) | Regular | ✅ muy buena | ✅ buena | **Baja** |
| Quadtree/Octree | O(log n) | O(log n + k) | Buena | ⚠️ regular | ✅ **muy buena** | Media |
| BVH | O(n log n) | Buena | ✅ **la mejor** | ❌ mala (refit) | ✅ muy buena | Media |

**Cómo elegir, en tres preguntas:**

```text
¿Menos de ~300 objetos?               → fuerza bruta (y no te compliques)
¿Se mueven casi todos cada frame?     → rejilla o hashing espacial
¿Distribución muy desigual?           → quadtree/octree o hashing
¿La consulta principal es un rayo?    → BVH
¿Geometría estática (nivel, terreno)? → BVH construido una vez con SAH
```

7. **Objetos en movimiento.** Lo que decide la estructura más veces:

```gdscript
# ✅ Rejilla: mover es barato y solo cuesta si cambia de celda.
func actualizar_todos(delta: float) -> void:
	for id in _n:
		_pos_x[id] += _vel_x[id] * delta
		_pos_y[id] += _vel_y[id] * delta
		_rejilla.mover(id, _pos_x[id], _pos_y[id])    # O(1), y casi siempre nada

# ⚠️ BVH: mover degrada el árbol. Dos estrategias, según cuánto se mueva.
func actualizar_bvh(delta: float) -> void:
	_frames_desde_reconstruccion += 1
	# Refit: actualiza las cajas de abajo arriba sin cambiar la topología.
	# Barato, pero las cajas se solapan cada vez más y las consultas empeoran.
	_bvh.refit()
	# Cuando la calidad cae por debajo del umbral, se reconstruye entero.
	if _bvh.calidad() < 0.6 or _frames_desde_reconstruccion > 120:
		_bvh.construir(_cajas_actuales())
		_frames_desde_reconstruccion = 0
```

Patrón habitual en motores: **dos estructuras**. Un BVH para la geometría estática (nivel, terreno, edificios), construido una vez con SAH, y una rejilla o hashing para las entidades móviles. Las consultas van a las dos y se combinan.

8. **Aplicarlo más allá de las colisiones:**

```gdscript
# Percepción de IA: cada agente pregunta quién tiene cerca. Con 1.000 agentes
# es exactamente el caso O(n²) que la rejilla resuelve.
func percepcion(agente: int) -> PackedInt32Array:
	return _rejilla.consultar_radio(_pos_x[agente], _pos_y[agente], RADIO_VISION)

# Culling de render: qué objetos ve la cámara.
func visibles(frustum: Array[Plane]) -> PackedInt32Array:
	return _bvh.consultar_frustum(frustum)      # descarta ramas enteras

# Audio: qué fuentes están dentro del alcance del oyente.
func fuentes_audibles(oyente: Vector3) -> PackedInt32Array:
	return _hash.consultar_radio(oyente, ALCANCE_MAX)
```

9. **Medirlo.** La única forma de elegir bien:

```gdscript
extends SceneTree   # espacial/benchmark.gd

const N := 5000
const CONSULTAS := 2000

func _init() -> void:
	for distribucion in ["uniforme", "agrupada", "lineal"]:
		print("\n== %d objetos, distribución %s, %d consultas ==" % [N, distribucion, CONSULTAS])
		var pos := _generar(distribucion, N)
		for nombre in ["fuerza_bruta", "rejilla", "hash", "quadtree", "bvh"]:
			var e := _construir(nombre, pos)
			var t_c := _medir(func(): _construir(nombre, pos))
			var t_q := _medir(func():
				for i in CONSULTAS:
					e.consultar_radio(pos[i % N], 50.0))
			# CORRECCIÓN antes que velocidad: una estructura rápida que
			# devuelve resultados distintos a la fuerza bruta no sirve.
			var ok := _mismos_resultados(e, pos)
			print("  %-14s construir %6.2f ms · consultar %6.2f ms · %s"
				% [nombre, t_c, t_q, "OK" if ok else "RESULTADOS DISTINTOS"])
	quit()
```

## ✍️ Ejercicios

1. Ejecuta el benchmark con las tres distribuciones y anota qué gana en cada una.
2. Encuentra el tamaño de celda óptimo de la rejilla variándolo y midiendo.
3. Implementa la consulta de frustum en el quadtree y úsala para culling.
4. Mide a partir de cuántos objetos la rejilla supera a la fuerza bruta en tu máquina.
5. Implementa refit en el BVH y mide cómo se degrada tras 100, 500 y 1.000 frames de movimiento.
6. Combina BVH estático y rejilla dinámica y comprueba que la unión da el resultado correcto.
7. Aplica la estructura a la percepción de 1.000 agentes de IA y mide antes y después.

## 📝 Reto verificable

Implementa las cinco estructuras (fuerza bruta, rejilla uniforme, hashing espacial, quadtree, BVH) con las tres consultas (radio, caja, rayo), inserción y movimiento, más un banco de pruebas que las compare sobre tres distribuciones distintas.

**Criterio de aceptación**: (a) las cinco estructuras devuelven **exactamente el mismo conjunto** de resultados que la fuerza bruta para 1.000 consultas aleatorias en cada distribución, comprobado como conjunto ordenado; (b) con 5.000 objetos uniformes, la rejilla es **al menos 20 veces** más rápida que la fuerza bruta en consultas de radio; (c) con distribución muy agrupada, el quadtree supera a la rejilla en consultas; (d) el BVH resuelve raycasts **al menos 10 veces** más rápido que la fuerza bruta; (e) mover 5.000 objetos y consultar sigue dando resultados correctos en rejilla y hashing; (f) el hashing espacial funciona con coordenadas negativas y con objetos a más de 10.000 unidades del origen; (g) el benchmark imprime tiempos de construcción y consulta por estructura y distribución.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La rejilla devuelve objetos que están lejos | Falta la comprobación exacta tras filtrar por celda. Añádela siempre. |
| Objetos en coordenadas negativas caen mal | Se usó `int()` en vez de `floor()`. `floor` trunca correctamente hacia abajo. |
| La estructura es más lenta que la fuerza bruta | Pocos objetos, o tamaño de celda mal elegido. Mide el punto de corte. |
| El hashing devuelve duplicados | Un id aparece por varios cubos. Lleva un conjunto de vistos. |
| El BVH se degrada con el tiempo | Refit sin reconstrucción. Mide la calidad y reconstruye cuando baje. |
| El quadtree se hace muy profundo | Muchos objetos en el mismo punto. Limita la profundidad máxima. |
| Consumo de memoria enorme con la rejilla | Mundo grande y disperso. Usa hashing espacial. |
| La estructura da resultados distintos a la fuerza bruta | Es un bug, no una aproximación. Compara siempre contra la referencia. |

## ❓ Preguntas frecuentes

**❓ ¿Cuál es la mejor?** No hay una: por eso la clase implementa cinco y las mide. Como punto de partida razonable: **rejilla uniforme** para entidades móviles con distribución más o menos regular, **BVH** para geometría estática y rayos, **hashing espacial** si el mundo es enorme o disperso. Y fuerza bruta hasta unos cientos de objetos.

**❓ ¿No las trae ya el motor?** Godot usa estructuras espaciales internamente en física y render, y para colisiones normales no necesitas nada. Las implementas cuando tienes un caso que el motor no cubre: percepción de miles de agentes, consultas de audio, lógica de juego a gran escala, o un sistema propio en compute shader.

**❓ ¿Qué tamaño de celda uso?** Empieza por el **radio de consulta más frecuente**: así cada consulta toca unas 4 celdas en 2D u 8 en 3D. Después ajústalo midiendo, porque depende de la densidad real de tus objetos.

**❓ ¿Y para mundos enormes?** Hashing espacial, que no reserva memoria para el vacío, o una estructura jerárquica por regiones — que es exactamente lo que hace el world partition de la [clase 344](../344-grandes-mundos-y-world-partition/README.md).

**❓ ¿Se pueden paralelizar las consultas?** Sí, y es un caso ideal de la [clase 341](../341-job-systems-y-task-graphs/README.md): las consultas de **lectura** no comparten estado, así que 1.000 agentes pueden consultar a la vez sin ninguna sincronización. Lo que no se paraleliza tan fácil es la **inserción**, que sí escribe.

## 🔗 Referencias

- Akenine-Möller, Haines & Hoffman — *Real-Time Rendering*, capítulo de estructuras espaciales: <https://www.realtimerendering.com/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Christer Ericson — *Real-Time Collision Detection*: <https://realtimecollisiondetection.net/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Teschner et al. — *Optimized Spatial Hashing for Collision Detection of Deformable Objects*: <https://matthias-research.github.io/pages/publications/tetraederCollision.pdf> · uso: respalda el Tema 3 «Hashing espacial»
- Godot Docs — `AABB` y `Rect2`: <https://docs.godotengine.org/en/4.3/classes/class_aabb.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — Física y detección de colisiones: <https://docs.godotengine.org/en/4.3/tutorials/physics/index.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Robert Nystrom — *Game Programming Patterns*, Spatial Partition: <https://gameprogrammingpatterns.com/spatial-partition.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 341 - Job Systems y Task Graphs](../341-job-systems-y-task-graphs/README.md)

## ➡️ Siguiente clase

[Clase 343 - Resource Management y streaming asíncrono](../343-resource-management-y-streaming-asincrono/README.md)
