#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Construye las **aplicaciones offline del curso** a partir del sitio generado.

  python scripts/generar_apps.py --contenido            # solo prepara el HTML
  python scripts/generar_apps.py --android              # APK
  python scripts/generar_apps.py --windows              # app de escritorio
  python scripts/generar_apps.py --todo                 # las dos + checksums

El contenido de las apps es **el mismo HTML** que se publica en GitHub Pages
(`scripts/generar_sitio.py`). No hay una segunda versión del curso que se pueda
quedar atrás: si el sitio cambia, las apps cambian.

Qué se excluye y por qué
------------------------
El manual en PDF (~36 MB) NO va dentro de las apps. Ninguna de las dos lo
mostraría bien —la WebView de Android no abre PDFs— y triplicaría el tamaño de
la descarga para algo que ya se publica como archivo suelto de la release.

Android sin Gradle
------------------
El APK se construye llamando directamente a `aapt2`, `d8`, `zipalign` y
`apksigner` del SDK. Es más código aquí, pero a cambio no hace falta Gradle, no
se descarga nada al construir y el proceso completo cabe en un archivo que se
puede leer de arriba abajo. Requisitos: un JDK y el SDK de Android.

La firma
--------
El APK se firma con un keystore que **no está en el repositorio y no debe
estarlo**. Si no le pasas uno, el script genera uno de pruebas fuera del repo y
te dice dónde. Para publicar actualizaciones que Android acepte como la misma
app, hay que conservar SIEMPRE el mismo keystore: si se pierde, los usuarios
tienen que desinstalar y volver a instalar.
"""
from __future__ import annotations

import argparse
import glob
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITIO = os.path.join(ROOT, "site")
APP = os.path.join(ROOT, "app")
DIST = os.path.join(ROOT, "dist")
CONTENIDO = os.path.join(DIST, "contenido")

VERSION = "2.0.0"
PAQUETE = "io.github.vladimiracunadev.curso"

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass


# --------------------------------------------------------------------------
# Utilidades
# --------------------------------------------------------------------------
def correr(cmd: list[str], cwd: str | None = None) -> None:
    """Ejecuta y aborta con el log si falla. Un build a medias no vale nada."""
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True,
                       encoding="utf-8", errors="replace")
    if r.returncode != 0:
        print(f"\nFALLÓ: {' '.join(cmd[:3])} ...", file=sys.stderr)
        print((r.stdout or "")[-4000:], file=sys.stderr)
        print((r.stderr or "")[-4000:], file=sys.stderr)
        raise SystemExit(1)


def jdk_exe(nombre: str) -> str:
    """Ruta a una herramienta del JDK (javac, keytool, jarsigner...).

    No basta con `shutil.which`: en Windows, el `javapath` que Oracle deja en el
    PATH solo publica java, javac, javaw y jshell — keytool no está. Se pregunta
    a la propia JVM dónde vive (`java.home`), que es la única respuesta que no
    depende de cómo esté montado el PATH.
    """
    candidatos: list[str] = []
    java_home = os.environ.get("JAVA_HOME", "")
    if java_home:
        candidatos.append(os.path.join(java_home, "bin"))

    java = shutil.which("java")
    if java:
        r = subprocess.run([java, "-XshowSettings:properties", "-version"],
                           capture_output=True, text=True, encoding="utf-8",
                           errors="replace")
        m = re.search(r"java\.home\s*=\s*(.+)", (r.stderr or "") + (r.stdout or ""))
        if m:
            candidatos.append(os.path.join(m.group(1).strip(), "bin"))

    for carpeta in candidatos:
        for sufijo in (".exe", ""):
            ruta = os.path.join(carpeta, nombre + sufijo)
            if os.path.isfile(ruta):
                return ruta

    directo = shutil.which(nombre)
    if directo:
        return directo

    print(f"No encuentro {nombre}. Instala un JDK o define JAVA_HOME.", file=sys.stderr)
    raise SystemExit(1)


def sha256(ruta: str) -> str:
    h = hashlib.sha256()
    with open(ruta, "rb") as f:
        for bloque in iter(lambda: f.read(1024 * 1024), b""):
            h.update(bloque)
    return h.hexdigest()


def tamano(ruta: str) -> str:
    b = os.path.getsize(ruta)
    return f"{b / (1024 * 1024):.1f} MB" if b >= 1024 * 1024 else f"{b / 1024:.0f} KB"


# --------------------------------------------------------------------------
# 1. Contenido
# --------------------------------------------------------------------------
def preparar_contenido() -> str:
    if not os.path.isdir(SITIO):
        print("No existe site/. Genera el sitio primero:")
        print("    python scripts/generar_sitio.py")
        raise SystemExit(1)

    if os.path.isdir(CONTENIDO):
        shutil.rmtree(CONTENIDO)
    os.makedirs(CONTENIDO, exist_ok=True)

    copiados = 0
    saltados = 0
    for cur, _dirs, archivos in os.walk(SITIO):
        rel = os.path.relpath(cur, SITIO)
        destino = CONTENIDO if rel == "." else os.path.join(CONTENIDO, rel)
        os.makedirs(destino, exist_ok=True)
        for nombre in archivos:
            if nombre.lower().endswith(".pdf"):
                saltados += 1
                continue
            shutil.copy2(os.path.join(cur, nombre), os.path.join(destino, nombre))
            copiados += 1

    # Las apps no tienen el PDF, así que el enlace del sitio llevaría a un 404.
    # Se reescribe para que apunte a la descarga, que es donde sí está.
    url_pdf = ("https://github.com/vladimiracunadev-create/"
               "modern-gamedev-program/releases/latest")
    tocados = 0
    for html in glob.glob(os.path.join(CONTENIDO, "**", "*.html"), recursive=True):
        with open(html, encoding="utf-8") as f:
            txt = f.read()
        nuevo = re.sub(r'href="((?:\.\./)*manual/MANUAL\.pdf)"', f'href="{url_pdf}"', txt)
        if nuevo != txt:
            with open(html, "w", encoding="utf-8") as f:
                f.write(nuevo)
            tocados += 1

    total = sum(os.path.getsize(os.path.join(c, n))
                for c, _d, fs in os.walk(CONTENIDO) for n in fs)
    print(f"Contenido preparado: {copiados} archivos ({total / (1024 * 1024):.1f} MB), "
          f"{saltados} PDF excluido(s), {tocados} enlace(s) al manual reapuntados.")
    return CONTENIDO


# --------------------------------------------------------------------------
# 2. Android
# --------------------------------------------------------------------------
def buscar_sdk() -> str:
    for var in ("ANDROID_HOME", "ANDROID_SDK_ROOT"):
        ruta = os.environ.get(var)
        if ruta and os.path.isdir(ruta):
            return ruta
    candidatos = [
        os.path.join(os.environ.get("LOCALAPPDATA", ""), "Android", "Sdk"),
        os.path.expanduser("~/Android/Sdk"),
        os.path.expanduser("~/Library/Android/sdk"),
        "/usr/lib/android-sdk",
    ]
    for c in candidatos:
        if c and os.path.isdir(c):
            return c
    print("No encuentro el SDK de Android. Define ANDROID_HOME.", file=sys.stderr)
    raise SystemExit(1)


def _version_tupla(nombre: str) -> tuple:
    return tuple(int(x) for x in re.findall(r"\d+", nombre)) or (0,)


def herramientas(sdk: str) -> tuple[str, str]:
    """(carpeta de build-tools más reciente, android.jar de la plataforma más alta)."""
    bts = sorted(glob.glob(os.path.join(sdk, "build-tools", "*")), key=_version_tupla)
    if not bts:
        print("El SDK no tiene build-tools instaladas.", file=sys.stderr)
        raise SystemExit(1)
    jars = sorted(glob.glob(os.path.join(sdk, "platforms", "android-*", "android.jar")),
                  key=lambda p: _version_tupla(os.path.basename(os.path.dirname(p))))
    if not jars:
        print("El SDK no tiene ninguna plataforma instalada.", file=sys.stderr)
        raise SystemExit(1)
    return bts[-1], jars[-1]


def exe(carpeta: str, nombre: str) -> str:
    for sufijo in (".exe", ".bat", ""):
        ruta = os.path.join(carpeta, nombre + sufijo)
        if os.path.isfile(ruta):
            return ruta
    print(f"No encuentro {nombre} en {carpeta}", file=sys.stderr)
    raise SystemExit(1)


def keystore_de_pruebas(ruta: str) -> None:
    if os.path.isfile(ruta):
        return
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    keytool = jdk_exe("keytool")
    print(f"Generando keystore de pruebas en {ruta}")
    correr([keytool, "-genkeypair", "-v",
            "-keystore", ruta, "-storepass", "android", "-keypass", "android",
            "-alias", "curso", "-keyalg", "RSA", "-keysize", "2048",
            "-validity", "10000",
            "-dname", "CN=Programa de Videojuegos Moderno, O=Curso abierto, C=CL"])


def construir_android(keystore: str, clave: str, alias: str, pass_clave: str) -> str:
    sdk = buscar_sdk()
    bt, android_jar = herramientas(sdk)
    print(f"SDK: {sdk}")
    print(f"build-tools: {os.path.basename(bt)} · plataforma: "
          f"{os.path.basename(os.path.dirname(android_jar))}")

    fuente = os.path.join(APP, "android")
    trabajo = os.path.join(DIST, "android-build")
    if os.path.isdir(trabajo):
        shutil.rmtree(trabajo)
    os.makedirs(trabajo)

    # -- 1. Recursos ------------------------------------------------------
    res_zip = os.path.join(trabajo, "res.zip")
    correr([exe(bt, "aapt2"), "compile", "--dir", os.path.join(fuente, "res"),
            "-o", res_zip])

    # -- 2. Enlazado: manifiesto + recursos + assets ------------------------
    # `-A` mete la carpeta de assets tal cual. Aquí es donde entra el curso.
    assets = os.path.join(trabajo, "assets")
    os.makedirs(assets)
    shutil.copytree(CONTENIDO, os.path.join(assets, "sitio"))

    base_apk = os.path.join(trabajo, "base.apk")
    correr([exe(bt, "aapt2"), "link",
            "-o", base_apk,
            "-I", android_jar,
            "--manifest", os.path.join(fuente, "AndroidManifest.xml"),
            "-R", res_zip,
            "-A", assets,
            "--min-sdk-version", "26",
            "--target-sdk-version", "35",
            "--version-code", "2000",
            "--version-name", VERSION,
            "--auto-add-overlay"])

    # -- 3. Java -> .class -> .dex ----------------------------------------
    clases = os.path.join(trabajo, "clases")
    os.makedirs(clases)
    javas = glob.glob(os.path.join(fuente, "java", "**", "*.java"), recursive=True)
    javac = jdk_exe("javac")
    # Con JDK 9+ `-bootclasspath` solo se admite con source/target 8. Es
    # exactamente lo que se quiere: bytecode 8, que es lo que d8 espera.
    correr([javac, "-nowarn", "-encoding", "UTF-8",
            "-source", "8", "-target", "8",
            "-bootclasspath", android_jar, "-classpath", android_jar,
            "-d", clases] + javas)

    dex = os.path.join(trabajo, "dex")
    os.makedirs(dex)
    clases_compiladas = glob.glob(os.path.join(clases, "**", "*.class"), recursive=True)
    correr([exe(bt, "d8"), "--lib", android_jar, "--min-api", "26",
            "--output", dex] + clases_compiladas)

    # -- 4. Meter el dex en el APK ----------------------------------------
    con_dex = os.path.join(trabajo, "con-dex.apk")
    shutil.copy2(base_apk, con_dex)
    with zipfile.ZipFile(con_dex, "a", zipfile.ZIP_DEFLATED) as z:
        for d in sorted(glob.glob(os.path.join(dex, "*.dex"))):
            z.write(d, os.path.basename(d))

    # -- 5. Alinear y firmar ----------------------------------------------
    # zipalign ANTES de firmar: alinear después invalidaría la firma.
    alineado = os.path.join(trabajo, "alineado.apk")
    correr([exe(bt, "zipalign"), "-f", "-p", "4", con_dex, alineado])

    os.makedirs(DIST, exist_ok=True)
    final = os.path.join(DIST, f"videojuegos-moderno-{VERSION}.apk")
    correr([exe(bt, "apksigner"), "sign",
            "--ks", keystore, "--ks-pass", f"pass:{clave}",
            "--ks-key-alias", alias, "--key-pass", f"pass:{pass_clave}",
            "--v1-signing-enabled", "true", "--v2-signing-enabled", "true",
            "--out", final, alineado])
    correr([exe(bt, "apksigner"), "verify", "--verbose", final])

    print(f"\nAPK: {final} ({tamano(final)})")
    return final


# --------------------------------------------------------------------------
# 3. Windows
# --------------------------------------------------------------------------
def construir_windows() -> str:
    proyecto = os.path.join(APP, "windows")
    npm = shutil.which("npm") or shutil.which("npm.cmd")
    npx = shutil.which("npx") or shutil.which("npx.cmd")
    if not npm or not npx:
        print("No encuentro npm/npx (Node.js).", file=sys.stderr)
        raise SystemExit(1)

    if not os.path.isdir(os.path.join(proyecto, "node_modules", "electron")):
        print("Instalando Electron (solo la primera vez)...")
        correr([npm, "install", "--no-audit", "--no-fund",
                "--save-dev", "electron@^38", "@electron/packager@^18"], cwd=proyecto)

    salida = os.path.join(DIST, "windows")
    if os.path.isdir(salida):
        shutil.rmtree(salida)
    os.makedirs(salida, exist_ok=True)

    # `--extra-resource` deja el curso junto al ejecutable, fuera del asar: se
    # puede abrir con cualquier navegador y se puede actualizar sin reempaquetar.
    correr([npx, "--yes", "@electron/packager", proyecto, "VideojuegosModerno",
            "--platform=win32", "--arch=x64",
            f"--app-version={VERSION}",
            "--out", salida,
            "--overwrite",
            "--prune=true",
            "--ignore=node_modules",
            f"--extra-resource={CONTENIDO}"], cwd=proyecto)

    carpeta = glob.glob(os.path.join(salida, "VideojuegosModerno-win32-x64"))
    if not carpeta:
        print("El empaquetado no produjo la carpeta esperada.", file=sys.stderr)
        raise SystemExit(1)
    carpeta = carpeta[0]

    # @electron/packager copia el recurso con el nombre de la carpeta origen;
    # la app espera 'sitio'.
    recursos = os.path.join(carpeta, "resources")
    origen = os.path.join(recursos, os.path.basename(CONTENIDO))
    destino = os.path.join(recursos, "sitio")
    if os.path.isdir(origen) and not os.path.isdir(destino):
        os.rename(origen, destino)

    os.makedirs(DIST, exist_ok=True)
    zip_final = os.path.join(DIST, f"videojuegos-moderno-{VERSION}-windows-x64.zip")
    if os.path.isfile(zip_final):
        os.remove(zip_final)
    print("Comprimiendo...")
    with zipfile.ZipFile(zip_final, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for cur, _d, archivos in os.walk(carpeta):
            for n in archivos:
                ruta = os.path.join(cur, n)
                z.write(ruta, os.path.join("VideojuegosModerno",
                                           os.path.relpath(ruta, carpeta)))

    print(f"\nWindows: {zip_final} ({tamano(zip_final)})")
    return zip_final


# --------------------------------------------------------------------------
def escribir_checksums(archivos: list[str]) -> str:
    ruta = os.path.join(DIST, "SHA256SUMS.txt")
    lineas = []
    for a in archivos:
        if os.path.isfile(a):
            lineas.append(f"{sha256(a)}  {os.path.basename(a)}")
    with open(ruta, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lineas) + "\n")
    print("\nSHA256:")
    for l in lineas:
        print("  " + l)
    return ruta


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--contenido", action="store_true", help="solo preparar el HTML")
    ap.add_argument("--android", action="store_true", help="construir el APK")
    ap.add_argument("--windows", action="store_true", help="construir la app de escritorio")
    ap.add_argument("--todo", action="store_true", help="las dos + checksums")
    ap.add_argument("--keystore", default=os.environ.get("CURSO_KEYSTORE", ""),
                    help="keystore para firmar el APK (por defecto: uno de pruebas fuera del repo)")
    ap.add_argument("--keystore-pass", default=os.environ.get("CURSO_KEYSTORE_PASS", "android"))
    ap.add_argument("--key-alias", default=os.environ.get("CURSO_KEY_ALIAS", "curso"))
    ap.add_argument("--key-pass", default=os.environ.get("CURSO_KEY_PASS", "android"))
    args = ap.parse_args()

    if not any([args.contenido, args.android, args.windows, args.todo]):
        ap.print_help()
        return 1

    preparar_contenido()
    if args.contenido and not (args.android or args.windows or args.todo):
        return 0

    generados: list[str] = []
    if args.android or args.todo:
        ks = args.keystore
        if not ks:
            # Fuera del repositorio, siempre. Un keystore versionado es un
            # secreto versionado, y aquí eso no pasa.
            ks = os.path.join(os.path.expanduser("~"), ".curso-gamedev", "firma.jks")
            keystore_de_pruebas(ks)
            print(f"\n  Firmando con el keystore de pruebas: {ks}")
            print("  GUÁRDALO: sin él no podrás publicar actualizaciones de la app.")
        generados.append(construir_android(ks, args.keystore_pass,
                                           args.key_alias, args.key_pass))

    if args.windows or args.todo:
        generados.append(construir_windows())

    if args.todo and generados:
        escribir_checksums(generados)

    print("\nListo.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
