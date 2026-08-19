# Clase 312 — Identidad, perfiles y entitlements

> Parte: **19 — Ingeniería de producción, backend y confiabilidad** · Fuente: *OWASP Authentication Cheat Sheet · Documentación de plataformas (Steamworks, tiendas móviles)*
> ⏱️ Duración estimada: **115 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Diseñar el sistema que responde a tres preguntas: **quién eres**, **qué tienes** y **qué puedes hacer**. Identidad (autenticación), perfil (tus datos) y entitlements (tus derechos sobre contenido). Es la base de las cuentas, las compras, los DLC, los pases de temporada y el cross-play, y es también donde un error de diseño se convierte directamente en pérdida de dinero o en pérdida de cuentas de jugadores.

La regla que gobierna toda la clase es corta: **el cliente nunca decide qué tienes**. El cliente presenta una credencial, el servidor decide quién eres y qué te corresponde, y el juego se limita a pintarlo. Vas a diseñar cuentas invitado que se puedan promocionar sin perder progreso, vinculación con plataformas (Steam, Google, Apple), un ciclo de vida de tokens que no guarde secretos en el cliente, y un sistema de entitlements que sobreviva a reembolsos, regalos y compras familiares.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Distinguir autenticación, autorización, identidad y perfil, y no mezclarlos.
2. Implementar cuentas invitado y su promoción a cuenta permanente sin perder progreso.
3. Diseñar vinculación de cuentas de plataforma con detección de conflictos.
4. Implementar un ciclo de vida de tokens (acceso corto, refresco largo, revocación).
5. Modelar entitlements como concesiones verificables con origen y estado.
6. Verificar recibos de compra en servidor y tratar reembolsos y revocaciones.
7. Enumerar qué **nunca** debe guardarse en el cliente y por qué.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Autenticación vs autorización | Confundirlas produce agujeros donde nadie los busca. |
| 2 | Identidad estable | El id interno no puede ser el correo ni el nick. |
| 3 | Cuentas invitado | Reducen fricción; su promoción es donde se pierde progreso. |
| 4 | Vinculación de plataformas | Cross-play y cross-save dependen de hacerlo bien. |
| 5 | Tokens y su ciclo de vida | Un token eterno es una contraseña que no se puede cambiar. |
| 6 | Secretos en el cliente | No existe forma de ocultarlos: hay que diseñar sin ellos. |
| 7 | Entitlements | El modelo correcto para DLC, pases y regalos. |
| 8 | Verificación de recibos | Es lo único que separa una compra de un `true` falsificado. |
| 9 | Reembolsos y revocación | Ocurren, y el sistema debe soportarlos sin dramas. |
| 10 | Sesiones y dispositivos | Un jugador en dos sitios a la vez es un caso normal. |

## 📖 Definiciones y características

- **Autenticación**: demostrar quién eres. Clave: produce una identidad, no permisos.
- **Autorización**: decidir qué puedes hacer. Clave: siempre en servidor, siempre por petición.
- **Identidad (player id)**: identificador interno, estable y opaco de un jugador. Clave: no es el correo, ni el nick, ni el id de plataforma.
- **Perfil**: datos del jugador (nombre visible, avatar, progreso, ajustes). Clave: es contenido mutable, separado de la identidad.
- **Cuenta invitado**: identidad creada sin credenciales, ligada al dispositivo. Clave: reduce fricción y es frágil por diseño.
- **Promoción de cuenta**: convertir una invitado en permanente conservando el progreso. Clave: debe ser un cambio de credencial, no una cuenta nueva.
- **Vinculación (account linking)**: asociar varias credenciales de plataforma a una identidad. Clave: hay que decidir qué pasa si ambas tenían progreso.
- **Token de acceso**: credencial de corta duración que autoriza peticiones. Clave: corta duración limita el daño si se filtra.
- **Token de refresco**: credencial de larga duración que obtiene tokens de acceso. Clave: se guarda con el mecanismo más seguro del dispositivo y se puede revocar.
- **Revocación**: invalidar un token antes de que expire. Clave: es la respuesta a "me han robado la cuenta".
- **Secreto**: clave que no debe conocerse (clave de API, firma). Clave: cualquier cosa en el binario del cliente es pública.
- **Entitlement**: derecho de un jugador sobre un contenido o capacidad. Clave: es una concesión con origen, no una bandera.
- **Origen del entitlement**: cómo se obtuvo (compra, regalo, promoción, suscripción). Clave: determina si puede revocarse y cómo.
- **Recibo de compra**: comprobante emitido por la tienda. Clave: se verifica **en servidor** contra la tienda, nunca en el cliente.
- **Reembolso**: devolución que retira el derecho. Clave: el entitlement pasa a revocado, no se borra (auditoría).
- **Suscripción**: entitlement con caducidad renovable. Clave: exige comprobar vigencia, no solo existencia.
- **Sesión**: periodo de uso autenticado desde un dispositivo. Clave: varias simultáneas son normales; decide si las limitas.

## 🧰 Herramientas y preparación

Trabajaremos con el `MockBackend` de la [clase 311](../311-arquitectura-backend-para-videojuegos/README.md) — nada de servicios reales ni claves. Documentación de apoyo: [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html), [OAuth 2.0 (RFC 6749)](https://datatracker.ietf.org/doc/html/rfc6749) y la [documentación de Steamworks sobre autenticación](https://partner.steamgames.com/doc/features/auth). Este es el punto exacto donde conviene decir algo incómodo: **no implementes tu propio sistema de contraseñas** si puedes evitarlo. Usa las identidades de plataforma y proveedores estándar.

## 🧪 Laboratorio guiado

1. **El modelo.** Tres cosas distintas que la gente mezcla:

```gdscript
class_name Identidad
extends RefCounted

# Lo que ERES. Opaco, estable, sin significado. Nunca se muestra al jugador.
var player_id: StringName = &""
var creada_en: float = 0.0
var es_invitado: bool = true
var credenciales: Array[Dictionary] = []   # [{proveedor, subject_id, vinculada_en}]
```

```gdscript
class_name Perfil
extends RefCounted

# Lo que TIENES. Mutable, visible, editable.
var player_id: StringName = &""
var nombre_visible: String = ""
var avatar: String = ""
var pais: String = ""            # solo si se necesita de verdad (ver clase 317)
var nivel: int = 1
```

```gdscript
class_name Entitlement
extends RefCounted

enum Estado { ACTIVO, REVOCADO, EXPIRADO }
enum Origen { COMPRA, REGALO, PROMOCION, SUSCRIPCION, PREPEDIDO }

var sku: StringName = &""          # "dlc_isla_norte", "pase_temporada_3"
var estado: Estado = Estado.ACTIVO
var origen: Origen = Origen.COMPRA
var concedido_en: float = 0.0
var expira_en: float = -1.0        # -1 = permanente
var referencia: String = ""        # id de transacción de la tienda, para auditoría

func vigente(ahora: float) -> bool:
	if estado != Estado.ACTIVO:
		return false
	return expira_en < 0.0 or ahora < expira_en
```

Fíjate en que un entitlement revocado **no se borra**: se marca. Borrarlo destruye la trazabilidad de un reembolso y hace imposible responder a una reclamación.

2. **El servicio de identidad (lado servidor, aquí simulado):**

```gdscript
class_name ServicioIdentidad
extends RefCounted

enum Fallo { OK, CREDENCIAL_INVALIDA, YA_VINCULADA, CONFLICTO_DE_PROGRESO, TOKEN_EXPIRADO, REVOCADO }

const VIDA_ACCESO := 900.0        # 15 min
const VIDA_REFRESCO := 2592000.0  # 30 días

var _identidades := {}            # player_id -> Identidad
var _por_credencial := {}         # "proveedor:subject" -> player_id
var _refrescos := {}              # token -> {player_id, expira, revocado}
var _rng := RandomNumberGenerator.new()

func crear_invitado(ahora: float) -> Identidad:
	var id := Identidad.new()
	id.player_id = _nuevo_id()
	id.creada_en = ahora
	id.es_invitado = true
	_identidades[id.player_id] = id
	return id

func _nuevo_id() -> StringName:
	# Opaco y sin información: no incorpora fecha, correo ni contador visible.
	return StringName("plr_" + Marshalls.raw_to_base64(
		PackedByteArray(range(16).map(func(_i): return _rng.randi() % 256))
	).replace("/", "_").replace("+", "-").substr(0, 22))
```

3. **Vincular una credencial de plataforma.** El caso difícil es el conflicto de progreso:

```gdscript
func vincular(player_id: StringName, proveedor: String, subject: String,
			  ahora: float, resolver: String = "") -> Fallo:
	var clave := "%s:%s" % [proveedor, subject]

	if _por_credencial.has(clave):
		var otro: StringName = _por_credencial[clave]
		if otro == player_id:
			return Fallo.OK                       # ya estaba: operación idempotente
		# La credencial pertenece a OTRA identidad con progreso propio. Esto no
		# se resuelve solo: el jugador tiene que elegir, y con información.
		if resolver == "":
			return Fallo.CONFLICTO_DE_PROGRESO
		if resolver == "usar_existente":
			return Fallo.OK                       # se descarta la invitado actual
		if resolver != "fusionar":
			return Fallo.CONFLICTO_DE_PROGRESO
		_fusionar(otro, player_id)

	var id: Identidad = _identidades[player_id]
	id.credenciales.append({"proveedor": proveedor, "subject_id": subject, "vinculada_en": ahora})
	id.es_invitado = false                        # promoción: MISMA identidad, nueva credencial
	_por_credencial[clave] = player_id
	return Fallo.OK
```

La promoción de invitado a permanente es exactamente esto: **añadir una credencial a la identidad que ya existe**. Si en su lugar creas una cuenta nueva y copias datos, aparecen los bugs clásicos de "he perdido mi progreso al iniciar sesión".

4. **Tokens.** Corto para acceder, largo para refrescar, y revocables:

```gdscript
func emitir_tokens(player_id: StringName, ahora: float) -> Dictionary:
	var refresco := _nuevo_token()
	_refrescos[refresco] = {"player_id": player_id, "expira": ahora + VIDA_REFRESCO, "revocado": false}
	return {
		"acceso": _firmar(player_id, ahora + VIDA_ACCESO),
		"refresco": refresco,
		"expira_en": ahora + VIDA_ACCESO,
	}

func refrescar(token: String, ahora: float) -> Dictionary:
	var r: Dictionary = _refrescos.get(token, {})
	if r.is_empty() or r["revocado"] or ahora >= float(r["expira"]):
		return {}
	# Rotación: cada refresco emite uno nuevo e invalida el anterior. Si alguien
	# roba un token de refresco, en cuanto el jugador legítimo refresque, el
	# robado deja de valer (y el uso del viejo delata el robo).
	_refrescos[token]["revocado"] = true
	return emitir_tokens(StringName(str(r["player_id"])), ahora)

func revocar_todo(player_id: StringName) -> int:
	var n := 0
	for t in _refrescos:
		if StringName(str(_refrescos[t]["player_id"])) == player_id and not _refrescos[t]["revocado"]:
			_refrescos[t]["revocado"] = true
			n += 1
	return n
```

> El token de **acceso** se valida por firma y no se guarda en el servidor: por eso ha de ser corto. El de **refresco** sí se guarda, y por eso se puede revocar. Esa asimetría es el diseño entero.

5. **Entitlements.** Concesión, consulta y revocación:

```gdscript
class_name ServicioEntitlements
extends RefCounted

var _por_jugador := {}            # player_id -> Array[Entitlement]

func conceder(player_id: StringName, sku: StringName, origen: Entitlement.Origen,
			  ahora: float, referencia: String, dias: float = -1.0) -> Entitlement:
	# Idempotencia por referencia: si la tienda reenvía el mismo recibo (cosa
	# que hace), no se concede dos veces.
	for e in _por_jugador.get(player_id, []):
		if e.referencia == referencia and referencia != "":
			return e
	var e := Entitlement.new()
	e.sku = sku; e.origen = origen; e.concedido_en = ahora
	e.referencia = referencia
	e.expira_en = -1.0 if dias < 0.0 else ahora + dias * 86400.0
	_por_jugador[player_id] = _por_jugador.get(player_id, []) + [e]
	return e

func tiene(player_id: StringName, sku: StringName, ahora: float) -> bool:
	for e in _por_jugador.get(player_id, []):
		if e.sku == sku and e.vigente(ahora):
			return true
	return false

func revocar(player_id: StringName, referencia: String, motivo: String) -> bool:
	for e in _por_jugador.get(player_id, []):
		if e.referencia == referencia:
			e.estado = Entitlement.Estado.REVOCADO   # se marca, NO se borra
			return true
	return false

func activos(player_id: StringName, ahora: float) -> Array:
	return _por_jugador.get(player_id, []).filter(func(e): return e.vigente(ahora))
```

6. **Verificación de recibos.** El paso que la mayoría de tutoriales se salta:

```gdscript
# EN SERVIDOR. El cliente manda el recibo opaco de la tienda; el servidor lo
# valida CONTRA LA TIENDA. Nunca contra sí mismo, y nunca en el cliente.
func procesar_compra(player_id: StringName, recibo: String, ahora: float) -> Entitlement:
	var v := _tienda.verificar(recibo)             # llamada al servicio de la tienda
	if not v["valido"]:
		push_warning("recibo inválido de %s" % player_id)
		return null
	if v["ya_usado_por"] != "" and StringName(str(v["ya_usado_por"])) != player_id:
		push_warning("recibo reutilizado: intento de fraude")
		return null
	return conceder(player_id, StringName(str(v["sku"])), Entitlement.Origen.COMPRA,
					ahora, str(v["transaccion_id"]))
```

Y el cliente, que no decide nada:

```gdscript
# EN CLIENTE. Solo pinta. Si esta función mintiera, el servidor seguiría sin
# dar el contenido: eso es lo que hace que sea seguro que sea tan simple.
func puede_entrar_a_isla_norte() -> bool:
	return _entitlements_cacheados.has("dlc_isla_norte")
```

7. **Lo que nunca va en el cliente.** Lista corta y sin excepciones:

| Nunca en el cliente | Por qué | Qué hacer |
|---|---|---|
| Claves de API de servicios de pago | El binario se puede leer | Llamar a tu backend, que sí las tiene |
| Secretos de firma | Permitirían falsificar tokens | Firmar en servidor |
| La decisión "tiene el DLC" | El jugador la cambiaría | Consultar al servidor; cachear solo para pintar |
| Contraseñas en claro o hasheadas | Un robo del dispositivo las expone | Tokens revocables, en el almacén seguro del sistema |
| El precio efectivo de una compra | Se manipularía | El servidor calcula el precio |
| Semillas de loot con valor | Se predeciría el resultado | Semilla del servidor |

8. **Probarlo:**

```gdscript
extends SceneTree

func _init() -> void:
	var idsvc := ServicioIdentidad.new()
	var ent := ServicioEntitlements.new()
	var t := 1000.0

	# Invitado con progreso, luego promoción: la identidad NO cambia.
	var inv := idsvc.crear_invitado(t)
	var antes := inv.player_id
	assert(idsvc.vincular(inv.player_id, "steam", "76561198000000001", t) == ServicioIdentidad.Fallo.OK)
	assert(inv.player_id == antes, "la promoción cambió el player_id (se pierde el progreso)")
	assert(not inv.es_invitado)

	# Vincular la MISMA credencial dos veces es idempotente.
	assert(idsvc.vincular(inv.player_id, "steam", "76561198000000001", t) == ServicioIdentidad.Fallo.OK)

	# Vincular una credencial de otra identidad exige decisión del jugador.
	var otro := idsvc.crear_invitado(t)
	assert(idsvc.vincular(otro.player_id, "steam", "76561198000000001", t)
		== ServicioIdentidad.Fallo.CONFLICTO_DE_PROGRESO)

	# Tokens: rotación y revocación.
	var tk := idsvc.emitir_tokens(inv.player_id, t)
	var tk2 := idsvc.refrescar(tk["refresco"], t + 10.0)
	assert(not tk2.is_empty(), "el refresco válido debería funcionar")
	assert(idsvc.refrescar(tk["refresco"], t + 20.0).is_empty(),
		"un token de refresco ya usado debe quedar invalidado")

	# Entitlements: idempotencia, vigencia y revocación.
	ent.conceder(inv.player_id, &"dlc_isla_norte", Entitlement.Origen.COMPRA, t, "txn_1")
	ent.conceder(inv.player_id, &"dlc_isla_norte", Entitlement.Origen.COMPRA, t, "txn_1")
	assert(ent.activos(inv.player_id, t).size() == 1, "el mismo recibo concedió dos entitlements")
	ent.conceder(inv.player_id, &"pase_3", Entitlement.Origen.SUSCRIPCION, t, "txn_2", 30.0)
	assert(ent.tiene(inv.player_id, &"pase_3", t + 29.0 * 86400.0))
	assert(not ent.tiene(inv.player_id, &"pase_3", t + 31.0 * 86400.0), "la suscripción no expiró")
	assert(ent.revocar(inv.player_id, "txn_1", "reembolso"))
	assert(not ent.tiene(inv.player_id, &"dlc_isla_norte", t), "el reembolso no retiró el derecho")

	print("== 11 comprobaciones, 0 fallos ==")
	quit()
```

## ✍️ Ejercicios

1. Implementa la fusión de progreso al vincular dos identidades con datos, con una política explícita (quedarse con el nivel mayor, sumar monedas, etc.).
2. Añade un límite de sesiones simultáneas y decide qué pasa con la más antigua.
3. Implementa "cerrar sesión en todos los dispositivos" con `revocar_todo` y comprueba el efecto.
4. Añade entitlements de regalo con remitente y mensaje, y su revocación por reembolso del comprador.
5. Modela un pase de temporada con niveles y comprueba que sus recompensas dependen de la vigencia.
6. Escribe un test que intente reutilizar un recibo en otra cuenta y verifique que se rechaza.
7. Documenta la política de recuperación de cuentas de tu juego (qué se pide, qué se comprueba, qué no se puede recuperar).

## 📝 Reto verificable

Implementa identidad con invitados y promoción, vinculación de al menos dos proveedores con detección de conflicto, tokens de acceso y refresco con rotación y revocación, y entitlements con origen, vigencia, idempotencia por recibo y revocación.

**Criterio de aceptación**: una prueba headless con **al menos 18 aserciones** demuestra que: (a) promocionar una cuenta invitado conserva el `player_id` y todo el progreso asociado; (b) vincular la misma credencial dos veces es idempotente y vincular una ajena devuelve `CONFLICTO_DE_PROGRESO`; (c) un token de refresco usado queda invalidado y su reutilización falla; (d) `revocar_todo` invalida todos los refrescos del jugador y ninguno de otros; (e) el mismo `referencia` de recibo no concede dos entitlements; (f) una suscripción deja de estar vigente al pasar su fecha; (g) un entitlement revocado deja de conceder acceso pero **sigue existiendo** en la lista completa; (h) ninguna función del cliente decide la posesión de contenido (comprobable porque la única fuente es la respuesta del servicio).

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El jugador pierde el progreso al iniciar sesión | La promoción crea una cuenta nueva. Añade la credencial a la identidad existente. |
| Un recibo compartido desbloquea el DLC a varias cuentas | No se comprueba la reutilización. Verifica en servidor y liga el recibo a un jugador. |
| Un reembolso no retira el contenido | Solo se comprobaba la existencia del entitlement. Comprueba `vigente()` con estado. |
| Robar el móvil da acceso indefinido | Token de larga duración sin revocación. Rotación de refrescos y "cerrar sesión en todos". |
| La clave de API apareció en un análisis del APK | Se incluyó un secreto en el cliente. No hay solución local: muévela al backend. |
| Las cuentas invitado se pierden al reinstalar | Es inherente al modelo. Avisa al jugador y ofrece promoción temprana. |
| El id de jugador revela información (correo, fecha) | Se usó un identificador con significado. Genera ids opacos. |
| Dos dispositivos se pelean por la sesión | No hay política de concurrencia. Decide (permitir, expulsar, avisar) y documéntala. |

## ❓ Preguntas frecuentes

**❓ ¿Puedo implementar login con contraseña yo mismo?** Puedes, pero rara vez deberías. Implica hashing correcto, recuperación de cuenta, protección contra fuerza bruta, filtrado de contraseñas comprometidas y respuesta a incidentes. Si tu juego está en una plataforma, usa su identidad; si necesitas cuenta propia, usa un proveedor de identidad estándar y céntrate en tu juego.

**❓ ¿Dónde guardo el token de refresco en el cliente?** En el almacén seguro del sistema cuando exista (Keychain en Apple, Keystore en Android, credential locker en Windows). Si no lo hay, en `user://` sabiendo que **no es secreto frente a alguien con acceso al dispositivo** — por eso importa tanto que sea revocable.

**❓ ¿Necesito todo esto para un juego single-player de pago?** No. Si no hay compras dentro del juego ni contenido de servidor, la plataforma ya gestiona tu entitlement (has comprado el juego). Esto empieza a hacer falta con DLC, pases, cross-save o cualquier compra dentro del juego.

**❓ ¿Y el cross-play y el cross-save?** Se apoyan exactamente en esto: una identidad con varias credenciales de plataforma. Si la identidad es propia (y no la de una plataforma concreta), el cross-save de la [clase 313](../313-cloud-saves-cross-save-y-resolucion-de-conflictos/README.md) es casi inmediato. Si dependes de la identidad de Steam, no podrás llevar el progreso a consola.

**❓ ¿Qué hago con los datos de menores?** Es una cuestión legal seria (COPPA, RGPD y equivalentes locales) y no se resuelve con código: afecta a qué datos puedes pedir, qué consentimiento necesitas y qué funciones sociales puedes ofrecer. Se trata en la [clase 317](../317-telemetria-privacidad-y-gobernanza-de-datos/README.md) y, en su vertiente contractual, en la [clase 273](../../parte-16-produccion-publicacion-monetizacion-y-liveops/273-presupuesto-contratos-y-aspectos-legales/README.md).

## 🔗 Referencias

- OWASP — Authentication Cheat Sheet: <https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html> · uso: se instala o se consulta en la preparación
- OWASP — Session Management Cheat Sheet: <https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento
- IETF — RFC 6749, OAuth 2.0: <https://datatracker.ietf.org/doc/html/rfc6749> · uso: se instala o se consulta en la preparación
- Steamworks — autenticación de usuarios y ownership: <https://partner.steamgames.com/doc/features/auth> · uso: se instala o se consulta en la preparación
- Godot Docs — `Marshalls` y utilidades de codificación: <https://docs.godotengine.org/en/4.3/classes/class_marshalls.html> · uso: lectura de respaldo del objetivo; no se usa en el procedimiento

## ⬅️ Clase anterior

[Clase 311 - Arquitectura backend para videojuegos](../311-arquitectura-backend-para-videojuegos/README.md)

## ➡️ Siguiente clase

[Clase 313 - Cloud saves, cross-save y resolución de conflictos](../313-cloud-saves-cross-save-y-resolucion-de-conflictos/README.md)
