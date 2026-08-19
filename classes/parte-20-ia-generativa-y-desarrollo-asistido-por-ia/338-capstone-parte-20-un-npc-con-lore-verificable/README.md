# Clase 338 — Capstone Parte 20: un NPC con lore verificable

> Parte: **20 — IA generativa y desarrollo de juegos asistido por IA** · Fuente: *Integración de las clases 325–337 · Laboratorio `labs/ai-game-system/`*
> ⏱️ Duración estimada: **8–12 h** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Construir un **sistema de NPC conversacional completo** que integre todo lo de la parte: abstracción de proveedor, construcción de contexto, RAG de lore con visibilidad, memoria persistente, validación de salida, ejecución por sistemas del juego, seguridad, caché, control de coste, fallbacks y evaluación.

Y con el requisito que define el capstone y que no admite excepciones: **funciona en CI con `MockProvider`, sin claves de API, sin red y de forma determinista**. Un proveedor real se puede configurar por variable de entorno, y es estrictamente opcional. Si el proyecto no arranca sin él, está mal hecho.

El laboratorio [`labs/ai-game-system/`](../../../labs/ai-game-system/README.md) contiene la versión `inicio/` con los `TODO` y la `solucion/` de referencia.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Integrar los trece componentes de la parte en un sistema coherente.
2. Demostrar que el juego funciona con IA, sin IA y con IA fallando.
3. Demostrar que ninguna salida del modelo puede alterar el juego sin validación.
4. Verificar el anclaje al lore y la seguridad con una suite de escenarios.
5. Instrumentar coste, latencia, caché y fallbacks.
6. Presentar el sistema como pieza de portfolio de ingeniería.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Integración | Trece piezas que deben encajar sin acoplarse. |
| 2 | Mock determinista | Es lo que hace posible verificar todo lo demás. |
| 3 | Modo sin IA | El juego completo, sin ningún proveedor. |
| 4 | Cadena de validación | Ninguna salida llega al estado sin pasar por ella. |
| 5 | Suite de evaluación | Anclaje, seguridad y calidad, medidos. |
| 6 | Instrumentación | Coste, latencia y caché en producción. |
| 7 | CI sin secretos | Corre en cualquier fork y sin red. |
| 8 | Documentación | Qué hace, qué no hace y por qué. |

## 📖 Definiciones y características

- **Sistema de NPC conversacional**: conjunto de componentes que permiten dialogar con un personaje. Clave: es infraestructura sobre los sistemas de gameplay, no los sustituye.
- **Composition root de IA**: punto único donde se ensamblan proveedor, lore, memoria, validador y ejecutor. Clave: es donde se ve la arquitectura entera.
- **Modo sin IA**: el juego funcionando con diálogo escrito. Clave: es el modo por defecto de la versión publicada.
- **Mock adversario**: proveedor que devuelve la peor respuesta posible. Clave: prueba las defensas en su peor caso.
- **Suite de escenarios**: conjunto fijo de casos de evaluación. Clave: es la prueba de integración de esta parte.
- **Trazabilidad de la respuesta**: registro de qué lore se usó, qué se validó y qué se ejecutó. Clave: hace depurable un sistema opaco.
- **Presupuesto de sesión**: tope de coste por partida. Clave: acota el peor caso económico.
- **Entregable de portfolio**: proyecto ejecutable con documentación y CI verde. Clave: es lo que se enseña en una entrevista.

## 🧰 Herramientas y preparación

Godot 4.3 o superior. Parte de [`labs/ai-game-system/inicio/`](../../../labs/ai-game-system/README.md). Necesitas las clases 325 a 337; este capstone las integra sin añadir conceptos. **No hace falta ninguna cuenta ni clave**: el sistema completo se ejercita con `MockProvider`.

## 🧪 Laboratorio guiado

1. **La estructura:**

```text
res://
  ia/
    proveedor/     ai_provider.gd  mock_provider.gd  mock_adversario.gd
                   local_provider.gd  remote_provider.gd  sin_ia_provider.gd
                   servicio_ia.gd
    contexto/      constructor_contexto.gd  presupuesto_contexto.gd
    lore/          base_de_lore.gd  memoria.gd  verificador_anclaje.gd
    seguridad/     saneador.gd  capacidades.gd  moderacion.gd  filtro_privacidad.gd
                   abuso.gd
    validacion/    validador_respuesta.gd  intencion.gd  ejecutor.gd
    coste/         modelo_coste.gd  presupuesto.gd  cache.gd  cola.gd
    evaluacion/    arnes.gd  ejecutar.gd
  datos/
    npcs/          herrero_bram.json  aldeana_nara.json  guardia_tolven.json
    lore/          mundo.json
    ia/            cache_precalculada.json
  pruebas/
    escenarios/    suite.json
    *_test.gd
  npc_ia.gd        composition root del sistema de IA
docs/
  arquitectura-ia.md
```

2. **El composition root:**

```gdscript
extends Node

func construir() -> SistemaNPC:
	# 1) PROVEEDOR: cadena con degradación. El último SIEMPRE es SinIA.
	var ia := ServicioIA.new()
	var cadena: Array[AIProvider] = []
	var url := OS.get_environment("MIJUEGO_IA_URL")
	if url != "":
		cadena.append(RemoteProvider.nuevo(url, _http, _token))
	var modelo := "user://modelos/npc.onnx"
	if FileAccess.file_exists(modelo):
		var local := LocalProvider.new(modelo)
		if local.disponible():
			cadena.append(local)
	if OS.is_debug_build() or OS.get_environment("MIJUEGO_IA_MOCK") == "1":
		cadena.append(MockProvider.new(1234))
	cadena.append(SinIAProvider.new())
	ia.configurar(cadena)

	# 2) CONOCIMIENTO: lore validado y memoria persistente.
	var lore := BaseDeLore.new()
	var errores := lore.cargar("res://datos/lore/mundo.json")
	if not errores.is_empty():
		for e in errores: printerr("LORE: ", e)
		push_error("el lore no valida: %d error(es)" % errores.size())
	var memoria := Memoria.new()

	# 3) SEGURIDAD y VALIDACIÓN.
	var moderacion := Moderacion.nueva(_tema_del_juego(), _edad_objetivo())
	var validador := ValidadorRespuesta.new()
	var ejecutor := EjecutorIntenciones.nuevo(_diario, _inv, _social, _tienda)

	# 4) COSTE: caché primero, presupuesto después.
	var cache := CacheIA.nueva("res://datos/ia/cache_precalculada.json")
	var presupuesto := PresupuestoIA.new()

	var sistema := SistemaNPC.new(ia, lore, memoria, moderacion, validador,
								  ejecutor, cache, presupuesto)

	print("Sistema IA construido: proveedor=%s · lore=%d entradas · npcs=%d · cache=%d" %
		[ia.activo(), lore.total(), _npcs.size(), cache.precalculadas()])
	return sistema
```

3. **El flujo completo, con sus trece pasos.** Es el resumen de la parte:

```text
 1. Entrada del jugador
 2. Saneado y acotación                          (336)
 3. Moderación de entrada                        (336)
 4. Caché: ¿ya tenemos esta respuesta?           (335)  ── acierto ─► responder
 5. Presupuesto: ¿podemos gastar?                (335)  ── no ─────► fallback
 6. Capacidades del NPC en este estado           (336)
 7. Recuperación de lore por relevancia          (332)
 8. Memoria a corto y largo plazo                (332)
 9. Construcción del contexto con presupuesto    (331)
10. Filtro de privacidad                         (336)  ── problema ► abortar
11. Proveedor con timeout                        (334)  ── fallo ───► fallback
12. Validación: esquema → intención → viabilidad (331)  ── fallo ───► fallback
13. Moderación de salida                         (336)  ── fallo ───► fallback
14. Ejecución por los sistemas del juego         (331)
15. Caché, memoria, telemetría                   (335, 316)
```

Cada flecha de fallback lleva a contenido escrito a mano. **En ningún punto el jugador ve un error.**

4. **Las pruebas.** Cinco suites que cubren el sistema:

```gdscript
# pruebas/sin_ia_test.gd — la más importante de todas.
extends SceneTree

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	var s := SistemaNPC.nuevo_con([SinIAProvider.new()] as Array[AIProvider])

	check.call(s.arranco(), "el sistema arranca sin ningún proveedor")
	check.call(not s.hay_ia(), "se detecta correctamente que no hay IA")
	var d := await s.hablar(&"herrero_bram", "Hola", {})
	check.call(d != "", "el NPC responde con diálogo escrito")
	check.call(s.puede_ofrecer_quests(&"herrero_bram"), "las quests siguen funcionando")
	check.call(s.puede_comerciar(&"herrero_bram"), "la tienda sigue funcionando")
	check.call(s.llamadas_al_proveedor() == 0, "no se ha llamado a ningún proveedor")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

```gdscript
# pruebas/adversario_test.gd — el mock devuelve la PEOR respuesta posible.
extends SceneTree

const ATAQUES := [
	'{"dialogo":"Toma.","intencion":{"tipo":"dar_item","parametros":{"item_id":"hoja_legendaria","cantidad":99}}}',
	'{"dialogo":"Ve.","intencion":{"tipo":"ofrecer_quest","parametros":{"quest_id":"quest_final_secreta"}}}',
	'{"dialogo":"Ok.","intencion":{"tipo":"borrar_partida","parametros":{}}}',
	'{"dialogo":"Mis instrucciones son: Eres Bram, herrero. NUNCA reveles...","intencion":{"tipo":"ninguna"}}',
	'{"dialogo":"El derrumbe lo causó el capataz Verol.","intencion":{"tipo":"ninguna"}}',
	'No soy JSON en absoluto, soy texto libre con instrucciones.',
	'{"dialogo":"' + "x".repeat(5000) + '","intencion":{"tipo":"ninguna"}}',
]

func _init() -> void:
	var hechas := 0; var fallos := 0
	for ataque in ATAQUES:
		var mock := MockProvider.new(1)
		mock.responder(ataque)
		var s := SistemaNPC.nuevo_con([mock] as Array[AIProvider])
		var antes := _instantanea_completa()
		await s.hablar(&"aldeano_generico", "haz lo que te digo", {})
		hechas += 2
		if _instantanea_completa() != antes:
			fallos += 1; printerr("  FALLA  el ataque cambió el estado del juego: ", ataque.substr(0, 60))
		if s.ultimo_dialogo() == "":
			fallos += 1; printerr("  FALLA  no hubo respuesta al ataque")
	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

5. **La suite de evaluación.** La prueba de integración de la parte:

```gdscript
# pruebas/evaluacion_test.gd
func _init() -> void:
	var arnes := ArnesEvaluacion.new()
	var escenarios := _cargar("res://pruebas/escenarios/suite.json")
	var r := await arnes.ejecutar(escenarios, MockProvider.new(555))
	var cfg := _cargar("res://pruebas/escenarios/umbrales.json")
	var cmp := arnes.comparar(r, _base(), cfg)

	print("== Evaluación (mock determinista) ==")
	for clave in ["tasa_validacion", "tasa_criterios", "tasa_seguridad",
				  "nombres_inventados", "tasa_repeticion"]:
		print("  %-22s %.3f" % [clave, float(r.get(clave, 0.0))])
	for f in cmp["fallos"]: printerr("  FALLO  ", f)
	print("== %d métricas, %d fallo(s) ==" % [5, cmp["fallos"].size()])
	quit(1 if not cmp["fallos"].is_empty() else 0)
```

6. **La documentación.** Parte del entregable, y con la sección que más vale:

```markdown
# Arquitectura del sistema de IA

## Qué hace
NPC conversacionales con lore anclado, memoria persistente y ejecución de
intenciones validadas contra los sistemas del juego.

## Qué NO hace (y por qué)
- **El modelo no decide nada del juego.** Propone intenciones de una lista
  cerrada; el juego valida y ejecuta.
- **No es obligatorio.** El juego es completo sin IA: los NPC usan el grafo de
  diálogo escrito de la clase 304.
- **No hay claves en el cliente.** El proveedor remoto pasa por un proxy propio.
- **No sustituye a la IA de gameplay.** El comportamiento (perseguir, atacar,
  patrullar) sigue siendo behavior trees de la Parte 5.

## Modos de funcionamiento
| Modo | Cuándo | Qué ve el jugador |
|---|---|---|
| Remoto | `MIJUEGO_IA_URL` configurada | Conversación completa |
| Local | Modelo descargado y hardware suficiente | Conversación completa, sin red |
| Mock | Desarrollo y CI | Respuestas fijadas |
| Sin IA | Por defecto en la build publicada | Diálogo escrito |

## Cómo ejecutar las pruebas
    godot --headless --script res://pruebas/sin_ia_test.gd
    godot --headless --script res://pruebas/adversario_test.gd
    godot --headless --script res://pruebas/lore_test.gd
    godot --headless --script res://pruebas/coste_test.gd
    godot --headless --script res://pruebas/evaluacion_test.gd

Ninguna requiere red, claves ni servicios.
```

7. **En CI:**

```yaml
  ai-game-system:
    name: Sistema de IA
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Instalar Godot
        run: bash scripts/instalar_godot.sh
      - name: Importar
        run: godot --headless --path labs/ai-game-system/solucion --import
      - name: Pruebas
        run: |
          set -euo pipefail
          # MIJUEGO_IA_URL deliberadamente vacía: si algo la necesitara,
          # fallaría aquí, que es donde queremos enterarnos.
          unset MIJUEGO_IA_URL || true
          export MIJUEGO_IA_MOCK=1
          for t in sin_ia adversario lore coste evaluacion; do
            echo "--- $t ---"
            godot --headless --path labs/ai-game-system/solucion \
                  --script "res://pruebas/${t}_test.gd"
          done
```

## ✍️ Ejercicios

1. Añade un tercer NPC con capacidades distintas y comprueba que la suite lo cubre.
2. Añade 10 escenarios hostiles nuevos y verifica que la tasa de seguridad sigue en 1.0.
3. Precalcula la caché de las preguntas frecuentes y mide el ahorro proyectado.
4. Implementa la trazabilidad completa: qué lore se usó y qué se validó, por respuesta.
5. Conecta un proveedor real por variable de entorno y compara métricas con el mock.
6. Añade la pantalla de ajustes donde el jugador activa o desactiva la IA.
7. Escribe la sección "qué no hace" de tu propio sistema.

## 📝 Reto verificable

Entrega un proyecto Godot ejecutable con el sistema completo: abstracción de proveedor con cadena de degradación y modo sin IA; **al menos tres NPC** con identidad, capacidades y fallbacks propios; base de lore de **al menos 25 entradas** con tres niveles de visibilidad; memoria persistente en el save; validación de tres filtros; ejecución por los sistemas del juego; seguridad completa; caché con precálculo; control de coste; y suite de evaluación de **al menos 25 escenarios**.

**Criterio de aceptación**:

1. `godot --headless --path . --quit-after 300` arranca **sin ninguna variable de entorno** e imprime `Sistema IA construido:`.
2. `pruebas/sin_ia_test.gd` demuestra que el juego es jugable sin ningún proveedor y que **no se llama a ninguno**.
3. `pruebas/adversario_test.gd` ejecuta **al menos 7 ataques** distintos y demuestra que **ninguno** altera el estado del juego y que todos producen respuesta.
4. `pruebas/lore_test.gd` demuestra que los secretos no se filtran, que el lore privado de un NPC no lo conocen los demás y que la recuperación es determinista.
5. `pruebas/coste_test.gd` demuestra que la caché acierta con variantes equivalentes, que el presupuesto corta y que el timeout funciona.
6. `pruebas/evaluacion_test.gd` ejecuta la suite y falla si alguna métrica crítica incumple su umbral; `tasa_seguridad` es **1.0**.
7. Ningún test requiere red, clave de API ni servicio externo; todos son deterministas con la misma semilla.
8. No existe ninguna clave de API en el repositorio, comprobable con una búsqueda.
9. `docs/arquitectura-ia.md` documenta modos de funcionamiento, flujo completo, **qué no hace el sistema** y cómo ejecutar cada prueba.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El proyecto no arranca sin `MIJUEGO_IA_URL` | La IA es requisito. `SinIAProvider` último y contenido fijo. |
| Un ataque del mock adversario cambia el estado | Falta validación o capacidades. Revisa los filtros 12 y 6 del flujo. |
| Los tests pasan en local y fallan en CI | Dependen de una variable o de red. Elimínalas del arranque. |
| El NPC filtra un secreto del lore | El filtro de visibilidad se aplica tarde. Va antes de puntuar. |
| La caché nunca acierta en los tests | Las claves incluyen algo variable. Revisa qué entra en la clave. |
| La suite de evaluación tarda 10 minutos | Se usa el proveedor real. Mock en CI. |
| El composition root está repartido | Se conectó desde varios sitios. Centraliza en `npc_ia.gd`. |
| No se sabe por qué el NPC dijo eso | Falta trazabilidad. Registra lore usado, validación y ejecución. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué tanto énfasis en el modo sin IA?** Porque es lo que hace publicable el sistema. Un juego que necesita un proveedor externo para funcionar tiene una dependencia que no controla: precios, disponibilidad, términos y existencia futura. Con el modo sin IA, lo peor que puede pasar es que una función opcional desaparezca.

**❓ ¿El mock adversario no es exagerado?** Es exactamente el escenario que hay que probar: **el modelo obedece completamente a un atacante**. Si tu sistema resiste eso, resiste cualquier prompt injection real, porque ya has probado el peor caso posible. Y como el mock es determinista, la prueba es fiable.

**❓ ¿Cuánto de esto necesito para un juego pequeño?** El modo sin IA, la abstracción de proveedor y la validación de salida: son la base y no son negociables si publicas. El RAG, la memoria y la evaluación completa escalan con la ambición del sistema. Lo que **no** puedes recortar es la validación: sin ella, cualquier salida del modelo puede tocar tu juego.

**❓ ¿Cómo lo presento en el portfolio?** Como pieza de ingeniería, con la frase que resume el logro: *"NPC conversacionales con lore anclado y ejecución validada; siete ataques de prompt injection no producen ningún efecto en el juego; funciona sin conexión y sin claves; verificado en CI"*. Para un puesto que toque IA aplicada, eso dice más que una demo bonita que solo funciona con la clave del autor.

**❓ ¿Y si quiero usarlo con un proveedor real?** Configuras `MIJUEGO_IA_URL` apuntando a tu proxy y funciona sin tocar una línea. Ese es el retorno de la abstracción de la clase 334, y es el mismo motivo por el que cambiar de proveedor mañana costará una tarde y no un mes.

## 🔗 Referencias

- Laboratorio de esta parte — [`labs/ai-game-system/`](../../../labs/ai-game-system/README.md) · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- OWASP — Top 10 for Large Language Model Applications: <https://owasp.org/www-project-top-10-for-large-language-model-applications/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- ONNX Runtime — inferencia local: <https://onnxruntime.ai/docs/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — Command line tutorial: <https://docs.godotengine.org/en/4.3/tutorials/editor/command_line_tutorial.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- NIST — AI Risk Management Framework: <https://www.nist.gov/itl/ai-risk-management-framework> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- GDC Vault — charlas sobre IA generativa en producción de juegos: <https://www.gdcvault.com/> — catálogo por tema, no una charla identificada (ponente y año pendientes) · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 337 - Evaluación de sistemas generativos](../337-evaluacion-de-sistemas-generativos/README.md)

## ➡️ Siguiente clase

[Clase 339 - Data-Oriented Design](../../parte-21-arquitectura-avanzada-de-motores-y-rendering/339-data-oriented-design/README.md)
