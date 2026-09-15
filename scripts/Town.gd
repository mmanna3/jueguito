extends Node2D

const MAP_W := 15
const MAP_H := 10

const GRASS := Vector2i(5, 0)
const PATH := Vector2i(6, 0)
const TREE := Vector2i(13, 10)
const WALL := Vector2i(16, 13)
const WATER := Vector2i(0, 0)

@onready var ground: TileMapLayer = $Ground


func _ready() -> void:
	_build_map()


func _build_map() -> void:
	# 1) pasto de fondo en todo el mapa
	for y in MAP_H:
		for x in MAP_W:
			ground.set_cell(Vector2i(x, y), 0, GRASS)

	# 2) borde de árboles (bloquea la salida del pueblo)
	for x in MAP_W:
		ground.set_cell(Vector2i(x, 0), 0, TREE)
		ground.set_cell(Vector2i(x, MAP_H - 1), 0, TREE)
	for y in MAP_H:
		ground.set_cell(Vector2i(0, y), 0, TREE)
		ground.set_cell(Vector2i(MAP_W - 1, y), 0, TREE)

	# 3) caminos de tierra
	for x in range(1, MAP_W - 1):
		ground.set_cell(Vector2i(x, 5), 0, PATH)
	ground.set_cell(Vector2i(4, 4), 0, PATH)
	ground.set_cell(Vector2i(9, 4), 0, PATH)

	# 4) dos casas (bloques 2x2 sólidos)
	_set_block(3, 2, 2, 2, WALL)
	_set_block(9, 2, 2, 2, WALL)

	# 5) laguna decorativa
	_set_block(11, 7, 2, 2, WATER)


func _set_block(x0: int, y0: int, w: int, h: int, tile: Vector2i) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			ground.set_cell(Vector2i(x, y), 0, tile)
