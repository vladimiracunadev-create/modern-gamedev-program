# Clase 298 — Status effects, buffs y debuffs

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Documentación de Gameplay Effects (GAS) · Nystrom, «Game Programming Patterns»*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir el sistema de **efectos de estado**: veneno, quemadura, congelación, aturdimiento, regeneración, y los buffs y debuffs que modifican estadísticas durante un tiempo. Es el sistema donde más reglas implícitas se acumulan y peor documentadas suelen estar: ¿qué pasa si te envenenan dos veces? ¿se suma la duración, se reinicia, se apilan los daños, o el segundo veneno no hace nada?

Aquí vas a **hacer explícitas** esas reglas: políticas de apilamiento (`refresh`, `stack`, `independiente`, `ignorar`), efectos periódicos con su propio reloj, duración e inmunidades, prioridad y origen. Y lo harás encima de lo que ya tienes: un buff no es más que un modificador de la [clase 296](../296-equipamiento-loadouts-y-estadisticas/README.md) con caducidad, y un aturdimiento es un tag de la [clase 297](../297-ability-system-arquitectura-de-habilidades/README.md) que bloquea habilidades. Eso es lo que demuestra que la arquitectura estaba bien puesta.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Modelar un efecto de estado como definición (dato) + instancia activa (estado).
2. Implementar las cuatro políticas de apilamiento y elegir la correcta para cada efecto.
3. Implementar efectos **periódicos** con acumulador propio, independientes del framerate.
4. Aplicar y retirar modificadores y tags de forma que no quede residuo al expirar.
5. Implementar dispel, inmunidad y resistencia a la duración.
6. Explicar por qué el **origen** de un efecto es parte de su identidad.
7. Probar el sistema headless avanzando el tiempo a mano.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Efecto instantáneo vs con duración | Son dos cosas distintas y conviene no mezclarlas en una clase. |
| 2 | Políticas de apilamiento | La regla que más discusiones de diseño genera y menos se escribe. |
| 3 | Duración y refresh | Determina si un DoT se puede mantener indefinidamente. |
| 4 | Efectos periódicos | El "tick" del veneno tiene su propio reloj, no el del frame. |
| 5 | Modificadores temporales | Reutilizan el sistema de stats: un buff es un mod con caducidad. |
| 6 | Tags de estado | Aturdido, silenciado, invulnerable: bloquean acciones sin `if` a medida. |
| 7 | Origen y ownership | Quién aplicó el efecto decide el daño y quién recibe el crédito. |
| 8 | Dispel e inmunidad | Contrajuego: quitar efectos y evitarlos. |
| 9 | Prioridad | Cuando dos efectos se contradicen, alguien tiene que ganar. |
| 10 | Límite de acumulación | Sin tope, cualquier DoT apilable acaba siendo infinito. |

## 📖 Definiciones y características

- **Status effect (efecto de estado)**: modificación temporal del estado de una entidad, con duración y reglas propias. Clave: tiene ciclo de vida, no es un valor suelto.
- **Buff**: efecto de estado beneficioso. Clave: técnicamente idéntico a un debuff; solo cambia el signo y la presentación.
- **Debuff**: efecto de estado perjudicial. Clave: suele ser dispelable y resistible, el buff no.
- **DoT (damage over time)**: efecto que aplica daño periódicamente. Clave: su daño total depende de duración × frecuencia, no del número que aparece en el tooltip.
- **HoT (heal over time)**: equivalente con curación. Clave: comparte toda la maquinaria con el DoT.
- **Efecto instantáneo**: cambio inmediato sin duración (un golpe, una poción). Clave: no entra en el gestor de efectos; se aplica y desaparece.
- **Política de apilamiento**: regla que decide qué ocurre al aplicar un efecto que ya está activo. Clave: debe estar en la definición, no en el código que lo aplica.
- **Refresh**: la nueva aplicación reinicia la duración sin acumular potencia. Clave: la política más común para DoT de un solo lanzador.
- **Stack (acumulable)**: la nueva aplicación aumenta un contador que multiplica el efecto, hasta un tope. Clave: sin tope es una bomba de balance.
- **Independiente**: cada aplicación vive por su cuenta con su propia duración. Clave: útil cuando el origen importa (varios jugadores envenenando).
- **Ignorar**: si ya está activo, la nueva aplicación no hace nada. Clave: evita cadenas de aturdimiento infinitas.
- **Periodo (tick rate)**: cada cuánto se aplica el efecto periódico. Clave: se acumula con `delta`, nunca se cuenta en frames.
- **Dispel**: acción que retira efectos según un criterio (tipo, escuela, cantidad). Clave: es contrajuego, y necesita saber qué es dispelable.
- **Inmunidad**: estado que impide aplicar cierto efecto. Clave: se comprueba **antes** de aplicar, no después.
- **Resistencia a duración**: reducción porcentual del tiempo de un debuff. Clave: alternativa más fina que la inmunidad binaria.
- **Prioridad**: valor que decide qué efecto manda cuando dos son incompatibles. Clave: sin ella, gana el último aplicado, que es aleatorio.
- **Diminishing returns**: reducción progresiva de la duración al reaplicar el mismo control en poco tiempo. Clave: evita el encadenamiento infinito en PvP.

## 🧰 Herramientas y preparación

Necesitas `Stats` (clase 296) y `Tags` (clase 297). Trabajaremos en `res://dominio/efectos/`. Igual que el sistema de habilidades, este avanza con un `tick(delta)` explícito para poder probarlo headless y replicarlo. Ten a mano la [documentación de Gameplay Effects de Unreal](https://dev.epicgames.com/documentation/en-us/unreal-engine/gameplay-effects-for-the-gameplay-ability-system-in-unreal-engine) como referencia conceptual de las políticas de apilamiento.

## 🧪 Laboratorio guiado

1. **La definición del efecto.** Todas las reglas, en datos:

```gdscript
class_name EfectoDefinicion
extends RefCounted

enum Apilamiento { REFRESH, STACK, INDEPENDIENTE, IGNORAR }

var id: StringName
var nombre: String
var duracion: float = 0.0            # 0 = permanente hasta que lo quiten
var periodo: float = 0.0             # 0 = no periódico
var apilamiento: Apilamiento = Apilamiento.REFRESH
var max_stacks: int = 1
var prioridad: int = 0
var dispelable := true
var beneficioso := false
var tags_aplicados: PackedStringArray = []     # p. ej. ["estado.aturdido"]
var modificadores: Array[Dictionary] = []      # {stat, modo, valor} por stack
var por_tick: Array[Dictionary] = []           # {tipo: "dano"|"curar", valor}

static func de_dict(d: Dictionary) -> EfectoDefinicion:
	var e := EfectoDefinicion.new()
	e.id = StringName(str(d.get("id", "")))
	e.nombre = str(d.get("nombre", ""))
	e.duracion = float(d.get("duracion", 0.0))
	e.periodo = float(d.get("periodo", 0.0))
	e.apilamiento = EfectoDefinicion.Apilamiento.get(
		str(d.get("apilamiento", "REFRESH")), Apilamiento.REFRESH)
	e.max_stacks = int(d.get("max_stacks", 1))
	e.prioridad = int(d.get("prioridad", 0))
	e.dispelable = bool(d.get("dispelable", true))
	e.beneficioso = bool(d.get("beneficioso", false))
	e.tags_aplicados = PackedStringArray(d.get("tags", []))
	e.modificadores = d.get("modificadores", []) as Array[Dictionary]
	e.por_tick = d.get("por_tick", []) as Array[Dictionary]
	return e
```

Tres ejemplos que cubren casi todo el espacio de diseño:

```json
[
  { "id": "quemadura", "nombre": "Quemadura", "duracion": 4.0, "periodo": 1.0,
    "apilamiento": "STACK", "max_stacks": 5,
    "por_tick": [{ "tipo": "dano", "valor": 6 }], "tags": ["dano.fuego"] },

  { "id": "aturdimiento", "nombre": "Aturdido", "duracion": 2.0,
    "apilamiento": "IGNORAR", "prioridad": 100, "dispelable": false,
    "tags": ["estado.aturdido"] },

  { "id": "furia", "nombre": "Furia", "duracion": 10.0, "beneficioso": true,
    "apilamiento": "REFRESH",
    "modificadores": [{ "stat": "ataque", "modo": "porcentual", "valor": 0.25 }] }
]
```

2. **La instancia.** Lo que cambia con el tiempo:

```gdscript
class_name EfectoActivo
extends RefCounted

var definicion: EfectoDefinicion
var origen: StringName            # quién lo aplicó
var stacks: int = 1
var restante: float = 0.0
var _acumulado_tick: float = 0.0

func _init(d: EfectoDefinicion, origen_: StringName) -> void:
	definicion = d
	origen = origen_
	restante = d.duracion

func clave() -> StringName:
	# Un efecto INDEPENDIENTE se identifica también por su origen: el veneno de
	# dos jugadores distintos son dos efectos, no uno.
	if definicion.apilamiento == EfectoDefinicion.Apilamiento.INDEPENDIENTE:
		return StringName("%s@%s" % [definicion.id, origen])
	return definicion.id

func caducado() -> bool:
	return definicion.duracion > 0.0 and restante <= 0.0
```

3. **El gestor.** Aplicar es donde vive la política de apilamiento:

```gdscript
class_name Efectos
extends RefCounted

signal aplicado(id: StringName, stacks: int)
signal refrescado(id: StringName, stacks: int)
signal expirado(id: StringName)
signal tick_efecto(id: StringName, efecto: Dictionary, origen: StringName)

var _stats: Stats
var _tags: Tags
var _activos := {}              # clave -> EfectoActivo
var _inmunidades := {}          # StringName id -> segundos restantes
var _resistencia_duracion := 0.0

func _init(stats: Stats, tags: Tags) -> void:
	_stats = stats
	_tags = tags

func aplicar(d: EfectoDefinicion, origen: StringName = &"desconocido") -> bool:
	if _inmunidades.has(d.id):
		return false                      # la inmunidad se comprueba ANTES

	var provisional := EfectoActivo.new(d, origen)
	var clave := provisional.clave()
	var existente: EfectoActivo = _activos.get(clave)

	if existente == null:
		provisional.restante = _duracion_efectiva(d)
		_activos[clave] = provisional
		_aplicar_capa(provisional)
		aplicado.emit(d.id, provisional.stacks)
		return true

	match d.apilamiento:
		EfectoDefinicion.Apilamiento.IGNORAR:
			return false
		EfectoDefinicion.Apilamiento.REFRESH:
			existente.restante = _duracion_efectiva(d)
			refrescado.emit(d.id, existente.stacks)
		EfectoDefinicion.Apilamiento.STACK:
			_retirar_capa(existente)      # quitamos, subimos y volvemos a poner:
			existente.stacks = mini(existente.stacks + 1, d.max_stacks)
			existente.restante = _duracion_efectiva(d)
			_aplicar_capa(existente)      # así el nº de mods siempre cuadra
			refrescado.emit(d.id, existente.stacks)
		EfectoDefinicion.Apilamiento.INDEPENDIENTE:
			pass                          # nunca llega aquí: la clave incluye el origen
	return true

func _duracion_efectiva(d: EfectoDefinicion) -> float:
	if d.beneficioso or d.duracion <= 0.0:
		return d.duracion
	return d.duracion * (1.0 - clampf(_resistencia_duracion, 0.0, 0.9))
```

4. **Poner y quitar la "capa".** Aquí se ve por qué el sistema de la clase 296 estaba bien diseñado: aplicar un buff es añadir modificadores con un origen, y quitarlo es retirarlos por ese mismo origen.

```gdscript
func _origen_mod(e: EfectoActivo) -> StringName:
	return StringName("efecto:%s" % e.clave())

func _aplicar_capa(e: EfectoActivo) -> void:
	for m in e.definicion.modificadores:
		var modo := {"plano": Estadistica.Modo.PLANO,
					 "porcentual": Estadistica.Modo.PORCENTUAL,
					 "multiplicativo": Estadistica.Modo.MULTIPLICATIVO}.get(
						str(m.get("modo", "plano")), Estadistica.Modo.PLANO)
		# El valor escala con los stacks: 3 stacks de quemadura pegan el triple.
		_stats.get_stat(StringName(str(m["stat"]))).agregar_mod(
			_origen_mod(e), modo, float(m["valor"]) * e.stacks)
	for t in e.definicion.tags_aplicados:
		_tags.agregar(t)

func _retirar_capa(e: EfectoActivo) -> void:
	_stats.retirar_origen(_origen_mod(e))
	for t in e.definicion.tags_aplicados:
		_tags.quitar(t)
```

5. **El tick.** El acumulador propio es lo que hace que un veneno de 1 s pegue una vez por segundo tanto a 30 como a 144 fps:

```gdscript
func tick(delta: float) -> void:
	for id in _inmunidades.keys():
		_inmunidades[id] -= delta
		if _inmunidades[id] <= 0.0:
			_inmunidades.erase(id)

	# Iteramos sobre una copia: vamos a borrar del diccionario mientras.
	for clave in _activos.keys().duplicate():
		var e: EfectoActivo = _activos[clave]

		if e.definicion.periodo > 0.0:
			e._acumulado_tick += delta
			# 'while', no 'if': con un delta grande (o una pausa) puede tocar
			# más de un tick, y saltárselos regalaría daño al objetivo.
			while e._acumulado_tick >= e.definicion.periodo:
				e._acumulado_tick -= e.definicion.periodo
				for efecto in e.definicion.por_tick:
					var escalado := efecto.duplicate()
					escalado["valor"] = int(efecto.get("valor", 0)) * e.stacks
					tick_efecto.emit(e.definicion.id, escalado, e.origen)

		if e.definicion.duracion > 0.0:
			e.restante -= delta
			if e.caducado():
				_quitar(clave)

func _quitar(clave: StringName) -> void:
	var e: EfectoActivo = _activos.get(clave)
	if e == null:
		return
	_retirar_capa(e)                 # el residuo cero está garantizado aquí
	_activos.erase(clave)
	expirado.emit(e.definicion.id)
```

6. **Dispel e inmunidad.** El contrajuego:

```gdscript
func dispel(cantidad: int = 1, solo_perjudiciales := true) -> int:
	var candidatos := _activos.values().filter(func(e):
		return e.definicion.dispelable and (not solo_perjudiciales or not e.definicion.beneficioso))
	# Se quita primero lo más prioritario: dispelar debe quitar el aturdimiento,
	# no un +2 de velocidad.
	candidatos.sort_custom(func(a, b): return a.definicion.prioridad > b.definicion.prioridad)
	var quitados := 0
	for e in candidatos.slice(0, cantidad):
		_quitar(e.clave())
		quitados += 1
	return quitados

func inmunizar(id: StringName, segundos: float) -> void:
	_inmunidades[id] = segundos
	for clave in _activos.keys().duplicate():
		if _activos[clave].definicion.id == id:
			_quitar(clave)            # inmunizar también limpia lo que ya había

func activos() -> Array:
	return _activos.values()

func tiene(id: StringName) -> bool:
	return _activos.values().any(func(e): return e.definicion.id == id)

func stacks_de(id: StringName) -> int:
	for e in _activos.values():
		if e.definicion.id == id:
			return e.stacks
	return 0
```

7. **Probarlo.** Los casos importantes son los de apilamiento y los de residuo:

```gdscript
extends SceneTree

func _init() -> void:
	var stats := Stats.new(); var tags := Tags.new()
	var fx := Efectos.new(stats, tags)
	var quemadura := EfectoDefinicion.de_dict({
		"id": "quemadura", "duracion": 4.0, "periodo": 1.0,
		"apilamiento": "STACK", "max_stacks": 3,
		"por_tick": [{"tipo": "dano", "valor": 6}]})
	var furia := EfectoDefinicion.de_dict({
		"id": "furia", "duracion": 10.0, "beneficioso": true,
		"modificadores": [{"stat": "ataque", "modo": "plano", "valor": 5}]})

	var golpes := 0
	fx.tick_efecto.connect(func(_id, e, _o): golpes += int(e["valor"]))

	fx.aplicar(quemadura, &"mago")
	fx.aplicar(quemadura, &"mago")
	assert(fx.stacks_de(&"quemadura") == 2, "no se acumularon los stacks")
	for i in 40: fx.tick(0.1)                # 4 s → 4 ticks × 6 × 2 stacks
	assert(golpes == 48, "daño periódico incorrecto: %d" % golpes)
	assert(not fx.tiene(&"quemadura"), "la quemadura no expiró")

	var base := stats.valor(&"ataque")
	fx.aplicar(furia, &"self")
	assert(stats.valor(&"ataque") == base + 5.0, "el buff no modificó la stat")
	for i in 110: fx.tick(0.1)
	assert(stats.valor(&"ataque") == base, "el buff dejó residuo al expirar")

	print("== 6 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Implementa `diminishing returns`: cada reaplicación de un control en menos de 15 s dura la mitad, hasta inmunidad.
2. Añade un efecto `congelacion` que aplique el tag `estado.congelado` y un `-50 %` de velocidad, y comprueba la interacción con `quemadura` (la quemadura descongela).
3. Implementa `refrescar_hasta(max_duracion)` para DoT que se pueden extender pero con tope (pandemic).
4. Añade prioridad real: si hay `invulnerable`, ningún efecto perjudicial se aplica.
5. Escribe un test que aplique y retire 1.000 efectos aleatorios y verifique que al final no queda ni un modificador ni un tag.
6. Muestra los efectos activos en el HUD con su icono, stacks y tiempo restante, alimentado solo por señales.
7. Registra en telemetría cuántas veces se aplica cada efecto y su uptime medio, para balance.

## 📝 Reto verificable

Implementa el sistema completo con **al menos seis efectos**: un DoT acumulable, un HoT con refresh, un control con `IGNORAR`, un buff porcentual, un debuff independiente por origen y una inmunidad temporal.

**Criterio de aceptación**: una prueba headless con **al menos 20 aserciones** demuestra que: (a) tras aplicar y expirar cualquier combinación de efectos, todas las estadísticas vuelven a su valor base y `Tags` queda vacío (residuo cero); (b) un DoT de 4 s y periodo 1 s con 3 stacks aplica exactamente `4 × valor × 3` de daño, ni uno más; (c) el mismo DoT lanzado por dos orígenes con política `INDEPENDIENTE` produce **dos** efectos activos; (d) aplicar un control con política `IGNORAR` mientras está activo devuelve `false` y no reinicia su duración; (e) avanzar el tiempo con `tick(1.0)` una vez y con `tick(0.1)` diez veces produce el mismo daño total.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El buff expira y el personaje conserva la bonificación | No se retiraron los modificadores por origen. Centraliza la salida en `_quitar()`. |
| El veneno pega más a 144 fps que a 30 | Se aplicó el daño por frame. Usa un acumulador y `while` con el periodo. |
| Al pausar y reanudar, el DoT descarga varios ticks de golpe | Es lo correcto con `while`, pero puede no ser lo deseado. Acota los ticks recuperables o congela el acumulador en pausa. |
| Con dos venenos de dos jugadores solo cuenta uno | Política `REFRESH` cuando querías `INDEPENDIENTE`. La clave debe incluir el origen. |
| El aturdimiento se encadena y el jugador no juega nunca | Falta `IGNORAR` o diminishing returns. Ambas son decisiones de diseño explícitas. |
| "Invalid access on base Nil" al expirar un efecto | Se modificó el diccionario mientras se iteraba. Itera sobre `keys().duplicate()`. |
| Los stacks suben pero el daño no | Se aplicó el modificador una vez y no se reescala. Retira y vuelve a aplicar la capa al cambiar stacks. |
| El personaje se queda aturdido para siempre | Los tags se guardaron como booleanos. Cuenta fuentes en `Tags`. |

## ❓ Preguntas frecuentes

**❓ ¿Efectos instantáneos también aquí?** No hace falta. Un golpe o una poción se aplican y desaparecen: van directos al pipeline de daño ([clase 299](../299-arquitectura-avanzada-de-combate-y-dano/README.md)) o a `Stats`. Este gestor es para lo que tiene **ciclo de vida**.

**❓ ¿Qué política elijo?** Reglas prácticas: `IGNORAR` para controles (aturdir, congelar), `REFRESH` para DoT de un solo lanzador y buffs propios, `STACK` con tope bajo (3-5) para efectos que quieres que premien la insistencia, `INDEPENDIENTE` cuando varios jugadores puedan aplicar lo mismo y el crédito del daño importe.

**❓ ¿Y el daño del DoT lo calcula quién?** El gestor solo emite `tick_efecto`. Quien lo aplica es el pipeline de daño, que sabe de resistencias y críticos. Así un veneno respeta la resistencia al veneno sin que este sistema sepa qué es una resistencia.

**❓ ¿Por qué el origen forma parte de la identidad?** Por tres razones prácticas: para las tablas de daño ("¿quién mató a quién?"), para que el daño escale con las stats **del lanzador** aunque cambien después, y para que dos jugadores no se pisen los DoT.

**❓ ¿Esto vale para efectos de entorno (lava, veneno de zona)?** Sí: aplica un efecto con duración corta y refrescalo cada frame mientras la entidad esté dentro. Al salir, expira solo. Es un patrón muy usado y no necesita nada nuevo.

## 🔗 Referencias

- Unreal Engine Docs — Gameplay Effects (referencia conceptual de políticas de apilamiento): <https://dev.epicgames.com/documentation/en-us/unreal-engine/gameplay-effects-for-the-gameplay-ability-system-in-unreal-engine> · uso: se instala o se consulta en la preparación
- Robert Nystrom — *Game Programming Patterns*, Update Method: <https://gameprogrammingpatterns.com/update-method.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `Timer` y tiempo de juego: <https://docs.godotengine.org/en/4.3/classes/class_timer.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — Diccionarios y arrays: <https://docs.godotengine.org/en/4.3/classes/class_dictionary.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- GDC Vault — charlas sobre diseño de combate, control y contrajuego: <https://www.gdcvault.com/> — catálogo por tema, no una charla identificada (ponente y año pendientes) · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 297 - Ability System: arquitectura de habilidades](../297-ability-system-arquitectura-de-habilidades/README.md)

## ➡️ Siguiente clase

[Clase 299 - Arquitectura avanzada de combate y daño](../299-arquitectura-avanzada-de-combate-y-dano/README.md)
