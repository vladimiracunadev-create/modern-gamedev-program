# 🤝 Guía de contribución

¡Gracias por tu interés en mejorar el **Programa de Desarrollo de Videojuegos Moderno**! Las contribuciones son bienvenidas: correcciones, mejoras a las clases, nuevos laboratorios o avance del roadmap. El código se publica bajo MIT, el contenido educativo bajo CC BY-NC-SA 4.0 y cada asset bajo la licencia registrada en [`ASSET_LICENSES.md`](ASSET_LICENSES.md). Al contribuir, confirmas que tienes derecho a aportar el material bajo la licencia aplicable.

## 🧭 Antes de empezar

- Lee el [README](README.md) y el [ROADMAP](ROADMAP.md) para entender la estructura.
- Cada clase es una carpeta `classes/parte-N-slug/NNN-slug/README.md` con un formato fijo (ver abajo).
- La numeración es **global y secuencial** (001→…). No reutilices números.

## ✍️ Formato de una clase

Toda clase debe incluir estas secciones, en este orden:

1. Encabezado `# Clase NNN — Título` + blockquote con parte, fuente, duración y nivel.
2. `## 🎯 Objetivo`
3. `## 📚 Resultados de aprendizaje` (lista verificable)
4. `## 🗺️ Temas` (tabla)
5. `## 📖 Definiciones y características`
6. `## 🧰 Herramientas y preparación`
7. `## 🧪 Laboratorio guiado` (pasos reales con código ejecutable)
8. `## ✍️ Ejercicios`
9. `## 📝 Reto verificable` (con **Criterio de aceptación**)
10. `## ⚠️ Errores comunes` (tabla síntoma → causa)
11. `## ❓ Preguntas frecuentes`
12. `## 🔗 Referencias` — cada fuente termina en `· uso: <etiqueta>`, declarando qué hace esa clase con ella.
13. `## ⬅️ Clase anterior` (enlace a la anterior; la 001 enlaza al índice)
14. `## ➡️ Siguiente clase` (enlace a la siguiente)

> El validador de CI (`scripts/validar_estructura.py`) comprueba que estas secciones existan, que la numeración sea contigua y que **no haya enlaces internos rotos**.
>
> Las dos últimas no se escriben a mano: las genera [`scripts/generar_navegacion.py`](scripts/generar_navegacion.py) a partir del orden de las clases. Si insertas o reordenas una, ejecútalo y la CI comprobará que está al día.

## ✅ Reglas de estilo

- **Español neutro y técnico.** Explica el *porqué*, no solo el *cómo*.
- **Código real y correcto.** En la Parte 1 usa la API de **Godot 4** (`CharacterBody2D`, `velocity`, `move_and_slide()` sin argumentos, `is_on_floor()`). Nunca API de Godot 3 (`KinematicBody2D`, `move_and_slide(velocity)`).
- **Contenido original.** No copies texto de libros ni de la documentación; cítalos como referencia.
- **Licencia y procedencia.** Todo asset nuevo necesita una fila en [`ASSET_LICENSES.md`](ASSET_LICENSES.md) con autoría, fuente, licencia y evidencia. La presencia del archivo o que sea gratuito no bastan. Las dependencias nuevas deben registrarse en [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
- **Toda fuente citada va en el registro.** Nada entra en un bloque `## 🔗 Referencias` sin su entrada en [`sources/bibliography.json`](sources/bibliography.json), con localizador resoluble: ISBN-13 para libros, DOI para artículos, URL https de la fuente primaria para normas y documentación. Lo que no resuelvas se marca `"status": "pendiente"` con su motivo — **nunca se inventa un ISBN, un DOI o una fecha, y nunca se borra una fuente que no resuelve**. Cómo hacerlo: [`sources/README.md`](sources/README.md).
- **La documentación del motor va anclada a versión.** Godot **4.3** y Blender **4.2 LTS**, nunca `/en/stable` ni `/latest`: esos alias se mueven solos y dejan al programa citando una versión que nunca enseñó. `verify-sources` falla si reaparecen.
- **Sin binarios pesados en Git.** Usa Git LFS para arte, audio y modelos (ver [`.gitattributes`](.gitattributes) y la Clase 015).

## 🔧 Comprobaciones locales antes de subir

Hay un script que corre **lo mismo que la CI**, para no descubrir en rojo lo que se puede
descubrir en verde:

```bash
python scripts/verificar_todo.py --rapido            # validadores: unos segundos
python scripts/verificar_todo.py --godot /ruta/godot # + los 6 labs: ~4 min
```

Comprueba estructura y enlaces, índice y manifest sincronizados, assets deterministas,
markdownlint, el build del sitio, los workflows, el registro de fuentes, y —si le pasas Godot 4.3— los laboratorios
enteros: cada uno en sus dos versiones más las pruebas de comportamiento (que la red replica,
que la IA decide, que la UI no se recorta).

Termina diciendo si puedes subir o no. **Si no le pasas `--godot`, avisa de que la mitad de la
CI se ha quedado sin comprobar** en vez de darte un verde tranquilizador.

Por partes, si lo prefieres:

```bash
python scripts/validar_estructura.py       # estructura, secciones y enlaces internos
npx --yes markdownlint-cli2 "**/*.md"      # lint de Markdown (requiere Node)
python scripts/verificar_assets.py         # los assets coinciden con el generador
python scripts/generar_sitio.py            # el sitio compila
python scripts/verify-sources              # el registro de fuentes cuadra
```

Todas deben pasar en verde. La CI las ejecuta en cada push.

## 🔀 Flujo de trabajo

1. Haz un *fork* y crea una rama descriptiva: `git checkout -b clase/046-escena-3d`.
2. Haz tus cambios y ejecuta las comprobaciones locales.
3. Commits claros en español (ej. `Añade Clase 046: escenas 3D y transformaciones`).
4. Abre un Pull Request describiendo qué añade o corrige.

## 💡 Ideas de contribución

- Corregir erratas, mejorar explicaciones o añadir errores comunes reales.
- Completar una parte del roadmap (2–17) siguiendo el formato.
- Aportar proyectos de ejemplo ejecutables (con licencia libre para los assets).
- Traducir o adaptar laboratorios a Unity/Unreal como material complementario.

¡Gracias por ayudar a que aprender a hacer videojuegos en español sea mejor! 🎮
