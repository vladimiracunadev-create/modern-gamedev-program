# Clase 329 — Assets generativos y provenance

> Parte: **20 — IA generativa y desarrollo de juegos asistido por IA** · Fuente: *Estándar C2PA de procedencia de contenido · Guías de plataformas sobre contenido generado por IA · Marco legal de propiedad intelectual*
> ⏱️ Duración estimada: **110 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Usar assets generativos —concept art, texturas, sprites, materiales, animación, sonido, música, 3D— **de forma que puedas defender lo que publicas**. La parte técnica de generar una textura es la fácil; la difícil es responder, dos años después, a estas preguntas: ¿de dónde salió este archivo? ¿con qué herramienta y qué versión? ¿qué licencia tiene lo generado? ¿puedo registrarlo? ¿tengo que declararlo en la tienda? ¿qué pasa si alguien reclama?

Vas a construir un sistema de **procedencia (provenance)**: metadatos obligatorios en cada asset generado, registrados junto al archivo, verificables en CI y consultables en cualquier momento. Y vas a repasar el panorama legal y de plataformas con la honestidad que exige: **es un terreno cambiante y depende de tu jurisdicción**, así que lo que se enseña son los principios y el sistema, no una respuesta legal.

> ⚠️ Esta clase no es asesoramiento jurídico. La propiedad intelectual del contenido generado varía por país y está en evolución. Consulta a un profesional antes de publicar comercialmente.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Definir qué metadatos de procedencia debe llevar cada asset generado.
2. Implementar un registro de procedencia versionado y verificable en CI.
3. Explicar el panorama de propiedad intelectual del contenido generado y sus riesgos.
4. Aplicar los requisitos de divulgación de las principales plataformas.
5. Distinguir usos por fase (exploración, producción, contenido final) y su riesgo.
6. Evaluar la licencia de una herramienta generativa antes de integrarla.
7. Formular la política de IA de un equipo, incluida su dimensión laboral.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Procedencia | Sin ella no puedes responder a ninguna pregunta posterior. |
| 2 | Metadatos obligatorios | Lo que hay que registrar en el momento, no después. |
| 3 | C2PA y estándares | Existe un estándar; conviene conocerlo. |
| 4 | Propiedad intelectual | Qué puedes registrar y qué no, según jurisdicción. |
| 5 | Licencia de la herramienta | Los términos varían enormemente entre proveedores. |
| 6 | Datos de entrenamiento | Origen del riesgo de reclamaciones. |
| 7 | Divulgación en tiendas | Requisito real con consecuencias reales. |
| 8 | Uso por fases | Exploración es de bajo riesgo; contenido final, no. |
| 9 | Revisión humana | Es lo que convierte una salida en un asset. |
| 10 | Dimensión laboral y ética | Afecta a personas y a la percepción del juego. |

## 📖 Definiciones y características

- **Procedencia (provenance)**: registro verificable del origen y la historia de un archivo. Clave: se captura al crear, no se reconstruye después.
- **Metadatos de generación**: herramienta, versión, modelo, prompt, semilla, fecha, autor. Clave: sin la semilla y el prompt, el resultado no es reproducible.
- **C2PA**: estándar abierto de credenciales de contenido que firma criptográficamente el origen. Clave: es el intento serio de estandarizar esto.
- **Marca de agua invisible**: señal incrustada que identifica contenido generado. Clave: se puede perder al reprocesar; no es una garantía.
- **Obra derivada**: creación basada en otra preexistente. Clave: es el concepto legal en juego cuando el modelo se entrenó con obras protegidas.
- **Umbral de autoría humana**: nivel de intervención humana requerido para poder registrar una obra. Clave: varía por jurisdicción y decide si puedes registrar tu asset.
- **Licencia de la herramienta**: términos que definen qué puedes hacer con lo generado. Clave: hay proveedores que ceden todos los derechos y otros que no.
- **Indemnización**: compromiso del proveedor de cubrirte ante reclamaciones. Clave: algunos la ofrecen con condiciones; léelas.
- **Divulgación**: declarar que hay contenido generado por IA. Clave: es obligatoria en varias tiendas y su omisión tiene consecuencias.
- **Contenido de exploración**: material para pensar, que no se publica. Clave: riesgo mínimo y es donde más valor aporta.
- **Contenido de producción**: material intermedio que se transforma. Clave: riesgo medio; documenta la transformación.
- **Contenido final**: lo que ve el jugador. Clave: máximo riesgo y máxima exigencia de procedencia.
- **Revisión humana**: aprobación explícita de una persona antes de integrar. Clave: es tanto control de calidad como argumento de autoría.
- **Trazabilidad**: capacidad de seguir un asset desde el prompt hasta la build. Clave: es lo que permite retirar algo si aparece un problema.
- **Registro de assets (asset ledger)**: archivo versionado con la procedencia de todo. Clave: es el entregable central de esta clase.

## 🧰 Herramientas y preparación

Cualquier herramienta generativa a la que tengas acceso, o ninguna: **el sistema de procedencia se construye y se verifica igual**, y es lo que se evalúa. Trabajaremos en `assets/` y `assets/PROCEDENCIA.json`, con un validador en CI. Documentación de referencia: el [estándar C2PA](https://c2pa.org/), las políticas de contenido generado de las tiendas donde publiques y la [clase 273](../../parte-16-produccion-publicacion-monetizacion-y-liveops/273-presupuesto-contratos-y-aspectos-legales/README.md) sobre aspectos legales.

## 🧪 Laboratorio guiado

1. **Lo que hay que registrar.** En el momento de generar, porque después es irrecuperable:

```json
{
  "version": 1,
  "assets": {
    "assets/texturas/roca_musgo_albedo.png": {
      "origen": "generado_ia",
      "herramienta": "difusion-local-1.5",
      "version_herramienta": "1.5.2",
      "modelo": "modelo-base-abierto-v2",
      "licencia_modelo": "CreativeML Open RAIL-M",
      "prompt": "textura de roca granítica con musgo, tileable, iluminación neutra, 2k",
      "prompt_negativo": "sombras marcadas, marca de agua, texto",
      "semilla": 884213,
      "parametros": { "pasos": 30, "cfg": 7.0, "muestreador": "euler_a" },
      "generado_en": "2026-02-03",
      "generado_por": "vacuna",
      "post_proceso": [
        "corrección de tileado manual en GIMP",
        "ajuste de niveles",
        "generación de normal map desde altura"
      ],
      "revision_humana": { "por": "arte", "fecha": "2026-02-04", "estado": "aprobado" },
      "uso": "contenido_final",
      "licencia_resultado": "propietaria",
      "notas": "Retocada a mano un 30 % aprox. para corregir la costura vertical."
    },
    "assets/sprites/enemigo_lobo.png": {
      "origen": "humano",
      "autor": "María R.",
      "licencia_resultado": "propietaria",
      "creado_en": "2026-01-15"
    },
    "assets/audio/paso_hierba_01.wav": {
      "origen": "generado_codigo",
      "herramienta": "scripts/generar_assets.py",
      "semilla": 1234,
      "licencia_resultado": "CC0"
    }
  }
}
```

Fíjate en que **todos** los assets están en el registro, no solo los generados. Un registro que solo cubre lo generado es un registro incompleto: cuando quieras responder "¿de dónde sale este archivo?", la respuesta "no está en el registro" no distingue entre "es humano" y "se nos olvidó".

2. **El validador.** En CI, porque un registro que se mantiene a mano se desactualiza en dos semanas:

```python
#!/usr/bin/env python3
"""Comprueba que todos los assets tienen procedencia declarada y completa."""
import json, os, sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRO = os.path.join(RAIZ, "assets", "PROCEDENCIA.json")
EXTENSIONES = {".png", ".jpg", ".webp", ".wav", ".ogg", ".glb", ".gltf", ".obj"}

# Campos obligatorios SEGÚN EL ORIGEN. Un asset generado necesita mucho más
# que uno humano, y por buenas razones: es el que hay que poder defender.
OBLIGATORIOS = {
    "generado_ia": ["herramienta", "version_herramienta", "modelo", "licencia_modelo",
                    "prompt", "semilla", "generado_en", "generado_por",
                    "revision_humana", "uso", "licencia_resultado"],
    "humano": ["autor", "licencia_resultado", "creado_en"],
    "generado_codigo": ["herramienta", "semilla", "licencia_resultado"],
    "terceros": ["fuente", "licencia_resultado", "url", "obtenido_en"],
}

def main():
    if not os.path.exists(REGISTRO):
        print("::error::falta assets/PROCEDENCIA.json")
        return 1
    registro = json.load(open(REGISTRO, encoding="utf-8"))["assets"]

    fallos = []
    encontrados = set()
    for cur, _, ficheros in os.walk(os.path.join(RAIZ, "assets")):
        for f in ficheros:
            ruta = os.path.relpath(os.path.join(cur, f), RAIZ).replace("\\", "/")
            if os.path.splitext(f)[1].lower() not in EXTENSIONES:
                continue
            encontrados.add(ruta)
            if ruta not in registro:
                fallos.append(f"{ruta}: sin procedencia declarada")
                continue
            e = registro[ruta]
            origen = e.get("origen", "")
            if origen not in OBLIGATORIOS:
                fallos.append(f"{ruta}: origen desconocido '{origen}'")
                continue
            for campo in OBLIGATORIOS[origen]:
                if campo not in e or e[campo] in ("", None, {}):
                    fallos.append(f"{ruta}: falta '{campo}' (origen {origen})")
            # Un asset generado que llega a contenido final SIN revisión
            # humana aprobada es exactamente lo que este validador existe
            # para impedir.
            if origen == "generado_ia" and e.get("uso") == "contenido_final":
                rev = e.get("revision_humana", {})
                if rev.get("estado") != "aprobado":
                    fallos.append(f"{ruta}: contenido final sin revisión humana aprobada")

    # Entradas huérfanas: el registro dice que existe algo que ya no está.
    for ruta in registro:
        if ruta not in encontrados:
            fallos.append(f"{ruta}: declarado en el registro pero no existe")

    for x in fallos:
        print(f"::error::{x}")
    generados = sum(1 for e in registro.values() if e.get("origen") == "generado_ia")
    print(f"== {len(encontrados)} asset(s), {generados} generado(s) por IA, "
          f"{len(fallos)} fallo(s) ==")
    return 1 if fallos else 0

if __name__ == "__main__":
    sys.exit(main())
```

3. **El informe de divulgación.** Se genera solo, del registro:

```python
def informe_divulgacion(registro):
    """Lo que hay que declarar en la ficha de la tienda, derivado del registro."""
    por_tipo = {}
    for ruta, e in registro.items():
        if e.get("origen") != "generado_ia" or e.get("uso") != "contenido_final":
            continue
        tipo = clasificar(ruta)      # "texturas", "audio", "sprites", ...
        por_tipo.setdefault(tipo, []).append(ruta)

    lineas = ["# Divulgación de contenido generado por IA", ""]
    if not por_tipo:
        lineas.append("Este juego no incluye contenido generado por IA "
                      "en el material publicado.")
        return "\n".join(lineas)
    lineas.append("Este juego incluye contenido creado con herramientas de IA "
                  "generativa en las siguientes categorías:")
    lineas.append("")
    for tipo in sorted(por_tipo):
        lineas.append(f"- **{tipo}**: {len(por_tipo[tipo])} elemento(s). "
                      f"Todo el material ha sido revisado y aprobado por una persona "
                      f"del equipo antes de su integración.")
    return "\n".join(lineas)
```

4. **El panorama legal, con honestidad.** Lo que se puede decir con seguridad y lo que no:

| Cuestión | Situación (variable por jurisdicción) | Qué hacer |
|---|---|---|
| ¿Puedo registrar como obra propia lo generado? | En varias jurisdicciones, **solo con aportación humana suficiente**; la salida sin intervención puede no ser registrable | Documenta y conserva la transformación humana |
| ¿Puedo usarlo comercialmente? | Depende de la **licencia de la herramienta**, no de la ley general | Lee los términos de cada herramienta antes de integrarla |
| ¿Me pueden reclamar por parecido con una obra? | Es posible; el riesgo depende de la herramienta y del prompt | Evita nombres de artistas y estilos identificables en el prompt |
| ¿Me cubre el proveedor? | Algunos ofrecen indemnización **con condiciones** | Léelas: suelen exigir usar sus filtros y no eludirlos |
| ¿Debo declararlo? | **Sí** en varias tiendas; algunas distinguen preproducción de contenido final | Consulta la política vigente antes de cada publicación |
| ¿Y la voz de una persona real? | Requiere consentimiento explícito y suele exigir contrato | No lo hagas sin acuerdo por escrito |

La conclusión práctica es doble y conviene tenerla clara: **la licencia de la herramienta importa más que la ley general** para el uso comercial, y **la trazabilidad es tu única defensa** si algo se cuestiona.

5. **Uso por fases.** No todo el uso tiene el mismo riesgo, y tratarlo igual es un error:

| Fase | Ejemplo | Riesgo | Requisitos |
|---|---|---|---|
| **Exploración** | Concept art para decidir la dirección visual | Muy bajo | Solo registrar; no se publica |
| **Referencia** | Moodboard, paleta, silueta | Bajo | Registrar; no se distribuye |
| **Base de trabajo** | Textura que un artista repinta encima | Medio | Registrar + documentar la transformación |
| **Placeholder** | Sprite temporal hasta tener el final | Medio | Registrar + tarea de sustitución |
| **Contenido final** | Textura que se publica tal cual | **Alto** | Todo: procedencia, revisión aprobada, divulgación |

La mayor parte del valor real está en las dos primeras filas, donde el riesgo es mínimo: explorar veinte direcciones visuales en una tarde es una ventaja enorme y no llega a publicarse nunca.

6. **La revisión humana.** No es un trámite; es control de calidad **y** argumento de autoría:

```markdown
## Revisión de asset generado

- [ ] **Calidad**: ¿está a la altura del resto del juego, sin artefactos ni costuras?
- [ ] **Coherencia**: ¿encaja con la dirección de arte y la paleta?
- [ ] **Técnica**: ¿resolución, formato, compresión y presupuesto correctos? (clase 330)
- [ ] **Contenido**: ¿hay texto ilegible, símbolos no deseados, elementos reconocibles?
- [ ] **Parecido**: ¿se parece demasiado a una obra o un personaje existente?
- [ ] **Transformación**: ¿qué ha aportado una persona? ¿está documentado?
- [ ] **Procedencia**: ¿está la entrada completa en `PROCEDENCIA.json`?
- [ ] **Decisión**: aprobado / rechazado / aprobado con cambios — y quién firma
```

El punto de "parecido" es el que más se salta y el que más problemas da: una salida que reproduce un personaje reconocible no es un problema técnico, es un problema legal.

7. **La política de equipo.** Explícita, publicable y con la dimensión laboral incluida:

```markdown
# Política de IA generativa — Estudio X

## Desarrollo (código, tests, documentación)
Permitido con verificación obligatoria (clase 328). Nada entra sin compilar,
pasar tests y ser revisado por una persona que pueda mantenerlo.

## Arte
- Exploración y referencia: **permitido**, siempre registrado.
- Base de trabajo transformada por un artista del equipo: **permitido**, con la
  transformación documentada.
- Contenido final sin transformación humana significativa: **no**.
- Nunca se usarán prompts que nombren a artistas vivos ni imiten estilos
  identificables de personas concretas.

## Voz y música
- Voz sintética solo para placeholder interno. La locución publicada la hacen
  personas, con contrato.
- Música generada: solo referencia para el compositor.

## Empleo
El uso de estas herramientas no sustituye puestos del equipo. Se adopta para
reducir trabajo repetitivo, no plantilla. Esta línea es parte de la política y
se revisa con el equipo cada seis meses.

## Divulgación
Se declara todo el contenido generado que llegue a la build, en la ficha de
tienda y en los créditos, con el detalle que exija cada plataforma.

## Trazabilidad
`assets/PROCEDENCIA.json` es obligatorio y lo verifica la CI. Un asset sin
procedencia no entra en la build.
```

8. **Lo que la trazabilidad te permite hacer.** El motivo práctico de todo lo anterior:

| Situación | Con registro | Sin registro |
|---|---|---|
| Una tienda pide detalle del contenido generado | Se genera el informe en un minuto | Días de arqueología, con dudas |
| Una herramienta cambia sus términos | Filtras qué assets la usaron y decides | No sabes cuáles son |
| Alguien reclama por parecido | Tienes prompt, semilla y fecha | No puedes documentar nada |
| Hay que regenerar con más resolución | Tienes prompt, semilla y parámetros | Vuelta a empezar |
| Un artista se incorpora al equipo | Sabe qué es qué y qué puede tocar | Pregunta uno por uno |
| Quieres publicar en una tienda con política estricta | Sabes si cumples | Riesgo de retirada |

## ✍️ Ejercicios

1. Crea `assets/PROCEDENCIA.json` para tu proyecto e incluye **todos** los assets, no solo los generados.
2. Implementa el validador y añádelo a la CI; cuenta cuántos assets no tienen procedencia hoy.
3. Genera el informe de divulgación automáticamente y compáralo con lo que declaras hoy.
4. Lee los términos de una herramienta generativa y resume en cinco líneas qué te permite y qué no.
5. Revisa la política de contenido generado de dos tiendas y anota sus diferencias.
6. Aplica la lista de revisión a un asset generado real y documenta la decisión.
7. Redacta la política de IA de tu equipo, incluida la sección de empleo.

## 📝 Reto verificable

Implementa un sistema de procedencia completo: registro `PROCEDENCIA.json` con **todos** los assets del proyecto clasificados por origen, validador en CI con campos obligatorios por origen, generador del informe de divulgación, lista de revisión documentada y política de equipo escrita.

**Criterio de aceptación**: (a) el validador falla si existe cualquier asset sin entrada en el registro, indicando su ruta; (b) falla si a un asset generado le falta cualquiera de sus campos obligatorios, indicando cuál; (c) falla si un asset `generado_ia` marcado como `contenido_final` no tiene `revision_humana.estado == "aprobado"`; (d) falla si el registro declara un asset que ya no existe en disco; (e) el informe de divulgación se genera automáticamente del registro y agrupa por categoría; (f) la política de equipo cubre desarrollo, arte, voz, música, empleo, divulgación y trazabilidad; (g) el registro contiene al menos un asset de cada uno de los cuatro orígenes (`humano`, `generado_ia`, `generado_codigo`, `terceros`).

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| No se sabe de dónde salió un asset | No se registró al generarlo. Es irrecuperable: registra siempre en el momento. |
| No se puede regenerar una variante | Falta la semilla o los parámetros. Guárdalos todos. |
| La tienda retira el juego por no declarar contenido generado | Se ignoró la política. Revísala antes de cada publicación. |
| Un asset generado llegó a producción sin revisar | No había puerta. El validador de CI es la puerta. |
| El registro está desactualizado | Se mantiene a mano sin verificación. Automatízalo. |
| Se usó una herramienta cuya licencia no permite uso comercial | No se leyeron los términos. Evalúa antes de integrar. |
| Un asset se parece demasiado a una obra conocida | El prompt nombraba un estilo o autor. Prohíbelo en la política. |
| El equipo está incómodo con el uso de IA | No hay política ni conversación. Escríbela y discútela. |

## ❓ Preguntas frecuentes

**❓ ¿Puedo usar assets generados en un juego comercial?** Depende de la licencia de la herramienta y de tu jurisdicción, y la respuesta cambia con el tiempo. Lo que sí puedes hacer siempre es **prepararte**: registra la procedencia desde el primer día, porque sin ella no podrás responder a ninguna pregunta después, y esa es la única parte que está enteramente en tu mano.

**❓ ¿Merece la pena todo esto para un proyecto pequeño?** El registro son quince minutos de configuración y treinta segundos por asset. Compáralo con reconstruir el origen de 400 archivos cuando una tienda te lo pida, o con no poder regenerar una textura porque perdiste la semilla.

**❓ ¿Y si transformo mucho el resultado?** Cuanta más aportación humana, mejor posición en casi todos los ejes: calidad, autoría y defensa ante reclamaciones. Pero **documenta la transformación** en `post_proceso`: "lo retoqué bastante" no es un registro; "corrección de tileado manual, ajuste de niveles, repintado del 40 % superior" sí.

**❓ ¿Debo declararlo aunque solo lo use para concept art?** Depende de la plataforma: algunas distinguen entre contenido que llega al jugador y material de preproducción. Por eso el registro tiene el campo `uso`: te permite generar el informe con el criterio que cada tienda pida, sin rehacer el trabajo.

**❓ ¿Cuál es la postura correcta sobre el impacto laboral?** No hay una respuesta única, y el programa no va a fingir que la tiene. Lo que sí es exigible profesionalmente es **tener una postura explícita, escrita y hablada con el equipo**, porque afecta a personas concretas, a contratos y a cómo se percibe tu juego. Una política que no menciona el asunto está tomando una postura igualmente, solo que sin decirlo.

## 🔗 Referencias

- C2PA — estándar abierto de credenciales de procedencia de contenido: <https://c2pa.org/>
- Content Authenticity Initiative — implementaciones y herramientas: <https://contentauthenticity.org/>
- U.S. Copyright Office — orientación sobre obras con material generado por IA: <https://www.copyright.gov/ai/>
- Oficina de Propiedad Intelectual de la UE (EUIPO) — recursos sobre PI: <https://www.euipo.europa.eu/>
- Steamworks — políticas de contenido y divulgación: <https://partner.steamgames.com/doc/gettingstarted>
- Creative Commons — tipos de licencia y su alcance: <https://creativecommons.org/licenses/>

## ⬅️ Clase anterior

[Clase 328 - Código generado por IA con verificación](../328-codigo-generado-por-ia-con-verificacion/README.md)

## ➡️ Siguiente clase

[Clase 330 - Pipeline técnico de assets asistido por IA](../330-pipeline-tecnico-de-assets-asistido-por-ia/README.md)
