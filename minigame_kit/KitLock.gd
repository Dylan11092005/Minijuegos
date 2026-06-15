extends Area2D
class_name KitLock


signal lock_opened(lock_node: KitLock)


var _opened := false
var _check_original_scale := Vector2.ONE


@onready var _check_sprite: Sprite2D = get_node_or_null("CheckSprite")


func _ready():
	input_pickable = true

	if _check_sprite != null:
		_check_original_scale = _check_sprite.scale
		_check_sprite.visible = false


func _input_event(_viewport, event, _shape_index):
	if _opened:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			open_lock()


func open_lock():
	if _opened:
		return

	_opened = true
	input_pickable = false

	_show_check()
	lock_opened.emit(self)


func _show_check():
	if _check_sprite == null:
		print("No se encontró CheckSprite en: " + name)
		return

	_check_sprite.visible = true
	_check_sprite.scale = Vector2.ZERO

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		_check_sprite,
		"scale",
		_check_original_scale,
		0.25
	)
