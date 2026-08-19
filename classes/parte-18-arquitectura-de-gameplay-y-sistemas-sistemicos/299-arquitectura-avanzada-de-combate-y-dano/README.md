# Clase 299 — Arquitectura avanzada de combate y daño

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Gregory, «Game Engine Architecture» · Charlas de GDC sobre sistemas de combate y hit detection*
> ⏱️ Duración estimada: **130 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir el **pipeline de daño**: la tubería explícita por la que pasa todo golpe del juego, desde que una hitbox toca una hurtbox hasta que aparece el número, se aplica el retroceso y, si toca, muere alguien. En la mayoría de proyectos amateur ese recorrido está repartido en seis scripts y cada arma lo hace un poco distinto; el resultado es que nadie puede responder a "¿por qué este golpe ha hecho 34?".

Aquí lo vas a convertir en una secuencia de pasos con nombre —`Attack → Hit → Cálculo → Resistencias → Modificadores → Salud → Efectos → Feedback → Muerte`— donde cada paso recibe un objeto de daño, lo transforma y lo pasa. Separarás hitbox de hurtbox, implementarás armadura y resistencias con fórmulas que no se rompen en los extremos, críticos deterministas, invulnerabilidad tras impacto (*i-frames*), retroceso y una muerte que ocurre **una sola vez**.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Enumerar los pasos del pipeline de daño y decir qué responsabilidad tiene cada uno.
2. Separar **hitbox** y **hurtbox** con capas de colisión y explicar por qué no son el mismo nodo.
3. Implementar un objeto `Golpe` que viaje por el pipeline acumulando su historia.
4. Aplicar armadura con una fórmula de reducción **asintótica** y razonar sobre sus límites.
5. Implementar críticos, resistencias por tipo de daño e invulnerabilidad temporal.
6. Garantizar que un mismo golpe no impacte dos veces y que la muerte se dispare una sola vez.
7. Separar el cálculo (dominio) del feedback (presentación) y probar el primero headless.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Hitbox vs hurtbox | Sin separarlas, un enemigo se golpea a sí mismo o los golpes se anulan. |
| 2 | El objeto Golpe | Llevar el contexto entero evita 8 parámetros y permite auditar el resultado. |
| 3 | Pipeline por pasos | Cada paso se prueba y se cambia sin tocar los demás. |
| 4 | Tipos de daño | Físico, fuego, veneno: cada uno con su resistencia. |
| 5 | Armadura y reducción | La fórmula lineal se rompe: al 100 de armadura no puede haber inmunidad. |
| 6 | Críticos | Probabilidad y multiplicador, con aleatoriedad controlada. |
| 7 | Invulnerabilidad (i-frames) | Evita que una hitbox persistente vacíe la vida en tres frames. |
| 8 | Retroceso (knockback) | Es parte del golpe, no del movimiento: viaja en el mismo objeto. |
| 9 | Muerte única | El bug de "muere dos veces y suelta doble loot" es endémico. |
| 10 | Feedback separado | Números, sonido y screenshake son presentación, no reglas. |

## 📖 Definiciones y características

- **Hitbox**: volumen que **produce** daño (el filo de la espada, la explosión). Clave: pertenece al atacante y solo está activa durante la ventana de golpeo.
- **Hurtbox**: volumen que **recibe** daño (el cuerpo del personaje). Clave: pertenece al defensor y suele ser más grande y estable que la hitbox.
- **Golpe (hit)**: objeto que describe un impacto concreto: atacante, defensor, cantidad base, tipo, dirección, flags. Clave: es el dato que atraviesa todo el pipeline.
- **Pipeline de daño**: secuencia ordenada de transformaciones sobre el golpe. Clave: hace el resultado explicable y auditable paso a paso.
- **Daño base**: número de partida antes de cualquier modificación. Clave: es dato del arma o la habilidad, nunca el resultado final.
- **Tipo de daño**: categoría (físico, fuego, hielo, veneno, verdadero). Clave: determina qué resistencia se aplica.
- **Daño verdadero (true damage)**: daño que ignora armadura y resistencias. Clave: herramienta de diseño para evitar builds invulnerables.
- **Armadura**: estadística que reduce el daño físico. Clave: debe usar una fórmula que nunca alcance el 100 % de reducción.
- **Reducción asintótica**: fórmula `A / (A + K)` que se acerca a 1 sin llegar. Clave: mantiene el juego balanceable en valores altos.
- **Resistencia**: reducción porcentual por tipo de daño, normalmente acotada. Clave: se acota arriba y abajo (una resistencia negativa es vulnerabilidad).
- **Crítico**: golpe con probabilidad de multiplicar el daño. Clave: la fuente de aleatoriedad debe ser la del juego, no `randf()` global.
- **Invulnerabilidad (i-frames)**: ventana tras un impacto en la que no se puede volver a recibir daño. Clave: es lo que hace jugable un juego de acción.
- **ID de golpe**: identificador único de un ataque concreto, usado para no impactar dos veces con la misma hitbox. Clave: distinto de i-frames; convive con ellos.
- **Knockback**: impulso aplicado al defensor, con dirección y fuerza. Clave: viaja en el golpe porque depende del atacante.
- **Muerte única (death latch)**: bandera que garantiza que la lógica de muerte se ejecute una sola vez. Clave: sin ella, dos golpes en el mismo frame duplican el loot.
- **Feedback**: números flotantes, sonido, partículas, vibración, *hitstop*. Clave: presentación pura; nunca decide daño.
- **Hitstop**: micro-congelación al impactar que aumenta la sensación de contundencia. Clave: es feedback, pero afecta al tiempo: decide si escala con el daño.

## 🧰 Herramientas y preparación

Necesitas `Salud` (clase 293), `Stats` (clase 296) y `Efectos` (clase 298). Trabajaremos en `res://dominio/combate/` para el cálculo y en `res://gameplay/combate/` para las áreas de colisión. Configura tres capas de física: `Hurtbox jugador`, `Hurtbox enemigo`, `Hitbox`, de forma que una hitbox de jugador solo detecte hurtboxes de enemigo. Documentación: [`Area2D`](https://docs.godotengine.org/en/4.3/classes/class_area2d.html) y [capas y máscaras de colisión](https://docs.godotengine.org/en/4.3/tutorials/physics/physics_introduction.html).

## 🧪 Laboratorio guiado

1. **El objeto Golpe.** Lleva de todo, y va **acumulando su historia** para poder explicarse:

```gdscript
class_name Golpe
extends RefCounted

enum Tipo { FISICO, FUEGO, HIELO, VENENO, VERDADERO }

var id_ataque: int = 0             # identifica ESTE ataque, para no impactar dos veces
var atacante: StringName = &""
var base: float = 0.0
var tipo: Tipo = Tipo.FISICO
var direccion: Vector2 = Vector2.ZERO
var fuerza_knockback: float = 0.0
var prob_critico: float = 0.0
var mult_critico: float = 2.0
var ignora_armadura := false
var efectos: Array[Dictionary] = []

# Resultado del pipeline (lo rellenan los pasos).
var final: float = 0.0
var fue_critico := false
var absorbido := false             # invulnerable, bloqueado o inmune
var traza: Array[String] = []      # "base 40" → "crítico ×2 = 80" → "armadura -21 = 59"

func anotar(paso: String) -> void:
	traza.append(paso)

func explicar() -> String:
	return " → ".join(traza)
```

Esa `traza` parece un lujo hasta el primer informe de "me ha hecho demasiado daño": entonces vale su peso en oro, y es el mismo dato que después alimentará la telemetría de balance ([clase 317](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/317-telemetria-privacidad-y-gobernanza-de-datos/README.md)).

2. **El defensor.** Todo lo que el pipeline necesita saber del que recibe:

```gdscript
class_name Defensor
extends RefCounted

var salud: Salud
var stats: Stats
var efectos: Efectos
var invulnerable_hasta: float = 0.0      # en tiempo de juego
var golpes_recibidos := {}               # id_ataque -> true

func es_invulnerable(ahora: float) -> bool:
	return ahora < invulnerable_hasta

func ya_golpeado_por(id_ataque: int) -> bool:
	return id_ataque != 0 and golpes_recibidos.has(id_ataque)
```

3. **El pipeline.** Un paso por función, en orden, y cada uno con una sola responsabilidad:

```gdscript
class_name PipelineDano
extends RefCounted

const K_ARMADURA := 100.0        # a 100 de armadura, reduce el 50 %

var _rng: RandomNumberGenerator

func _init(rng: RandomNumberGenerator) -> void:
	# El RNG se INYECTA: con semilla fija, el combate es reproducible y se puede
	# grabar en un replay (clase 308) y comparar en un test.
	_rng = rng

func aplicar(g: Golpe, d: Defensor, ahora: float) -> Golpe:
	g.anotar("base %.0f" % g.base)
	g.final = g.base

	# 1) Puertas: si no procede, se sale sin tocar nada más.
	if not d.salud.esta_vivo():
		g.absorbido = true
		g.anotar("objetivo ya muerto")
		return g
	if d.ya_golpeado_por(g.id_ataque):
		g.absorbido = true
		g.anotar("mismo ataque, ya impactó")
		return g
	if d.es_invulnerable(ahora):
		g.absorbido = true
		g.anotar("invulnerable")
		return g

	# 2) Crítico.
	if g.prob_critico > 0.0 and _rng.randf() < g.prob_critico:
		g.fue_critico = true
		g.final *= g.mult_critico
		g.anotar("crítico ×%.1f = %.0f" % [g.mult_critico, g.final])

	# 3) Modificadores ofensivos ya vienen en `base` (los aplicó el atacante).
	#    Aquí toca lo defensivo.
	if g.tipo != Golpe.Tipo.VERDADERO:
		g.final = _armadura(g, d)
		g.final = _resistencia(g, d)

	# 4) Redondeo y suelo: un golpe que conecta hace al menos 1.
	g.final = maxf(1.0, roundf(g.final))
	g.anotar("final %.0f" % g.final)

	# 5) Aplicar.
	d.salud.recibir(int(g.final))
	if g.id_ataque != 0:
		d.golpes_recibidos[g.id_ataque] = true

	# 6) Efectos que trae el golpe (quemadura, sangrado…).
	for e in g.efectos:
		g.anotar("efecto %s" % str(e.get("estado", "?")))

	return g

func _armadura(g: Golpe, d: Defensor) -> float:
	if g.ignora_armadura or g.tipo != Golpe.Tipo.FISICO:
		return g.final
	var a := maxf(0.0, d.stats.valor(&"defensa"))
	# Asintótica: nunca llega a reducir el 100 %, por muchísima armadura que haya.
	var reduccion := a / (a + K_ARMADURA)
	var r := g.final * (1.0 - reduccion)
	g.anotar("armadura %.0f (-%.0f%%) = %.0f" % [a, reduccion * 100.0, r])
	return r

func _resistencia(g: Golpe, d: Defensor) -> float:
	var clave := StringName("res_" + Golpe.Tipo.keys()[g.tipo].to_lower())
	# Acotamos: -1.0 = daño doble (vulnerable), 0.9 = 90 % resistido. Nunca 100 %.
	var res := clampf(d.stats.valor(clave), -1.0, 0.9)
	if is_zero_approx(res):
		return g.final
	var r := g.final * (1.0 - res)
	g.anotar("resistencia %s %.0f%% = %.0f" % [clave, res * 100.0, r])
	return r
```

4. **Las áreas, en gameplay.** El dominio ya está probado; ahora se conecta al mundo:

```gdscript
# res://gameplay/combate/hitbox.gd
extends Area2D

@export var dano_base: float = 10.0
@export var tipo: Golpe.Tipo = Golpe.Tipo.FISICO
@export var knockback: float = 200.0

static var _siguiente_id := 1
var _id_ataque := 0

func activar() -> void:
	# Un id NUEVO por swing: la misma hitbox puede golpear a varios enemigos,
	# pero a cada uno una sola vez.
	_id_ataque = _siguiente_id
	_siguiente_id += 1
	monitoring = true

func desactivar() -> void:
	monitoring = false

func _on_area_entered(hurtbox: Area2D) -> void:
	if not monitoring:
		return
	var g := Golpe.new()
	g.id_ataque = _id_ataque
	g.atacante = owner.name
	g.base = dano_base
	g.tipo = tipo
	g.direccion = (hurtbox.global_position - global_position).normalized()
	g.fuerza_knockback = knockback
	hurtbox.recibir(g)
```

```gdscript
# res://gameplay/combate/hurtbox.gd
extends Area2D

signal golpeado(g: Golpe)

@export var iframes: float = 0.5

var defensor: Defensor          # lo inyecta la entidad al construirse

func recibir(g: Golpe) -> void:
	var ahora := float(Time.get_ticks_msec()) / 1000.0
	var pipeline: PipelineDano = Servicios.actual.obtener(&"pipeline")
	pipeline.aplicar(g, defensor, ahora)
	if not g.absorbido:
		defensor.invulnerable_hasta = ahora + iframes
	golpeado.emit(g)             # la presentación se entera por aquí
```

5. **El feedback, aparte.** No decide nada; solo reacciona:

```gdscript
# res://presentacion/feedback_combate.gd
extends Node2D

func _on_golpeado(g: Golpe) -> void:
	if g.absorbido:
		return
	_numero_flotante(str(int(g.final)), Color.RED if not g.fue_critico else Color.YELLOW)
	if g.fue_critico:
		_hitstop(0.08)           # el hitstop escala con el impacto, no con el daño bruto
	_sonido_impacto(g.tipo)
```

6. **La muerte, una sola vez.** El bug clásico y su solución, que son cuatro líneas:

```gdscript
extends CharacterBody2D

var _muerto := false

func _on_salud_murio() -> void:
	if _muerto:
		return                   # dos golpes en el mismo frame no dan doble loot
	_muerto = true
	murio_en.emit(global_position, _ultimo_atacante)
	$Hurtbox.monitoring = false  # deja de recibir: si no, sigue "muriendo"
	queue_free()
```

7. **Probarlo headless.** Con RNG de semilla fija, el combate es reproducible al 100 %:

```gdscript
extends SceneTree

func _init() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 42
	var pipe := PipelineDano.new(rng)

	var d := Defensor.new()
	d.stats = Stats.new()
	d.salud = Salud.new(200)
	d.stats.get_stat(&"defensa").base = 100.0     # K = 100 → 50 % de reducción

	var g := Golpe.new(); g.id_ataque = 1; g.base = 40.0
	pipe.aplicar(g, d, 0.0)
	assert(g.final == 20.0, "la armadura no redujo el 50%%: %f" % g.final)
	assert(d.salud.actual == 180)

	# El MISMO ataque no golpea dos veces.
	var g2 := Golpe.new(); g2.id_ataque = 1; g2.base = 40.0
	pipe.aplicar(g2, d, 0.0)
	assert(g2.absorbido and d.salud.actual == 180, "el mismo ataque golpeó dos veces")

	# Daño verdadero: ignora armadura.
	var g3 := Golpe.new(); g3.id_ataque = 2; g3.base = 40.0; g3.tipo = Golpe.Tipo.VERDADERO
	pipe.aplicar(g3, d, 0.0)
	assert(g3.final == 40.0, "el daño verdadero fue reducido")

	# Invulnerabilidad.
	d.invulnerable_hasta = 10.0
	var g4 := Golpe.new(); g4.id_ataque = 3; g4.base = 999.0
	pipe.aplicar(g4, d, 5.0)
	assert(g4.absorbido, "los i-frames no absorbieron el golpe")

	print(g.explicar())
	print("== 5 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Añade un paso de **bloqueo**: si el defensor tiene el tag `estado.bloqueando` y el golpe viene de frente, reduce un 70 % y aplica el resto a una barra de aguante.
2. Implementa daño en área con caída por distancia (`falloff`) y un id de ataque compartido.
3. Añade **penetración de armadura** al golpe y decide en qué orden se aplica respecto a la reducción.
4. Implementa `sobrecuración` (curar por encima del máximo) como escudo temporal usando el sistema de efectos.
5. Escribe una prueba que dispare 10.000 golpes con el mismo RNG sembrado y compruebe que la tasa de críticos cae dentro del ±1 % de `prob_critico`.
6. Añade una tabla de daño por atacante para la pantalla de fin de combate.
7. Implementa `hitstop` proporcional a `final / vida_max` y compara la sensación con un valor fijo.

## 📝 Reto verificable

Implementa el pipeline completo con **hitbox y hurtbox separadas**, tipos de daño, armadura asintótica, resistencias acotadas, críticos con RNG inyectado, i-frames, id de ataque, knockback y muerte única.

**Criterio de aceptación**: una prueba headless con **al menos 18 aserciones** demuestra que: (a) con defensa igual a `K_ARMADURA` el daño físico se reduce exactamente a la mitad; (b) con defensa 10.000 el daño sigue siendo mayor que 0; (c) el daño verdadero ignora armadura y resistencias; (d) el mismo `id_ataque` no aplica daño dos veces al mismo defensor pero **sí** golpea a dos defensores distintos; (e) durante los i-frames todos los golpes quedan absorbidos; (f) dos golpes letales en el mismo frame emiten la señal de muerte **una sola vez**; (g) con `rng.seed` fijo, dos ejecuciones producen la misma secuencia de críticos y el mismo daño total.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El enemigo pierde toda la vida al tocar la espada | La hitbox está activa varios frames sin id de ataque ni i-frames. Añade ambos. |
| El jugador se golpea a sí mismo | Hitbox y hurtbox en la misma capa. Sepáralas y ajusta las máscaras. |
| Con mucha armadura los enemigos son inmortales | Fórmula lineal (`dano - armadura`). Usa la reducción asintótica. |
| El loot sale duplicado | La señal de muerte se emitió dos veces. Añade la bandera `_muerto`. |
| Los críticos "se sienten" mal distribuidos | Se usa `randf()` global compartido con efectos visuales. Inyecta un RNG propio del combate. |
| El daño no es reproducible en un replay | El RNG no está sembrado o se comparte. Un RNG por sistema, con semilla guardada. |
| El número flotante muestra un valor distinto al que baja la vida | El feedback recalcula el daño. Debe leer `g.final`, nunca recalcular. |
| Golpes que no registran a 144 fps | La hitbox se activa y desactiva en menos de un frame de física. Usa una ventana mínima en `_physics_process`. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué la armadura asintótica y no `daño - armadura`?** Porque la resta se rompe en los dos extremos: con armadura alta el daño llega a 0 (inmortalidad) y con daño alto la armadura no importa. `A/(A+K)` da rendimientos decrecientes suaves, tiene un parámetro con significado claro (`K` es la armadura que reduce el 50 %) y nunca alcanza el 100 %.

**❓ ¿i-frames y id de ataque no son lo mismo?** No, y hacen falta los dos. El **id de ataque** impide que una misma hitbox golpee dos veces al mismo enemigo; los **i-frames** impiden que dos ataques distintos (o dos enemigos) encadenen golpes sin darte reaccionar. Sin id, una hitbox persistente pega cada frame; sin i-frames, tres enemigos rodeándote te matan al instante.

**❓ ¿El pipeline no añade coste?** Es una función con siete pasos y unas pocas multiplicaciones; el coste es despreciable frente a la detección de colisiones. Lo que sí añade es la posibilidad de **auditar** cada número, que es lo que hace balanceable el juego.

**❓ ¿Dónde aplico los efectos que trae el golpe?** El pipeline los anota y los pasa al gestor de efectos ([clase 298](../298-status-effects-buffs-y-debuffs/README.md)) **después** de resolver el daño, para que un golpe letal no aplique un veneno a un cadáver.

**❓ ¿Y si es multijugador?** El pipeline corre en el servidor y punto. El cliente puede predecir el número para el feedback, pero la salud autoritativa es la del servidor; si difieren, manda el servidor. Es exactamente lo que hace el lab de multijugador de la Parte 7.

## 🔗 Referencias

- Godot Docs — `Area2D`: <https://docs.godotengine.org/en/4.3/classes/class_area2d.html> · uso: se instala o se consulta en la preparación
- Godot Docs — Introducción a la física y capas de colisión: <https://docs.godotengine.org/en/4.3/tutorials/physics/physics_introduction.html> · uso: se instala o se consulta en la preparación
- Godot Docs — `RandomNumberGenerator` (semillas y determinismo): <https://docs.godotengine.org/en/4.3/classes/class_randomnumbergenerator.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Jason Gregory — *Game Engine Architecture*: <https://www.gameenginebook.com/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- GDC Vault — charlas sobre game feel, hit detection y diseño de combate: <https://www.gdcvault.com/> — catálogo por tema, no una charla identificada (ponente y año pendientes) · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 298 - Status effects, buffs y debuffs](../298-status-effects-buffs-y-debuffs/README.md)

## ➡️ Siguiente clase

[Clase 300 - Loot tables y sistemas de recompensas](../300-loot-tables-y-sistemas-de-recompensas/README.md)
