# Clase 217 — Motores web: Phaser (2D)

> Parte: **12 — Juegos web y HTML5** · Fuente: *Documentación oficial de Phaser 3 (phaser.io)*
> ⏱️ Duración estimada: **75 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Escribir un juego solo con Canvas puro funciona, pero pronto reinventas cargador de assets, física, colisiones e input. **Phaser 3** es un framework de juegos 2D que trae todo eso resuelto. En esta clase entenderás su modelo: una **configuración** (`new Phaser.Game(config)`) y **escenas** con tres métodos clave —`preload()` para cargar recursos, `create()` para montar el mundo y `update()` para la lógica por cuadro.

Usarás el sistema de **física arcade** (`this.physics`) para mover un jugador con el teclado, colisionar y recoger un ítem con `overlap`. Al terminar tendrás un mini-juego jugable y comprenderás cuándo conviene un framework como Phaser frente a Canvas puro: cuando quieres velocidad de desarrollo y baterías incluidas.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Configurar un juego Phaser 3 con `Phaser.Game` y una escena.
2. Cargar recursos en `preload()` y crear sprites en `create()`.
3. Mover un sprite con física arcade e input de teclado en `update()`.
4. Detectar la recogida de un ítem con `this.physics.add.overlap`.
5. Justificar cuándo usar un framework 2D en lugar de Canvas puro.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Objeto de configuración | Define renderer, tamaño, física y escenas. |
| 2 | Escenas y su ciclo | `preload/create/update` estructuran el juego. |
| 3 | Carga de assets | El *loader* gestiona imágenes y audio por ti. |
| 4 | Sprites y física arcade | Cuerpos con velocidad, gravedad y colisión listos. |
| 5 | Input de teclado | `createCursorKeys` da las flechas sin boilerplate. |
| 6 | Colisión vs solapamiento | `collider` bloquea; `overlap` solo detecta. |
| 7 | Framework vs Canvas puro | Compensa el peso extra con productividad. |
| 8 | Escalado y renderer | AUTO elige WebGL o Canvas según el navegador. |

## 📖 Definiciones y características

- **Phaser.Game**: instancia principal creada con un objeto de configuración. Clave: arranca el bucle y gestiona escenas.
- **Config**: objeto con `type`, `width`, `height`, `physics` y `scene`. Clave: describe todo el juego de forma declarativa.
- **Scene**: unidad con `preload`, `create` y `update`. Clave: separa pantallas (menú, nivel, game over).
- **preload()**: carga assets antes de empezar. Clave: garantiza que las texturas existan en `create`.
- **Arcade Physics**: motor de física simple AABB. Clave: rápido y suficiente para plataformas y arcades.
- **`this.physics.add.sprite`**: crea un sprite con cuerpo físico. Clave: permite `setVelocity`, gravedad y colisión.
- **`collider`**: hace que dos cuerpos no se atraviesen. Clave: para paredes y suelos.
- **`overlap`**: detecta que dos cuerpos se solapan sin frenarlos. Clave: para recoger ítems o zonas de disparo.

## 🧰 Herramientas y preparación

Necesitas un navegador y un editor. Cargaremos Phaser 3 desde un CDN (<https://cdn.jsdelivr.net/npm/phaser@3/dist/phaser.min.js>) para no instalar nada. Como servir por HTTP evita problemas de carga, usa `python -m http.server`. La documentación y ejemplos están en <https://phaser.io/> y <https://newdocs.phaser.io/>.

Crea una carpeta `phaser-mini/` con `index.html` y `juego.js`. Generaremos las texturas por código (rectángulos de colores) para no depender de archivos de imagen.

## 🧪 Laboratorio guiado

Harás un jugador que se mueve con las flechas y recoge un ítem.

1. `index.html` carga Phaser y tu script:

```html
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><title>Phaser Mini</title></head>
<body>
  <script src="https://cdn.jsdelivr.net/npm/phaser@3/dist/phaser.min.js"></script>
  <script src="juego.js"></script>
</body>
</html>
```

2. En `juego.js` define la configuración con física arcade y una escena:

```javascript
const config = {
  type: Phaser.AUTO,          // WebGL si está disponible, si no Canvas.
  width: 640,
  height: 400,
  backgroundColor: '#101828',
  physics: { default: 'arcade', arcade: { debug: false } },
  scene: { preload, create, update }
};

const juego = new Phaser.Game(config);
let jugador, item, cursores, puntos = 0, textoPuntos;
```

3. En `preload()` genera dos texturas de color con el API gráfico (sin archivos):

```javascript
function preload() {
  // Textura del jugador: cuadrado verde de 32x32.
  const g = this.make.graphics({ x: 0, y: 0, add: false });
  g.fillStyle(0x4ade80, 1).fillRect(0, 0, 32, 32);
  g.generateTexture('jugador', 32, 32);
  // Textura del ítem: cuadrado amarillo de 20x20.
  g.clear().fillStyle(0xfacc15, 1).fillRect(0, 0, 20, 20);
  g.generateTexture('item', 20, 20);
}
```

4. En `create()` crea el jugador con cuerpo físico, el ítem, las teclas y el marcador; registra el solapamiento:

```javascript
function create() {
  jugador = this.physics.add.sprite(320, 200, 'jugador');
  jugador.setCollideWorldBounds(true);   // No sale del área.

  item = this.physics.add.sprite(120, 120, 'item');

  cursores = this.input.keyboard.createCursorKeys();

  textoPuntos = this.add.text(12, 12, 'Puntos: 0', { color: '#ffffff', fontSize: '18px' });

  // Al solaparse jugador e ítem, recogemos.
  this.physics.add.overlap(jugador, item, recoger, null, this);
}

function recoger(jug, it) {
  puntos += 1;
  textoPuntos.setText('Puntos: ' + puntos);
  // Reubicamos el ítem en una posición aleatoria dentro del área.
  it.setPosition(Phaser.Math.Between(40, 600), Phaser.Math.Between(40, 360));
}
```

5. En `update()` mueve al jugador según las flechas usando velocidad (no posición):

```javascript
function update() {
  const velocidad = 220;
  jugador.setVelocity(0);
  if (cursores.left.isDown)  jugador.setVelocityX(-velocidad);
  if (cursores.right.isDown) jugador.setVelocityX(velocidad);
  if (cursores.up.isDown)    jugador.setVelocityY(-velocidad);
  if (cursores.down.isDown)  jugador.setVelocityY(velocidad);
}
```

6. Sirve la carpeta (`python -m http.server 8000`) y abre <http://localhost:8000/>. Mueve el cuadrado verde con las flechas hacia el amarillo: al tocarlo, el marcador sube y el ítem reaparece en otro lugar.

Fíjate en cuánto código te ahorró Phaser: no escribiste bucle, ni loader, ni detección de colisión manual.

## ✍️ Ejercicios

1. Añade gravedad al jugador (`arcade.gravity.y`) y un salto con la barra espaciadora.
2. Crea varios ítems en un grupo (`this.physics.add.group`) y recógelos todos.
3. Muestra un mensaje de victoria cuando los puntos lleguen a 5.
4. Reemplaza las texturas generadas por imágenes cargadas con `this.load.image`.
5. Añade un segundo tipo de ítem que reste puntos si lo tocas.
6. Activa `arcade: { debug: true }` y describe qué muestran los cuerpos físicos.

## 📝 Reto verificable

Construye un nivel donde el jugador debe recoger 5 ítems dispersos evitando un "enemigo" que rebota por la pantalla; tocar al enemigo reinicia los puntos a 0. Muestra puntos y un mensaje al ganar.

**Criterio de aceptación**: el jugador se mueve con las flechas, recoge los 5 ítems que reaparecen, el enemigo rebota de forma autónoma, tocarlo reinicia el marcador, y al llegar a 5 aparece "¡Ganaste!"; sin errores en consola.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| "Phaser is not defined" | El script del CDN no cargó o va después de `juego.js`. Ponlo antes y verifica la URL. |
| El jugador no se mueve | Usaste `setPosition` en `update` o no creaste los cursores. Usa `setVelocity` y `createCursorKeys`. |
| El overlap no dispara | El jugador o el ítem no son sprites de física. Créalos con `this.physics.add.sprite`. |
| El sprite ignora los bordes | Falta `setCollideWorldBounds(true)`. Actívalo tras crear el sprite. |
| La textura sale invisible | Olvidaste `generateTexture` o el nombre no coincide. Revisa la clave usada en `add.sprite`. |

## ❓ Preguntas frecuentes

**❓ ¿Cuándo Phaser y cuándo Canvas puro?** Phaser cuando quieres física, escenas, input y assets resueltos y velocidad de desarrollo; Canvas puro cuando buscas control total, aprender los fundamentos o un bundle mínimo.

**❓ ¿Qué diferencia hay entre `collider` y `overlap`?** `collider` impide que los cuerpos se atraviesen; `overlap` solo notifica que se tocan sin frenarlos, ideal para recoger cosas.

**❓ ¿Debo mover con posición o con velocidad?** Con velocidad: así la física arcade gestiona colisiones y límites correctamente cuadro a cuadro.

**❓ ¿Puedo tener varias escenas?** Sí. Pasa un arreglo de escenas en la config y cambia entre ellas con `this.scene.start('nombre')`, útil para menú y niveles.

## 🔗 Referencias

- Phaser — Sitio oficial y ejemplos: <https://phaser.io/>
- Phaser — Nueva documentación (API): <https://newdocs.phaser.io/>
- Phaser — Making your first game: <https://phaser.io/tutorials/making-your-first-phaser-3-game>
- MDN — 2D breakout game con Phaser: <https://developer.mozilla.org/es/docs/Games/Tutorials/2D_breakout_game_Phaser>

## ⬅️ Clase anterior

[Clase 216 - JavaScript para juegos: el bucle y Canvas](../216-javascript-para-juegos-el-bucle-y-canvas/README.md)

## ➡️ Siguiente clase

[Clase 218 - PixiJS y renderizado 2D acelerado](../218-pixijs-y-renderizado-2d-acelerado/README.md)
