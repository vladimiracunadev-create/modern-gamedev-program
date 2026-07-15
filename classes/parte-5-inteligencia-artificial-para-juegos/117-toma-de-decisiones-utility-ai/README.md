# Clase 117 — Toma de decisiones: utility AI

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Dave Mark, "Behavioral Mathematics for Game AI" + Game AI Pro (cap. "An Introduction to Utility Theory")*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Aprender a construir una IA que **decide por puntuación** en lugar de por reglas rígidas. Al terminar sabrás modelar acciones (atacar, huir, curarse, cubrirse), evaluar cada una con **curvas de respuesta** sobre el estado del agente (salud, distancia, munición), y elegir cada frame la de **mayor utilidad**. Verás por qué este enfoque produce comportamientos más fluidos y fáciles de ajustar que un árbol de `if` anidados.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar el ciclo de una IA de utilidad: puntuar → elegir la máxima → ejecutar.
- Normalizar valores del mundo al rango [0, 1] con curvas de respuesta.
- Modelar acciones como clases con un método `puntuar(contexto)`.
- Combinar varias consideraciones en una única puntuación por acción.
- Ajustar el carácter del agente cambiando curvas y pesos sin tocar la lógica.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Utilidad y decisión | Base para elegir "la mejor" acción de forma continua |
| 2 | Normalización [0,1] | Permite comparar magnitudes distintas (salud vs distancia) |
| 3 | Curvas de respuesta | Definen cómo un valor del mundo se traduce en deseo |
| 4 | Consideraciones múltiples | Una acción se juzga por varios factores a la vez |
| 5 | Selección de la máxima | El agente actúa según la puntuación ganadora |
| 6 | Curvas por acción | Cada acción tiene su propia sensibilidad al estado |
| 7 | Utility vs reglas fijas | Ventajas de escalabilidad y ajuste |

## 📖 Definiciones y características

- **Utilidad**: número en [0, 1] que expresa cuán deseable es una acción ahora. Clave: mayor utilidad = más prioridad.
- **Consideración**: un factor de entrada (ej. salud actual) normalizado a [0, 1]. Clave: alimenta la curva de respuesta.
- **Curva de respuesta**: función que mapea la entrada normalizada a una salida. Clave: lineal, cuadrática, inversa o logística cambian el "carácter".
- **Puntuación de acción**: producto o promedio de sus consideraciones. Clave: multiplicar hace que un factor en 0 anule la acción.
- **Selector de utilidad**: componente que evalúa todas las acciones y ejecuta la ganadora. Clave: se recalcula cada frame o cada intervalo.
- **Contexto**: estado del mundo que reciben las acciones para puntuarse. Clave: normalmente un `Dictionary` (blackboard).
- **Ventaja sobre reglas fijas**: añadir una acción no obliga a reescribir condiciones existentes. Clave: cada acción es independiente.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x**. Modelaremos las acciones con `class_name` extendiendo `RefCounted`, sin nodos pesados. Crea `res://ia/utility/`. Revisa [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html), el uso de `clampf`, `lerpf` y `Callable`. El agente será un `CharacterBody2D` que actúa según la decisión, pero el motor de utilidad es puro GDScript reutilizable.

## 🧪 Laboratorio guiado

Crearemos un agente que cada frame evalúa cuatro acciones y ejecuta la de mayor utilidad, mostrando en pantalla cuál eligió.

### Paso 1 — Curvas de respuesta reutilizables

```gdscript
class_name Curvas
extends RefCounted

# Todas reciben y devuelven valores en [0, 1].

static func lineal(x: float) -> float:
	return clampf(x, 0.0, 1.0)

static func inversa(x: float) -> float:
	return clampf(1.0 - x, 0.0, 1.0)

static func cuadratica(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x

# Logística: transición suave alrededor de 'centro' con 'pendiente'.
static func logistica(x: float, centro: float = 0.5, pendiente: float = 12.0) -> float:
	return 1.0 / (1.0 + exp(-pendiente * (x - centro)))
```

### Paso 2 — Acción base

```gdscript
class_name AccionUtilidad
extends RefCounted

var nombre: String = "accion"

# Devuelve una utilidad en [0, 1] a partir del contexto (blackboard).
func puntuar(_ctx: Dictionary) -> float:
	return 0.0

# Ejecuta la acción sobre el agente.
func ejecutar(_agente: Node, _delta: float) -> void:
	pass
```

### Paso 3 — Cuatro acciones concretas

```gdscript
class_name AccionCurarse
extends AccionUtilidad

func _init() -> void:
	nombre = "curarse"

func puntuar(ctx: Dictionary) -> float:
	# Muy deseable con poca salud; casi nula con salud alta.
	var salud: float = ctx["salud"]  # ya normalizada [0,1]
	var deseo_por_salud: float = Curvas.inversa(salud)
	var hay_pocion: float = 1.0 if ctx["pociones"] > 0 else 0.0
	# Multiplicar: sin pociones la utilidad cae a 0.
	return Curvas.cuadratica(deseo_por_salud) * hay_pocion
```

```gdscript
class_name AccionHuir
extends AccionUtilidad

func _init() -> void:
	nombre = "huir"

func puntuar(ctx: Dictionary) -> float:
	var salud: float = ctx["salud"]
	var cercania: float = ctx["cercania_enemigo"]  # 1 = pegado, 0 = lejos
	# Huir cuando estoy débil Y el enemigo está cerca.
	return Curvas.inversa(salud) * Curvas.logistica(cercania, 0.6, 10.0)
```

```gdscript
class_name AccionAtacar
extends AccionUtilidad

func _init() -> void:
	nombre = "atacar"

func puntuar(ctx: Dictionary) -> float:
	var municion: float = ctx["municion"]        # [0,1]
	var cercania: float = ctx["cercania_enemigo"]
	var salud: float = ctx["salud"]
	# Atacar si tengo balas, el enemigo está a tiro y no estoy moribundo.
	return Curvas.lineal(municion) * Curvas.lineal(cercania) * Curvas.logistica(salud, 0.3, 8.0)
```

```gdscript
class_name AccionCubrirse
extends AccionUtilidad

func _init() -> void:
	nombre = "cubrirse"

func puntuar(ctx: Dictionary) -> float:
	# Recargar/protegerse cuando queda poca munición pero aún hay salud.
	var municion: float = ctx["municion"]
	var salud: float = ctx["salud"]
	return Curvas.inversa(municion) * Curvas.lineal(salud) * 0.9
```

### Paso 4 — El selector y el agente

```gdscript
extends CharacterBody2D

var acciones: Array[AccionUtilidad] = []
var _actual: AccionUtilidad
@onready var etiqueta: Label = $Label

# Estado de ejemplo del agente.
var salud: float = 1.0
var municion: float = 1.0
var pociones: int = 2
var dist_enemigo: float = 400.0

func _ready() -> void:
	acciones = [AccionCurarse.new(), AccionHuir.new(), AccionAtacar.new(), AccionCubrirse.new()]

func _construir_contexto() -> Dictionary:
	return {
		"salud": clampf(salud, 0.0, 1.0),
		"municion": clampf(municion, 0.0, 1.0),
		"pociones": pociones,
		# Convertimos distancia (0-400 px) en cercanía normalizada.
		"cercania_enemigo": clampf(1.0 - dist_enemigo / 400.0, 0.0, 1.0),
	}

func _physics_process(delta: float) -> void:
	var ctx: Dictionary = _construir_contexto()
	var mejor: AccionUtilidad = null
	var mejor_valor: float = -1.0
	for a in acciones:  # elegimos la acción de mayor utilidad
		var v: float = a.puntuar(ctx)
		if v > mejor_valor:
			mejor_valor = v
			mejor = a
	_actual = mejor
	etiqueta.text = "%s (%.2f)" % [mejor.nombre, mejor_valor]
	mejor.ejecutar(self, delta)
```

Ejecuta y modifica en el inspector `salud`, `municion` y `dist_enemigo`: la etiqueta muestra en vivo qué acción gana. Observable: al bajar la salud con enemigo cerca, la decisión salta de "atacar" a "huir" o "curarse".

## ✍️ Ejercicios

1. Añade una quinta acción "patrullar" con utilidad base baja constante (0.1) como comportamiento por defecto.
2. Cambia la curva de `AccionCurarse` de cuadrática a logística y compara la sensibilidad.
3. Introduce histéresis: multiplica la utilidad de la acción actual por 1.2 para evitar parpadeos.
4. Grafica las utilidades de las cuatro acciones en pantalla con barras.
5. Haz que `pociones` baje al curarse y verifica que "curarse" deja de ganar al llegar a 0.
6. Evalúa las decisiones solo cada 0.2 s con un `Timer` en vez de cada frame.

## 📝 Reto verificable

Implementa un agente con **al menos cinco acciones** cuyo comportamiento sea coherente en tres escenarios: (a) salud alta + enemigo cerca + munición → ataca; (b) salud baja + con pociones → se cura; (c) sin munición + salud media → se cubre/recarga.

**Criterio de aceptación**: al fijar los valores de cada escenario, la acción ganadora impresa coincide con la esperada en los tres casos, y añadir una acción nueva no requiere modificar el código de las acciones existentes ni del selector.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El agente "parpadea" entre acciones | Utilidades casi empatadas cada frame. Añade histéresis o evalúa con menos frecuencia. |
| Una acción nunca gana | Su curva satura en valores bajos, o multiplicas por un factor 0. Revisa el rango de sus consideraciones. |
| Valores fuera de [0,1] rompen la comparación | No normalizaste una entrada. Usa `clampf` al construir el contexto. |
| Todas las acciones dan 0 | Multiplicas consideraciones donde una siempre es 0. Verifica los datos del contexto. |
| Difícil ajustar el carácter | Estás mezclando lógica y curvas. Aísla las curvas en funciones reutilizables. |

## ❓ Preguntas frecuentes

**¿Multiplicar o promediar consideraciones?** Multiplicar da "vetos" (un factor 0 anula la acción); promediar es más tolerante. Se suele multiplicar para condiciones necesarias.

**¿Utility AI reemplaza a los árboles de comportamiento?** No; se complementan. La utilidad decide *qué* meta perseguir y un BT puede ejecutar el *cómo*.

**¿Cómo evito decisiones erráticas?** Con histéresis (bonus a la acción actual) o suavizando las entradas a lo largo de varios frames.

**¿Cuántas consideraciones por acción?** Pocas y claras (2-4). Demasiadas dificultan predecir y depurar el comportamiento.

## 🔗 Referencias

- Game AI Pro — Utility Theory: <http://www.gameaipro.com/>
- Dave Mark — Behavioral Mathematics for Game AI (charlas GDC): <https://www.gdcvault.com/>
- Godot Docs — RefCounted: <https://docs.godotengine.org/en/stable/classes/class_refcounted.html>
- Godot Docs — GDScript exports y clases: <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html>

## ⬅️ Clase anterior

[Clase 116 - Percepción: visión, oído y memoria del agente](../116-percepcion-vision-oido-y-memoria-del-agente/README.md)

## ➡️ Siguiente clase

[Clase 118 - GOAP: planificación orientada a objetivos](../118-goap-planificacion-orientada-a-objetivos/README.md)
