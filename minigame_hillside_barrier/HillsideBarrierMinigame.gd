extends Node2D
class_name HillsideBarrierMinigame

const TREE_SAPLING_SCENE := preload("res://minigame_hillside_barrier/TreeSapling.tscn")

@onready var _tree_saplings: Node2D = $TreeSaplings
@onready var _tree_spawn_point: Marker2D = $TreeSpawnPoint


func _ready():
	print("PRUEBA: El minijuego inició")
	print("PRUEBA: TreeSaplings existe: ", _tree_saplings)
	print("PRUEBA: TreeSpawnPoint existe: ", _tree_spawn_point)
	
	_spawn_test_tree()


func _spawn_test_tree():
	print("PRUEBA: Creando arbolito")

	var tree = TREE_SAPLING_SCENE.instantiate()
	tree.position = _tree_spawn_point.position
	tree.z_index = 100

	_tree_saplings.add_child(tree)

	print("PRUEBA: Arbolito creado en: ", tree.position)
