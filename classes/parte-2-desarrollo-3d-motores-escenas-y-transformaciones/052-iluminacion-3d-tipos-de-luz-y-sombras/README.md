# Clase 052 — Iluminación 3D: tipos de luz y sombras

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Godot Engine 4 — Documentación oficial: Lights and shadows*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Iluminar una escena 3D en Godot 4 combinando los tres tipos de luz —**DirectionalLight3D**, **OmniLight3D** y **SpotLight3D**— y activar **sombras** de calidad, aprendiendo a ajustar energía, color y el parámetro **bias** para eliminar el *acné de sombra* sin sacrificar el rendimiento.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Distinguir cuándo usar luz direccional, omni o de foco según la fuente que se quiere simular.
2. Controlar `light_energy` y `light_color` para dar carácter a una escena.
3. Activar y configurar sombras con `shadow_enabled` y ajustar su calidad.
4. Corregir el *acné de sombra* y el *peter-panning* modificando el **bias**.
5. Evaluar el coste de rendimiento de cada luz con sombras y priorizar cuáles la usan.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | DirectionalLight3D | Simula el sol; ilumina toda la escena en paralelo. |
| 2 | OmniLight3D | Bombilla que irradia en todas direcciones con alcance. |
| 3 | SpotLight3D | Foco cónico dirigido, como una linterna. |
| 4 | Energía y color | Definen intensidad y temperatura de la luz. |
| 5 | Sombras (shadow_enabled) | Dan profundidad y anclan objetos al suelo. |
| 6 | Bias y acné de sombra | Evitan patrones de moiré en superficies iluminadas. |
| 7 | Rango y atenuación | Controlan hasta dónde alcanza omni/spot. |
| 8 | Coste y rendimiento | Cada sombra dinámica cuesta; hay que dosificarlas. |

## 📖 Definiciones y características

- **DirectionalLight3D**: luz de rayos paralelos sin origen posicional (solo rotación). Clave: su dirección importa, no su posición.
- **OmniLight3D**: emite en todas direcciones desde un punto con `omni_range`. Clave: ideal para bombillas y antorchas.
- **SpotLight3D**: cono de luz con `spot_range` y `spot_angle`. Clave: simula focos y linternas.
- **light_energy**: intensidad de la luz. Clave: valores altos saturan; combínalo con el tonemapping.
- **light_color**: color emitido. Clave: cálido (naranja) o frío (azul) cambia la atmósfera.
- **shadow_enabled**: activa el cálculo de sombras de esa luz. Clave: desactivado por defecto en omni/spot.
- **shadow_bias**: desplaza la profundidad de sombra para evitar auto-sombreado erróneo. Clave: valor típico 0.02–0.1.
- **Acné de sombra**: patrón de rayas oscuras por precisión insuficiente. Clave: se corrige subiendo el bias con cuidado.

## 🧰 Herramientas y preparación

Usa **Godot 4.x** con una escena que tenga suelo y varios objetos con relieve (esferas, cajas, una rampa) para apreciar las sombras. Conviene tener un `WorldEnvironment` con luz ambiental baja para que las sombras sean visibles. Consulta la guía de luces y sombras en <https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html> y la API de `Light3D` en <https://docs.godotengine.org/en/stable/classes/class_light3d.html>. Motor: <https://godotengine.org/download>.

## 🧪 Laboratorio guiado

1. Crea una escena `Node3D` con un suelo (`MeshInstance3D` plano) y coloca 4-5 esferas y cajas encima a distintas alturas.
2. Añade un `DirectionalLight3D` y rótalo con `rotation_degrees = Vector3(-50, -30, 0)` para simular un sol de tarde.
3. Agrega un `OmniLight3D` sobre una caja (por ejemplo `position = Vector3(2, 3, 0)`) y un `SpotLight3D` apuntando hacia el suelo desde arriba.
4. Añade un script a la raíz para configurar las tres luces y demostrar el ajuste de bias:

```gdscript
extends Node3D

@onready var sol: DirectionalLight3D = $DirectionalLight3D
@onready var bombilla: OmniLight3D = $OmniLight3D
@onready var foco: SpotLight3D = $SpotLight3D

func _ready() -> void:
	# Sol cálido con sombras.
	sol.light_color = Color(1.0, 0.95, 0.85)
	sol.light_energy = 1.2
	sol.shadow_enabled = true
	sol.shadow_bias = 0.03

	# Bombilla puntual con alcance limitado.
	bombilla.light_color = Color(1.0, 0.7, 0.4)
	bombilla.light_energy = 3.0
	bombilla.omni_range = 8.0
	bombilla.shadow_enabled = true

	# Foco dirigido.
	foco.light_color = Color(0.8, 0.9, 1.0)
	foco.light_energy = 4.0
	foco.spot_range = 12.0
	foco.spot_angle = 30.0
	foco.shadow_enabled = true

func _process(_delta: float) -> void:
	# Ajustar el bias del sol en vivo para observar el acné de sombra.
	if Input.is_action_pressed("ui_up"):
		sol.shadow_bias = clamp(sol.shadow_bias + 0.05 * _delta, 0.0, 0.5)
	if Input.is_action_pressed("ui_down"):
		sol.shadow_bias = clamp(sol.shadow_bias - 0.05 * _delta, 0.0, 0.5)
	# Rotar el sol para ver cómo se mueven las sombras.
	sol.rotate_y(0.3 * _delta)
```

5. Ejecuta la escena. Observa cómo el sol proyecta sombras largas y en movimiento, la bombilla crea un halo cálido y el foco recorta un círculo frío.
6. Pon `shadow_bias` cercano a 0 con la flecha abajo: aparecerán rayas de *acné* en las superficies. Súbelo con la flecha arriba hasta que desaparezcan sin que las sombras se despeguen del objeto.

## ✍️ Ejercicios

1. Desactiva `shadow_enabled` del foco y compara el coste de render (usa el monitor de FPS del editor).
2. Cambia el `light_color` del sol a un tono azulado y describe la atmósfera resultante.
3. Anima la energía de la bombilla con una onda seno para simular una llama parpadeante.
4. Reduce `omni_range` a 3 y observa cómo se recorta el alcance de la luz.
5. Ajusta `spot_angle` entre 10 y 60 grados y documenta el cambio en el haz.
6. Combina las tres luces para recrear una escena nocturna con una sola bombilla como fuente principal.

## 📝 Reto verificable

Ilumina una habitación cerrada (cuatro paredes y suelo) usando un `OmniLight3D` central con sombras activas, más un `SpotLight3D` como lámpara de escritorio. El `DirectionalLight3D` debe estar apagado (energía 0). Corrige cualquier acné de sombra ajustando el bias.

**Criterio de aceptación**: la escena se ve iluminada solo por las luces puntuales, las sombras se proyectan correctamente sin rayas de acné y no hay errores en consola.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Rayas oscuras sobre superficies iluminadas | Acné de sombra por bias bajo; sube `shadow_bias` gradualmente. |
| La sombra se despega del objeto | *Peter-panning* por bias excesivo; baja `shadow_bias`. |
| Omni/Spot no proyectan sombra | `shadow_enabled` está en `false`; actívalo en cada luz. |
| La escena está totalmente negra | No hay luz ni ambiente; añade una luz o sube la luz ambiental. |
| Caída brusca de FPS | Demasiadas luces con sombras; limita cuáles usan sombra. |
| La bombilla no ilumina de lejos | `omni_range` demasiado corto; auméntalo. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué la luz direccional no tiene posición?** Simula una fuente infinitamente lejana (el sol), así que solo importa su ángulo, no dónde esté el nodo.

**❓ ¿Cuántas luces con sombra puedo usar?** Depende del hardware; en general limita las sombras dinámicas a las luces clave y deja las secundarias sin sombra.

**❓ ¿El bias es lo mismo en todas las luces?** El concepto es igual, pero cada luz tiene su propio `shadow_bias` a ajustar según su geometría.

**❓ ¿Necesito luz ambiental además de estas?** Sí; sin algo de ambiente, las zonas no iluminadas quedan totalmente negras. Se configura en el `WorldEnvironment` (próxima clase).

## 🔗 Referencias

- Lights and shadows: <https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html>
- Light3D — API oficial: <https://docs.godotengine.org/en/stable/classes/class_light3d.html>
- DirectionalLight3D: <https://docs.godotengine.org/en/stable/classes/class_directionallight3d.html>

## ⬅️ Clase anterior

[Clase 051 - Cámaras 3D: perspectiva, FOV y Camera3D](../051-camaras-3d-perspectiva-fov-y-camera3d/README.md)

## ➡️ Siguiente clase

[Clase 053 - WorldEnvironment: cielo, niebla y tonemapping](../053-worldenvironment-cielo-niebla-y-tonemapping/README.md)
