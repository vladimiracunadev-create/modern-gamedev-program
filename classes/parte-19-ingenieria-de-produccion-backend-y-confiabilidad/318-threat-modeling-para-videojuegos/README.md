# Clase 318 — Threat modeling para videojuegos

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *OWASP Threat Modeling · Metodología STRIDE (Microsoft)*
> ⏱️ Duración estimada: **115 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Aprender a **modelar amenazas**: un método sistemático para descubrir, antes de que ocurra, qué puede salir mal en tu juego y quién tiene incentivo para provocarlo. No es "pensar en seguridad": es un procedimiento con pasos, con una lista de comprobación y con un entregable — un documento que dice qué defiendes, de quién, y qué has decidido **no** defender y por qué.

La [clase 154](../../parte-7-multijugador-y-networking/154-seguridad-en-multijugador-validacion-y-exploits/README.md) enseñó a validar entradas y a cerrar exploits concretos. Esta clase es el paso anterior: **cómo saber qué hay que validar**. Vas a dibujar los límites de confianza de un juego, aplicar STRIDE a cada uno, priorizar por impacto y probabilidad, y derivar de ahí las defensas concretas — muchas de las cuales ya has construido en esta parte sin saber exactamente contra qué protegían.

Todo el contenido es **defensivo**: identificar riesgos en tu propio sistema y mitigarlos. No se enseñan técnicas para atacar juegos ajenos.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Dibujar un diagrama de flujo de datos con **límites de confianza** explícitos.
2. Aplicar STRIDE sistemáticamente a cada elemento del diagrama.
3. Identificar los activos de un juego y a quién le interesa atacarlos.
4. Priorizar amenazas por impacto, probabilidad y coste de mitigación.
5. Derivar controles concretos y trazarlos hasta el código que los implementa.
6. Documentar riesgos **aceptados** con su justificación.
7. Mantener el modelo vivo: revisarlo cuando cambia la arquitectura.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Activos | Sin saber qué proteges, no puedes decidir cuánto invertir. |
| 2 | Atacantes e incentivos | El perfil del atacante determina el nivel de defensa razonable. |
| 3 | Diagrama de flujo de datos | Hace visible lo que se piensa "de memoria" y siempre incompleto. |
| 4 | Límite de confianza | Es **el** concepto: todo cruce es un punto de validación. |
| 5 | STRIDE | Seis categorías que cubren casi todo y evitan puntos ciegos. |
| 6 | Priorización | No todo se puede mitigar: hay que elegir con criterio. |
| 7 | Controles | La respuesta concreta a una amenaza concreta. |
| 8 | Riesgo aceptado | Decidir no defender algo es legítimo si está escrito. |
| 9 | Trazabilidad | Cada control debe apuntar al código o al proceso que lo cumple. |
| 10 | Modelo vivo | Un modelo de hace dos años describe otro juego. |

## 📖 Definiciones y características

- **Modelo de amenazas**: análisis estructurado de qué puede atacarse, cómo y con qué consecuencia. Clave: es un documento vivo, no un ejercicio único.
- **Activo**: lo que tiene valor y merece protección (cuentas, economía, integridad de la partida, datos personales, disponibilidad). Clave: se enumera primero.
- **Atacante**: perfil con capacidad e incentivo (jugador tramposo, revendedor, estafador, competidor, curioso). Clave: define el nivel de defensa proporcionado.
- **Superficie de ataque**: conjunto de puntos donde alguien puede interactuar con el sistema. Clave: crece con cada función nueva.
- **Diagrama de flujo de datos (DFD)**: dibujo de procesos, almacenes, flujos y límites. Clave: es la base sobre la que se aplica STRIDE.
- **Límite de confianza**: frontera entre zonas con distinto nivel de confianza. Clave: **todo dato que lo cruza debe validarse**.
- **STRIDE**: Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege. Clave: es una lista de comprobación contra puntos ciegos.
- **Spoofing (suplantación)**: hacerse pasar por otro. Clave: se mitiga con autenticación.
- **Tampering (manipulación)**: alterar datos o código. Clave: se mitiga con validación e integridad.
- **Repudiation (repudio)**: negar haber hecho algo. Clave: se mitiga con registros de auditoría.
- **Information disclosure**: filtrar información que no debería verse. Clave: incluye datos del juego (posición de enemigos, cartas del rival).
- **Denial of service**: impedir el uso del sistema. Clave: en juegos incluye tumbar una partida, no solo el servidor.
- **Elevation of privilege**: obtener capacidades que no corresponden. Clave: el más grave, porque habilita todos los demás.
- **Control (mitigación)**: medida concreta que reduce una amenaza. Clave: debe ser verificable.
- **Riesgo residual**: el que queda tras aplicar los controles. Clave: se acepta explícitamente o se escala.
- **Defensa en profundidad**: varias capas independientes de control. Clave: asume que una fallará.
- **Confianza cero en el cliente**: principio de tratar todo dato del cliente como hostil. Clave: es la conclusión práctica de casi todo el modelo.

## 🧰 Herramientas y preparación

No hace falta software: un diagrama y una tabla. Puedes usar papel, [Graphviz](https://graphviz.org/) o cualquier herramienta de diagramas. Documentación de referencia: [OWASP Threat Modeling](https://owasp.org/www-community/Threat_Modeling) y la [hoja de referencia de OWASP](https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html). El entregable de esta clase es un documento que se guarda en el repositorio junto al código, y se revisa como el código.

## 🧪 Laboratorio guiado

1. **Paso 1: los activos.** Qué tienes que vale algo, y para quién:

| Activo | Valor para el jugador | Valor para un atacante |
|---|---|---|
| Cuenta y progreso | Muy alto (horas invertidas) | Alto (reventa de cuentas) |
| Economía del juego | Alto (esfuerzo) | Muy alto (dinero real) |
| Integridad de la partida | Muy alto (que sea justo) | Medio (ventaja competitiva) |
| Datos personales | Muy alto | Alto (fraude, extorsión) |
| Disponibilidad del servicio | Alto | Bajo/medio (sabotaje, extorsión) |
| Contenido no publicado | Bajo | Medio (filtraciones, hype) |
| Código y assets | Bajo | Bajo/medio (clones, piratería) |

2. **Paso 2: los atacantes.** Nombrarlos evita defender de fantasmas y olvidar lo real:

| Perfil | Capacidad | Incentivo | Defensa proporcionada |
|---|---|---|---|
| Jugador curioso | Baja (editar un JSON) | Diversión | Validación básica; asumible en single-player |
| Tramposo competitivo | Media (herramientas públicas) | Ganar | Autoridad de servidor, detección de anomalías |
| Explotador de economía | Media-alta | Dinero real | Idempotencia, auditoría, límites |
| Estafador de cuentas | Media | Reventa | Autenticación fuerte, revocación |
| Atacante de disponibilidad | Variable | Sabotaje | Límites, protección de infraestructura |
| Automatizador (bots) | Alta | Ventaja o beneficio | Rate limiting, detección de patrones |

3. **Paso 3: el diagrama con límites de confianza.** El dibujo que hace visible lo invisible:

```text
┌─────────────────── ZONA NO CONFIABLE (dispositivo del jugador) ──────────────────┐
│                                                                                  │
│   ┌──────────┐      ┌────────────┐      ┌──────────────┐      ┌──────────────┐   │
│   │  Entrada │─────►│  Cliente   │─────►│ Save local   │      │ Mods / packs │   │
│   │ (teclado)│      │  del juego │◄─────│ (user://)    │─────►│ (user://)    │   │
│   └──────────┘      └─────┬──────┘      └──────────────┘      └──────────────┘   │
│                           │                                                      │
└───────────────────────────┼══════ LÍMITE DE CONFIANZA (la red) ══════════════════┘
                            │
┌───────────────────────────┼─────────── ZONA CONFIABLE (tu backend) ──────────────┐
│                    ┌──────▼───────┐                                              │
│                    │ API Gateway  │  ◄── autenticación, límites, validación       │
│                    └──┬────────┬──┘                                              │
│          ┌────────────▼──┐  ┌──▼───────────┐  ┌──────────────┐                   │
│          │ Perfil/Economía│  │ Matchmaking │  │ Telemetría   │                   │
│          └────────┬───────┘  └──────┬──────┘  └──────────────┘                   │
│                   │                 │                                            │
│            ┌──────▼──────┐   ┌──────▼─────────┐                                  │
│            │ Base de datos│   │ Servidor       │ ◄── simulación autoritativa       │
│            └─────────────┘   │ dedicado       │                                  │
│                              └────────────────┘                                  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

Ese doble trazo es lo único que hay que recordar: **todo lo que lo cruza de arriba abajo se valida**. Sin excepciones, sin "esto lo manda nuestro propio cliente".

4. **Paso 4: STRIDE, elemento por elemento.** La parte mecánica, y por eso funciona:

| Elemento | S | T | R | I | D | E |
|---|---|---|---|---|---|---|
| Cliente del juego | — | ✔ binario y memoria modificables | — | ✔ expone datos del mundo | — | ✔ si valida él |
| Save local | — | ✔ editable | — | ✔ contiene estado | — | — |
| Red cliente↔servidor | ✔ suplantar sesión | ✔ paquetes alterados | ✔ negar acción | ✔ escucha | ✔ inundación | — |
| API Gateway | ✔ token robado | ✔ parámetros | ✔ sin registro | ✔ mensajes de error | ✔ sin límites | ✔ autorización débil |
| Servicio de economía | — | ✔ duplicación | ✔ "yo no compré" | — | ✔ operaciones caras | ✔ operar sobre otro |
| Servidor dedicado | ✔ cliente falso | ✔ estado inyectado | — | ✔ ve todo el mapa | ✔ colgarlo | — |
| Mods / packs | ✔ suplantar mod oficial | ✔ contenido alterado | — | ✔ leer archivos | ✔ romper el juego | ✔ ejecutar código |
| Telemetría | ✔ eventos falsos | ✔ métricas envenenadas | — | ✔ datos personales | ✔ inundar la ingesta | — |

5. **Paso 5: priorizar.** No todo se mitiga; hay que elegir con criterio, no con miedo:

```text
Riesgo ≈ Impacto × Probabilidad ÷ Coste de mitigación

Impacto:      1 molesto · 2 perjudica a un jugador · 3 perjudica a muchos
              4 daña la economía o la confianza · 5 daño legal o de negocio
Probabilidad: 1 requiere capacidades excepcionales · 3 herramientas públicas
              5 lo hará alguien la primera semana
```

| Amenaza | I | P | Riesgo | Mitigación | Estado |
|---|---|---|---|---|---|
| Cliente decide su oro | 5 | 5 | Crítico | Autoridad de servidor (clase 314) | Implementado |
| Duplicación por reintento | 5 | 4 | Crítico | Claves de idempotencia (314) | Implementado |
| Token robado sin revocación | 4 | 3 | Alto | Rotación y revocación (312) | Implementado |
| Speed hack en partida | 3 | 4 | Alto | Validación de movimiento (148, 319) | Implementado |
| Editar el save en single-player | 1 | 5 | Bajo | **Aceptado**: no afecta a terceros | Aceptado |
| Mod malicioso | 4 | 2 | Medio | Consentimiento informado, plataforma (309) | Parcial |
| Ver la posición de rivales | 3 | 3 | Medio | No enviar lo que no se ve (fog of war en servidor) | Pendiente |
| Inundar la ingesta de telemetría | 2 | 2 | Bajo | Rate limiting y cuotas (316) | Implementado |

6. **Paso 6: la trazabilidad.** Un control que no apunta a código es una intención:

```markdown
### C-07 — Toda operación económica es idempotente

- **Amenaza**: T (tampering) / duplicación por reintento en el límite de red.
- **Control**: clave de idempotencia generada por el cliente, resultado
  memorizado en el servidor.
- **Implementación**: `servidor/economia/servicio_economia.gd:ejecutar()`
- **Verificación**: `pruebas/economia_test.gd` — "el mismo comando cinco veces
  produce un solo efecto".
- **Riesgo residual**: una clave reutilizada intencionadamente por el cliente
  para "cancelar" una compra legítima. Mitigado por caducidad de 24 h.
```

7. **Paso 7: los riesgos aceptados.** Escribirlos es lo que los convierte en decisiones:

```markdown
### RA-02 — El save local es editable

El jugador puede modificar `user://saves/slot_0.json` y darse objetos.

- **Por qué se acepta**: en modo un jugador no perjudica a terceros ni a la
  economía (que es local). Impedirlo requeriría autoridad de servidor para una
  experiencia offline, con un coste desproporcionado.
- **Límite**: si en el futuro hay tablas de clasificación **globales** o
  intercambio de objetos entre jugadores, este riesgo deja de ser aceptable y
  hay que revisar la decisión.
- **Detección**: el checksum detecta ediciones torpes y se registra como
  telemetría anónima, sin sancionar.
```

Ese apartado "límite" es lo que hace útil el documento a los dos años: **dice cuándo deja de valer la decisión**.

8. **Paso 8: mantenerlo vivo.** Un modelo que no se revisa describe un juego que ya no existe:

- Se revisa cuando **se añade un límite de confianza** (una función online nueva, un SDK, mods).
- Se revisa cuando **cambia el modelo de negocio** (aparecen compras, aparece competitivo).
- Se revisa tras **cada incidente**: lo que ocurrió estaba en el modelo o faltaba.
- Vive en el repositorio, en `docs/`, y su cambio pasa por revisión como el código.

## ✍️ Ejercicios

1. Dibuja el DFD de tu propio juego con sus límites de confianza reales.
2. Aplica STRIDE a los tres elementos que más te preocupen y anota al menos dos amenazas por elemento.
3. Prioriza las amenazas encontradas con la fórmula del paso 5.
4. Escribe tres fichas de control con su trazabilidad a código y prueba.
5. Escribe dos riesgos aceptados con su condición de caducidad.
6. Revisa el modelo suponiendo que añades intercambio de objetos entre jugadores: ¿qué cambia?
7. Haz una sesión de modelado de 45 minutos con otra persona y compara los hallazgos.

## 📝 Reto verificable

Entrega un documento de modelo de amenazas de un juego (el tuyo o el del capstone) en `docs/modelo-amenazas.md` que contenga: inventario de activos, perfiles de atacante, DFD con límites de confianza, tabla STRIDE completa para **al menos seis elementos**, priorización cuantificada de **al menos doce amenazas**, **al menos ocho fichas de control** con trazabilidad a archivo y prueba, y **al menos tres riesgos aceptados** con su condición de caducidad.

**Criterio de aceptación**: (a) cada elemento del DFD aparece en la tabla STRIDE con las seis categorías consideradas (aunque sea para descartarlas con motivo); (b) cada amenaza priorizada tiene impacto, probabilidad y estado; (c) cada ficha de control apunta a un archivo y una prueba que **existen** en el repositorio y pasan; (d) cada riesgo aceptado indica explícitamente qué cambio lo haría inaceptable; (e) el documento identifica al menos una amenaza que **no** estuviera ya mitigada, con su plan; (f) el documento indica su fecha de revisión y qué eventos disparan la siguiente.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El modelo dice "validamos todo" y no dice dónde | Falta trazabilidad. Cada control apunta a archivo y prueba. |
| Se defienden amenazas improbables y falta lo obvio | No se priorizó. Aplica impacto × probabilidad. |
| El diagrama no tiene límites de confianza | Es un diagrama de arquitectura, no un DFD. Dibuja las fronteras. |
| "Nuestro cliente no manda datos falsos" | Confianza en el cliente. Todo lo que cruza el límite se valida. |
| El modelo tiene dos años y la arquitectura cambió | No hay proceso de revisión. Ligalo a los cambios de arquitectura. |
| Se aceptan riesgos sin escribirlos | Entonces no son decisiones, son olvidos. Documenta con su caducidad. |
| El modelo lo hizo una persona sola | Se pierden puntos ciegos. Hazlo en pareja o en grupo pequeño. |
| Se confunden amenazas con vulnerabilidades | La amenaza es lo que alguien quiere hacer; la vulnerabilidad, el fallo que se lo permite. Modela lo primero. |

## ❓ Preguntas frecuentes

**❓ ¿Es esto necesario para un juego indie?** El método completo, no siempre. Pero el **dibujo de límites de confianza** y una pasada de STRIDE ocupan una tarde y cambian decisiones de arquitectura que después cuestan meses. Si tu juego tiene cualquier componente online, hazlo.

**❓ ¿STRIDE u otra metodología?** STRIDE es la más fácil de aplicar sin formación previa y cubre bien el caso de los juegos. Existen otras (PASTA, LINDDUN para privacidad) más completas y más caras de aplicar. Para privacidad, LINDDUN complementa bien lo de la [clase 317](../317-telemetria-privacidad-y-gobernanza-de-datos/README.md).

**❓ ¿Cuándo hago el modelo?** Al diseñar la arquitectura, **antes** de implementarla: es cuando cambiar decisiones es barato. Después se revisa, no se rehace. Hacerlo al final convierte hallazgos en deuda.

**❓ ¿Y si encuentro una amenaza que no puedo mitigar?** La documentas como riesgo aceptado con su justificación y su condición de caducidad, y añades **detección** aunque no puedas prevenir. Saber que está ocurriendo ya es una mitigación parcial: es lo que permite reaccionar.

**❓ ¿Esto no enseña a atacar?** Enseña a **encontrar tus propios fallos**, que es lo mismo que hace cualquier revisión de seguridad. No incluye herramientas ni técnicas ofensivas, y la [clase 319](../319-anti-cheat-y-respuesta-frente-al-abuso/README.md) mantiene el mismo criterio: defensa de lo tuyo, nunca ataque a lo ajeno.

## 🔗 Referencias

- OWASP — Threat Modeling: <https://owasp.org/www-community/Threat_Modeling>
- OWASP — Threat Modeling Cheat Sheet: <https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html>
- Microsoft — STRIDE y el proceso de modelado de amenazas: <https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats>
- OWASP — Top Ten (referencia de categorías de riesgo en aplicaciones): <https://owasp.org/www-project-top-ten/>
- Adam Shostack — *Threat Modeling: Designing for Security*: <https://shostack.org/books/threat-modeling-book>

## ⬅️ Clase anterior

[Clase 317 - Telemetría, privacidad y gobernanza de datos](../317-telemetria-privacidad-y-gobernanza-de-datos/README.md)

## ➡️ Siguiente clase

[Clase 319 - Anti-cheat y respuesta frente al abuso](../319-anti-cheat-y-respuesta-frente-al-abuso/README.md)
