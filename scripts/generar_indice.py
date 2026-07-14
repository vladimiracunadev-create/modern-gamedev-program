#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Regenera `classes/README.md` (índice maestro) y `classes/_manifest.json` a partir
de la estructura real del repositorio. Lee el título H1 de cada clase construida
(`# Clase NNN — Título`) y el de cada parte, y marca como planificadas las partes
que aún no tienen carpeta.

Uso:  python scripts/generar_indice.py
"""
from __future__ import annotations
import glob
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLASSES = os.path.join(ROOT, "classes")

# Plan canónico del programa completo (18 partes). start/end = rango global de clases.
PLAN = [
    (0, "Fundamentos y prerrequisitos", "parte-0-fundamentos-y-prerrequisitos", 1, 25),
    (1, "Motores 2D y tu primer juego jugable", "parte-1-motores-2d-y-tu-primer-juego-jugable", 26, 45),
    (2, "Desarrollo 3D: motores, escenas y transformaciones", "parte-2-desarrollo-3d-motores-escenas-y-transformaciones", 46, 67),
    (3, "Física y matemáticas de juegos aplicadas", "parte-3-fisica-y-matematicas-de-juegos-aplicadas", 68, 85),
    (4, "Gráficos, shaders y rendering moderno", "parte-4-graficos-shaders-y-rendering-moderno", 86, 107),
    (5, "Inteligencia artificial para juegos", "parte-5-inteligencia-artificial-para-juegos", 108, 125),
    (6, "Audio y música interactiva", "parte-6-audio-y-musica-interactiva", 126, 137),
    (7, "Multijugador y networking", "parte-7-multijugador-y-networking", 138, 155),
    (8, "Game design y diseño de niveles", "parte-8-game-design-y-diseno-de-niveles", 156, 171),
    (9, "Arte, animación y pipeline de assets", "parte-9-arte-animacion-y-pipeline-de-assets", 172, 187),
    (10, "UI/UX, accesibilidad y localización", "parte-10-ui-ux-accesibilidad-y-localizacion", 188, 199),
    (11, "Móvil, consolas y plataformas", "parte-11-movil-consolas-y-plataformas", 200, 213),
    (12, "Juegos web y HTML5", "parte-12-juegos-web-y-html5", 214, 227),
    (13, "VR, AR y experiencias inmersivas", "parte-13-vr-ar-y-experiencias-inmersivas", 228, 239),
    (14, "Optimización, profiling y rendimiento", "parte-14-optimizacion-profiling-y-rendimiento", 240, 254),
    (15, "Herramientas, editores y automatización (tooling)", "parte-15-herramientas-editores-y-automatizacion", 255, 266),
    (16, "Producción, publicación, monetización y LiveOps", "parte-16-produccion-publicacion-monetizacion-y-liveops", 267, 280),
    (17, "Capstones y preparación profesional / portfolio", "parte-17-capstones-y-preparacion-profesional-portfolio", 281, 292),
]

H1_CLASE = re.compile(r"^#\s+Clase\s+(\d{3})\s*[—-]\s*(.+)$", re.MULTILINE)


def clases_de(parte_slug: str) -> list[tuple[int, str, str]]:
    """Devuelve [(num, titulo, slug)] de las clases construidas de una parte."""
    pdir = os.path.join(CLASSES, parte_slug)
    out = []
    for cdir in sorted(glob.glob(os.path.join(pdir, "*"))):
        base = os.path.basename(cdir)
        if not (os.path.isdir(cdir) and re.match(r"^\d{3}-", base)):
            continue
        readme = os.path.join(cdir, "README.md")
        num = int(base[:3])
        titulo = base[4:].replace("-", " ").capitalize()
        if os.path.isfile(readme):
            m = H1_CLASE.search(open(readme, encoding="utf-8").read())
            if m:
                titulo = m.group(2).strip()
        out.append((num, titulo, base))
    return out


def main() -> int:
    construidas = 0
    total_plan = sum(fin - ini + 1 for _, _, _, ini, fin in PLAN)
    partes_hechas = 0

    lineas = [
        "# 📚 Índice completo de clases",
        "",
        "> [⬅️ Volver al programa](../README.md) · [🗺️ Roadmap](../ROADMAP.md)",
        "",
        f"Programa secuencial de **{total_plan} clases** en **18 partes**. La numeración es global "
        "(001→…) y el orden importa: cada clase asume la anterior.",
        "",
        "---",
        "",
    ]

    manifest_parts = []

    for idx, titulo, slug, ini, fin in PLAN:
        pdir = os.path.join(CLASSES, slug)
        clases = clases_de(slug) if os.path.isdir(pdir) else []
        if clases:
            partes_hechas += 1
            construidas += len(clases)
            lineas.append(f"## ✅ Parte {idx} — {titulo} · clases {ini:03d}–{fin:03d}")
            lineas.append("")
            lineas.append(f"> [📂 Ver README de la parte]({slug}/README.md)")
            lineas.append("")
            lineas.append("| # | Clase |")
            lineas.append("|---|---|")
            for num, ct, cslug in clases:
                lineas.append(f"| {num:03d} | [{ct}]({slug}/{cslug}/README.md) |")
            lineas.append("")
            manifest_parts.append({
                "idx": idx, "title": titulo, "slug": slug,
                "start": ini, "end": fin, "count": len(clases), "built": True,
                "classes": [{"num": n, "title": t, "slug": s} for n, t, s in clases],
            })
        else:
            lineas.append(f"## 🔜 Parte {idx} — {titulo} · clases {ini:03d}–{fin:03d} · "
                          f"{fin - ini + 1} clases *(planificada)*")
            lineas.append("")
            manifest_parts.append({
                "idx": idx, "title": titulo, "slug": slug,
                "start": ini, "end": fin, "count": fin - ini + 1, "built": False,
                "classes": [],
            })

    # Resumen al principio (se inserta tras la línea de descripción).
    resumen = (f"**Estado:** {construidas} clases construidas en {partes_hechas} de 18 partes "
               f"· {total_plan - construidas} clases planificadas.")
    lineas.insert(5, resumen)
    lineas.insert(6, "")

    with open(os.path.join(CLASSES, "README.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(lineas).rstrip() + "\n")

    manifest = {
        "program": "Desarrollo de Videojuegos Moderno",
        "total_planned": total_plan,
        "total_built": construidas,
        "parts_built": partes_hechas,
        "parts": manifest_parts,
    }
    with open(os.path.join(CLASSES, "_manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)
        f.write("\n")

    print(f"Índice y manifest regenerados: {construidas} clases en {partes_hechas} partes "
          f"(plan total {total_plan}).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
