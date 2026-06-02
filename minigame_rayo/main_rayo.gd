extends Node2D

@export var rayo_scene: PackedScene

var tiempo := 30
var juego_terminado := false
var mensaje_actual := ""

@onready var player = $PlayerRayo
@onready var timer_spawn = $TimerSpawnRayos
@onready var timer_tormenta = $TimerTormenta
@onready var hud = $UI/HUD

func _ready():
	mensaje_actual = ""
	actualizar_ui()


func _process(delta):
	actualizar_ui()

	if player.vidas <= 0 and juego_terminado == false:
		perder()


func actualizar_ui():
	hud.actualizar_hud(tiempo, player.vidas, mensaje_actual)


func _on_timer_spawn_rayos_timeout():
	if juego_terminado:
		return

	var rayo = rayo_scene.instantiate()
	rayo.position.x = randi_range(80, 1200)
	rayo.position.y = -50
	add_child(rayo)


func _on_timer_tormenta_timeout():
	if juego_terminado:
		return

	tiempo -= 1

	if tiempo <= 0:
		ganar()


func ganar():
	juego_terminado = true
	mensaje_actual = "¡Ganaste!\nSobreviviste a la tormenta."
	timer_spawn.stop()
	timer_tormenta.stop()
	actualizar_ui()


func perder():
	juego_terminado = true
	mensaje_actual = "Perdiste.\nTe alcanzaron 3 rayos."
	timer_spawn.stop()
	timer_tormenta.stop()
	actualizar_ui()
