# Clase 319 — Anti-cheat y respuesta frente al abuso

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *Charlas de GDC sobre anti-cheat y confianza en juegos online · OWASP*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Diseñar la defensa de **tu propio juego** frente a trampas y abuso, con una premisa que conviene aceptar cuanto antes: **no puedes impedir que alguien modifique un programa que corre en su ordenador**. Lo que sí puedes es hacer que eso no le sirva de nada, detectarlo cuando ocurra y responder de forma proporcionada y justa.

La [clase 148](../../parte-7-multijugador-y-networking/148-servidor-autoritativo-y-anti-cheat-basico/README.md) construyó el servidor autoritativo y la [154](../../parte-7-multijugador-y-networking/154-seguridad-en-multijugador-validacion-y-exploits/README.md) la validación de entradas. Aquí subimos un nivel: validación de estado imposible, detección estadística de anomalías, telemetría de trampa, y la parte que casi nadie diseña y que determina si tu comunidad confía en ti — **el proceso de sanción**: umbrales, falsos positivos, apelaciones y comunicación.

> Esta clase es **exclusivamente defensiva**. No describe cómo desarrollar trampas, ni cómo evadir sistemas anti-cheat, ni cómo atacar juegos de terceros. Todo lo que aparece aquí es para proteger un sistema propio.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Clasificar los tipos de trampa según qué rompen y qué defensa admiten.
2. Aplicar el principio de autoridad de servidor a cada dato relevante del juego.
3. Implementar validación de estado imposible y de coherencia física.
4. Implementar detección estadística de anomalías con umbrales calibrados.
5. Diseñar telemetría de trampa que alimente decisiones sin acusar a nadie sola.
6. Diseñar un proceso de sanción proporcionado con apelación y trazabilidad.
7. Estimar y acotar la tasa de falsos positivos, y explicar por qué es lo más importante.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué se puede y qué no | Evita gastar meses en defensas imposibles. |
| 2 | Taxonomía de trampas | Cada tipo tiene una defensa distinta y una dificultad distinta. |
| 3 | Autoridad de servidor | Convierte la mayoría de trampas en irrelevantes. |
| 4 | Estado imposible | La validación más barata y más eficaz. |
| 5 | Coherencia física | Detecta lo que la validación por rangos deja pasar. |
| 6 | Información: no enviar lo que no se ve | Única defensa real contra wallhacks. |
| 7 | Detección estadística | Para lo que no se puede validar de forma determinista. |
| 8 | Falsos positivos | Un inocente sancionado hace más daño que diez tramposos. |
| 9 | Sanciones proporcionadas | La escala importa tanto como la detección. |
| 10 | Apelación y comunicación | Es lo que decide si la comunidad confía en el sistema. |

## 📖 Definiciones y características

- **Trampa (cheat)**: obtener ventaja saltándose las reglas del juego. Clave: no toda ventaja es trampa; hay que definirla.
- **Autoridad de servidor**: el servidor decide el estado; el cliente solo pide y muestra. Clave: es la defensa que elimina categorías enteras de trampa.
- **Estado imposible**: valor que las reglas del juego no permiten alcanzar. Clave: detectarlo es determinista y barato.
- **Validación de coherencia**: comprobar que una secuencia de acciones es físicamente posible. Clave: pilla lo que la validación de un solo valor no ve.
- **Speed hack**: acelerar la simulación del cliente para moverse o actuar más rápido. Clave: se detecta comparando el tiempo del cliente con el del servidor.
- **Aimbot**: automatización de la puntería. Clave: no se valida de forma determinista; se detecta estadísticamente.
- **Wallhack / ESP**: ver información oculta del juego. Clave: la **única** defensa real es no enviar esa información.
- **Duplicación**: crear objetos de la nada explotando la economía. Clave: se previene con idempotencia y transacciones (clase 314).
- **Replay attack**: reenviar un mensaje válido para repetir su efecto. Clave: se previene con secuencia y ventana temporal.
- **Detección determinista**: identifica algo imposible con certeza. Clave: puede sancionar con confianza.
- **Detección estadística**: identifica algo improbable. Clave: **nunca** debe sancionar sola.
- **Falso positivo**: sancionar a alguien que no hizo trampa. Clave: es el fallo más caro del sistema, en confianza y en soporte.
- **Falso negativo**: no detectar a un tramposo. Clave: molesto, pero recuperable.
- **Umbral de detección**: valor a partir del cual se marca un caso. Clave: se calibra con datos reales, no a ojo.
- **Puntuación de sospecha**: valor acumulado de señales débiles. Clave: permite decidir sobre el conjunto y no sobre un dato suelto.
- **Sombra (shadow ban)**: sanción no anunciada, como emparejar entre sospechosos. Clave: eficaz y controvertida; exige mucha precisión.
- **Oleada de sanciones (ban wave)**: sancionar en bloque tras acumular pruebas. Clave: dificulta que se deduzca qué se detectó.
- **Apelación**: proceso por el que un sancionado puede pedir revisión. Clave: es lo que hace legítimo el sistema.
- **Proporcionalidad**: sanción acorde con la gravedad y la reincidencia. Clave: la escalada gradual funciona mejor que el todo o nada.

## 🧰 Herramientas y preparación

Trabajaremos sobre el servidor autoritativo de la Parte 7 y el `MockBackend`. Todo el código de la clase corre en el **servidor**. Ten a mano el modelo de amenazas de la [clase 318](../318-threat-modeling-para-videojuegos/README.md): el anti-cheat es la implementación de la mitad de sus controles, y sin el modelo se acaba defendiendo lo que no toca.

## 🧪 Laboratorio guiado

1. **Lo primero: qué se puede y qué no.** Aceptarlo ahorra meses:

| Se puede | No se puede |
|---|---|
| Hacer que modificar el cliente no dé ventaja | Impedir que se modifique el cliente |
| Detectar estados imposibles con certeza | Detectar un aimbot con certeza |
| No enviar información que el jugador no debe ver | Ocultar información que ya enviaste |
| Detectar patrones estadísticamente anómalos | Distinguir con certeza a un tramposo de alguien muy bueno |
| Hacer la trampa cara e incómoda | Hacerla imposible |

2. **La taxonomía y su defensa.** Cada casilla es una decisión de arquitectura:

| Trampa | Qué rompe | Defensa | Certeza |
|---|---|---|---|
| Editar el save local | Nada (single-player) | Riesgo aceptado | — |
| Editar valores en memoria | Nada, si el servidor manda | Autoridad de servidor | Alta |
| Speed hack | Simulación | Validación de tiempo y distancia | Alta |
| Teletransporte | Simulación | Validación de continuidad | Alta |
| Duplicación de objetos | Economía | Idempotencia y transacciones | Alta |
| Replay de paquetes | Cualquier acción | Número de secuencia + ventana | Alta |
| Wallhack / ESP | Información | No enviar lo no visible | Alta (si se hace) |
| Aimbot | Habilidad | Detección estadística | Baja/media |
| Bots de farmeo | Economía y comunidad | Patrones de actividad | Media |
| Boosting / smurfing | Emparejamiento | Análisis de cuentas y ranking | Baja |

3. **Validación determinista: estado imposible.** Barata y certera:

```gdscript
class_name ValidadorEstado
extends RefCounted

class Veredicto extends RefCounted:
	var valido: bool = true
	var motivo: String = ""
	var gravedad: int = 0        # 0 nada · 1 sospechoso · 2 imposible

	static func imposible(m: String) -> Veredicto:
		var v := Veredicto.new(); v.valido = false; v.motivo = m; v.gravedad = 2; return v
	static func sospechoso(m: String) -> Veredicto:
		var v := Veredicto.new(); v.valido = true; v.motivo = m; v.gravedad = 1; return v
	static func ok() -> Veredicto:
		return Veredicto.new()

const VEL_MAX := 300.0           # px/s, del diseño del juego
const TOLERANCIA := 1.15         # 15 % de margen: latencia y jitter existen

static func validar_movimiento(anterior: Vector2, nuevo: Vector2,
							   dt: float, sprintando: bool) -> Veredicto:
	if dt <= 0.0:
		return Veredicto.imposible("dt no positivo")
	var maxima := VEL_MAX * (1.5 if sprintando else 1.0) * TOLERANCIA
	var recorrido := anterior.distance_to(nuevo)
	if recorrido > maxima * dt:
		# IMPOSIBLE, no "raro": ninguna combinación de latencia produce esto.
		return Veredicto.imposible("velocidad %.1f > máxima %.1f" % [recorrido / dt, maxima])
	return Veredicto.ok()

static func validar_recurso(actual: float, maximo: float, nombre: String) -> Veredicto:
	if actual > maximo:
		return Veredicto.imposible("%s = %.1f supera el máximo %.1f" % [nombre, actual, maximo])
	if actual < 0.0:
		return Veredicto.imposible("%s negativo" % nombre)
	return Veredicto.ok()

static func validar_cadencia(ultimo_disparo: float, ahora: float, cadencia: float) -> Veredicto:
	# La cadencia la impone el SERVIDOR. Que el cliente dispare más rápido no
	# significa que el servidor tenga que aceptarlo.
	if ahora - ultimo_disparo < cadencia * 0.9:
		return Veredicto.imposible("cadencia %.3f < mínima %.3f" % [ahora - ultimo_disparo, cadencia])
	return Veredicto.ok()
```

4. **Coherencia de secuencia.** Lo que la validación puntual deja pasar:

```gdscript
class_name ValidadorSecuencia
extends RefCounted

var _ultimo_seq := {}          # jugador -> último número de secuencia aceptado
var _ventana := {}             # jugador -> [(seq, momento)]

const VENTANA_SEG := 5.0

func validar_paquete(jugador: StringName, seq: int, momento: float,
					 ahora: float) -> ValidadorEstado.Veredicto:
	# Replay: un paquete ya visto no se vuelve a aplicar.
	var vistos: Array = _ventana.get(jugador, [])
	vistos = vistos.filter(func(p): return ahora - float(p[1]) < VENTANA_SEG)
	for p in vistos:
		if int(p[0]) == seq:
			return ValidadorEstado.Veredicto.imposible("paquete repetido (seq %d)" % seq)

	# Marca temporal del cliente demasiado desviada: o hay speed hack, o el
	# reloj está mal. Las dos cosas justifican rechazar el paquete.
	if abs(momento - ahora) > 2.0:
		return ValidadorEstado.Veredicto.imposible("marca temporal desviada %.1fs" % (momento - ahora))

	# Retroceso de secuencia: puede ser reordenación de red (sospechoso) o
	# manipulación (si es sistemático).
	if seq <= int(_ultimo_seq.get(jugador, -1)):
		return ValidadorEstado.Veredicto.sospechoso("secuencia no creciente")

	vistos.append([seq, ahora])
	_ventana[jugador] = vistos
	_ultimo_seq[jugador] = seq
	return ValidadorEstado.Veredicto.ok()
```

5. **No enviar lo que no se ve.** La única defensa real contra los wallhacks, y es de diseño:

```gdscript
# En el servidor, ANTES de enviar el estado a cada cliente.
func estado_para(jugador: StringName) -> Dictionary:
	var visible := {}
	for otro in _jugadores:
		if otro == jugador:
			visible[otro] = _estado_completo(otro)
			continue
		# Si no lo ve, no se le manda. Nada de "se lo mando y que el cliente
		# no lo dibuje": eso es exactamente lo que un wallhack aprovecha.
		if _hay_linea_de_vision(jugador, otro) or _fue_visto_hace_menos_de(jugador, otro, 1.0):
			visible[otro] = _estado_reducido(otro)
	return visible
```

Tiene un coste: hay que calcular visibilidad por jugador y por tick, y complica la interpolación (un enemigo que aparece de golpe al doblar una esquina). Ese coste es el precio de que el wallhack no exista, y casi siempre compensa en juegos competitivos.

6. **Detección estadística.** Para lo que no se puede validar, con señales que **suman**:

```gdscript
class_name Sospecha
extends RefCounted

# Señales DÉBILES que se acumulan. Ninguna basta por sí sola: un jugador muy
# bueno dispara varias de estas de forma legítima.
const PESOS := {
	"precision_extrema": 25,      # precisión sostenida muy por encima del percentil 99
	"tiempo_reaccion_bajo": 20,   # reacciones por debajo del límite humano razonable
	"giro_instantaneo": 30,       # cambios de orientación sin transición
	"actividad_continua": 15,     # 20 h seguidas sin pausa (bot)
	"patron_repetitivo": 20,      # trayectorias idénticas repetidas
	"paquetes_rechazados": 10,    # rechazos del validador determinista
}

var _puntos := {}                # jugador -> puntuación acumulada
var _senales := {}               # jugador -> [{senal, momento, detalle}]

func senal(jugador: StringName, nombre: String, ahora: float, detalle := {}) -> int:
	var p := int(PESOS.get(nombre, 5))
	_puntos[jugador] = int(_puntos.get(jugador, 0)) + p
	var lista: Array = _senales.get(jugador, [])
	lista.append({"senal": nombre, "t": ahora, "detalle": detalle})
	_senales[jugador] = lista
	return _puntos[jugador]

func decaer(delta_horas: float) -> void:
	# La sospecha CADUCA. Sin decaimiento, cualquier jugador de muchas horas
	# acaba acumulando puntos por puro azar.
	for j in _puntos:
		_puntos[j] = maxi(0, int(_puntos[j]) - int(5 * delta_horas))

func nivel(jugador: StringName) -> String:
	var p := int(_puntos.get(jugador, 0))
	if p >= 200: return "revision_manual"    # NO sanción automática
	if p >= 100: return "vigilancia"
	if p >= 50:  return "observacion"
	return "normal"
```

7. **La escala de respuesta.** Proporcionada, y con el punto clave marcado:

| Nivel | Evidencia | Respuesta | ¿Automática? |
|---|---|---|---|
| Rechazo | Estado imposible en un paquete | Descartar el paquete, corregir al cliente | Sí |
| Corrección | Rechazos repetidos | Reconciliación forzada, aviso al jugador | Sí |
| Expulsión de partida | Muchos rechazos en poco tiempo | Sacar de la partida en curso | Sí |
| Restricción | Sospecha alta sostenida | Emparejamiento restringido, sin ranking | Sí, reversible |
| Suspensión temporal | Evidencia determinista repetida | Días sin acceso a modos online | Sí |
| Suspensión permanente | Evidencia determinista grave o reincidencia | Cuenta cerrada | **No**: revisión humana |

La línea de "revisión manual" está donde está por una razón: las detecciones **estadísticas** nunca sancionan solas. Solo abren un caso.

8. **Falsos positivos: la cuenta que hay que hacer.** Es aritmética, no opinión:

```text
Base de jugadores: 100.000
Tramposos reales:      1 % = 1.000
Detector: 95 % de acierto, 1 % de falsos positivos

Detectados correctamente:   950
Inocentes marcados:         990   ← MÁS que tramposos detectados

Con un 0,1 % de falsos positivos: 99 inocentes marcados
Con un 0,01 %:                     10 inocentes marcados
```

Con un 1 % de falsos positivos, **la mayoría de las personas que sancionas son inocentes** — aunque el detector "acierte el 95 %". Por eso: los umbrales se calibran para que los falsos positivos estén por debajo del 0,01 %, y por eso las señales débiles se acumulan en vez de disparar solas.

9. **La apelación.** Es parte del sistema, no de soporte:

```gdscript
func abrir_apelacion(jugador: StringName, texto: String, ahora: float) -> Dictionary:
	var caso := {
		"jugador": jugador,
		"sancion": _sanciones.get(jugador, {}),
		# Las señales que llevaron a la sanción, con fecha: sin esto, revisar
		# una apelación es imposible y el proceso se vuelve arbitrario.
		"senales": _sospecha.historial(jugador),
		"evidencia_determinista": _rechazos.historial(jugador),
		"texto_jugador": texto,
		"abierta_en": ahora,
		"estado": "pendiente",
	}
	Log.info("apelacion_abierta", {"jugador_hash": jugador.hash(), "puntos": _sospecha.nivel(jugador)})
	return caso
```

Y la comunicación, que es la mitad del efecto: di **qué política** se ha infringido y **qué duración** tiene la sanción; no des el detalle de la detección (eso ayuda a los tramposos), pero tampoco te escondas detrás de un "actividad sospechosa" que no significa nada.

10. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	# Determinista: teletransporte imposible.
	var v := ValidadorEstado.validar_movimiento(Vector2.ZERO, Vector2(5000, 0), 0.1, false)
	assert(not v.valido and v.gravedad == 2, "no se detectó el teletransporte")

	# Movimiento legítimo con latencia: NO debe marcarse.
	var ok := ValidadorEstado.validar_movimiento(Vector2.ZERO, Vector2(30, 0), 0.1, false)
	assert(ok.valido, "un movimiento legítimo se marcó como trampa")

	# Replay de paquete.
	var vs := ValidadorSecuencia.new()
	assert(vs.validar_paquete(&"p1", 10, 100.0, 100.0).valido)
	assert(not vs.validar_paquete(&"p1", 10, 100.0, 100.5).valido, "se aceptó un paquete repetido")

	# Estadística: una sola señal NO basta.
	var s := Sospecha.new()
	s.senal(&"p2", "precision_extrema", 0.0)
	assert(s.nivel(&"p2") == "observacion", "una sola señal escaló demasiado")
	for n in ["giro_instantaneo", "tiempo_reaccion_bajo", "patron_repetitivo",
			  "actividad_continua", "paquetes_rechazados", "precision_extrema",
			  "giro_instantaneo"]:
		s.senal(&"p2", n, 0.0)
	assert(s.nivel(&"p2") == "revision_manual", "la acumulación no escaló a revisión")

	# Decaimiento: la sospecha caduca.
	s.decaer(40.0)
	assert(s.nivel(&"p2") != "revision_manual", "la sospecha no decayó con el tiempo")

	print("== 6 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Calibra el umbral de velocidad con datos reales de latencia y mide cuántos falsos positivos genera.
2. Implementa la corrección al cliente cuando el servidor rechaza un movimiento, sin que se note como tirón.
3. Añade la señal "actividad continua" con detección de sesiones de más de 12 h y decaimiento.
4. Implementa emparejamiento restringido para el nivel "vigilancia" y mide su efecto.
5. Escribe el texto exacto de la notificación de sanción de tu juego.
6. Diseña el panel de revisión manual: qué información necesita quien revisa para decidir en un minuto.
7. Calcula, con la base de jugadores de tu juego, cuántos inocentes marcarían tus umbrales actuales.

## 📝 Reto verificable

Implementa un sistema anti-cheat defensivo con validación determinista de movimiento, recursos, cadencia y secuencia; protección contra replay; acumulación de señales con pesos y decaimiento; escala de respuesta proporcionada; y registro de evidencias para apelación.

**Criterio de aceptación**: una prueba headless con **al menos 18 aserciones** demuestra que: (a) cada tipo de estado imposible se detecta con gravedad 2; (b) **ningún** movimiento legítimo, incluidos los del percentil 99 de latencia simulada, se marca como imposible (0 falsos positivos sobre 10.000 muestras legítimas); (c) un paquete repetido dentro de la ventana se rechaza y fuera de ella no; (d) una sola señal estadística nunca alcanza el nivel de revisión manual; (e) la sospecha decae con el tiempo hasta volver a "normal"; (f) ninguna función del sistema aplica una suspensión permanente de forma automática; (g) el caso de apelación incluye el historial completo de señales con fecha.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Jugadores legítimos con mala conexión son expulsados | Umbral sin tolerancia. Añade margen y valida sobre ventanas, no sobre un paquete. |
| El wallhack sigue funcionando pese al "anti-cheat" | Se envía información que no se ve. La defensa es no enviarla. |
| Se sanciona por detección estadística automática | Confundir improbable con imposible. Lo estadístico abre casos, no sanciona. |
| La comunidad no confía en las sanciones | No hay apelación ni comunicación. Publica la política y ofrece revisión. |
| Todo jugador veterano acaba marcado | Falta decaimiento de la sospecha. Añádelo. |
| El anti-cheat consume más CPU que el juego | Se valida todo en cada tick. Valida lo que importa y muestrea el resto. |
| Los tramposos aprenden qué se detecta | Se sanciona al instante y con detalle. Oleadas y comunicación genérica del motivo. |
| Se banea la IP y cae un colegio entero | Sanción por IP. Sanciona cuentas, no direcciones compartidas. |

## ❓ Preguntas frecuentes

**❓ ¿Necesito un anti-cheat de kernel?** Es la opción de algunos juegos competitivos grandes, y tiene costes serios: privacidad, estabilidad, soporte, rechazo de parte del público y problemas en Linux y Steam Deck. Para la inmensa mayoría de juegos, **autoridad de servidor + validación + no enviar lo invisible** cubre el 90 % del problema sin ninguno de esos costes.

**❓ ¿Y si mi juego es cooperativo o single-player?** Entonces buena parte de esto no aplica: si alguien se da objetos en su partida, no perjudica a nadie. Sigue siendo un riesgo aceptado documentado ([clase 318](../318-threat-modeling-para-videojuegos/README.md)). La excepción son las **tablas de clasificación globales**: en cuanto existan, hay competición y hace falta autoridad.

**❓ ¿Por qué es peor un falso positivo que un falso negativo?** Por la aritmética del paso 8 y por el efecto en la comunidad. Un tramposo sin detectar molesta a los de su partida; un inocente sancionado pierde su cuenta, lo cuenta públicamente y erosiona la confianza de todos en el sistema. Además, el coste de soporte de las apelaciones es real.

**❓ ¿Oleadas de sanciones o sanción inmediata?** Inmediata para lo determinista y grave (protege la partida en curso). Oleadas para lo acumulado: dificulta deducir qué señal se detectó y permite revisar un lote con más contexto.

**❓ ¿Puedo usar aprendizaje automático?** Puedes, y varios estudios lo hacen para priorizar revisiones. Dos precauciones: un modelo que no sabes explicar produce sanciones que no puedes justificar en una apelación, y sigue siendo una detección **estadística** — con lo cual no debe sancionar sola. Úsalo para ordenar la cola de revisión, no para decidir.

## 🔗 Referencias

- GDC Vault — charlas sobre anti-cheat, confianza y seguridad en juegos online: <https://www.gdcvault.com/> — catálogo por tema, no una charla identificada (ponente y año pendientes) · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- OWASP — Top Ten y controles de validación de entrada: <https://owasp.org/www-project-top-ten/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Valve — documentación de Steamworks sobre integridad de partidas: <https://partner.steamgames.com/doc/features> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `MultiplayerAPI` y autoridad: <https://docs.godotengine.org/en/4.3/tutorials/networking/high_level_multiplayer.html> · uso: respalda el Tema 3 «Autoridad de servidor»
- Adam Shostack — *Threat Modeling*: <https://shostack.org/books/threat-modeling-book> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 318 - Threat modeling para videojuegos](../318-threat-modeling-para-videojuegos/README.md)

## ➡️ Siguiente clase

[Clase 320 - Testing de producción](../320-testing-de-produccion/README.md)
