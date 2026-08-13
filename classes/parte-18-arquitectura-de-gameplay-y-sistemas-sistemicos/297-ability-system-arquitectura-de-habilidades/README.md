# Clase 297 — Ability System: arquitectura de habilidades

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Documentación del Gameplay Ability System de Unreal Engine (referencia conceptual) · Nystrom, «Game Programming Patterns» (State, Command)*
> ⏱️ Duración estimada: **130 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir un **sistema de habilidades reutilizable**: una arquitectura donde añadir una bola de fuego, una embestida o una curación en área sea escribir una definición de datos y, como mucho, un pequeño script de efecto — no copiar y pegar 200 líneas con su propio cooldown, su propia comprobación de maná y su propia animación.

Estudiarás el modelo que los motores profesionales han convergido en usar (el *Gameplay Ability System* de Unreal es el ejemplo más documentado) y lo implementarás en Godot sin depender de él: **definición de habilidad**, **instancia en ejecución**, **fases** (activación, coste, casteo, ejecución, recuperación), **cooldowns**, **targeting**, **tags** para requisitos y bloqueos, y **cancelación e interrupción**. Al terminar tendrás un `AbilitySystem` que puede lanzar cualquier habilidad del catálogo y explicar por qué ha rechazado las que no.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Separar **definición** de habilidad e **instancia activa**, igual que con los items.
2. Modelar coste, cooldown, rango, duración, requisitos, tags y efectos como datos.
3. Implementar la máquina de fases de una habilidad y sus transiciones.
4. Implementar cooldowns con tiempo de juego (no de reloj) y consultarlos para la UI.
5. Usar **tags** para expresar requisitos, bloqueos e inmunidades sin escribir condiciones a medida.
6. Implementar cancelación e interrupción con limpieza garantizada de estado.
7. Explicar por qué el sistema devuelve un **motivo de fallo** en vez de un simple `false`.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Definición vs instancia | La misma habilidad la usan diez enemigos a la vez con cooldowns distintos. |
| 2 | Fases de una habilidad | Sin fases no hay animación creíble ni cancelación posible. |
| 3 | Coste y recursos | Maná, resistencia, munición: son la misma abstracción. |
| 4 | Cooldown | Regula el ritmo del combate; mal implementado, se salta con lag o pausa. |
| 5 | Targeting | Decide a quién afecta: uno, área, cono, self. |
| 6 | Tags y requisitos | Expresan "no si estás aturdido" sin un `if` por caso. |
| 7 | Efectos declarativos | La habilidad describe qué pasa; otro sistema lo ejecuta. |
| 8 | Cancelación e interrupción | La diferencia entre un combate reactivo y uno rígido. |
| 9 | Motivo de fallo | La UI necesita decir "sin maná", no solo apagar el botón. |
| 10 | Determinismo | Un sistema determinista se puede replicar en red y grabar en un replay. |

## 📖 Definiciones y características

- **AbilityDefinition**: dato inmutable que describe una habilidad (id, coste, cooldown, rango, tags, efectos). Clave: se comparte entre todos los que la conocen.
- **AbilityInstance**: estado en ejecución de una habilidad concreta en un lanzador concreto. Clave: es lo que tiene fase, tiempo restante y objetivo.
- **AbilitySystem**: componente que guarda las habilidades conocidas, sus cooldowns y ejecuta las activaciones. Clave: es el único punto por el que se lanza una habilidad.
- **Fase**: etapa de la ejecución (`INACTIVA`, `CASTEO`, `EJECUCION`, `RECUPERACION`). Clave: cada fase decide qué se puede cancelar y qué no.
- **Casteo (cast time)**: tiempo previo al efecto durante el cual la habilidad puede interrumpirse. Clave: sin casteo no hay contrajuego.
- **Recuperación (recovery)**: tiempo posterior al efecto durante el cual no se puede actuar. Clave: es lo que da peso al combate.
- **Coste**: recurso consumido al activar (maná, resistencia, munición). Clave: se cobra al iniciar la ejecución, no al pulsar.
- **Cooldown**: tiempo mínimo entre dos usos de la misma habilidad. Clave: se mide con tiempo de juego acumulado, nunca con la hora del sistema.
- **Global cooldown (GCD)**: cooldown corto compartido por todas las habilidades. Clave: impide encadenar diez habilidades en un frame.
- **Targeting**: forma de elegir objetivos (self, uno, área, cono, dirección). Clave: es un dato, no un `if` dentro de cada habilidad.
- **Rango**: distancia máxima al objetivo. Clave: se comprueba al activar y, en habilidades largas, también al ejecutar.
- **Gameplay Tag**: etiqueta jerárquica (`estado.aturdido`, `escuela.fuego`) usada para requisitos y bloqueos. Clave: permite reglas nuevas sin tocar código.
- **Requisito (`requiere` / `bloquea`)**: conjuntos de tags que deben estar o no estar presentes. Clave: sustituye a condiciones a medida por datos.
- **Cancelación**: fin voluntario de una habilidad por parte de quien la lanza. Clave: debe revertir lo reversible y no devolver el coste ya cobrado.
- **Interrupción**: fin forzado por un tercero (un golpe, un aturdimiento). Clave: es la que más estados a medias produce si no hay limpieza única.
- **Motivo de fallo**: enumeración que explica por qué no se pudo activar. Clave: la UI y la telemetría lo necesitan; `false` no informa de nada.

## 🧰 Herramientas y preparación

Necesitas `Stats` de la [clase 296](../296-equipamiento-loadouts-y-estadisticas/README.md) para los recursos y modificadores. Trabajaremos en `res://dominio/habilidades/`. El sistema completo es `RefCounted` y avanza con un `tick(delta)` explícito: eso lo hace determinista y probable headless, y es lo que permitirá replicarlo (Parte 7) y grabarlo en un replay ([clase 308](../308-commands-input-recording-y-replays/README.md)).

Si has trabajado con Unreal, esta arquitectura te sonará; el objetivo es que entiendas **por qué** es así, no que uses su API. Documentación conceptual de referencia: [Gameplay Ability System](https://dev.epicgames.com/documentation/en-us/unreal-engine/gameplay-ability-system-for-unreal-engine).

## 🧪 Laboratorio guiado

1. **La definición.** Todo lo que distingue una habilidad de otra, en datos:

```gdscript
class_name AbilityDefinition
extends RefCounted

enum Targeting { SELF, UNO, AREA, CONO, DIRECCION }

var id: StringName
var nombre: String
var coste_recurso: StringName = &"mana"
var coste: float = 0.0
var cooldown: float = 0.0
var tiempo_casteo: float = 0.0
var tiempo_recuperacion: float = 0.0
var rango: float = 0.0
var radio: float = 0.0
var targeting: Targeting = Targeting.UNO
var tags: PackedStringArray = []              # lo que ESTA habilidad es
var requiere_tags: PackedStringArray = []     # deben estar presentes en el lanzador
var bloquea_tags: PackedStringArray = []      # si alguna está, no se puede lanzar
var cancelable_en_casteo := true
var efectos: Array[Dictionary] = []

static func de_dict(d: Dictionary) -> AbilityDefinition:
	var a := AbilityDefinition.new()
	a.id = StringName(str(d.get("id", "")))
	a.nombre = str(d.get("nombre", ""))
	a.coste_recurso = StringName(str(d.get("coste_recurso", "mana")))
	a.coste = float(d.get("coste", 0.0))
	a.cooldown = float(d.get("cooldown", 0.0))
	a.tiempo_casteo = float(d.get("casteo", 0.0))
	a.tiempo_recuperacion = float(d.get("recuperacion", 0.0))
	a.rango = float(d.get("rango", 0.0))
	a.radio = float(d.get("radio", 0.0))
	a.targeting = AbilityDefinition.Targeting.get(str(d.get("targeting", "UNO")), Targeting.UNO)
	a.tags = PackedStringArray(d.get("tags", []))
	a.requiere_tags = PackedStringArray(d.get("requiere", []))
	a.bloquea_tags = PackedStringArray(d.get("bloquea", []))
	a.cancelable_en_casteo = bool(d.get("cancelable", true))
	a.efectos = d.get("efectos", []) as Array[Dictionary]
	return a
```

Y una habilidad de ejemplo, en `res://datos/habilidades.json`:

```json
{
  "id": "bola_fuego",
  "nombre": "Bola de fuego",
  "coste_recurso": "mana", "coste": 25,
  "cooldown": 6.0, "casteo": 1.2, "recuperacion": 0.4,
  "rango": 12.0, "radio": 3.0, "targeting": "AREA",
  "tags": ["escuela.fuego", "dano.magico"],
  "requiere": [], "bloquea": ["estado.aturdido", "estado.silenciado"],
  "cancelable": true,
  "efectos": [
    { "tipo": "dano", "valor": 40, "escala_con": "poder_magico" },
    { "tipo": "estado", "estado": "quemadura", "duracion": 4.0 }
  ]
}
```

2. **El motivo de fallo.** Antes que nada, el vocabulario de errores. Que la UI pueda decir *por qué*:

```gdscript
class_name Fallo
extends RefCounted

enum Motivo {
	OK, DESCONOCIDA, EN_COOLDOWN, SIN_RECURSO, FUERA_DE_RANGO,
	SIN_OBJETIVO, BLOQUEADA_POR_TAG, FALTA_REQUISITO, YA_ACTIVA, GCD,
}

const TEXTO := {
	Motivo.EN_COOLDOWN: "Aún no está lista",
	Motivo.SIN_RECURSO: "Recurso insuficiente",
	Motivo.FUERA_DE_RANGO: "Demasiado lejos",
	Motivo.BLOQUEADA_POR_TAG: "No puedes hacerlo ahora",
	Motivo.SIN_OBJETIVO: "Sin objetivo válido",
}
```

3. **El contenedor de tags.** Diez líneas que sustituyen a decenas de banderas booleanas:

```gdscript
class_name Tags
extends RefCounted

var _cuenta := {}          # tag -> nº de fuentes que la aplican

func agregar(t: String) -> void:
	_cuenta[t] = _cuenta.get(t, 0) + 1

func quitar(t: String) -> void:
	# Contamos fuentes: dos efectos que aturden y uno que acaba no deben
	# dejar al personaje andando.
	if not _cuenta.has(t):
		return
	_cuenta[t] -= 1
	if _cuenta[t] <= 0:
		_cuenta.erase(t)

func tiene(t: String) -> bool:
	return _cuenta.has(t)

func tiene_alguna(lista: PackedStringArray) -> bool:
	for t in lista:
		if tiene(t):
			return true
	return false

func tiene_todas(lista: PackedStringArray) -> bool:
	for t in lista:
		if not tiene(t):
			return false
	return true
```

4. **El sistema.** Comprobar, cobrar, ejecutar y enfriar — en ese orden y en un solo sitio:

```gdscript
class_name AbilitySystem
extends RefCounted

signal activada(id: StringName)
signal fase_cambiada(id: StringName, fase: int)
signal fallo(id: StringName, motivo: int)
signal efectos_aplicados(id: StringName, objetivos: Array, efectos: Array)

enum Fase { INACTIVA, CASTEO, EJECUCION, RECUPERACION }

const GCD := 0.4

var tags := Tags.new()
var _defs := {}                 # id -> AbilityDefinition
var _cooldowns := {}            # id -> segundos restantes
var _recursos := {}             # StringName -> float
var _activa: AbilityDefinition = null
var _fase: Fase = Fase.INACTIVA
var _t_fase := 0.0
var _gcd := 0.0
var _objetivos: Array = []

func aprender(d: AbilityDefinition) -> void:
	_defs[d.id] = d

func recurso(clave: StringName) -> float:
	return _recursos.get(clave, 0.0)

func fijar_recurso(clave: StringName, v: float) -> void:
	_recursos[clave] = maxf(0.0, v)

func cooldown_restante(id: StringName) -> float:
	return _cooldowns.get(id, 0.0)

func puede_activar(id: StringName, objetivos: Array, distancia: float) -> Fallo.Motivo:
	if not _defs.has(id):
		return Fallo.Motivo.DESCONOCIDA
	var d: AbilityDefinition = _defs[id]
	if _activa != null:
		return Fallo.Motivo.YA_ACTIVA
	if _gcd > 0.0:
		return Fallo.Motivo.GCD
	if cooldown_restante(id) > 0.0:
		return Fallo.Motivo.EN_COOLDOWN
	if tags.tiene_alguna(d.bloquea_tags):
		return Fallo.Motivo.BLOQUEADA_POR_TAG
	if not tags.tiene_todas(d.requiere_tags):
		return Fallo.Motivo.FALTA_REQUISITO
	if recurso(d.coste_recurso) < d.coste:
		return Fallo.Motivo.SIN_RECURSO
	if d.targeting != AbilityDefinition.Targeting.SELF and objetivos.is_empty():
		return Fallo.Motivo.SIN_OBJETIVO
	if d.rango > 0.0 and distancia > d.rango:
		return Fallo.Motivo.FUERA_DE_RANGO
	return Fallo.Motivo.OK

func activar(id: StringName, objetivos: Array = [], distancia: float = 0.0) -> Fallo.Motivo:
	var motivo := puede_activar(id, objetivos, distancia)
	if motivo != Fallo.Motivo.OK:
		fallo.emit(id, motivo)
		return motivo

	var d: AbilityDefinition = _defs[id]
	_activa = d
	_objetivos = objetivos.duplicate()
	# El coste se cobra AL ACTIVAR: si se cobrara al impactar, el jugador podría
	# encadenar tres castes antes de pagar el primero.
	fijar_recurso(d.coste_recurso, recurso(d.coste_recurso) - d.coste)
	_gcd = GCD
	_pasar_a(Fase.CASTEO if d.tiempo_casteo > 0.0 else Fase.EJECUCION)
	activada.emit(id)
	return Fallo.Motivo.OK
```

5. **El avance por fases.** Un `tick` explícito, sin `_process`: así el sistema es determinista y probable:

```gdscript
func tick(delta: float) -> void:
	_gcd = maxf(0.0, _gcd - delta)
	for id in _cooldowns.keys():
		_cooldowns[id] = maxf(0.0, _cooldowns[id] - delta)
		if _cooldowns[id] == 0.0:
			_cooldowns.erase(id)

	if _activa == null:
		return
	_t_fase += delta
	match _fase:
		Fase.CASTEO:
			if _t_fase >= _activa.tiempo_casteo:
				_pasar_a(Fase.EJECUCION)
		Fase.EJECUCION:
			_ejecutar()
			_pasar_a(Fase.RECUPERACION if _activa.tiempo_recuperacion > 0.0 else Fase.INACTIVA)
		Fase.RECUPERACION:
			if _t_fase >= _activa.tiempo_recuperacion:
				_pasar_a(Fase.INACTIVA)
		_:
			pass

func _ejecutar() -> void:
	# El sistema NO aplica daño: publica los efectos y quien sepa hacerlo los
	# aplica (clase 299). Así esto se puede probar sin un mundo.
	efectos_aplicados.emit(_activa.id, _objetivos, _activa.efectos)
	_cooldowns[_activa.id] = _activa.cooldown

func _pasar_a(f: Fase) -> void:
	_fase = f
	_t_fase = 0.0
	if _activa != null:
		fase_cambiada.emit(_activa.id, f)
	if f == Fase.INACTIVA:
		_limpiar()

func _limpiar() -> void:
	_activa = null
	_objetivos.clear()
	_fase = Fase.INACTIVA
	_t_fase = 0.0
```

6. **Cancelar e interrumpir.** Las dos acaban en la misma limpieza; lo que cambia son las reglas:

```gdscript
func cancelar() -> bool:
	if _activa == null:
		return false
	if _fase == Fase.CASTEO and not _activa.cancelable_en_casteo:
		return false
	if _fase == Fase.EJECUCION:
		return false        # ya ha ocurrido: cancelar aquí sería deshacer el efecto
	# El coste NO se devuelve: cancelar tiene precio, si no es gratis fintar.
	_pasar_a(Fase.INACTIVA)
	return true

func interrumpir(por_tag: String = "estado.aturdido") -> bool:
	if _activa == null:
		return false
	if _fase != Fase.CASTEO:
		return false        # solo el casteo es interrumpible
	_cooldowns[_activa.id] = _activa.cooldown * 0.5   # cooldown reducido: castigo, no ruina
	_pasar_a(Fase.INACTIVA)
	return true
```

7. **Probarlo.** El sistema entero se puede ejercitar sin mundo, avanzando el tiempo a mano:

```gdscript
extends SceneTree

func _init() -> void:
	var sys := AbilitySystem.new()
	sys.aprender(AbilityDefinition.de_dict({
		"id": "bola_fuego", "coste": 25, "cooldown": 6.0,
		"casteo": 1.2, "recuperacion": 0.4, "rango": 12.0,
		"bloquea": ["estado.aturdido"],
		"efectos": [{"tipo": "dano", "valor": 40}],
	}))
	sys.fijar_recurso(&"mana", 100.0)

	assert(sys.activar(&"bola_fuego", ["enemigo"], 5.0) == Fallo.Motivo.OK)
	assert(sys.recurso(&"mana") == 75.0, "el coste no se cobró al activar")
	assert(sys.activar(&"bola_fuego", ["enemigo"], 5.0) == Fallo.Motivo.YA_ACTIVA)

	for i in 20: sys.tick(0.1)                    # 2 s: casteo + ejecución + recuperación
	assert(sys.cooldown_restante(&"bola_fuego") > 0.0, "no se aplicó el cooldown")
	assert(sys.activar(&"bola_fuego", ["enemigo"], 5.0) == Fallo.Motivo.EN_COOLDOWN)

	for i in 80: sys.tick(0.1)
	sys.tags.agregar("estado.aturdido")
	assert(sys.activar(&"bola_fuego", ["enemigo"], 5.0) == Fallo.Motivo.BLOQUEADA_POR_TAG)
	sys.tags.quitar("estado.aturdido")
	assert(sys.activar(&"bola_fuego", ["enemigo"], 99.0) == Fallo.Motivo.FUERA_DE_RANGO)

	print("== 7 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Añade cargas (`charges`): tres usos con un cooldown por carga, como el dash de muchos juegos.
2. Implementa `Targeting.CONO` con un ángulo en la definición y una función de selección de objetivos.
3. Añade un modificador de "reducción de cooldown" que lea una estadística de `Stats`.
4. Implementa habilidades **canalizadas** (efecto por tick durante la canalización, cancelable en cualquier momento).
5. Haz que `puede_activar` devuelva además el texto localizable del fallo para la UI.
6. Añade un tag `escuela.fuego` y un efecto de enemigo `inmune.escuela.fuego` que bloquee solo esa escuela.
7. Registra en un array el histórico de activaciones y fallos y úsalo como base de la telemetría de balance.

## 📝 Reto verificable

Implementa un `AbilitySystem` con **al menos cuatro habilidades** definidas en JSON que cubran los cuatro tipos de targeting, con coste, cooldown, casteo, recuperación, tags de bloqueo, cancelación e interrupción.

**Criterio de aceptación**: una prueba headless con **al menos 18 aserciones** demuestra que: (a) cada uno de los ocho motivos de fallo se puede provocar y se devuelve el correcto; (b) interrumpir durante el casteo deja el sistema en `INACTIVA`, con la mitad del cooldown y **sin** devolver el coste; (c) cancelar durante la ejecución devuelve `false` y no altera nada; (d) tras `tick()` acumulando exactamente `casteo + recuperacion`, el sistema vuelve a `INACTIVA`; (e) dos instancias distintas de `AbilitySystem` que reciben la misma secuencia de `activar`/`tick` terminan con **el mismo estado** (determinismo).

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El jugador lanza tres habilidades en un frame | Falta el GCD y la comprobación de `YA_ACTIVA`. Ambas van en `puede_activar`. |
| Los cooldowns se saltan al pausar o al cambiar la hora del sistema | Se usó `Time.get_unix_time_from_system()`. Usa tiempo de juego acumulado en `tick(delta)`. |
| Al interrumpir, el personaje se queda "atascado" sin poder actuar | Se salió de la fase sin limpiar. Centraliza la limpieza en `_pasar_a(INACTIVA)`. |
| El maná se gasta aunque la habilidad falle | Se cobra antes de validar. Cobra **después** de que `puede_activar` devuelva OK. |
| Cancelar devuelve el maná y el jugador fintea gratis | Decisión de diseño no tomada. Decide y documenta: lo habitual es no devolverlo. |
| Añadir una habilidad obliga a tocar el sistema | Los efectos están hardcodeados. Publícalos como datos y que los aplique el pipeline de daño. |
| El botón se ve apagado y el jugador no sabe por qué | La UI recibe `false`. Devuelve el motivo y muéstralo. |
| Dos efectos que aturden y uno que termina desbloquean al personaje | Los tags se guardaron como booleanos. Cuenta fuentes, como en `Tags`. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué el sistema no aplica el daño?** Porque entonces necesitaría conocer la salud, las resistencias, los críticos y la posición — es decir, medio juego. Publicando `efectos_aplicados` puedes probar todo el ciclo de vida de una habilidad sin un mundo, y el pipeline de daño de la [clase 299](../299-arquitectura-avanzada-de-combate-y-dano/README.md) se prueba por su cuenta.

**❓ ¿Esto es una copia del GAS de Unreal?** Es la **misma arquitectura**, que no es de Unreal: definición/instancia, atributos con modificadores, tags y efectos declarativos aparecen en casi todos los RPG de producción. Entender el modelo te permite usar el GAS cuando trabajes en Unreal y construirlo cuando no.

**❓ ¿Y si mi juego es un plataformas sin maná?** El sistema sigue valiendo: `coste = 0`, `cooldown` para el dash, tags para "en el aire" o "aturdido". Lo que ahorra no es el maná, es no repetir la máquina de estados en cada acción.

**❓ ¿Un `tick(delta)` explícito no es incómodo?** Es una línea en el `_physics_process` de la entidad, y a cambio obtienes: pruebas headless, determinismo, replays y la posibilidad de simular el sistema en el servidor. Es de las mejores relaciones coste/beneficio de esta parte.

**❓ ¿Cómo se replica esto en red?** El servidor es el único que ejecuta `activar` y `tick`; el cliente predice la animación y espera confirmación. Como el sistema es determinista y consume solo `delta` y entradas explícitas, encaja directamente con lo aprendido en la Parte 7.

## 🔗 Referencias

- Unreal Engine Docs — Gameplay Ability System (referencia conceptual): <https://dev.epicgames.com/documentation/en-us/unreal-engine/gameplay-ability-system-for-unreal-engine>
- Unreal Engine Docs — Gameplay Tags: <https://dev.epicgames.com/documentation/en-us/unreal-engine/using-gameplay-tags-in-unreal-engine>
- Robert Nystrom — *Game Programming Patterns*, State: <https://gameprogrammingpatterns.com/state.html>
- Godot Docs — Señales personalizadas: <https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html>
- GDC Vault — charlas sobre diseño de sistemas de habilidades y combate: <https://www.gdcvault.com/>

## ⬅️ Clase anterior

[Clase 296 - Equipamiento, loadouts y estadísticas](../296-equipamiento-loadouts-y-estadisticas/README.md)

## ➡️ Siguiente clase

[Clase 298 - Status effects, buffs y debuffs](../298-status-effects-buffs-y-debuffs/README.md)
