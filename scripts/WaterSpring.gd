extends StaticBody2D

## El manantial no decide que pasa al interactuar -- eso lo define la
## escena (Forest.gd), porque dispara toda una cutscene la primera vez.
signal interact_requested

## El manantial mide 3x3 tiles (48x48), no uno solo como un NPC.
@export var interact_size := Vector2(48, 48)


func _ready() -> void:
	add_to_group("interactable")


func interact() -> void:
	interact_requested.emit()
