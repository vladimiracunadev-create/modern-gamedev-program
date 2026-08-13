class_name Paralelo
extends RefCounted

## Paralelismo de datos sobre `WorkerThreadPool` (clase 341).
##
## El caso ideal: el mismo trabajo sobre trozos distintos, SIN datos
## compartidos. Cada worker escribe en su propio rango, así que no hay carrera
## y no hace falta ningún mutex — que es exactamente el diseño que se busca.
##
## Los arrays son MIEMBROS, no parámetros: los `Packed*Array` de GDScript son
## copy-on-write, así que pasarlos a una función y mutarlos dentro no modifica
## el array del llamador. Es un detalle que arruina un paralelizado sin dar
## ningún error.

const POR_GRUPO := 4096

var entrada := PackedFloat32Array()
var salida := PackedFloat32Array()

var _n: int = 0
var _por_worker := PackedInt32Array()
var _umbral: float = 0.0


func crear(n: int, semilla: int = 5) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	_n = n
	entrada.resize(n)
	salida.resize(n)
	for i in n:
		entrada[i] = rng.randf_range(0.1, 100.0)
		salida[i] = 0.0


func trabajo_secuencial() -> void:
	for i in _n:
		salida[i] = _calcular(entrada[i])


func trabajo_paralelo() -> void:
	# TODO(5): reparte `_n` elementos en grupos de `POR_GRUPO` (redondeando
	# hacia arriba, y nunca menos de 1) con
	# `WorkerThreadPool.add_group_task(_trozo, grupos, -1, false, "trabajo")`
	# y ESPERA con `wait_for_group_task_completion(id)`. Sin la espera, el
	# código sigue con datos a medio escribir y el fallo aparece una vez de cada
	# mil ejecuciones.
	pass


func contar_secuencial(umbral: float) -> int:
	var n := 0
	for i in _n:
		if salida[i] > umbral:
			n += 1
	return n


func contar_paralelo(umbral: float) -> int:
	## Patrón de ACUMULADOR LOCAL: cada worker suma en una variable local y
	## escribe UNA sola vez en su casilla. Escribir en el array compartido
	## dentro del bucle provocaría falso compartido, y podría ser más lento que
	## la versión secuencial sin que hubiera ningún error visible.
	_umbral = umbral
	var grupos := maxi(1, (_n + POR_GRUPO - 1) / POR_GRUPO)
	_por_worker.resize(grupos)
	_por_worker.fill(0)
	var id := WorkerThreadPool.add_group_task(_contar_trozo, grupos, -1, false, "contar")
	WorkerThreadPool.wait_for_group_task_completion(id)
	# Combinación en orden FIJO de índice: por eso el resultado es determinista.
	var total := 0
	for v in _por_worker:
		total += v
	return total


func hash_salida() -> int:
	var trozos := PackedStringArray()
	for i in _n:
		trozos.append(str(int(salida[i] * 1000.0)))
	return hash("|".join(trozos))


static func _calcular(v: float) -> float:
	## Trabajo con peso real por elemento. Con una simple multiplicación, la
	## sobrecarga de repartir domina y el paralelismo PIERDE — que es
	## exactamente la lección de la clase 341: mide antes de paralelizar.
	var r := v
	for k in 8:
		r = sqrt(r * r + 1.0) + sin(r) * 0.5
	return r


func _trozo(indice_grupo: int) -> void:
	var ini := indice_grupo * POR_GRUPO
	var fin := mini(ini + POR_GRUPO, _n)
	# Cada worker toca SOLO [ini, fin): sin solapamiento y sin carrera.
	for i in range(ini, fin):
		salida[i] = _calcular(entrada[i])


func _contar_trozo(indice_grupo: int) -> void:
	# TODO(6): cuenta en una variable LOCAL los elementos de tu rango que
	# superan `_umbral` y escribe el total UNA sola vez en
	# `_por_worker[indice_grupo]`. Si escribes en el array compartido dentro del
	# bucle tendrás falso compartido: el resultado seguirá siendo correcto, pero
	# puede acabar más lento que la versión secuencial sin ningún error visible.
	pass
