extends Node

## Escena principal: construye las estructuras, comprueba que son correctas
## frente a la referencia e imprime el marcador que la CI busca.

const N := 50000
const N_ESPACIAL := 3000


func _ready() -> void:
	var particulas := Particulas.new()
	particulas.crear(N, 1)

	var pool := PoolObjetos.new(
		func(): return PoolObjetos.Elemento.new(), func(o): o.reiniciar(), 1000)

	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var px := PackedFloat32Array(); px.resize(N_ESPACIAL)
	var py := PackedFloat32Array(); py.resize(N_ESPACIAL)
	for i in N_ESPACIAL:
		px[i] = rng.randf_range(-1000.0, 1000.0)
		py[i] = rng.randf_range(-1000.0, 1000.0)
	var rejilla := RejillaUniforme.new(50.0)
	rejilla.construir(px, py)

	_comprobar_correccion(particulas, rejilla, px, py)

	print("Banco listo: %d partículas SoA, pool de %d, rejilla con %d celdas, %d núcleos"
		% [particulas.vivas, pool.libres(), rejilla.celdas_ocupadas(),
		   OS.get_processor_count()])


func _comprobar_correccion(p: Particulas, rejilla: RejillaUniforme,
		px: PackedFloat32Array, py: PackedFloat32Array) -> void:
	## Una optimización que cambia el resultado no es una optimización. Aquí se
	## comprueba antes de presumir de velocidad.
	var soa := Particulas.new()
	soa.crear(500, 9)
	var aos := Particulas.crear_aos(500, 9)
	for i in 30:
		soa.avanzar(0.016)
		Particulas.avanzar_aos(aos, 0.016)

	var ref := RejillaUniforme.fuerza_bruta(px, py, 0.0, 0.0, 120.0)
	ref.sort()
	var rej := rejilla.consultar_radio(0.0, 0.0, 120.0)

	print("  correcto: SoA==AoS=%s · rejilla==fuerza_bruta=%s (%d objetos en el radio)"
		% [soa.equivalente_a(aos), rej == ref, ref.size()])
