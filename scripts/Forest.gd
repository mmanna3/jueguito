extends Node2D

const MAP_W := 15
const MAP_H := 10

const GRASS := Vector2i(0, 0)
const PATH := Vector2i(1, 0)
const BUSH_BORDER := Vector2i(2, 0)
const TREE_TRUNK := Vector2i(3, 0)
const WATER := Vector2i(4, 0)
const BUSH_DECO := Vector2i(5, 0)

const RYAN_PORTRAIT := preload("res://assets/characters_custom/ryan_portrait.png")
const ABUELA_PORTRAIT := preload("res://assets/characters_custom/abuela_portrait.png")

@onready var ground: TileMapLayer = $Ground
@onready var abuela: StaticBody2D = $NPCs/AbuelaCatta


func _ready() -> void:
	_build_map()
	abuela.interact_requested.connect(_on_abuela_interact)


func _build_map() -> void:
	for y in MAP_H:
		for x in MAP_W:
			ground.set_cell(Vector2i(x, y), 0, GRASS)

	for x in MAP_W:
		ground.set_cell(Vector2i(x, 0), 0, BUSH_BORDER)
		ground.set_cell(Vector2i(x, MAP_H - 1), 0, BUSH_BORDER)
	for y in MAP_H:
		ground.set_cell(Vector2i(0, y), 0, BUSH_BORDER)
		ground.set_cell(Vector2i(MAP_W - 1, y), 0, BUSH_BORDER)

	# sendero desde donde arranca Ryan hasta la laguna, donde está la abuela
	for x in range(3, 9):
		ground.set_cell(Vector2i(x, 5), 0, PATH)

	# laguna de Agua Púrpura
	_set_block(9, 3, 2, 2, WATER)

	# árboles y arbustos decorativos
	for pos in [Vector2i(2, 2), Vector2i(12, 2), Vector2i(2, 7), Vector2i(12, 6), Vector2i(6, 2)]:
		ground.set_cell(pos, 0, TREE_TRUNK)
	for pos in [Vector2i(5, 3), Vector2i(10, 7), Vector2i(3, 8)]:
		ground.set_cell(pos, 0, BUSH_DECO)


func _set_block(x0: int, y0: int, w: int, h: int, tile: Vector2i) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			ground.set_cell(Vector2i(x, y), 0, tile)


func _on_abuela_interact() -> void:
	Dialogue.start_conversation([
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "¿Abuela? ¿Qué hacés tan lejos de casa, con este frío?"},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Buscando el murmullo del agua, muchacho. Hace tiempo que no la escuchaba cantar tan cerca."},
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "¿El agua… púrpura? Siempre me dijiste que no me acercara a los manantiales."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Y hice bien en decírtelo, hasta que tuvieras edad de entenderlo. Dicen los viejos relatos que nace donde los Cristales duermen bajo la tierra, y se lleva su color al despertar."},
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "¿Cristales? Nunca vi ninguno."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Pocos los ven, y menos los que viven para contarlo con la mente entera. Pero el agua que ellos tiñen sí se puede tocar. Cura heridas que ni el tiempo cierra, y calma fiebres que ningún médico entiende."},
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "¿Entonces por qué nadie la usa?"},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Porque toda cura tiene su precio. Bebida sin cuidado, la misma agua que sana también reclama algo a cambio. Por eso los antiguos la trataban con respeto, no con codicia."},
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "Tendré cuidado, abuela. Lo prometo."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Lo sé. Por eso te lo cuento a vos y no a otro. Ahora andá, que el bosque se pone hablador cuando cae la tarde."},
	])
