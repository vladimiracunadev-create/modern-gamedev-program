# Clase 343 — Resource Management y streaming asíncrono

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Gregory, «Game Engine Architecture» (resource management) · Documentación de `ResourceLoader` de Godot 4*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir el sistema que decide **qué está cargado en cada momento**. Es el que hace posible que un mundo de 40 GB corra en una máquina con 8 GB de RAM, y el que separa una carga que congela el juego dos segundos de otra que ocurre mientras juegas sin que te enteres.

Vas a implementar el gestor de recursos completo: **contado de referencias** (para saber qué se puede liberar), **grafo de dependencias** (una escena necesita mallas que necesitan texturas), **carga asíncrona** en hilo aparte, **streaming** por proximidad, **caché con política de expulsión** y **hot reload** para desarrollo. Y la parte que la mayoría de tutoriales omite: qué hacer cuando el recurso **aún no está listo** y el juego ya lo necesita.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diseñar un gestor de recursos con identidad estable y contado de referencias.
2. Resolver grafos de dependencias y cargar en el orden correcto.
3. Implementar carga asíncrona sin bloquear el hilo principal.
4. Implementar streaming por proximidad con histéresis.
5. Implementar caché con política de expulsión y presupuesto de memoria.
6. Diseñar placeholders y niveles de detalle progresivos para lo que no está listo.
7. Implementar hot reload en desarrollo sin afectar a la build publicada.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Identidad del recurso | Sin id estable no hay caché ni referencias. |
| 2 | Contado de referencias | Es lo que permite liberar con seguridad. |
| 3 | Grafo de dependencias | Cargar una escena es cargar un subgrafo. |
| 4 | Carga asíncrona | La diferencia entre un tirón y nada. |
| 5 | Prioridad | Lo que se ve ahora antes que lo de dentro de un minuto. |
| 6 | Streaming por proximidad | Cargar lo cercano, liberar lo lejano. |
| 7 | Histéresis | Evita el ciclo de cargar y descargar en el borde. |
| 8 | Presupuesto y expulsión | La memoria es finita: hay que decidir qué sale. |
| 9 | Placeholders y LOD progresivo | Qué se enseña mientras no está lo bueno. |
| 10 | Hot reload | Multiplica la iteración en desarrollo. |

## 📖 Definiciones y características

- **Recurso**: dato cargable e identificable (textura, malla, sonido, escena). Clave: su id es estable y su contenido inmutable.
- **Identidad (resource id)**: ruta o hash que identifica el recurso. Clave: es la clave de la caché.
- **Contado de referencias**: número de usuarios activos de un recurso. Clave: liberar con contador > 0 produce fallos difíciles.
- **Handle**: referencia indirecta a un recurso, válida aunque no esté cargado. Clave: permite referirse a algo que aún no existe en memoria.
- **Grafo de dependencias**: relaciones "A necesita B". Clave: define el orden de carga y de liberación.
- **Carga síncrona**: bloquea hasta terminar. Clave: simple, y produce tirones.
- **Carga asíncrona**: ocurre en otro hilo mientras el juego sigue. Clave: es lo normal en producción.
- **Cola de prioridad**: orden de carga según urgencia. Clave: lo visible primero.
- **Streaming**: cargar y descargar según la posición del jugador. Clave: hace posibles mundos mayores que la memoria.
- **Radio de carga / descarga**: distancias que disparan cada operación. Clave: deben ser distintas, o hay ciclo.
- **Histéresis**: diferencia entre el umbral de entrada y el de salida. Clave: evita cargar y descargar en bucle en el borde.
- **Presupuesto de memoria**: tope de memoria para recursos. Clave: convierte "cabe o no cabe" en una decisión de diseño.
- **Política de expulsión**: criterio para liberar (LRU, por prioridad, por distancia). Clave: decide qué se pierde cuando falta sitio.
- **LRU (least recently used)**: expulsar lo menos usado recientemente. Clave: buena política general.
- **Placeholder**: recurso provisional mientras carga el real. Clave: evita huecos y objetos invisibles.
- **LOD progresivo**: cargar primero una versión baja y refinar. Clave: el jugador ve algo de inmediato.
- **Hot reload**: recargar un recurso modificado sin reiniciar. Clave: multiplica la velocidad de iteración.
- **Precarga (preload)**: cargar antes de necesitarlo. Clave: convierte una espera en nada.
- **Thrashing**: cargar y descargar lo mismo repetidamente. Clave: síntoma de presupuesto insuficiente o histéresis ausente.

## 🧰 Herramientas y preparación

Godot 4.x con [`ResourceLoader.load_threaded_request`](https://docs.godotengine.org/en/4.3/classes/class_resourceloader.html) y `load_threaded_get_status`, que es la API de carga asíncrona del motor. Trabajaremos en `res://recursos/`. Ten a mano la clase [251](../../parte-14-optimizacion-profiling-y-rendimiento/251-tiempos-de-carga-y-arranque/README.md) sobre tiempos de carga y la [248](../../parte-14-optimizacion-profiling-y-rendimiento/248-culling-lod-y-streaming-de-mundo/README.md) sobre streaming de mundo.

## 🧪 Laboratorio guiado

1. **El handle.** La pieza que permite referirse a lo que aún no existe:

```gdscript
class_name HandleRecurso
extends RefCounted

enum Estado { NO_CARGADO, EN_COLA, CARGANDO, LISTO, FALLIDO }

var id: String = ""
var estado: Estado = Estado.NO_CARGADO
var recurso: Resource = null
var referencias := 0
var ultimo_uso := 0
var bytes := 0
var prioridad := 0

func listo() -> bool:
	return estado == Estado.LISTO and recurso != null

func obtener_o(placeholder: Resource) -> Resource:
	# El juego NUNCA se queda sin algo que dibujar: si no está listo, se
	# devuelve el placeholder. Es lo que evita huecos y `null` por todas partes.
	return recurso if listo() else placeholder
```

2. **El gestor con contado de referencias:**

```gdscript
class_name GestorRecursos
extends RefCounted

signal cargado(id: String)
signal fallo_carga(id: String, motivo: String)
signal expulsado(id: String, bytes: int)

var presupuesto_bytes := 512 * 1024 * 1024      # 512 MB
var _handles := {}
var _bytes_usados := 0
var _reloj := 0

func adquirir(id: String, prioridad := 0) -> HandleRecurso:
	var h: HandleRecurso = _handles.get(id)
	if h == null:
		h = HandleRecurso.new()
		h.id = id
		_handles[id] = h
	h.referencias += 1
	h.ultimo_uso = _reloj
	h.prioridad = maxi(h.prioridad, prioridad)
	if h.estado == HandleRecurso.Estado.NO_CARGADO:
		_encolar(h)
	return h

func liberar(h: HandleRecurso) -> void:
	h.referencias -= 1
	if h.referencias < 0:
		push_error("liberado más veces de las que se adquirió: %s" % h.id)
		h.referencias = 0
	# NO se descarga al llegar a 0: se deja en caché por si vuelve a hacer
	# falta. Solo se expulsa cuando el presupuesto lo exige.

func tick(delta: float) -> void:
	_reloj += 1
	_avanzar_cargas()
	if _bytes_usados > presupuesto_bytes:
		_expulsar_hasta(presupuesto_bytes * 0.9)   # margen: evita expulsar cada frame
```

3. **La carga asíncrona.** Con el detalle que evita el tirón:

```gdscript
const MAX_CARGAS_SIMULTANEAS := 3

var _cola: Array[HandleRecurso] = []
var _en_curso: Array[HandleRecurso] = []

func _encolar(h: HandleRecurso) -> void:
	h.estado = HandleRecurso.Estado.EN_COLA
	_cola.append(h)
	# Orden estable por prioridad: lo visible antes que lo lejano, y a
	# igualdad, por id, para que el orden sea reproducible.
	_cola.sort_custom(func(a, b):
		if a.prioridad != b.prioridad: return a.prioridad > b.prioridad
		return a.id < b.id)

func _avanzar_cargas() -> void:
	# Lanzar las que quepan.
	while _en_curso.size() < MAX_CARGAS_SIMULTANEAS and not _cola.is_empty():
		var h: HandleRecurso = _cola.pop_front()
		var err := ResourceLoader.load_threaded_request(h.id)
		if err != OK:
			h.estado = HandleRecurso.Estado.FALLIDO
			fallo_carga.emit(h.id, "no se pudo iniciar la carga (%d)" % err)
			continue
		h.estado = HandleRecurso.Estado.CARGANDO
		_en_curso.append(h)

	# Comprobar las que están en vuelo. Se consulta el ESTADO; no se espera.
	for h in _en_curso.duplicate():
		var progreso := []
		match ResourceLoader.load_threaded_get_status(h.id, progreso):
			ResourceLoader.THREAD_LOAD_LOADED:
				h.recurso = ResourceLoader.load_threaded_get(h.id)
				h.estado = HandleRecurso.Estado.LISTO
				h.bytes = _estimar_bytes(h.recurso)
				_bytes_usados += h.bytes
				_en_curso.erase(h)
				cargado.emit(h.id)
			ResourceLoader.THREAD_LOAD_FAILED:
				h.estado = HandleRecurso.Estado.FALLIDO
				_en_curso.erase(h)
				fallo_carga.emit(h.id, "la carga falló")
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				h.estado = HandleRecurso.Estado.FALLIDO
				_en_curso.erase(h)
				fallo_carga.emit(h.id, "recurso inválido o inexistente")
			_:
				h.progreso = float(progreso[0]) if not progreso.is_empty() else 0.0
```

Un aviso que ahorra horas: **cargar en un hilo no es gratis en el hilo principal**. En Godot, la carga se hace en paralelo pero la *integración* del recurso (subir texturas a la GPU, instanciar) toca el hilo principal. Por eso se limita el número de cargas simultáneas: cinco texturas grandes terminando en el mismo frame producen el tirón que querías evitar.

4. **El grafo de dependencias:**

```gdscript
class_name GrafoRecursos
extends RefCounted

var _dependencias := {}          # id -> [ids de los que depende]

func registrar(id: String, depende_de: Array[String]) -> void:
	_dependencias[id] = depende_de

func orden_de_carga(raiz: String) -> Array[String]:
	"""Devuelve los ids en orden: primero las hojas, luego lo que las usa."""
	var visitados := {}
	var orden: Array[String] = []
	var visitar := func(id: String, self_ref: Callable) -> void:
		if visitados.has(id):
			return
		visitados[id] = true
		for dep in _dependencias.get(id, []):
			self_ref.call(dep, self_ref)
		orden.append(id)           # el propio, DESPUÉS de sus dependencias
	visitar.call(raiz, visitar)
	return orden

func puede_liberar(id: String, referencias: Dictionary) -> bool:
	# Un recurso no se libera si alguien que sí está cargado lo necesita,
	# aunque su propio contador esté a cero.
	for otro in _dependencias:
		if _dependencias[otro].has(id) and int(referencias.get(otro, 0)) > 0:
			return false
	return true
```

5. **El streaming por proximidad, con histéresis.** El detalle que evita el thrashing:

```gdscript
class_name StreamingProximidad
extends RefCounted

# DOS radios distintos. Con uno solo, un jugador quieto en el borde carga y
# descarga la misma región cada frame: el disco se satura y el juego da
# tirones sin motivo aparente.
var radio_carga := 200.0
var radio_descarga := 280.0        # 40 % mayor: la histéresis

var _regiones := {}                # Vector2i -> {ids, cargada}
var _tamano_region := 128.0

func actualizar(pos: Vector2, gestor: GestorRecursos) -> Dictionary:
	var cargadas := 0
	var liberadas := 0
	var centro := _region_de(pos)
	var alcance := int(ceil(radio_descarga / _tamano_region))

	for ry in range(centro.y - alcance, centro.y + alcance + 1):
		for rx in range(centro.x - alcance, centro.x + alcance + 1):
			var r := Vector2i(rx, ry)
			if not _regiones.has(r):
				continue
			var d := _distancia_a_region(pos, r)
			var info: Dictionary = _regiones[r]

			if d <= radio_carga and not info["cargada"]:
				# Prioridad inversa a la distancia: lo más cerca, primero.
				var prio := int(1000.0 - d)
				for id in info["ids"]:
					gestor.adquirir(id, prio)
				info["cargada"] = true
				cargadas += 1
			elif d > radio_descarga and info["cargada"]:
				for id in info["ids"]:
					gestor.liberar(gestor.handle(id))
				info["cargada"] = false
				liberadas += 1

	return {"cargadas": cargadas, "liberadas": liberadas}
```

6. **Presupuesto y expulsión:**

```gdscript
func _expulsar_hasta(objetivo_bytes: int) -> void:
	# Solo se puede expulsar lo que NADIE usa y de lo que NADIE depende.
	var candidatos := _handles.values().filter(func(h):
		return h.listo() and h.referencias == 0 and _grafo.puede_liberar(h.id, _referencias()))

	# LRU con prioridad: primero lo menos importante y menos usado.
	candidatos.sort_custom(func(a, b):
		if a.prioridad != b.prioridad: return a.prioridad < b.prioridad
		return a.ultimo_uso < b.ultimo_uso)

	for h in candidatos:
		if _bytes_usados <= objetivo_bytes:
			break
		_bytes_usados -= h.bytes
		expulsado.emit(h.id, h.bytes)
		h.recurso = null
		h.estado = HandleRecurso.Estado.NO_CARGADO
		h.bytes = 0

	if _bytes_usados > objetivo_bytes:
		# No se pudo bajar del objetivo: todo lo que queda está EN USO. Es un
		# problema de diseño (el presupuesto no da para el peor caso), y hay
		# que enterarse ahora, no cuando el sistema operativo mate el proceso.
		push_warning("presupuesto de recursos superado con todo en uso: %.1f MB"
			% (_bytes_usados / 1048576.0))
```

7. **Placeholders y LOD progresivo.** Qué se ve mientras no está lo bueno:

```gdscript
class_name RecursoProgresivo
extends RefCounted

# Tres niveles: uno diminuto que viene con el juego (siempre disponible), uno
# medio y el completo. El jugador ve algo desde el primer frame.
var _niveles := ["_lod2.ctex", "_lod1.ctex", ".ctex"]
var _handles: Array[HandleRecurso] = []
var _nivel_actual := -1

func solicitar(base: String, gestor: GestorRecursos, distancia: float) -> void:
	var deseado := 0 if distancia > 100.0 else (1 if distancia > 30.0 else 2)
	for i in range(deseado + 1):
		if i >= _handles.size():
			_handles.append(gestor.adquirir(base + _niveles[i], 100 - i * 10))

func mejor_disponible(placeholder: Texture2D) -> Texture2D:
	# Se devuelve el mejor nivel YA cargado, no se espera al deseado. La
	# textura mejora sola cuando termina de cargar la siguiente.
	for i in range(_handles.size() - 1, -1, -1):
		if _handles[i].listo():
			return _handles[i].recurso
	return placeholder
```

8. **Hot reload.** Solo en desarrollo, y multiplica la iteración:

```gdscript
class_name RecargaEnCaliente
extends Node

var _mtimes := {}
var _gestor: GestorRecursos

func _ready() -> void:
	# Solo en debug: en release no existe, ni gasta, ni introduce riesgo.
	set_process(OS.is_debug_build())

func _process(_d: float) -> void:
	_t += get_process_delta_time()
	if _t < 0.5:                   # comprobar 2 veces por segundo basta
		return
	_t = 0.0
	for id in _gestor.ids_cargados():
		var ruta := ProjectSettings.globalize_path(id)
		if not FileAccess.file_exists(ruta):
			continue
		var m := FileAccess.get_modified_time(ruta)
		if _mtimes.get(id, m) != m:
			_gestor.recargar(id)
			print("Recargado: %s" % id)
		_mtimes[id] = m
```

9. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	var g := GestorRecursos.new()
	g.presupuesto_bytes = 10 * 1024 * 1024

	# Contado de referencias.
	var h1 := g.adquirir("res://test/a.ctex")
	var h2 := g.adquirir("res://test/a.ctex")
	check.call(h1 == h2, "el mismo id devuelve el mismo handle")
	check.call(h1.referencias == 2, "el contador cuenta ambas adquisiciones")
	g.liberar(h1)
	check.call(h1.referencias == 1, "liberar decrementa")
	check.call(h1.listo() or h1.estado != HandleRecurso.Estado.NO_CARGADO,
		"con referencias vivas no se descarga")

	# Orden de dependencias.
	var gr := GrafoRecursos.new()
	gr.registrar("escena", ["malla", "material"])
	gr.registrar("material", ["textura"])
	var orden := gr.orden_de_carga("escena")
	check.call(orden.find("textura") < orden.find("material"), "la textura antes que el material")
	check.call(orden.find("material") < orden.find("escena"), "el material antes que la escena")

	# Histéresis: un jugador quieto en el borde no produce thrashing.
	var s := StreamingProximidad.new()
	s.radio_carga = 100.0; s.radio_descarga = 140.0
	var cambios := 0
	for i in 100:
		# Oscilación pequeña alrededor del borde de carga.
		var r := s.actualizar(Vector2(105.0 + sin(i) * 3.0, 0), g)
		cambios += int(r["cargadas"]) + int(r["liberadas"])
	check.call(cambios <= 2, "la histéresis evita el thrashing (hubo %d cambios)" % cambios)

	# Expulsión: lo que no se usa sale, lo que se usa no.
	var usado := g.adquirir("res://test/en_uso.ctex")
	for i in 50:
		g.liberar(g.adquirir("res://test/relleno_%d.ctex" % i))
	g.tick(0.016)
	check.call(usado.referencias == 1 and usado.estado != HandleRecurso.Estado.NO_CARGADO,
		"no se expulsa un recurso en uso")
	check.call(g.bytes_usados() <= g.presupuesto_bytes, "se respeta el presupuesto")

	# Placeholder: nunca se devuelve null.
	var p := HandleRecurso.new()
	check.call(p.obtener_o(_placeholder) == _placeholder,
		"un recurso no cargado devuelve el placeholder, no null")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

## ✍️ Ejercicios

1. Implementa el gestor y mide el tiempo de carga síncrona frente a asíncrona de 50 texturas.
2. Encuentra el valor de `MAX_CARGAS_SIMULTANEAS` que minimiza el tirón en tu máquina.
3. Añade una barra de progreso real usando el progreso de `load_threaded_get_status`.
4. Ajusta los radios de carga y descarga hasta eliminar el thrashing con un jugador oscilando.
5. Implementa LOD progresivo de texturas y comprueba que se ve algo desde el primer frame.
6. Añade telemetría: aciertos de caché, expulsiones y bytes en uso a lo largo del tiempo.
7. Implementa hot reload y mide cuánto tiempo de iteración ahorra en una sesión real.

## 📝 Reto verificable

Implementa el gestor de recursos completo: handles con contado de referencias, grafo de dependencias con orden de carga, cola de prioridad, carga asíncrona limitada, streaming por proximidad con histéresis, presupuesto de memoria con expulsión LRU y prioridad, placeholders, LOD progresivo y hot reload solo en debug.

**Criterio de aceptación**: una prueba headless con **al menos 18 aserciones** demuestra que: (a) adquirir el mismo id dos veces devuelve el mismo handle y el contador refleja ambas; (b) liberar más veces de las adquiridas se detecta y registra; (c) el orden de carga respeta el grafo completo de dependencias; (d) un recurso con referencias vivas **nunca** se expulsa, aunque se supere el presupuesto; (e) un recurso del que otro cargado depende no se expulsa aunque su propio contador sea 0; (f) con un jugador oscilando en el borde durante 100 pasos, la histéresis produce **2 cambios o menos** de estado de región; (g) el presupuesto se respeta tras 100 adquisiciones y liberaciones; (h) un handle no cargado devuelve el placeholder y nunca `null`; (i) el hot reload no está activo en una build de release.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El juego se congela al entrar en una zona | Carga síncrona. Asíncrona con prioridad y placeholders. |
| Tirón aunque la carga sea asíncrona | Varios recursos integrándose el mismo frame. Limita las cargas simultáneas. |
| El disco no para en el borde de una región | Falta histéresis. Radio de descarga mayor que el de carga. |
| "Attempt to call function on a null instance" | Se usó el recurso antes de estar listo. Placeholder y comprobación de estado. |
| La memoria crece hasta que el sistema mata el proceso | Sin presupuesto ni expulsión. Añade ambos. |
| Se expulsa algo que se está usando | Contado de referencias mal llevado, o falta comprobar dependencias. |
| Una textura aparece sin su material | Orden de carga incorrecto. Resuelve el grafo antes de cargar. |
| Recargar en caliente rompe la build publicada | El hot reload está activo en release. `OS.is_debug_build()`. |
| La barra de progreso salta de 0 a 100 | No se consulta el progreso real. Usa el array de `load_threaded_get_status`. |

## ❓ Preguntas frecuentes

**❓ ¿Godot no gestiona esto ya?** `ResourceLoader` cachea y `Resource` cuenta referencias, así que para juegos medianos no necesitas nada más. Este sistema hace falta cuando quieres **control**: prioridades, presupuesto de memoria, streaming por proximidad, LOD progresivo y expulsión con criterio propio. Es decir, en mundos grandes o en plataformas con memoria ajustada.

**❓ ¿Cuántas cargas simultáneas?** Entre 2 y 4 suele ser el punto dulce. Más satura el disco y provoca que varias terminen en el mismo frame, que es exactamente el tirón que evitas. Mídelo en el dispositivo objetivo: en un móvil con almacenamiento lento, el número óptimo es menor.

**❓ ¿Por qué no descargar en cuanto el contador llega a cero?** Porque el jugador entra y sale de zonas constantemente: descargar de inmediato garantiza recargar en cinco segundos. Dejarlo en caché y expulsar solo bajo presión de memoria es lo que hace que el patrón funcione.

**❓ ¿Y si nunca se libera lo suficiente?** Entonces el presupuesto no da para el peor caso, y eso es un problema de diseño de contenido, no de código. El aviso del paso 6 existe para que te enteres en desarrollo: la respuesta es reducir la resolución de los assets, dividir mejor las regiones o subir el requisito mínimo del juego — pero conscientemente.

**❓ ¿Merece la pena el LOD progresivo?** En mundos grandes, mucho: la diferencia entre ver un mundo borroso que se afina en dos segundos y ver un mundo vacío que aparece de golpe. Es también lo que permite empezar a jugar antes de que todo esté cargado, que en un juego grande es la diferencia entre 5 y 30 segundos de espera.

## 🔗 Referencias

- Godot Docs — `ResourceLoader` y carga en hilo: <https://docs.godotengine.org/en/4.3/classes/class_resourceloader.html> · uso: se instala o se consulta en la preparación
- Godot Docs — Carga en segundo plano: <https://docs.godotengine.org/en/4.3/tutorials/io/background_loading.html> · uso: respalda el Tema 4 «Carga asíncrona»
- Jason Gregory — *Game Engine Architecture*, capítulo de gestión de recursos: <https://www.gameenginebook.com/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `Resource` y contado de referencias: <https://docs.godotengine.org/en/4.3/classes/class_resource.html> · uso: respalda el Tema 2 «Contado de referencias»
- Akenine-Möller et al. — *Real-Time Rendering*, capítulo de LOD y streaming: <https://www.realtimerendering.com/> · uso: respalda el Tema 6 «Streaming por proximidad»

## ⬅️ Clase anterior

[Clase 342 - Particionamiento espacial](../342-particionamiento-espacial/README.md)

## ➡️ Siguiente clase

[Clase 344 - Grandes mundos y world partition](../344-grandes-mundos-y-world-partition/README.md)
