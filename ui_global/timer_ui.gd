extends CanvasLayer

signal tiempo_agotado

const C_BEIGE   = Color("#E5C89E")
const C_NARANJA = Color("#E0B080")
const C_AZUL    = Color("#3E5F8F")
const C_CELESTE = Color("#39B5E6")
const C_BLANCO  = Color("#FFFFFF")
const C_ROJO    = Color("#D63A3A")

# Colores del timer por fase
const C_FASE_AZUL   = Color("#3E5F8F")
const C_FASE_NARANJA = Color("#E07820")
const C_FASE_ROJO   = Color("#D63A3A")

var panel: Panel
var hbox: HBoxContainer

var label_antes:   Label
var label_tiempo:  Label
var label_despues: Label

var reloj: Control

var tiempo_total    := 60.0
var tiempo_restante := 60.0
var activo          := false

var rot_minutos  := 0.0
var rot_segundos := 0.0

# Color activo (usado tanto en labels como en el reloj)
var color_activo := C_FASE_AZUL

func _ready():
	layer   = 10
	visible = false
	crear_ui()

func crear_ui():
	panel          = Panel.new()
	panel.position = Vector2(20, 20)
	panel.size     = Vector2(430, 60)

	add_child(panel)

	var estilo := StyleBoxFlat.new()
	estilo.bg_color                   = C_BEIGE
	estilo.border_color               = C_NARANJA
	estilo.border_width_left          = 4
	estilo.border_width_right         = 4
	estilo.border_width_top           = 4
	estilo.border_width_bottom        = 4
	estilo.corner_radius_top_left     = 22
	estilo.corner_radius_top_right    = 22
	estilo.corner_radius_bottom_left  = 22
	estilo.corner_radius_bottom_right = 22

	panel.add_theme_stylebox_override("panel", estilo)

	hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left   = 12
	hbox.offset_right  = -12
	hbox.offset_top    = 6
	hbox.offset_bottom = -6
	hbox.add_theme_constant_override("separation", 10)

	panel.add_child(hbox)

	label_antes                     = Label.new()
	label_antes.visible             = false
	label_antes.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	label_antes.add_theme_font_size_override("font_size", 22)
	label_antes.add_theme_color_override("font_color", color_activo)

	hbox.add_child(label_antes)

	reloj = Control.new()
	reloj.custom_minimum_size = Vector2(48, 48)

	hbox.add_child(reloj)

	reloj.draw.connect(_dibujar_reloj)

	label_tiempo                            = Label.new()
	label_tiempo.text                       = "60"
	label_tiempo.custom_minimum_size        = Vector2(0, 0)
	label_tiempo.horizontal_alignment       = HORIZONTAL_ALIGNMENT_CENTER
	label_tiempo.vertical_alignment         = VERTICAL_ALIGNMENT_CENTER
	label_tiempo.add_theme_font_size_override("font_size", 30)
	label_tiempo.add_theme_color_override("font_color", color_activo)

	hbox.add_child(label_tiempo)

	label_despues                    = Label.new()
	label_despues.visible            = false
	label_despues.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_despues.add_theme_font_size_override("font_size", 22)
	label_despues.add_theme_color_override("font_color", color_activo)

	hbox.add_child(label_despues)

func set_tamano_panel(ancho: float, alto: float):
	panel.size = Vector2(ancho, alto)

func _dibujar_reloj():
	var centro = Vector2(24, 24)
	var radio  = 22.0

	# Fondo del reloj
	reloj.draw_circle(centro, radio, Color("#D8ECF6"))

	# Aro exterior con color_activo
	reloj.draw_arc(centro, radio, 0.0, TAU, 64, color_activo, 3.0, true)

	# Marcas de horas con color_activo
	for i in range(12):
		var ang = i * TAU / 12.0 - PI / 2.0
		var p1  = centro + Vector2(cos(ang), sin(ang)) * 17
		var p2  = centro + Vector2(cos(ang), sin(ang)) * 21
		reloj.draw_line(p1, p2, color_activo, 1.5)

	# Manecilla minutos (naranja fijo, decorativa)
	var ang_min = rot_minutos - PI / 2
	var pmin    = centro + Vector2(cos(ang_min), sin(ang_min)) * 12
	reloj.draw_line(centro, pmin, C_NARANJA, 3.0)

	# Manecilla segundos con color_activo
	var ang_seg = rot_segundos - PI / 2
	var pseg    = centro + Vector2(cos(ang_seg), sin(ang_seg)) * 18
	reloj.draw_line(centro, pseg, color_activo, 2.0)

	# Centro
	reloj.draw_circle(centro, 3, C_BLANCO)

func _process(delta):
	if !activo:
		return

	tiempo_restante -= delta

	if tiempo_restante < 0:
		tiempo_restante = 0

	actualizar_display()
	animar_agujas()
	reloj.queue_redraw()

	if tiempo_restante <= 0:
		activo = false
		tiempo_agotado.emit()

func iniciar(p_tiempo: float, p_texto_antes := "", p_texto_despues := ""):
	tiempo_total    = p_tiempo
	tiempo_restante = p_tiempo
	activo          = true
	visible         = true

	label_antes.text    = p_texto_antes
	label_antes.visible = p_texto_antes != ""

	label_despues.text    = p_texto_despues
	label_despues.visible = p_texto_despues != ""

	actualizar_display()
	animar_agujas()
	reloj.queue_redraw()

func detener():
	activo = false

func ocultar():
	activo  = false
	visible = false

func get_tiempo_restante():
	return tiempo_restante

func _get_color_fase() -> Color:
	var fraccion = tiempo_restante / tiempo_total
	if fraccion > 0.5:
		return C_FASE_AZUL
	elif fraccion > 0.25:
		return C_FASE_NARANJA
	else:
		return C_FASE_ROJO

func actualizar_display():
	var segs = int(ceil(tiempo_restante))
	var mins = segs / 60
	var secs = segs % 60

	if mins > 0:
		label_tiempo.text = "%d:%02d" % [mins, secs]
	else:
		label_tiempo.text = str(secs)

	# Actualizar color_activo según la fase
	color_activo = _get_color_fase()

	# Aplicar a todos los labels
	label_tiempo.add_theme_color_override("font_color", color_activo)
	label_antes.add_theme_color_override("font_color",  color_activo)
	label_despues.add_theme_color_override("font_color", color_activo)

func animar_agujas():
	if tiempo_total <= 0:
		return

	var progreso  = 1.0 - (tiempo_restante / tiempo_total)
	rot_minutos   = progreso * TAU

	var ciclo_seg = fmod(tiempo_total - tiempo_restante, 60.0) / 60.0
	rot_segundos  = ciclo_seg * TAU
