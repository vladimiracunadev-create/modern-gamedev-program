# Clase 323 — Parches, delivery y recuperación

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *Google, «Site Reliability Engineering» (gestión de incidentes y postmortems) · Documentación de plataformas sobre parches y CDN*
> ⏱️ Duración estimada: **120 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Cerrar el ciclo: cómo llega el juego actualizado a los jugadores y **qué se hace cuando algo sale mal**. La [clase 279](../../parte-16-produccion-publicacion-monetizacion-y-liveops/279-post-lanzamiento-parches-comunidad-y-retencion/README.md) trató el post-lanzamiento desde la producción y la comunidad; esta lo trata desde la ingeniería: parches delta, catálogos de contenido, CDN, versionado de assets, hotfixes, rollback, publicación gradual, modo degradado y recuperación ante desastre.

La idea que gobierna la clase es que **fallar es inevitable y recuperarse es diseñable**. Un equipo maduro no se distingue por no tener incidentes, sino por el tiempo que tarda en detectarlos y en volver a un estado bueno. Vas a construir las piezas que hacen ese tiempo corto: detección, rollback ensayado, modo degradado y un procedimiento de incidente que no dependa de que esté despierta la persona que sabe.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Diseñar la entrega de actualizaciones con catálogo de contenido versionado.
2. Explicar cómo funciona un parche delta y cuándo compensa.
3. Implementar publicación gradual con criterios de parada automáticos.
4. Diseñar y **ensayar** un rollback de build y de configuración.
5. Implementar modo degradado por subsistema con criterios claros.
6. Escribir un procedimiento de incidente y un postmortem sin culpables.
7. Definir objetivos de recuperación (RTO/RPO) y comprobar que se cumplen.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Catálogo de contenido | Permite actualizar assets sin publicar una build. |
| 2 | Parche delta | La diferencia entre 60 MB y 3 GB de descarga. |
| 3 | CDN y caché | Dónde vive el contenido y por qué a veces sirve lo viejo. |
| 4 | Publicación gradual | Limita el daño de un fallo al porcentaje activado. |
| 5 | Criterio de parada | Detener automáticamente antes de que crezca. |
| 6 | Hotfix | Corrección urgente por la vía rápida, con reglas. |
| 7 | Rollback | Volver atrás rápido; y ensayarlo antes de necesitarlo. |
| 8 | Modo degradado | Seguir jugando aunque falte una parte. |
| 9 | Procedimiento de incidente | Roles y pasos, para no improvisar a las 3 de la mañana. |
| 10 | Postmortem sin culpables | Convierte un incidente en una mejora del sistema. |

## 📖 Definiciones y características

- **Catálogo de contenido**: índice versionado de assets descargables con su hash y su URL. Clave: permite actualizar contenido sin tocar el ejecutable.
- **Versionado de assets**: incluir el hash en el nombre o la ruta del recurso. Clave: hace la caché de CDN trivialmente correcta.
- **Parche delta**: fichero con solo las diferencias respecto a la versión anterior. Clave: reduce la descarga uno o dos órdenes de magnitud.
- **Parche completo**: sustitución total de los archivos. Clave: más simple y siempre válido; es el respaldo del delta.
- **CDN**: red que sirve contenido desde nodos cercanos al jugador. Clave: rápida y con caché, lo que trae el problema de la invalidación.
- **Invalidación de caché**: forzar que la CDN deje de servir la versión antigua. Clave: se evita casi siempre versionando el nombre del asset.
- **Publicación gradual**: activar la versión nueva para un porcentaje creciente. Clave: convierte un desastre en un incidente pequeño.
- **Criterio de parada (halt)**: umbral de métricas que detiene la publicación automáticamente. Clave: sin él, el rollout gradual no protege de nada por la noche.
- **Hotfix**: corrección urgente publicada fuera del ciclo normal. Clave: alcance mínimo y revisión obligatoria pese a la prisa.
- **Rollback**: volver a la versión anterior conocida como buena. Clave: debe estar ensayado, o no existe.
- **Compatibilidad hacia atrás**: capacidad de la versión nueva de convivir con datos y clientes viejos. Clave: es lo que hace posible el rollback.
- **Modo degradado**: funcionamiento con capacidades reducidas ante un fallo parcial. Clave: se diseña por subsistema, con antelación.
- **RTO (Recovery Time Objective)**: tiempo máximo aceptable hasta recuperar el servicio. Clave: dirige las decisiones de arquitectura.
- **RPO (Recovery Point Objective)**: pérdida máxima aceptable de datos, en tiempo. Clave: determina la frecuencia de copias.
- **Runbook**: guion paso a paso para responder a un tipo de incidente. Clave: sirve para que no haga falta un experto a las 3 de la mañana.
- **Postmortem sin culpables (blameless)**: análisis centrado en el sistema, no en las personas. Clave: es lo único que produce mejoras reales.

## 🧰 Herramientas y preparación

Continuamos con el `MockBackend`, los flags de la [clase 315](../315-remote-config-feature-flags-y-experimentos/README.md) y los artefactos de la [322](../322-build-y-release-engineering/README.md). Trabajaremos en `res://infraestructura/contenido/` y `docs/runbooks/`. Documentación de fondo: el capítulo de gestión de incidentes de [Google SRE](https://sre.google/sre-book/managing-incidents/) y la política de parches de las plataformas donde publiques.

## 🧪 Laboratorio guiado

1. **El catálogo de contenido.** Versionado por hash, que resuelve la caché de una vez:

```json
{
  "version_catalogo": 42,
  "build_minima": "1.4.0",
  "base_url": "https://cdn.mijuego.example/assets/",
  "entradas": {
    "texturas/pueblo_atlas.ctex": {
      "hash": "9f2c4a8b1d3e5f70",
      "bytes": 4194304,
      "url": "texturas/pueblo_atlas.9f2c4a8b1d3e5f70.ctex",
      "obligatorio": true
    },
    "audio/tema_invierno.ogg": {
      "hash": "3b7e1c9a6f2d4e88",
      "bytes": 8388608,
      "url": "audio/tema_invierno.3b7e1c9a6f2d4e88.ogg",
      "obligatorio": false
    }
  }
}
```

El hash en el nombre del archivo es la técnica clave: como cada versión tiene URL distinta, **la CDN puede cachear para siempre** y no hay invalidación que gestionar. Cambiar un asset es publicar otro fichero y actualizar el catálogo.

2. **El descargador.** Verifica, reintenta y no bloquea el juego:

```gdscript
class_name Actualizador
extends Node

signal progreso(descargados: int, total: int, bytes: int)
signal listo(cambios: int)
signal fallo(motivo: String)

var _catalogo := {}
var _local := {}              # ruta -> hash instalado
const DIR := "user://contenido"

func comprobar(url_catalogo: String) -> void:
	var r := await _pedir(url_catalogo)
	if not r.ok:
		fallo.emit("no se pudo obtener el catálogo")
		return
	var nuevo: Dictionary = r.datos
	if _comparar_versiones(str(nuevo.get("build_minima", "0.0.0")),
						   str(Version.info()["version"])) > 0:
		# Contenido que exige una build más nueva: NO se descarga. Si se
		# descargara, el juego cargaría assets que no sabe usar.
		fallo.emit("hay contenido nuevo que requiere actualizar el juego")
		return
	_catalogo = nuevo
	await _sincronizar()

func _sincronizar() -> void:
	var pendientes := []
	for ruta in _catalogo.get("entradas", {}):
		var e: Dictionary = _catalogo["entradas"][ruta]
		if _local.get(ruta, "") != str(e["hash"]):
			pendientes.append([ruta, e])

	var descargados := 0
	var bytes := 0
	for par in pendientes:
		var ruta: String = par[0]
		var e: Dictionary = par[1]
		var datos := await _descargar(str(_catalogo["base_url"]) + str(e["url"]))
		if datos.is_empty():
			if bool(e.get("obligatorio", false)):
				fallo.emit("no se pudo descargar %s" % ruta)
				return
			continue                       # opcional: se sigue sin él
		# Verificación SIEMPRE: una descarga truncada por la CDN produce un
		# archivo válido de tamaño incorrecto, y eso rompe el juego después.
		if _hash(datos) != str(e["hash"]):
			fallo.emit("hash incorrecto en %s" % ruta)
			return
		_guardar_atomico(DIR.path_join(ruta), datos)
		_local[ruta] = str(e["hash"])
		descargados += 1
		bytes += datos.size()
		progreso.emit(descargados, pendientes.size(), bytes)

	_guardar_indice_local()
	listo.emit(descargados)
```

3. **Parches delta.** Cuándo compensan y cuándo no:

| Situación | Delta | Completo |
|---|---|---|
| Cambio de código, assets iguales | ✔ (unos MB) | ✗ (GB) |
| Textura recomprimida entera | ✗ (parecido al completo) | ✔ |
| Muchos archivos pequeños tocados | Depende | Suele ganar el completo por archivo |
| Instalación desde cero | ✗ | ✔ |
| Jugador varias versiones atrás | Encadenar deltas o completo | ✔ si son muchas |

Regla práctica: genera **ambos** y deja que el cliente elija por tamaño. Y ten siempre el completo: es el que funciona cuando el delta falla.

```gdscript
func plan_de_actualizacion(version_local: String, destino: String) -> Dictionary:
	var deltas := _catalogo["deltas"].get("%s->%s" % [version_local, destino], null)
	var completo: Dictionary = _catalogo["completos"][destino]
	# El delta solo gana si ahorra al menos un 40 %: por debajo, la complejidad
	# de aplicarlo y el riesgo de fallo no compensan.
	if deltas != null and int(deltas["bytes"]) < int(completo["bytes"]) * 0.6:
		return {"tipo": "delta", "bytes": deltas["bytes"], "url": deltas["url"],
				"respaldo": completo}
	return {"tipo": "completo", "bytes": completo["bytes"], "url": completo["url"]}
```

4. **Publicación gradual con parada automática.** Lo que convierte un desastre en un susto:

```gdscript
class_name Rollout
extends RefCounted

signal etapa_cambiada(porcentaje: int)
signal detenido(motivo: String, metricas: Dictionary)

const ETAPAS := [1, 5, 25, 50, 100]
const ESPERA_ENTRE_ETAPAS := 3600.0        # 1 h de observación por etapa

# Criterios de PARADA. Si se cumple cualquiera, el rollout se detiene solo.
const LIMITES := {
	"tasa_crash":       {"max": 0.010, "linea_base": 0.004},   # 1 % absoluto
	"tasa_error_api":   {"max": 0.020, "linea_base": 0.005},
	"p99_carga_ms":     {"max": 5000.0, "linea_base": 2100.0},
	"sesiones_relativo":{"min": 0.85},                          # -15 % es señal de rotura
}

var etapa := 0
var _t := 0.0

func tick(delta: float, metricas: Dictionary) -> void:
	_t += delta
	var motivo := _debe_detenerse(metricas)
	if motivo != "":
		detenido.emit(motivo, metricas)
		return
	if _t >= ESPERA_ENTRE_ETAPAS and etapa < ETAPAS.size() - 1:
		_t = 0.0
		etapa += 1
		etapa_cambiada.emit(ETAPAS[etapa])

func _debe_detenerse(m: Dictionary) -> String:
	for clave in LIMITES:
		var l: Dictionary = LIMITES[clave]
		var v := float(m.get(clave, 0.0))
		if l.has("max") and v > float(l["max"]):
			return "%s = %.4f supera el máximo %.4f" % [clave, v, l["max"]]
		# Además del absoluto, el EMPEORAMIENTO relativo: doblar una tasa que
		# era buena es una señal aunque siga por debajo del máximo.
		if l.has("linea_base") and v > float(l["linea_base"]) * 2.0:
			return "%s = %.4f dobla su línea base %.4f" % [clave, v, l["linea_base"]]
		if l.has("min") and v < float(l["min"]):
			return "%s = %.3f por debajo del mínimo %.3f" % [clave, v, l["min"]]
	return ""

func porcentaje() -> int:
	return ETAPAS[etapa]
```

5. **Rollback.** Tres niveles, de más rápido a más lento:

| Nivel | Qué se revierte | Tiempo | Requisito |
|---|---|---|---|
| 1 | Feature flag / kill switch | Segundos | El código nuevo está tras un flag (clase 315) |
| 2 | Configuración remota | Minutos | Valores anteriores guardados |
| 3 | Build completa | Horas (revisión de tienda) | Artefacto anterior disponible y compatible |

```python
#!/usr/bin/env python3
"""Rollback de build: vuelve a la versión anterior conocida como buena."""
def rollback(version_actual, version_objetivo):
    # 1) Comprobar que el artefacto objetivo existe y verifica.
    manifiesto = descargar_manifiesto(version_objetivo)
    verificar_checksums(manifiesto)

    # 2) COMPATIBILIDAD HACIA ATRÁS: lo que casi siempre se olvida. Si la
    #    versión actual subió SAVE_VERSION, los jugadores que ya han guardado
    #    NO pueden volver: sus saves son del futuro para la build vieja.
    if save_version(version_objetivo) < save_version(version_actual):
        raise RuntimeError(
            f"rollback inseguro: la {version_actual} escribe saves v"
            f"{save_version(version_actual)} y la {version_objetivo} solo entiende "
            f"hasta v{save_version(version_objetivo)}. Hace falta un hotfix, no un rollback.")

    # 3) Publicar el artefacto anterior en el canal.
    publicar(version_objetivo, canal="production")
    registrar_incidente(f"rollback {version_actual} -> {version_objetivo}")
    return True
```

Ese punto 2 es la lección más cara de la clase: **una versión que cambia el formato del save no se puede revertir sin más**. Por eso los cambios de `SAVE_VERSION` se despliegan detrás de un flag y se activan una vez confirmada la estabilidad.

6. **Modo degradado.** Diseñado por subsistema, con antelación:

```gdscript
class_name Degradacion
extends RefCounted

enum Nivel { COMPLETO, DEGRADADO, DESACTIVADO }

var _estado := {}

func evaluar(subsistema: StringName, fallos: int, total: int) -> Nivel:
	if total == 0:
		return Nivel.COMPLETO
	var tasa := float(fallos) / float(total)
	var nivel := Nivel.COMPLETO
	if tasa > 0.5:   nivel = Nivel.DESACTIVADO
	elif tasa > 0.1: nivel = Nivel.DEGRADADO
	if _estado.get(subsistema, Nivel.COMPLETO) != nivel:
		_estado[subsistema] = nivel
		Log.warn("degradacion", {"subsistema": String(subsistema), "nivel": nivel, "tasa": tasa})
	return nivel
```

| Subsistema | Completo | Degradado | Desactivado |
|---|---|---|---|
| Cloud save | Sincroniza | Solo local, cola pendiente | Solo local, aviso visible |
| Tienda | Todo | Solo consulta, sin comprar | Oculta con explicación |
| Matchmaking | Emparejamiento normal | Cola más lenta, criterios laxos | Solo modos offline |
| Telemetría | Envía | Encola en disco | Descarta silenciosamente |
| Remote config | Remoto | Última caché válida | Defectos compilados |
| Tabla de clasificación | En vivo | Datos cacheados con fecha | Oculta |

Lo importante de esta tabla: **se escribe antes del incidente**, y cada celda es una decisión de producto, no una improvisación.

7. **El procedimiento de incidente.** Roles y pasos, en un runbook:

```markdown
# Runbook: subida de la tasa de crash tras una publicación

## Detección
Alerta `tasa_crash > 1 % (5 min)` o informes en la comunidad.

## Roles
- **Responsable del incidente**: coordina y decide. NO depura.
- **Investigación**: mira crashes, logs y correlaciona con la publicación.
- **Comunicación**: informa a la comunidad y al equipo.

## Pasos
1. **Declarar** el incidente y anotar la hora (todo lo demás se mide desde aquí).
2. **Detener** el rollout: `python scripts/rollout.py --detener`.
3. **Acotar**: ¿afecta a una plataforma, una versión, un porcentaje?
4. **Mitigar antes que arreglar**, por este orden:
   a. Kill switch de la función sospechosa (segundos)
   b. Revertir la configuración remota (minutos)
   c. Rollback de build — comprobar antes la compatibilidad de saves (horas)
5. **Confirmar** que la métrica vuelve a la línea base.
6. **Comunicar**: qué pasó, a quién afectó, qué se ha hecho, qué falta.
7. **Cerrar** y convocar el postmortem en 48 h.

## Objetivos
- Detección → mitigación: **< 30 min** (RTO)
- Pérdida de progreso de jugador: **0** (RPO)
```

8. **El postmortem sin culpables.** El entregable que hace que el incidente valga algo:

```markdown
# Postmortem — 2026-03-14: crash al abrir el inventario en Android

## Impacto
2 h 15 min. 8,4 % de las sesiones de Android. 0 pérdidas de progreso.

## Cronología (todo en UTC)
- 14:02 se publica la 1.4.2 al 5 %
- 14:19 la alerta de tasa de crash salta (0,9 %)
- 14:23 se declara incidente, se detiene el rollout
- 14:31 kill switch de "inventario_v2" → la tasa vuelve a la base
- 16:17 hotfix 1.4.3 publicado y verificado

## Causa raíz
El atlas de iconos nuevo supera el tamaño máximo de textura de una familia de
GPU móviles. El dispositivo no está en la matriz de pruebas.

## Por qué no se detectó antes
1. La matriz de dispositivos no incluye esa gama.
2. El presupuesto de tamaño de textura no comprueba el límite por GPU.
3. La carga del atlas fallaba en silencio y el crash venía después.

## Qué funcionó
- El rollout gradual limitó el impacto al 5 %.
- El kill switch mitigó en 8 minutos.

## Acciones
| # | Acción | Responsable | Fecha |
|---|---|---|---|
| 1 | Añadir dos dispositivos de gama baja a la matriz | QA | 2026-03-21 |
| 2 | Presupuesto de tamaño máximo de textura por perfil | Tools | 2026-03-28 |
| 3 | Fallo ruidoso al no cargar un atlas | Cliente | 2026-03-20 |
| 4 | Runbook: añadir "comprobar tamaños de textura" | SRE | 2026-03-18 |

## Sin culpables
Nadie cometió un error. El sistema permitió que un asset incompatible llegara
a producción sin una comprobación que hoy no existía. La acción #2 la crea.
```

## ✍️ Ejercicios

1. Implementa el catálogo de contenido con hash en el nombre y verificación al descargar.
2. Implementa la elección entre delta y completo según el ahorro relativo.
3. Simula un rollout con métricas sintéticas que empeoran y comprueba que se detiene solo.
4. **Ensaya** un rollback completo de tu juego y cronometra cuánto tardas.
5. Escribe la tabla de modo degradado de tu juego, subsistema por subsistema.
6. Escribe un runbook para el incidente que consideres más probable en tu proyecto.
7. Redacta el postmortem de un incidente real (o de uno simulado) siguiendo la plantilla.

## 📝 Reto verificable

Implementa la cadena de entrega y recuperación: catálogo versionado por hash con verificación, elección delta/completo, rollout gradual con criterios de parada automáticos, rollback con comprobación de compatibilidad de saves, modo degradado por subsistema, y un runbook y un postmortem escritos.

**Criterio de aceptación**: una prueba headless con **al menos 15 aserciones** demuestra que: (a) una descarga con hash incorrecto se rechaza y no se instala; (b) un asset opcional que falla no detiene la actualización y uno obligatorio sí; (c) contenido que declara `build_minima` superior a la del juego no se descarga; (d) el rollout avanza por sus etapas y **se detiene solo** cuando una métrica supera su máximo o dobla su línea base; (e) un rollback a una versión con `SAVE_VERSION` menor que la actual se **rechaza** con un mensaje que explica por qué; (f) el modo degradado cambia de nivel según la tasa de fallos y lo registra; (g) existen en el repositorio un runbook y un postmortem con la estructura completa, y el postmortem incluye acciones con responsable y fecha.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| Los jugadores siguen viendo el asset viejo | Caché de CDN sin invalidar. Versiona el nombre por hash y desaparece el problema. |
| Una descarga truncada rompe el juego | No se verifica el hash. Verifica siempre antes de instalar. |
| El rollback no fue posible | La versión nueva subió `SAVE_VERSION`. Despliega los cambios de formato tras un flag. |
| El rollout llegó al 100 % con un fallo grave | No había criterio de parada automático. Añádelo: por la noche no hay nadie mirando. |
| El hotfix rompió otra cosa | Alcance demasiado amplio con prisa. Un hotfix cambia lo mínimo y pasa revisión igual. |
| El incidente duró horas por falta de coordinación | Sin roles ni runbook. Escríbelos antes de necesitarlos. |
| El postmortem acabó en quién tuvo la culpa | Enfoque equivocado y contraproducente. Céntrate en qué permitió el fallo. |
| El rollback falló porque nadie lo había probado | No se ensayó. Ensáyalo en un canal de pruebas cada trimestre. |
| El juego se queda inservible si cae un servicio | No hay modo degradado. Diseña la tabla por subsistema. |

## ❓ Preguntas frecuentes

**❓ ¿Merece la pena implementar parches delta?** Si tu juego pesa poco (menos de 1 GB) y actualizas poco, no: el completo es más simple y más fiable. Compensa con juegos grandes y actualizaciones frecuentes. Y ten en cuenta que **las plataformas ya lo hacen por ti**: Steam y las tiendas móviles generan deltas automáticamente, así que solo necesitas implementarlo si distribuyes por tu cuenta.

**❓ ¿Cada cuánto ensayo el rollback?** Al menos una vez por trimestre y siempre antes de un lanzamiento grande, en un canal de pruebas. Un rollback que nunca se ha ejecutado es una suposición, y las suposiciones fallan justo cuando importan.

**❓ ¿Rollback o hotfix?** Rollback si el problema es grave y la versión anterior es segura de restaurar (compatibilidad de datos comprobada). Hotfix si el rollback no es posible —típicamente por el formato del save— o si el problema es acotado. El orden de preferencia real es: kill switch → configuración → hotfix → rollback, de más rápido a más lento.

**❓ ¿Qué RTO es razonable?** Depende del juego, pero como referencia: **mitigar** en menos de 30 minutos y **resolver** en menos de 24 horas es un objetivo alcanzable para un equipo pequeño si existen kill switches y runbooks. Sin esas dos cosas, ningún RTO es alcanzable.

**❓ ¿Postmortem para todos los incidentes?** Para los que tengan impacto en jugadores o hayan estado cerca de tenerlo. Los "casi" son especialmente valiosos: te dan la lección sin pagar el precio. Y la regla del **sin culpables** no es amabilidad: es lo único que hace que la gente cuente lo que pasó de verdad.

## 🔗 Referencias

- Google — *Site Reliability Engineering*, gestión de incidentes: <https://sre.google/sre-book/managing-incidents/> · uso: se instala o se consulta en la preparación
- Google — *SRE*, cultura de postmortem sin culpables: <https://sre.google/sre-book/postmortem-culture/> · uso: respalda el Tema 10 «Postmortem sin culpables»
- Godot Docs — `ProjectSettings.load_resource_pack` (contenido descargable): <https://docs.godotengine.org/en/4.3/classes/class_projectsettings.html> · uso: respalda el Tema 1 «Catálogo de contenido»
- Godot Docs — `HTTPRequest` (descargas con verificación): <https://docs.godotengine.org/en/4.3/classes/class_httprequest.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- Steamworks — actualizaciones y depots: <https://partner.steamgames.com/doc/store/application/depots> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 322 - Build y release engineering](../322-build-y-release-engineering/README.md)

## ➡️ Siguiente clase

[Clase 324 - Capstone Parte 19: un runtime de producción](../324-capstone-parte-19-un-runtime-de-produccion/README.md)
