extends Node2D

const TIMER_HUD_SCENE       = preload("res://ui_global/TimerUi.tscn")
const PANEL_RESULTADO_SCENE = preload("res://ui_global/GameResult.tscn")

const TOTAL_TIME = 15.0

@export var rayo_scene: PackedScene

var juego_terminado := false
var mensaje_actual  := ""

@onready var player       = $PlayerRayo
@onready var timer_spawn  = $TimerSpawnRayos
@onready var hud_vidas    = $UI/HUD
@onready var fondo_tormenta = $FondoTormenta
@onready var audio_lluvia = $AudioLluvia
@onready var audio_rayo   = $AudioRayo

var timer_hud: CanvasLayer
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

	# Timer reutilizable
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)
	timer_hud.tiempo_agotado.connect(_on_tiempo_agotado)
	timer_hud.set_tamano_panel(500, 60)

	# Panel de ganar/perder
	panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(panel_resultado)

	timer_hud.iniciar(TOTAL_TIME, "Tiempo restante", "para sobrevivir")

	# Actualizar corazones al iniciar
	actualizar_hud_vidas()

	# Sonido de lluvia
	if audio_lluvia:
		audio_lluvia.volume_db = -12
		audio_lluvia.play()
		audio_lluvia.finished.connect(_on_audio_lluvia_finished)

	# Sonido de relámpago del fondo
	if fondo_tormenta:
		fondo_tormenta.relampago_aparecio.connect(_on_relampago_fondo)

	if audio_rayo:
		audio_rayo.volume_db = -3


# =========================================================
# PROCESS
# =========================================================
func _process(_delta):
	actualizar_hud_vidas()

	if player.vidas <= 0 and not juego_terminado:
		perder()


# =========================================================
# ACTUALIZAR CORAZONES
# =========================================================
func actualizar_hud_vidas():
	if hud_vidas and player:
		hud_vidas.actualizar_hud(0, player.vidas, "")


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
# AUDIO
# =========================================================
func _on_relampago_fondo():
	if juego_terminado:
		return

	if audio_rayo:
		audio_rayo.stop()
		audio_rayo.play()


func _on_audio_lluvia_finished():
	if not juego_terminado:
		audio_lluvia.play()


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

	if timer_hud:
		timer_hud.detener()

	if audio_lluvia:
		audio_lluvia.stop()

	if panel_resultado:
		panel_resultado.mostrar_ganaste()


func perder():
	juego_terminado = true

	timer_spawn.stop()

	if timer_hud:
		timer_hud.detener()

	if audio_lluvia:
		audio_lluvia.stop()

	if panel_resultado:
		panel_resultado.mostrar_perdiste()
