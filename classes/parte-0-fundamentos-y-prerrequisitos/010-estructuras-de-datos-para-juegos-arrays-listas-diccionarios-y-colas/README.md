# Clase 010 — Estructuras de datos para juegos: arrays, listas, diccionarios y colas

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Jason Gregory, Game Engine Architecture*
> ⏱️ Duración estimada: **110 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Elegir la estructura de datos correcta es una de las decisiones que más impacta el rendimiento de un juego. Buscar un enemigo por su id, reciclar balas sin crear basura, procesar eventos en orden o deshacer acciones: cada caso tiene una estructura ideal.

En esta clase repasarás arrays, listas, diccionarios, colas y pilas con su coste O() intuitivo, y aplicarás dos patrones esenciales: un **object pool** de balas con `Queue` para no crear/destruir cada frame, y un **registro de entidades por id** con `Dictionary` para búsquedas instantáneas. Medirás la diferencia real entre crear y reutilizar.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Distinguir array de lista dinámica y cuándo conviene cada uno.
2. Usar un diccionario para búsquedas por clave en tiempo casi constante.
3. Aplicar colas y pilas para eventos y deshacer acciones.
4. Estimar el coste O() de las operaciones básicas de cada estructura.
5. Implementar un object pool y explicar por qué evita el coste de crear/destruir por frame.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Array vs lista dinámica | Tamaño fijo vs crecimiento; afecta memoria y velocidad. |
| 2 | Diccionario / hash | Buscar entidades por id sin recorrer todo. |
| 3 | Cola (Queue) | Procesar eventos y reciclar objetos en orden FIFO. |
| 4 | Pila (Stack) | Deshacer acciones y navegación de menús (LIFO). |
| 5 | Coste O() intuitivo | Anticipar qué operación será cara. |
| 6 | Object pooling | Evita crear/destruir cada frame y reduce hipos del GC. |
| 7 | Iterar sin romper la colección | Evita excepciones al modificar mientras recorres. |

## 📖 Definiciones y características

- **Array**: bloque contiguo de tamaño fijo. Clave: acceso por índice O(1), pero no crece.
- **Lista dinámica (`List<T>`)**: array que crece solo. Clave: `Add` amortizado O(1), inserción al medio O(n).
- **Diccionario (`Dictionary<K,V>`)**: mapa clave→valor por hash. Clave: búsqueda O(1) promedio.
- **Cola (`Queue<T>`)**: FIFO, primero en entrar primero en salir. Clave: `Enqueue`/`Dequeue` O(1).
- **Pila (`Stack<T>`)**: LIFO, último en entrar primero en salir. Clave: ideal para undo.
- **Notación O()**: cómo escala el coste con el tamaño. Clave: O(1) constante, O(n) lineal.
- **Object pool**: colección de objetos preasignados que se reutilizan. Clave: cero asignaciones por frame.
- **Iteración segura**: no modificar una colección mientras se recorre con `foreach`. Clave: usa una copia o índice inverso.

## 🧰 Herramientas y preparación

Continuamos con el .NET SDK 8.0 (<https://dotnet.microsoft.com/download>) y una consola creada con `dotnet new console`. Usaremos los tipos de `System.Collections.Generic` (ya incluidos) y `System.Diagnostics.Stopwatch` para medir tiempos. Editor: Visual Studio Code <https://code.visualstudio.com/>. La referencia conceptual es *Game Engine Architecture* de Jason Gregory (<https://www.gameenginebook.com/>). Documentación de colecciones: <https://learn.microsoft.com/dotnet/api/system.collections.generic>.

## 🧪 Laboratorio guiado

### Paso 1 — Array vs lista dinámica

Edita `Program.cs`:

```csharp
int[] fijo = new int[3];        // tamano fijo, acceso O(1)
fijo[0] = 10;

var dinamica = new List<int>(); // crece sola
dinamica.Add(10);
dinamica.Add(20);
Console.WriteLine($"Array[0]={fijo[0]}, Lista tiene {dinamica.Count} elementos");
```

### Paso 2 — Registro de entidades por id con Dictionary

```csharp
class Entidad
{
    public int Id;
    public string Nombre;
    public int Vida = 100;
}

var registro = new Dictionary<int, Entidad>();
registro[1] = new Entidad { Id = 1, Nombre = "Aria" };
registro[2] = new Entidad { Id = 2, Nombre = "Goblin" };

// Buscar por id en O(1) promedio, sin recorrer la lista entera
if (registro.TryGetValue(2, out var e))
    Console.WriteLine($"Encontrada entidad {e.Id}: {e.Nombre}");
```

### Paso 3 — Object pool de balas con Queue

En vez de `new Bala()` cada disparo, sacamos una del pool y la devolvemos al terminar:

```csharp
class Bala
{
    public float X, Y;
    public bool Activa;
    public void Reset(float x, float y) { X = x; Y = y; Activa = true; }
}

class PoolBalas
{
    private readonly Queue<Bala> _libres = new();

    public PoolBalas(int cantidad)
    {
        for (int i = 0; i < cantidad; i++) _libres.Enqueue(new Bala());
    }

    public Bala Obtener(float x, float y)
    {
        // Si hay libres reutilizamos; si no, creamos una nueva
        Bala b = _libres.Count > 0 ? _libres.Dequeue() : new Bala();
        b.Reset(x, y);
        return b;
    }

    public void Devolver(Bala b)
    {
        b.Activa = false;
        _libres.Enqueue(b);   // vuelve al pool para reutilizarse
    }

    public int Disponibles => _libres.Count;
}
```

### Paso 4 — Medir crear vs reutilizar

```csharp
using System.Diagnostics;

const int DISPAROS = 1_000_000;

// A) Crear una bala nueva cada disparo (genera basura para el GC)
var sw = Stopwatch.StartNew();
for (int i = 0; i < DISPAROS; i++)
{
    var b = new Bala();
    b.Reset(i, 0);
}
sw.Stop();
long crear = sw.ElapsedMilliseconds;

// B) Reutilizar desde el pool
var pool = new PoolBalas(64);
sw.Restart();
for (int i = 0; i < DISPAROS; i++)
{
    var b = pool.Obtener(i, 0);
    pool.Devolver(b);
}
sw.Stop();
long reutilizar = sw.ElapsedMilliseconds;

Console.WriteLine($"Crear nuevas: {crear} ms");
Console.WriteLine($"Reutilizar pool: {reutilizar} ms");
Console.WriteLine($"Balas en pool al final: {pool.Disponibles}");
```

Ejecuta con `dotnet run`. Verás que reutilizar es más rápido y, sobre todo, no deja millones de objetos para que el recolector de basura los limpie (lo que en un juego causa "hipos" de frame).

### Paso 5 — Pila para deshacer e iteración segura

```csharp
var historial = new Stack<string>();   // LIFO para undo
historial.Push("mover");
historial.Push("disparar");
Console.WriteLine($"Deshacer: {historial.Pop()}");  // "disparar" primero

// Iteracion segura: recorrer una COPIA para poder modificar la original
var enemigos = new List<Entidad> {
    new() { Id = 1, Vida = 0 }, new() { Id = 2, Vida = 50 }
};
foreach (var en in enemigos.ToList())   // ToList() crea una copia
    if (en.Vida <= 0) enemigos.Remove(en);
Console.WriteLine($"Enemigos vivos: {enemigos.Count}");
```

## ✍️ Ejercicios

1. Amplía el pool para que reporte cuántas veces tuvo que crear una bala nueva (pool agotado).
2. Cambia el `Dictionary` por una `List` y busca por id con un bucle; compara el tiempo con `Stopwatch`.
3. Implementa `undo`/`redo` con dos pilas (`Stack`) para una lista de acciones.
4. Usa una `Queue` para procesar una cola de eventos de juego en orden y vaciarla.
5. Preasigna 128 balas en el pool y verifica que `Disponibles` vuelve a 128 tras devolverlas todas.
6. Provoca a propósito la excepción "Collection was modified" quitando el `ToList()` y luego arréglala.

## 📝 Reto verificable

Simula 60 frames de un juego que dispara hasta 20 balas por frame usando el `PoolBalas`. En cada frame obtén balas, "muévelas" y devuelve al pool las que salgan de pantalla (X > 100). Al final imprime cuántas balas se crearon en total (idealmente cercano al tamaño del pool, no a las miles disparadas) y el tamaño final del pool.

**Criterio de aceptación**: el programa corre con `dotnet run`, el número total de balas creadas se mantiene bajo (del orden del tamaño del pool y no de los disparos totales), y el pool termina con todas sus balas disponibles, demostrando la reutilización.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| `InvalidOperationException: Collection was modified` | Modificaste la lista dentro de un `foreach`. Itera sobre una copia (`ToList()`) o con índice inverso. |
| `KeyNotFoundException` | Accediste a `dict[clave]` inexistente. Usa `TryGetValue` antes. |
| El juego tiene hipos periódicos | Creas/destruyes muchos objetos por frame; el GC se dispara. Usa un object pool. |
| Búsqueda lenta con muchas entidades | Recorres una `List` con bucle O(n). Cambia a `Dictionary` para O(1). |
| `IndexOutOfRangeException` en un array | Accediste fuera del tamaño fijo. Los arrays no crecen; usa `List` o valida el índice. |
| El pool "no reutiliza" | Olvidaste llamar a `Devolver`; sin eso, cada disparo crea una bala nueva. |

## ❓ Preguntas frecuentes

**❓ ¿Cuándo uso array y cuándo `List`?** Array si el tamaño es fijo y conocido (rendimiento y memoria óptimos); `List` cuando el número de elementos cambia en runtime.

**❓ ¿Por qué el diccionario es tan rápido para buscar?** Porque usa una función hash para saltar directo al valor, sin recorrer todos los elementos: coste O(1) en promedio frente a O(n) de una lista.

**❓ ¿Qué problema resuelve el object pooling?** Evita asignar y liberar memoria cada frame. Crear/destruir objetos constantemente genera basura que el recolector debe limpiar, causando caídas de rendimiento.

**❓ ¿Por qué no puedo borrar mientras hago `foreach`?** Porque modificar la colección invalida el iterador y lanza una excepción. Recorre una copia o usa un `for` con índice descendente.

## 🔗 Referencias

- Jason Gregory, *Game Engine Architecture*, 3ª ed., capítulo de estructuras de datos y gestión de memoria.
- Robert Nystrom, "Object Pool": <https://gameprogrammingpatterns.com/object-pool.html>
- Microsoft, `System.Collections.Generic`: <https://learn.microsoft.com/dotnet/api/system.collections.generic>
- Microsoft, `Dictionary<TKey,TValue>`: <https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2>

## ⬅️ Clase anterior

[Clase 009 - POO para juegos: clases, herencia y composición](../009-programacion-orientada-a-objetos-para-juegos-clases-herencia-y-composicion/README.md)

## ➡️ Siguiente clase

[Clase 011 - C++ para juegos: fundamentos, punteros y memoria](../011-c-plus-plus-para-juegos-fundamentos-punteros-y-memoria/README.md)
