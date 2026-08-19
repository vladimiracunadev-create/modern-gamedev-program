# Clase 352 — Capstone Parte 21: ingeniería avanzada verificable

> Parte: **21 — Arquitectura avanzada de motores y rendering** · Fuente: *Integración de las clases 339–351 · Laboratorio `labs/advanced-engineering/`*
> ⏱️ Duración estimada: **10–14 h** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Demostrar, **con números**, que entiendes las técnicas de esta parte. No con una demo bonita: con un banco de pruebas que mide, compara contra una implementación de referencia y **falla cuando algo se rompe**.

El capstone integra las técnicas verificables sin GPU —data-oriented design, pools y arenas, job systems, particionamiento espacial, gestión de recursos, mundo grande— con las que sí la necesitan —compute shaders, culling en GPU, escalado— y separa claramente unas de otras. Porque esa es la disciplina que la parte enseña: **lo que se puede verificar automáticamente se verifica, y lo que no, se documenta y se comprueba a mano antes de publicar**.

El resultado es un proyecto que la CI puede importar y ejecutar entero sin tarjeta gráfica, con las pruebas visuales marcadas y descritas. El laboratorio [`labs/advanced-engineering/`](../../../labs/advanced-engineering/README.md) contiene la versión `inicio/` con los `TODO` y la `solucion/` de referencia.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Integrar las técnicas de la parte en un proyecto coherente y medible.
2. Separar lo verificable sin GPU de lo que exige comprobación visual.
3. Construir un banco de pruebas que compare contra implementaciones de referencia.
4. Establecer presupuestos de rendimiento que fallen la CI.
5. Documentar decisiones de arquitectura con los datos que las sostienen.
6. Presentar el trabajo como pieza de portfolio de ingeniería.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Integración medible | El capstone se juzga por sus números. |
| 2 | Implementación de referencia | Sin ella, "más rápido" no significa nada. |
| 3 | Corrección antes que velocidad | Una optimización que cambia el resultado no vale. |
| 4 | Verificable sin GPU | Es lo que permite que corra en CI. |
| 5 | Comprobación visual documentada | Lo que no se automatiza, se describe. |
| 6 | Presupuestos | Convierten el rendimiento en un contrato. |
| 7 | Documentación con datos | Las decisiones se justifican con mediciones. |
| 8 | Portfolio | Es una pieza de ingeniería, y se presenta como tal. |

## 📖 Definiciones y características

- **Banco de pruebas (benchmark)**: programa que mide y compara implementaciones. Clave: sin referencia, no compara nada.
- **Implementación de referencia**: la versión simple y evidentemente correcta. Clave: es el criterio de corrección, no de velocidad.
- **Equivalencia numérica**: dos implementaciones producen el mismo resultado dentro de una tolerancia declarada. Clave: se comprueba antes de medir.
- **Verificable sin GPU**: comprobable con `--headless` en un runner sin tarjeta. Clave: es el requisito para estar en CI.
- **Comprobación visual**: la que requiere ver el resultado. Clave: se documenta con capturas y procedimiento.
- **Presupuesto de rendimiento**: límite que hace fallar la CI. Clave: es lo que impide la degradación lenta.
- **Escalado**: cómo cambia el tiempo con el tamaño del problema. Clave: revela el orden de complejidad real.
- **Informe de arquitectura**: documento con las decisiones y sus mediciones. Clave: es el entregable que se lee.

## 🧰 Herramientas y preparación

Godot 4.3 o superior. Parte de [`labs/advanced-engineering/inicio/`](../../../labs/advanced-engineering/README.md). Necesitas las clases 339 a 351. El proyecto se organiza para que **todo lo que no necesita GPU corra en CI**, y lo que sí la necesita quede en una escena aparte, documentada y ejecutable a mano.

## 🧪 Laboratorio guiado

1. **La estructura:**

```text
res://
  dod/           soa.gd  aos.gd  benchmark.gd
  memoria/       pool.gd  arena.gd  benchmark.gd
  jobs/          grafo_tareas.gd  paralelo.gd  benchmark.gd
  espacial/      rejilla.gd  hash.gd  quadtree.gd  bvh.gd  benchmark.gd
  recursos/      gestor.gd  streaming.gd
  mundo/         particion.gd  posicion_mundo.gd  estado_regiones.gd
  gpu/           cull.glsl  compute_minimo.gd      ← requiere GPU
  escalado/      resolucion_dinamica.gd
  pruebas/
    sin_gpu/     *_test.gd        ← todo esto corre en CI
    con_gpu/     *_test.gd        ← esto no
  visual/        escena_demo.tscn ← comprobación a mano
docs/
  INFORME.md     decisiones, mediciones y conclusiones
  VISUAL.md      procedimiento de comprobación visual con capturas
```

2. **La regla de oro: corrección antes que velocidad.** Cada técnica se compara con su referencia:

```gdscript
class_name ComparadorReferencia
extends RefCounted

# Toda optimización se compara con la implementación EVIDENTEMENTE CORRECTA.
# Una versión 10 veces más rápida que da otro resultado no es una
# optimización: es un bug rápido.

static func comparar(nombre: String, referencia: Callable, optimizada: Callable,
					 entradas: Array, tolerancia := 0.0001) -> Dictionary:
	var iguales := 0
	var diferencias := []
	for e in entradas:
		var a = referencia.call(e)
		var b = optimizada.call(e)
		if _equivalentes(a, b, tolerancia):
			iguales += 1
		else:
			if diferencias.size() < 5:
				diferencias.append({"entrada": e, "referencia": a, "optimizada": b})

	var t_ref := _medir(func(): for e in entradas: referencia.call(e))
	var t_opt := _medir(func(): for e in entradas: optimizada.call(e))

	return {
		"nombre": nombre,
		"correcta": iguales == entradas.size(),
		"iguales": iguales,
		"total": entradas.size(),
		"diferencias": diferencias,
		"ms_referencia": t_ref,
		"ms_optimizada": t_opt,
		"aceleracion": t_ref / maxf(t_opt, 0.0001),
	}
```

3. **El banco de pruebas.** Un informe, no un `print` suelto:

```gdscript
extends SceneTree   # pruebas/sin_gpu/banco.gd

func _init() -> void:
	print("== Banco de ingeniería avanzada ==")
	print("   %s · %d núcleos\n" % [OS.get_name(), OS.get_processor_count()])

	var resultados := []
	resultados.append(_bench_dod())
	resultados.append(_bench_memoria())
	resultados.append(_bench_jobs())
	resultados.append(_bench_espacial())
	resultados.append(_bench_recursos())

	print("\n  %-24s %10s %10s %8s  %s"
		% ["técnica", "referencia", "optimizada", "×", "correcta"])
	var fallos := 0
	for r in resultados:
		print("  %-24s %8.2f ms %8.2f ms %7.1f×  %s"
			% [r["nombre"], r["ms_referencia"], r["ms_optimizada"],
			   r["aceleracion"], "sí" if r["correcta"] else "NO ←"])
		if not r["correcta"]:
			fallos += 1
			for d in r["diferencias"]:
				printerr("     entrada %s → ref %s vs opt %s"
					% [d["entrada"], d["referencia"], d["optimizada"]])

	print("\n== %d técnicas, %d incorrecta(s) ==" % [resultados.size(), fallos])
	quit(1 if fallos > 0 else 0)
```

4. **El escalado.** Lo que revela el orden de complejidad real:

```gdscript
func _escalado(nombre: String, f: Callable, tamanos: Array) -> void:
	print("\n  Escalado de %s:" % nombre)
	print("    %10s %10s %8s" % ["n", "ms", "ms/n"])
	var previo := 0.0
	for n in tamanos:
		var ms := _medir(func(): f.call(n))
		var por_elemento := ms * 1000.0 / float(n)
		# Si ms/n crece con n, la complejidad no es lineal: hay algo peor de
		# lo que crees. Este es el diagnóstico más útil de todo el banco.
		var marca := ""
		if previo > 0.0 and por_elemento > previo * 1.5:
			marca = "  ← no escala linealmente"
		print("    %10d %8.2f %8.4f%s" % [n, ms, por_elemento, marca])
		previo = por_elemento
```

Ejemplo de salida, que es el tipo de dato que el informe debe contener:

```text
  Escalado de consulta espacial (fuerza bruta):
             n         ms     ms/n
           100       0.42   0.0042
           500       9.80   0.0196  ← no escala linealmente
          2000     156.30   0.0781  ← no escala linealmente

  Escalado de consulta espacial (rejilla):
             n         ms     ms/n
           100       0.31   0.0031
           500       1.55   0.0031
          2000       6.30   0.0032
```

5. **Los presupuestos.** El contrato que impide la degradación:

```json
{
  "presupuestos": {
    "dod_100k_particulas_ms":      { "max": 3.0,  "motivo": "cabe en el frame con margen" },
    "pool_10k_obtener_devolver_ms":{ "max": 2.0,  "motivo": "no debe notarse en combate" },
    "espacial_5k_2k_consultas_ms": { "max": 8.0,  "motivo": "percepción de IA cada frame" },
    "jobs_aceleracion_min":        { "min": 2.0,  "motivo": "4+ núcleos deben dar 2× al menos" },
    "recursos_100_cargas_ms":      { "max": 50.0, "motivo": "cambio de zona sin tirón" },
    "mundo_100km_memoria_ratio":   { "max": 1.3,  "motivo": "recorrer no debe filtrar memoria" }
  },
  "tolerancia_regresion": 0.10
}
```

6. **Lo que necesita GPU, separado y documentado:**

```gdscript
extends SceneTree   # pruebas/con_gpu/compute_test.gd

func _init() -> void:
	var rd := RenderingServer.create_local_rendering_device()
	if rd == null:
		# Se SALTA con un mensaje claro, no se falla. Un runner sin GPU no es
		# un fallo del proyecto, y hacerlo fallar enseñaría a ignorar los rojos.
		print("== 0 comprobaciones, 0 fallos (sin dispositivo de cómputo: OMITIDO) ==")
		quit(0)
		return

	var hechas := 0; var fallos := 0
	# ... pruebas de compute y culling en GPU, comparadas con la referencia
	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

```markdown
<!-- docs/VISUAL.md -->
# Comprobación visual

Lo que no se puede verificar sin GPU, con su procedimiento exacto.

## V-01 — Culling en GPU descarta lo correcto
1. Abrir `visual/escena_demo.tscn` y pulsar F5.
2. Pulsar `1` para activar la vista de depuración de culling.
3. Los objetos descartados por frustum se pintan de **azul**, por distancia de
   **verde** y por oclusión de **rojo**.
4. **Esperado**: al girar la cámara, los azules cambian de forma coherente con
   el borde de pantalla; ningún objeto visible aparece coloreado.
5. Captura de referencia: `docs/capturas/v01_culling.png`

## V-02 — La resolución dinámica no oscila visiblemente
1. Pulsar `2` para mostrar el gráfico de escala de render.
2. Provocar carga con `3` (multiplica las partículas por 10).
3. **Esperado**: la escala baja en menos de 0,5 s y se estabiliza; al quitar
   la carga, sube en varios pasos a lo largo de ~2 s, sin oscilar.
4. Captura: `docs/capturas/v02_resolucion.png`

## V-03 — El mundo grande no tiembla a 50 km
...
```

7. **El informe.** El entregable que se lee:

```markdown
<!-- docs/INFORME.md -->
# Informe de ingeniería avanzada

## Resumen
| Técnica | Aceleración | Correcta | Presupuesto |
|---|---|---|---|
| SoA vs AoS (100k partículas) | 7,9× | ✅ | 2,4 / 3,0 ms |
| Pool vs asignación (10k) | 12,3× | ✅ | 0,9 / 2,0 ms |
| Jobs vs secuencial (100k) | 3,1× | ✅ | ≥ 2,0 ✅ |
| Rejilla vs fuerza bruta (5k) | 24,8× | ✅ | 6,1 / 8,0 ms |
| BVH vs fuerza bruta (raycast) | 41,2× | ✅ | — |

## Decisiones y su justificación

### D-01 — SoA con `PackedFloat32Array` para partículas
**Medición**: 100.000 partículas, 60 iteraciones.
- AoS con objetos: 48,3 ms/iter
- AoS con diccionarios: 112,7 ms/iter
- SoA empaquetado: 6,1 ms/iter

**Decisión**: SoA. **Por qué**: el sistema procesa >50.000 elementos cada
frame con trabajo trivial por elemento, que es exactamente el caso donde el
acceso a memoria domina.

**Dónde NO se aplicó**: en el sistema de inventario y en el de quests, donde
hay decenas de elementos y la lógica es compleja. Aplicar SoA ahí habría
empeorado la legibilidad sin ninguna ganancia medible.

### D-02 — Rejilla uniforme y no quadtree
**Medición**: 5.000 objetos, 2.000 consultas, tres distribuciones.
| Distribución | Rejilla | Quadtree | Hash |
|---|---|---|---|
| Uniforme | 6,1 ms | 9,4 ms | 7,2 ms |
| Agrupada | 14,8 ms | 8,1 ms | 9,6 ms |
| Lineal | 8,3 ms | 8,9 ms | 8,0 ms |

**Decisión**: rejilla. **Por qué**: los objetos de la escena son móviles y de
distribución razonablemente uniforme, que es donde la rejilla gana. Si el
diseño de niveles cambiara a distribuciones muy agrupadas, la decisión debería
revisarse — y esta tabla es lo que permitiría hacerlo con datos.

## Limitaciones conocidas
- El culling en GPU lee el contador de vuelta y sincroniza: no es GPU-driven
  puro. Godot no expone draw indirecto desde GDScript (clase 349).
- El escalado de jobs se midió en una máquina de 8 núcleos; en 4 la
  aceleración cae a ~1,9×.
- Las técnicas de rendering temporal (clases 345-348) se documentan pero no se
  implementan: dependen del renderizador del motor.
```

8. **En CI.** Lo que corre siempre y lo que no:

```yaml
  advanced-engineering:
    name: Ingeniería avanzada
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Instalar Godot
        run: bash scripts/instalar_godot.sh

      - name: Importar (valida escenas, scripts y shaders)
        run: |
          set -euo pipefail
          godot --headless --path labs/advanced-engineering/solucion --import 2>&1 | tee import.log
          if grep -E "SCRIPT ERROR|Parse Error|ERROR:|SHADER ERROR" import.log; then
            echo "::error::el proyecto no importa limpio"; exit 1
          fi

      - name: Pruebas sin GPU
        run: |
          set -euo pipefail
          for t in dod memoria jobs espacial recursos mundo; do
            echo "--- $t ---"
            godot --headless --path labs/advanced-engineering/solucion \
                  --script "res://pruebas/sin_gpu/${t}_test.gd"
          done

      - name: Banco de pruebas y presupuestos
        run: |
          godot --headless --path labs/advanced-engineering/solucion \
                --script res://pruebas/sin_gpu/banco.gd

      - name: Pruebas con GPU (se omiten si no hay dispositivo)
        run: |
          godot --headless --path labs/advanced-engineering/solucion \
                --script res://pruebas/con_gpu/compute_test.gd
```

## ✍️ Ejercicios

1. Añade una técnica más al banco con su implementación de referencia.
2. Ejecuta el análisis de escalado y encuentra una función de tu proyecto que no escale linealmente.
3. Ajusta los presupuestos a tu máquina y comprueba que fallan al degradar algo.
4. Escribe la comprobación visual de un efecto que no se pueda automatizar.
5. Añade una decisión al informe con su tabla de mediciones.
6. Documenta una limitación conocida de tu implementación y por qué existe.
7. Ejecuta el banco en dos máquinas distintas y compara los resultados.

## 📝 Reto verificable

Entrega un proyecto Godot que integre **al menos seis** técnicas de la parte con su implementación de referencia, banco de pruebas comparativo, análisis de escalado, presupuestos de rendimiento, pruebas sin GPU en CI, pruebas con GPU que se omiten limpiamente, comprobación visual documentada e informe de arquitectura con las mediciones que justifican cada decisión.

**Criterio de aceptación**:

1. `godot --headless --path . --import` importa sin errores ni de script ni de shader.
2. **Toda** técnica optimizada produce el mismo resultado que su referencia, dentro de una tolerancia declarada, sobre al menos 1.000 entradas.
3. El banco imprime la tabla comparativa con tiempos, aceleración y corrección, y devuelve código distinto de 0 si alguna técnica es incorrecta.
4. El análisis de escalado se ejecuta con **al menos cuatro tamaños** por técnica e identifica automáticamente las que no escalan linealmente.
5. Los presupuestos hacen fallar el banco al superarse, indicando métrica, valor y límite.
6. Las pruebas sin GPU cubren **al menos seis técnicas** y corren completas en un runner sin tarjeta gráfica.
7. Las pruebas con GPU se **omiten con un mensaje claro y código de salida 0** cuando no hay dispositivo de cómputo.
8. `docs/VISUAL.md` documenta **al menos tres** comprobaciones visuales con procedimiento paso a paso y captura de referencia.
9. `docs/INFORME.md` contiene, para **al menos tres** decisiones, la tabla de mediciones que la sostiene y **dónde no se aplicó la técnica y por qué**.
10. El informe declara explícitamente las limitaciones conocidas de la implementación.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El banco dice "10× más rápido" y el juego va igual | Se optimizó lo que no era el cuello. Perfila el juego real, no el micro-benchmark. |
| La versión optimizada da resultados distintos | Es un bug. Corrección antes que velocidad, siempre. |
| Las pruebas fallan en el runner de CI | Dependen de GPU o de un número de núcleos. Sepáralas y omite con criterio. |
| Los presupuestos fallan en máquinas lentas | Umbrales absolutos. Compara contra una base del mismo runner (clase 321). |
| El benchmark da resultados distintos cada vez | Sin calentamiento ni mediana. Descarta las primeras y usa la mediana. |
| El informe dice qué se hizo pero no por qué | Faltan las mediciones. Cada decisión con su tabla. |
| No se documenta dónde NO aplicar la técnica | Es la parte más útil del informe. Añádela. |
| Las pruebas con GPU hacen fallar la CI | Deben omitirse, no fallar. Detecta el dispositivo y sal con 0. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué tanto énfasis en la implementación de referencia?** Porque sin ella no puedes afirmar nada. "Es más rápido" sin comparar con qué, y sin comprobar que da el mismo resultado, no es una medición: es una impresión. Y la mitad de las optimizaciones que parecen funcionar en realidad han cambiado el comportamiento sin que nadie se diera cuenta.

**❓ ¿Puedo entregar solo las técnicas sin GPU?** Sí, y es una entrega perfectamente válida: seis de las trece clases de la parte son verificables sin tarjeta, y son las que más se aplican en el día a día. Lo que sí hay que hacer es **documentar** por qué las demás quedan fuera, en lugar de omitirlas en silencio.

**❓ ¿Cómo lo presento en el portfolio?** Como pieza de ingeniería, con el informe delante: *"seis técnicas de arquitectura de motores implementadas, comparadas contra referencia y verificadas en CI; entre 3× y 41× de mejora medida, con las decisiones justificadas por datos y las limitaciones documentadas"*. Para un puesto de ingeniería de motor o de rendimiento, eso pesa más que cualquier demo.

**❓ ¿No es esto demasiado para un capstone?** Es el último del programa y va después de 351 clases, así que sí es exigente. Pero cada pieza ya la has construido en su clase: lo que se añade aquí es el **rigor de la medición** y el informe. Si te queda grande, entrega menos técnicas con más rigor — es mejor entrega que seis a medias.

**❓ ¿Qué hago con las clases de rendering que no puedo verificar?** Documentarlas honestamente, como en el informe del paso 7: qué entendiste, qué probaste a mano, qué depende del renderizador del motor y qué no pudiste medir. La honestidad sobre los límites de lo que has verificado es, en sí misma, una competencia profesional — y es la que este programa entero ha intentado enseñar.

## 🔗 Referencias

- Laboratorio de esta parte — [`labs/advanced-engineering/`](../../../labs/advanced-engineering/README.md) · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Jason Gregory — *Game Engine Architecture*: <https://www.gameenginebook.com/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Akenine-Möller, Haines & Hoffman — *Real-Time Rendering*: <https://www.realtimerendering.com/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Richard Fabian — *Data-Oriented Design*: <https://www.dataorienteddesign.com/dodbook/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — Command line tutorial y `--headless`: <https://docs.godotengine.org/en/4.3/tutorials/editor/command_line_tutorial.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — Optimización y profiling: <https://docs.godotengine.org/en/4.3/tutorials/performance/index.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 351 - APIs gráficas modernas](../351-apis-graficas-modernas/README.md)

## ➡️ Fin del programa

Has completado el **Programa de Desarrollo de Videojuegos Moderno**: 352 clases, de las matemáticas y el game loop a la arquitectura interna de un motor, pasando por el diseño, la producción, los sistemas de juego, la operación en producción y la IA generativa.

Lo que llevas no es una lista de temas: es la capacidad de **diseñar, implementar, operar, mantener y evolucionar** un videojuego complejo — y, sobre todo, de saber qué has verificado y qué no. Ahora lo más importante: **seguir construyendo, terminando y publicando**.

Vuelve al [índice del programa](../../README.md) para repasar cualquier parte, elige tu próximo capstone y comparte lo que hagas. 🎮
