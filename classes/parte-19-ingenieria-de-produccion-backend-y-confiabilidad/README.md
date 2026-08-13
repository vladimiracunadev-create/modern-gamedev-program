# Parte 19 — Ingeniería de producción, backend y confiabilidad

> [⬅️ Volver al programa](../../README.md) · [📚 Índice completo](../README.md) · [⏮️ Parte anterior](../parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/README.md) · [⏭️ Parte siguiente](../parte-20-ia-generativa-y-desarrollo-asistido-por-ia/README.md)

**14 clases** · rango 311–324 · Lo que separa "mi juego funciona en mi máquina" de "mi juego funciona para miles de personas, todos los días, y cuando algo falla me entero yo antes que ellos": backend, identidad, cloud saves, economía autoritativa, configuración remota, observabilidad, privacidad, modelo de amenazas, anti-cheat, testing de producción, presupuestos de rendimiento, releases y recuperación

**Fuentes de referencia de esta parte:**

- Documentación de [OWASP](https://owasp.org/) sobre modelado de amenazas y seguridad de aplicaciones.
- [OpenTelemetry](https://opentelemetry.io/docs/) — estándar abierto de trazas, métricas y logs.
- Google — *Site Reliability Engineering* (capítulos de monitorización, SLO y postmortems): <https://sre.google/books/>
- [Semantic Versioning 2.0.0](https://semver.org/) y documentación de [GitHub Actions](https://docs.github.com/actions).
- Reglamentos de protección de datos aplicables (RGPD en la UE, COPPA en EE. UU.) y las guías de privacidad de las plataformas.
- Charlas de GDC sobre LiveOps, backends de juegos y respuesta a incidentes: <https://www.gdcvault.com/>

---

## 🎯 ¿De qué trata esta parte?

La Parte 16 te enseñó a **publicar** un juego y la Parte 7 a conectarlo en red. Esta parte trata de lo que viene después y dura años: **operarlo**. Es la disciplina de la ingeniería de producción aplicada a videojuegos, y cubre el hueco más grande que separa a un desarrollador indie competente de alguien que puede trabajar en un estudio con un juego vivo.

Aquí aprenderás a diseñar el backend que respalda a un cliente, a no confiar nunca en datos que vienen de él, a saber qué está pasando en producción sin adivinar, a cambiar el comportamiento del juego sin publicar una build, a demostrar con presupuestos automáticos que un cambio no ha empeorado el rendimiento, y a tener un plan para cuando algo se rompa — porque se romperá.

Todo lo de esta parte se practica **sin servicios de pago, sin claves de API y sin credenciales**: el laboratorio usa mocks deterministas y funciona offline en CI. Lo que se enseña son los patrones, que son los mismos con cualquier proveedor.

## 🧩 Problemas que resuelve

- Backends improvisados donde el cliente decide su propio oro, nivel o inventario.
- Cuentas, compras y derechos de contenido gestionados con archivos locales.
- Guardados en la nube que pierden progreso al jugar en dos dispositivos.
- Cambiar un número de balance obliga a publicar una build y esperar a la revisión de la tienda.
- Crashes en producción de los que solo se sabe por una reseña de una estrella.
- Telemetría que recoge datos personales sin consentimiento, sin retención y sin necesidad.
- Anti-cheat improvisado que castiga a inocentes y no detecta a los tramposos.
- Un parche que arregla un bug y triplica el tiempo de carga sin que nadie lo note.
- Un lanzamiento que sale mal y no hay forma de volver atrás.

## 🎓 Resultados de aprendizaje

Al terminar la parte, el alumno podrá:

- Dibujar la arquitectura de un backend de juego y señalar dónde está la autoridad de cada dato.
- Diseñar identidad, perfiles y entitlements sin guardar secretos en el cliente.
- Implementar cloud saves con detección y resolución de conflictos, y modo offline.
- Implementar operaciones de economía **idempotentes** y auditables en servidor.
- Usar remote config y feature flags con valores por defecto seguros y kill switches.
- Instrumentar un juego con logs estructurados, métricas, trazas y crash reporting.
- Diseñar una taxonomía de eventos de telemetría respetuosa con la privacidad por diseño.
- Construir un modelo de amenazas con límites de confianza y derivar de él las validaciones.
- Montar una batería de testing de producción: property-based, fuzzing seguro, soak y carga.
- Definir presupuestos de rendimiento que **fallen la CI** cuando se superan.
- Publicar builds reproducibles, firmadas y versionadas por canales, con plan de rollback.

## 🧱 Prerrequisitos

- Parte 7 (multijugador), especialmente las clases 148, 152 y 154: esta parte las profundiza.
- Parte 15 (tooling y CI) y Parte 16 (producción, publicación y analítica).
- Parte 18: el save versionado de la clase 307 y la economía de la 303 son el punto de partida de las clases 313 y 314.
- Godot 4.x. El laboratorio no requiere ninguna cuenta ni servicio externo.

## 📚 Las 14 clases

| # | Clase |
|---|---|
| 311 | [Arquitectura backend para videojuegos](311-arquitectura-backend-para-videojuegos/README.md) |
| 312 | [Identidad, perfiles y entitlements](312-identidad-perfiles-y-entitlements/README.md) |
| 313 | [Cloud saves, cross-save y resolución de conflictos](313-cloud-saves-cross-save-y-resolucion-de-conflictos/README.md) |
| 314 | [Economía transaccional de servidor](314-economia-transaccional-de-servidor/README.md) |
| 315 | [Remote Config, feature flags y experimentos](315-remote-config-feature-flags-y-experimentos/README.md) |
| 316 | [Observabilidad de juegos](316-observabilidad-de-juegos/README.md) |
| 317 | [Telemetría, privacidad y gobernanza de datos](317-telemetria-privacidad-y-gobernanza-de-datos/README.md) |
| 318 | [Threat modeling para videojuegos](318-threat-modeling-para-videojuegos/README.md) |
| 319 | [Anti-cheat y respuesta frente al abuso](319-anti-cheat-y-respuesta-frente-al-abuso/README.md) |
| 320 | [Testing de producción](320-testing-de-produccion/README.md) |
| 321 | [Performance regression testing](321-performance-regression-testing/README.md) |
| 322 | [Build y release engineering](322-build-y-release-engineering/README.md) |
| 323 | [Parches, delivery y recuperación](323-parches-delivery-y-recuperacion/README.md) |
| 324 | [Capstone Parte 19: un runtime de producción](324-capstone-parte-19-un-runtime-de-produccion/README.md) |

---

> Con el juego construido y operable, la [Parte 20](../parte-20-ia-generativa-y-desarrollo-asistido-por-ia/README.md) incorpora la IA generativa: como herramienta de desarrollo y como sistema dentro del juego, siempre con verificación.
