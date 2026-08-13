# Clase 303 — Economía interna implementada

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Charlas de GDC sobre economías de juego y virtual economy design · Schell, «The Art of Game Design»*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Implementar la **economía interna**: monedas, fuentes, sumideros, tiendas, precios, compra y venta, historial de transacciones y las herramientas para saber si el conjunto está sano o se está inflando. La [clase 158](../../parte-8-game-design-y-diseno-de-niveles/158-mecanicas-verbos-y-economia-del-jugador/README.md) enseñó a *diseñar* la economía del jugador y la [161](../../parte-8-game-design-y-diseno-de-niveles/161-balanceo-de-juego-numeros-spreadsheets-y-tuning/README.md) a balancear con hojas de cálculo; aquí se construye el sistema que ejecuta ese diseño y, sobre todo, el que permite **medirlo**.

La idea central es simple y casi nunca se implementa: toda variación de moneda pasa por un único punto y queda registrada con su motivo. Con eso obtienes gratis el balance de fuentes y sumideros, la detección de inflación, la auditoría anti-trampas y los datos de telemetría que necesitarás en la Parte 19. Sin eso, tienes `oro += 50` en 40 sitios y ninguna forma de saber por qué los jugadores tienen tres millones.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Modelar varias monedas con reglas propias (blanda, dura, premium) y sus restricciones.
2. Implementar un monedero donde **toda** variación pasa por un punto único y registrado.
3. Distinguir fuentes (faucets) de sumideros (sinks) y medir el balance neto por hora de juego.
4. Implementar una tienda con inventario, precios dinámicos, compra y venta atómicas.
5. Detectar inflación con un simulador de partida y ajustar los sumideros.
6. Implementar historial de transacciones y usarlo para auditoría y depuración.
7. Explicar por qué en un juego online la economía debe ser autoritativa del servidor.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Tipos de moneda | Cada una tiene reglas distintas: mezclarlas rompe el diseño y la ley. |
| 2 | Punto único de mutación | Sin él no hay telemetría, ni auditoría, ni balance. |
| 3 | Fuentes (faucets) | Todo lo que crea dinero: loot, quests, ventas. |
| 4 | Sumideros (sinks) | Todo lo que lo destruye: reparaciones, viajes, mejoras. |
| 5 | Balance neto | La cifra que decide si tu economía se infla o se ahoga. |
| 6 | Precios y márgenes | El diferencial compra/venta es el sumidero más discreto. |
| 7 | Tienda con stock | Convierte comprar en una decisión, no en un grifo infinito. |
| 8 | Precios dinámicos | Oferta y demanda o simple escasez temporal. |
| 9 | Historial de transacciones | El registro que permite responder "¿de dónde salió esto?". |
| 10 | Simulación económica | Probar 100 horas de juego en 2 segundos antes de publicar. |

## 📖 Definiciones y características

- **Moneda blanda (soft currency)**: la que se gana jugando en abundancia. Clave: su exceso se corrige con sumideros, no bajando las fuentes.
- **Moneda dura (hard currency)**: escasa, ligada a logros o compra. Clave: exige mucho más control y suele ser autoritativa del servidor.
- **Monedero (wallet)**: componente que guarda los saldos y es el único que los modifica. Clave: su API no expone escritura directa.
- **Fuente (faucet)**: mecanismo que **crea** moneda en la economía. Clave: se identifica por un motivo etiquetado, no por el sitio del código.
- **Sumidero (sink)**: mecanismo que **destruye** moneda. Clave: sin sumideros suficientes, toda economía se infla.
- **Balance neto**: fuentes menos sumideros por unidad de tiempo. Clave: si es persistentemente positivo, la moneda pierde valor.
- **Inflación**: pérdida de poder adquisitivo por exceso de moneda circulante. Clave: se detecta antes en un simulador que en producción.
- **Precio base**: valor de referencia de un item, del catálogo. Clave: debe derivarse del coste de crafteo, no ponerse a ojo.
- **Diferencial compra/venta (spread)**: diferencia entre lo que cuesta comprar y lo que pagan al vender. Clave: es un sumidero silencioso y muy eficaz.
- **Stock**: unidades disponibles en una tienda. Clave: convierte la tienda en un recurso y no en un grifo.
- **Reposición (restock)**: recuperación del stock con el tiempo. Clave: define el ritmo real de acceso a los items.
- **Precio dinámico**: precio que varía con la escasez, la reputación o la demanda. Clave: debe ser explicable al jugador o parecerá roto.
- **Transacción**: registro inmutable de un cambio de saldo con motivo, cantidad y momento. Clave: es la unidad de auditoría.
- **Motivo (reason)**: etiqueta corta que clasifica la transacción (`loot`, `venta`, `reparacion`). Clave: sin taxonomía cerrada, la telemetría es inútil.
- **Auditoría**: comprobación de que el saldo actual coincide con la suma del historial. Clave: detecta duplicaciones y bugs de economía.
- **Máquina de dinero (money loop)**: combinación de operaciones que produce beneficio infinito. Clave: casi siempre nace de comprar y vender lo mismo con márgenes mal puestos.

## 🧰 Herramientas y preparación

Necesitas el catálogo (294), el inventario con transacciones (295) y el árbol de coste de crafteo (301) para derivar precios coherentes. Trabajaremos en `res://dominio/economia/`. Ten a mano el análisis de loot de la clase 300: la moneda que sueltan los enemigos es tu principal fuente, y su valor esperado por hora es el primer número del balance.

## 🧪 Laboratorio guiado

1. **El monedero con punto único de mutación.** Fíjate en que no hay setter público:

```gdscript
class_name Monedero
extends RefCounted

signal saldo_cambiado(moneda: StringName, nuevo: int, delta: int, motivo: StringName)

const MONEDAS := [&"oro", &"gemas", &"fragmentos"]

var _saldos := {}
var _historial: Array[Dictionary] = []
var _tiempo_juego: float = 0.0

func _init() -> void:
	for m in MONEDAS:
		_saldos[m] = 0

func saldo(m: StringName) -> int:
	return _saldos.get(m, 0)

func avanzar_tiempo(delta: float) -> void:
	_tiempo_juego += delta

# --- ÚNICO punto de mutación de todo el juego -----------------------------
func _mover(m: StringName, delta: int, motivo: StringName) -> bool:
	if delta == 0 or not _saldos.has(m):
		return false
	var nuevo := _saldos[m] + delta
	if nuevo < 0:
		return false                       # no se permite saldo negativo, nunca
	_saldos[m] = nuevo
	_historial.append({
		"t": _tiempo_juego, "moneda": String(m),
		"delta": delta, "saldo": nuevo, "motivo": String(motivo),
	})
	saldo_cambiado.emit(m, nuevo, delta, motivo)
	return true

func ingresar(m: StringName, cantidad: int, motivo: StringName) -> bool:
	assert(cantidad > 0, "ingresar espera cantidades positivas")
	return _mover(m, cantidad, motivo)

func gastar(m: StringName, cantidad: int, motivo: StringName) -> bool:
	assert(cantidad > 0, "gastar espera cantidades positivas")
	return _mover(m, -cantidad, motivo)

func puede_pagar(m: StringName, cantidad: int) -> bool:
	return saldo(m) >= cantidad
```

El `motivo` obligatorio en la firma no es burocracia: es lo que hace que exista el informe del paso 5. Si fuera opcional, en tres semanas la mitad de las transacciones dirían `"desconocido"`.

2. **El informe de fuentes y sumideros.** Es la razón de ser del historial:

```gdscript
func informe() -> Dictionary:
	var fuentes := {}
	var sumideros := {}
	for t in _historial:
		var clave := "%s:%s" % [t["moneda"], t["motivo"]]
		if t["delta"] > 0:
			fuentes[clave] = fuentes.get(clave, 0) + t["delta"]
		else:
			sumideros[clave] = sumideros.get(clave, 0) - t["delta"]
	var total_in := 0; var total_out := 0
	for v in fuentes.values(): total_in += v
	for v in sumideros.values(): total_out += v
	var horas := maxf(_tiempo_juego / 3600.0, 0.0001)
	return {
		"fuentes": fuentes, "sumideros": sumideros,
		"neto": total_in - total_out,
		"neto_por_hora": (total_in - total_out) / horas,
		"transacciones": _historial.size(),
	}

func auditar() -> bool:
	"""El saldo debe ser exactamente la suma de los deltas. Si no, hay un bug."""
	var suma := {}
	for m in MONEDAS: suma[m] = 0
	for t in _historial:
		suma[StringName(t["moneda"])] += int(t["delta"])
	for m in MONEDAS:
		if suma[m] != _saldos[m]:
			push_error("auditoría fallida en %s: historial %d vs saldo %d" % [m, suma[m], _saldos[m]])
			return false
	return true
```

3. **Los precios, derivados del crafteo.** Nada de números a ojo:

```gdscript
class_name Precios
extends RefCounted

const MARGEN_VENTA := 0.4          # el jugador recibe el 40 % al vender: spread del 60 %

var _base: BaseDeItems
var _crafteo: Crafteo

func _init(base: BaseDeItems, crafteo: Crafteo) -> void:
	_base = base
	_crafteo = crafteo

func precio_compra(id: StringName, modificador := 1.0) -> int:
	var d := _base.obtener(id)
	var por_rareza: float = Item.PESO_RAREZA.get(d.rareza, 1.0)
	return maxi(1, int(round(d.valor * por_rareza * modificador)))

func precio_venta(id: StringName) -> int:
	# Vender SIEMPRE por debajo de comprar: si no, comprar y vender es una
	# máquina de dinero y el jugador la encontrará en veinte minutos.
	return maxi(1, int(floor(precio_compra(id) * MARGEN_VENTA)))

func coherente(id: StringName) -> bool:
	"""Craftear no puede salir más caro que comprar el resultado y venderlo."""
	var coste := 0
	for material in _crafteo.coste_base(id):
		coste += precio_compra(material) * _crafteo.coste_base(id)[material]
	return precio_venta(id) < coste or coste == 0
```

4. **La tienda.** Con stock y reposición, que es lo que la convierte en diseño:

```gdscript
class_name Tienda
extends RefCounted

signal comprado(id: StringName, cantidad: int, coste: int)
signal vendido(id: StringName, cantidad: int, pago: int)

enum Fallo { OK, SIN_STOCK, SIN_SALDO, SIN_ESPACIO, NO_COMPRA_ESE_ITEM, SIN_ITEM }

var id_tienda: StringName
var moneda: StringName = &"oro"
var _precios: Precios
var _stock := {}                    # id -> unidades disponibles
var _stock_max := {}
var _tiempo_restock := 0.0
var periodo_restock := 300.0
var modificador_precio := 1.0       # reputación, dificultad, eventos
var compra_tags: PackedStringArray = ["arma", "consumible", "material"]

func _init(precios: Precios) -> void:
	_precios = precios

func abastecer(id: StringName, unidades: int) -> void:
	_stock[id] = unidades
	_stock_max[id] = unidades

func tick(delta: float) -> void:
	_tiempo_restock += delta
	while _tiempo_restock >= periodo_restock:
		_tiempo_restock -= periodo_restock
		for id in _stock_max:
			_stock[id] = mini(_stock_max[id], _stock.get(id, 0) + 1)

func precio(id: StringName) -> int:
	# Escasez: cuanto menos queda, más caro. Explicable y con tope.
	var ratio := 1.0
	if _stock_max.get(id, 0) > 0:
		var q := float(_stock.get(id, 0)) / float(_stock_max[id])
		ratio = lerpf(1.5, 1.0, clampf(q, 0.0, 1.0))
	return _precios.precio_compra(id, modificador_precio * ratio)
```

5. **Comprar y vender, atómicamente.** Dos sistemas otra vez, así que transacción:

```gdscript
func comprar(id: StringName, n: int, inv: Inventario, w: Monedero) -> Fallo:
	if _stock.get(id, 0) < n:
		return Fallo.SIN_STOCK
	var coste := precio(id) * n
	if not w.puede_pagar(moneda, coste):
		return Fallo.SIN_SALDO
	if inv.cabe(id, n) < n:
		return Fallo.SIN_ESPACIO

	# Orden importante: primero cobramos, luego entregamos; si la entrega falla,
	# devolvemos. Al revés, un fallo al cobrar regala el item.
	if not w.gastar(moneda, coste, StringName("compra:%s" % id_tienda)):
		return Fallo.SIN_SALDO
	if not inv.agregar_todo_o_nada(id, n):
		w.ingresar(moneda, coste, StringName("rollback_compra:%s" % id_tienda))
		return Fallo.SIN_ESPACIO

	_stock[id] -= n
	comprado.emit(id, n, coste)
	return Fallo.OK

func vender(id: StringName, n: int, inv: Inventario, w: Monedero, base: BaseDeItems) -> Fallo:
	if inv.contar(id) < n:
		return Fallo.SIN_ITEM
	var d := base.obtener(id)
	var acepta := false
	for t in compra_tags:
		if d.tiene_tag(t):
			acepta = true
	if not acepta:
		return Fallo.NO_COMPRA_ESE_ITEM
	var pago := _precios.precio_venta(id) * n
	if not inv.quitar(id, n):
		return Fallo.SIN_ITEM
	w.ingresar(moneda, pago, StringName("venta:%s" % id_tienda))
	_stock[id] = _stock.get(id, 0) + n          # lo vendido vuelve al stock
	vendido.emit(id, n, pago)
	return Fallo.OK
```

6. **El simulador.** Cien horas de juego en dos segundos, y el veredicto:

```gdscript
extends SceneTree   # godot --headless --script res://herramientas/simular_economia.gd

const HORAS := 100
const ENEMIGOS_POR_HORA := 120
const MUERTES_POR_HORA := 1.5

func _init() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	var base := BaseDeItems.new(); base.cargar_desde_json("res://datos/items.json")
	var tablas := TablasDeLoot.new(base, rng); tablas.cargar("res://datos/loot.json")
	var w := Monedero.new()

	for h in HORAS:
		w.avanzar_tiempo(3600.0)
		# FUENTES
		for e in ENEMIGOS_POR_HORA:
			for s in tablas.tirar(&"humanoide_basico", {"nivel": 20}):
				if s.id == &"moneda_oro":
					w.ingresar(&"oro", s.cantidad, &"loot")
		w.ingresar(&"oro", 500, &"quests")
		# SUMIDEROS
		w.gastar(&"oro", mini(w.saldo(&"oro"), 300), &"consumibles")
		w.gastar(&"oro", mini(w.saldo(&"oro"), int(200 * MUERTES_POR_HORA)), &"reparacion")

	var inf := w.informe()
	print("== Simulación de %d horas ==" % HORAS)
	for clave in inf["fuentes"]:  printt("  fuente ", clave, inf["fuentes"][clave])
	for clave in inf["sumideros"]: printt("  sumidero", clave, inf["sumideros"][clave])
	print("Saldo final: %d oro · neto/hora: %.1f" % [w.saldo(&"oro"), inf["neto_por_hora"]])
	assert(w.auditar(), "la auditoría no cuadra")
	quit()
```

Si `neto_por_hora` crece sin freno, tu economía se infla: el jugador acabará con más oro del que existe nada que comprar, y el dinero dejará de motivar. La corrección casi nunca es "que caiga menos oro" (se siente mal), sino **añadir sumideros deseables**: mejoras caras, cosmética, reparaciones, viajes rápidos.

7. **Probarlo:**

```gdscript
var w := Monedero.new()
assert(not w.gastar(&"oro", 10, &"test"), "se permitió saldo negativo")
w.ingresar(&"oro", 100, &"loot")
assert(w.saldo(&"oro") == 100 and w.auditar())

var t := Tienda.new(precios); t.abastecer(&"pocion_menor", 5)
var antes := w.saldo(&"oro")
assert(t.comprar(&"pocion_menor", 99, inv, w) == Tienda.Fallo.SIN_STOCK)
assert(w.saldo(&"oro") == antes, "una compra fallida movió dinero")
assert(precios.precio_venta(&"pocion_menor") < precios.precio_compra(&"pocion_menor"),
	"comprar y vender es una máquina de dinero")
```

## ✍️ Ejercicios

1. Añade una moneda `gemas` que **no** se pueda vender ni comprar con oro, y prueba que no hay conversión posible.
2. Implementa impuestos: un 5 % de cada venta se destruye como sumidero.
3. Añade descuentos por reputación de facción (adelanta la clase 306) y comprueba el efecto en el balance.
4. Implementa un "mercado" con precios que suben si muchos jugadores compran (con datos simulados).
5. Detecta automáticamente máquinas de dinero: busca pares de operaciones con beneficio neto positivo.
6. Añade un tope de saldo y decide qué pasa al alcanzarlo.
7. Exporta el historial a CSV y analiza en una hoja de cálculo qué motivo domina las fuentes.

## 📝 Reto verificable

Implementa el monedero con punto único de mutación e historial, precios derivados del coste de crafteo, una tienda con stock, reposición y precio por escasez, y un simulador de 100 horas.

**Criterio de aceptación**: (a) `godot --headless --script res://herramientas/simular_economia.gd` imprime fuentes, sumideros y neto por hora, y termina con `auditar() == true`; (b) no existe ninguna llamada que modifique un saldo fuera de `_mover`, comprobable porque `_saldos` solo se escribe en esa función; (c) para **todos** los items del catálogo, `precio_venta < precio_compra`; (d) una compra fallida por cualquiera de los cinco motivos deja saldo, inventario y stock exactamente igual que antes; (e) una prueba con al menos 15 aserciones cubre saldo negativo, stock insuficiente, sin espacio, item no aceptado por la tienda y rollback de la entrega.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Los jugadores tienen millones de oro a las 30 horas | Fuentes sin sumideros equivalentes. Mide el neto por hora en el simulador y añade sumideros deseables. |
| No hay forma de saber de dónde salió el dinero | Se muta el saldo en 40 sitios. Punto único de mutación con motivo obligatorio. |
| Comprar y vender lo mismo da beneficio | El margen de venta es demasiado alto. `precio_venta` siempre por debajo de `precio_compra`. |
| Craftear y vender es más rentable que jugar | El precio del resultado supera el de sus materiales. Compara con `coste_base`. |
| Una compra fallida se queda con el dinero | No hay rollback tras cobrar. Devuelve al fallar la entrega, o usa la transacción. |
| El saldo aparece negativo tras un bug | No se validó `nuevo < 0`. La validación va en `_mover`, no en cada llamador. |
| La tienda es un grifo infinito de pociones | Sin stock ni reposición. Añade ambos: convierten comprar en decisión. |
| La economía se rompe con un item nuevo | Se le puso valor a ojo. Derívalo del coste de crafteo y valida en CI. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué obligar a un motivo en cada transacción?** Porque es lo que convierte tu economía en algo medible. Con motivos tienes el informe del paso 2 gratis, la telemetría de la Parte 19 casi hecha y la capacidad de responder a un jugador que dice que le falta oro. Sin motivos, tienes un número.

**❓ ¿Los sumideros no frustran al jugador?** Los malos, sí (impuestos arbitrarios). Los buenos son cosas que el jugador **quiere** comprar: mejoras, cosmética, comodidades. La regla práctica es que el sumidero debe dar algo a cambio, aunque sea estatus.

**❓ ¿Cómo pongo el precio de un item nuevo?** Calcula su coste de crafteo en materiales base ([clase 301](../301-crafting-y-recetas/README.md)), valora esos materiales con las tablas de loot ([clase 300](../300-loot-tables-y-sistemas-de-recompensas/README.md)) y añade un margen. Después pásalo por `coherente()` para que no genere beneficio.

**❓ ¿Y si el juego tiene compras reales?** Entonces la moneda dura deja de ser un tema de gameplay y pasa a ser un tema legal, fiscal y de seguridad: la autoridad **debe** estar en el servidor, con entitlements y recibos verificados. Eso se trata en las clases [312](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/312-identidad-perfiles-y-entitlements/README.md) y [314](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/314-economia-transaccional-de-servidor/README.md), y el marco legal en la [clase 273](../../parte-16-produccion-publicacion-monetizacion-y-liveops/273-presupuesto-contratos-y-aspectos-legales/README.md).

**❓ ¿Cuánto historial guardo?** En local, una ventana (las últimas 500 transacciones) basta para depurar y no engorda el save. La contabilidad completa, si hace falta, vive en el servidor: allí es un registro de auditoría con retención definida ([clase 317](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/317-telemetria-privacidad-y-gobernanza-de-datos/README.md)).

## 🔗 Referencias

- GDC Vault — charlas sobre diseño de economías virtuales, faucets y sinks: <https://www.gdcvault.com/>
- Jesse Schell — *The Art of Game Design*, capítulo sobre economías: <https://www.schellgames.com/art-of-game-design/>
- Godot Docs — Señales y `StringName`: <https://docs.godotengine.org/en/stable/classes/class_stringname.html>
- Godot Docs — `FileAccess` y exportación de datos (CSV del historial): <https://docs.godotengine.org/en/stable/classes/class_fileaccess.html>
- Vili Lehdonvirta & Edward Castronova — *Virtual Economies: Design and Analysis* (MIT Press): <https://mitpress.mit.edu/9780262027250/virtual-economies/>

## ⬅️ Clase anterior

[Clase 302 - Progresión y skill trees](../302-progresion-y-skill-trees/README.md)

## ➡️ Siguiente clase

[Clase 304 - Sistemas de diálogo](../304-sistemas-de-dialogo/README.md)
