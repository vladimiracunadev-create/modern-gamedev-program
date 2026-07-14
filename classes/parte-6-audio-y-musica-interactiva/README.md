# Parte 6 — Audio y música interactiva

> [⬅️ Volver al programa](../../README.md) · [📚 Índice completo](../README.md) · [⏮️ Parte anterior](../parte-5-inteligencia-artificial-para-juegos/README.md) · [⏭️ Parte siguiente](../parte-7-multijugador-y-networking/README.md)

**12 clases** · rango 126–137 · Audio que reacciona al juego: diseño de sonido, buses y mezcla dinámica, audio 3D, música adaptativa (vertical y horizontal), FMOD, Wwise y localización

**Fuentes de referencia de esta parte:**

- Documentación de [audio de Godot 4](https://docs.godotengine.org/en/stable/tutorials/audio/index.html).
- Documentación oficial de [FMOD](https://www.fmod.com/docs/) y [Wwise](https://www.audiokinetic.com/library/).
- Karen Collins, *Game Sound* (MIT Press).
- GDC talks sobre música adaptativa e implementación de audio interactivo.

---

## 🎯 ¿De qué trata esta parte?

El sonido es la mitad de la experiencia y, sin embargo, suele ser lo último que se cuida. Esta parte convierte el audio de "poner un `.wav` cuando saltas" en un sistema **interactivo** que responde al estado del juego. Retomamos los fundamentos (muestreo, formatos, buses) de forma aplicada y avanzamos al **diseño de sonido** (capas, variación y aleatoriedad para que un mismo evento no suene repetitivo), la **mezcla dinámica** con buses y efectos, y el **audio 3D/posicional** con atenuación por distancia.

El núcleo de la parte es la **música adaptativa**: capas verticales (instrumentos que entran y salen según la tensión) y transiciones horizontales (pasar de exploración a combate sin cortes). Cubrimos el middleware profesional —**FMOD** y **Wwise**— que usan los estudios, la sincronización con el ritmo, las voces y la **localización** de audio, y la optimización (memoria, streaming, límite de voces). Cerramos con un **capstone**: un sistema de audio adaptativo completo integrado en un nivel.

## 🧩 Problemas que resuelve

- Efectos de sonido repetitivos y cansinos por falta de variación.
- Mezcla plana donde todo suena al mismo volumen y nada destaca.
- Audio que no transmite espacio (sin posicionamiento 3D ni atenuación).
- Música que corta bruscamente al cambiar de situación en vez de fluir.
- No saber integrar el middleware (FMOD/Wwise) que pide la industria.
- Juegos que consumen demasiada memoria o se quedan sin voces de audio.

## 🎓 Resultados de aprendizaje

Al terminar la parte, el alumno podrá:

- Diseñar sonido con capas, variación y aleatoriedad para evitar la repetición.
- Configurar buses, efectos y mezcla dinámica según el estado del juego.
- Implementar audio 3D posicional con atenuación realista.
- Construir música adaptativa vertical (capas) y horizontal (transiciones).
- Integrar FMOD o Wwise en un proyecto y disparar eventos desde el gameplay.
- Sincronizar audio con el ritmo, gestionar voces/diálogo y localizarlos.
- Optimizar el audio en memoria, streaming y número de voces.

## 🧱 Prerrequisitos

- Partes 0 y 1 (audio digital: muestreo/formatos/buses, y sonido 2D en el motor).
- Parte 2 para el audio 3D posicional (escenas y espacio tridimensional).
- Godot 4.x; opcionalmente FMOD/Wwise (versiones gratuitas para indies) para las clases de middleware.

## 📚 Las 12 clases

| # | Clase |
|---|---|
| 126 | [Fundamentos de audio para juegos (repaso aplicado)](126-fundamentos-de-audio-para-juegos-repaso-aplicado/README.md) |
| 127 | [Diseño de sonido: capas, variación y aleatoriedad](127-diseno-de-sonido-capas-variacion-y-aleatoriedad/README.md) |
| 128 | [Buses, efectos y mezcla dinámica](128-buses-efectos-y-mezcla-dinamica/README.md) |
| 129 | [Audio 3D/posicional y atenuación](129-audio-3d-posicional-y-atenuacion/README.md) |
| 130 | [Música adaptativa: capas verticales](130-musica-adaptativa-capas-verticales/README.md) |
| 131 | [Música adaptativa: transiciones horizontales](131-musica-adaptativa-transiciones-horizontales/README.md) |
| 132 | [Middleware de audio: FMOD](132-middleware-de-audio-fmod/README.md) |
| 133 | [Middleware de audio: Wwise](133-middleware-de-audio-wwise/README.md) |
| 134 | [Sincronización con ritmo y eventos](134-sincronizacion-con-ritmo-y-eventos/README.md) |
| 135 | [Voces, diálogo y localización de audio](135-voces-dialogo-y-localizacion-de-audio/README.md) |
| 136 | [Optimización de audio: memoria y streaming](136-optimizacion-de-audio-memoria-y-streaming/README.md) |
| 137 | [Capstone Parte 6: sistema de audio adaptativo](137-capstone-parte-6-sistema-de-audio-adaptativo/README.md) |

---

> Con imagen y sonido resueltos, la [Parte 7](../parte-7-multijugador-y-networking/README.md) conecta jugadores: arquitecturas de red, replicación, predicción y netcode.
