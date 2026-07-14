# Clase 023 — Debugging y profiling: herramientas y mentalidad

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Documentación de depuradores; Godot debugger y profiler*
> ⏱️ Duración estimada: **90 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Depurar no es adivinar: es un método. Ante un fallo, el desarrollador experto no cambia líneas al azar, sino que **reproduce** el problema, lo **aísla**, formula una **hipótesis** y la **verifica**. Las herramientas —breakpoints, watch, pila de llamadas, prints estratégicos— sirven a ese método, no lo sustituyen.

El **profiling** es la cara del rendimiento: antes de optimizar hay que **medir**, porque la intuición sobre qué es lento suele fallar. En esta clase adoptarás la mentalidad de depuración, usarás el depurador de Godot para pausar en un error, inspeccionar variables y leer la pila, y abrirás el profiler para observar FPS, tiempo por cuadro, draw calls y memoria, identificando cuellos de botella con datos en vez de corazonadas.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Aplicar el ciclo reproducir → aislar → hipótesis → verificar ante un bug.
2. Colocar breakpoints y usar watch y la pila de llamadas en el depurador de Godot.
3. Usar prints estratégicos para acotar un problema sin llenar la consola de ruido.
4. Leer FPS, tiempo por cuadro, draw calls y memoria en el profiler de Godot.
5. Justificar por qué se mide antes de optimizar y localizar un cuello de botella.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Método de depuración | Evita cambios al azar y ahorra horas. |
| 2 | Reproducir el fallo | Sin reproducirlo no se puede arreglar. |
| 3 | Breakpoints y watch | Pausar y observar el estado real. |
| 4 | Pila de llamadas | Saber cómo se llegó al error. |
| 5 | Prints estratégicos | Acotar sin depurador cuando conviene. |
| 6 | Profiler | Medir FPS, cuadro, draw calls, memoria. |
| 7 | Cuellos de botella | Dónde se va realmente el tiempo. |
| 8 | Medir antes de optimizar | La intuición engaña; los datos no. |

## 📖 Definiciones y características

- **Bug**: comportamiento distinto del esperado. Clave: se ataca reproduciéndolo, no adivinando.
- **Breakpoint**: marca que pausa la ejecución en una línea. Clave: permite inspeccionar el estado en ese punto.
- **Watch / inspección**: ver el valor de variables mientras la ejecución está pausada. Clave: confirma o descarta hipótesis.
- **Pila de llamadas (stack)**: cadena de funciones que llevaron al punto actual. Clave: revela el origen del flujo.
- **Print estratégico**: mensaje puntual y etiquetado para acotar. Clave: pocos y significativos, no ruido.
- **Profiler**: herramienta que mide el coste de cada parte del cuadro. Clave: datos objetivos de rendimiento.
- **Draw call**: orden de dibujo enviada a la GPU. Clave: muchas draw calls encarecen el render.
- **Cuello de botella**: la parte que limita el rendimiento global. Clave: optimizar otra cosa no ayuda.

## 🧰 Herramientas y preparación

Usarás **Godot 4** y sus paneles integrados: el **Depurador** (panel inferior *Depurador*, con pestañas *Pila de variables*, *Errores* y *Puntos de interrupción*) y el **Monitor/Profiler** (pestañas *Monitores* y *Profiler* del mismo panel). No necesitas instalar nada extra. Ten un proyecto 2D con un par de nodos para experimentar. Como lecturas de apoyo están la documentación oficial de depuración de Godot (<https://docs.godotengine.org/en/stable/tutorials/scripting/debug/overview_of_debugging_tools.html>) y la del profiler (<https://docs.godotengine.org/en/stable/tutorials/scripting/debug/the_profiler.html>). El método general de depuración es transversal a cualquier depurador (GDB, el de VS Code, etc.).

## 🧪 Laboratorio guiado

### Paso 1 — Provocar un bug reproducible

Crea un script con un error típico: acceder a un elemento fuera de rango o a un nodo nulo.

```gdscript
extends Node

func _ready() -> void:
	var enemigos := ["orco", "goblin"]
	print(enemigos[5])   # error: indice fuera de rango
```

Ejecuta el proyecto. Godot detiene la ejecución y muestra el error en el panel *Depurador*. **Reproducir** de forma fiable es el primer paso: si el fallo ocurre siempre aquí, es abordable.

### Paso 2 — Leer el error y la pila de llamadas

En el panel *Depurador*, pestaña *Pila de variables*, observa la línea señalada y la **pila de llamadas**: te dice qué función llamó a cuál hasta llegar al error. Esto **aísla** el problema al método `_ready` y a la línea concreta. La hipótesis es clara: el índice 5 no existe en un arreglo de dos elementos.

### Paso 3 — Colocar un breakpoint e inspeccionar

Corrige el índice a algo válido pero añade un breakpoint para observar el estado. Haz clic en el margen izquierdo de una línea (aparece un punto rojo) o usa la palabra clave `breakpoint`:

```gdscript
func _ready() -> void:
	var enemigos := ["orco", "goblin"]
	var indice := 1
	breakpoint            # la ejecucion se pausa aqui
	print(enemigos[indice])
```

Al ejecutar, el juego se pausa. En el panel del depurador inspecciona `enemigos` e `indice`: confirmas sus valores reales antes de que se use la variable. Esto **verifica** la hipótesis con datos, no suposiciones.

### Paso 4 — Prints estratégicos para acotar

Cuando el depurador es incómodo (bucles muy repetidos, timing), usa prints etiquetados y escasos:

```gdscript
func mover(delta: float) -> void:
	print("[mover] pos=", position, " delta=", delta)
	position.x += 240.0 * delta
```

La etiqueta `[mover]` permite filtrar la consola y entender de un vistazo qué cambia. Retíralos al terminar: prints de más ensucian la salida y ralentizan.

### Paso 5 — Abrir el profiler y leer métricas

Ejecuta un proyecto con algo de carga (muchos nodos o dibujos), abre el panel *Depurador > Profiler* y pulsa *Iniciar*. Observa el tiempo por cuadro y qué funciones lo consumen. En *Monitores* activa gráficas como **FPS**, **tiempo de proceso**, **draw calls** (Raster > Draw Calls) y **memoria de vídeo**. Para inspeccionar en código:

```gdscript
func _process(_delta: float) -> void:
	print("FPS: ", Engine.get_frames_per_second())
	print("Draw calls: ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
```

Con estos números localizas el cuello de botella: si las draw calls son altísimas, el problema es de render; si una función domina el profiler, es de CPU. **Mides primero, optimizas después.**

## ✍️ Ejercicios

1. Provoca un acceso a nodo nulo (`get_node("NoExiste").position`) y lee el error en el depurador.
2. Coloca un breakpoint dentro de un bucle y avanza paso a paso observando una variable.
3. Añade prints etiquetados a dos funciones y filtra la consola por una etiqueta.
4. Instancia 500 nodos y compara las draw calls y el FPS en los monitores.
5. Usa `Performance.get_monitor` para imprimir la memoria de vídeo cada segundo.
6. Describe la pila de llamadas de un error producido dentro de una función anidada.

## 📝 Reto verificable

Toma un proyecto con un bug de tu elección (índice fuera de rango o nodo nulo) y documenta el ciclo completo: reproducir el fallo, aislarlo con la pila de llamadas, formular una hipótesis, verificarla con un breakpoint inspeccionando variables y corregirlo. Después, con el proyecto ya funcionando pero con carga (muchos nodos), abre el profiler y anota FPS, tiempo por cuadro y draw calls, identificando el mayor consumidor.

**Criterio de aceptación**: el informe describe los cuatro pasos del método con la variable inspeccionada en el breakpoint que confirmó la causa; y se incluyen tres métricas leídas del profiler (FPS, tiempo por cuadro y draw calls) con una frase señalando cuál es el cuello de botella.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| `Invalid get index 'X' on base: Array` | Índice fuera de rango. Valida el tamaño antes de acceder al elemento. |
| `Attempt to call function ... on a null instance` | El nodo no existe todavía o la ruta es errónea. Comprueba con `is_instance_valid` o `has_node`. |
| El breakpoint no detiene la ejecución | La línea no se ejecuta o el depurador está desactivado. Verifica el flujo y que corres desde el editor. |
| La consola es ilegible de tantos prints | Prints sin etiqueta y demasiados. Etiqueta, reduce y retíralos al terminar. |
| Optimizaste y el juego sigue lento | Optimizaste lo que no era el cuello de botella. Mide con el profiler antes de tocar nada. |

## ❓ Preguntas frecuentes

**❓ ¿Breakpoints o prints, qué es mejor?** Depende. Los breakpoints dan una foto completa del estado en un punto y son ideales para inspeccionar. Los prints sirven cuando necesitas ver una evolución en el tiempo o en bucles muy rápidos donde pausar es incómodo.

**❓ ¿Qué me dice la pila de llamadas?** La cadena de funciones que se invocaron hasta llegar al error. Te permite reconstruir el camino y descubrir que el fallo real está en quien llamó a la función, no siempre en la línea que reventó.

**❓ ¿Por qué no optimizar directamente lo que "parece" lento?** Porque la intuición sobre rendimiento acierta poco. Sin medir, es fácil dedicar horas a acelerar algo irrelevante mientras el verdadero cuello de botella sigue intacto.

**❓ ¿Qué son las draw calls y por qué importan?** Son las órdenes de dibujo que la CPU envía a la GPU. Muchas draw calls saturan esa comunicación y bajan el FPS; agrupar sprites o usar atlas reduce su número.

## 🔗 Referencias

- Godot Docs, "Overview of debugging tools": <https://docs.godotengine.org/en/stable/tutorials/scripting/debug/overview_of_debugging_tools.html>
- Godot Docs, "The Profiler": <https://docs.godotengine.org/en/stable/tutorials/scripting/debug/the_profiler.html>
- Godot Docs, "Debugger panel": <https://docs.godotengine.org/en/stable/tutorials/scripting/debug/debugger_panel.html>
- Godot Docs, "Performance monitors": <https://docs.godotengine.org/en/stable/classes/class_performance.html>

## ➡️ Siguiente clase

[Clase 024 - Prototipado rápido y bucle de iteración de diseño](../024-prototipado-rapido-y-bucle-de-iteracion-de-diseno/README.md)
