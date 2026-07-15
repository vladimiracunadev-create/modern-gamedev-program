# Clase 145 — Predicción del cliente y reconciliación

> Parte: **7 — Multijugador y networking** · Fuente: *Valve, "Source Multiplayer Networking" + Gabriel Gambetta, "Fast-Paced Multiplayer"*
> ⏱️ Duración estimada: **55 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Eliminar la sensación de "input pegajoso" cuando todo espera al servidor. Vas a hacer que el cliente **prediga** su propio movimiento de inmediato, mientras el servidor sigue siendo la autoridad final. Cuando llega el estado autoritativo, el cliente **reconcilia**: coloca su avatar donde dice el servidor y **reaplica** los inputs que aún no habían sido confirmados. Para ello sellarás cada input con un número de tick y mantendrás un buffer de inputs no confirmados.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar por qué esperar la respuesta del servidor produce input laggeado.
- Implementar predicción local aplicando el input en el mismo tick en que se genera.
- Sellar cada input con un número de tick y guardarlo en un buffer.
- Reconciliar el estado autoritativo reaplicando inputs no confirmados.
- Distinguir la responsabilidad del cliente (predecir) y del servidor (validar).

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Latencia y round-trip | Es lo que hace que el input se sienta lento |
| 2 | Predicción del cliente | El avatar responde ya, sin esperar al servidor |
| 3 | Sellado de input por tick | Permite saber qué inputs confirmó el servidor |
| 4 | Buffer de inputs pendientes | Guarda lo no confirmado para reaplicarlo |
| 5 | Servidor autoritativo | La verdad final la tiene el servidor |
| 6 | Reconciliación (rewind & replay) | Corrige la predicción sin romper el control |
| 7 | Simulación determinista del paso | Predicción y servidor deben mover igual |

## 📖 Definiciones y características

- **Predicción del cliente:** aplicar el efecto del input localmente en el acto, antes de que el servidor confirme.
- **Servidor autoritativo:** el servidor procesa los inputs y produce el estado oficial; el cliente no puede imponer su verdad.
- **Número de tick de input:** entero creciente que identifica cada input; el servidor devuelve el último tick procesado.
- **Buffer de inputs:** lista de inputs enviados y aún no confirmados por el servidor.
- **Reconciliación:** al recibir el estado autoritativo, se coloca el avatar en esa posición y se reaplican todos los inputs con tick posterior al confirmado.
- **Determinismo del paso:** la función que mueve al jugador debe dar el mismo resultado en cliente y servidor para los mismos datos.

## 🧰 Herramientas y preparación

Godot 4.x con dos instancias (*Debug → Run Multiple Instances*). Partimos del avatar de la clase 144. Introducimos una función pura `aplicar_input()` compartida por cliente y servidor para garantizar el mismo movimiento. Para *notar* la mejora conviene simular latencia: en el diálogo *Debug → Network Profiler* o añadiendo un retardo artificial al procesar RPCs. Lee la explicación visual de [Gabriel Gambetta sobre predicción y reconciliación](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html).

## 🧪 Laboratorio guiado

**1. Un paso de movimiento determinista.** Cliente y servidor deben mover igual. Extrae el paso a una función pura.

```gdscript
const VELOCIDAD := 220.0

# Movimiento puro: mismos datos -> mismo resultado en cliente y servidor
static func aplicar_input(pos: Vector2, dir: Vector2, delta: float) -> Vector2:
    return pos + dir * VELOCIDAD * delta
```

**2. El cliente predice y sella el input.** En cada tick físico, el cliente genera un input con número de tick, lo aplica ya (predicción) y lo guarda en el buffer antes de mandarlo al servidor.

```gdscript
extends CharacterBody2D

var tick := 0
var inputs_pendientes: Array = [] # cada elemento: {tick, dir}
var pos_predicha := Vector2.ZERO

func _physics_process(delta: float) -> void:
    if not is_multiplayer_authority():
        return
    tick += 1
    var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var entrada := {"tick": tick, "dir": dir}
    inputs_pendientes.append(entrada)

    # Predicción: muevo YA, sin esperar al servidor
    pos_predicha = aplicar_input(pos_predicha, dir, delta)
    position = pos_predicha

    enviar_input.rpc_id(1, tick, dir) # al servidor (id 1)
```

**3. El servidor procesa y responde el estado autoritativo.** Simula con la misma función y devuelve la posición junto al último tick procesado.

```gdscript
@rpc("any_peer", "call_remote", "unreliable_ordered")
func enviar_input(cli_tick: int, dir: Vector2) -> void:
    if not multiplayer.is_server():
        return
    var delta := 1.0 / Engine.physics_ticks_per_second
    pos_predicha = aplicar_input(pos_predicha, dir, delta)
    var emisor := multiplayer.get_remote_sender_id()
    # Devuelvo estado oficial: posición + último tick que apliqué
    recibir_estado.rpc_id(emisor, pos_predicha, cli_tick)
```

**4. El cliente reconcilia.** Al llegar el estado, descarta los inputs ya confirmados y **reaplica** los que quedan sobre la posición autoritativa.

```gdscript
@rpc("authority", "call_remote", "unreliable_ordered")
func recibir_estado(pos_servidor: Vector2, tick_confirmado: int) -> void:
    # 1) descarto lo que el servidor ya confirmó
    inputs_pendientes = inputs_pendientes.filter(
        func(e): return e["tick"] > tick_confirmado)
    # 2) parto de la verdad del servidor
    var pos := pos_servidor
    var delta := 1.0 / Engine.physics_ticks_per_second
    # 3) reaplico lo aún no confirmado
    for e in inputs_pendientes:
        pos = aplicar_input(pos, e["dir"], delta)
    pos_predicha = pos
    position = pos
```

**5. Compruébalo.** Con dos instancias y algo de latencia simulada, el avatar propio responde al instante (predicción) y, cuando el servidor corrige, no da un tirón visible porque los inputs pendientes se reaplican. Si desactivas la reconciliación (paso 4), verás cómo el avatar se "pelea" con el servidor y retrocede.

## ✍️ Ejercicios

1. Añade latencia artificial (retrasar el `rpc_id` con un `Timer`) y observa la predicción con y sin reconciliación.
2. Registra el error entre `pos_predicha` y `pos_servidor` en cada reconciliación e imprímelo.
3. Limita el tamaño del buffer de inputs y explica qué pasa si se llena (input muy viejo sin confirmar).
4. Cambia la fiabilidad del RPC de input a `reliable` y comenta el efecto en la sensación de control.
5. Haz que el servidor rechace inputs con `dir` de módulo mayor que 1 (primer sanity check).
6. Muestra en pantalla el `tick` local y el `tick_confirmado` para visualizar cuánto va por detrás el servidor.

## 📝 Reto verificable

Implementa predicción + reconciliación para un avatar con latencia simulada de ~120 ms ida/vuelta. El input debe sentirse inmediato y las correcciones del servidor no deben producir tirones visibles.

**Criterio de aceptación**: con la latencia activa, mover el avatar responde en el mismo frame; al desactivar la reconciliación se aprecia un retroceso/tirón claro, y al reactivarla desaparece; el error medio reconciliado tiende a cero cuando el cliente y el servidor no divergen.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El avatar da tirones al corregir | No reaplicas los inputs pendientes tras colocar la posición del servidor |
| Predicción y servidor divergen siempre | La función de paso no es determinista (usan `delta` distinto). Usa un `delta` fijo en ambos |
| El avatar avanza el doble | Predices y además aplicas el estado del servidor sin descartar inputs confirmados |
| Input laggeado pese a predecir | Estás esperando el estado antes de mover; predice en el mismo tick del input |
| Buffer crece sin fin | Nunca filtras por `tick_confirmado`; recorta lo ya confirmado |

## ❓ Preguntas frecuentes

**¿Por qué se siente lento sin predicción?** Porque el avatar no se mueve hasta el round-trip completo (cliente→servidor→cliente). Con 100 ms de RTT notas ese retraso en cada pulsación.

**¿La predicción abre la puerta a trampas?** No, porque el servidor sigue siendo autoritativo: valida los inputs y su estado gana. La predicción es solo cosmética/de sensación.

**¿Qué pasa si el servidor y el cliente divergen mucho?** La reconciliación colocará el avatar en la posición del servidor; si la divergencia es grande, se verá un salto. Por eso importa el determinismo.

**¿Reconcilio en `_process` o `_physics_process`?** La simulación va en `_physics_process` (tick fijo). La reconciliación se dispara al recibir el estado, pero opera sobre el mismo modelo de tick.

## 🔗 Referencias

- Gabriel Gambetta — Client-Side Prediction and Server Reconciliation: <https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html>
- Valve Developer — Source Multiplayer Networking: <https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking>
- Gaffer On Games — Networked Physics: <https://gafferongames.com/post/networked_physics_2004/>
- Godot Docs — High-level multiplayer: <https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html>

## ⬅️ Clase anterior

[Clase 144 - Mover jugadores en red: replicación de estado](../144-mover-jugadores-en-red-replicacion-de-estado/README.md)

## ➡️ Siguiente clase

[Clase 146 - Interpolación y extrapolación de entidades](../146-interpolacion-y-extrapolacion-de-entidades/README.md)
