# Clase 306 — Facciones, reputación y relaciones

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Charlas de GDC sobre sistemas de facciones y simulación social · Millington & Funge, «Artificial Intelligence for Games»*
> ⏱️ Duración estimada: **110 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Implementar el sistema de **facciones y reputación**: quién es amigo de quién, cómo cambia esa relación con lo que hace el jugador y qué consecuencias tiene en el diálogo, el comercio, las quests y la IA. Es el sistema que convierte un mundo de NPC estáticos en uno que **reacciona**, y el que hace que una decisión tomada en la hora 3 se note en la hora 20.

Construirás una matriz de relaciones entre facciones, umbrales con nombre (`hostil`, `neutral`, `aliado`), propagación de reputación entre facciones aliadas y enemigas, decaimiento hacia la neutralidad y un conjunto de consultas que los demás sistemas usan sin conocer los detalles. Al terminar, matar a un bandido subirá tu reputación con la guardia, la bajará con el gremio de ladrones y hará que el mercader del gremio te suba los precios — todo sin un solo `if` a medida.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Modelar facciones, su matriz de relaciones y las relaciones NPC-jugador.
2. Implementar reputación numérica con umbrales nombrados y consultas estables.
3. Implementar propagación de cambios de reputación entre facciones relacionadas.
4. Implementar decaimiento temporal hacia la neutralidad y explicar cuándo conviene.
5. Integrar reputación con diálogo, comercio, quests e IA sin acoplar sistemas.
6. Modelar relaciones individuales con NPC además de las de facción.
7. Persistir el estado social y validar la coherencia de la matriz.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Facción | La unidad social del mundo: agrupa NPC y define bandos. |
| 2 | Matriz de relaciones | Define quién ataca a quién sin escribirlo caso por caso. |
| 3 | Reputación del jugador | El número que resume tu historia con cada facción. |
| 4 | Umbrales nombrados | Convierten un número en algo que el diseño puede usar. |
| 5 | Propagación | Ayudar a A perjudica a su enemigo B: emergencia con dos líneas. |
| 6 | Decaimiento | Decide si el mundo perdona con el tiempo. |
| 7 | Relación individual | Un NPC puede apreciarte aunque su facción te odie. |
| 8 | Hostilidad y agresión | La IA consulta esto para decidir a quién atacar. |
| 9 | Consecuencias en sistemas | Precios, diálogo y quests leen la misma consulta. |
| 10 | Persistencia y validación | El estado social es save; la matriz es contenido. |

## 📖 Definiciones y características

- **Facción**: grupo con identidad propia al que pertenecen NPC y del que el jugador puede tener reputación. Clave: es contenido con id estable.
- **Matriz de relaciones**: tabla que define la afinidad entre cada par de facciones. Clave: debe ser simétrica salvo que el diseño quiera lo contrario, y hay que decidirlo.
- **Reputación**: valor numérico de la relación jugador–facción, típicamente en `[-100, 100]`. Clave: el número es interno; el jugador ve el umbral.
- **Umbral (rango) de reputación**: tramo con nombre (`odiado`, `hostil`, `neutral`, `amistoso`, `aliado`). Clave: las reglas de diseño se escriben sobre el nombre, no sobre el número.
- **Afinidad entre facciones**: valor en `[-1, 1]` que dice si dos facciones son enemigas o aliadas. Clave: es el multiplicador de la propagación.
- **Propagación**: aplicación de una fracción del cambio de reputación a las facciones relacionadas. Clave: es lo que genera consecuencias no escritas a mano.
- **Decaimiento (decay)**: tendencia lenta de la reputación hacia 0 con el tiempo. Clave: define si el mundo olvida; es una decisión de diseño fuerte.
- **Relación individual**: afecto de un NPC concreto hacia el jugador, sumado al de su facción. Clave: permite excepciones narrativas dentro de un bando.
- **Hostilidad**: estado en que una facción o NPC ataca a la vista. Clave: se deriva del umbral, no se guarda aparte.
- **Reputación bloqueada (locked)**: valor que ya no puede subir por decisiones irreversibles. Clave: hace que las decisiones pesen de verdad.
- **Karma / alineamiento**: eje global independiente de facciones. Clave: es otra dimensión, no un sustituto de la reputación por facción.
- **Consulta social**: función que los demás sistemas llaman (`es_hostil`, `modificador_precio`). Clave: es la interfaz que evita el acoplamiento.
- **Evento social**: acción del jugador con consecuencia reputacional, definida en datos. Clave: permite ajustar el balance sin tocar código.
- **Coherencia de matriz**: ausencia de contradicciones (A aliado de B y B enemigo de A sin motivo). Clave: se valida en CI.

## 🧰 Herramientas y preparación

Necesitas el diálogo (304) y las quests (305) para las integraciones, y la economía (303) para el modificador de precios. Trabajaremos en `res://dominio/social/` y `res://datos/facciones.json`. Este sistema se conecta al mismo bus de eventos de la clase anterior: es la segunda vez que lo reutilizas, y no será la última.

## 🧪 Laboratorio guiado

1. **El dato:**

```json
{
  "version": 1,
  "umbrales": [
    { "nombre": "odiado",   "desde": -100 },
    { "nombre": "hostil",   "desde": -50 },
    { "nombre": "neutral",  "desde": -10 },
    { "nombre": "amistoso", "desde": 25 },
    { "nombre": "aliado",   "desde": 70 }
  ],
  "facciones": [
    { "id": "guardia",  "nombre": "fac.guardia",  "decaimiento": 0.5 },
    { "id": "ladrones", "nombre": "fac.ladrones", "decaimiento": 0.0 },
    { "id": "gremio",   "nombre": "fac.gremio",   "decaimiento": 0.2 },
    { "id": "bandidos", "nombre": "fac.bandidos", "decaimiento": 0.0 }
  ],
  "relaciones": [
    { "a": "guardia", "b": "bandidos", "afinidad": -1.0 },
    { "a": "guardia", "b": "ladrones", "afinidad": -0.6 },
    { "a": "guardia", "b": "gremio",   "afinidad": 0.7 },
    { "a": "ladrones", "b": "bandidos", "afinidad": 0.3 },
    { "a": "gremio", "b": "ladrones",  "afinidad": -0.4 }
  ],
  "eventos": [
    { "id": "matar_bandido", "cambios": [{ "faccion": "bandidos", "valor": -8 }] },
    { "id": "robar_a_gremio", "cambios": [{ "faccion": "gremio", "valor": -15 }] },
    { "id": "quest_guardia_completada", "cambios": [{ "faccion": "guardia", "valor": 20 }] }
  ]
}
```

Fíjate en que un evento solo declara el cambio **directo**. Lo demás lo hará la propagación: matar a un bandido bajará la reputación con bandidos y, por la afinidad `-1.0`, subirá con la guardia sin que nadie lo escriba.

2. **El sistema social:**

```gdscript
class_name Social
extends RefCounted

signal reputacion_cambiada(faccion: StringName, nueva: float, umbral: String)
signal umbral_cruzado(faccion: StringName, anterior: String, nuevo: String)

const MIN := -100.0
const MAX := 100.0
const FACTOR_PROPAGACION := 0.5    # la propagación vale la mitad que el cambio directo

var _facciones := {}               # id -> Dictionary
var _afinidad := {}                # "a|b" -> float
var _eventos := {}                 # id -> Array[cambios]
var _umbrales: Array = []          # [{nombre, desde}] ordenado
var _reputacion := {}              # id -> float (ESTADO: va al save)
var _individual := {}              # id_npc -> float (ESTADO)
var _bloqueadas := {}              # id -> true

func cargar(ruta: String) -> Array[String]:
	var d = JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return ["facciones.json ilegible"]
	_umbrales = d.get("umbrales", [])
	_umbrales.sort_custom(func(a, b): return float(a["desde"]) < float(b["desde"]))
	for f in d.get("facciones", []):
		var id := StringName(str(f["id"]))
		_facciones[id] = f
		_reputacion[id] = 0.0
	for r in d.get("relaciones", []):
		_fijar_afinidad(StringName(str(r["a"])), StringName(str(r["b"])), float(r["afinidad"]))
	for e in d.get("eventos", []):
		_eventos[StringName(str(e["id"]))] = e.get("cambios", [])
	return validar()

func _clave(a: StringName, b: StringName) -> String:
	# Clave ordenada: la relación es simétrica, así que "a|b" y "b|a" son la misma.
	return "%s|%s" % ([String(a), String(b)] if String(a) < String(b) else [String(b), String(a)])

func _fijar_afinidad(a: StringName, b: StringName, v: float) -> void:
	_afinidad[_clave(a, b)] = clampf(v, -1.0, 1.0)

func afinidad(a: StringName, b: StringName) -> float:
	if a == b:
		return 1.0
	return _afinidad.get(_clave(a, b), 0.0)
```

3. **Umbrales y consultas.** La interfaz que usan los demás sistemas:

```gdscript
func reputacion(f: StringName) -> float:
	return _reputacion.get(f, 0.0)

func umbral(f: StringName) -> String:
	var actual := "neutral"
	for u in _umbrales:
		if reputacion(f) >= float(u["desde"]):
			actual = str(u["nombre"])
	return actual

func es_hostil(f: StringName) -> bool:
	return umbral(f) in ["hostil", "odiado"]

func es_aliado(f: StringName) -> bool:
	return umbral(f) == "aliado"

func modificador_precio(f: StringName) -> float:
	# De 1.25 (te odian) a 0.85 (aliado). Explicable y acotado: un jugador debe
	# poder entender por qué el pan le cuesta más aquí.
	var r := reputacion(f)
	return clampf(1.05 - (r / 100.0) * 0.2, 0.85, 1.25)

func actitud_hacia(id_npc: StringName, f: StringName) -> float:
	# La relación personal se SUMA a la de facción: un NPC puede apreciarte
	# aunque su facción te odie, que es donde vive la narrativa interesante.
	return clampf(reputacion(f) + _individual.get(id_npc, 0.0), MIN, MAX)
```

4. **Aplicar un evento social, con propagación:**

```gdscript
func aplicar_evento(id_evento: StringName) -> void:
	if not _eventos.has(id_evento):
		push_warning("evento social desconocido: %s" % id_evento)
		return
	for c in _eventos[id_evento]:
		modificar(StringName(str(c["faccion"])), float(c["valor"]), true)

func modificar(f: StringName, delta: float, propagar := true) -> void:
	if not _facciones.has(f) or is_zero_approx(delta):
		return
	_aplicar(f, delta)
	if not propagar:
		return
	for otra in _facciones:
		if otra == f:
			continue
		var a := afinidad(f, otra)
		if is_zero_approx(a):
			continue
		# Enemigo de mi enemigo: afinidad -1 invierte el signo del cambio.
		_aplicar(otra, delta * a * FACTOR_PROPAGACION)

func _aplicar(f: StringName, delta: float) -> void:
	if _bloqueadas.has(f) and delta > 0.0:
		return                       # decisión irreversible: ya no se puede subir
	var antes := umbral(f)
	_reputacion[f] = clampf(reputacion(f) + delta, MIN, MAX)
	var ahora := umbral(f)
	reputacion_cambiada.emit(f, _reputacion[f], ahora)
	if antes != ahora:
		umbral_cruzado.emit(f, antes, ahora)

func bloquear(f: StringName) -> void:
	_bloqueadas[f] = true
```

5. **Decaimiento.** Opcional y por facción, porque no todas perdonan igual:

```gdscript
func tick(delta_horas: float) -> void:
	for f in _facciones:
		var tasa := float(_facciones[f].get("decaimiento", 0.0))
		if is_zero_approx(tasa) or _bloqueadas.has(f):
			continue
		var r := reputacion(f)
		if is_zero_approx(r):
			continue
		# Tiende a 0 sin pasarse: move_toward evita oscilar alrededor del cero.
		_aplicar(f, move_toward(r, 0.0, tasa * delta_horas) - r)
```

6. **Conectarlo a los demás sistemas.** Aquí se ve el pago de haber desacoplado todo:

```gdscript
# En el arranque, no dentro de cada sistema.
func conectar(bus: EventosJuego, cond: Condiciones, tienda: Tienda) -> void:
	bus.enemigo_muerto.connect(func(id, _p):
		if id == &"bandido":
			aplicar_evento(&"matar_bandido"))

	# El diálogo pregunta; no sabe qué es una facción.
	cond.consultas[&"reputacion_min"] = func(d: Dictionary) -> bool:
		return reputacion(StringName(str(d["faccion"]))) >= float(d["valor"])

	# La tienda ajusta precios; tampoco sabe qué es la reputación.
	reputacion_cambiada.connect(func(f, _v, _u):
		if f == tienda.id_tienda:
			tienda.modificador_precio = modificador_precio(f))
```

7. **Validar y persistir:**

```gdscript
func validar() -> Array[String]:
	var errores: Array[String] = []
	if _umbrales.is_empty():
		errores.append("no hay umbrales definidos")
	for clave in _afinidad:
		for parte in clave.split("|"):
			if not _facciones.has(StringName(parte)):
				errores.append("relación con facción inexistente: '%s'" % parte)
	for id in _eventos:
		for c in _eventos[id]:
			if not _facciones.has(StringName(str(c.get("faccion", "")))):
				errores.append("evento '%s': facción inexistente '%s'" % [id, c.get("faccion", "")])
	# Una facción aislada nunca propagará nada: suele ser un olvido, no un diseño.
	for f in _facciones:
		var tiene := false
		for otra in _facciones:
			if otra != f and not is_zero_approx(afinidad(f, otra)):
				tiene = true
		if not tiene:
			errores.append("aviso: la facción '%s' no tiene ninguna relación definida" % f)
	return errores

func a_dict() -> Dictionary:
	return {"reputacion": _reputacion, "individual": _individual,
			"bloqueadas": _bloqueadas.keys().map(func(k): return String(k))}

func de_dict(d: Dictionary) -> void:
	for clave in d.get("reputacion", {}):
		var id := StringName(str(clave))
		if _facciones.has(id):
			_reputacion[id] = float(d["reputacion"][clave])
	_individual = d.get("individual", {}).duplicate()
	_bloqueadas.clear()
	for k in d.get("bloqueadas", []):
		_bloqueadas[StringName(str(k))] = true
```

8. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	var s := Social.new()
	var avisos := s.cargar("res://datos/facciones.json")
	assert(avisos.filter(func(e): return not e.begins_with("aviso")).is_empty(), "la matriz no valida")

	# Matar bandidos baja con bandidos y sube con la guardia (afinidad -1).
	s.aplicar_evento(&"matar_bandido")
	assert(s.reputacion(&"bandidos") == -8.0)
	assert(s.reputacion(&"guardia") == 4.0, "la propagación no llegó a la guardia")
	# Y baja algo con ladrones, aliados parciales de los bandidos (0.3).
	assert(is_equal_approx(s.reputacion(&"ladrones"), -1.2), "propagación indirecta incorrecta")

	# Umbral y precio.
	for i in 10: s.modificar(&"gremio", 10.0, false)
	assert(s.umbral(&"gremio") == "aliado")
	assert(s.modificador_precio(&"gremio") < 1.0, "un aliado debería vender más barato")

	# Decaimiento: la guardia perdona, los bandidos no.
	var rep_bandidos := s.reputacion(&"bandidos")
	s.tick(10.0)
	assert(s.reputacion(&"bandidos") == rep_bandidos, "los bandidos no deberían olvidar")

	print("== 6 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Añade reputación **por región** además de por facción y combínalas al consultar la actitud.
2. Implementa testigos: un crimen solo afecta a la reputación si alguien lo ve.
3. Añade "recompensa por tu cabeza" (bounty) que crezca con los crímenes y se pueda pagar.
4. Implementa quests exclusivas por facción que se bloqueen mutuamente al aceptarse.
5. Haz que la IA de un enemigo consulte `es_hostil` para elegir objetivo y prueba dos facciones peleando entre sí.
6. Añade un panel de reputación en la UI alimentado solo por señales.
7. Genera un diagrama de la matriz de facciones en Graphviz con las afinidades como pesos.

## 📝 Reto verificable

Implementa el sistema con **al menos cuatro facciones**, matriz de relaciones, cinco umbrales, propagación, decaimiento por facción, relaciones individuales, bloqueo irreversible e integración con diálogo, comercio y quests.

**Criterio de aceptación**: una prueba headless con **al menos 16 aserciones** demuestra que: (a) un evento que baja 10 puntos con una facción sube exactamente `10 × |afinidad| × FACTOR_PROPAGACION` con su enemiga; (b) cruzar un umbral emite `umbral_cruzado` con el nombre anterior y el nuevo, **una sola vez** por cruce; (c) la reputación queda siempre acotada en `[-100, 100]` tras 1.000 modificaciones aleatorias; (d) una facción con decaimiento 0 no cambia con `tick()`, y una con decaimiento positivo se acerca a 0 sin cruzarlo; (e) una facción bloqueada no sube pero sí baja; (f) el validador detecta una relación con facción inexistente y un evento con facción inexistente.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Ayudar a una facción no afecta a nadie más | Falta la propagación, o la matriz está vacía. Comprueba las afinidades. |
| La reputación oscila alrededor de cero con el decaimiento | Se resta un valor fijo. Usa `move_toward` para no pasarse. |
| `umbral_cruzado` se emite en cada golpe | Se compara el valor, no el umbral. Compara el nombre antes y después. |
| Toda la ciudad me ataca por un error | La propagación es demasiado fuerte o la matriz demasiado polarizada. Ajusta `FACTOR_PROPAGACION`. |
| Un NPC amigo me ataca porque su facción me odia | Solo se consulta la facción. Usa `actitud_hacia` con la relación individual. |
| Los precios cambian y el jugador no entiende por qué | Falta comunicar el umbral. Muestra el estado de reputación en la tienda. |
| La reputación se dispara a 500 | Falta el `clampf`. Acota siempre en `_aplicar`. |
| Añadir una facción rompe el balance social | La matriz es incompleta. Valida que toda facción tenga relaciones. |

## ❓ Preguntas frecuentes

**❓ ¿Un número por facción o una matriz completa jugador–NPC?** Empieza por el número por facción más una tabla dispersa de excepciones individuales: es el 95 % del valor con el 10 % de la complejidad. Una matriz completa solo compensa en juegos de simulación social donde las relaciones NPC-NPC son el núcleo.

**❓ ¿La afinidad debe ser simétrica?** Por defecto sí, y por eso la clave está ordenada. Si tu diseño necesita asimetría (A desprecia a B pero B admira a A), guarda las dos direcciones — pero hazlo a conciencia, porque duplica la superficie a validar.

**❓ ¿Decaimiento sí o no?** Con decaimiento el mundo perdona y el jugador puede recuperarse de un error; sin él, las decisiones son permanentes y pesan más. Muchos juegos lo aplican solo a la reputación positiva (lo bueno se olvida, lo malo no), lo cual se consigue con una condición en `tick`.

**❓ ¿Cómo evito que el jugador quede sin acceso a contenido?** Con dos herramientas: umbrales de no-retorno explícitos y documentados (para que la irreversibilidad sea una decisión y no un accidente), y misiones de redención. Lo que no debe pasar nunca es que un jugador quede bloqueado sin haberlo elegido.

**❓ ¿Esto sirve para IA de combate?** Directamente: la IA pregunta `es_hostil(faccion_del_objetivo)` en vez de tener listas de enemigos. Con eso, dos facciones hostiles entre sí pelean solas y el jugador puede provocar el conflicto — emergencia gratis, en la línea de la [clase 169](../../parte-8-game-design-y-diseno-de-niveles/169-diseno-de-sistemas-emergentes-y-sandbox/README.md).

## 🔗 Referencias

- Ian Millington & John Funge — *Artificial Intelligence for Games*: <https://www.routledge.com/Artificial-Intelligence-for-Games/Millington/p/book/9780367670566>
- GDC Vault — charlas sobre sistemas de facciones, reputación y simulación social: <https://www.gdcvault.com/>
- Godot Docs — Señales y diccionarios: <https://docs.godotengine.org/en/stable/classes/class_dictionary.html>
- Godot Docs — `@GlobalScope.move_toward` y funciones matemáticas: <https://docs.godotengine.org/en/stable/classes/class_@globalscope.html>
- Robert Nystrom — *Game Programming Patterns*, Observer: <https://gameprogrammingpatterns.com/observer.html>

## ⬅️ Clase anterior

[Clase 305 - Quest System](../305-quest-system/README.md)

## ➡️ Siguiente clase

[Clase 307 - Save System de producción](../307-save-system-de-produccion/README.md)
