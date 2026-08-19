# Clase 326 — Prompt y specification engineering para juegos

> Parte: **20 — IA generativa y desarrollo de juegos asistido por IA** · Fuente: *Documentación oficial de las tecnologías de IA generativa · Prácticas de especificación de software*
> ⏱️ Duración estimada: **110 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Aprender a convertir una idea vaga en una **especificación lo bastante precisa** como para que otra persona —o un modelo— pueda implementarla y para que tú puedas verificar el resultado. Esa es la habilidad real detrás de la etiqueta "prompt engineering": no son trucos de redacción, es la vieja disciplina de escribir requisitos, aplicada a un colaborador nuevo que es rápido, literal y no pregunta cuando duda.

Vas a recorrer la cadena completa **idea → requisitos → GDD → arquitectura → tareas → implementación → tests**, viendo en cada paso qué aporta la asistencia y qué debe decidir una persona. Y vas a construir tu propia biblioteca de prompts para las tareas recurrentes de gamedev: gameplay, shaders, IA, UI, depuración, diseño de niveles y testing. El criterio que guía todo: **un prompt es bueno si su resultado se puede verificar**.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Escribir una especificación con contexto, restricciones, criterios de aceptación y formato de salida.
2. Descomponer un problema de gamedev en tareas verificables de tamaño adecuado.
3. Aplicar patrones de prompt (rol, ejemplos, plantilla, autocrítica) y saber cuándo cada uno.
4. Pedir salidas estructuradas y validarlas contra un esquema.
5. Diagnosticar por qué un resultado es malo: falta de contexto, ambigüedad o tarea inadecuada.
6. Construir una biblioteca de prompts versionada y reutilizable por el equipo.
7. Reconocer cuándo el problema no es el prompt, sino que la tarea no es adecuada.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Especificación vs prompt | El prompt es el vehículo; la especificación es el contenido. |
| 2 | Contexto explícito | El modelo no conoce tu proyecto; lo que no digas, se lo inventa. |
| 3 | Restricciones | Sin ellas, la respuesta será genérica y no encajará. |
| 4 | Criterios de aceptación | Sin ellos no se puede verificar, y sin verificar no sirve. |
| 5 | Formato de salida | Estructurado se valida; texto libre, no. |
| 6 | Descomposición | Tareas grandes producen resultados vagos. |
| 7 | Ejemplos (few-shot) | Un ejemplo vale más que tres párrafos de explicación. |
| 8 | Iteración dirigida | Corregir con precisión es más rápido que reescribir. |
| 9 | Biblioteca de prompts | Lo que funciona se guarda, se versiona y se comparte. |
| 10 | Cuándo el prompt no es el problema | Reconocerlo ahorra horas. |

## 📖 Definiciones y características

- **Especificación**: descripción precisa de qué debe hacer algo y cómo se comprueba. Clave: es independiente de quién la implemente.
- **Prompt**: instrucción concreta que se da a un modelo. Clave: es el envoltorio de una especificación.
- **Contexto**: información del proyecto que el modelo necesita (motor, versión, convenciones, código relacionado). Clave: lo que falte, se rellenará con suposiciones.
- **Restricción**: límite explícito (no usar dependencias externas, respetar una API, no tocar ciertos archivos). Clave: convierte una respuesta genérica en una utilizable.
- **Criterio de aceptación**: condición comprobable que define "terminado". Clave: es lo mismo que pides en cada clase de este programa.
- **Salida estructurada**: respuesta en un formato definido (JSON, tabla, diff). Clave: permite validación automática.
- **Esquema**: definición formal de la estructura esperada. Clave: rechaza lo que no encaja sin leerlo.
- **Few-shot**: incluir ejemplos de entrada y salida deseada. Clave: la forma más eficaz de comunicar estilo y formato.
- **Zero-shot**: pedir sin ejemplos. Clave: suficiente para tareas comunes, insuficiente para convenciones propias.
- **Rol / persona**: indicar desde qué perspectiva responder. Clave: útil para el registro y el énfasis; no sustituye al contexto.
- **Cadena de pasos**: pedir que razone o trabaje por etapas. Clave: mejora tareas con estructura; encarece las simples.
- **Autocrítica**: pedir que revise su propia salida contra los criterios. Clave: detecta una parte de los errores, no todos.
- **Descomposición**: partir un problema en tareas pequeñas y verificables. Clave: es la técnica que más mejora los resultados.
- **Iteración dirigida**: corregir señalando el punto exacto en vez de repetir la petición. Clave: converge mucho más rápido.
- **Biblioteca de prompts**: colección versionada de prompts que funcionan. Clave: es conocimiento de equipo, no una carpeta personal.
- **Anti-patrón "pide más"**: intentar arreglar una tarea mal planteada añadiendo instrucciones. Clave: el problema es la tarea, no el prompt.

## 🧰 Herramientas y preparación

Cualquier asistente de IA al que tengas acceso, o ninguno: **el ejercicio de escribir la especificación es válido por sí mismo** y es lo que se evalúa. Trabajaremos en `docs/prompts/` del repositorio, versionado en git como cualquier otro recurso del equipo. Nada de esta clase depende de un proveedor concreto.

## 🧪 Laboratorio guiado

1. **La cadena completa.** Qué aporta la asistencia y qué decide una persona:

| Paso | Entrada | Salida | ¿Puede asistir? | Quién decide |
|---|---|---|---|---|
| Idea | Una frase | Concepto | Explorar variantes | Persona |
| Requisitos | Concepto | Qué debe hacer y qué no | Estructurar y detectar huecos | Persona |
| GDD | Requisitos | Documento de diseño | Redactar secciones | Persona |
| Arquitectura | Requisitos | Sistemas y sus límites | Proponer opciones y contrastarlas | **Persona** |
| Tareas | Arquitectura | Lista verificable | Descomponer | Persona revisa |
| Implementación | Tarea + contexto | Código | **Sí, con verificación** | Persona revisa |
| Tests | Criterios | Casos y aserciones | Sí, y es de lo más rentable | Persona revisa |

La fila de arquitectura está en negrita a propósito: es donde más tentador resulta delegar y donde peor sale. Un modelo propondrá una arquitectura razonable **en abstracto**; encajarla con lo que ya tienes, con tu equipo y con tu plazo es una decisión de contexto que no tiene.

2. **La plantilla de especificación.** Cinco bloques; si falta uno, el resultado se resiente:

```markdown
## Contexto
Godot 4.3, GDScript. Proyecto con la arquitectura por capas de la clase 293:
`dominio/` sin nodos, `gameplay/` con nodos, comunicación por señales.
El inventario ya existe en `dominio/inventario/inventario.gd` con la API:
`agregar(id, n) -> int`, `quitar(id, n) -> bool`, `cabe(id, n) -> int`.

## Objetivo
Implementar `ordenar()` en `Inventario`: agrupa por tipo y rareza, compacta
stacks parciales y deja las ranuras vacías al final.

## Restricciones
- Sin dependencias externas ni nodos: la clase extiende `RefCounted`.
- No cambiar la firma de ningún método existente.
- Emitir `ranura_cambiada` solo para las ranuras que realmente cambien.
- Comentarios en español, solo donde expliquen un porqué no obvio.

## Criterios de aceptación
1. El total de unidades por item es idéntico antes y después.
2. Tras ordenar, no quedan dos stacks parciales del mismo item.
3. Las ranuras vacías están todas al final.
4. Ordenar dos veces seguidas no produce cambios en la segunda (idempotente).
5. Con el inventario vacío no falla y no emite señales.

## Formato de salida
Solo el código del método y los auxiliares privados que necesite, en un bloque
GDScript. Sin explicación previa.
```

Compárala con lo que la mayoría escribe: *"hazme una función para ordenar el inventario"*. La diferencia en el resultado no es de estilo: es que la primera **se puede verificar** y la segunda no.

3. **Descomposición.** La técnica que más mejora los resultados, y no tiene nada que ver con la redacción:

```text
❌ "Implementa el sistema de combate del juego"
   → Demasiado grande. La respuesta será genérica y no encajará con nada.

✅ Descompuesto:
   1. Objeto `Golpe` con sus campos y su traza          (criterios: 3)
   2. Reducción por armadura asintótica                  (criterios: 2, incluye extremos)
   3. Cálculo de crítico con RNG inyectado               (criterios: 2, incluye determinismo)
   4. Ventana de invulnerabilidad e id de ataque         (criterios: 3)
   5. Integración de los cuatro en `PipelineDano`        (criterios: 4)
   6. Pruebas headless del pipeline completo             (criterios: 1 por caso)
```

Regla práctica: **si no puedes escribir los criterios de aceptación de una tarea en cinco líneas, la tarea es demasiado grande**.

4. **Los patrones, y cuándo usar cada uno:**

| Patrón | Cuándo | Cuándo NO |
|---|---|---|
| Ejemplos (few-shot) | Convenciones propias, formatos, estilo de comentario | Tareas estándar bien conocidas |
| Rol | Ajustar registro (documentación, nota de parche) | Como sustituto del contexto real |
| Pasos explícitos | Tareas con estructura (migración, refactor guiado) | Tareas de una línea |
| Autocrítica | Antes de aceptar una salida larga | Cuando ya tienes tests que lo comprueban |
| Salida estructurada | Siempre que vayas a procesar la salida | Cuando quieres explicación para leer |
| Iteración dirigida | Corregir un punto concreto | Cuando el planteamiento es el que falla |

Ejemplo de few-shot para una convención propia:

```markdown
Genera la sección "Errores comunes" de una clase del curso siguiendo EXACTAMENTE
este formato y densidad:

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El progreso no persiste tras cerrar | Guardaste en `res://` (solo lectura al exportar). Usa siempre `user://`. |
| "Cannot call method 'store_string' on a null value" | `FileAccess.open` devolvió `null`. Comprueba el resultado antes de usarlo. |

Ahora genera 6 filas para el tema: sistema de inventario por ranuras.
Los síntomas deben ser lo que una persona VE o el mensaje EXACTO que aparece,
no una descripción abstracta del bug.
```

5. **Salida estructurada y validación.** Lo que convierte una respuesta en un dato utilizable:

````markdown
Devuelve SOLO un objeto JSON con este esquema, sin texto alrededor:

```json
{
  "quest": {
    "id": "string, snake_case, único",
    "titulo": "string, máximo 60 caracteres",
    "objetivos": [
      { "id": "string", "tipo": "matar|recoger|alcanzar|hablar",
        "objetivo": "string", "cantidad": "int, 1-50" }
    ],
    "recompensas": { "xp": "int, 50-2000", "oro": "int, 0-1000" }
  }
}
```

Restricciones: entre 2 y 4 objetivos; los `objetivo` deben salir de esta lista
cerrada: ["lobo", "bandido", "piel_lobo", "zona_guarida", "guardia_puerta"].
````

Y del otro lado, la validación — porque **pedir un formato no garantiza recibirlo**:

```gdscript
func validar_quest_generada(texto: String) -> Dictionary:
	var d = JSON.parse_string(texto)
	if typeof(d) != TYPE_DICTIONARY or not d.has("quest"):
		return {"ok": false, "error": "no es un objeto con clave 'quest'"}
	var q: Dictionary = d["quest"]
	var errores := []
	if not str(q.get("id", "")).is_valid_identifier():
		errores.append("id no es snake_case")
	if str(q.get("titulo", "")).length() > 60:
		errores.append("título demasiado largo")
	var objetivos: Array = q.get("objetivos", [])
	if objetivos.size() < 2 or objetivos.size() > 4:
		errores.append("número de objetivos fuera de rango")
	for o in objetivos:
		# La lista cerrada NO es una sugerencia: se comprueba. Un objetivo
		# inventado produce una quest imposible de completar.
		if not str(o.get("objetivo", "")) in OBJETIVOS_VALIDOS:
			errores.append("objetivo inexistente: %s" % o.get("objetivo", ""))
	return {"ok": errores.is_empty(), "errores": errores, "quest": q}
```

6. **La biblioteca de prompts.** Versionada, con su motivo y su historial:

```markdown
<!-- docs/prompts/gameplay/sistema-nuevo.md — v3 -->
# Prompt: implementar un sistema de dominio

**Cuándo usarlo**: al añadir un sistema nuevo en `dominio/`.
**Verificación obligatoria**: compila, pasa `pruebas/<sistema>_test.gd`, revisión humana.

## Plantilla

    ## Contexto
    Godot {VERSION}, GDScript. Arquitectura por capas: `dominio/` no extiende Node
    ni usa `get_node`; comunicación hacia fuera por señales.
    Sistemas existentes relacionados: {SISTEMAS}
    API que debe respetar: {API}

    ## Objetivo
    {OBJETIVO}

    ## Restricciones
    - `extends RefCounted`; nada de nodos, escenas ni `get_tree()`.
    - Toda aleatoriedad por un `RandomNumberGenerator` inyectado.
    - Avance temporal por `tick(delta)` explícito, no `_process`.
    - Comentarios solo donde expliquen un porqué no obvio.

    ## Criterios de aceptación
    {CRITERIOS}

    ## Formato
    Solo código GDScript. Sin explicación.

## Historial
- v3: añadida la restricción de RNG inyectado — sin ella generaba `randf()`
  global y rompía el determinismo de los replays.
- v2: añadido `tick(delta)` explícito.
- v1: versión inicial.
```

Ese apartado "Historial" es lo que convierte una carpeta de prompts en conocimiento de equipo: cada línea es un error que ya no se repetirá.

7. **Diagnóstico: por qué salió mal.** Antes de reescribir el prompt, identifica la causa:

| Síntoma del resultado | Causa probable | Arreglo |
|---|---|---|
| Genérico, "de tutorial" | Falta contexto del proyecto | Añade convenciones, API y ejemplos reales |
| Usa APIs que no existen | Contexto insuficiente o versión no indicada | Indica versión exacta y pega la API real |
| Correcto pero no encaja | Faltan restricciones | Enumera lo que **no** debe hacer |
| Cambia cosas que no tocaba | Alcance no acotado | Di explícitamente qué archivos y qué firmas no se tocan |
| Formato inconsistente | Sin esquema ni ejemplos | Da el esquema y un ejemplo completo |
| Se queda a medias | Tarea demasiado grande | Descompón |
| Plausible y falso | La tarea requiere hechos que no tiene | Aporta los hechos, o no es tarea para esto |

8. **Cuándo el prompt no es el problema.** Reconocerlo pronto ahorra tardes enteras:

- **La tarea requiere conocimiento de tu proyecto que no cabe en el contexto.** Solución: reduce el alcance, no alargues el prompt.
- **La tarea requiere ser correcta y no puedes verificarla.** Solución: no la delegues; escríbela tú.
- **Llevas cuatro iteraciones y cada una arregla una cosa y rompe otra.** Solución: para, escribe tú el esqueleto y pide solo las partes mecánicas.
- **El resultado es bueno pero no sabes si es correcto.** Solución: el problema es que faltan tests, no prompt.

## ✍️ Ejercicios

1. Escribe la especificación completa (cinco bloques) de una función real de tu proyecto.
2. Coge una tarea grande de tu backlog y descomponla en tareas con criterios de cinco líneas.
3. Crea un prompt few-shot que reproduzca la convención de comentarios de tu equipo.
4. Diseña un esquema JSON para contenido generado de tu juego y escribe su validador.
5. Empieza `docs/prompts/` con tres prompts que uses de verdad, con su apartado de verificación.
6. Coge un resultado malo que hayas tenido y diagnostícalo con la tabla del paso 7.
7. Identifica una tarea de tu proyecto que **no** deberías delegar y escribe por qué.

## 📝 Reto verificable

Entrega una biblioteca de prompts en `docs/prompts/` con **al menos cinco prompts** para categorías distintas (gameplay, shaders, IA, UI, testing o depuración), cada uno con plantilla, cuándo usarlo, verificación obligatoria e historial; más **una especificación completa** de un sistema real y su validador de salida estructurada.

**Criterio de aceptación**: (a) cada prompt tiene los cinco bloques (contexto, objetivo, restricciones, criterios, formato) y declara explícitamente su verificación; (b) al menos dos prompts incluyen ejemplos few-shot con contenido real del proyecto; (c) la especificación entregada tiene **al menos cinco criterios de aceptación comprobables por una máquina**; (d) el validador de salida estructurada rechaza: JSON malformado, campo faltante, tipo incorrecto, valor fuera de rango y referencia a un id inexistente — con una prueba headless que lo demuestre; (e) la biblioteca está versionada en git y cada prompt tiene al menos una entrada de historial que explique un cambio y su motivo.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Cada resultado hay que reescribirlo entero | Falta contexto y restricciones. Usa la plantilla de cinco bloques. |
| El código usa métodos inexistentes de Godot | No se indicó la versión ni se pegó la API real. Ambas cosas. |
| El JSON generado no parsea | Se pidió "JSON" sin esquema ni "solo el objeto". Da esquema y exige salida limpia. |
| Se acepta contenido generado sin validar | Falta el validador. Pedir formato no es recibirlo. |
| Los prompts viven en el historial de chat de cada uno | No hay biblioteca. Llévalos al repositorio. |
| Se itera diez veces sobre lo mismo | La tarea es demasiado grande o inadecuada. Descompón o hazla tú. |
| El resultado es correcto pero rompe una convención | La convención no estaba escrita. Añádela a las restricciones y al prompt base. |
| El prompt tiene 3.000 palabras | Se está compensando una tarea mal planteada. Reduce el alcance. |

## ❓ Preguntas frecuentes

**❓ ¿"Prompt engineering" es una habilidad real?** La parte útil sí, y no es nueva: es escribir requisitos claros, descomponer problemas y definir criterios de aceptación. Eso vale igual para un colaborador humano, y de hecho el mejor indicador de que una especificación es buena es que **una persona que no conoce el proyecto podría implementarla**.

**❓ ¿Merece la pena la biblioteca de prompts si trabajo solo?** Sí, por la misma razón que merece la pena tener plantillas: cada vez que descubres una restricción que hay que añadir (como el RNG inyectado del ejemplo), la anotas una vez y no vuelves a perder tiempo con ese error.

**❓ ¿Los ejemplos no gastan mucho contexto?** Gastan, y compensan. Un ejemplo completo de tu convención real ahorra tres iteraciones. Si el contexto se queda corto, el problema es que la tarea es demasiado grande — vuelve a la descomposición.

**❓ ¿Y si el modelo se inventa una API?** Es lo esperado si no le das la real: rellenará el hueco con lo más plausible. La solución no es pedirle que no invente, es **pegarle la API** que debe usar. Y en cualquier caso, la verificación de la [clase 328](../328-codigo-generado-por-ia-con-verificacion/README.md) lo detecta antes de que llegue al repositorio.

**❓ ¿Esto sirve igual con cualquier proveedor?** Sí, y por eso la clase no menciona ninguno. Contexto, restricciones, criterios y formato son propiedades de la **especificación**, no del modelo. Cambiar de proveedor puede exigir ajustar detalles; la estructura se mantiene.

## 🔗 Referencias

- OWASP — Top 10 for LLM Applications (riesgos al procesar salidas): <https://owasp.org/www-project-top-10-for-large-language-model-applications/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- JSON Schema — especificación de esquemas para validar salidas: <https://json-schema.org/> · uso: respalda el Tema 1 «Especificación vs prompt»
- Godot Docs — `JSON` (parseo y validación en el motor): <https://docs.godotengine.org/en/4.3/classes/class_json.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- IEEE — prácticas de especificación de requisitos de software (fundamento de la plantilla): <https://standards.ieee.org/> · uso: respalda el Tema 1 «Especificación vs prompt»
- GDC Vault — charlas sobre flujos de trabajo asistidos en producción: <https://www.gdcvault.com/> — catálogo por tema, no una charla identificada (ponente y año pendientes) · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 325 - IA generativa en desarrollo de videojuegos](../325-ia-generativa-en-desarrollo-de-videojuegos/README.md)

## ➡️ Siguiente clase

[Clase 327 - Agentes de programación para GameDev](../327-agentes-de-programacion-para-gamedev/README.md)
