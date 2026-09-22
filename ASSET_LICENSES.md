# Registro de licencias de assets

Este registro es la fuente de verdad para gráficos, audio, música, fuentes,
modelos 3D y otros assets distribuidos en el repositorio. **La mera presencia de
un archivo no concede una licencia**: solo puede reutilizarse bajo la licencia de
su fila. Las copias bajo `inicio/` y `solucion/` son duplicados de la misma
familia.

| Activo o familia | Tipo | Rutas | Autoría/origen comprobado | Licencia | Evidencia y notas |
|---|---|---|---|---|---|
| Sprites y tiles 2D (`jugador`, `enemigo`, `moneda`, `tileset`) | Gráficos PNG | `labs/plataformas-2d/{inicio,solucion}/assets/*.png` | Vladimir Acuña / vladimiracunadev-create; generación procedural | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | `scripts/generar_assets.py`; contenido verificado por `scripts/verificar_assets.py` |
| Texturas de prueba (`silueta`, `textura_prueba`) | Gráficos PNG | `labs/shaders/{inicio,solucion}/assets/*.png` | Vladimir Acuña / vladimiracunadev-create; generación procedural | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | `scripts/generar_assets.py`; contenido verificado por `scripts/verificar_assets.py` |
| Efectos de plataforma (`salto`, `moneda`, `dano`) | Audio WAV, SFX | `labs/plataformas-2d/{inicio,solucion}/assets/*.wav` | Vladimir Acuña / vladimiracunadev-create; síntesis procedural | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | No son grabaciones ni muestras externas; `scripts/generar_assets.py` |
| Efectos 3D (`salto`, `cristal`, `portal`) | Audio WAV, SFX | `labs/3d-tercera-persona/{inicio,solucion}/assets/*.wav` | Vladimir Acuña / vladimiracunadev-create; síntesis procedural | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | No son grabaciones ni muestras externas; `scripts/generar_assets.py` |
| Icono de mando y fondo de Android | Gráficos vectoriales XML | `app/android/res/drawable/ic_*.xml`, `app/android/res/mipmap-anydpi-v26/ic_launcher.xml` | Vladimir Acuña / vladimiracunadev-create; vectores originales del repositorio | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | El lanzador adaptativo referencia los dos vectores; no contiene logos de motores |

## Categorías actualmente ausentes

| Categoría | Estado en el árbol versionado |
|---|---|
| Música | No hay pistas musicales versionadas. Los WAV registrados son efectos sintetizados, no música. |
| Fuentes | No hay archivos `.ttf`, `.otf`, `.woff` ni `.woff2`. El sitio y los generadores solicitan fuentes del sistema; no las redistribuyen. |
| Modelos 3D | No hay `.gltf`, `.glb`, `.fbx`, `.obj` ni `.blend`. Los labs 3D usan primitivas de Godot. |
| Vídeo | No hay vídeo versionado. |
| Packs o assets de terceros | No se encontraron en el árbol versionado auditado. Si se añade uno, necesita su propia fila antes de integrarse. |

`manual/MANUAL.pdf` no es un asset independiente: es una versión del contenido
educativo y se rige por [LICENSE-CONTENT.md](LICENSE-CONTENT.md). Los motores y
sus recursos no se distribuyen con el repositorio; consulta
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Regla para contribuciones futuras

Toda incorporación de arte, audio, música, fuentes, modelos o datos binarios
debe añadir o actualizar una fila con ruta, autoría, fuente, versión, licencia y
evidencia. “Gratis”, “descargado de Internet” o “incluido en el repositorio” no
son licencias. Si la procedencia no puede demostrarse, el activo no debe
distribuirse.
