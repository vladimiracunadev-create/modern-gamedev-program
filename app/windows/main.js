// Aplicación de escritorio del Programa de Desarrollo de Videojuegos Moderno.
//
// Igual que la versión de Android, el curso se sirve desde un ORIGEN propio en
// vez de con file://. El motivo es el mismo y conviene repetirlo porque es el
// error clásico de empaquetar un sitio estático: bajo file:// cada archivo es un
// origen distinto, así que fetch() se bloquea y localStorage no persiste. El
// buscador, el quiz y la pantalla de progreso dependen de las dos cosas.
//
// Aquí se resuelve registrando el esquema `curso://` como privilegiado (estándar,
// seguro y con soporte de fetch) y sirviéndolo desde la carpeta del contenido.

const { app, BrowserWindow, Menu, shell, protocol, net } = require('electron')
const path = require('node:path')
const { pathToFileURL } = require('node:url')

const ESQUEMA = 'curso'
const INICIO = `${ESQUEMA}://curso/index.html`

// La carpeta del contenido va DENTRO del paquete, junto al ejecutable, no
// dentro del asar: así se puede inspeccionar y actualizar sin reempaquetar.
const RAIZ = app.isPackaged
  ? path.join(process.resourcesPath, 'sitio')
  : path.join(__dirname, '..', '..', 'site')

// Debe declararse ANTES de que la app esté lista: después, Electron ya ha
// construido la tabla de esquemas y este registro no tendría efecto.
protocol.registerSchemesAsPrivileged([{
  scheme: ESQUEMA,
  privileges: { standard: true, secure: true, supportFetchAPI: true, stream: true },
}])

function rutaSegura (urlPedida) {
  const url = new URL(urlPedida)
  let relativa = decodeURIComponent(url.pathname)
  if (relativa.endsWith('/')) relativa += 'index.html'
  if (relativa === '' || relativa === '/') relativa = '/index.html'

  // path.join normaliza los '..', pero eso no basta: hay que COMPROBAR que el
  // resultado sigue dentro de la raíz. Sin esta comprobación, una ruta como
  // /../../secreto se serviría tan contenta.
  const destino = path.join(RAIZ, relativa)
  const raizNormalizada = path.resolve(RAIZ) + path.sep
  if (!path.resolve(destino).startsWith(raizNormalizada)) return null
  return destino
}

function crearVentana () {
  const ventana = new BrowserWindow({
    width: 1280,
    height: 860,
    minWidth: 420,
    minHeight: 480,
    backgroundColor: '#0d0f14',
    title: 'Programa de Desarrollo de Videojuegos Moderno',
    autoHideMenuBar: true,
    webPreferences: {
      // El contenido es HTML estático: no necesita Node, así que no lo tiene.
      // Un renderer sin Node no puede tocar el disco aunque una página haga algo
      // raro, y aquí no cuesta nada.
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true,
      spellcheck: false,
    },
  })

  ventana.loadURL(INICIO)

  // Los enlaces externos salen al navegador del sistema en vez de abrir una
  // ventana de Electron sin barra de direcciones, que es justo donde nadie
  // puede comprobar a dónde ha ido a parar.
  ventana.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith('http://') || url.startsWith('https://')) shell.openExternal(url)
    return { action: 'deny' }
  })
  ventana.webContents.on('will-navigate', (evento, url) => {
    if (!url.startsWith(`${ESQUEMA}://`)) {
      evento.preventDefault()
      if (url.startsWith('http://') || url.startsWith('https://')) shell.openExternal(url)
    }
  })

  return ventana
}

function construirMenu () {
  // Un menú mínimo y en español. Sin él, Electron pone el suyo en inglés con
  // media docena de opciones de desarrollo que aquí no pintan nada.
  const plantilla = [
    {
      label: 'Curso',
      submenu: [
        { label: 'Índice de clases', accelerator: 'CmdOrCtrl+I',
          click: () => BrowserWindow.getFocusedWindow()?.loadURL(`${ESQUEMA}://curso/classes/README.html`) },
        { label: 'Buscador', accelerator: 'CmdOrCtrl+F',
          click: () => BrowserWindow.getFocusedWindow()?.loadURL(`${ESQUEMA}://curso/buscar.html`) },
        { label: 'Mi progreso',
          click: () => BrowserWindow.getFocusedWindow()?.loadURL(`${ESQUEMA}://curso/autoevaluaciones/progreso.html`) },
        { type: 'separator' },
        { label: 'Portada', accelerator: 'CmdOrCtrl+H',
          click: () => BrowserWindow.getFocusedWindow()?.loadURL(INICIO) },
        { type: 'separator' },
        { label: 'Salir', role: 'quit' },
      ],
    },
    {
      label: 'Ver',
      submenu: [
        { label: 'Atrás', accelerator: 'Alt+Left',
          click: () => { const w = BrowserWindow.getFocusedWindow(); if (w?.webContents.canGoBack()) w.webContents.goBack() } },
        { label: 'Adelante', accelerator: 'Alt+Right',
          click: () => { const w = BrowserWindow.getFocusedWindow(); if (w?.webContents.canGoForward()) w.webContents.goForward() } },
        { type: 'separator' },
        { label: 'Acercar', role: 'zoomIn' },
        { label: 'Alejar', role: 'zoomOut' },
        { label: 'Tamaño normal', role: 'resetZoom' },
        { type: 'separator' },
        { label: 'Pantalla completa', role: 'togglefullscreen' },
      ],
    },
    {
      label: 'Ayuda',
      submenu: [
        { label: 'Repositorio en GitHub',
          click: () => shell.openExternal('https://github.com/vladimiracunadev-create/modern-gamedev-program') },
        { label: 'Sitio del curso',
          click: () => shell.openExternal('https://vladimiracunadev-create.github.io/modern-gamedev-program/') },
      ],
    },
  ]
  Menu.setApplicationMenu(Menu.buildFromTemplate(plantilla))
}

// Comprobación automática: `VideojuegosModerno.exe --verificar` carga la app en
// una ventana oculta y exige que el contenido esté COMPLETO y que fetch()
// funcione a través del esquema propio. Esto último es lo único que de verdad
// distingue una app que arranca de una app que sirve: con file:// la ventana
// también se abriría, y el buscador y el quiz estarían rotos.
async function verificar () {
  const ventana = new BrowserWindow({ show: false, webPreferences: { sandbox: true } })
  let hechas = 0
  let fallos = 0
  const check = (ok, que) => {
    hechas++
    if (!ok) { fallos++; console.log(`  FALLA  ${que}`) } else { console.log(`  ok     ${que}`) }
  }

  try {
    await ventana.loadURL(INICIO)
    check(true, 'la portada carga desde el esquema del curso')

    const r = await ventana.webContents.executeJavaScript(`(async () => {
      const out = { titulo: document.title, partes: document.querySelectorAll('.part').length }
      const b = await fetch('curso://curso/busqueda.json').then(x => x.json())
      out.clases = b.length
      const p = await fetch('curso://curso/autoevaluaciones/preguntas.json').then(x => x.json())
      out.preguntas = p.partes.reduce((n, x) => n + x.preguntas.length, 0)
      const m = await fetch('curso://curso/classes/_manifest.json').then(x => x.json())
      out.manifest = m.total_built
      const r404 = await fetch('curso://curso/no-existe.html')
      out.estado404 = r404.status
      return out
    })()`)

    check(r.titulo.includes('Videojuegos'), `la portada es la del curso ("${r.titulo}")`)
    check(r.partes === 22, `la portada pinta las 22 partes (pinta ${r.partes})`)
    check(r.clases === 352, `el buscador indexa 352 clases (indexa ${r.clases})`)
    check(r.preguntas === 110, `el quiz trae 110 preguntas (trae ${r.preguntas})`)
    check(r.manifest === 352, `el manifest declara 352 clases (declara ${r.manifest})`)
    check(r.estado404 === 404, `lo que no existe devuelve 404 (devuelve ${r.estado404})`)

    const clase = await ventana.webContents.executeJavaScript(
      `fetch('curso://curso/classes/parte-21-arquitectura-avanzada-de-motores-y-rendering/` +
      `352-capstone-parte-21-ingenieria-avanzada-verificable/README.html')` +
      `.then(r => r.ok ? r.text() : '').then(t => t.length)`)
    check(clase > 5000, `la última clase (352) está entera (${clase} bytes)`)
  } catch (e) {
    hechas++
    fallos++
    console.log(`  FALLA  excepción: ${e && e.message}`)
  }

  console.log(`== ${hechas} comprobaciones, ${fallos} fallos ==`)
  app.exit(fallos > 0 ? 1 : 0)
}

app.whenReady().then(() => {
  protocol.handle(ESQUEMA, (peticion) => {
    const destino = rutaSegura(peticion.url)
    if (!destino) {
      return new Response('Ruta no permitida', { status: 403, headers: { 'content-type': 'text/plain' } })
    }
    return net.fetch(pathToFileURL(destino).toString()).catch(() =>
      new Response(
        '<!doctype html><meta charset="utf-8">' +
        '<body style="background:#0d0f14;color:#e6e8ef;font-family:system-ui;padding:2rem">' +
        '<h1>Contenido no encontrado</h1>' +
        `<p>Esta página no está incluida en la app. <a style="color:#7c5cff" href="${INICIO}">Ir al índice</a></p>` +
        '</body>',
        { status: 404, headers: { 'content-type': 'text/html; charset=utf-8' } }))
  })

  if (process.argv.includes('--verificar')) {
    verificar()
    return
  }

  construirMenu()
  crearVentana()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) crearVentana()
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})
