# Clase 073 — Fricción, arrastre y amortiguación

> Parte: **3 — Física y matemáticas de juegos aplicadas** · Fuente: *Sensación de movimiento en juegos — apuntes de aula y práctica con Godot 4*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Darle **peso y tacto** al movimiento. La fricción, el arrastre (drag) y la amortiguación (damping) son lo que separa un control "resbaladizo sobre hielo" de uno que se siente sólido. Distinguiremos fricción estática y cinética, drag lineal y cuadrático, y aplicaremos amortiguación para frenar suavemente. Lo probaremos en Godot 4 sobre un cuerpo en movimiento y compararemos el "feel".

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diferenciar **fricción estática** de **cinética** y cuándo actúa cada una.
2. Aplicar **drag lineal** y **drag cuadrático** y describir cómo cambian la velocidad terminal.
3. Implementar **amortiguación** exponencial de la velocidad por frame.
4. Usar `move_toward` y multiplicadores de damping para frenar de forma controlada.
5. Ajustar `PhysicsMaterial.friction` y comparar el resultado con la fricción manual.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Fricción estática vs cinética | Define si el objeto arranca o se queda quieto |
| 2 | Drag lineal | Frenado proporcional a la velocidad |
| 3 | Drag cuadrático | Realista a altas velocidades (aire) |
| 4 | Amortiguación (damping) | Suaviza y da peso al control |
| 5 | move_toward para frenar | Frenado lineal predecible |
| 6 | Velocidad terminal | Límite natural de caída/avance |
| 7 | PhysicsMaterial en Godot | Fricción y rebote sin código |

## 📖 Definiciones y características

- **Fricción estática**: fuerza que impide que un objeto en reposo empiece a moverse hasta superar un umbral. Clave: mayor que la cinética.
- **Fricción cinética**: fuerza constante que se opone al movimiento ya iniciado. Clave: no depende de la velocidad, solo de la dirección.
- **Drag lineal**: fuerza de frenado proporcional a la velocidad (`-k*v`). Clave: produce decaimiento exponencial suave.
- **Drag cuadrático**: proporcional al cuadrado de la velocidad (`-k*v*|v|`). Clave: domina a alta velocidad, define la velocidad terminal.
- **Amortiguación (damping)**: multiplicar la velocidad por un factor <1 cada frame. Clave: forma barata y estable de frenar.
- **`move_toward(actual, objetivo, paso)`**: acerca un valor al objetivo un paso fijo. Clave: frenado lineal hasta cero sin pasarse.
- **Velocidad terminal**: velocidad en la que el drag iguala a la fuerza aplicada. Clave: el objeto deja de acelerar.
- **PhysicsMaterial**: recurso con `friction` y `bounce` para cuerpos rígidos. Clave: aplica fricción sin escribir código.

## 🧰 Herramientas y preparación

Usaremos **Godot 4.x** ([godotengine.org](https://godotengine.org)) con un `CharacterBody2D` en una escena 2D. Añade una `CollisionShape2D` y un `Sprite2D` para ver el objeto. Lo observable es cómo cambia el "feel": con drag alto el objeto se detiene rápido; sin él, patina. Consulta [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html) y [PhysicsMaterial](https://docs.godotengine.org/en/stable/classes/class_physicsmaterial.html).

## 🧪 Laboratorio guiado

Aplicaremos drag y fricción manuales a un `CharacterBody2D` y compararemos el tacto.

**Paso 1 — Movimiento con drag lineal.** Adjunta este script al `CharacterBody2D`.

```gdscript
extends CharacterBody2D

@export var aceleracion := 1200.0
@export var drag_lineal := 4.0     # mayor = frena antes
@export var friccion := 300.0      # frenado de piso, en px/s^2

func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Empuje del jugador.
	velocity += dir * aceleracion * delta

	# Drag lineal: frenado proporcional a la velocidad.
	velocity -= velocity * drag_lineal * delta

	# Friccion cinetica: si no hay input, frena a ritmo fijo hacia 0.
	if dir == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, friccion * delta)

	move_and_slide()
```

Ejecuta (F6). Mueve el objeto con las flechas y suéltalas: se detiene con peso, no de golpe. Sube `drag_lineal` a 10 y verás un control mucho más "pesado"; bájalo a 0.5 y patina como sobre hielo.

**Paso 2 — Drag cuadrático y velocidad terminal.** Sustituye la línea de drag para simular resistencia del aire:

```gdscript
	var rapidez := velocity.length()
	if rapidez > 0.0:
		var drag_cuad := 0.002  # coeficiente
		velocity -= velocity.normalized() * drag_cuad * rapidez * rapidez * delta
```

Con drag cuadrático, al mantener una dirección la velocidad crece hasta un tope (velocidad terminal) donde empuje y frenado se igualan. Imprime `velocity.length()` para verlo estabilizarse.

**Paso 3 — Amortiguación exponencial.** Alternativa muy estable e independiente de la magnitud:

```gdscript
	# damping: 0.90 conserva 90% de la velocidad cada frame de fisica.
	var damping := 0.90
	velocity *= damping
```

Compara los tres enfoques cambiando cuál está activo. La amortiguación exponencial nunca "se pasa" ni invierte el signo, por eso es la más segura para controles.

**Paso 4 — Fricción sin código con PhysicsMaterial.** Para un `RigidBody2D`, crea un `PhysicsMaterial` en el inspector, ajusta `friction = 0.8` y `bounce = 0.2`, y asígnalo al cuerpo. El motor aplica la fricción en los contactos automáticamente; compara el asentamiento contra tu versión manual.

## ✍️ Ejercicios

1. Expón `damping` con `@export` y encuentra el valor que "se siente" mejor para un personaje.
2. Implementa un umbral de fricción estática: si la velocidad baja de 5 px/s y no hay input, ponla a cero.
3. Compara el tiempo hasta detenerse con drag lineal vs `move_toward` desde la misma velocidad inicial.
4. Añade gravedad y drag cuadrático a un objeto en caída y mide su velocidad terminal.
5. Crea dos superficies (hielo y barro) cambiando `friccion` por zona con `Area2D`.
6. Sustituye la amortiguación fija por una dependiente de `delta`: `velocity *= pow(damping, delta * 60.0)` y explica por qué es más correcta.

## 📝 Reto verificable

Construye un controlador top-down con dos "materiales de suelo": **normal** y **hielo**. Al entrar en un `Area2D` de hielo, el drag y la fricción bajan drásticamente; al salir, vuelven a los valores normales. El cambio debe ser inmediato y perceptible.

**Criterio de aceptación**: sobre suelo normal, al soltar el control el personaje se detiene en menos de 0.5 s; sobre hielo, sigue deslizándose visiblemente más de 2 s antes de parar, y la transición entre zonas es evidente sin tirones bruscos.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El objeto tiembla alrededor de cero | El frenado "se pasa"; usa `move_toward`, que se detiene exacto en 0 |
| El control patina siempre | Drag/fricción demasiado bajos; súbelos gradualmente |
| El comportamiento cambia con los FPS | Aplicaste damping fijo por frame; usa `pow(damping, delta*60)` o multiplica por `delta` |
| La velocidad se invierte de signo | Restaste más de lo que había; con `move_toward` o damping exponencial no ocurre |
| PhysicsMaterial no hace efecto | Lo asignaste a un `CharacterBody2D`; la fricción de material es para `RigidBody2D` |

## ❓ Preguntas frecuentes

**¿Fricción o drag para el control del jugador?** Para un personaje suele combinarse: `move_toward` (fricción cinética) da un frenado predecible, y un poco de damping suaviza. El drag cuadrático encaja mejor para proyectiles o vehículos.

**¿Por qué mi frenado depende de los FPS?** Multiplicar la velocidad por un factor fijo por frame asume FPS constantes. Ata el factor a `delta` con `pow(damping, delta*60)` para independizarlo.

**¿Cuál es la diferencia práctica entre drag lineal y cuadrático?** El lineal frena parejo siempre; el cuadrático casi no frena a baja velocidad pero mucho a alta, dando una velocidad terminal natural, ideal para caídas.

**¿Cuándo uso PhysicsMaterial?** Cuando trabajas con `RigidBody2D`/`3D` y quieres fricción y rebote realistas en contactos sin programarlos. Para `CharacterBody`, controla el frenado por código.

## 🔗 Referencias

1. Godot Engine — CharacterBody2D: <https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html>
2. Godot Engine — PhysicsMaterial: <https://docs.godotengine.org/en/stable/classes/class_physicsmaterial.html>
3. Godot Engine — `move_toward` (Vector2): <https://docs.godotengine.org/en/stable/classes/class_vector2.html#class-vector2-method-move-toward>

## ⬅️ Clase anterior

[Clase 072 - Respuesta a colisiones: impulsos y restitución](../072-respuesta-a-colisiones-impulsos-y-restitucion/README.md)

## ➡️ Siguiente clase

[Clase 074 - Raycasts y shapecasts: usos avanzados](../074-raycasts-y-shapecasts-usos-avanzados/README.md)
