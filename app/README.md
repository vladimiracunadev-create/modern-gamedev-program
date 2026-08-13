# 📱 Apps offline del curso (Windows y Android)

> [⬅️ Volver al programa](../README.md) · [📚 Índice de clases](../classes/README.md) · [📥 Descargas](https://github.com/vladimiracunadev-create/modern-gamedev-program/releases/latest)

Dos aplicaciones que llevan **las 352 clases** a tu escritorio y a tu teléfono, para leerlas sin conexión: buscador, glosario, autoevaluaciones y seguimiento de progreso incluidos.

## 🧩 La decisión que define ambas apps

Las dos empaquetan **exactamente el mismo HTML** que se publica en GitHub Pages, generado por [`scripts/generar_sitio.py`](../scripts/generar_sitio.py). No hay una segunda versión del curso que se pueda quedar atrás: si el sitio cambia, las apps cambian.

Y las dos sirven ese HTML desde un **origen propio**, no con `file://`. Esto no es un detalle de estilo, es el error clásico de empaquetar un sitio estático:

- Bajo `file://`, el navegador trata **cada archivo como un origen distinto**. `fetch()` se bloquea y `localStorage` no persiste de forma fiable.
- El buscador (`busqueda.json`), el quiz (`preguntas.json`) y la pantalla de progreso (`classes/_manifest.json`) **leen sus datos con `fetch`**, y el progreso se guarda en `localStorage`.
- Resultado de hacerlo mal: la app abre, la portada se ve perfecta y las tres funciones interactivas están rotas. Nadie lo nota hasta que un usuario lo reporta.

| App | Cómo sirve el contenido |
|---|---|
| **Android** | Un `WebViewClient` intercepta `https://curso.local/...` y lo resuelve contra los assets del APK ([`android/java/.../MainActivity.java`](android/java/io/github/vladimiracunadev/curso/MainActivity.java)) |
| **Windows** | Electron registra el esquema `curso://` como privilegiado y lo sirve desde la carpeta del contenido ([`windows/main.js`](windows/main.js)) |

## 🤖 Android

Un APK de **sideload** (fuera de Play Store) con el curso dentro.

- **Sin un solo permiso.** Ni siquiera `INTERNET`: todas las peticiones se resuelven contra los assets y lo que no existe devuelve un 404 propio, así que nada llega a intentar salir a la red. Los enlaces externos se abren en el navegador del sistema mediante un `Intent`.
- **minSdk 26** (Android 8.0), **targetSdk 35**.
- **Icono adaptativo vectorial**: una definición para todas las densidades, sin binarios que versionar.
- El botón atrás navega por el historial, y al girar la pantalla se **restaura la clase que estabas leyendo** en vez de volver al índice.

## 🖥️ Windows

Una app de escritorio Electron, distribuida como **ZIP portable**: se descomprime y se ejecuta, sin instalador y sin tocar el registro.

- El curso queda en `resources/sitio`, **fuera del asar**: se puede inspeccionar y actualizar sin reempaquetar.
- El renderer va **sin Node, con `contextIsolation` y `sandbox`**: el contenido es HTML estático y no necesita más.
- Menú en español con atajos: índice (`Ctrl+I`), buscador (`Ctrl+F`), portada (`Ctrl+H`), atrás/adelante y zoom.
- Los enlaces externos salen al navegador del sistema, no a una ventana de Electron sin barra de direcciones.

### Comprobación automática

La app trae un modo de verificación que **carga el contenido y comprueba que `fetch` funciona**, que es lo único que distingue una app que arranca de una app que sirve:

```bash
VideojuegosModerno.exe --verificar
```

```text
  ok     la portada carga desde el esquema del curso
  ok     la portada pinta las 22 partes (pinta 22)
  ok     el buscador indexa 352 clases (indexa 352)
  ok     el quiz trae 110 preguntas (trae 110)
  ok     el manifest declara 352 clases (declara 352)
  ok     lo que no existe devuelve 404 (devuelve 404)
  ok     la última clase (352) está entera (27248 bytes)
== 8 comprobaciones, 0 fallos ==
```

Devuelve `0` si todo pasa y `1` si algo falla, así que sirve tal cual en un pipeline.

## 🔨 Construirlas tú

```bash
python scripts/generar_sitio.py          # 1. el contenido, primero
python scripts/generar_apps.py --todo    # 2. APK + ZIP de Windows + SHA256SUMS
```

También por separado: `--contenido`, `--android`, `--windows`.

| Necesitas | Para qué |
|---|---|
| **Python 3.10+** y `markdown` | generar el sitio |
| **JDK 17+** y el **SDK de Android** (build-tools + una plataforma) | el APK |
| **Node.js 18+** | la app de Windows (descarga Electron la primera vez) |

El APK se construye llamando directamente a `aapt2`, `d8`, `zipalign` y `apksigner`: **sin Gradle**, sin descargas al construir y con todo el proceso en un archivo que se puede leer de arriba abajo.

## 🔑 Sobre la firma del APK

El APK se firma con un keystore que **no está en el repositorio y no debe estarlo**. Si no le pasas uno, el script genera uno de pruebas en `~/.curso-gamedev/firma.jks` y te dice dónde.

> ⚠️ **Guarda ese keystore fuera del proyecto y haz copia.** Android identifica una app por su firma: si lo pierdes, no podrás publicar actualizaciones y los usuarios tendrán que desinstalar y volver a instalar.

Para usar el tuyo:

```bash
python scripts/generar_apps.py --android --keystore /ruta/firma.jks --key-alias curso
```

O por variables de entorno: `CURSO_KEYSTORE`, `CURSO_KEYSTORE_PASS`, `CURSO_KEY_ALIAS`, `CURSO_KEY_PASS`.

## 🔍 Qué NO incluyen

- **El manual en PDF.** Pesa más que la app entera, la WebView de Android no abre PDFs y triplicaría la descarga. Se publica como archivo suelto en la misma release, y los enlaces del manual dentro de las apps apuntan ahí.
- **Los laboratorios Godot.** Son proyectos que se abren en el editor, no páginas que se lean. Se clonan del repositorio.
- **Actualización automática.** Cada versión se descarga de la release. Es una decisión deliberada: un curso offline no necesita un actualizador que hable con un servidor.
