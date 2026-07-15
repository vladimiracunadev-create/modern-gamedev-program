#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Genera los assets del laboratorio (sprites y SFX) de forma procedural.

Todo lo que produce este script es obra original creada por código, por lo que
se publica bajo **CC0 / dominio público**: no depende de packs de terceros ni
arrastra licencias ajenas. Es reproducible: borra `assets/` y vuelve a correrlo.

Uso:  python scripts/generar_assets.py [destino ...]
      (por defecto genera en los proyectos de labs/plataformas-2d/)

Requiere: pip install pillow
"""
from __future__ import annotations

import math
import os
import struct
import sys
import wave

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DESTINOS_POR_DEFECTO = [
    os.path.join(ROOT, "labs", "plataformas-2d", "solucion", "assets"),
    os.path.join(ROOT, "labs", "plataformas-2d", "inicio", "assets"),
]

# Paleta (estilo pixel art plano, alto contraste para buena legibilidad).
PIEL = (255, 205, 160, 255)
PELO = (60, 40, 35, 255)
CAMISA = (60, 120, 216, 255)
PANTALON = (40, 50, 80, 255)
BOTA = (45, 30, 25, 255)
OJO = (25, 25, 30, 255)

HIERBA = (90, 190, 90, 255)
HIERBA_OSC = (60, 150, 65, 255)
TIERRA = (140, 95, 60, 255)
TIERRA_OSC = (110, 72, 45, 255)
PIEDRA = (135, 140, 150, 255)
PIEDRA_OSC = (100, 105, 115, 255)
MADERA = (170, 120, 70, 255)
MADERA_OSC = (130, 90, 50, 255)

ORO = (255, 200, 60, 255)
ORO_OSC = (215, 155, 30, 255)

ENEMIGO = (200, 70, 90, 255)
ENEMIGO_OSC = (160, 45, 65, 255)

VACIO = (0, 0, 0, 0)


# --------------------------------------------------------------------------
# Sprites
# --------------------------------------------------------------------------
def _cuerpo_jugador(d: ImageDraw.ImageDraw, ox: int, oy: int,
                    bob: int = 0, pierna_izq: int = 0, pierna_der: int = 0,
                    brazo: int = 0) -> None:
    """Dibuja un personaje de 32x32 en (ox, oy). Los offsets animan la pose."""
    y = oy + bob
    # Cabeza
    d.rectangle([ox + 11, y + 5, ox + 20, y + 13], fill=PIEL)
    # Pelo
    d.rectangle([ox + 11, y + 4, ox + 20, y + 7], fill=PELO)
    d.rectangle([ox + 10, y + 5, ox + 11, y + 9], fill=PELO)
    # Ojos
    d.rectangle([ox + 14, y + 9, ox + 15, y + 10], fill=OJO)
    d.rectangle([ox + 18, y + 9, ox + 19, y + 10], fill=OJO)
    # Torso
    d.rectangle([ox + 11, y + 14, ox + 20, y + 22], fill=CAMISA)
    # Brazos
    d.rectangle([ox + 8, y + 15 + brazo, ox + 10, y + 21 + brazo], fill=CAMISA)
    d.rectangle([ox + 21, y + 15 - brazo, ox + 23, y + 21 - brazo], fill=CAMISA)
    d.rectangle([ox + 8, y + 21 + brazo, ox + 10, y + 23 + brazo], fill=PIEL)
    d.rectangle([ox + 21, y + 21 - brazo, ox + 23, y + 23 - brazo], fill=PIEL)
    # Piernas
    d.rectangle([ox + 12, y + 23, ox + 15, y + 28 + pierna_izq], fill=PANTALON)
    d.rectangle([ox + 16, y + 23, ox + 19, y + 28 + pierna_der], fill=PANTALON)
    # Botas
    d.rectangle([ox + 12, y + 28 + pierna_izq, ox + 15, y + 30 + pierna_izq], fill=BOTA)
    d.rectangle([ox + 16, y + 28 + pierna_der, ox + 19, y + 30 + pierna_der], fill=BOTA)


def jugador(destino: str) -> None:
    """Spritesheet del jugador: 6 columnas x 4 filas de 32x32 (192x128).

    Fila 0: idle (4 frames) · Fila 1: run (6) · Fila 2: jump (1) · Fila 3: fall (1)
    """
    img = Image.new("RGBA", (192, 128), VACIO)
    d = ImageDraw.Draw(img)

    # Idle: respiración suave.
    for i, bob in enumerate([0, 1, 0, -1][:4]):
        _cuerpo_jugador(d, i * 32, 0, bob=bob)

    # Run: piernas alternando y brazos en contrafase.
    ciclo = [(-3, 3, 2), (-1, 2, 1), (2, 0, -1), (3, -3, -2), (1, -1, -1), (0, 2, 1)]
    for i, (pi, pd, br) in enumerate(ciclo):
        _cuerpo_jugador(d, i * 32, 32, bob=(-1 if i % 3 == 0 else 0),
                        pierna_izq=pi, pierna_der=pd, brazo=br)

    # Jump: piernas recogidas, brazos arriba.
    _cuerpo_jugador(d, 0, 64, bob=-1, pierna_izq=-3, pierna_der=-1, brazo=-3)
    # Fall: piernas estiradas, brazos abajo.
    _cuerpo_jugador(d, 0, 96, bob=1, pierna_izq=1, pierna_der=2, brazo=2)

    img.save(os.path.join(destino, "jugador.png"))


def tileset(destino: str) -> None:
    """Tileset de 4 tiles de 16x16 en una fila (64x16).

    0: hierba (suelo con tapa) · 1: tierra · 2: piedra · 3: plataforma de madera
    """
    img = Image.new("RGBA", (64, 16), VACIO)
    d = ImageDraw.Draw(img)

    # 0 — hierba
    d.rectangle([0, 0, 15, 15], fill=TIERRA)
    d.rectangle([0, 0, 15, 4], fill=HIERBA)
    d.rectangle([0, 5, 15, 5], fill=HIERBA_OSC)
    for x in (2, 7, 12):
        d.rectangle([x, 8, x + 1, 9], fill=TIERRA_OSC)

    # 1 — tierra
    d.rectangle([16, 0, 31, 15], fill=TIERRA)
    for x, y in ((19, 3), (25, 6), (21, 11), (28, 12)):
        d.rectangle([x, y, x + 1, y + 1], fill=TIERRA_OSC)

    # 2 — piedra
    d.rectangle([32, 0, 47, 15], fill=PIEDRA)
    d.rectangle([32, 0, 47, 0], fill=(160, 165, 175, 255))
    for x, y in ((35, 4), (41, 8), (37, 12)):
        d.rectangle([x, y, x + 2, y + 1], fill=PIEDRA_OSC)

    # 3 — plataforma de madera
    d.rectangle([48, 0, 63, 5], fill=MADERA)
    d.rectangle([48, 6, 63, 7], fill=MADERA_OSC)
    for x in (52, 58):
        d.rectangle([x, 0, x, 5], fill=MADERA_OSC)

    img.save(os.path.join(destino, "tileset.png"))


def moneda(destino: str) -> None:
    """Moneda girando: 6 frames de 16x16 (96x16)."""
    img = Image.new("RGBA", (96, 16), VACIO)
    d = ImageDraw.Draw(img)
    anchos = [6, 4, 2, 4, 6, 6]  # semiancho: simula el giro
    for i, w in enumerate(anchos):
        cx = i * 16 + 8
        d.ellipse([cx - w, 3, cx + w - 1, 12], fill=ORO, outline=ORO_OSC)
        if w >= 4:
            d.rectangle([cx - w + 2, 6, cx - w + 3, 9], fill=ORO_OSC)
    img.save(os.path.join(destino, "moneda.png"))


def enemigo(destino: str) -> None:
    """Enemigo tipo babosa: 4 frames de 24x24 (96x24) con squash."""
    img = Image.new("RGBA", (96, 24), VACIO)
    d = ImageDraw.Draw(img)
    for i, squash in enumerate([0, 1, 2, 1]):
        ox = i * 24
        top = 8 + squash
        d.ellipse([ox + 2, top, ox + 21, 22], fill=ENEMIGO, outline=ENEMIGO_OSC)
        d.rectangle([ox + 2, 21, ox + 21, 22], fill=ENEMIGO_OSC)
        # Ojos
        d.rectangle([ox + 7, top + 3, ox + 8, top + 5], fill=(255, 255, 255, 255))
        d.rectangle([ox + 15, top + 3, ox + 16, top + 5], fill=(255, 255, 255, 255))
        d.rectangle([ox + 7, top + 4, ox + 8, top + 5], fill=OJO)
        d.rectangle([ox + 15, top + 4, ox + 16, top + 5], fill=OJO)
    img.save(os.path.join(destino, "enemigo.png"))


# --------------------------------------------------------------------------
# Audio
# --------------------------------------------------------------------------
def _wav(ruta: str, muestras: list[float], sr: int = 44100) -> None:
    with wave.open(ruta, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(b"".join(
            struct.pack("<h", max(-32767, min(32767, int(m * 32767)))) for m in muestras))


def _env(i: int, n: int, ataque: float = 0.01, caida: float = 0.6) -> float:
    """Envolvente simple ataque/decaimiento para que no chasquee."""
    t = i / n
    if t < ataque:
        return t / ataque
    return max(0.0, (1.0 - (t - ataque) / (1.0 - ataque)) ** (1.0 / caida))


def sfx(destino: str, sr: int = 44100) -> None:
    # Salto: barrido ascendente (onda cuadrada suave).
    n = int(sr * 0.12)
    salto = []
    fase = 0.0
    for i in range(n):
        f = 220 + (660 - 220) * (i / n)
        fase += 2 * math.pi * f / sr
        salto.append(0.35 * math.copysign(1.0, math.sin(fase)) * _env(i, n))
    _wav(os.path.join(destino, "salto.wav"), salto)

    # Moneda: dos notas (A5 -> E6), arpegio corto y brillante.
    n = int(sr * 0.10)
    monedas = []
    for idx, f in enumerate((880.0, 1318.5)):
        for i in range(n):
            monedas.append(0.30 * math.sin(2 * math.pi * f * i / sr) * _env(i, n))
    _wav(os.path.join(destino, "moneda.wav"), monedas)

    # Daño: barrido descendente con algo de aspereza.
    n = int(sr * 0.22)
    dano = []
    fase = 0.0
    for i in range(n):
        f = 400 - (400 - 110) * (i / n)
        fase += 2 * math.pi * f / sr
        s = math.sin(fase)
        s = 0.7 * s + 0.3 * math.copysign(1.0, s)  # armónicos: más "sucio"
        dano.append(0.35 * s * _env(i, n, caida=0.9))
    _wav(os.path.join(destino, "dano.wav"), dano)


# --------------------------------------------------------------------------
def generar(destino: str) -> None:
    os.makedirs(destino, exist_ok=True)
    jugador(destino)
    tileset(destino)
    moneda(destino)
    enemigo(destino)
    sfx(destino)
    print(f"  assets generados en {os.path.relpath(destino, ROOT)}")


def main(argv: list[str]) -> int:
    destinos = argv[1:] or DESTINOS_POR_DEFECTO
    print("Generando assets CC0 (obra original por código)...")
    for d in destinos:
        generar(d)
    print("Listo.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
