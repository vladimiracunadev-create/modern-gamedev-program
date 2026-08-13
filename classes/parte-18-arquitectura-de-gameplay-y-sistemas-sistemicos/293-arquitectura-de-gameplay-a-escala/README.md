# Clase 293 — Arquitectura de gameplay a escala

> Parte: **18 — Arquitectura de gameplay y sistemas sistémicos** · Fuente: *Nystrom, «Game Programming Patterns» · Gregory, «Game Engine Architecture» (gameplay foundation systems)*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Aprender a **repartir un juego en capas** para que siga siendo modificable cuando crezca. Hasta ahora tus proyectos han cabido en la cabeza: un script de jugador, uno de enemigo, un HUD. En cuanto aparecen inventario, habilidades, quests y guardado, ese modelo se rompe — no por falta de talento, sino por **acoplamiento**: todo conoce a todo, y cambiar una cosa obliga a tocar cinco.

En esta clase separarás un mini-juego monolítico en cuatro capas —**dominio, gameplay, presentación e infraestructura**— con una regla de dependencias en un solo sentido, comunicación por **señales** y servicios inyectados en vez de singletons globales. Al terminar, el sistema de salud del juego será una clase sin nodos que puedes probar sin abrir una escena, y la barra de vida se enterará de los cambios sin que nadie la llame por su nombre.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Clasificar cualquier archivo de un proyecto en una de las cuatro capas y justificar por qué.
2. Enunciar y aplicar la **regla de dependencia**: las capas interiores no conocen a las exteriores.
3. Convertir una llamada directa entre sistemas en una **señal** (evento) y explicar qué se gana y qué se pierde.
4. Implementar un **contenedor de servicios** que se inyecta en el arranque, en lugar de Autoloads consultados desde cualquier punto.
5. Escribir una prueba de un sistema de dominio **sin instanciar ninguna escena**.
6. Detectar dependencias circulares y romperlas invirtiendo la dirección con una interfaz o un evento.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Las cuatro capas | Da un sitio evidente a cada archivo nuevo y evita el "cajón de sastre". |
| 2 | Regla de dependencia | Es la única regla que impide que la arquitectura se degrade sola. |
| 3 | Dominio sin motor | Lo que no depende de Godot se prueba en milisegundos y sobrevive a un cambio de motor. |
| 4 | Señales y eventos | Desacoplan al emisor del receptor: el sistema de salud no conoce el HUD. |
| 5 | Servicios e inyección | Hace explícitas las dependencias que un singleton esconde. |
| 6 | Data-driven | Mover el balance a datos permite cambiarlo sin recompilar ni redesplegar. |
| 7 | Límites de sistema | Definir qué entra y qué sale evita que un sistema se convierta en otro. |
| 8 | Composición sobre herencia | Un enemigo no "es un" personaje: "tiene" salud, movimiento e IA. |
| 9 | Dependencias circulares | El síntoma más fiable de que un límite está mal puesto. |

## 📖 Definiciones y características

- **Capa de dominio**: código que expresa las reglas del juego (salud, daño, inventario) sin depender del motor ni de la UI. Clave: se prueba sin abrir una escena.
- **Capa de gameplay**: los nodos que conectan el dominio con el mundo del juego (el `CharacterBody2D` que consulta al sistema de movimiento). Clave: traduce entre entidades del motor y datos puros.
- **Capa de presentación**: HUD, menús, efectos y sonido. Clave: solo lee estado y reacciona a eventos; nunca decide reglas.
- **Capa de infraestructura**: guardado, red, archivos, telemetría, reloj. Clave: es lo que cambia al cambiar de plataforma, no las reglas.
- **Regla de dependencia**: convención por la que las capas exteriores conocen a las interiores y nunca al revés. Clave: si el dominio importa el HUD, la arquitectura ya está rota.
- **Acoplamiento**: grado en que un módulo necesita conocer los detalles de otro para funcionar. Clave: se mide contando qué hay que tocar para hacer un cambio.
- **Cohesión**: grado en que todo lo que hay dentro de un módulo trata del mismo asunto. Clave: alta cohesión y bajo acoplamiento es el objetivo, en ese orden.
- **Inversión de dependencias**: técnica por la que el módulo de alto nivel define la interfaz y el de bajo nivel la implementa. Clave: permite que el dominio "use" el guardado sin conocerlo.
- **Inyección de dependencias**: pasar las dependencias de un objeto desde fuera (constructor o `setup()`) en vez de que él las busque. Clave: hace posible sustituirlas en una prueba.
- **Service Locator**: registro central desde el que un objeto pide sus dependencias por nombre o tipo. Clave: más cómodo que la inyección pura y más rastreable que un singleton suelto.
- **Singleton global**: instancia única accesible desde cualquier punto del programa. Clave: cómoda al principio y responsable de la mayoría de dependencias invisibles después.
- **Señal (evento)**: mensaje que un emisor publica sin saber quién lo escucha. Clave: invierte la dirección del conocimiento entre dos sistemas.
- **Event bus**: canal común por el que viajan eventos de todo el juego. Clave: potente y peligroso — sin disciplina se convierte en un `goto` global.
- **Data-driven design**: diseñar el sistema para que su comportamiento venga de datos externos y no de código. Clave: convierte cambios de balance en cambios de archivo.
- **Composición**: construir una entidad agregando piezas independientes en vez de heredar de una jerarquía. Clave: evita la explosión de subclases.
- **Dependencia circular**: A necesita a B y B necesita a A. Clave: casi siempre significa que falta un tercer concepto o sobra una llamada.

## 🧰 Herramientas y preparación

Trabajarás sobre un proyecto Godot 4.x nuevo o sobre cualquiera de tus labs anteriores. No hace falta ningún plugin. Conviene tener a mano la documentación de [señales](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html), de [`RefCounted`](https://docs.godotengine.org/en/stable/classes/class_refcounted.html) —la clase base de los objetos de dominio, que no son nodos y se liberan solos— y de [Autoloads](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html), para saber exactamente de qué nos estamos apartando y por qué.

El laboratorio de esta parte, [`labs/gameplay-systems/`](../../../labs/gameplay-systems/README.md), está montado con esta estructura de carpetas: úsalo como referencia mientras lees.

## 🧪 Laboratorio guiado

Partimos de un script monolítico típico y lo separamos paso a paso.

1. **El punto de partida.** Este es el enemigo que casi todo el mundo escribe la primera vez. Funciona, y por eso es peligroso:

```gdscript
extends CharacterBody2D

var vida := 100
var vida_max := 100

func recibir_golpe(dano: int) -> void:
	vida -= dano
	# El enemigo conoce el HUD, el audio, las partículas y la escena del loot.
	get_node("/root/Mundo/HUD/BarraVida").value = vida
	$SonidoGolpe.play()
	if vida <= 0:
		get_node("/root/Mundo").soltar_loot(global_position)
		queue_free()
```

Nada de eso es "malo" por sí solo; el problema es la **suma**. Este enemigo no se puede probar sin un HUD, no se puede reutilizar en otra escena, y el día que la barra de vida cambie de sitio deja de funcionar en silencio.

2. **Extraer el dominio.** La regla "restar daño, no bajar de cero, avisar cuando muere" no necesita a Godot. Vive en `res://dominio/salud.gd`:

```gdscript
class_name Salud
extends RefCounted

# El dominio no extiende Node: no está en el árbol, no tiene _process y no
# necesita una escena para existir. Eso es justo lo que lo hace testeable.
signal cambio(actual: int, maximo: int)
signal murio

var actual: int
var maximo: int

func _init(maximo_inicial: int) -> void:
	maximo = max(1, maximo_inicial)
	actual = maximo

func recibir(dano: int) -> void:
	if actual <= 0 or dano <= 0:
		return                      # ya está muerto o el golpe no hace nada
	actual = max(0, actual - dano)
	cambio.emit(actual, maximo)
	if actual == 0:
		murio.emit()

func curar(cantidad: int) -> void:
	if actual <= 0 or cantidad <= 0:
		return                      # a un muerto no se le cura: es una regla, y vive aquí
	actual = min(maximo, actual + cantidad)
	cambio.emit(actual, maximo)

func esta_vivo() -> bool:
	return actual > 0
```

3. **La capa de gameplay usa el dominio.** El nodo se queda con lo que solo el motor puede hacer: existir en el mundo, colisionar, desaparecer.

```gdscript
extends CharacterBody2D

signal murio_en(posicion: Vector2)   # hacia fuera: el mundo decide qué hacer

var _salud: Salud

func _ready() -> void:
	_salud = Salud.new(100)
	# El nodo escucha a su propio dominio; el dominio no sabe que hay un nodo.
	_salud.murio.connect(_on_murio)

func recibir_golpe(dano: int) -> void:
	_salud.recibir(dano)

func _on_murio() -> void:
	murio_en.emit(global_position)
	queue_free()

func salud() -> Salud:
	return _salud                    # para que la presentación pueda suscribirse
```

4. **La presentación se suscribe, no pregunta.** La barra de vida no busca al enemigo por ruta: alguien se la da al construir la escena.

```gdscript
extends ProgressBar

func observar(salud: Salud) -> void:
	max_value = salud.maximo
	value = salud.actual
	salud.cambio.connect(_on_cambio)

func _on_cambio(actual: int, maximo: int) -> void:
	max_value = maximo
	value = actual
```

5. **Quién conecta a quién: el ensamblador.** Alguien tiene que unir las piezas, y ese alguien es la escena de nivel — la capa más externa, la única a la que se le permite conocer a todas:

```gdscript
extends Node2D

func _ready() -> void:
	var enemigo := $Enemigo
	$HUD/BarraVida.observar(enemigo.salud())
	enemigo.murio_en.connect(_soltar_loot)
	print("Nivel construido: 1 enemigo, sistemas conectados")

func _soltar_loot(posicion: Vector2) -> void:
	# El mundo decide el loot; el enemigo solo informa de que ha muerto.
	pass
```

6. **Servicios en vez de Autoloads sueltos.** Cuando varios sistemas necesitan lo mismo (reloj, aleatoriedad, guardado), no los conviertas en cinco Autoloads. Regístralos en un contenedor y **pásalo** al arrancar:

```gdscript
class_name Servicios
extends RefCounted

var _mapa := {}

func registrar(clave: StringName, servicio: Object) -> void:
	assert(not _mapa.has(clave), "servicio duplicado: %s" % clave)
	_mapa[clave] = servicio

func obtener(clave: StringName) -> Object:
	# Fallar aquí y con nombre es mucho mejor que un null tres capas más abajo.
	assert(_mapa.has(clave), "servicio no registrado: %s" % clave)
	return _mapa[clave]
```

```gdscript
# res://arranque.gd — el único sitio donde se decide qué implementación se usa.
func _ready() -> void:
	var servicios := Servicios.new()
	servicios.registrar(&"rng", RngDeterminista.new(12345))
	servicios.registrar(&"guardado", GuardadoEnDisco.new())
	$Mundo.setup(servicios)     # inyección: el mundo recibe, no busca
```

La diferencia con un Autoload no es de comodidad, es de **honestidad**: aquí la dependencia está escrita en la firma de `setup()`. Con un Autoload, cualquier archivo puede empezar a depender de `Guardado` sin que se note en ninguna parte, y lo descubres el día que intentas probar algo.

7. **Probar el dominio sin escenas.** Como `Salud` es un `RefCounted`, esto corre en milisegundos:

```gdscript
extends SceneTree   # se ejecuta con: godot --headless --script res://pruebas/salud_test.gd

func _init() -> void:
	var s := Salud.new(30)
	s.recibir(10)
	assert(s.actual == 20, "el daño no se aplicó")
	s.recibir(999)
	assert(s.actual == 0, "la vida no se ha limitado a 0")
	s.curar(50)
	assert(s.actual == 0, "se ha curado a un muerto")
	print("== 3 comprobaciones, 0 fallos ==")
	quit()
```

8. **Detectar dependencias circulares.** Recorre tus `preload`/`class_name` y dibuja las flechas. Si encuentras un ciclo —`Inventario` → `UI` → `Inventario`— hay dos salidas: invertir una flecha con una señal (la UI escucha al inventario) o extraer el concepto que falta. Nunca se arregla añadiendo un tercer acceso global.

## ✍️ Ejercicios

1. Clasifica en las cuatro capas cada script de tu lab de plataformas 2D y anota los que estén en la capa equivocada.
2. Extrae el contador de monedas de ese lab a una clase de dominio `Monedero` con señal `cambio` y conéctale el HUD.
3. Sustituye una búsqueda por ruta (`get_node("/root/...")`) de tus proyectos por una inyección en `setup()`.
4. Añade a `Servicios` un método `intentar_obtener()` que devuelva `null` en vez de fallar, y razona en qué casos conviene cada uno.
5. Escribe una prueba headless que compruebe que `curar()` nunca supera el máximo.
6. Dibuja el grafo de dependencias de tu proyecto más grande y señala el ciclo más corto que encuentres.
7. Convierte una constante de balance (velocidad, daño base) en un dato leído de un `Resource` y comprueba que puedes cambiarla sin tocar código.

## 📝 Reto verificable

Refactoriza un mini-juego monolítico —puedes partir de `labs/gameplay-systems/inicio/` o de tu lab de plataformas— separándolo en las cuatro capas, con **al menos tres sistemas de dominio** (por ejemplo salud, monedero y temporizador de partida) que no extiendan `Node`, comunicación por señales hacia la presentación y un contenedor `Servicios` inyectado desde el arranque.

**Criterio de aceptación**: (a) ningún archivo de `dominio/` contiene la cadena `get_node`, `$` ni `preload` de una escena; (b) existe un script de pruebas headless que instancia los tres sistemas de dominio, ejecuta al menos 8 aserciones y termina imprimiendo `== N comprobaciones, 0 fallos ==`; (c) el juego sigue siendo jugable y arranca imprimiendo `Nivel construido:`; (d) borrar el nodo del HUD de la escena no produce ningún error en el Output — la lógica sigue funcionando sin su presentación.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| "Invalid get index 'BarraVida' on base 'null instance'" al cambiar la escena de sitio | Búsqueda por ruta absoluta desde gameplay. Inyecta la referencia en `setup()` o usa una señal. |
| Cambiar una regla obliga a tocar 6 archivos | La regla está repetida en la presentación y en la lógica. Muévela al dominio y que los demás la consulten. |
| El dominio necesita `get_tree()` para un temporizador | Estás metiendo tiempo del motor en el dominio. Pásale `delta` desde gameplay o inyecta un servicio de reloj. |
| Todo el juego depende de 9 Autoloads | Se han usado singletons como cajón de dependencias. Agrúpalos en un contenedor de servicios inyectado. |
| "Cyclic reference" al usar `class_name` | Dependencia circular real entre dos scripts. Invierte una dirección con una señal o extrae la parte común. |
| La UI reacciona tarde o dos veces | Se conectó la misma señal en dos sitios, o se emite antes de actualizar el estado. Emite **después** de mutar y conecta en un único punto. |
| Las pruebas tardan minutos porque cargan escenas | Estás probando gameplay, no dominio. Extrae la regla a un `RefCounted` y prueba eso. |

## ❓ Preguntas frecuentes

**❓ ¿No es esto sobre-ingeniería para un juego pequeño?** Para un juego de una jam, sí. El umbral práctico es este: en cuanto **dos sistemas distintos** necesiten leer o modificar el mismo estado, sepáralo. Antes de eso, un script monolítico es la decisión correcta.

**❓ ¿Los Autoloads son malos entonces?** No. Un Autoload es una herramienta razonable para *un puñado* de servicios de verdad globales (audio, ajustes, escena actual). Lo que hace daño es usarlos como atajo para que cualquier script hable con cualquier otro, porque las dependencias dejan de verse.

**❓ ¿Señales para todo?** No. Una señal es la respuesta cuando el emisor **no debe conocer** al receptor. Si A tiene que saber que B existe de todas formas —un jugador y su inventario—, una llamada directa es más simple y más fácil de seguir en un depurador.

**❓ ¿Esto es "arquitectura limpia" / hexagonal?** Comparte la idea central (la regla de dependencia) pero sin su ceremonia. En gameplay no hace falta una interfaz por cada colaborador: bastan carpetas con una regla clara y disciplina para respetarla.

**❓ ¿Y el ECS de la Parte 14?** Es una respuesta distinta al mismo problema, orientada al rendimiento (verás su versión avanzada en la [clase 339](../../parte-21-arquitectura-avanzada-de-motores-y-rendering/339-data-oriented-design/README.md)). Las capas organizan **el conocimiento**; el ECS organiza **los datos en memoria**. Se pueden combinar.

## 🔗 Referencias

- Robert Nystrom — *Game Programming Patterns*, Component y Service Locator: <https://gameprogrammingpatterns.com/component.html>
- Robert Nystrom — Decoupling Patterns (Event Queue, Observer): <https://gameprogrammingpatterns.com/observer.html>
- Godot Docs — Señales: <https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html>
- Godot Docs — `RefCounted`: <https://docs.godotengine.org/en/stable/classes/class_refcounted.html>
- Godot Docs — Singletons (Autoload) y sus advertencias: <https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html>
- Jason Gregory — *Game Engine Architecture*, cap. «Runtime Gameplay Foundation Systems»: <https://www.gameenginebook.com/>

## ⬅️ Clase anterior

[Clase 292 - Capstone final: publica tu juego y tu portfolio](../../parte-17-capstones-y-preparacion-profesional-portfolio/292-capstone-final-publica-tu-juego-y-tu-portfolio/README.md)

## ➡️ Siguiente clase

[Clase 294 - Items y base de datos de objetos](../294-items-y-base-de-datos-de-objetos/README.md)
