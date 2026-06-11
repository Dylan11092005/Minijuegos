extends Control

var minigame_data: Node

func _ready():
	minigame_data = get_node("/root/MinigameData")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_clear_scene()
	_build_scene()

func _clear_scene():
	for child in get_children():
		child.queue_free()

func _build_scene():
	var screen = get_viewport_rect().size

	# ── Sonido de instrucciones en bucle ───────────────────
	var audio = AudioStreamPlayer.new()
	audio.name = "AudioInstrucciones"
	audio.stream = load("res://ui_global/music/Sound_Instruction.mp3")
	audio.volume_db = -15.0
	add_child(audio)
	audio.call_deferred("play")
	audio.finished.connect(func(): audio.play())

	# ── Fondo ──────────────────────────────────────────────
	var bg = ColorRect.new()
	bg.color = Color("#30C0F0")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ── Título arriba al centro ────────────────────────────
	var panel_titulo = PanelContainer.new()
	panel_titulo.custom_minimum_size = Vector2(screen.x * 0.57, 73)
	panel_titulo.position = Vector2(screen.x / 2 - screen.x * 0.285, 10)
	_set_panel_color(panel_titulo, Color("#2B2B2B"))
	add_child(panel_titulo)

	var lbl_title = Label.new()
	lbl_title.text = minigame_data.title
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 58)
	lbl_title.add_theme_color_override("font_color", Color("#FFF020"))
	lbl_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_titulo.add_child(lbl_title)

	# ── HBox principal ─────────────────────────────────────
	var hbox = HBoxContainer.new()
	hbox.position = Vector2(40, 100)
	hbox.size = Vector2(screen.x - 80, screen.y - 200)
	hbox.add_theme_constant_override("separation", 25)
	add_child(hbox)

	# ── Video lado izquierdo ───────────────────────────────
	var vbox_video = VBoxContainer.new()
	vbox_video.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_video.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_video.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox_video)

	var panel_video = PanelContainer.new()
	panel_video.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel_video.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style_video = StyleBoxFlat.new()
	style_video.bg_color = Color("#2B2B2B")
	style_video.corner_radius_top_left     = 12
	style_video.corner_radius_top_right    = 12
	style_video.corner_radius_bottom_left  = 12
	style_video.corner_radius_bottom_right = 12
	style_video.content_margin_left   = 30
	style_video.content_margin_right  = 30
	style_video.content_margin_top    = 30
	style_video.content_margin_bottom = 30
	panel_video.add_theme_stylebox_override("panel", style_video)
	vbox_video.add_child(panel_video)

	var video = VideoStreamPlayer.new()
	video.custom_minimum_size = Vector2(screen.x * 0.46, screen.y * 0.58)
	video.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	video.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	video.expand = true
	video.volume_db = -80.0
	panel_video.add_child(video)

	if minigame_data.video_path != "":
		var stream = VideoStreamTheora.new()
		stream.file = minigame_data.video_path
		video.stream = stream
		video.play()
		video.finished.connect(func(): video.play())

	# ── VBox lado derecho ──────────────────────────────────
	var vbox_right = VBoxContainer.new()
	vbox_right.custom_minimum_size = Vector2(screen.x * 0.28, 0)
	vbox_right.size_flags_horizontal = Control.SIZE_SHRINK_END
	vbox_right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_right.add_theme_constant_override("separation", 18)
	hbox.add_child(vbox_right)

	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 60)
	vbox_right.add_child(spacer_top)

	# ── Panel controles ────────────────────────────────────
	var panel_controles = PanelContainer.new()
	panel_controles.size_flags_vertical = Control.SIZE_FILL
	panel_controles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_panel_color(panel_controles, Color("#2B2B2B"))
	vbox_right.add_child(panel_controles)

	var vbox_controles = VBoxContainer.new()
	vbox_controles.add_theme_constant_override("separation", 10)
	vbox_controles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_controles.add_child(vbox_controles)

	var lbl_controles_title = Label.new()
	lbl_controles_title.text = "Controles"
	lbl_controles_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_controles_title.add_theme_font_size_override("font_size", 36)
	lbl_controles_title.add_theme_color_override("font_color", Color("#F5F5F5"))
	lbl_controles_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox_controles.add_child(lbl_controles_title)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	vbox_controles.add_child(grid)

	for control in minigame_data.controls:
		var icon = TextureRect.new()
		icon.texture = load(control["icon"])
		icon.custom_minimum_size = Vector2(50, 50)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		grid.add_child(icon)

		var lbl_control = Label.new()
		lbl_control.text = control["action"]
		lbl_control.add_theme_color_override("font_color", Color("#F5F5F5"))
		lbl_control.add_theme_font_size_override("font_size", 26)
		lbl_control.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(lbl_control)

	# ── Panel descripción ──────────────────────────────────
	var panel_desc = PanelContainer.new()
	panel_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_panel_color(panel_desc, Color("#2B2B2B"))
	vbox_right.add_child(panel_desc)

	var vbox_desc = VBoxContainer.new()
	vbox_desc.add_theme_constant_override("separation", 16)
	vbox_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_desc.add_child(vbox_desc)

	var lbl_desc = Label.new()
	lbl_desc.text = minigame_data.description
	lbl_desc.add_theme_color_override("font_color", Color("#F5F5F5"))
	lbl_desc.add_theme_font_size_override("font_size", 26)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_desc.add_child(lbl_desc)

	# ── Título "Instrucciones" ──────────────────────────────
	var lbl_instr_title = Label.new()
	lbl_instr_title.text = "Instrucciones"
	lbl_instr_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_instr_title.add_theme_font_size_override("font_size", 36)
	lbl_instr_title.add_theme_color_override("font_color", Color("#F5F5F5"))
	lbl_instr_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox_desc.add_child(lbl_instr_title)

	var lbl_instr = Label.new()
	lbl_instr.text = minigame_data.instructions
	lbl_instr.add_theme_color_override("font_color", Color("#F5F5F5"))
	lbl_instr.add_theme_font_size_override("font_size", 23)
	lbl_instr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_instr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_desc.add_child(lbl_instr)

	# ── Botón Empezar ──────────────────────────────────────
	var btn = Button.new()
	btn.text = "¡Empezar!"
	btn.custom_minimum_size = Vector2(260, 75)
	btn.position = Vector2(screen.x / 2 - 130, screen.y - 130)
	btn.add_theme_font_size_override("font_size", 40)
	btn.add_theme_color_override("font_color", Color("#2B2B2B"))
	_set_button_color(btn, Color("#60B060"), Color("#80C070"), Color("#406080"))
	btn.pressed.connect(_on_start)
	add_child(btn)

func _set_panel_color(panel: PanelContainer, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left     = 12
	style.corner_radius_top_right    = 12
	style.corner_radius_bottom_left  = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left   = 16
	style.content_margin_right  = 16
	style.content_margin_top    = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)

func _set_button_color(btn: Button, normal: Color, hover: Color, pressed: Color):
	for state in [["normal", normal], ["hover", hover], ["pressed", pressed]]:
		var style = StyleBoxFlat.new()
		style.bg_color = state[1]
		style.corner_radius_top_left     = 10
		style.corner_radius_top_right    = 10
		style.corner_radius_bottom_left  = 10
		style.corner_radius_bottom_right = 10
		btn.add_theme_stylebox_override(state[0], style)

func _on_start():
	var audio = get_node_or_null("AudioInstrucciones")
	if audio:
		audio.stop()
	get_tree().change_scene_to_file(minigame_data.minigame_scene)
