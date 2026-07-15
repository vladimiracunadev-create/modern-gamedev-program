#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Genera un sitio estático (site/) a partir de los Markdown del repositorio,
para publicarlo en GitHub Pages. Renderiza el README raíz, el índice de
clases, los README de parte y los README de clase a HTML, reescribiendo
los enlaces internos .md -> .html para que la navegación funcione en el sitio.

Uso:  python scripts/generar_sitio.py
Salida: carpeta site/ con index.html y el árbol de clases en HTML.
Requiere: pip install "markdown>=3.6"
"""
from __future__ import annotations
import glob
import html as htmllib
import json
import os
import re
import shutil

import markdown

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "site")

# Markdown de origen del nivel superior que se publican.
INCLUIR_TOP = ["README.md", "ROADMAP.md", "CONTRIBUTING.md", "SECURITY.md",
               "labs/README.md", "labs/plataformas-2d/README.md"]

LINK_MD = re.compile(r"\]\(([^)]+?)\.md((?:#[^)]*)?)\)")

PLANTILLA = """<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} · Desarrollo de Videojuegos Moderno</title>
<style>
  :root {{ color-scheme: light dark; --acento:#7c5cff; --acento2:#22d3ee; }}
  * {{ box-sizing: border-box; }}
  body {{
    font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.65; max-width: 900px; margin: 0 auto; padding: 2rem 1.2rem 5rem;
    color: #1b1f24; background: #ffffff;
  }}
  @media (prefers-color-scheme: dark) {{
    body {{ color: #e6edf3; background: #0d1117; }}
    a {{ color: #a78bfa; }}
    code, pre {{ background: #161b22 !important; }}
    table, th, td {{ border-color: #30363d !important; }}
    thead th {{ background: #161b22 !important; }}
  }}
  a {{ color: #6d28d9; text-decoration: none; }}
  a:hover {{ text-decoration: underline; }}
  h1, h2, h3 {{ line-height: 1.25; }}
  h1 {{ border-bottom: 1px solid #d0d7de; padding-bottom: .3em; }}
  h2 {{ border-bottom: 1px solid #d0d7de; padding-bottom: .2em; margin-top: 2rem; }}
  code {{ background: #f2f4f6; padding: .15em .35em; border-radius: 5px; font-size: .9em; }}
  pre {{ background: #f2f4f6; padding: 1rem; border-radius: 8px; overflow-x: auto; }}
  pre code {{ background: transparent; padding: 0; }}
  table {{ border-collapse: collapse; width: 100%; overflow-x: auto; display: block; }}
  th, td {{ border: 1px solid #d0d7de; padding: .5em .75em; text-align: left; }}
  thead th {{ background: #f2f4f6; }}
  blockquote {{ border-left: 4px solid var(--acento); margin: 1rem 0; padding: .2rem 1rem; color: inherit; opacity: .9; }}
  .nav {{ font-size: .9rem; margin-bottom: 1.5rem; opacity: .85; }}
</style>
</head>
<body>
<div class="nav"><a href="{home}">🎮 Inicio</a> · <a href="{indice}">📚 Clases</a> · <a href="{roadmap}">🗺️ Roadmap</a></div>
{body}
</body>
</html>
"""


def reescribir_enlaces(texto: str) -> str:
    """Convierte enlaces internos ...algo.md(#anchor) en ...algo.html(#anchor)."""
    return LINK_MD.sub(lambda m: f"]({m.group(1)}.html{m.group(2)})", texto)


def render(md_text: str) -> str:
    return markdown.markdown(
        md_text,
        extensions=["tables", "fenced_code", "toc", "sane_lists", "attr_list"],
    )


def profundidad(rel: str) -> int:
    return rel.replace("\\", "/").count("/")


def escribir(rel_md: str, md_text: str) -> None:
    rel_html = rel_md[:-3] + ".html"
    destino = os.path.join(OUT, rel_html)
    os.makedirs(os.path.dirname(destino) or OUT, exist_ok=True)
    prof = profundidad(rel_html)
    subir = "../" * prof
    title = "Programa de Desarrollo de Videojuegos Moderno"
    m = re.search(r"^#\s+(.+)$", md_text, re.MULTILINE)
    if m:
        title = re.sub(r"[#*`]", "", m.group(1)).strip()
    html = PLANTILLA.format(
        title=title,
        home=f"{subir}index.html" if prof else "index.html",
        indice=f"{subir}classes/README.html" if prof else "classes/README.html",
        roadmap=f"{subir}ROADMAP.html" if prof else "ROADMAP.html",
        body=render(reescribir_enlaces(md_text)),
    )
    with open(destino, "w", encoding="utf-8") as f:
        f.write(html)


LANDING_CSS = """
:root{
  --acento:#7c5cff; --acento2:#22d3ee; --acento3:#f472b6;
  --bg:#ffffff; --bg2:#f5f4fb; --txt:#12181d; --muted:#5b6670; --card:#ffffff; --borde:#e6e2f2;
}
@media (prefers-color-scheme:dark){
  :root{ --bg:#0d1117; --bg2:#12111c; --txt:#e6edf3; --muted:#9aa7b2; --card:#161b22; --borde:#272138; }
}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
body{margin:0;font-family:system-ui,-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;
  background:var(--bg);color:var(--txt);line-height:1.6;-webkit-font-smoothing:antialiased}
a{color:inherit;text-decoration:none}
.wrap{max-width:1040px;margin:0 auto;padding:0 1.1rem}
/* Hero */
.hero{position:relative;overflow:hidden;color:#fff;text-align:center;padding:4.5rem 1.1rem 3.2rem;
  background:radial-gradient(1200px 520px at 50% -10%,#8b5cf6 0%,#5b21b6 45%,#1e1b4b 100%)}
.hero::after{content:"";position:absolute;inset:0;opacity:.12;
  background-image:linear-gradient(#fff 1px,transparent 1px),linear-gradient(90deg,#fff 1px,transparent 1px);
  background-size:32px 32px;mask-image:radial-gradient(circle at 50% 0,#000,transparent 72%)}
.hero>*{position:relative;z-index:1}
.hero .escudo{font-size:3.4rem;line-height:1;filter:drop-shadow(0 4px 16px rgba(0,0,0,.35))}
.hero h1{font-size:clamp(1.8rem,4.5vw,3rem);margin:.4rem 0 .3rem;font-weight:800;letter-spacing:-.5px}
.hero .sub{font-size:clamp(1rem,2.2vw,1.25rem);opacity:.94;max-width:660px;margin:0 auto 1.4rem}
.chips{display:flex;flex-wrap:wrap;gap:.5rem;justify-content:center;margin-bottom:1.6rem}
.chip{background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.28);border-radius:999px;
  padding:.28rem .8rem;font-size:.85rem;font-weight:600;backdrop-filter:blur(4px)}
.cta{display:flex;flex-wrap:wrap;gap:.7rem;justify-content:center}
.btn{display:inline-block;padding:.7rem 1.3rem;border-radius:10px;font-weight:700;font-size:1rem;transition:transform .08s ease,box-shadow .2s}
.btn:hover{transform:translateY(-2px)}
.btn-1{background:#fff;color:#5b21b6;box-shadow:0 6px 22px rgba(0,0,0,.28)}
.btn-2{background:rgba(255,255,255,.14);color:#fff;border:1px solid rgba(255,255,255,.55)}
/* Aviso */
.aviso{background:var(--bg2);border-bottom:1px solid var(--borde);font-size:.9rem;color:var(--muted)}
.aviso .wrap{padding:.7rem 1.1rem;text-align:center}
/* Stats */
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:1rem;margin:2.6rem 0}
.stat{background:var(--card);border:1px solid var(--borde);border-radius:14px;padding:1.1rem;text-align:center}
.stat b{display:block;font-size:1.9rem;color:var(--acento);font-weight:800;line-height:1}
.stat span{font-size:.85rem;color:var(--muted)}
/* Secciones */
h2.sec{font-size:1.5rem;margin:2.6rem 0 1.1rem;font-weight:800}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(250px,1fr));gap:1rem}
.feat{background:var(--card);border:1px solid var(--borde);border-radius:14px;padding:1.2rem;transition:border-color .2s,transform .08s}
.feat:hover{border-color:var(--acento);transform:translateY(-2px)}
.feat .ic{font-size:1.7rem}
.feat h3{margin:.5rem 0 .3rem;font-size:1.08rem}
.feat p{margin:0;color:var(--muted);font-size:.92rem}
/* Partes */
.parts{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:.8rem}
.part{position:relative;display:flex;gap:.75rem;align-items:center;background:var(--card);border:1px solid var(--borde);
  border-radius:12px;padding:.8rem .9rem;transition:border-color .2s,transform .08s}
.part:hover{border-color:var(--acento);transform:translateY(-2px)}
.part .num{flex:0 0 auto;width:38px;height:38px;border-radius:10px;display:grid;place-items:center;
  font-weight:800;color:#fff;background:linear-gradient(135deg,var(--acento),#5b21b6)}
.part .t{font-size:.92rem;font-weight:600;line-height:1.25}
.part .c{font-size:.78rem;color:var(--muted)}
.part .estado{position:absolute;top:.5rem;right:.6rem;font-size:.7rem}
.part.soon{opacity:.72}
.part.soon .num{background:linear-gradient(135deg,#94a3b8,#475569)}
/* Footer */
footer{margin-top:3rem;border-top:1px solid var(--borde);background:var(--bg2)}
footer .wrap{padding:2rem 1.1rem;text-align:center;color:var(--muted);font-size:.9rem}
footer a{color:var(--acento);font-weight:600}
"""

# Programa completo planificado (para pintar las 18 partes en la portada).
# 'done' marca las partes ya construidas (con carpeta real en classes/).
PLAN = [
    (0, "Fundamentos y prerrequisitos", 25),
    (1, "Motores 2D y tu primer juego jugable", 20),
    (2, "Desarrollo 3D: motores, escenas y transformaciones", 22),
    (3, "Física y matemáticas de juegos aplicadas", 18),
    (4, "Gráficos, shaders y rendering moderno", 22),
    (5, "Inteligencia artificial para juegos", 18),
    (6, "Audio y música interactiva", 12),
    (7, "Multijugador y networking", 18),
    (8, "Game design y diseño de niveles", 16),
    (9, "Arte, animación y pipeline de assets", 16),
    (10, "UI/UX, accesibilidad y localización", 12),
    (11, "Móvil, consolas y plataformas", 14),
    (12, "Juegos web y HTML5", 14),
    (13, "VR, AR y experiencias inmersivas", 12),
    (14, "Optimización, profiling y rendimiento", 15),
    (15, "Herramientas, editores y automatización", 12),
    (16, "Producción, publicación, monetización y LiveOps", 14),
    (17, "Capstones y preparación profesional / portfolio", 12),
]


def partes_construidas() -> dict[int, dict]:
    """Devuelve info real de las partes con carpeta en classes/."""
    out: dict[int, dict] = {}
    for pdir in glob.glob(os.path.join(ROOT, "classes", "parte-*")):
        m = re.search(r"parte-(\d+)", os.path.basename(pdir))
        if not m:
            continue
        idx = int(m.group(1))
        slug = os.path.basename(pdir)
        nums = [int(re.match(r"^(\d{3})", os.path.basename(c)).group(1))
                for c in glob.glob(os.path.join(pdir, "*"))
                if os.path.isdir(c) and re.match(r"^\d{3}", os.path.basename(c))]
        if nums:
            out[idx] = {"slug": slug, "n": len(nums), "ini": min(nums), "fin": max(nums)}
    return out


def escribir_landing() -> None:
    hechas = partes_construidas()
    total_hechas = sum(p["n"] for p in hechas.values())
    total_plan = sum(n for _, _, n in PLAN)
    stats = [
        (str(total_hechas), "clases listas"),
        (str(len(hechas)), "partes construidas"),
        (str(total_plan), "clases planificadas"),
        ("18", "partes en total"),
        ("3+", "motores (Godot/Unity/Unreal)"),
    ]
    stats_html = "".join(f'<div class="stat"><b>{v}</b><span>{k}</span></div>' for v, k in stats)
    feats = [
        ("📚", "Currículo paso a paso", f"{total_hechas} clases listas (Partes 0 y 1), cada una con objetivo, laboratorio guiado, ejercicios y reto verificable.", "classes/README.html"),
        ("🕹️", "Tu primer juego real", "La Parte 1 te lleva de un sprite en pantalla a un plataformas 2D completo y jugable en Godot 4.", "classes/parte-1-motores-2d-y-tu-primer-juego-jugable/README.html"),
        ("🧮", "Fundamentos sólidos", "Matemáticas, física, C#, C++, patrones y ECS: entiendes el porqué, no solo el cómo.", "classes/parte-0-fundamentos-y-prerrequisitos/README.html"),
        ("🛠️", "Todas las tecnologías", "Agnóstico de motor: Godot, Unity y Unreal; C#, C++, GDScript, shaders, web y más.", "classes/README.html"),
        ("🗺️", "Roadmap abierto", "18 partes diseñadas de fundamentos a nivel profesional. Sigue el avance del programa.", "ROADMAP.html"),
        ("🎯", "Orientado a portfolio", "Cada capstone es una pieza publicable. Terminas con juegos que puedes enseñar.", "classes/README.html"),
    ]
    feats_html = "".join(
        f'<a class="feat" href="{u}"><div class="ic">{i}</div><h3>{t}</h3><p>{d}</p></a>'
        for i, t, d, u in feats)

    partes_html = []
    for idx, titulo, n_plan in PLAN:
        info = hechas.get(idx)
        if info:
            href = f'classes/{info["slug"]}/README.html'
            meta = f'{info["n"]} clases · {info["ini"]:03d}–{info["fin"]:03d}'
            partes_html.append(
                f'<a class="part" href="{href}"><div class="num">{idx}</div>'
                f'<div><div class="t">{htmllib.escape(titulo)}</div>'
                f'<div class="c">{meta}</div></div><span class="estado">✅</span></a>')
        else:
            partes_html.append(
                f'<div class="part soon"><div class="num">{idx}</div>'
                f'<div><div class="t">{htmllib.escape(titulo)}</div>'
                f'<div class="c">{n_plan} clases · próximamente</div></div>'
                f'<span class="estado">🔜</span></div>')
    parts_html = "".join(partes_html)

    cuerpo = f"""
<header class="hero">
  <div class="escudo">🎮</div>
  <h1>Desarrollo de Videojuegos Moderno</h1>
  <p class="sub">De las matemáticas y el game loop a un juego completo y publicable — con Godot, Unity y Unreal, paso a paso y en español.</p>
  <div class="chips">
    <span class="chip">{total_hechas} clases listas</span><span class="chip">18 partes</span>
    <span class="chip">Fundamentos → Profesional</span><span class="chip">Godot · Unity · Unreal</span><span class="chip">MIT</span>
  </div>
  <div class="cta">
    <a class="btn btn-1" href="classes/README.html">📚 Empezar el curso</a>
    <a class="btn btn-2" href="ROADMAP.html">🗺️ Ver el roadmap</a>
  </div>
</header>
<div class="aviso"><div class="wrap">🕹️ Curso abierto (MIT) · Partes 0 y 1 completas · el resto del programa se publica siguiendo el <a href="ROADMAP.html">roadmap</a>.</div></div>
<main class="wrap">
  <div class="stats">{stats_html}</div>
  <h2 class="sec">Qué incluye</h2>
  <div class="grid">{feats_html}</div>
  <h2 class="sec">Las 18 partes</h2>
  <div class="parts">{parts_html}</div>
</main>
<footer><div class="wrap">
  Programa de Desarrollo de Videojuegos Moderno · {total_hechas} clases listas · licencia
  <a href="https://github.com/vladimiracunadev-create/desarrollo-videojuegos-moderno-program">MIT en GitHub</a><br>
  <a href="classes/README.html">Índice de clases</a> · <a href="ROADMAP.html">Roadmap</a>
</div></footer>
"""
    doc = (f"<!doctype html><html lang='es'><head><meta charset='utf-8'>"
           f"<meta name='viewport' content='width=device-width,initial-scale=1'>"
           f"<title>Programa de Desarrollo de Videojuegos Moderno</title>"
           f"<style>{LANDING_CSS}</style></head><body>{cuerpo}</body></html>")
    with open(os.path.join(OUT, "index.html"), "w", encoding="utf-8") as f:
        f.write(doc)


def main() -> int:
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(OUT, exist_ok=True)

    generados = 0

    # Documentos del nivel superior.
    for rel in INCLUIR_TOP:
        p = os.path.join(ROOT, rel)
        if os.path.isfile(p):
            escribir(rel, open(p, encoding="utf-8").read())
            generados += 1

    # Todo el árbol de classes/.
    for cur, _, files in os.walk(os.path.join(ROOT, "classes")):
        for fn in files:
            if fn.endswith(".md"):
                p = os.path.join(cur, fn)
                rel = os.path.relpath(p, ROOT).replace("\\", "/")
                escribir(rel, open(p, encoding="utf-8").read())
                generados += 1

    # Portada diseñada (el README raíz abre con <div align=center> + badges,
    # que no se renderiza bien como landing; usamos una portada propia).
    escribir_landing()

    # .nojekyll para que Pages no ignore archivos con nombres especiales.
    open(os.path.join(OUT, ".nojekyll"), "w").close()

    print(f"Sitio generado en site/  ({generados} páginas HTML + index.html)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
