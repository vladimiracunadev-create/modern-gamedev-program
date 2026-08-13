# Clase 320 — Testing de producción

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *Documentación de GUT · Literatura sobre property-based testing y fuzzing · Google, «Site Reliability Engineering»*
> ⏱️ Duración estimada: **125 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Ampliar el testing de la [clase 264](../../parte-15-herramientas-editores-y-automatizacion/264-testing-automatizado-de-juegos-gut/README.md) —tests unitarios con GUT— hasta la batería completa que necesita un juego que va a estar años en producción. Los tests de ejemplo comprueban lo que **se te ocurrió** comprobar; los de esta clase buscan lo que **no se te ocurrió**.

Vas a implementar seis técnicas que se complementan: **property-based testing** (afirmar propiedades y dejar que la máquina busque contraejemplos), **fuzzing seguro** (entradas malformadas contra tus parsers y tu red), **replay determinista** como test de integración, **smoke tests** de arranque, **soak testing** (dejarlo corriendo horas para cazar fugas) y **load testing** (simular jugadores concurrentes). Todo ejecutable en CI, sin GPU y sin servicios externos.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Elegir el tipo de test adecuado para cada tipo de fallo.
2. Escribir tests **basados en propiedades** con generadores y reducción de contraejemplos.
3. Implementar fuzzing seguro sobre parsers de contenido y mensajes de red.
4. Usar replays deterministas como tests de integración de gameplay.
5. Implementar soak tests que detecten fugas de memoria y degradación.
6. Implementar load tests con clientes simulados y medir percentiles.
7. Definir criterios de fallo objetivos para cada tipo de test en CI.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Pirámide de tests | Muchos rápidos, pocos lentos: es una cuestión de coste. |
| 2 | Property-based | Encuentra los casos límite que nadie escribe a mano. |
| 3 | Reducción (shrinking) | Un contraejemplo de 300 pasos no sirve; uno de 3, sí. |
| 4 | Fuzzing | Los parsers reciben basura antes o después. |
| 5 | Fuzzing seguro | Contra lo tuyo, sin explotar nada ajeno. |
| 6 | Replay determinista | El test de integración más barato de todos. |
| 7 | Smoke test | Detecta el 80 % de las roturas en 30 segundos. |
| 8 | Soak testing | Las fugas solo se ven con el tiempo. |
| 9 | Load testing | Saber cuántos jugadores aguantas antes de descubrirlo en directo. |
| 10 | Criterio de fallo | Un test sin umbral objetivo no es un test. |

## 📖 Definiciones y características

- **Test unitario**: prueba una unidad aislada. Clave: milisegundos, y es donde deben estar la mayoría.
- **Test de integración**: prueba varios componentes juntos por sus interfaces reales. Clave: detecta fallos de conexión que las unitarias no ven.
- **Smoke test**: comprobación mínima de que el sistema arranca y hace lo básico. Clave: es la primera barrera y debe ser muy rápida.
- **Property-based testing**: afirmar una propiedad universal y generar entradas para intentar refutarla. Clave: encuentra lo que no imaginaste.
- **Propiedad**: afirmación que debe cumplirse para **toda** entrada válida. Clave: formularla bien es el 90 % del trabajo.
- **Generador**: función que produce entradas aleatorias válidas. Clave: su calidad determina la del test.
- **Reducción (shrinking)**: simplificar un contraejemplo hasta el mínimo que sigue fallando. Clave: es lo que hace utilizable el hallazgo.
- **Fuzzing**: alimentar un sistema con entradas malformadas o inesperadas. Clave: los parsers y los protocolos son sus objetivos naturales.
- **Fuzzing seguro**: hacerlo solo contra sistemas propios y en entorno controlado. Clave: es la línea ética y legal.
- **Crash vs error controlado**: el fuzzer busca lo primero; lo segundo es comportamiento correcto. Clave: rechazar una entrada mala es aprobar el test.
- **Replay determinista**: reproducir una partida grabada y comparar el resultado. Clave: cubre integración real con coste casi nulo.
- **Soak test**: ejecución prolongada buscando degradación. Clave: detecta fugas, crecimiento de estructuras y desbordamientos.
- **Fuga de memoria**: memoria que se reserva y no se libera. Clave: se ve como crecimiento monótono en horas.
- **Load test**: simulación de carga concurrente. Clave: mide capacidad y descubre el punto de rotura.
- **Percentil de latencia**: p50/p95/p99 del tiempo de respuesta. Clave: es la métrica de calidad, no la media.
- **Test flaky**: el que falla de forma intermitente sin causa real. Clave: es peor que no tenerlo, porque enseña a ignorar los rojos.
- **Cobertura**: porcentaje de código ejecutado por los tests. Clave: útil como señal, inútil como objetivo.

## 🧰 Herramientas y preparación

Godot 4.x con [GUT](https://github.com/bitwes/Gut) para los unitarios (clase 264) y scripts `SceneTree` headless para el resto. Trabajaremos en `res://pruebas/`. Todo lo de esta clase corre con `godot --headless`, sin GPU, que es el requisito para que la CI lo ejecute en cada push. Necesitas el sistema de comandos y replays de la [clase 308](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/308-commands-input-recording-y-replays/README.md).

## 🧪 Laboratorio guiado

1. **La pirámide, con tiempos reales.** Determina cuántos de cada tipo tienes:

```text
        ╱ Load  ╲          minutos-horas · pocos · manual o nocturno
       ╱  Soak   ╲         horas         · 1-2   · nocturno
      ╱  Replay   ╲        segundos      · decenas · cada push
     ╱ Integración ╲       segundos      · decenas · cada push
    ╱     Fuzz      ╲      segundos      · varios  · cada push
   ╱   Unitarios     ╲     milisegundos  · cientos · cada push
```

2. **Property-based testing.** El cambio de mentalidad de la clase:

```gdscript
class_name Propiedad
extends RefCounted

class Resultado extends RefCounted:
	var ok: bool = true
	var contraejemplo: Variant = null
	var intentos: int = 0
	var reducciones: int = 0

static func comprobar(nombre: String, generador: Callable, propiedad: Callable,
					  reductor: Callable, n := 200, semilla := 1234) -> Resultado:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla                   # reproducible: un fallo se puede repetir
	var r := Resultado.new()
	for i in n:
		r.intentos = i + 1
		var entrada = generador.call(rng)
		if propiedad.call(entrada):
			continue
		# Falla: ahora REDUCIMOS. Un contraejemplo de 300 elementos no dice
		# nada; el mismo reducido a 2 suele señalar el bug con el dedo.
		r.ok = false
		r.contraejemplo = entrada
		var actual = entrada
		var seguir := true
		while seguir and r.reducciones < 1000:
			seguir = false
			for candidato in reductor.call(actual):
				if not propiedad.call(candidato):
					actual = candidato
					r.contraejemplo = candidato
					r.reducciones += 1
					seguir = true
					break
		return r
	return r
```

Aplicado al inventario de la clase 295:

```gdscript
extends SceneTree

func _init() -> void:
	var fallos := 0

	# PROPIEDAD 1: agregar y quitar la misma cantidad deja el inventario igual.
	var p1 := Propiedad.comprobar("agregar/quitar es neutro",
		func(rng): return {"id": ["pocion_menor", "mineral_hierro"][rng.randi() % 2],
						   "n": rng.randi_range(1, 200)},
		func(e):
			var inv := _inv_limpio()
			var antes := inv.a_dict()
			var restante := inv.agregar(e["id"], e["n"])
			inv.quitar(e["id"], e["n"] - restante)
			return inv.a_dict() == antes,
		func(e): return [{"id": e["id"], "n": maxi(1, e["n"] / 2)}])

	# PROPIEDAD 2: cabe() nunca miente.
	var p2 := Propiedad.comprobar("cabe() coincide con agregar()",
		func(rng): return {"id": "pocion_menor", "n": rng.randi_range(1, 500),
						   "cap": rng.randi_range(1, 10)},
		func(e):
			var inv := Inventario.new(_base, e["cap"])
			var previsto := inv.cabe(e["id"], e["n"])
			var restante := inv.agregar(e["id"], e["n"])
			return previsto == e["n"] - restante,
		func(e): return [{"id": e["id"], "n": maxi(1, e["n"] / 2), "cap": e["cap"]},
						 {"id": e["id"], "n": e["n"], "cap": maxi(1, e["cap"] - 1)}])

	# PROPIEDAD 3: una transacción fallida no cambia nada.
	var p3 := Propiedad.comprobar("las transacciones son atómicas",
		func(rng): return rng.randi_range(1, 50),
		func(n):
			var inv := _inv_limpio()
			var antes := inv.a_dict()
			inv.transaccion([func(): return inv.agregar_todo_o_nada("pocion_menor", n),
							 func(): return false])          # el segundo paso siempre falla
			return inv.a_dict() == antes,
		func(n): return [maxi(1, n / 2)])

	for p in [p1, p2, p3]:
		if not p.ok:
			fallos += 1
			printerr("  contraejemplo: ", p.contraejemplo,
					 " (tras %d intentos, %d reducciones)" % [p.intentos, p.reducciones])

	print("== 3 comprobaciones, %d fallos ==" % fallos)
	quit(1 if fallos > 0 else 0)
```

3. **Fuzzing seguro.** Contra **tus** parsers, en **tu** máquina:

```gdscript
class_name Fuzzer
extends RefCounted

# Solo contra sistemas propios: parsers de contenido, deserializadores de save
# y mensajes de red de nuestro protocolo. Nunca contra servicios de terceros.
static func mutar(base: String, rng: RandomNumberGenerator) -> String:
	var s := base
	match rng.randi() % 8:
		0: s = s.substr(0, rng.randi_range(0, s.length()))          # truncar
		1: s = s + s                                                 # duplicar
		2: s = s.replace("\"", "")                                   # romper comillas
		3: s = s.replace("}", "")                                    # romper estructura
		4: s = s.insert(rng.randi_range(0, s.length()), char(0))     # byte nulo
		5: s = s.replace("0", str(rng.randi()))                      # números enormes
		6: s = s.replace(":", ": -")                                 # negativos
		7: s = char(0xFEFF) + s                                      # BOM inesperado
	return s

static func campana(rutas: Array[String], iteraciones := 500, semilla := 99) -> Dictionary:
	var rng := RandomNumberGenerator.new(); rng.seed = semilla
	var crashes := []
	var rechazos := 0
	for ruta in rutas:
		var original := FileAccess.open(ruta, FileAccess.READ).get_as_text()
		for i in iteraciones:
			var mutado := mutar(original, rng)
			# El criterio de ÉXITO es que el parser rechace limpiamente. Un
			# error controlado es aprobar; un crash o un cuelgue es fallar.
			var base := BaseDeItems.new()
			var errores := base.cargar_desde_texto(mutado)
			if errores.is_empty() and base.todos().is_empty():
				crashes.append({"ruta": ruta, "semilla": rng.seed, "iteracion": i,
								"motivo": "aceptó basura sin avisar"})
			else:
				rechazos += 1
	return {"crashes": crashes, "rechazos_correctos": rechazos}
```

Regla ética de la clase, y no es negociable: **el fuzzing se hace contra sistemas propios o con autorización explícita**. Lanzar entradas malformadas contra el servicio de otro es un ataque, no una prueba.

4. **Replay como test de integración.** Ya lo tienes de la clase 308; aquí se integra en la batería:

```gdscript
extends SceneTree   # pruebas/replays_test.gd

func _init() -> void:
	var hechas := 0; var fallos := 0
	for ruta in DirAccess.get_files_at("res://pruebas/replays/"):
		if not ruta.ends_with(".json"):
			continue
		hechas += 1
		var g := Grabacion.cargar("res://pruebas/replays/" + ruta)
		var sim := Simulacion.new()
		var rep := Reproductor.new()
		rep.divergencia.connect(func(t, e, o):
			printerr("  %s diverge en tick %d (%d != %d)" % [ruta, t, e, o]))
		rep.cargar(sim, g)
		if not rep.reproducir_todo():
			fallos += 1
	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

5. **Smoke test.** Treinta segundos que evitan la mitad de los desastres:

```gdscript
extends SceneTree   # pruebas/smoke_test.gd

func _init() -> void:
	var fallos := 0
	# 1) El contenido carga y valida.
	var base := BaseDeItems.new()
	var errs := base.cargar_desde_json("res://datos/items.json")
	errs.append_array(ValidadorDeItems.validar(base))
	if not errs.is_empty(): fallos += 1; printerr("  contenido inválido: ", errs[0])

	# 2) Las escenas principales instancian sin errores.
	for ruta in ["res://escenas/menu.tscn", "res://escenas/mundo.tscn"]:
		var esc := load(ruta)
		if esc == null: fallos += 1; printerr("  no carga: ", ruta); continue
		var nodo = esc.instantiate()
		if nodo == null: fallos += 1; printerr("  no instancia: ", ruta); continue
		nodo.free()

	# 3) Los autoloads y servicios se construyen.
	if not _puede_construir_servicios(): fallos += 1

	print("== 3 comprobaciones, %d fallos ==" % fallos)
	quit(1 if fallos > 0 else 0)
```

6. **Soak test.** Horas de ejecución buscando lo que solo se ve con el tiempo:

```gdscript
extends SceneTree   # pruebas/soak_test.gd --  --minutos 60

const TOLERANCIA_CRECIMIENTO := 1.15   # 15 % de margen sobre la línea base

var _muestras: Array[Dictionary] = []
var _t := 0.0
var _minutos := 60.0

func _initialize() -> void:
	_minutos = float(_arg("--minutos", "60"))
	print("Soak test: %d minutos" % _minutos)

func _process(delta: float) -> bool:
	_t += delta
	_simular_partida(delta)

	if int(_t) % 60 == 0:
		_muestras.append({
			"min": _t / 60.0,
			"memoria": OS.get_static_memory_usage(),
			"objetos": Performance.get_monitor(Performance.OBJECT_COUNT),
			"nodos": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		})

	if _t / 60.0 >= _minutos:
		return _veredicto()
	return false

func _veredicto() -> bool:
	# La memoria FLUCTÚA; lo que delata una fuga es el crecimiento SOSTENIDO.
	# Comparamos el primer y el último tercio, no el primer y el último punto.
	var n := _muestras.size()
	var base := _media(_muestras.slice(0, n / 3), "memoria")
	var final := _media(_muestras.slice(2 * n / 3), "memoria")
	var ratio := final / maxf(base, 1.0)
	var objetos_base := _media(_muestras.slice(0, n / 3), "objetos")
	var objetos_final := _media(_muestras.slice(2 * n / 3), "objetos")

	var fallos := 0
	if ratio > TOLERANCIA_CRECIMIENTO:
		fallos += 1
		printerr("  fuga de memoria: %.1f MB -> %.1f MB (×%.2f)"
			% [base / 1048576.0, final / 1048576.0, ratio])
	if objetos_final > objetos_base * TOLERANCIA_CRECIMIENTO:
		fallos += 1
		printerr("  fuga de objetos: %d -> %d" % [int(objetos_base), int(objetos_final)])

	print("== 2 comprobaciones, %d fallos ==" % fallos)
	quit(1 if fallos > 0 else 0)
	return true
```

7. **Load test.** Clientes simulados y percentiles, no medias:

```gdscript
extends SceneTree   # pruebas/load_test.gd -- --clientes 200 --segundos 60

var _latencias: Array[float] = []
var _errores := 0

func _correr(clientes: int, segundos: float) -> void:
	var servicio := ServicioEconomia.nuevo_para_pruebas()
	var rng := RandomNumberGenerator.new(); rng.seed = 5
	var t := 0.0
	while t < segundos:
		for c in clientes:
			var ini := Time.get_ticks_usec()
			var cmd := ComandoEconomia.nuevo(ComandoEconomia.Tipo.COMPRAR,
				StringName("plr_%d" % c), {"item": "pocion_menor", "cantidad": 1}, rng)
			var r := servicio.ejecutar(cmd, t)
			_latencias.append((Time.get_ticks_usec() - ini) / 1000.0)
			if int(r["resultado"]) not in [ServicioEconomia.Resultado.OK,
										   ServicioEconomia.Resultado.SIN_SALDO,
										   ServicioEconomia.Resultado.LIMITADO]:
				_errores += 1
		t += 0.1

	_latencias.sort()
	var p50 := _latencias[int(_latencias.size() * 0.50)]
	var p95 := _latencias[int(_latencias.size() * 0.95)]
	var p99 := _latencias[int(_latencias.size() * 0.99)]
	print("operaciones: %d · p50 %.2f ms · p95 %.2f ms · p99 %.2f ms · errores %d"
		% [_latencias.size(), p50, p95, p99, _errores])

	# CRITERIOS objetivos: sin ellos, "va bien" es una opinión.
	var fallos := 0
	if p99 > 50.0:  fallos += 1; printerr("  p99 por encima del presupuesto (50 ms)")
	if _errores > 0: fallos += 1; printerr("  %d errores inesperados" % _errores)
	print("== 2 comprobaciones, %d fallos ==" % fallos)
	quit(1 if fallos > 0 else 0)
```

8. **Cuándo corre cada cosa.** El reparto que hace que la CI siga siendo útil:

| Test | Cuándo | Duración | Bloquea el merge |
|---|---|---|---|
| Unitarios (GUT) | Cada push | < 30 s | Sí |
| Smoke | Cada push | < 30 s | Sí |
| Property-based | Cada push | < 60 s | Sí |
| Fuzz (500 iter.) | Cada push | < 60 s | Sí |
| Replays | Cada push | < 2 min | Sí |
| Soak (1 h) | Nocturno | 1 h | No, avisa |
| Load | Antes de release | 10 min | Sí, en la rama de release |

## ✍️ Ejercicios

1. Escribe tres propiedades del sistema de efectos de estado (clase 298) y busca contraejemplos.
2. Añade fuzzing al deserializador de saves y comprueba que ninguna entrada lo hace crashear.
3. Convierte tu escenario de integración en un replay y añádelo a la batería de regresión.
4. Ejecuta un soak de 8 horas y grafica memoria y número de nodos.
5. Encuentra el punto de rotura de tu servicio: sube clientes hasta que el p99 supere el presupuesto.
6. Añade un test que falle si algún test tarda más de lo que dice su categoría.
7. Identifica un test flaky de tu proyecto, diagnostica la causa y arréglalo o elimínalo.

## 📝 Reto verificable

Implementa una batería de testing de producción con: property-based testing con generadores y reducción para **al menos tres propiedades**, fuzzing de **al menos dos parsers**, tres replays de regresión, un smoke test, un soak test parametrizable y un load test con percentiles y criterios objetivos.

**Criterio de aceptación**: (a) todos los tests corren con `godot --headless` sin GPU y sin servicios externos; (b) cada test imprime `== N comprobaciones, M fallos ==` y devuelve código de salida distinto de 0 si falla; (c) el property-based encuentra y **reduce** un contraejemplo cuando se introduce a propósito un bug en `Inventario.agregar` (por ejemplo, olvidar el `min` con `max_stack`); (d) el fuzzing ejecuta al menos 500 mutaciones por parser sin un solo crash, y todas las entradas malformadas producen errores controlados; (e) el soak test detecta una fuga introducida a propósito (una lista que crece sin límite) y no da falso positivo en 30 minutos de ejecución normal; (f) el load test imprime p50, p95 y p99 y falla si el p99 supera el presupuesto declarado.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El property-based da un contraejemplo ilegible | Falta reducción. Implementa el shrinking, es lo que lo hace útil. |
| El test falla y no se puede reproducir | El generador no está sembrado. Semilla fija e imprímela al fallar. |
| El fuzzer marca como fallo un rechazo correcto | Se confunde error controlado con crash. Solo el crash o el cuelgue es fallo. |
| El soak test siempre falla | La tolerancia es demasiado estricta o se comparan puntos sueltos. Compara medias de tercios. |
| El load test da resultados distintos cada vez | Depende del hardware o hay aleatoriedad no sembrada. Fija la semilla y compara contra una línea base propia. |
| Los tests tardan 20 minutos y nadie los espera | Demasiados de nivel alto. Mueve lógica a unitarios y deja los lentos en nocturno. |
| Hay tests que fallan "a veces" y se ignoran | Tests flaky. Arréglalos o elimínalos: enseñan a ignorar los rojos. |
| La cobertura es del 90 % y siguen apareciendo bugs | La cobertura mide ejecución, no verificación. Añade propiedades y aserciones. |

## ❓ Preguntas frecuentes

**❓ ¿Property-based sustituye a los tests de ejemplo?** No: los complementa. Los de ejemplo documentan el comportamiento esperado y son legibles; los de propiedad buscan los casos que no imaginaste. Lo habitual es que un test de propiedad encuentre un contraejemplo y ese contraejemplo se convierta en un test de ejemplo permanente.

**❓ ¿El fuzzing no es una técnica de ataque?** El fuzzing es una técnica de **prueba**; se vuelve ataque cuando se aplica a un sistema ajeno sin autorización. En esta clase se usa exclusivamente contra parsers y protocolos propios, en local. Esa distinción —propio y autorizado— es la misma que separa una auditoría de un delito.

**❓ ¿Cuántas iteraciones de property-based?** 100-200 por propiedad en cada push (segundos) y varios miles en la ejecución nocturna con semillas distintas. Lo importante no es el número: es la **calidad del generador**, que debe producir casos límite (cero, uno, el máximo, el máximo más uno) y no solo valores medios.

**❓ ¿Puedo hacer soak testing en CI?** Sí, en la ejecución nocturna, no en cada push. Una hora basta para detectar la mayoría de fugas; ocho horas dan mucha más confianza para una release. Lo que no puedes es bloquear un merge durante una hora.

**❓ ¿Cómo evito tests que fallan por rendimiento del runner?** Comparando contra una **línea base medida en el mismo runner** en lugar de contra un número absoluto, y usando percentiles con margen. Es exactamente el problema que resuelve la [clase 321](../321-performance-regression-testing/README.md).

## 🔗 Referencias

- GUT — Godot Unit Test: <https://github.com/bitwes/Gut>
- Godot Docs — Command line tutorial (`--headless`, `--script`): <https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html>
- Godot Docs — `Performance` (monitores de memoria y objetos): <https://docs.godotengine.org/en/stable/classes/class_performance.html>
- QuickCheck — el artículo original de property-based testing (Claessen & Hughes): <https://dl.acm.org/doi/10.1145/351240.351266>
- Google — *Site Reliability Engineering*, capítulo de testing de fiabilidad: <https://sre.google/books/>
- OWASP — Fuzzing (uso defensivo): <https://owasp.org/www-community/Fuzzing>

## ⬅️ Clase anterior

[Clase 319 - Anti-cheat y respuesta frente al abuso](../319-anti-cheat-y-respuesta-frente-al-abuso/README.md)

## ➡️ Siguiente clase

[Clase 321 - Performance regression testing](../321-performance-regression-testing/README.md)
