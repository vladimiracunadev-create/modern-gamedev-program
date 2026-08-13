# ☁️ Ingeniero de backend y online

> Lo que la gente ve cuando tu juego falla. Este rol se mide en incidentes evitados,
> no en funciones entregadas.
>
> **Nivel de entrada:** avanzado · **Foco:** confiabilidad y operación · **Hito faro:** un cliente que sobrevive a un servidor hostil

## 🧭 Qué es y por qué importa

El ingeniero de backend/online sostiene todo lo que el juego necesita **fuera** del dispositivo del jugador: cuentas, inventarios en servidor, compras, guardados en la nube, configuración remota, telemetría y parches. Y sostiene también la parte del cliente que habla con todo eso, que es donde se decide si un corte de red es una molestia o una partida perdida.

Importa porque el juego que funciona en tu máquina no es el juego que existe. En producción hay red que falla a medias, respuestas que llegan tarde, apagones durante la escritura del guardado y jugadores que no son los de tu playtest. La diferencia entre un juego que aguanta y uno que no rara vez está en el código de gameplay: está aquí.

Es un rol de segunda etapa, hermano del de [multijugador](multijugador.md) pero distinto: allí el problema es la latencia dentro de una partida; aquí es la **durabilidad** del estado a lo largo de años y parches.

## 🗓️ Un día en el puesto

- **Mirar los tableros.** Tasa de error, latencias, colas. Antes de escribir nada, saber cómo está el servicio.
- **Atender o revisar un incidente.** Qué falló, qué lo detectó, cuánto tardó en recuperarse y qué se cambia para la próxima.
- **Diseñar una operación nueva** pensando primero en cómo puede fallar: reintentos, idempotencia, tiempo de espera, degradación.
- **Trabajar con feature flags:** activar algo para el 5 %, mirar los números, decidir si sigue o se apaga ([clase 315](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/315-remote-config-feature-flags-y-experimentos/README.md)).
- **Revisar telemetría y privacidad.** Qué se registra, con qué consentimiento y durante cuánto tiempo ([clase 317](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/317-telemetria-privacidad-y-gobernanza-de-datos/README.md)).
- **Preparar una release.** Versionado, compatibilidad de guardados, plan de reversión. Lo aburrido que evita los desastres.

## 🧠 Qué necesitas saber

### Conocimiento técnico

- **Fallos parciales.** Un timeout no dice que la operación falló: dice que no sabes qué pasó. De ahí sale todo lo demás.
- **Idempotencia:** claves por operación para que un reintento no cobre dos veces ([clase 314](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/314-economia-transaccional-de-servidor/README.md)).
- **Reintentos con backoff y jitter, y circuit breakers.** Reintentar un servicio caído alarga la caída ([clase 311](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/311-arquitectura-backend-para-videojuegos/README.md)).
- **Autoridad en servidor** para todo lo que tenga valor: economía, entitlements, progresión ([clase 312](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/312-identidad-perfiles-y-entitlements/README.md)).
- **Guardado en la nube y resolución de conflictos** entre dispositivos ([clase 313](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/313-cloud-saves-cross-save-y-resolucion-de-conflictos/README.md)).
- **Observabilidad:** métricas, trazas y registros que sirvan para diagnosticar, no para decorar ([clase 316](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/316-observabilidad-de-juegos/README.md)).
- **Modelado de amenazas y anti-abuso**, siempre en clave **defensiva** ([clases 318](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/318-threat-modeling-para-videojuegos/README.md) y [319](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/319-anti-cheat-y-respuesta-frente-al-abuso/README.md)).
- **Release engineering:** builds reproducibles, parches y recuperación ([clases 322](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/322-build-y-release-engineering/README.md) y [323](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/323-parches-delivery-y-recuperacion/README.md)).

### Herramientas del oficio

- **HTTP/REST y JSON** como base; **Git y CI** como higiene mínima ([Parte 15](../classes/parte-15-herramientas-editores-y-automatizacion/README.md)).
- Un **backend simulado y hostil** para probar: lento, 5xx, caído, corrupto, intermitente. El 🧪 [lab de runtime de producción](../labs/production-runtime/README.md) trae uno con siete modos.
- **Tableros y alertas** (Grafana, Prometheus o el equivalente del proveedor).
- **Servicios gestionados** (Nakama, PlayFab, Steamworks) para no reinventar identidad y matchmaking ([clase 152](../classes/parte-7-multijugador-y-networking/152-backends-nakama-steam-y-servicios-gestionados/README.md)).

### Habilidades no técnicas

- **Pensar en modo fallo.** Ante cada función nueva, la primera pregunta es qué pasa cuando no funciona.
- **Escribir postmortems sin culpables.** Lo que se busca es el fallo del sistema, no el de la persona.
- **Comunicar bajo presión.** Durante un incidente, la mitad del trabajo es informar con claridad.
- **Respeto por los datos ajenos.** La privacidad no es un requisito legal que se cumple al final: es una decisión de diseño.

## 📚 Tu ruta en el programa

1. ✅ **Requisito:** la ruta de [**Programador de multijugador**](multijugador.md), o al menos la [Parte 7](../classes/parte-7-multijugador-y-networking/README.md).
2. 📚 [**Parte 15 — Tooling, CI y automatización**](../classes/parte-15-herramientas-editores-y-automatizacion/README.md) (255–266). La base del oficio.
3. 📚 [**Parte 19 — Producción y confiabilidad**](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md) (311–324). **El núcleo**, con el 🧪 [lab de runtime de producción](../labs/production-runtime/README.md).
4. 🎯 **Hito**: un cliente que sobrevive a un servidor hostil — reintentos, circuit breaker, idempotencia y degradación ([clase 324](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/324-capstone-parte-19-un-runtime-de-produccion/README.md)).
5. 📚 [**Parte 18 — Sistemas de gameplay**](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/README.md) (293–310). Para entender qué estás autorizando en el servidor.
6. 📚 [**Parte 16 — Publicación y LiveOps**](../classes/parte-16-produccion-publicacion-monetizacion-y-liveops/README.md) (267–280). Parches, telemetría y recuperación.

> **Sobre seguridad.** Todo el enfoque del programa es **defensivo**: modelar amenazas contra tu propio juego y cerrarlas. No se desarrollan técnicas ofensivas contra juegos ajenos.

## 🎓 Qué te contrata

- **Un cliente que aguanta un backend roto**, con la demostración de cada modo de fallo y su comportamiento.
- **Un diagrama de una operación crítica** (una compra, por ejemplo) con sus puntos de fallo señalados y cómo se cubre cada uno.
- **Un postmortem escrito**, aunque sea de un proyecto personal. Es el documento que más dice de este perfil.
- **Un guardado con migraciones** y una prueba de que una partida vieja sigue cargando tras tres versiones.

## 📈 Progresión de carrera y salario

1. **Backend / online engineer junior** — implementas endpoints e integraciones dentro de una arquitectura dada.
2. **Online engineer** — dueño de servicios completos y de su comportamiento en fallo.
3. **Senior / SRE de juegos** — defines la arquitectura de servicios, los SLO y la estrategia de release.
4. **Especialización:** infraestructura y plataforma, seguridad defensiva de producto o [arquitecto técnico](arquitecto-tecnico.md).

Rangos **orientativos** (brutos anuales):

- **LATAM:** entrada aproximada USD 15.000–30.000; con experiencia USD 32.000–65.000+.
- **España:** entrada aproximada 26.000–36.000 €; senior 48.000–70.000 €+.
- **Remoto / USD:** seniors por encima de USD 100.000–150.000.

Ventaja poco conocida: es la ruta **más transferible fuera de los videojuegos**. Estas mismas habilidades se pagan igual o mejor en cualquier empresa de software con servicios en producción, lo que da una red de seguridad que otras rutas no tienen.

## ⚠️ Mitos y errores comunes

- **«Si falla, reintento y ya.»** Sin idempotencia, cada reintento es una operación duplicada sobre el dinero del jugador.
- **«Reintento hasta que vuelva.»** Con miles de clientes sincronizados, eso impide que el servidor se levante. Backoff, jitter y circuit breaker.
- **«El cliente puede calcular esto, es inofensivo.»** No hay nada inofensivo: si el cliente lo decide, alguien lo modificará.
- **«Registro todo por si acaso.»** Eso es un problema de privacidad y una factura. Taxonomía cerrada y consentimiento explícito.
- **«Guardo directamente sobre el archivo.»** Un corte a media escritura deja una partida corrupta. Temporal, checksum y renombrado atómico.
- **«La observabilidad es para empresas grandes.»** Sin métricas no sabes que algo falla hasta que te lo cuentan en una reseña.

## 🚀 Siguientes pasos

1. Haz la **Parte 15** si vienes sin CI: sin builds reproducibles, lo demás no se sostiene.
2. Completa el 🧪 [lab de runtime de producción](../labs/production-runtime/README.md) desde `inicio/` y **provoca a propósito** cada uno de los siete modos de fallo.
3. Coge una función online de un juego tuyo y hazla **idempotente**. Comprueba que reintentarla dos veces no duplica nada.
4. Añade guardado versionado con migraciones y prueba cargar una partida de la versión anterior.
5. Monta telemetría con taxonomía cerrada y consentimiento. Registra lo mínimo que responda a una pregunta concreta.
6. Escribe un **postmortem** del primer fallo que te encuentres, por pequeño que sea. Es la práctica que define el rol.

---

- ⬅️ [Volver al índice de rutas](./README.md)
- 🏠 [Inicio del programa](../README.md)
