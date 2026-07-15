# Clase 016 — Montaje del entorno: Godot, Unity, Unreal y herramientas

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Documentación oficial de Godot, Unity y Unreal*
> ⏱️ Duración estimada: **90 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Antes de escribir una sola línea de lógica de juego necesitas un entorno de trabajo funcional y reproducible. Un motor mal instalado, sin editor de código integrado ni control de versiones, provoca horas perdidas en errores que no tienen nada que ver con hacer juegos.

En esta clase montarás un entorno completo en Windows: instalarás **Godot 4** (que se distribuye como un ejecutable directo, sin instalador), conocerás cómo se instala **Unity** mediante Unity Hub y por qué **Unreal Engine** es opcional y pesado. Añadirás herramientas de apoyo (VS Code, Git, Blender, editores de imagen y audio) y verificarás que todo renderiza y responde.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Descargar y ejecutar Godot 4 sin instalador y crear un proyecto vacío que renderice.
2. Explicar la diferencia entre el flujo de instalación de Godot, Unity y Unreal.
3. Instalar VS Code y la extensión de Godot para editar scripts fuera del motor.
4. Verificar versiones de las herramientas clave desde la terminal.
5. Enumerar las herramientas de apoyo (Git, Blender, Aseprite/Krita, Audacity) y su función en el pipeline.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Godot 4 portátil | Se ejecuta sin instalar; ideal para empezar rápido. |
| 2 | Unity Hub + LTS | Gestiona versiones y módulos del editor de Unity. |
| 3 | Unreal Engine | Motor AAA opcional; requiere mucho disco y GPU. |
| 4 | Editor de código | VS Code + extensión de Godot para escribir scripts. |
| 5 | Control de versiones | Git protege tu trabajo y permite colaborar. |
| 6 | Herramientas de arte | Blender, Aseprite/Krita para modelos y sprites. |
| 7 | Herramientas de audio | Audacity para editar SFX y música. |
| 8 | Requisitos de hardware | Evitar sorpresas de rendimiento al elegir motor. |

## 📖 Definiciones y características

- **Motor de juego (engine)**: software que integra render, físicas, audio e input para construir juegos. Clave: Godot, Unity y Unreal son las tres opciones más usadas.
- **Godot portátil**: versión de Godot que corre desde un `.exe` sin instalación. Clave: puedes tener varias versiones en carpetas distintas.
- **Unity Hub**: aplicación que instala y administra editores de Unity y sus módulos. Clave: separa la gestión de versiones del editor en sí.
- **LTS (Long-Term Support)**: versión con soporte prolongado y correcciones estables. Clave: recomendada para proyectos serios frente a versiones Tech Stream.
- **Extensión de editor**: complemento de VS Code que aporta resaltado y autocompletado. Clave: la extensión oficial de Godot habilita GDScript.
- **LSP (Language Server Protocol)**: protocolo que conecta el editor con el motor para autocompletado. Clave: Godot expone un servidor LSP en un puerto local.
- **Pipeline de contenido**: conjunto de herramientas que producen assets (arte, audio, modelos). Clave: el motor consume lo que estas herramientas exportan.
- **Requisitos de hardware**: mínimo de CPU, RAM, GPU y disco para trabajar con fluidez. Clave: Unreal exige mucho más que Godot.

## 🧰 Herramientas y preparación

Descarga Godot 4 desde la web oficial (<https://godotengine.org/download/windows/>): elige la edición **Standard** (GDScript) salvo que vayas a usar C#. Unity se instala mediante Unity Hub (<https://unity.com/download>) seleccionando una versión **LTS**. Unreal Engine se obtiene desde el Epic Games Launcher (<https://www.unrealengine.com/download>) y es opcional por su tamaño (decenas de GB). Como editor de código usa Visual Studio Code (<https://code.visualstudio.com/>) con la extensión oficial de Godot. Instala Git (<https://git-scm.com/downloads>), Blender para 3D (<https://www.blender.org/download/>), Aseprite (de pago, <https://www.aseprite.org/>) o Krita gratuito (<https://krita.org/>) para sprites, y Audacity para audio (<https://www.audacityteam.org/>). Requisitos cómodos para Godot: CPU de 4 núcleos, 8 GB de RAM y GPU con soporte Vulkan; para Unreal se recomiendan 32 GB de RAM, SSD y una GPU dedicada moderna.

## 🧪 Laboratorio guiado

### Paso 1 — Descargar y ejecutar Godot 4

Entra en <https://godotengine.org/download/windows/> y descarga el ZIP de **Godot Engine (Standard)**. Descomprímelo en una carpeta estable, por ejemplo `C:\Herramientas\Godot`:

```powershell
mkdir C:\Herramientas\Godot
# Copia el .exe descargado (p. ej. Godot_v4.x-stable_win64.exe) a esa carpeta
```

Godot no tiene instalador: haz doble clic en el `.exe` para abrir el **Project Manager**. No requiere permisos de administrador.

### Paso 2 — Crear un proyecto vacío que renderice

En el Project Manager pulsa **New**, asigna un nombre (`hola-godot`) y una carpeta vacía, deja el renderer **Forward+** y pulsa **Create & Edit**. Se abre el editor con una escena vacía. Añade un nodo raíz **Node2D** con **+ Add Child Node**, luego agrégale un hijo **Sprite2D** y arrastra el icono de Godot (`icon.svg`) del panel FileSystem a su propiedad *Texture*. Pulsa **F5** (Run Project); Godot pedirá elegir la escena principal, selecciona la actual. Verás una ventana con el sprite renderizado: el motor funciona.

### Paso 3 — Instalar VS Code y la extensión de Godot

Instala VS Code desde <https://code.visualstudio.com/>. Ábrelo, ve al panel **Extensions** (`Ctrl+Shift+X`) y busca **godot-tools** (extensión oficial). Instálala. Luego, en Godot, ve a **Editor > Editor Settings > Text Editor > External**, marca *Use External Editor* y apunta a VS Code:

```text
Exec Path:  C:\Users\<usuario>\AppData\Local\Programs\Microsoft VS Code\Code.exe
Exec Flags: {project} --goto {file}:{line}:{col}
```

Al hacer doble clic en un script `.gd`, ahora se abrirá en VS Code con autocompletado vía LSP.

### Paso 4 — Verificar versiones desde la terminal

Abre PowerShell y comprueba las herramientas de apoyo:

```powershell
git --version
code --version
# Godot también responde por línea de comandos:
& "C:\Herramientas\Godot\Godot_v4.x-stable_win64.exe" --version
```

Cada comando debe imprimir un número de versión. Si `git` o `code` no se reconocen, reinicia la terminal para recargar el `PATH`.

## ✍️ Ejercicios

1. Instala una segunda versión de Godot en otra carpeta y confirma que ambas abren sin conflicto.
2. Crea un proyecto con renderer **Mobile** y compara el arranque con el de **Forward+**.
3. Instala Unity Hub y agrega (sin descargar aún) una versión LTS a la lista disponible.
4. Añade la extensión de Git a VS Code y abre tu carpeta de proyecto de Godot como repositorio.
5. Descarga Krita o Blender y verifica que abre correctamente.
6. Documenta en un archivo `entorno.md` las versiones exactas que instalaste.

## 📝 Reto verificable

Monta el entorno completo y deja evidencia: un proyecto de Godot que renderice un sprite, VS Code con la extensión godot-tools instalada y editando un script `.gd`, y un archivo `entorno.md` con las versiones de Godot, VS Code y Git obtenidas por terminal. **Criterio de aceptación**: al ejecutar el proyecto con F5 aparece la ventana con el sprite, al doble-clicar un script se abre en VS Code, y `entorno.md` lista las tres versiones reales.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Godot no abre o cierra al instante | Falta soporte Vulkan; descarga la versión con renderer *Compatibility* o actualiza el driver de la GPU. |
| `'git' no se reconoce...` | Git no está en el `PATH`; reinstala marcando la opción de PATH o reinicia la terminal. |
| Doble clic en `.gd` no abre VS Code | Ruta de *Exec Path* incorrecta en Editor Settings; corrige la ruta a `Code.exe`. |
| Autocompletado ausente en VS Code | El proyecto de Godot no está abierto o el LSP no conecta; abre Godot y VS Code sobre la misma carpeta. |
| Unity Hub pide licencia | Falta activar la licencia gratuita Personal; inicia sesión con tu cuenta Unity. |
| Descarga de Unreal se detiene | Espacio en disco insuficiente; libera decenas de GB antes de instalar. |

## ❓ Preguntas frecuentes

**❓ ¿Necesito instalar Unity y Unreal para el curso?** No. Godot 4 es suficiente para todos los laboratorios de esta parte; Unity y Unreal se instalan solo cuando el temario lo pida.

**❓ ¿Godot requiere permisos de administrador?** No. Al ser portátil, se ejecuta desde cualquier carpeta de usuario sin instalación ni privilegios elevados.

**❓ ¿Elijo la versión Standard o la de .NET/C#?** Usa **Standard** con GDScript para empezar; la edición .NET solo la necesitas si vas a programar en C#.

**❓ ¿Puedo usar otro editor en vez de VS Code?** Sí. El editor interno de Godot es funcional; VS Code se recomienda por su ecosistema, pero no es obligatorio.

## 🔗 Referencias

- Godot — Descargas oficiales: <https://godotengine.org/download/windows/>
- Godot — Documentación de introducción: <https://docs.godotengine.org/en/stable/getting_started/introduction/index.html>
- Unity — Descargar Unity Hub: <https://unity.com/download>
- Unreal Engine — Descargas: <https://www.unrealengine.com/download>
- Visual Studio Code: <https://code.visualstudio.com/>

## ⬅️ Clase anterior

[Clase 015 - Git y control de versiones para proyectos de juegos (con LFS)](../015-git-y-control-de-versiones-para-proyectos-de-juegos-con-lfs/README.md)

## ➡️ Siguiente clase

[Clase 017 - Gráficos por computadora: cómo se dibuja un frame](../017-graficos-por-computadora-como-se-dibuja-un-frame/README.md)
