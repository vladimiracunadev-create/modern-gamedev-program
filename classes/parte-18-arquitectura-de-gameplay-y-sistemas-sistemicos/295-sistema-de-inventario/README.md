# Clase 295 — Sistema de inventario

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Nystrom, «Game Programming Patterns» · Charlas de GDC sobre diseño de sistemas de inventario*
> ⏱️ Duración estimada: **130 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Implementar un **inventario de verdad**: no un array donde se hace `append`, sino un sistema con ranuras, apilamiento, capacidad, consultas, eventos y **transacciones**. El inventario es engañoso: parece trivial hasta que un jugador intenta meter 30 pociones en un hueco donde caben 20 con el inventario casi lleno, y el sistema tiene que decidir qué pasa exactamente — y hacerlo igual todas las veces.

Aquí construirás las operaciones (`agregar`, `quitar`, `mover`, `partir`, `fusionar`), los casos límite que las rompen, y el mecanismo que evita el bug más caro de todos: **la operación a medias**. Si añadir 30 pociones solo cabe en parte, o se hace entera o no se hace nada; nunca "se han metido 12 y las otras 18 se han evaporado". Terminarás con un inventario que se prueba headless y emite eventos para que la UI se dibuje sola.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Modelar un inventario como **lista de ranuras** y justificar por qué no es un diccionario `id → cantidad`.
2. Implementar apilamiento respetando `max_stack`, incluyendo el reparto entre varias ranuras.
3. Implementar `agregar`, `quitar`, `mover`, `partir` y `fusionar` con sus casos límite.
4. Distinguir una operación **consultable** (`cabe()`) de una **mutadora** y usar la primera para evitar estados a medias.
5. Implementar una **transacción** con rollback sobre el inventario.
6. Emitir eventos granulares que permitan a la UI actualizarse sin releer todo el inventario.
7. Serializar y restaurar el inventario preservando la posición de cada ranura.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Ranuras vs bolsa | Determina si el jugador ve huecos y puede ordenar, o solo una lista. |
| 2 | Apilamiento y reparto | Un stack que no reparte pierde objetos silenciosamente. |
| 3 | Capacidad y "no cabe" | El caso límite más frecuente y el peor tratado. |
| 4 | Operaciones atómicas | O entra todo o no entra nada: sin esto hay duplicación y pérdida. |
| 5 | Transacciones y rollback | Comprar = quitar oro + dar item; si falla la segunda hay que deshacer la primera. |
| 6 | Consultas (filtros, búsqueda) | La UI y las quests preguntan cosas que el inventario debe saber responder. |
| 7 | Eventos granulares | Redibujar 60 ranuras por cada moneda recogida es un coste evitable. |
| 8 | Serialización | El inventario es lo primero que el jugador nota si el save falla. |
| 9 | Validación de entrada | Un id desconocido o una cantidad negativa no pueden entrar al sistema. |

## 📖 Definiciones y características

- **Ranura (slot)**: posición numerada del inventario que contiene un `ItemStack` o está vacía. Clave: su índice es estable y forma parte del guardado.
- **Inventario por ranuras**: modelo en el que la capacidad se mide en huecos, no en unidades. Clave: es el que permite ordenar, arrastrar y mostrar una rejilla.
- **Inventario por peso**: modelo alternativo donde la capacidad es una suma de pesos. Clave: cambia por completo la sensación de gestión y las decisiones del jugador.
- **Stack parcial**: ranura que contiene menos unidades que `max_stack`. Clave: es donde se intenta encajar lo nuevo antes de ocupar un hueco libre.
- **Operación atómica**: operación que se aplica entera o no se aplica. Clave: sin atomicidad, cada caso límite es una fuga de objetos.
- **Transacción**: agrupación de varias operaciones que deben tener éxito conjuntamente. Clave: necesita un punto de restauración para poder deshacerse.
- **Rollback**: restauración del estado previo cuando una transacción falla. Clave: en local basta una copia; en servidor exige idempotencia (clase 314).
- **Restante (remainder)**: unidades que no cupieron al añadir. Clave: devolverlo es más honesto que descartarlo o que fallar.
- **Consulta (`cabe`, `contiene`, `contar`)**: función que no muta y permite decidir antes de actuar. Clave: separar consulta de comando es lo que hace el sistema previsible.
- **Evento granular**: notificación que dice qué ranura cambió, no "algo cambió". Clave: permite a la UI redibujar solo lo necesario.
- **Compactar / ordenar**: reagrupar stacks parciales y ordenar por criterio. Clave: operación cómoda para el jugador y trampa clásica para los índices de la UI.
- **Inventario lleno**: estado en el que no hay ranuras libres ni stacks parciales del item. Clave: debe tener una respuesta diseñada (rechazar, soltar al suelo, buzón).
- **Fusionar (merge)**: unir dos stacks del mismo item respetando el máximo. Clave: el sobrante se queda en el origen, no se pierde.
- **Partir (split)**: dividir un stack en dos ranuras. Clave: requiere una ranura libre; si no hay, la operación no ocurre.

## 🧰 Herramientas y preparación

Continúa con el catálogo de la [clase 294](../294-items-y-base-de-datos-de-objetos/README.md): el inventario no funciona sin él, porque necesita saber cuánto apila cada item. Trabajaremos en `res://dominio/inventario/`. Todo el código de esta clase es `RefCounted`: no hay nodos, no hay escenas y por tanto se puede probar headless en milisegundos — es exactamente el criterio de la [clase 293](../293-arquitectura-de-gameplay-a-escala/README.md).

## 🧪 Laboratorio guiado

1. **La estructura.** Un array de tamaño fijo con `null` en los huecos. Sencillo, y con índices estables:

```gdscript
class_name Inventario
extends RefCounted

signal ranura_cambiada(indice: int)
signal inventario_lleno(id: StringName, restante: int)

var _base: BaseDeItems
var _ranuras: Array = []          # Array[ItemStack | null], tamaño fijo

func _init(base: BaseDeItems, capacidad: int) -> void:
	_base = base
	_ranuras.resize(max(1, capacidad))   # resize() rellena con null

func capacidad() -> int:
	return _ranuras.size()

func ranura(i: int) -> ItemStack:
	return _ranuras[i] if i >= 0 and i < _ranuras.size() else null

func libres() -> int:
	return _ranuras.count(null)
```

2. **Consultar antes de actuar: `cabe()`.** Esta función es la que hace posible la atomicidad. Calcula sin tocar nada:

```gdscript
func cabe(id: StringName, cantidad: int) -> int:
	"""Devuelve cuántas unidades de `id` cabrían. No modifica nada."""
	if cantidad <= 0 or not _base.existe(id):
		return 0
	var tope := _base.obtener(id).max_stack
	var hueco := 0
	for s in _ranuras:
		if s == null:
			hueco += tope                      # una ranura libre admite un stack entero
		elif s.id == id:
			hueco += tope - s.cantidad         # stack parcial: lo que le falta
		if hueco >= cantidad:
			return cantidad                    # ya sabemos que cabe todo: salimos
	return hueco
```

3. **Agregar, repartiendo.** Primero se rellenan los stacks parciales (para no fragmentar el inventario) y solo después se ocupan huecos:

```gdscript
func agregar(id: StringName, cantidad: int) -> int:
	"""Añade lo que pueda y devuelve el RESTANTE que no cupo."""
	if cantidad <= 0 or not _base.existe(id):
		return cantidad
	var tope := _base.obtener(id).max_stack
	var quedan := cantidad

	# Fase 1: completar stacks parciales existentes.
	for i in _ranuras.size():
		if quedan == 0:
			break
		var s: ItemStack = _ranuras[i]
		if s != null and s.id == id and s.cantidad < tope:
			var mete := mini(tope - s.cantidad, quedan)
			s.cantidad += mete
			quedan -= mete
			ranura_cambiada.emit(i)

	# Fase 2: ocupar ranuras vacías.
	for i in _ranuras.size():
		if quedan == 0:
			break
		if _ranuras[i] == null:
			var mete := mini(tope, quedan)
			_ranuras[i] = ItemStack.new(id, mete)
			quedan -= mete
			ranura_cambiada.emit(i)

	if quedan > 0:
		inventario_lleno.emit(id, quedan)
	return quedan
```

4. **Agregar de forma atómica.** La versión anterior es útil (loot que rebosa al suelo), pero para comercio y recompensas quieres todo-o-nada:

```gdscript
func agregar_todo_o_nada(id: StringName, cantidad: int) -> bool:
	if cabe(id, cantidad) < cantidad:
		return false          # no tocamos nada: el inventario queda intacto
	var restante := agregar(id, cantidad)
	assert(restante == 0, "cabe() y agregar() discrepan: hay un bug en uno de los dos")
	return true
```

Ese `assert` no es decorativo: es la forma de detectar que las dos funciones se han desincronizado al tocar una sola.

5. **Quitar.** También todo-o-nada, y recorriendo desde el final para consumir primero los stacks parciales:

```gdscript
func contar(id: StringName) -> int:
	var n := 0
	for s in _ranuras:
		if s != null and s.id == id:
			n += s.cantidad
	return n

func quitar(id: StringName, cantidad: int) -> bool:
	if cantidad <= 0 or contar(id) < cantidad:
		return false
	var quedan := cantidad
	for i in range(_ranuras.size() - 1, -1, -1):
		if quedan == 0:
			break
		var s: ItemStack = _ranuras[i]
		if s != null and s.id == id:
			var saca := mini(s.cantidad, quedan)
			s.cantidad -= quedan if s.cantidad >= quedan else s.cantidad
			quedan -= saca
			if s.cantidad <= 0:
				_ranuras[i] = null       # ranura vacía, no un stack de 0
			ranura_cambiada.emit(i)
	return true
```

> Nota deliberada: un stack de cantidad `0` **no existe**. Si lo permites, `contar()` da bien pero la UI pinta huecos con un icono fantasma, y el guardado se llena de ruido.

6. **Mover y fusionar.** Aquí es donde aparecen los bugs de duplicación si no se piensa:

```gdscript
func mover(desde: int, hasta: int) -> bool:
	if desde == hasta or not _valido(desde) or not _valido(hasta):
		return false
	var a: ItemStack = _ranuras[desde]
	if a == null:
		return false
	var b: ItemStack = _ranuras[hasta]

	if b == null:                                  # hueco: movimiento simple
		_ranuras[hasta] = a
		_ranuras[desde] = null
	elif b.id == a.id:                             # mismo item: fusionar
		var tope := _base.obtener(a.id).max_stack
		var pasa := mini(tope - b.cantidad, a.cantidad)
		b.cantidad += pasa
		a.cantidad -= pasa
		if a.cantidad == 0:
			_ranuras[desde] = null                 # el sobrante SE QUEDA en el origen
	else:                                          # items distintos: intercambio
		_ranuras[hasta] = a
		_ranuras[desde] = b

	ranura_cambiada.emit(desde)
	ranura_cambiada.emit(hasta)
	return true

func partir(indice: int, cantidad: int) -> bool:
	var s: ItemStack = ranura(indice)
	if s == null or cantidad <= 0 or cantidad >= s.cantidad:
		return false
	var hueco := _ranuras.find(null)
	if hueco == -1:
		return false                               # sin hueco no se puede partir
	s.cantidad -= cantidad
	_ranuras[hueco] = ItemStack.new(s.id, cantidad)
	ranura_cambiada.emit(indice)
	ranura_cambiada.emit(hueco)
	return true

func _valido(i: int) -> bool:
	return i >= 0 and i < _ranuras.size()
```

7. **Transacciones con rollback.** Una compra son dos operaciones y ninguna puede quedar suelta:

```gdscript
func instantanea() -> Array:
	# Copia PROFUNDA: si copiamos las referencias, el rollback no restaura nada.
	return _ranuras.map(func(s): return ItemStack.new(s.id, s.cantidad) if s else null)

func restaurar(instantanea_previa: Array) -> void:
	_ranuras = instantanea_previa
	for i in _ranuras.size():
		ranura_cambiada.emit(i)

func transaccion(operaciones: Array[Callable]) -> bool:
	var copia := instantanea()
	for op in operaciones:
		if not op.call():
			restaurar(copia)     # deshacemos TODO lo hecho hasta aquí
			return false
	return true
```

```gdscript
# Comprar una espada: quitar 80 de oro y meter el item, o nada de lo dos.
var ok := inv.transaccion([
	func(): return inv.quitar(&"moneda_oro", 80),
	func(): return inv.agregar_todo_o_nada(&"espada_hierro", 1),
])
```

8. **Serializar.** Se guardan índices y stacks; nunca nombres ni iconos:

```gdscript
func a_dict() -> Dictionary:
	var ranuras := {}
	for i in _ranuras.size():
		if _ranuras[i] != null:
			ranuras[str(i)] = _ranuras[i].a_dict()   # solo lo ocupado
	return {"capacidad": _ranuras.size(), "ranuras": ranuras}

func de_dict(d: Dictionary) -> void:
	_ranuras.clear()
	_ranuras.resize(int(d.get("capacidad", 20)))
	for clave in d.get("ranuras", {}):
		var i := int(clave)
		var stack := ItemStack.de_dict(d["ranuras"][clave])
		# Un item borrado en un parche no debe impedir cargar la partida.
		if _valido(i) and _base.existe(stack.id):
			_ranuras[i] = stack
	for i in _ranuras.size():
		ranura_cambiada.emit(i)
```

9. **Probarlo.** Los casos que de verdad importan son los feos:

```gdscript
extends SceneTree

func _init() -> void:
	var base := BaseDeItems.new()
	base.cargar_desde_json("res://datos/items.json")
	var inv := Inventario.new(base, 3)            # solo 3 ranuras: fácil de llenar

	assert(inv.agregar(&"pocion_menor", 25) == 0, "25 pociones caben en 2 ranuras de 20")
	assert(inv.contar(&"pocion_menor") == 25)
	assert(inv.libres() == 1)

	# Ahora rebosa: 1 ranura libre (20) + hueco del stack parcial (15) = 35.
	var restante := inv.agregar(&"pocion_menor", 50)
	assert(restante == 15, "el restante debe ser 15, fue %d" % restante)

	# Atómico: no cabe, no se toca nada.
	var antes := inv.contar(&"espada_hierro")
	assert(inv.agregar_todo_o_nada(&"espada_hierro", 1) == false)
	assert(inv.contar(&"espada_hierro") == antes, "una operación fallida ha mutado el inventario")

	print("== 6 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Implementa `ordenar()` que agrupe por tipo y rareza compactando stacks, y comprueba que no pierde ni duplica unidades.
2. Añade un modo por peso: capacidad en kg usando el campo `peso` del ejercicio de la clase 294.
3. Implementa `soltar_al_suelo(restante)` para que lo que no cabe caiga en el mundo en vez de perderse.
4. Añade una ranura "bloqueada" (una mochila que se desbloquea por progresión) y respétala en `cabe()` y `agregar()`.
5. Implementa `transferir(otro_inventario, id, cantidad)` de forma atómica **entre dos inventarios**.
6. Añade un evento `stack_agotado(id)` y úsalo para que la barra de acceso rápido se vacíe sola.
7. Escribe una prueba que ejecute 10.000 operaciones aleatorias y verifique que el total de unidades nunca cambia salvo por agregados y quitados explícitos.

## 📝 Reto verificable

Implementa el `Inventario` completo con `agregar`, `agregar_todo_o_nada`, `quitar`, `mover`, `partir`, `contar`, `cabe`, `transaccion`, `a_dict` y `de_dict`, más una batería de pruebas headless que cubra **los seis casos límite**: inventario lleno, stack parcial, cantidad mayor que el stack máximo, item inexistente, cantidad negativa o cero, y rollback de una transacción fallida.

**Criterio de aceptación**: `godot --headless --script res://pruebas/inventario_test.gd` ejecuta **al menos 20 aserciones**, termina imprimiendo `== N comprobaciones, 0 fallos ==` con código de salida 0, y en particular demuestra que: (a) tras una `transaccion` fallida el inventario es **byte a byte** el mismo que antes (compara `a_dict()`); (b) `mover` entre dos stacks del mismo item con sobrante deja exactamente `max_stack` en destino y el resto en origen; (c) `a_dict()` → `de_dict()` conserva la posición de cada ranura.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Al llenar el inventario desaparecen objetos | `agregar` descarta el restante. Devuélvelo y decide qué hacer con él (rechazar, suelo, buzón). |
| Al arrastrar un stack sobre otro se duplican unidades | En `mover` se sumó en destino sin restar en origen. Fusiona calculando `pasa` y réstalo siempre. |
| El rollback no restaura nada | `instantanea()` copió referencias, no valores. Crea `ItemStack` nuevos en la copia. |
| Aparecen ranuras con un icono y cantidad 0 | Se dejó el stack tras vaciarlo. Pon `null` en la ranura cuando llegue a 0. |
| La UI parpadea entera al recoger una moneda | Se emite un evento global. Emite `ranura_cambiada(i)` y redibuja solo esa. |
| Cargar una partida vieja peta con "item desconocido" | Un id se borró en un parche. Filtra con `_base.existe()` al deserializar y registra el descarte. |
| `cabe()` dice que sí y `agregar()` deja restante | Las dos funciones no aplican la misma regla (típicamente una ignora las ranuras bloqueadas). Extrae la regla a una sola función. |
| Ordenar deja al jugador con el objeto equivocado en la mano | La UI guardaba índices y el orden cambió. Referencia por id de stack, o cancela la selección al ordenar. |

## ❓ Preguntas frecuentes

**❓ ¿Ranuras o diccionario `id → cantidad`?** El diccionario es más simple y perfecto para monedas y materiales (un "banco"). Las ranuras son obligatorias en cuanto el jugador pueda **ordenar, arrastrar o ver huecos**, y en cuanto un item tenga estado propio (durabilidad, encantamiento): dos espadas iguales con distinto desgaste no son intercambiables.

**❓ ¿Dónde meto la durabilidad o los encantamientos?** En la instancia (`ItemStack`), nunca en la definición. Y ten en cuenta que un item con estado propio **no puede apilar** con otro de estado distinto: es la razón práctica por la que las armas tienen `max_stack = 1`.

**❓ ¿Debe el inventario conocer la UI?** No. Emite eventos y expone consultas; la UI se suscribe. Así puedes probar el inventario headless y reutilizarlo en un cofre, una tienda o el inventario de un NPC sin cambiar una línea.

**❓ ¿Y si el juego es multijugador?** Entonces el inventario **autoritativo vive en el servidor** y el cliente muestra una copia. Toda esta lógica sigue siendo válida; lo que cambia es quién la ejecuta y que las operaciones necesitan claves de idempotencia — es exactamente el tema de la [clase 314](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/314-economia-transaccional-de-servidor/README.md).

**❓ ¿Merece la pena la transacción para un juego single-player?** Sí, y es barato: son quince líneas. El coste de no tenerlas es un jugador que pierde su espada legendaria porque el inventario estaba lleno a mitad de un intercambio, y un bug que no sabrás reproducir.

## 🔗 Referencias

- Robert Nystrom — *Game Programming Patterns*: <https://gameprogrammingpatterns.com/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — Arrays y tipos de datos: <https://docs.godotengine.org/en/4.3/tutorials/scripting/gdscript/gdscript_basics.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — Señales personalizadas: <https://docs.godotengine.org/en/4.3/getting_started/step_by_step/signals.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — Drag and drop en Control (para la UI del inventario): <https://docs.godotengine.org/en/4.3/classes/class_control.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- GDC Vault — charlas sobre diseño de sistemas de inventario y UX de gestión: <https://www.gdcvault.com/> — catálogo por tema, no una charla identificada (ponente y año pendientes) · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 294 - Items y base de datos de objetos](../294-items-y-base-de-datos-de-objetos/README.md)

## ➡️ Siguiente clase

[Clase 296 - Equipamiento, loadouts y estadísticas](../296-equipamiento-loadouts-y-estadisticas/README.md)
