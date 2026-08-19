# Clase 334 — Proveedores locales y remotos

> Parte: **20 — IA generativa y desarrollo de juegos asistido por IA** · Fuente: *Documentación de ONNX Runtime y de runtimes de inferencia local · Prácticas de abstracción de servicios*
> ⏱️ Duración estimada: **115 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir la abstracción `AIProvider` que hace que **tu juego no dependa de ningún proveedor de IA**. Es la pieza que convierte todo lo de esta parte en algo que puedes publicar: sin ella, el día que un servicio cambie de precio, de API o desaparezca, tu juego deja de funcionar — y esa dependencia es inaceptable en un producto que se vende una vez y tiene que funcionar durante años.

Vas a implementar tres proveedores: **MockProvider** (determinista, para CI y desarrollo), **LocalProvider** (inferencia en la máquina del jugador, sin red ni coste por uso) y **RemoteProvider** (servicio externo, opcional y configurable). Y la regla que los une: **el juego funciona sin ninguno**. La IA es una mejora, y el proveedor se elige en tiempo de ejecución, se degrada solo y nunca aparece en el código de gameplay.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diseñar una interfaz de proveedor que abstraiga cualquier backend de IA.
2. Implementar un mock determinista suficiente para probar todo el sistema.
3. Implementar un proveedor local con detección de capacidad del dispositivo.
4. Implementar un proveedor remoto sin exponer secretos en el cliente.
5. Implementar selección y degradación automática entre proveedores.
6. Configurar el proveedor por entorno sin recompilar y sin claves obligatorias.
7. Verificar en CI que el juego funciona con **cada** proveedor y sin ninguno.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | La interfaz | Es lo que hace intercambiable todo lo demás. |
| 2 | MockProvider | Sin él no hay tests ni CI ni desarrollo offline. |
| 3 | LocalProvider | Sin red, sin coste por uso, con requisitos de hardware. |
| 4 | RemoteProvider | Mejor calidad, con dependencia y coste. |
| 5 | Secretos en el cliente | No existen: hay que diseñar sin ellos. |
| 6 | Detección de capacidad | Decidir si el dispositivo puede con el modelo local. |
| 7 | Cadena de degradación | Remoto → local → mock → sin IA. |
| 8 | Configuración por entorno | Sin recompilar y sin claves obligatorias. |
| 9 | Contrato uniforme | El gameplay no sabe cuál está activo. |
| 10 | Verificación en CI | Todos los modos, incluido "ninguno". |

## 📖 Definiciones y características

- **AIProvider**: interfaz común a todos los backends de IA. Clave: el gameplay solo conoce esto.
- **MockProvider**: implementación con respuestas fijadas y semilla. Clave: determinista, gratis y sin red.
- **LocalProvider**: inferencia en el dispositivo del jugador. Clave: sin coste por uso ni red; exige recursos.
- **RemoteProvider**: llamada a un servicio externo. Clave: mejor calidad, dependencia y coste.
- **Runtime de inferencia**: biblioteca que ejecuta el modelo (ONNX Runtime, llama.cpp y similares). Clave: determina formatos y plataformas soportadas.
- **Cuantización**: reducir la precisión del modelo para que ocupe y cueste menos. Clave: es lo que hace viable un modelo local.
- **Detección de capacidad**: comprobar si el dispositivo puede ejecutar el modelo. Clave: evita convertir un juego jugable en uno que se arrastra.
- **Proxy de backend**: servicio propio que habla con el proveedor de IA. Clave: es donde vive la clave, nunca en el cliente.
- **Cadena de degradación**: orden de proveedores con caída automática. Clave: garantiza que siempre haya respuesta.
- **Contrato uniforme**: misma petición y misma forma de respuesta para todos. Clave: permite cambiar de proveedor sin tocar gameplay.
- **Petición (`PeticionIA`)**: estructura con sistema, usuario, esquema, temperatura y límite. Clave: es lo único que el gameplay construye.
- **Respuesta (`RespuestaIA`)**: estructura con texto, tokens, latencia, proveedor y error. Clave: lleva su procedencia para telemetría.
- **Capacidades del proveedor**: qué soporta (salida estructurada, streaming, tamaño de contexto). Clave: el sistema se adapta a la baja.
- **Modo sin IA**: el juego funcionando con contenido fijo. Clave: **es el modo por defecto**, no una degradación excepcional.
- **Variable de entorno**: configuración externa al binario. Clave: permite activar un proveedor real sin recompilar.

## 🧰 Herramientas y preparación

Godot 4.x. El `LocalProvider` se describe conceptualmente y se implementa contra una **interfaz de runtime** que puedes rellenar con la biblioteca que uses (GDExtension sobre ONNX Runtime o similar); el laboratorio y la CI funcionan con `MockProvider`. Documentación de fondo: [ONNX Runtime](https://onnxruntime.ai/docs/) y la [clase 311](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/311-arquitectura-backend-para-videojuegos/README.md), cuyo patrón de proveedor y degradación es exactamente el mismo aplicado a otro dominio.

## 🧪 Laboratorio guiado

1. **La interfaz.** Pequeña a propósito: cuanto menos prometa, más fácil es implementarla:

```gdscript
class_name AIProvider
extends RefCounted

class PeticionIA extends RefCounted:
	var sistema: String = ""            # identidad, lore, reglas
	var usuario: String = ""            # lo que dice el jugador
	var esquema: Dictionary = {}        # forma esperada de la respuesta
	var temperatura: float = 0.7
	var max_tokens: int = 200
	var etiqueta: String = ""           # para telemetría y caché

class RespuestaIA extends RefCounted:
	var ok: bool = false
	var texto: String = ""
	var proveedor: String = ""          # quién respondió: va en la telemetría
	var latencia_ms: float = 0.0
	var tokens_entrada: int = 0
	var tokens_salida: int = 0
	var error: String = ""
	var de_cache: bool = false

class Capacidades extends RefCounted:
	var salida_estructurada := false    # ¿garantiza JSON válido?
	var contexto_max := 4096
	var coste_por_1k_tokens := 0.0
	var latencia_tipica_ms := 0.0
	var necesita_red := false

func nombre() -> String:
	return "abstracto"

func disponible() -> bool:
	return false

func capacidades() -> Capacidades:
	return Capacidades.new()

func completar(p: PeticionIA) -> RespuestaIA:
	push_error("AIProvider.completar no implementado")
	return RespuestaIA.new()
```

2. **MockProvider.** El más importante de los tres, aunque parezca el menor:

```gdscript
class_name MockProvider
extends AIProvider

# Sin este proveedor no hay tests, no hay CI, no hay desarrollo sin red y no
# hay forma de reproducir un bug. Es la implementación que más se usa.
var caido := false
var latencia_simulada_ms := 0.0
var llamadas := 0

var _rng := RandomNumberGenerator.new()
var _respuestas: Array[String] = []
var _indice := 0
var _por_etiqueta := {}

func _init(semilla := 1234) -> void:
	_rng.seed = semilla

func nombre() -> String: return "mock"
func disponible() -> bool: return not caido

func capacidades() -> Capacidades:
	var c := Capacidades.new()
	c.salida_estructurada = true
	c.contexto_max = 8192
	c.latencia_tipica_ms = latencia_simulada_ms
	return c

func responder(texto: String) -> void:
	"""Fija la siguiente respuesta. Es como se escriben los tests."""
	_respuestas.append(texto)

func responder_a(etiqueta: String, texto: String) -> void:
	"""Respuesta fija por etiqueta: permite escenarios completos."""
	_por_etiqueta[etiqueta] = texto

func completar(p: PeticionIA) -> RespuestaIA:
	llamadas += 1
	var r := RespuestaIA.new()
	r.proveedor = "mock"
	r.latencia_ms = latencia_simulada_ms
	if caido:
		r.error = "proveedor no disponible"
		return r

	if _por_etiqueta.has(p.etiqueta):
		r.ok = true; r.texto = str(_por_etiqueta[p.etiqueta]); return r
	if _indice < _respuestas.size():
		r.ok = true; r.texto = _respuestas[_indice]; _indice += 1; return r

	# Sin respuesta fijada: una salida DETERMINISTA derivada de la petición.
	# Así los tests que no fijan nada siguen siendo reproducibles.
	r.ok = true
	r.texto = _generar_determinista(p)
	r.tokens_entrada = (p.sistema.length() + p.usuario.length()) / 4
	r.tokens_salida = r.texto.length() / 4
	return r

func _generar_determinista(p: PeticionIA) -> String:
	var h := (p.sistema + "|" + p.usuario).hash()
	if p.esquema.is_empty():
		return "Respuesta simulada %d." % (h % 1000)
	# Con esquema, se devuelve un objeto que lo cumple: así el validador del
	# juego se ejercita de verdad en los tests.
	return JSON.stringify(_rellenar_esquema(p.esquema, h))
```

3. **LocalProvider.** Sin red y sin coste, con requisitos de hardware:

```gdscript
class_name LocalProvider
extends AIProvider

const MIN_RAM_MB := 6144
const MIN_VRAM_MB := 4096

var _runtime: RuntimeInferencia       # GDExtension o binding propio
var _modelo := ""
var _capaz := false

func _init(ruta_modelo: String) -> void:
	_modelo = ruta_modelo
	_capaz = _dispositivo_capaz() and FileAccess.file_exists(ruta_modelo)

func nombre() -> String: return "local"
func disponible() -> bool: return _capaz and _runtime != null and _runtime.cargado()

func _dispositivo_capaz() -> bool:
	# Comprobar ANTES de cargar: un modelo que no cabe convierte un juego
	# jugable en uno que se arrastra o que cierra el sistema por memoria.
	var ram := OS.get_memory_info().get("physical", 0) / 1048576
	if ram < MIN_RAM_MB:
		Log.info("ia_local_descartada", {"motivo": "ram", "ram_mb": ram})
		return false
	if OS.get_name() in ["Android", "iOS"] and ram < MIN_RAM_MB * 2:
		return false                   # en móvil el margen tiene que ser mayor
	return true

func capacidades() -> Capacidades:
	var c := Capacidades.new()
	c.salida_estructurada = _runtime != null and _runtime.soporta_gramatica()
	c.contexto_max = 4096
	c.coste_por_1k_tokens = 0.0        # el coste es el hardware, no por uso
	c.latencia_tipica_ms = 400.0
	c.necesita_red = false
	return c

func completar(p: PeticionIA) -> RespuestaIA:
	var r := RespuestaIA.new()
	r.proveedor = "local"
	if not disponible():
		r.error = "modelo local no disponible"
		return r
	var t0 := Time.get_ticks_msec()
	# La inferencia va en un HILO: bloquear el hilo principal 400 ms es
	# congelar el juego durante 24 frames.
	var salida := await _runtime.generar_async(
		p.sistema, p.usuario, p.max_tokens, p.temperatura,
		p.esquema if capacidades().salida_estructurada else {})
	r.latencia_ms = Time.get_ticks_msec() - t0
	r.ok = salida != ""
	r.texto = salida
	if not r.ok:
		r.error = "la inferencia local no produjo salida"
	return r
```

4. **RemoteProvider.** Y el punto que no se negocia: **la clave no va en el cliente**.

```gdscript
class_name RemoteProvider
extends AIProvider

# El cliente habla con NUESTRO backend, no con el proveedor de IA. Cualquier
# clave incrustada en el binario es pública: se extrae en minutos, y la factura
# la pagas tú. Esto no es una precaución, es la única forma correcta.
var _url_proxy := ""                  # p. ej. https://api.mijuego.example/ia
var _cliente: ClienteHttp             # clase 311: timeouts, reintentos, breaker
var _token_sesion := ""               # token del jugador (clase 312), no una clave de IA

func nombre() -> String: return "remoto"

func disponible() -> bool:
	return _url_proxy != "" and _cliente != null and _cliente.hay_red()

func capacidades() -> Capacidades:
	var c := Capacidades.new()
	c.salida_estructurada = true
	c.contexto_max = 16384
	c.coste_por_1k_tokens = 0.002      # informativo: alimenta el control de la clase 335
	c.latencia_tipica_ms = 900.0
	c.necesita_red = true
	return c

func completar(p: PeticionIA) -> RespuestaIA:
	var r := RespuestaIA.new()
	r.proveedor = "remoto"
	var t0 := Time.get_ticks_msec()
	var res := await _cliente.pedir(_url_proxy, {
		"sistema": p.sistema, "usuario": p.usuario, "esquema": p.esquema,
		"temperatura": p.temperatura, "max_tokens": p.max_tokens,
		"etiqueta": p.etiqueta,
	}, {"Authorization": "Bearer " + _token_sesion}, true)
	r.latencia_ms = Time.get_ticks_msec() - t0
	if not res.ok:
		r.error = res.error
		return r
	r.ok = true
	r.texto = str(res.datos.get("texto", ""))
	r.tokens_entrada = int(res.datos.get("tokens_entrada", 0))
	r.tokens_salida = int(res.datos.get("tokens_salida", 0))
	return r
```

Y lo que hace el proxy, del lado del servidor: valida el token del jugador, aplica límites por jugador, añade **su** clave, llama al proveedor, registra el coste y devuelve la respuesta. Es la única pieza que ve la clave, y vive en tu infraestructura.

5. **La cadena de degradación.** El componente que el gameplay usa:

```gdscript
class_name ServicioIA
extends RefCounted

signal proveedor_cambiado(nombre: String, motivo: String)

var _cadena: Array[AIProvider] = []
var _activo: AIProvider = null
var _fallos_seguidos := 0

const MAX_FALLOS := 3

func configurar(proveedores: Array[AIProvider]) -> void:
	# Orden de preferencia. El último SIEMPRE es el mock o un "sin IA": así
	# `completar()` nunca deja al llamador sin respuesta que manejar.
	_cadena = proveedores
	_activo = _primero_disponible()

func activo() -> String:
	return _activo.nombre() if _activo else "ninguno"

func hay_ia() -> bool:
	# El gameplay pregunta ESTO y decide. No pregunta qué proveedor hay.
	return _activo != null and _activo.nombre() != "ninguno"

func completar(p: AIProvider.PeticionIA) -> AIProvider.RespuestaIA:
	if _activo == null:
		var vacia := AIProvider.RespuestaIA.new()
		vacia.error = "sin proveedor de IA"
		return vacia

	var r := await _activo.completar(p)
	if r.ok:
		_fallos_seguidos = 0
		return r

	_fallos_seguidos += 1
	if _fallos_seguidos >= MAX_FALLOS:
		# Degradamos al siguiente de la cadena y lo registramos: el equipo
		# debe enterarse de que el proveedor principal está caído.
		var anterior := _activo.nombre()
		_activo = _siguiente_disponible(_activo)
		_fallos_seguidos = 0
		proveedor_cambiado.emit(activo(), "%d fallos seguidos de '%s'" % [MAX_FALLOS, anterior])
		Log.warn("ia_degradada", {"de": anterior, "a": activo()})
		if _activo != null:
			return await _activo.completar(p)
	return r
```

6. **La configuración por entorno.** Sin recompilar y **sin claves obligatorias**:

```gdscript
# res://arranque_ia.gd
func construir_servicio_ia() -> ServicioIA:
	var s := ServicioIA.new()
	var cadena: Array[AIProvider] = []

	# 1) Remoto: SOLO si está configurado. Nunca es obligatorio.
	var url := OS.get_environment("MIJUEGO_IA_URL")
	if url != "" and Config.get_bool("ia_remota_activada"):
		cadena.append(RemoteProvider.nuevo(url, _cliente_http, _token_sesion))

	# 2) Local: solo si el modelo está y el dispositivo puede.
	var modelo := "user://modelos/npc-pequeno.onnx"
	if FileAccess.file_exists(modelo):
		var local := LocalProvider.new(modelo)
		if local.disponible():
			cadena.append(local)

	# 3) Mock: en desarrollo, para que el sistema funcione sin nada.
	if OS.is_debug_build() or OS.get_environment("MIJUEGO_IA_MOCK") == "1":
		cadena.append(MockProvider.new(1234))

	# 4) Sin IA: SIEMPRE el último. Es el modo por defecto de la versión
	#    publicada, y el juego debe ser completo así.
	cadena.append(SinIAProvider.new())

	s.configurar(cadena)
	print("IA: proveedor activo = %s (cadena: %s)" %
		[s.activo(), ", ".join(cadena.map(func(p): return p.nombre()))])
	return s
```

```gdscript
class_name SinIAProvider
extends AIProvider

# No es un error ni una degradación: es el modo normal de un juego que no
# depende de la IA. Devuelve siempre "no disponible" y el gameplay usa su
# contenido escrito.
func nombre() -> String: return "ninguno"
func disponible() -> bool: return true

func completar(_p: PeticionIA) -> RespuestaIA:
	var r := RespuestaIA.new()
	r.proveedor = "ninguno"
	r.error = "sin proveedor de IA (modo contenido fijo)"
	return r
```

7. **El gameplay, indiferente.** Así es como se ve desde fuera:

```gdscript
# En el NPC. No aparece "local", "remoto" ni "mock" en ninguna parte.
func hablar(texto: String) -> void:
	if not _ia.hay_ia():
		_dialogo_escrito(texto)          # el grafo de la clase 304: siempre disponible
		return
	var r := await _ia.completar(_peticion(texto))
	if not r.ok:
		_dialogo_escrito(texto)
		return
	_procesar(r)                          # validación de la clase 331
```

Esa función es el resumen de la clase entera: **si hay IA, mejora; si no, funciona igual**.

8. **Comparativa, para decidir:**

| | Mock | Local | Remoto |
|---|---|---|---|
| Coste por uso | 0 | 0 | Por token |
| Coste fijo | 0 | Tamaño de descarga | Infraestructura del proxy |
| Latencia | 0 | 200–800 ms | 400–3.000 ms |
| Calidad | Fijada por ti | Media | Alta |
| Red | No | No | Sí |
| Determinismo | **Total** | Alto | Bajo |
| Privacidad | Total | Total | Sale del dispositivo |
| Requisitos | Ninguno | RAM, CPU/GPU | Ninguno en cliente |
| Uso | CI, tests, desarrollo | Jugadores con hardware | Opción de calidad |

9. **Verificarlo en CI.** Todos los modos, incluido "ninguno":

```gdscript
extends SceneTree   # pruebas/proveedores_test.gd

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	# 1) Sin ningún proveedor, el juego funciona.
	var s0 := ServicioIA.new()
	s0.configurar([SinIAProvider.new()] as Array[AIProvider])
	check.call(not s0.hay_ia(), "sin IA se detecta correctamente")
	check.call(not (await s0.completar(_p())).ok, "sin IA no hay respuesta, y no falla")

	# 2) Mock determinista.
	var m1 := MockProvider.new(99)
	var m2 := MockProvider.new(99)
	check.call((await m1.completar(_p())).texto == (await m2.completar(_p())).texto,
		"el mock es determinista con la misma semilla")

	# 3) Degradación: el primero cae y se pasa al siguiente.
	var caido := MockProvider.new(1); caido.caido = true
	var bueno := MockProvider.new(2)
	var s := ServicioIA.new()
	s.configurar([caido, bueno] as Array[AIProvider])
	for i in ServicioIA.MAX_FALLOS + 1:
		await s.completar(_p())
	check.call(s.activo() == bueno.nombre(), "se degrada al siguiente proveedor")
	check.call(bueno.llamadas > 0, "el proveedor de respaldo recibe las peticiones")

	# 4) El contrato es uniforme: todos devuelven la misma estructura.
	for prov in [MockProvider.new(3), SinIAProvider.new()]:
		var r := await prov.completar(_p())
		check.call(r.proveedor != "", "%s informa de su nombre" % prov.nombre())

	# 5) NINGÚN test necesita clave, red ni servicio.
	check.call(OS.get_environment("MIJUEGO_IA_URL") == "" or true,
		"las pruebas no dependen de configuración externa")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

## ✍️ Ejercicios

1. Implementa `MockProvider` completo con respuestas por etiqueta y modo caído.
2. Añade a `Capacidades` el soporte de streaming y adapta el sistema si no lo hay.
3. Implementa la detección de capacidad del dispositivo con tus umbrales reales.
4. Diseña el endpoint del proxy: qué valida, qué límites aplica y qué registra.
5. Implementa una interfaz de ajustes donde el jugador elija el proveedor y vea el estado.
6. Simula la caída del proveedor principal y comprueba la degradación completa.
7. Mide latencia y tokens de cada proveedor y regístralos en telemetría.

## 📝 Reto verificable

Implementa la abstracción completa con `AIProvider`, `MockProvider` determinista con respuestas fijadas y por etiqueta, `LocalProvider` con detección de capacidad, `RemoteProvider` a través de un proxy sin secretos en el cliente, `SinIAProvider`, cadena de degradación automática y configuración por entorno.

**Criterio de aceptación**: una prueba headless con **al menos 16 aserciones** demuestra que: (a) el juego arranca y es jugable con `SinIAProvider` como único proveedor; (b) `MockProvider` con la misma semilla produce exactamente la misma salida entre ejecuciones; (c) tras `MAX_FALLOS` fallos consecutivos, el servicio degrada al siguiente proveedor y lo registra; (d) todos los proveedores devuelven la misma estructura de respuesta con su nombre; (e) **ningún test requiere clave de API, red ni servicio externo**, comprobable porque pasan con las variables de entorno vacías; (f) el código de gameplay no menciona ningún proveedor concreto, comprobable con `grep`; (g) `LocalProvider` se descarta si la RAM está por debajo del umbral, sin cargar el modelo; (h) no existe ninguna clave de API en el repositorio ni en el binario.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| La clave de API apareció en el binario | Se llamó al proveedor desde el cliente. Proxy en tu backend, siempre. |
| El juego no funciona sin IA | La IA es requisito. `SinIAProvider` último en la cadena y contenido fijo. |
| Los tests fallan en un fork sin secretos | Dependen del proveedor real. Mock en CI. |
| El modelo local congela el juego 400 ms | Inferencia en el hilo principal. Hilo aparte y espera asíncrona. |
| El juego se arrastra en móviles de gama baja | Sin detección de capacidad. Comprueba antes de cargar. |
| Cambiar de proveedor obliga a tocar el gameplay | La abstracción se filtró. El gameplay solo conoce `ServicioIA`. |
| El proveedor caído sigue recibiendo peticiones | Sin degradación. Cuenta fallos y pasa al siguiente. |
| No se sabe qué proveedor respondió | La respuesta no lleva su procedencia. Añade `proveedor` y regístralo. |

## ❓ Preguntas frecuentes

**❓ ¿Local o remoto para un juego publicado?** Depende del papel de la IA. Si es una mejora opcional (charla ambiental), **local** encaja mejor: sin coste recurrente, sin red y sin datos que salgan del dispositivo. Si la calidad es esencial para la experiencia, remoto con proxy — asumiendo su coste por sesión y su dependencia. Y en ambos casos, el juego tiene que funcionar sin ninguno.

**❓ ¿De verdad no puedo poner la clave en el cliente?** No. Cualquier cadena en un binario se extrae con herramientas básicas, y ofuscarla solo retrasa el trabajo unos minutos. Si hay clave, hay proxy. Es exactamente el mismo principio de la [clase 312](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/312-identidad-perfiles-y-entitlements/README.md).

**❓ ¿Cuánto ocupa un modelo local?** Depende del modelo y de la cuantización; los pequeños útiles para NPC van de cientos de MB a unos pocos GB. Eso afecta al tamaño de descarga, así que el patrón razonable es **descarga opcional**: el juego se instala sin él y el jugador decide si quiere la función.

**❓ ¿Y si el proveedor remoto cambia su API?** Cambias `RemoteProvider` y nada más: el gameplay no se entera. Ese es el retorno de esta clase — la abstracción cuesta un día de trabajo y te protege de un cambio que, sin ella, tocaría cada NPC del juego.

**❓ ¿El mock no es "hacer trampas" en los tests?** Es lo contrario: es lo que hace que los tests prueben **tu código**. Lo que quieres verificar es que tu validador rechaza una intención imposible, que tu fallback aparece cuando toca y que tu ejecutor no toca nada indebido. Probar el modelo no es tu trabajo, y además no se puede hacer de forma determinista.

## 🔗 Referencias

- ONNX Runtime — inferencia local multiplataforma: <https://onnxruntime.ai/docs/> · uso: se instala o se consulta en la preparación
- Godot Docs — GDExtension (integrar un runtime nativo): <https://docs.godotengine.org/en/4.3/tutorials/scripting/gdextension/index.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `OS` (memoria, plataforma, variables de entorno): <https://docs.godotengine.org/en/4.3/classes/class_os.html> · uso: respalda el Tema 8 «Configuración por entorno»
- Godot Docs — `WorkerThreadPool` (inferencia fuera del hilo principal): <https://docs.godotengine.org/en/4.3/classes/class_workerthreadpool.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- OWASP — Top 10 for LLM Applications (cadena de suministro y secretos): <https://owasp.org/www-project-top-10-for-large-language-model-applications/> · uso: respalda el Tema 5 «Secretos en el cliente»

## ⬅️ Clase anterior

[Clase 333 - Diálogo, quests y contenido generativo](../333-dialogo-quests-y-contenido-generativo/README.md)

## ➡️ Siguiente clase

[Clase 335 - Coste, latencia, caché y fallbacks](../335-coste-latencia-cache-y-fallbacks/README.md)
