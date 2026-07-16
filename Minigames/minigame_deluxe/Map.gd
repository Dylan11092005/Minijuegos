extends Node2D

var tramo_actual: PathFollow2D
var personaje: Node2D
var nodo_actual: int = 1  # empieza en el nivel 1

# Diccionario de conexiones: para cada nodo, qué dirección lleva a qué camino
# "invertido" = true significa que ese Way va del nodo MAYOR al MENOR
# (ej: Way1-2 va de 1->2, así que desde el nodo 2 hacia el 1 iría "invertido")
var conexiones = {
	1: {
		"derecha": {"path": "Background/Way1-2/PathFollow2D", "destino": 2, "invertido": false}
	},
	2: {
		"izquierda": {"path": "Background/Way1-2/PathFollow2D", "destino": 1, "invertido": true},
		"derecha": {"path": "Background/Way2-3/PathFollow2D", "destino": 3, "invertido": false}
		# aquí falta la conexión 2-5 si existe, según me confirmes Way2,5-4
	},
	3: {
		"izquierda": {"path": "Background/Way2-3/PathFollow2D", "destino": 2, "invertido": true},
		"abajo": {"path":"Background/Way3-4/PathFollow2D", "destino": 4, "invertido": false}
	},
	4: {
		"arriba": {"path": "Background/Way3-4/PathFollow2D", "destino": 3, "invertido": true},
		"izquierda": {"path": "Background/Way4 -5", "destino": 5, "invertido": false}
	},
	5: {
		"derecha": {"path": "Background/Way4 -5/PathFollow2D", "destino": 4, "invertido": true},
		"izquierda": {"path": "Background/Way5 -6/PathFollow2D", "destino": 6, "invertido": false}
		# aquí faltan las conexiones hacia 8 (volcán) según Way2,5-4 / Way2,5-5
	},
	6: {
		"derecha": {"path": "Background/Way5 -6/PathFollow2D", "destino": 5, "invertido": true},
		"abajo": {"path": "Background/Way6 -7/PathFollow2D", "destino": 7, "invertido": false}
	},
	7: {
		"arriba": {"path": "Background/Way6 -7/PathFollow2D", "destino": 6, "invertido": true},
		"derecha": {"path": "Background/Way7 -8/PathFollow2D", "destino": 8, "invertido": false}
	},
	8: {
		"izquierda": {"path": "Background/Way7 -8/PathFollow2D", "destino": 7, "invertido": true},
		"derecha": {"path": "Background/Way8 -9/PathFollow2D", "destino": 9, "invertido": false}
	},
	9: {
		"izquierda": {"path": "Background/Way8 -9/PathFollow2D", "destino": 8, "invertido": true},
		"derecha": {"path": "Background/Way9 -10/PathFollow2D", "destino": 10, "invertido": false}
	},
	10: {
		"izquierda": {"path": "Background/Way9 -10/PathFollow2D", "destino": 9, "invertido": true}
	}
}

func _ready():
	tramo_actual = $"Background/Way1-2/PathFollow2D"
	personaje = tramo_actual.get_node("Character")

func _input(event):
	var direccion = ""
	if event.is_action_pressed("ui_right"):
		direccion = "derecha"
	elif event.is_action_pressed("ui_left"):
		direccion = "izquierda"
	elif event.is_action_pressed("ui_up"):
		direccion = "arriba"
	elif event.is_action_pressed("ui_down"):
		direccion = "abajo"
	else:
		return

	if conexiones.has(nodo_actual) and conexiones[nodo_actual].has(direccion):
		var info = conexiones[nodo_actual][direccion]
		var destino_path = get_node(info["path"])
		mover_por_tramo(destino_path, info["invertido"])
		nodo_actual = info["destino"]

func mover_por_tramo(destino: PathFollow2D, invertido: bool = false, duracion: float = 1.0):
	personaje.reparent(destino)
	var inicio_ratio = 1.0 if invertido else 0.0
	var final_ratio = 0.0 if invertido else 1.0

	destino.progress_ratio = inicio_ratio
	tramo_actual = destino

	var tween = create_tween()
	tween.tween_property(destino, "progress_ratio", final_ratio, duracion)
