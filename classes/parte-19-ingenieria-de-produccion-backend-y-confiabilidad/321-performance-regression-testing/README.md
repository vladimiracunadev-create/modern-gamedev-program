# Clase 321 — Performance regression testing

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *Documentación de profiling de Godot 4 · Google, «Site Reliability Engineering» (SLO y presupuestos)*
> ⏱️ Duración estimada: **115 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Convertir el rendimiento en algo que la **CI puede suspender**. La Parte 14 enseñó a optimizar: perfilar, encontrar el cuello de botella y arreglarlo. Esta clase enseña lo contrario y complementario: **impedir que se estropee otra vez**. Porque el rendimiento no se pierde en un commit dramático; se pierde en cincuenta commits que añaden 2 ms cada uno, y cuando alguien se da cuenta ya nadie sabe cuál fue.

Vas a definir **presupuestos** (tiempo de arranque, frame time, memoria, tamaño de assets, tamaño de build, tiempo de carga), medirlos de forma reproducible en un entorno ruidoso como es un runner de CI, compararlos contra una **línea base versionada** y hacer que un cambio que se pase del presupuesto **falle el build**. Y vas a hacerlo evitando la trampa clásica: umbrales absolutos que fallan por el ruido del runner y acaban desactivados a la semana.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Definir presupuestos de rendimiento medibles y justificados por el dispositivo objetivo.
2. Medir de forma reproducible en un entorno ruidoso, usando mediana y percentiles.
3. Mantener una línea base versionada y detectar regresiones relativas.
4. Distinguir ruido de regresión con un criterio estadístico simple.
5. Integrar los presupuestos en CI para que bloqueen un merge.
6. Medir tamaño de build y de assets como presupuesto de primera clase.
7. Actualizar la línea base de forma deliberada y trazable.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Presupuesto | Convierte "va rápido" en un número que se puede comprobar. |
| 2 | Dispositivo objetivo | El presupuesto sale del hardware mínimo, no del tuyo. |
| 3 | Medición reproducible | Un runner de CI es ruidoso; hay que medir en consecuencia. |
| 4 | Mediana y percentiles | La media se la lleva cualquier hipo del sistema operativo. |
| 5 | Línea base versionada | Sin referencia no hay regresión, solo números. |
| 6 | Regresión relativa | Comparar contra la base es mucho más estable que un absoluto. |
| 7 | Ruido vs señal | Umbral con margen y confirmación por repetición. |
| 8 | Tamaño como presupuesto | El tamaño de la build es rendimiento en descarga y en memoria. |
| 9 | Fallo del build | Un presupuesto que no bloquea no es un presupuesto. |
| 10 | Actualizar la base | Subirla debe ser una decisión explícita y registrada. |

## 📖 Definiciones y características

- **Presupuesto de rendimiento**: límite numérico declarado para una métrica. Clave: se decide antes, no se descubre después.
- **Dispositivo objetivo**: el hardware mínimo que quieres soportar. Clave: es lo que fija los presupuestos.
- **Frame budget**: milisegundos disponibles por frame (16,6 ms a 60 fps; 8,3 a 120). Clave: se reparte entre subsistemas.
- **Línea base (baseline)**: medición de referencia guardada en el repositorio. Clave: versionada, para saber cuándo y por qué cambió.
- **Regresión de rendimiento**: empeoramiento medible respecto a la línea base. Clave: relativa, no absoluta.
- **Ruido de medición**: variación por causas ajenas al código (otros procesos, térmica, virtualización). Clave: es grande en CI y hay que absorberlo.
- **Mediana**: valor central de las muestras. Clave: robusta frente a valores extremos, al contrario que la media.
- **Percentil p95/p99**: cola de la distribución. Clave: describe los peores frames, que son los que se notan.
- **Calentamiento (warm-up)**: descartar las primeras iteraciones. Clave: evita medir el coste de la primera carga y de la compilación.
- **Iteración**: cada repetición de la medición. Clave: más iteraciones, menos ruido, más tiempo de CI.
- **Umbral de tolerancia**: margen relativo a partir del cual se considera regresión. Clave: típicamente 5-10 % en CI.
- **Confirmación**: repetir la medición antes de declarar regresión. Clave: reduce falsos positivos casi a cero.
- **Tamaño de build**: peso del ejecutable y sus datos. Clave: afecta a descarga, actualización y memoria.
- **Presupuesto de assets**: límites por tipo (texturas, audio, mallas). Clave: evita que un asset de 200 MB entre sin que nadie lo note.
- **Tiempo de arranque**: desde lanzar hasta poder interactuar. Clave: es la primera impresión y se degrada silenciosamente.
- **Perfil de escenario**: guion fijo que se ejecuta para medir. Clave: sin escenario fijo, cada medición mide otra cosa.

## 🧰 Herramientas y preparación

Godot 4.x con `--headless`, la clase `Performance`, `Time.get_ticks_usec()` y los replays deterministas de la [clase 308](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/308-commands-input-recording-y-replays/README.md) como escenarios reproducibles. Trabajaremos en `res://pruebas/rendimiento/` y guardaremos la línea base en `pruebas/rendimiento/baseline.json`, versionada en git. Repasa de la Parte 14 las clases [240](../../parte-14-optimizacion-profiling-y-rendimiento/240-mentalidad-de-rendimiento-medir-antes-de-optimizar/README.md) y [242](../../parte-14-optimizacion-profiling-y-rendimiento/242-presupuesto-de-frame-y-objetivos-de-fps/README.md): aquí no se trata de optimizar, sino de no desoptimizar.

## 🧪 Laboratorio guiado

1. **Los presupuestos.** Un archivo, revisado como código, con el porqué de cada número:

```json
{
  "version": 1,
  "dispositivo_objetivo": "portátil de gama media 2020, iGPU, 8 GB RAM",
  "presupuestos": {
    "arranque_ms":        { "max": 3000, "motivo": "por encima de 3 s la gente cree que se ha colgado" },
    "carga_nivel_ms":     { "max": 1500, "motivo": "cabe en la animación de transición" },
    "frame_p50_ms":       { "max": 12.0, "motivo": "60 fps con margen para picos" },
    "frame_p99_ms":       { "max": 24.0, "motivo": "ningún frame por encima de 2 vsync" },
    "memoria_pico_mb":    { "max": 900,  "motivo": "1 GB de objetivo con margen del SO" },
    "tick_logica_ms":     { "max": 2.0,  "motivo": "la lógica no puede comerse el frame" },
    "build_mb":           { "max": 350,  "motivo": "descarga razonable y actualizaciones baratas" },
    "textura_mayor_mb":   { "max": 12,   "motivo": "una textura no puede ser el 3 % de la build" },
    "carga_catalogos_ms": { "max": 120,  "motivo": "se hace en el arranque, dentro del presupuesto" }
  },
  "tolerancia_regresion": 0.08,
  "iteraciones": 9,
  "calentamiento": 2
}
```

Fíjate en el campo `motivo`. Un presupuesto sin justificación se acaba subiendo "porque falla", y entonces deja de ser un presupuesto.

2. **La medición reproducible.** Mediana de varias iteraciones, con calentamiento:

```gdscript
class_name Medidor
extends RefCounted

class Medicion extends RefCounted:
	var nombre: String
	var muestras: Array[float] = []

	func mediana() -> float:
		var s := muestras.duplicate(); s.sort()
		return s[s.size() / 2] if s.size() % 2 == 1 \
			else (s[s.size() / 2 - 1] + s[s.size() / 2]) * 0.5

	func percentil(p: float) -> float:
		var s := muestras.duplicate(); s.sort()
		return s[clampi(int(s.size() * p), 0, s.size() - 1)]

	func dispersion() -> float:
		# Rango intercuartílico relativo: si es alto, la medición no es fiable
		# y decir "hay regresión" sería adivinar.
		var q1 := percentil(0.25); var q3 := percentil(0.75)
		return (q3 - q1) / maxf(mediana(), 0.0001)

static func medir(nombre: String, escenario: Callable,
				  iteraciones := 9, calentamiento := 2) -> Medicion:
	var m := Medicion.new()
	m.nombre = nombre
	for i in calentamiento:
		escenario.call()                 # se descartan: cachés frías, primer parse
	for i in iteraciones:
		var t0 := Time.get_ticks_usec()
		escenario.call()
		m.muestras.append((Time.get_ticks_usec() - t0) / 1000.0)
	return m
```

3. **La comparación contra la línea base.** Relativa y con confirmación:

```gdscript
class_name Presupuestos
extends RefCounted

enum Veredicto { OK, REGRESION, SUPERA_PRESUPUESTO, MEDICION_NO_FIABLE, MEJORA }

static func evaluar(m: Medidor.Medicion, base: float, maximo: float,
					tolerancia: float) -> Dictionary:
	var valor := m.mediana()

	# 1) ¿Es fiable la medición? Un runner ocupado da dispersiones enormes; en
	#    ese caso, callarse es más honesto que dar un veredicto.
	if m.dispersion() > 0.25:
		return {"veredicto": Veredicto.MEDICION_NO_FIABLE, "valor": valor,
				"dispersion": m.dispersion()}

	# 2) Presupuesto ABSOLUTO: no se puede superar, venga de donde venga.
	if valor > maximo:
		return {"veredicto": Veredicto.SUPERA_PRESUPUESTO, "valor": valor, "maximo": maximo}

	# 3) Regresión RELATIVA respecto a la base.
	if base > 0.0:
		var delta := (valor - base) / base
		if delta > tolerancia:
			return {"veredicto": Veredicto.REGRESION, "valor": valor,
					"base": base, "delta": delta}
		if delta < -tolerancia:
			return {"veredicto": Veredicto.MEJORA, "valor": valor,
					"base": base, "delta": delta}
	return {"veredicto": Veredicto.OK, "valor": valor}
```

4. **Los escenarios.** Fijos y deterministas, o no se mide nada comparable:

```gdscript
extends SceneTree   # pruebas/rendimiento/medir.gd

func _init() -> void:
	var cfg = JSON.parse_string(FileAccess.open(
		"res://pruebas/rendimiento/presupuestos.json", FileAccess.READ).get_as_text())
	var base = _cargar_baseline()
	var resultados := {}
	var fallos := 0

	# Escenario 1: cargar y validar todos los catálogos.
	resultados["carga_catalogos_ms"] = Medidor.medir("carga_catalogos_ms",
		func():
			var b := BaseDeItems.new()
			b.cargar_desde_json("res://datos/items.json")
			ValidadorDeItems.validar(b),
		int(cfg["iteraciones"]), int(cfg["calentamiento"]))

	# Escenario 2: 1.000 ticks de lógica con todos los sistemas activos. Un
	# REPLAY como escenario: siempre la misma secuencia, siempre comparable.
	resultados["tick_logica_ms"] = Medidor.medir("tick_logica_ms",
		func():
			var sim := _sim_desde_replay("res://pruebas/replays/base.json")
			for i in 1000:
				sim.avanzar(),
		int(cfg["iteraciones"]), int(cfg["calentamiento"]))

	# Escenario 3: 10.000 operaciones de inventario.
	resultados["inventario_10k_ms"] = Medidor.medir("inventario_10k_ms",
		func():
			var inv := _inv_limpio()
			for i in 10000:
				inv.agregar(&"pocion_menor", 1)
				if i % 3 == 0: inv.quitar(&"pocion_menor", 1),
		int(cfg["iteraciones"]), int(cfg["calentamiento"]))

	for clave in resultados:
		var p: Dictionary = cfg["presupuestos"].get(clave, {"max": INF})
		var r := Presupuestos.evaluar(resultados[clave], float(base.get(clave, 0.0)),
									  float(p.get("max", INF)), float(cfg["tolerancia_regresion"]))
		fallos += _informar(clave, r, p)

	print("== %d comprobaciones, %d fallos ==" % [resultados.size(), fallos])
	quit(1 if fallos > 0 else 0)

func _informar(clave: String, r: Dictionary, p: Dictionary) -> int:
	match int(r["veredicto"]):
		Presupuestos.Veredicto.OK:
			print("  OK    %-24s %.2f" % [clave, r["valor"]]); return 0
		Presupuestos.Veredicto.MEJORA:
			print("  MEJOR %-24s %.2f (%.1f%% mejor)" % [clave, r["valor"], -r["delta"] * 100.0])
			return 0
		Presupuestos.Veredicto.MEDICION_NO_FIABLE:
			print("  ????  %-24s dispersión %.0f%%: runner ruidoso, no se juzga"
				% [clave, r["dispersion"] * 100.0]); return 0
		Presupuestos.Veredicto.REGRESION:
			printerr("  REGR  %-24s %.2f vs base %.2f (+%.1f%%)"
				% [clave, r["valor"], r["base"], r["delta"] * 100.0]); return 1
		_:
			printerr("  PRESU %-24s %.2f supera el máximo %.2f — motivo: %s"
				% [clave, r["valor"], r["maximo"], p.get("motivo", "")]); return 1
	return 0
```

5. **Presupuestos de tamaño.** El que más se degrada y menos se vigila:

```python
#!/usr/bin/env python3
"""Comprueba los presupuestos de tamaño de la build y de los assets."""
import json, os, sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIMITES = json.load(open(os.path.join(RAIZ, "pruebas/rendimiento/presupuestos.json"),
                         encoding="utf-8"))["presupuestos"]

def mb(ruta):
    return os.path.getsize(ruta) / (1024 * 1024)

def main():
    fallos = 0
    build = os.path.join(RAIZ, "build", "juego.pck")
    if os.path.exists(build):
        tam = mb(build)
        maximo = LIMITES["build_mb"]["max"]
        if tam > maximo:
            print(f"::error::la build ocupa {tam:.1f} MB (máximo {maximo})")
            fallos += 1
        else:
            print(f"  OK    build {tam:.1f} MB / {maximo}")

    # El asset gordo que entra sin que nadie lo vea es el clásico de esta
    # categoría: nadie mira el tamaño de un PNG al revisar un PR.
    maximo_tex = LIMITES["textura_mayor_mb"]["max"]
    for cur, _, ficheros in os.walk(os.path.join(RAIZ, "assets")):
        for f in ficheros:
            if not f.lower().endswith((".png", ".jpg", ".webp", ".exr")):
                continue
            ruta = os.path.join(cur, f)
            tam = mb(ruta)
            if tam > maximo_tex:
                print(f"::error::{os.path.relpath(ruta, RAIZ)} ocupa {tam:.1f} MB "
                      f"(máximo {maximo_tex})")
                fallos += 1

    print(f"== presupuestos de tamaño: {fallos} fallo(s) ==")
    return 1 if fallos else 0

if __name__ == "__main__":
    sys.exit(main())
```

6. **La línea base.** Versionada, y con historia:

```json
{
  "generada_en": "2026-03-14",
  "commit": "a1b2c3d",
  "runner": "ubuntu-latest / 4 vCPU",
  "nota": "línea base tras migrar el inventario a array de ranuras (#412)",
  "valores": {
    "carga_catalogos_ms": 68.4,
    "tick_logica_ms": 412.0,
    "inventario_10k_ms": 95.2
  }
}
```

Subir la línea base es una acción **deliberada**: se hace en un commit propio, con su motivo en el campo `nota`, y se revisa. Nunca se actualiza automáticamente al fallar — eso es lo mismo que borrar la prueba.

```bash
python scripts/actualizar_baseline.py --motivo "el nuevo pathfinding cuesta 8 ms más y lo aceptamos"
```

7. **En CI.** Con la particularidad importante: los runners son ruidosos.

```yaml
  rendimiento:
    name: Presupuestos de rendimiento
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Instalar Godot
        run: # (igual que en el resto de jobs)
      - name: Medir
        run: |
          set -euo pipefail
          # Dos pasadas: si la primera detecta regresión, se repite. Una
          # regresión real se repite; el ruido del runner, casi nunca.
          if ! godot --headless --script res://pruebas/rendimiento/medir.gd; then
            echo "Primera pasada con regresión: confirmando..."
            godot --headless --script res://pruebas/rendimiento/medir.gd
          fi
      - name: Presupuestos de tamaño
        run: python scripts/presupuestos_tamano.py
```

8. **Ruido: lo que hay que saber antes de confiar en un número.** En un runner compartido, la varianza entre ejecuciones puede ser del 10-20 %. Estrategias, por orden de eficacia:

1. **Medir trabajo, no tiempo, cuando se pueda**: número de operaciones, de asignaciones, de nodos creados. No tiene ruido.
2. **Mediana de 9 iteraciones** con 2 de calentamiento.
3. **Comparar contra la base medida en el mismo tipo de runner.**
4. **Tolerancia del 8-10 %** y confirmación con una segunda pasada.
5. **Rechazar el veredicto** si la dispersión es alta, en lugar de inventar uno.

La primera es la más infravalorada: `assert(asignaciones <= 3)` en un test es completamente estable y detecta regresiones que el tiempo esconde.

## ✍️ Ejercicios

1. Define los presupuestos de tu juego con su dispositivo objetivo y el motivo de cada número.
2. Añade un contador de asignaciones a tu bucle principal y conviértelo en presupuesto sin ruido.
3. Mide el arranque de tu juego 20 veces y calcula mediana, p95 y dispersión.
4. Introduce a propósito una regresión del 20 % y comprueba que el sistema la detecta.
5. Introduce una del 3 % y comprueba que **no** produce falso positivo.
6. Añade el presupuesto de tamaño de build a tu CI y comprueba que falla con un asset grande.
7. Escribe el procedimiento de tu equipo para actualizar la línea base.

## 📝 Reto verificable

Implementa un sistema de presupuestos de rendimiento con **al menos cinco métricas** (arranque, tick de lógica, carga de catálogos, una operación intensiva y tamaño de build), medición con mediana y calentamiento, línea base versionada, detección de regresión relativa con tolerancia, rechazo de mediciones no fiables e integración en CI.

**Criterio de aceptación**: (a) `godot --headless --script res://pruebas/rendimiento/medir.gd` imprime cada métrica con su veredicto y devuelve código distinto de 0 solo cuando hay regresión o se supera un presupuesto; (b) introducir una regresión artificial del 25 % en cualquier escenario hace fallar el job **indicando la métrica, el valor y la base**; (c) una variación del 3 % no produce ningún fallo; (d) cuando la dispersión intercuartílica supera el 25 %, el sistema informa de medición no fiable y **no** falla; (e) el script de tamaño detecta un asset que supera el límite y lo nombra; (f) la línea base está versionada en git con commit, runner y motivo, y existe un script que la actualiza de forma explícita.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El job de rendimiento falla constantemente y se desactiva | Umbrales absolutos sin margen en un runner ruidoso. Regresión relativa con tolerancia y confirmación. |
| La línea base se actualiza sola al fallar | Eso elimina la prueba. Actualización manual, en su propio commit y con motivo. |
| Se mide con la media y un pico lo arruina | La media no es robusta. Usa mediana y percentiles. |
| El primer resultado siempre es peor | Falta calentamiento. Descarta las primeras iteraciones. |
| Dos ejecuciones dan resultados incomparables | El escenario no es determinista. Usa un replay o una secuencia fija. |
| Nadie mira los números aunque estén | El job no bloquea. Un presupuesto que no falla el build no es un presupuesto. |
| La build creció 200 MB y nadie se enteró | No hay presupuesto de tamaño. Añádelo: es el más fácil y el más rentable. |
| El presupuesto se sube cada vez que molesta | No hay motivo escrito. Exige justificar el número en el propio archivo. |

## ❓ Preguntas frecuentes

**❓ ¿Se puede medir rendimiento en CI de forma fiable?** El tiempo absoluto, no; las **regresiones relativas**, sí, si mides con mediana, comparas contra una base del mismo tipo de runner y aceptas una tolerancia. Y las métricas de **trabajo** (asignaciones, operaciones, tamaño) son perfectamente fiables porque no dependen del reloj.

**❓ ¿No basta con perfilar de vez en cuando?** Perfilar te dice dónde está el problema **hoy**; el presupuesto te avisa el día que aparece. Son complementarios, y el segundo es el que evita que llegues a necesitar el primero con urgencia antes de una release.

**❓ ¿Qué hago cuando una regresión está justificada?** Actualizar la línea base **en un commit propio**, con el motivo escrito. Eso deja constancia de que alguien decidió gastar esos 8 ms y por qué, que es exactamente lo que querías tener a los seis meses.

**❓ ¿Presupuestos absolutos o relativos?** Los dos, y por razones distintas. El absoluto viene del dispositivo objetivo y no se negocia (por encima de 16,6 ms no hay 60 fps, digan lo que digan las bases). El relativo detecta la degradación lenta mucho antes de que llegue al absoluto.

**❓ ¿Cómo mido el frame time sin GPU en CI?** No lo mides: mides el **tiempo de lógica**, que es lo que sí es reproducible sin tarjeta y suele ser donde entran las regresiones de código. El frame time completo se mide en máquinas de prueba con GPU, con menos frecuencia (antes de cada release) y con su propia base.

## 🔗 Referencias

- Godot Docs — Optimización y profiling: <https://docs.godotengine.org/en/4.3/tutorials/performance/index.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `Performance` (monitores del motor): <https://docs.godotengine.org/en/4.3/classes/class_performance.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `Time` (medición de alta resolución): <https://docs.godotengine.org/en/4.3/classes/class_time.html> · uso: respalda el Tema 3 «Medición reproducible»
- Google — *Site Reliability Engineering*, SLO y presupuestos de error: <https://sre.google/books/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- GitHub Docs — Actions y jobs de CI: <https://docs.github.com/actions> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 320 - Testing de producción](../320-testing-de-produccion/README.md)

## ➡️ Siguiente clase

[Clase 322 - Build y release engineering](../322-build-y-release-engineering/README.md)
