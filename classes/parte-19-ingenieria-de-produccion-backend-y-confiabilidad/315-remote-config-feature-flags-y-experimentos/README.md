# Clase 315 — Remote Config, feature flags y experimentos

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *Google, «Site Reliability Engineering» · Literatura sobre continuous delivery y experimentación controlada*
> ⏱️ Duración estimada: **115 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Separar **desplegar** de **activar**. Hoy, cambiar un número de balance en tu juego significa publicar una build, esperar la revisión de la tienda y que los jugadores actualicen: días. Con configuración remota y feature flags, significa cambiar un valor y que surta efecto en la siguiente sesión: minutos. Y si algo sale mal, apagarlo es igual de rápido.

Vas a implementar un sistema de configuración remota con **valores por defecto compilados** (para que el juego funcione perfectamente sin red), validación de lo que llega, feature flags con despliegue gradual por porcentaje, **kill switches** para apagar una función en caliente, y asignación determinista a grupos de experimento. La regla que gobierna todo: **el servicio remoto es una mejora, nunca un requisito**. Si falla, el juego funciona igual.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Distinguir configuración, feature flag, kill switch y experimento, y usar cada uno para lo suyo.
2. Implementar valores por defecto compilados y una jerarquía de precedencia clara.
3. Validar la configuración remota y rechazar valores fuera de rango sin romper el juego.
4. Implementar despliegue gradual por porcentaje con asignación **determinista y estable**.
5. Implementar kill switches con efecto inmediato y comportamiento seguro por defecto.
6. Diseñar un experimento A/B con asignación consistente y métricas asociadas.
7. Explicar los límites éticos y legales de experimentar con jugadores.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Desplegar vs activar | Es la idea que cambia la velocidad de todo el equipo. |
| 2 | Valores por defecto | Sin ellos, el juego depende de la red para arrancar. |
| 3 | Precedencia | Defecto < remoto < local de depuración: y en ese orden. |
| 4 | Validación de config | Un valor remoto malo puede ser peor que ninguno. |
| 5 | Feature flag | Activar código ya desplegado, para una parte de los jugadores. |
| 6 | Rollout gradual | 1 % → 10 % → 50 % → 100 %, con métricas entre paso y paso. |
| 7 | Asignación determinista | El mismo jugador debe caer siempre en el mismo grupo. |
| 8 | Kill switch | La herramienta de emergencia; ha de ser trivial y fiable. |
| 9 | Experimentos A/B | Comparar variantes con rigor, no con impresiones. |
| 10 | Ética y ley | Experimentar con personas tiene límites. |

## 📖 Definiciones y características

- **Remote config**: valores de configuración servidos desde el backend. Clave: cambia el comportamiento sin publicar build.
- **Valor por defecto compilado**: el que trae el binario. Clave: es el que garantiza que el juego funcione sin red.
- **Precedencia**: orden en que se resuelven las fuentes de un valor. Clave: debe ser explícita y estar documentada.
- **Feature flag**: interruptor que activa o desactiva una funcionalidad ya presente en el código. Clave: separa el despliegue de la activación.
- **Flag permanente vs temporal**: el que se queda (modo accesibilidad) frente al que debe eliminarse tras el rollout. Clave: los temporales no eliminados son deuda técnica que se acumula rápido.
- **Rollout gradual (staged rollout)**: activación progresiva por porcentaje de jugadores. Clave: limita el daño de un fallo al porcentaje activado.
- **Asignación determinista**: cálculo del grupo a partir de un hash del id del jugador. Clave: sin ella, un jugador cambia de grupo en cada sesión y todo se invalida.
- **Bucket**: número de 0 a 99 derivado del hash, que decide el grupo. Clave: estable mientras no cambie la sal.
- **Sal (salt)**: cadena que se mezcla en el hash, distinta por flag. Clave: evita que los mismos jugadores caigan siempre en el mismo lado de todos los experimentos.
- **Kill switch**: flag cuya función es apagar algo en emergencia. Clave: su valor seguro es "apagado" y debe consultarse en caliente.
- **Experimento A/B**: comparación entre dos variantes con asignación aleatoria y métrica objetivo. Clave: sin métrica definida de antemano, no es un experimento.
- **Grupo de control**: el que recibe el comportamiento actual. Clave: es la referencia contra la que se mide.
- **Métrica objetivo**: la que decide el resultado del experimento. Clave: se define antes de mirar los datos.
- **Configuración segura por defecto**: comportamiento elegido cuando falta o falla el valor. Clave: siempre el conservador.
- **Esquema de configuración**: definición de claves, tipos y rangos válidos. Clave: convierte un error de operación en un rechazo controlado.
- **Sobrescritura local (override)**: valor forzado en desarrollo o QA. Clave: imprescindible para probar, peligroso si llega a producción.

## 🧰 Herramientas y preparación

Necesitas el `MockBackend` de la [clase 311](../311-arquitectura-backend-para-videojuegos/README.md). Trabajaremos en `res://infraestructura/config/`. No hace falta ningún servicio: el laboratorio sirve la configuración desde un JSON local que simula la respuesta remota, que es exactamente lo que la CI usará. Documentación útil de fondo: [Martin Fowler sobre feature toggles](https://martinfowler.com/articles/feature-toggles.html).

## 🧪 Laboratorio guiado

1. **El esquema.** Antes que los valores, sus reglas — porque un valor remoto malo puede hacer más daño que la falta de valor:

```gdscript
class_name EsquemaConfig
extends RefCounted

# clave -> {tipo, defecto, min, max, opciones}
const ESQUEMA := {
	"dano_base_jugador":   {"tipo": TYPE_FLOAT, "defecto": 10.0, "min": 1.0, "max": 100.0},
	"multiplicador_xp":    {"tipo": TYPE_FLOAT, "defecto": 1.0,  "min": 0.1, "max": 10.0},
	"precio_pocion":       {"tipo": TYPE_INT,   "defecto": 15,   "min": 1,   "max": 10000},
	"intervalo_autosave":  {"tipo": TYPE_FLOAT, "defecto": 120.0,"min": 30.0,"max": 900.0},
	"url_noticias":        {"tipo": TYPE_STRING,"defecto": ""},
	"dificultad_por_defecto": {"tipo": TYPE_STRING, "defecto": "normal",
							   "opciones": ["facil", "normal", "dificil"]},
}

static func validar(clave: String, valor: Variant) -> bool:
	if not ESQUEMA.has(clave):
		return false                     # clave desconocida: se ignora, no se adopta
	var d: Dictionary = ESQUEMA[clave]
	if typeof(valor) != int(d["tipo"]):
		# JSON no distingue int de float: aceptamos el caso compatible.
		if not (int(d["tipo"]) == TYPE_FLOAT and typeof(valor) == TYPE_INT):
			return false
	if d.has("min") and float(valor) < float(d["min"]):
		return false
	if d.has("max") and float(valor) > float(d["max"]):
		return false
	if d.has("opciones") and not (d["opciones"] as Array).has(valor):
		return false
	return true
```

2. **El servicio de configuración.** Precedencia explícita y a la vista:

```gdscript
class_name Config
extends RefCounted

signal actualizada(claves: Array)
signal rechazada(clave: String, valor: Variant, motivo: String)

# PRECEDENCIA (de menor a mayor):
#   1. defecto compilado   ← siempre existe, el juego funciona solo con esto
#   2. remoto              ← lo que sirve el backend, ya validado
#   3. override local      ← solo en builds de desarrollo
var _remoto := {}
var _override := {}
var _permite_override := OS.is_debug_build()

func get_valor(clave: String) -> Variant:
	if _permite_override and _override.has(clave):
		return _override[clave]
	if _remoto.has(clave):
		return _remoto[clave]
	return EsquemaConfig.ESQUEMA.get(clave, {}).get("defecto", null)

func get_float(clave: String) -> float: return float(get_valor(clave))
func get_int(clave: String) -> int:     return int(get_valor(clave))
func get_str(clave: String) -> String:  return str(get_valor(clave))

func aplicar_remoto(payload: Dictionary) -> Array:
	var aplicadas := []
	for clave in payload.get("valores", {}):
		var v = payload["valores"][clave]
		if not EsquemaConfig.validar(clave, v):
			# NO se adopta: se registra y se sigue con el defecto. Un valor malo
			# en producción no puede tumbar el juego de nadie.
			rechazada.emit(clave, v, "no cumple el esquema")
			continue
		_remoto[clave] = v
		aplicadas.append(clave)
	if not aplicadas.is_empty():
		actualizada.emit(aplicadas)
	return aplicadas

func forzar(clave: String, valor: Variant) -> bool:
	if not _permite_override:
		return false                     # en release, ni existe
	if not EsquemaConfig.validar(clave, valor):
		return false
	_override[clave] = valor
	return true
```

3. **Los flags con rollout y asignación determinista.** El hash es la pieza clave:

```gdscript
class_name Flags
extends RefCounted

var _defs := {}                # nombre -> {activo, porcentaje, sal, kill}
var _jugador: StringName = &""

func configurar(jugador: StringName, payload: Dictionary) -> void:
	_jugador = jugador
	for nombre in payload.get("flags", {}):
		var d: Dictionary = payload["flags"][nombre]
		_defs[nombre] = {
			"activo": bool(d.get("activo", false)),
			"porcentaje": clampi(int(d.get("porcentaje", 0)), 0, 100),
			"sal": str(d.get("sal", nombre)),
			"kill": bool(d.get("kill", false)),
		}

func activo(nombre: String) -> bool:
	var d: Dictionary = _defs.get(nombre, {})
	if d.is_empty():
		return false                     # flag desconocido: SIEMPRE apagado
	if bool(d["kill"]):
		return false                     # el kill switch gana a todo lo demás
	if not bool(d["activo"]):
		return false
	if int(d["porcentaje"]) >= 100:
		return true
	return _bucket(str(d["sal"])) < int(d["porcentaje"])

func _bucket(sal: String) -> int:
	# Determinista y estable: el mismo jugador cae siempre en el mismo bucket
	# para el mismo flag. Y la SAL por flag evita que los mismos desafortunados
	# entren en todos los experimentos a la vez.
	var texto := "%s|%s" % [sal, _jugador]
	var h := texto.sha256_buffer()
	return (int(h[0]) << 8 | int(h[1])) % 100
```

4. **El kill switch.** Simple a propósito: cuando hace falta, no es momento de sutilezas.

```gdscript
# En el punto de uso, la comprobación es una línea y el fallo es seguro.
func abrir_tienda() -> void:
	if not flags.activo("tienda_online"):
		mostrar_aviso("La tienda no está disponible ahora mismo.")
		return
	_abrir_tienda_real()
```

Tres reglas de un kill switch que funciona:

1. **El valor seguro es apagado.** Si no se sabe, no se hace.
2. **Se consulta en el punto de uso**, no al arrancar: apagarlo debe tener efecto sin reiniciar.
3. **No depende del mismo servicio que apaga.** Si la tienda está caída porque el backend está caído, el flag tiene que venir de una ruta distinta (o su defecto tiene que ser el correcto).

5. **Los experimentos.** Igual que los flags, pero con más de dos ramas y con métrica:

```gdscript
class_name Experimentos
extends RefCounted

signal expuesto(experimento: String, variante: String)

var _defs := {}                # nombre -> {variantes: [{nombre, peso}], sal, activo}
var _jugador: StringName = &""
var _cache := {}               # nombre -> variante asignada (estable en la sesión)

func variante(nombre: String) -> String:
	if _cache.has(nombre):
		return _cache[nombre]
	var d: Dictionary = _defs.get(nombre, {})
	if d.is_empty() or not bool(d.get("activo", false)):
		return "control"
	var total := 0
	for v in d["variantes"]:
		total += int(v["peso"])
	var b := _bucket(str(d.get("sal", nombre)), total)
	var acumulado := 0
	for v in d["variantes"]:
		acumulado += int(v["peso"])
		if b < acumulado:
			_cache[nombre] = str(v["nombre"])
			# La EXPOSICIÓN se registra: solo cuentan los jugadores que de
			# verdad han visto la variante, no los que estaban asignados.
			expuesto.emit(nombre, _cache[nombre])
			return _cache[nombre]
	return "control"

func _bucket(sal: String, modulo: int) -> int:
	var h := ("%s|%s" % [sal, _jugador]).sha256_buffer()
	return (int(h[0]) << 8 | int(h[1])) % maxi(1, modulo)
```

6. **El ciclo de vida de un rollout.** El procedimiento, no la teoría:

```text
1. Desplegar el código con el flag APAGADO           → nadie lo ve
2. Activar al 1 %                                    → observar errores y métricas
3. 10 % durante 24 h                                 → comparar con el control
4. 50 %                                              → confirmar que escala
5. 100 %                                             → todos
6. ELIMINAR el flag y el código antiguo              → este paso es el que se olvida
```

El paso 6 no es opcional. Un juego con 80 flags temporales que nadie retiró tiene 2⁸⁰ combinaciones posibles de comportamiento y ninguna está probada.

7. **La conexión con la telemetría.** Un experimento sin métrica es una corazonada cara:

```gdscript
func _ready() -> void:
	# Cada evento de telemetría lleva las variantes activas: sin eso, no se
	# puede atribuir ningún efecto a ninguna variante.
	experimentos.expuesto.connect(func(exp, v):
		telemetria.registrar("experimento_expuesto", {"experimento": exp, "variante": v}))
	telemetria.contexto_global["variantes"] = experimentos.activas()
```

8. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	var cfg := Config.new()

	# Sin remoto, el juego funciona con los defectos.
	assert(cfg.get_float("multiplicador_xp") == 1.0, "el defecto compilado no se aplica")

	# Un valor válido se adopta; uno fuera de rango se RECHAZA sin romper nada.
	var rechazos := []
	cfg.rechazada.connect(func(c, v, m): rechazos.append(c))
	cfg.aplicar_remoto({"valores": {"multiplicador_xp": 2.0, "precio_pocion": -5,
									"clave_inventada": 1}})
	assert(cfg.get_float("multiplicador_xp") == 2.0)
	assert(cfg.get_int("precio_pocion") == 15, "se adoptó un valor fuera de rango")
	assert(rechazos.size() == 2, "no se rechazaron los dos valores inválidos")

	# Asignación determinista y estable.
	var f1 := Flags.nuevo(&"plr_abc")
	var f2 := Flags.nuevo(&"plr_abc")
	var payload := {"flags": {"nueva_ui": {"activo": true, "porcentaje": 50, "sal": "v1"}}}
	f1.configurar(&"plr_abc", payload); f2.configurar(&"plr_abc", payload)
	assert(f1.activo("nueva_ui") == f2.activo("nueva_ui"),
		"el mismo jugador cae en grupos distintos")

	# Distribución razonable sobre muchos jugadores.
	var dentro := 0
	for i in 10000:
		var f := Flags.nuevo(StringName("plr_%d" % i))
		f.configurar(StringName("plr_%d" % i), payload)
		if f.activo("nueva_ui"): dentro += 1
	assert(abs(dentro - 5000) < 250, "la distribución del 50%% se desvía demasiado: %d" % dentro)

	# Kill switch: gana a todo.
	f1.configurar(&"plr_abc", {"flags": {"nueva_ui":
		{"activo": true, "porcentaje": 100, "kill": true}}})
	assert(not f1.activo("nueva_ui"), "el kill switch no apagó el flag")

	# Flag desconocido: apagado.
	assert(not f1.activo("no_existe"), "un flag desconocido debería estar apagado")

	print("== 8 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Añade caché en disco de la última configuración válida y úsala cuando no haya red.
2. Implementa segmentación: un flag activo solo para una plataforma o una versión de build.
3. Añade una pantalla de depuración que liste todos los flags, su estado y por qué (defecto, remoto, override).
4. Implementa `expira_en` para flags temporales y un aviso en CI cuando alguno caduca.
5. Escribe un test que compruebe que ninguna clave del esquema carece de defecto.
6. Simula un despliegue del 1 % al 100 % y registra el número de jugadores afectados en cada paso.
7. Diseña un experimento A/B real de tu juego: hipótesis, métrica objetivo, tamaño de muestra y criterio de parada.

## 📝 Reto verificable

Implementa configuración remota con esquema y defectos compilados, feature flags con rollout por porcentaje y asignación determinista, kill switches, experimentos multivariante con registro de exposición, override local solo en debug y caché en disco.

**Criterio de aceptación**: una prueba headless con **al menos 16 aserciones** demuestra que: (a) con el backend caído, todas las claves devuelven su defecto y el juego arranca; (b) un valor remoto fuera de rango, de tipo incorrecto o de clave desconocida se rechaza y **no** sustituye al defecto; (c) el mismo `player_id` obtiene siempre el mismo bucket para el mismo flag, entre ejecuciones distintas; (d) sobre 10.000 jugadores simulados, un rollout al 50 % activa entre el 47 % y el 53 %; (e) dos flags con sales distintas no asignan al mismo conjunto de jugadores (correlación baja); (f) un kill switch a `true` desactiva el flag aunque esté al 100 %; (g) `forzar()` no tiene ningún efecto en una build de release.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El juego no arranca si el backend está caído | Se espera la configuración remota. Defectos compilados y carga asíncrona. |
| Un valor mal puesto en el panel rompió el juego | No hay validación. Esquema con tipos y rangos; rechazar lo inválido. |
| Un jugador ve la función y al día siguiente no | El bucket no es determinista (usa aleatoriedad o la sesión). Hash del id. |
| Los mismos jugadores entran en todos los experimentos | Falta sal por flag. Añádela y varíala. |
| El kill switch no apaga nada | Se consultó al arrancar y se cacheó. Consulta en el punto de uso. |
| Hay 60 flags y nadie sabe cuáles siguen vivos | Los temporales no se eliminaron. Marca caducidad y limpia. |
| El experimento no concluye nada | No había métrica definida antes. Define hipótesis y métrica primero. |
| Un override de QA llegó a producción | El override existe en release. Compílalo solo en debug. |

## ❓ Preguntas frecuentes

**❓ ¿No es peligroso poder cambiar el juego sin publicar?** Es peligroso **no** poder. Con flags, un fallo grave se apaga en minutos; sin ellos, se arregla con un parche que tarda días en llegar a los jugadores. El riesgo real es cambiar sin validación ni rollout gradual, y por eso esta clase pone las dos cosas.

**❓ ¿Debo pedir permiso a la tienda para esto?** Cambiar valores de balance y activar funciones ya revisadas está aceptado y es práctica habitual. Lo que **no** está permitido en varias plataformas es usar la configuración remota para introducir funcionalidad esencialmente nueva que no pasó revisión, o para cambiar el modelo de compra. Consulta las políticas de cada tienda.

**❓ ¿Cuántos flags son demasiados?** Los que no puedas explicar. Una regla práctica: cada flag temporal nace con fecha de caducidad y un responsable; si llega la fecha y sigue vivo, se revisa o se elimina. Los permanentes (accesibilidad, modo depuración) son otra categoría y no cuentan.

**❓ ¿Qué límites éticos tiene experimentar con jugadores?** Los mismos que con cualquier persona, y algunos más si hay menores. Reglas mínimas: no experimentar con precios de forma que perjudique a un grupo, no experimentar con mecánicas de riesgo (loot boxes, gasto) sin un cuidado especial, no degradar deliberadamente la experiencia del grupo de control más allá del statu quo, y respetar el consentimiento y las obligaciones de transparencia aplicables ([clase 317](../317-telemetria-privacidad-y-gobernanza-de-datos/README.md)).

**❓ ¿Y si no tengo backend?** Puedes servir un JSON estático desde cualquier CDN o incluso desde un repositorio. Es lo bastante para configuración y kill switches. La segmentación y los experimentos con métricas ya requieren algo más, pero el 80 % del valor está en el JSON estático.

## 🔗 Referencias

- Martin Fowler — Feature Toggles: <https://martinfowler.com/articles/feature-toggles.html> · uso: se instala o se consulta en la preparación
- Google — *Site Reliability Engineering*, capítulo de releases progresivas: <https://sre.google/books/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `OS.is_debug_build` y builds: <https://docs.godotengine.org/en/4.3/classes/class_os.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `String.sha256_buffer` (hash determinista): <https://docs.godotengine.org/en/4.3/classes/class_string.html> · uso: respalda el Tema 7 «Asignación determinista»
- GDC Vault — charlas sobre LiveOps, experimentación y balance en producción: <https://www.gdcvault.com/> — catálogo por tema, no una charla identificada (ponente y año pendientes) · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 314 - Economía transaccional de servidor](../314-economia-transaccional-de-servidor/README.md)

## ➡️ Siguiente clase

[Clase 316 - Observabilidad de juegos](../316-observabilidad-de-juegos/README.md)
