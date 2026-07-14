# Clase 008 — Programación fundamentos con C#: tipos, control de flujo y funciones

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Microsoft C# Docs*
> ⏱️ Duración estimada: **100 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

C# es el lenguaje principal de Unity y una opción de primera clase en Godot, por lo que dominar sus fundamentos es un requisito directo para programar juegos. Antes de tocar un motor conviene entender tipos, variables, control de flujo y funciones en un entorno limpio: una aplicación de consola.

En esta clase instalarás el .NET SDK, crearás tu primer proyecto de consola y escribirás un pequeño simulador de combate por turnos con vida, ataque y un bucle de juego. Al terminar tendrás las herramientas de lógica que usarás en cada script de gameplay.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Instalar el .NET SDK y crear/ejecutar un proyecto de consola con `dotnet new` y `dotnet run`.
2. Declarar variables con los tipos básicos (`int`, `float`, `bool`, `string`) y explicar `struct` vs `class`.
3. Controlar el flujo con `if`, `switch` y bucles `for`, `while` y `foreach`.
4. Escribir métodos con parámetros y valor de retorno, reutilizando lógica.
5. Justificar cuándo usar `float` y cuándo `double` en el contexto de juegos.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Por qué C# en juegos | Es el lenguaje de scripting de Unity y Godot (C#). |
| 2 | Tipos básicos | Definen qué datos manejas y cuánta memoria ocupan. |
| 3 | `struct` vs `class` | Valor vs referencia: afecta rendimiento y copias. |
| 4 | Operadores | Comparan y combinan valores en la lógica de juego. |
| 5 | `if` / `switch` | Toman decisiones según el estado del juego. |
| 6 | Bucles for/while/foreach | Recorren enemigos, turnos, inventarios. |
| 7 | Métodos | Encapsulan lógica reutilizable como "atacar". |
| 8 | `float` vs `double` | Los motores usan `float`; importa por memoria y compatibilidad. |

## 📖 Definiciones y características

- **`int`**: número entero. Clave: contadores, vidas, munición.
- **`float`**: decimal de precisión simple (sufijo `f`). Clave: es el tipo de posiciones y tiempos en Unity.
- **`bool`**: verdadero/falso. Clave: banderas de estado como `estaVivo`.
- **`string`**: texto. Clave: nombres, mensajes, diálogos.
- **`struct`**: tipo de valor; se copia al asignarlo. Clave: ideal para datos pequeños como `Vector2`.
- **`class`**: tipo de referencia; se comparte por referencia. Clave: entidades con estado e identidad.
- **Método**: bloque con nombre que recibe parámetros y puede devolver un valor. Clave: evita repetir lógica.
- **`switch`**: selección entre múltiples casos. Clave: máquinas de estado y menús.

## 🧰 Herramientas y preparación

Instala el **.NET SDK 8.0** (LTS) desde <https://dotnet.microsoft.com/download>. Verifica con `dotnet --version`. Como editor usa Visual Studio Code <https://code.visualstudio.com/> con la extensión C# Dev Kit, o Visual Studio Community. La documentación oficial del lenguaje está en <https://learn.microsoft.com/dotnet/csharp/>. No necesitas Unity todavía; trabajaremos solo con consola.

## 🧪 Laboratorio guiado

### Paso 1 — Crear el proyecto

En una terminal:

```bash
dotnet new console -o SimuladorCombate
cd SimuladorCombate
dotnet run
```

Deberías ver `Hello, World!`. Ese proyecto genera un `Program.cs` que ahora reemplazarás.

### Paso 2 — Tipos y variables

Abre `Program.cs` y empieza con lo básico:

```csharp
int vidaMaxima = 100;
float multiplicadorCritico = 1.5f;   // el sufijo f marca un float
bool jugadorVivo = true;
string nombreHeroe = "Aria";

Console.WriteLine($"{nombreHeroe} entra al combate con {vidaMaxima} de vida.");
```

### Paso 3 — Un método para calcular daño

```csharp
// Metodo con parametros y retorno
static int CalcularDanio(int ataque, int defensa, bool esCritico)
{
    int baseDanio = ataque - defensa;
    if (baseDanio < 1) baseDanio = 1;          // minimo 1 de dano
    if (esCritico) baseDanio = (int)(baseDanio * 1.5f);
    return baseDanio;
}
```

### Paso 4 — El simulador por turnos completo

Reemplaza todo el contenido de `Program.cs` por:

```csharp
class Combatiente
{
    public string Nombre;
    public int Vida;
    public int Ataque;
    public int Defensa;
    public bool EstaVivo => Vida > 0;   // propiedad calculada
}

class Program
{
    static int CalcularDanio(int ataque, int defensa, bool esCritico)
    {
        int danio = ataque - defensa;
        if (danio < 1) danio = 1;
        if (esCritico) danio = (int)(danio * 1.5f);
        return danio;
    }

    static void Main()
    {
        var heroe = new Combatiente { Nombre = "Aria",  Vida = 100, Ataque = 25, Defensa = 8 };
        var enemigo = new Combatiente { Nombre = "Goblin", Vida = 80,  Ataque = 18, Defensa = 5 };

        int turno = 1;
        var rng = new Random();

        while (heroe.EstaVivo && enemigo.EstaVivo)
        {
            Console.WriteLine($"--- Turno {turno} ---");

            // El heroe ataca; 30% de probabilidad de critico
            bool critico = rng.NextDouble() < 0.30;
            int danio = CalcularDanio(heroe.Ataque, enemigo.Defensa, critico);
            enemigo.Vida -= danio;
            Console.WriteLine($"{heroe.Nombre} golpea por {danio}{(critico ? " CRITICO!" : "")}. " +
                              $"{enemigo.Nombre} queda con {Math.Max(enemigo.Vida, 0)} de vida.");

            if (!enemigo.EstaVivo) break;

            // El enemigo contraataca
            int danioEnemigo = CalcularDanio(enemigo.Ataque, heroe.Defensa, false);
            heroe.Vida -= danioEnemigo;
            Console.WriteLine($"{enemigo.Nombre} responde por {danioEnemigo}. " +
                              $"{heroe.Nombre} queda con {Math.Max(heroe.Vida, 0)} de vida.");

            turno++;
        }

        string ganador = heroe.EstaVivo ? heroe.Nombre : enemigo.Nombre;
        Console.WriteLine($"\nCombate terminado en {turno} turnos. Ganador: {ganador}!");
    }
}
```

Ejecuta con `dotnet run`. Verás el combate turno a turno con daños, críticos y un ganador. Como usa `Random`, cada ejecución varía.

### Paso 5 — Probar un `switch`

Añade una función que clasifique el estado de vida y llámala tras cada turno:

```csharp
static string EstadoSalud(int vida) => vida switch
{
    > 66 => "Saludable",
    > 33 => "Herido",
    > 0  => "Critico",
    _    => "Derrotado"
};
```

## ✍️ Ejercicios

1. Añade un tercer combatiente y haz que el héroe pelee contra ambos en secuencia.
2. Convierte `CalcularDanio` para que reciba también un `float multiplicador` como parámetro.
3. Usa un bucle `for` para simular 10 combates y contar cuántos gana el héroe.
4. Sustituye el `if` de crítico por una llamada a `EstadoSalud` que imprima el estado tras cada golpe.
5. Cambia `Combatiente` de `class` a `struct` y observa cómo cambia el comportamiento al pasarlo a un método.
6. Añade curación: si el héroe baja de 20 de vida, que se cure 15 puntos una única vez.

## 📝 Reto verificable

Amplía el simulador para que el héroe tenga una habilidad especial usable una vez por combate que inflige daño doble, y registra en qué turno se usó. Al final imprime un resumen: turnos totales, daño total infligido por cada combatiente y el ganador.

**Criterio de aceptación**: `dotnet run` ejecuta sin errores, el combate termina con un ganador, la habilidad especial se usa como máximo una vez, y el resumen final muestra los tres datos (turnos, daño por combatiente, ganador).

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| `error CS0664: cannot implicitly convert double to float` | Falta el sufijo `f`: escribe `1.5f`, no `1.5`. |
| `dotnet: command not found` | El SDK no está instalado o no está en el PATH. Reinstala desde dotnet.microsoft.com. |
| El bucle nunca termina | La condición del `while` no cambia; asegúrate de restar vida cada turno. |
| `NullReferenceException` | Usaste un objeto `class` sin `new`. Instáncialo antes de acceder a sus campos. |
| Cambios en un `struct` "no se guardan" | Los `struct` se copian por valor al pasarlos; usa `class` o `ref` si necesitas mutar. |
| El daño sale negativo | No pusiste el mínimo de 1; añade `if (danio < 1) danio = 1;`. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué C# y no C++ para empezar?** C# tiene recolección de basura y sintaxis más simple, y es el lenguaje directo de Unity, así que aprendes rápido y aplicas de inmediato.

**❓ ¿Cuándo uso `float` y cuándo `double`?** En juegos usa `float`: Unity y la mayoría de APIs gráficas trabajan con precisión simple, y ahorra memoria. `double` solo cuando necesitas precisión extra en cálculos no gráficos.

**❓ ¿Qué diferencia hay entre `struct` y `class`?** Un `struct` es tipo de valor (se copia al asignarlo), ideal para datos pequeños como un vector; una `class` es de referencia (se comparte), ideal para entidades con identidad.

**❓ ¿Necesito Visual Studio o basta VS Code?** Basta VS Code con la extensión C#. Visual Studio Community es opcional y más pesado, pero cómodo para proyectos grandes.

## 🔗 Referencias

- Microsoft, "A tour of C#": <https://learn.microsoft.com/dotnet/csharp/tour-of-csharp/>
- Microsoft, "Install .NET": <https://learn.microsoft.com/dotnet/core/install/>
- Microsoft, "`dotnet new`": <https://learn.microsoft.com/dotnet/core/tools/dotnet-new>
- C# tipos integrados: <https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/built-in-types>

## ➡️ Siguiente clase

[Clase 009 - POO para juegos: clases, herencia y composición](../009-programacion-orientada-a-objetos-para-juegos-clases-herencia-y-composicion/README.md)
