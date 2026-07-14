# Clase 132 — Middleware de audio: FMOD

> Parte: **6 — Audio y música interactiva** · Fuente: *Documentación oficial de FMOD Studio (Firelight Technologies) + integración fmod-gdextension para Godot 4*
> ⏱️ Duración estimada: **50 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Entender qué es un middleware de audio y por qué gran parte de la industria confía en **FMOD Studio** para el sonido de sus juegos. Aprenderás el vocabulario que sostiene todo el flujo —eventos, parámetros y banks—, cómo un diseñador de sonido construye comportamiento adaptativo sin tocar código, y cómo Godot 4 dispara esos eventos mediante un plugin de integración. Al terminar sabrás cuándo un middleware compensa frente al audio nativo del motor y cuándo es una complejidad que no necesitas.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

- Explicar qué resuelve un middleware de audio y por qué separa el trabajo del diseñador del trabajo del programador.
- Definir con precisión los conceptos de evento, parámetro y bank en FMOD Studio.
- Describir el flujo completo: diseñar en Studio, exportar banks e integrar en Godot mediante plugin.
- Disparar un evento y modificar un parámetro desde GDScript a través de la API de integración.
- Decidir de forma razonada entre FMOD y el `AudioStreamPlayer` nativo según el proyecto.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Qué es un middleware de audio | Traslada el control creativo del sonido al diseñador, no al código |
| 2 | Por qué la industria usa FMOD | Herramienta madura, multiplataforma y con licencia accesible para indies |
| 3 | Eventos | Son la unidad reproducible; encapsulan uno o varios sonidos con lógica |
| 4 | Parámetros | Permiten que un mismo evento suene distinto según el estado del juego |
| 5 | Banks | Empaquetan los datos de audio para cargarlos y descargarlos en runtime |
| 6 | Integración con Godot 4 | Sin plugin no hay puente; Godot no trae FMOD de fábrica |
| 7 | Disparo desde código | El gameplay decide *cuándo* y *cómo* suena cada evento |
| 8 | FMOD vs audio nativo | Elegir la herramienta adecuada evita sobreingeniería |

## 📖 Definiciones y características

- **Middleware de audio**: capa de software especializada entre el motor y el hardware de sonido. Clave: el diseñador itera el audio sin recompilar el juego.
- **FMOD Studio**: aplicación de autoría donde se construyen los eventos con una línea de tiempo y una consola de mezcla. Clave: separa autoría (Studio) de reproducción (runtime API).
- **Evento**: contenedor reproducible que agrupa sonidos, automatizaciones y efectos bajo un nombre o ruta (`event:/SFX/Explosion`). Clave: es lo que el juego dispara, nunca el archivo crudo.
- **Parámetro**: valor de entrada (continuo o discreto) que modula el evento en tiempo real, como `intensidad` o `superficie`. Clave: un solo evento cubre muchas variaciones.
- **Bank**: archivo `.bank` que empaqueta metadatos y muestras de audio. Clave: se carga y descarga para controlar la memoria.
- **Instancia de evento**: una reproducción concreta de un evento; puedes tener varias vivas a la vez. Clave: cada instancia mantiene su propio estado de parámetros.
- **Mixer / buses de FMOD**: enrutado y mezcla propios de FMOD, independientes de los buses de Godot. Clave: la mezcla vive dentro del middleware.

## 🧰 Herramientas y preparación

Necesitas descargar e instalar **FMOD Studio** desde [fmod.com](https://www.fmod.com/) (requiere crear una cuenta gratuita; la licencia indie es gratuita bajo cierto umbral de ingresos). Para el puente con el motor usarás una integración de la comunidad basada en GDExtension, por ejemplo [fmod-gdextension de Utopia-rise](https://github.com/utopia-rise/fmod-gdextension), que expone la API de FMOD como nodos y singletons de Godot 4. Ten a mano la [documentación de FMOD Studio](https://www.fmod.com/docs/2.02/studio/welcome-to-fmod-studio.html) y, como contraste, la [referencia de AudioStreamPlayer de Godot](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html). Importante: **Godot 4 no incluye una API nativa de FMOD**; todo pasa por el plugin, así que primero confirma que la versión de la integración coincide con tu versión de Godot.

## 🧪 Laboratorio guiado

Construiremos un evento de "motor" cuyo tono sube con un parámetro `intensidad`, lo exportaremos como bank y lo dispararemos desde Godot. Si no tienes FMOD instalado, igual puedes leer y escribir el snippet de integración: el resultado observable será el evento reaccionando al parámetro.

**Paso 1 — Crea el proyecto en FMOD Studio.** Abre FMOD Studio y crea un proyecto nuevo. En la pestaña *Events*, clic derecho → *New Event* → *2D Event*. Nómbralo `Engine` dentro de la carpeta `SFX`, de modo que su ruta sea `event:/SFX/Engine`.

**Paso 2 — Añade el sonido.** Arrastra un loop de motor (un WAV corto) a la línea de tiempo del evento, sobre la pista de audio, y actívalo como bucle con una región de loop.

**Paso 3 — Crea el parámetro `intensidad`.** En la pestaña de parámetros del evento, clic en *+* → *New Continuous Parameter*, nómbralo `intensidad`, rango `0` a `1`. Selecciona el módulo de audio, clic derecho sobre su propiedad *Pitch* → *Add Automation* y dibuja una curva: en `intensidad = 0` el pitch es 0 semitonos, en `intensidad = 1` sube a +12. Prueba moviendo el deslizador del parámetro: el motor debe acelerar.

**Paso 4 — Asigna el evento a un bank y exporta.** En la pestaña *Banks*, asegúrate de que el evento pertenece a un bank (por defecto `Master`). Menú *File → Build* para generar los `.bank`. Se crearán, entre otros, `Master.bank` y `Master.strings.bank`.

**Paso 5 — Integra en Godot.** Instala la integración fmod-gdextension en tu proyecto (carpeta `addons/`), reinicia el editor y copia los `.bank` a una carpeta accesible, por ejemplo `res://audio/fmod/`. En un `Node`, carga los banks y dispara el evento:

```gdscript
extends Node

# La API concreta depende del plugin fmod-gdextension.
# Estos nombres siguen su convención de singletons FmodServer / FmodManager.
var _instancia_motor  # instancia de evento viva

func _ready() -> void:
	# 1) Cargar los banks generados en FMOD Studio.
	FmodServer.load_bank("res://audio/fmod/Master.strings.bank", FmodServer.FMOD_STUDIO_LOAD_BANK_NORMAL)
	FmodServer.load_bank("res://audio/fmod/Master.bank", FmodServer.FMOD_STUDIO_LOAD_BANK_NORMAL)

	# 2) Crear una instancia del evento por su ruta y arrancarla.
	_instancia_motor = FmodServer.create_event_instance("event:/SFX/Engine")
	_instancia_motor.start()

func _process(delta: float) -> void:
	# 3) Modular el parámetro segun la aceleración del jugador (0..1).
	var intensidad: float = clampf(Input.get_action_strength("acelerar"), 0.0, 1.0)
	_instancia_motor.set_parameter_by_name("intensidad", intensidad, false)

func _exit_tree() -> void:
	# 4) Liberar la instancia para no filtrar memoria.
	if _instancia_motor:
		_instancia_motor.stop(FmodServer.FMOD_STUDIO_STOP_ALLOWFADEOUT)
		_instancia_motor.release()
```

**Paso 6 — Ejecuta y escucha.** Al mantener la acción `acelerar`, el pitch del motor sube en tiempo real porque el parámetro `intensidad` recorre la curva que dibujaste en Studio. Ese cambio audible, dirigido por un valor de gameplay, es la esencia del middleware.

**Resultado visible:** un evento único que suena distinto según un parámetro del juego, sin haber tocado archivos de audio en el código.

## ✍️ Ejercicios

1. Añade un segundo parámetro discreto `superficie` (asfalto/tierra) que cambie el volumen del motor.
2. Crea un evento `event:/SFX/Horn` y dispáralo con una tecla, como *one-shot* que no necesita release manual.
3. Separa los SFX en un bank aparte de la música y carga solo el que necesitas en cada escena.
4. Envuelve la carga de banks en una comprobación que registre un error si un bank no existe.
5. Mide en el perfilador la RAM antes y después de cargar el bank; anota la diferencia.
6. Escribe una tabla comparando tres tareas resueltas con FMOD frente a resolverlas con `AudioStreamPlayer` nativo.

## 📝 Reto verificable

Entrega una mini-escena de Godot con la integración FMOD donde un objeto reproduce el evento `event:/SFX/Engine` y un `HSlider` en pantalla controla el parámetro `intensidad` en vivo. Incluye los `.bank` exportados y un README breve con las rutas de los eventos usados.

**Criterio de aceptación**: al mover el slider de 0 a 1 el sonido cambia de forma audible y continua, los banks cargan sin errores en consola, y al cerrar la escena la instancia se libera (sin fugas reportadas por el plugin).

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| "Event not found" al crear la instancia | No cargaste `Master.strings.bank`; ese bank contiene las rutas por nombre, cárgalo siempre primero |
| El parámetro no afecta al sonido | Olvidaste dibujar la automatización en Studio o el nombre del parámetro no coincide exacto |
| Silencio total pese a cargar banks | El evento quedó fuera de todo bank al construir; verifica su asignación y reconstruye |
| La memoria crece sin parar | Creas instancias en cada frame sin liberarlas; reutiliza una instancia o llama `release()` |
| El plugin no aparece tras instalarlo | Versión de la integración incompatible con tu Godot; alinea versiones y reinicia el editor |

## ❓ Preguntas frecuentes

**¿Godot 4 trae FMOD de serie?**
No. FMOD se integra mediante un plugin externo (GDExtension). El motor por sí solo no conoce eventos ni banks.

**¿Necesito FMOD para hacer buen audio en un juego?**
No siempre. Para proyectos pequeños el audio nativo basta. FMOD brilla cuando el diseño sonoro es complejo y quieres que el diseñador itere sin programar.

**¿Cuál es la diferencia entre un evento y un archivo WAV?**
El WAV es la muestra cruda; el evento la envuelve con lógica, parámetros, efectos y variaciones. El juego dispara eventos, no archivos.

**¿FMOD es gratis?**
Tiene una licencia indie gratuita bajo un umbral de ingresos por título. Consulta los términos vigentes en fmod.com antes de publicar comercialmente.

## 🔗 Referencias

- [FMOD — sitio oficial y descargas](https://www.fmod.com/)
- [FMOD Studio — documentación 2.02](https://www.fmod.com/docs/2.02/studio/welcome-to-fmod-studio.html)
- [fmod-gdextension (integración Godot 4)](https://github.com/utopia-rise/fmod-gdextension)
- [AudioStreamPlayer — Godot Docs](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html)

## ➡️ Siguiente clase

[Clase 133 - Middleware de audio: Wwise](../133-middleware-de-audio-wwise/README.md)
