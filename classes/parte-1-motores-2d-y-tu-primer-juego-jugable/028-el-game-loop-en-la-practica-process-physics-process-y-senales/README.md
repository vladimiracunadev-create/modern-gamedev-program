# Clase 028 — El game loop en la práctica: _process,_physics_process y señales

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4 (Idle and Physics processing, Signals)*
> ⏱️ Duración estimada: **80 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Comprender en la práctica cómo Godot ejecuta tu juego cada frame mediante `_process(delta)` y `_physics_process(delta)`, cuándo usar cada uno y por qué el `delta` es esencial para un movimiento independiente de la velocidad del equipo.

Además, aprenderás el sistema de eventos de Godot: las **señales**. Declararás una señal propia, la conectarás por el editor y por código, y la emitirás para desacoplar objetos. El laboratorio mueve el sprite con `delta` y usa un `Timer` con señal para llevar un contador en pantalla.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar la diferencia entre `_process` y `_physics_process` y elegir el correcto.
2. Usar `delta` para lograr movimiento independiente de los FPS.
3. Declarar, emitir y conectar una señal propia por código.
4. Conectar una señal de un nodo (Timer) desde el editor y desde script.
5. Desacoplar dos nodos usando señales en lugar de referencias directas.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | El game loop de Godot | Es el corazón que ejecuta tu lógica cada frame. |
| 2 | `_process(delta)` | Lógica de render/visual cada frame variable. |
| 3 | `_physics_process(delta)` | Física en pasos fijos y estables. |
| 4 | Qué es `delta` | Permite movimiento uniforme sin importar los FPS. |
| 5 | Señales de Godot | Sistema de eventos para comunicar nodos. |
| 6 | Conectar por editor | Enlaza señales sin escribir código. |
| 7 | Conectar y emitir por código | Control dinámico del flujo de eventos. |
| 8 | Nodo Timer | Fuente de eventos periódicos con señal. |

## 📖 Definiciones y características

- **Game loop**: ciclo que procesa entrada, actualiza estado y renderiza cada frame. Clave: en Godot lo gestiona el motor y tú enganchas callbacks.
- **`_process(delta)`**: se llama cada frame de render, a ritmo variable. Clave: ideal para animación y lógica no física.
- **`_physics_process(delta)`**: se llama a paso fijo (por defecto 60/s). Clave: obligatorio para mover cuerpos físicos con estabilidad.
- **`delta`**: segundos transcurridos desde el frame anterior. Clave: multiplicar por delta hace el movimiento independiente de los FPS.
- **Señal**: mensaje que un nodo emite y otros escuchan. Clave: desacopla emisor y receptor.
- **Emitir**: disparar la señal con `nombre.emit(args)`. Clave: notifica a todos los conectados en ese instante.
- **Conectar**: registrar un método como respuesta con `senal.connect(metodo)`. Clave: puede hacerse por editor o por código.
- **Timer**: nodo que emite `timeout` cada cierto tiempo. Clave: fuente natural de eventos periódicos.

## 🧰 Herramientas y preparación

Sigue en `PlataformasCurso`. Trabajaremos sobre `escenas/jugador.tscn` y `escenas/mundo.tscn`. No hacen falta assets nuevos. Ten a mano el panel **Output** para ver los prints y el panel **Node → Signals** (a la derecha, junto al Inspector) para conectar señales por editor.

Documentación de apoyo: procesamiento en <https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html> y señales en <https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html>.

## 🧪 Laboratorio guiado

Moveremos el sprite con `delta`, añadiremos un Timer con señal y crearemos una señal propia.

1. Abre `escenas/jugador.tscn` y reemplaza `jugador.gd` por un movimiento horizontal sencillo basado en delta:

```gdscript
extends Node2D

@export var velocidad: float = 120.0  # pixeles por segundo
var direccion: int = 1

func _process(delta: float) -> void:
	# Movimiento independiente de los FPS: pixeles/seg * segundos.
	position.x += velocidad * direccion * delta
	# Rebote simple al salir de los limites horizontales.
	if position.x > 1000.0:
		direccion = -1
	elif position.x < 152.0:
		direccion = 1
```

2. Ejecuta con F5. El sprite se desplaza a velocidad constante. Si tu equipo corriera a más FPS, `delta` sería menor y el resultado visual sería el mismo: esa es la clave.

3. Ahora un contador con Timer. Abre `escenas/mundo.tscn`, selecciona `Mundo`, añade un hijo **Timer** y renómbralo `TimerContador`. En el Inspector pon **Wait Time** a `1`, activa **Autostart** y deja **One Shot** desactivado.

4. Añade un nodo **Label** como hijo de `Mundo`, llámalo `EtiquetaContador`, colócalo arriba a la izquierda y escribe un texto inicial como `Segundos: 0`.

5. Conecta la señal del Timer **por el editor**: selecciona `TimerContador`, ve a la pestaña **Node → Signals**, doble clic en `timeout()`, elige `Mundo` como receptor y confirma. Godot creará el método `_on_timer_contador_timeout()` en `mundo.gd`.

6. Añade también una **señal propia** para practicar el desacople. Edita `mundo.gd` así:

```gdscript
extends Node2D

signal cada_diez_segundos  # senal propia que emitiremos nosotros

var segundos: int = 0

func _ready() -> void:
	# Conexion de una senal propia POR CODIGO.
	cada_diez_segundos.connect(_on_cada_diez_segundos)

# Conectada al Timer DESDE EL EDITOR (pestana Node > Signals).
func _on_timer_contador_timeout() -> void:
	segundos += 1
	$EtiquetaContador.text = "Segundos: " + str(segundos)
	if segundos % 10 == 0:
		cada_diez_segundos.emit()  # emitimos nuestra senal

func _on_cada_diez_segundos() -> void:
	print("Han pasado 10 segundos. Total: ", segundos)
```

7. Ejecuta con F5. La etiqueta debe subir de uno en uno cada segundo, y cada diez segundos el Output imprimirá el aviso emitido por tu señal propia.

8. Para comparar `_process` con `_physics_process`, añade temporalmente al `mundo.gd` estos dos métodos y observa la frecuencia en Output:

```gdscript
func _process(delta: float) -> void:
	pass  # se llama cada frame de render (variable)

func _physics_process(delta: float) -> void:
	pass  # se llama a paso fijo (por defecto 60 veces por segundo)
```

Ya tienes claro el ritmo del juego y el patrón de señales para eventos. En la próxima clase usaremos `_physics_process` con input real.

## ✍️ Ejercicios

1. Cambia `velocidad` desde el Inspector (gracias a `@export`) y observa el efecto sin tocar código.
2. Mueve la lógica de movimiento del jugador a `_physics_process` y compara la suavidad.
3. Añade una segunda `Label` que muestre los FPS con `Engine.get_frames_per_second()`.
4. Crea una señal `rebote` en el jugador que se emita cada vez que cambia de dirección e imprímela desde el mundo.
5. Desactiva **Autostart** del Timer y arráncalo por código con `$TimerContador.start()` en `_ready()`.
6. Reduce el **Wait Time** a 0.5 y ajusta el texto de la etiqueta para reflejar medios segundos.

## 📝 Reto verificable

Haz que el jugador emita una señal `rebote(nueva_direccion: int)` cada vez que invierte su marcha, y que el mundo escuche esa señal (conectándola por código a la instancia del jugador) para contar cuántos rebotes lleva y mostrarlo en una `Label`.

**Criterio de aceptación**: al ejecutar, el jugador se mueve y rebota entre los límites, y una etiqueta actualiza el número de rebotes en tiempo real usando la señal, sin que el mundo lea directamente la variable `direccion`.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El movimiento es más rápido en equipos potentes | Olvidaste multiplicar por `delta`. Usa `velocidad * delta`. |
| "Signal 'timeout' is already connected" | Conectaste la señal por editor y por código a la vez. Deja solo una. |
| El método `_on_..._timeout` no se ejecuta | El nombre no coincide o la conexión se borró. Revisa la pestaña Node → Signals. |
| "Nonexistent function 'emit'" o error al emitir | Usaste sintaxis de Godot 3. En Godot 4 es `mi_senal.emit()`. |
| La Label no cambia | Ruta `$EtiquetaContador` incorrecta. Verifica el nombre exacto del nodo. |

## ❓ Preguntas frecuentes

**❓ ¿Cuándo uso `_process` y cuándo `_physics_process`?** Usa `_physics_process` para mover cuerpos físicos y lógica que deba ser estable; usa `_process` para animación visual y lógica no física.

**❓ ¿Qué pasa si no multiplico por `delta`?** El movimiento dependerá de los FPS: irá más rápido en equipos potentes y más lento en los débiles.

**❓ ¿Conviene conectar señales por editor o por código?** Ambas son válidas. El editor es cómodo para nodos fijos; el código es mejor para instancias creadas en tiempo de ejecución.

**❓ ¿Las señales pueden llevar datos?** Sí. Declara `signal murio(puntos: int)` y emítela con `murio.emit(10)`; el método receptor recibe ese argumento.

## 🔗 Referencias

- Godot Docs — Idle and Physics processing: <https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html>
- Godot Docs — Signals: <https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html>
- Godot Docs — Using signals (scripting): <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html>
- Godot Docs — Timer: <https://docs.godotengine.org/en/stable/classes/class_timer.html>

## ➡️ Siguiente clase

[Clase 029 - Input: teclado, ratón, gamepad y mapeo de acciones](../029-input-teclado-raton-gamepad-y-mapeo-de-acciones/README.md)
