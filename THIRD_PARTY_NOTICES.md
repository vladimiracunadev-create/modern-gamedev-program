# Avisos de terceros y dependencias

Este proyecto menciona y utiliza herramientas de terceros, pero no reclama su
autoría. Cada componente conserva su copyright, licencia y condiciones. Este
archivo describe el estado auditado del árbol fuente; una distribución binaria
debe incluir además los avisos que entregue cada motor o empaquetador.

## Dependencias directas del código

| Componente | Uso | Versión declarada | Licencia declarada | Incluido en Git |
|---|---|---|---|---|
| Electron | Runtime de la app Windows | `38.8.6` | MIT | No; se instala con npm |
| `@electron/packager` | Empaquetado de la app Windows | `18.4.4` | BSD-2-Clause | No; se instala con npm |
| Python-Markdown | Generación de sitio, material y manual | `>=3.6`, sin tope | BSD-3-Clause | No; se instala con pip |
| Pillow | Generación y verificación de PNG | No fijada | HPND | No; se instala con pip |

La lista exacta y reproducible del árbol npm está en
`app/windows/package-lock.json`. En la auditoría del 2026-09-22 contiene **173
entradas de paquetes**: 138 MIT, 19 ISC, 6 BSD-2-Clause, 3 BSD-3-Clause, 4
Apache-2.0, 1 CC-BY-3.0, 1 CC0-1.0 y 1 con elección MIT o CC0-1.0. No hay
entradas sin licencia declarada. Las licencias de los paquetes instalados
prevalecen sobre este resumen.

## Herramientas, motores y frameworks

| Componente | Relación con el proyecto | Términos relevantes |
|---|---|---|
| Godot Engine | Ejecuta y verifica los labs; el binario no está en el repositorio | Motor MIT de sus contribuidores, con avisos adicionales en su `COPYRIGHT.txt`; una exportación debe conservarlos. <https://godotengine.org/license/> |
| Unity | Solo se explica o compara; no se incluye | Software y marcas de Unity Technologies bajo sus propios términos. |
| Unreal Engine | Solo se explica o compara; no se incluye | Software y marcas de Epic Games bajo sus propios términos. |
| Android SDK y plataforma Android | Compilan la app Android; no están incluidos | Licencias y términos de Google y de los componentes instalados del SDK. |
| Chrome o Microsoft Edge | Renderizan PDF durante el build; no están incluidos | Términos del navegador instalado por el usuario. |
| GitHub Actions | Ejecutan CI; no se redistribuyen | `actions/checkout`, `setup-python`, `setup-node`, `upload-artifact`, `configure-pages`, `upload-pages-artifact` y `deploy-pages`, bajo sus licencias propias. |
| gitleaks y Bandit | Herramientas de CI instaladas en ejecución | gitleaks (MIT) y Bandit (Apache-2.0), bajo sus propios avisos. |

Ni la licencia MIT del código ni la licencia del contenido se extienden a estos
componentes. Tener un proyecto Godot, citar una API de Unity o mostrar una marca
en una explicación no transfiere propiedad sobre el motor, su documentación o
su marca.

## Material bibliográfico y documentación externa

`sources/bibliography.json` y los bloques “Referencias” describen libros,
artículos, normas y documentación externa. El repositorio contiene citas,
metadatos, enlaces y explicaciones originales; **no incorpora ni relicencia las
obras citadas**. Sus titulares conservan todos los derechos y licencias.

Los nombres de API, fragmentos mínimos necesarios para interoperabilidad y
enlaces se mantienen separados del material licenciado por el proyecto. Si un
archivo futuro incorpora contenido de terceros, deberá indicar junto al archivo
su fuente, copyright, licencia y modificaciones.

## Obligaciones al redistribuir binarios

Antes de publicar una app empaquetada:

1. conserva los archivos de licencia y avisos que Electron incluya en su
   distribución, incluidos los avisos de Chromium;
2. si se exporta con Godot, incorpora la licencia del motor y sus avisos de
   terceros (el `COPYRIGHT.txt` correspondiente a esa versión);
3. vuelve a generar el inventario desde el lockfile y no sustituyas las
   licencias completas de las dependencias por este resumen;
4. conserva [ASSET_LICENSES.md](ASSET_LICENSES.md) y la licencia del contenido
   que viaje dentro del paquete.

Este inventario no es asesoría legal. Ante una discrepancia, prevalecen el
archivo de licencia y los avisos distribuidos por el tercero correspondiente.
