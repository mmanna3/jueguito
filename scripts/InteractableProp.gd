extends StaticBody2D

## Para objetos grandes del escenario que no son personas (la nave, el
## manantial): no deciden que pasa al interactuar, eso lo define la
## escena que los contiene, via esta señal.
signal interact_requested

## Tamaño del area que Player.gd usa para saber si lo esta encarando.
@export var interact_size := Vector2(32, 32)


func _ready() -> void:
	add_to_group("interactable")


func interact() -> void:
	interact_requested.emit()
