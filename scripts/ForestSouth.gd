extends Node2D

const MAP_W := 20
const MAP_H := 15

const GRASS := Vector2i(0, 0)
const PATH := Vector2i(1, 0)
const GRASS_SHADE := Vector2i(2, 0)
const FLOWERS := Vector2i(3, 0)
const HEDGE := Vector2i(5, 0)
const TREE_TRUNK := Vector2i(6, 0)
const PINE_TRUNK := Vector2i(7, 0)
const ROCK := Vector2i(8, 0)
const BUSH_DECO := Vector2i(9, 0)

const RYAN_PORTRAIT := preload("res://assets/characters_custom/ryan_portrait.png")
const ABUELA_PORTRAIT := preload("res://assets/characters_custom/abuela_portrait.png")

const SHIP_POS := Vector2(168, 120)

@onready var ground: TileMapLayer = $Ground
@onready var decoration: TileMapLayer = $Decoration
@onready var abuela: StaticBody2D = $NPCs/AbuelaCatta
@onready var ship: StaticBody2D = $Ship
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	_build_map()
	ship.interact_requested.connect(_on_ship_interact)
	player.move_finished.connect(_on_player_moved_for_follow)

	if GameState.entering_forest_south:
		GameState.entering_forest_south = false
		player.movement_locked = true
		await Transition.fade_in()
		player.movement_locked = false



func _on_player_moved_for_follow(from_pos: Vector2, _to_pos: Vector2) -> void:
	abuela.walk_to(from_pos, 0.15)


func _build_map() -> void:
	for y in MAP_H:
		for x in MAP_W:
			ground.set_cell(Vector2i(x, y), 0, GRASS)

	for x in MAP_W:
		decoration.set_cell(Vector2i(x, 0), 0, HEDGE)
		decoration.set_cell(Vector2i(x, MAP_H - 1), 0, HEDGE)
	for y in MAP_H:
		decoration.set_cell(Vector2i(0, y), 0, HEDGE)
		decoration.set_cell(Vector2i(MAP_W - 1, y), 0, HEDGE)

	# sendero corto desde la entrada (norte) hasta la nave
	for y in range(2, 8):
		ground.set_cell(Vector2i(10, y), 0, PATH)

	var flower_patch := [Vector2i(4, 4), Vector2i(5, 4), Vector2i(4, 5)]
	for pos in flower_patch:
		ground.set_cell(pos, 0, FLOWERS)
	var shade_patch := [Vector2i(15, 10), Vector2i(16, 10), Vector2i(15, 11)]
	for pos in shade_patch:
		ground.set_cell(pos, 0, GRASS_SHADE)

	var pines := [Vector2i(3, 3), Vector2i(16, 4), Vector2i(4, 11), Vector2i(15, 12)]
	for pos in pines:
		decoration.set_cell(pos, 0, PINE_TRUNK)
	var trees := [Vector2i(2, 8), Vector2i(17, 8)]
	for pos in trees:
		decoration.set_cell(pos, 0, TREE_TRUNK)
	var bushes := [Vector2i(6, 3), Vector2i(13, 3), Vector2i(6, 12), Vector2i(13, 12)]
	for pos in bushes:
		decoration.set_cell(pos, 0, BUSH_DECO)
	var rocks := [Vector2i(3, 6), Vector2i(16, 9)]
	for pos in rocks:
		decoration.set_cell(pos, 0, ROCK)


func _on_ship_interact() -> void:
	Dialogue.start_conversation([
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "Abuela, ¿Qué es esto entre los matorrales?"},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Una vieja nave de la época de la Segunda Conquista, fue usada por la Rebelión."},
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT, "text": "..."},
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "¡¿La Rebelión?! ¿Cómo sabés eso?"},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Hay muchas cosas que no sabés de mí."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Tendremos tiempo de hablar, pero este no es el momento."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Tenés que subirte y buscar a Cocco, en Paltiv."},
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "¿Cómo te voy a dejar sola?"},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Ryan, hacé lo que te digo. Esos Extraños traen la sombra consigo."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "No mentían cuando dijeron que Neurolick cayó. Puedo sentirlo."},
	])
