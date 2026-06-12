extends Node

signal earthquake_started
signal earthquake_ended

enum State { WAITING, EARTHQUAKE, WALKING, WIN }
var current_state: State = State.WAITING

@export var earthquake_interval_min: float = 3.0
@export var earthquake_interval_max: float = 7.0
@export var earthquake_duration:     float = 4.0

var earthquake_timer: float = 0.0
var next_earthquake_in: float = 0.0
var shake_timer: float = 0.0

@onready var hud:      CanvasLayer       = $Hud
@onready var eq_sound: AudioStreamPlayer = $AudioEQ

func _ready() -> void:
	_schedule_next_earthquake()
	hud.hide_earthquake_label()

func _process(delta: float) -> void:
	match current_state:
		State.WAITING:
			_process_waiting(delta)
		State.EARTHQUAKE:
			_process_earthquake(delta)

func _process_waiting(delta: float) -> void:
	earthquake_timer += delta
	if earthquake_timer >= next_earthquake_in:
		_start_earthquake()

func _process_earthquake(delta: float) -> void:
	shake_timer += delta
	if shake_timer >= earthquake_duration:
		_end_earthquake()

func _start_earthquake() -> void:
	current_state = State.EARTHQUAKE
	shake_timer = 0.0
	earthquake_timer = 0.0
	eq_sound.play()
	hud.show_earthquake_label()
	emit_signal("earthquake_started")

func _end_earthquake() -> void:
	eq_sound.stop()
	hud.hide_earthquake_label()
	emit_signal("earthquake_ended")
	current_state = State.WALKING

func _schedule_next_earthquake() -> void:
	earthquake_timer = 0.0
	next_earthquake_in = randf_range(earthquake_interval_min, earthquake_interval_max)

func on_player_reached_safe_zone() -> void:
	current_state = State.WIN
