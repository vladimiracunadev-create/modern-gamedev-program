#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Pone (y mantiene) el enlace «⬅️ Clase anterior» al final de cada clase.

Las clases ya enlazaban hacia adelante, pero no hacia atrás: para volver a la
anterior había que subir al índice y buscarla. Un curso secuencial se lee en los
dos sentidos — sobre todo cuando la clase de hoy da por sabido lo de ayer.

La sección va justo ANTES de «➡️ Siguiente…», así el pie de cada clase queda:

    ## ⬅️ Clase anterior
    [Clase 005 - Matemáticas para juegos II: matrices y transformaciones](../005-.../README.md)

    ## ➡️ Siguiente clase
    [Clase 007 - Física básica para juegos](../007-.../README.md)

Casos que hay que tratar aparte:
  * La clase 001 no tiene anterior: enlaza al índice del programa.
  * Al cambiar de parte, la anterior está en OTRA carpeta: la ruta sube dos
    niveles (../../parte-N-.../NNN-.../README.md).

Es idempotente: si la sección ya está, se reescribe con el destino correcto. Así
reordenar o insertar una clase se arregla volviendo a ejecutarlo, y la CI
comprueba que nadie se ha olvidado (igual que con el índice y el glosario).

Uso:  python scripts/generar_navegacion.py
      python scripts/generar_navegacion.py --check   # no escribe; falla si algo está sin generar
"""
from __future__ import annotations

import argparse
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLASSES = os.path.join(ROOT, "classes")

RE_CLASE = re.compile(r"^(\d{3})-")
RE_H1 = re.compile(r"^#\s+Clase\s+\d{3}\s*[—-]\s*(.+?)\s*$", re.M)
RE_SIGUIENTE = re.compile(r"^##\s+➡️\s+", re.M)
RE_ANTERIOR = re.compile(r"^##\s+⬅️\s+Clase anterior\s*\n+.*?(?=\n##\s|\Z)", re.M | re.S)

CABECERA = "## ⬅️ Clase anterior"

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass


class Clase:
    def __init__(self, ruta: str) -> None:
        self.ruta = ruta                                   # .../classes/parte-X/NNN-slug/README.md
        self.dir = os.path.dirname(ruta)                   # .../classes/parte-X/NNN-slug
        self.carpeta = os.path.basename(self.dir)          # NNN-slug
        self.parte = os.path.basename(os.path.dirname(self.dir))  # parte-X-slug
        self.numero = int(RE_CLASE.match(self.carpeta).group(1))

    @property
    def titulo(self) -> str:
        with open(self.ruta, encoding="utf-8") as f:
            m = RE_H1.search(f.read())
        return m.group(1).strip() if m else self.carpeta

    def enlace_desde(self, otra: "Clase") -> str:
        """Ruta relativa para ir de `otra` a `self`."""
        if otra.parte == self.parte:
            destino = f"../{self.carpeta}/README.md"
        else:
            destino = f"../../{self.parte}/{self.carpeta}/README.md"
        # Guion simple y no raya: es el formato que ya usan los enlaces
        # «Siguiente clase» de todo el repo.
        return f"[Clase {self.numero:03d} - {self.titulo}]({destino})"


def cargar() -> list[Clase]:
    rutas = glob.glob(os.path.join(CLASSES, "parte-*", "[0-9][0-9][0-9]-*", "README.md"))
    clases = [Clase(r) for r in rutas]
    clases.sort(key=lambda c: c.numero)
    return clases


def bloque_anterior(actual: Clase, previa: Clase | None) -> str:
    if previa is None:
        # La primera clase del programa: no hay hacia dónde volver, salvo arriba.
        cuerpo = "[Volver al índice del programa](../../README.md)"
    else:
        cuerpo = previa.enlace_desde(actual)
    return f"{CABECERA}\n\n{cuerpo}\n"


def aplicar(texto: str, bloque: str) -> str:
    """Deja `bloque` justo antes de la sección «➡️ Siguiente…», sin duplicar."""
    # Fuera la que hubiera: así el script es idempotente y corrige destinos viejos.
    texto = RE_ANTERIOR.sub("", texto)

    m = RE_SIGUIENTE.search(texto)
    if m:
        corte = m.start()
        return texto[:corte].rstrip("\n") + "\n\n" + bloque + "\n" + texto[corte:]
    # Sin sección «Siguiente» (la última clase del programa): al final del todo.
    return texto.rstrip("\n") + "\n\n" + bloque


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true",
                    help="no escribe: solo dice si alguna clase está sin generar")
    args = ap.parse_args()

    clases = cargar()
    if not clases:
        print("No encontré ninguna clase.")
        return 1

    cambiadas: list[str] = []
    for i, c in enumerate(clases):
        previa = clases[i - 1] if i > 0 else None
        with open(c.ruta, encoding="utf-8") as f:
            original = f.read()
        nuevo = aplicar(original, bloque_anterior(c, previa))
        if nuevo != original:
            cambiadas.append(c.carpeta)
            if not args.check:
                with open(c.ruta, "w", encoding="utf-8", newline="\n") as f:
                    f.write(nuevo)

    print(f"== Navegacion hacia atras: {len(clases)} clases ==")
    if args.check:
        if cambiadas:
            print(f"\nFALLO: {len(cambiadas)} clase(s) sin la navegación al día:")
            for c in cambiadas[:10]:
                print(f"  - {c}")
            if len(cambiadas) > 10:
                print(f"  ... y {len(cambiadas) - 10} más")
            print("\nEjecuta: python scripts/generar_navegacion.py")
            return 1
        print("OK: todas tienen su enlace a la clase anterior, y apunta bien.")
        return 0

    print(f"Actualizadas: {len(cambiadas)}")
    print("OK: cada clase enlaza a la anterior (y la 001, al índice).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
