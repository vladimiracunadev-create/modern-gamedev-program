# Clase 328 — Código generado por IA con verificación

> Parte: **20 — IA generativa y desarrollo de juegos asistido por IA** · Fuente: *Prácticas de revisión de código y testing · OWASP Top 10 for LLM Applications*
> ⏱️ Duración estimada: **110 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Establecer el **ciclo de verificación obligatorio** para todo código generado: `generar → compilar → probar → inspeccionar → perfilar → validar`. Y establecer la regla que lo justifica: **el código generado es una propuesta, no una solución**. Compila, parece correcto, sigue el estilo — y puede estar mal de formas que el código escrito a mano rara vez está.

Esta clase no es sobre desconfianza genérica. Es sobre los **modos de fallo específicos** del código generado, que son distintos de los humanos: usa APIs que no existen, resuelve el caso general ignorando el particular que importaba, introduce dependencias silenciosas, y —el más peligroso— es plausible en la superficie y erróneo en un caso límite que nadie mira. Vas a aprender a detectar cada uno con una comprobación concreta, y a integrar todo eso en la CI para que no dependa de la disciplina de nadie.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Aplicar el ciclo de verificación completo a cualquier código generado.
2. Enumerar los modos de fallo típicos del código generado y su comprobación específica.
3. Detectar APIs inexistentes, dependencias nuevas y cambios de alcance automáticamente.
4. Escribir tests **antes** de generar, para que el criterio no lo ponga el generador.
5. Revisar con foco en los casos límite y en el manejo de errores.
6. Verificar que un cambio no ha empeorado el rendimiento ni el determinismo.
7. Integrar todo el ciclo en CI y en la revisión de cambios.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | El ciclo obligatorio | Convierte una norma en un procedimiento. |
| 2 | Compilar no es funcionar | El primer filtro, y el más engañoso. |
| 3 | Tests antes de generar | Si el criterio lo pone el generador, no hay criterio. |
| 4 | APIs inexistentes | El fallo más frecuente y el más fácil de detectar. |
| 5 | Casos límite | Donde el código generado falla de forma característica. |
| 6 | Manejo de errores | Casi siempre optimista de más. |
| 7 | Dependencias silenciosas | Se cuelan sin que nadie las apruebe. |
| 8 | Determinismo y rendimiento | Dos regresiones invisibles a la vista. |
| 9 | Seguridad | Validación de entrada y datos del jugador. |
| 10 | En la CI | Lo que no está automatizado, no ocurre. |

## 📖 Definiciones y características

- **Código generado**: el producido por un modelo, con o sin agente. Clave: es una propuesta hasta que pasa la verificación.
- **Ciclo de verificación**: secuencia de comprobaciones obligatorias antes de aceptar. Clave: cada paso detecta una familia de fallos distinta.
- **Plausibilidad**: parecer correcto sin serlo. Clave: es la propiedad que hace peligroso el código generado.
- **API alucinada**: llamada a un método o clase que no existe. Clave: la detecta el compilador o un análisis estático.
- **Caso límite**: entrada extrema o inusual (cero, vacío, máximo, negativo, nulo). Clave: es donde falla característicamente.
- **Manejo optimista**: asumir que todo va bien, sin comprobar nulos ni errores. Clave: patrón muy frecuente en código generado.
- **Dependencia silenciosa**: biblioteca o recurso nuevo introducido sin aprobación. Clave: afecta a licencias, tamaño y seguridad.
- **Deriva de estilo**: código que no sigue las convenciones del proyecto. Clave: cosmético, pero degrada el repositorio con el tiempo.
- **Regresión de determinismo**: introducir aleatoriedad o dependencia temporal no controlada. Clave: rompe replays y tests, y no da error.
- **Regresión de rendimiento**: solución correcta pero más lenta. Clave: la detectan los presupuestos de la clase 321.
- **Test escrito antes**: prueba redactada por una persona antes de generar la implementación. Clave: garantiza que el criterio es tuyo.
- **Inspección dirigida**: revisión enfocada en los puntos de fallo conocidos. Clave: mucho más eficaz que leer de arriba abajo.
- **Análisis estático**: comprobación automática sin ejecutar. Clave: detecta APIs inexistentes y tipos incorrectos.
- **Superficie de cambio**: conjunto de archivos y líneas afectados. Clave: si crece más de lo previsto, hay que mirar.

## 🧰 Herramientas y preparación

Godot 4.x, `--headless` para compilar y ejecutar tests, GUT o scripts `SceneTree` (Parte 15 y clase 320), los presupuestos de rendimiento de la [clase 321](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/321-performance-regression-testing/README.md) y los replays deterministas de la [clase 308](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/308-commands-input-recording-y-replays/README.md). Trabajaremos en `scripts/verificar/` y en la CI. Todo lo de esta clase es **independiente del generador**: se aplica igual venga el código de donde venga.

## 🧪 Laboratorio guiado

1. **El ciclo, con lo que detecta cada paso:**

```text
1. GENERAR      con la especificación de la clase 326
       │
2. COMPILAR     ──► APIs inexistentes, errores de sintaxis y de tipo
       │            godot --headless --check-only / --import
3. PROBAR       ──► lógica incorrecta en los casos que TÚ escribiste
       │            los tests, escritos ANTES
4. INSPECCIONAR ──► casos límite, manejo de errores, dependencias, estilo
       │            revisión humana dirigida
5. PERFILAR     ──► regresiones de rendimiento y de determinismo
       │            presupuestos (clase 321) + replays (clase 308)
6. VALIDAR      ──► ¿resuelve el problema real?  ← lo único que no se automatiza
```

El paso 6 es el que no se puede delegar: los cinco anteriores comprueban que el código **hace lo que dice**; el sexto, que **era eso lo que hacía falta**.

2. **Los tests, antes.** Es la inversión del orden habitual, y es deliberada:

```gdscript
# pruebas/ordenar_inventario_test.gd
# ESCRITO ANTES de generar `Inventario.ordenar()`. Si los tests se escriben
# después, y peor aún si los escribe el mismo generador, acaban describiendo lo
# que el código hace en vez de lo que debería hacer.
extends SceneTree

func _init() -> void:
	var hechas := 0; var fallos := 0
	var check := func(ok: bool, que: String):
		hechas += 1
		if not ok: fallos += 1; printerr("  FALLA  ", que)

	# 1. Conservación: la propiedad que NUNCA puede romperse.
	var inv := _inv_con({&"pocion_menor": 47, &"mineral_hierro": 13, &"espada_hierro": 2})
	var antes := _cuenta_por_item(inv)
	inv.ordenar()
	check.call(_cuenta_por_item(inv) == antes, "ordenar no cambia el total por item")

	# 2. Compactación.
	check.call(_stacks_parciales(inv, &"pocion_menor") <= 1, "no quedan dos stacks parciales")

	# 3. Huecos al final.
	check.call(_huecos_al_final(inv), "las ranuras vacías quedan al final")

	# 4. Idempotencia.
	var d1 := inv.a_dict(); inv.ordenar()
	check.call(inv.a_dict() == d1, "ordenar dos veces no cambia nada")

	# 5. Casos límite: vacío y lleno. Los que el código generado suele fallar.
	var vacio := Inventario.new(_base, 10)
	vacio.ordenar()
	check.call(vacio.libres() == 10, "ordenar un inventario vacío no rompe nada")

	var lleno := _inv_lleno_sin_huecos()
	var antes_lleno := lleno.a_dict()
	lleno.ordenar()
	check.call(_cuenta_por_item(lleno) == _cuenta_de(antes_lleno),
		"ordenar un inventario lleno conserva todo")

	# 6. Señales: solo de lo que cambió.
	var emitidas := []
	var inv2 := _inv_ya_ordenado()
	inv2.ranura_cambiada.connect(func(i): emitidas.append(i))
	inv2.ordenar()
	check.call(emitidas.is_empty(), "ordenar algo ya ordenado no emite señales")

	print("== %d comprobaciones, %d fallos ==" % [hechas, fallos])
	quit(1 if fallos > 0 else 0)
```

3. **Detectar APIs inexistentes.** El fallo más frecuente, y automatizable:

```python
#!/usr/bin/env python3
"""Detecta llamadas a métodos que no existen en las clases del proyecto.

El compilador de GDScript pilla muchos casos, pero no todos: las llamadas
dinámicas sobre `Variant` pasan de largo y explotan en runtime.
"""
import os, re, sys, subprocess

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LLAMADA = re.compile(r"\b([A-Z]\w+)\.(\w+)\s*\(")

def metodos_declarados():
    """clase -> {métodos} a partir de los `class_name` del proyecto."""
    mapa = {}
    for cur, _, ficheros in os.walk(os.path.join(RAIZ, "res")):
        for f in ficheros:
            if not f.endswith(".gd"):
                continue
            texto = open(os.path.join(cur, f), encoding="utf-8").read()
            m = re.search(r"^class_name\s+(\w+)", texto, re.M)
            if not m:
                continue
            mapa[m.group(1)] = set(re.findall(r"^\s*(?:static\s+)?func\s+(\w+)", texto, re.M))
    return mapa

def main():
    declarados = metodos_declarados()
    fallos = []
    for cur, _, ficheros in os.walk(os.path.join(RAIZ, "res")):
        for f in ficheros:
            if not f.endswith(".gd"):
                continue
            ruta = os.path.join(cur, f)
            for n, linea in enumerate(open(ruta, encoding="utf-8"), 1):
                for clase, metodo in LLAMADA.findall(linea):
                    # Solo comprobamos NUESTRAS clases: las del motor las valida Godot.
                    if clase in declarados and metodo not in declarados[clase]:
                        fallos.append(f"{os.path.relpath(ruta, RAIZ)}:{n}: "
                                      f"{clase}.{metodo}() no existe")
    for x in fallos:
        print(f"::error::{x}")
    print(f"== APIs comprobadas: {len(fallos)} inexistente(s) ==")
    return 1 if fallos else 0

if __name__ == "__main__":
    sys.exit(main())
```

4. **Los modos de fallo característicos.** Cada uno con su comprobación:

| Modo de fallo | Ejemplo típico | Cómo se detecta |
|---|---|---|
| API inexistente | `Array.remove(i)` (en Godot 4 es `remove_at`) | Compilación + script del paso 3 |
| Caso límite ignorado | Divide sin comprobar cero; itera sin comprobar vacío | Tests de límites escritos antes |
| Manejo optimista | `FileAccess.open(...).get_as_text()` sin comprobar null | Búsqueda de patrón + revisión |
| Off-by-one | `for i in range(n - 1)` donde debía ser `n` | Test con el caso de tamaño 1 |
| Aleatoriedad no controlada | `randf()` global en lugar del RNG inyectado | Búsqueda + test de replay |
| Dependencia temporal | `Time.get_ticks_msec()` en `dominio/` | Búsqueda + test de determinismo |
| Dependencia nueva | Un `preload` de algo que no estaba | Diff de importaciones |
| Complejidad innecesaria | Una jerarquía de clases para tres casos | Revisión humana |
| Rendimiento | Bucle anidado donde había un diccionario | Presupuestos (clase 321) |
| Validación ausente | Confía en el dato del jugador | Revisión de seguridad |

5. **La inspección dirigida.** Búsquedas concretas, no lectura lineal:

```bash
grep -rnE "randf\(\)|randi\(\)|randomize\(\)" res/dominio/
```

```bash
grep -rnE "Time\.get_ticks|Time\.get_unix|OS\.get_time" res/dominio/
```

```bash
grep -rnE "(FileAccess\.open|get_node|instantiate)\([^)]*\)\.\w+" res/
```

```bash
git diff --name-only | xargs grep -l "^preload\|^const .* = preload" || true
```

Cada una de esas cuatro búsquedas corresponde a una fila de la tabla anterior. Automatizadas, tardan un segundo; a ojo, se olvidan.

6. **Determinismo y rendimiento.** Las dos regresiones que no dan error:

```gdscript
# pruebas/determinismo_test.gd — la misma semilla debe dar el mismo resultado.
extends SceneTree

func _init() -> void:
	var a := _simular(semilla=777, ticks=600)
	var b := _simular(semilla=777, ticks=600)
	var c := _simular(semilla=778, ticks=600)

	var fallos := 0
	if a != b:
		fallos += 1
		printerr("  el sistema NO es determinista con la misma semilla")
		printerr("  (busca randf() global, Time.* o iteración de Dictionary sin ordenar)")
	if a == c:
		fallos += 1
		printerr("  dos semillas distintas dan el mismo resultado: ¿se usa la semilla?")

	print("== 2 comprobaciones, %d fallos ==" % fallos)
	quit(1 if fallos > 0 else 0)
```

Y el rendimiento, con los presupuestos que ya tienes de la clase 321: un cambio generado que sustituya una búsqueda en diccionario por un bucle sobre un array **funcionará perfectamente** y multiplicará el coste por mil. Los tests no lo ven; el presupuesto, sí.

7. **La revisión humana, con foco.** Preguntas, no lectura:

```markdown
## Lista de revisión de código generado

### Corrección
- [ ] ¿Qué pasa con entrada vacía, cero, negativa, nula y el máximo?
- [ ] ¿Los bucles cubren el primer y el último elemento?
- [ ] ¿Se comprueban los retornos que pueden ser `null`?
- [ ] ¿Los errores se manejan o se ignoran?

### Encaje
- [ ] ¿Usa las clases y utilidades que ya existen en el proyecto?
- [ ] ¿Respeta la regla de dependencia entre capas?
- [ ] ¿Sigue las convenciones de `CONVENCIONES.md`?
- [ ] ¿Ha aparecido alguna dependencia nueva?

### Riesgos silenciosos
- [ ] ¿Introduce aleatoriedad o dependencia del reloj no controlada?
- [ ] ¿Puede ser más lento que lo que sustituye?
- [ ] ¿Valida los datos que vienen del jugador o de la red?
- [ ] ¿Se ha modificado algún test para que pase?

### Lo esencial
- [ ] ¿Resuelve el problema que teníamos, o uno parecido?
- [ ] ¿Podría mantenerlo alguien del equipo dentro de seis meses?
```

8. **En la CI.** Lo que no está automatizado no ocurre:

```yaml
  verificacion:
    name: Verificación de código
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Instalar Godot
        run: bash scripts/instalar_godot.sh

      - name: Compilar (detecta APIs inexistentes y errores de tipo)
        run: |
          set -euo pipefail
          godot --headless --path . --import 2>&1 | tee import.log
          if grep -E "SCRIPT ERROR|Parse Error|ERROR:" import.log; then
            echo "::error::el proyecto no compila limpio"; exit 1
          fi

      - name: APIs del proyecto
        run: python scripts/verificar/apis.py

      - name: Patrones prohibidos en dominio/
        run: |
          set -euo pipefail
          # El dominio no puede usar aleatoriedad global ni el reloj del
          # sistema: rompería replays, tests y determinismo de red.
          if grep -rnE "randf\(\)|randi\(\)|Time\.get_" res/dominio/; then
            echo "::error::patrón prohibido en dominio/ (usa RNG inyectado y tick(delta))"
            exit 1
          fi

      - name: Tests
        run: godot --headless --script res://pruebas/todos.gd

      - name: Determinismo
        run: godot --headless --script res://pruebas/determinismo_test.gd

      - name: Replays de regresión
        run: godot --headless --script res://pruebas/replays_test.gd

      - name: Presupuestos de rendimiento
        run: godot --headless --script res://pruebas/rendimiento/medir.gd
```

## ✍️ Ejercicios

1. Escribe los tests de una función **antes** de implementarla y compara con tu costumbre habitual.
2. Implementa el detector de APIs inexistentes y pásalo por tu proyecto: cuenta los hallazgos.
3. Añade a la CI la comprobación de patrones prohibidos en `dominio/`.
4. Coge un fragmento de código generado y aplícale la lista de revisión completa; anota qué encuentras.
5. Introduce a propósito un `randf()` global y comprueba que el test de determinismo lo detecta.
6. Comprueba con los presupuestos que un cambio no ha empeorado el rendimiento.
7. Documenta la política de tu equipo: qué verificación es obligatoria antes de aceptar código generado.

## 📝 Reto verificable

Implementa el ciclo de verificación completo y automatizado: compilación limpia, detector de APIs inexistentes del proyecto, comprobación de patrones prohibidos por capa, batería de tests con casos límite escritos antes, test de determinismo, replays de regresión y presupuestos de rendimiento; todo integrado en un job de CI.

**Criterio de aceptación**: (a) el job falla si se introduce una llamada a un método inexistente de una clase del proyecto, **indicando archivo, línea y método**; (b) falla si aparece `randf()`, `randi()` o `Time.get_*` dentro de `dominio/`; (c) falla si el sistema deja de ser determinista con la misma semilla; (d) falla si un replay de regresión diverge, indicando el tick; (e) falla si un presupuesto de rendimiento se supera; (f) los tests de casos límite cubren, para al menos una función, entrada vacía, cero, negativa, máxima y máxima más uno; (g) la lista de revisión humana está documentada en el repositorio e incluye la comprobación de tests modificados.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| "Invalid call. Nonexistent function" en runtime | API alucinada que el compilador no vio. Detector estático + tipado estricto. |
| El código funciona con datos normales y falla con vacío | Caso límite ignorado. Escribe los tests de límites antes. |
| Los replays empiezan a divergir sin motivo | Se coló aleatoriedad o el reloj. Comprobación de patrones prohibidos. |
| El juego va más lento tras un cambio "equivalente" | Regresión de rendimiento. Presupuestos en CI. |
| Aparece una dependencia nueva en el proyecto | No se revisó el diff de importaciones. Añádelo a la revisión. |
| Los tests pasan y el bug sigue | Los tests se escribieron después y describen el código. Escríbelos antes. |
| Se acepta el código porque compila | Compilar es el primer filtro, no el último. Ciclo completo. |
| El código no encaja con lo que ya existe | Falta contexto en la generación y revisión de encaje. Ambas cosas. |

## ❓ Preguntas frecuentes

**❓ ¿No es todo esto lo que ya se hace con cualquier código?** En buena medida sí, y esa es la conclusión tranquilizadora: **no hace falta un proceso nuevo, hace falta aplicar el que ya deberías tener**. Lo que cambia es el énfasis: el código generado falla más en casos límite y en manejo de errores, y menos en sintaxis. La revisión se enfoca ahí.

**❓ ¿Escribir los tests antes no es más lento?** Al principio sí, unos minutos. Después es más rápido, porque el criterio queda fijado y no hay discusión sobre si el resultado es correcto. Y en el contexto de esta parte tiene una razón añadida: **si el criterio lo pone el generador, no hay criterio**.

**❓ ¿Cuánto código generado revisáis línea a línea?** Regla práctica: **todo lo que toque seguridad, economía, guardado o red, línea a línea**; el resto, por muestreo (tres archivos al azar) más las comprobaciones automáticas. Si la muestra sale mal, se revisa entero.

**❓ ¿Y si el código generado es mejor que el mío?** Puede serlo, y no cambia nada del proceso: sigue teniendo que compilar, pasar tests, no introducir dependencias y ser mantenible por el equipo. El criterio no es quién lo escribió, es si cumple.

**❓ ¿Merece la pena si genero poco código?** Sí, porque todas estas comprobaciones son útiles al margen del origen del código: el detector de APIs, los patrones prohibidos por capa, el test de determinismo y los presupuestos detectan errores humanos exactamente igual. La IA solo ha hecho más evidente que hacían falta.

## 🔗 Referencias

- OWASP — Top 10 for LLM Applications (manejo inseguro de salidas): <https://owasp.org/www-project-top-10-for-large-language-model-applications/> · uso: respalda el Tema 6 «Manejo de errores»
- Godot Docs — GDScript tipado estático: <https://docs.godotengine.org/en/4.3/tutorials/scripting/gdscript/static_typing.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — Command line tutorial (`--import`, `--script`): <https://docs.godotengine.org/en/4.3/tutorials/editor/command_line_tutorial.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- GUT — Godot Unit Test: <https://github.com/bitwes/Gut> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- GitHub Docs — Actions: <https://docs.github.com/actions> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 327 - Agentes de programación para GameDev](../327-agentes-de-programacion-para-gamedev/README.md)

## ➡️ Siguiente clase

[Clase 329 - Assets generativos y provenance](../329-assets-generativos-y-provenance/README.md)
