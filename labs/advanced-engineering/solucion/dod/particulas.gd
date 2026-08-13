class_name Particulas
extends RefCounted

## Data-oriented design: AoS frente a SoA (clase 339).
##
## Las dos versiones hacen EXACTAMENTE el mismo trabajo. Lo único que cambia es
## cómo están dispuestos los datos en memoria — y esa diferencia es la que se
## mide, porque con este volumen el acceso a memoria domina sobre el cálculo.


class ParticulaAoS extends RefCounted:
	## Lo natural de escribir, y lo más lento: cada partícula es un objeto
	## suelto en el heap, así que la CPU salta por la memoria en cada
	## iteración y el prefetch no puede adivinar dónde está la siguiente.
	var pos_x: float = 0.0
	var pos_y: float = 0.0
	var vel_x: float = 0.0
	var vel_y: float = 0.0
	var vida: float = 0.0
	# Datos FRÍOS: el bucle no los usa, pero viajan en la misma línea de caché.
	var color: Color = Color.WHITE
	var tipo: int = 0
	var metadata: Dictionary = {}


# --- SoA: un array por campo, contiguo y sin `Variant` ---------------------
var pos_x := PackedFloat32Array()
var pos_y := PackedFloat32Array()
var vel_x := PackedFloat32Array()
var vel_y := PackedFloat32Array()
var vida := PackedFloat32Array()

# FRÍO: fuera del bucle caliente, para no traer líneas de caché inútiles.
var color := PackedColorArray()
var tipo := PackedByteArray()

var vivas: int = 0


func crear(n: int, semilla: int = 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	pos_x.resize(n)
	pos_y.resize(n)
	vel_x.resize(n)
	vel_y.resize(n)
	vida.resize(n)
	color.resize(n)
	tipo.resize(n)
	for i in n:
		pos_x[i] = rng.randf_range(-500.0, 500.0)
		pos_y[i] = rng.randf_range(-500.0, 500.0)
		vel_x[i] = rng.randf_range(-60.0, 60.0)
		vel_y[i] = rng.randf_range(-60.0, 60.0)
		vida[i] = rng.randf_range(1.0, 8.0)
		color[i] = Color(rng.randf(), rng.randf(), rng.randf())
		tipo[i] = rng.randi() % 4
	vivas = n


static func crear_aos(n: int, semilla: int = 1) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var out: Array = []
	out.resize(n)
	for i in n:
		var p := ParticulaAoS.new()
		p.pos_x = rng.randf_range(-500.0, 500.0)
		p.pos_y = rng.randf_range(-500.0, 500.0)
		p.vel_x = rng.randf_range(-60.0, 60.0)
		p.vel_y = rng.randf_range(-60.0, 60.0)
		p.vida = rng.randf_range(1.0, 8.0)
		p.color = Color(rng.randf(), rng.randf(), rng.randf())
		p.tipo = rng.randi() % 4
		out[i] = p
	return out


func avanzar(delta: float) -> void:
	## Recorridos secuenciales sobre memoria contigua, y SIN ramas dentro del
	## bucle: las vivas están en [0, vivas).
	for i in vivas:
		pos_x[i] += vel_x[i] * delta
		pos_y[i] += vel_y[i] * delta
		vida[i] -= delta


static func avanzar_aos(datos: Array, delta: float) -> void:
	for p in datos:
		p.pos_x += p.vel_x * delta
		p.pos_y += p.vel_y * delta
		p.vida -= delta


func compactar() -> int:
	## Al morir una, se intercambia con la última viva: O(1) por elemento y sin
	## huecos, lo que mantiene el bucle caliente sin ramas.
	var i := 0
	var muertas := 0
	while i < vivas:
		if vida[i] <= 0.0:
			vivas -= 1
			muertas += 1
			_intercambiar(i, vivas)
		else:
			i += 1
	return muertas


func total_vidas() -> float:
	var t := 0.0
	for i in vivas:
		t += vida[i]
	return t


func equivalente_a(aos: Array, tolerancia: float = 0.001) -> bool:
	## Corrección ANTES que velocidad: una versión 8 veces más rápida que da
	## otro resultado no es una optimización, es un bug rápido.
	if aos.size() != pos_x.size():
		return false
	for i in aos.size():
		if absf(aos[i].pos_x - pos_x[i]) > tolerancia:
			return false
		if absf(aos[i].pos_y - pos_y[i]) > tolerancia:
			return false
		if absf(aos[i].vida - vida[i]) > tolerancia:
			return false
	return true


func _intercambiar(a: int, b: int) -> void:
	var t: float
	t = pos_x[a]; pos_x[a] = pos_x[b]; pos_x[b] = t
	t = pos_y[a]; pos_y[a] = pos_y[b]; pos_y[b] = t
	t = vel_x[a]; vel_x[a] = vel_x[b]; vel_x[b] = t
	t = vel_y[a]; vel_y[a] = vel_y[b]; vel_y[b] = t
	t = vida[a]; vida[a] = vida[b]; vida[b] = t
	var c := color[a]; color[a] = color[b]; color[b] = c
	var ti := tipo[a]; tipo[a] = tipo[b]; tipo[b] = ti
