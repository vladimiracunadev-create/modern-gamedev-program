class_name Proveedores
extends RefCounted

## Implementaciones de `AIProvider` (clase 334).
##
## Tres, y el orden en que se prueban importa: `SinIA` es SIEMPRE el último de
## la cadena, y es el modo por defecto de la versión publicada. Si el juego no
## es completo así, el diseño tiene un problema anterior a esta clase.


class MockProvider extends AIProvider:
	## Determinista, gratis y sin red. Es la implementación que más se usa:
	## sin ella no hay tests, ni CI, ni desarrollo offline, ni forma de
	## reproducir un bug.
	var caido: bool = false
	var llamadas: int = 0

	var _rng := RandomNumberGenerator.new()
	var _respuestas: Array = []
	var _indice: int = 0

	func _init(semilla: int = 1234) -> void:
		_rng.seed = semilla

	func nombre() -> String:
		return "mock"

	func disponible() -> bool:
		return not caido

	func responder(texto: String) -> void:
		## Fija la siguiente respuesta: así se escriben los tests.
		_respuestas.append(texto)

	func completar(p: Peticion) -> Respuesta:
		llamadas += 1
		var r := Respuesta.new()
		r.proveedor = "mock"
		if caido:
			r.error = "proveedor no disponible"
			return r
		if _indice < _respuestas.size():
			r.ok = true
			r.texto = _respuestas[_indice]
			_indice += 1
			return r
		# Sin respuesta fijada: una salida DETERMINISTA derivada de la
		# petición, para que los tests que no fijan nada sigan siendo
		# reproducibles.
		r.ok = true
		r.texto = JSON.stringify({
			"dialogo": "Hmm. (respuesta simulada %d)" % (hash(p.sistema + p.usuario) % 1000),
			"intencion": {"tipo": "ninguna", "parametros": {}},
			"emocion": "neutral",
		})
		r.tokens_entrada = (p.sistema.length() + p.usuario.length()) / 4
		r.tokens_salida = r.texto.length() / 4
		return r


class MockAdversario extends AIProvider:
	## Devuelve la PEOR respuesta posible: el modelo obedeciendo por completo a
	## un atacante. Si el sistema resiste esto, resiste cualquier prompt
	## injection real — y como es determinista, la prueba es fiable.
	var ataques: Array = []
	var _indice: int = 0

	func nombre() -> String:
		return "mock_adversario"

	func disponible() -> bool:
		return true

	func completar(_p: Peticion) -> Respuesta:
		var r := Respuesta.new()
		r.proveedor = "mock_adversario"
		r.ok = true
		r.texto = str(ataques[_indice % maxi(1, ataques.size())]) if not ataques.is_empty() else ""
		_indice += 1
		return r


class SinIA extends AIProvider:
	## No es un error ni una degradación: es el modo NORMAL de un juego que no
	## depende de la IA. El gameplay pregunta `hay_ia()` y usa su diálogo
	## escrito.
	func nombre() -> String:
		return "ninguno"

	func disponible() -> bool:
		return true

	func completar(_p: Peticion) -> Respuesta:
		var r := Respuesta.new()
		r.proveedor = "ninguno"
		r.error = "sin proveedor de IA (modo contenido fijo)"
		return r
