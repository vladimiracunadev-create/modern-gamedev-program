# Clase 108 — Panorama de la IA de juegos: qué es y qué no

> Parte: **5 — Inteligencia artificial para juegos** · Fuente: *Ian Millington & John Funge, "Artificial Intelligence for Games" (2ª ed.) + Steve Rabin, "Game AI Pro"*
> ⏱️ Duración estimada: **45 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Construir un mapa mental claro de qué es (y qué no es) la inteligencia artificial en videojuegos antes de escribir una sola línea de comportamiento. Al terminar distinguirás la IA de juegos —cuyo fin es ser **creíble y divertida**— de la IA académica y el machine learning, entenderás el bucle universal **sentir → pensar → actuar**, y sabrás nombrar las técnicas clásicas (FSM, behavior trees, utility, GOAP, pathfinding) para elegir la adecuada según el problema, no por moda.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar por qué la IA de juegos prioriza la diversión y la credibilidad sobre la optimalidad.
- Diferenciar la IA de juegos de la IA académica y del machine learning.
- Describir el bucle sentir-pensar-actuar y ubicar cada técnica dentro de él.
- Enumerar las principales técnicas de decisión y decir para qué sirve cada una.
- Analizar la IA de un juego conocido e identificar sus estados y decisiones.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | IA creíble vs IA óptima | Un enemigo perfecto no es divertido; buscamos la ilusión de inteligencia |
| 2 | IA de juegos vs IA académica/ML | Evita aplicar redes neuronales donde basta un `match` |
| 3 | El bucle sentir-pensar-actuar | Es la columna vertebral de todo agente |
| 4 | Percepción (sentir) | Sin datos del mundo no hay decisión honesta |
| 5 | Decisión (pensar) | Aquí viven FSM, BT, utility y GOAP |
| 6 | Actuación (actuar) | Movimiento, pathfinding y animación cierran el ciclo |
| 7 | "Fun over smart" | Criterio de diseño que guía cada elección técnica |

## 📖 Definiciones y características

- **IA de juegos**: conjunto de técnicas que hacen a un agente parecer inteligente ante el jugador. Clave: el objetivo es la experiencia, no la exactitud.
- **IA académica**: busca resolver problemas de forma óptima o general (planificación, búsqueda, aprendizaje). Clave: la métrica es el rendimiento, no la diversión.
- **Machine learning**: sistemas que aprenden patrones a partir de datos. Clave: raro en la lógica de enemigos comerciales por coste y control.
- **Bucle sentir-pensar-actuar**: ciclo de percibir el mundo, decidir y ejecutar. Clave: se repite cada frame o cada tick de IA.
- **Percepción**: cómo el agente obtiene información (visión, oído, memoria). Clave: debe tener límites para ser justa con el jugador.
- **Toma de decisiones**: mecanismo que elige la acción (FSM, BT, utility, GOAP). Clave: elegir la más simple que resuelva el caso.
- **"Fun over smart"**: principio de que la IA debe entretener, no ganar. Clave: a veces conviene que el enemigo falle a propósito.

## 🧰 Herramientas y preparación

Esta clase es conceptual y de análisis, así que solo necesitas Godot 4.x abierto para escribir pseudocódigo comentado en un `Node` de práctica, y un juego que conozcas bien (un shooter, un stealth o un plataformas con enemigos). Ten a mano papel o un archivo de texto para esbozar diagramas de estados. Como apoyo teórico, revisa los artículos gratuitos de [Game AI Pro](http://www.gameaipro.com/) y el capítulo introductorio de *Artificial Intelligence for Games*. La documentación de [scripting de Godot 4](https://docs.godotengine.org/en/stable/tutorials/scripting/index.html) te servirá para dar forma al esqueleto del guardia.

## 🧪 Laboratorio guiado

No programaremos un agente funcional todavía: el objetivo es **modelar** el pensamiento de una IA y expresarlo como esqueleto en GDScript, algo que podrás ejecutar aunque solo imprima texto.

**Paso 1 — Elige y observa.** Toma un juego con enemigos (por ejemplo, un guardia de un stealth). Juega 5 minutos observando **solo a un enemigo**. Anota: ¿qué hace cuando no te ve? ¿qué cambia cuando te ve? ¿qué pasa cuando te pierde?

**Paso 2 — Lista sus estados.** Con lo observado, escribe la lista de estados aparentes. Para un guardia típico saldrá algo como: `PATRULLA`, `ALERTA`, `PERSIGUE`, `BUSCA`, `VUELVE`.

**Paso 3 — Identifica las transiciones.** Para cada cambio de comportamiento, escribe la condición que lo dispara: "de PATRULLA a PERSIGUE cuando ve al jugador".

**Paso 4 — Esboza el bucle en GDScript.** Crea una escena con un `Node` raíz, adjunta un script y escribe el esqueleto sentir-pensar-actuar como pseudocódigo ejecutable:

```gdscript
extends Node

# Estados aparentes que observamos en el guardia real.
enum Estado { PATRULLA, PERSIGUE, BUSCA }

var estado: Estado = Estado.PATRULLA
var ve_al_jugador: bool = false
var recuerda_al_jugador: bool = false

func _ready() -> void:
	# Simulamos tres ticks de IA para ver el bucle en acción.
	for tick in 3:
		_tick_ia()
		ve_al_jugador = tick == 1   # el jugador aparece en el tick 1

func _tick_ia() -> void:
	var percepcion := _sentir()          # 1) SENTIR
	estado = _pensar(percepcion)         # 2) PENSAR
	_actuar()                            # 3) ACTUAR

func _sentir() -> Dictionary:
	# En un juego real aquí consultaríamos RayCast2D, Area2D, etc.
	return { "ve": ve_al_jugador, "recuerda": recuerda_al_jugador }

func _pensar(p: Dictionary) -> Estado:
	if p["ve"]:
		recuerda_al_jugador = true
		return Estado.PERSIGUE
	if p["recuerda"]:
		return Estado.BUSCA
	return Estado.PATRULLA

func _actuar() -> void:
	match estado:
		Estado.PATRULLA: print("Camino mi ruta tranquilo.")
		Estado.PERSIGUE: print("¡Te vi! Voy hacia ti.")
		Estado.BUSCA:    print("Te perdí... reviso la última posición.")
```

**Paso 5 — Ejecuta y lee la consola.** Al correr la escena verás en la salida cómo el guardia pasa de patrullar a perseguir cuando "ve" al jugador y luego a buscar cuando lo pierde. Ese texto es tu bucle sentir-pensar-actuar funcionando.

**Resultado visible:** tres líneas en la consola que narran la transición de estados de tu guardia, más un diagrama en papel con estados y flechas.

## ✍️ Ejercicios

1. Analiza un segundo juego y compara: ¿su IA parece más "creíble" o más "óptima"? Justifica.
2. Añade un cuarto estado (`VUELVE` a la ruta) al esqueleto y su transición desde `BUSCA`.
3. Escribe tres ejemplos de IA que sea divertida precisamente por **no** ser óptima.
4. Clasifica cinco comportamientos de un juego que conozcas en sentir, pensar o actuar.
5. Explica en dos frases por qué usar machine learning para un guardia de patrulla suele ser exagerado.
6. Dibuja el diagrama de estados completo del guardia con todas sus transiciones.

## 📝 Reto verificable

Elige un enemigo de un juego real y entrega un documento con: (a) su lista de estados, (b) una tabla de transiciones con la condición de cada una, y (c) el esqueleto sentir-pensar-actuar en GDScript que imprima por consola al menos cuatro estados distintos según la percepción simulada.

**Criterio de aceptación**: el script corre sin errores, imprime como mínimo cuatro comportamientos diferentes, y el documento identifica claramente qué parte del bucle corresponde a cada bloque de código.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Diseñas una IA "que siempre gane" y no es divertida | Confundes óptimo con creíble; añade fallos y límites de percepción |
| Quieres usar ML para todo | Empieza por FSM o BT; el ML rara vez compensa en lógica de enemigos |
| Mezclas sentir, pensar y actuar en una función gigante | Sepáralos en tres pasos claros como en el laboratorio |
| El agente reacciona con datos que no debería tener | La percepción no tiene límites; modela visión y memoria explícitas |
| Eliges la técnica por moda, no por el problema | Parte del comportamiento deseado y elige la herramienta más simple |

## ❓ Preguntas frecuentes

**¿La IA de juegos usa redes neuronales?**
Casi nunca en la lógica de enemigos comerciales. Dominan FSM, behavior trees y utility por ser controlables, depurables y baratas.

**¿Por qué un enemigo no debería ser perfecto?**
Porque un rival imbatible frustra. La gracia está en la ilusión de inteligencia con puntos débiles que el jugador descubre.

**¿Dónde encaja el pathfinding en el bucle?**
En "actuar": una vez decidido *adónde* ir, el pathfinding resuelve *cómo* llegar rodeando obstáculos.

**¿Necesito matemáticas avanzadas para esta parte?**
Vectores básicos y lógica bastan para empezar. Las técnicas más avanzadas (utility, GOAP) introducen su propia matemática poco a poco.

## 🔗 Referencias

- [Game AI Pro — artículos gratuitos](http://www.gameaipro.com/)
- [Artificial Intelligence for Games (CRC Press)](https://www.routledge.com/Artificial-Intelligence-for-Games/Millington/p/book/9780367670566)
- [GDC Vault — charlas de IA de juegos](https://www.gdcvault.com/)
- [Introducción al scripting — Godot Docs](https://docs.godotengine.org/en/stable/tutorials/scripting/index.html)

## ⬅️ Clase anterior

[Clase 107 - Capstone Parte 4: set de shaders y post-procesado](../../parte-4-graficos-shaders-y-rendering-moderno/107-capstone-parte-4-set-de-shaders-y-post-procesado/README.md)

## ➡️ Siguiente clase

[Clase 109 - Máquinas de estado finito (FSM) para IA](../109-maquinas-de-estado-finito-fsm-para-ia/README.md)
