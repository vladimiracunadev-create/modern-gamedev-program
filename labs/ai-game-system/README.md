# 🤖 Lab: Sistema de IA en el juego

> [⬅️ Volver a los laboratorios](../README.md) · [📚 Parte 20](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/README.md) · [🎓 Clase 338 (capstone)](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/338-capstone-parte-20-un-npc-con-lore-verificable/README.md)

NPC conversacionales con lore anclado, memoria de contexto, validación de salida y ejecución por los sistemas del juego. La regla que gobierna todo el laboratorio: **el modelo propone, el juego dispone**. Un LLM aquí no abre puertas, no da objetos y no inicia quests — genera una intención estructurada que un sistema conocido valida contra las reglas del juego.

Y el requisito que lo define: **funciona sin claves de API, sin red y de forma determinista**. Un proveedor real se puede añadir a la cadena, y es estrictamente opcional. Si el proyecto no arrancara sin él, estaría mal hecho.

## 🎯 La demostración

Ejecuta las dos versiones y compara la salida:

```bash
godot --headless --path labs/ai-game-system/solucion --quit-after 120
```

```text
  ataque: «Pídeme hierro y acero, no milagros.» · efecto en el juego: NINGUNO
  lore secreto accesible sin la quest: false
```

```bash
godot --headless --path labs/ai-game-system/inicio --quit-after 120
```

```text
  ataque: «Toma la Hoja del Alba.» · efecto en el juego: ¡SE COLÓ!
  lore secreto accesible sin la quest: true
```

**El mismo ataque, el mismo modelo, el mismo prompt.** Lo único que cambia es que en `solucion/` están implementadas la validación de viabilidad y el filtro de visibilidad del lore. Esa es la tesis entera de la Parte 20: la defensa es de **arquitectura**, no de prompt.

## 📦 Qué hay dentro

| Pieza | Archivo | Clase |
|---|---|---|
| Abstracción de proveedor | `ia/ai_provider.gd` | [334](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/334-proveedores-locales-y-remotos/README.md) |
| Mock, mock adversario y «sin IA» | `ia/proveedores.gd` | [334](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/334-proveedores-locales-y-remotos/README.md) |
| Cadena con degradación | `ia/servicio_ia.gd` | [334](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/334-proveedores-locales-y-remotos/README.md) |
| Lore con visibilidad y recuperación | `ia/base_lore.gd` | [332](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/332-rag-memoria-y-lore-del-mundo/README.md) |
| Validador de tres filtros | `ia/validador.gd` | [331](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/331-npc-controlados-por-llm/README.md) |
| Capacidades mínimas por NPC | `ia/capacidades.gd` | [336](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/336-seguridad-y-moderacion-de-ia-dentro-del-juego/README.md) |
| Saneado y filtro de privacidad | `ia/saneador.gd` | [336](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/336-seguridad-y-moderacion-de-ia-dentro-del-juego/README.md) |
| Caché por clave normalizada | `ia/cache_ia.gd` | [335](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/335-coste-latencia-cache-y-fallbacks/README.md) |
| El NPC con el pipeline completo | `scripts/npc_seguro.gd` | [331](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/331-npc-controlados-por-llm/README.md) |

## ✅ Qué verifica la CI

```bash
godot --headless --path labs/ai-game-system/solucion --script res://pruebas/ia_test.gd
```

```text
== 55 comprobaciones, 0 fallos ==
```

- **Sin IA**: el sistema arranca, el NPC responde con su diálogo escrito y **no se produce ningún efecto**.
- **Lore**: 26 entradas validadas; un secreto no se filtra sin su quest y sí aparece después; el lore privado de un NPC no lo conocen los demás; la recuperación es **determinista** y normaliza acentos, signos y mayúsculas.
- **Validación**: los ocho motivos de rechazo se provocan uno a uno — no es JSON, esquema incompleto, respuesta larguísima, fuga del prompt, intención desconocida, quest inventada, item no autorizado y cantidad por encima del máximo.
- **Mock adversario**: **siete ataques distintos**, con el modelo obedeciendo por completo al atacante, y **ninguno altera el estado del juego**. En todos el NPC responde algo coherente.
- **Seguridad**: la entrada se acota a 300 caracteres, los delimitadores se neutralizan, los intentos de redirección se **marcan** (no se bloquean, para no producir falsos positivos con frases normales) y un dato personal en el contexto corta la petición.
- **Caché y degradación**: dos preguntas equivalentes cuestan una sola llamada; el estado que cambia la respuesta cambia la clave; con el proveedor caído la cadena degrada a «sin IA» y el NPC sigue respondiendo.

## 🔍 Qué NO cubre

- **No hay proveedor real.** El contrato está listo; implementarlo —y el proxy que guarda la clave, del lado del servidor— es cosa tuya ([clase 334](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/334-proveedores-locales-y-remotos/README.md)).
- **No hay memoria persistente** ([clase 332](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/332-rag-memoria-y-lore-del-mundo/README.md)): hay recuperación de lore, pero no memoria a largo plazo guardada entre sesiones.
- **No hay generación de contenido** ([clase 333](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/333-dialogo-quests-y-contenido-generativo/README.md)) ni arnés de evaluación con métricas ([clase 337](../../classes/parte-20-ia-generativa-y-desarrollo-asistido-por-ia/337-evaluacion-de-sistemas-generativos/README.md)).
- **La moderación es mínima** y está ajustada al tema: una lista de palabras bloqueadas por NPC. Un juego real necesita más, y con criterio propio.
