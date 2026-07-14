# Clase 009 — POO para juegos: clases, herencia y composición

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Robert Nystrom, Game Programming Patterns*
> ⏱️ Duración estimada: **110 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

La programación orientada a objetos organiza el código en entidades con estado y comportamiento, algo natural para modelar jugadores, enemigos y objetos. Pero la herencia clásica —un árbol rígido `Entity → Player/Enemy`— se vuelve frágil rápidamente cuando el juego crece y aparecen combinaciones inesperadas.

En esta clase modelarás entidades primero con herencia para sentir el problema en carne propia, y luego refactorizarás a **composición con componentes**, el enfoque que usan los motores modernos (Unity, Godot, Unreal). Verás por qué "composición sobre herencia" es más que un eslogan.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Definir clases con encapsulación y crear objetos a partir de ellas.
2. Implementar herencia y polimorfismo entre entidades de juego.
3. Explicar con un ejemplo concreto la fragilidad del árbol de herencia rígido.
4. Refactorizar entidades a un modelo de composición con componentes.
5. Justificar por qué los motores modernos favorecen componentes sobre jerarquías profundas.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Clases y objetos | La unidad básica para modelar entidades. |
| 2 | Encapsulación | Proteger el estado interno evita bugs difusos. |
| 3 | Herencia | Reutiliza comportamiento común entre entidades. |
| 4 | Fragilidad del árbol rígido | Combinaciones nuevas rompen la jerarquía. |
| 5 | Composición | Ensamblar entidades a partir de piezas. |
| 6 | Componentes | El patrón que usan Unity, Godot y Unreal. |
| 7 | Interfaces y polimorfismo | Tratar objetos distintos de forma uniforme. |

## 📖 Definiciones y características

- **Clase**: plantilla que define estado y comportamiento. Clave: se instancia en objetos.
- **Encapsulación**: ocultar el estado interno tras métodos y propiedades. Clave: `private` protege invariantes.
- **Herencia**: una clase hija hereda de una base. Clave: reutiliza, pero acopla fuertemente.
- **Polimorfismo**: llamar el mismo método en tipos distintos. Clave: `override` cambia el comportamiento.
- **Árbol frágil**: jerarquía que no admite combinaciones nuevas sin duplicar código. Clave: el "problema del diamante" de features.
- **Composición**: construir una entidad a partir de componentes independientes. Clave: "tiene un" en vez de "es un".
- **Componente**: pieza reutilizable de comportamiento (salud, movimiento). Clave: se añade o quita en runtime.
- **Interfaz**: contrato de métodos sin implementación. Clave: permite polimorfismo sin herencia.

## 🧰 Herramientas y preparación

Seguimos con el .NET SDK 8.0 (<https://dotnet.microsoft.com/download>) y una app de consola creada con `dotnet new console`. Editor recomendado: Visual Studio Code <https://code.visualstudio.com/> con la extensión C#. La referencia conceptual es *Game Programming Patterns* de Robert Nystrom, disponible online gratis en <https://gameprogrammingpatterns.com/component.html>. Documentación de POO en C#: <https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/>.

## 🧪 Laboratorio guiado

### Paso 1 — Enfoque con herencia

Crea el proyecto y edita `Program.cs`. Empezamos modelando con una jerarquía clásica:

```csharp
abstract class Entity
{
    public string Nombre;
    public int Vida = 100;
    public virtual void Actuar() => Console.WriteLine($"{Nombre} existe.");
}

class Player : Entity
{
    public override void Actuar() => Console.WriteLine($"{Nombre} recibe input del jugador.");
}

class Enemy : Entity
{
    public override void Actuar() => Console.WriteLine($"{Nombre} persigue al jugador (IA).");
}
```

### Paso 2 — Sentir la fragilidad

Ahora el diseñador pide un "enemigo controlable" (poseído por el jugador) y un "aliado con IA que también recibe input a veces". ¿De quién heredan? No encajan en `Player` ni en `Enemy` sin duplicar código:

```csharp
// Problema: ni Player ni Enemy sirven. Tendrias que crear
// class EnemigoControlable : Enemy  -> pero necesita el input de Player
// class AliadoIA : Player           -> pero necesita la IA de Enemy
// El arbol rigido obliga a COPIAR comportamiento entre ramas.
```

Este es el síntoma: cada combinación nueva pelea contra la jerarquía. La herencia responde bien a "es un", pero el gameplay real es "tiene estas capacidades".

### Paso 3 — Refactor a componentes

Modelamos capacidades como componentes independientes y una entidad que los contiene:

```csharp
interface IComponent
{
    void Update(GameObject owner);
}

class HealthComponent : IComponent
{
    public int Vida = 100;
    public void Update(GameObject owner)
    {
        if (Vida <= 0)
            Console.WriteLine($"{owner.Nombre} ha sido derrotado.");
    }
    public void Recibir(int danio) => Vida -= danio;
}

class MoveComponent : IComponent
{
    public float X, Y;
    public float Velocidad = 2f;
    public void Update(GameObject owner)
    {
        X += Velocidad;   // movimiento simple hacia la derecha
        Console.WriteLine($"{owner.Nombre} se mueve a X={X:0.0}");
    }
}

class InputComponent : IComponent
{
    public void Update(GameObject owner) =>
        Console.WriteLine($"{owner.Nombre} procesa input del jugador.");
}

class AIComponent : IComponent
{
    public void Update(GameObject owner) =>
        Console.WriteLine($"{owner.Nombre} decide su accion con IA.");
}
```

### Paso 4 — El contenedor `GameObject`

```csharp
class GameObject
{
    public string Nombre;
    private readonly List<IComponent> _componentes = new();

    public GameObject(string nombre) => Nombre = nombre;

    public GameObject Add(IComponent c) { _componentes.Add(c); return this; }

    public T Get<T>() where T : class =>
        _componentes.FirstOrDefault(c => c is T) as T;

    public void Update()
    {
        foreach (var c in _componentes) c.Update(this);
    }
}
```

### Paso 5 — Ensamblar cualquier entidad sin tocar la jerarquía

```csharp
class Program
{
    static void Main()
    {
        // Un jugador: salud + movimiento + input
        var jugador = new GameObject("Aria")
            .Add(new HealthComponent())
            .Add(new MoveComponent())
            .Add(new InputComponent());

        // Un enemigo: salud + movimiento + IA
        var enemigo = new GameObject("Goblin")
            .Add(new HealthComponent())
            .Add(new MoveComponent())
            .Add(new AIComponent());

        // El caso que rompia la herencia: enemigo CONTROLABLE.
        // Solo cambiamos que componentes tiene; cero duplicacion.
        var enemigoPoseido = new GameObject("Goblin Poseido")
            .Add(new HealthComponent())
            .Add(new MoveComponent())
            .Add(new InputComponent());   // input en vez de IA

        foreach (var obj in new[] { jugador, enemigo, enemigoPoseido })
        {
            Console.WriteLine($"== {obj.Nombre} ==");
            obj.Update();
        }

        // Acceder a un componente concreto:
        jugador.Get<HealthComponent>().Recibir(120);
        jugador.Get<HealthComponent>().Update(jugador);  // reporta derrota
    }
}
```

Ejecuta con `dotnet run`. Cada entidad se comporta según sus componentes, y el "enemigo controlable" que rompía la herencia ahora es trivial: solo cambia su lista de componentes.

## ✍️ Ejercicios

1. Crea un `SpriteComponent` que imprima qué textura dibuja y añádelo a las tres entidades.
2. Implementa un método `Remove<T>()` en `GameObject` para quitar un componente en runtime.
3. Añade un `WeaponComponent` con daño y haz que ataque al enemigo restando vida vía `HealthComponent`.
4. Reescribe la versión con herencia de los pasos 1–2 y compara líneas de código al añadir el "enemigo controlable".
5. Haz que `MoveComponent` lea la dirección desde un campo público y prueba distintas velocidades.
6. Crea una entidad "trampa" que solo tenga `HealthComponent` y `WeaponComponent` (sin movimiento ni IA).

## 📝 Reto verificable

Construye un pequeño escenario con al menos cuatro `GameObject` distintos (jugador, enemigo con IA, enemigo poseído y una trampa estática) usando solo composición. Ejecuta 3 ciclos de `Update()` sobre todos e imprime el estado de cada uno. Ningún comportamiento debe estar duplicado entre clases.

**Criterio de aceptación**: el programa compila y corre con `dotnet run`, las cuatro entidades se comportan de forma distinta según sus componentes, y añadir el "enemigo poseído" no requirió crear una nueva clase de entidad ni copiar métodos.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| Duplicas código entre ramas de herencia | Es la señal de que necesitas composición, no otra subclase. |
| `Get<T>()` devuelve `null` | La entidad no tiene ese componente; verifica que lo añadiste con `Add`. |
| `NullReferenceException` al usar un componente | Accediste antes de añadirlo o tras removerlo. Comprueba con `if (comp != null)`. |
| Jerarquía cada vez más profunda | Estás resolviendo con herencia lo que pide composición. Aplana a componentes. |
| Un componente no se actualiza | No está en la lista `_componentes` o el bucle `Update` no lo recorre. |

## ❓ Preguntas frecuentes

**❓ ¿La herencia es mala?** No; es útil para relaciones "es un" estables. El problema es abusar de ella para modelar capacidades combinables, donde la composición es más flexible.

**❓ ¿Por qué los motores usan componentes?** Porque permiten a los diseñadores ensamblar entidades sin programar nuevas clases: en Unity añades un `Rigidbody` o un `Collider` a un `GameObject` desde el editor.

**❓ ¿Qué gano con interfaces?** Polimorfismo sin acoplar a una jerarquía: cualquier clase que implemente `IComponent` encaja en el sistema, vengan de donde vengan.

**❓ ¿Composición reemplaza totalmente a la herencia?** No; se combinan. Puedes tener componentes que hereden de una base común, pero la entidad se arma por composición, no por una cadena profunda de subclases.

## 🔗 Referencias

- Robert Nystrom, *Game Programming Patterns*, capítulo "Component": <https://gameprogrammingpatterns.com/component.html>
- Microsoft, "Object-Oriented programming (C#)": <https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/>
- Unity, "Introduction to components": <https://docs.unity3d.com/Manual/Components.html>
- "Composition over inheritance": <https://en.wikipedia.org/wiki/Composition_over_inheritance>

## ➡️ Siguiente clase

[Clase 010 - Estructuras de datos para juegos: arrays, listas, diccionarios y colas](../010-estructuras-de-datos-para-juegos-arrays-listas-diccionarios-y-colas/README.md)
