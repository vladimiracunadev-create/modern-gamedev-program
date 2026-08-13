# Parte 20 — IA generativa y desarrollo de juegos asistido por IA

> [⬅️ Volver al programa](../../README.md) · [📚 Índice completo](../README.md) · [⏮️ Parte anterior](../parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md) · [⏭️ Parte siguiente](../parte-21-arquitectura-avanzada-de-motores-y-rendering/README.md)

**14 clases** · rango 325–338 · La IA generativa en dos frentes distintos: como **herramienta** para desarrollar (código, assets, diseño, testing) y como **sistema dentro del juego** (NPC, diálogo, contenido dinámico) — siempre con verificación, con proveedores intercambiables y sin depender de ninguna API comercial para funcionar

**Fuentes de referencia de esta parte:**

- Documentación oficial de las tecnologías de IA que uses (modelos, APIs y runtimes locales).
- [OWASP Top 10 for Large Language Model Applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/) — riesgos de seguridad específicos de aplicaciones con LLM.
- Documentación de [ONNX Runtime](https://onnxruntime.ai/) y de los formatos de modelo abiertos, para inferencia local.
- Charlas de GDC sobre IA generativa aplicada a producción de juegos: <https://www.gdcvault.com/>
- Guías de las plataformas sobre contenido generado por IA y sus requisitos de divulgación.
- Legislación aplicable sobre propiedad intelectual y contenido generado (varía por jurisdicción).

---

## 🎯 ¿De qué trata esta parte?

De dos cosas que se confunden constantemente y que conviene mantener separadas:

**IA para desarrollar.** Escribir código con asistencia, generar borradores de diseño, producir assets de partida, ayudar a depurar, generar casos de prueba. Aquí la IA es una herramienta del equipo, y la disciplina que hace falta es la de **verificación**: nada generado entra en el repositorio sin compilar, pasar tests y ser leído por una persona.

**IA dentro del juego.** NPC que conversan, diálogo generado, contenido dinámico. Aquí la IA es un **sistema en producción** con todo lo que eso implica: coste por petición, latencia, fallos, salidas inesperadas, moderación, privacidad y — sobre todo — la necesidad de que el modelo **nunca decida directamente** nada crítico del juego. El modelo propone; el juego valida y dispone.

La **Parte 5 sigue siendo la IA de gameplay tradicional** (máquinas de estado, behavior trees, pathfinding, steering) y no se sustituye: sigue siendo la herramienta correcta para el 95 % de la IA de un juego. Esta parte añade lo que la IA generativa hace posible, y también lo que no.

Nada de esta parte requiere una clave de API. Toda la arquitectura se construye sobre una abstracción `AIProvider` con implementaciones **mock** (deterministas, para CI), **local** (modelos que corren en la máquina) y **remota** (opcional, configurable por variables de entorno).

## 🧩 Problemas que resuelve

- Código generado que compila y está mal, aceptado porque "lo escribió la IA".
- Assets generados sin trazabilidad de origen ni licencia, imposibles de defender.
- NPC con LLM que inventan hechos incompatibles con el lore o prometen cosas imposibles.
- Modelos que devuelven texto libre donde el juego esperaba una acción válida.
- Juegos que dejan de funcionar cuando el proveedor de IA falla o cambia de precio.
- Costes de inferencia que nadie estimó y aparecen en la factura del primer mes.
- Prompt injection a través de lo que escribe el jugador.
- Sistemas generativos que nadie sabe si están mejorando o empeorando.

## 🎓 Resultados de aprendizaje

Al terminar la parte, el alumno podrá:

- Distinguir con precisión **IA para desarrollo** de **IA dentro del juego** y aplicar a cada una su disciplina.
- Convertir una idea en requisitos, arquitectura, tareas e implementación con asistencia y verificación.
- Trabajar con agentes de programación de forma verificable, independiente del proveedor.
- Aplicar un ciclo de verificación obligatorio a todo código generado.
- Gestionar la procedencia, la licencia y la trazabilidad de assets generativos.
- Diseñar un pipeline de assets asistido con validación, optimización y revisión humana.
- Construir un NPC con LLM cuya salida se valida contra esquema y reglas del juego.
- Implementar recuperación de lore (RAG), memoria a corto y largo plazo y anclaje.
- Abstraer proveedores locales, remotos y mock, y hacer que el juego funcione sin ninguno.
- Gestionar coste, latencia, caché, colas, timeouts y fallbacks.
- Defenderse de prompt injection y moderar entrada y salida.
- Evaluar un sistema generativo con métricas y escenarios de referencia.

## 🧱 Prerrequisitos

- Parte 5 (IA de juegos clásica): esta parte la complementa, no la sustituye.
- Parte 18 (sistemas de gameplay): el diálogo y las quests generadas se validan contra los sistemas de las clases 304 y 305.
- Parte 19 (producción): proveedores, timeouts, fallbacks, telemetría y privacidad se apoyan directamente en ella.
- Godot 4.x. **No se requiere ninguna clave de API**: el laboratorio y la CI usan un proveedor mock determinista.

## 📚 Las 14 clases

| # | Clase |
|---|---|
| 325 | [IA generativa en desarrollo de videojuegos](325-ia-generativa-en-desarrollo-de-videojuegos/README.md) |
| 326 | [Prompt y specification engineering para juegos](326-prompt-y-specification-engineering-para-juegos/README.md) |
| 327 | [Agentes de programación para GameDev](327-agentes-de-programacion-para-gamedev/README.md) |
| 328 | [Código generado por IA con verificación](328-codigo-generado-por-ia-con-verificacion/README.md) |
| 329 | [Assets generativos y provenance](329-assets-generativos-y-provenance/README.md) |
| 330 | [Pipeline técnico de assets asistido por IA](330-pipeline-tecnico-de-assets-asistido-por-ia/README.md) |
| 331 | [NPC controlados por LLM](331-npc-controlados-por-llm/README.md) |
| 332 | [RAG, memoria y lore del mundo](332-rag-memoria-y-lore-del-mundo/README.md) |
| 333 | [Diálogo, quests y contenido generativo](333-dialogo-quests-y-contenido-generativo/README.md) |
| 334 | [Proveedores locales y remotos](334-proveedores-locales-y-remotos/README.md) |
| 335 | [Coste, latencia, caché y fallbacks](335-coste-latencia-cache-y-fallbacks/README.md) |
| 336 | [Seguridad y moderación de IA dentro del juego](336-seguridad-y-moderacion-de-ia-dentro-del-juego/README.md) |
| 337 | [Evaluación de sistemas generativos](337-evaluacion-de-sistemas-generativos/README.md) |
| 338 | [Capstone Parte 20: un NPC con lore verificable](338-capstone-parte-20-un-npc-con-lore-verificable/README.md) |

---

> Con la IA integrada y verificada, la [Parte 21](../parte-21-arquitectura-avanzada-de-motores-y-rendering/README.md) baja al nivel más profundo: arquitectura de motores, memoria, paralelismo y rendering moderno.
