# 🌐 Programador de multijugador

> Haces que dos personas con 80 ms de latencia entre ellas vean la misma partida.
> Es uno de los roles más difíciles del oficio, y de los mejor pagados.
>
> **Nivel de entrada:** intermedio-avanzado · **Foco:** red, autoridad y determinismo · **Hito faro:** un juego en red cliente-servidor autoritativo funcionando

## 🧭 Qué es y por qué importa

El programador de multijugador resuelve un problema que no tiene solución perfecta: la información tarda en viajar. Todo lo demás —predicción, reconciliación, interpolación, rollback— son formas de **mentir bien** para que la latencia no se note, sin que los jugadores acaben viendo partidas distintas.

Importa porque el multijugador multiplica el valor de un juego (retención, comunidad, vida útil) y porque es la parte que **no se puede añadir después**. Un juego pensado para un jugador y «convertido» a red más tarde suele terminar reescrito. Quien sabe hacerlo bien es escaso, y se nota en las ofertas.

Es también el rol con la peor relación entre esfuerzo y visibilidad: cuando funciona, nadie lo nota; cuando falla, todo el mundo lo nota a la vez y en público.

## 🗓️ Un día en el puesto

- **Reproducir un bug que solo pasa con latencia.** Media hora de simulador de red, tres clientes abiertos y mucha paciencia.
- **Decidir qué es autoritativo.** Cada mecánica nueva trae la misma pregunta: ¿esto lo decide el servidor o lo puede decidir el cliente?
- **Medir ancho de banda y frecuencia de envío.** Cada campo replicado cuesta dinero real en servidores.
- **Depurar desincronizaciones.** Comparar estados, buscar el punto donde divergieron y descubrir que era un `randf()` sin semilla.
- **Trabajar contra el abuso.** Validar entradas, limitar frecuencias, detectar lo imposible ([clase 154](../classes/parte-7-multijugador-y-networking/154-seguridad-en-multijugador-validacion-y-exploits/README.md)).
- **Pruebas con carga**: no es lo mismo cuatro jugadores en tu red que sesenta repartidos por el mundo.

## 🧠 Qué necesitas saber

### Conocimiento técnico

- **Redes de verdad:** TCP frente a UDP, MTU, pérdida de paquetes, jitter, NAT. Sin esto, la predicción es superstición.
- **Modelo autoritativo:** el servidor manda, el cliente propone. Y sus consecuencias en cada mecánica ([clase 148](../classes/parte-7-multijugador-y-networking/148-servidor-autoritativo-y-anti-cheat-basico/README.md)).
- **Predicción y reconciliación:** el cliente simula por adelantado y corrige cuando el servidor le contradice.
- **Interpolación y extrapolación** de entidades remotas, que es lo que hace que los demás no se muevan a saltos.
- **Determinismo**: coma flotante, orden de iteración, RNG con semilla. Es la base del rollback y del replay ([clase 084](../classes/parte-3-fisica-y-matematicas-de-juegos-aplicadas/084-determinismo-y-fisica-fija-para-multijugador/README.md)).
- **Serialización eficiente:** cuantización, deltas, snapshots y qué NO enviar.

### Herramientas del oficio

- **ENet** (el transporte de Godot) y el `MultiplayerAPI` del motor; los equivalentes de Unity (Netcode/Mirror) y Unreal.
- Un **simulador de condiciones de red** (`clumsy`, `tc netem`, o el del propio motor): sin latencia artificial no estás probando nada.
- **Wireshark** para cuando el problema no está donde crees.
- Un **arnés de pruebas headless** que levante servidor y varios clientes de golpe — como el que verifica el 🧪 [lab de multijugador](../labs/multijugador/README.md) en cada push.

### Habilidades no técnicas

- **Pensar en el peor caso.** El jugador con 300 ms y pérdida del 5 % existe y es tu usuario.
- **Rigor con los estados.** El multijugador castiga la programación «a ojo» como ninguna otra área.
- **Explicar lo invisible.** Justificar ante diseño por qué esa mecánica costará el doble en red.
- **Aguantar la depuración larga.** Aquí los bugs no se arreglan en diez minutos.

## 📚 Tu ruta en el programa

1. 📚 [**Parte 0 — Fundamentos**](../classes/parte-0-fundamentos-y-prerrequisitos/README.md) (001–025), con foco en redes básicas y determinismo (022).
2. 📚 [**Parte 1**](../classes/parte-1-motores-2d-y-tu-primer-juego-jugable/README.md) (026–045) y 📚 [**Parte 2**](../classes/parte-2-desarrollo-3d-motores-escenas-y-transformaciones/README.md) (046–067). Base de gameplay: hace falta un juego que poner en red.
3. 📚 [**Parte 3 — Física y determinismo**](../classes/parte-3-fisica-y-matematicas-de-juegos-aplicadas/README.md) (068–085), especialmente la [clase 084](../classes/parte-3-fisica-y-matematicas-de-juegos-aplicadas/084-determinismo-y-fisica-fija-para-multijugador/README.md).
4. 📚 [**Parte 7 — Multijugador**](../classes/parte-7-multijugador-y-networking/README.md) (138–155) con el 🧪 [lab de multijugador](../labs/multijugador/README.md). **El núcleo**: RPCs, predicción, reconciliación y rollback.
5. 🎯 **Hito**: un juego en red cliente-servidor autoritativo ([clase 155](../classes/parte-7-multijugador-y-networking/155-capstone-parte-7-un-juego-en-red-minimo-cliente-servidor/README.md)).
6. 📚 [**Parte 14 — Optimización**](../classes/parte-14-optimizacion-profiling-y-rendimiento/README.md) (240–254) · 📚 [**Parte 15 — Servidores y CI**](../classes/parte-15-herramientas-editores-y-automatizacion/README.md) (255–266).
7. 📚 [**Parte 17 — Capstone y portfolio**](../classes/parte-17-capstones-y-preparacion-profesional-portfolio/README.md).

➡️ La Parte 7 te da el juego en red; la [**Parte 19**](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md) te da el servicio que sigue en pie a las tres de la mañana. Continúa en [**Ingeniero de backend y online**](backend-online.md).

## 🎓 Qué te contrata

- **Una demo jugable en red** entre dos máquinas distintas, no dos ventanas del mismo PC.
- **Un vídeo con latencia simulada** mostrando el mismo momento en dos clientes. Es la prueba que un entrevistador entiende al instante.
- **Números:** ancho de banda por jugador, frecuencia de envío, tasa de correcciones de reconciliación.
- **Un escrito sobre una desincronización que resolviste.** Es el tipo de historia por el que se contrata en esta especialidad.

## 📈 Progresión de carrera y salario

1. **Junior network programmer** — implementas replicación de funciones concretas dentro de una arquitectura existente.
2. **Network / multiplayer programmer** — diseñas la replicación de sistemas completos y su modelo de autoridad.
3. **Senior** — defines la arquitectura de red del juego, el presupuesto de banda y la estrategia anti-cheat.
4. **Especialización:** [backend y servicios online](backend-online.md), infraestructura de servidores o [arquitecto técnico](arquitecto-tecnico.md).

Rangos **orientativos** (brutos anuales):

- **LATAM:** entrada aproximada USD 14.000–26.000; con experiencia USD 30.000–60.000+.
- **España:** entrada aproximada 24.000–32.000 €; senior 45.000–65.000 €+.
- **Remoto / USD:** seniors de red frecuentemente por encima de USD 100.000–140.000. Es de los perfiles más escasos del sector.

## ⚠️ Mitos y errores comunes

- **«Añadimos multijugador al final.»** El coste de convertir un juego single-player en autoritativo suele ser reescribirlo.
- **«Con que sincronice la posición basta.»** La posición es lo fácil. El problema son las acciones, el orden y quién decide.
- **«Confío en el cliente para esto que es inofensivo.»** No hay nada inofensivo: si el cliente lo decide, alguien lo modificará.
- **«Lo probé y va perfecto.»** En localhost va perfecto siempre. Sin latencia simulada no has probado nada.
- **«El rollback es la solución.»** Es una solución cara y exigente (determinismo total). Para muchos juegos, predicción + reconciliación basta y cuesta la mitad.
- **«El anti-cheat es un producto que se compra.»** El primer anti-cheat es la validación en servidor. Sin ella, lo comprado no te salva.

## 🚀 Siguientes pasos

1. Termina las **Partes 0–3** antes de tocar red. Sin determinismo entendido, la Parte 7 se vuelve un muro.
2. Haz el 🧪 [lab de multijugador](../labs/multijugador/README.md) desde `inicio/` y **no mires la solución** hasta tener la predicción funcionando.
3. Añade latencia y pérdida de paquetes artificiales a tu propio juego. Todo lo que aprendas ahí es el oficio.
4. Levanta un servidor dedicado headless y juega contra él desde otra máquina de tu red.
5. Escribe el desglose de una desincronización que hayas sufrido: síntoma, causa y solución.
6. Sigue por la [**Parte 19**](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md) para lo que viene después del «funciona»: reintentos, idempotencia y economía autoritativa.

---

- ⬅️ [Volver al índice de rutas](./README.md)
- 🏠 [Inicio del programa](../README.md)
