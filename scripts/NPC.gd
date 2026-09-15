extends StaticBody2D

## Coordenadas (columna, fila) del personaje dentro del spritesheet
## res://assets/characters/roguelikeChar_transparent.png (celdas de 16x16 con 1px de separación).
@export var atlas_coords: Vector2i = Vector2i(0, 6)

const CHAR_SHEET := preload("res://assets/characters/roguelikeChar_transparent.png")
const TILE_PITCH := 17
const TILE_SIZE := 16

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	var tex := AtlasTexture.new()
	tex.atlas = CHAR_SHEET
	tex.region = Rect2(
		atlas_coords.x * TILE_PITCH,
		atlas_coords.y * TILE_PITCH,
		TILE_SIZE,
		TILE_SIZE
	)
	sprite.texture = tex

	# La InteractionZone queda preparada para el futuro sistema de diálogo,
	# pero todavía no dispara nada al entrar en ella.
