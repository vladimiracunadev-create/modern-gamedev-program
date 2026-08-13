#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Falla si algún archivo de texto del repo tiene mojibake (texto doblemente
codificado) o no es UTF-8 válido.

Contexto: este repositorio se escribe en español, con acentos y emoji en casi
cada título. Basta con que una herramienta lea un archivo como cp1252 y lo
vuelva a guardar como UTF-8 para que "física" se convierta en "fÃ­sica" y los
emoji en garabatos — y el resultado sigue siendo un archivo válido que nadie
detecta hasta que alguien lo lee. En Windows, además, es el fallo más fácil de
provocar sin querer.

Por qué NO se detecta con grep: un patrón no-ASCII puede corromperse al pasar
por el shell y acabar buscando los BYTES del texto SANO (el byte C3 está en
toda vocal acentuada), dando falsos positivos en archivos correctos. La
detección aquí es programática, por round-trip, sin patrones.

Por qué cp1252 "sloppy": cp1252 deja sin definir los bytes 81/8D/8F/90/9D, y
los emoji los llevan (el selector VS16 U+FE0F -> EF B8 8F). Con cp1252 puro
esas líneas lanzan UnicodeEncodeError y quedarían sin detectar EN SILENCIO.

Uso:
    python scripts/validar_encoding.py
"""
from __future__ import annotations

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

EXTS = {".md", ".json", ".html", ".py", ".yml", ".yaml", ".toml", ".txt",
        ".css", ".js", ".gd", ".gdshader", ".tscn", ".godot", ".cfg", ".csv",
        ".java", ".xml"}
SKIP = {".git", "node_modules", ".venv", "venv", "__pycache__", ".godot",
        "site", "dist", "material", ".verif_red"}

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

# Tabla sloppy-cp1252: byte -> char (los huecos de cp1252 se resuelven como latin-1)
_DEC: dict[int, str] = {}
for _b in range(256):
    try:
        _DEC[_b] = bytes([_b]).decode("cp1252")
    except UnicodeDecodeError:
        _DEC[_b] = chr(_b)
_ENC = {c: b for b, c in _DEC.items()}


def linea_con_mojibake(linea: str) -> bool:
    """True si la línea se puede «des-corromper», o sea: está corrupta.

    Una línea sana no sobrevive el round-trip: al volver a bytes por cp1252,
    esos bytes no forman UTF-8 válido y la conversión falla. Si en cambio
    funciona y además cambia el texto, es que había una capa de más.
    """
    try:
        arreglada = bytes(_ENC[c] for c in linea).decode("utf-8")
    except (KeyError, UnicodeDecodeError):
        return False
    return arreglada != linea


def main() -> int:
    malos: list[str] = []
    no_utf8: list[str] = []
    revisados = 0

    for base, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in SKIP]
        for nombre in files:
            if os.path.splitext(nombre)[1].lower() not in EXTS:
                continue
            ruta = os.path.join(base, nombre)
            rel = os.path.relpath(ruta, ROOT).replace("\\", "/")
            try:
                with open(ruta, "rb") as f:
                    texto = f.read().decode("utf-8")
            except UnicodeDecodeError:
                no_utf8.append(rel)
                continue
            revisados += 1
            n = sum(1 for linea in texto.split("\n") if linea_con_mojibake(linea))
            if n:
                malos.append(f"{rel} ({n} línea(s))")

    print(f"Archivos de texto revisados: {revisados}")
    if not malos and not no_utf8:
        print("OK: sin mojibake; todo UTF-8 válido.")
        return 0

    for m in malos:
        print(f"ERROR mojibake: {m}")
    for m in no_utf8:
        print(f"ERROR no es UTF-8: {m}")
    print("\nAbre el archivo con un editor en UTF-8 y vuelve a guardarlo, o "
          "regenéralo con su script si es contenido generado.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
