# Clase 013 — Patrones de diseño en juegos: State, Observer, Component y más

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Robert Nystrom, Game Programming Patterns*
> ⏱️ Duración estimada: **115 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Los patrones de diseño son soluciones probadas a problemas que reaparecen una y otra vez al programar juegos. Un personaje que cambia de comportamiento, un sistema de eventos que avisa a varios interesados sin acoplarlos, o entidades que se construyen combinando piezas: cada situación tiene un patrón que la resuelve con claridad.

En esta clase estudiarás los patrones más útiles en videojuegos —**State**, **Observer**, **Component**, **Command**, **Singleton** (con precaución) y **Object Pool**— y los aplicarás en C#. Implementarás una máquina de estados de personaje (Idle/Run/Jump) con el patrón State y un sistema Observer con un evento `OnDeath` y varios suscriptores. Todo ejecutable.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Identificar qué patrón resuelve cada problema recurrente de un juego.
2. Implementar una máquina de estados con el patrón State.
3. Desacoplar sistemas con el patrón Observer (eventos/señales).
4. Explicar la composición del patrón Component frente a la herencia.
5. Reconocer los riesgos del Singleton y alternativas más seguras.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | State | Cambiar comportamiento del personaje sin cadenas de `if`. |
| 2 | Observer | Avisar a varios sistemas sin acoplarlos. |
| 3 | Component | Componer entidades por piezas reutilizables. |
| 4 | Command | Input rebindable y deshacer acciones. |
| 5 | Singleton | Acceso global... con sus peligros. |
| 6 | Object Pool | Reutilizar objetos y evitar picos del GC. |
| 7 | Cuándo NO usar un patrón | Evitar sobreingeniería. |

## 📖 Definiciones y características

- **State**: cada estado es un objeto que define su comportamiento. Clave: elimina condicionales gigantes.
- **Observer**: un sujeto notifica a suscriptores cuando algo ocurre. Clave: desacople total entre emisor y receptores.
- **Component**: una entidad se arma agregando componentes. Clave: composición sobre herencia.
- **Command**: encapsula una acción como objeto. Clave: permite rebindear input y deshacer.
- **Singleton**: garantiza una única instancia global. Clave: cómodo pero acopla y dificulta pruebas.
- **Object Pool**: reutiliza objetos preasignados. Clave: cero asignaciones por frame.
- **Acoplamiento**: cuánto depende un módulo de otro. Clave: menos acoplamiento = más fácil de cambiar.
- **Máquina de estados finita (FSM)**: conjunto de estados y transiciones. Clave: modela comportamiento del personaje.

## 🧰 Herramientas y preparación

Usaremos el .NET SDK 8.0 (<https://dotnet.microsoft.com/download>) con una consola creada mediante `dotnet new console`. Los eventos usan el tipo `event`/`Action` de `System` (ya incluido). Editor recomendado: Visual Studio Code (<https://code.visualstudio.com/>) con la extensión C# Dev Kit. La referencia principal es *Game Programming Patterns* de Robert Nystrom, disponible en línea gratuitamente (<https://gameprogrammingpatterns.com/>). Documentación de eventos en C#: <https://learn.microsoft.com/dotnet/csharp/programming-guide/events/>.

## 🧪 Laboratorio guiado

### Paso 1 — Máquina de estados con el patrón State

Cada estado es una clase con `Entrar` y `Actualizar`. El personaje delega su comportamiento al estado actual. Edita `Program.cs`:

```csharp
interface IEstado
{
    void Entrar(Personaje p);
    IEstado Actualizar(Personaje p, string input);
}

class Idle : IEstado
{
    public void Entrar(Personaje p) => Console.WriteLine($"{p.Nombre} -> Idle");
    public IEstado Actualizar(Personaje p, string input) =>
        input switch
        {
            "correr" => new Run(),
            "saltar" => new Jump(),
            _        => this   // sin cambio de estado
        };
}

class Run : IEstado
{
    public void Entrar(Personaje p) => Console.WriteLine($"{p.Nombre} -> Run");
    public IEstado Actualizar(Personaje p, string input) =>
        input switch { "parar" => new Idle(), "saltar" => new Jump(), _ => this };
}

class Jump : IEstado
{
    public void Entrar(Personaje p) => Console.WriteLine($"{p.Nombre} -> Jump");
    public IEstado Actualizar(Personaje p, string input) =>
        input == "aterrizar" ? new Idle() : this;   // en el aire ignora otros inputs
}
```

### Paso 2 — El personaje que usa la FSM

```csharp
class Personaje
{
    public string Nombre;
    private IEstado _estado;

    public Personaje(string nombre)
    {
        Nombre = nombre;
        _estado = new Idle();
        _estado.Entrar(this);
    }

    public void Procesar(string input)
    {
        IEstado siguiente = _estado.Actualizar(this, input);
        if (siguiente != _estado)   // solo si cambia de estado
        {
            _estado = siguiente;
            _estado.Entrar(this);
        }
    }
}
```

### Paso 3 — Probar la máquina de estados

```csharp
var heroe = new Personaje("Aria");
foreach (var input in new[] { "correr", "saltar", "aterrizar", "parar" })
    heroe.Procesar(input);
```

Ejecuta con `dotnet run`. Verás las transiciones Idle → Run → Jump → Idle impresas: el comportamiento cambió sin una sola cadena de `if` en el personaje.

### Paso 4 — Patrón Observer: evento OnDeath con suscriptores

El sujeto (el enemigo) no conoce a sus observadores; solo dispara el evento. Añade:

```csharp
class Enemigo
{
    public string Nombre;
    public int Vida = 30;

    // El evento: cualquiera puede suscribirse sin que Enemigo lo sepa
    public event Action<Enemigo>? OnDeath;

    public Enemigo(string nombre) => Nombre = nombre;

    public void Danar(int cantidad)
    {
        Vida -= cantidad;
        if (Vida <= 0)
            OnDeath?.Invoke(this);   // notifica a todos los suscriptores
    }
}
```

### Paso 5 — Suscribir varios sistemas al evento

```csharp
var goblin = new Enemigo("Goblin");

// Cada sistema reacciona a la muerte sin conocer a los demas
goblin.OnDeath += e => Console.WriteLine($"[Puntuacion] +100 por {e.Nombre}");
goblin.OnDeath += e => Console.WriteLine($"[Loot] {e.Nombre} suelta una pocion");
goblin.OnDeath += e => Console.WriteLine($"[Audio] reproducir sonido de muerte");

goblin.Danar(10);
goblin.Danar(25);   // aqui la vida llega a <= 0 y se dispara OnDeath una vez
```

Ejecuta de nuevo. Al morir el goblin, los tres sistemas (puntuación, loot y audio) reaccionan sin estar acoplados entre sí ni al enemigo: esa es la fuerza del patrón Observer.

## ✍️ Ejercicios

1. Añade un estado `Crouch` a la FSM con transiciones desde y hacia `Idle`.
2. Impide saltar dos veces seguidas añadiendo lógica dentro de `Jump`.
3. Añade un suscriptor a `OnDeath` que reste 1 al contador de enemigos vivos y lo imprima.
4. Convierte una acción en un `ICommand` con método `Ejecutar()` para rebindear el input de salto.
5. Modela un `Component` simple: una `Entidad` con una lista de componentes que se actualizan en bucle.
6. Explica en comentarios un caso donde un Singleton complicaría las pruebas y cómo lo evitarías.

## 📝 Reto verificable

Combina State y Observer: haz que el `Personaje` dispare un evento `OnCambioEstado` cada vez que cambia de estado, y suscribe dos sistemas (uno que registre un log de estados y otro que cuente cuántas veces el personaje saltó). Procesa una secuencia de al menos 6 inputs y muestra el log y el total de saltos al final.

**Criterio de aceptación**: el programa corre con `dotnet run`, las transiciones de estado se imprimen mediante suscriptores del evento (no dentro del personaje), y al final se muestra correctamente el número de saltos contados por un observador desacoplado.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| `NullReferenceException` al invocar el evento | El evento no tiene suscriptores. Usa `OnDeath?.Invoke(...)` con el operador `?.`. |
| El estado nunca cambia | Comparas o devuelves el mismo objeto. Devuelve una nueva instancia del estado destino. |
| El evento se dispara varias veces | Suscribiste el mismo handler repetido, o disparas dentro de un bucle. Suscribe una sola vez. |
| Cadenas de `if`/`switch` enormes en el personaje | No delegaste al estado. Mueve el comportamiento a cada clase de estado. |
| El Singleton hace difícil probar | Estado global compartido. Inyecta la dependencia en vez de un acceso global. |
| Memoria que no se libera con eventos | No te desuscribiste (`-=`). Quita el handler cuando el objeto muere. |

## ❓ Preguntas frecuentes

**❓ ¿Cuándo uso State en vez de un `enum` con `switch`?** Cuando el comportamiento por estado crece: State reparte el código en clases separadas, evita `switch` gigantes y facilita añadir estados nuevos sin tocar los existentes.

**❓ ¿En qué se diferencia Observer de una llamada directa?** Con Observer, el emisor no conoce a los receptores; publica un evento y cualquiera se suscribe. Eso desacopla los sistemas y permite añadir o quitar reacciones sin tocar el emisor.

**❓ ¿Por qué el Singleton tiene mala fama?** Introduce estado global que acopla módulos, oculta dependencias y complica las pruebas unitarias. Úsalo con criterio y considera inyección de dependencias como alternativa.

**❓ ¿Component es lo mismo que ECS?** No exactamente. Component es el patrón de composición (una entidad con piezas). ECS lleva la idea más lejos separando datos y lógica para rendimiento; lo verás en la clase siguiente.

## 🔗 Referencias

- Robert Nystrom, *Game Programming Patterns*, "State": <https://gameprogrammingpatterns.com/state.html>
- Robert Nystrom, *Game Programming Patterns*, "Observer": <https://gameprogrammingpatterns.com/observer.html>
- Robert Nystrom, *Game Programming Patterns*, "Component": <https://gameprogrammingpatterns.com/component.html>
- Microsoft, "Eventos en C#": <https://learn.microsoft.com/dotnet/csharp/programming-guide/events/>

## ⬅️ Clase anterior

[Clase 012 - GDScript y Python en juegos: scripting rápido](../012-gdscript-y-python-en-juegos-scripting-rapido/README.md)

## ➡️ Siguiente clase

[Clase 014 - Arquitectura ECS (Entity-Component-System)](../014-arquitectura-ecs-entity-component-system/README.md)
