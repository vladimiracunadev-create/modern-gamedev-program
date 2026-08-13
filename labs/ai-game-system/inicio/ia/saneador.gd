class_name Saneador
extends RefCounted

## Saneado de la entrada del jugador (clase 336).
##
## Todo lo que escribe una persona es ENTRADA NO CONFIABLE, igual que un
## parámetro de red. La diferencia es que aquí el "intérprete" es un modelo de
## lenguaje que no distingue instrucciones de datos.

const MAX_LONGITUD := 300

## Patrones característicos de intento de redirección. NO son una defensa
## suficiente por sí solos: son un filtro barato y, sobre todo, una SEÑAL para
## la telemetría de abuso. Por eso marcan, no bloquean.
const PATRONES := [
	"(?i)ignora (las |tus )?(instrucciones|reglas|indicaciones)",
	"(?i)olvida (todo|las instrucciones|lo anterior)",
	"(?i)(eres|actua como|compórtate como) (un|una) (asistente|ia|chatbot|modelo)",
	"(?i)(system|sistema)\\s*:",
	"(?i)(muestra|repite|dime) (tu |el )?(prompt|instrucciones|system)",
	"(?i)modo (desarrollador|dios|debug|sin (filtros|restricciones))",
]


class Resultado extends RefCounted:
	var texto: String = ""
	var sospechoso: bool = false
	var patrones: Array = []
	var recortado: bool = false


static func sanear(entrada: String) -> Resultado:
	var r := Resultado.new()
	var t := entrada.strip_edges()

	# 1) Acotar: impide el ataque por volumen y controla el coste.
	if t.length() > MAX_LONGITUD:
		t = t.substr(0, MAX_LONGITUD)
		r.recortado = true

	# 2) Normalizar: un texto con 40 saltos de línea puede intentar "separar"
	#    secciones del prompt.
	t = t.replace("\r", " ").replace("\t", " ")
	while t.contains("\n\n"):
		t = t.replace("\n\n", "\n")
	t = t.replace("\n", " ")

	# 3) Neutralizar delimitadores que podrían imitar los nuestros.
	t = t.replace("<<<", "«").replace(">>>", "»")

	# 4) Marcar, no bloquear: "olvida lo que te dije antes" es una frase
	#    normal, y bloquearla sería un falso positivo constante.
	for p in PATRONES:
		var re := RegEx.create_from_string(p)
		if re != null and re.search(t) != null:
			r.sospechoso = true
			r.patrones.append(p)

	r.texto = t
	return r


static func revisar_privacidad(contexto: String, datos_jugador: Dictionary) -> Array:
	## Lo que se pone en el prompt SALE del dispositivo. Un dato personal ahí
	## no tiene vuelta atrás (clase 317).
	var problemas: Array = []
	for clave in ["nombre_real", "email", "ip", "player_id", "ubicacion"]:
		var valor := str(datos_jugador.get(clave, ""))
		if valor.length() > 3 and contexto.contains(valor):
			problemas.append("el contexto contiene '%s' del jugador" % clave)
	for patron in ["[\\w.]+@[\\w.]+\\.\\w+", "\\b\\d{1,3}(\\.\\d{1,3}){3}\\b",
			"[A-Za-z]:\\\\Users\\\\[^\\\\]+"]:
		var re := RegEx.create_from_string(patron)
		if re != null and re.search(contexto) != null:
			problemas.append("el contexto contiene un patrón de dato personal")
	return problemas
