# Auditoría de licencias

**Fecha:** 2026-09-22

**Repositorio:** `vladimiracunadev-create/modern-gamedev-program`

**Alcance:** árbol Git, historial completo local, dependencias declaradas,
binarios versionados, documentación y salidas generadas.

## Resultado ejecutivo

La licencia MIT única no distinguía código, currículo, assets ni terceros. Se
reemplazó esa ambigüedad por una matriz de alcance: código MIT; contenido
educativo CC BY-NC-SA 4.0; cinco familias de assets propios bajo CC0; y avisos
separados para dependencias, motores, bibliografía y marcas. La concesión MIT
histórica se documentó y se preservó expresamente.

No se hallaron contribuidores independientes, fuentes tipográficas, música,
modelos 3D ni packs de terceros en el árbol versionado. Sí se hallaron 12 PNG,
12 WAV y un PDF. Los 24 assets audiovisuales se reproducen desde código propio;
el PDF es una salida del contenido educativo, no un asset con licencia separada.

## Hallazgos y resolución

| ID | Hallazgo | Riesgo previo | Resolución |
|---|---|---|---|
| L-01 | `LICENSE` MIT parecía abarcar todo el repositorio | No distinguía código de contenido | MIT acotada a código; `LICENSE-CONTENT.md` para contenido |
| L-02 | README prometía MIT para todo | Permitía interpretar uso comercial de todo el currículo actual | Tabla clara de permisos y límites; se conservó el MIT histórico |
| L-03 | Assets descritos globalmente como CC0 sin registro por familia | Difícil auditar audio y gráficos por separado | `ASSET_LICENSES.md` con una fila por familia y evidencia |
| L-04 | Audio se trataba como asset genérico | Podía asumirse licencia por mera presencia | WAV identificados como SFX sintetizados CC0; regla explícita contra presunciones |
| L-05 | Sin inventario de fuentes, música o modelos | Ausencia no documentada | Categorías ausentes declaradas y verificables |
| L-06 | Dependencias solo visibles en workflows, imports y lockfile | Avisos incompletos en redistribuciones | `THIRD_PARTY_NOTICES.md` y obligaciones para binarios |
| L-07 | Motores y marcas aparecían junto al material propio | Posible apariencia de titularidad o respaldo | Exclusiones expresas y `TRADEMARKS.md` |
| L-08 | Dos variantes de nombre en Git | Autoría inconsistente | Nombre público normalizado sin reescribir historia |
| L-09 | Manual generado decía “Licencia MIT” | Contradecía el nuevo alcance | Generador actualizado a CC BY-NC-SA 4.0 y código MIT |
| L-10 | Sitio no publicaba documentos de licencia | Información incompleta fuera de GitHub | Documentos de licencia añadidos al build del sitio |

## Matriz de alcance actual

| Categoría obligatoria | Tratamiento | Fuente de verdad |
|---|---|---|
| 1. Código | MIT | `LICENSE` |
| 2. Contenido educativo | CC BY-NC-SA 4.0 | `LICENSE-CONTENT.md` |
| 3. Gráficos | CC0 por familia | `ASSET_LICENSES.md` |
| 4. Audio | CC0 por familia; nunca por presencia implícita | `ASSET_LICENSES.md` |
| 5. Música | No hay archivos versionados | `ASSET_LICENSES.md` |
| 6. Fuentes | No se redistribuyen archivos de fuente | `ASSET_LICENSES.md` |
| 7. Modelos 3D | No hay modelos versionados | `ASSET_LICENSES.md` |
| 8. Assets | Registro por activo o familia | `ASSET_LICENSES.md` |
| 9. Motores/frameworks | Terceros, no incluidos ni relicenciados | `THIRD_PARTY_NOTICES.md` |
| 10. Material de terceros | Citas/metadatos o dependencias bajo términos propios | `THIRD_PARTY_NOTICES.md` |

## Historial y contribuyentes

El historial auditado contiene 32 atribuciones de commit, todas con el mismo
correo: 28 como `Vladimir Acuña` y 4 merges como `Vladimir Acuña Valdebenito
DEV`. No se observó evidencia Git de otro titular al que hubiera que solicitar
consentimiento para la nueva licencia de contribuciones futuras. Esto no permite
atribuirse obras externas: por eso bibliografía, motores, dependencias y marcas
quedan excluidos.

El límite histórico y los hashes verificables están en
`docs/LICENSING_HISTORY.md`.

## Dependencias

El único manifest de paquete es `app/windows/package.json`, con dos dependencias
de desarrollo directas. El lockfile declara 173 entradas y ninguna carece de
identificador de licencia. Los scripts Python también requieren
Python-Markdown y Pillow; CI incorpora herramientas y GitHub Actions. No existe
un archivo de requisitos Python fijado, por lo que los avisos registran el rango
o la ausencia de pin sin inventar una versión.

## Límites de la auditoría

La auditoría prueba lo que está versionado y lo que declara el lockfile. No
certifica derechos sobre archivos ignorados locales (`dist/`, `site/`,
`material/`, `node_modules/`), descargas futuras ni entregables que un alumno
añada. Toda release binaria debe repetir el inventario sobre sus componentes
reales e incorporar los textos completos exigidos por Electron, Chromium, Godot
y las dependencias que efectivamente distribuya.

## Verificación exigida en adelante

- actualizar `ASSET_LICENSES.md` antes de aceptar un asset nuevo;
- mantener lockfiles e inventarios de terceros sincronizados;
- conservar el bloque de licencias del README, el sitio y el manual;
- ejecutar `python scripts/verificar_todo.py --rapido` y, cuando haya Godot 4.3,
  la suite completa con `--godot`;
- revisar historial y procedencia antes de cualquier relicenciamiento futuro.
