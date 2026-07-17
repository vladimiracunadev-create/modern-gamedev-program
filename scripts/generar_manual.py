#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Arma el **manual completo del curso en un solo PDF**: las 292 clases, en orden,
listas para leer de corrido, imprimir o llevar offline.

El curso ya se lee clase a clase (en el repo o en el sitio web). Esto es lo otro:
un único documento con todo seguido. Sale en blanco y negro, denso y sin partir
los bloques de código entre páginas, con el mismo estilo imprimible que las
guías por clase.

El PDF NO se versiona (son ~300 páginas y se regenera solo): se crea bajo demanda
en `material/`, que está en .gitignore. Se refresca cuando quieras con el comando
de abajo.

Cómo trata cada clase al meterla en el manual
---------------------------------------------
* Le quita la navegación «⬅️ anterior / ➡️ siguiente»: en un libro se pasa página.
* Baja un nivel los títulos (la clase pasa de `#` a `##`) para que quede bajo el
  título de su parte sin romper la jerarquía.
* Convierte los enlaces internos en texto normal: en papel un enlace relativo no
  lleva a ningún sitio. Los enlaces http se conservan con su URL visible.

Uso:  python scripts/generar_manual.py            # material/MANUAL-COMPLETO.pdf
      python scripts/generar_manual.py --html      # solo el HTML intermedio (rápido)
Requiere: pip install "markdown>=3.6" y Chrome o Edge (headless).
"""
from __future__ import annotations

import argparse
import glob
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLASSES = os.path.join(ROOT, "classes")
MATERIAL = os.path.join(ROOT, "material")

RE_H1 = re.compile(r"^#\s+(.+?)\s*$", re.M)
RE_NAV = re.compile(r"\n##\s+(?:⬅️\s+Clase anterior|➡️\s+(?:Siguiente|Fin del programa))")
RE_FENCE = re.compile(r"^(\s*)(```|~~~)")

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass


def partes() -> list[tuple[int, str, list[str]]]:
    """[(idx, dir_parte, [rutas de clase en orden])] ordenado por número de parte."""
    out = []
    for pdir in sorted(glob.glob(os.path.join(CLASSES, "parte-*")),
                       key=lambda p: int(re.search(r"parte-(\d+)", p).group(1))):
        idx = int(re.search(r"parte-(\d+)", pdir).group(1))
        clases = sorted(glob.glob(os.path.join(pdir, "[0-9][0-9][0-9]-*", "README.md")),
                        key=lambda r: int(os.path.basename(os.path.dirname(r))[:3]))
        if clases:
            out.append((idx, pdir, clases))
    return out


def _quitar_nav(texto: str) -> str:
    m = RE_NAV.search(texto)
    return (texto[:m.start()].rstrip() + "\n") if m else texto


def _demotar_titulos(texto: str) -> str:
    """Baja un nivel cada título, pero sin tocar los '#' de dentro del código."""
    salida, en_fence, marca = [], False, ""
    for linea in texto.splitlines():
        f = RE_FENCE.match(linea)
        if f:
            if not en_fence:
                en_fence, marca = True, f.group(2)
            elif f.group(2) == marca:
                en_fence = False
            salida.append(linea)
        elif not en_fence and linea.startswith("#"):
            salida.append("#" + linea)
        else:
            salida.append(linea)
    return "\n".join(salida)


def construir_markdown() -> str:
    total = sum(len(c) for _, _, c in partes())
    doc = [
        "# Manual completo — Desarrollo de Videojuegos Moderno",
        "",
        f"*{total} clases · 18 partes · de fundamentos a nivel profesional*  ",
        "*github.com/vladimiracunadev-create/modern-gamedev-program · Licencia MIT*",
        "",
    ]
    for idx, pdir, clases in partes():
        # Portada de la parte: su README, sin el H1 (lo ponemos nosotros como
        # título de parte) ni su barra de navegación.
        with open(os.path.join(pdir, "README.md"), encoding="utf-8") as f:
            intro = f.read()
        m = RE_H1.search(intro)
        titulo_parte = re.sub(r"^Parte\s+\d+\s*[—-]\s*", "", m.group(1)).strip() if m else pdir
        intro = RE_H1.sub("", intro, count=1)
        intro = re.sub(r"^\s*>\s*\[⬅️[^\n]*\n", "", intro, count=1, flags=re.M)

        doc.append(f"# Parte {idx} — {titulo_parte}")
        doc.append("")
        doc.append(_quitar_nav(intro).strip())
        doc.append("")

        for ruta in clases:
            with open(ruta, encoding="utf-8") as f:
                cuerpo = _demotar_titulos(_quitar_nav(f.read())).strip()
            doc.append(cuerpo)
            doc.append("")
    return "\n".join(doc)


def main() -> int:
    ap = argparse.ArgumentParser(description="Genera el manual completo del curso en un PDF.")
    ap.add_argument("--html", action="store_true",
                    help="deja solo el HTML intermedio (sin llamar a Chrome)")
    args = ap.parse_args()

    try:
        import markdown
    except ImportError:
        print("Falta 'markdown'. Instálalo: pip install \"markdown>=3.6\"")
        return 1
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import generar_material as gm  # reutiliza el CSS B/N, la plantilla y buscar_navegador

    lista = partes()
    total = sum(len(c) for _, _, c in lista)
    print(f"== Manual: {len(lista)} partes, {total} clases ==")

    md = construir_markdown()
    # En papel los enlaces relativos no llevan a ningún sitio: a texto plano.
    md = gm.LINK_REL.sub(r"\1", md)
    cuerpo = markdown.markdown(md, extensions=["tables", "fenced_code", "sane_lists"])
    html = gm.PLANTILLA.format(title="Manual completo", css=gm.CSS_PRINT, body=cuerpo)

    os.makedirs(MATERIAL, exist_ok=True)

    if args.html:
        ruta = os.path.join(MATERIAL, "MANUAL-COMPLETO.html")
        with open(ruta, "w", encoding="utf-8") as f:
            f.write(html)
        print(f"  {os.path.relpath(ruta, ROOT)} ({os.path.getsize(ruta) // 1024} KB)")
        return 0

    navegador = gm.buscar_navegador()
    if navegador is None:
        print("No encontré Chrome ni Edge (hacen falta para el PDF). Prueba --html.")
        return 1

    pdf = os.path.join(MATERIAL, "MANUAL-COMPLETO.pdf")
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False, encoding="utf-8") as tmp:
        tmp.write(html)
        ruta_tmp = tmp.name
    try:
        print("Generando el PDF (son ~300 páginas: puede tardar un par de minutos)...")
        subprocess.run(
            [navegador, "--headless=new", "--disable-gpu", "--no-sandbox",
             "--no-pdf-header-footer", f"--print-to-pdf={pdf}",
             "file:///" + ruta_tmp.replace("\\", "/")],
            check=True, timeout=600,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
        print(f"Chrome falló generando el PDF: {e}")
        return 1
    finally:
        os.unlink(ruta_tmp)

    print(f"  {os.path.relpath(pdf, ROOT)} ({os.path.getsize(pdf) // 1024} KB)")
    print("\nOK: manual en PDF generado (en material/, no se versiona).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
