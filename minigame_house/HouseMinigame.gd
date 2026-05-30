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

const TOTAL_TIME = 40.0
var time_remaining: float = TOTAL_TIME
var total_pieces: int = 0
var detached_pieces: int = 0
var game_active: bool = false

# wall_main: 557x448 <- base
# wall_windows: 215x177 -> escalar x2.59 para igualar ancho
# roof: 224x157 -> escalar x2.48 para igualar ancho
# door: 69x118
# fence: 120x100

var house_data = [
	{
		"id": "wall_main",
		"texture": "res://minigame_house/assets/wall_main.png",
		"position": Vector2(0, 0),
		"piece_scale": Vector2(1.0, 1.0),
		"screws": [
			{"offset": Vector2(-220, -180), "color": "orange"},
			{"offset": Vector2(0, -180),    "color": "orange"},
			{"offset": Vector2(220, -180),  "color": "orange"},
			{"offset": Vector2(-220, 180),  "color": "green"},
			{"offset": Vector2(220, 180),   "color": "green"},
		]
	},
	{
		"id": "wall_windows",
		"texture": "res://minigame_house/assets/wall_windows.png",
		"position": Vector2(0, -312),
		"piece_scale": Vector2(2.59, 2.59),
		"screws": [
			{"offset": Vector2(-90, -70), "color": "purple"},
			{"offset": Vector2(90, -70),  "color": "purple"},
			{"offset": Vector2(-90, 70),  "color": "green"},
			{"offset": Vector2(90, 70),   "color": "green"},
		]
	},
	{
		"id": "roof",
		"texture": "res://minigame_house/assets/roof.png",
		"position": Vector2(0, -540),
		"piece_scale": Vector2(2.48, 2.48),
		"screws": [
			{"offset": Vector2(-90, -30), "color": "orange"},
			{"offset": Vector2(0, -60),   "color": "orange"},
			{"offset": Vector2(90, -30),  "color": "orange"},
			{"offset": Vector2(-60, 50),  "color": "green"},
			{"offset": Vector2(60, 50),   "color": "green"},
		]
	},
	{
		"id": "door",
		"texture": "res://minigame_house/assets/door.png",
		"position": Vector2(-120, 100),
		"piece_scale": Vector2(1.5, 1.5),
		"screws": [
			{"offset": Vector2(0, -50), "color": "orange"},
			{"offset": Vector2(0, 50),  "color": "orange"},
		]
	},
	{
		"id": "fence_left",
		"texture": "res://minigame_house/assets/fence.png",
		"position": Vector2(-338, 200),
		"piece_scale": Vector2(1.0, 1.0),
		"screws": [
			{"offset": Vector2(-40, 0), "color": "purple"},
			{"offset": Vector2(40, 0),  "color": "green"},
		]
	},
	{
		"id": "fence_right",
		"texture": "res://minigame_house/assets/fence.png",
		"position": Vector2(338, 200),
		"piece_scale": Vector2(1.0, 1.0),
		"screws": [
			{"offset": Vector2(-40, 0), "color": "purple"},
			{"offset": Vector2(40, 0),  "color": "green"},
		]
	},
]

var screw_textures = {
	"red":    "res://minigame_house/screws/screw_orange.png",
	"green":  "res://minigame_house/screws/screw_green.png",
	"yellow": "res://minigame_house/screws/screw_orange.png",
	"orange": "res://minigame_house/screws/screw_orange.png",
	"purple": "res://minigame_house/screws/screw_purple.png",
	"pink":   "res://minigame_house/screws/screw_purple.png",
	"blue":   "res://minigame_house/screws/screw_green.png",
}

func _ready():
	result_panel.hide()
	btn_back.pressed.connect(_on_back_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	game_timer.timeout.connect(_on_timer_timeout)
	house_container.scale = Vector2(0.75, 0.75)
	house_container.position = Vector2(576, 590)
	_build_house()
	_start_game()

func _build_house():
	total_pieces = house_data.size()
	detached_pieces = 0

	for data in house_data:
		var piece: RigidBody2D = PIECE_SCENE.instantiate()
		piece.position = data["position"]
		piece.scale = data.get("piece_scale", Vector2(1.0, 1.0))
		piece.name = data["id"]

		var sprite: Sprite2D = piece.get_node("Sprite2D")
		sprite.texture = load(data["texture"])

		house_container.add_child(piece)

		for screw_data in data["screws"]:
			var screw = SCREW_SCENE.instantiate()
			screw.position = screw_data["offset"]
			screw.parent_piece = piece
			screw.scale = Vector2(0.3, 0.3)

			var color = screw_data.get("color", "green")
			if screw_textures.has(color):
				screw.get_node("Sprite2D").texture = load(screw_textures[color])

			screw.screw_clicked.connect(_on_screw_clicked)
			piece.add_child(screw)
			piece.add_screw()

func _start_game():
	time_remaining = TOTAL_TIME
	game_active = true
	game_timer.start(TOTAL_TIME)

func _process(_delta):
	if not game_active:
		return
	time_remaining -= _delta
	time_remaining = max(time_remaining, 0.0)
	timer_label.text = "Tiempo: %d" % int(ceil(time_remaining))

func _on_screw_clicked(_screw):
	if not game_active:
		return

func on_piece_detached(_piece: RigidBody2D):
	detached_pieces += 1
	if detached_pieces >= total_pieces:
		_win()

func _on_timer_timeout():
	if detached_pieces < total_pieces:
		_lose()

func _win():
	game_active = false
	game_timer.stop()
	result_label.text = "🎉 ¡Ganaste!\nDesarmaste la casa"
	result_panel.show()

func _lose():
	game_active = false
	result_label.text = "⏰ ¡Se acabó el tiempo!\nInténtalo de nuevo"
	result_panel.show()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_restart_pressed():
	get_tree().reload_current_scene()
