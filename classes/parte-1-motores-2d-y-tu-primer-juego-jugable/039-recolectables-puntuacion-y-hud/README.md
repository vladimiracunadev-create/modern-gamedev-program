# Clase 039 — Recolectables, puntuación y HUD

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4*
> ⏱️ Duración estimada: **90 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Cerrar el bucle de juego con **recolectables**, **puntuación** persistente entre escenas y un **HUD** que reaccione por señales. Crearemos monedas como `Area2D` que suman puntos al recogerse, un **Autoload** `GameState` con puntuación y vidas accesible globalmente, y un HUD en `CanvasLayer` que se actualiza sin *polling*.

Al terminar tendrás la infraestructura de estado global que todo juego necesita: un único lugar de verdad para los puntos y las vidas, y una interfaz que se entera de los cambios porque el estado la avisa, no porque pregunte cada frame.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Crear un `Autoload` singleton para estado global de juego.
2. Implementar monedas con `Area2D`, `body_entered` y `queue_free`.
3. Emitir señales desde el estado global al cambiar puntuación o vidas.
4. Construir un HUD en `CanvasLayer` fijo a la pantalla.
5. Actualizar el HUD por señales en lugar de consultarlo cada frame.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Autoload / singleton | Estado accesible desde cualquier escena por nombre. |
| 2 | Recolectable como Area2D | Detecta al jugador sin bloquear su movimiento. |
| 3 | body_entered y grupos | Identifica al jugador de forma robusta. |
| 4 | queue_free tras recoger | Elimina la moneda de forma segura. |
| 5 | Señales del estado global | Notifican cambios a quien los necesite. |
| 6 | CanvasLayer para HUD | Mantiene la UI fija aunque la cámara se mueva. |
| 7 | TextureProgressBar de vida | Muestra la salud de forma visual. |
| 8 | Actualización por señal vs polling | Menos costo y menos bugs de sincronía. |

## 📖 Definiciones y características

- **Autoload**: escena o script cargado al inicio y siempre presente. Clave: se accede por su nombre global desde cualquier lugar.
- **Singleton**: instancia única y compartida de un sistema. Clave: en Godot se implementa con Autoload.
- **Recolectable**: objeto que el jugador toma al tocarlo. Clave: usa `Area2D` para no frenar el movimiento.
- **body_entered**: señal de `Area2D` al entrar un cuerpo físico. Clave: entrega el nodo para comprobar si es el jugador.
- **CanvasLayer**: capa que dibuja su contenido sin seguir la cámara. Clave: ideal para HUD y menús.
- **Control**: nodo base de UI (Label, barras, contenedores). Clave: se posiciona con anclas dentro del CanvasLayer.
- **TextureProgressBar**: barra que rellena según un valor. Clave: perfecta para representar la vida.
- **Señal de estado**: aviso que emite `GameState` al cambiar. Clave: desacopla la lógica de la presentación.

## 🧰 Herramientas y preparación

Continúa con `PlataformasCurso`. Asegúrate de que el `Jugador` está en el grupo `"jugador"` (pestaña **Node > Groups**). Repasa cómo registrar un Autoload en **Project Settings > Autoload** (<https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html>) y la referencia de `CanvasLayer` (<https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html>). Para las barras, consulta `TextureProgressBar` (<https://docs.godotengine.org/en/stable/classes/class_textureprogressbar.html>).

Prepara una textura simple para la moneda (puede ser el `icon.svg` escalado) y otra para el relleno de la barra de vida.

## 🧪 Laboratorio guiado

Montaremos el estado global, la moneda y el HUD por señales.

1. Crea `escenas/game_state.gd` como script de Autoload. Guarda puntuación y vidas y emite señales al cambiar.

```gdscript
extends Node

signal puntuacion_cambiada(nueva: int)
signal vidas_cambiadas(nuevas: int)

var puntuacion: int = 0
var vidas: int = 3

func sumar_puntos(cantidad: int) -> void:
	puntuacion += cantidad
	puntuacion_cambiada.emit(puntuacion)

func perder_vida() -> void:
	vidas = max(vidas - 1, 0)
	vidas_cambiadas.emit(vidas)

func reiniciar() -> void:
	puntuacion = 0
	vidas = 3
	puntuacion_cambiada.emit(puntuacion)
	vidas_cambiadas.emit(vidas)
```

2. Registra el Autoload: **Project Settings > Autoload**, ruta `res://escenas/game_state.gd`, nombre de nodo `GameState`, y activa **Enable**. Ahora `GameState` es accesible por nombre desde cualquier script.

3. Crea la escena `Moneda` con raíz `Area2D`. Añade `Sprite2D`, `CollisionShape2D` y opcionalmente `AnimatedSprite2D` girando. Configura su máscara para detectar la capa del jugador. Añade el script.

```gdscript
extends Area2D

@export var valor: int = 10

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		GameState.sumar_puntos(valor)
		_recoger()

func _recoger() -> void:
	# feedback: pequeño tween de escala antes de desaparecer
	set_deferred("monitoring", false)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.4, 1.4), 0.1)
	t.tween_property(self, "modulate:a", 0.0, 0.1)
	await t.finished
	queue_free()
```

4. Guarda como `escenas/moneda.tscn` y coloca varias en tu nivel. Al pasar el jugador por encima deberían sumar puntos (aún sin verse en pantalla) y desaparecer con el efecto.

5. Crea la escena `HUD` con raíz `CanvasLayer`. Añade un `Control` que ocupe la pantalla, dentro un `Label` llamado `PuntosLabel` (ancla arriba-izquierda) y una `TextureProgressBar` llamada `BarraVida`. Añade el script al `CanvasLayer`.

```gdscript
extends CanvasLayer

@onready var puntos_label: Label = $Control/PuntosLabel
@onready var barra_vida: TextureProgressBar = $Control/BarraVida

func _ready() -> void:
	GameState.puntuacion_cambiada.connect(_on_puntuacion_cambiada)
	GameState.vidas_cambiadas.connect(_on_vidas_cambiadas)
	barra_vida.max_value = GameState.vidas
	_on_puntuacion_cambiada(GameState.puntuacion)
	_on_vidas_cambiadas(GameState.vidas)

func _on_puntuacion_cambiada(nueva: int) -> void:
	puntos_label.text = "Puntos: %d" % nueva

func _on_vidas_cambiadas(nuevas: int) -> void:
	barra_vida.value = nuevas
```

6. Instancia la escena `HUD` como hijo de tu nivel (o de una escena principal que contenga el nivel). Al arrancar debe mostrar `Puntos: 0` y la barra llena. Ejecuta.

7. Conecta la vida real: en el `_on_died` o al recibir daño del `Jugador` (clase 038), llama a `GameState.perder_vida()`. El HUD reflejará el cambio automáticamente por la señal, sin que el jugador conozca al HUD.

```gdscript
func _on_damaged(_cantidad: int, vida_actual: int) -> void:
	if vida_actual == 0:
		GameState.perder_vida()
```

8. Prueba el bucle completo: recoge monedas (sube el contador), recibe daño (baja la barra). Verifica que abrir y volver a entrar a la misma escena mantiene la puntuación, porque `GameState` sobrevive a los cambios de escena.

## ✍️ Ejercicios

1. Añade un contador de monedas independiente de los puntos y muéstralo en el HUD.
2. Reproduce un sonido corto al recoger cada moneda (prepara un `AudioStreamPlayer`).
3. Muestra un mensaje "¡Nivel completo!" cuando la puntuación supere un umbral.
4. Cambia la barra de vida por corazones (varios `TextureRect`) que se oculten al perder vida.
5. Persiste la puntuación máxima en `GameState` y muéstrala junto a la actual.
6. Haz que `reiniciar()` se llame al empezar una partida nueva desde el menú.

## 📝 Reto verificable

Crea un recolectable especial `Gema` que otorgue una vida extra (hasta un máximo) y dispare en el HUD una animación de destello sobre la barra de vida mediante un tween. **Criterio de aceptación**: al recoger la gema `GameState.vidas` aumenta en 1 sin superar el máximo definido, la señal `vidas_cambiadas` actualiza la barra, el HUD reacciona solo por señal (sin leer `GameState` cada frame) y la gema desaparece con feedback visual.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| `Identifier "GameState" not declared` | No registraste el Autoload o el nombre no coincide; revísalo en Project Settings. |
| El HUD se mueve con la cámara | Los nodos de UI no están bajo un `CanvasLayer`; muévelos dentro. |
| La moneda no detecta al jugador | La máscara del `Area2D` no incluye su capa, o el jugador no está en el grupo. |
| La moneda suma puntos dos veces | Sigue monitoreando durante el tween; usa `set_deferred("monitoring", false)`. |
| El HUD no se actualiza | Conectaste la señal después de emitirla; conéctala en `_ready` y sincroniza el valor inicial. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué un Autoload y no una variable en el nivel?** Porque el nivel se destruye al cambiar de escena y perderías la puntuación. El Autoload persiste durante toda la ejecución.

**❓ ¿Señales o preguntar el valor cada frame?** Señales. El *polling* gasta CPU y se desincroniza; con señales el HUD solo se redibuja cuando algo cambia de verdad.

**❓ ¿El HUD debe ser hijo del jugador?** No. Va en su propio `CanvasLayer`, independiente del jugador y de la cámara, para quedar fijo en pantalla.

**❓ ¿Puedo tener varios Autoloads?** Sí, uno por sistema (estado, audio, guardado). Mantén cada uno con una responsabilidad clara para que no se conviertan en un cajón de sastre.

## 🔗 Referencias

- Godot — Singletons (Autoload): <https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html>
- Godot — CanvasLayer: <https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html>
- Godot — TextureProgressBar: <https://docs.godotengine.org/en/stable/classes/class_textureprogressbar.html>
- Godot — Area2D: <https://docs.godotengine.org/en/stable/classes/class_area2d.html>

## ➡️ Siguiente clase

[Clase 040 - Menús, pausa y flujo de escenas](../040-menus-pausa-y-flujo-de-escenas/README.md)
