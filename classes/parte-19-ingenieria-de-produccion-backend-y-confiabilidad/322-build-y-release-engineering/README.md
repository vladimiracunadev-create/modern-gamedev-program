# Clase 322 — Build y release engineering

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *Semantic Versioning 2.0.0 · Documentación de GitHub Actions y de exportación de Godot 4*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Convertir "exportar el juego" en un **proceso de ingeniería**: versionado con significado, builds reproducibles, matriz de plataformas, artefactos con checksum, firma, símbolos archivados y canales de distribución (dev, alpha, beta, producción). La [clase 261](../../parte-15-herramientas-editores-y-automatizacion/261-automatizacion-de-builds-y-exportacion-por-cli/README.md) enseñó a exportar por línea de comandos; esta clase convierte ese comando en una cadena de publicación de la que puedes fiarte.

La pregunta que hay que poder responder en cualquier momento es: **"un jugador reporta un crash en la 1.4.2; ¿de qué commit salió esa build, con qué símbolos se lee su pila y cómo la reproduzco?"**. Si la respuesta no es inmediata, el problema no es el crash: es la cadena de release.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Aplicar versionado semántico y decidir qué número sube en cada cambio.
2. Incrustar versión, commit y fecha en la build y exponerlos en el juego.
3. Diseñar una matriz de build multiplataforma en CI.
4. Producir artefactos con checksum y manifiesto verificable.
5. Explicar qué es una build reproducible y qué la rompe.
6. Archivar símbolos por versión y relacionarlos con los crash reports.
7. Diseñar canales de distribución con promoción entre ellos.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Versionado semántico | Comunica el impacto de un cambio sin leer el changelog. |
| 2 | Versión en el binario | Sin ella, un informe de crash no se puede situar. |
| 3 | Trazabilidad build↔commit | Es lo que permite reproducir un fallo. |
| 4 | Matriz de build | Varias plataformas, un solo proceso. |
| 5 | Artefacto y manifiesto | Lo que se publica debe poder verificarse. |
| 6 | Checksum | Detecta corrupción y descargas incompletas. |
| 7 | Firma | Lo que evita avisos del sistema y suplantaciones. |
| 8 | Símbolos | Sin ellos los crashes son ilegibles. |
| 9 | Canales | Separan a quien quiere estabilidad de quien quiere novedades. |
| 10 | Promoción | Un artefacto se promociona, no se reconstruye. |

## 📖 Definiciones y características

- **Versionado semántico (SemVer)**: `MAYOR.MENOR.PARCHE` con reglas sobre cuándo sube cada uno. Clave: comunica compatibilidad, no cantidad de trabajo.
- **Versión de build**: número incremental de compilación, distinto de la versión pública. Clave: identifica el artefacto exacto.
- **Build reproducible**: la que, con las mismas entradas, produce bytes idénticos. Clave: permite verificar que un binario viene del código que dice.
- **No determinismo de build**: marcas de tiempo, rutas absolutas, orden de archivos, aleatoriedad. Clave: son las causas habituales de que dos builds difieran.
- **Matriz de build**: combinación de plataformas, arquitecturas y configuraciones. Clave: un solo workflow produce todas.
- **Artefacto**: fichero publicable resultante del build. Clave: es inmutable; si hay que cambiarlo, es otro artefacto.
- **Manifiesto de release**: documento con versión, commit, artefactos, checksums y fecha. Clave: es la fuente de verdad de qué se publicó.
- **Checksum (SHA-256)**: huella del contenido. Clave: detecta corrupción y permite verificar descargas.
- **Firma de código**: prueba criptográfica de quién construyó el binario. Clave: la exigen las plataformas y evita avisos de seguridad.
- **Notarización**: verificación adicional de la plataforma (macOS). Clave: sin ella, el sistema bloquea la ejecución.
- **Símbolos de depuración**: información para traducir direcciones a funciones y líneas. Clave: se archivan por versión y no se distribuyen.
- **Canal (rama de distribución)**: vía por la que llega una build a un público (`dev`, `alpha`, `beta`, `production`). Clave: cada uno con su público y su ritmo.
- **Promoción**: mover **el mismo artefacto** de un canal al siguiente. Clave: reconstruir para promocionar destruye la trazabilidad.
- **Changelog**: registro legible de cambios por versión. Clave: es para las personas; el commit log es para las máquinas.
- **Congelación (code freeze)**: periodo sin cambios salvo correcciones críticas. Clave: da estabilidad a la validación previa a publicar.
- **Rama de release**: rama desde la que se construye una versión. Clave: permite corregir sin arrastrar lo que está a medias.

## 🧰 Herramientas y preparación

Godot 4.x con plantillas de exportación, GitHub Actions y Python para los scripts. Trabajaremos en `.github/workflows/release.yml` y `scripts/release/`. Documentación: [exportación desde CLI en Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html), [SemVer 2.0.0](https://semver.org/) y [GitHub Actions](https://docs.github.com/actions). Si tu repositorio ya tiene CI (Parte 15), esta clase la amplía; no la sustituye.

## 🧪 Laboratorio guiado

1. **Versionado con criterio.** Y la parte incómoda: en juegos, "compatibilidad" significa varias cosas:

| Cambio | Sube | Por qué |
|---|---|---|
| Corregir un bug sin cambiar comportamiento | PARCHE | 1.4.1 → 1.4.2 |
| Añadir contenido o una función | MENOR | 1.4.2 → 1.5.0 |
| Cambio que **rompe saves antiguos** | MAYOR | 1.5.0 → 2.0.0 |
| Cambio que **rompe mods** (API) | MAYOR | Ver clase 309 |
| Cambio que rompe el protocolo de red | MAYOR | Clientes viejos no podrán jugar |
| Rebalanceo de números por remote config | Ninguno | No es una build |

Esa fila del save es la que sorprende: si subes `SAVE_VERSION` sin migración, has roto la compatibilidad y eso es un cambio mayor. Con migración ([clase 307](../../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/307-save-system-de-produccion/README.md)), es menor.

2. **La versión, dentro del binario.** Generada en el build, no escrita a mano:

```python
#!/usr/bin/env python3
"""Escribe la información de versión en el proyecto antes de exportar."""
import json, os, subprocess, sys, datetime

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def git(*args):
    return subprocess.check_output(["git", *args], cwd=RAIZ, text=True).strip()

def main():
    version = sys.argv[1] if len(sys.argv) > 1 else "0.0.0-dev"
    info = {
        "version": version,
        "commit": git("rev-parse", "HEAD"),
        "commit_corto": git("rev-parse", "--short", "HEAD"),
        "rama": git("rev-parse", "--abbrev-ref", "HEAD"),
        # SOURCE_DATE_EPOCH: si está definida, se usa esa fecha en vez de "ahora".
        # Es lo que permite que dos builds del mismo commit sean idénticas.
        "fecha": datetime.datetime.fromtimestamp(
            int(os.environ.get("SOURCE_DATE_EPOCH", 0)) or
            int(git("log", "-1", "--format=%ct")),
            datetime.timezone.utc).isoformat(),
        "sucio": bool(git("status", "--porcelain")),
    }
    if info["sucio"]:
        print("::warning::el árbol de trabajo tiene cambios sin commitear")

    destino = os.path.join(RAIZ, "version.json")
    with open(destino, "w", encoding="utf-8", newline="\n") as f:
        json.dump(info, f, ensure_ascii=False, indent=2, sort_keys=True)
        f.write("\n")
    print(f"version.json: {info['version']} ({info['commit_corto']})")
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

```gdscript
# Y en el juego, accesible desde cualquier sitio y visible para el jugador.
class_name Version
extends RefCounted

static var _info := {}

static func info() -> Dictionary:
	if _info.is_empty():
		var f := FileAccess.open("res://version.json", FileAccess.READ)
		_info = JSON.parse_string(f.get_as_text()) if f else {"version": "desconocida"}
	return _info

static func cadena() -> String:
	# Esta cadena va en el menú, en los crash reports y en la telemetría. Es lo
	# que convierte "me falla el juego" en algo investigable.
	return "%s (%s)" % [info().get("version", "?"), info().get("commit_corto", "?")]
```

3. **La matriz de build.** Un workflow, todas las plataformas:

```yaml
name: Release

on:
  push:
    tags: ["v*"]
  workflow_dispatch:
    inputs:
      version: { description: "Versión (ej. 1.4.2)", required: true }

permissions:
  contents: write

env:
  GODOT_VERSION: "4.3"

jobs:
  construir:
    name: ${{ matrix.plataforma }}
    runs-on: ${{ matrix.runner }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - plataforma: windows
            runner: ubuntu-latest
            preset: "Windows Desktop"
            salida: "juego.exe"
          - plataforma: linux
            runner: ubuntu-latest
            preset: "Linux/X11"
            salida: "juego.x86_64"
          - plataforma: web
            runner: ubuntu-latest
            preset: "Web"
            salida: "index.html"
    steps:
      - uses: actions/checkout@v5
        with: { fetch-depth: 0, lfs: true }

      - name: Determinar versión
        id: v
        run: |
          set -euo pipefail
          VER="${{ github.event.inputs.version }}"
          [ -z "$VER" ] && VER="${GITHUB_REF_NAME#v}"
          echo "version=$VER" >> "$GITHUB_OUTPUT"

      - name: Sellar versión
        run: |
          # Fecha del commit, no la de ahora: es la mitad de la reproducibilidad.
          export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)
          python scripts/release/sellar_version.py "${{ steps.v.outputs.version }}"

      - name: Instalar Godot y plantillas
        run: bash scripts/release/instalar_godot.sh "$GODOT_VERSION"

      - name: Exportar
        run: |
          set -euo pipefail
          mkdir -p build/${{ matrix.plataforma }}
          godot --headless --export-release "${{ matrix.preset }}" \
                "build/${{ matrix.plataforma }}/${{ matrix.salida }}"

      - name: Presupuestos de tamaño
        run: python scripts/presupuestos_tamano.py

      - name: Checksums y manifiesto
        run: python scripts/release/manifiesto.py "${{ matrix.plataforma }}" "${{ steps.v.outputs.version }}"

      - uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.plataforma }}-${{ steps.v.outputs.version }}
          path: build/${{ matrix.plataforma }}
          retention-days: 90
```

4. **El manifiesto.** Lo que hace verificable un artefacto:

```python
#!/usr/bin/env python3
"""Genera checksums y manifiesto de una build."""
import hashlib, json, os, sys, datetime

def sha256(ruta):
    h = hashlib.sha256()
    with open(ruta, "rb") as f:
        for bloque in iter(lambda: f.read(1 << 20), b""):
            h.update(bloque)
    return h.hexdigest()

def main():
    plataforma, version = sys.argv[1], sys.argv[2]
    carpeta = os.path.join("build", plataforma)
    info = json.load(open("version.json", encoding="utf-8"))

    archivos = []
    for cur, _, ficheros in os.walk(carpeta):
        for f in sorted(ficheros):          # orden estable: el manifiesto también es reproducible
            if f == "manifiesto.json":
                continue
            ruta = os.path.join(cur, f)
            archivos.append({
                "ruta": os.path.relpath(ruta, carpeta).replace("\\", "/"),
                "bytes": os.path.getsize(ruta),
                "sha256": sha256(ruta),
            })

    manifiesto = {
        "version": version,
        "plataforma": plataforma,
        "commit": info["commit"],
        "fecha": info["fecha"],
        "godot": os.environ.get("GODOT_VERSION", ""),
        "archivos": archivos,
        "bytes_total": sum(a["bytes"] for a in archivos),
    }
    destino = os.path.join(carpeta, "manifiesto.json")
    with open(destino, "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifiesto, f, ensure_ascii=False, indent=2, sort_keys=True)
        f.write("\n")
    print(f"{plataforma}: {len(archivos)} archivo(s), "
          f"{manifiesto['bytes_total'] / 1048576:.1f} MB")
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

5. **Builds reproducibles.** Qué las rompe, y qué hacer con cada cosa:

| Causa | Efecto | Solución |
|---|---|---|
| Marca de tiempo del build | Bytes distintos cada vez | `SOURCE_DATE_EPOCH` con la fecha del commit |
| Rutas absolutas incrustadas | Difiere entre máquinas | Rutas relativas; construir en ruta fija |
| Orden del sistema de archivos | Orden de recursos distinto | Ordenar explícitamente antes de empaquetar |
| Versión de Godot o plantillas | Todo distinto | Fijar versión exacta en el workflow |
| Contenido generado con RNG | Assets distintos | Semilla fija en los generadores |
| Locale de la máquina | Ordenación de cadenas distinta | Fijar `LC_ALL=C` |

Reproducibilidad total es difícil; lo que sí es alcanzable y ya vale mucho: **dos builds del mismo commit deben tener el mismo tamaño y los mismos assets**. Compara manifiestos, y si los checksums no coinciden, investiga cuál de las filas de arriba es.

6. **Firma y símbolos.** Los dos pasos que se descubren tarde:

```yaml
      - name: Firmar (Windows)
        if: matrix.plataforma == 'windows'
        env:
          CERT_PFX_BASE64: ${{ secrets.CERT_PFX_BASE64 }}
          CERT_PASS: ${{ secrets.CERT_PASS }}
        run: |
          # Los secretos NUNCA se imprimen ni se escriben en el log, y el
          # certificado se borra al terminar el job.
          if [ -z "${CERT_PFX_BASE64:-}" ]; then
            echo "::warning::sin certificado: se publica sin firmar (solo para pruebas)"
            exit 0
          fi
          echo "$CERT_PFX_BASE64" | base64 -d > /tmp/cert.pfx
          osslsigncode sign -pkcs12 /tmp/cert.pfx -pass "$CERT_PASS" \
            -n "Mi Juego" -i "https://mijuego.example" \
            -in build/windows/juego.exe -out build/windows/juego-firmado.exe
          mv build/windows/juego-firmado.exe build/windows/juego.exe
          rm -f /tmp/cert.pfx

      - name: Archivar símbolos
        uses: actions/upload-artifact@v4
        with:
          # Los símbolos se guardan APARTE y no se publican con el juego. Sin
          # ellos, los crashes de esta versión no se pueden leer nunca más.
          name: simbolos-${{ matrix.plataforma }}-${{ steps.v.outputs.version }}
          path: |
            build/${{ matrix.plataforma }}/**/*.pdb
            build/${{ matrix.plataforma }}/**/*.debug
            version.json
          retention-days: 365
```

7. **Los canales y la promoción.** El artefacto **no se reconstruye**:

```text
   main ──► dev        cada push · equipo · sin firmar · símbolos sí
             │
             ▼ promoción (mismo artefacto)
           alpha       semanal · testers internos
             │
             ▼ promoción
           beta        quincenal · público opt-in · notas de versión
             │
             ▼ promoción
        production     cuando procede · todos · rollout gradual (clase 323)
```

```python
def promocionar(version, origen, destino):
    """Mueve el MISMO artefacto de canal. No reconstruye: si reconstruyera,
    lo que se prueba en beta no sería lo que llega a producción."""
    manifiesto = descargar_manifiesto(version, origen)
    artefacto = descargar_artefacto(version, origen)
    if sha256(artefacto) != manifiesto["archivos"][0]["sha256"]:
        raise RuntimeError("el artefacto no coincide con su manifiesto")
    publicar(artefacto, manifiesto, canal=destino)
    registrar_promocion(version, origen, destino, quien=os.environ["GITHUB_ACTOR"])
```

8. **La lista de comprobación de release.** Automatizable casi entera:

```markdown
- [ ] CI en verde en el commit exacto del tag
- [ ] Presupuestos de rendimiento y de tamaño dentro de límite (clase 321)
- [ ] `SAVE_VERSION` con su migración si cambió (clase 307)
- [ ] Versión de API de mods revisada si cambió (clase 309)
- [ ] Changelog actualizado y legible
- [ ] Manifiesto con checksums generado para cada plataforma
- [ ] Binarios firmados (y notarizados donde aplique)
- [ ] Símbolos archivados y asociados a la versión
- [ ] Feature flags de la versión en su estado correcto (clase 315)
- [ ] Plan de rollback escrito y probado (clase 323)
```

## ✍️ Ejercicios

1. Añade `version.json` a tu proyecto y muéstralo en el menú principal y en el crash report.
2. Construye dos veces el mismo commit y compara los manifiestos: identifica qué difiere y por qué.
3. Añade una plataforma más a la matriz de build.
4. Escribe un script que verifique un artefacto descargado contra su manifiesto.
5. Implementa la promoción entre canales sin reconstruir y registra quién la hizo.
6. Genera el changelog automáticamente a partir de los mensajes de commit desde el último tag.
7. Documenta qué cambio de tu juego obligaría a subir la versión mayor y por qué.

## 📝 Reto verificable

Implementa una cadena de release completa: sellado de versión desde git, matriz de build de **al menos dos plataformas**, presupuestos de tamaño integrados, manifiesto con checksums, archivado de símbolos, canales con promoción sin reconstruir y lista de comprobación automatizada.

**Criterio de aceptación**: (a) la build incrusta versión, commit y fecha, y el juego los muestra; (b) construir dos veces el mismo commit produce manifiestos con **el mismo número de archivos y el mismo tamaño total**, y las diferencias de checksum (si las hay) se explican en el README con su causa concreta; (c) el manifiesto permite verificar cualquier artefacto descargado con un script; (d) los símbolos se archivan con retención de un año y quedan asociados a la versión; (e) promocionar de beta a producción publica **el mismo fichero** (mismo SHA-256), comprobable; (f) el workflow falla si los presupuestos de tamaño se superan; (g) ningún secreto aparece en los logs del workflow.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Un crash report llega y no se sabe de qué build es | La versión no está en el binario. Séllala en el build. |
| Los símbolos de la versión que falla ya no existen | No se archivaron. Sube símbolos como artefacto con retención larga. |
| Lo que se probó en beta no es lo que salió | Se reconstruyó al promocionar. Promociona el artefacto, no el código. |
| Windows avisa de "editor desconocido" | Binario sin firmar. Firma con un certificado de código. |
| macOS bloquea el juego | Falta notarización. Es un paso aparte de la firma. |
| Dos builds del mismo commit difieren | Marcas de tiempo o rutas absolutas. `SOURCE_DATE_EPOCH` y rutas relativas. |
| El tag se creó del commit equivocado | Proceso manual. Construye siempre desde el tag, nunca desde local. |
| Un secreto apareció en el log | Se hizo `echo` de una variable. Nunca imprimas secretos; usa máscaras. |
| La versión se sube a mano y se olvida | Deriva del tag y falla el build si no coinciden. |

## ❓ Preguntas frecuentes

**❓ ¿SemVer tiene sentido en un juego?** Adaptado, sí. La clave es definir qué significa "romper compatibilidad" en tu caso: **saves**, **mods** y **protocolo de red**. Si un cambio rompe cualquiera de los tres para los usuarios existentes, es un cambio mayor aunque el juego se vea igual.

**❓ ¿Merece la pena perseguir builds reproducibles?** La reproducibilidad **total** (bit a bit) es cara y rara vez necesaria en juegos. La reproducibilidad **práctica** —mismo commit, mismo contenido, mismo tamaño— es barata y te da lo importante: poder afirmar que el binario publicado sale del código que dices.

**❓ ¿Puedo publicar sin firmar?** Puedes en itch.io y en distribución directa, y tus jugadores verán avisos del sistema. En las tiendas grandes es obligatorio. El certificado cuesta dinero, y es un gasto que hay que prever en el presupuesto de lanzamiento ([clase 273](../../parte-16-produccion-publicacion-monetizacion-y-liveops/273-presupuesto-contratos-y-aspectos-legales/README.md)).

**❓ ¿Cuántos canales necesito?** Con `dev` y `production` puedes vivir. `beta` aparece en cuanto tengas jugadores dispuestos a probar cosas a cambio de verlas antes, y es de las herramientas más rentables que existen: te da señal real con público real antes de la publicación.

**❓ ¿Dónde guardo los secretos de firma?** En los secretos del sistema de CI, nunca en el repositorio ni en el proyecto. Y con acceso restringido: si cualquiera puede lanzar el workflow de release, cualquiera puede firmar con tu certificado.

## 🔗 Referencias

- Semantic Versioning 2.0.0: <https://semver.org/>
- Godot Docs — Exportar proyectos y exportación desde CLI: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html>
- GitHub Docs — Actions, matrices y artefactos: <https://docs.github.com/actions>
- Reproducible Builds — guía y causas de no determinismo: <https://reproducible-builds.org/docs/>
- Keep a Changelog — formato de changelog legible: <https://keepachangelog.com/>

## ⬅️ Clase anterior

[Clase 321 - Performance regression testing](../321-performance-regression-testing/README.md)

## ➡️ Siguiente clase

[Clase 323 - Parches, delivery y recuperación](../323-parches-delivery-y-recuperacion/README.md)
