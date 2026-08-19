# Clase 324 — Capstone Parte 19: un runtime de producción

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *Integración de las clases 311–323 · Laboratorio `labs/production-runtime/`*
> ⏱️ Duración estimada: **8–12 h** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir el **runtime de producción** de un juego: la capa que lo conecta con el mundo real y lo mantiene funcionando cuando ese mundo falla. No es un juego: es todo lo que rodea a un juego para que pueda operarse — cliente con degradación, backend simulado, configuración remota, feature flags, telemetría gobernada, observabilidad, save versionado, reintentos y recuperación.

Y hay un requisito que define el capstone: **funciona entero en CI, sin red, sin claves de API, sin servicios de pago y de forma determinista**. Todo lo remoto está detrás de un `MockBackend` que puede simular latencia, errores, caídas y respuestas malformadas a voluntad. Eso no es una simplificación para el ejercicio: es exactamente como se prueban estos sistemas en la industria, porque un backend real no te deja provocar una caída del 100 % a las tres de la tarde.

El laboratorio [`labs/production-runtime/`](../../../labs/production-runtime/README.md) contiene la versión `inicio/` con los `TODO` y la `solucion/` de referencia.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Integrar backend, configuración, telemetría, observabilidad y guardado en un runtime coherente.
2. Diseñar un mock determinista capaz de simular todos los modos de fallo relevantes.
3. Demostrar con pruebas que el juego funciona **completamente offline**.
4. Demostrar degradación elegante subsistema por subsistema.
5. Verificar en CI el esquema de telemetría y la compatibilidad de saves.
6. Presentar el runtime como pieza de portfolio de ingeniería.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Composition root del runtime | Las dependencias se ven en un sitio o no se ven. |
| 2 | Mock determinista | Sin él no se pueden probar los fallos. |
| 3 | Matriz de modos de fallo | Cada combinación es un caso a demostrar. |
| 4 | Offline total | Es el requisito más revelador del diseño. |
| 5 | Verificación de esquema | La telemetría es un contrato y se prueba como tal. |
| 6 | Compatibilidad de saves | Una migración sin test es una esperanza. |
| 7 | CI sin secretos | Un test que necesita una clave no corre en un fork. |
| 8 | Documentación operativa | Un runtime sin runbook no se puede operar. |

## 📖 Definiciones y características

- **Runtime de producción**: capa que conecta el juego con servicios externos y gestiona sus fallos. Clave: es infraestructura, no gameplay.
- **Mock determinista**: implementación falsa cuyo comportamiento depende solo de su configuración y su semilla. Clave: reproducible, y por eso testeable.
- **Modo de fallo**: forma concreta en que algo puede romperse (lento, error, caído, respuesta corrupta). Clave: se enumeran y se prueban uno a uno.
- **Prueba de caos**: introducir fallos a propósito para comprobar la respuesta. Clave: aquí es determinista, con semilla y sin sorpresas.
- **Offline total**: el juego arranca y se juega sin ninguna conexión. Clave: es la prueba de fuego de la arquitectura.
- **Contrato de telemetría**: taxonomía y esquema que la CI verifica. Clave: convierte la gobernanza en algo automático.
- **Prueba de migración**: cargar saves de versiones antiguas y comprobar el resultado. Clave: son los tests que evitan perder partidas.
- **Runbook**: guion de respuesta a incidentes. Clave: forma parte del entregable.

## 🧰 Herramientas y preparación

Godot 4.3 o superior. Parte de [`labs/production-runtime/inicio/`](../../../labs/production-runtime/README.md). Necesitas haber recorrido las clases 311 a 323; este capstone las integra sin introducir conceptos nuevos. No hace falta ninguna cuenta, ninguna clave ni ningún servicio: si algo del proyecto pide credenciales, es que está mal planteado.

## 🧪 Laboratorio guiado

1. **La estructura:**

```text
res://
  infraestructura/
    backend/        proveedor.gd  mock_backend.gd  cliente_http.gd  interruptor.gd
    config/         config.gd  esquema.gd  flags.gd
    observabilidad/ log.gd  metricas.gd  traza.gd  crash.gd
    telemetria/     telemetria.gd  consentimiento.gd  retencion.gd
    guardado/       guardado.gd  migraciones.gd  sincronizador.gd
  datos/            taxonomia.json  presupuestos.json  config_defecto.json
  pruebas/          offline_test.gd  degradacion_test.gd  telemetria_test.gd
                    migraciones_test.gd  caos_test.gd
  runtime.gd        composition root
docs/
  runbooks/         subida_de_crashes.md  backend_caido.md
  postmortem-ejemplo.md
```

2. **El mock, con todos sus modos de fallo.** Es la pieza que hace posible el resto:

```gdscript
class_name MockBackend
extends ProveedorBackend

enum Modo { NORMAL, LENTO, ERROR_5XX, ERROR_4XX, CAIDO, CORRUPTO, INTERMITENTE }

var modo: Modo = Modo.NORMAL
var latencia_ms := 0.0
var probabilidad_fallo := 0.0
var llamadas := 0                 # contador: para probar reintentos y circuit breaker
var _rng := RandomNumberGenerator.new()

func _init(semilla := 1234) -> void:
	_rng.seed = semilla           # determinista: el mismo test da el mismo resultado

func obtener_perfil(id: StringName) -> Respuesta:
	llamadas += 1
	var r := Respuesta.new()
	match modo:
		Modo.CAIDO:
			r.ok = false; r.error = "sin conexión"; return r
		Modo.ERROR_5XX:
			r.ok = false; r.codigo = 503; return r
		Modo.ERROR_4XX:
			r.ok = false; r.codigo = 404; return r
		Modo.CORRUPTO:
			# El modo que más bugs descubre: una respuesta 200 con basura dentro.
			r.ok = true; r.datos = {"perfil": "<<esto no es un perfil>>"}; return r
		Modo.INTERMITENTE:
			if _rng.randf() < probabilidad_fallo:
				r.ok = false; r.codigo = 503; return r
		_:
			pass
	r.ok = true
	r.datos = {"player_id": String(id), "nivel": 12, "oro": 340}
	return r
```

3. **El composition root del runtime.** Con la degradación decidida de antemano:

```gdscript
extends Node

var servicios := Servicios.new()

func _ready() -> void:
	# 1) OBSERVABILIDAD primero: si algo falla después, queremos verlo.
	Log._sinks = [SinkArchivo.new("user://logs"), SinkMock.new()]
	Log.contexto("build", Version.cadena())
	Log.contexto("plataforma", OS.get_name())

	# 2) CONFIGURACIÓN con defectos compilados. El juego ya puede funcionar.
	var cfg := Config.new()
	var flags := Flags.new()

	# 3) TELEMETRÍA gobernada por el consentimiento.
	var consent := Consentimiento.new()
	var tel := Telemetria.nueva(consent, "res://datos/taxonomia.json")

	# 4) BACKEND: proveedor real o mock, según el arranque. El resto del juego
	#    no sabe cuál es, y ese es el objetivo.
	var proveedor: ProveedorBackend = _elegir_proveedor()
	var backend := Backend.new(proveedor)

	# 5) GUARDADO local, siempre disponible; nube, si se puede.
	var guardado := Guardado.new()
	var sinc := Sincronizador.new(backend, guardado)

	# 6) Sincronización remota SIN bloquear. Si falla, no pasa nada: seguimos
	#    con los defectos y la caché.
	_sincronizar_en_segundo_plano(backend, cfg, flags, tel)

	for par in [["cfg", cfg], ["flags", flags], ["tel", tel], ["backend", backend],
				["guardado", guardado], ["sinc", sinc], ["consent", consent]]:
		servicios.registrar(StringName(par[0]), par[1])

	$Juego.setup(servicios)
	print("Runtime construido: %d flags, %d claves de config, modo %s" %
		[flags.total(), cfg.total(), _modo_actual()])
```

4. **La matriz de degradación.** Lo que el capstone debe demostrar, caso por caso:

| Subsistema | Backend OK | Backend lento | Backend 5xx | Backend caído | Respuesta corrupta |
|---|---|---|---|---|---|
| Config | Remota | Remota (asíncrona) | Defectos | Caché o defectos | Defectos + log |
| Flags | Remotos | Remotos | Defectos (apagados) | Defectos | Defectos + log |
| Perfil | Del servidor | Del servidor | Caché | Caché o defecto | Caché + log |
| Cloud save | Sincroniza | Sincroniza | Cola pendiente | Solo local | Solo local + log |
| Telemetría | Envía | Encola | Encola | Encola en disco | Descarta el lote |
| Juego | Normal | Normal | **Normal** | **Normal** | **Normal** |

La última fila es el examen: **en las cinco columnas el juego se puede jugar**.

5. **La prueba de offline total.** La más importante de todas:

```gdscript
extends SceneTree   # pruebas/offline_test.gd

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	var mock := MockBackend.new(42)
	mock.modo = MockBackend.Modo.CAIDO          # sin red desde el primer instante
	var rt := Runtime.nuevo(mock)

	check.call(rt.arranco_correctamente(), "el runtime arranca sin conexión")
	check.call(rt.cfg.get_float("multiplicador_xp") == 1.0, "config usa los defectos")
	check.call(not rt.flags.activo("cualquiera"), "los flags desconocidos están apagados")
	check.call(rt.guardado.guardar(0, {"nivel": 3}), "guardar en local funciona sin red")
	check.call(rt.guardado.cargar(0), "cargar en local funciona sin red")
	check.call(rt.tel.registrar("sesion_iniciada",
		{"plataforma": "linux", "build": "test", "primera_vez": true}),
		"la telemetría esencial se encola sin red")
	check.call(rt.tel.pendientes() > 0, "los eventos quedan en cola, no se pierden")
	check.call(rt.puede_jugar(), "SE PUEDE JUGAR sin conexión")

	# Y al volver la red, lo pendiente se envía.
	mock.modo = MockBackend.Modo.NORMAL
	rt.sincronizar()
	check.call(rt.tel.pendientes() == 0, "la cola se vacía al recuperar la conexión")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

6. **La prueba de caos determinista.** Recorre la matriz entera:

```gdscript
extends SceneTree   # pruebas/caos_test.gd

const MODOS := [MockBackend.Modo.NORMAL, MockBackend.Modo.LENTO,
				MockBackend.Modo.ERROR_5XX, MockBackend.Modo.ERROR_4XX,
				MockBackend.Modo.CAIDO, MockBackend.Modo.CORRUPTO,
				MockBackend.Modo.INTERMITENTE]

func _init() -> void:
	var hechas := 0; var fallos := 0
	for modo in MODOS:
		var mock := MockBackend.new(7)
		mock.modo = modo
		mock.probabilidad_fallo = 0.5
		var rt := Runtime.nuevo(mock)

		# En TODOS los modos, sin excepción:
		hechas += 4
		if not rt.arranco_correctamente(): fallos += 1; printerr("  no arranca en modo ", modo)
		if not rt.puede_jugar():           fallos += 1; printerr("  no se puede jugar en modo ", modo)
		if not rt.guardado.guardar(0, {}): fallos += 1; printerr("  no guarda en modo ", modo)
		if rt.hubo_excepcion():            fallos += 1; printerr("  excepción no controlada en modo ", modo)

		# Y en los modos de fallo, el circuit breaker debe abrirse en vez de
		# seguir golpeando un servicio que no responde.
		if modo in [MockBackend.Modo.CAIDO, MockBackend.Modo.ERROR_5XX]:
			hechas += 1
			for i in 20:
				rt.backend.obtener_perfil(&"plr", float(i))
			if mock.llamadas > 8:
				fallos += 1
				printerr("  el interruptor no cortó: %d llamadas a un servicio caído" % mock.llamadas)

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

7. **Las pruebas de contrato.** Telemetría y saves, verificadas en CI:

```gdscript
# pruebas/telemetria_test.gd — el esquema es un contrato y se comprueba.
func _comprobar_taxonomia() -> int:
	var fallos := 0
	var tax = JSON.parse_string(FileAccess.open(
		"res://datos/taxonomia.json", FileAccess.READ).get_as_text())
	for nombre in tax["eventos"]:
		var e: Dictionary = tax["eventos"][nombre]
		if not e.has("v"):        fallos += 1; printerr("  ", nombre, ": sin versión")
		if not e.has("pregunta"): fallos += 1; printerr("  ", nombre, ": sin pregunta que justifique su existencia")
		if not e.has("consentimiento"): fallos += 1; printerr("  ", nombre, ": sin categoría de consentimiento")
		for campo in e.get("campos", {}):
			if str(campo).to_lower() in Telemetria.PROHIBIDOS:
				fallos += 1; printerr("  ", nombre, ": campo prohibido en el esquema: ", campo)
	return fallos
```

```gdscript
# pruebas/migraciones_test.gd — saves de cada versión antigua, guardados como
# fixtures. Cada uno es un seguro contra perder partidas de jugadores reales.
func _init() -> void:
	var hechas := 0; var fallos := 0
	for ruta in DirAccess.get_files_at("res://pruebas/saves_antiguos/"):
		hechas += 1
		var d = JSON.parse_string(FileAccess.open(
			"res://pruebas/saves_antiguos/" + ruta, FileAccess.READ).get_as_text())
		var migrado := Guardado.migrar(d)
		if migrado.is_empty():
			fallos += 1; printerr("  no migra: ", ruta); continue
		if int(migrado["version"]) != Guardado.SAVE_VERSION:
			fallos += 1; printerr("  versión incorrecta tras migrar: ", ruta); continue
		for clave in ["progresion", "inventario", "monedero"]:
			if not migrado["datos"].has(clave):
				fallos += 1; printerr("  falta '%s' tras migrar %s" % [clave, ruta])
	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

8. **En CI.** Todo offline, sin secretos, determinista:

```yaml
  production-runtime:
    name: Runtime de producción
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Instalar Godot
        run: bash scripts/instalar_godot.sh
      - name: Importar
        run: godot --headless --path labs/production-runtime/solucion --import
      - name: Pruebas del runtime
        run: |
          set -euo pipefail
          # Ninguna necesita red, ni claves, ni servicios: por eso funcionan
          # también en un fork y en una máquina sin acceso a internet.
          for t in offline degradacion caos telemetria migraciones; do
            echo "--- $t ---"
            godot --headless --path labs/production-runtime/solucion \
                  --script "res://pruebas/${t}_test.gd"
          done
```

## ✍️ Ejercicios

1. Añade un modo de fallo nuevo al mock (respuesta que tarda más que el timeout) y comprueba la respuesta.
2. Añade una migración de save real y su fixture correspondiente.
3. Implementa la pantalla de estado que muestra qué subsistemas están degradados.
4. Añade un flag que active una función y comprueba el kill switch de punta a punta.
5. Mide cuántas llamadas hace tu cliente a un servicio caído en 60 s con y sin circuit breaker.
6. Añade un runbook para "la cola de telemetría no se vacía".
7. Escribe el postmortem de un incidente simulado usando tu propio sistema.

## 📝 Reto verificable

Entrega un proyecto Godot ejecutable con el runtime completo: cliente con timeouts, reintentos, backoff con jitter y circuit breaker; `MockBackend` determinista con **al menos seis modos de fallo**; configuración remota con esquema y defectos; feature flags con rollout y kill switch; telemetría con taxonomía, lista blanca y consentimiento; observabilidad con logs, métricas y trazas; save versionado con **al menos tres migraciones**; sincronización con cola offline; y runbooks documentados.

**Criterio de aceptación**:

1. `godot --headless --path . --quit-after 300` arranca **sin conexión** e imprime `Runtime construido:`.
2. `pruebas/offline_test.gd` demuestra con al menos 8 aserciones que el juego arranca, guarda, carga y se puede jugar sin red, y que la cola se vacía al recuperarla.
3. `pruebas/caos_test.gd` recorre los **seis o más** modos de fallo y demuestra que en todos el juego arranca, se puede jugar, guarda y no lanza excepciones no controladas.
4. El circuit breaker corta tras el umbral: con el backend caído, 20 intentos producen **8 llamadas o menos** al proveedor.
5. `pruebas/telemetria_test.gd` verifica la taxonomía completa y falla si algún evento carece de versión, pregunta o categoría, o si declara un campo prohibido.
6. `pruebas/migraciones_test.gd` carga un fixture por **cada versión antigua** de save y comprueba que todos llegan a la versión actual con sus bloques.
7. Ningún test requiere red, claves de API, secretos ni servicios de pago; todos son deterministas y repiten resultado con la misma semilla.
8. `docs/runbooks/` contiene al menos dos runbooks y un postmortem de ejemplo con acciones, responsables y fechas.
9. El README del proyecto documenta la matriz de degradación completa y cómo ejecutar cada prueba.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Los tests fallan en el CI de un fork | Necesitan secretos. Todo debe correr con el mock. |
| El test de caos da resultados distintos cada vez | El mock no está sembrado. Semilla fija en el constructor. |
| El juego arranca offline pero se queda en la carga | Se espera una respuesta remota. Sincroniza en segundo plano. |
| La cola de telemetría crece sin límite | Sin tope ni persistencia. Acota y descarta lo más viejo. |
| Una respuesta corrupta hace crashear el cliente | No se valida el contenido de un 200. El modo `CORRUPTO` lo detecta. |
| El circuit breaker no corta | Se crea uno nuevo por llamada. Debe vivir en el cliente, no en la petición. |
| La migración funciona pero pierde un bloque | Faltan fixtures de esa versión. Uno por versión publicada. |
| El runtime tiene el composition root repartido | Se conectó desde varios sitios. Centraliza en `runtime.gd`. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué tanto énfasis en el mock?** Porque es lo que hace **posible** probar todo lo demás. Un backend real no te deja simular una caída total, ni una respuesta corrupta, ni un 503 intermitente al 50 %, y desde luego no de forma reproducible. El mock no es una versión pobre del backend: es un instrumento de laboratorio.

**❓ ¿Y cuándo pruebo contra el backend real?** En un entorno de staging, antes de cada release, con un conjunto pequeño de pruebas de humo. Esas pruebas verifican que el **contrato** se cumple (rutas, formatos, códigos); todo el comportamiento ante fallos ya está verificado con el mock.

**❓ ¿No es esto mucho para un juego indie?** Depende de tu juego. Si es completamente offline, te sobra la mitad. Pero el save versionado con migraciones, el logging estructurado y los defectos compilados valen la pena en cualquier proyecto que vaya a recibir más de un parche — y son la parte barata.

**❓ ¿Cómo lo presento en el portfolio?** Como pieza de ingeniería: el README con la matriz de degradación, el badge de CI verde, y una frase que resume el logro — *"el juego arranca, guarda y se juega en los seis modos de fallo del backend, verificado en CI sin red"*. Para un puesto de backend o de ingeniería de plataforma, esto dice más que cualquier demo.

**❓ ¿Puedo reutilizar esto en otros proyectos?** Sí, y es la intención: `infraestructura/` está diseñada para no saber nada de tu juego. Copiar esa carpeta a un proyecto nuevo y registrar sus sistemas en `Guardado` es cuestión de una tarde.

## 🔗 Referencias

- Laboratorio de esta parte — [`labs/production-runtime/`](../../../labs/production-runtime/README.md) · uso: respalda el Tema 1 «Composition root del runtime»
- Google — *Site Reliability Engineering*: <https://sre.google/books/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- OpenTelemetry — modelo de observabilidad: <https://opentelemetry.io/docs/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — Command line tutorial: <https://docs.godotengine.org/en/4.3/tutorials/editor/command_line_tutorial.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Martin Fowler — Circuit Breaker: <https://martinfowler.com/bliki/CircuitBreaker.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- GitHub Docs — Actions: <https://docs.github.com/actions> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 323 - Parches, delivery y recuperación](../323-parches-delivery-y-recuperacion/README.md)

## ➡️ Siguiente clase

[Clase 325 - IA generativa en desarrollo de videojuegos](../../parte-20-ia-generativa-y-desarrollo-asistido-por-ia/325-ia-generativa-en-desarrollo-de-videojuegos/README.md)
