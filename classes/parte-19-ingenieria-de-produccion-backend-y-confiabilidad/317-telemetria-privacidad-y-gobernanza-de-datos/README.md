# Clase 317 — Telemetría, privacidad y gobernanza de datos

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *Reglamento General de Protección de Datos (RGPD) · COPPA · Guías de privacidad de las plataformas*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Diseñar la telemetría de un juego de forma que sea **útil para el equipo y respetuosa con quien juega**. La [clase 278](../../parte-16-produccion-publicacion-monetizacion-y-liveops/278-analitica-de-juego-y-telemetria/README.md) presentó la analítica de producto: qué medir para entender a los jugadores. Esta clase se ocupa de la otra mitad, la que se salta casi todo el mundo hasta que llega un requerimiento legal: **qué datos puedes recoger, con qué base, durante cuánto tiempo, quién accede y cómo se borran**.

Vas a construir una **taxonomía de eventos** con esquema y versión, un emisor con lista blanca de campos que hace estructuralmente imposible enviar datos personales por descuido, un sistema de consentimiento real (no un banner decorativo), seudonimización, retención con borrado automático y el flujo de "quiero que borres mis datos". Y vas a entender por qué esto no es burocracia: un dataset bien gobernado es **más útil** que uno lleno de basura personal que nadie puede tocar por miedo.

> ⚠️ Esta clase explica principios técnicos y de diseño. No es asesoramiento legal: las obligaciones concretas dependen de tu jurisdicción, tu público y tu modelo de negocio. Consulta a un profesional antes de publicar.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diseñar una taxonomía de eventos con nombres estables, esquema y versión.
2. Implementar un emisor con lista blanca que impida enviar campos no declarados.
3. Distinguir dato personal, seudonimizado y anonimizado, y las consecuencias de cada uno.
4. Implementar consentimiento granular que gobierne de verdad lo que se envía.
5. Aplicar minimización de datos y justificar cada campo por la pregunta que responde.
6. Implementar retención con borrado automático y el flujo de supresión a petición.
7. Enumerar las precauciones adicionales cuando hay menores entre los jugadores.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Taxonomía de eventos | Sin nombres estables no hay análisis posible a los seis meses. |
| 2 | Esquema y versión | Los eventos evolucionan; sin versión, los datos históricos se rompen. |
| 3 | Lista blanca de campos | Convierte "no enviar datos personales" en algo estructural. |
| 4 | Minimización | Cada campo debe responder a una pregunta concreta. |
| 5 | Dato personal | Es más amplio de lo que la gente cree (un id de dispositivo lo es). |
| 6 | Seudonimización | Reduce riesgo sin destruir el análisis. |
| 7 | Consentimiento | Debe ser informado, granular y revocable — y gobernar el código. |
| 8 | Retención | Guardar para siempre es un riesgo, no un activo. |
| 9 | Derecho de supresión | Hay que poder borrar de verdad, incluidos los backups. |
| 10 | Menores | Cambia por completo lo que puedes hacer. |

## 📖 Definiciones y características

- **Telemetría**: datos que el juego envía sobre su uso y funcionamiento. Clave: es un producto con dueño, esquema y ciclo de vida, no un vertedero.
- **Evento**: unidad de telemetría con nombre, momento y propiedades. Clave: su nombre debe ser estable para siempre.
- **Taxonomía**: catálogo de eventos permitidos con su significado y sus campos. Clave: es el contrato entre quien instrumenta y quien analiza.
- **Esquema de evento**: definición de los campos, sus tipos y sus valores válidos. Clave: permite validar en emisión y en ingesta.
- **Versión de evento**: número que cambia cuando cambia el significado o la estructura. Clave: sin ella, un cambio invalida el histórico sin avisar.
- **Dato personal**: cualquier información que permita identificar a una persona, directa o indirectamente. Clave: incluye ids de dispositivo, IP y combinaciones aparentemente inocuas.
- **Dato sensible**: categoría especialmente protegida (salud, orientación, creencias, biometría). Clave: en un juego rara vez hace falta; si aparece, hay que preguntarse por qué.
- **Seudonimización**: sustituir identificadores por un alias que solo puede revertirse con información separada. Clave: reduce riesgo; **sigue siendo dato personal**.
- **Anonimización**: transformación irreversible que impide reidentificar. Clave: si se puede revertir, no es anonimización.
- **Agregación**: sustituir registros individuales por totales. Clave: la forma más simple y robusta de anonimizar.
- **Minimización**: recoger solo lo necesario para un fin declarado. Clave: es principio legal y buena ingeniería a la vez.
- **Base legal / finalidad**: motivo por el que se puede tratar un dato. Clave: se define antes de recoger, no después.
- **Consentimiento**: permiso libre, informado, específico y revocable. Clave: si el juego funciona igual lo des o no, y no se puede retirar, no es consentimiento.
- **Retención**: tiempo máximo que se conserva un dato. Clave: debe estar definida, automatizada y auditable.
- **Derecho de acceso / supresión**: obligación de entregar o borrar los datos de una persona a petición. Clave: requiere poder localizar todo lo suyo.
- **Registro de tratamientos**: documento con qué datos se tratan, para qué y cuánto. Clave: es lo primero que se pide en una auditoría.
- **Transferencia a terceros**: envío de datos a un proveedor. Clave: cada SDK de analítica que integras es uno de estos.

## 🧰 Herramientas y preparación

Continuamos en `res://infraestructura/observabilidad/`, ahora con `telemetria/`. Necesitas el emisor de la [clase 316](../316-observabilidad-de-juegos/README.md). Documentación de referencia: el [texto del RGPD](https://eur-lex.europa.eu/eli/reg/2016/679/oj) (especialmente los principios del artículo 5), la [guía de COPPA de la FTC](https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy) y las políticas de privacidad de las tiendas donde publiques.

## 🧪 Laboratorio guiado

1. **La taxonomía.** Es un archivo, se revisa como código y nadie emite fuera de él:

```json
{
  "version_taxonomia": 3,
  "eventos": {
    "sesion_iniciada": {
      "v": 1,
      "descripcion": "El jugador ha arrancado el juego y ha llegado al menú.",
      "pregunta": "¿Cuánta gente juega y desde qué plataforma?",
      "consentimiento": "esencial",
      "campos": {
        "plataforma": { "tipo": "string", "valores": ["windows", "linux", "macos", "android", "ios", "web"] },
        "build": { "tipo": "string" },
        "primera_vez": { "tipo": "bool" }
      }
    },
    "nivel_completado": {
      "v": 2,
      "descripcion": "El jugador ha terminado un nivel.",
      "pregunta": "¿Dónde se atasca la gente y cuánto tarda?",
      "consentimiento": "analitica",
      "campos": {
        "nivel_id": { "tipo": "string" },
        "segundos": { "tipo": "int", "min": 0, "max": 86400 },
        "muertes": { "tipo": "int", "min": 0, "max": 10000 },
        "dificultad": { "tipo": "string", "valores": ["facil", "normal", "dificil"] }
      }
    },
    "compra_realizada": {
      "v": 1,
      "descripcion": "Compra completada dentro del juego.",
      "pregunta": "¿Qué se compra y en qué momento de la progresión?",
      "consentimiento": "analitica",
      "campos": {
        "sku": { "tipo": "string" },
        "moneda": { "tipo": "string" },
        "nivel_jugador": { "tipo": "int", "min": 1, "max": 999 }
      }
    }
  }
}
```

Fíjate en el campo `pregunta`. Es la regla de oro de la minimización: **si un campo no responde a una pregunta que alguien va a hacer, no se recoge**. Y si nadie sabe formular la pregunta, tampoco.

2. **El emisor con lista blanca.** Esta es la pieza que convierte una política en una garantía:

```gdscript
class_name Telemetria
extends RefCounted

signal evento_rechazado(nombre: String, motivo: String)

# Campos que NUNCA salen del dispositivo, aunque alguien los ponga por error.
const PROHIBIDOS := ["nombre", "email", "correo", "ip", "telefono", "direccion",
					 "usuario", "username", "password", "token", "ruta", "path",
					 "player_name", "steam_id", "device_id", "lat", "lon"]

var _taxonomia := {}
var _consentimiento: Consentimiento
var _cola: Array[Dictionary] = []
var _id_seudonimo: String = ""

func cargar_taxonomia(ruta: String) -> Array[String]:
	var d = JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return ["taxonomía ilegible"]
	_taxonomia = d.get("eventos", {})
	return []

func registrar(nombre: String, campos: Dictionary = {}) -> bool:
	# 1) El evento debe existir en la taxonomía. Si no está declarado, no se
	#    envía: no hay "eventos ad hoc".
	if not _taxonomia.has(nombre):
		evento_rechazado.emit(nombre, "evento no declarado en la taxonomía")
		return false
	var def: Dictionary = _taxonomia[nombre]

	# 2) El consentimiento manda. Si el jugador no lo dio, aquí acaba.
	var categoria := str(def.get("consentimiento", "analitica"))
	if not _consentimiento.permite(categoria):
		return false

	# 3) LISTA BLANCA: solo pasan los campos declarados, con su tipo y rango.
	var limpio := {}
	var esquema: Dictionary = def.get("campos", {})
	for clave in campos:
		if str(clave).to_lower() in PROHIBIDOS:
			evento_rechazado.emit(nombre, "campo prohibido: %s" % clave)
			return false                 # no se recorta: se rechaza y se avisa
		if not esquema.has(clave):
			evento_rechazado.emit(nombre, "campo no declarado: %s" % clave)
			continue                     # se descarta el campo, el evento sigue
		if not _valida_campo(esquema[clave], campos[clave]):
			evento_rechazado.emit(nombre, "campo inválido: %s" % clave)
			continue
		limpio[clave] = campos[clave]

	_cola.append({
		"e": nombre,
		"v": int(def.get("v", 1)),        # versión del evento, siempre
		"t": int(Time.get_unix_time_from_system()),
		"sid": _id_seudonimo,             # seudónimo, no identidad
		"p": limpio,
	})
	return true

func _valida_campo(d: Dictionary, valor: Variant) -> bool:
	match str(d.get("tipo", "")):
		"string":
			if typeof(valor) != TYPE_STRING: return false
			if d.has("valores") and not (d["valores"] as Array).has(valor): return false
		"int":
			if typeof(valor) != TYPE_INT: return false
			if d.has("min") and int(valor) < int(d["min"]): return false
			if d.has("max") and int(valor) > int(d["max"]): return false
		"bool":
			if typeof(valor) != TYPE_BOOL: return false
		_:
			return false
	return true
```

3. **La seudonimización.** Un identificador que sirve para analizar y no para identificar:

```gdscript
func _generar_seudonimo() -> String:
	# Un id ALEATORIO guardado en el dispositivo, no derivado de nada personal.
	# Derivarlo del hardware o del correo lo convertiría en reidentificable, y
	# entonces no habríamos seudonimizado nada.
	var ruta := "user://telemetria_id"
	if FileAccess.file_exists(ruta):
		return FileAccess.open(ruta, FileAccess.READ).get_as_text().strip_edges()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var id := "anon_%08x%08x" % [rng.randi(), rng.randi()]
	FileAccess.open(ruta, FileAccess.WRITE).store_string(id)
	return id

func olvidar() -> void:
	# El jugador retira el consentimiento o pide el borrado: se rota el
	# seudónimo, de forma que los datos futuros no se puedan enlazar con los
	# pasados, y se pide la supresión de lo anterior.
	DirAccess.remove_absolute("user://telemetria_id")
	_id_seudonimo = _generar_seudonimo()
	_cola.clear()
```

4. **El consentimiento, de verdad.** Granular, revocable y con un valor por defecto conservador:

```gdscript
class_name Consentimiento
extends RefCounted

signal cambiado(categoria: String, permitido: bool)

# "esencial" no se puede desactivar, y por eso su contenido debe ser
# MÍNIMO y defendible: crash reports anonimizados y poco más. Meter analítica
# de producto aquí sería hacer trampas.
const CATEGORIAS := {
	"esencial":   {"por_defecto": true,  "bloqueado": true,
				   "explicacion": "Detectar y arreglar fallos del juego."},
	"analitica":  {"por_defecto": false, "bloqueado": false,
				   "explicacion": "Entender cómo se juega para mejorar el diseño."},
	"marketing":  {"por_defecto": false, "bloqueado": false,
				   "explicacion": "Medir campañas y personalizar promociones."},
}

var _estado := {}

func _init() -> void:
	for c in CATEGORIAS:
		_estado[c] = bool(CATEGORIAS[c]["por_defecto"])
	_cargar()

func permite(categoria: String) -> bool:
	return bool(_estado.get(categoria, false))

func fijar(categoria: String, permitido: bool) -> bool:
	if not CATEGORIAS.has(categoria) or bool(CATEGORIAS[categoria]["bloqueado"]):
		return false
	_estado[categoria] = permitido
	_guardar()
	cambiado.emit(categoria, permitido)
	return true
```

Tres señales de que un consentimiento es real y no decorativo:

1. El **valor por defecto es "no"** para todo lo que no sea estrictamente esencial.
2. **Rechazar es tan fácil como aceptar** (un clic, mismo tamaño, mismo color).
3. **Se puede cambiar después**, desde los ajustes, sin buscarlo.

5. **La retención y el borrado.** Guardar para siempre no es prudencia, es riesgo acumulado:

```gdscript
class_name Retencion
extends RefCounted

# Cada categoría con su plazo, y el plazo se cumple SOLO. Una política que
# depende de que alguien se acuerde no es una política.
const DIAS := {
	"crash":      90,
	"analitica":  400,          # ~13 meses: permite comparar año contra año
	"economia":  1825,          # 5 años: obligaciones contables
	"logs_debug":   7,
}

static func caducado(categoria: String, momento: float, ahora: float) -> bool:
	var dias := int(DIAS.get(categoria, 30))
	return (ahora - momento) > dias * 86400.0

static func purgar(registros: Array, categoria: String, ahora: float) -> Array:
	return registros.filter(func(r): return not caducado(categoria, float(r["t"]), ahora))
```

```gdscript
# El flujo de supresión, del lado del servicio.
func suprimir_datos_de(seudonimo: String) -> Dictionary:
	var borrados := {"eventos": 0, "crashes": 0, "perfil": 0}
	borrados["eventos"] = _almacen.borrar_por("sid", seudonimo)
	borrados["crashes"] = _crashes.borrar_por("jugador_anonimo", seudonimo)
	borrados["perfil"] = 1 if _perfiles.borrar(seudonimo) else 0
	# Y lo que casi siempre se olvida: los backups y los agregados derivados.
	_cola_backups.encolar_supresion(seudonimo)
	Log.info("supresion_ejecutada", borrados)
	return borrados
```

6. **La tabla de decisión de cada campo.** El ejercicio que hay que hacer campo a campo:

| Campo | ¿Personal? | ¿Qué pregunta responde? | Alternativa mejor |
|---|---|---|---|
| Nombre del jugador | Sí | Ninguna analítica | Seudónimo |
| Dirección IP | Sí | País aproximado | País derivado en ingesta y descartar la IP |
| Id de dispositivo | Sí | Distinguir instalaciones | Seudónimo propio, rotable |
| Fecha de nacimiento | Sí | Franja de edad | Franja (`13-17`, `18-24`) |
| Coordenadas GPS | Sí (sensible) | Ninguna en la mayoría de juegos | No recoger |
| Nivel alcanzado | No | Progresión y dificultad | Se recoge tal cual |
| Segundos por nivel | No | Ritmo y atascos | Se recoge tal cual |
| Ruta del ejecutable | Sí (contiene el usuario) | Depuración | Ruta relativa o solo el nombre |

Esa penúltima fila es la que más sorprende: `C:\Users\Ana\Juegos\...` lleva el nombre de una persona, y va en la mitad de los crash reports mal filtrados del mundo.

7. **Menores.** El caso que cambia todas las reglas:

- Si tu juego **está dirigido a menores** o sabes que los tienes, la publicidad personalizada y muchos tipos de recogida quedan restringidos o prohibidos según jurisdicción.
- El **consentimiento** puede requerir verificación parental, que es un problema difícil y con implicaciones propias.
- Las **funciones sociales** (chat abierto, contenido generado por usuarios) tienen requisitos adicionales de moderación.
- La solución técnica habitual —una *age gate* neutral al entrar— es imperfecta, pero es el mínimo esperable, y debe registrarse su resultado para condicionar el resto.

No es un tema que se resuelva con código: es un tema de producto y legal que **condiciona** el código. Lo que sí puedes hacer bien desde ingeniería es que las categorías de consentimiento y la taxonomía permitan apagar por completo lo que no proceda.

8. **Probarlo.** Las pruebas de privacidad son verificables como cualquier otra:

```gdscript
extends SceneTree

func _init() -> void:
	var cons := Consentimiento.new()
	var t := Telemetria.nueva(cons, "res://datos/taxonomia.json")
	var rechazos := []
	t.evento_rechazado.connect(func(n, m): rechazos.append([n, m]))

	# Por defecto, la analítica NO está permitida.
	assert(not t.registrar("nivel_completado", {"nivel_id": "n1", "segundos": 40,
												"muertes": 2, "dificultad": "normal"}),
		"se envió analítica sin consentimiento")

	cons.fijar("analitica", true)
	assert(t.registrar("nivel_completado", {"nivel_id": "n1", "segundos": 40,
											"muertes": 2, "dificultad": "normal"}))

	# Evento no declarado: no se envía.
	assert(not t.registrar("evento_inventado", {}), "se aceptó un evento fuera de la taxonomía")

	# Campo prohibido: el evento entero se rechaza.
	assert(not t.registrar("nivel_completado", {"nivel_id": "n1", "email": "a@b.c"}),
		"se aceptó un evento con un campo prohibido")

	# Campo no declarado: se descarta el campo, el evento pasa limpio.
	assert(t.registrar("nivel_completado", {"nivel_id": "n1", "extra": 1}))
	assert(not t.ultimo()["p"].has("extra"), "un campo no declarado llegó a la cola")

	# Valor fuera de rango.
	assert(t.registrar("nivel_completado", {"nivel_id": "n1", "segundos": -5}))
	assert(not t.ultimo()["p"].has("segundos"), "se aceptó un valor fuera de rango")

	# Ningún evento de la cola contiene un campo prohibido.
	for ev in t.cola():
		for clave in ev["p"]:
			assert(not str(clave).to_lower() in Telemetria.PROHIBIDOS,
				"campo prohibido en la cola: %s" % clave)

	# Retirar el consentimiento rota el seudónimo y vacía la cola.
	var sid := t.seudonimo()
	t.olvidar()
	assert(t.seudonimo() != sid, "el seudónimo no rotó al olvidar")
	assert(t.cola().is_empty(), "la cola no se vació")

	# Retención.
	var ahora := 1_000_000.0
	assert(Retencion.caducado("logs_debug", ahora - 8 * 86400.0, ahora))
	assert(not Retencion.caducado("analitica", ahora - 100 * 86400.0, ahora))

	print("== 12 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Escribe la taxonomía completa de tu juego con la columna `pregunta` rellena para cada campo.
2. Implementa un test de CI que falle si el código emite un evento que no está en la taxonomía.
3. Añade derivación de país a partir de la IP **en ingesta** y descarta la IP inmediatamente.
4. Implementa la pantalla de consentimiento con rechazo tan accesible como la aceptación.
5. Implementa exportación de datos del jugador (derecho de acceso) en un JSON legible.
6. Añade una purga automática diaria según la tabla de retención y un log de lo purgado.
7. Escribe el registro de tratamientos de tu juego: qué recoges, para qué, cuánto tiempo y quién lo recibe.

## 📝 Reto verificable

Implementa telemetría gobernada: taxonomía con esquema y versión por evento, emisor con lista blanca y campos prohibidos, consentimiento granular con defecto conservador, seudónimo rotable, retención por categoría con purga automática y flujo de supresión.

**Criterio de aceptación**: una prueba headless con **al menos 18 aserciones** demuestra que: (a) ningún evento fuera de la taxonomía se emite; (b) un evento con cualquiera de los campos prohibidos se rechaza **entero**; (c) los campos no declarados y los valores fuera de rango se descartan sin tumbar el evento; (d) sin consentimiento de `analitica`, ningún evento de esa categoría entra en la cola; (e) retirar el consentimiento rota el seudónimo y vacía la cola pendiente; (f) recorriendo toda la cola no aparece ni un campo de la lista de prohibidos; (g) la purga elimina exactamente los registros que superan el plazo de su categoría y ninguno más; (h) cada evento de la cola lleva su número de versión.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El crash report incluye `C:\Users\Ana\...` | Rutas absolutas en la pila. Recórtalas a relativas antes de enviar. |
| Hay 400 nombres de evento y nadie sabe qué miden | No hay taxonomía. Declara los eventos y prohíbe los ad hoc. |
| Un cambio de significado invalidó seis meses de datos | Falta versión de evento. Sube `v` cuando cambie el significado. |
| El banner de consentimiento no cambia nada | El consentimiento no gobierna el emisor. Consúltalo en `registrar()`. |
| Aceptar es un botón grande y rechazar un enlace pequeño | No es consentimiento libre. Igual peso visual para ambas opciones. |
| No se puede borrar los datos de un jugador | No hay identificador consistente ni inventario de dónde están. Seudónimo único y registro de tratamientos. |
| Se guardan eventos desde 2019 "por si acaso" | Sin política de retención. Define plazos y automatiza la purga. |
| Un SDK de terceros envía más de lo que crees | Integrarlo es una transferencia a terceros. Audita qué recoge y decláralo. |
| La analítica está en "esencial" | Se está evitando el consentimiento. Esencial es lo que el juego necesita para funcionar y arreglarse, nada más. |

## ❓ Preguntas frecuentes

**❓ ¿Un id aleatorio de dispositivo es dato personal?** En la práctica, sí: identifica de forma persistente a una persona aunque no sepas su nombre. Por eso se trata como seudónimo (no como anónimo), se puede rotar y entra en el derecho de supresión. Lo que sí es anónimo es un agregado del que no se puede extraer a nadie.

**❓ ¿Puedo recoger telemetría sin consentimiento?** Depende de la finalidad y la jurisdicción. Lo estrictamente necesario para que el juego funcione y para detectar fallos suele poder ampararse en otra base legal; la analítica de producto y el marketing normalmente requieren consentimiento. La regla práctica y segura: **mínimo en esencial, consentimiento para lo demás**.

**❓ ¿Y si uso un SDK de analítica de terceros?** Entonces estás transfiriendo datos a un proveedor, y sigues siendo responsable de qué se recoge. Lee qué envía por defecto (muchos recogen identificadores de publicidad automáticamente), configúralo para minimizar y decláralo en tu política de privacidad.

**❓ ¿No es todo esto un freno para el equipo de datos?** Al contrario. Un dataset con taxonomía, esquema y versiones **es mucho más útil** que uno con 400 eventos ad hoc y campos que nadie sabe qué significan. La gobernanza no reduce el valor de los datos: es lo que lo hace posible a los dos años.

**❓ ¿Por dónde empiezo si ya tengo un juego publicado sin nada de esto?** Por el inventario: lista qué eventos emites hoy y qué campos llevan. Con esa lista delante, elimina lo que no responde a ninguna pregunta (suele ser la mitad), marca lo personal y añade la lista blanca. Es un trabajo de días, no de meses.

## 🔗 Referencias

- Reglamento General de Protección de Datos (texto oficial): <https://eur-lex.europa.eu/eli/reg/2016/679/oj>
- FTC — Children's Privacy (COPPA): <https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy>
- Agencia Española de Protección de Datos — guías para responsables: <https://www.aepd.es/guias-y-herramientas>
- OWASP — Privacy Risks: <https://owasp.org/www-project-top-10-privacy-risks/>
- Godot Docs — `FileAccess` y `DirAccess` (almacenamiento local del seudónimo): <https://docs.godotengine.org/en/stable/classes/class_diraccess.html>

## ⬅️ Clase anterior

[Clase 316 - Observabilidad de juegos](../316-observabilidad-de-juegos/README.md)

## ➡️ Siguiente clase

[Clase 318 - Threat modeling para videojuegos](../318-threat-modeling-para-videojuegos/README.md)
