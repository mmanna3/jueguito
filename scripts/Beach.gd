extends Node2D

## Playa donde se estrella la nave al escapar de la emboscada del Bosque
## Púrpura (ver ForestSouth.gd). El mapa más grande hasta ahora: 55x40
## tiles (2200 celdas), contra las 40x30 del bosque.

const MAP_W := 55
const MAP_H := 40

const SAND := Vector2i(0, 0)
const WET_SAND := Vector2i(1, 0)
const SAND_SHADE := Vector2i(2, 0)
const SHELLS := Vector2i(3, 0)
const WATER_RED := Vector2i(4, 0)
const TREE_DARK := Vector2i(5, 0)
const TREE_DARK_PINE := Vector2i(6, 0)
const BOULDER := Vector2i(7, 0)
const ROCK_WALL := Vector2i(8, 0)
const DEAD_BUSH := Vector2i(9, 0)
const SHORE_A := Vector2i(10, 0)
const SHORE_B := Vector2i(11, 0)
const SHORE_C := Vector2i(12, 0)
const WRECK_DEBRIS := Vector2i(13, 0)
const SCORCHED_SAND := Vector2i(14, 0)

const SHORE_VARIANTS := [SHORE_A, SHORE_B, SHORE_C]
const ROCK_VARIETY := [ROCK_WALL, BOULDER]
const TREE_VARIETY := [TREE_DARK, TREE_DARK_PINE]

## Franja de mar en el borde sur: fila de arena mojada, fila de costa
## (espuma), y el resto agua abierta hasta el final del mapa.
const SEA_WET_ROW := MAP_H - 9
const SEA_SHORE_ROW := MAP_H - 8
const SEA_TOP_ROW := MAP_H - 7

const SHIP_CELL := Vector2i(26, 14)

## Grupos irregulares de piedra (6-7 celdas cada uno) -- "mucha piedra",
## repartida por el interior, no amontonada en un solo lugar.
const ROCK_CLUSTERS := [
	[Vector2i(6, 22), Vector2i(7, 22), Vector2i(8, 22), Vector2i(6, 23), Vector2i(8, 23), Vector2i(7, 21), Vector2i(6, 21)],
	[Vector2i(10, 20), Vector2i(11, 20), Vector2i(10, 21), Vector2i(9, 21), Vector2i(11, 21), Vector2i(10, 22)],
	[Vector2i(16, 9), Vector2i(17, 9), Vector2i(16, 10), Vector2i(17, 10), Vector2i(18, 10), Vector2i(17, 11), Vector2i(15, 10)],
	[Vector2i(45, 22), Vector2i(46, 22), Vector2i(47, 22), Vector2i(45, 23), Vector2i(47, 23), Vector2i(46, 21), Vector2i(45, 21)],
	[Vector2i(18, 22), Vector2i(19, 22), Vector2i(18, 23), Vector2i(17, 23), Vector2i(19, 23), Vector2i(18, 24)],
	[Vector2i(35, 5), Vector2i(36, 5), Vector2i(35, 6), Vector2i(34, 6), Vector2i(36, 6), Vector2i(35, 7)],
	[Vector2i(13, 6), Vector2i(14, 6), Vector2i(15, 6), Vector2i(13, 7), Vector2i(15, 7), Vector2i(14, 5), Vector2i(13, 5)],
	[Vector2i(6, 11), Vector2i(7, 11), Vector2i(6, 12), Vector2i(5, 12), Vector2i(7, 12), Vector2i(6, 13)],
	[Vector2i(38, 10), Vector2i(39, 10), Vector2i(38, 11), Vector2i(39, 11), Vector2i(40, 11), Vector2i(39, 12), Vector2i(37, 11)],
	[Vector2i(19, 4), Vector2i(20, 4), Vector2i(19, 5), Vector2i(18, 5), Vector2i(20, 5), Vector2i(19, 6)],
]

const TREE_CLUSTERS := [
	[Vector2i(42, 20), Vector2i(43, 20), Vector2i(42, 21), Vector2i(43, 21), Vector2i(44, 21), Vector2i(43, 22), Vector2i(41, 21)],
	[Vector2i(6, 3), Vector2i(7, 3), Vector2i(6, 4), Vector2i(7, 4), Vector2i(8, 4), Vector2i(7, 5), Vector2i(5, 4)],
	[Vector2i(43, 12), Vector2i(44, 12), Vector2i(45, 12), Vector2i(43, 13), Vector2i(45, 13), Vector2i(44, 11), Vector2i(43, 11)],
	[Vector2i(30, 28), Vector2i(31, 28), Vector2i(32, 28), Vector2i(30, 29), Vector2i(32, 29), Vector2i(31, 27), Vector2i(30, 27)],
	[Vector2i(48, 17), Vector2i(49, 17), Vector2i(48, 18), Vector2i(49, 18), Vector2i(50, 18), Vector2i(49, 19), Vector2i(47, 18)],
	[Vector2i(5, 9), Vector2i(6, 9), Vector2i(7, 9), Vector2i(5, 10), Vector2i(7, 10), Vector2i(6, 8), Vector2i(5, 8)],
	[Vector2i(26, 26), Vector2i(27, 26), Vector2i(26, 27), Vector2i(25, 27), Vector2i(27, 27), Vector2i(26, 28)],
]

const LOOSE_BOULDERS := [Vector2i(47, 14), Vector2i(35, 22), Vector2i(44, 18), Vector2i(9, 5), Vector2i(3, 14), Vector2i(36, 13), Vector2i(15, 17), Vector2i(51, 15), Vector2i(41, 12), Vector2i(40, 28)]
const DEAD_BUSHES := [Vector2i(20, 7), Vector2i(48, 25), Vector2i(14, 23), Vector2i(49, 28), Vector2i(17, 8), Vector2i(17, 6), Vector2i(7, 15), Vector2i(39, 17), Vector2i(41, 5), Vector2i(4, 4)]
const SHADE_BLOB_ORIGINS := [Vector2i(19, 29), Vector2i(38, 4), Vector2i(49, 19), Vector2i(6, 10), Vector2i(5, 27), Vector2i(25, 27), Vector2i(16, 26), Vector2i(39, 24), Vector2i(38, 9)]
const SHELL_BLOB_ORIGINS := [Vector2i(37, 20), Vector2i(12, 10), Vector2i(7, 4), Vector2i(19, 17), Vector2i(41, 14), Vector2i(9, 13), Vector2i(36, 9)]

const BLOB_OFFSETS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1)]

## Fragmentos del casco esparcidos alrededor del cráter, y el cráter en si
## (elipse chata de arena quemada) -- todo en la capa "Ground", son
## decorados caminables, no obstáculos.
const CRASH_DEBRIS_OFFSETS := [Vector2i(-3, 2), Vector2i(4, 1), Vector2i(-2, -3), Vector2i(3, -2), Vector2i(0, 3), Vector2i(-4, -1)]

const RYAN_PORTRAIT := preload("res://assets/characters_custom/ryan_portrait.png")
const NARRATOR_TEXT := "El viaje fue desquiciado. La nave está destruida pero Ryan, aunque muy lastimado, está vivo."
const SHIP_FLAVOR_TEXT := "La nave quedó completamente destruida. Del casco todavía sale humo, y las luces internas ya no responden."

@onready var ground: TileMapLayer = $Ground
@onready var decoration: TileMapLayer = $Decoration
@onready var player: CharacterBody2D = $Player
@onready var ship: StaticBody2D = $Ship


func _ready() -> void:
	player.movement_locked = true
	_build_map()
	ship.interact_requested.connect(_on_ship_interact)
	await _play_intro()


## Pantalla oscura (heredada de la pantalla de capítulo anterior, todavía
## no se hizo fade_in) con una línea de narrador sin nombre -- mismo
## recurso que ya usamos para el texto del manantial en el bosque. Recién
## al cerrarse se revela la playa con un fundido.
func _play_intro() -> void:
	Dialogue.start_conversation([
		{"speaker": "", "portrait": null, "text": NARRATOR_TEXT},
	])
	await Dialogue.dialogue_closed

	await Transition.fade_in()
	player.movement_locked = false


func _on_ship_interact() -> void:
	Dialogue.start_conversation([
		{"speaker": "", "portrait": null, "text": SHIP_FLAVOR_TEXT},
	])


func _build_map() -> void:
	for y in MAP_H:
		for x in MAP_W:
			ground.set_cell(Vector2i(x, y), 0, SAND)

	_paint_ground_variety()
	_paint_borders()
	_paint_sea()
	_paint_clusters(ROCK_CLUSTERS, ROCK_VARIETY)
	_paint_clusters(TREE_CLUSTERS, TREE_VARIETY)
	_paint_loose_accents()
	_paint_crash_site()


func _paint_ground_variety() -> void:
	for origin in SHADE_BLOB_ORIGINS:
		_paint_blob(SAND_SHADE, origin)
	for origin in SHELL_BLOB_ORIGINS:
		_paint_blob(SHELLS, origin)


func _paint_blob(tile: Vector2i, origin: Vector2i) -> void:
	for off in BLOB_OFFSETS:
		var pos: Vector2i = origin + off
		if pos.x > 1 and pos.x < MAP_W - 2 and pos.y > 1 and pos.y < SEA_WET_ROW - 1:
			ground.set_cell(pos, 0, tile)


func _paint_borders() -> void:
	for x in MAP_W:
		decoration.set_cell(Vector2i(x, 0), 0, ROCK_WALL)
		decoration.set_cell(Vector2i(x, 1), 0, ROCK_WALL)
	for y in MAP_H:
		decoration.set_cell(Vector2i(0, y), 0, TREE_VARIETY[y % 2])
		decoration.set_cell(Vector2i(1, y), 0, TREE_VARIETY[(y + 1) % 2])
		decoration.set_cell(Vector2i(MAP_W - 1, y), 0, ROCK_VARIETY[y % 2])
		decoration.set_cell(Vector2i(MAP_W - 2, y), 0, ROCK_VARIETY[(y + 1) % 2])


## El mar ocupa toda la franja sur, de punta a punta -- rompe adrede el
## borde de bosque/roca de los costados (la playa se abre al mar).
func _paint_sea() -> void:
	for x in MAP_W:
		ground.set_cell(Vector2i(x, SEA_WET_ROW), 0, WET_SAND)
		decoration.set_cell(Vector2i(x, SEA_SHORE_ROW), 0, SHORE_VARIANTS[x % SHORE_VARIANTS.size()])
	for y in range(SEA_TOP_ROW, MAP_H):
		for x in MAP_W:
			decoration.set_cell(Vector2i(x, y), 0, WATER_RED)


func _paint_clusters(clusters: Array, variety: Array) -> void:
	for cluster in clusters:
		for i in cluster.size():
			var pos: Vector2i = cluster[i]
			decoration.set_cell(pos, 0, variety[(pos.x + pos.y + i) % variety.size()])


func _paint_loose_accents() -> void:
	for pos in LOOSE_BOULDERS:
		decoration.set_cell(pos, 0, BOULDER)
	for pos in DEAD_BUSHES:
		decoration.set_cell(pos, 0, DEAD_BUSH)


func _paint_crash_site() -> void:
	for dy in range(-3, 4):
		for dx in range(-4, 5):
			if (dx * dx) / 16.0 + (dy * dy) / 9.0 <= 1.0:
				ground.set_cell(SHIP_CELL + Vector2i(dx, dy), 0, SCORCHED_SAND)
	for off in CRASH_DEBRIS_OFFSETS:
		ground.set_cell(SHIP_CELL + off, 0, WRECK_DEBRIS)
