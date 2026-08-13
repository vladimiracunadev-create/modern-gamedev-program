# 📱 Desarrollador móvil / web

> Alcance masivo y restricciones duras: pantallas pequeñas, dedos gordos, baterías finitas
> y jugadores que se van si tarda tres segundos en cargar.
>
> **Nivel de entrada:** inicial-intermedio · **Foco:** rendimiento, entrega y plataforma · **Hito faro:** un juego jugable en el navegador y en un teléfono real

## 🧭 Qué es y por qué importa

Este rol lleva juegos a donde está casi toda la gente: el teléfono y el navegador. Técnicamente es el mismo oficio que gameplay, pero con un conjunto de restricciones que cambia todas las decisiones: memoria escasa, CPU térmicamente limitada, GPU modesta, tamaño de descarga que decide si alguien lo instala y una entrada táctil que no perdona un botón mal colocado.

Importa porque el mercado móvil es, de largo, el más grande, y porque la web es el único sitio donde tu juego se juega **sin instalar nada**: es el mejor escaparate que existe para un indie. Un enlace que abre tu juego en cinco segundos convierte muchísimo mejor que una descarga.

También es el rol donde más rápido se aprende a optimizar de verdad, porque no hay margen: en escritorio puedes ir sobrado por accidente; en un móvil de gama media, no.

## 🗓️ Un día en el puesto

- **Probar en dispositivos reales.** El emulador miente sobre rendimiento, sobre táctil y sobre batería. Un cajón con tres teléfonos viejos es una herramienta de trabajo.
- **Perseguir el tamaño del build.** Cada megabyte cuesta instalaciones. Atlas, compresión de texturas, formatos de audio, recorte de dependencias.
- **Ajustar la interfaz a pantallas imposibles:** muescas, barras de gestos, relaciones de aspecto raras, texto que crece por accesibilidad.
- **Medir batería y temperatura.** Un juego que calienta el teléfono se desinstala aunque vaya a 60 fps.
- **Pelear con las tiendas:** permisos, políticas de privacidad, edad, versiones mínimas de SDK, revisiones rechazadas.
- **En web:** tiempo de carga, tamaño del WASM, y que funcione igual en Chrome, Safari y un navegador de móvil.

## 🧠 Qué necesitas saber

### Conocimiento técnico

- **Fundamentos y 2D** completos: es el mismo oficio de base ([Partes 0 y 1](../classes/parte-0-fundamentos-y-prerrequisitos/README.md)).
- **Entrada táctil de verdad:** zonas de toque mínimas, gestos, multitáctil, y por qué un botón de escritorio no vale.
- **UI adaptativa y accesible.** En pantallas pequeñas la UI **es** el juego ([Parte 10](../classes/parte-10-ui-ux-accesibilidad-y-localizacion/README.md)).
- **Exportación y firma** para Android/iOS, tamaños de APK/AAB, permisos y requisitos de tienda ([Parte 11](../classes/parte-11-movil-consolas-y-plataformas/README.md)).
- **Web:** Canvas, WebGL, WebAssembly, PWA y las limitaciones de cada navegador ([Parte 12](../classes/parte-12-juegos-web-y-html5/README.md)).
- **Optimización, y no como extra:** presupuesto de fotograma, draw calls, memoria y arranque ([Parte 14](../classes/parte-14-optimizacion-profiling-y-rendimiento/README.md)).

### Herramientas del oficio

- **Godot 4** con sus exportadores de Android, iOS y Web; **Unity** si vas a móvil comercial.
- **adb** y las herramientas de perfilado de Android; **Safari Web Inspector** para iOS, que es donde aparecen los problemas raros.
- **Lighthouse** y las DevTools del navegador para el arranque en web.
- **Phaser / PixiJS / Three.js** si el proyecto es web nativo en vez de exportado.

### Habilidades no técnicas

- **Empatía con el contexto de uso:** se juega en el metro, con una mano, con interrupciones y con poca batería.
- **Disciplina de tamaño.** Decir que no a un asset de 8 MB es una decisión de producto.
- **Paciencia con las tiendas.** Los rechazos son parte del proceso; el enfado no acelera la revisión.
- **Datos por encima de opiniones.** En móvil todo se mide: retención, tiempo de carga, caídas por dispositivo.

## 📚 Tu ruta en el programa

1. 📚 [**Parte 0**](../classes/parte-0-fundamentos-y-prerrequisitos/README.md) (001–025) y 📚 [**Parte 1**](../classes/parte-1-motores-2d-y-tu-primer-juego-jugable/README.md) (026–045).
2. 📚 [**Parte 10 — UI/UX, accesibilidad e i18n**](../classes/parte-10-ui-ux-accesibilidad-y-localizacion/README.md) (188–199) con el 🧪 [lab de UI accesible](../labs/ui-accesible/README.md). Crítico en pantallas pequeñas.
3. 📚 [**Parte 11 — Móvil y plataformas**](../classes/parte-11-movil-consolas-y-plataformas/README.md) (200–213). Export, táctil, batería y tiendas.
4. 📚 [**Parte 12 — Web y HTML5**](../classes/parte-12-juegos-web-y-html5/README.md) (214–227). WASM, Phaser, Three.js y PWA.
5. 📚 [**Parte 14 — Optimización**](../classes/parte-14-optimizacion-profiling-y-rendimiento/README.md) (240–254). **Imprescindible** aquí, no opcional.
6. 📚 [**Parte 16 — Monetización y publicación**](../classes/parte-16-produccion-publicacion-monetizacion-y-liveops/README.md) (267–280) · 📚 [**Parte 17**](../classes/parte-17-capstones-y-preparacion-profesional-portfolio/README.md).

➡️ Si tu juego móvil incorpora cuentas, compras o contenido en servidor, continúa en [**Ingeniero de backend y online**](backend-online.md) ([Parte 19](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md)).

## 🎓 Qué te contrata

- **Un enlace que se juega en el navegador.** Sin instalar, sin registro, funcionando en móvil. Es la demo más eficaz posible.
- **Un APK instalable** y datos de rendimiento en un dispositivo de gama media concreto (modelo, fps, memoria, tamaño).
- **Un caso de optimización documentado:** de 90 MB a 28 MB, o de 22 fps a 60, con lo que hiciste y lo que costó.
- **Capturas de la UI a distintas resoluciones**, incluida una con muesca y otra con texto ampliado.

## 📈 Progresión de carrera y salario

1. **Junior mobile/web game developer** — implementas funciones y peleas bugs específicos de dispositivo.
2. **Mobile/web game developer** — te haces cargo de la exportación, el rendimiento y la publicación.
3. **Senior** — decides arquitectura multiplataforma, pipeline de assets y estrategia de entrega.
4. **Especialización:** [rendimiento](motor-rendimiento.md), [backend y LiveOps](backend-online.md) o liderazgo técnico.

Rangos **orientativos** (brutos anuales):

- **LATAM:** entrada aproximada USD 10.000–22.000; con experiencia USD 24.000–48.000+.
- **España:** entrada aproximada 20.000–28.000 €; senior 38.000–55.000 €+.
- **Remoto / USD:** seniors por encima de USD 75.000–110.000.

El móvil comercial (free-to-play, publishers) paga mejor que el indie móvil, pero el trabajo es distinto: mucha métrica, mucha iteración sobre retención y monetización. Conviene saber a cuál de los dos apuntas.

## ⚠️ Mitos y errores comunes

- **«Si va bien en mi PC, en el móvil también.»** No. El móvil limita por temperatura: los primeros dos minutos mienten.
- **«Ya adaptaré la UI al final.»** La UI móvil condiciona el diseño de la pantalla entera. Al final solo se puede parchear.
- **«El táctil es el ratón sin botón derecho.»** No hay hover, el dedo tapa lo que toca y la precisión es de milímetros.
- **«Web es solo exportar a HTML5.»** El arranque, el tamaño del WASM, el audio bloqueado hasta el primer toque y Safari te esperan.
- **«El tamaño da igual, hay wifi.»** El tamaño decide instalaciones, sobre todo fuera de países ricos.
- **«Optimizar es para el final.»** En esta ruta, optimizar **es** el trabajo. Se mide desde el principio.

## 🚀 Siguientes pasos

1. Coge cualquier juego que ya hayas hecho y **expórtalo a web**. Mide cuánto tarda en ser jugable y redúcelo a la mitad.
2. Instálalo en un **teléfono real de gama media**. Anota fps, temperatura y qué pasa a los diez minutos.
3. Haz el 🧪 [lab de UI accesible](../labs/ui-accesible/README.md) y aplica lo aprendido a tu HUD con texto al 200 %.
4. Publica en itch.io con la versión web incrustada; es donde más gente lo probará.
5. Prepara un build de Android firmado y pásalo por la lista de requisitos de la **Parte 11**.
6. Cuando toques cuentas o compras, entra en la [**Parte 19**](../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md): ahí es donde eso se hace bien.

---

- ⬅️ [Volver al índice de rutas](./README.md)
- 🏠 [Inicio del programa](../README.md)
