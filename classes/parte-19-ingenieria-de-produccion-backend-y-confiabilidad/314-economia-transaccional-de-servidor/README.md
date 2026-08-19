# Clase 314 — Economía transaccional de servidor

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *Literatura de sistemas transaccionales (ACID, idempotencia) · Charlas de GDC sobre economías online y duplicación de objetos*
> ⏱️ Duración estimada: **125 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Llevar la economía de la [clase 303](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/303-economia-interna-implementada/README.md) al servidor y hacerla **a prueba de reintentos, de concurrencia y de clientes maliciosos**. En single-player, una compra que falla a medias es un bug molesto. En un juego online con economía, es una máquina de duplicar objetos que puede destruir el juego en 48 horas — y la historia del género está llena de ejemplos.

Vas a implementar los cuatro mecanismos que hacen sólida una economía de servidor: **autoridad** (el cliente pide, el servidor decide), **idempotencia** (el mismo intento repetido no se aplica dos veces), **transaccionalidad** (todo o nada, incluso con dos jugadores a la vez) y **auditoría** (todo movimiento queda registrado y el saldo se puede reconstruir). Todo con el `MockBackend`, sin base de datos ni servicios externos, pero con la semántica correcta.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Trasladar la autoridad de inventario y monedas del cliente al servidor.
2. Implementar claves de idempotencia y explicar exactamente qué problema resuelven.
3. Implementar operaciones atómicas con rollback y validación previa.
4. Detectar y prevenir condiciones de carrera en intercambios entre jugadores.
5. Implementar un registro de auditoría que permita reconstruir cualquier saldo.
6. Enumerar los ataques clásicos de duplicación y la defensa concreta de cada uno.
7. Diseñar la reconciliación cliente-servidor cuando el cliente predice mal.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Autoridad de servidor | Sin ella, no hay economía: hay sugerencias. |
| 2 | Comando vs consulta | El cliente pide operaciones, no envía estados. |
| 3 | Idempotencia | Los reintentos existen; sin claves, duplican. |
| 4 | Transacción atómica | Un intercambio a medias crea o destruye objetos. |
| 5 | Concurrencia | Dos peticiones del mismo jugador a la vez son normales. |
| 6 | Bloqueo optimista | La forma barata de evitar carreras sin serializarlo todo. |
| 7 | Registro de auditoría | Permite responder "¿de dónde salió esto?" y revertir. |
| 8 | Ataques de duplicación | Hay cinco patrones, y se defienden uno a uno. |
| 9 | Reconciliación | El cliente predice para que el juego responda; el servidor manda. |
| 10 | Revertir en masa | Cuando un exploit se cuela, hay que poder deshacerlo. |

## 📖 Definiciones y características

- **Autoridad de servidor**: el servidor es la única fuente de verdad del estado económico. Clave: el cliente solo tiene una copia para pintar.
- **Comando (intención)**: petición del cliente para que ocurra algo (`comprar`, `craftear`). Clave: describe la intención, no el resultado.
- **Clave de idempotencia**: identificador único que el cliente genera por intento. Clave: permite al servidor reconocer un reintento y devolver el mismo resultado.
- **Operación idempotente**: la que aplicada N veces produce el mismo estado que aplicada una. Clave: es lo que hace seguros los reintentos.
- **Transacción**: conjunto de cambios que se aplican todos o ninguno. Clave: atomicidad, y en economía es innegociable.
- **Rollback**: deshacer los cambios parciales de una transacción fallida. Clave: exige un punto de restauración o un diseño donde nada se escriba hasta el final.
- **Condición de carrera**: dos operaciones concurrentes que leen el mismo estado y escriben resultados incompatibles. Clave: es la causa del clásico "vender el mismo objeto dos veces".
- **Bloqueo optimista**: leer con versión, escribir exigiendo esa versión. Clave: barato, y convierte la carrera en un error detectable.
- **Bloqueo pesimista**: tomar el recurso en exclusiva antes de operar. Clave: correcto y caro; se reserva para operaciones críticas.
- **Registro de auditoría (ledger)**: lista inmutable de movimientos con motivo y referencia. Clave: el saldo es la suma del registro, no un número suelto.
- **Reconstrucción de saldo**: calcular el estado a partir del registro. Clave: detecta discrepancias y permite reparar.
- **Duplicación (dupe)**: bug que crea objetos de la nada. Clave: el fallo más grave posible en una economía.
- **Reconciliación**: corrección del estado del cliente cuando difiere del servidor. Clave: el servidor manda siempre, y el cliente debe encajarlo con elegancia.
- **Predicción optimista**: el cliente muestra el resultado antes de la confirmación. Clave: mejora la sensación de respuesta y obliga a saber revertir.
- **Rate limiting**: límite de peticiones por jugador y ventana. Clave: primera defensa contra automatización y ataques de repetición.
- **Reversión en masa (rollback de exploit)**: deshacer todas las operaciones de un periodo o un patrón. Clave: solo es posible si existe el registro de auditoría.

## 🧰 Herramientas y preparación

Necesitas la economía de la clase 303, el inventario de la 295 y el `MockBackend` de la 311. Trabajaremos en `res://servidor/economia/` (código que conceptualmente vive en el servidor, aunque lo ejecutemos en el proyecto). La clase [148](../../parte-7-multijugador-y-networking/148-servidor-autoritativo-y-anti-cheat-basico/README.md) introdujo el servidor autoritativo para el movimiento; esto es lo mismo aplicado a la economía, donde el incentivo para hacer trampas es mucho mayor.

## 🧪 Laboratorio guiado

1. **El comando y su clave de idempotencia.** El cliente genera la clave, **no** el servidor:

```gdscript
class_name ComandoEconomia
extends RefCounted

enum Tipo { COMPRAR, VENDER, CRAFTEAR, INTERCAMBIAR, ABRIR_CAJA }

var clave_idempotencia: String = ""    # la genera el CLIENTE, una por intento
var jugador: StringName = &""
var tipo: Tipo = Tipo.COMPRAR
var parametros: Dictionary = {}

static func nuevo(tipo_: Tipo, jugador_: StringName, params: Dictionary,
				  rng: RandomNumberGenerator) -> ComandoEconomia:
	var c := ComandoEconomia.new()
	c.tipo = tipo_
	c.jugador = jugador_
	c.parametros = params
	# La clave identifica el INTENTO, no la operación: si el jugador quiere
	# comprar dos pociones en dos acciones distintas, son dos claves.
	c.clave_idempotencia = "%s-%d-%d" % [jugador_, Time.get_ticks_msec(), rng.randi()]
	return c
```

2. **El registro de auditoría.** El saldo **es** la suma del registro:

```gdscript
class_name Ledger
extends RefCounted

class Movimiento extends RefCounted:
	var secuencia: int = 0
	var jugador: StringName = &""
	var recurso: StringName = &""       # "oro", o el id de un item
	var delta: int = 0
	var motivo: String = ""
	var clave: String = ""              # la de idempotencia, para poder revertir
	var momento: float = 0.0

var _movimientos: Array[Movimiento] = []
var _secuencia := 0

func anotar(jugador: StringName, recurso: StringName, delta: int,
			motivo: String, clave: String, ahora: float) -> void:
	var m := Movimiento.new()
	_secuencia += 1
	m.secuencia = _secuencia
	m.jugador = jugador; m.recurso = recurso; m.delta = delta
	m.motivo = motivo; m.clave = clave; m.momento = ahora
	_movimientos.append(m)

func saldo(jugador: StringName, recurso: StringName) -> int:
	var t := 0
	for m in _movimientos:
		if m.jugador == jugador and m.recurso == recurso:
			t += m.delta
	return t

func revertir_clave(clave: String, ahora: float) -> int:
	# Revertir NO borra: añade movimientos contrarios. La historia se conserva
	# entera, que es justo lo que permite auditar un exploit después.
	var n := 0
	for m in _movimientos.duplicate():
		if m.clave == clave:
			anotar(m.jugador, m.recurso, -m.delta, "reversion:" + m.motivo, clave + "-rev", ahora)
			n += 1
	return n
```

3. **El servicio, con idempotencia.** El corazón de la clase:

```gdscript
class_name ServicioEconomia
extends RefCounted

enum Resultado { OK, SIN_SALDO, SIN_STOCK, SIN_ESPACIO, INVALIDO, CONFLICTO, LIMITADO }

var _ledger := Ledger.new()
var _resultados := {}          # clave_idempotencia -> {resultado, respuesta}
var _versiones := {}           # jugador -> int (bloqueo optimista)
var _peticiones := {}          # jugador -> [momentos] (rate limiting)

const MAX_PETICIONES := 20
const VENTANA := 10.0

func ejecutar(c: ComandoEconomia, ahora: float) -> Dictionary:
	# 1) IDEMPOTENCIA: si ya vimos esta clave, devolvemos EL MISMO resultado.
	#    No es una optimización: es lo que impide que un reintento por timeout
	#    compre dos veces.
	if _resultados.has(c.clave_idempotencia):
		var previo: Dictionary = _resultados[c.clave_idempotencia].duplicate()
		previo["repetida"] = true
		return previo

	# 2) RATE LIMIT: barato y corta la automatización más burda.
	if not _permite(c.jugador, ahora):
		return {"resultado": Resultado.LIMITADO}

	# 3) Ejecutar según el tipo.
	var r := {}
	match c.tipo:
		ComandoEconomia.Tipo.COMPRAR:      r = _comprar(c, ahora)
		ComandoEconomia.Tipo.VENDER:       r = _vender(c, ahora)
		ComandoEconomia.Tipo.INTERCAMBIAR: r = _intercambiar(c, ahora)
		_:                                 r = {"resultado": Resultado.INVALIDO}

	# 4) Guardar el resultado ANTES de responder: si el cliente no recibe la
	#    respuesta y reintenta, encontrará esta.
	_resultados[c.clave_idempotencia] = r.duplicate()
	return r

func _permite(jugador: StringName, ahora: float) -> bool:
	var lista: Array = _peticiones.get(jugador, [])
	lista = lista.filter(func(t): return ahora - float(t) < VENTANA)
	if lista.size() >= MAX_PETICIONES:
		_peticiones[jugador] = lista
		return false
	lista.append(ahora)
	_peticiones[jugador] = lista
	return true
```

4. **Una compra atómica.** Validar todo antes de escribir nada:

```gdscript
func _comprar(c: ComandoEconomia, ahora: float) -> Dictionary:
	var sku := StringName(str(c.parametros.get("item", "")))
	var n := int(c.parametros.get("cantidad", 1))
	# El PRECIO lo pone el servidor. Si viniera del cliente, el cliente
	# decidiría cuánto paga: es el exploit más elemental que existe.
	var precio := _precio_servidor(sku) * n

	if n <= 0 or not _catalogo.existe(sku):
		return {"resultado": Resultado.INVALIDO}
	if _stock.get(sku, 0) < n:
		return {"resultado": Resultado.SIN_STOCK}
	if _ledger.saldo(c.jugador, &"oro") < precio:
		return {"resultado": Resultado.SIN_SALDO}
	if _espacio_libre(c.jugador) < _ranuras_necesarias(sku, n):
		return {"resultado": Resultado.SIN_ESPACIO}

	# Punto de no retorno: a partir de aquí, todo o nada. Como el ledger es
	# append-only, "todo" son dos anotaciones consecutivas.
	_stock[sku] -= n
	_ledger.anotar(c.jugador, &"oro", -precio, "compra", c.clave_idempotencia, ahora)
	_ledger.anotar(c.jugador, sku, n, "compra", c.clave_idempotencia, ahora)
	_versiones[c.jugador] = int(_versiones.get(c.jugador, 0)) + 1

	return {"resultado": Resultado.OK, "gastado": precio,
			"saldo": _ledger.saldo(c.jugador, &"oro"),
			"version": _versiones[c.jugador]}
```

5. **El intercambio entre dos jugadores.** Aquí es donde nacen las duplicaciones:

```gdscript
func _intercambiar(c: ComandoEconomia, ahora: float) -> Dictionary:
	var a: StringName = c.jugador
	var b := StringName(str(c.parametros.get("con", "")))
	var da: Dictionary = c.parametros.get("da", {})       # {item: cantidad}
	var db: Dictionary = c.parametros.get("recibe", {})

	# Orden canónico de bloqueo: siempre el jugador con id menor primero. Sin
	# esto, dos intercambios cruzados (A↔B y B↔A a la vez) pueden bloquearse
	# mutuamente para siempre.
	var primero := a if String(a) < String(b) else b
	var segundo := b if primero == a else a
	if not _tomar_bloqueo(primero, ahora) :
		return {"resultado": Resultado.CONFLICTO}
	if not _tomar_bloqueo(segundo, ahora):
		_soltar_bloqueo(primero)
		return {"resultado": Resultado.CONFLICTO}

	var r := {"resultado": Resultado.OK}
	# Validar AMBOS lados por completo antes de mover un solo objeto.
	for item in da:
		if _ledger.saldo(a, StringName(str(item))) < int(da[item]):
			r = {"resultado": Resultado.INVALIDO}
	for item in db:
		if _ledger.saldo(b, StringName(str(item))) < int(db[item]):
			r = {"resultado": Resultado.INVALIDO}

	if int(r["resultado"]) == Resultado.OK:
		for item in da:
			_ledger.anotar(a, StringName(str(item)), -int(da[item]), "intercambio", c.clave_idempotencia, ahora)
			_ledger.anotar(b, StringName(str(item)), int(da[item]), "intercambio", c.clave_idempotencia, ahora)
		for item in db:
			_ledger.anotar(b, StringName(str(item)), -int(db[item]), "intercambio", c.clave_idempotencia, ahora)
			_ledger.anotar(a, StringName(str(item)), int(db[item]), "intercambio", c.clave_idempotencia, ahora)

	_soltar_bloqueo(segundo)
	_soltar_bloqueo(primero)
	return r
```

6. **Los cinco ataques de duplicación y su defensa.** Cada uno tiene un nombre y una respuesta:

| Ataque | Cómo funciona | Defensa |
|---|---|---|
| **Reintento** | Corta la red tras enviar la petición y reintenta | Clave de idempotencia |
| **Carrera** | Envía dos ventas del mismo objeto a la vez | Bloqueo optimista o pesimista, orden canónico |
| **Desconexión** | Se desconecta en mitad de un intercambio | Transacción atómica; nunca escribir a medias |
| **Precio del cliente** | Manda el precio en la petición | El precio lo calcula el servidor |
| **Rollback de instancia** | Provoca un fallo del servidor tras recibir el objeto | Ledger append-only + reconciliación al reconectar |

7. **La reconciliación.** El cliente predice para que el juego responda, y encaja la corrección:

```gdscript
# CLIENTE
func comprar_optimista(sku: StringName, n: int) -> void:
	var c := ComandoEconomia.nuevo(ComandoEconomia.Tipo.COMPRAR, _yo,
		{"item": sku, "cantidad": n}, _rng)

	# Predicción: pintamos el resultado ya, para que el botón responda.
	var prediccion := _aplicar_local(sku, n)
	_pendientes[c.clave_idempotencia] = prediccion

	var r := await _backend.enviar(c)
	_pendientes.erase(c.clave_idempotencia)

	if int(r.get("resultado", -1)) != ServicioEconomia.Resultado.OK:
		_revertir_local(prediccion)
		_avisar_al_jugador(r)
		return
	# El servidor manda: si su saldo difiere del predicho, se adopta el suyo
	# sin discutir, y se avisa solo si la diferencia es visible.
	if int(r["saldo"]) != _saldo_local():
		_fijar_saldo(int(r["saldo"]))
```

8. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	var svc := ServicioEconomia.nuevo_para_pruebas()
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var yo := &"plr_a"
	svc.conceder_inicial(yo, &"oro", 500)

	# Idempotencia: la MISMA clave dos veces cobra una sola vez.
	var c := ComandoEconomia.nuevo(ComandoEconomia.Tipo.COMPRAR, yo,
		{"item": "pocion_menor", "cantidad": 2}, rng)
	var r1 := svc.ejecutar(c, 0.0)
	var r2 := svc.ejecutar(c, 0.1)        # el reintento del cliente
	assert(int(r1["resultado"]) == ServicioEconomia.Resultado.OK)
	assert(bool(r2.get("repetida", false)), "el reintento no se reconoció como repetido")
	assert(svc.saldo(yo, &"oro") == 500 - int(r1["gastado"]), "se cobró dos veces")
	assert(svc.saldo(yo, &"pocion_menor") == 2, "se entregaron 4 pociones")

	# El precio lo pone el servidor: mandar uno propio no sirve de nada.
	var trampa := ComandoEconomia.nuevo(ComandoEconomia.Tipo.COMPRAR, yo,
		{"item": "espada_hierro", "cantidad": 1, "precio": 1}, rng)
	var r3 := svc.ejecutar(trampa, 1.0)
	assert(int(r3.get("gastado", 0)) == svc.precio(&"espada_hierro"),
		"el cliente ha conseguido fijar el precio")

	# Auditoría: el saldo es exactamente la suma del ledger.
	assert(svc.auditar(yo), "el saldo no cuadra con el registro")

	# Reversión de un exploit: se anula por clave y queda rastro.
	var antes := svc.saldo(yo, &"pocion_menor")
	svc.revertir(c.clave_idempotencia, 2.0)
	assert(svc.saldo(yo, &"pocion_menor") == antes - 2, "la reversión no retiró los items")
	assert(svc.auditar(yo), "la reversión rompió la auditoría")

	print("== 8 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Implementa caducidad de las claves de idempotencia (24 h) y comprueba que el reintento tardío se rechaza en vez de repetirse.
2. Añade bloqueo optimista con versión de jugador y provoca un conflicto con dos comandos concurrentes.
3. Implementa apertura de cajas con RNG de servidor sembrado y guarda la semilla en el ledger.
4. Simula 10.000 operaciones aleatorias y verifica que `auditar()` cuadra en todos los jugadores.
5. Implementa la reversión en masa de todas las operaciones de un intervalo de tiempo.
6. Añade límites por jugador y por hora para operaciones sensibles (intercambios, ventas).
7. Escribe un detector de anomalías que marque a jugadores cuyo saldo crece más rápido que el percentil 99.

## 📝 Reto verificable

Implementa un servicio de economía autoritativo con claves de idempotencia, ledger append-only, compra, venta e intercambio atómicos, bloqueo con orden canónico, rate limiting, auditoría y reversión por clave.

**Criterio de aceptación**: una prueba headless con **al menos 20 aserciones** demuestra que: (a) ejecutar el mismo comando cinco veces produce **un solo** efecto y devuelve el mismo resultado marcado como repetido; (b) el precio enviado por el cliente se ignora por completo; (c) un intercambio en el que un lado no tiene el objeto no mueve **nada** del otro lado; (d) dos intercambios cruzados simultáneos (A↔B y B↔A) no se bloquean mutuamente ni duplican objetos; (e) tras 10.000 operaciones aleatorias, el saldo de cada jugador coincide exactamente con la suma de su ledger; (f) revertir una clave deja el saldo como antes de esa operación y **conserva** ambos movimientos en el registro; (g) superar el rate limit devuelve `LIMITADO` sin aplicar la operación.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Jugadores con objetos que nunca compraron | Duplicación por reintento. Claves de idempotencia, siempre. |
| Un exploit vació la economía en un fin de semana | Sin ledger no se pudo revertir. Registro append-only desde el día uno. |
| Vender el mismo objeto dos veces funciona | Condición de carrera. Bloqueo optimista con versión, o pesimista en operaciones críticas. |
| Un intercambio se cortó y desapareció un objeto | Escritura parcial. Valida ambos lados y escribe todo junto. |
| El jugador compra por 1 de oro | El precio venía del cliente. El servidor calcula el precio. |
| Dos intercambios simultáneos se quedan colgados | Interbloqueo. Toma los bloqueos siempre en el mismo orden. |
| El saldo mostrado no coincide con el real | Predicción sin reconciliación. Adopta el saldo del servidor al confirmar. |
| Un bot hace 500 peticiones por segundo | Falta rate limiting. Ventana deslizante por jugador. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué la clave la genera el cliente?** Porque el problema que resuelve es exactamente "el cliente no sabe si su petición llegó". Si la generara el servidor, el reintento traería una clave nueva y se aplicaría dos veces. El cliente genera una por **intención del jugador** y la reutiliza en todos los reintentos de esa intención.

**❓ ¿El ledger no crece sin control?** Crece, y es aceptable: son unas decenas de bytes por movimiento. Lo habitual es consolidar periódicamente (snapshot de saldo + ledger desde ese punto) y archivar lo antiguo en almacenamiento barato. Lo que no debe hacerse es borrarlo: es la única forma de investigar un exploit.

**❓ ¿Bloqueo optimista o pesimista?** Optimista por defecto: es más barato y la mayoría de operaciones no compiten. Pesimista para lo que sí compite de verdad (intercambios entre jugadores, subastas), donde un reintento constante sería peor que esperar.

**❓ ¿Y si mi juego es single-player con tienda?** No necesitas nada de esto para evitar trampas —el jugador puede editar su save y no pasa nada—, pero **la idempotencia y la atomicidad siguen siendo útiles**: evitan perder objetos por un cierre inesperado. La diferencia es el modelo de amenazas ([clase 318](../318-threat-modeling-para-videojuegos/README.md)), no la técnica.

**❓ ¿Cómo pruebo la concurrencia sin servidor real?** Con el patrón de esta clase: como el servicio es determinista y avanza por llamadas explícitas, puedes intercalar operaciones a mano y reproducir exactamente la carrera que quieres. Es **más** fiable que probarlo contra un servidor real, donde la carrera aparece cuando quiere.

## 🔗 Referencias

- Stripe — Idempotent requests (la explicación de referencia del patrón): <https://docs.stripe.com/api/idempotent_requests> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Martin Kleppmann — *Designing Data-Intensive Applications*, capítulos de transacciones y concurrencia: <https://dataintensive.net/> · uso: respalda el Tema 5 «Concurrencia»
- OWASP — Business Logic Vulnerabilities: <https://owasp.org/www-community/vulnerabilities/Business_logic_vulnerability> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- GDC Vault — charlas sobre economías online, duplicación y respuesta a exploits: <https://www.gdcvault.com/> — catálogo por tema, no una charla identificada (ponente y año pendientes) · uso: respalda el Tema 8 «Ataques de duplicación»
- Godot Docs — `RandomNumberGenerator` (semillas de servidor): <https://docs.godotengine.org/en/4.3/classes/class_randomnumbergenerator.html> · uso: respalda el Tema 1 «Autoridad de servidor»

## ⬅️ Clase anterior

[Clase 313 - Cloud saves, cross-save y resolución de conflictos](../313-cloud-saves-cross-save-y-resolucion-de-conflictos/README.md)

## ➡️ Siguiente clase

[Clase 315 - Remote Config, feature flags y experimentos](../315-remote-config-feature-flags-y-experimentos/README.md)
