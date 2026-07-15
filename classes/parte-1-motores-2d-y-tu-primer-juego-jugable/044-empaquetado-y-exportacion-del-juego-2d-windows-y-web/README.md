# Clase 044 — Empaquetado y exportación del juego 2D (Windows y web)

> Parte: **1 — Motores 2D y tu primer juego jugable** · Fuente: *Documentación de Godot 4 (Exporting)*
> ⏱️ Duración estimada: **85 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Convertir tu proyecto en un juego que otras personas puedan ejecutar. Hasta ahora el juego solo corre dentro del editor; en esta clase lo **exportarás** a dos formatos: un ejecutable **Windows Desktop (.exe)** y una versión **Web (HTML5)** que corre en el navegador. Aprenderás a instalar las **plantillas de exportación**, a crear **presets**, a asignar icono y metadatos, y a resolver los requisitos particulares del build web.

Verás que el export web tiene condiciones especiales (necesita **SharedArrayBuffer** y debe servirse por **HTTP**, no abriendo el archivo directamente). Aprenderás a probar el build local con un servidor sencillo y a dejar tu juego listo para publicarlo en **itch.io**, la plataforma más popular para juegos independientes. Al terminar tendrás un `.exe` funcional y un juego jugable en navegador.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Instalar las **export templates** correctas para su versión de Godot 4.
2. Crear y configurar un **preset de Windows Desktop** y exportar un `.exe` que funcione.
3. Crear un **preset Web (HTML5)** y exportar el juego a una carpeta servible.
4. Servir el build web localmente por HTTP y probarlo en el navegador.
5. Preparar y describir los pasos para **publicar en itch.io**.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Plantillas de exportación | Sin ellas Godot no puede generar ejecutables. |
| 2 | Presets de exportación | Definen plataforma y opciones de cada build. |
| 3 | Export Windows Desktop | Genera el `.exe` que corre nativo en Windows. |
| 4 | Icono y metadatos | Dan identidad y profesionalidad al ejecutable. |
| 5 | Export Web (HTML5) | Permite jugar sin instalar nada, solo el navegador. |
| 6 | SharedArrayBuffer y HTTP | Requisitos técnicos sin los que el web build no arranca. |
| 7 | Servir el build localmente | Necesario porque `file://` no funciona para web. |
| 8 | Publicar en itch.io | El canal habitual para compartir juegos indie. |

## 📖 Definiciones y características

- **Export templates**: paquete oficial con los binarios base de cada plataforma que Godot combina con tu proyecto. Clave: deben coincidir **exactamente** con tu versión de Godot.
- **Preset de exportación**: configuración guardada (plataforma, ruta, opciones) para un build concreto. Clave: puedes tener varios (Windows, Web) a la vez.
- **Windows Desktop**: preset que produce un `.exe` (y un `.pck` con los datos, o todo embebido). Clave: es el juego nativo para PC.
- **Web / HTML5**: preset que genera `.html`, `.js`, `.wasm` y `.pck`. Clave: corre en el navegador vía WebAssembly.
- **SharedArrayBuffer**: característica del navegador que el runtime web de Godot 4 necesita para el multihilo. Clave: exige cabeceras COOP/COEP en el servidor.
- **Servidor HTTP local**: proceso que sirve archivos por `http://` (p. ej. `python -m http.server`). Clave: el build web **no** funciona abierto como `file://`.
- **Metadatos**: nombre de producto, versión, descripción e icono del ejecutable. Clave: se configuran en el preset (sección Application).
- **itch.io**: plataforma de distribución de juegos indie que soporta descargas y juegos web embebidos. Clave: destino natural para publicar.

## 🧰 Herramientas y preparación

Necesitas tu proyecto `PlataformasCurso` terminado hasta aquí, **Godot 4.x** y conexión a internet para descargar las plantillas. Para el build web conviene tener **Python 3** instalado (trae un servidor HTTP integrado). Opcionalmente, crea una cuenta gratuita en **itch.io** (<https://itch.io>) para la parte de publicación. Documentación de referencia: exportación general <https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html> y exportación web <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html>.

## 🧪 Laboratorio guiado

Instalaremos plantillas, exportaremos `.exe` y HTML5, y probaremos el build web en el navegador.

1. **Instalar las export templates.** En el editor ve a **Editor → Manage Export Templates**. Pulsa **Download and Install**; Godot descargará las plantillas correspondientes a tu versión exacta. Espera a que aparezca la marca de instaladas. Si no tienes internet, usa **Install from File** con el archivo `.tpz` oficial.

2. **Abrir el diálogo de exportación.** Ve a **Project → Export**. Verás una lista de presets (vacía al principio) y el botón **Add...**.

3. **Crear el preset de Windows.** Pulsa **Add... → Windows Desktop**. En la pestaña **Options** revisa la arquitectura (`x86_64`). En la sección **Application** rellena **Product Name** (`Plataformas Curso`), **File Version** y **Company Name**. Para el icono, prepara un `.ico` y asígnalo en **Icon**.

4. **Exportar el .exe.** Con el preset de Windows seleccionado pulsa **Export Project**. Elige una carpeta (por ejemplo `builds/windows/`) y nombre `PlataformasCurso.exe`. Desmarca **Export With Debug** para un build final. Godot generará el `.exe`.

5. **Probar el ejecutable.** Sal del editor y ejecuta el `.exe` con un doble clic (o desde consola):

```bash
# Desde la carpeta del build, en Windows (Git Bash / consola)
./PlataformasCurso.exe
```

El juego debe abrirse como aplicación nativa, con tu menú, sonido, partículas y guardado funcionando. El guardado `user://` seguirá persistiendo, ahora en la carpeta de datos del ejecutable.

6. **Crear el preset Web.** Vuelve a **Project → Export → Add... → Web**. Deja las opciones por defecto; asegúrate de que **Export Type** sea el estándar. Godot puede advertir si faltan plantillas web: reinstálalas si es necesario.

7. **Exportar el build web.** Con el preset Web seleccionado pulsa **Export Project** y elige una carpeta vacía, por ejemplo `builds/web/`, con el nombre de archivo **`index.html`** (importante: así el servidor lo sirve por defecto). Se generarán varios archivos: `index.html`, `index.js`, `index.wasm`, `index.pck`, etc.

8. **Servir y probar el build web.** Un build web **no** funciona abriéndolo como `file://`; hay que servirlo por HTTP. Godot ofrece un botón de **remote debug/One-click** con "Run in Browser", pero para servirlo tú mismo usa Python:

```bash
# Sitúate en la carpeta del build web y levanta un servidor local
cd builds/web
python -m http.server 8060
```

Abre en el navegador <http://localhost:8060>. Si la pantalla queda en negro y la consola del navegador se queja de `SharedArrayBuffer`, es por las cabeceras: el servidor debe enviar `Cross-Origin-Opener-Policy: same-origin` y `Cross-Origin-Embedder-Policy: require-corp`. El servidor simple de Python no las envía, así que usa el botón **"Run in Browser"** del propio Godot (que sí las configura) para la prueba local, o un servidor con esas cabeceras.

9. **Preparar la publicación en itch.io.** Para subir el build web, comprime la carpeta `builds/web/` en un `.zip` (con `index.html` en la raíz del zip). En itch.io: crea un nuevo proyecto (**Create → Upload new project**), en **Kind of project** elige **HTML**, sube el `.zip`, marca **This file will be played in the browser**, ajusta el tamaño del visor y publica. Para la versión Windows, sube el `.exe` (o su `.zip`) como descarga adicional. No publiques sin revisar; deja el proyecto en modo **Draft** hasta comprobarlo.

## ✍️ Ejercicios

1. Crea un `.ico` a partir del icono del juego y verifica que el `.exe` lo muestra en el explorador de Windows.
2. Exporta una segunda versión del `.exe` **con** Export Debug y compara el comportamiento y el tamaño.
3. Cambia el color de fondo y el tamaño del canvas del build web desde las opciones del preset Web.
4. Sirve el build web en el puerto `9000` y confirma que responde en <http://localhost:9000>.
5. Investiga y anota qué cabeceras HTTP exige el build web y por qué `python -m http.server` no basta por sí solo.
6. Redacta la ficha de itch.io (título, descripción corta, controles) que acompañaría a tu juego.

## 📝 Reto verificable

Deja tu juego publicable en las dos plataformas. Exporta un `.exe` de Windows sin modo debug que arranque con doble clic y conserve el guardado entre ejecuciones, y un build web servido correctamente (con las cabeceras COOP/COEP) que sea jugable en el navegador. Documenta en un pequeño README de build los comandos usados y la URL local de prueba.

**Criterio de aceptación**: el `.exe` se ejecuta en un equipo Windows sin Godot instalado y el build web carga y es jugable en `http://localhost:<puerto>` sin errores de `SharedArrayBuffer` en la consola del navegador; ambos incluyen sonido, partículas y guardado funcionando.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| "No export template found for the selected platform" | No instalaste las plantillas. Ve a Editor → Manage Export Templates y descárgalas. |
| El `.exe` no abre o falta el `.pck` | Moviste el `.exe` sin su `.pck`. Mantenlos juntos o activa **Embed Pck** en el preset. |
| Pantalla negra en el build web y error de SharedArrayBuffer | Falta enviar cabeceras COOP/COEP. Usa "Run in Browser" de Godot o un servidor que las incluya. |
| El juego web no carga abriendo `index.html` directo | Lo abriste como `file://`. Sírvelo por HTTP con `python -m http.server`. |
| itch.io muestra "Index file not found" | El `.zip` no tiene `index.html` en su raíz. Recomprime con el archivo en el nivel superior. |
| La plantilla no coincide con la versión | Actualizaste Godot pero no las plantillas. Reinstálalas para que coincidan exactamente. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué el build web necesita un servidor y no puedo abrir el HTML?** El runtime usa WebAssembly y características como `SharedArrayBuffer` que los navegadores solo habilitan bajo `http(s)://` con ciertas cabeceras; el esquema `file://` las bloquea.

**❓ ¿El `.exe` incluye Godot dentro?** Sí: la plantilla de exportación es un runtime de Godot que se empaqueta con tu juego, por eso el usuario final no necesita instalar el motor.

**❓ ¿Mi guardado `user://` funciona en el build web?** Sí, pero se almacena en el almacenamiento del navegador (IndexedDB), no en el disco. Persiste mientras el usuario no borre los datos del sitio.

**❓ ¿Puedo publicar el mismo juego como descarga y como web en itch.io?** Sí. Sube el `.exe` (o su zip) como archivo descargable y el build web marcado como "jugable en el navegador"; ambos conviven en la misma página del proyecto.

## 🔗 Referencias

- Godot Docs — Exporting projects: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html>
- Godot Docs — Export templates: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html#export-templates>
- Godot Docs — Exporting for the Web: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html>
- Godot Docs — Exporting for Windows: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html>
- itch.io — Uploading HTML5 games: <https://itch.io/docs/creators/html5>

## ⬅️ Clase anterior

[Clase 043 - Guardado y carga de progreso](../043-guardado-y-carga-de-progreso/README.md)

## ➡️ Siguiente clase

[Clase 045 - Capstone Parte 1: un plataformas 2D completo jugable](../045-capstone-parte-1-un-plataformas-2d-completo-jugable/README.md)
