# Clase 011 — C++ para juegos: fundamentos, punteros y memoria

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Jason Gregory, Game Engine Architecture*
> ⏱️ Duración estimada: **115 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

C++ es el lenguaje que domina los motores AAA (Unreal Engine, id Tech, Frostbite) porque ofrece control directo de la memoria y un rendimiento predecible sin recolector de basura. Ese poder tiene un precio: tú administras la vida de cada objeto, y un error de puntero se convierte en un cuelgue o una fuga.

En esta clase entenderás la diferencia entre **stack** y **heap**, cómo funcionan **punteros y referencias**, por qué `new`/`delete` a mano es peligroso, y cómo los **smart pointers** con **RAII** resuelven la gestión de memoria de forma segura. Compilarás y ejecutarás un programa que gestiona un arreglo de entidades usando `struct`, memoria del stack y del heap, y un `unique_ptr`.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar por qué C++ se usa en motores AAA y cómo se compila un programa.
2. Distinguir memoria de stack de memoria de heap con ejemplos.
3. Usar punteros y referencias, y diferenciar `*` de `&`.
4. Justificar por qué `new`/`delete` manual es propenso a fugas y errores.
5. Aplicar `unique_ptr`/`shared_ptr` y el idioma RAII para liberar memoria automáticamente.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | C++ en motores AAA | Rendimiento predecible y control fino de memoria. |
| 2 | Compilación (g++/MSVC) | Del `.cpp` al ejecutable nativo. |
| 3 | Tipos y `struct` | Agrupar datos de una entidad de juego. |
| 4 | Stack vs heap | Dónde vive cada objeto y su coste. |
| 5 | Punteros y referencias | Acceso indirecto y aliasing de datos. |
| 6 | `new`/`delete` manual | Origen de fugas y dobles liberaciones. |
| 7 | Smart pointers y RAII | Liberación automática y segura. |
| 8 | Cache-friendliness | Datos contiguos = menos fallos de caché. |

## 📖 Definiciones y características

- **Compilación**: traducir `.cpp` a código máquina nativo. Clave: se ejecuta sin intérprete ni VM.
- **`struct`**: agrupación de campos bajo un nombre. Clave: en C++ es como `class` pero con miembros públicos por defecto.
- **Stack**: memoria automática de la función actual. Clave: rápida, se libera al salir del ámbito.
- **Heap**: memoria dinámica pedida en runtime. Clave: vive hasta que la liberas tú.
- **Puntero**: variable que guarda una dirección de memoria. Clave: se desreferencia con `*`, puede ser `nullptr`.
- **Referencia**: alias de una variable existente. Clave: no puede ser nula ni reasignarse.
- **RAII**: un objeto libera su recurso en su destructor. Clave: la vida del recurso sigue la del objeto.
- **`unique_ptr`**: smart pointer de dueño único. Clave: libera automáticamente, no se copia (se mueve).

## 🧰 Herramientas y preparación

Necesitas un compilador de C++. En Windows usa MSVC instalando Build Tools de Visual Studio (<https://visualstudio.microsoft.com/downloads/>) o MinGW-w64 (<https://www.mingw-w64.org/>); en Linux/macOS usa GCC (`g++`) o Clang. Verifica con `g++ --version`. Editor recomendado: Visual Studio Code (<https://code.visualstudio.com/>) con la extensión C/C++ de Microsoft. Usaremos el estándar C++17 (bandera `-std=c++17`). La referencia conceptual es *Game Engine Architecture* de Jason Gregory (<https://www.gameenginebook.com/>) y la documentación del lenguaje en <https://en.cppreference.com/>.

## 🧪 Laboratorio guiado

### Paso 1 — Instalar y verificar el compilador

En una terminal comprueba que el compilador responde:

```bash
g++ --version
```

Si usas MSVC, abre el "Developer Command Prompt" y prueba `cl`. Crea un archivo `entidades.cpp` en una carpeta de trabajo.

### Paso 2 — Un `struct` de entidad y memoria en el stack

Escribe en `entidades.cpp`:

```cpp
#include <iostream>
#include <string>

struct Entidad {
    int id;
    std::string nombre;
    float vida;
};

int main() {
    // Vive en el STACK: se libera solo al terminar main()
    Entidad jugador{1, "Aria", 100.0f};
    std::cout << "Jugador " << jugador.id << ": " << jugador.nombre
              << " (vida " << jugador.vida << ")\n";
    return 0;
}
```

### Paso 3 — Compilar y ejecutar

Con g++:

```bash
g++ -std=c++17 -Wall entidades.cpp -o entidades
./entidades
```

Con MSVC (Developer Command Prompt):

```powershell
cl /EHsc /std:c++17 entidades.cpp
.\entidades.exe
```

Deberías ver los datos del jugador impresos: es tu primer ejecutable nativo.

### Paso 4 — Un arreglo de entidades en el heap con puntero crudo

El heap permite pedir memoria cuyo tamaño decides en runtime. Añade dentro de `main`, antes del `return`:

```cpp
    const int N = 3;
    // Reserva en el HEAP: hay que liberarla manualmente
    Entidad* enemigos = new Entidad[N];
    for (int i = 0; i < N; ++i) {
        enemigos[i] = Entidad{i + 10, "Goblin" + std::to_string(i), 50.0f};
    }
    // Un puntero guarda una direccion; se desreferencia con -> o []
    std::cout << "Primer enemigo: " << enemigos[0].nombre << "\n";

    delete[] enemigos;   // si olvidas esta linea, hay FUGA de memoria
    enemigos = nullptr;  // evita usar un puntero colgante
```

Este patrón manual es el que falla en la práctica: cualquier `return` temprano o excepción entre el `new` y el `delete[]` deja la memoria sin liberar.

### Paso 5 — RAII con `unique_ptr` (versión segura)

`unique_ptr` libera la memoria automáticamente al salir del ámbito, sin `delete` explícito:

```cpp
#include <memory>
// ...
    // El unique_ptr es DUENO del arreglo; se libera solo al final del ambito
    std::unique_ptr<Entidad[]> jefes(new Entidad[2]);
    jefes[0] = Entidad{99, "Dragon", 500.0f};
    jefes[1] = Entidad{98, "Lich", 400.0f};
    std::cout << "Jefe principal: " << jefes[0].nombre
              << " vida " << jefes[0].vida << "\n";
    // No hay delete[]: RAII lo hace por ti aunque haya un return de por medio
```

Recompila con el mismo comando del Paso 3 y ejecuta. Observa que el resultado es idéntico, pero ya no puedes olvidar liberar: esa es la ganancia de RAII.

## ✍️ Ejercicios

1. Añade un campo `float x, y` a `Entidad` y muévela sumando a `x` en un bucle.
2. Escribe una función `void curar(Entidad& e, float cantidad)` que use una referencia y modifique la vida.
3. Escribe `void describir(const Entidad* e)` que reciba un puntero y valide `nullptr` antes de usarlo.
4. Provoca una fuga a propósito quitando el `delete[]` y explícala; luego arréglala con `unique_ptr`.
5. Usa `shared_ptr<Entidad>` compartido entre dos punteros e imprime `use_count()`.
6. Reserva el arreglo en el stack (`Entidad enemigos[3];`) y compara con la versión de heap.

## 📝 Reto verificable

Crea un programa que gestione hasta 5 entidades enemigas usando `std::unique_ptr<Entidad[]>`. Inicialízalas con id, nombre y vida distintos, aplica una función `dañar(Entidad&, float)` que reduzca la vida, e imprime cuáles quedan con vida > 0. El programa no debe contener ningún `delete` explícito.

**Criterio de aceptación**: compila sin advertencias con `g++ -std=c++17 -Wall` (o MSVC equivalente), corre e imprime el estado de las entidades tras el daño, y toda la memoria del heap se gestiona mediante smart pointers (cero `new`/`delete` manuales sin dueño RAII).

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| `undefined reference to main` / no genera ejecutable | Falta `-o nombre` o el archivo no compila. Revisa la sintaxis y la orden del comando. |
| `Segmentation fault` al ejecutar | Desreferenciaste un puntero `nullptr` o colgante. Valida antes de usar y anula tras `delete`. |
| La memoria crece sin parar (fuga) | Hiciste `new`/`new[]` sin su `delete`/`delete[]`. Usa `unique_ptr`/RAII. |
| `double free` / cuelgue al salir | Liberaste dos veces la misma memoria. Con smart pointers no ocurre. |
| `error: 'unique_ptr' was not declared` | Falta `#include <memory>`. Añádelo. |
| `error: use of deleted function` al copiar `unique_ptr` | `unique_ptr` no se copia. Usa `std::move` para transferir la propiedad. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué los motores AAA usan C++ y no un lenguaje con GC?** Porque el recolector de basura puede pausar la ejecución en momentos impredecibles, causando caídas de frame. C++ da control total y rendimiento predecible.

**❓ ¿Cuándo uso stack y cuándo heap?** Stack para objetos de vida corta y tamaño conocido (rápido y automático); heap cuando el tamaño se decide en runtime o el objeto debe sobrevivir al ámbito actual.

**❓ ¿Qué diferencia hay entre puntero y referencia?** El puntero puede ser nulo, reasignarse y requiere `*` para desreferenciar; la referencia es un alias fijo que no puede ser nulo ni cambiar de objeto.

**❓ ¿Cuándo elijo `shared_ptr` en vez de `unique_ptr`?** Usa `unique_ptr` por defecto (dueño único, sin coste extra). Reserva `shared_ptr` para cuando varias partes comparten la propiedad y ninguna sabe quién libera último.

## 🔗 Referencias

- Jason Gregory, *Game Engine Architecture*, 3ª ed., capítulos de fundamentos de C++ y gestión de memoria.
- cppreference, "Smart pointers": <https://en.cppreference.com/book/intro/smart_pointers>
- cppreference, `std::unique_ptr`: <https://en.cppreference.com/w/cpp/memory/unique_ptr>
- ISO C++ Core Guidelines, gestión de recursos (RAII): <https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#S-resource>

## ⬅️ Clase anterior

[Clase 010 - Estructuras de datos para juegos: arrays, listas, diccionarios y colas](../010-estructuras-de-datos-para-juegos-arrays-listas-diccionarios-y-colas/README.md)

## ➡️ Siguiente clase

[Clase 012 - GDScript y Python en juegos: scripting rápido](../012-gdscript-y-python-en-juegos-scripting-rapido/README.md)
