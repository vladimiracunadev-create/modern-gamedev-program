# Clase 311 — Arquitectura backend para videojuegos

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *Google, «Site Reliability Engineering» · Charlas de GDC sobre backends de juegos*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender **qué piezas componen el backend de un juego**, qué responsabilidad tiene cada una y —lo más importante— **dónde vive la autoridad de cada dato**. La [clase 152](../../parte-7-multijugador-y-networking/152-backends-nakama-steam-y-servicios-gestionados/README.md) presentó los servicios gestionados que puedes contratar; esta clase enseña la arquitectura que hay detrás, para que sepas qué estás contratando, qué puedes sustituir y qué tienes que construir tú.

Aprenderás a distinguir los cuatro caminos por los que viaja la información de un juego online (el HTTP de perfil y tienda, el tiempo real del gameplay, el CDN de contenido y la cola de analítica), por qué tienen requisitos incompatibles entre sí, y cómo diseñar un **cliente que degrada con elegancia**: que funciona sin conexión, que reintenta con criterio y que nunca se queda colgado porque un servicio tardó dos segundos de más.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Dibujar la arquitectura de referencia de un backend de juego con sus componentes.
2. Clasificar cada dato del juego según **dónde está su autoridad** y justificarlo.
3. Distinguir los cuatro planos de comunicación y sus requisitos de latencia y fiabilidad.
4. Diseñar una capa cliente con timeouts, reintentos con backoff y circuit breaker.
5. Implementar degradación elegante: qué hace el juego cuando el backend no responde.
6. Decidir entre servicio gestionado y construcción propia con criterios explícitos.
7. Estimar coste y escala a partir de jugadores concurrentes y peticiones por sesión.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Arquitectura de referencia | Da un mapa donde colocar cada decisión posterior. |
| 2 | Autoridad del dato | Es **la** decisión de seguridad de todo el sistema. |
| 3 | Los cuatro planos | Perfil, tiempo real, contenido y analítica no se parecen en nada. |
| 4 | API gateway | Punto único de entrada: autenticación, límites y versión. |
| 5 | Servidores dedicados | Dónde corre la simulación autoritativa y qué cuesta. |
| 6 | Almacenamiento | Base de datos, caché y almacenamiento de objetos: tres cosas distintas. |
| 7 | Timeouts y reintentos | Sin ellos, un servicio lento cuelga el juego entero. |
| 8 | Circuit breaker | Deja de golpear lo que está caído y se recupera solo. |
| 9 | Degradación elegante | Un backend caído no debe ser un juego caído. |
| 10 | Gestionado vs propio | Criterios para decidir, no ideología. |

## 📖 Definiciones y características

- **Backend de juego**: conjunto de servicios que respaldan al cliente (cuentas, progreso, tienda, partidas, telemetría). Clave: no es "un servidor", son varios sistemas con requisitos distintos.
- **Autoridad del dato**: quién decide el valor correcto de un dato. Clave: si es el cliente, el jugador puede cambiarlo.
- **Cliente ligero (thin client)**: cliente que presenta y predice, pero no decide. Clave: es el modelo obligatorio en cuanto haya economía o competición.
- **API gateway**: punto de entrada único que autentica, limita y enruta las peticiones. Clave: concentra las políticas transversales en un sitio.
- **Servicio de perfil**: guarda identidad, progreso, inventario y entitlements. Clave: es la autoridad de todo lo persistente.
- **Servidor dedicado**: proceso que simula la partida de forma autoritativa. Clave: es lo más caro de operar y lo más sensible a la latencia.
- **Matchmaking**: servicio que agrupa jugadores en partidas. Clave: mezcla cola, criterios de emparejamiento y asignación de servidor.
- **Caché**: almacén rápido de datos leídos con frecuencia. Clave: reduce coste y latencia, e introduce el problema de la invalidación.
- **Almacenamiento de objetos**: sistema para archivos grandes (assets, parches, capturas). Clave: barato por GB y servido por CDN.
- **CDN**: red de distribución que sirve contenido desde el nodo más cercano. Clave: imprescindible para descargas y parches.
- **Cola de eventos**: buffer entre el juego y el análisis de datos. Clave: absorbe picos y desacopla la ingesta del procesamiento.
- **Timeout**: tiempo máximo de espera de una respuesta. Clave: sin timeout, un servicio lento se convierte en un cuelgue.
- **Reintento con backoff exponencial**: reintentar esperando cada vez más. Clave: sin él, mil clientes reintentando tumban el servicio que intentaban usar.
- **Jitter**: aleatoriedad añadida al backoff. Clave: evita que todos los clientes reintenten a la vez (efecto manada).
- **Circuit breaker**: mecanismo que deja de llamar a un servicio que falla y prueba de vez en cuando. Clave: protege al servicio y da respuesta inmediata al cliente.
- **Degradación elegante**: seguir funcionando con capacidades reducidas cuando algo falla. Clave: es una decisión de diseño, no un efecto secundario.
- **CCU (concurrent users)**: jugadores simultáneos. Clave: es la unidad con la que se dimensiona y se factura casi todo.

## 🧰 Herramientas y preparación

No hace falta contratar nada: trabajaremos con un **backend simulado** en el propio proyecto Godot, que es lo que después usará la CI. Necesitarás `HTTPRequest` para la parte real y el patrón de proveedor que construiremos aquí. Documentación: [`HTTPRequest`](https://docs.godotengine.org/en/stable/classes/class_httprequest.html) y [`HTTPClient`](https://docs.godotengine.org/en/stable/classes/class_httpclient.html). Conviene tener a mano la clase [151](../../parte-7-multijugador-y-networking/151-servidores-dedicados-headless-y-despliegue/README.md) sobre servidores dedicados headless.

## 🧪 Laboratorio guiado

1. **La arquitectura de referencia.** Memorízala: casi todos los backends de juego son una variante de esto.

```text
                        ┌──────────────┐
     ┌──────────────────│  API Gateway │─────────────────┐
     │  HTTPS           └──────┬───────┘  auth, límites  │
     │                         │           versión       │
┌────┴─────┐          ┌────────┼─────────┐         ┌─────┴──────┐
│  CLIENTE │          │ Perfil │ Tienda  │         │ Matchmaking│
│  (juego) │          │ Saves  │ Economía│         └─────┬──────┘
└──┬───┬───┘          └────────┼─────────┘               │ asigna
   │   │                       │                    ┌────┴────────┐
   │   │  UDP tiempo real      │              ┌─────┤ Servidores  │
   │   └───────────────────────┼──────────────┘     │ dedicados   │
   │                           │                    └─────────────┘
   │   HTTPS descargas    ┌────┴─────┐  ┌───────┐
   ├──────────────────────┤   CDN    │  │ Caché │
   │                      └──────────┘  └───┬───┘
   │   eventos (batch)                      │
   └──────────────────►┌──────────┐    ┌────┴─────┐
                       │ Cola de  │───►│   Base   │
                       │ eventos  │    │ de datos │
                       └────┬─────┘    └──────────┘
                            │
                       ┌────┴─────┐
                       │ Analítica│
                       └──────────┘
```

2. **La tabla de autoridad.** Es el primer documento que hay que escribir de un juego online, antes de una línea de código:

| Dato | Autoridad | Por qué |
|---|---|---|
| Posición del jugador en partida | Servidor dedicado | Si la decide el cliente, hay teletransporte |
| Ajustes de vídeo y volumen | Cliente | No afecta a nadie más |
| Oro, inventario, nivel | Servicio de perfil | Es economía: el cliente mentiría |
| Rebinding de teclas | Cliente | Preferencia local |
| Progreso de logros | Perfil (validado) | Se presume, se verifica |
| Semilla de un run | Servidor | Si la elige el cliente, elige su loot |
| Elección de idioma | Cliente | Preferencia local |
| Resultado de una partida clasificatoria | Servidor | Determina el ranking |
| Capturas de pantalla | Cliente + almacenamiento | Contenido, no estado |

La regla, dicha de una vez: **si dos jugadores pueden discrepar sobre un dato y eso importa, la autoridad no puede estar en el cliente**.

3. **Los cuatro planos.** Tienen requisitos incompatibles, y por eso son cuatro sistemas y no uno:

| Plano | Transporte | Latencia | Volumen | Si falla |
|---|---|---|---|---|
| Perfil / tienda | HTTPS petición-respuesta | 100–500 ms aceptable | Bajo | Modo offline |
| Tiempo real | UDP con fiabilidad propia | < 50 ms deseable | Alto y constante | No hay partida |
| Contenido / parches | HTTPS + CDN | Irrelevante | Enorme | No se actualiza |
| Analítica | HTTPS por lotes | Minutos aceptable | Medio | Se pierden datos, no la partida |

4. **El cliente resiliente.** Empieza por el contrato, no por la implementación:

```gdscript
class_name ProveedorBackend
extends RefCounted

# Toda respuesta lleva su origen: el juego debe poder decir "esto es del
# servidor" o "esto es lo último que sé". Un valor sin procedencia es una
# fuente de bugs invisibles.
class Respuesta extends RefCounted:
	var ok: bool = false
	var datos: Dictionary = {}
	var codigo: int = 0
	var origen: String = "red"        # "red" | "cache" | "defecto"
	var error: String = ""

func obtener_perfil(id: StringName) -> Respuesta:
	push_error("no implementado"); return Respuesta.new()

func guardar_progreso(id: StringName, datos: Dictionary) -> Respuesta:
	push_error("no implementado"); return Respuesta.new()
```

5. **Timeouts, reintentos y backoff.** Las tres piezas que evitan el 90 % de los cuelgues:

```gdscript
class_name ClienteHttp
extends Node

const TIMEOUT := 8.0
const MAX_INTENTOS := 3
const BASE_BACKOFF := 0.5

var _rng := RandomNumberGenerator.new()

func pedir(url: String, cuerpo: Dictionary, idempotente: bool) -> ProveedorBackend.Respuesta:
	var r := ProveedorBackend.Respuesta.new()
	# Solo se reintenta lo IDEMPOTENTE. Reintentar "cómprame esto" puede
	# cobrar dos veces; reintentar "dame mi perfil" no puede hacer daño.
	var intentos := MAX_INTENTOS if idempotente else 1

	for intento in intentos:
		var req := HTTPRequest.new()
		add_child(req)
		req.timeout = TIMEOUT
		req.request(url, [], HTTPClient.METHOD_POST, JSON.stringify(cuerpo))
		var res: Array = await req.request_completed
		req.queue_free()

		var resultado := int(res[0])       # Result enum de HTTPRequest
		var codigo := int(res[1])
		if resultado == HTTPRequest.RESULT_SUCCESS and codigo >= 200 and codigo < 300:
			r.ok = true
			r.codigo = codigo
			r.datos = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8()) or {}
			return r

		# 4xx (salvo 429) es culpa nuestra: reintentar da el mismo error.
		if codigo >= 400 and codigo < 500 and codigo != 429:
			r.codigo = codigo
			r.error = "petición rechazada (%d)" % codigo
			return r

		if intento < intentos - 1:
			# Backoff exponencial CON JITTER: sin el jitter, mil clientes que
			# fallan a la vez reintentan a la vez y rematan el servicio.
			var espera := BASE_BACKOFF * pow(2.0, intento)
			espera += _rng.randf() * espera * 0.5
			await get_tree().create_timer(espera).timeout

	r.error = "sin respuesta tras %d intento(s)" % intentos
	return r
```

6. **Circuit breaker.** Cuando algo está caído, dejar de llamarlo es mejor para todos:

```gdscript
class_name Interruptor
extends RefCounted

enum Estado { CERRADO, ABIERTO, SEMIABIERTO }

var umbral_fallos := 5
var espera_reintento := 30.0

var _estado: Estado = Estado.CERRADO
var _fallos := 0
var _abierto_desde := 0.0

func permite(ahora: float) -> bool:
	match _estado:
		Estado.CERRADO:
			return true
		Estado.ABIERTO:
			if ahora - _abierto_desde >= espera_reintento:
				_estado = Estado.SEMIABIERTO     # dejamos pasar UNA para tantear
				return true
			return false
		_:
			return true

func exito() -> void:
	_estado = Estado.CERRADO
	_fallos = 0

func fallo(ahora: float) -> void:
	_fallos += 1
	if _estado == Estado.SEMIABIERTO or _fallos >= umbral_fallos:
		_estado = Estado.ABIERTO
		_abierto_desde = ahora
```

7. **Degradación elegante.** La tabla que hay que escribir **antes** de que falle nada:

```gdscript
class_name Backend
extends RefCounted

var _proveedor: ProveedorBackend
var _cache := {}
var _interruptor := Interruptor.new()
var _cola_pendientes: Array[Dictionary] = []

func obtener_perfil(id: StringName, ahora: float) -> ProveedorBackend.Respuesta:
	if not _interruptor.permite(ahora):
		return _de_cache(id)                      # respuesta inmediata, sin esperar
	var r := _proveedor.obtener_perfil(id)
	if r.ok:
		_interruptor.exito()
		_cache[id] = r.datos
		return r
	_interruptor.fallo(ahora)
	return _de_cache(id)

func _de_cache(id: StringName) -> ProveedorBackend.Respuesta:
	var r := ProveedorBackend.Respuesta.new()
	if _cache.has(id):
		r.ok = true; r.datos = _cache[id]; r.origen = "cache"
	else:
		r.ok = true; r.datos = _perfil_por_defecto(); r.origen = "defecto"
	return r

func guardar_progreso(id: StringName, datos: Dictionary, ahora: float) -> bool:
	if not _interruptor.permite(ahora):
		_cola_pendientes.append({"id": id, "datos": datos})   # se enviará al volver
		return false
	var r := _proveedor.guardar_progreso(id, datos)
	if r.ok:
		_interruptor.exito()
		return true
	_interruptor.fallo(ahora)
	_cola_pendientes.append({"id": id, "datos": datos})
	return false
```

| Servicio caído | El juego debe… | Nunca debe… |
|---|---|---|
| Perfil | Usar caché local y encolar escrituras | Impedir jugar en single-player |
| Tienda | Ocultar la tienda con un aviso | Mostrar precios de hace una semana como actuales |
| Matchmaking | Ofrecer modo local o reintentar en segundo plano | Quedarse en "buscando" para siempre |
| Remote config | Usar los valores por defecto compilados | Quedarse en la pantalla de carga |
| Telemetría | Encolar en disco y descartar lo viejo | Bloquear un solo frame |

8. **Estimar escala y coste.** Con dos cuentas se evita la mayoría de sustos:

```text
Peticiones/s ≈ CCU × peticiones_por_sesión / duración_sesión_segundos

10.000 CCU × 40 peticiones / 1.800 s ≈ 222 req/s   → un servicio pequeño basta
Ancho de banda tiempo real ≈ CCU × tasa_envío × tamaño_paquete
10.000 × 30/s × 120 B ≈ 36 MB/s ≈ 288 Mbps         → esto sí cuesta dinero
```

La conclusión típica sorprende: **el plano HTTP casi nunca es el problema; el tiempo real y el ancho de banda, sí**. Por eso los servidores dedicados son la partida de coste que hay que dimensionar primero.

## ✍️ Ejercicios

1. Escribe la tabla de autoridad completa de tu propio juego, dato por dato.
2. Implementa el `Interruptor` y escribe un test que compruebe las tres transiciones de estado.
3. Añade jitter al backoff y simula 1.000 clientes reintentando: compara la distribución con y sin jitter.
4. Implementa la cola de escrituras pendientes con persistencia en `user://` y reenvío al recuperar conexión.
5. Diseña la degradación de cada pantalla de tu juego en una tabla como la del paso 7.
6. Estima peticiones por segundo y ancho de banda para 1.000, 10.000 y 100.000 CCU de tu juego.
7. Compara el coste de un servicio gestionado frente a construirlo, incluyendo tiempo de desarrollo y operación.

## 📝 Reto verificable

Implementa una capa de backend con `ProveedorBackend` (interfaz), un `MockBackend` determinista que pueda simular latencia, errores 5xx y caídas totales, timeouts, reintentos con backoff y jitter para operaciones idempotentes, circuit breaker y degradación con caché y cola de pendientes.

**Criterio de aceptación**: una prueba headless con **al menos 15 aserciones** demuestra que: (a) una operación idempotente que falla dos veces y acierta a la tercera devuelve `ok` y registra 3 intentos; (b) una operación **no** idempotente que falla se intenta exactamente una vez; (c) un 404 no se reintenta y un 429 sí; (d) tras 5 fallos consecutivos el interruptor queda `ABIERTO` y las llamadas siguientes devuelven de caché **sin llamar al proveedor** (comprobable con un contador); (e) pasado el tiempo de espera, el interruptor pasa a `SEMIABIERTO` y una respuesta correcta lo cierra; (f) con el backend caído, `obtener_perfil` devuelve `origen == "cache"` o `"defecto"` y nunca falla; (g) las escrituras hechas offline se encolan y se reenvían en orden al recuperar.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El juego se queda congelado al perder la conexión | Falta timeout, o se espera de forma bloqueante. Timeout siempre y llamadas asíncronas. |
| Al volver el servicio, se cae otra vez | Efecto manada: todos reintentan a la vez. Backoff exponencial con jitter. |
| Un jugador compró dos veces por un reintento | Se reintentó una operación no idempotente. Reintenta solo lo seguro (y ver clase 314). |
| El cliente muestra oro que no tiene | El cliente es autoridad de la economía. La autoridad va al servidor. |
| La telemetría hace tirones | Se envía en el hilo principal y sin lotes. Encola, agrupa y envía en segundo plano. |
| El juego no arranca si el backend está caído | No hay valores por defecto. Compila defaults seguros y úsalos. |
| Se reintenta un 400 mil veces | No se distingue error de cliente de error de servidor. 4xx no se reintenta (salvo 429). |
| La caché sirve datos viejos como si fueran actuales | No se marca el origen. Devuelve `origen` y muéstralo en la UI cuando importe. |

## ❓ Preguntas frecuentes

**❓ ¿Necesito backend si mi juego es single-player?** Para jugar, no. Pero en cuanto quieras cloud saves, logros verificados, remote config o telemetría, ya tienes backend — aunque sea el de la plataforma. Y conviene diseñarlo con esta arquitectura desde el principio, porque añadir "autoridad de servidor" después obliga a rehacer sistemas enteros.

**❓ ¿Gestionado o propio?** Gestionado por defecto: el coste de operar identidad, saves y matchmaking 24/7 es enorme y no diferencia tu juego. Construye tú lo que sea **núcleo de tu propuesta** (un sistema de emparejamiento muy particular, una simulación autoritativa específica). El criterio no es técnico, es de dónde quieres gastar el tiempo de tu equipo.

**❓ ¿Por qué separar los cuatro planos?** Porque optimizar para uno perjudica a los otros: TCP fiable arruina el tiempo real, y UDP sin garantías no sirve para una compra. Meterlo todo en un servicio "porque es más simple" acaba en un sistema que no cumple ninguno de sus requisitos.

**❓ ¿Cómo pruebo esto sin backend real?** Con el `MockBackend` determinista de esta clase, que es lo que se usará en el capstone y en la CI. Puedes simular latencia, errores y caídas de forma reproducible — algo que un backend real **no** te deja hacer fácilmente.

**❓ ¿Y si uso Nakama, PlayFab o los servicios de Steam?** Perfecto: te dan la mayor parte de esta arquitectura hecha. Lo que esta clase te aporta es saber **qué te están dando**, qué sigue siendo responsabilidad tuya (la tabla de autoridad, la degradación, los timeouts en tu cliente) y cómo migrar si algún día cambias de proveedor.

## 🔗 Referencias

- Google — *Site Reliability Engineering*, capítulos de manejo de sobrecarga y cascadas de fallos: <https://sre.google/books/>
- Godot Docs — `HTTPRequest`: <https://docs.godotengine.org/en/stable/classes/class_httprequest.html>
- Godot Docs — `HTTPClient`: <https://docs.godotengine.org/en/stable/classes/class_httpclient.html>
- AWS — Exponential backoff and jitter (explicación clásica del patrón): <https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/>
- Martin Fowler — Circuit Breaker: <https://martinfowler.com/bliki/CircuitBreaker.html>
- GDC Vault — charlas sobre arquitectura de backends de juegos y LiveOps: <https://www.gdcvault.com/>

## ⬅️ Clase anterior

[Clase 310 - Capstone Parte 18: un juego sistémico](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/310-capstone-parte-18-un-juego-sistemico/README.md)

## ➡️ Siguiente clase

[Clase 312 - Identidad, perfiles y entitlements](../312-identidad-perfiles-y-entitlements/README.md)
