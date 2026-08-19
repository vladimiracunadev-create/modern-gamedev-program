# Registro de fuentes

Este directorio contiene el aparato que hace comprobable lo que el programa
afirma. No es una bibliografía decorativa: es el índice único contra el que se
verifica cada cita de cada clase, y una CI que bloquea si deja de cuadrar.

| Fichero | Qué es |
|---|---|
| [`bibliography.json`](bibliography.json) | El registro. Una entrada por obra, con localizador resoluble. |
| [`refresh-report.md`](refresh-report.md) | Última salida de `scripts/refresh-sources`: qué resolvió y qué no. Lo genera la máquina. |

## Por qué existe

El programa se apoya en 207 obras y cita a la documentación de Godot en 275 de
sus 352 clases. Antes de este registro, esas citas apuntaban a `/en/stable`, un
alias que **se mueve solo**: cuando se hizo esta medición, `stable` ya servía la
rama 4.7, mientras la CI de laboratorios compila con **4.3**. El programa
enseñaba una versión y enlazaba a otra, y nada lo detectaba.

Anclar la versión, además, sacó a la luz **16 enlaces de Godot que estaban rotos**
—14 de ellos ya devolvían 404 en `stable`, no solo en 4.3— y otros 18 fuera de
Godot. Todos están corregidos con un destino comprobado por HTTP, o marcados.

## Las dos capas

Son dos a propósito, y **no se mezclan**. Si la red entra en un gate que
bloquea, el gate empieza a fallar por causas ajenas al repositorio y se acaba
ignorando.

### `scripts/verify-sources` — offline, determinista, bloquea en CI

```bash
python scripts/verify-sources
```

Cero peticiones de red. Comprueba:

1. el registro parsea y cumple el esquema;
2. todo `book` lleva ISBN-13 con dígito de control válido; todo `paper`, DOI;
3. el `locator` tiene la forma canónica de su tipo;
4. toda fuente citada en una clase existe en el registro;
5. ninguna entrada del registro sobra, y su `used_in` coincide con el recuento real;
6. ningún bloque de fuentes se repite entre clases;
7. los enlaces al motor y a la suite usan la versión anclada;
8. cada cita declara el uso que su clase hace de ella;
9. las cifras del README las produjo este script.

`python scripts/verify-sources --write` regenera el bloque del README. Las
cifras **no se escriben a mano**: si alguien las toca, el paso 9 falla.

### `scripts/refresh-sources` — en red, manual o mensual, **no** bloquea

```bash
python scripts/refresh-sources            # comprueba y actualiza el registro
python scripts/refresh-sources --dry-run  # solo informa
```

Resuelve cada ISBN contra `openlibrary.org` y cada DOI contra
`api.crossref.org` comparando título y autoría, hace un GET a cada URL de norma
o documentación, y escribe `refresh-report.md`. Reintenta lo transitorio antes
de dar nada por caído, y distingue tres cosas que no son lo mismo:

- **dejó de resolver** → la entrada pasa a `pendiente` con su motivo;
- **el servidor rechaza clientes automáticos** (401/403) → se anota aparte y la
  entrada se deja como estaba: un 403 no es prueba de que la fuente esté rota;
- **los metadatos no casan** con lo que dice la autoridad → se lista para
  revisar a mano.

Lo corre [`.github/workflows/sources.yml`](../.github/workflows/sources.yml) el
día 1 de cada mes, y a demanda. **Nunca borra una entrada.**

## Cómo añadir una fuente

1. Cita la obra en el bloque `## 🔗 Referencias` de la clase, terminando con
   `· uso: <etiqueta>` (las etiquetas válidas están en `usage_vocabulary`
   dentro del registro).
2. Añade la entrada a `bibliography.json`:
   - **libro** → `isbn13` con dígito de control válido y
     `locator: https://openlibrary.org/isbn/{isbn13}`;
   - **artículo** → `doi` y `locator: https://doi.org/{doi}`;
   - **norma o documentación oficial** → `locator` https de la fuente primaria
     y `accessed`.
3. Declara en `match.urls` los prefijos de URL con los que se cita, o en
   `match.works` el fragmento de texto si la obra se cita sin enlace.
4. Deja `used_in` como esté y ejecuta `python scripts/verify-sources`: te dirá
   el valor real. Ese campo lo manda el recuento, no el criterio de nadie.
5. Regenera el README: `python scripts/verify-sources --write`.

### Lo que no se hace nunca

- **Inventar** un ISBN, un DOI, una URL o una fecha. Lo que no se resuelve va
  con `"status": "pendiente"` y su `pending_reason`.
- **Borrar** una fuente que no resuelve. Se marca; la cita se conserva.
- Escribir a mano las cifras del README.

Un hueco declarado es información. Un hueco rellenado por intuición es una
invención con formato de bibliografía.

## Versiones ancladas

`pinned_versions` fija la versión de la documentación viva:

| Herramienta | Versión | Por qué esa |
|---|---|---|
| Godot | **4.3** | Es la que descarga, importa y ejecuta `.github/workflows/labs.yml`. |
| Blender | **4.2 LTS** | LTS contemporánea del Godot anclado, para que el par sea coherente. |

Cuando se suba la versión del motor, se sube aquí, se remapean los enlaces y
`verify-sources` comprueba que no quedó ninguno en la versión vieja.
