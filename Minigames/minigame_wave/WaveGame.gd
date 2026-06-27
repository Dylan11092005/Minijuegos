extends Node2D

@onready var boy = $CharacterBody2D/BoyAnimated
@onready var wave = $WaveAnimated
@onready var obstacles_node = $Obstacles

var score = 0
var score_timer = 0.0
var game_over = false
var speed = 300.0
var speed_increase = 20.0

var score_label: Label
var gameover_label: Label
var restart_button: Button

func _ready():
	_setup_ui()
	wave.play("wave")
	for obs in obstacles_node.get_children():
		obs.visible = false

func _setup_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	score_label = Label.new()
	score_label.position = Vector2(20, 20)
	score_label.add_theme_font_size_override("font_size", 32)
	canvas.add_child(score_label)
	
	gameover_label = Label.new()
	gameover_label.position = Vector2(400, 250)
	gameover_label.add_theme_font_size_override("font_size", 48)
	gameover_label.text = ""
	canvas.add_child(gameover_label)
	
	restart_button = Button.new()
	restart_button.text = "Reiniciar"
	restart_button.position = Vector2(450, 350)
	restart_button.visible = false
	restart_button.pressed.connect(_restart)
	canvas.add_child(restart_button)

func _process(delta):
	if game_over:
		return
	
	score_timer += delta
	if score_timer >= 0.5:
		score_timer = 0
		score += 1
		score_label.text = "Puntos: %d" % score
	
	speed = 300.0 + (score / 10) * speed_increase

func trigger_game_over():
	game_over = true
	boy.play("fail")
	boy.scale = Vector2(1.09, 1.072)  # ✅ Mismo scale que run y jump
	gameover_label.text = "¡GAME OVER!\nPuntos: %d" % score
	restart_button.visible = true

func _restart():
	get_tree().reload_current_scene()
