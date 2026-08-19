# Informe de refresco de fuentes

Generado por `scripts/refresh-sources` el **2026-08-19**. Este informe **no bloquea la CI**: el gate obligatorio es `scripts/verify-sources`, que es offline.

- Entradas comprobadas: **207** de 207
- Resolvieron: **206**
- Dejaron de resolver: **1**
- Resolvieron pero el servidor rechaza clientes automáticos: **31**
- Metadatos que no casan con el registro: **0**
- Huecos ya declarados en el registro (`pendiente`): **3**

## Dejaron de resolver

No se borran. Quedan marcadas `pendiente` con su motivo.

| Obra | Tipo | Localizador | Motivo |
|---|---|---|---|
| `orkin-goap` | reference | <https://alumni.media.mit.edu/~jorkin/goap.html> | El localizador no resuelve (HTTP 404). |

## Sin verificación automática posible

Estos servidores rechazan al cliente (401/403) o limitan el ritmo por IP (429, o la conexión cortada tras varios intentos). No es prueba de que la fuente esté rota; tampoco de que siga viva. Se dejan como estaban y se listan aquí para que quien las mire sepa qué no se pudo comprobar.

| Obra | Estado HTTP | Localizador |
|---|---:|---|
| `anthropy-clark-game-design-vocabulary` | 0 | <https://openlibrary.org/isbn/9780321886927> |
| `artstation` | 403 | <https://artstation.com/> |
| `beyer-site-reliability-engineering` | 0 | <https://openlibrary.org/isbn/9781491929124> |
| `chacon-pro-git` | 0 | <https://openlibrary.org/isbn/9781484200773> |
| `euipo` | 403 | <https://euipo.europa.eu/> |
| `fabian-data-oriented-design` | 0 | <https://openlibrary.org/isbn/9781916478701> |
| `ftc-privacidad-infantil` | 403 | <https://ftc.gov/> |
| `game-ui-database` | 403 | <https://gameuidatabase.com/> |
| `keith-agile-game-development` | 0 | <https://openlibrary.org/isbn/9780321618528> |
| `kickstarter-learn` | 403 | <https://kickstarter.com/> |
| `kleppmann-designing-data-intensive-applications` | 0 | <https://openlibrary.org/isbn/9781449373320> |
| `lehdonvirta-virtual-economies` | 0 | <https://openlibrary.org/isbn/9780262027250> |
| `lengyel-foundations-game-engine-development` | 0 | <https://openlibrary.org/isbn/9780985811747> |
| `lengyel-mathematics-for-3d-game-programming` | 0 | <https://openlibrary.org/isbn/9781435458864> |
| `linux-netem` | 403 | <https://wiki.linuxfoundation.org/> |
| `liquipedia` | 403 | <https://liquipedia.net/> |
| `ludum-dare` | 0 | <https://ldjam.com/> |
| `mark-behavioral-mathematics` | 0 | <https://openlibrary.org/isbn/9781584506843> |
| `mit-press` | 403 | <https://mitpress.mit.edu/> |
| `phaser` | 403 | <https://docs.phaser.io/> |
| `rabin-introduction-to-game-development` | 0 | <https://openlibrary.org/isbn/9781584506799> |
| `rogers-level-up` | 0 | <https://openlibrary.org/isbn/9781118877166> |
| `salen-zimmerman-rules-of-play` | 0 | <https://openlibrary.org/isbn/9780262240451> |
| `schreier-blood-sweat-pixels` | 0 | <https://openlibrary.org/isbn/9780062651235> |
| `shaker-procedural-content-generation` | 0 | <https://openlibrary.org/isbn/9783319427140> |
| `shostack-threat-modeling` | 0 | <https://openlibrary.org/isbn/9781118809990> |
| `sutton-barto-reinforcement-learning` | 0 | <https://openlibrary.org/isbn/9780262039246> |
| `swink-game-feel` | 0 | <https://openlibrary.org/isbn/9780123743282> |
| `unreal-docs` | 403 | <https://dev.epicgames.com/> |
| `williams-animators-survival-kit` | 0 | <https://openlibrary.org/isbn/9780571238347> |
| `wwise-audiokinetic` | 403 | <https://audiokinetic.com/> |

## Huecos declarados en el registro

| Obra | Motivo declarado |
|---|---|
| `gdc-vault` | Las 53 citas del programa apuntan a la raíz del catálogo: ninguna identifica una charla concreta, así que ninguna cumple ponente + título + año + sesión. El catálogo sí es una fuente real y se conserva como tal, pero cada charla concreta queda por resolver. La búsqueda de gdcvault.com se resuelve por JavaScript en el navegador y no devuelve resultados a un cliente HTTP, por lo que refresh-sources no puede resolverlas automáticamente: hay que identificarlas a mano. Las citas de clase se han reescrito para declarar que apuntan al catálogo por tema, no a una charla. |
| `gdc-youtube` | Mismo hueco que gdc-vault: las citas apuntan al canal, no a una charla concreta con ponente y año. Los identificadores antiguos del canal (/user/gdconf, /@Gdconf) devuelven 404; el canal vigente es youtube.com/@GDC y a él se han migrado las citas. |
| `orkin-goap` | La página del autor en alumni.media.mit.edu devuelve 404 y no se ha localizado un localizador estable (ISBN, DOI o URL primaria viva) que la sustituya. La cita se conserva marcada; no se inventa un reemplazo. |

