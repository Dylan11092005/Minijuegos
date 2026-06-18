extends Area2D
class_name TargetSlot


@export var slot_id: String = ""
@export var placed_item: NodePath


var occupied := false
var placed_node: Node2D


func _ready():
	_setup_target()
	_setup_placed_item()


func show_placed_item():
	if placed_node != null:
		placed_node.visible = true


func _setup_target():
	visible = false
	monitoring = true
	monitorable = true


func _setup_placed_item():
	if placed_item == NodePath(""):
		return

	placed_node = get_node_or_null(placed_item)

	if placed_node != null:
		placed_node.visible = false
	else:
		print("No se encontró el PlacedItem del target: " + slot_id)
