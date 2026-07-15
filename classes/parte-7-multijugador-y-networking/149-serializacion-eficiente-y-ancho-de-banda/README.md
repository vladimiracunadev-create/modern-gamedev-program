# Clase 149 — Serialización eficiente y ancho de banda

> Parte: **7 — Multijugador y networking** · Fuente: *Glenn Fiedler, "Gaffer On Games" (Reading and Writing Packets / Serialization Strategies) + documentación de PackedByteArray de Godot 4*
> ⏱️ Duración estimada: **50 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

El ancho de banda cuesta dinero y latencia: cuantos más bytes envías, más se satura la red y peor escala tu servidor. En esta clase reduces el tráfico de un sincronizador aplicando cuatro palancas: **bajar la frecuencia de envío** (tick rate), **cuantizar** floats (posiciones con menos precisión), enviar **solo lo que cambió** (deltas) y lo **relevante** (interés/AOI), y elegir bien **reliable vs unreliable**. Empaquetarás el estado en un `PackedByteArray` y **medirás** los bytes por segundo antes y después.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Estimar el coste en bytes/seg de un sincronizador y por qué crece con jugadores y tick rate.
- Cuantizar posiciones (float → entero) para reducir el tamaño de cada estado.
- Empaquetar estado en un `PackedByteArray` y desempaquetarlo correctamente.
- Enviar solo deltas (cambios) y aplicar un filtro de interés (AOI).
- Elegir reliable vs unreliable y una frecuencia de envío adecuada, y medir la mejora.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Coste del ancho de banda | Escala con jugadores × tick rate × tamaño |
| 2 | Tick rate de envío | Menos envíos = menos tráfico (con más responsabilidad del interp) |
| 3 | Cuantización de floats | Un float de 4 B puede caber en 2 B |
| 4 | Bitpacking | Empaquetar flags y valores en pocos bits |
| 5 | Deltas y dirty flags | No reenviar lo que no cambió |
| 6 | Interés / AOI | No mandar lo que el jugador no puede ver |
| 7 | Reliable vs unreliable | Fiabilidad vs coste; elegir por tipo de dato |

## 📖 Definiciones y características

- **Ancho de banda:** bytes por segundo que circulan; se paga en coste de servidor y en latencia si se satura.
- **Tick rate de envío:** cuántas veces por segundo mandas estado (distinto del tick de simulación). Bajarlo reduce tráfico.
- **Cuantización:** representar un valor continuo con menos bits (p. ej. posición redondeada a enteros de 16 bits) aceptando un pequeño error.
- **Bitpacking:** meter varios valores pequeños o flags en el mismo byte usando operaciones de bits.
- **Delta / dirty flag:** enviar solo las propiedades que cambiaron desde el último envío.
- **Área de interés (AOI):** conjunto de entidades relevantes para un jugador (cercanas/visibles); solo esas se le replican.
- **`PackedByteArray`:** buffer binario de Godot con `encode_*`/`decode_*` y `put_*` para serializar de forma compacta.

## 🧰 Herramientas y preparación

Godot 4.x, dos instancias. En vez de replicar propiedades sueltas con `MultiplayerSynchronizer`, construiremos un paquete binario propio con `PackedByteArray` y lo enviaremos por un RPC no fiable a una frecuencia controlada. Mediremos bytes con un contador propio (sumando `paquete.size()`) y con el *Network Profiler* de Godot (*Debug → Network Profiler*). Repasa [`PackedByteArray`](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html) y sus métodos `encode_u16`/`decode_u16`.

## 🧪 Laboratorio guiado

**1. Punto de partida y medición.** Antes de optimizar, mide. Envía la posición como dos floats a 30 Hz y suma bytes.

```gdscript
var bytes_enviados := 0
var _acum := 0.0

func _process(delta: float) -> void:
    if not multiplayer.is_server():
        return
    _acum += delta
    if _acum >= 1.0:
        print("Bytes/seg: ", bytes_enviados)
        bytes_enviados = 0
        _acum = 0.0
```

**2. Cuantizar la posición.** Un mapa de -10000..10000 px cabe en un entero de 16 bits por eje si aceptamos precisión de ~0.3 px. Pasamos de 8 B (2 floats) a 4 B (2 u16).

```gdscript
const RANGO := 20000.0 # ancho total del mundo en px
const MAX_U16 := 65535.0

func cuantizar(v: float) -> int:
    var t := clampf((v + RANGO * 0.5) / RANGO, 0.0, 1.0)
    return int(round(t * MAX_U16))

func descuantizar(q: int) -> float:
    return (q / MAX_U16) * RANGO - RANGO * 0.5
```

**3. Empaquetar en `PackedByteArray`.** Serializa id (u16) + x (u16) + y (u16) = 6 bytes por entidad, más compacto que un `Dictionary` var-serializado.

```gdscript
func empaquetar_estado(entidades: Array) -> PackedByteArray:
    var buf := PackedByteArray()
    buf.resize(2 + entidades.size() * 6) # 2 B de conteo + 6 B por entidad
    var off := 0
    buf.encode_u16(off, entidades.size()); off += 2
    for e in entidades:
        buf.encode_u16(off, e.id); off += 2
        buf.encode_u16(off, cuantizar(e.pos.x)); off += 2
        buf.encode_u16(off, cuantizar(e.pos.y)); off += 2
    return buf

func desempaquetar_estado(buf: PackedByteArray) -> Array:
    var res: Array = []
    var off := 0
    var n := buf.decode_u16(off); off += 2
    for i in n:
        var id := buf.decode_u16(off); off += 2
        var x := descuantizar(buf.decode_u16(off)); off += 2
        var y := descuantizar(buf.decode_u16(off)); off += 2
        res.append({"id": id, "pos": Vector2(x, y)})
    return res
```

**4. Enviar solo deltas + AOI, a menor frecuencia.** Manda cada entidad únicamente si se movió, y solo las cercanas al destinatario, a 15 Hz en vez de 30.

```gdscript
const AOI_RADIO := 1200.0
const UMBRAL_MOV := 1.0
var ultima_pos: Dictionary = {} # id -> Vector2 ya enviada

func difundir_estado() -> void: # llamar ~15 veces/seg con un Timer
    if not multiplayer.is_server():
        return
    for peer_id in multiplayer.get_peers():
        var receptor := get_node_or_null(str(peer_id))
        if receptor == null:
            continue
        var visibles: Array = []
        for e in get_tree().get_nodes_in_group("jugadores"):
            var eid := e.name.to_int()
            # AOI: solo lo cercano al receptor
            if receptor.position.distance_to(e.position) > AOI_RADIO:
                continue
            # Delta: solo si se movió lo suficiente
            var previa: Vector2 = ultima_pos.get(eid, Vector2(1e9, 1e9))
            if e.position.distance_to(previa) < UMBRAL_MOV:
                continue
            ultima_pos[eid] = e.position
            visibles.append({"id": eid, "pos": e.position})
        if visibles.is_empty():
            continue
        var paquete := empaquetar_estado(visibles)
        bytes_enviados += paquete.size()
        recibir_estado.rpc_id(peer_id, paquete)

@rpc("authority", "call_remote", "unreliable")
func recibir_estado(buf: PackedByteArray) -> void:
    for e in desempaquetar_estado(buf):
        var nodo := get_node_or_null(str(e["id"]))
        if nodo:
            nodo.position = e["pos"] # (idealmente alimenta el interpolador de la clase 146)
```

**5. Mide de nuevo.** Compara el contador `bytes_enviados` antes (floats a 30 Hz, todo a todos) y después (u16, deltas, AOI, 15 Hz). Deberías ver una reducción grande, sobre todo cuando hay jugadores quietos o lejos. Combínalo con la interpolación (clase 146) para que bajar el tick rate no se note en fluidez.

## ✍️ Ejercicios

1. Muestra en pantalla los bytes/seg en vivo y compáralos moviendo pocos vs muchos jugadores.
2. Reduce la cuantización a u8 por eje en un mapa pequeño y observa el error visible.
3. Empaqueta un byte de flags (p. ej. está_disparando, mirando_derecha) con bitpacking.
4. Haz `AOI_RADIO` dependiente del zoom de cámara del receptor.
5. Envía a 10 Hz y sube el retardo de interpolación para compensar; comenta el resultado.
6. Compara el tamaño de tu paquete con `var_to_bytes(dict)` del mismo estado y anota la diferencia.

## 📝 Reto verificable

Reduce el tráfico de un sincronizador de jugadores: baja el tick rate de envío, cuantiza la posición, envía solo deltas y aplica AOI, empaquetando en `PackedByteArray`. Mide bytes/seg antes y después.

**Criterio de aceptación**: el contador de bytes/seg tras optimizar es netamente menor que el de partida (idealmente menos de la mitad con jugadores dispersos); jugadores quietos o fuera del AOI dejan de generar tráfico; el movimiento sigue viéndose fluido gracias a la interpolación.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Posiciones "tembleques" tras cuantizar | Precisión insuficiente; usa u16 o amplía menos el rango |
| Desempaquetado corrupto | Los offsets de encode/decode no coinciden; usa el mismo orden y tamaño de tipos |
| El estado remoto "salta" a 15 Hz | No interpolas; combina con la clase 146 |
| Jugadores lejanos desaparecen mal | AOI sin histéresis; añade margen al entrar/salir del radio |
| No baja el tráfico | Envías todo cada tick sin comparar con `ultima_pos` (no hay deltas reales) |

## ❓ Preguntas frecuentes

**¿Cuánto puedo bajar el tick rate?** Depende del juego: shooters rápidos usan 20-60 Hz; juegos más lentos, 10-15 Hz. Cuanto más bajes, más trabajo hace la interpolación/predicción.

**¿Cuantizar no rompe la física?** No, porque solo cuantizas lo que **envías** para render; la simulación autoritativa sigue con floats completos en el servidor.

**¿Reliable o unreliable para el estado?** Unreliable: el estado se reenvía constantemente, perder un paquete no importa. Reserva reliable para eventos que no se repiten (disparo, recogida, muerte).

**¿AOI merece la pena con pocos jugadores?** Con 2-4 no tanto; su valor crece con decenas o cientos de entidades, donde mandar todo a todos es O(n²) en tráfico.

## 🔗 Referencias

- Gaffer On Games — Serialization Strategies: <https://gafferongames.com/post/serialization_strategies/>
- Gaffer On Games — Reading and Writing Packets: <https://gafferongames.com/post/reading_and_writing_packets/>
- Godot Docs — PackedByteArray: <https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html>
- Godot Docs — High-level multiplayer y Network Profiler: <https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html>

## ⬅️ Clase anterior

[Clase 148 - Servidor autoritativo y anti-cheat básico](../148-servidor-autoritativo-y-anti-cheat-basico/README.md)

## ➡️ Siguiente clase

[Clase 150 - Matchmaking, salas y relay/NAT traversal](../150-matchmaking-salas-y-relay-nat-traversal/README.md)
