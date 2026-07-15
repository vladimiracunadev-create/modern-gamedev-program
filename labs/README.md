# 🧪 Laboratorios ejecutables

> [⬅️ Volver al programa](../README.md) · [📚 Índice de clases](../classes/README.md)

Las clases explican **cómo** se hace; estos laboratorios son proyectos **reales que se abren y se juegan**. Cada uno viene en dos versiones:

- **`inicio/`** — proyecto de partida: assets, escenas e infraestructura listas, con los scripts de gameplay marcados con `TODO`. Es donde trabajas tú.
- **`solucion/`** — implementación de referencia completa y jugable. Compárala cuando te atasques (o cuando termines).

Ambas versiones se **verifican en CI con Godot headless** en cada push: se importan, compilan y arrancan. Si el badge está verde, el código de estos labs funciona de verdad.

[![Labs (Godot)](https://github.com/vladimiracunadev-create/desarrollo-videojuegos-moderno-program/actions/workflows/labs.yml/badge.svg?branch=main)](https://github.com/vladimiracunadev-create/desarrollo-videojuegos-moderno-program/actions/workflows/labs.yml)

## 📦 Laboratorios disponibles

| Lab | Parte | Qué construyes |
|---|---|---|
| [**Plataformas 2D**](plataformas-2d/README.md) | [Parte 1](../classes/parte-1-motores-2d-y-tu-primer-juego-jugable/README.md) (clases 026–045) | Un plataformas completo: controlador con game feel, monedas, enemigos, HUD, audio y récord persistente. |

> Más laboratorios (3D, shaders, IA, multijugador) se irán añadiendo siguiendo el [roadmap](../ROADMAP.md).

## 🚀 Cómo usarlos

1. Instala **Godot 4.3** o superior desde <https://godotengine.org/download> (no necesitas nada más: ni plugins, ni cuentas, ni assets de pago).
2. Abre el **Project Manager** de Godot → *Import* → elige el `project.godot` del lab (por ejemplo `labs/plataformas-2d/inicio/project.godot`).
3. Pulsa **F5** para ejecutar.

> **Nota sobre Git LFS.** Los assets binarios (`.png`, `.wav`) se versionan con [Git LFS](https://git-lfs.com/) — justamente lo que enseña la [clase 015](../classes/parte-0-fundamentos-y-prerrequisitos/015-git-y-control-de-versiones-para-proyectos-de-juegos-con-lfs/README.md). Si al clonar ves archivos de texto raros en lugar de imágenes, instala LFS y ejecuta `git lfs pull`.

## 🎨 Sobre los assets

Todos los assets (sprites y sonidos) son **obra original generada por código** con [`scripts/generar_assets.py`](../scripts/generar_assets.py) y están en **dominio público (CC0)**: puedes usarlos para lo que quieras, sin atribución y sin arrastrar licencias de terceros.

¿Quieres cambiarlos? Edita el generador y vuelve a ejecutarlo:

```bash
python -m pip install pillow
python scripts/generar_assets.py
```

La CI comprueba que el generador es **determinista** (que regenerar produce exactamente los assets versionados).
