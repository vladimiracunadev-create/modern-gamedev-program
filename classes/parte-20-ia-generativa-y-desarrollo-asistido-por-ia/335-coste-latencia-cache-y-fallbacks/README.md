# Clase 335 — Coste, latencia, caché y fallbacks

> Parte: **20 — IA generativa y desarrollo de juegos asistido por IA** · Fuente: *Google, «Site Reliability Engineering» · Prácticas de control de coste en servicios de inferencia*
> ⏱️ Duración estimada: **115 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Hacer que un sistema con IA dentro del juego sea **económicamente viable y perceptualmente aceptable**. Son los dos problemas que hunden la mayoría de los proyectos con NPC conversacionales: la factura del primer mes y el jugador esperando dos segundos a que un aldeano conteste "buenos días".

Vas a implementar el control de coste (presupuestos por jugador y globales, con corte automático), la reducción de latencia (caché en varias capas, precálculo, ocultación), y la red de seguridad completa: **timeouts, colas, degradación y fallbacks escritos a mano**. La conclusión de la clase, que conviene adelantar: **la caché es la optimización más rentable con diferencia**, porque en un juego la mayoría de las interacciones se repiten mucho más de lo que parece.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Modelar el coste de una función de IA y proyectarlo a su base de jugadores.
2. Implementar presupuestos por jugador y global con corte automático.
3. Implementar caché por clave normalizada con varias capas y medir su tasa de acierto.
4. Reducir la latencia percibida con precálculo, streaming y ocultación.
5. Implementar timeouts, cola con prioridad y descarte con criterio.
6. Diseñar fallbacks por categoría que mantengan la experiencia.
7. Instrumentar y vigilar coste, latencia y tasa de acierto en producción.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Modelo de coste | Sin él, el precio se descubre en la factura. |
| 2 | Presupuesto por jugador | Acota el peor caso individual. |
| 3 | Presupuesto global | Acota el peor caso del negocio. |
| 4 | Caché por clave normalizada | La optimización de mayor retorno, con diferencia. |
| 5 | Capas de caché | Memoria, disco y compartida: distinta vida y alcance. |
| 6 | Tasa de acierto | La métrica que decide si el sistema es viable. |
| 7 | Latencia percibida | No es la real: se puede ocultar. |
| 8 | Timeout y cola | Sin ellos, una petición lenta arruina el turno. |
| 9 | Fallbacks | La red de seguridad, escrita a mano. |
| 10 | Vigilancia | Coste y latencia son métricas de producción. |

## 📖 Definiciones y características

- **Coste por token**: precio unitario de entrada y salida. Clave: la entrada suele ser mucho mayor que la salida y domina la factura.
- **Coste por interacción**: tokens totales de un turno por su precio. Clave: es la unidad con la que se razona.
- **Presupuesto por jugador**: tope de gasto por sesión o por día. Clave: acota el abuso y el bucle infinito.
- **Presupuesto global**: tope agregado con corte automático. Clave: protege el negocio de un pico inesperado.
- **Corte (circuit break) por coste**: desactivar la función al alcanzar el tope. Clave: degradar es preferible a una factura imprevista.
- **Caché**: reutilización de respuestas anteriores. Clave: reduce coste y latencia a la vez.
- **Clave de caché**: identificador derivado de la petición. Clave: su normalización determina la tasa de acierto.
- **Normalización**: reducir variantes equivalentes a la misma clave (minúsculas, sin acentos, sin puntuación). Clave: multiplica los aciertos.
- **Tasa de acierto (hit rate)**: proporción de peticiones servidas por caché. Clave: por encima del 60 % cambia la viabilidad del sistema.
- **Precálculo (warm cache)**: generar en desarrollo las respuestas más probables. Clave: convierte lo frecuente en instantáneo.
- **Latencia percibida**: la que el jugador nota. Clave: se reduce con diseño, no solo con velocidad.
- **Streaming**: mostrar la respuesta según llega. Clave: reduce mucho la percepción de espera.
- **Timeout**: tiempo máximo antes de rendirse. Clave: en un turno de diálogo, entre 2 y 4 segundos.
- **Cola con prioridad**: ordenar peticiones por importancia. Clave: la conversación activa va antes que la ambiental.
- **Descarte (drop)**: cancelar peticiones que ya no importan. Clave: el jugador se fue; la respuesta ya no sirve.
- **Fallback**: contenido fijo que sustituye a la generación. Clave: escrito a mano, siempre disponible.

## 🧰 Herramientas y preparación

Godot 4.x, el `ServicioIA` de la [clase 334](../334-proveedores-locales-y-remotos/README.md) y las métricas de la [clase 316](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/316-observabilidad-de-juegos/README.md). Trabajaremos en `res://ia/coste/` y `res://ia/cache/`. Todo se puede medir y probar con el `MockProvider` simulando latencia y tokens, sin ningún proveedor real.

## 🧪 Laboratorio guiado

1. **El modelo de coste.** Hazlo antes de escribir la función, no después:

```gdscript
class_name ModeloCoste
extends RefCounted

# Los números concretos cambian con el proveedor; la ESTRUCTURA del cálculo, no.
var precio_entrada_1k := 0.0005
var precio_salida_1k := 0.0015

func coste_turno(tokens_entrada: int, tokens_salida: int) -> float:
	return (tokens_entrada / 1000.0) * precio_entrada_1k \
		 + (tokens_salida / 1000.0) * precio_salida_1k

func proyeccion(turnos_por_sesion: int, tokens_entrada: int, tokens_salida: int,
				sesiones_mes: int, tasa_acierto_cache: float) -> Dictionary:
	var por_turno := coste_turno(tokens_entrada, tokens_salida)
	var efectivos := turnos_por_sesion * (1.0 - tasa_acierto_cache)
	return {
		"coste_turno": por_turno,
		"coste_sesion": por_turno * efectivos,
		"coste_mes": por_turno * efectivos * sesiones_mes,
		"turnos_facturados_mes": int(efectivos * sesiones_mes),
	}
```

```text
Ejemplo: NPC conversacional
  1.400 tokens de entrada (identidad + lore + memoria + estado)
    150 tokens de salida
  30 turnos por sesión · 100.000 sesiones al mes

Sin caché:      30 × (1.400 × 0.0005/1k + 150 × 0.0015/1k) = 0,0276 €/sesión
                × 100.000 = 2.760 €/mes
Con 65 % de acierto de caché: 966 €/mes
Con 65 % + contexto reducido a 800 tokens: 620 €/mes
```

La lección está en las tres líneas: **la caché y el tamaño del contexto son las dos palancas**, y ambas están enteramente en tu mano. Cambiar de modelo es la tercera, y suele ser la que peor relación calidad/ahorro tiene.

2. **Los presupuestos.** Por jugador y global, con corte:

```gdscript
class_name PresupuestoIA
extends RefCounted

signal jugador_agotado(jugador: StringName, gastado: float)
signal global_agotado(gastado: float, tope: float)
signal umbral_alcanzado(porcentaje: float)

var tope_jugador_dia := 0.05          # €/jugador/día
var tope_global_dia := 200.0          # €/día para todo el juego
var _por_jugador := {}
var _global := 0.0
var _dia := 0
var _avisado := {}

func puede_gastar(jugador: StringName, estimado: float, hoy: int) -> bool:
	_rotar_si_cambia_el_dia(hoy)
	if _global + estimado > tope_global_dia:
		global_agotado.emit(_global, tope_global_dia)
		return false
	if float(_por_jugador.get(jugador, 0.0)) + estimado > tope_jugador_dia:
		jugador_agotado.emit(jugador, float(_por_jugador.get(jugador, 0.0)))
		return false
	return true

func registrar(jugador: StringName, coste: float) -> void:
	_por_jugador[jugador] = float(_por_jugador.get(jugador, 0.0)) + coste
	_global += coste
	# Avisos al 50, 75 y 90 %: enterarse al 100 % es enterarse tarde.
	for u in [0.5, 0.75, 0.9]:
		if _global / tope_global_dia >= u and not _avisado.has(u):
			_avisado[u] = true
			umbral_alcanzado.emit(u)
			Log.warn("presupuesto_ia", {"porcentaje": u * 100.0, "gastado": _global})
```

Cuando el presupuesto se agota, **la función degrada; el juego no**: el NPC pasa a su diálogo escrito y el jugador no ve un error, ve un NPC normal.

3. **La caché.** La optimización con más retorno, y depende casi toda de la clave:

```gdscript
class_name CacheIA
extends RefCounted

# La NORMALIZACIÓN es lo que decide la tasa de acierto. "¿Dónde está la mina?",
# "donde esta la mina" y "¿Dónde está la mina?  " deben dar la misma clave: son
# la misma pregunta y no tiene sentido pagarla tres veces.
static func clave(npc_id: StringName, pregunta: String, estado: Dictionary) -> String:
	var p := pregunta.to_lower().strip_edges()
	p = _sin_acentos(p)
	p = p.replace("¿", "").replace("?", "").replace("¡", "").replace("!", "")
	p = p.replace(",", "").replace(".", "")
	while p.contains("  "):
		p = p.replace("  ", " ")

	# El estado que CAMBIA la respuesta forma parte de la clave; el que no,
	# se deja fuera. Meter la posición exacta del jugador aquí destruiría la
	# caché sin mejorar ninguna respuesta.
	var relevante := "%s|%s|%s" % [
		estado.get("reputacion_umbral", "neutral"),
		str(estado.get("quests_activas", [])),
		estado.get("lugar", ""),
	]
	return "%s|%s|%s" % [npc_id, p.sha256_text().substr(0, 16), relevante.sha256_text().substr(0, 8)]
```

```gdscript
var _memoria := {}                 # clave -> {texto, usos, momento}
var _disco_dir := "user://cache_ia"
var _precalculada := {}            # cargada de res://, generada en desarrollo

var aciertos := 0
var fallos := 0

func obtener(clave: String) -> String:
	# Capa 1: precalculada (viene con el juego, no caduca).
	if _precalculada.has(clave):
		aciertos += 1
		return str(_precalculada[clave])
	# Capa 2: memoria de la sesión.
	if _memoria.has(clave):
		aciertos += 1
		_memoria[clave]["usos"] += 1
		return str(_memoria[clave]["texto"])
	# Capa 3: disco (sobrevive entre sesiones).
	var ruta := _disco_dir.path_join(clave.substr(0, 32) + ".txt")
	if FileAccess.file_exists(ruta):
		var t := FileAccess.open(ruta, FileAccess.READ).get_as_text()
		_memoria[clave] = {"texto": t, "usos": 1, "momento": _ahora}
		aciertos += 1
		return t
	fallos += 1
	return ""

func tasa_acierto() -> float:
	var total := aciertos + fallos
	return float(aciertos) / maxf(total, 1)
```

4. **El precálculo.** Convertir lo frecuente en instantáneo:

```gdscript
extends SceneTree   # herramientas/precalcular_cache.gd

# Las preguntas más frecuentes de un juego son sorprendentemente pocas. Se
# generan UNA vez en desarrollo, se revisan y se envían con el juego: coste
# cero en producción y latencia de milisegundos.
const FRECUENTES := [
	"hola", "adios", "quien eres", "que vendes", "que haces aqui",
	"hablame del pueblo", "hablame de la mina", "necesitas ayuda",
	"donde estoy", "que ha pasado aqui", "conoces a alguien que pueda ayudarme",
]

func _init() -> void:
	var generadas := 0
	var salida := {}
	for npc in _todos_los_npcs():
		for estado in _estados_representativos():      # 3-4 combinaciones típicas
			for p in FRECUENTES:
				var clave := CacheIA.clave(npc["id"], p, estado)
				var r := await _ia.completar(_peticion(npc, p, estado))
				if r.ok and _validador.validar(r.texto, npc, estado).ok():
					salida[clave] = r.texto
					generadas += 1

	FileAccess.open("res://datos/ia/cache_precalculada.json", FileAccess.WRITE) \
		.store_string(JSON.stringify(salida, "\t"))
	print("== %d respuestas precalculadas para %d NPC ==" % [generadas, _todos_los_npcs().size()])
	print("   revísalas antes de publicar: van dentro del juego")
	quit()
```

5. **La latencia percibida.** No es la real, y se puede trabajar:

| Técnica | Reducción percibida | Coste de implementación |
|---|---|---|
| Caché | 100 % (es instantáneo) | Bajo |
| Streaming (mostrar según llega) | 60–80 % | Medio |
| Animación de "pensando" del NPC | 30–50 % | Bajo |
| Respuesta corta inmediata + desarrollo | 50 % | Medio |
| Precarga al acercarse al NPC | 100 % si acierta | Medio |
| Modelo más pequeño | 40–60 % (y menos calidad) | Bajo |

```gdscript
func hablar_con_npc(texto: String) -> void:
	# 1) Caché: instantáneo, sin espera de ningún tipo.
	var clave := CacheIA.clave(_npc.id, texto, _estado)
	var cacheado := _cache.obtener(clave)
	if cacheado != "":
		_mostrar(cacheado)
		return

	# 2) Ocultar la espera con algo que el NPC haría de todas formas.
	_npc.animacion("pensando")
	_ui.mostrar_puntos_suspensivos()

	# 3) Pedir con timeout. Si tarda demasiado, el NPC dice algo escrito y
	#    la conversación sigue: es infinitamente mejor que un silencio de 4 s.
	var r := await _ia.completar_con_timeout(_peticion(texto), 3.0)
	_ui.ocultar_puntos_suspensivos()

	if not r.ok:
		_mostrar(Fallbacks.para(_npc, r.motivo, _rng))
		return
	_cache.guardar(clave, r.texto)
	_mostrar(r.texto)
```

6. **La cola con prioridad.** No todas las peticiones valen lo mismo:

```gdscript
class_name ColaIA
extends RefCounted

enum Prioridad { CONVERSACION = 0, REACCION = 1, AMBIENTAL = 2 }

const MAX_CONCURRENTES := 2
const MAX_EN_COLA := 8

var _cola: Array[Dictionary] = []
var _en_vuelo := 0

func encolar(p: AIProvider.PeticionIA, prioridad: Prioridad,
			 cancelable: bool = true) -> void:
	if _cola.size() >= MAX_EN_COLA:
		# La cola llena se poda por lo MENOS importante, no por lo más antiguo:
		# descartar la charla ambiental de un aldeano es gratis.
		_cola.sort_custom(func(a, b): return int(a["prio"]) < int(b["prio"]))
		var ultimo: Dictionary = _cola[-1]
		if int(ultimo["prio"]) > int(prioridad):
			_cola.pop_back()
			Log.info("ia_peticion_descartada", {"prioridad": ultimo["prio"]})
		else:
			return                     # lo nuevo es aún menos importante: no entra
	_cola.append({"p": p, "prio": prioridad, "cancelable": cancelable,
				  "encolada_en": _ahora})
	_procesar()

func cancelar_de(npc_id: StringName) -> int:
	# El jugador se alejó: sus peticiones ya no sirven a nadie. Cancelarlas
	# ahorra dinero y libera hueco para las que sí importan.
	var antes := _cola.size()
	_cola = _cola.filter(func(x):
		return not (bool(x["cancelable"]) and str(x["p"].etiqueta).begins_with(String(npc_id))))
	return antes - _cola.size()
```

7. **Los fallbacks.** Escritos a mano, por categoría, y con la razón de cada uno:

```gdscript
class_name FallbacksIA
extends RefCounted

# Un fallback bien escrito es indistinguible de contenido normal. Uno mal
# escrito ("Error: no se pudo generar la respuesta") rompe la inmersión más
# que no tener IA en absoluto.
const CATEGORIAS := {
	"timeout":     "El NPC está ocupado un momento",
	"sin_red":     "El NPC no reacciona a lo específico",
	"presupuesto": "El NPC responde con su diálogo habitual",
	"rechazado":   "El NPC cambia de tema",
	"sin_ia":      "Modo normal del juego: diálogo escrito",
}

static func elegir(npc: Dictionary, categoria: String, rng: RandomNumberGenerator) -> String:
	var opciones: Array = npc.get("fallbacks", {}).get(categoria, [])
	if opciones.is_empty():
		opciones = npc.get("fallbacks", {}).get("generico", ["..."])
	return str(opciones[rng.randi() % opciones.size()])
```

8. **La vigilancia.** Coste y latencia son métricas de producción:

```gdscript
func _registrar(r: AIProvider.RespuestaIA, clave: String, cacheado: bool) -> void:
	_metricas.incrementar("ia_peticiones", {"proveedor": r.proveedor,
											"cacheado": str(cacheado)})
	if not cacheado:
		_metricas.observar("ia_latencia_ms", r.latencia_ms, {"proveedor": r.proveedor})
		var coste := _modelo.coste_turno(r.tokens_entrada, r.tokens_salida)
		_metricas.observar("ia_coste_turno", coste * 1000.0)   # en milésimas
		_presupuesto.registrar(_jugador, coste)
	_metricas.fijar("ia_tasa_acierto_cache", _cache.tasa_acierto())
```

| Alerta | Umbral | Por qué |
|---|---|---|
| Coste diario | > 80 % del presupuesto | Antes del corte, no después |
| Tasa de acierto de caché | < 40 % | La normalización de clave se ha roto |
| p95 de latencia | > 3 s | La experiencia se está degradando |
| Tasa de fallback | > 20 % | Algo falla: proveedor, validación o presupuesto |
| Peticiones canceladas | > 30 % | Se está pidiendo demasiado pronto |

9. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	# Normalización: variantes equivalentes comparten clave.
	var e := {"reputacion_umbral": "neutral", "lugar": "villarroca", "quests_activas": []}
	check.call(CacheIA.clave(&"bram", "¿Dónde está la mina?", e)
			== CacheIA.clave(&"bram", "donde esta la mina", e),
		"la normalización unifica variantes")
	check.call(CacheIA.clave(&"bram", "hola", e) != CacheIA.clave(&"otro", "hola", e),
		"NPC distintos no comparten caché")

	# El estado relevante SÍ cambia la clave.
	var e2 := e.duplicate(); e2["reputacion_umbral"] = "aliado"
	check.call(CacheIA.clave(&"bram", "hola", e) != CacheIA.clave(&"bram", "hola", e2),
		"un estado que cambia la respuesta cambia la clave")

	# Acierto de caché: la segunda vez no llama al proveedor.
	var mock := MockProvider.new(1)
	var svc := ServicioIACacheado.nuevo(mock)
	await svc.preguntar(&"bram", "hola", e)
	var llamadas := mock.llamadas
	await svc.preguntar(&"bram", "Hola.", e)
	check.call(mock.llamadas == llamadas, "la segunda pregunta equivalente sale de caché")

	# Presupuesto: al agotarse, degrada y no llama.
	var pres := PresupuestoIA.new(); pres.tope_jugador_dia = 0.0001
	svc.presupuesto = pres
	var antes := mock.llamadas
	var r := await svc.preguntar(&"bram", "pregunta nueva y distinta", e)
	check.call(mock.llamadas == antes, "sin presupuesto no se llama al proveedor")
	check.call(r != "", "sin presupuesto hay fallback")

	# Timeout: no se espera indefinidamente.
	mock.latencia_simulada_ms = 10000.0
	var t0 := Time.get_ticks_msec()
	await svc.preguntar(&"bram", "otra pregunta", e)
	check.call(Time.get_ticks_msec() - t0 < 4000, "el timeout corta la espera")

	# Cola: se descarta lo ambiental antes que lo importante.
	var cola := ColaIA.new()
	for i in 20:
		cola.encolar(_p("amb_%d" % i), ColaIA.Prioridad.AMBIENTAL)
	cola.encolar(_p("conversacion"), ColaIA.Prioridad.CONVERSACION)
	check.call(cola.contiene("conversacion"), "la conversación no se descarta")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

## ✍️ Ejercicios

1. Calcula el coste mensual de tu función de IA con tres tasas de acierto de caché distintas.
2. Implementa la normalización de clave y mide la tasa de acierto sobre 200 preguntas reales.
3. Precalcula las 15 preguntas más frecuentes de tres NPC y mide el impacto.
4. Implementa streaming y compara la percepción de espera con y sin él.
5. Añade precarga al acercarse a un NPC y mide cuántas peticiones se desperdician.
6. Escribe los fallbacks de las cinco categorías para un NPC, en su voz.
7. Define las alertas de coste y latencia de tu juego con sus umbrales.

## 📝 Reto verificable

Implementa el control completo: modelo de coste con proyección, presupuestos por jugador y global con corte y avisos, caché de tres capas con normalización y métricas, precálculo en desarrollo, timeout, cola con prioridad y cancelación, fallbacks por categoría e instrumentación.

**Criterio de aceptación**: una prueba headless con **al menos 18 aserciones** demuestra que: (a) preguntas equivalentes con distinta puntuación, acentos y mayúsculas comparten clave de caché; (b) NPC distintos y estados que cambian la respuesta **no** la comparten; (c) la segunda petición equivalente no llama al proveedor, comprobable con el contador del mock; (d) al agotarse el presupuesto del jugador no se llama al proveedor y se devuelve un fallback; (e) el presupuesto global emite avisos al 50, 75 y 90 %; (f) una petición que supera el timeout se corta y devuelve fallback en menos del tiempo límite más un margen; (g) con la cola llena, se descartan primero las peticiones de menor prioridad y **nunca** la conversación activa; (h) sobre un lote de 200 preguntas con repetición realista, la tasa de acierto de caché supera el 50 %.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La factura del primer mes triplica lo previsto | No se modeló el coste ni hubo presupuesto. Ambas cosas, antes de publicar. |
| La caché casi nunca acierta | Clave sin normalizar o con estado irrelevante dentro. Revisa qué entra en la clave. |
| La caché devuelve respuestas incoherentes con el estado | Falta estado relevante en la clave. Añade lo que **cambia** la respuesta. |
| El jugador espera 3 s mirando a un NPC quieto | Latencia sin ocultar. Animación, streaming y timeout. |
| Un jugador agota el presupuesto de todos | Sin tope por jugador. Añádelo. |
| El juego se queda colgado si el proveedor tarda | Sin timeout. Siempre timeout, y corto. |
| Se pagan respuestas que nadie va a leer | No se cancelan las peticiones obsoletas. Cancela al alejarse. |
| El fallback dice "Error de conexión" | Fallback técnico en vez de narrativo. Escríbelos en la voz del personaje. |
| El presupuesto salta al 100 % sin previo aviso | Sin avisos intermedios. 50, 75 y 90 %. |

## ❓ Preguntas frecuentes

**❓ ¿De verdad la caché acierta tanto en un juego?** Sí, y más de lo que sugiere la intuición: los jugadores hacen las mismas preguntas ("¿quién eres?", "¿qué vendes?", "¿dónde está X?"), los NPC secundarios reciben pocas preguntas distintas, y el estado relevante toma pocos valores. Con normalización decente, tasas del 60-75 % son habituales. Y cada acierto es coste cero **y** latencia cero.

**❓ ¿Qué timeout pongo?** Para diálogo por turnos, 2-4 segundos. Para charla ambiental, 1 segundo (si tarda más, no merece la pena: el jugador ya se fue). El criterio no es cuánto tarda el proveedor, es cuánto está dispuesto a esperar el jugador **en esa situación**.

**❓ ¿Cómo estimo el coste antes de tener jugadores?** Con la proyección del paso 1 y tres escenarios: pesimista (sin caché, sesiones largas), esperado (caché al 60 %) y optimista. Si el escenario **pesimista** te arruina, no publiques esa función tal cual: reduce el contexto, precalcula más o mueve la generación a desarrollo.

**❓ ¿Y si el presupuesto se agota a media partida?** El NPC pasa a su diálogo escrito y el jugador no ve nada raro. Eso es lo que hace aceptable el corte: **la IA es una mejora**, y quitarla devuelve al juego a su estado normal, no a un estado roto. Si quitarla rompe el juego, el diseño tiene un problema anterior a esta clase.

**❓ ¿Precalcular no elimina la gracia de la IA?** Elimina la variedad en lo repetitivo, que es justo donde no aporta: la respuesta número 4.000 a "hola" no gana nada por ser distinta. La variedad importa en lo específico e imprevisto, y ahí la caché no acierta y la generación hace su trabajo.

## 🔗 Referencias

- Google — *Site Reliability Engineering*, gestión de sobrecarga y degradación: <https://sre.google/books/>
- Godot Docs — `String.sha256_text` (claves de caché): <https://docs.godotengine.org/en/stable/classes/class_string.html>
- Godot Docs — `FileAccess` (caché en disco): <https://docs.godotengine.org/en/stable/classes/class_fileaccess.html>
- Godot Docs — Señales y `await` (timeouts y asincronía): <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html>
- OpenTelemetry — instrumentación de coste y latencia: <https://opentelemetry.io/docs/>

## ⬅️ Clase anterior

[Clase 334 - Proveedores locales y remotos](../334-proveedores-locales-y-remotos/README.md)

## ➡️ Siguiente clase

[Clase 336 - Seguridad y moderación de IA dentro del juego](../336-seguridad-y-moderacion-de-ia-dentro-del-juego/README.md)
