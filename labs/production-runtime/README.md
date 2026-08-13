# 🛡️ Lab: Runtime de producción

> [⬅️ Volver a los laboratorios](../README.md) · [📚 Parte 19](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/README.md) · [🎓 Clase 324 (capstone)](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/324-capstone-parte-19-un-runtime-de-produccion/README.md)

La capa que conecta un juego con el mundo real y lo mantiene en pie cuando ese mundo falla: cliente con reintentos y circuit breaker, configuración remota con defectos compilados, feature flags con kill switch, telemetría gobernada por consentimiento y guardado versionado con migraciones.

Y el requisito que define el laboratorio: **funciona entero sin red, sin claves de API, sin servicios de pago y de forma determinista**. Todo lo remoto está detrás de un `MockBackend` que simula latencia, errores 4xx y 5xx, caída total, respuestas corruptas y fallos intermitentes. Eso no es una simplificación para el ejercicio: es como se prueban estos sistemas en la industria, porque un backend real no te deja provocar una caída del 100 % a las tres de la tarde.

## 📦 Qué hay dentro

| Pieza | Archivo | Clase |
|---|---|---|
| Contrato de backend | `infraestructura/proveedor.gd` | [311](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/311-arquitectura-backend-para-videojuegos/README.md) |
| Mock determinista con 7 modos de fallo | `infraestructura/mock_backend.gd` | [324](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/324-capstone-parte-19-un-runtime-de-produccion/README.md) |
| Circuit breaker | `infraestructura/interruptor.gd` | [311](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/311-arquitectura-backend-para-videojuegos/README.md) |
| Cliente con reintentos, caché y cola | `infraestructura/backend.gd` | [311](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/311-arquitectura-backend-para-videojuegos/README.md) |
| Config con esquema y defectos | `infraestructura/config.gd` | [315](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/315-remote-config-feature-flags-y-experimentos/README.md) |
| Feature flags y kill switch | `infraestructura/flags.gd` | [315](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/315-remote-config-feature-flags-y-experimentos/README.md) |
| Telemetría con taxonomía y consentimiento | `infraestructura/telemetria.gd` | [317](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/317-telemetria-privacidad-y-gobernanza-de-datos/README.md) |
| Guardado con migraciones | `infraestructura/guardado.gd` | [307](../../classes/parte-18-arquitectura-de-gameplay-y-sistemas-sistemicos/307-save-system-de-produccion/README.md) |

## 🚀 Cómo usarlo

```bash
godot --path labs/production-runtime/inicio
```

```bash
godot --headless --path labs/production-runtime/solucion --script res://pruebas/runtime_test.gd
```

La versión `inicio/` tiene los `TODO` en las piezas que de verdad importan: la validación del esquema de configuración, la resolución de flags con su bucket determinista, la lectura resiliente del backend, los tres filtros de la telemetría y las dos migraciones de guardado. Arranca igual, y por eso se ve enseguida qué se pierde sin ellas.

## ✅ Qué verifica la CI

```text
== 91 comprobaciones, 0 fallos ==
```

- **Offline total**: el runtime arranca, se puede jugar, se guarda y se carga en local **sin una sola llamada al proveedor**; la telemetría y las escrituras remotas se encolan y se envían solas al volver la red.
- **Caos determinista**: los seis modos de fallo (normal, 5xx, 4xx, caído, corrupto, intermitente) y en **todos** el juego arranca, es jugable y guarda.
- **Reintentos con criterio**: una lectura idempotente reintenta exactamente 3 veces; un 404 no se reintenta ni una.
- **Circuit breaker**: con el servicio caído, tras abrirse **no se hace ni una llamada más**; pasado el tiempo de espera tantea de nuevo y una respuesta correcta lo cierra.
- **Caché con procedencia**: con el servicio caído sigue habiendo respuesta, marcada como `cache`, no como si fuera fresca.
- **Configuración**: un valor fuera de rango, de tipo incorrecto, fuera de la lista de opciones o de clave desconocida se **rechaza** y se sigue con el defecto. Un payload corrupto (un 200 con basura dentro) no toca nada.
- **Flags**: el mismo jugador cae siempre en el mismo grupo; un rollout al 50 % sobre 10.000 jugadores activa entre el 47 % y el 53 %; dos sales distintas reparten a conjuntos distintos; el kill switch gana aunque el flag esté al 100 %.
- **Telemetría**: sin consentimiento no entra nada en la cola; un evento fuera de la taxonomía se rechaza; un campo prohibido rechaza el evento **entero**; un campo no declarado o inválido se descarta sin tumbarlo; todos los eventos llevan versión; retirar el consentimiento rota el seudónimo y vacía la cola.
- **Migraciones**: un save de la v1 llega a la v3 moviendo ajustes y creando el monedero; un save de versión futura o ilegible se rechaza **sin lanzar errores**.

## 🔍 Qué NO cubre

- **No hay red real.** Ni un `HTTPRequest`. El contrato `ProveedorBackend` está preparado para uno, pero implementarlo es cosa tuya — y el proxy que guarda la clave, del servidor.
- **No hay observabilidad completa** ([clase 316](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/316-observabilidad-de-juegos/README.md)): hay telemetría gobernada, pero no métricas con percentiles, trazas ni crash reporting.
- **No hay resolución de conflictos de cloud save** ([clase 313](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/313-cloud-saves-cross-save-y-resolucion-de-conflictos/README.md)): el guardado ya lleva versión local y dispositivo, que son los campos que hacen falta, pero la lógica de conflicto no está.
- **No hay presupuestos de rendimiento** ([clase 321](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/321-performance-regression-testing/README.md)) ni pipeline de release ([322](../../classes/parte-19-ingenieria-de-produccion-backend-y-confiabilidad/322-build-y-release-engineering/README.md)).
