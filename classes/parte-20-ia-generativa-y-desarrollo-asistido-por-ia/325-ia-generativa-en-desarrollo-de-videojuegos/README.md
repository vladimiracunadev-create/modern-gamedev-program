# Clase 325 — IA generativa en desarrollo de videojuegos

> Parte: **20 — IA generativa y desarrollo de juegos asistido por IA** · Fuente: *Documentación oficial de las tecnologías de IA generativa · Charlas de GDC sobre IA en producción*
> ⏱️ Duración estimada: **100 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Poner orden en un campo lleno de ruido. Esta clase establece el **mapa conceptual** de la parte: qué familias de modelos existen, qué sabe hacer cada una y qué no, y —sobre todo— la distinción que gobierna las trece clases siguientes: **IA para desarrollar** frente a **IA dentro del juego**.

Son dos disciplinas con requisitos opuestos. En desarrollo, la IA es una herramienta: puede equivocarse porque tú vas a verificar antes de aceptar, y su coste es tiempo de una persona. Dentro del juego, la IA es un sistema en producción: se equivoca **delante del jugador**, cuesta dinero por cada frase, tarda, falla, y puede decir cosas que no quieres que diga. Confundir las dos es el error del que salen la mayoría de los proyectos fallidos con IA generativa.

También vas a aprender a evaluar honestamente **cuándo la IA generativa es la herramienta correcta** y cuándo un sistema clásico de la Parte 5 hace el trabajo mejor, más barato y de forma determinista.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Describir las familias de modelos generativos y qué problema resuelve cada una.
2. Distinguir IA para desarrollo de IA dentro del juego y aplicar los criterios de cada una.
3. Enumerar las limitaciones estructurales de los modelos generativos actuales.
4. Decidir con criterio entre IA generativa y un sistema clásico para un problema dado.
5. Estimar el coste y la latencia de una función de juego basada en IA.
6. Identificar los riesgos legales, éticos y de producto de cada uso.
7. Situar cada clase de la parte en el mapa.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Familias de modelos | Cada una resuelve un problema distinto; mezclarlas confunde. |
| 2 | LLM | El más versátil y el más fácil de usar mal. |
| 3 | Difusión | Imágenes y texturas; su encaje en un pipeline es el problema real. |
| 4 | Multimodal y voz | Amplían el alcance y multiplican los costes. |
| 5 | Generación 3D y audio | Maduran rápido; conviene saber su estado real. |
| 6 | Agentes | Modelos que actúan, no solo responden. |
| 7 | IA para desarrollo | Herramienta con verificación humana. |
| 8 | IA dentro del juego | Sistema en producción con SLA, coste y riesgo. |
| 9 | Limitaciones estructurales | Alucinación, no determinismo, contexto acotado. |
| 10 | Cuándo NO usarla | La decisión más rentable de toda la parte. |

## 📖 Definiciones y características

- **IA generativa**: sistemas que producen contenido nuevo (texto, imagen, audio, código, 3D) a partir de una petición. Clave: generan plausible, no verdadero.
- **LLM (large language model)**: modelo de lenguaje que predice texto. Clave: escribe, resume, clasifica y razona sobre texto; no consulta hechos por sí mismo.
- **Modelo de difusión**: genera imágenes partiendo de ruido y refinando. Clave: es el estándar de imagen y textura.
- **Modelo multimodal**: acepta o produce más de un tipo de dato (texto + imagen). Clave: permite describir una captura o generar desde una referencia visual.
- **Text-to-speech / voz generativa**: síntesis de habla. Clave: cambia el coste de la locución en juegos con mucho diálogo, con implicaciones laborales y legales.
- **Generación 3D**: producción de mallas o campos volumétricos. Clave: es la familia menos madura para producción; útil para bloqueo y referencia.
- **Agente**: sistema que usa un modelo para **actuar** (leer archivos, ejecutar comandos, iterar). Clave: aporta autonomía y por eso exige límites.
- **Inferencia**: ejecución del modelo para producir una salida. Clave: es lo que cuesta dinero y tiempo.
- **Token**: unidad en que el modelo procesa texto. Clave: es la unidad de facturación y de límite de contexto.
- **Ventana de contexto**: cantidad máxima de tokens que el modelo puede considerar. Clave: determina cuánto lore le cabe.
- **Temperatura**: parámetro que controla la variabilidad de la salida. Clave: 0 no garantiza determinismo, solo lo aproxima.
- **Alucinación**: salida plausible y falsa. Clave: no es un bug que se arregle; es una propiedad del método.
- **Anclaje (grounding)**: proporcionar hechos verificados para que la salida se ciña a ellos. Clave: es la mitigación principal de la alucinación.
- **Inferencia local**: ejecutar el modelo en la máquina del jugador. Clave: sin coste por uso ni red, con coste de hardware.
- **Inferencia remota**: llamar a un servicio. Clave: mejor calidad, coste por uso y dependencia externa.
- **Determinismo**: misma entrada, misma salida. Clave: los modelos generativos **no** lo garantizan, y eso condiciona los tests.

## 🧰 Herramientas y preparación

Para esta clase basta con leer y decidir; no hay código. Conviene tener a mano la [taxonomía de riesgos de OWASP para aplicaciones con LLM](https://owasp.org/www-project-top-10-for-large-language-model-applications/) y las guías de contenido generado de las plataformas donde publiques. A partir de la clase 326 empezaremos a construir, y desde la 334 todo se apoyará en la abstracción `AIProvider` con su implementación **mock** — de modo que nada de esta parte necesita una cuenta de pago.

## 🧪 Laboratorio guiado

Esta clase es de análisis y decisión. El "laboratorio" es un ejercicio de criterio, y es el que más dinero ahorra de toda la parte.

1. **El mapa de familias.** Qué usa cada cosa y cuál es su estado real en producción:

| Familia | Produce | Uso típico en juegos | Madurez en producción |
|---|---|---|---|
| LLM | Texto, código, JSON | Código asistido, diálogo, descripciones, clasificación | Alta para desarrollo; media dentro del juego |
| Difusión (imagen) | Imágenes | Concept art, texturas, iconos, referencias | Alta para concept; media para asset final |
| Multimodal | Texto desde imagen | Revisión de capturas, accesibilidad, QA visual | Media |
| Voz | Audio de habla | Locución de placeholder, accesibilidad | Media; con implicaciones laborales serias |
| Música / SFX | Audio | Pistas de referencia, ambientes | Baja-media |
| 3D | Mallas, texturas | Bloqueo, props de fondo, referencia | Baja |
| Agentes | Acciones | Refactors, migraciones, tests, triaje | Media, con verificación |

2. **La distinción central.** Léela dos veces; el resto de la parte depende de ella:

| | IA **para desarrollar** | IA **dentro del juego** |
|---|---|---|
| Quién ve el error | El equipo | El jugador |
| Coste | Tiempo de una persona | Dinero por petición, en cada partida |
| Latencia aceptable | Minutos | Milisegundos a pocos segundos |
| Determinismo | No hace falta | Necesario para poder probar |
| Verificación | Compilar, tests, revisión humana | Esquema + reglas del juego, automática |
| Si el proveedor cae | El equipo trabaja igual | **El juego tiene que seguir funcionando** |
| Riesgo principal | Aceptar código incorrecto | Salida inadecuada o incoherente ante el jugador |
| Clases de esta parte | 326, 327, 328, 329, 330 | 331, 332, 333, 334, 335, 336, 337, 338 |

3. **Las limitaciones estructurales.** No son fallos que se arreglarán mañana; son propiedades del método, y hay que diseñar **contando con ellas**:

| Limitación | Qué significa en la práctica | Cómo se convive |
|---|---|---|
| Alucinación | Inventa hechos con total seguridad | Anclaje (RAG) + validación contra el juego |
| No determinismo | Dos ejecuciones difieren | Mock determinista para tests; caché para producción |
| Contexto acotado | No "conoce" tu juego entero | Recuperación selectiva de lo relevante |
| Sin estado | No recuerda entre llamadas | Memoria explícita que tú gestionas |
| Sesgo del entrenamiento | Reproduce patrones de sus datos | Revisión humana; diversidad en la validación |
| Coste y latencia | Cada frase cuesta y tarda | Caché, lotes, modelos pequeños, fallbacks |
| Opacidad | No se puede depurar "por dentro" | Trazas de entrada/salida y evaluación por escenarios |

4. **La decisión: ¿generativa o clásica?** El árbol que evita el 80 % de los errores:

```text
¿El comportamiento se puede describir con reglas?
├─ SÍ  → Usa un sistema clásico (Parte 5). Es determinista, gratis, instantáneo
│        y depurable. Un behavior tree para decidir a quién atacar es mejor que
│        un LLM en todos los ejes que importan.
└─ NO  → ¿Necesita ser correcto o basta con que sea plausible?
   ├─ CORRECTO → ¿Puedes validar la salida automáticamente?
   │   ├─ SÍ  → Generativa CON validación estricta (clases 333, 337)
   │   └─ NO  → No uses generativa en producción. Úsala en desarrollo, con
   │            revisión humana, y publica el resultado como contenido fijo.
   └─ PLAUSIBLE → Generativa es buena candidata (charla ambiental, descripciones,
                  variación de saludos). Aun así: valida y ten fallback.
```

Ejemplos aplicados, que es donde se ve:

| Necesidad | Mejor herramienta | Por qué |
|---|---|---|
| Enemigo que decide a quién atacar | Behavior tree (Parte 5) | Reglas claras, determinista, gratis |
| Pathfinding | A* (Parte 5) | Correcto por construcción |
| Charla ambiental de aldeanos | LLM con caché | Plausible basta; la variedad es el valor |
| Descripción de un item generado | LLM con validación | Plausible, y el esquema acota |
| Decidir si una quest está completa | Sistema de quests (clase 305) | Debe ser **correcto**, no plausible |
| Traducir la UI | Traducción profesional | Correcto y con responsabilidad legal |
| Generar 200 nombres de NPC | LLM en desarrollo | Se revisan una vez y se publican fijos |
| Moderar chat de jugadores | Clasificador + revisión humana | Correcto, y con apelación |

5. **La estimación de coste.** Hazla **antes** de diseñar la función, no después:

```text
Coste por partida ≈ interacciones × (tokens_entrada + tokens_salida) × precio_por_token

Ejemplo: NPC conversacional en un RPG
  30 interacciones por sesión
  × (1.200 tokens de contexto + 150 de respuesta)
  = 40.500 tokens por sesión

Con 100.000 sesiones al mes: 4.050 millones de tokens/mes.
```

Ese número hay que multiplicarlo por el precio del modelo que elijas y compararlo con el ingreso medio por jugador. Muchas veces la conclusión honesta es: **con caché agresiva y un modelo pequeño, sí; con el modelo grande en cada frase, no**. Es exactamente el análisis de la [clase 335](../335-coste-latencia-cache-y-fallbacks/README.md).

Y la latencia:

```text
Latencia percibida = red + cola + inferencia + validación
  Remota, modelo grande:  600–3.000 ms   → hace falta ocultarla (animación, "está pensando")
  Remota, modelo pequeño: 200–800 ms     → tolerable en diálogo por turnos
  Local, modelo pequeño:  100–500 ms     → sin red, pero pide hardware
  Contenido cacheado:     < 5 ms         → indistinguible de contenido escrito
```

6. **Los riesgos que hay que mirar antes de empezar.** No son opcionales:

| Riesgo | Consecuencia | Dónde se trata |
|---|---|---|
| Propiedad intelectual del contenido generado | No poder registrar ni defender tus assets | Clase 329 |
| Licencia de los datos de entrenamiento | Reclamaciones sobre tu contenido | Clase 329 |
| Divulgación obligatoria en tiendas | Retirada de la ficha o de la publicación | Clase 329 |
| Salida inadecuada ante un jugador | Daño reputacional, retirada por edad | Clase 336 |
| Prompt injection vía chat del jugador | El NPC se salta sus reglas | Clase 336 |
| Datos personales en el prompt | Incumplimiento de privacidad | Clases 317 y 336 |
| Dependencia de un proveedor | El juego deja de funcionar o se dispara el coste | Clase 334 |
| Impacto laboral en el equipo | Cuestión ética y contractual real | Clases 329 y 273 |

7. **El mapa de la parte.** Dónde encaja cada clase:

```text
IA PARA DESARROLLAR                     IA DENTRO DEL JUEGO
─────────────────────                   ───────────────────
326 Prompt y especificación             331 NPC con LLM
327 Agentes de programación             332 RAG, memoria y lore
328 Verificación de código              333 Diálogo y quests generativos
329 Assets y provenance                 334 Proveedores (mock/local/remoto)
330 Pipeline de assets                  335 Coste, latencia, caché, fallbacks
                                        336 Seguridad y moderación
                                        337 Evaluación
                                        338 Capstone: NPC con lore verificable
```

## ✍️ Ejercicios

1. Clasifica cinco funciones de tu juego según el árbol de decisión del paso 4 y justifica cada una.
2. Estima el coste mensual de una función conversacional con tu número real de jugadores.
3. Estima la latencia percibida de esa función y diseña cómo la ocultarías.
4. Enumera tres cosas que **no** harías con IA generativa en tu juego y explica por qué.
5. Revisa las políticas de contenido generado de dos tiendas y anota sus requisitos de divulgación.
6. Identifica en qué parte de tu pipeline actual la IA ahorraría más tiempo con menos riesgo.
7. Escribe la política de uso de IA de tu equipo en una página: qué se permite, con qué verificación y qué se declara.

## 📝 Reto verificable

Entrega un documento `docs/estrategia-ia.md` que analice el uso de IA generativa en un proyecto concreto (el tuyo o el del capstone) con: mapa de las funciones candidatas clasificadas por el árbol de decisión; para cada función aceptada, estimación de coste mensual y de latencia con su plan de ocultación; para cada función rechazada, la alternativa clásica elegida; tabla de riesgos con mitigación y clase de referencia; y la política de uso del equipo.

**Criterio de aceptación**: (a) el documento analiza **al menos seis** funciones candidatas y rechaza razonadamente **al menos dos**; (b) cada función aceptada tiene coste estimado con sus supuestos explícitos (interacciones, tokens, precio) y latencia con plan; (c) la tabla de riesgos cubre propiedad intelectual, divulgación, moderación, privacidad y dependencia de proveedor; (d) se declara explícitamente qué pasa con cada función **si el proveedor de IA no está disponible**; (e) la política de equipo especifica qué verificación es obligatoria antes de aceptar contenido generado.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Un LLM decide la lógica de combate | Se usó generativa donde había reglas. Vuelve al sistema clásico. |
| El juego no funciona sin internet | La IA es un requisito, no una mejora. Fallback obligatorio (clase 335). |
| La factura del primer mes triplica lo previsto | No se estimó el coste. Calcula antes de diseñar. |
| El NPC inventa hechos del mundo | Falta anclaje. RAG y validación (clases 332 y 333). |
| Se publicaron assets generados sin declararlo | Se ignoró la política de la tienda. Revisa antes de publicar. |
| El equipo acepta código generado sin leerlo | Falta política de verificación. Compilar + tests + revisión. |
| Se probó con el proveedor real en CI | Coste, no determinismo y dependencia de una clave. Usa el mock. |
| "Con IA lo hacemos todo más rápido" y el proyecto va más lento | Se aplicó donde no aportaba. El árbol de decisión existe para esto. |

## ❓ Preguntas frecuentes

**❓ ¿La IA generativa sustituye a la IA de la Parte 5?** No, y confundirlas es caro. Un behavior tree decide en microsegundos, gratis, siempre igual y se puede depurar paso a paso. Un LLM tarda cientos de milisegundos, cuesta dinero, varía y es opaco. Para *decidir* comportamiento, la clásica gana casi siempre. La generativa aporta donde hace falta **lenguaje o variedad**, no lógica.

**❓ ¿Puedo hacer un juego entero con IA generativa dentro?** Técnicamente sí; en la práctica, los proyectos que lo intentan chocan con lo mismo: coste por sesión, latencia, incoherencia y la imposibilidad de garantizar que el juego se pueda terminar. El patrón que sí funciona es **generativa en las capas de superficie** (cómo se dice) sobre **sistemas deterministas en el núcleo** (qué ocurre).

**❓ ¿Es esto una moda que pasará?** Algunas herramientas cambiarán; los patrones de esta parte —abstracción de proveedor, validación de salida, anclaje, caché, fallback, evaluación— son de arquitectura de software y sobreviven al proveedor de turno. Por eso la parte se construye sobre `AIProvider` y no sobre una API concreta.

**❓ ¿Y el impacto en el trabajo de artistas y guionistas?** Es una cuestión real y no técnica, y merece una postura explícita del equipo. Hay estudios que usan IA solo en fases de exploración, otros que la excluyen del contenido final, otros que la integran con acuerdos concretos. Lo que no es defendible es no tener postura: afecta a personas, a contratos y a la percepción pública de tu juego. Se trata con más detalle en la [clase 329](../329-assets-generativos-y-provenance/README.md).

**❓ ¿Por dónde empiezo si quiero probar hoy?** Por la IA **para desarrollo**, que tiene el mejor perfil riesgo/beneficio: verificas antes de aceptar y no hay coste en producción. Concretamente: generación de tests, refactors mecánicos y borradores de documentación. La IA dentro del juego exige toda la infraestructura de las clases 331-337.

## 🔗 Referencias

- OWASP — Top 10 for Large Language Model Applications: <https://owasp.org/www-project-top-10-for-large-language-model-applications/> · uso: se instala o se consulta en la preparación
- ONNX Runtime — inferencia local multiplataforma: <https://onnxruntime.ai/> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- GDC Vault — charlas sobre IA generativa en producción de juegos: <https://www.gdcvault.com/> — catálogo por tema, no una charla identificada (ponente y año pendientes) · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Godot Docs — `HTTPRequest` (base de cualquier proveedor remoto): <https://docs.godotengine.org/en/4.3/classes/class_httprequest.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Millington & Funge — *Artificial Intelligence for Games* (la IA clásica que esto complementa): <https://www.routledge.com/Artificial-Intelligence-for-Games/Millington/p/book/9780367670566> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 324 - Capstone Parte 19: un runtime de producción](../../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/324-capstone-parte-19-un-runtime-de-produccion/README.md)

## ➡️ Siguiente clase

[Clase 326 - Prompt y specification engineering para juegos](../326-prompt-y-specification-engineering-para-juegos/README.md)
