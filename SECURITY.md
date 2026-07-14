# 🔐 Política de seguridad

Este repositorio es un **currículo educativo** (Markdown, scripts de generación en Python y workflows de CI). No es una aplicación en producción, pero mantenemos buenas prácticas de seguridad en la cadena de suministro.

## 📦 Alcance

Lo que se protege y revisa automáticamente:

- **Scripts de Python** (`scripts/`) — analizados con [Bandit](https://bandit.readthedocs.io/) (SAST) en cada push/PR.
- **Todo el repositorio** — escaneado con [gitleaks](https://github.com/gitleaks/gitleaks) en busca de secretos filtrados.
- **Workflows y dependencias de CI** — versiones ancladas y permisos mínimos (`contents: read`).

## 🐛 Reportar una vulnerabilidad

Si encuentras un problema de seguridad (por ejemplo, un secreto real filtrado por error, una dependencia vulnerable en la CI, o código inseguro en los scripts):

1. **No abras un issue público** si se trata de un secreto expuesto.
2. Usa la pestaña **Security → Report a vulnerability** de GitHub (avisos privados), o
3. Escribe a `vladimir.acuna.dev@gmail.com` con el detalle y, si aplica, una prueba de concepto.

Intentaremos responder en un plazo razonable y dar crédito a quien reporte, salvo que prefiera el anonimato.

## ⚠️ Sobre el contenido de las clases

Las clases pueden incluir **código de ejemplo** y valores ficticios (claves de API de muestra en tutoriales de integración, rutas de ejemplo, etc.) con fines didácticos. **Nunca son secretos reales.** El archivo [`.gitleaks.toml`](.gitleaks.toml) documenta las exclusiones aplicadas al material educativo.

## ✅ Buenas prácticas para quien use este repo

- No subas claves reales, tokens ni credenciales a tus propios proyectos de juego. Usa variables de entorno y `.gitignore`.
- Usa **Git LFS** para assets binarios en lugar de commitear archivos grandes (ver la Clase 015).
- Descarga motores y herramientas solo desde sus sitios oficiales.
