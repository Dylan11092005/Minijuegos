extends Node2D

@onready var btn_back = $CanvasLayer/BtnBack
@onready var house_container = $HouseContainer

# ── Sonidos ──────────────────────────────────────────────
@onready var audio_fondo     = $BackgroundSound
@onready var audio_tornillo  = $ScrewSound
@onready var audio_caida     = $FallSound

const SCREW_SCENE = preload("res://Minigames/minigame_house/Screw.tscn")
const PIECE_SCENE = preload("res://Minigames/minigame_house/Piece.tscn")
const TIMER_HUD_SCENE = preload("res://Minigames/ui_global/TimerUi.tscn")
const PANEL_RESULTADO_SCENE = preload("res://Minigames/ui_global/GameResult.tscn")

const GLOBAL_SOUND_VOLUME := -10.0

var TOTAL_TIME: float = 45.0
var total_pieces: int = 0
var detached_pieces: int = 0
var game_active: bool = false
var total_screws: int = 0
var removed_screws: int = 0

var timer_hud: CanvasLayer
var panel_resultado: CanvasLayer

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null

var house_data = [
	{
		"id": "wall_main",
		"texture": "res://Minigames/minigame_house/assets/wall_main.png",
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
		"texture": "res://Minigames/minigame_house/assets/wall_windows.png",
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
		"texture": "res://Minigames/minigame_house/assets/roof.png",
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
		"texture": "res://Minigames/minigame_house/assets/door.png",
		"position": Vector2(-90, 170),
		"piece_scale": Vector2(3.3, 3.3),
		"screws": [
			{"offset": Vector2(0, 0), "color": "red"},
		]
	},
	{
		"id": "fence_left",
		"texture": "res://Minigames/minigame_house/assets/fence.png",
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
		"texture": "res://Minigames/minigame_house/assets/fence.png",
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
		"texture": "res://Minigames/minigame_house/assets/magnet_latch.png",
		"position": Vector2(-90, 390),
		"piece_scale": Vector2(2.3, 2.3),
		"screws": [
			{"offset": Vector2(45, 20), "color": "orange"},
			{"offset": Vector2(-45, 20), "color": "orange"},
		]
	},
	{
		"id": "windows_frame_1",
		"texture": "res://Minigames/minigame_house/assets/windows_frame.png",
		"position": Vector2(-145, -360),
		"piece_scale": Vector2(2.3, 2.3),
		"screws": [
			{"offset": Vector2(-5, 3), "color": "purple"},
		]
	},
	{
		"id": "windows_frame_2",
		"texture": "res://Minigames/minigame_house/assets/windows_frame.png",
		"position": Vector2(155, -360),
		"piece_scale": Vector2(2.3, 2.3),
		"screws": [
			{"offset": Vector2(0, 3), "color": "red"},
		]
	},
	{
		"id": "windows_frame_3",
		"texture": "res://Minigames/minigame_house/assets/windows_frame.png",
		"position": Vector2(178, 100),
		"piece_scale": Vector2(2.1, 2.8),
		"screws": [
			{"offset": Vector2(0, 0), "color": "red"},
		]
	},
]

var screw_textures = {
	"red":    "res://Minigames/minigame_house/screws/screw_red.png",
	"green":  "res://Minigames/minigame_house/screws/screw_green.png",
	"yellow": "res://Minigames/minigame_house/screws/screw_yellow.png",
	"orange": "res://Minigames/minigame_house/screws/screw_orange.png",
	"purple": "res://Minigames/minigame_house/screws/screw_purple.png",
}


func _ready():
	_init_game()


func _init_game():
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)
	timer_hud.time_up.connect(_on_tiempo_agotado)
	timer_hud.set_tamano_panel(500, 60)

	panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(panel_resultado)

	_setup_damage_effect()
	_setup_sound_volumes()

	btn_back.pressed.connect(_on_back_pressed)

	house_container.scale = Vector2(0.75, 0.75)
	house_container.position = Vector2(1000, 700)

	_build_house()
	_start_game()


# =========================================================
# SONIDOS
# =========================================================

func _setup_sound_volumes() -> void:
	if audio_fondo and audio_fondo is AudioStreamPlayer:
		audio_fondo.volume_db = GLOBAL_SOUND_VOLUME

	if audio_tornillo and audio_tornillo is AudioStreamPlayer:
		audio_tornillo.volume_db = GLOBAL_SOUND_VOLUME

	if audio_caida and audio_caida is AudioStreamPlayer:
		audio_caida.volume_db = GLOBAL_SOUND_VOLUME

	_set_game_result_sound_volume()


func _set_game_result_sound_volume() -> void:
	if panel_resultado == null:
		return

	var result_sounds := [
		"WinSound",
		"win_sound",
		"AudioWin",
		"WinAudio",
		"LoseSound",
		"lose_sound",
		"AudioLose",
		"LoseAudio"
	]

	for sound_name in result_sounds:
		var sound = panel_resultado.find_child(sound_name, true, false)

		if sound and sound is AudioStreamPlayer:
			sound.volume_db = GLOBAL_SOUND_VOLUME
			sound.process_mode = Node.PROCESS_MODE_ALWAYS


func _play_sound(sound: AudioStreamPlayer) -> void:
	if sound == null:
		return

	if sound.stream == null:
		return

	sound.volume_db = GLOBAL_SOUND_VOLUME
	sound.stop()
	sound.play()


# =========================================================
# DAMAGE EFFECT
# =========================================================

func _setup_damage_effect():
	damage_layer = CanvasLayer.new()
	damage_layer.name = "DamageLayer"
	damage_layer.layer = 200
	add_child(damage_layer)
	
	damage_rect = ColorRect.new()
	damage_rect.name = "DamageRect"
	damage_rect.color = Color(1, 0, 0)
	damage_rect.modulate.a = 0.0
	damage_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	damage_layer.add_child(damage_rect)


func _play_damage_effect():
	if not damage_rect:
		return
	
	var original_position: Vector2 = position
	
	var flash_tween := create_tween()
	damage_rect.modulate.a = 0.0
	flash_tween.tween_property(damage_rect, "modulate:a", 0.35, 0.08)
	flash_tween.tween_property(damage_rect, "modulate:a", 0.0, 0.22)
	
	var shake_tween := create_tween()
	
	for i in range(6):
		var offset := Vector2(
			randf_range(-8.0, 8.0),
			randf_range(-8.0, 8.0)
		)
		
		shake_tween.tween_property(self, "position", original_position + offset, 0.03)
	
	shake_tween.tween_property(self, "position", original_position, 0.05)


# =========================================================
# TIME BONUS POR EDAD
# =========================================================

func _get_time_bonus(age: int) -> float:
	match age:
		11:
			return 5.0
		10:
			return 5.0
		9:
			return 7.0
		8:
			return 10.0
		7:
			return 15.0
		_:
			return 15.0 if age < 7 else 0.0


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
	game_active = true

	if audio_fondo:
		audio_fondo.volume_db = GLOBAL_SOUND_VOLUME
		audio_fondo.play()

	var player_age: int = MinigameData.player_age

	if player_age < 12:
		TOTAL_TIME = 45.0 + _get_time_bonus(player_age)
	else:
		TOTAL_TIME = 45.0

	timer_hud.iniciar(TOTAL_TIME, "Tiempo restante", "para la erupción")


func _process(_delta):
	pass


func _on_screw_clicked(_screw):
	if not game_active:
		return

	_play_sound(audio_tornillo)

	removed_screws += 1

	if removed_screws >= total_screws:
		_win()


func on_piece_detached(_piece: RigidBody2D):
	detached_pieces += 1
	_play_sound(audio_caida)


func _on_tiempo_agotado():
	if game_active:
		_lose()


func _win():
	game_active = false

	if audio_fondo:
		audio_fondo.stop()

	timer_hud.detener()
	_set_game_result_sound_volume()
	panel_resultado.mostrar_ganaste()


func _lose():
	game_active = false

	if audio_fondo:
		audio_fondo.stop()

	timer_hud.detener()
	_set_game_result_sound_volume()
	_play_damage_effect()
	panel_resultado.mostrar_perdiste()


func _on_back_pressed():
	if audio_fondo:
		audio_fondo.stop()

	get_tree().change_scene_to_file("res://Main.tscn")
