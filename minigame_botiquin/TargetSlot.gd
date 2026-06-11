extends Area2D
class_name TargetSlot

@export var slot_id: String = ""

# Aquí arrastras el Sprite2D final que debe aparecer cuando el objeto se coloca bien
@export var placed_item: NodePath

var occupied := false
var placed_node: Node2D


func _ready():
	visible = false
	monitoring = true
	monitorable = true

	if placed_item != NodePath(""):
		placed_node = get_node_or_null(placed_item)

	if placed_node != null:
		placed_node.visible = false


func show_placed_item():
	if placed_node != null:
		placed_node.visible = true
