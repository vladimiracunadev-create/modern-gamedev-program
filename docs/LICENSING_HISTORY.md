# Historial de licencias

Este documento conserva la trazabilidad de las concesiones del repositorio. Una
licencia ya otorgada no se retira de las copias que la recibieron.

## 2026-07-13 — concesión MIT original

El commit inicial `59236dc918e2d14438f7619c5d0798a44cbabbd2` publicó el
repositorio con una licencia MIT raíz, copyright 2026 Vladimir Acuña. El texto
autorizaba el uso, copia, modificación, publicación, distribución, sublicencia y
venta del “software y documentación asociada”.

Todos los commits auditados usan el correo `vladimir.acuna.dev@gmail.com` y uno
de estos nombres:

- `Vladimir Acuña`;
- `Vladimir Acuña Valdebenito DEV` (commits de merge).

No se encontraron commits atribuidos a otra identidad. Desde esta reorganización
la forma pública normalizada es **Vladimir Acuña / vladimiracunadev-create**. No
se reescribe el historial Git, para preservar su integridad.

## 2026-09-22 — separación por tipo de obra

El último snapshot anterior a la reorganización es
`c49c06b0ec62546bc51777e2fe1ed5585d21ed3e`. Ese snapshot y cualquier copia
obtenida bajo la concesión MIT anterior conservan esos permisos ya concedidos;
la nueva estructura **no los revoca ni los convierte retroactivamente**.

A partir del commit que introduce este documento, las contribuciones nuevas se
publican por alcance:

| Categoría | Licencia o tratamiento |
|---|---|
| Código y configuración propios | MIT (`LICENSE`) |
| Currículo, clases, explicaciones, retos y metodología | CC BY-NC-SA 4.0 (`LICENSE-CONTENT.md`) |
| Fragmentos de código en documentos | MIT, además de la licencia de la prosa |
| Gráficos, audio y demás assets | Licencia específica por fila (`ASSET_LICENSES.md`) |
| Dependencias, motores y material de terceros | No relicenciados (`THIRD_PARTY_NOTICES.md`) |
| Marcas | No licenciadas (`TRADEMARKS.md`) |

Cuando un material actual sea idéntico a una versión publicada antes de este
cambio, sigue disponible bajo la concesión MIT que recibió entonces.
Las versiones posteriores que incorporen cambios quedan disponibles conforme a
la licencia indicada por su categoría, sin afectar derechos previos.

## Evidencia revisada

- `git log --all` y `git shortlog -sne --all` para autoría y contribuciones;
- primer commit y versión histórica de `LICENSE`;
- commits de incorporación de cada binario versionado;
- reproducción de gráficos y audio con `scripts/generar_assets.py` y
  `scripts/verificar_assets.py`;
- `app/windows/package-lock.json` para dependencias npm;
- inventario del árbol Git por extensiones para fuentes, modelos, música y
  otros binarios.

Este registro describe evidencia del repositorio y no sustituye asesoría legal.
