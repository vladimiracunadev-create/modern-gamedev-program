# Clase 053 — WorldEnvironment: cielo, niebla y tonemapping

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Godot Engine 4 — Documentación oficial: Environment and post-processing*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Configurar un nodo **WorldEnvironment** con un recurso **Environment** para dar atmósfera a una escena 3D de Godot 4: un **cielo procedural** que aporta iluminación ambiental, **niebla** para dar profundidad, **glow/bloom** para brillos y **tonemapping** (ACES/Filmic) con exposición para lograr una imagen final equilibrada.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Crear un `WorldEnvironment` con un recurso `Environment` y un `ProceduralSkyMaterial`.
2. Usar el cielo como fuente de **luz ambiental** para iluminar zonas en sombra.
3. Añadir **niebla** para simular profundidad y ambiente.
4. Activar **glow/bloom** y controlar sus umbrales.
5. Comparar modos de **tonemapping** y ajustar la exposición para el look deseado.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Nodo WorldEnvironment | Aplica un Environment global a toda la escena. |
| 2 | ProceduralSkyMaterial | Genera un cielo sin texturas, gratis y editable. |
| 3 | Luz ambiental | Ilumina lo que las luces directas no alcanzan. |
| 4 | Niebla (fog) | Da sensación de distancia y atmósfera. |
| 5 | Glow / Bloom | Simula el desborde de luz en zonas brillantes. |
| 6 | Tonemapping | Mapea el rango HDR a la pantalla (ACES, Filmic). |
| 7 | Exposición | Controla el brillo global antes del tonemap. |
| 8 | Fondo (background) | Define qué se ve donde no hay geometría. |

## 📖 Definiciones y características

- **WorldEnvironment**: nodo que aloja un recurso `Environment` para toda la escena. Clave: solo debe haber uno activo.
- **Environment**: recurso que agrupa cielo, ambiente, niebla, glow y ajustes de imagen. Clave: es reutilizable entre escenas.
- **ProceduralSkyMaterial**: cielo generado por gradiente de horizonte y cénit. Clave: aporta color e iluminación ambiental IBL.
- **Luz ambiental**: iluminación difusa de relleno. Clave: puede provenir del cielo (`ambient_light_source`).
- **Niebla (fog)**: atenúa objetos según su distancia. Clave: se activa con `fog_enabled` y color/densidad.
- **Glow**: desborde luminoso sobre zonas brillantes. Clave: `glow_enabled` más umbral e intensidad.
- **Tonemapping**: conversión del color HDR a rango visible. Clave: modos `TONE_MAPPER_ACES`, `TONE_MAPPER_FILMIC`.
- **Exposición**: multiplicador de brillo previo al tonemap. Clave: ajústala junto a la energía de las luces.

## 🧰 Herramientas y preparación

Necesitas **Godot 4.x** y una escena con un `DirectionalLight3D` (sol) y algunos objetos, para que el cielo y la niebla tengan contexto. Ten a mano una superficie brillante (material con emisión) para apreciar el glow. Consulta la guía de entorno en <https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html> y la API de `Environment` en <https://docs.godotengine.org/en/stable/classes/class_environment.html>. Descarga: <https://godotengine.org/download>.

## 🧪 Laboratorio guiado

1. En tu escena 3D, añade un nodo `WorldEnvironment`. En el inspector, en la propiedad **Environment**, crea un nuevo recurso `Environment`.
2. En el `Environment`, pon **Background → Mode** en *Sky*, crea un `Sky` y asígnale un `ProceduralSkyMaterial`. En **Ambient Light → Source** elige *Sky* para que el cielo ilumine.
3. Añade un script a la raíz para configurar niebla, glow y alternar tonemapping en runtime:

```gdscript
extends Node3D

@onready var world_env: WorldEnvironment = $WorldEnvironment
var _env: Environment

func _ready() -> void:
	_env = world_env.environment

	# Niebla atmosférica.
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.7, 0.8, 0.9)
	_env.fog_density = 0.02

	# Glow / bloom sobre zonas muy brillantes.
	_env.glow_enabled = true
	_env.glow_intensity = 0.8
	_env.glow_bloom = 0.1

	# Tonemapping cinematográfico ACES y exposición.
	_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	_env.tonemap_exposure = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_alternar_tonemap()

func _alternar_tonemap() -> void:
	# Rotar entre ACES, Filmic y Reinhard para comparar.
	match _env.tonemap_mode:
		Environment.TONE_MAPPER_ACES:
			_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		Environment.TONE_MAPPER_FILMIC:
			_env.tonemap_mode = Environment.TONE_MAPPER_REINHARD
		_:
			_env.tonemap_mode = Environment.TONE_MAPPER_ACES

func _process(_delta: float) -> void:
	# Ajustar la exposición con las flechas.
	if Input.is_action_pressed("ui_up"):
		_env.tonemap_exposure = clamp(_env.tonemap_exposure + 0.5 * _delta, 0.1, 3.0)
	if Input.is_action_pressed("ui_down"):
		_env.tonemap_exposure = clamp(_env.tonemap_exposure - 0.5 * _delta, 0.1, 3.0)
```

4. Ejecuta la escena. Verás el cielo procedural de fondo iluminando suavemente los objetos, la niebla difuminando lo lejano y el glow realzando materiales emisivos.
5. Pulsa **Enter** para rotar entre ACES, Filmic y Reinhard: nota cómo ACES da contraste cinematográfico y Reinhard aplana las altas luces.
6. Sube y baja la exposición con las flechas para calibrar el brillo global.

## ✍️ Ejercicios

1. Cambia los colores de horizonte y cénit del `ProceduralSkyMaterial` para crear un atardecer.
2. Aumenta `fog_density` hasta 0.1 y describe el efecto en la lectura de la escena.
3. Añade un material con `emission` fuerte y ajusta `glow_intensity` para verlo brillar.
4. Prueba `ambient_light_source` en modo *Color* en lugar de *Sky* y compara.
5. Fija la exposición baja (0.4) y sube la energía del sol; explica la relación.
6. Crea niebla volumétrica de profundidad ajustando `fog_aerial_perspective`.

## 📝 Reto verificable

Configura un `WorldEnvironment` con cielo procedural que ilumine la escena como única fuente ambiental, niebla suave para dar profundidad y glow activo. Añade un botón por tecla que alterne entre tonemapping ACES y Filmic.

**Criterio de aceptación**: al ejecutar, la escena se ilumina con el cielo, la niebla difumina el fondo, los materiales emisivos brillan y la tecla alterna visiblemente entre los dos tonemappings sin errores.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| No se ve ningún cielo | El `Background Mode` no está en *Sky* o falta el `Sky`; configúralo. |
| La escena se ve lavada o sin contraste | Tonemapping Reinhard o exposición alta; prueba ACES y baja exposición. |
| El glow no aparece | `glow_enabled` desactivado o no hay zonas suficientemente brillantes. |
| Todo demasiado oscuro | Falta luz ambiental; pon `ambient_light_source` en *Sky*. |
| Dos entornos compiten | Hay más de un `WorldEnvironment`; deja solo uno activo. |
| La niebla tapa todo | `fog_density` demasiado alta; redúcela. |

## ❓ Preguntas frecuentes

**❓ ¿Qué tonemapping debería usar?** ACES es un buen punto de partida para un look cinematográfico; Filmic ofrece otra respuesta de altas luces. Prueba ambos con tu iluminación.

**❓ ¿El cielo procedural ilumina de verdad?** Sí, si pones `ambient_light_source` en *Sky* actúa como iluminación basada en imagen (IBL) de bajo coste.

**❓ ¿Puedo tener niebla y glow a la vez?** Sí, son efectos independientes del mismo `Environment` y se combinan sin problema.

**❓ ¿La exposición reemplaza a la energía de las luces?** No; trabajan juntas. La exposición es un ajuste global de imagen; la energía es por luz.

## 🔗 Referencias

- Environment and post-processing: <https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html>
- Environment — API oficial: <https://docs.godotengine.org/en/stable/classes/class_environment.html>
- ProceduralSkyMaterial: <https://docs.godotengine.org/en/stable/classes/class_proceduralskymaterial.html>

## ➡️ Siguiente clase

[Clase 054 - Movimiento 3D: CharacterBody3D y move_and_slide](../054-movimiento-3d-characterbody3d-y-move-and-slide/README.md)
