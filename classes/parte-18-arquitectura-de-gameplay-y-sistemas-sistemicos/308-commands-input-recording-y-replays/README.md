# Clase 308 — Commands, input recording y replays

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Nystrom, «Game Programming Patterns» (Command) · Charlas de GDC sobre replays deterministas y testing automatizado*
> ⏱️ Duración estimada: **125 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Aplicar el patrón **Command** al gameplay y descubrir todo lo que se obtiene gratis al hacerlo: deshacer, rebinding de teclas, IA que "juega" con el mismo código que el jugador, grabación de partidas, replays, ghosts de carreras y —lo más valioso para un equipo— **tests de regresión que reproducen una partida entera** y comprueban que el resultado sigue siendo el mismo.

La idea es sencilla: en vez de que el jugador mueva al personaje, el jugador **emite un comando** y el juego lo aplica. Si además el juego es determinista (mismo estado + mismos comandos = mismo resultado), grabar la partida se reduce a guardar la lista de comandos y la semilla. Un replay de diez minutos ocupa unos pocos kilobytes, y un bug que solo pasa "a veces" se convierte en un archivo que puedes adjuntar a un issue.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Convertir entrada directa en **comandos** con datos explícitos y sin estado oculto.
2. Implementar una cola de comandos con marca de tick y aplicarla de forma determinista.
3. Enumerar las fuentes de indeterminismo de un juego y neutralizarlas una a una.
4. Grabar una partida (semilla + comandos) y reproducirla con resultado idéntico.
5. Implementar deshacer/rehacer con comandos reversibles.
6. Usar un replay como **test de regresión** con verificación por hash de estado.
7. Explicar la relación entre este modelo y el netcode determinista de la Parte 7.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Patrón Command | Convierte una acción en un dato que se puede guardar, enviar y repetir. |
| 2 | Tick fijo | Sin paso de simulación fijo no hay determinismo posible. |
| 3 | Fuentes de indeterminismo | Reloj, RNG, orden de iteración, coma flotante, hilos. |
| 4 | Grabación | Semilla + comandos = partida completa en pocos KB. |
| 5 | Reproducción | Aplicar los comandos al mismo estado inicial. |
| 6 | Hash de estado | La forma de detectar en qué tick empezó a divergir. |
| 7 | Deshacer / rehacer | Sale gratis si los comandos son reversibles. |
| 8 | Rebinding y accesibilidad | La entrada deja de estar cableada a una tecla. |
| 9 | Bots y demos | Un bot es una fuente de comandos más. |
| 10 | Replay como test | El test de integración más barato que existe. |

## 📖 Definiciones y características

- **Command (comando)**: objeto que representa una acción a ejecutar, con todos sus datos. Clave: es dato, así que se guarda, se envía y se repite.
- **Cola de comandos**: lista ordenada de comandos pendientes con su tick. Clave: el orden debe ser total y estable.
- **Tick**: paso discreto de simulación con `delta` fijo. Clave: es el reloj del determinismo; `_process` no sirve.
- **Paso fijo (fixed timestep)**: avanzar la simulación siempre con el mismo `delta`. Clave: sin él, el mismo input da resultados distintos según el framerate.
- **Determinismo**: propiedad de que el mismo estado inicial y la misma secuencia de entradas producen el mismo resultado. Clave: es una decisión de arquitectura, no algo que ocurra solo.
- **Fuente de indeterminismo**: cualquier cosa que varíe entre dos ejecuciones (hora del sistema, RNG global, orden de un diccionario, hilos). Clave: hay que enumerarlas y eliminarlas.
- **Semilla (seed)**: valor inicial del RNG, guardado con el replay. Clave: sin ella no hay reproducción posible.
- **Grabación (recording)**: archivo con estado inicial, semilla y lista de comandos por tick. Clave: es órdenes de magnitud más pequeño que grabar el estado.
- **Replay**: reproducción de una grabación aplicando sus comandos. Clave: no reproduce vídeo, re-simula el juego.
- **Hash de estado**: resumen numérico del estado del juego en un tick. Clave: comparar hashes localiza el tick exacto de la divergencia.
- **Desincronización (desync)**: divergencia entre dos ejecuciones que deberían coincidir. Clave: es el fallo característico de este modelo y del netcode determinista.
- **Comando reversible**: comando que sabe deshacerse. Clave: es lo que habilita el deshacer/rehacer.
- **Rebinding**: reasignación de la entrada física a un comando. Clave: es accesibilidad, y es gratis con este modelo.
- **Ghost**: reproducción de la grabación de otra partida junto a la actual. Clave: solo necesita los comandos del otro jugador.
- **Test de regresión por replay**: prueba que reproduce una partida y compara hashes. Clave: cubre integración real a coste casi nulo.
- **Grabación de entradas vs de estado**: dos formas de grabar. Clave: la de entradas es diminuta y frágil; la de estado es enorme y robusta.

## 🧰 Herramientas y preparación

Necesitas los sistemas de la parte con `tick(delta)` explícito: habilidades (297), efectos (298) y combate (299). Trabajaremos en `res://dominio/comandos/`. Repasa de la Parte 7 la clase [147](../../parte-7-multijugador-y-networking/147-lag-compensation-y-rollback-netcode/README.md): el rollback netcode es este mismo modelo aplicado a la red, y muchas de las trampas son las mismas.

## 🧪 Laboratorio guiado

1. **El comando.** Datos, no comportamiento oculto:

```gdscript
class_name Comando
extends RefCounted

enum Tipo { MOVER, SALTAR, ATACAR, USAR_HABILIDAD, USAR_ITEM, INTERACTUAR }

var tick: int = 0
var actor: int = 0                    # id del actor (jugador 0, bot 1…)
var tipo: Tipo = Tipo.MOVER
var eje: Vector2 = Vector2.ZERO       # para MOVER
var arg: StringName = &""             # id de habilidad o de item

func a_array() -> Array:
	# Formato compacto: un replay de 10 min son ~36.000 entradas como esta.
	return [tick, actor, int(tipo), snappedf(eje.x, 0.001), snappedf(eje.y, 0.001), String(arg)]

static func de_array(a: Array) -> Comando:
	var c := Comando.new()
	c.tick = int(a[0]); c.actor = int(a[1]); c.tipo = int(a[2]) as Tipo
	c.eje = Vector2(float(a[3]), float(a[4])); c.arg = StringName(str(a[5]))
	return c
```

Fíjate en el `snappedf`: cuantizar el eje a milésimas evita que un `0.7071067811865476` de un joystick se guarde con más precisión de la que el `float` de destino puede reproducir. Es una de las causas más silenciosas de desync.

2. **La simulación con paso fijo.** El reloj del determinismo:

```gdscript
class_name Simulacion
extends RefCounted

const DT := 1.0 / 60.0            # paso FIJO: nunca el delta del frame

var tick: int = 0
var rng := RandomNumberGenerator.new()
var _actores := {}                 # id -> estado (dominio puro)
var _pendientes: Array[Comando] = []

func iniciar(semilla: int) -> void:
	tick = 0
	rng.seed = semilla             # el RNG es del sistema, no el global
	_actores.clear()
	_actores[0] = {"pos": Vector2.ZERO, "vida": 100, "cooldown": 0.0}

func encolar(c: Comando) -> void:
	_pendientes.append(c)

func avanzar() -> void:
	# 1) Los comandos de ESTE tick, en orden TOTAL y estable. Si dos comandos
	#    del mismo tick se aplicaran en distinto orden en dos ejecuciones, ya
	#    tendríamos desync: por eso se ordena por (tick, actor, tipo).
	var de_este := _pendientes.filter(func(c): return c.tick == tick)
	de_este.sort_custom(func(a, b):
		if a.actor != b.actor: return a.actor < b.actor
		return int(a.tipo) < int(b.tipo))
	for c in de_este:
		_aplicar(c)
	_pendientes = _pendientes.filter(func(c): return c.tick > tick)

	# 2) Avanzar los sistemas con DT fijo.
	for id in _actores.keys():
		var a: Dictionary = _actores[id]
		a["cooldown"] = maxf(0.0, a["cooldown"] - DT)
	tick += 1

func _aplicar(c: Comando) -> void:
	var a: Dictionary = _actores.get(c.actor, {})
	if a.is_empty():
		return
	match c.tipo:
		Comando.Tipo.MOVER:
			a["pos"] += c.eje.normalized() * 200.0 * DT
		Comando.Tipo.ATACAR:
			if a["cooldown"] <= 0.0:
				a["cooldown"] = 0.5
				# Aleatoriedad SIEMPRE del rng de la simulación.
				a["ultimo_dano"] = rng.randi_range(8, 12)
		_:
			pass
```

3. **El hash de estado.** La herramienta que convierte "hay un desync" en "el desync empieza en el tick 4.812":

```gdscript
func hash_estado() -> int:
	# Iteramos en orden ORDENADO de claves: el orden de un Dictionary no está
	# garantizado entre ejecuciones y sería una fuente de divergencia.
	var trozos := PackedStringArray()
	var ids := _actores.keys()
	ids.sort()
	for id in ids:
		var a: Dictionary = _actores[id]
		# Cuantizamos los floats: comparar bit a bit es demasiado frágil.
		trozos.append("%d:%d,%d,%d" % [
			id, int(a["pos"].x * 1000.0), int(a["pos"].y * 1000.0), int(a["vida"])])
	return hash("|".join(trozos))
```

4. **La grabación:**

```gdscript
class_name Grabacion
extends RefCounted

const VERSION := 1

var semilla: int = 0
var build: String = ""
var comandos: Array[Comando] = []
var hashes := {}                   # tick -> hash (uno cada N ticks)

func grabar(c: Comando) -> void:
	comandos.append(c)

func a_dict() -> Dictionary:
	return {
		"version": VERSION, "semilla": semilla, "build": build,
		"comandos": comandos.map(func(c): return c.a_array()),
		"hashes": hashes,
	}

func guardar(ruta: String) -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(JSON.stringify(a_dict()))
	f.close()

static func cargar(ruta: String) -> Grabacion:
	var d = JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())
	var g := Grabacion.new()
	g.semilla = int(d.get("semilla", 0))
	g.build = str(d.get("build", ""))
	for a in d.get("comandos", []):
		g.comandos.append(Comando.de_array(a))
	g.hashes = d.get("hashes", {})
	return g
```

5. **El grabador y el reproductor.** Dos objetos pequeños que hacen todo el trabajo:

```gdscript
class_name Grabador
extends RefCounted

const CADA_N_TICKS := 60           # un hash por segundo: suficiente para localizar

var grabacion := Grabacion.new()
var _sim: Simulacion

func empezar(sim: Simulacion, semilla: int, build: String) -> void:
	_sim = sim
	grabacion = Grabacion.new()
	grabacion.semilla = semilla
	grabacion.build = build
	sim.iniciar(semilla)

func enviar(c: Comando) -> void:
	c.tick = _sim.tick
	grabacion.grabar(c)
	_sim.encolar(c)

func avanzar() -> void:
	if _sim.tick % CADA_N_TICKS == 0:
		grabacion.hashes[str(_sim.tick)] = _sim.hash_estado()
	_sim.avanzar()
```

```gdscript
class_name Reproductor
extends RefCounted

signal divergencia(tick: int, esperado: int, obtenido: int)
signal fin()

var _sim: Simulacion
var _g: Grabacion
var _ultimo_tick: int = 0

func cargar(sim: Simulacion, g: Grabacion) -> void:
	_sim = sim
	_g = g
	sim.iniciar(g.semilla)          # mismo estado inicial, misma semilla
	for c in g.comandos:
		sim.encolar(c)
		_ultimo_tick = maxi(_ultimo_tick, c.tick)

func reproducir_todo() -> bool:
	var ok := true
	while _sim.tick <= _ultimo_tick:
		var clave := str(_sim.tick)
		if _g.hashes.has(clave):
			var esperado := int(_g.hashes[clave])
			var obtenido := _sim.hash_estado()
			if esperado != obtenido:
				divergencia.emit(_sim.tick, esperado, obtenido)
				ok = false
				break               # seguir no aporta: ya diverge todo
		_sim.avanzar()
	fin.emit()
	return ok
```

6. **Deshacer / rehacer.** Cuando el comando sabe revertirse, sale gratis:

```gdscript
class_name Historial
extends RefCounted

var _hechos: Array[Dictionary] = []     # {comando, deshacer: Callable}
var _deshechos: Array[Dictionary] = []

func ejecutar(c: Comando, hacer: Callable, deshacer: Callable) -> void:
	hacer.call(c)
	_hechos.append({"comando": c, "deshacer": deshacer})
	_deshechos.clear()                  # una acción nueva invalida el rehacer

func deshacer() -> bool:
	if _hechos.is_empty():
		return false
	var e: Dictionary = _hechos.pop_back()
	e["deshacer"].call(e["comando"])
	_deshechos.append(e)
	return true
```

Esto es exactamente lo que necesita un editor de niveles in-game ([clase 265](../../parte-15-herramientas-editores-y-automatizacion/265-editores-de-niveles-y-contenido-in-game/README.md)) o un modo constructor.

7. **El replay como test de regresión.** El pago final de toda la clase:

```gdscript
extends SceneTree   # godot --headless --script res://pruebas/replays_test.gd

func _init() -> void:
	var fallos := 0
	var hechas := 0
	for ruta in _listar("res://pruebas/replays/"):
		hechas += 1
		var g := Grabacion.cargar(ruta)
		var sim := Simulacion.new()
		var rep := Reproductor.new()
		rep.divergencia.connect(func(t, e, o):
			printerr("  %s diverge en el tick %d (esperado %d, obtenido %d)" % [ruta, t, e, o]))
		rep.cargar(sim, g)
		if not rep.reproducir_todo():
			fallos += 1
	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)

func _listar(dir: String) -> Array[String]:
	var salida: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".json"):
			salida.append(dir + f)
	return salida
```

Cada replay guardado es un test de integración completo: recorre combate, habilidades, efectos e inventario a la vez, tarda milisegundos y **detecta cualquier cambio de comportamiento**, incluidos los que no querías hacer.

8. **La lista de indeterminismos.** Antes de dar esto por bueno, repasa una por una:

| Fuente | Síntoma | Solución |
|---|---|---|
| `randf()` global | El replay diverge en el primer crítico | `RandomNumberGenerator` por sistema, sembrado |
| `delta` del frame | Diverge según el framerate | Paso fijo `DT` |
| `Time.get_unix_time_from_system()` | Diverge entre ejecuciones | Tiempo de juego acumulado |
| Orden de `Dictionary` | Diverge a veces, sin patrón | Ordenar las claves antes de iterar |
| Orden de nodos del árbol | Diverge al reordenar la escena | No iterar el árbol en el dominio |
| Hilos | Diverge de forma irreproducible | La simulación, en un solo hilo |
| Físicas del motor | Diverge entre plataformas | Simular el dominio propio, no el solver |

## ✍️ Ejercicios

1. Añade rebinding: una tabla `tecla → Comando.Tipo` cargada de un archivo, editable en opciones.
2. Implementa un bot que emita comandos por un patrón fijo y grábalo como replay de referencia.
3. Añade velocidad de reproducción (×0.5, ×2) y salto a un tick concreto.
4. Implementa un ghost: reproduce dos grabaciones a la vez y dibuja ambas posiciones.
5. Comprime la grabación con `FileAccess.open_compressed` y mide el tamaño de 10 minutos.
6. Provoca un desync a propósito (usa `randf()` global en un sitio) y localiza el tick con los hashes.
7. Añade a la grabación la versión de build y rechaza reproducir grabaciones de otra build con un aviso.

## 📝 Reto verificable

Implementa el sistema de comandos con simulación de paso fijo, grabación, reproducción, hashes periódicos, deshacer/rehacer y una batería de replays de regresión.

**Criterio de aceptación**: (a) `godot --headless --script res://pruebas/replays_test.gd` reproduce **al menos tres** grabaciones de 30 segundos y termina con `0 fallos` y código de salida 0; (b) reproducir la misma grabación dos veces produce hashes idénticos en todos los puntos de control; (c) introducir a propósito una llamada a `randf()` global hace que el test falle **indicando el tick** de la divergencia; (d) una grabación de 60 segundos a 60 ticks/s ocupa menos de 200 KB; (e) `deshacer()` seguido de `rehacer()` deja el estado con el mismo hash que antes de deshacer; (f) la simulación no contiene ninguna llamada a `Time.get_ticks_msec`, `randf()` global ni `get_tree()`.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El replay diverge siempre en el mismo punto | Hay una fuente de indeterminismo fija (RNG global, reloj). Repasa la tabla del paso 8. |
| El replay diverge "a veces" | Orden de iteración de un diccionario o un hilo. Ordena claves; simula en un hilo. |
| Diverge solo en otra máquina | Coma flotante o físicas del motor. Cuantiza el hash y simula tu propio dominio. |
| El archivo de replay es enorme | Se está grabando estado, no comandos. Graba comandos y la semilla. |
| El replay carga pero no pasa nada | Los comandos tienen ticks que ya pasaron. Comprueba que `tick` se asigna al encolar. |
| Deshacer deja el juego en un estado raro | El comando no revierte todos sus efectos secundarios. Un comando que no sabe deshacerse no debe entrar en el historial. |
| Al actualizar el juego, los replays viejos fallan | Es lo esperado: el comportamiento ha cambiado. Guarda la build en la grabación y regrábalos a propósito. |
| El bot y el jugador se comportan distinto | El bot no pasa por los comandos. Toda entrada, sea humana o no, debe ser un comando. |

## ❓ Preguntas frecuentes

**❓ ¿Grabo comandos o grabo estado?** Comandos, casi siempre: ocupan miles de veces menos y sirven de test. Su fragilidad —cualquier cambio de comportamiento invalida los replays viejos— es en realidad una ventaja cuando los usas como regresión: te avisan de que has cambiado algo. Para replays que el jugador vaya a **compartir** entre versiones, graba estado o acepta que caducan.

**❓ ¿Merece la pena en un juego single-player?** Los tests de regresión por replay, sí, casi siempre: son el test de integración más barato que existe. El determinismo completo cuesta disciplina, pero la mayor parte ya la tienes si has seguido esta parte: tus sistemas avanzan con `tick(delta)` y su RNG inyectado.

**❓ ¿Esto es lo mismo que el rollback netcode?** Es la misma base. El rollback ([clase 147](../../parte-7-multijugador-y-networking/147-lag-compensation-y-rollback-netcode/README.md)) añade re-simular hacia atrás cuando llegan entradas tarde; si tienes determinismo y comandos, ya tienes la mitad del trabajo hecho.

**❓ ¿Cómo hago que el `float` no me arruine el determinismo?** Tres medidas prácticas: cuantiza las entradas (`snappedf`), cuantiza el hash (multiplica por 1000 y trunca) y no dependas del solver de físicas del motor para nada que grabes. Aritmética de punto fijo es la solución completa, pero rara vez hace falta si no compartes replays entre plataformas.

**❓ ¿Y el input analógico y las repeticiones?** El eje se cuantiza y se graba solo cuando **cambia**: un stick quieto no genera comandos. Eso reduce el tamaño de la grabación otro orden de magnitud y no afecta al determinismo, porque el estado del eje persiste hasta el siguiente comando.

## 🔗 Referencias

- Robert Nystrom — *Game Programming Patterns*, Command: <https://gameprogrammingpatterns.com/command.html> · uso: respalda el Tema 1 «Patrón Command»
- Robert Nystrom — *Game Programming Patterns*, Game Loop y paso fijo: <https://gameprogrammingpatterns.com/game-loop.html> · uso: respalda el Tema 2 «Tick fijo»
- Godot Docs — `RandomNumberGenerator`: <https://docs.godotengine.org/en/4.3/classes/class_randomnumbergenerator.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `_physics_process` y paso fijo: <https://docs.godotengine.org/en/4.3/tutorials/scripting/idle_and_physics_processing.html> · uso: respalda el Tema 2 «Tick fijo»
- GDC Vault — charlas sobre replays deterministas, rollback y testing automatizado: <https://www.gdcvault.com/> — catálogo por tema, no una charla identificada (ponente y año pendientes) · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 307 - Save System de producción](../307-save-system-de-produccion/README.md)

## ➡️ Siguiente clase

[Clase 309 - Modding y arquitectura extensible](../309-modding-y-arquitectura-extensible/README.md)
