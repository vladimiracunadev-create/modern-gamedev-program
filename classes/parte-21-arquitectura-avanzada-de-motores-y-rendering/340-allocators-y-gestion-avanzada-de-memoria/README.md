# Clase 340 — Allocators y gestión avanzada de memoria

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Gregory, «Game Engine Architecture» (memory management) · Documentación de gestión de memoria de C++, Rust y .NET*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender por qué **los motores no usan el asignador de memoria del sistema para todo**, y qué usan en su lugar. Pedir memoria al sistema operativo es una operación cara e impredecible: puede tardar cientos de nanosegundos o bloquear varios milisegundos si le toca ampliar el heap. En un frame de 16 ms, unos cuantos de esos son un tirón visible.

Vas a estudiar las estrategias que los motores emplean —**pools**, **arenas**, **stack allocators**, **memoria temporal por frame**— y el problema que todas atacan: la **fragmentación**. Compararás cómo se resuelve esto en C++ (control total), Rust (control con garantías), C# (recolector de basura) y Godot (contado de referencias), porque entender las diferencias es lo que te permite escribir código eficiente en cualquiera de ellos.

La [clase 246](../../parte-14-optimizacion-profiling-y-rendimiento/246-object-pooling-y-evitar-asignaciones/README.md) enseñó object pooling como técnica; aquí se explica el modelo completo del que forma parte.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar qué hace un asignador de propósito general y por qué es caro.
2. Distinguir fragmentación interna y externa y sus consecuencias.
3. Implementar y elegir entre pool, arena, stack allocator y memoria de frame.
4. Clasificar las asignaciones por **tiempo de vida** y aplicar la estrategia adecuada.
5. Comparar el modelo de memoria de C++, Rust, C# y Godot.
6. Detectar y diagnosticar picos de asignación en un juego real.
7. Medir el impacto de eliminar asignaciones del bucle principal.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Coste real de asignar | Es impredecible, y lo impredecible produce tirones. |
| 2 | Fragmentación | El fallo que aparece a las tres horas de juego. |
| 3 | Tiempo de vida | Es el criterio que decide la estrategia. |
| 4 | Pool | Objetos del mismo tamaño, reutilizados. |
| 5 | Arena | Muchas asignaciones, una sola liberación. |
| 6 | Stack allocator | Orden LIFO estricto: la más barata. |
| 7 | Memoria de frame | Se reinicia cada frame: coste cero de liberación. |
| 8 | Modelos por lenguaje | Manual, con garantías, con GC, con refcount. |
| 9 | GC y sus pausas | Por qué C# necesita evitar asignaciones en el bucle. |
| 10 | Medición | Sin medir, todo esto es teoría. |

## 📖 Definiciones y características

- **Asignador (allocator)**: componente que entrega y recupera bloques de memoria. Clave: el del sistema es general, y por eso no es óptimo para nada concreto.
- **Heap**: región de memoria dinámica. Clave: crece y se fragmenta.
- **Stack (pila)**: memoria de vida ligada al ámbito, con orden LIFO. Clave: asignar y liberar cuestan casi nada.
- **Fragmentación externa**: hay memoria libre suficiente pero no contigua. Clave: provoca fallos de asignación con memoria de sobra.
- **Fragmentación interna**: se entrega más memoria de la pedida por alineación o tamaño de bloque. Clave: desperdicio silencioso.
- **Alineación**: requisito de que una dirección sea múltiplo de un valor. Clave: afecta al tamaño real de las estructuras.
- **Pool allocator**: reserva un bloque grande y lo reparte en elementos de tamaño fijo. Clave: asignar y liberar son O(1) sin fragmentación externa.
- **Free list**: lista de huecos libres dentro del pool. Clave: se guarda **en** los propios huecos, sin memoria extra.
- **Arena (region) allocator**: asigna avanzando un puntero y libera todo de golpe. Clave: liberar es poner el puntero a cero.
- **Stack allocator**: arena con liberación en orden inverso mediante marcas. Clave: permite ámbitos anidados.
- **Memoria de frame (scratch)**: arena que se reinicia al final de cada frame. Clave: ideal para lo temporal.
- **Doble búfer**: dos arenas alternas para datos que sobreviven un frame. Clave: permite leer lo del frame anterior.
- **Tiempo de vida**: cuánto dura un dato. Clave: es el criterio de clasificación fundamental.
- **RAII**: liberar recursos al salir del ámbito. Clave: modelo de C++ y Rust.
- **Contado de referencias**: liberar cuando nadie apunta. Clave: modelo de Godot con `RefCounted`.
- **Recolector de basura (GC)**: libera automáticamente lo inalcanzable. Clave: cómodo, con pausas impredecibles.
- **Pausa de GC**: parada para recolectar. Clave: es el enemigo número uno del frame estable en C#.
- **Asignación cero (zero-allocation)**: bucle que no reserva memoria. Clave: el objetivo del código de frame.

## 🧰 Herramientas y preparación

Godot 4.x con `Performance.get_monitor()` para medir memoria y objetos, y `OS.get_static_memory_usage()`. Trabajaremos en `res://memoria/`. GDScript no permite escribir un asignador de bajo nivel —eso es territorio de GDExtension o C++—, pero **sí permite implementar pools y arenas de objetos**, que es donde está la mayor parte del beneficio práctico. Los ejemplos en C++ se incluyen para explicar el modelo.

## 🧪 Laboratorio guiado

1. **Por qué asignar es caro.** No es el coste medio; es la varianza:

```text
Asignación típica del sistema:        ~50-200 ns
Asignación que provoca ampliar heap:  ~10.000-100.000 ns  ← el tirón
Liberación con coalescencia:          ~50-500 ns
Pausa de GC (C#, generación 2):       ~1-50 ms            ← el tirón grande
Pool allocator:                       ~5-15 ns            ← predecible
Arena (avanzar puntero):              ~2-5 ns
```

El problema de un frame no es que 1.000 asignaciones cuesten 100 µs de media: es que **una** de esas mil puede costar 5 ms y producir un salto visible. Los asignadores de esta clase existen sobre todo para eliminar esa varianza.

2. **La fragmentación.** El fallo que aparece cuando ya llevas tres horas jugando:

```text
Inicio:        [████████████████████████████████]  32 bloques libres

Tras horas de asignar y liberar objetos de tamaños distintos:
               [██░░███░█░████░░██░█░░███░█░████]
                  ↑    ↑ ↑    ↑↑  ↑ ↑↑   ↑
               10 bloques libres... pero ninguno contiguo de 4.

Pedir un bloque de 4 → FALLA, con 10 bloques libres.
```

Un pool no tiene este problema porque todos sus elementos son del mismo tamaño: cualquier hueco sirve para cualquier elemento.

3. **La clasificación por tiempo de vida.** Es el criterio que decide todo:

| Tiempo de vida | Ejemplos | Estrategia | Coste de liberar |
|---|---|---|---|
| Todo el juego | Configuración, catálogos, atlas | Asignar una vez al arrancar | Ninguno |
| Un nivel | Mallas, texturas, navmesh | Arena por nivel | Reiniciar el puntero |
| Muchos frames | Entidades, proyectiles | Pool | O(1) |
| Un frame | Listas de visibilidad, resultados de consultas | Memoria de frame | Reiniciar al final |
| Un ámbito | Buffers temporales de una función | Stack allocator | Marca |

**La regla de oro**: nunca uses una estrategia más general de la que necesitas. Un dato que vive un frame no debe pasar por el asignador general.

4. **El pool.** El más útil y el más fácil de implementar en cualquier lenguaje:

```gdscript
class_name PoolObjetos
extends RefCounted

# Los objetos se crean UNA vez y se reutilizan. El bucle de juego no asigna
# nada: solo cambia el estado de objetos que ya existen.
var _libres: Array = []
var _en_uso := {}
var _fabrica: Callable
var _resetear: Callable
var creados := 0
var picos := 0

func _init(fabrica: Callable, resetear: Callable, precrear := 0) -> void:
	_fabrica = fabrica
	_resetear = resetear
	for i in precrear:
		_libres.append(_fabrica.call())
		creados += 1

func obtener() -> Variant:
	var o
	if _libres.is_empty():
		# Crecer en caliente es un fallo de dimensionado: se registra, porque
		# es exactamente la asignación que queríamos evitar.
		o = _fabrica.call()
		creados += 1
		picos += 1
	else:
		o = _libres.pop_back()
	_en_uso[o] = true
	return o

func devolver(o: Variant) -> void:
	if not _en_uso.has(o):
		push_error("se devolvió al pool un objeto que no salió de él")
		return
	_en_uso.erase(o)
	_resetear.call(o)          # limpiar SIEMPRE al devolver, no al obtener:
	_libres.append(o)          # así un objeto en el pool nunca retiene referencias

func en_uso() -> int: return _en_uso.size()
func libres() -> int: return _libres.size()
```

```gdscript
# Uso: proyectiles sin una sola asignación en el bucle de disparo.
var _pool := PoolObjetos.new(
	func(): return Proyectil.new(),
	func(p): p.reiniciar(),
	200)                                     # dimensionado para el peor caso

func disparar(pos: Vector2, dir: Vector2) -> void:
	var p: Proyectil = _pool.obtener()
	p.activar(pos, dir)

func _on_proyectil_terminado(p: Proyectil) -> void:
	_pool.devolver(p)
```

5. **La arena.** Muchas asignaciones, una liberación:

```gdscript
class_name Arena
extends RefCounted

# Modelo conceptual: en C++ sería un puntero que avanza sobre un bloque; aquí
# es un array preasignado y un índice. La IDEA es la misma y el patrón de uso
# también: asignar es barato, liberar es instantáneo y TOTAL.
var _bloque: Array = []
var _cursor := 0
var _capacidad := 0
var desbordes := 0

func _init(capacidad: int, fabrica: Callable) -> void:
	_capacidad = capacidad
	_bloque.resize(capacidad)
	for i in capacidad:
		_bloque[i] = fabrica.call()

func asignar() -> Variant:
	if _cursor >= _capacidad:
		desbordes += 1
		return null                # la arena NO crece: dimensiónala bien
	var o = _bloque[_cursor]
	_cursor += 1
	return o

func reiniciar() -> void:
	# Liberar TODO cuesta una asignación de entero. Este es el punto entero
	# de una arena.
	_cursor = 0

func marca() -> int:
	return _cursor

func liberar_hasta(m: int) -> void:
	# Stack allocator: liberación en orden inverso mediante marcas.
	_cursor = maxi(0, mini(m, _cursor))
```

```gdscript
# Memoria de frame: se reinicia al final de cada frame, sin excepción.
var _frame := Arena.new(4096, func(): return {})

func _process(_delta: float) -> void:
	var visibles = _frame.asignar()          # lista temporal
	_calcular_visibles(visibles)
	_dibujar(visibles)
	# ...
	_frame.reiniciar()                        # coste: una asignación de entero
```

Con la memoria de frame hay una regla que no admite excepciones: **nada de lo asignado ahí puede sobrevivir al frame**. Guardar una referencia a un objeto de la arena y usarla al frame siguiente es un puntero colgante, y en un lenguaje sin protección es un fallo difícil de diagnosticar.

6. **Los cuatro modelos de memoria.** Conocerlos explica por qué el mismo código rinde distinto:

| | C++ | Rust | C# (Unity) | GDScript (Godot) |
|---|---|---|---|---|
| Modelo | Manual + RAII | Ownership + RAII | Recolector de basura | Contado de referencias |
| Liberación | Explícita o por ámbito | Automática y garantizada | Cuando el GC decide | Al llegar a 0 referencias |
| Pausas | Ninguna | Ninguna | **Sí, impredecibles** | Ninguna |
| Fugas | Posibles | Muy difíciles | Por referencias vivas | **Por ciclos** |
| Coste típico | Bajo, controlable | Bajo, controlable | Bajo al asignar, caro al recolectar | Bajo, con sobrecarga por objeto |
| Allocator propio | Total | Total | Limitado (structs, pools) | Solo pools de objetos |
| Qué evitar en el frame | Asignaciones grandes | Asignaciones grandes | **Cualquier asignación** | Crear muchos objetos |

Consecuencias prácticas de cada uno:

```csharp
// C#/Unity: la técnica central es evitar que el GC tenga trabajo.
void Update() {
    var lista = new List<Enemy>();     // ← asigna: basura para el GC cada frame
    // ...
}
// Correcto: reutilizar una lista miembro y limpiarla.
private readonly List<Enemy> _cache = new List<Enemy>(64);
void Update() {
    _cache.Clear();                    // sin asignación
}
```

```gdscript
# Godot: no hay GC, pero crear objetos tiene coste y los CICLOS no se liberan.
class A extends RefCounted:
	var b                              # A -> B
class B extends RefCounted:
	var a                              # B -> A  ← ciclo: NINGUNO se libera

# Solución: romper el ciclo con una referencia débil.
var _padre_debil: WeakRef
func setup(padre) -> void:
	_padre_debil = weakref(padre)
func padre():
	return _padre_debil.get_ref() if _padre_debil else null
```

7. **Medirlo.** Sin medición, todo lo anterior es teoría:

```gdscript
extends SceneTree   # memoria/benchmark.gd

func _init() -> void:
	print("== Asignación vs pool ==")
	_medir("crear objetos nuevos", func():
		var l := []
		for i in 10000:
			l.append(Proyectil.new()))

	var pool := PoolObjetos.new(func(): return Proyectil.new(),
								func(p): p.reiniciar(), 10000)
	_medir("obtener y devolver del pool", func():
		var l := []
		for i in 10000:
			l.append(pool.obtener())
		for p in l:
			pool.devolver(p))

	print("\n== Crecimiento de memoria en 600 frames ==")
	var base := OS.get_static_memory_usage()
	for f in 600:
		_frame_con_pool()
	print("  con pool:  %+.2f MB" % ((OS.get_static_memory_usage() - base) / 1048576.0))

	base = OS.get_static_memory_usage()
	for f in 600:
		_frame_sin_pool()
	print("  sin pool:  %+.2f MB" % ((OS.get_static_memory_usage() - base) / 1048576.0))
	print("  objetos vivos: %d" % Performance.get_monitor(Performance.OBJECT_COUNT))
	quit()
```

8. **Detectar el problema en un juego real.** Los tres síntomas y su diagnóstico:

| Síntoma | Diagnóstico | Herramienta |
|---|---|---|
| Tirón periódico cada pocos segundos | GC (en C#) o ampliación de heap | Perfilador de memoria |
| Memoria que sube sin bajar | Fuga o pool que crece sin tope | `OBJECT_COUNT` a lo largo del tiempo |
| Tirón la primera vez que ocurre algo | Asignación grande en caliente | Precrear en la carga |
| Frame time con picos irregulares | Asignaciones en el bucle | Contador de asignaciones por frame |

```gdscript
# Un contador de asignaciones por frame: detecta el problema antes de que
# aparezca el tirón, y es un presupuesto verificable (clase 321).
var _objetos_inicio := 0

func _process(_d: float) -> void:
	_objetos_inicio = Performance.get_monitor(Performance.OBJECT_COUNT)

func _fin_de_frame() -> void:
	var delta := Performance.get_monitor(Performance.OBJECT_COUNT) - _objetos_inicio
	if delta > PRESUPUESTO_OBJETOS_POR_FRAME:
		Log.warn("asignaciones_por_frame", {"creados": delta, "escena": _escena})
```

## ✍️ Ejercicios

1. Ejecuta el benchmark y anota la proporción entre crear objetos y usar un pool.
2. Convierte tu sistema de proyectiles o partículas a pool y mide el crecimiento de memoria en 10 minutos.
3. Implementa memoria de frame para una lista temporal y comprueba que no crece.
4. Añade el contador de asignaciones por frame y establece un presupuesto.
5. Crea un ciclo de referencias a propósito, comprueba que no se libera y arréglalo con `weakref`.
6. Dimensiona un pool midiendo el pico real de uso y añade telemetría de desbordes.
7. Documenta, para tu proyecto, qué datos van en cada categoría de tiempo de vida.

## 📝 Reto verificable

Implementa un sistema de gestión de memoria con: pool de objetos con precreación, reset al devolver, detección de devoluciones inválidas y telemetría de crecimiento; arena con marcas y liberación por marca; memoria de frame con reinicio automático; y un contador de asignaciones por frame con presupuesto.

**Criterio de aceptación**: una prueba headless con **al menos 15 aserciones** demuestra que: (a) tras 10.000 ciclos obtener/devolver, el pool no ha creado más objetos que su tamaño inicial; (b) devolver un objeto que no salió del pool se detecta y registra; (c) un objeto devuelto al pool no conserva referencias del uso anterior; (d) la arena con marcas libera exactamente hasta la marca y no más; (e) la memoria de frame reiniciada 1.000 veces no incrementa el número de objetos vivos; (f) un ciclo de referencias se detecta con un test que comprueba que el objeto **no** se libera, y su versión con `weakref` sí; (g) el presupuesto de asignaciones por frame falla si se superan las creaciones declaradas; (h) el benchmark demuestra que el pool es **al menos 5 veces** más rápido que crear objetos nuevos.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Tirones periódicos en un juego C#/Unity | Pausas de GC. Elimina asignaciones del `Update`. |
| El pool crece indefinidamente | Objetos que no se devuelven. Telemetría de `en_uso` y revisión de los caminos de salida. |
| Un objeto del pool conserva datos del uso anterior | No se resetea. Resetea **al devolver**, no al obtener. |
| Fallo de asignación con memoria libre de sobra | Fragmentación externa. Pool o arena. |
| Memoria que sube y nunca baja en Godot | Ciclo de referencias. `weakref` para romperlo. |
| Un dato de la memoria de frame se usa al frame siguiente | Violación de la regla de vida. Cópialo si debe sobrevivir. |
| El pool se dimensionó a ojo y desborda en combate | Sin medición del pico. Mide el peor caso real y añade margen. |
| Se implementa un allocator complejo sin necesidad | Sobrediseño. Un pool cubre el 80 % de los casos. |

## ❓ Preguntas frecuentes

**❓ ¿Puedo escribir un allocator de verdad en GDScript?** No en el sentido de gestionar bytes: no tienes control sobre el layout ni sobre la memoria bruta. Sí puedes implementar **pools y arenas de objetos**, que es donde está la mayor parte del beneficio en un proyecto de juego. Para lo demás, GDExtension en C++.

**❓ ¿Y si uso C# en Godot o Unity?** Entonces esta clase es especialmente relevante: el GC es la causa más común de frame time irregular. Las técnicas concretas son evitar asignaciones en el bucle, reutilizar colecciones, usar `struct` donde tenga sentido y precrear todo lo que puedas. Los pools son igual de útiles.

**❓ ¿Cómo dimensiono un pool?** Midiendo el pico real de uso simultáneo en el peor caso jugable (combate grande, efecto masivo) y añadiendo un 20-30 % de margen. Y registrando los desbordes: si el pool crece en caliente, el dimensionado está mal y quieres enterarte.

**❓ ¿No es prematuro optimizar esto?** El **pooling** de lo que se crea y destruye constantemente no es optimización prematura: es diseño. Reescribir un sistema de proyectiles a pool después cuesta más que hacerlo bien la primera vez, y el patrón no complica el código. Lo que sí sería prematuro es escribir un allocator a medida sin haber medido nada.

**❓ ¿Godot no gestiona la memoria por mí?** El contado de referencias libera automáticamente casi todo, y eso está muy bien. Lo que no hace es evitar el **coste de crear** objetos ni resolver los **ciclos**. La primera es la razón de los pools; la segunda, la de `weakref`.

## 🔗 Referencias

- Jason Gregory — *Game Engine Architecture*, capítulo de gestión de memoria: <https://www.gameenginebook.com/> · uso: respalda el Tema 7 «Memoria de frame»
- Godot Docs — `Performance` (monitores de memoria y objetos): <https://docs.godotengine.org/en/4.3/classes/class_performance.html> · uso: respalda el Tema 7 «Memoria de frame»
- Godot Docs — `RefCounted` y `WeakRef`: <https://docs.godotengine.org/en/4.3/classes/class_weakref.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Microsoft — Fundamentos de la recolección de basura en .NET: <https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- The Rust Book — Ownership y gestión de memoria: <https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html> · uso: respalda el Tema 7 «Memoria de frame»
- Richard Fabian — *Data-Oriented Design*, capítulo de memoria: <https://www.dataorienteddesign.com/dodbook/> · uso: respalda el Tema 7 «Memoria de frame»

## ⬅️ Clase anterior

[Clase 339 - Data-Oriented Design](../339-data-oriented-design/README.md)

## ➡️ Siguiente clase

[Clase 341 - Job Systems y Task Graphs](../341-job-systems-y-task-graphs/README.md)
