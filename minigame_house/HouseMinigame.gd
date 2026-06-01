extends Node2D

@onready var timer_label = $CanvasLayer/TimerLabel
@onready var status_label = $CanvasLayer/StatusLabel
@onready var game_timer = $GameTimer
@onready var result_panel = $CanvasLayer/ResultPanel
@onready var result_label = $CanvasLayer/ResultPanel/ResultLabel
@onready var btn_back = $CanvasLayer/BtnBack
@onready var btn_restart = $CanvasLayer/ResultPanel/BtnRestart
@onready var house_container = $HouseContainer

const SCREW_SCENE = preload("res://minigame_house/Screw.tscn")
const PIECE_SCENE = preload("res://minigame_house/Piece.tscn")

const TOTAL_TIME = 60.0
var time_remaining: float = TOTAL_TIME
var total_pieces: int = 0
var detached_pieces: int = 0
var game_active: bool = false

var total_screws: int = 0
var removed_screws: int = 0

var house_data = [
	{
		"id": "wall_main",
		"texture": "res://minigame_house/assets/wall_main.png",
		"position": Vector2(0, 120),
		"piece_scale": Vector2(1.3, 1.3),
		"screws": [
			{"offset": Vector2(-215, -170), "color": "orange"},
			{"offset": Vector2(10, -170),    "color": "orange"},
			{"offset": Vector2(230, -170),  "color": "purple"},
			{"offset": Vector2(-215, 0),  "color": "green"},
			{"offset": Vector2(40, 0),   "color": "green"},
			{"offset": Vector2(230, 0),   "color": "purple"},
		]
	},
	{
		"id": "wall_windows",
		"texture": "res://minigame_house/assets/wall_windows.png",
		"position": Vector2(5, -395),
		"piece_scale": Vector2(3.2, 3.2),
		"screws": [
			{"offset": Vector2(-90, -5), "color": "purple"},
			{"offset": Vector2(90, -5),  "color": "orange"},
			{"offset": Vector2(-90, 60),  "color": "green"},
			{"offset": Vector2(90, 60),   "color": "green"},
			{"offset": Vector2(0, 60),  "color": "red"},
			{"offset": Vector2(0, -65),  "color": "red"},
		]
	},
	{
		"id": "roof",
		"texture": "res://minigame_house/assets/roof.png",
		"position": Vector2(5, -620),
		"piece_scale": Vector2(3.5, 3.5),
		"screws": [
			{"offset": Vector2(-2, -20), "color": "purple"},
			{"offset": Vector2(-45, 10), "color": "orange"},
			{"offset": Vector2(41, 10), "color": "green"},
			{"offset": Vector2(80, 35), "color": "green"},
			{"offset": Vector2(-80, 35), "color": "red"},
			{"offset": Vector2(-60, -20), "color": "purple"},
		]
	},
	{
		"id": "door",
		"texture": "res://minigame_house/assets/door.png",
		"position": Vector2(-90, 170),
		"piece_scale": Vector2(3.3, 3.3),
		"screws": [
			{"offset": Vector2(0, 0), "color": "red"},
		]
	},
	{
		"id": "fence_left",
		"texture": "res://minigame_house/assets/fence.png",
		"position": Vector2(-370, 290),
		"piece_scale": Vector2(2.0, 2.0),
		"screws": [
			{"offset": Vector2(37, -20), "color": "red"},
			{"offset": Vector2(37, 20), "color": "purple"},
			{"offset": Vector2(-27, -20), "color": "red"},
			{"offset": Vector2(-27, 20), "color": "green"},
		]
	},
	{
		"id": "fence_right",
		"texture": "res://minigame_house/assets/fence.png",
		"position": Vector2(370, 290),
		"piece_scale": Vector2(2.0, 2.0),
		"screws": [
			{"offset": Vector2(-27, -20), "color": "red"},
			{"offset": Vector2(35, 20), "color": "purple"},
			{"offset": Vector2(35, -20), "color": "orange"},
			{"offset": Vector2(-27, 20), "color": "green"},
		]
	},
	{
		"id": "magnet_lantch",
		"texture": "res://minigame_house/assets/magnet_latch.png",
		"position": Vector2(-90, 390),
		"piece_scale": Vector2(2.3, 2.3),
		"screws": [
			{"offset": Vector2(45, 20), "color": "orange"},
			{"offset": Vector2(-45, 20), "color": "orange"},
		]
	},
	{
		"id": "windows_frame_1",
		"texture": "res://minigame_house/assets/windows_frame.png",
		"position": Vector2(-145, -360),
		"piece_scale": Vector2(2.3, 2.3),
		"screws": [
			{"offset": Vector2(-5, 3), "color": "purple"},
		]
	},
	{
		"id": "windows_frame_2",
		"texture": "res://minigame_house/assets/windows_frame.png",
		"position": Vector2(155, -360),
		"piece_scale": Vector2(2.3, 2.3),
		"screws": [
			{"offset": Vector2(0, 3), "color": "red"},
		]
	},
	{
		"id": "windows_frame_3",
		"texture": "res://minigame_house/assets/windows_frame.png",
		"position": Vector2(178, 100),
		"piece_scale": Vector2(2.1, 2.8),
		"screws": [
			{"offset": Vector2(0, 0), "color": "red"},
		]
	},
]

var screw_textures = {
	"red":    "res://minigame_house/screws/screw_red.png",
	"green":  "res://minigame_house/screws/screw_green.png",
	"yellow": "res://minigame_house/screws/screw_yellow.png",
	"orange": "res://minigame_house/screws/screw_orange.png",
	"purple": "res://minigame_house/screws/screw_purple.png",
}

func _ready():
	result_panel.hide()
	btn_back.pressed.connect(_on_back_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	game_timer.timeout.connect(_on_timer_timeout)
	house_container.scale = Vector2(0.75, 0.75)
	house_container.position = Vector2(1000, 700)
	_build_house()
	_start_game()

func _build_house():
	total_pieces = house_data.size()
	detached_pieces = 0
	total_screws = 0
	removed_screws = 0

	for data in house_data:
		var piece: RigidBody2D = PIECE_SCENE.instantiate()
		piece.position = data["position"]
		piece.scale = data.get("piece_scale", Vector2(1.0, 1.0))
		piece.name = data["id"]

		var sprite: Sprite2D = piece.get_node("Sprite2D")
		sprite.texture = load(data["texture"])

		house_container.add_child(piece)

		var parent_scale = piece.scale.x

		for screw_data in data["screws"]:
			var screw = SCREW_SCENE.instantiate()
			screw.position = screw_data["offset"]
			screw.parent_piece = piece
			screw.scale = Vector2(0.37 / parent_scale, 0.37 / parent_scale)

			var color = screw_data.get("color", "green")
			if screw_textures.has(color):
				screw.get_node("Sprite2D").texture = load(screw_textures[color])

			screw.screw_clicked.connect(_on_screw_clicked)
			piece.add_child(screw)
			piece.add_screw()
			total_screws += 1

func _start_game():
	time_remaining = TOTAL_TIME
	game_active = true
	game_timer.start(TOTAL_TIME)

func _process(_delta):
	if not game_active:
		return
	time_remaining -= _delta
	time_remaining = max(time_remaining, 0.0)
	timer_label.text = "Tiempo restante para la erupción: %d" % int(ceil(time_remaining))
 
func _on_screw_clicked(_screw):
	if not game_active:
		return
	removed_screws += 1
	if removed_screws >= total_screws:
		_win()

func on_piece_detached(_piece: RigidBody2D):
	detached_pieces += 1

func _on_timer_timeout():
	if removed_screws < total_screws:
		_lose()

func _show_result():
	var canvas = $CanvasLayer
	canvas.move_child(result_panel, canvas.get_child_count() - 1)
	
	result_panel.custom_minimum_size = Vector2(500, 250)
	result_panel.size = Vector2(500, 250)
	
	# Centrar usando el tamaño real de pantalla
	var screen_size = get_viewport().get_visible_rect().size
	result_panel.position = Vector2(
		screen_size.x / 2 - 250,
		screen_size.y / 2 - 125
	)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	result_panel.add_theme_stylebox_override("panel", style)
	
	result_panel.show()

func _win():
	game_active = false
	game_timer.stop()
	result_label.text = "   🎉 ¡Ganaste!\n   Desarmaste la casa"
	_show_result()

func _lose():
	game_active = false
	result_label.text = "  ⏰ ¡Se acabó el tiempo!\n   Inténtalo de nuevo"
	_show_result()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_restart_pressed():
	get_tree().reload_current_scene()
