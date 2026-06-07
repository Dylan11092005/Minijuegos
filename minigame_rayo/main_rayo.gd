extends Node2D

const TIMER_HUD_SCENE       = preload("res://ui_global/timer_ui.tscn")
const PANEL_RESULTADO_SCENE = preload("res://ui_global/ResultadoJuego.tscn")

const TOTAL_TIME = 15.0

@export var rayo_scene: PackedScene

var juego_terminado := false
var mensaje_actual  := ""

@onready var player       = $PlayerRayo
@onready var timer_spawn  = $TimerSpawnRayos

var timer_hud:       CanvasLayer
var panel_resultado: CanvasLayer

# =========================================================
# READY
# =========================================================
func _ready():
	randomize()

	juego_terminado = false
	mensaje_actual  = ""

	if player:
		player.vidas = 3

	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)
	timer_hud.tiempo_agotado.connect(_on_tiempo_agotado)
	timer_hud.set_tamano_panel(500, 60)

	panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(panel_resultado)

	timer_hud.iniciar(TOTAL_TIME, "Tiempo restante", "para sobrevivir")

# =========================================================
# PROCESS
# =========================================================
func _process(_delta):
	if player.vidas <= 0 and not juego_terminado:
		perder()

# =========================================================
# SPAWN RAYOS
# =========================================================
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

# =========================================================
# CALLBACK TIMER AGOTADO
# =========================================================
func _on_tiempo_agotado():
	if not juego_terminado:
		ganar()

# =========================================================
# GANAR / PERDER
# =========================================================
func ganar():
	juego_terminado = true
	timer_spawn.stop()
	timer_hud.detener()
	panel_resultado.mostrar_ganaste()

func perder():
	juego_terminado = true
	timer_spawn.stop()
	timer_hud.detener()
	panel_resultado.mostrar_perdiste()
