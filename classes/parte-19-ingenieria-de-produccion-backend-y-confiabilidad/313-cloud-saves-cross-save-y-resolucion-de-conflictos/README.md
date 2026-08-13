# Clase 313 — Cloud saves, cross-save y resolución de conflictos

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *Documentación de Steam Cloud y de servicios de guardado de plataformas · Literatura sobre sistemas distribuidos (offline-first, causalidad)*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Llevar el save de producción de la [clase 307](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/307-save-system-de-produccion/README.md) a la nube, y resolver el problema que aparece en cuanto lo haces: **el mismo jugador, dos dispositivos, dos versiones distintas del progreso**. Es un problema de sistemas distribuidos disfrazado de función de comodidad, y es donde más partidas se pierden por un diseño ingenuo.

Aquí aprenderás por qué "gana el más reciente" es una respuesta insuficiente (los relojes de los dispositivos mienten), cómo detectar conflictos de verdad con **contadores de versión** en lugar de fechas, cómo diseñar un flujo **offline-first** donde el juego funciona sin conexión y sincroniza después, y cómo presentar un conflicto al jugador sin obligarle a entender nada de esto. Construirás el sistema completo con el `MockBackend`, sin ningún servicio real.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar por qué las marcas de tiempo del cliente no bastan para ordenar cambios.
2. Implementar un contador de versión monótono por save y detectar divergencias reales.
3. Implementar un flujo offline-first: escribir local siempre, sincronizar cuando se pueda.
4. Implementar subida y bajada idempotentes con reintentos seguros.
5. Detectar un conflicto y presentarlo al jugador con información útil para decidir.
6. Implementar fusión automática cuando el dominio lo permite, y saber cuándo no permitirlo.
7. Diseñar cross-save entre plataformas apoyándose en la identidad de la clase 312.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Offline-first | El juego no puede depender de la red para guardar. |
| 2 | Reloj del cliente | Miente: zona horaria, desfase, manipulación deliberada. |
| 3 | Contador de versión | Ordena cambios sin depender de relojes. |
| 4 | Detección de conflicto | Divergencia real ≠ "hay dos copias". |
| 5 | Estrategias de resolución | Automática, por el jugador, o fusión: cada una tiene su sitio. |
| 6 | Idempotencia | Un reintento no puede duplicar ni pisar. |
| 7 | Fusión de dominio | Sumar monedas y unir logros sí; posición en el mapa no. |
| 8 | Presentación al jugador | Debe poder elegir con datos, no con jerga técnica. |
| 9 | Cross-save | Depende de tener identidad propia, no de plataforma. |
| 10 | Cuotas y tamaño | Las plataformas limitan; el save debe caber. |

## 📖 Definiciones y características

- **Cloud save**: copia del progreso almacenada en un servicio remoto. Clave: es una réplica, no la fuente única.
- **Cross-save**: mismo progreso accesible desde plataformas distintas. Clave: requiere identidad propia (clase 312).
- **Offline-first**: diseño en el que la escritura local siempre funciona y la sincronización es posterior. Clave: es lo que hace que el juego no dependa de la red.
- **Contador de versión**: entero que se incrementa en cada guardado local. Clave: ordena cambios sin usar relojes.
- **Vector de versión**: contador por dispositivo, que permite saber si dos estados son comparables. Clave: detecta divergencia real, no solo diferencia.
- **Divergencia**: dos copias que han evolucionado por separado desde un ancestro común. Clave: es el único caso que es de verdad un conflicto.
- **Conflicto**: divergencia que el sistema no puede resolver solo. Clave: la palabra correcta para lo que hay que enseñar al jugador.
- **Last-write-wins (LWW)**: política de quedarse con la escritura más reciente. Clave: simple y peligrosa si "reciente" se mide con el reloj del cliente.
- **Fusión (merge)**: combinar dos estados en uno según reglas del dominio. Clave: solo funciona con datos que tengan una operación de combinación con sentido.
- **CRDT**: estructura de datos que se fusiona sin conflictos por construcción. Clave: excelente para contadores y conjuntos; excesiva para un save típico.
- **Idempotencia**: propiedad de que repetir una operación no cambia el resultado. Clave: sin ella, un reintento duplica.
- **ETag / precondición**: identificador de versión que el servidor exige para aceptar una escritura. Clave: es lo que impide pisar cambios ajenos.
- **Subida condicional**: escritura que solo se aplica si la versión base coincide. Clave: convierte una carrera en un error detectable.
- **Cuota**: límite de tamaño o número de archivos del servicio. Clave: hay que medir el save y comprimirlo si hace falta.
- **Sincronización perezosa**: sincronizar en momentos concretos (arranque, salida, cambio de zona). Clave: barata y suficiente para casi todos los juegos.
- **Ancestro común**: última versión que ambos dispositivos compartieron. Clave: es lo que permite saber si hay divergencia o solo retraso.

## 🧰 Herramientas y preparación

Necesitas el `Guardado` de la clase 307 y el `MockBackend` de la 311. Trabajaremos en `res://infraestructura/nube/`. Documentación útil: [Steam Cloud](https://partner.steamgames.com/doc/features/cloud) para ver un servicio real con sus cuotas y su modelo de conflicto, y la [clase 312](../312-identidad-perfiles-y-entitlements/README.md) para la identidad que hace posible el cross-save.

## 🧪 Laboratorio guiado

1. **El problema, en un dibujo.** Esto es lo que hay que resolver:

```text
        v3 (móvil, 40 monedas)
       /
v2 ───┤                  ¿cuál es el bueno?
       \
        v3' (PC, mató al jefe)
```

Las dos partieron de `v2` y las dos son `v3`. Con marcas de tiempo, gana la que tenga el reloj más adelantado — que puede ser la del dispositivo con la hora mal puesta. Con contadores de versión, se detecta que **ambas** vienen de `v2` y que por tanto hay divergencia real.

2. **Los metadatos de sincronización.** Tres campos, y todo lo demás sale de ahí:

```gdscript
class_name MetaSync
extends RefCounted

var version: int = 0              # contador MONÓTONO local
var base: int = 0                 # versión del servidor sobre la que se construyó
var dispositivo: StringName = &""  # id estable del dispositivo
var guardado_en: float = 0.0      # solo informativo: NUNCA para decidir

func a_dict() -> Dictionary:
	return {"version": version, "base": base,
			"dispositivo": String(dispositivo), "guardado_en": guardado_en}

static func de_dict(d: Dictionary) -> MetaSync:
	var m := MetaSync.new()
	m.version = int(d.get("version", 0))
	m.base = int(d.get("base", 0))
	m.dispositivo = StringName(str(d.get("dispositivo", "")))
	m.guardado_en = float(d.get("guardado_en", 0.0))
	return m
```

3. **El servicio de nube (simulado, con precondición).** La pieza clave es que **rechaza** escrituras basadas en una versión antigua:

```gdscript
class_name NubeMock
extends RefCounted

enum Resultado { OK, CONFLICTO, ERROR_RED, CUOTA }

const CUOTA_BYTES := 1 << 20      # 1 MB, como muchos servicios reales

var _saves := {}                  # player_id -> {datos, meta}
var caida := false
var latencia := 0.0

func bajar(player_id: StringName) -> Dictionary:
	if caida:
		return {"resultado": Resultado.ERROR_RED}
	if not _saves.has(player_id):
		return {"resultado": Resultado.OK, "vacio": true}
	return {"resultado": Resultado.OK, "vacio": false,
			"datos": _saves[player_id]["datos"].duplicate(true),
			"meta": _saves[player_id]["meta"].duplicate()}

func subir(player_id: StringName, datos: Dictionary, meta: Dictionary) -> Dictionary:
	if caida:
		return {"resultado": Resultado.ERROR_RED}
	if JSON.stringify(datos).length() > CUOTA_BYTES:
		return {"resultado": Resultado.CUOTA}

	var actual: Dictionary = _saves.get(player_id, {})
	if not actual.is_empty():
		var v_servidor := int(actual["meta"]["version"])
		# PRECONDICIÓN: solo acepto si venías de mi versión actual. Si no,
		# alguien escribió entre medias y esto es una divergencia.
		if int(meta.get("base", -1)) != v_servidor:
			return {"resultado": Resultado.CONFLICTO,
					"datos": actual["datos"].duplicate(true),
					"meta": actual["meta"].duplicate()}

	var nueva := meta.duplicate()
	nueva["version"] = int(actual.get("meta", {}).get("version", 0)) + 1
	_saves[player_id] = {"datos": datos.duplicate(true), "meta": nueva}
	return {"resultado": Resultado.OK, "meta": nueva}
```

4. **El sincronizador.** Offline-first: escribir local siempre, sincronizar después:

```gdscript
class_name Sincronizador
extends RefCounted

enum Estado { SINCRONIZADO, PENDIENTE, CONFLICTO, SIN_RED }

signal conflicto_detectado(local: Dictionary, remoto: Dictionary)
signal sincronizado(version: int)

var _nube: NubeMock
var _guardado: Guardado
var _meta := MetaSync.new()
var estado: Estado = Estado.SINCRONIZADO

func guardar_local(slot: int, datos_meta: Dictionary) -> bool:
	# SIEMPRE funciona: el disco local es la única escritura que no puede fallar
	# por causas ajenas. La nube viene después.
	_meta.version += 1
	_meta.guardado_en = Time.get_unix_time_from_system()
	var meta := datos_meta.duplicate()
	meta["sync"] = _meta.a_dict()
	var ok := _guardado.guardar(slot, meta)
	if ok and estado == Estado.SINCRONIZADO:
		estado = Estado.PENDIENTE
	return ok

func sincronizar(player_id: StringName, slot: int) -> Estado:
	if estado == Estado.CONFLICTO:
		return estado                       # hasta que el jugador decida, no se toca

	var remoto := _nube.bajar(player_id)
	if int(remoto["resultado"]) == NubeMock.Resultado.ERROR_RED:
		estado = Estado.SIN_RED
		return estado

	if bool(remoto.get("vacio", false)):
		return _subir(player_id, slot)

	var meta_remota := MetaSync.de_dict(remoto["meta"])

	# Caso 1: el remoto es exactamente lo que yo tengo por base y no he tocado
	# nada → estoy al día.
	if _meta.base == meta_remota.version and _meta.version == _meta.base:
		estado = Estado.SINCRONIZADO
		return estado

	# Caso 2: el remoto ha avanzado y yo NO he tocado nada → bajo sin más.
	if _meta.version == _meta.base and meta_remota.version > _meta.base:
		_aplicar_remoto(remoto)
		estado = Estado.SINCRONIZADO
		return estado

	# Caso 3: yo he avanzado y el remoto sigue en mi base → subo.
	if _meta.version > _meta.base and meta_remota.version == _meta.base:
		return _subir(player_id, slot)

	# Caso 4: los dos hemos avanzado desde la misma base → DIVERGENCIA real.
	estado = Estado.CONFLICTO
	conflicto_detectado.emit(_resumen_local(), _resumen(remoto))
	return estado

func _subir(player_id: StringName, slot: int) -> Estado:
	var datos := _guardado.leer_crudo(slot)
	var r := _nube.subir(player_id, datos, _meta.a_dict())
	match int(r["resultado"]):
		NubeMock.Resultado.OK:
			_meta.base = int(r["meta"]["version"])
			_meta.version = _meta.base
			estado = Estado.SINCRONIZADO
			sincronizado.emit(_meta.base)
		NubeMock.Resultado.CONFLICTO:
			estado = Estado.CONFLICTO
			conflicto_detectado.emit(_resumen_local(), _resumen(r))
		NubeMock.Resultado.ERROR_RED:
			estado = Estado.SIN_RED
		NubeMock.Resultado.CUOTA:
			push_error("el save supera la cuota del servicio")
			estado = Estado.PENDIENTE
	return estado
```

5. **El resumen para el jugador.** Nadie debe leer la palabra "vector de versión" en una pantalla:

```gdscript
func _resumen(r: Dictionary) -> Dictionary:
	var d: Dictionary = r.get("datos", {})
	var m: Dictionary = d.get("meta", {})
	return {
		"dispositivo": str(r.get("meta", {}).get("dispositivo", "otro dispositivo")),
		"nivel": int(m.get("nivel", 1)),
		"tiempo_jugado": float(m.get("tiempo_jugado", 0.0)),
		"zona": str(m.get("zona", "")),
		"fecha": str(m.get("guardado_en", "")),
	}
```

Y la pantalla dice, en cristiano:

```text
Tienes dos partidas distintas.

  Este dispositivo     PC de casa
  Nivel 27             Nivel 24
  43 h 12 min          41 h 05 min
  Guarida del lobo     Pueblo del río
  hace 5 minutos       hace 2 días

  [Usar esta]  [Usar la de PC de casa]  [Guardar las dos]
```

La tercera opción es importante: **conservar la descartada** en una ranura local convierte una decisión irreversible en reversible, y elimina la peor consecuencia de equivocarse.

6. **Fusión automática, cuando el dominio lo permite.** Y solo entonces:

```gdscript
class_name FusionSave
extends RefCounted

# Se fusiona lo que tiene una operación de combinación EVIDENTE. Todo lo demás
# es una elección de partida, no una fusión.
static func fusionar(a: Dictionary, b: Dictionary) -> Dictionary:
	var r := a.duplicate(true)

	# Máximos: nunca quitan progreso a nadie.
	r["progresion"]["xp"] = maxi(int(a["progresion"]["xp"]), int(b["progresion"]["xp"]))

	# Uniones: desbloqueos y logros son conjuntos.
	var unlocks := {}
	for u in a["progresion"].get("desbloqueos", []): unlocks[u] = true
	for u in b["progresion"].get("desbloqueos", []): unlocks[u] = true
	r["progresion"]["desbloqueos"] = unlocks.keys()

	# NO se fusiona: inventario, posición, estado de quests. Un inventario
	# fusionado duplicaría objetos, que es exactamente el bug que crea
	# economías rotas. Se toma el del lado elegido.
	return r
```

7. **Idempotencia de la subida.** Un reintento no puede crear dos versiones:

```gdscript
func subir_con_reintento(player_id: StringName, slot: int, intentos := 3) -> Estado:
	for i in intentos:
		var st := _subir(player_id, slot)
		if st != Estado.SIN_RED:
			return st
		# La subida es idempotente porque va con precondición: si la primera
		# llegó y no nos enteramos, la segunda dará CONFLICTO con la MISMA
		# versión que subimos, y eso se detecta comparando el contenido.
		await _esperar(0.5 * pow(2.0, i))
	return Estado.SIN_RED
```

8. **Probarlo.** Los cuatro casos, más el conflicto:

```gdscript
extends SceneTree

func _init() -> void:
	var nube := NubeMock.new()
	var pid := &"plr_test"

	# Dispositivo A guarda y sube.
	var a := Sincronizador.nuevo(nube, &"movil")
	a.guardar_local_simulado({"xp": 100})
	assert(a.sincronizar(pid, 0) == Sincronizador.Estado.SINCRONIZADO)

	# Dispositivo B baja: está al día sin haber tocado nada.
	var b := Sincronizador.nuevo(nube, &"pc")
	assert(b.sincronizar(pid, 0) == Sincronizador.Estado.SINCRONIZADO)
	assert(b.datos()["xp"] == 100, "B no recibió el estado de A")

	# Los dos avanzan sin conexión desde la misma base → divergencia.
	a.guardar_local_simulado({"xp": 150})
	b.guardar_local_simulado({"xp": 120})
	assert(a.sincronizar(pid, 0) == Sincronizador.Estado.SINCRONIZADO, "A debería poder subir")
	assert(b.sincronizar(pid, 0) == Sincronizador.Estado.CONFLICTO,
		"B debería detectar conflicto, no pisar a A")

	# Sin red: guardar local SIEMPRE funciona.
	nube.caida = true
	assert(b.guardar_local_simulado({"xp": 130}), "guardar local falló sin conexión")
	assert(b.sincronizar(pid, 0) == Sincronizador.Estado.CONFLICTO,
		"el conflicto pendiente no debe perderse por una caída")

	# Reloj hacia atrás: no debe cambiar nada, porque no decidimos por fecha.
	b.forzar_reloj(-86400.0)
	assert(b.sincronizar(pid, 0) == Sincronizador.Estado.CONFLICTO,
		"el reloj del cliente ha influido en la decisión")

	print("== 8 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Implementa la resolución "guardar las dos" creando una ranura local con el descartado.
2. Añade compresión al subir y comprueba que un save de 3 MB cabe en la cuota de 1 MB.
3. Implementa sincronización perezosa: solo al arrancar, al salir y al cambiar de zona.
4. Simula 100 sincronizaciones alternando dispositivos y comprueba que nunca se pierde XP.
5. Añade un histórico de las últimas 3 versiones en la nube y una opción de restaurar.
6. Implementa detección de "save del futuro" (versión superior a la que entiende la build).
7. Escribe el texto exacto de la pantalla de conflicto de tu juego, sin jerga técnica.

## 📝 Reto verificable

Implementa cloud save con contador de versión, subida condicional con precondición, los cuatro casos de sincronización, detección de conflicto, resolución por el jugador con conservación del descartado, fusión automática de campos combinables y modo offline con cola de pendientes.

**Criterio de aceptación**: una prueba headless con **al menos 18 aserciones** demuestra que: (a) dos dispositivos que avanzan desde la misma base producen `CONFLICTO` y **ninguno pisa al otro**; (b) manipular el reloj del cliente (adelantarlo o atrasarlo un día) **no cambia** ninguna decisión de sincronización; (c) guardar en local funciona siempre, incluso con la nube caída; (d) una subida reintentada tras un error de red no crea dos versiones en la nube; (e) un save que supera la cuota se rechaza con un error específico y no corrompe el remoto; (f) la fusión automática conserva el máximo de XP y la unión de desbloqueos, y **no** fusiona inventarios; (g) tras resolver un conflicto eligiendo un lado, el otro queda accesible en una ranura local.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El progreso del móvil pisa al del PC | Se decidió por marca de tiempo. Usa contadores de versión y precondición. |
| El jugador pierde horas al elegir mal en el conflicto | La decisión era irreversible. Conserva siempre el descartado. |
| Un reintento crea dos partidas en la nube | La subida no es condicional. Envía la versión base y rechaza si no coincide. |
| No se puede jugar sin conexión | La escritura local depende de la nube. Offline-first: local primero, siempre. |
| El save no sube y no hay aviso | Se supera la cuota en silencio. Devuelve un error específico y avísalo. |
| El inventario se duplica tras sincronizar | Se fusionó lo que no se debe fusionar. Fusiona solo máximos y uniones. |
| El cross-save no funciona entre PC y consola | La identidad es la de plataforma. Necesitas identidad propia (clase 312). |
| Cada arranque sube el save entero | Sincronización demasiado ansiosa. Sube solo si la versión local avanzó. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué no usar simplemente la fecha?** Porque los relojes de los clientes son poco fiables por accidente (zonas horarias, desfases, arranques sin red) y manipulables a propósito. Un contador que solo tú incrementas y una precondición en el servidor dan un orden correcto sin depender de nadie.

**❓ ¿No es esto demasiado para un juego pequeño?** El contador de versión y la precondición son unas veinte líneas y evitan la clase de bug que hace perder partidas. Lo que sí puedes simplificar es la resolución: para muchos juegos basta con "te enseño las dos y eliges", sin fusión automática.

**❓ ¿Qué hago si la plataforma ya me da cloud save?** Steam Cloud y equivalentes resuelven el transporte y la cuota, pero **el conflicto sigue siendo tuyo**: te avisan de que hay dos versiones y decides. Todo lo de esta clase sigue aplicando; lo que te ahorras es el almacenamiento.

**❓ ¿CRDT para el save?** Es la solución teóricamente elegante para fusionar sin conflictos, y encaja muy bien con contadores (monedas ganadas) y conjuntos (logros). Para un save típico con inventario y posición es desproporcionado: la fusión selectiva del paso 6 da el 90 % del valor con una fracción del coste.

**❓ ¿Cada cuánto sincronizo?** Sincronización perezosa: al arrancar, al salir y en hitos (cambio de zona, fin de nivel). Sincronizar continuamente multiplica el tráfico, aumenta la probabilidad de conflicto y no mejora la experiencia.

## 🔗 Referencias

- Steamworks — Steam Cloud, cuotas y conflictos: <https://partner.steamgames.com/doc/features/cloud>
- MDN — HTTP conditional requests (ETag y precondiciones): <https://developer.mozilla.org/en-US/docs/Web/HTTP/Conditional_requests>
- Godot Docs — `FileAccess` y compresión: <https://docs.godotengine.org/en/stable/classes/class_fileaccess.html>
- Martin Kleppmann — *Designing Data-Intensive Applications*, capítulo sobre replicación y conflictos: <https://dataintensive.net/>
- Wikipedia — Version vector: <https://en.wikipedia.org/wiki/Version_vector>

## ⬅️ Clase anterior

[Clase 312 - Identidad, perfiles y entitlements](../312-identidad-perfiles-y-entitlements/README.md)

## ➡️ Siguiente clase

[Clase 314 - Economía transaccional de servidor](../314-economia-transaccional-de-servidor/README.md)
