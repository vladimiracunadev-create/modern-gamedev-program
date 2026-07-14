# Clase 133 — Middleware de audio: Wwise

> Parte: **6 — Audio y música interactiva** · Fuente: *Documentación oficial de Audiokinetic Wwise + integración Wwise para Godot 4 (comunidad)*
> ⏱️ Duración estimada: **50 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Conocer **Wwise** (de Audiokinetic), el otro gran middleware de audio de la industria, y su modelo mental propio: una jerarquía de actor-mixer, eventos que actúan como acciones, RTPC para modular en tiempo real, y states/switches para el contexto del juego. Aprenderás a generar soundbanks, integrarlos en Godot 4 con un plugin y disparar un evento con un RTPC que ligue una variable de gameplay al volumen. Al terminar podrás comparar Wwise con FMOD y elegir con criterio.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Describir la jerarquía de actor-mixer de Wwise y su papel en la organización del audio.
- Diferenciar eventos, RTPC, states y switches, y decir para qué sirve cada uno.
- Generar soundbanks en Wwise y explicar qué contienen.
- Integrar Wwise en Godot 4 mediante plugin y disparar un evento desde GDScript.
- Comparar Wwise y FMOD en flujo de trabajo, curva de aprendizaje y casos de uso.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es Wwise y quién lo usa | Estándar en producciones AAA; conviene entender su terminología |
| 2 | Jerarquía actor-mixer | Organiza todos los sonidos y su enrutado de mezcla |
| 3 | Eventos como acciones | En Wwise un evento ejecuta acciones (play, stop, set state...) |
| 4 | RTPC | Ligan valores del juego a propiedades de audio en tiempo real |
| 5 | States y switches | Modelan el contexto global (states) y por objeto (switches) |
| 6 | Soundbanks | Empaquetan estructuras y medios para cargar en runtime |
| 7 | Integración con Godot 4 | El puente vive en un plugin; Godot no trae Wwise nativo |
| 8 | Comparación con FMOD | Ayuda a elegir la herramienta adecuada al proyecto y al equipo |

## 📖 Definiciones y características

- **Wwise (Wave Works Interactive Sound Engine)**: middleware de audio de Audiokinetic para autoría y reproducción interactiva. Clave: potente y granular, con curva de aprendizaje más pronunciada.
- **Actor-Mixer Hierarchy**: árbol donde se agrupan sonidos, contenedores y buses de mezcla. Clave: la organización determina cómo se modula y mezcla todo.
- **Evento**: en Wwise no reproduce directamente un sonido, sino que dispara **acciones** (Play, Stop, Pause, Set Switch...). Clave: el juego llama a `PostEvent`, no a un archivo.
- **RTPC (Real-Time Parameter Control)**: curva que mapea una variable del juego (velocidad, salud) a una propiedad de audio (volumen, LPF). Clave: modulación continua sin código de audio.
- **State**: variable **global** de contexto (por ejemplo `Combate` vs `Exploracion`) que afecta la mezcla. Clave: cambia el ambiente sonoro completo.
- **Switch**: variable **por objeto** que elige una variación (superficie de pisadas: madera, metal). Clave: mismo evento, medio distinto según contexto local.
- **Soundbank**: archivo `.bnk` con las estructuras y, opcionalmente, los medios de audio. Clave: se carga y descarga para gestionar memoria.

## 🧰 Herramientas y preparación

Descarga **Wwise** a través del *Audiokinetic Launcher* desde [audiokinetic.com](https://www.audiokinetic.com/) (cuenta gratuita; licencia gratuita para proyectos por debajo de cierto umbral). Para el puente con el motor necesitas una integración de Wwise para Godot 4 basada en GDExtension, disponible en el ecosistema de la comunidad (busca "Wwise Godot integration"). Consulta la [documentación de Wwise](https://www.audiokinetic.com/library/edge/?source=Help&id=welcome_to_wwise) y su [guía de RTPC](https://www.audiokinetic.com/library/edge/?source=Help&id=working_with_game_parameters). Igual que con FMOD, **Godot 4 no ofrece API nativa de Wwise**: todo el flujo (PostEvent, SetRTPCValue, banks) pasa por el plugin. Verifica que la versión de la integración corresponde a tu build de Wwise y de Godot antes de empezar.

## 🧪 Laboratorio guiado

Crearemos un evento `Play_Wind` cuyo volumen crece con la velocidad del jugador mediante un RTPC `Velocidad`, generaremos el soundbank y lo dispararemos desde Godot. Sin Wwise instalado puedes seguir los pasos conceptuales y escribir el snippet de integración; lo observable es el viento subiendo de volumen al acelerar.

**Paso 1 — Organiza la jerarquía.** En Wwise, en *Audio → Actor-Mixer Hierarchy*, crea un *Sound SFX* llamado `Wind` e importa un loop de viento (WAV). Actívalo como bucle en sus propiedades.

**Paso 2 — Crea el evento.** En *Events*, clic derecho → *New Event → Play*, apúntalo a `Wind` y nómbralo `Play_Wind`. Ese evento ejecutará la acción Play sobre el sonido.

**Paso 3 — Define el RTPC.** En *Game Syncs → Game Parameters*, crea `Velocidad` con rango `0` a `100`. Selecciona el sonido `Wind`, ve a su pestaña *RTPC*, añade una curva que ligue `Velocidad` a *Voice Volume*: en `0` el volumen es -60 dB (silencio), en `100` sube a 0 dB.

**Paso 4 — Genera el soundbank.** En *SoundBanks*, crea un bank `Main`, arrastra el evento `Play_Wind` dentro y pulsa *Generate*. Se producirá `Main.bnk` junto a `Init.bnk` (siempre necesario).

**Paso 5 — Integra en Godot.** Instala la integración de Wwise en `addons/`, reinicia el editor y copia los `.bnk` a `res://audio/wwise/`. En un `Node`:

```gdscript
extends Node

# Los nombres de la API dependen de la integración Wwise-Godot que uses.
# Siguen la convención PostEvent / SetRTPCValue / LoadBank del SDK de Wwise.
var _id_viento: int = 0  # playing ID devuelto por PostEvent

func _ready() -> void:
	# 1) Cargar el bank de inicialización y el principal.
	Wwise.load_bank("Init")
	Wwise.load_bank("Main")

	# 2) Registrar este nodo como game object emisor de audio.
	Wwise.register_game_obj(self, "Jugador")

	# 3) Disparar el evento; guarda el playing ID para poder detenerlo luego.
	_id_viento = Wwise.post_event("Play_Wind", self)

func _process(_delta: float) -> void:
	# 4) Actualizar el RTPC con la velocidad actual del jugador (0..100).
	var velocidad: float = clampf(_velocidad_jugador(), 0.0, 100.0)
	Wwise.set_rtpc_value("Velocidad", velocidad, self)

func _velocidad_jugador() -> float:
	# Sustituir por la velocidad real; aquí una demo con la entrada.
	return Input.get_action_strength("acelerar") * 100.0

func _exit_tree() -> void:
	# 5) Limpiar: detener el evento y desregistrar el game object.
	Wwise.stop_event(_id_viento)
	Wwise.unregister_game_obj(self)
```

**Paso 6 — Ejecuta y escucha.** Al mantener `acelerar`, el RTPC `Velocidad` recorre la curva y el viento pasa de inaudible a pleno volumen. Ese cambio, dirigido por una variable del juego sin tocar el archivo, es la potencia de Wwise.

**Resultado visible:** un loop de viento cuyo volumen sigue la velocidad del jugador en tiempo real vía RTPC.

## ✍️ Ejercicios

1. Añade un state global `Interior`/`Exterior` que baje el volumen del viento en interiores.
2. Crea un switch de superficie para pisadas y dispara la variación correcta según el terreno.
3. Añade un filtro paso-bajo controlado por el mismo RTPC `Velocidad` para simular presión de aire.
4. Descarga `Main.bnk` al salir de la escena y verifica que el evento deja de sonar.
5. Mide el tamaño de `Main.bnk` con y sin medios embebidos; anota la diferencia.
6. Redacta una tabla comparando Wwise y FMOD en jerarquía, RTPC/parámetros y curva de aprendizaje.

## 📝 Reto verificable

Entrega una escena de Godot con la integración Wwise donde un objeto reproduce `Play_Wind` y un control en pantalla ajusta el RTPC `Velocidad` de 0 a 100 en vivo, más un state global que cambia el ambiente. Incluye `Init.bnk`, `Main.bnk` y un README con los nombres de eventos, RTPC y states.

**Criterio de aceptación**: al variar la velocidad el volumen del viento cambia de forma audible y continua, el cambio de state altera perceptiblemente la mezcla, los banks cargan sin errores, y al cerrar la escena el evento se detiene y el game object se desregistra.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| El evento no suena aunque `PostEvent` no falla | No cargaste `Init.bnk`; es obligatorio y va siempre primero |
| El RTPC no cambia nada | No trazaste la curva RTPC en el sonido o el nombre no coincide exacto |
| Error "game object not registered" | Llamas a `PostEvent` sin registrar el game object antes; regístralo en `_ready` |
| El state cambia pero no se oye | El state no está enlazado a ninguna propiedad; añade una State Property o mezcla por state |
| El bank pesa demasiado | Embebiste medios que se repiten en varios banks; usa un bank de medios compartido |

## ❓ Preguntas frecuentes

**¿Wwise reproduce sonidos directamente?**
No: un evento dispara *acciones* (Play, Stop, Set State...). Es más indirecto que FMOD y por eso más flexible en producciones grandes.

**¿Cuál es la diferencia entre state y switch?**
El state es global y cambia el contexto de todo el juego (combate vs calma); el switch es local a un objeto y elige una variación (tipo de suelo bajo un personaje).

**¿Wwise es mejor que FMOD?**
Ni mejor ni peor: Wwise ofrece más granularidad y suele verse en AAA; FMOD tiene una curva más suave y es muy popular en indies. Elige según equipo y proyecto.

**¿Godot habla con Wwise sin plugin?**
No. Como con FMOD, la integración vive en un plugin externo; Godot no incluye Wwise en su núcleo.

## 🔗 Referencias

- [Audiokinetic — sitio oficial y Launcher](https://www.audiokinetic.com/)
- [Wwise — documentación de bienvenida](https://www.audiokinetic.com/library/edge/?source=Help&id=welcome_to_wwise)
- [Wwise — trabajar con Game Parameters (RTPC)](https://www.audiokinetic.com/library/edge/?source=Help&id=working_with_game_parameters)
- [FMOD — para comparar middlewares](https://www.fmod.com/)

## ➡️ Siguiente clase

[Clase 134 - Sincronización con ritmo y eventos](../134-sincronizacion-con-ritmo-y-eventos/README.md)
