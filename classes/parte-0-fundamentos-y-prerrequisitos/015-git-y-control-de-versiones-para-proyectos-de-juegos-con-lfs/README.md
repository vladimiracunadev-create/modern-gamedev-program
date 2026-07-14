# Clase 015 — Git y control de versiones para proyectos de juegos (con LFS)

> Parte: **0 — Fundamentos y prerrequisitos** · Fuente: *Pro Git (Chacon & Straub); Git LFS docs*
> ⏱️ Duración estimada: **105 min** · Nivel: **Fundamentos**

---

## 🎯 Objetivo

Un proyecto de juego evoluciona con cientos de cambios: código, escenas, arte y audio. Sin control de versiones no hay forma segura de volver atrás, trabajar en paralelo o colaborar. **Git** resuelve esto, pero los juegos añaden un reto extra: los **archivos binarios grandes** (texturas, sonidos, modelos) que Git maneja mal. Para eso existe **Git LFS**.

En esta clase aprenderás el flujo básico de Git (`init`, `add`, `commit`, `branch`, `merge`), a escribir un `.gitignore` adecuado para un proyecto de juego (por ejemplo, ignorar `.godot/`), y a configurar **Git LFS** para versionar `*.png` y `*.wav` sin inflar el repositorio. Crearás un repo de prueba, harás commits y una rama.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Inicializar un repositorio y registrar cambios con `add` y `commit`.
2. Crear y fusionar ramas para trabajar en paralelo.
3. Escribir un `.gitignore` que excluya carpetas de import/build de un proyecto de juego.
4. Explicar por qué los binarios grandes son problemáticos en Git.
5. Instalar y configurar Git LFS para rastrear texturas y audio.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Por qué versionar | Historial, retroceso y colaboración segura. |
| 2 | `init`/`add`/`commit` | El ciclo básico de guardar cambios. |
| 3 | `branch`/`merge` | Trabajar en features sin romper lo principal. |
| 4 | `.gitignore` en juegos | No versionar carpetas de import/build generadas. |
| 5 | Binarios grandes | Inflan el repo y no se fusionan bien. |
| 6 | Git LFS | Versionar arte/audio con punteros ligeros. |
| 7 | Escenas binarias | Por qué no se hace merge fácil de ellas. |

## 📖 Definiciones y características

- **Repositorio**: carpeta con historial de cambios versionado por Git. Clave: lo crea `git init`.
- **Commit**: instantánea de los cambios con un mensaje. Clave: unidad de historial reversible.
- **Staging area**: zona intermedia donde preparas qué entra al commit. Clave: la llena `git add`.
- **Rama (branch)**: línea de desarrollo paralela. Clave: aislar trabajo sin afectar `main`.
- **Merge**: integrar los cambios de una rama en otra. Clave: puede generar conflictos a resolver.
- **`.gitignore`**: lista de patrones de archivos que Git ignora. Clave: excluye carpetas generadas.
- **Git LFS**: extensión que guarda binarios grandes fuera del repo dejando un puntero. Clave: repo ligero.
- **Merge de binarios**: Git no sabe fusionar binarios línea a línea. Clave: se resuelven eligiendo una versión completa.

## 🧰 Herramientas y preparación

Necesitas Git instalado (<https://git-scm.com/downloads>); verifica con `git --version`. Configura tu identidad la primera vez con `git config`. Instala también Git LFS (<https://git-lfs.com/>), disponible como paquete aparte o incluido en instaladores recientes de Git para Windows. Editor recomendado: Visual Studio Code (<https://code.visualstudio.com/>). Las referencias son el libro gratuito *Pro Git* de Scott Chacon y Ben Straub (<https://git-scm.com/book/es/v2>) y la documentación de Git LFS (<https://github.com/git-lfs/git-lfs/wiki/Tutorial>). Los comandos siguientes se ejecutan en una terminal bash (Git Bash en Windows).

## 🧪 Laboratorio guiado

### Paso 1 — Configurar Git e iniciar el repo

Configura tu identidad (solo la primera vez) y crea el proyecto:

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@correo.com"

mkdir juego-prueba && cd juego-prueba
git init
```

`git init` crea el repositorio (una carpeta oculta `.git`). Comprueba el estado con `git status`.

### Paso 2 — Un `.gitignore` para proyecto de juego

Crea el archivo `.gitignore` con las carpetas generadas que NO deben versionarse. Ejemplo para Godot y assets exportados:

```bash
cat > .gitignore << 'EOF'
# Godot 4: carpeta de import/cache generada
.godot/

# Carpetas de exportacion/compilacion
build/
export/
*.tmp

# Sistema operativo
.DS_Store
Thumbs.db
EOF
```

Estas carpetas se regeneran solas; versionarlas solo añade ruido y conflictos.

### Paso 3 — Primer commit

Crea algo de contenido de código y regístralo:

```bash
echo "extends Node" > player.gd
echo "# Juego de prueba" > README.md

git add .gitignore player.gd README.md
git commit -m "Estructura inicial del proyecto"
```

`git add` mueve los archivos al staging area y `git commit` guarda la instantánea. Revisa el historial con `git log --oneline`.

### Paso 4 — Instalar y configurar Git LFS para arte y audio

Instala LFS una vez por máquina y declara qué extensiones rastrear en este repo:

```bash
git lfs install                 # activa LFS para tu usuario

git lfs track "*.png"           # texturas
git lfs track "*.wav"           # audio

git add .gitattributes          # LFS guarda las reglas aqui
git commit -m "Configurar Git LFS para *.png y *.wav"
```

El comando `git lfs track` escribe reglas en `.gitattributes`. A partir de ahora, cualquier `.png` o `.wav` se guardará como un puntero ligero y su contenido real irá al almacén de LFS. Verifica las reglas con `git lfs track` y los archivos rastreados con `git lfs ls-files`.

### Paso 5 — Crear una rama, trabajar y fusionar

Trabaja una funcionalidad en su propia rama y luego intégrala en `main`:

```bash
git switch -c feature/salto        # crea y cambia a la rama
echo "func saltar(): pass" >> player.gd
git add player.gd
git commit -m "Anadir funcion de salto al jugador"

git switch main                    # volver a la rama principal
git merge feature/salto            # integrar los cambios
git log --oneline --graph          # ver el historial ramificado
```

Verás el commit del salto ya integrado en `main`. Este flujo —rama por feature, commit, merge— es la base del trabajo colaborativo sin pisarse el código.

## ✍️ Ejercicios

1. Añade `*.ogg` y `*.psd` al rastreo de LFS y verifica con `git lfs track`.
2. Crea una rama `feature/enemigo`, haz dos commits y fusiónala en `main`.
3. Provoca un conflicto de merge editando la misma línea en dos ramas y resuélvelo.
4. Amplía `.gitignore` con la carpeta `Library/` (Unity) y comprueba que Git la ignora.
5. Usa `git log --oneline` y `git diff` para inspeccionar el historial y los cambios.
6. Crea un `.png` de prueba, añádelo y confirma con `git lfs ls-files` que LFS lo rastrea.

## 📝 Reto verificable

Crea desde cero un repositorio de un proyecto de juego con: un `.gitignore` que excluya al menos `.godot/` y `build/`, Git LFS configurado para `*.png` y `*.wav`, al menos tres commits con mensajes claros, y una rama de feature fusionada en `main`. Genera un archivo `.png` de prueba y demuestra que está rastreado por LFS.

**Criterio de aceptación**: `git log --oneline` muestra al menos tres commits y el merge de la rama; `git lfs ls-files` lista el archivo `.png`; y `git status` está limpio, sin las carpetas ignoradas apareciendo como cambios pendientes.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|------------------------|
| `fatal: not a git repository` | No ejecutaste `git init` o estás fuera de la carpeta del repo. Entra al proyecto e inicialízalo. |
| Aparecen cientos de archivos en `git status` | Falta un `.gitignore`; se están rastreando carpetas generadas. Créalo antes del primer `add`. |
| `Please tell me who you are` al hacer commit | No configuraste `user.name`/`user.email`. Ejecuta los `git config` del Paso 1. |
| Un `.png` grande se subió como binario normal, no por LFS | Configuraste LFS después de añadirlo. Rastréalo con `git lfs track` y vuelve a añadirlo (`git rm --cached` y `git add`). |
| `git lfs: command not found` | Git LFS no está instalado. Instálalo desde git-lfs.com y ejecuta `git lfs install`. |
| Conflicto en una escena binaria imposible de fusionar | Git no hace merge de binarios línea a línea. Elige una versión completa (`git checkout --ours/--theirs`) y coordina con el equipo. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué no versionar carpetas como `.godot/` o `build/`?** Porque son contenido generado automáticamente a partir de los fuentes. Versionarlas infla el repo, causa conflictos y no aporta información útil; se regeneran solas.

**❓ ¿Qué problema tienen los binarios grandes en Git?** Git guarda una copia de cada versión completa del archivo; con binarios pesados el repositorio crece enormemente y las operaciones se vuelven lentas. LFS los sustituye por punteros ligeros.

**❓ ¿Qué hace exactamente Git LFS?** Reemplaza el archivo grande por un pequeño puntero de texto en el repo y guarda el contenido real en un almacén aparte. El repositorio se mantiene ligero y el archivo se descarga cuando hace falta.

**❓ ¿Por qué no se pueden fusionar escenas binarias fácilmente?** Porque Git fusiona texto línea a línea, y una escena binaria no es texto legible línea a línea. Por eso conviene evitar que dos personas editen la misma escena a la vez y, si ocurre, elegir una versión completa.

## 🔗 Referencias

- Scott Chacon & Ben Straub, *Pro Git*, "Fundamentos de Git": <https://git-scm.com/book/es/v2>
- Scott Chacon & Ben Straub, *Pro Git*, "Ramificaciones en Git": <https://git-scm.com/book/es/v2/Ramificaciones-en-Git-Procedimientos-Basicos-para-Ramificar-y-Fusionar>
- Git LFS, tutorial oficial: <https://github.com/git-lfs/git-lfs/wiki/Tutorial>
- GitHub Docs, "Ignoring files (.gitignore)": <https://docs.github.com/get-started/getting-started-with-git/ignoring-files>

## ➡️ Siguiente clase

[Clase 016 - Montaje del entorno: Godot, Unity, Unreal y herramientas](../016-montaje-del-entorno-godot-unity-unreal-y-herramientas/README.md)
