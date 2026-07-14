# Clase 045 — Capstone Parte 1: un plataformas 2D completo jugable

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4 (Best practices)*
> ⏱️ Duración estimada: **150 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Integrar **todo** lo aprendido en la Parte 1 en un único juego terminado. No hay conceptos nuevos: esta clase es un **capstone**, un proyecto de cierre donde ensamblas las piezas que construiste clase a clase —menú, tilemap, jugador con FSM y game feel, enemigos, monedas y puntuación, vida y daño, HUD, pausa, sonido, música, partículas, guardado y pantallas de victoria/derrota— en un plataformas 2D coherente y jugable de principio a fin, y lo exportas.

Recibirás la **especificación completa**, una **checklist de integración**, los criterios de "terminado" (*definition of done*) y una guía de **pulido y playtesting**. El corazón técnico es un `GameManager` que orquesta el flujo de escenas. Al terminar tendrás un juego que un desconocido puede abrir, entender y jugar sin tu ayuda: el mejor artefacto para tu portfolio.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Ensamblar los sistemas de la Parte 1 en un juego completo y coherente.
2. Orquestar el flujo entre escenas (menú → nivel → victoria/derrota) con un `GameManager`.
3. Aplicar una **checklist** y una *definition of done* para evaluar si el juego está terminado.
4. Conducir una sesión de **playtesting** con otra persona y registrar hallazgos en una lista de bugs.
5. Pulir y **exportar** la versión final del juego lista para compartir.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Especificación del juego | Define el "qué" antes de integrar el "cómo". |
| 2 | GameManager y flujo de escenas | Da un único punto de control del ciclo del juego. |
| 3 | Checklist de features | Asegura que ningún sistema quede a medias. |
| 4 | Definition of Done | Criterio objetivo para declarar el juego terminado. |
| 5 | Integración de sistemas | El reto real: que todo funcione a la vez sin conflictos. |
| 6 | Playtesting con otra persona | Revela problemas que el autor ya no ve. |
| 7 | Lista de bugs y priorización | Convierte el caos en tareas accionables. |
| 8 | Pulido final y export | El último 10% que hace que el juego se sienta acabado. |

## 📖 Definiciones y características

- **Capstone**: proyecto integrador que demuestra el dominio conjunto de todo lo aprendido. Clave: no añade temas, los combina.
- **Especificación**: descripción de qué debe hacer el juego (mecánicas, pantallas, objetivos). Clave: es el contrato contra el que se valida.
- **GameManager**: Autoload que controla el estado global del juego y el cambio de escenas. Clave: centraliza `change_scene_to_file` y evita lógica duplicada.
- **Definition of Done (DoD)**: lista de condiciones que deben cumplirse para considerar algo terminado. Clave: elimina la ambigüedad de "casi listo".
- **Playtesting**: observar a alguien jugar sin ayudarlo para detectar fricciones. Clave: no defiendas el juego, toma notas.
- **Lista de bugs**: registro priorizado de defectos (crítico/mayor/menor). Clave: se ataca primero lo que rompe la experiencia.
- **Pulido (polish)**: ajustes finos de feel, tiempos y feedback que elevan la calidad percibida. Clave: pequeñas mejoras de gran impacto.
- **Flujo de escenas**: recorrido del jugador entre pantallas (menú, niveles, fin). Clave: debe poder recorrerse en bucle sin callejones sin salida.

## 🧰 Herramientas y preparación

Reúne todo tu proyecto `PlataformasCurso` con los sistemas de las clases 026-044: escenas de menú, nivel(es) con **TileMap**, jugador `CharacterBody2D` con máquina de estados, enemigos, monedas, HUD, pausa, audio (Autoloads de música y SFX), partículas y `GameState` de guardado. Necesitas **Godot 4.x** y, para el playtesting, **otra persona** que no haya jugado antes. Ten a mano la guía de buenas prácticas de organización: <https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html> y el cambio de escenas: <https://docs.godotengine.org/en/stable/tutorials/scripting/change_scenes_manually.html>.

## 🧪 Laboratorio guiado

Ensamblaremos el juego completo con un `GameManager` central y validaremos con la checklist.

1. **Especificación mínima del juego.** Tu plataformas debe cumplir: (a) menú principal con Jugar / Continuar / Salir; (b) al menos un nivel con tilemap, plataformas y suelo; (c) jugador que corre, salta y tiene game feel; (d) enemigos que dañan; (e) monedas que suman puntos; (f) vida/daño con derrota al llegar a 0; (g) HUD con vida y puntuación; (h) pausa; (i) sonido, música y partículas; (j) guardado del récord; (k) pantallas de victoria y derrota; (l) build exportado.

2. **Crear el GameManager (Autoload).** Centraliza el flujo en `res://sistema/game_manager.gd` y regístralo como Autoload `GameManager`:

```gdscript
extends Node

# Rutas de las pantallas principales del juego.
const MENU := "res://escenas/menu.tscn"
const VICTORIA := "res://escenas/victoria.tscn"
const DERROTA := "res://escenas/derrota.tscn"

var puntuacion := 0

func iniciar_partida() -> void:
	puntuacion = 0
	GameState.nivel_actual = 1
	cambiar_a("res://escenas/nivel_1.tscn")

func cambiar_a(ruta: String) -> void:
	# Punto único de cambio de escena: fácil de mantener y depurar.
	get_tree().change_scene_to_file(ruta)

func sumar_puntos(valor: int) -> void:
	puntuacion += valor
	GameState.registrar_puntuacion(puntuacion)   # persiste el récord (Clase 043)

func nivel_completado() -> void:
	cambiar_a(VICTORIA)

func jugador_derrotado() -> void:
	cambiar_a(DERROTA)

func volver_al_menu() -> void:
	cambiar_a(MENU)
```

3. **Conectar el flujo desde las pantallas.** El menú llama a `GameManager.iniciar_partida()`; la meta del nivel llama a `GameManager.nivel_completado()`; la muerte del jugador llama a `GameManager.jugador_derrotado()`. Las pantallas de victoria/derrota ofrecen "Reintentar" (`iniciar_partida`) y "Menú" (`volver_al_menu`).

4. **Integrar puntuación y HUD.** Cuando el jugador recoge una moneda, notifica al GameManager y actualiza el HUD:

```gdscript
# En la moneda, al ser recogida (Area2D):
func _on_body_entered(cuerpo: Node2D) -> void:
	if cuerpo.is_in_group("jugador"):
		GameManager.sumar_puntos(10)
		$SonidoMoneda.play()   # SFX posicional (Clase 041)
		queue_free()
```

```gdscript
# En el HUD, escuchando cambios cada frame o por señal:
@onready var etiqueta_puntos: Label = $Puntos
func _process(_delta: float) -> void:
	etiqueta_puntos.text = "Puntos: %d" % GameManager.puntuacion
```

5. **Integrar vida, daño y derrota.** El jugador reutiliza el flash y hit-stop (Clase 042) al recibir daño y notifica al GameManager al morir:

```gdscript
func recibir_dano(cantidad: int) -> void:
	vida -= cantidad
	Sfx.reproducir("dano")
	flash_dano()
	if vida <= 0:
		GameManager.jugador_derrotado()
```

6. **Verificar la pausa.** Confirma que la tecla de pausa muestra el menú de pausa y congela el juego con `get_tree().paused = true`, y que el menú de pausa tiene su **Process Mode** en **Always** para seguir respondiendo mientras el árbol está pausado.

7. **Recorrer la checklist de integración.** Antes de dar por hecho nada, marca cada item:

| Feature | ¿Integrada? | ¿Probada en runtime? |
|---------|-------------|----------------------|
| Menú (Jugar/Continuar/Salir) | ☐ | ☐ |
| Nivel con TileMap y colisiones | ☐ | ☐ |
| Jugador: correr, saltar, game feel | ☐ | ☐ |
| Enemigos que dañan | ☐ | ☐ |
| Monedas y puntuación | ☐ | ☐ |
| Vida/daño y derrota a 0 | ☐ | ☐ |
| HUD (vida + puntos) | ☐ | ☐ |
| Pausa funcional | ☐ | ☐ |
| SFX en salto/moneda/daño | ☐ | ☐ |
| Música continua entre escenas | ☐ | ☐ |
| Partículas (polvo/explosión/flash) | ☐ | ☐ |
| Guardado del récord | ☐ | ☐ |
| Pantalla de victoria | ☐ | ☐ |
| Pantalla de derrota | ☐ | ☐ |
| Build exportado (.exe / web) | ☐ | ☐ |

8. **Definition of Done.** El juego está "terminado" cuando: se puede jugar del menú a la victoria y de vuelta al menú **sin cerrarse ni bloquearse**; ningún sistema lanza errores en el Output durante una partida completa; el récord persiste tras cerrar; y el build exportado corre en un equipo sin Godot. Si algo falla, no está hecho.

9. **Playtesting.** Siéntate junto a otra persona, **no le expliques nada** y obsérvala jugar. Anota dónde se confunde, dónde muere de forma injusta y qué no entiende del HUD. Convierte cada observación en una entrada de la lista de bugs con prioridad (crítico/mayor/menor).

10. **Pulido y export final.** Ataca primero los bugs críticos, ajusta tiempos de salto y daño según el playtest, revisa volúmenes de audio y exporta la versión final siguiendo la Clase 044. Prueba el build una última vez de principio a fin.

## ✍️ Ejercicios

1. Añade un **segundo nivel** y encadénalo: al completar el nivel 1, `GameManager` carga `nivel_2.tscn` en lugar de la victoria directa.
2. Muestra la **puntuación final y el récord** en la pantalla de victoria leyendo `GameManager.puntuacion` y `GameState.puntuacion_maxima`.
3. Implementa un **contador de vidas** global: al perder todas se va a derrota; con vidas restantes, reinicia el nivel.
4. Añade una **transición** (fundido a negro con tween) entre escenas dentro de `cambiar_a()`.
5. Registra un **playtest real** con otra persona y entrega la lista de bugs priorizada resultante.
6. Crea una pantalla de **créditos** accesible desde el menú y desde la victoria.

## 📝 Reto verificable

Entrega el juego completo terminado según la especificación y la *definition of done*: recorrido jugable de menú → nivel(es) → victoria/derrota → menú, con todos los sistemas de la Parte 1 integrados, el récord persistido y un build exportado (Windows o web). Acompáñalo de la checklist marcada y de la lista de bugs del playtest con al menos tres hallazgos y su estado (resuelto/pendiente).

**Criterio de aceptación**: una persona ajena al desarrollo puede abrir el build, entender los controles, completar o perder una partida y volver al menú sin recibir ayuda ni provocar errores; el récord sigue guardado al reabrir el juego; y la checklist de features está completamente marcada.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Al cambiar de escena se pierde la puntuación | Guardaste el score en la escena del nivel. Muévelo al Autoload `GameManager`. |
| El menú de pausa no responde mientras el juego está pausado | Su **Process Mode** no es **Always**. Cámbialo para que ignore la pausa. |
| La música se reinicia al ir a victoria/derrota | El reproductor no está en un Autoload. Revisa la Clase 041. |
| "change_scene_to_file: Cannot change to nonexistent scene" | La ruta del `.tscn` está mal escrita. Verifica exactamente el `res://...`. |
| Errores al recoger monedas tras cargar otra escena | Señales conectadas a nodos ya liberados. Reconecta en `_ready` de cada escena. |
| El build final funciona a medias | No repetiste la checklist sobre el `.exe`. Prueba features en el build, no solo en el editor. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué un GameManager en vez de manejar todo desde cada escena?** Porque centraliza el flujo y el estado global (puntuación, cambio de escena) en un único lugar; sin él, la lógica se duplica y aparecen bugs difíciles de rastrear.

**❓ ¿Cuándo considero el juego "terminado"?** Cuando cumple la Definition of Done: se juega de principio a fin sin bloqueos ni errores, el guardado persiste y el build corre fuera del editor. "Casi listo" no cuenta.

**❓ ¿Por qué no debo explicar nada durante el playtesting?** Porque en la vida real no estarás al lado del jugador. Si necesita tus explicaciones para entenderlo, el juego aún no comunica bien por sí mismo.

**❓ ¿Y si el playtest revela muchos bugs?** Es lo esperado y es bueno: prioriza por gravedad, arregla primero lo crítico (lo que rompe o bloquea) y deja lo menor para el pulido. Una lista de bugs es señal de progreso, no de fracaso.

## 🔗 Referencias

- Godot Docs — Scene organization: <https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html>
- Godot Docs — Change scenes manually: <https://docs.godotengine.org/en/stable/tutorials/scripting/change_scenes_manually.html>
- Godot Docs — Singletons (Autoload): <https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html>
- Godot Docs — Pausing games: <https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html>
- Godot Docs — Exporting projects: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html>

## ➡️ Siguiente paso

¡Felicidades, has terminado la Parte 1 con un juego completo! La **Parte 2 — Desarrollo 3D** (en construcción) dará el salto a las tres dimensiones. Mientras tanto, revisa el [índice del programa](../../README.md) y pule tu juego para el portfolio.
