extends CanvasLayer

@export var ruta_menu := "res://MenuPrincipal.tscn"

@onready var contenedor = $Contenedor
@onready var panel_fondo = $Contenedor/PanelFondo
@onready var label_mensaje = $Contenedor/LabelMensaje
@onready var boton_volver = $Contenedor/BotonVolver

# Paleta oficial
var color_verde := Color("#60B060")
var color_verde_claro := Color("#80C070")
var color_celeste_claro := Color("#C0E0FF")
var color_celeste := Color("#30C0F0")
var color_azul_oscuro := Color("#406080")

var color_cafe := Color("#907050")
var color_rojo := Color("#F02020")
var color_naranja := Color("#E08040")
var color_amarillo := Color("#FFF020")
var color_piel := Color("#E0B080")

var color_azul_gris := Color("#A0B0C0")
var color_beige := Color("#F0D0A0")
var color_blanco := Color("#F5F5F5")
var color_negro := Color("#2B2B2B")
var color_gris := Color("#B2B2B2")

var mensaje_actual := ""


func _ready():
	visible = false
	
	configurar_contenedor()
	configurar_panel()
	configurar_label()
	configurar_boton()
	
	boton_volver.pressed.connect(_on_boton_volver_pressed)


func configurar_contenedor():
	contenedor.position = Vector2.ZERO
	contenedor.size = get_viewport().get_visible_rect().size
	contenedor.mouse_filter = Control.MOUSE_FILTER_STOP


func configurar_panel():
	var pantalla := get_viewport().get_visible_rect().size
	
	panel_fondo.custom_minimum_size = Vector2(660, 280)
	panel_fondo.position = Vector2(
		(pantalla.x - 660) / 2,
		(pantalla.y - 280) / 2
	)
	panel_fondo.size = Vector2(660, 280)
	
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color_beige
	estilo.border_color = color_naranja
	
	estilo.border_width_left = 8
	estilo.border_width_right = 8
	estilo.border_width_top = 8
	estilo.border_width_bottom = 8
	
	estilo.corner_radius_top_left = 32
	estilo.corner_radius_top_right = 32
	estilo.corner_radius_bottom_left = 32
	estilo.corner_radius_bottom_right = 32
	
	estilo.shadow_color = Color(0, 0, 0, 0.28)
	estilo.shadow_size = 14
	estilo.shadow_offset = Vector2(0, 8)
	
	panel_fondo.add_theme_stylebox_override("panel", estilo)


func configurar_label():
	var pantalla := get_viewport().get_visible_rect().size
	
	label_mensaje.position = Vector2(
		(pantalla.x - 600) / 2,
		(pantalla.y - 120) / 2 - 15
	)
	
	label_mensaje.size = Vector2(600, 120)
	label_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_mensaje.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	label_mensaje.add_theme_color_override("font_color", color_azul_oscuro)
	label_mensaje.add_theme_font_size_override("font_size", 38)
	
	var fuente = load("res://assets/fonts/Montserrat.ttf")
	if fuente:
		label_mensaje.add_theme_font_override("font", fuente)


func configurar_boton():
	var pantalla := get_viewport().get_visible_rect().size
	
	boton_volver.text = "Volver al menú"
	boton_volver.position = Vector2(
		(pantalla.x - 240) / 2,
		(pantalla.y / 2) + 90
	)
	boton_volver.size = Vector2(240, 55)
	
	var estilo_normal := StyleBoxFlat.new()
	estilo_normal.bg_color = color_celeste
	estilo_normal.border_color = color_azul_oscuro
	
	estilo_normal.border_width_left = 4
	estilo_normal.border_width_right = 4
	estilo_normal.border_width_top = 4
	estilo_normal.border_width_bottom = 4
	
	estilo_normal.corner_radius_top_left = 18
	estilo_normal.corner_radius_top_right = 18
	estilo_normal.corner_radius_bottom_left = 18
	estilo_normal.corner_radius_bottom_right = 18
	
	var estilo_hover := StyleBoxFlat.new()
	estilo_hover.bg_color = color_celeste_claro
	estilo_hover.border_color = color_azul_oscuro
	
	estilo_hover.border_width_left = 4
	estilo_hover.border_width_right = 4
	estilo_hover.border_width_top = 4
	estilo_hover.border_width_bottom = 4
	
	estilo_hover.corner_radius_top_left = 18
	estilo_hover.corner_radius_top_right = 18
	estilo_hover.corner_radius_bottom_left = 18
	estilo_hover.corner_radius_bottom_right = 18
	
	var estilo_pressed := StyleBoxFlat.new()
	estilo_pressed.bg_color = color_azul_oscuro
	estilo_pressed.border_color = color_celeste
	
	estilo_pressed.border_width_left = 4
	estilo_pressed.border_width_right = 4
	estilo_pressed.border_width_top = 4
	estilo_pressed.border_width_bottom = 4
	
	estilo_pressed.corner_radius_top_left = 18
	estilo_pressed.corner_radius_top_right = 18
	estilo_pressed.corner_radius_bottom_left = 18
	estilo_pressed.corner_radius_bottom_right = 18
	
	boton_volver.add_theme_stylebox_override("normal", estilo_normal)
	boton_volver.add_theme_stylebox_override("hover", estilo_hover)
	boton_volver.add_theme_stylebox_override("pressed", estilo_pressed)
	
	boton_volver.add_theme_color_override("font_color", color_blanco)
	boton_volver.add_theme_color_override("font_hover_color", color_azul_oscuro)
	boton_volver.add_theme_color_override("font_pressed_color", color_blanco)
	boton_volver.add_theme_font_size_override("font_size", 22)
	
	var fuente = load("res://assets/fonts/Montserrat.ttf")
	if fuente:
		boton_volver.add_theme_font_override("font", fuente)


func mostrar_ganaste():
	mensaje_actual = "Felicidades,\nganaste el juego"
	label_mensaje.text = mensaje_actual
	label_mensaje.add_theme_color_override("font_color", color_azul_oscuro)
	visible = true


func mostrar_perdiste():
	mensaje_actual = "Qué mal,\nperdiste"
	label_mensaje.text = mensaje_actual
	label_mensaje.add_theme_color_override("font_color", color_azul_oscuro)
	visible = true


func ocultar():
	visible = false


func _on_boton_volver_pressed():
	get_tree().change_scene_to_file(ruta_menu)
