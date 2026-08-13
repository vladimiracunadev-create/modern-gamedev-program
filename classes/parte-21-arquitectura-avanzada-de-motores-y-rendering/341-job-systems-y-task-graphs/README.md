# Clase 341 — Job Systems y Task Graphs

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Gregory, «Game Engine Architecture» (multithreading) · Documentación de `WorkerThreadPool` de Godot 4*
> ⏱️ Duración estimada: **125 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Aprovechar los núcleos que tu juego está desperdiciando. Una CPU moderna tiene 8, 12 o 16 núcleos; un juego mal paralelizado usa uno al 100 % y deja el resto parados. La [clase 250](../../parte-14-optimizacion-profiling-y-rendimiento/250-multithreading-y-trabajos-en-paralelo/README.md) introdujo el multithreading; esta clase enseña el modelo que los motores usan de verdad: **job systems** con **task graphs**.

La diferencia con "crear hilos" es fundamental. Crear un hilo cuesta cientos de microsegundos, así que no se crea uno por tarea: se crea un **pool de workers** una vez y se le envían **jobs** pequeños. Y como los jobs tienen dependencias entre sí (no puedes hacer culling antes de actualizar las transformadas), se organizan en un **grafo** que el sistema recorre respetando el orden.

Y la parte incómoda que la clase no va a esquivar: **el paralelismo introduce una familia de errores nueva** —carreras de datos, interbloqueos, no determinismo— que no aparecen en los tests y sí en la máquina de un jugador. La disciplina para evitarlos es tan importante como la técnica.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar por qué un pool de workers es mejor que crear hilos por tarea.
2. Diseñar la descomposición de un frame en jobs con sus dependencias.
3. Implementar un task graph y verificar que respeta el orden.
4. Identificar carreras de datos y evitarlas por diseño, no por sincronización.
5. Aplicar paralelismo de datos (`parallel for`) con particionado correcto.
6. Explicar work stealing y por qué mejora el balanceo.
7. Mantener el determinismo en un sistema paralelo, y saber cuándo es imposible.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Pool de workers | Crear hilos por tarea es más caro que la tarea. |
| 2 | Job | La unidad de trabajo: pequeña, sin estado compartido. |
| 3 | Task graph | Las dependencias son la mitad del problema. |
| 4 | Paralelismo de datos vs de tareas | Dos formas distintas de repartir. |
| 5 | Carrera de datos | El error característico, y no aparece en los tests. |
| 6 | Diseño sin compartir | La única defensa fiable. |
| 7 | Sincronización | Necesaria a veces, y siempre cara. |
| 8 | Falso compartido | El coste invisible de escribir cerca. |
| 9 | Work stealing | Balanceo automático cuando los jobs son desiguales. |
| 10 | Determinismo | Compatible con paralelismo, si se diseña. |

## 📖 Definiciones y características

- **Job (tarea)**: unidad de trabajo autocontenida que se ejecuta en un worker. Clave: cuanto menos comparta, mejor.
- **Job system**: infraestructura que reparte jobs entre workers. Clave: los hilos se crean una vez, al arrancar.
- **Worker**: hilo del pool que consume jobs. Clave: su número se ajusta a los núcleos disponibles.
- **Cola de jobs**: estructura de la que los workers toman trabajo. Clave: su contención es el cuello de botella del sistema.
- **Task graph**: grafo dirigido acíclico de jobs con dependencias. Clave: define qué puede ir en paralelo y qué no.
- **Dependencia**: relación "B no empieza hasta que A termina". Clave: es lo que hace correcto el paralelismo.
- **Barrera (fence)**: punto donde se espera a que termine un conjunto de jobs. Clave: sincroniza, y por eso serializa.
- **Paralelismo de datos**: el mismo trabajo sobre trozos distintos de datos. Clave: es el más fácil y el más rentable.
- **Paralelismo de tareas**: trabajos distintos a la vez. Clave: limitado por las dependencias.
- **Granularidad**: tamaño de cada job. Clave: demasiado pequeño y domina la sobrecarga; demasiado grande y no balancea.
- **Carrera de datos (data race)**: dos hilos acceden al mismo dato y al menos uno escribe, sin sincronización. Clave: comportamiento indefinido, y a veces funciona por casualidad.
- **Interbloqueo (deadlock)**: dos hilos se esperan mutuamente. Clave: se evita con orden fijo de adquisición.
- **Mutex**: exclusión mutua. Clave: correcto y caro; si aparece en un bucle caliente, el diseño está mal.
- **Atómico**: operación indivisible sin bloqueo. Clave: barato para contadores; no resuelve invariantes complejas.
- **Falso compartido (false sharing)**: dos hilos escriben en la misma línea de caché sin compartir datos. Clave: destroza el rendimiento sin ser un error lógico.
- **Work stealing**: un worker sin trabajo toma jobs de la cola de otro. Clave: balancea automáticamente jobs desiguales.
- **Determinismo paralelo**: mismo resultado independientemente del orden de ejecución. Clave: exige que los jobs no dependan del orden entre ellos.

## 🧰 Herramientas y preparación

Godot 4.x con [`WorkerThreadPool`](https://docs.godotengine.org/en/stable/classes/class_workerthreadpool.html), que es exactamente un job system: pool de workers, `add_task`, `add_group_task` y esperas por identificador. Trabajaremos en `res://jobs/`. Ten a mano la clase [250](../../parte-14-optimizacion-profiling-y-rendimiento/250-multithreading-y-trabajos-en-paralelo/README.md) y, sobre todo, la [308](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/308-commands-input-recording-y-replays/README.md): el determinismo que allí se exigía es lo que aquí hay que preservar.

## 🧪 Laboratorio guiado

1. **Por qué un pool y no hilos por tarea:**

```text
Crear y destruir un hilo:      ~50-500 µs
Enviar un job a un pool:       ~0,1-1 µs        ← 100-1000× menos
Trabajo típico de un job:      ~10-500 µs

Con 1.000 jobs por frame:
  hilos por tarea:  1.000 × 200 µs = 200 ms de PURA sobrecarga → imposible
  pool de workers:  1.000 × 0,5 µs = 0,5 ms                    → despreciable
```

2. **La descomposición del frame.** Lo primero es dibujar el grafo:

```text
                    ┌─────────────┐
                    │   INPUT     │  (secuencial: es un único evento)
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
    ┌──────────┐    ┌───────────┐    ┌───────────┐
    │ IA (×N)  │    │ Física    │    │ Animación │   ← en PARALELO: no comparten
    └────┬─────┘    │ (×M islas)│    │  (×K)     │
         │          └─────┬─────┘    └─────┬─────┘
         └────────────────┼────────────────┘
                          ▼
                   ┌─────────────┐
                   │  BARRERA    │  ← todo lo anterior debe haber terminado
                   └──────┬──────┘
                          ▼
                   ┌─────────────┐
                   │ Transformadas│
                   └──────┬──────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
      ┌───────────────┐      ┌───────────────┐
      │ Culling (×4)  │      │ Partículas    │  ← paralelo otra vez
      └───────┬───────┘      └───────┬───────┘
              └───────────┬───────────┘
                          ▼
                   ┌─────────────┐
                   │  RENDER     │  (secuencial: la API gráfica manda)
                   └─────────────┘
```

Dos observaciones que definen el diseño real: hay **partes que no se paralelizan** (entrada, envío a la API gráfica) y **las barreras cuestan**, porque todos los workers esperan al más lento.

3. **Paralelismo de datos.** El más rentable, y el más fácil:

```gdscript
class_name SistemaParalelo
extends RefCounted

# El caso ideal: el mismo trabajo sobre trozos distintos, SIN datos
# compartidos. Cada worker escribe en su propio rango del array de salida.
var _pos_x := PackedFloat32Array()
var _pos_y := PackedFloat32Array()
var _vel_x := PackedFloat32Array()
var _vel_y := PackedFloat32Array()
var _delta := 0.0

func avanzar_paralelo(delta: float) -> void:
	_delta = delta
	var n := _pos_x.size()
	# Granularidad: trozos de ~2000 elementos. Con trozos de 10, la sobrecarga
	# de repartir supera al trabajo; con uno solo, no hay paralelismo.
	var elementos_por_grupo := 2048
	var grupos := maxi(1, (n + elementos_por_grupo - 1) / elementos_por_grupo)

	var id := WorkerThreadPool.add_group_task(
		_trozo, grupos, -1, false, "avanzar_particulas")
	WorkerThreadPool.wait_for_group_task_completion(id)   # barrera

func _trozo(indice_grupo: int) -> void:
	var n := _pos_x.size()
	var por_grupo := 2048
	var ini := indice_grupo * por_grupo
	var fin := mini(ini + por_grupo, n)
	# Cada worker toca SOLO [ini, fin): no hay solapamiento, no hay carrera,
	# no hace falta ningún mutex.
	for i in range(ini, fin):
		_pos_x[i] += _vel_x[i] * _delta
		_pos_y[i] += _vel_y[i] * _delta
```

4. **El task graph.** Cuando las dependencias importan:

```gdscript
class_name GrafoDeTareas
extends RefCounted

class Nodo extends RefCounted:
	var nombre: String
	var trabajo: Callable
	var depende_de: Array[String] = []
	var id_tarea := -1
	var terminado := false

var _nodos := {}
var _orden: Array[String] = []

func agregar(nombre: String, trabajo: Callable, depende_de: Array[String] = []) -> void:
	var n := Nodo.new()
	n.nombre = nombre; n.trabajo = trabajo; n.depende_de = depende_de
	_nodos[nombre] = n

func validar() -> Array[String]:
	var errores: Array[String] = []
	for nombre in _nodos:
		for dep in _nodos[nombre].depende_de:
			if not _nodos.has(dep):
				errores.append("'%s' depende de '%s', que no existe" % [nombre, dep])
	errores.append_array(_ordenar_topologicamente())
	return errores

func _ordenar_topologicamente() -> Array[String]:
	# Kahn: si al terminar quedan nodos sin colocar, hay un ciclo. Un ciclo en
	# el grafo de tareas es un interbloqueo garantizado.
	var errores: Array[String] = []
	var entrada := {}
	for n in _nodos: entrada[n] = _nodos[n].depende_de.size()
	var listos := _nodos.keys().filter(func(n): return int(entrada[n]) == 0)
	listos.sort()                          # orden estable: mismo plan siempre
	_orden.clear()
	while not listos.is_empty():
		var n: String = listos.pop_front()
		_orden.append(n)
		for otro in _nodos:
			if _nodos[otro].depende_de.has(n):
				entrada[otro] = int(entrada[otro]) - 1
				if int(entrada[otro]) == 0:
					listos.append(otro)
					listos.sort()
	if _orden.size() != _nodos.size():
		errores.append("ciclo de dependencias en el grafo de tareas")
	return errores

func ejecutar() -> void:
	# Se ejecuta por NIVELES: todo lo que no depende de nada pendiente va en
	# paralelo; después se espera y se pasa al siguiente nivel.
	var pendientes := _orden.duplicate()
	while not pendientes.is_empty():
		var nivel: Array[String] = []
		for n in pendientes:
			var listo := true
			for dep in _nodos[n].depende_de:
				if not _nodos[dep].terminado:
					listo = false
			if listo:
				nivel.append(n)
		if nivel.is_empty():
			push_error("el grafo no avanza: revisa las dependencias")
			return
		var ids := []
		for n in nivel:
			ids.append(WorkerThreadPool.add_task(_nodos[n].trabajo, false, n))
		for id in ids:
			WorkerThreadPool.wait_for_task_completion(id)     # barrera del nivel
		for n in nivel:
			_nodos[n].terminado = true
			pendientes.erase(n)
```

```gdscript
func construir_frame() -> GrafoDeTareas:
	var g := GrafoDeTareas.new()
	g.agregar("ia", _job_ia)
	g.agregar("fisica", _job_fisica)
	g.agregar("animacion", _job_animacion)
	g.agregar("transformadas", _job_transformadas, ["ia", "fisica", "animacion"])
	g.agregar("culling", _job_culling, ["transformadas"])
	g.agregar("particulas", _job_particulas, ["transformadas"])
	g.agregar("render", _job_render, ["culling", "particulas"])
	assert(g.validar().is_empty(), "el grafo del frame no valida")
	return g
```

5. **Las carreras de datos.** El error característico, y la única defensa fiable:

```gdscript
# ❌ CARRERA: dos workers escriben el mismo contador. El resultado es
#    impredecible, y lo peor es que a veces sale bien y pasa los tests.
var _enemigos_vistos := 0

func _job_malo(i: int) -> void:
	if _visible(i):
		_enemigos_vistos += 1          # leer, sumar, escribir: NO es atómico
```

```gdscript
# ✅ SIN COMPARTIR: cada worker escribe en SU casilla. Se combina después,
#    en secuencial. Es la solución más rápida y la que no puede fallar.
var _por_worker := PackedInt32Array()

func _preparar(n_workers: int) -> void:
	_por_worker.resize(n_workers)
	_por_worker.fill(0)

func _job_bueno(indice_grupo: int) -> void:
	var local := 0                      # acumular en LOCAL, no en el array
	for i in _rango(indice_grupo):
		if _visible(i):
			local += 1
	_por_worker[indice_grupo] = local   # una sola escritura, en su casilla

func _combinar() -> int:
	var total := 0
	for v in _por_worker:
		total += v
	return total                        # secuencial, y cuesta microsegundos
```

El acumulador local no es un detalle de estilo: escribir directamente en `_por_worker[indice]` dentro del bucle provocaría **falso compartido** si dos índices caen en la misma línea de caché, y el rendimiento se hundiría sin ningún error visible.

6. **Falso compartido.** El coste invisible:

```text
Línea de caché de 64 bytes:
  [ contador_worker0 | contador_worker1 | ... | contador_worker15 ]
    (4 B cada uno → los 16 caben en UNA línea)

Worker 0 escribe su contador → invalida la línea en TODOS los demás núcleos
Worker 1 escribe el suyo     → invalida otra vez
...
Resultado: los núcleos se pelean por la misma línea. Puede ser MÁS LENTO que
la versión secuencial, sin que haya ninguna carrera ni ningún error lógico.

Soluciones: acumular en una variable local (la del paso 5), o separar cada
contador en su propia línea con relleno.
```

7. **Determinismo con paralelismo.** Compatible, si se diseña:

```gdscript
# ❌ NO determinista: el orden de finalización de los workers decide el
#    orden de la lista, y ese orden varía en cada ejecución.
var _resultados := []
func _job_no_det(i: int) -> void:
	_mutex.lock()
	_resultados.append(_calcular(i))    # el orden depende del scheduler
	_mutex.unlock()

# ✅ Determinista: cada worker escribe en SU índice. El orden del array final
#    es siempre el mismo, venga como venga la ejecución.
var _resultados_det := []
func _preparar(n: int) -> void:
	_resultados_det.resize(n)
func _job_det(i: int) -> void:
	_resultados_det[i] = _calcular(i)   # sin mutex y sin orden dependiente
```

| Operación | ¿Determinista en paralelo? | Cómo hacerlo |
|---|---|---|
| Transformar N elementos independientes | ✅ | Cada uno en su índice |
| Contar / sumar enteros | ✅ | Acumular por worker y combinar en orden fijo |
| Sumar **flotantes** | ⚠️ | El orden cambia el resultado; combina en orden fijo de índice |
| Recolectar en una lista | ❌ tal cual | Índice fijo por worker, o ordenar después |
| Modificar una estructura compartida | ❌ | Rediseñar: partición o fase secuencial |

Ese caso de los flotantes merece atención: `(a + b) + c` no es igual a `a + (b + c)` en coma flotante. Si el orden de combinación varía, el resultado varía en el último bit — y eso rompe un replay o desincroniza una partida en red ([clase 308](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/308-commands-input-recording-y-replays/README.md)).

8. **Granularidad y work stealing:**

```gdscript
func _granularidad_optima(n_elementos: int, coste_por_elemento_ns: float) -> int:
	# Regla práctica: cada job debe durar entre 50 y 500 µs. Menos, y la
	# sobrecarga de repartir domina; más, y el balanceo empeora (un worker
	# acaba mucho antes que otro y se queda parado).
	var objetivo_ns := 100000.0        # 100 µs
	var por_job := int(objetivo_ns / maxf(coste_por_elemento_ns, 0.001))
	return clampi(por_job, 64, maxi(64, n_elementos / WorkerThreadPool.get_thread_count()))
```

**Work stealing** resuelve el problema del desequilibrio: cada worker tiene su cola, y cuando la vacía, roba trabajo del final de la cola de otro. Con jobs de coste muy desigual (una IA compleja junto a diez triviales), la diferencia frente a un reparto fijo es grande. `WorkerThreadPool` de Godot ya balancea internamente; en un motor propio, es la técnica estándar.

9. **Probarlo.** Y con un detalle importante sobre cómo se prueban estas cosas:

```gdscript
extends SceneTree

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	# 1) CORRECCIÓN: paralelo y secuencial dan el mismo resultado.
	var s := SistemaParalelo.nuevo(100000)
	var esperado := s.avanzar_secuencial_copia(0.016)
	s.avanzar_paralelo(0.016)
	check.call(s.equivalente_a(esperado, 0.0001), "paralelo == secuencial")

	# 2) DETERMINISMO: 100 ejecuciones dan exactamente lo mismo. Una carrera
	#    aparece una de cada mil veces, así que una sola pasada no prueba nada.
	var primero := _ejecutar_y_hashear()
	var todos_iguales := true
	for i in 100:
		if _ejecutar_y_hashear() != primero:
			todos_iguales = false
	check.call(todos_iguales, "100 ejecuciones paralelas dan el mismo resultado")

	# 3) El grafo detecta ciclos.
	var g := GrafoDeTareas.new()
	g.agregar("a", func(): pass, ["b"])
	g.agregar("b", func(): pass, ["a"])
	check.call(not g.validar().is_empty(), "se detecta el ciclo en el grafo")

	# 4) El grafo respeta el orden.
	var orden := []
	var g2 := GrafoDeTareas.new()
	g2.agregar("primero", func(): orden.append("primero"))
	g2.agregar("segundo", func(): orden.append("segundo"), ["primero"])
	g2.ejecutar()
	check.call(orden == ["primero", "segundo"], "el grafo respeta las dependencias")

	# 5) ESCALADO: con más núcleos, más rápido. No lineal, pero sí notable.
	var t_sec := _medir(func(): s.avanzar_secuencial(0.016))
	var t_par := _medir(func(): s.avanzar_paralelo(0.016))
	check.call(t_par < t_sec * 0.6, "el paralelo mejora al menos un 40%% (%.2f vs %.2f ms)"
		% [t_par, t_sec])

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

## ✍️ Ejercicios

1. Dibuja el grafo de tareas del frame de tu juego con sus dependencias reales.
2. Paraleliza tu sistema con más entidades y mide el escalado con 1, 2, 4 y 8 workers.
3. Encuentra la granularidad óptima variando el tamaño de trozo y midiendo.
4. Provoca una carrera a propósito y comprueba que 1.000 ejecuciones la detectan (y 1, no).
5. Implementa el patrón de acumulador local y compáralo con escribir en el array compartido.
6. Añade un test de determinismo que ejecute 100 veces y compare hashes.
7. Identifica en tu proyecto una parte que **no** se puede paralelizar y explica por qué.

## 📝 Reto verificable

Implementa un job system sobre `WorkerThreadPool` con: paralelismo de datos con granularidad configurable, task graph con validación de ciclos y ejecución por niveles, patrón de acumulador local sin datos compartidos, y una batería de tests de corrección, determinismo y escalado.

**Criterio de aceptación**: una prueba headless con **al menos 15 aserciones** demuestra que: (a) la versión paralela produce **exactamente** el mismo resultado que la secuencial para 100.000 elementos; (b) **100 ejecuciones** consecutivas del sistema paralelo producen el mismo hash de estado; (c) el grafo detecta un ciclo de dependencias y no se cuelga; (d) el grafo ejecuta los nodos respetando todas las dependencias declaradas, verificado con un registro de orden; (e) la versión paralela es al menos un 40 % más rápida que la secuencial con 100.000 elementos en una máquina de 4 o más núcleos; (f) no existe ningún mutex dentro de un bucle de job, comprobable por inspección; (g) el sistema funciona correctamente con `WorkerThreadPool` limitado a 1 hilo (sin paralelismo real).

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El resultado varía entre ejecuciones | Carrera de datos. Rediseña para que cada worker escriba en su rango. |
| Paralelizar lo hace más lento | Granularidad demasiado fina o falso compartido. Trozos mayores y acumulador local. |
| El juego se cuelga al cerrar | Se espera un job que nunca termina. Comprueba las dependencias y los ciclos. |
| Funciona en desarrollo y falla en la máquina de un jugador | Carrera que depende del número de núcleos. Test de 100 ejecuciones. |
| Escala bien hasta 4 hilos y luego no | Contención en la cola o memoria saturada. Aumenta la granularidad. |
| Los replays desincronizan tras paralelizar | Suma de flotantes en orden variable. Combina en orden fijo. |
| Un mutex en el bucle caliente | El diseño comparte estado. Particiona los datos. |
| Se crea un hilo por enemigo | Coste de creación. Pool de workers, siempre. |

## ❓ Preguntas frecuentes

**❓ ¿Merece la pena paralelizar en GDScript?** Para lógica de juego con pocas entidades, no: la sobrecarga se come la ganancia y añades una familia de errores. Para procesar decenas de miles de elementos (partículas, consultas espaciales, generación procedural), sí, y `WorkerThreadPool` lo hace razonablemente cómodo. La regla es la de siempre: mide primero.

**❓ ¿Por qué el render suele ir en un solo hilo?** Porque las APIs gráficas tradicionales exigen que el envío de comandos ocurra en un hilo concreto. Las modernas (Vulkan, DX12, Metal) permiten **grabar** command buffers en paralelo y **enviarlos** desde uno solo — que es exactamente lo que verás en la [clase 351](../351-apis-graficas-modernas/README.md).

**❓ ¿Mutex o diseño sin compartir?** Diseño sin compartir, siempre que sea posible. Un mutex es correcto pero serializa: si dos workers se bloquean en el mismo mutex, tienes un hilo trabajando y otro esperando. Cuando aparezca un mutex en un bucle caliente, la pregunta correcta no es cómo hacerlo más rápido, es **cómo dejar de necesitarlo**.

**❓ ¿Cómo pruebo código concurrente?** Con dos técnicas complementarias: repetición masiva (100-1.000 ejecuciones, porque una carrera puede aparecer una vez de cada mil) y comparación con la versión secuencial. Además, probar con **1 hilo** verifica que la lógica es correcta al margen del paralelismo, lo que separa los errores de lógica de los de concurrencia.

**❓ ¿Cuántos workers uso?** Núcleos disponibles menos uno o dos, para dejar sitio al hilo principal y al sistema operativo. `WorkerThreadPool` de Godot ya lo dimensiona solo. Lo que **no** debes hacer es fijar un número: la máquina de tu jugador no es la tuya.

## 🔗 Referencias

- Godot Docs — `WorkerThreadPool`: <https://docs.godotengine.org/en/stable/classes/class_workerthreadpool.html>
- Godot Docs — Uso de hilos: <https://docs.godotengine.org/en/stable/tutorials/performance/using_multiple_threads.html>
- Jason Gregory — *Game Engine Architecture*, capítulo de concurrencia: <https://www.gameenginebook.com/>
- Intel — Guía sobre falso compartido: <https://www.intel.com/content/www/us/en/developer/articles/technical/avoiding-and-identifying-false-sharing-among-threads.html>
- Blumofe & Leiserson — *Scheduling Multithreaded Computations by Work Stealing*: <https://dl.acm.org/doi/10.1145/324133.324234>

## ⬅️ Clase anterior

[Clase 340 - Allocators y gestión avanzada de memoria](../340-allocators-y-gestion-avanzada-de-memoria/README.md)

## ➡️ Siguiente clase

[Clase 342 - Particionamiento espacial](../342-particionamiento-espacial/README.md)
