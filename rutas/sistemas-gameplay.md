# 🎒 Programador de sistemas de gameplay

> Diseñas las reglas que otros usan: inventario, stats, habilidades, quests y economía.
> Sistemas que se combinan entre sí y que **nadie puede reescribir a mitad de producción**.
>
> **Nivel de entrada:** intermedio-avanzado · **Foco:** arquitectura de contenido · **Hito faro:** un juego sistémico con guardado migrable

## 🧭 Qué es y por qué importa

Mientras el programador de gameplay hace que el salto se sienta bien, el programador de **sistemas** hace que trescientos objetos, cuarenta habilidades y sesenta quests convivan sin contradecirse. Su producto no es una mecánica: es una **arquitectura** que diseño y contenido pueden usar durante años sin pedirle permiso.

Importa porque estos sistemas son los más caros de cambiar. Un controlador de personaje se reescribe en una semana; un sistema de inventario mal diseñado se arrastra hasta el final del proyecto y contagia al guardado, a la UI, a la economía y a las quests. La decisión que tomas el primer mes decide cuántas ideas serán viables el último.

Es un rol de segunda etapa: se llega después de haber hecho juegos, cuando ya has sufrido el acoplamiento. Enseñarlo antes es enseñar burocracia sin causa.

## 🗓️ Un día en el puesto

- **Recibir una petición de diseño** que suena simple: «que los anillos den bonus condicionales según la facción». Traducirla a un cambio de modelo sin romper lo existente.
- **Diseñar el dato antes que el código.** Cómo se declara ese objeto en JSON para que diseño lo edite sin ti.
- **Escribir pruebas.** Aquí sí: los sistemas se prueban solos, sin abrir el juego, porque tienen entradas y salidas claras.
- **Pelear con casos límite:** ¿qué pasa si fabricas sin espacio? ¿si te quitan un objeto equipado? ¿si dos efectos aplican la misma etiqueta?
- **Migrar guardados.** Cada cambio de estructura obliga a pensar en las partidas que ya existen.
- **Revisar el acoplamiento.** La pregunta constante: ¿este sistema necesita conocer a ese otro, o basta con un evento?

## 🧠 Qué necesitas saber

### Conocimiento técnico

- **Definición frente a instancia.** La distinción que evita congelar los datos del juego dentro de las partidas guardadas ([clase 294](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/294-items-y-base-de-datos-de-objetos/README.md)).
- **Transacciones atómicas con rollback.** Una operación que toca varios sistemas se valida entera antes de aplicar nada ([clase 295](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/295-sistema-de-inventario/README.md)).
- **Stats por modificadores:** la base nunca cambia, el valor final se deriva ([clase 296](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/296-equipamiento-loadouts-y-estadisticas/README.md)).
- **Etiquetas con conteo por fuente**, para que curar el veneno no quite también la ralentización de la maldición ([clase 298](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/298-status-effects-buffs-y-debuffs/README.md)).
- **Aleatoriedad inyectada y determinista.** Sin RNG controlable no hay replays, ni pruebas, ni depuración ([clase 300](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/300-loot-tables-y-sistemas-de-recompensas/README.md)).
- **Guardado versionado con migraciones encadenadas.** Lo que separa un parche de una catástrofe ([clase 307](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/307-save-system-de-produccion/README.md)).
- **Eventos frente a llamadas directas**, y cuándo cada uno. El acoplamiento no se elimina: se coloca donde duele menos.

### Herramientas del oficio

- **Datos en archivos legibles** (JSON, recursos del motor) y un validador que falle pronto y claro.
- **Un arnés de pruebas** que corra sin abrir el juego, como el del 🧪 [lab de sistemas de gameplay](../labs/gameplay-systems/README.md) (122 comprobaciones).
- **Hojas de cálculo** para el balance, exportadas a datos por script ([clase 259](../classes/parte-15-herramientas-editores-y-automatizacion/259-generacion-y-validacion-de-datos-data-driven/README.md)).
- **Herramientas de editor** para que diseño no dependa de ti para cada cambio ([Parte 15](../classes/parte-15-herramientas-editores-y-automatizacion/README.md)).

### Habilidades no técnicas

- **Decir «todavía no» sin bloquear.** Buena parte del rol es proteger la arquitectura de peticiones puntuales que la romperían.
- **Anticipar el contenido futuro** sin caer en la sobreingeniería. La línea es fina y se aprende equivocándose.
- **Documentar el modelo.** Un sistema que solo tú entiendes es un sistema que solo tú puedes tocar.
- **Escuchar a diseño de verdad.** El sistema existe para que ellos trabajen rápido, no al revés.

## 📚 Tu ruta en el programa

1. ✅ **Requisito:** la ruta de [**Programador de gameplay**](gameplay.md) completa, incluida la [Parte 5](../classes/parte-5-inteligencia-artificial-para-juegos/README.md).
2. 📚 [**Parte 18 — Arquitectura de gameplay**](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/README.md) (293–310). **El núcleo**, con el 🧪 [lab de sistemas de gameplay](../labs/gameplay-systems/README.md).
3. 🎯 **Hito**: inventario con transacciones atómicas y guardado con migraciones encadenadas ([clase 310](../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/310-capstone-parte-18-un-juego-sistemico/README.md)).
4. 📚 [**Parte 8 — Game design**](../classes/parte-8-game-design-y-diseno-de-niveles/README.md) (156–171). Si te la saltaste: diseñarás sistemas sin saber para qué.
5. 📚 [**Parte 16 — Economía y LiveOps**](../classes/parte-16-produccion-publicacion-monetizacion-y-liveops/README.md) (267–280). Lo que pasa cuando tus sistemas tienen dinero dentro.
6. 📚 [**Parte 19 — Confiabilidad**](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md) (311–324). Si el inventario vive en un servidor, es otro problema.

## 🎓 Qué te contrata

- **Un sistema completo y probado**, con su suite ejecutable. Aquí sí puedes enseñar pruebas: es de los pocos sitios del gamedev donde son naturales.
- **El diagrama de tu modelo de datos** y las decisiones que descartaste. El «por qué no» vale más que el «qué».
- **Una migración de guardado real** de v1 a v3, con partidas antiguas que siguen cargando.
- **Un archivo de datos que un diseñador pueda leer** sin explicación. Si hace falta un manual, el diseño del dato falló.

## 📈 Progresión de carrera y salario

1. **Gameplay programmer** con sistemas a su cargo — el punto de entrada natural.
2. **Systems programmer / gameplay systems engineer** — dueño de una familia de sistemas completa.
3. **Senior** — defines el modelo de contenido del juego y las herramientas que lo alimentan.
4. **Especialización:** [arquitecto técnico](arquitecto-tecnico.md), lead de gameplay o [backend y online](backend-online.md) si el contenido pasa a servidor.

Rangos **orientativos** (brutos anuales):

- **LATAM:** entrada aproximada USD 15.000–28.000; con experiencia USD 30.000–55.000+.
- **España:** entrada aproximada 26.000–34.000 €; senior 45.000–62.000 €+.
- **Remoto / USD:** seniors por encima de USD 95.000–130.000. Es un perfil senior por definición: casi no existe la versión junior.

## ⚠️ Mitos y errores comunes

- **«Esto es solo un inventario, lo hago en una tarde.»** Lo haces en una tarde y lo arrastras dos años. Las decisiones baratas se pagan caras.
- **«Guardo el objeto entero en la partida.»** Y congelas el balance dentro de cada guardado. Guarda el id y el estado propio.
- **«Sumo el bonus al equipar y lo resto al desequipar.»** Acumulas error y cualquier fallo de orden queda grabado. La base no se toca.
- **«El guardado ya lo versionaré cuando haga falta.»** Hará falta el día del primer parche, y entonces ya no se puede.
- **«Cuanto más genérico, mejor.»** Un sistema que sirve para todo no sirve para nada y nadie sabe usarlo. Generaliza cuando aparezca el segundo caso, no antes.
- **«Las pruebas en gameplay no valen.»** En sistemas, sí: hay entradas, salidas y reglas. Es la parte del juego que más se beneficia de ellas.

## 🚀 Siguientes pasos

1. Coge un juego tuyo que ya funcione y **añádele un inventario de verdad**, con apilado, límites y transacciones.
2. Haz el 🧪 [lab de sistemas de gameplay](../labs/gameplay-systems/README.md) desde `inicio/`; los TODO están puestos justo en las decisiones que importan.
3. Escribe **una prueba por caso límite** antes de arreglarlo. Es el hábito que más rinde en este rol.
4. Versiona tu guardado desde el día uno, aunque solo tengas la v1. La v2 llega antes de lo que crees.
5. Saca todo el contenido a datos y **pide a alguien que añada un objeto sin tu ayuda**. Si no puede, el sistema aún no está terminado.
6. Cuando el contenido pase a servidor, entra en la [**Parte 19**](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md).

---

- ⬅️ [Volver al índice de rutas](./README.md)
- 🏠 [Inicio del programa](../README.md)
