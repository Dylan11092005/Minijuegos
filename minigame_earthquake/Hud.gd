extends CanvasLayer

# ─── Node references ──────────────────────────────────────────────────────────
@onready var earthquake_label: Label                 = $EarthquakeLabel
@onready var progress_bar:     TextureProgressBar    = $ProgressBar
@onready var hold_button:      TextureButton          = $HoldButton
@onready var lives_container:  HBoxContainer          = $LivesHBox
@onready var win_panel:        Control                = $WinPanel
@onready var gameover_panel:   Control                = $GameOverPanel

# ─── Ready ────────────────────────────────────────────────────────────────────
func _ready() -> void:
	earthquake_label.visible = false
	win_panel.visible = false
	gameover_panel.visible = false
	progress_bar.value = 0.0
	# Conectar eventos del botón
	hold_button.button_down.connect(_on_hold_button_down)
	hold_button.button_up.connect(_on_hold_button_up)

# ─── Earthquake label ─────────────────────────────────────────────────────────
func show_earthquake_label() -> void:
	earthquake_label.visible = true

func hide_earthquake_label() -> void:
	earthquake_label.visible = false

# ─── Lives ────────────────────────────────────────────────────────────────────
func update_lives(current_lives: int) -> void:
	# Muestra o esconde íconos de corazón según las vidas actuales
	for i in range(lives_container.get_child_count()):
		var heart = lives_container.get_child(i)
		heart.modulate.a = 1.0 if i < current_lives else 0.3

# ─── Progress bar ─────────────────────────────────────────────────────────────
func update_progress(value: float) -> void:
	# value entre 0.0 y 1.0
	progress_bar.value = value * 100.0

# ─── End screens ──────────────────────────────────────────────────────────────

# ─── Button events ────────────────────────────────────────────────────────────
func _on_hold_button_down() -> void:
	get_node("/root/Main/Player").on_hold_button_pressed()

func _on_hold_button_up() -> void:
	get_node("/root/Main/Player").on_hold_button_released()

# ─── Restart (conectar al botón de restart en WinPanel/GameOverPanel) ─────────
func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
