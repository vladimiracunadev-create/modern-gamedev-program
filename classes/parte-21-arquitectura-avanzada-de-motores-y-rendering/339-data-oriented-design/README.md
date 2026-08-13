# Clase 339 — Data-Oriented Design

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Richard Fabian, «Data-Oriented Design» · Mike Acton, charlas de CppCon · Gregory, «Game Engine Architecture»*
> ⏱️ Duración estimada: **125 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender por qué **la forma en que dispones los datos en memoria importa más que el algoritmo** cuando procesas muchas entidades, y aprender a diseñar en consecuencia. Es la clase que explica por qué 10.000 entidades con un `_process` cada una van a tirones, y las mismas 10.000 procesadas en un bucle sobre arrays van sobradas.

La razón está en un hecho del hardware que no ha dejado de agravarse en treinta años: **la CPU es muchísimo más rápida que la memoria**. Un acceso a caché L1 cuesta unos pocos ciclos; uno a memoria principal, cientos. Un programa que salta por la memoria pasa la mayor parte del tiempo esperando, con la CPU parada. El *data-oriented design* consiste en organizar los datos para que ese salto no ocurra.

Esta clase es el **contrapunto deliberado** de la [clase 293](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/293-arquitectura-de-gameplay-a-escala/README.md): allí organizamos el código por responsabilidades para que sea modificable; aquí organizamos los datos por acceso para que sea rápido. Las dos son correctas, en sitios distintos, y saber cuándo aplicar cada una es el objetivo real.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar la jerarquía de memoria y el coste relativo de cada nivel.
2. Distinguir **AoS** de **SoA** y elegir según el patrón de acceso.
3. Reorganizar un sistema de "objetos con métodos" a "arrays con bucles" y medir la mejora.
4. Separar datos calientes de fríos y justificar la separación.
5. Explicar la relación entre DOD y ECS, y qué aporta cada uno.
6. Aplicar DOD dentro de GDScript pese a sus limitaciones, y saber dónde está el techo.
7. Decidir cuándo **no** aplicar DOD.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | La brecha CPU-memoria | Es el hecho del que se deriva todo lo demás. |
| 2 | Línea de caché | La unidad real de transferencia: 64 bytes, no un campo. |
| 3 | Localidad espacial y temporal | Las dos formas de que el dato ya esté cerca. |
| 4 | AoS vs SoA | La decisión central, y depende del acceso. |
| 5 | Fallo de caché | El coste que hay que evitar, y se puede medir. |
| 6 | Datos calientes y fríos | Lo que se toca cada frame, separado de lo que no. |
| 7 | Bucles sobre arrays | La forma que el hardware premia. |
| 8 | Predicción de saltos | Las ramas dentro del bucle también cuestan. |
| 9 | DOD y ECS | Relacionados pero no lo mismo. |
| 10 | Cuándo no aplicarlo | La parte que evita el sobrediseño. |

## 📖 Definiciones y características

- **Data-oriented design (DOD)**: diseñar el programa alrededor de cómo se transforman los datos, no de los objetos del dominio. Clave: la pregunta es "qué datos, en qué orden", no "qué objetos".
- **Jerarquía de memoria**: registros → L1 → L2 → L3 → RAM → disco, cada nivel más grande y más lento. Clave: la diferencia entre extremos es de varios órdenes de magnitud.
- **Línea de caché**: bloque que la CPU trae de memoria de una vez, típicamente 64 bytes. Clave: pedir un `float` trae 64 bytes; aprovecharlos o no es la diferencia.
- **Fallo de caché (cache miss)**: el dato no estaba en caché y hay que ir a buscarlo. Clave: es lo que de verdad cuesta.
- **Localidad espacial**: usar datos que están juntos en memoria. Clave: es lo que hace útil traer 64 bytes.
- **Localidad temporal**: reutilizar pronto un dato ya traído. Clave: la otra mitad del aprovechamiento de caché.
- **AoS (array of structures)**: array de objetos completos. Clave: natural de leer; trae campos que no usas.
- **SoA (structure of arrays)**: un array por campo. Clave: si solo lees dos campos, solo traes esos dos.
- **Memoria contigua**: datos consecutivos sin huecos. Clave: es lo que permite prefetch y vectorización.
- **Prefetch**: el hardware adivina qué traerás y lo trae antes. Clave: acierta con accesos secuenciales; falla con punteros.
- **Persecución de punteros (pointer chasing)**: recorrer estructuras enlazadas. Clave: el patrón más hostil a la caché.
- **Datos calientes**: los que se usan cada frame. Clave: deben estar contiguos y ser pequeños.
- **Datos fríos**: los que se usan rara vez (nombre, descripción, icono). Clave: sacarlos del bucle caliente reduce lo que se trae.
- **Vectorización (SIMD)**: una instrucción sobre varios datos a la vez. Clave: requiere datos contiguos y uniformes.
- **Predicción de saltos**: la CPU adivina el resultado de un `if`. Clave: un `if` impredecible dentro de un bucle cuesta mucho.
- **ECS (entity-component-system)**: arquitectura de entidades, componentes de datos y sistemas que los procesan. Clave: es **una** forma de aplicar DOD, no su sinónimo.
- **Archetype**: agrupación de entidades con el mismo conjunto de componentes. Clave: permite recorrerlas de forma contigua.

## 🧰 Herramientas y preparación

Godot 4.x con `Time.get_ticks_usec()` para medir, y `PackedFloat32Array` / `PackedVector2Array` para los arrays contiguos —que en GDScript son la herramienta clave, porque no son arrays de `Variant`—. Trabajaremos en `res://dod/`. Repasa de la Parte 14 la clase [243](../../parte-14-optimizacion-profiling-y-rendimiento/243-optimizacion-de-cpu-logica-scripts-y-llamadas/README.md) sobre optimización de CPU: allí se midió; aquí se explica el porqué.

## 🧪 Laboratorio guiado

1. **El hecho del que sale todo.** Los números aproximados que conviene tener en la cabeza:

```text
Operación                          Ciclos aprox.    Equivalente si 1 ciclo = 1 s
────────────────────────────────────────────────────────────────────────────
Instrucción en registro                  1          1 segundo
Acceso a caché L1                        4          4 segundos
Acceso a caché L2                       12          12 segundos
Acceso a caché L3                       40          40 segundos
Acceso a memoria principal             200          3 minutos
Lectura de SSD                   ~150.000          2 días
```

Un bucle que hace una multiplicación por elemento y falla en caché en cada uno pasa **el 99 % del tiempo esperando**. Optimizar la multiplicación no sirve de nada; optimizar el acceso, sí.

2. **La línea de caché.** El detalle que lo explica casi todo:

```text
Pides un float de 4 bytes → la CPU trae 64 bytes (la línea completa)

AoS: array de partículas de 64 bytes cada una
  [pos.x pos.y vel.x vel.y color(16B) vida masa nombre_id ...] [siguiente] ...
   ↑─────── traes 64 B ───────↑
  Si solo necesitas pos y vel (16 B), has traído 48 B inútiles: 75 % desperdiciado.

SoA: un array por campo
  pos_x:  [x0 x1 x2 x3 ... x15]   ← 64 B = 16 valores útiles
  pos_y:  [y0 y1 y2 y3 ... y15]
  vel_x:  [...]
  Traes 64 B y usas 64 B: 0 % desperdiciado, y el prefetch acierta siempre.
```

3. **El experimento.** Mídelo tú, porque los números dependen de tu máquina:

```gdscript
extends SceneTree   # dod/benchmark.gd

const N := 200000
const ITERACIONES := 60

func _init() -> void:
	print("== %d entidades, %d iteraciones ==" % [N, ITERACIONES])
	_medir("AoS (Array de objetos)", _aos)
	_medir("AoS (Array de diccionarios)", _aos_dict)
	_medir("SoA (PackedFloat32Array)", _soa)
	_medir("SoA + campos fríos aparte", _soa_frio)
	quit()

func _medir(nombre: String, f: Callable) -> void:
	f.call()                          # calentamiento: la primera pasada no cuenta
	var t0 := Time.get_ticks_usec()
	for i in ITERACIONES:
		f.call()
	var ms := (Time.get_ticks_usec() - t0) / 1000.0 / ITERACIONES
	print("  %-32s %.2f ms/iteración" % [nombre, ms])
```

```gdscript
# --- AoS: lo natural, y lo más lento -------------------------------------
class Particula:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var color := Color.WHITE          # 16 B que el bucle NO usa
	var vida := 1.0
	var nombre := ""                  # y esto es un puntero a otra parte
	var metadata := {}                # y esto, otro

var _aos_datos: Array[Particula] = []

func _aos() -> void:
	# Cada `p` es un objeto en el heap: la CPU salta por la memoria en cada
	# iteración y el prefetch no puede adivinar dónde está el siguiente.
	for p in _aos_datos:
		p.pos += p.vel * 0.016
		p.vida -= 0.016

# --- SoA: arrays empaquetados, contiguos y sin Variant --------------------
var _pos_x := PackedFloat32Array()
var _pos_y := PackedFloat32Array()
var _vel_x := PackedFloat32Array()
var _vel_y := PackedFloat32Array()
var _vida := PackedFloat32Array()

func _soa() -> void:
	# Cuatro recorridos secuenciales sobre memoria contigua. El prefetch
	# acierta siempre y no se trae ni un byte que no se use.
	for i in N:
		_pos_x[i] += _vel_x[i] * 0.016
		_pos_y[i] += _vel_y[i] * 0.016
		_vida[i] -= 0.016
```

Resultados típicos en una máquina de escritorio (varían, pero la **proporción** se mantiene):

```text
== 200000 entidades, 60 iteraciones ==
  AoS (Array de objetos)             48.30 ms/iteración
  AoS (Array de diccionarios)       112.70 ms/iteración
  SoA (PackedFloat32Array)            6.10 ms/iteración      ← 8× más rápido
  SoA + campos fríos aparte            5.80 ms/iteración
```

El array de diccionarios —que es lo que mucha gente escribe por comodidad— es **18 veces más lento** que el SoA para exactamente el mismo trabajo.

4. **Calientes y fríos.** La separación que más rinde con menos esfuerzo:

```gdscript
class_name SistemaParticulas
extends RefCounted

# CALIENTE: se toca cada frame para las N partículas. Contiguo y mínimo.
var pos_x := PackedFloat32Array()
var pos_y := PackedFloat32Array()
var vel_x := PackedFloat32Array()
var vel_y := PackedFloat32Array()
var vida := PackedFloat32Array()

# FRÍO: se toca al crear, al dibujar o nunca. Fuera del bucle caliente para
# que no ocupe líneas de caché que necesita lo de arriba.
var color := PackedColorArray()
var tipo := PackedByteArray()
var metadata: Array[Dictionary] = []

func avanzar(delta: float) -> void:
	var n := pos_x.size()
	for i in n:
		pos_x[i] += vel_x[i] * delta
		pos_y[i] += vel_y[i] * delta
		vida[i] -= delta
```

Regla práctica: **si un campo no se usa en el bucle que corre cada frame, no debe estar en la estructura que ese bucle recorre**.

5. **Las ramas dentro del bucle.** El segundo coste, después de la caché:

```gdscript
# ❌ Un `if` impredecible por elemento: la CPU se equivoca al predecir y
#    tiene que descartar trabajo ya empezado. Con datos aleatorios, cuesta.
func avanzar_con_rama(delta: float) -> void:
	for i in pos_x.size():
		if vida[i] > 0.0:
			pos_x[i] += vel_x[i] * delta
			vida[i] -= delta

# ✅ Partición: se mantienen vivas y muertas separadas. El bucle no tiene
#    ramas y procesa solo lo vivo.
var _vivas := 0                       # las [0, _vivas) están vivas

func avanzar_sin_rama(delta: float) -> void:
	for i in _vivas:
		pos_x[i] += vel_x[i] * delta
		vida[i] -= delta

func compactar() -> void:
	# Al morir una, se intercambia con la última viva: O(1) y sin huecos.
	var i := 0
	while i < _vivas:
		if vida[i] <= 0.0:
			_vivas -= 1
			_intercambiar(i, _vivas)
		else:
			i += 1
```

6. **DOD y ECS: qué es cada cosa.** Se confunden constantemente:

| | DOD | ECS |
|---|---|---|
| Qué es | Una forma de pensar | Una arquitectura concreta |
| Idea central | Organizar datos por acceso | Entidad + componentes de datos + sistemas |
| ¿Necesita lo otro? | No necesita ECS | Un ECS **puede** no ser DOD (si guarda componentes dispersos) |
| Dónde aplica | Cualquier bucle sobre muchos datos | Estructura general de las entidades |
| Coste de adopción | Bajo: un sistema cada vez | Alto: cambia toda la arquitectura |

Un ECS bien implementado agrupa las entidades por **archetype** (mismo conjunto de componentes) y las guarda contiguas, con lo que sale SoA de forma natural. Pero puedes aplicar DOD a tu sistema de partículas sin adoptar un ECS, y eso es lo recomendable para empezar.

7. **Aplicarlo dentro de Godot.** Con sus posibilidades reales y su techo:

| Herramienta | Qué aporta | Límite |
|---|---|---|
| `PackedFloat32Array` y familia | Memoria contigua sin `Variant` | Solo tipos primitivos |
| `MultiMeshInstance` | Miles de instancias en una llamada de dibujo | Solo para dibujar |
| `RenderingServer` directo | Salta el árbol de nodos | Más verboso y manual |
| Compute shaders | Paralelismo masivo en GPU | Requiere GPU y transferencia |
| GDExtension (C++) | SIMD, control total de memoria | Compilación por plataforma |
| Nodos individuales | Comodidad y editor | El árbol tiene un coste por nodo |

```gdscript
# Miles de entidades SIN un nodo por entidad: los datos en arrays, y el
# dibujado en una sola llamada con MultiMesh.
class_name EnjambreVisual
extends MultiMeshInstance2D

var _pos_x := PackedFloat32Array()
var _pos_y := PackedFloat32Array()

func _ready() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.instance_count = 10000
	multimesh.mesh = _quad()

func _process(delta: float) -> void:
	for i in _pos_x.size():
		_pos_x[i] += _vel_x[i] * delta
		_pos_y[i] += _vel_y[i] * delta
	_subir_transformadas()
```

8. **Cuándo NO aplicarlo.** La parte que evita el sobrediseño:

| Situación | ¿DOD? | Por qué |
|---|---|---|
| 20 enemigos con IA compleja | ❌ | El coste está en la lógica, no en la memoria |
| 50.000 partículas | ✅ | El acceso a memoria domina |
| El sistema de inventario | ❌ | Se toca en eventos, no cada frame |
| 10.000 proyectiles | ✅ | Bucle grande y simple |
| La máquina de estados del jugador | ❌ | Una entidad; la claridad importa más |
| Colisiones de 5.000 entidades | ✅ | Y combinado con particionamiento (clase 342) |
| El sistema de quests | ❌ | Decenas de elementos, lógica compleja |
| Simulación de fluidos o multitudes | ✅ | Es exactamente su caso |

La regla honesta: **DOD se aplica donde has medido que hay un problema y el problema es el acceso a memoria**. Aplicarlo en todas partes produce código difícil de leer sin ganancia, y eso es una pérdida neta.

9. **Probarlo.** El test que documenta la decisión:

```gdscript
extends SceneTree

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	# 1) CORRECCIÓN: SoA y AoS deben dar el mismo resultado. Si no, la
	#    optimización ha cambiado el comportamiento y no vale nada.
	var aos := _crear_aos(1000)
	var soa := _crear_soa(1000)
	for i in 100:
		_avanzar_aos(aos, 0.016)
		soa.avanzar(0.016)
	check.call(_equivalentes(aos, soa, 0.001), "SoA y AoS dan el mismo resultado")

	# 2) RENDIMIENTO: presupuesto, no comparación absoluta (clase 321).
	var t0 := Time.get_ticks_usec()
	for i in 60: soa.avanzar(0.016)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0 / 60.0
	check.call(ms < 2.0, "100k entidades en menos de 2 ms/frame (fue %.2f)" % ms)

	# 3) La compactación no pierde ni duplica entidades.
	var antes := soa.vivas()
	soa.matar(10); soa.compactar()
	check.call(soa.vivas() == antes - 1, "compactar no pierde entidades")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

## ✍️ Ejercicios

1. Ejecuta el benchmark en tu máquina y anota la proporción entre AoS, diccionarios y SoA.
2. Convierte un sistema tuyo de más de 1.000 entidades a SoA y mide antes y después.
3. Separa datos calientes y fríos en ese sistema y mide la mejora adicional.
4. Elimina una rama del bucle caliente mediante partición y mide el efecto.
5. Compara 5.000 nodos `Sprite2D` con un `MultiMesh` de 5.000 instancias.
6. Mide cómo cambia el resultado al variar N: 100, 1.000, 10.000, 100.000.
7. Documenta un caso de tu proyecto donde DOD **no** compensa, con su justificación.

## 📝 Reto verificable

Implementa un sistema de partículas o proyectiles con **al menos 100.000 entidades** en SoA con `PackedFloat32Array`, separación de datos calientes y fríos, bucle sin ramas mediante partición vivos/muertos, compactación O(1) y dibujado con `MultiMesh`; más una versión AoS equivalente para comparar.

**Criterio de aceptación**: (a) una prueba headless demuestra que la versión SoA y la AoS producen **resultados numéricamente equivalentes** (dentro de una tolerancia declarada) tras 100 pasos; (b) el benchmark imprime el tiempo por iteración de ambas y la versión SoA es **al menos 3 veces más rápida** con 100.000 entidades; (c) la compactación no pierde ni duplica entidades tras 1.000 operaciones aleatorias de creación y muerte; (d) el bucle caliente no contiene ninguna rama condicional, comprobable por inspección; (e) los campos fríos (color, tipo, metadata) no se acceden dentro del bucle de actualización; (f) existe un presupuesto de rendimiento que falla si el tiempo por frame supera el límite declarado; (g) el README documenta en qué casos de tu proyecto **no** aplicarías esta técnica y por qué.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Se convierte todo a SoA y no mejora nada | El cuello no era la memoria. Mide antes de reorganizar. |
| El código se vuelve ilegible sin ganancia | DOD aplicado donde no tocaba. Solo donde el bucle es grande. |
| SoA en GDScript con `Array` normal, sin mejora | `Array` guarda `Variant`, no es contiguo. Usa `Packed*Array`. |
| La versión optimizada da resultados distintos | Se cambió el orden de operaciones. Prueba la equivalencia siempre. |
| Se guardan los campos fríos junto a los calientes | Se traen líneas de caché inútiles. Sepáralos. |
| Un `if` por elemento en el bucle caliente | Predicción fallida. Particiona los datos. |
| Se adopta un ECS entero para un sistema | Coste enorme por un problema local. Aplica DOD solo a ese sistema. |
| Mejora en el escritorio y no en móvil | Distinta jerarquía de caché. Mide en el dispositivo objetivo. |

## ❓ Preguntas frecuentes

**❓ ¿Esto contradice la arquitectura por capas de la clase 293?** No: resuelven problemas distintos. Las capas organizan el **conocimiento** para que el proyecto sea modificable; el DOD organiza los **datos** para que un bucle sea rápido. Un proyecto sano tiene lo primero en general y lo segundo en los tres o cuatro sitios donde hay volumen. Aplicar DOD a todo produce un proyecto rápido e inmantenible; ignorarlo donde hay 50.000 elementos produce uno claro y lento.

**❓ ¿Merece la pena en GDScript, que ya es lento?** Sí, y a veces más: precisamente porque el intérprete añade sobrecarga por operación, reducir accesos y usar `Packed*Array` (que evita el boxing a `Variant`) da mejoras grandes. El techo está en que no controlas el layout exacto ni tienes SIMD; para eso está GDExtension.

**❓ ¿Necesito un ECS?** Casi nunca para empezar. Un ECS es una decisión arquitectónica que afecta a todo el proyecto y tiene un coste de adopción real. Puedes obtener la mayor parte del beneficio aplicando SoA a los dos o tres sistemas con volumen, sin tocar nada más.

**❓ ¿Cómo sé si mi problema es de caché?** Síntomas: el tiempo escala peor que lineal con el número de elementos, el perfilador muestra tiempo en accesos y no en cálculo, y el trabajo por elemento es trivial pero el total es alto. Y la prueba definitiva: reorganizar a SoA y medir. Si no mejora, no era eso.

**❓ ¿Y las GPU?** Tienen la misma sensibilidad, agravada: un compute shader con acceso desordenado a memoria rinde una fracción de lo que podría. Los principios de esta clase se aplican igual en GPU, y se ven en las clases [341](../341-job-systems-y-task-graphs/README.md) y [349](../349-gpu-driven-rendering/README.md).

## 🔗 Referencias

- Richard Fabian — *Data-Oriented Design* (libro completo en abierto): <https://www.dataorienteddesign.com/dodbook/>
- Mike Acton — «Data-Oriented Design and C++», CppCon (charla de referencia): <https://www.youtube.com/watch?v=rX0ItVEVjHc>
- Jason Gregory — *Game Engine Architecture*: <https://www.gameenginebook.com/>
- Godot Docs — `PackedFloat32Array` y tipos empaquetados: <https://docs.godotengine.org/en/stable/classes/class_packedfloat32array.html>
- Godot Docs — `MultiMesh` y `MultiMeshInstance2D`: <https://docs.godotengine.org/en/stable/classes/class_multimesh.html>
- Ulrich Drepper — *What Every Programmer Should Know About Memory*: <https://people.freebsd.org/~lstewart/articles/cpumemory.pdf>

## ⬅️ Clase anterior

[Clase 338 - Capstone Parte 20: un NPC con lore verificable](../../parte-20-ia-generativa-y-desarrollo-asistido-por-ia/338-capstone-parte-20-un-npc-con-lore-verificable/README.md)

## ➡️ Siguiente clase

[Clase 340 - Allocators y gestión avanzada de memoria](../340-allocators-y-gestion-avanzada-de-memoria/README.md)
