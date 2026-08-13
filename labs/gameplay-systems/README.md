# 🧩 Lab: Sistemas de gameplay

> [⬅️ Volver a los laboratorios](../README.md) · [📚 Parte 18](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/README.md) · [🎓 Clase 310 (capstone)](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/310-capstone-parte-18-un-juego-sistemico/README.md)

Los sistemas que aparecen en cuanto un juego pasa de tres escenas a treinta: catálogo de objetos, inventario, equipo, estadísticas con modificadores, habilidades, efectos de estado, loot, progresión, economía, misiones y guardado versionado. **Todos funcionando juntos y verificados por una máquina.**

No hay gráficos, y es a propósito: este laboratorio se juzga por sus **122 comprobaciones**, no por su aspecto. Todo el dominio son clases `RefCounted` sin nodos, así que la batería entera corre headless en menos de un segundo.

## 📦 Qué hay dentro

| Sistema | Archivo | Clase |
|---|---|---|
| Catálogo de items con validación | `dominio/base_items.gd` | [294](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/294-items-y-base-de-datos-de-objetos/README.md) |
| Inventario por ranuras y transacciones | `dominio/inventario.gd` | [295](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/295-sistema-de-inventario/README.md) |
| Estadísticas con modificadores | `dominio/estadistica.gd`, `stats.gd` | [296](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/296-equipamiento-loadouts-y-estadisticas/README.md) |
| Equipamiento con slots y restricciones | `dominio/equipo.gd` | [296](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/296-equipamiento-loadouts-y-estadisticas/README.md) |
| Habilidades con fases, coste y cooldown | `dominio/habilidades.gd` | [297](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/297-ability-system-arquitectura-de-habilidades/README.md) |
| Efectos de estado y apilamiento | `dominio/efectos.gd` | [298](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/298-status-effects-buffs-y-debuffs/README.md) |
| Tablas de loot deterministas | `dominio/loot.gd` | [300](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/300-loot-tables-y-sistemas-de-recompensas/README.md) |
| Progresión y desbloqueos | `dominio/progresion.gd` | [302](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/302-progresion-y-skill-trees/README.md) |
| Monedero con punto único de mutación | `dominio/monedero.gd` | [303](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/303-economia-interna-implementada/README.md) |
| Misiones por eventos | `dominio/quests.gd`, `eventos.gd` | [305](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/305-quest-system/README.md) |
| Guardado con migraciones y backups | `infraestructura/guardado.gd` | [307](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/307-save-system-de-produccion/README.md) |

El pegamento está en `scripts/juego.gd`, el **composition root**: el único archivo que conoce a todos los sistemas. Lo comparten la escena principal y las pruebas, así que lo que se verifica es exactamente lo que se ejecuta.

## 🚀 Cómo usarlo

```bash
godot --path labs/gameplay-systems/inicio
```

```bash
godot --headless --path labs/gameplay-systems/solucion --script res://pruebas/sistemas_test.gd
```

La versión `inicio/` trae la misma estructura con los `TODO` marcados en el código: inventario (`cabe`, `agregar`, `quitar`, `mover`), equipo (`equipar`, `desequipar`), efectos (`tick`), misiones (`_avanzar`) y las dos migraciones de guardado. Arranca y construye el mundo igual, pero sus sistemas no hacen nada todavía — y las pruebas lo dicen.

## ✅ Qué verifica la CI

La batería cubre exactamente lo que se puede romper en silencio:

- **Apilamiento y ranuras**: reparto entre stacks parciales, restante que no cabe, ranura vaciada como `null`.
- **Operaciones atómicas**: una operación fallida deja el inventario **byte a byte** igual (`a_dict()` comparado antes y después).
- **Equipar / desequipar**: el modificador se aplica, no se duplica al reemplazar y **no deja residuo** al quitarlo. Con el inventario lleno no se desequipa, y no se destruye nada.
- **Modificadores**: el orden documentado (base → planos → porcentuales → multiplicativos) da exactamente `29.25` para el caso de referencia.
- **Cooldown y fases**: los ocho motivos de rechazo del sistema de habilidades se provocan y se comprueban uno a uno.
- **Efectos de estado**: apilamiento `STACK`, `IGNORAR` e `INDEPENDIENTE`; daño periódico **independiente del framerate**; residuo cero al expirar.
- **Transiciones de quest**: la máquina de estados rechaza lo inválido y lo registra; los objetivos secuenciales no se saltan el orden; entregar con el inventario lleno no consume la recompensa.
- **Loot determinista**: la misma semilla produce exactamente el mismo loot; los garantizados caen siempre; las entradas condicionadas no salen sin cumplir su condición.
- **Migraciones de guardado**: un save de la v1 llega a la v3 conservando el oro y renombrando la habilidad; el estado restaurado es **idéntico** al guardado; un save corrupto se recupera del backup; un checksum manipulado lo invalida.

```text
== 122 comprobaciones, 0 fallos ==
```

Y una comprobación que no está en la lista pero importa igual: al terminar, **no queda ni una instancia filtrada**. Los ciclos de referencia entre sistemas conectados por señales se rompen explícitamente en `Juego.liberar()` — es el problema de la [clase 340](../../classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/340-allocators-y-gestion-avanzada-de-memoria/README.md), y aquí se ve de verdad.

## 🔍 Qué NO cubre

Ser exacto con esto vale más que una lista de promesas:

- **No hay interfaz.** El inventario emite `ranura_cambiada(i)` y nadie escucha. Dibujarlo es el ejercicio 6 de la clase 295.
- **No hay pipeline de daño** ([clase 299](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/299-arquitectura-avanzada-de-combate-y-dano/README.md)): las habilidades publican sus efectos y el laboratorio comprueba que llegan, pero no los convierte en daño.
- **No hay crafteo, diálogo ni facciones** (clases 301, 304 y 306). El capstone completo sí los pide; aquí están fuera para que la batería siga siendo legible.
- **El guardado es local.** La versión en la nube y sus conflictos son la [clase 313](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/313-cloud-saves-cross-save-y-resolucion-de-conflictos/README.md).
