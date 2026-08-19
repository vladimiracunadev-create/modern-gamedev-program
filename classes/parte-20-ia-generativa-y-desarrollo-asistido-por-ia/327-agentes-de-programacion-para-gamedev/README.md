# Clase 327 — Agentes de programación para GameDev

> Parte: **20 — IA generativa y desarrollo de juegos asistido por IA** · Fuente: *Documentación de las herramientas de agentes de programación · Prácticas de revisión de código y CI*
> ⏱️ Duración estimada: **110 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Trabajar con **agentes de programación** —sistemas que leen un repositorio, planifican, editan varios archivos, ejecutan builds y tests, y iteran— de forma que el resultado sea verificable y el proceso siga siendo tuyo. La diferencia con la clase anterior es de naturaleza: allí pedías texto y lo copiabas; aquí el sistema **actúa** sobre tu proyecto.

Eso cambia las reglas. Un agente puede ahorrarte una migración de 200 archivos o dejarte un repositorio en un estado que no entiendes. La disciplina que separa ambos resultados es concreta: **alcance acotado, entorno aislado, verificación automática, revisión humana obligatoria y un historial de git que cuente lo que pasó**. Vas a diseñar ese flujo de trabajo y a decidir qué tareas de gamedev son buenas candidatas y cuáles no.

El contenido es **independiente de proveedor**: se describen capacidades y patrones, no una herramienta concreta, porque las herramientas cambian y los patrones no.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Describir el bucle de un agente de programación y sus puntos de control.
2. Clasificar tareas de gamedev por su idoneidad para delegar en un agente.
3. Preparar un repositorio para que un agente trabaje bien en él.
4. Definir límites: qué puede tocar, qué no, y qué debe pedir confirmación.
5. Diseñar la verificación automática que un agente debe pasar antes de que mires nada.
6. Revisar el resultado de un agente con criterio y en tiempo razonable.
7. Reconocer las señales de que hay que parar y hacerlo a mano.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | El bucle del agente | Entenderlo permite intervenir en el punto correcto. |
| 2 | Tareas idóneas | La elección de tarea determina el resultado más que nada. |
| 3 | Repositorio preparado | Un repo con CI y convenciones escritas multiplica el rendimiento. |
| 4 | Alcance y límites | Sin ellos, el cambio se extiende a donde no debía. |
| 5 | Aislamiento | Rama o worktree: nunca sobre lo que estás usando. |
| 6 | Verificación automática | Es la condición para que revisar sea barato. |
| 7 | Revisión humana | Obligatoria, y con técnica propia. |
| 8 | Historial de git | Un commit gigante no se puede revisar ni revertir. |
| 9 | Coste de la delegación | Delegar tiene un coste fijo que hay que amortizar. |
| 10 | Cuándo parar | Reconocer el bucle improductivo. |

## 📖 Definiciones y características

- **Agente de programación**: sistema que usa un modelo para leer, planificar, editar y verificar código de forma iterativa. Clave: actúa, no solo responde.
- **Bucle del agente**: ciclo leer → planificar → actuar → verificar → repetir. Clave: la verificación es lo que lo hace converger.
- **Herramienta (tool)**: capacidad concreta del agente (leer archivo, buscar, editar, ejecutar comando). Clave: define lo que puede y no puede hacer.
- **Alcance (scope)**: conjunto de archivos y acciones permitidas para una tarea. Clave: acotarlo es la primera medida de seguridad.
- **Aislamiento**: ejecutar en una rama, un worktree o un contenedor separado. Clave: permite descartar el resultado sin coste.
- **Punto de control (checkpoint)**: momento en que el agente se detiene y pide confirmación. Clave: se coloca antes de lo irreversible.
- **Verificación automática**: build, lint y tests que el agente debe pasar. Clave: sin ella, revisar cuesta más que hacerlo a mano.
- **Bucle improductivo**: el agente alterna entre dos estados sin avanzar. Clave: se reconoce por la repetición y hay que cortarlo.
- **Deriva de alcance**: el cambio se extiende a archivos no previstos. Clave: se detecta mirando el diff antes que el código.
- **Commit atómico**: un cambio coherente por commit. Clave: hace revisable y reversible el trabajo.
- **Contexto del repositorio**: documentación que el agente lee para conocer convenciones. Clave: es la inversión de mayor retorno.
- **Coste de delegación**: tiempo de preparar, supervisar y revisar. Clave: si supera al de hacerlo, no delegues.
- **Cambio mecánico**: transformación repetitiva y verificable (renombrar, migrar API, añadir tests). Clave: es la categoría ideal.
- **Cambio de criterio**: requiere decisiones de diseño o de producto. Clave: no se delega; se decide y luego, si acaso, se delega la ejecución.

## 🧰 Herramientas y preparación

Cualquier agente de programación al que tengas acceso, o ninguno: **el diseño del flujo de trabajo y de la verificación es el entregable**, y vale igual. Trabajaremos sobre un repositorio Godot con CI (Parte 15) y con las convenciones escritas. Necesitas git con ramas o worktrees. Si tu proyecto aún no tiene CI, empieza por ahí: es el requisito previo de todo lo demás.

## 🧪 Laboratorio guiado

1. **El bucle, y dónde intervenir.** No en todos los pasos hace falta:

```text
┌── 1. LEER ────────► explora el repo, busca, abre archivos
│                     ▲ Intervención: darle el contexto correcto (paso 3)
│
├── 2. PLANIFICAR ──► propone los pasos
│                     ▲ Intervención: REVISAR EL PLAN. El punto más rentable.
│
├── 3. ACTUAR ──────► edita archivos, crea, borra
│                     ▲ Intervención: límites de alcance (paso 4)
│
├── 4. VERIFICAR ───► build, lint, tests
│                     ▲ Intervención: que la verificación sea buena (paso 5)
│
└── 5. ¿OK? ────────► no → vuelve a 2 · sí → termina
                      ▲ Intervención: detectar bucle improductivo (paso 8)
```

El paso 2 merece la pena por encima de todos: **leer un plan cuesta un minuto y revisar 40 archivos cuesta una hora**. Si el plan está mal, corrígelo antes de que se ejecute.

2. **Qué delegar.** La elección de tarea importa más que cualquier otra cosa:

| Tarea | Idoneidad | Por qué |
|---|---|---|
| Migrar una API deprecada en 80 archivos | ✅ Excelente | Mecánico, verificable por compilación |
| Añadir tests a un módulo sin cobertura | ✅ Excelente | Verificable: pasan o no |
| Renombrar un concepto en todo el proyecto | ✅ Muy buena | Mecánico, y el diff se revisa rápido |
| Escribir el validador de un esquema existente | ✅ Muy buena | Criterios claros, test inmediato |
| Convertir prints en logs estructurados | ✅ Buena | Mecánico con criterio simple |
| Traducir comentarios de un idioma a otro | ✅ Buena | Revisable en diff |
| Implementar un sistema nuevo de gameplay | ⚠️ Con cuidado | Delega la ejecución, decide tú el diseño |
| Diseñar la arquitectura del proyecto | ❌ No | Decisión de contexto, equipo y plazo |
| Ajustar el game feel de un salto | ❌ No | Se juzga jugando, no verificando |
| Balancear una economía | ❌ No | Requiere datos, criterio y objetivos de producto |
| Cambiar el formato del save | ❌ No solo | Riesgo alto: revisa cada línea de la migración |

La regla: **delega lo mecánico y lo verificable; decide tú lo que requiere criterio**. Un agente es excelente ejecutando una decisión y mediocre tomándola.

3. **Preparar el repositorio.** Lo que más rendimiento da, con diferencia:

```markdown
<!-- CONVENCIONES.md — leído por cualquiera que entre al proyecto, humano o no -->
# Convenciones del proyecto

## Arquitectura
- `dominio/`: lógica pura. NO extiende Node, NO usa `get_node`, `$` ni `get_tree()`.
- `gameplay/`: nodos que conectan dominio y mundo.
- `presentacion/`: UI y efectos. Solo lee estado y reacciona a señales.
- `infraestructura/`: guardado, red, telemetría.
- Regla de dependencia: las capas exteriores conocen a las interiores, nunca al revés.

## Código
- GDScript con tipado estático siempre que sea posible (`var x: int`).
- Aleatoriedad: `RandomNumberGenerator` inyectado. NUNCA `randf()` global.
- Tiempo: `tick(delta)` explícito en dominio. NUNCA `_process` en `dominio/`.
- Comentarios en español y solo donde expliquen un PORQUÉ no obvio.

## Verificación (obligatoria antes de proponer un cambio)
    python scripts/validar_estructura.py
    godot --headless --script res://pruebas/todos.gd
    npx markdownlint-cli2 "**/*.md"

## Qué NO tocar sin confirmación explícita
- `classes/**` (contenido del curso)
- `.github/workflows/**`
- `SAVE_VERSION` y `scripts/release/**`
```

Ese archivo hace tres cosas a la vez: orienta a un agente, orienta a una persona nueva y documenta decisiones que hoy solo están en la cabeza de alguien. Es la mejor relación esfuerzo/beneficio de esta clase.

4. **Límites y puntos de control.** Explícitos, en la propia tarea:

```markdown
## Tarea
Migrar todas las llamadas a `Sistema.viejo_metodo(a, b)` a
`Sistema.nuevo_metodo({"a": a, "b": b})`.

## Alcance
- PUEDES tocar: `res://gameplay/**`, `res://presentacion/**`
- NO toques: `res://dominio/**`, `res://datos/**`, `.github/**`, `project.godot`
- NO crees archivos nuevos.
- NO cambies ninguna firma pública.

## Puntos de control
1. Muestra la lista de archivos afectados ANTES de editar nada.
2. Para después de los 5 primeros archivos y enséñame el diff.
3. Al terminar, ejecuta la verificación completa y muestra la salida.

## Criterios
- `grep -r "viejo_metodo" res/` no devuelve nada fuera de `dominio/`.
- La verificación completa pasa.
- Un commit por cada 10 archivos, con mensaje descriptivo.
```

5. **Aislamiento.** Nunca sobre la rama en la que estás trabajando:

```bash
git worktree add ../proyecto-migracion -b migracion/api-sistemas
```

```bash
git -C ../proyecto-migracion diff main --stat
```

El worktree da una copia independiente del repositorio: si el resultado no sirve, se borra la carpeta y no ha pasado nada. Y mientras el agente trabaja, tú puedes seguir en tu rama sin conflictos.

6. **La verificación.** Un único comando, y que sea el mismo que la CI:

```python
#!/usr/bin/env python3
"""Verificación completa. Es lo que un agente debe pasar antes de proponer nada.

Un solo comando y la MISMA verificación que la CI: si divergen, el agente
optimiza para un criterio que después falla en el pipeline.
"""
import subprocess, sys

PASOS = [
    ("estructura", [sys.executable, "scripts/validar_estructura.py"]),
    ("contenido",  ["godot", "--headless", "--script", "res://herramientas/validar_datos.gd"]),
    ("unitarios",  ["godot", "--headless", "--script", "res://pruebas/todos.gd"]),
    ("replays",    ["godot", "--headless", "--script", "res://pruebas/replays_test.gd"]),
    ("markdown",   ["npx", "--yes", "markdownlint-cli2", "**/*.md"]),
]

def main():
    fallos = []
    for nombre, cmd in PASOS:
        p = subprocess.run(cmd, capture_output=True, text=True)
        estado = "OK  " if p.returncode == 0 else "FALLA"
        print(f"  {estado}  {nombre}")
        if p.returncode != 0:
            fallos.append(nombre)
            print("\n".join(p.stdout.splitlines()[-15:]))
    print(f"== {len(PASOS)} comprobaciones, {len(fallos)} fallo(s) ==")
    return 1 if fallos else 0

if __name__ == "__main__":
    sys.exit(main())
```

7. **La revisión humana.** Obligatoria, y con técnica: no leas el código primero.

```text
1. EL DIFF, no el código.  git diff --stat  → ¿cuántos archivos? ¿son los previstos?
                           Si hay archivos que no esperabas, para aquí.
2. LOS BORRADOS.           git diff --diff-filter=D  → ¿por qué se borró eso?
                           Es donde se pierden cosas en silencio.
3. LO NUEVO.               ¿Hay dependencias nuevas? ¿archivos nuevos no pedidos?
4. LA MUESTRA.             Lee 3 archivos al azar del cambio, completos.
                           Si los tres están bien, el resto probablemente también.
5. LOS TESTS.              ¿Se modificó algún test para que pasara?
                           ← LA SEÑAL DE ALARMA MÁS IMPORTANTE
6. EJECÚTALO.              Abre el juego. Los tests no lo ven todo.
```

El punto 5 merece énfasis: un test modificado para que pase es un test que ya no comprueba nada. Revisa siempre los cambios en `pruebas/` con más atención que los del código.

8. **Cuándo parar.** Señales de que hay que hacerlo a mano:

| Señal | Qué significa |
|---|---|
| Tres iteraciones y el mismo test sigue rojo | La tarea no está bien planteada o falta contexto |
| El diff toca archivos que no tienen relación | Deriva de alcance: el planteamiento era vago |
| Se modificaron tests para que pasaran | Se está optimizando el criterio equivocado |
| Aparecen dependencias nuevas no pedidas | Se ha resuelto por la vía fácil, no la tuya |
| El plan cambia en cada iteración | No hay comprensión del problema; para y decídelo tú |
| Llevas más tiempo supervisando que el que habrías tardado | El coste de delegación no se amortiza |

9. **El coste de delegar.** Hazlo explícito antes de empezar:

```text
Coste de delegar = preparar la tarea + supervisar + revisar + arreglar lo que quede
Coste de hacerlo = implementar + probar

Migrar 80 archivos:  preparar 15 min + revisar 30 min  vs  hacer 6 h    → delega
Escribir una función: preparar 10 min + revisar 10 min  vs  hacer 20 min → hazla
```

La conclusión práctica es contraintuitiva: **los agentes rinden en tareas grandes y mecánicas, no en las pequeñas**. Para una función de 20 líneas, escribirla suele ser más rápido que especificarla, supervisarla y revisarla.

## ✍️ Ejercicios

1. Escribe el `CONVENCIONES.md` de tu proyecto con las tres secciones del paso 3.
2. Unifica tu verificación en un solo comando que sea idéntico al de la CI.
3. Clasifica cinco tareas de tu backlog según la tabla del paso 2 y justifica cada una.
4. Escribe la especificación con alcance y puntos de control de una migración real.
5. Prueba el flujo con worktree en una tarea mecánica y cronometra preparación, supervisión y revisión.
6. Aplica el protocolo de revisión de 6 pasos a un cambio grande de tu historial de git.
7. Documenta un caso en el que paraste y lo hiciste a mano, con la señal que lo detonó.

## 📝 Reto verificable

Entrega el flujo de trabajo completo para agentes en tu repositorio: `CONVENCIONES.md` con arquitectura, código, verificación y zonas prohibidas; un script único de verificación idéntico al de la CI; una plantilla de tarea con alcance y puntos de control; un protocolo de revisión documentado; y la ejecución real de **una tarea mecánica** con su registro.

**Criterio de aceptación**: (a) `python scripts/verificar_todo.py` ejecuta build, validaciones, tests y lint, imprime `== N comprobaciones, M fallo(s) ==` y devuelve el código correcto; (b) `CONVENCIONES.md` declara explícitamente qué rutas **no** se tocan sin confirmación; (c) la plantilla de tarea incluye alcance positivo, alcance negativo, puntos de control y criterios verificables; (d) la tarea ejecutada se hizo en una rama o worktree aislado, con **commits atómicos** (ninguno con más de 15 archivos) y mensajes descriptivos; (e) el registro documenta tiempo de preparación, supervisión y revisión, y compara con el estimado de hacerlo a mano; (f) el protocolo de revisión incluye la comprobación de que no se modificaron tests para que pasaran.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El agente cambió 200 archivos y no sabes qué pasó | Sin alcance ni puntos de control. Acota y para a los 5 archivos. |
| Los tests pasan pero el juego está roto | Se modificaron los tests. Revísalos siempre aparte y con lupa. |
| El resultado no sigue las convenciones del equipo | No estaban escritas. `CONVENCIONES.md` es el arreglo. |
| Un commit gigante imposible de revisar | Sin instrucción de atomicidad. Pide un commit por unidad coherente. |
| Se rompió algo que no estaba en el alcance | Falta el alcance negativo. Enumera lo que no se toca. |
| Se pierde más tiempo del que se ahorra | Tarea demasiado pequeña. Delega lo grande y mecánico. |
| El agente "arregla" el fallo desactivando la comprobación | La verificación era el criterio y se optimizó contra ella. Revisa qué cambió en `pruebas/`. |
| Trabajó sobre tu rama y ahora tienes conflictos | Sin aislamiento. Worktree o rama, siempre. |

## ❓ Preguntas frecuentes

**❓ ¿Puedo dejar a un agente trabajando solo?** En tareas mecánicas, con alcance acotado, en un worktree aislado y con verificación automática, sí. Sin esas cuatro condiciones, no: el problema no es que se equivoque, es que no podrás revisar el resultado en un tiempo razonable.

**❓ ¿La revisión no anula el ahorro?** No, si la tarea es grande y mecánica: revisar el diff de una migración de 80 archivos son 30 minutos; hacerla, seis horas. En tareas pequeñas sí lo anula, y por eso no se delegan.

**❓ ¿Qué pasa con el conocimiento del equipo?** Es la preocupación legítima de fondo. Si nadie entiende el código que entra, el equipo pierde capacidad. Dos contramedidas prácticas: la revisión es obligatoria y la hace alguien que tendrá que mantener eso, y el trabajo delegado se limita a lo mecánico — las decisiones de diseño siguen siendo del equipo y quedan documentadas.

**❓ ¿Y si el agente introduce una vulnerabilidad?** Es un riesgo real, especialmente en validación de entradas y en manejo de datos del jugador. Contramedidas: la verificación incluye lint de seguridad, las zonas sensibles (autenticación, economía de servidor, guardado) están en la lista de "no tocar sin confirmación", y esas áreas se revisan línea a línea. Es la misma política que aplicarías a un colaborador nuevo.

**❓ ¿Depende esto de la herramienta concreta?** Los patrones no: alcance, aislamiento, verificación, revisión y commits atómicos valen con cualquiera. Las capacidades y la interfaz sí cambian, y por eso conviene que tu inversión esté en el **repositorio** (convenciones, verificación en un comando, CI) y no en configuraciones de una herramienta que quizá no uses el año que viene.

## 🔗 Referencias

- Godot Docs — Command line tutorial (lo que un agente ejecuta para verificar): <https://docs.godotengine.org/en/4.3/tutorials/editor/command_line_tutorial.html> · uso: respalda el Tema 1 «El bucle del agente»
- Git — `git worktree` (aislamiento sin clonar): <https://git-scm.com/docs/git-worktree> · uso: respalda el Tema 5 «Aislamiento»
- GitHub Docs — Actions y verificación en CI: <https://docs.github.com/actions> · uso: respalda el Tema 6 «Verificación automática»
- OWASP — Top 10 for LLM Applications (riesgos de sistemas que actúan): <https://owasp.org/www-project-top-10-for-large-language-model-applications/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Google — *Site Reliability Engineering*, automatización con supervisión: <https://sre.google/books/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 326 - Prompt y specification engineering para juegos](../326-prompt-y-specification-engineering-para-juegos/README.md)

## ➡️ Siguiente clase

[Clase 328 - Código generado por IA con verificación](../328-codigo-generado-por-ia-con-verificacion/README.md)
