# Clase 310 — Capstone Parte 18: un juego sistémico

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Integración de las clases 293–309 · Laboratorio `labs/gameplay-systems/`*
> ⏱️ Duración estimada: **8–12 h** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir un **juego sistémico pequeño pero completo** que integre todo lo de esta parte: catálogo de items, inventario, equipo con estadísticas, habilidades, efectos de estado, pipeline de daño, loot, crafteo, progresión, economía, diálogo, quests, reputación y save versionado — todo funcionando junto y **verificable por una máquina**.

No se trata de hacer un RPG grande. Se trata de demostrar que los sistemas encajan: que matar un lobo dispara un evento que avanza una quest, suelta loot según una tabla determinista, sube reputación con la guardia y baja con los bandidos, que el material que cae permite craftear una espada cuyo modificador se aplica al equiparla, y que todo eso sobrevive a guardar, cerrar y volver a abrir — incluso después de subir `SAVE_VERSION`.

El entregable es un proyecto Godot ejecutable con una batería de pruebas headless que la CI puede correr. El laboratorio [`labs/gameplay-systems/`](../../../labs/gameplay-systems/README.md) contiene la versión `inicio/` con los `TODO` y la `solucion/` de referencia.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Integrar doce sistemas independientes en un juego que funciona, sin acoplarlos entre sí.
2. Diseñar el punto de ensamblaje (composition root) donde se conectan todas las piezas.
3. Demostrar con pruebas automáticas que el conjunto se comporta como se espera.
4. Guardar y restaurar el estado completo del juego con migración de versión.
5. Diagnosticar un fallo de integración localizando en qué sistema empieza.
6. Presentar el proyecto como pieza de portfolio con su documentación técnica.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Composition root | El único punto que conoce a todos: si se ensucia, se ensucia todo. |
| 2 | Bus de eventos | Es lo que permite que doce sistemas colaboren sin conocerse. |
| 3 | Orden de arranque | Cargar contenido, validar, construir sistemas, conectar, empezar. |
| 4 | Integración vs unidad | Las pruebas de esta clase son de otro tipo que las anteriores. |
| 5 | Estado completo en el save | Doce `a_dict()` y el pegamento que los junta. |
| 6 | Verificación en CI | Un capstone que no se puede verificar no se ha terminado. |
| 7 | Diagnóstico de integración | Cuando falla el conjunto, hay que saber por dónde empezar. |
| 8 | Documentación técnica | El README del proyecto es parte del entregable. |

## 📖 Definiciones y características

- **Juego sistémico**: aquel cuyo interés nace de la interacción entre sistemas, no de contenido guionizado. Clave: cada sistema debe ser simple y componible.
- **Composition root**: punto único donde se instancian y conectan todas las dependencias. Clave: normalmente es la escena principal o un `arranque.gd`.
- **Orden de arranque**: secuencia de inicialización que respeta las dependencias entre sistemas. Clave: contenido y validación siempre antes que estado.
- **Prueba de integración**: prueba que ejercita varios sistemas juntos a través de sus interfaces reales. Clave: complementa a las unitarias, no las sustituye.
- **Escenario (golden scenario)**: guion fijo de acciones con resultado esperado conocido. Clave: es la forma práctica de probar integración.
- **Humo (smoke test)**: prueba mínima de que el proyecto arranca y construye su mundo. Clave: es la primera línea de defensa en CI.
- **Marcador de CI**: línea que el proyecto imprime para demostrar que llegó a construirse. Clave: sin ella, "no falló" no significa "funcionó".
- **Estado global de partida**: agregado de los estados de todos los sistemas. Clave: es lo que se guarda, y lo que se compara al probar la ida y vuelta.
- **Diagnóstico por capas**: técnica de localizar un fallo comprobando de dentro afuera (dominio → integración → presentación). Clave: ahorra horas.
- **Vertical slice**: porción del juego completa en profundidad aunque estrecha en contenido. Clave: es exactamente la forma de este capstone.

## 🧰 Herramientas y preparación

Godot 4.3 o superior. Parte de [`labs/gameplay-systems/inicio/`](../../../labs/gameplay-systems/README.md), que trae el esqueleto de carpetas, el contenido de ejemplo y los `TODO`. Necesitas haber hecho —o al menos leído con el código delante— las clases 293 a 309: este capstone no introduce conceptos nuevos, los integra.

Si vienes de la Parte 17, la [clase 283](../../parte-17-capstones-y-preparacion-profesional-portfolio/283-construir-el-vertical-slice/README.md) describe cómo se construye y se presenta un vertical slice; este capstone es uno, con el foco puesto en la arquitectura.

## 🧪 Laboratorio guiado

1. **La estructura del proyecto.** Refleja las cuatro capas de la clase 293:

```text
res://
  dominio/          items/ inventario/ stats/ habilidades/ efectos/ combate/
                    loot/ crafteo/ progresion/ economia/ dialogo/ quests/ social/
  gameplay/         actores, hitbox/hurtbox, zonas, NPC
  presentacion/     HUD, menús, números flotantes
  infraestructura/  guardado/, eventos.gd, servicios.gd
  datos/            items.json recetas.json loot.json quests.json
                    facciones.json arbol_habilidades.json dialogos/
  pruebas/          *_test.gd  (headless)
  arranque.gd       composition root
```

2. **El composition root.** El único archivo que conoce a todos, y el orden importa:

```gdscript
extends Node

var servicios := Servicios.new()

func _ready() -> void:
	# 1) CONTENIDO. Antes que nada, porque todo lo demás depende de él.
	var base := BaseDeItems.new()
	var errores := base.cargar_desde_json("res://datos/items.json")
	errores.append_array(ValidadorDeItems.validar(base))

	var rng := RandomNumberGenerator.new()
	rng.seed = int(Time.get_unix_time_from_system())   # la semilla se guarda en el save
	var loot := TablasDeLoot.new(base, rng); errores.append_array(loot.cargar("res://datos/loot.json"))
	var crafteo := Crafteo.new(base);        errores.append_array(crafteo.cargar("res://datos/recetas.json"))
	var social := Social.new();              errores.append_array(social.cargar("res://datos/facciones.json"))
	var diario := Diario.new();              errores.append_array(diario.cargar("res://datos/quests.json"))

	# 2) VALIDACIÓN. Un contenido roto se detiene AQUÍ, no en la partida del jugador.
	var graves := errores.filter(func(e): return not e.begins_with("aviso"))
	if not graves.is_empty():
		for e in graves: printerr("CONTENIDO: ", e)
		push_error("el contenido no valida: %d error(es)" % graves.size())
		get_tree().quit(1)
		return

	# 3) SISTEMAS de estado.
	var stats := Stats.new()
	var tags := Tags.new()
	var inv := Inventario.new(base, 30)
	var equipo := Equipo.new(base, stats)
	var efectos := Efectos.new(stats, tags)
	var habilidades := AbilitySystem.new()
	var prog := Progresion.new()
	var arbol := ArbolHabilidades.new(stats, prog)
	var monedero := Monedero.new()
	var bb := Blackboard.new()
	var pipeline := PipelineDano.new(rng)

	# 4) CONEXIONES. Todo el pegamento del juego, en un solo sitio y a la vista.
	var bus := EventosJuego.new()
	diario.conectar(bus)
	social.conectar(bus, _condiciones(bb, inv, diario, social), null)
	bus.enemigo_muerto.connect(func(id, pos): _soltar_loot(loot, inv, id, pos))
	prog.subio_nivel.connect(func(n, _p): diario.fijar_nivel(n))
	habilidades.efectos_aplicados.connect(func(_id, objetivos, efs):
		_aplicar_efectos_de_habilidad(pipeline, efectos, objetivos, efs))

	# 5) GUARDADO. Cada sistema aporta su par leer/escribir; el save no los conoce.
	var guardado := Guardado.new()
	guardado.registrar("inventario", inv.a_dict, inv.de_dict)
	guardado.registrar("progresion", prog.a_dict, prog.de_dict)
	guardado.registrar("monedero",   monedero.a_dict, monedero.de_dict)
	guardado.registrar("quests",     diario.a_dict, diario.de_dict)
	guardado.registrar("social",     social.a_dict, social.de_dict)
	guardado.registrar("narrativa",  bb.a_dict, bb.de_dict)
	# `ArbolHabilidades` no traía a_dict/de_dict en la clase 302: añádelos ahora
	# (serializa `_invertido`) y reaplica los modificadores al cargar.
	guardado.registrar("arbol",      arbol.a_dict, arbol.de_dict)

	# 6) SERVICIOS y arranque del mundo.
	for par in [["base", base], ["rng", rng], ["bus", bus], ["inv", inv],
				["equipo", equipo], ["stats", stats], ["efectos", efectos],
				["habilidades", habilidades], ["prog", prog], ["arbol", arbol],
				["monedero", monedero], ["diario", diario], ["social", social],
				["crafteo", crafteo], ["loot", loot], ["guardado", guardado],
				["pipeline", pipeline], ["blackboard", bb]]:
		servicios.registrar(StringName(par[0]), par[1])

	$Mundo.setup(servicios)
	# El marcador que la CI busca: no basta con no fallar, hay que llegar aquí.
	print("Mundo construido: %d items, %d quests, %d facciones" %
		[base.todos().size(), diario._quests.size(), social._facciones.size()])
```

3. **El bucle sistémico mínimo.** Lo que debe ocurrir cuando el jugador mata un lobo:

```text
Golpe → PipelineDano → Salud → murio
                                 │
      ┌──────────────────────────┼──────────────────────────┐
      ▼                          ▼                          ▼
bus.enemigo_muerto        Progresion.ganar_xp        Social.aplicar_evento
      │                          │                          │
      ├─► Diario: avanza quest   └─► sube nivel → puntos     ├─► guardia +
      └─► TablasDeLoot.tirar → Inventario.agregar            └─► bandidos −
                                        │
                                        └─► Crafteo: ahora la receta es posible
```

Ese diagrama es el capstone. Si lo consigues sin que ningún sistema importe a otro, has entendido la parte.

4. **La prueba de integración.** Un escenario fijo, de principio a fin:

```gdscript
extends SceneTree   # godot --headless --script res://pruebas/integracion_test.gd

var hechas := 0
var fallos := 0

func check(ok: bool, que: String) -> void:
	hechas += 1
	if not ok:
		fallos += 1
		printerr("  FALLA  ", que)

func _init() -> void:
	var j := Juego.nuevo(12345)          # semilla fija: todo reproducible

	# --- Contenido -------------------------------------------------------
	check(j.base.todos().size() >= 20, "el catálogo tiene al menos 20 items")
	check(ValidadorDeItems.validar(j.base).is_empty(), "el catálogo valida")

	# --- Quest + loot + reputación, todo por eventos ---------------------
	check(j.diario.aceptar(&"lobos_del_camino"), "se acepta la primera quest")
	for i in 5:
		j.bus.enemigo_muerto.emit(&"lobo", Vector2.ZERO)
	check(j.diario.estado(&"lobos_del_camino") == Quest.Estado.COMPLETED,
		"matar 5 lobos completa la quest")
	check(j.inv.contar(&"piel_lobo") > 0, "el loot llegó al inventario")
	check(j.social.reputacion(&"guardia") > 0.0, "la reputación subió por propagación")

	# --- Entrega de recompensa ------------------------------------------
	var oro_antes := j.monedero.saldo(&"oro")
	check(j.diario.entregar(&"lobos_del_camino", j.inv, j.monedero, j.prog),
		"la recompensa se entrega")
	check(j.monedero.saldo(&"oro") > oro_antes, "la recompensa pagó oro")
	check(j.prog.nivel() > 1, "la XP subió de nivel")

	# --- Crafteo + equipo + stats ---------------------------------------
	j.inv.agregar(&"mineral_hierro", 6)
	j.crafteo.aprender(&"espada_hierro")
	var ctx := {"nivel": j.prog.nivel(), "estacion": "fragua"}
	j.crafteo.craftear(&"lingote_hierro", j.inv, ctx)
	j.crafteo.craftear(&"lingote_hierro", j.inv, ctx)
	j.crafteo.craftear(&"lingote_hierro", j.inv, ctx)
	j.inv.agregar(&"empunadura", 1); j.inv.agregar(&"martillo_herrero", 1)
	check(j.crafteo.craftear(&"espada_hierro", j.inv, ctx) == FalloCrafteo.Motivo.OK,
		"se craftea la espada con los materiales del loot")
	var ataque_antes := j.stats.valor(&"ataque")
	check(j.equipo.equipar(j.inv, &"mano_principal", &"espada_hierro"), "se equipa la espada")
	check(j.stats.valor(&"ataque") > ataque_antes, "equipar sube el ataque")

	# --- Combate completo ------------------------------------------------
	var d := Defensor.new(); d.stats = Stats.new(); d.salud = Salud.new(100)
	var g := Golpe.new(); g.id_ataque = 1; g.base = j.stats.dano_fisico()
	j.pipeline.aplicar(g, d, 0.0)
	check(d.salud.actual < 100, "el pipeline de daño aplicó el golpe")
	check(not g.traza.is_empty(), "el golpe deja traza auditable")

	# --- Save: ida y vuelta con migración --------------------------------
	var antes := j.instantanea()
	check(j.guardado.guardar(0, j.meta()), "se guarda la partida")
	var j2 := Juego.nuevo(12345)
	check(j2.guardado.cargar(0), "se carga la partida")
	check(j2.instantanea() == antes, "el estado restaurado es idéntico")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

5. **El diagnóstico por capas.** Cuando la prueba de integración falla, no empieces por el final:

| Nivel | Pregunta | Cómo se comprueba |
|---|---|---|
| 1. Contenido | ¿Validan todos los catálogos? | Ejecuta cada validador por separado |
| 2. Dominio | ¿Falla un sistema solo? | Ejecuta sus pruebas unitarias |
| 3. Conexiones | ¿Llegan los eventos? | Conecta un `print` al bus y cuenta |
| 4. Orden | ¿Se conectó antes de emitir? | Revisa el composition root |
| 5. Estado | ¿El save conserva todo? | Compara `instantanea()` antes y después |

El 80 % de los fallos de integración están en los niveles 3 y 4: una señal que no se conectó, o que se conectó después de que el emisor ya hubiera emitido.

6. **El README del proyecto.** Es parte del entregable, no un extra. Debe contener: qué sistemas incluye, el diagrama del bucle sistémico, cómo ejecutar el juego, cómo ejecutar las pruebas, qué garantiza cada prueba y qué **no** está implementado (ser explícito con los límites vale más que una lista de promesas).

## ✍️ Ejercicios

1. Añade un segundo enemigo con su propia tabla de loot y su facción, y comprueba que el diagrama sigue funcionando sin tocar código de sistemas.
2. Añade una habilidad que aplique un efecto de estado y verifica el recorrido completo hasta la salud.
3. Sube `SAVE_VERSION` con una migración real y añade un test que cargue un save de la versión anterior.
4. Añade un mod de datos que introduzca tres items y una receta, y comprueba que el juego los usa sin cambios.
5. Graba un replay de 30 segundos del escenario de prueba y añádelo a la batería de regresión.
6. Mide con `Time.get_ticks_usec()` el coste de un tick con todos los sistemas activos.
7. Escribe el "informe de balance": valor esperado por hora de loot, coste de crafteo y neto de economía.

## 📝 Reto verificable

Entrega un proyecto Godot ejecutable que integre **al menos doce** de los sistemas de la parte (items, inventario, equipo+stats, habilidades, efectos, combate, loot, crafteo, progresión, economía, diálogo, quests, reputación, save) con contenido suficiente para jugarlo: 20 items, 8 recetas, 6 quests, 4 facciones, 4 habilidades y una conversación de 15 nodos.

**Criterio de aceptación**:

1. `godot --headless --path . --quit-after 300` arranca sin errores en el Output e imprime `Mundo construido:` con las cuentas de contenido.
2. `godot --headless --script res://pruebas/integracion_test.gd` ejecuta **al menos 25 comprobaciones**, termina con `== N comprobaciones, 0 fallos ==` y código de salida 0.
3. Existen pruebas unitarias headless para al menos **seis** sistemas de dominio, cada una con su propio archivo y su marcador de comprobaciones.
4. La validación de contenido (items, loot, recetas, quests, diálogos, facciones) se ejecuta al arrancar y **detiene el juego** si hay errores graves.
5. El escenario completo funciona: matar enemigos avanza una quest, suelta loot determinista, mueve reputación en dos facciones, permite craftear un item con esos materiales y equiparlo sube una estadística.
6. `guardar()` → `cargar()` restaura un estado **idéntico** (comparado por diccionario completo), incluida al menos una migración de versión.
7. Ningún archivo de `dominio/` contiene `get_node`, `$` ni referencias a nodos de presentación.
8. El README del proyecto documenta los sistemas, el diagrama del bucle, cómo ejecutar juego y pruebas, y qué queda fuera.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El juego arranca pero nada reacciona | Las señales se conectaron después de emitir, o no se conectaron. Revisa el orden del composition root. |
| Un sistema necesita otro y aparece un `import` cruzado | Falta un evento. Invierte la dirección con el bus. |
| La prueba de integración falla y no se sabe por dónde | Faltan pruebas unitarias. Baja al nivel 2 del diagnóstico. |
| El save restaura casi todo menos una cosa | Un sistema no se registró en `Guardado`. La lista de `registrar` es el checklist. |
| Cada ejecución da un loot distinto y las pruebas fallan | La semilla no es fija en las pruebas. Inyecta el RNG con semilla conocida. |
| El composition root tiene 400 líneas | Es normal que sea el archivo más largo, pero extrae las conexiones a funciones con nombre. |
| El juego valida el contenido y sigue con errores | Se avisó en vez de detener. Distingue avisos de errores graves y aborta con los graves. |
| Todo funciona en el editor y falla en CI | Se usó algo que necesita ventana. Prueba siempre con `--headless` en local antes de pushear. |

## ❓ Preguntas frecuentes

**❓ ¿Doce sistemas no son demasiados para un capstone?** Son muchos en número y pocos en tamaño: cada uno son 100-200 líneas que ya escribiste en su clase. Lo difícil —y lo que se evalúa— no es escribirlos, es **conectarlos sin acoplarlos**. Si te cuesta, casi siempre significa que algún sistema quedó con una dependencia que no debería tener.

**❓ ¿Puedo reutilizar el proyecto de otro capstone?** Sí, y es buena idea. Añadir estos sistemas a tu plataformas de la Parte 1 o a tu juego 3D de la Parte 2 demuestra que la arquitectura encaja con lo que ya tenías, que es justo el punto.

**❓ ¿Y la parte visual?** Puede ser mínima: rectángulos de colores bastan. Este capstone evalúa arquitectura y verificabilidad. El pulido visual tiene su sitio en la Parte 17 y su propio capstone.

**❓ ¿Cómo lo presento en el portfolio?** Como pieza de **ingeniería**: el README con el diagrama, el badge de CI en verde, un GIF corto del bucle funcionando y un párrafo por decisión de arquitectura no obvia. Para un puesto de gameplay programmer, esto vale más que un juego bonito sin estructura — es exactamente lo que argumenta la [clase 287](../../parte-17-capstones-y-preparacion-profesional-portfolio/287-tu-portfolio-de-desarrollador-de-juegos/README.md).

**❓ ¿Qué hago si no me da tiempo a los doce sistemas?** Reduce el contenido, no los sistemas: 8 items en vez de 20, 3 quests en vez de 6. Un juego con doce sistemas y poco contenido demuestra lo que se pide; uno con cuatro sistemas y mucho contenido, no.

## 🔗 Referencias

- Laboratorio de esta parte — [`labs/gameplay-systems/`](../../../labs/gameplay-systems/README.md)
- Robert Nystrom — *Game Programming Patterns*: <https://gameprogrammingpatterns.com/>
- Jason Gregory — *Game Engine Architecture*: <https://www.gameenginebook.com/>
- Godot Docs — Command line tutorial (`--headless`, `--script`): <https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html>
- Godot Docs — `SceneTree`: <https://docs.godotengine.org/en/stable/classes/class_scenetree.html>
- GDC Vault — charlas sobre diseño de juegos sistémicos: <https://www.gdcvault.com/>

## ⬅️ Clase anterior

[Clase 309 - Modding y arquitectura extensible](../309-modding-y-arquitectura-extensible/README.md)

## ➡️ Siguiente clase

[Clase 311 - Arquitectura backend para videojuegos](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/311-arquitectura-backend-para-videojuegos/README.md)
