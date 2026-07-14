# Clase 077 — Ragdolls y física de personajes

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Documentación oficial de Godot 4 (Physical bones / Ragdolls) · Ian Millington, Game Physics Engine Development*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Convertir un personaje animado en un **ragdoll** físico usando `PhysicalBone3D` sobre un `Skeleton3D`. Aprenderás a activar y desactivar la simulación con `physical_bones_start_simulation()`, a mezclar animación esquelética con física y a hacer un *blend* creíble hacia la muerte cuando el personaje recibe el golpe final.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar cómo un `Skeleton3D` con `PhysicalBone3D` sustituye la pose animada por simulación física.
2. Generar y configurar huesos físicos con formas de colisión y juntas apropiadas.
3. Iniciar y detener el ragdoll con `physical_bones_start_simulation()` / `physical_bones_stop_simulation()`.
4. Transicionar de una animación en curso a un ragdoll conservando la velocidad e inercia del momento.
5. Diagnosticar ragdolls que tiemblan, se estiran o atraviesan el suelo.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Skeleton3D y huesos | El esqueleto es la base sobre la que se monta la física |
| 2 | PhysicalBone3D | Cada hueso físico es un cuerpo rígido con junta |
| 3 | Formas de colisión por hueso | Definen el volumen del brazo, pierna, torso |
| 4 | Iniciar/detener simulación | Alternar entre pose animada y ragdoll |
| 5 | Simular solo algunos huesos | Golpe localizado sin soltar todo el cuerpo |
| 6 | Blend animación→física | Evita el "salto" brusco al morir |
| 7 | Capas de colisión del ragdoll | Que los huesos no choquen entre sí de forma absurda |
| 8 | Rendimiento | Muchos ragdolls simultáneos cuestan CPU |

## 📖 Definiciones y características

- **Skeleton3D**: nodo que contiene la jerarquía de huesos que deforma la malla del personaje.
- **PhysicalBone3D**: cuerpo rígido asociado a un hueso; cuando el ragdoll está activo, la física manda sobre la pose del hueso.
- **physical_bones_start_simulation(bones)**: inicia la simulación física; sin argumentos, simula todos los huesos físicos.
- **physical_bones_stop_simulation()**: devuelve el control a la animación (vuelve a la pose animada).
- **Joint del hueso**: cada `PhysicalBone3D` tiene una junta (pin, cono, bisagra) que limita su rango respecto al padre.
- **Blend de animación**: mezcla ponderada entre pose animada y física para una transición suave.
- **Bone attachment**: permite anclar objetos (arma, casco) a un hueso concreto.
- **Modo de simulación parcial**: pasar una lista de huesos a `start_simulation` deja el resto animado.

## 🧰 Herramientas y preparación

Necesitas Godot 4.2+ y un personaje con `Skeleton3D` (los modelos de Mixamo importados en formato glTF funcionan bien). En el inspector del `Skeleton3D`, el menú **"Create physical skeleton"** genera automáticamente un `PhysicalBone3D` por hueso con formas de cápsula y juntas; luego ajustas tamaños y límites. Activa **Debug → Visible Collision Shapes** para ver las cápsulas. Asegúrate de tener un suelo con colisión. Consulta la guía oficial: <https://docs.godotengine.org/en/stable/tutorials/physics/ragdoll_system.html>.

## 🧪 Laboratorio guiado

### Paso 1 — Preparar el esqueleto físico

Tras usar "Create physical skeleton", tu escena tiene `PhysicalBone3D` colgando de cada hueso. Revisa que las cápsulas cubran bien brazos, piernas y torso, y asigna capas de colisión al conjunto para que golpeen el suelo pero no se atasquen entre sí.

### Paso 2 — Activar el ragdoll al morir

```gdscript
extends CharacterBody3D

@onready var esqueleto: Skeleton3D = $Modelo/Skeleton3D
@onready var animador: AnimationPlayer = $AnimationPlayer
var vivo := true

func recibir_golpe(danio: int) -> void:
	if not vivo:
		return
	if danio >= 100:
		morir()

func morir() -> void:
	vivo = false
	animador.stop()                          # dejo de imponer la pose animada
	esqueleto.physical_bones_start_simulation()  # la física toma el control
	# Los huesos caen desde la pose actual: el arranque parece natural.
```

**Observable**: mientras el personaje está vivo se anima normalmente; al recibir 100 de daño, el cuerpo se desploma de forma física desde la última pose.

### Paso 3 — Impulso direccional del golpe

Un ragdoll que solo cae por gravedad es soso. Aplica un impulso al hueso del torso en la dirección del disparo para que el cuerpo salga despedido.

```gdscript
func morir_con_impulso(direccion: Vector3, fuerza: float) -> void:
	vivo = false
	animador.stop()
	esqueleto.physical_bones_start_simulation()

	# Busco el hueso físico del torso y le aplico el impulso del golpe.
	var torso := esqueleto.get_node("Physical Bone Spine") as PhysicalBone3D
	if torso:
		torso.apply_central_impulse(direccion.normalized() * fuerza)
```

**Observable**: al morir, el cuerpo sale despedido en la dirección del golpe con la intensidad de `fuerza`, en vez de derrumbarse en el sitio.

### Paso 4 — Volver a levantarse (opcional)

```gdscript
func revivir() -> void:
	esqueleto.physical_bones_stop_simulation()  # la animación recupera el mando
	animador.play("idle")
	vivo = true
```

**Observable**: al llamar `revivir()`, el personaje deja de ser ragdoll y vuelve a la animación de reposo.

## ✍️ Ejercicios

1. Simula solo el brazo (pasa la lista de huesos del brazo a `start_simulation`) para un golpe que sacude una extremidad sin soltar todo el cuerpo.
2. Aplica el impulso al hueso más cercano al punto de impacto en lugar de siempre al torso.
3. Añade un pequeño *delay* con un `Timer` antes de desaparecer el cadáver tras el ragdoll.
4. Ajusta los límites de las juntas de cuello y rodillas para evitar poses imposibles.
5. Reduce la masa de manos y pies frente al torso y observa el cambio en la caída.
6. Ancla un arma al hueso de la mano con `BoneAttachment3D` y comprueba que cae con el ragdoll.

## 📝 Reto verificable

Implementa un enemigo que camina con animación y, al llegar su vida a cero por un disparo, transiciona a ragdoll con un impulso proporcional al arma usada y en la dirección del proyectil. Tras 4 segundos, el cadáver se desvanece.

**Criterio de aceptación**: la transición de animación a ragdoll no muestra un salto brusco de pose, el cuerpo reacciona con impulso en la dirección correcta del disparo, no atraviesa el suelo y desaparece a los 4 segundos.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El ragdoll tiembla o vibra | Cápsulas de huesos que se solapan y colisionan entre sí. Ajusta capas/máscaras o tamaños. |
| El cuerpo se estira o "explota" | Juntas con límites incoherentes o masas muy dispares. Revisa límites y equilibra masas. |
| Salto brusco al morir | Se inicia el ragdoll desde una pose distinta a la animada. Detén la animación en el mismo *frame*. |
| Los huesos atraviesan el suelo | Máscara de colisión del ragdoll no incluye el suelo. Corrige capas del `PhysicalBone3D`. |
| Vuelve a la pose "T" al morir | La animación sigue imponiendo la pose. Llama `animador.stop()` antes de simular. |

## ❓ Preguntas frecuentes

**¿Necesito crear cada PhysicalBone3D a mano?** No: el botón "Create physical skeleton" del inspector genera todos; solo ajustas formas y límites.

**¿Puedo mezclar animación y física a la vez?** Sí, simulando solo algunos huesos (impacto localizado) mientras el resto sigue la animación.

**¿Por qué mi personaje no cae aunque llamo start_simulation?** Probablemente la animación sigue reproduciéndose y sobrescribe la pose; deténla primero.

**¿Cuántos ragdolls puedo tener?** Depende del hardware; cada uno son ~15 cuerpos con juntas. Limita los activos y "congela" los cadáveres quietos.

## 🔗 Referencias

- Godot Docs — Ragdoll system: <https://docs.godotengine.org/en/stable/tutorials/physics/ragdoll_system.html>
- Godot Docs — PhysicalBone3D: <https://docs.godotengine.org/en/stable/classes/class_physicalbone3d.html>
- Godot Docs — Skeleton3D: <https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html>
- Ian Millington, *Game Physics Engine Development*, capítulos sobre cuerpos rígidos articulados.

## ➡️ Siguiente clase

[Clase 078 - Vehículos: física de ruedas y suspensión](../078-vehiculos-fisica-de-ruedas-y-suspension/README.md)
