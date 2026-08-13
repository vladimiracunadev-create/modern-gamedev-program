package io.github.vladimiracunadev.curso;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.KeyEvent;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

/**
 * El curso entero, dentro del APK y sin red.
 *
 * <p>La decisión que explica todo lo demás: el contenido NO se carga con
 * {@code file://}, sino desde un origen https inventado que un interceptor
 * resuelve contra los assets. Con {@code file://} el navegador trata cada
 * archivo como un origen distinto y bloquea {@code fetch()} — y el buscador, el
 * quiz y la pantalla de progreso leen sus datos justo así. Servirlo bajo un
 * origen https los convierte en peticiones normales del mismo sitio, y de paso
 * habilita {@code localStorage}, que es donde el curso guarda tu avance.
 *
 * <p>Ninguna petición llega a salir: lo que no está en los assets devuelve un
 * 404 propio. Por eso la app no declara el permiso de INTERNET.
 */
public class MainActivity extends Activity {

    /** Origen inventado. No existe como dominio y nunca se resuelve por DNS. */
    private static final String ORIGEN = "https://curso.local/";
    private static final String HOST = "curso.local";
    private static final String RAIZ_ASSETS = "sitio";

    private WebView web;

    @Override
    protected void onCreate(Bundle estado) {
        super.onCreate(estado);

        web = new WebView(this);
        WebSettings ajustes = web.getSettings();
        ajustes.setJavaScriptEnabled(true);   // buscador, quiz y progreso son JS
        ajustes.setDomStorageEnabled(true);   // el avance vive en localStorage
        // El interceptor sirve TODO, así que la WebView no necesita tocar el
        // sistema de archivos ni los content providers. Cerrarlo es gratis.
        ajustes.setAllowFileAccess(false);
        ajustes.setAllowContentAccess(false);
        ajustes.setSupportZoom(true);
        ajustes.setBuiltInZoomControls(true);
        ajustes.setDisplayZoomControls(false);
        ajustes.setUseWideViewPort(true);
        ajustes.setLoadWithOverviewMode(true);

        web.setWebViewClient(new ClienteDeAssets());
        setContentView(web);

        // Al girar la pantalla se restaura el historial en vez de volver al
        // índice: perder la clase que estabas leyendo por girar el móvil es de
        // las cosas que más molestan de una app de lectura.
        if (estado != null) {
            web.restoreState(estado);
        } else {
            web.loadUrl(ORIGEN + "index.html");
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle estado) {
        super.onSaveInstanceState(estado);
        web.saveState(estado);
    }

    @Override
    public boolean onKeyDown(int codigo, KeyEvent evento) {
        if (codigo == KeyEvent.KEYCODE_BACK && web.canGoBack()) {
            web.goBack();
            return true;
        }
        return super.onKeyDown(codigo, evento);
    }

    @Override
    protected void onDestroy() {
        // Sin esto la WebView puede sobrevivir a la Activity y filtrar su
        // contexto: el mismo problema de ciclos que enseña la clase 340, pero
        // con el recolector de Android.
        if (web != null) {
            web.setWebViewClient(new WebViewClient());
            web.destroy();
            web = null;
        }
        super.onDestroy();
    }

    /** Resuelve cada petición del origen del curso contra los assets del APK. */
    private final class ClienteDeAssets extends WebViewClient {

        private final Map<String, String> TIPOS = new HashMap<>();

        ClienteDeAssets() {
            TIPOS.put("html", "text/html");
            TIPOS.put("css", "text/css");
            TIPOS.put("js", "text/javascript");
            TIPOS.put("json", "application/json");
            TIPOS.put("svg", "image/svg+xml");
            TIPOS.put("png", "image/png");
            TIPOS.put("jpg", "image/jpeg");
            TIPOS.put("jpeg", "image/jpeg");
            TIPOS.put("gif", "image/gif");
            TIPOS.put("webp", "image/webp");
            TIPOS.put("ico", "image/x-icon");
            TIPOS.put("woff2", "font/woff2");
            TIPOS.put("pdf", "application/pdf");
            TIPOS.put("txt", "text/plain");
        }

        @Override
        public WebResourceResponse shouldInterceptRequest(WebView vista, WebResourceRequest peticion) {
            Uri uri = peticion.getUrl();
            if (!HOST.equals(uri.getHost())) {
                // Cualquier otro host se deja pasar al flujo normal, donde
                // shouldOverrideUrlLoading ya lo habrá mandado al navegador.
                return null;
            }
            return servir(uri.getPath());
        }

        @Override
        public boolean shouldOverrideUrlLoading(WebView vista, WebResourceRequest peticion) {
            Uri uri = peticion.getUrl();
            if (HOST.equals(uri.getHost())) {
                return false;  // navegación interna: que la maneje la WebView
            }
            // Lo de fuera se abre en el navegador del sistema. Una app sin
            // permiso de red no puede (ni debe) hacer de navegador general.
            try {
                startActivity(new Intent(Intent.ACTION_VIEW, uri));
            } catch (ActivityNotFoundException e) {
                // Sin navegador instalado no hay nada que hacer, pero tampoco
                // hay motivo para tirar la app.
            }
            return true;
        }

        private WebResourceResponse servir(String ruta) {
            if (ruta == null || ruta.isEmpty() || "/".equals(ruta)) {
                ruta = "/index.html";
            }
            if (ruta.endsWith("/")) {
                ruta = ruta + "index.html";
            }
            // Normalización mínima pero imprescindible: sin ella, una ruta con
            // '..' saldría de la carpeta del sitio. Aquí solo se sirve de
            // dentro, y punto.
            String limpia = Uri.decode(ruta).replace('\\', '/');
            if (limpia.contains("..")) {
                return error404();
            }
            String enAssets = RAIZ_ASSETS + limpia;

            try {
                InputStream flujo = getAssets().open(enAssets);
                WebResourceResponse respuesta = new WebResourceResponse(
                        tipoDe(limpia), "utf-8", flujo);
                respuesta.setResponseHeaders(Collections.singletonMap(
                        "Cache-Control", "no-cache"));
                return respuesta;
            } catch (IOException e) {
                return error404();
            }
        }

        private String tipoDe(String ruta) {
            int punto = ruta.lastIndexOf('.');
            if (punto < 0) {
                return "application/octet-stream";
            }
            String ext = ruta.substring(punto + 1).toLowerCase();
            String tipo = TIPOS.get(ext);
            return tipo != null ? tipo : "application/octet-stream";
        }

        private WebResourceResponse error404() {
            // Un 404 propio, para que ni una sola petición fallida acabe
            // intentando salir a la red.
            String cuerpo = "<!doctype html><meta charset='utf-8'>"
                    + "<body style='background:#0d0f14;color:#e6e8ef;"
                    + "font-family:system-ui;padding:2rem'>"
                    + "<h1>Contenido no encontrado</h1>"
                    + "<p>Esta página no está incluida en la app. "
                    + "Vuelve atrás o abre el índice del curso.</p>"
                    + "<p><a style='color:#7c5cff' href='" + ORIGEN + "index.html'>"
                    + "Ir al índice</a></p></body>";
            return new WebResourceResponse("text/html", "utf-8", 404, "Not Found",
                    Collections.<String, String>emptyMap(),
                    new ByteArrayInputStream(cuerpo.getBytes(StandardCharsets.UTF_8)));
        }
    }
}
