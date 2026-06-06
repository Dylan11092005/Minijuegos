extends Node2D

@export var rayo_scene: PackedScene

var tiempo := 15
var juego_terminado := false
var mensaje_actual := ""

@onready var player = $PlayerRayo
@onready var timer_spawn = $TimerSpawnRayos
@onready var timer_tormenta = $TimerTormenta
@onready var hud = $UI/HUD
@onready var resultado_juego = $ResultadoJuego


func _ready():
	randomize()
	
	tiempo = 15
	juego_terminado = false
	mensaje_actual = ""
	
	if player:
		player.vidas = 3
	
	actualizar_ui()


func _process(delta):
	actualizar_ui()

	if player.vidas <= 0 and juego_terminado == false:
		perder()


func actualizar_ui():
	if hud:
		hud.actualizar_hud(tiempo, player.vidas, mensaje_actual)


func _on_timer_spawn_rayos_timeout():
	if juego_terminado:
		return

	if rayo_scene == null:
		print("ERROR: No se asignó la escena Rayo.tscn en MainRayo.")
		return

	var ancho_pantalla := get_viewport_rect().size.x

	var rayo = rayo_scene.instantiate()
	rayo.position.x = randi_range(80, int(ancho_pantalla - 80))
	rayo.position.y = -80

	add_child(rayo)


func _on_timer_tormenta_timeout():
	if juego_terminado:
		return

	tiempo -= 1

	if tiempo <= 0:
		ganar()


func ganar():
	juego_terminado = true
	mensaje_actual = ""

	timer_spawn.stop()
	timer_tormenta.stop()

	actualizar_ui()
	resultado_juego.mostrar_ganaste()


func perder():
	juego_terminado = true
	mensaje_actual = ""

	timer_spawn.stop()
	timer_tormenta.stop()

	actualizar_ui()
	resultado_juego.mostrar_perdiste()
