# Clase 146 — Interpolación y extrapolación de entidades

> Parte: **7 — Multijugador y networking** · Fuente: *Valve, "Source Multiplayer Networking" (entity interpolation) + Gabriel Gambetta, "Entity Interpolation"*
> ⏱️ Duración estimada: **50 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Suavizar el movimiento de las **entidades remotas** (los otros jugadores). En la clase 144 vimos que colocar la posición de golpe produce saltos. La solución estándar es **renderizar en el pasado**: guardar un buffer de snapshots con marca de tiempo y dibujar la entidad en un instante ligeramente atrasado (interpolation delay), interpolando entre los dos snapshots que rodean ese instante. Cuando faltan datos, **extrapolamos** (dead reckoning) con cuidado, y hacemos *snapping* si la divergencia es grande.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar por qué se renderiza "en el pasado" para poder interpolar entidades remotas.
- Mantener un buffer de snapshots con marca de tiempo por entidad.
- Interpolar la posición remota entre dos snapshots con `lerp`.
- Extrapolar (dead reckoning) cuando faltan snapshots recientes.
- Decidir cuándo hacer *snapping* en lugar de interpolar.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Buffer de snapshots | Guarda estados pasados con su tiempo para poder interpolar |
| 2 | Interpolation delay | Un pequeño retardo garantiza tener dos snapshots que rodean el instante |
| 3 | Interpolación con `lerp` | Produce movimiento continuo entre estados discretos |
| 4 | Renderizar en el pasado | Cambia latencia por suavidad en entidades ajenas |
| 5 | Extrapolación / dead reckoning | Estima la posición cuando no llegan datos |
| 6 | Snapping | Corrige de golpe cuando la diferencia es demasiado grande |
| 7 | Local vs remoto | El propio se predice; los ajenos se interpolan |

## 📖 Definiciones y características

- **Snapshot:** captura de estado (posición y tiempo) de una entidad remota, recibida por la red.
- **Buffer de snapshots:** cola ordenada de snapshots recientes de cada entidad.
- **Interpolation delay:** desfase temporal (p. ej. 100 ms) con el que se renderiza para asegurar tener dos snapshots que envuelven el instante objetivo.
- **Interpolación:** mezclar dos snapshots con un factor `t` entre 0 y 1 mediante `lerp` para obtener una posición intermedia.
- **Extrapolación (dead reckoning):** proyectar hacia adelante con la última velocidad conocida cuando no hay snapshot futuro disponible.
- **Snapping:** teletransportar la entidad a su estado real cuando la diferencia supera un umbral (evita interpolar distancias enormes).

## 🧰 Herramientas y preparación

Godot 4.x, dos instancias. Reutiliza el avatar en red. La entidad **local** se mueve con predicción (clase 145); la entidad **remota** se separa: su synchronizer o RPC no coloca `position` directamente, sino que **almacena snapshots** que un interpolador consume. Usaremos `Time.get_ticks_msec()` como reloj. Consulta la nota de Valve sobre *entity interpolation* y la [guía visual de Gambetta](https://www.gabrielgambetta.com/entity-interpolation.html).

## 🧪 Laboratorio guiado

**1. Recibir snapshots en la entidad remota.** En lugar de escribir `position` al recibir estado, guarda `{tiempo, pos}` en un buffer.

```gdscript
extends CharacterBody2D

const RETARDO_INTERP_MS := 100.0 # renderizamos 100 ms en el pasado
var snapshots: Array = []        # cada uno: {t: int (ms), pos: Vector2}

@rpc("authority", "call_remote", "unreliable_ordered")
func recibir_snapshot(pos: Vector2) -> void:
    snapshots.append({"t": Time.get_ticks_msec(), "pos": pos})
    # Mantengo solo ~1 s de historia
    while snapshots.size() > 2 and snapshots[0]["t"] < Time.get_ticks_msec() - 1000:
        snapshots.pop_front()
```

**2. Interpolar en el pasado.** En `_process` (visual), busca los dos snapshots que rodean el instante `ahora - retardo` e interpola entre ellos.

```gdscript
func _process(_delta: float) -> void:
    if is_multiplayer_authority():
        return # el propio se predice, no se interpola
    if snapshots.size() < 2:
        return
    var objetivo := Time.get_ticks_msec() - RETARDO_INTERP_MS

    # Busco el par [a, b] tal que a.t <= objetivo <= b.t
    for i in range(snapshots.size() - 1):
        var a: Dictionary = snapshots[i]
        var b: Dictionary = snapshots[i + 1]
        if a["t"] <= objetivo and objetivo <= b["t"]:
            var span := float(b["t"] - a["t"])
            var t := 0.0 if span == 0.0 else (objetivo - a["t"]) / span
            position = a["pos"].lerp(b["pos"], clampf(t, 0.0, 1.0))
            return

    # No hay snapshot futuro: extrapolamos (paso 3)
    _extrapolar(objetivo)
```

**3. Extrapolar cuando faltan datos.** Con los dos últimos snapshots estimamos velocidad y proyectamos, limitando cuánto extrapolamos.

```gdscript
const MAX_EXTRAP_MS := 150.0

func _extrapolar(objetivo: int) -> void:
    var n := snapshots.size()
    var a: Dictionary = snapshots[n - 2]
    var b: Dictionary = snapshots[n - 1]
    var span := float(b["t"] - a["t"])
    if span <= 0.0:
        position = b["pos"]
        return
    var vel := (b["pos"] - a["pos"]) / span # px por ms
    var dt := clampf(objetivo - b["t"], 0.0, MAX_EXTRAP_MS)
    position = b["pos"] + vel * dt
```

**4. Snapping ante saltos grandes.** Si el snapshot nuevo está muy lejos de donde estamos dibujando (p. ej. tras un teleport real o un lag largo), no interpolamos: colocamos de golpe.

```gdscript
const UMBRAL_SNAP := 400.0

func recibir_snapshot(pos: Vector2) -> void:
    if not snapshots.is_empty() and pos.distance_to(position) > UMBRAL_SNAP:
        snapshots.clear() # descarto historia vieja
        position = pos     # snapping
    snapshots.append({"t": Time.get_ticks_msec(), "pos": pos})
```

**5. Compruébalo.** Con dos instancias, aunque el emisor mande estado a 10-15 envíos por segundo, el avatar remoto se ve **fluido** porque interpolas entre snapshots con 100 ms de retardo. Baja el ritmo de envío y sube el retardo si aún ves saltos; verás el compromiso entre suavidad y "cuánto atrás" ves a los demás.

## ✍️ Ejercicios

1. Haz configurable `RETARDO_INTERP_MS` en runtime y observa el compromiso suavidad/retardo.
2. Dibuja un rastro (`Line2D`) con las posiciones interpoladas para visualizar la trayectoria suavizada.
3. Añade un contador de "snapshots por segundo" recibidos y muéstralo en pantalla.
4. Desactiva la extrapolación y provoca pérdida de paquetes; describe qué ves (la entidad se "congela").
5. Interpola también `rotation` con `lerp_angle`.
6. Ajusta `MAX_EXTRAP_MS` a un valor alto y comenta el "gomeo" (rubber-banding) al reaparecer datos.

## 📝 Reto verificable

Interpola la posición de un jugador remoto entre snapshots con ~100 ms de retardo, con extrapolación limitada ante pérdidas y snapping por umbral. El emisor debe enviar a baja frecuencia (≤15 Hz) y aun así verse suave.

**Criterio de aceptación**: con envío a 10-15 Hz, la entidad remota se ve fluida (sin saltos perceptibles); al inducir pérdida de paquetes la extrapolación evita el congelamiento hasta `MAX_EXTRAP_MS`; un teleport real dispara snapping en vez de un deslizamiento largo.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| La entidad remota sigue a saltos | Escribes `position` directo en vez de bufferizar snapshots e interpolar |
| Movimiento "adelantado" e impreciso | Extrapolas demasiado; baja `MAX_EXTRAP_MS` o prioriza interpolación |
| El propio avatar se ve laggeado | Estás interpolando también el local; el propio se predice, no se interpola |
| Deslizamientos largos tras un teleport | Falta snapping; añade el umbral de distancia |
| Interpolación entrecortada | Interpolas en `_physics_process`; hazlo en `_process` para ir al ritmo de render |

## ❓ Preguntas frecuentes

**¿Interpolación o predicción?** Predicción para tu propio avatar (control inmediato); interpolación para los ajenos (suavidad). Son técnicas complementarias, no rivales.

**¿Cuánto retardo de interpolación uso?** Suele bastar con 2 intervalos de envío (p. ej. si envías a 10 Hz, ~100-200 ms). Más retardo = más suave pero ves a los demás más "en el pasado".

**¿Por qué en `_process` y no en `_physics_process`?** Porque es puramente visual y quieres que vaya al ritmo de los frames dibujados, no al tick de simulación.

**¿La extrapolación no introduce errores?** Sí: adivina el futuro. Por eso se limita en tiempo y se corrige en cuanto llega un snapshot real.

## 🔗 Referencias

- Gabriel Gambetta — Entity Interpolation: <https://www.gabrielgambetta.com/entity-interpolation.html>
- Valve Developer — Source Multiplayer Networking (interpolation): <https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking>
- Gaffer On Games — Snapshot Interpolation: <https://gafferongames.com/post/snapshot_interpolation/>
- Godot Docs — MultiplayerSynchronizer: <https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html>

## ⬅️ Clase anterior

[Clase 145 - Predicción del cliente y reconciliación](../145-prediccion-del-cliente-y-reconciliacion/README.md)

## ➡️ Siguiente clase

[Clase 147 - Lag compensation y rollback netcode](../147-lag-compensation-y-rollback-netcode/README.md)
