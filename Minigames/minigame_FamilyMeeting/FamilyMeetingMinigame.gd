extends Node2D

@onready var game_result := $GameResult
@onready var timer_ui := $TimerUI
@onready var player := $Player
@onready var music_player := $MusicPlayer
@onready var correct_player := $CorrectPlayer

@onready var father := $FamilyMembers/Father
@onready var father_sprite := $FamilyMembers/Father/Sprite2D
@onready var father_icon := $FamilyPanel/FatherIcon
@onready var father_follower := $Player/FatherFollower

@onready var mother := $FamilyMembers/Mother
@onready var mother_sprite := $FamilyMembers/Mother/Sprite2D
@onready var mother_icon := $FamilyPanel/MotherIcon
@onready var mother_follower := $Player/MotherFollower

@onready var son := $FamilyMembers/Son
@onready var son_sprite := $FamilyMembers/Son/Sprite2D
@onready var son_icon := $FamilyPanel/SonIcon
@onready var son_follower := $Player/SonFollower

@onready var daughter := $FamilyMembers/Daughter
@onready var daughter_sprite := $FamilyMembers/Daughter/Sprite2D
@onready var daughter_icon := $FamilyPanel/DaughterIcon
@onready var daughter_follower := $Player/DaughterFollower

const TOTAL_FAMILY := 4
var TOTAL_TIME: float = 35.0
var rescued_count := 0
var game_finished := false

var father_rescued := false
var mother_rescued := false
var son_rescued := false
var daughter_rescued := false

var father_happy_texture := preload("res://Minigames/minigame_FamilyMeeting/assets/objects/Father_Happy.png")
var mother_happy_texture := preload("res://Minigames/minigame_FamilyMeeting/assets/objects/Mother_Happy.png")
var son_happy_texture := preload("res://Minigames/minigame_FamilyMeeting/assets/objects/Son_Happy.png")
var daughter_happy_texture := preload("res://Minigames/minigame_FamilyMeeting/assets/objects/Daughter_Happy.png")

func _ready() -> void:
	var player_age: int = MinigameData.player_age

	if player_age < 12:
		TOTAL_TIME = 35.0 + _get_time_bonus(player_age)
	else:
		TOTAL_TIME = 35.0

	timer_ui.iniciar(TOTAL_TIME, "Reúne a todos en", "segundos")
	timer_ui.time_up.connect(_on_timer_ui_time_up)
	music_player.play()



	father_icon.modulate = Color(0.25, 0.25, 0.25, 1)
	mother_icon.modulate = Color(0.25, 0.25, 0.25, 1)
	son_icon.modulate = Color(0.25, 0.25, 0.25, 1)
	daughter_icon.modulate = Color(0.25, 0.25, 0.25, 1)

	father_follower.visible = false
	mother_follower.visible = false
	son_follower.visible = false
	daughter_follower.visible = false

func _rescue_family_member(
	member: Node2D,
	member_sprite: Sprite2D,
	member_icon: Sprite2D,
	follower: Sprite2D,
	happy_texture: Texture2D,
	member_name: String
) -> void:
	member_sprite.texture = happy_texture
	member_icon.modulate = Color(1, 1, 1, 1)
	member.visible = false
	follower.visible = true
	correct_player.play()
	rescued_count += 1
	print(member_name + " rescatado")

func _on_father_body_entered(body: Node2D) -> void:
	if father_rescued:
		return

	if body.name == "Player":
		father_rescued = true
		_rescue_family_member(father, father_sprite, father_icon, father_follower, father_happy_texture, "Papá")

func _on_mother_body_entered(body: Node2D) -> void:
	if mother_rescued:
		return

	if body.name == "Player":
		mother_rescued = true
		_rescue_family_member(mother, mother_sprite, mother_icon, mother_follower, mother_happy_texture, "Mamá")

func _on_son_body_entered(body: Node2D) -> void:
	if son_rescued:
		return

	if body.name == "Player":
		son_rescued = true
		_rescue_family_member(son, son_sprite, son_icon, son_follower, son_happy_texture, "Hijo")

func _on_daughter_body_entered(body: Node2D) -> void:
	if daughter_rescued:
		return

	if body.name == "Player":
		daughter_rescued = true
		_rescue_family_member(daughter, daughter_sprite, daughter_icon, daughter_follower, daughter_happy_texture, "Hija")

func _on_safe_zone_body_entered(body: Node2D) -> void:
	if game_finished:
		return

	if body.name == "Player" and rescued_count >= TOTAL_FAMILY:
		game_finished = true
		timer_ui.detener()
		music_player.stop()
		player.bloquear_movimiento()
		game_result.show_win()

func _on_timer_ui_time_up() -> void:
	if game_finished:
		return

	game_finished = true
	music_player.stop()
	player.bloquear_movimiento()
	game_result.show_lose()

# =========================================================
# TIME BONUS POR EDAD
# =========================================================
func _get_time_bonus(age: int) -> float:
	match age:
		11:
			return 2.0
		10:
			return 3.0
		9:
			return 5.0
		8:
			return 7.0
		7:
			return 10.0
		_:
			return 10.0 if age < 7 else 0.0
