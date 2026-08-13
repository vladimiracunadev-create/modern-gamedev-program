# Clase 300 — Loot tables y sistemas de recompensas

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Charlas de GDC sobre sistemas de recompensa y economía de loot · Documentación de `RandomNumberGenerator` de Godot*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir el sistema que decide **qué suelta un enemigo, un cofre o un jefe**. Es un sistema pequeño en líneas de código y enorme en consecuencias: el loot marca el ritmo de progresión, la economía y la sensación de recompensa de todo el juego, y es de los pocos sistemas donde un error de una cifra decimal no se nota hasta que llevas veinte horas de partida.

Implementarás **tablas ponderadas**, tablas anidadas, drops garantizados, condiciones, y dos cosas que separan un sistema de producción de un `randi() % 100`: **determinismo por semilla** —para poder reproducir exactamente lo que le pasó a un jugador— y **sistemas de piedad (pity)**, que corrigen la crueldad estadística de la aleatoriedad pura. Y analizarás matemáticamente lo que has construido: probabilidad efectiva, valor esperado y varianza, porque un sistema de loot que no se puede calcular no se puede balancear.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Implementar una tabla ponderada correcta y explicar por qué los pesos no son porcentajes.
2. Componer tablas anidadas y entender cómo se multiplican las probabilidades.
3. Implementar drops garantizados, condicionales y por cantidad variable.
4. Hacer el loot **reproducible** inyectando un RNG sembrado, y explicar por qué importa.
5. Implementar un sistema de piedad (pity duro y blando) y calcular su efecto real.
6. Calcular la probabilidad efectiva, el valor esperado y la desviación de una tabla.
7. Validar las tablas en CI: pesos positivos, ids existentes y ausencia de ciclos.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Peso vs probabilidad | Confundirlos hace que añadir un item cambie las de todos los demás. |
| 2 | Selección ponderada | El algoritmo base: sencillo y fácil de implementar mal. |
| 3 | Tablas anidadas | Permiten reutilizar "loot de humanoide" en veinte enemigos. |
| 4 | Drops garantizados | La primera vez, la quest, el jefe: no todo es aleatorio. |
| 5 | Condiciones | Loot que depende de nivel, dificultad o progreso. |
| 6 | Determinismo y semilla | Reproducir un bug de loot es imposible sin esto. |
| 7 | Pity duro y blando | Corrige la cola larga de la distribución geométrica. |
| 8 | Valor esperado | Es la cifra que de verdad balancea la economía. |
| 9 | Varianza y percentiles | La media no describe la experiencia del jugador desafortunado. |
| 10 | Validación de tablas | Un id mal escrito en una tabla es un drop que nunca ocurre. |

## 📖 Definiciones y características

- **Loot table**: estructura de datos que describe qué puede caer y con qué probabilidad relativa. Clave: es contenido, no código.
- **Entrada (entry)**: cada línea de la tabla, con item o subtabla, peso y cantidad. Clave: puede apuntar a otra tabla, y ahí empieza la composición.
- **Peso (weight)**: número relativo que determina la probabilidad de una entrada frente a las demás. Clave: `p = peso / suma_de_pesos`, así que añadir entradas cambia el reparto.
- **Selección ponderada**: algoritmo que sortea un número en `[0, suma_pesos)` y avanza acumulando. Clave: coste lineal, suficiente para tablas de juego.
- **Tabla anidada**: entrada cuyo resultado es tirar otra tabla. Clave: las probabilidades se **multiplican** al bajar de nivel.
- **Drop garantizado**: entrada que siempre cae, al margen del sorteo. Clave: se resuelve antes o aparte de la tirada ponderada.
- **Tirada (roll)**: número de veces que se sortea en una misma tabla. Clave: `rolls: 3` no es lo mismo que triplicar los pesos.
- **Con reemplazo / sin reemplazo**: si una entrada ya elegida puede volver a salir. Clave: sin reemplazo evita "tres espadas iguales" en un cofre.
- **Probabilidad efectiva**: probabilidad real de obtener un item concreto tras componer todas las capas. Clave: es la única cifra útil para balancear.
- **Valor esperado (EV)**: media del valor obtenido por tirada. Clave: es lo que conecta el loot con la economía (clase 303).
- **Distribución geométrica**: la que describe "cuántos intentos hasta el primer éxito" con probabilidad constante. Clave: su cola es larguísima, y ahí viven los jugadores frustrados.
- **Pity duro (hard pity)**: garantía absoluta tras N intentos fallidos. Clave: acota el peor caso a un número que se puede comunicar.
- **Pity blando (soft pity)**: aumento progresivo de la probabilidad a partir de cierto intento. Clave: suaviza la cola sin hacer el resultado evidente.
- **Semilla (seed)**: valor inicial del generador que determina toda la secuencia. Clave: guardarla convierte un bug irreproducible en un test.
- **RNG por sistema**: instancia de generador propia de cada sistema. Clave: evita que añadir una partícula cambie el loot.
- **Cadena de suerte**: contador de fallos consecutivos usado por el pity. Clave: forma parte del guardado, o el pity se resetea al reiniciar.

## 🧰 Herramientas y preparación

Necesitas el catálogo (clase 294) y el inventario (clase 295). Trabajaremos en `res://dominio/loot/` y las tablas en `res://datos/loot.json`. Lee la documentación de [`RandomNumberGenerator`](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html): a diferencia de `randi()` global, permite tener un generador por sistema con su propia semilla, que es la base de todo lo determinista de esta clase.

## 🧪 Laboratorio guiado

1. **El formato de tabla.** Datos puros, con anidamiento y condiciones:

```json
{
  "version": 1,
  "tablas": {
    "humanoide_basico": {
      "rolls": 2,
      "garantizados": [{ "item": "moneda_oro", "min": 5, "max": 20 }],
      "entradas": [
        { "item": "pocion_menor", "peso": 50, "min": 1, "max": 2 },
        { "item": "espada_hierro", "peso": 10 },
        { "tabla": "raro_generico", "peso": 5 },
        { "nada": true, "peso": 35 }
      ]
    },
    "raro_generico": {
      "rolls": 1,
      "entradas": [
        { "item": "anillo_fuerza", "peso": 70 },
        { "item": "amuleto_vida", "peso": 25 },
        { "item": "hoja_legendaria", "peso": 5, "condicion": { "nivel_min": 20 } }
      ]
    }
  }
}
```

Fíjate en la entrada `{"nada": true, "peso": 35}`. Es la forma honesta de expresar "un 35 % de las veces no cae nada": si en vez de eso hicieras una tirada previa de "¿cae algo?", tendrías dos probabilidades que ajustar en dos sitios.

2. **La tabla en código.** Con el RNG **inyectado**, que es la decisión importante:

```gdscript
class_name TablasDeLoot
extends RefCounted

var _base: BaseDeItems
var _tablas := {}
var _rng: RandomNumberGenerator

func _init(base: BaseDeItems, rng: RandomNumberGenerator) -> void:
	_base = base
	_rng = rng          # inyectado: el mismo seed da siempre el mismo loot

func cargar(ruta: String) -> Array[String]:
	var datos = JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())
	if typeof(datos) != TYPE_DICTIONARY:
		return ["loot.json ilegible"]
	_tablas = datos.get("tablas", {})
	return []
```

3. **La selección ponderada.** Diez líneas, y el sitio donde más gente se equivoca:

```gdscript
func _elegir(entradas: Array, contexto: Dictionary) -> Dictionary:
	# Filtramos por condición ANTES de sumar: si no, los pesos de entradas
	# inaccesibles se "comen" probabilidad y nadie entiende los números.
	var validas := entradas.filter(func(e): return _cumple(e, contexto))
	var total := 0.0
	for e in validas:
		total += maxf(0.0, float(e.get("peso", 1)))
	if total <= 0.0:
		return {}
	var tirada := _rng.randf() * total
	var acumulado := 0.0
	for e in validas:
		acumulado += maxf(0.0, float(e.get("peso", 1)))
		if tirada < acumulado:
			return e
	return validas[-1]        # red de seguridad ante errores de coma flotante

func _cumple(e: Dictionary, contexto: Dictionary) -> bool:
	var c: Dictionary = e.get("condicion", {})
	if c.is_empty():
		return true
	if c.has("nivel_min") and int(contexto.get("nivel", 0)) < int(c["nivel_min"]):
		return false
	if c.has("dificultad") and str(contexto.get("dificultad", "")) != str(c["dificultad"]):
		return false
	if c.has("primera_vez") and not bool(contexto.get("primera_vez", false)):
		return false
	return true
```

4. **Tirar la tabla.** Con anidamiento, garantizados y protección contra ciclos:

```gdscript
func tirar(nombre: StringName, contexto: Dictionary = {}, profundidad := 0) -> Array[ItemStack]:
	var salida: Array[ItemStack] = []
	if profundidad > 8:
		push_error("tabla de loot con anidamiento excesivo o cíclico: %s" % nombre)
		return salida
	if not _tablas.has(nombre):
		push_error("tabla de loot desconocida: %s" % nombre)
		return salida

	var t: Dictionary = _tablas[nombre]

	# 1) Garantizados: no pasan por el sorteo.
	for g in t.get("garantizados", []):
		if _cumple(g, contexto):
			salida.append(ItemStack.new(StringName(str(g["item"])), _cantidad(g)))

	# 2) Tiradas ponderadas.
	for _i in int(t.get("rolls", 1)):
		var e := _elegir(t.get("entradas", []), contexto)
		if e.is_empty() or bool(e.get("nada", false)):
			continue
		if e.has("tabla"):
			salida.append_array(tirar(StringName(str(e["tabla"])), contexto, profundidad + 1))
		else:
			salida.append(ItemStack.new(StringName(str(e["item"])), _cantidad(e)))

	return _compactar(salida)

func _cantidad(e: Dictionary) -> int:
	var lo := int(e.get("min", 1))
	var hi := int(e.get("max", lo))
	return _rng.randi_range(mini(lo, hi), maxi(lo, hi))

func _compactar(items: Array[ItemStack]) -> Array[ItemStack]:
	# Tres tiradas de "5 monedas" deben llegar al inventario como una de 15.
	var por_id := {}
	for s in items:
		por_id[s.id] = por_id.get(s.id, 0) + s.cantidad
	var salida: Array[ItemStack] = []
	for id in por_id:
		salida.append(ItemStack.new(id, por_id[id]))
	return salida
```

5. **El sistema de piedad.** El estado que hace el loot humano. Y sí: **se guarda en el save**.

```gdscript
class_name Pity
extends RefCounted

var duro: int = 90              # a los 90 fallos, garantizado
var blando_desde: int = 75      # a partir de 75, la probabilidad sube
var incremento: float = 0.06    # +6 puntos por intento a partir de ahí
var base: float = 0.006         # 0,6 % por tirada

var fallos: int = 0             # ESTADO: va en el guardado

func probabilidad_actual() -> float:
	if fallos + 1 >= duro:
		return 1.0
	if fallos + 1 < blando_desde:
		return base
	return clampf(base + incremento * (fallos + 1 - blando_desde + 1), 0.0, 1.0)

func tirar(rng: RandomNumberGenerator) -> bool:
	var exito := rng.randf() < probabilidad_actual()
	fallos = 0 if exito else fallos + 1
	return exito

func a_dict() -> Dictionary: return {"fallos": fallos}
func de_dict(d: Dictionary) -> void: fallos = int(d.get("fallos", 0))
```

6. **Analizar lo que has construido.** Esta parte no es opcional: una tabla que no sabes calcular es una tabla que no puedes balancear.

```gdscript
extends SceneTree   # godot --headless --script res://herramientas/analizar_loot.gd

func _init() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 1
	var base := BaseDeItems.new(); base.cargar_desde_json("res://datos/items.json")
	var tablas := TablasDeLoot.new(base, rng); tablas.cargar("res://datos/loot.json")

	const N := 100000
	var cuenta := {}
	var valor_total := 0
	for i in N:
		for s in tablas.tirar(&"humanoide_basico", {"nivel": 25}):
			cuenta[s.id] = cuenta.get(s.id, 0) + s.cantidad
			valor_total += base.obtener(s.id).valor * s.cantidad

	print("== Análisis sobre %d tiradas ==" % N)
	for id in cuenta:
		printt(id, "media/tirada: %.4f" % (float(cuenta[id]) / N))
	print("Valor esperado por tirada: %.2f de oro" % (float(valor_total) / N))
	quit()
```

Con la tabla del paso 1, la `hoja_legendaria` tiene probabilidad efectiva `(5/100) × (5/100) = 0,25 %` **por roll**, y hay 2 rolls: `1 - (1 - 0.0025)² ≈ 0,50 %`. Si el simulador no te da esa cifra, uno de los dos está mal — y ese contraste es justo el objetivo del ejercicio.

7. **Validar las tablas.** Igual que el catálogo, en CI:

```gdscript
static func validar(tablas: Dictionary, base: BaseDeItems) -> Array[String]:
	var errores: Array[String] = []
	for nombre in tablas:
		var t: Dictionary = tablas[nombre]
		var entradas: Array = t.get("entradas", [])
		if entradas.is_empty() and t.get("garantizados", []).is_empty():
			errores.append("tabla '%s' vacía" % nombre)
		var suma := 0.0
		for e in entradas:
			suma += float(e.get("peso", 1))
			if float(e.get("peso", 1)) <= 0.0:
				errores.append("tabla '%s': peso <= 0" % nombre)
			if e.has("item") and not base.existe(StringName(str(e["item"]))):
				errores.append("tabla '%s': item inexistente '%s'" % [nombre, e["item"]])
			if e.has("tabla") and not tablas.has(str(e["tabla"])):
				errores.append("tabla '%s': subtabla inexistente '%s'" % [nombre, e["tabla"]])
			if int(e.get("min", 1)) > int(e.get("max", 1)):
				errores.append("tabla '%s': min > max" % nombre)
		if suma <= 0.0 and not entradas.is_empty():
			errores.append("tabla '%s': suma de pesos 0" % nombre)
	return errores
```

8. **Comprobar el determinismo.** El test más valioso de la clase:

```gdscript
var a := TablasDeLoot.new(base, _rng_con(777))
var b := TablasDeLoot.new(base, _rng_con(777))
a.cargar(RUTA); b.cargar(RUTA)
for i in 100:
	var x := a.tirar(&"humanoide_basico"); var y := b.tirar(&"humanoide_basico")
	assert(_igual(x, y), "el loot no es reproducible con la misma semilla")
```

## ✍️ Ejercicios

1. Implementa tiradas **sin reemplazo** para un cofre de jefe que no debe repetir item.
2. Añade `bonus_suerte` al contexto que multiplique los pesos de las entradas raras y comprueba el efecto en el simulador.
3. Implementa "primer drop garantizado": la primera vez que se mata a un jefe, cae seguro su item único.
4. Calcula analíticamente y verifica por simulación la probabilidad de no obtener un item del 1 % en 100 intentos (≈ 36,6 %).
5. Implementa pity blando y grafica la probabilidad acumulada frente a la geométrica pura.
6. Añade "loot personal" en multijugador: cada jugador tira su propia tabla con su semilla.
7. Escribe un informe automático que liste todos los items del catálogo que **ninguna** tabla puede soltar.

## 📝 Reto verificable

Implementa el sistema de loot completo con tablas ponderadas, anidamiento, garantizados, condiciones, cantidades variables, compactación, RNG inyectado y sistema de pity persistente, más un validador y un simulador.

**Criterio de aceptación**: (a) `godot --headless --script res://herramientas/analizar_loot.gd` imprime la media por item sobre 100.000 tiradas y el valor esperado; (b) la probabilidad efectiva medida de un item anidado coincide con la calculada a mano con un margen menor del 5 % relativo; (c) dos instancias con la misma semilla producen **exactamente** la misma secuencia de 100 tiradas; (d) el validador detecta peso 0, item inexistente, subtabla inexistente y `min > max`; (e) con pity duro a 90, una simulación de 10.000 secuencias demuestra que **ninguna** supera los 90 intentos sin éxito.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Al añadir un item nuevo bajan las probabilidades de todos | Es el comportamiento correcto de los pesos. Si quieres porcentajes fijos, normaliza y documenta el resto. |
| Un item raro no cae nunca | Su id está mal escrito, o su condición nunca se cumple. El validador lo detecta. |
| El loot cambia al añadir partículas al juego | Se usa el RNG global compartido. Un `RandomNumberGenerator` por sistema. |
| No se puede reproducir el bug de loot de un jugador | No se guarda la semilla. Guárdala en el save y en la telemetría. |
| Los jugadores se quejan de "mala suerte" con números correctos | La distribución geométrica es cruel en la cola. Añade pity y comunica el tope. |
| El cofre suelta tres veces el mismo item | Tiradas con reemplazo. Implementa sin reemplazo para cofres. |
| Un ciclo de tablas cuelga el juego | Falta el límite de profundidad. Añade `profundidad` y valida los ciclos en CI. |
| El drop garantizado también consume una tirada | Se metió en `entradas`. Debe resolverse aparte, en `garantizados`. |

## ❓ Preguntas frecuentes

**❓ ¿Pesos o porcentajes?** Pesos. Los porcentajes obligan a que todo sume 100 y a reajustar la tabla entera cada vez que añades una línea. Con pesos añades `{"item": "x", "peso": 3}` y ya está. Para comunicar al jugador, calcula el porcentaje efectivo y muéstralo.

**❓ ¿El pity no es engañar al jugador?** Al contrario: la aleatoriedad pura es la que engaña, porque la intuición humana espera que "1 %" signifique "una de cada cien" cuando en realidad un 37 % de la gente no lo verá en 100 intentos. Muchos juegos publican su pity precisamente porque es más honesto que la geométrica pura. Nota legal: en varios países la publicación de probabilidades de cajas de botín **es obligatoria**; consúltalo antes de monetizar (Parte 16).

**❓ ¿Por qué guardar el contador de pity?** Porque si no, reiniciar el juego lo resetea, y eso es a la vez injusto y explotable. Es estado del jugador, y va en el save con su migración ([clase 307](../307-save-system-de-produccion/README.md)).

**❓ ¿Loot en el servidor o en el cliente?** En cuanto haya multijugador o economía real, **siempre en el servidor**: si el cliente decide el loot, el cliente decide su propia riqueza. Es uno de los casos del modelo de amenazas de la [clase 318](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/318-threat-modeling-para-videojuegos/README.md).

**❓ ¿Cuántas tiradas necesito para validar una tabla?** Depende de la probabilidad más pequeña: para estimar un 0,25 % con un error relativo del 5 % hacen falta del orden de 10⁵–10⁶ muestras. Es barato: el simulador de arriba hace 100.000 tiradas en menos de un segundo.

## 🔗 Referencias

- Godot Docs — `RandomNumberGenerator`: <https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html>
- Godot Docs — Números aleatorios y semillas: <https://docs.godotengine.org/en/stable/tutorials/math/random_number_generation.html>
- GDC Vault — charlas sobre sistemas de recompensa, drop rates y psicología del loot: <https://www.gdcvault.com/>
- Wikipedia — Distribución geométrica (base matemática del "cuántos intentos hasta"): <https://en.wikipedia.org/wiki/Geometric_distribution>
- Robert Nystrom — *Game Programming Patterns*: <https://gameprogrammingpatterns.com/>

## ⬅️ Clase anterior

[Clase 299 - Arquitectura avanzada de combate y daño](../299-arquitectura-avanzada-de-combate-y-dano/README.md)

## ➡️ Siguiente clase

[Clase 301 - Crafting y recetas](../301-crafting-y-recetas/README.md)
