# Clase 129 — Audio 3D/posicional y atenuación

> Parte: **6 — Audio y música interactiva** · Fuente: *Documentación de audio de Godot 4 (AudioStreamPlayer3D, Doppler, Reverb Bus)*
> ⏱️ Duración estimada: **55 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Dar **espacio** al sonido: que una fogata suene más fuerte al acercarte, que una máquina a tu izquierda se oiga por el altavoz izquierdo y que un pasillo tenga eco mientras el exterior no. Usaremos `AudioStreamPlayer3D`, su atenuación por distancia (`max_distance`, `attenuation`, `unit_size`), el paneo automático según la posición del `Camera3D`/`Listener`, zonas de reverberación por bus y el efecto **Doppler** para objetos en movimiento.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Colocar fuentes de sonido con `AudioStreamPlayer3D` y explicar cómo se espacializan.
- Configurar la atenuación por distancia con `max_distance`, `unit_size` y curvas.
- Verificar el paneo estéreo automático al moverse alrededor de una fuente.
- Definir una zona con reverberación enrutando el player a un bus con reverb.
- Activar el efecto Doppler para fuentes u observador en movimiento.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | AudioStreamPlayer3D | Reproductor que se posiciona en el espacio 3D |
| 2 | El Listener (cámara) | Define desde dónde se "oye" la escena |
| 3 | Atenuación por distancia | El volumen cae con la lejanía, como en la realidad |
| 4 | `unit_size` y `max_distance` | Escalan cuánto y hasta dónde se oye |
| 5 | Paneo automático | La dirección de la fuente reparte el sonido L/R |
| 6 | Zonas de reverb | Un bus con reverb da "sala" a ciertos lugares |
| 7 | Doppler | El tono cambia con la velocidad relativa |

## 📖 Definiciones y características

- **AudioStreamPlayer3D**: player que emite desde una posición 3D y se atenúa/panea según el oyente. Clave: el stream debe ser **mono**.
- **Listener**: punto de escucha; por defecto la `Camera3D` activa, o un nodo `AudioListener3D`. Clave: sin un oyente correcto, todo suena centrado.
- **max_distance**: distancia a partir de la cual la fuente deja de oírse (0 = sin límite). Clave: evita que sonidos lejanos sumen ruido.
- **unit_size**: distancia a la que el volumen empieza a caer notablemente. Clave: ajusta la "escala" del audio al tamaño del mundo.
- **attenuation_model**: curva de caída (inversa, cuadrática, logarítmica). Clave: define qué tan rápido baja el volumen con la distancia.
- **Paneo**: reparto de la señal entre canales según la dirección. Clave: es automático en 3D; solo requiere un stream mono y un listener.
- **Área de reverb**: bus con `AudioEffectReverb` al que enrutas players dentro de una zona. Clave: se activa/desactiva al entrar y salir.
- **Doppler**: variación de tono por velocidad relativa fuente-oyente. Clave: se activa con `doppler_tracking` y da realismo a coches o proyectiles.

## 🧰 Herramientas y preparación

Necesitas una escena 3D con un suelo, una `Camera3D` (que hará de oyente) y algún modo de moverla (un `CharacterBody3D` sencillo o mover la cámara con teclas). Consigue un sonido **mono** en bucle para la fuente (una fogata, un generador, agua goteando). Importa el WAV/OGG en mono con *Loop* activado. Ten a mano la [referencia de AudioStreamPlayer3D](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html) y la [guía de reverb areas](https://docs.godotengine.org/en/stable/tutorials/audio/index.html). Comprueba que en *Project Settings → Audio* no tengas forzado un canal mono en la salida.

## 🧪 Laboratorio guiado

Colocaremos una fuente 3D con atenuación, comprobaremos el paneo al rodearla y añadiremos una zona con reverb. Resultado audible: el sonido sube al acercarte, se va a un lado al pasar de largo y "resuena" dentro de la zona.

**Paso 1 — Coloca la fuente.** En tu escena 3D, añade un `AudioStreamPlayer3D` llamado `Fogata`. Arrastra el sonido mono a su `Stream`. Sitúala en el mundo (por ejemplo, en `(4, 1, 0)`).

**Paso 2 — Ajusta la atenuación.** En el inspector de `Fogata`:

- `Unit Size`: `3.0` (a partir de ~3 m empieza a bajar de forma clara).
- `Max Distance`: `20.0` (más allá de 20 m no se oye).
- `Attenuation Model`: `Inverse Distance` para una caída natural.

**Paso 3 — Asegura el oyente.** Godot usa la `Camera3D` activa como oyente por defecto. Si quisieras separar oído y vista (oír desde la cabeza del personaje), añadirías un `AudioListener3D` y llamarías a `make_current()`. Por ahora, la cámara basta.

**Paso 4 — Muévete y arranca el sonido.** Adjunta un script al jugador/cámara para iniciar la fogata y moverte:

```gdscript
extends CharacterBody3D

@onready var fogata: AudioStreamPlayer3D = get_node("../Fogata")

const VELOCIDAD := 5.0

func _ready() -> void:
	fogata.play()   # el sonido suena en bucle desde su posición

func _physics_process(delta: float) -> void:
	# Movimiento simple para acercarnos y rodear la fuente.
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity.x = dir.x * VELOCIDAD
	velocity.z = dir.y * VELOCIDAD
	move_and_slide()
```

**Paso 5 — Escucha la atenuación y el paneo.** Corre la escena. Camina hacia la fogata: el volumen sube. Pásate de largo y rodéala: oirás cómo se desplaza al canal izquierdo o derecho según de qué lado quede. Aléjate más de 20 m y desaparece.

**Paso 6 — Añade una zona con reverb.** Crea un bus `Reverb3D` con un `AudioEffectReverb` (sala amplia). Usa un `Area3D` con un `CollisionShape3D` como "cueva"; al entrar, enruta la fogata a ese bus:

```gdscript
func _on_zona_reverb_body_entered(body: Node) -> void:
	if body == self:
		fogata.bus = "Reverb3D"   # dentro de la zona: con eco

func _on_zona_reverb_body_exited(body: Node) -> void:
	if body == self:
		fogata.bus = "Master"     # fuera: seco
```

**Resultado visible:** una fuente sonora que respira con la distancia, se reparte entre altavoces según la dirección y gana reverberación al entrar en una zona marcada.

## ✍️ Ejercicios

1. Cambia `attenuation_model` a `Logarithmic` y describe cómo varía la caída del volumen.
2. Reduce `unit_size` a `1.0` y observa cómo el sonido se vuelve "íntimo" y cae muy rápido.
3. Añade un `AudioListener3D` en la cabeza del personaje y comprueba la diferencia frente a oír desde la cámara.
4. Activa `doppler_tracking` en una fuente montada sobre un objeto que se mueva rápido y escucha el cambio de tono.
5. Prueba a asignar un stream **estéreo** a la fuente 3D y explica por qué el paneo deja de funcionar bien.
6. Crea dos zonas de reverb (cueva y catedral) con tiempos distintos y transita entre ellas.

## 📝 Reto verificable

Monta un pequeño nivel 3D con al menos dos fuentes `AudioStreamPlayer3D` (por ejemplo, una fogata y un generador) con atenuación configurada, y una zona (`Area3D`) que aplique reverberación mediante un bus dedicado a las fuentes que estén dentro. El jugador debe poder moverse para comprobar volumen y paneo.

**Criterio de aceptación**: al acercarse a cada fuente el volumen aumenta y al alejarse se desvanece antes de `max_distance`; al rodearlas el sonido se panea de forma coherente entre izquierda y derecha; y al entrar en la zona las fuentes correspondientes ganan reverberación audible que desaparece al salir.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El sonido no se panea | El stream es estéreo; usa una fuente mono para audio 3D |
| Todo suena igual de fuerte sin importar la distancia | `unit_size` demasiado grande o `max_distance` en un valor enorme; ajústalos a la escala del nivel |
| No se oye nada en 3D | No hay `Camera3D` activa ni `AudioListener3D`; añade un oyente |
| El sonido se corta de golpe al alejarse | `max_distance` muy corto o caída brusca; sube la distancia o cambia la curva |
| La reverb no cambia al entrar en la zona | La señal `body_entered` no está conectada o el filtro de nodo falla; verifica la conexión |
| El Doppler suena exagerado | Objeto demasiado rápido para la escala; reduce velocidad o desactiva `doppler_tracking` |

## ❓ Preguntas frecuentes

**¿La cámara siempre es el oyente?**
Por defecto sí, la `Camera3D` activa. Puedes anularlo con un `AudioListener3D` y `make_current()`, útil en cámaras en tercera persona donde quieres oír desde el personaje.

**¿Por qué mi audio 3D suena mono aunque me mueva?**
Casi siempre porque el archivo importado es estéreo o la salida está forzada a mono. Reimporta el sonido en mono.

**¿`max_distance` en 0 es un error?**
No: `0` significa "sin límite de distancia". Es válido, pero conviene poner un límite para no acumular fuentes lejanas inaudibles que igual consumen voces.

**¿Cómo simulo oclusión (una pared que tapa el sonido)?**
Godot no la trae automática; se aproxima bajando el volumen o aplicando un low-pass cuando un raycast detecta pared entre fuente y oyente.

## 🔗 Referencias

- [AudioStreamPlayer3D — referencia de clase](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html)
- [AudioListener3D — referencia de clase](https://docs.godotengine.org/en/stable/classes/class_audiolistener3d.html)
- [Audio en Godot 4 — documentación oficial](https://docs.godotengine.org/en/stable/tutorials/audio/index.html)
- [AudioEffectReverb — referencia de clase](https://docs.godotengine.org/en/stable/classes/class_audioeffectreverb.html)

## ➡️ Siguiente clase

[Clase 130 - Música adaptativa: capas verticales](../130-musica-adaptativa-capas-verticales/README.md)
