extends Node2D

const MAP_W := 40
const MAP_H := 30

const GRASS := Vector2i(0, 0)
const PATH := Vector2i(1, 0)
const GRASS_SHADE := Vector2i(2, 0)
const FLOWERS := Vector2i(3, 0)
const WATER := Vector2i(4, 0)
const HEDGE := Vector2i(5, 0)
const TREE_TRUNK := Vector2i(6, 0)
const PINE_TRUNK := Vector2i(7, 0)
const ROCK := Vector2i(8, 0)
const BUSH_DECO := Vector2i(9, 0)
const WATER_EDGE_TOP := Vector2i(10, 0)
const WATER_EDGE_MID := Vector2i(11, 0)
const WATER_EDGE_BOTTOM := Vector2i(12, 0)

const OBSTACLE_VARIETY := [HEDGE, TREE_TRUNK, PINE_TRUNK]

const RYAN_PORTRAIT := preload("res://assets/characters_custom/ryan_portrait.png")
const ABUELA_PORTRAIT := preload("res://assets/characters_custom/abuela_portrait.png")
const STRANGER_PORTRAIT := preload("res://assets/characters_custom/stranger_portrait.png")
const STRANGER_SHOCKED_TEX := preload("res://assets/characters_custom/stranger_shocked.png")
const STRANGER_SHOCKED_PORTRAIT := preload("res://assets/characters_custom/stranger_shocked_portrait.png")

const WATER_FLAVOR_TEXT := "El Agua Púrpura brota de la tierra calmada, como si escondiera el secreto de un pasado olvidado."

const STRANGER_ARRIVAL_POS := Vector2(392, 168)

## "Ground" siempre tiene un terreno solido (pasto/camino/agua) debajo de todo.
## "Decoration" tiene los obstaculos (arboles, arbustos, rocas, orillas), que
## son siluetas con transparencia -- si se pintaran solos en una sola capa,
## esa transparencia dejaria ver el fondo gris de la ventana en vez del
## pasto.
@onready var ground: TileMapLayer = $Ground
@onready var decoration: TileMapLayer = $Decoration
@onready var abuela: StaticBody2D = $NPCs/AbuelaCatta
@onready var stranger: StaticBody2D = $NPCs/Stranger
@onready var pond: StaticBody2D = $Pond
@onready var player: CharacterBody2D = $Player

var _talked_to_abuela := false
var _water_event_played := false


func _ready() -> void:
	_build_map()
	abuela.interact_requested.connect(_on_abuela_interact)
	pond.interact_requested.connect(_on_pond_interact)

	if GameState.returning_from_battle_defeat:
		GameState.returning_from_battle_defeat = false
		await _play_post_battle_scene()


func _build_map() -> void:
	for y in MAP_H:
		for x in MAP_W:
			ground.set_cell(Vector2i(x, y), 0, GRASS)

	_paint_grass_variety()
	_paint_path()

	_paint_border()
	_paint_groves()
	_paint_accents()


func _paint_border() -> void:
	for x in MAP_W:
		decoration.set_cell(Vector2i(x, 0), 0, HEDGE)
		decoration.set_cell(Vector2i(x, 1), 0, HEDGE)
		decoration.set_cell(Vector2i(x, MAP_H - 2), 0, HEDGE)
		decoration.set_cell(Vector2i(x, MAP_H - 1), 0, HEDGE)
	for y in MAP_H:
		decoration.set_cell(Vector2i(MAP_W - 1, y), 0, ROCK)

	# agua a la izquierda, con orilla (las piezas de la laguna dan el borde).
	# Van en "Decoration": son siluetas con esquinas transparentes, y el
	# pasto de "Ground" (ya pintado) tiene que verse por ahi.
	decoration.set_cell(Vector2i(0, 2), 0, WATER_EDGE_TOP)
	for y in range(3, MAP_H - 3):
		decoration.set_cell(Vector2i(0, y), 0, WATER_EDGE_MID)
	decoration.set_cell(Vector2i(0, MAP_H - 3), 0, WATER_EDGE_BOTTOM)


func _paint_grass_variety() -> void:
	var shade_patches := [
		Vector2i(6, 6), Vector2i(19, 4), Vector2i(29, 12), Vector2i(9, 21), Vector2i(34, 22), Vector2i(17, 18),
	]
	for origin in shade_patches:
		_paint_blob(ground, origin, GRASS_SHADE)

	var flower_patches := [
		Vector2i(4, 10), Vector2i(16, 23), Vector2i(25, 8), Vector2i(36, 16), Vector2i(11, 16), Vector2i(30, 24),
	]
	for origin in flower_patches:
		_paint_blob(ground, origin, FLOWERS)


func _paint_blob(layer: TileMapLayer, origin: Vector2i, tile: Vector2i) -> void:
	var offsets := [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1),
	]
	for off in offsets:
		var pos: Vector2i = origin + off
		if pos.x > 1 and pos.x < MAP_W - 2 and pos.y > 2 and pos.y < MAP_H - 3:
			layer.set_cell(pos, 0, tile)


func _paint_path() -> void:
	# sendero desde donde arranca Ryan hasta la laguna, junto a la abuela
	var points := [
		Vector2i(5, 15), Vector2i(11, 15), Vector2i(11, 12), Vector2i(16, 12),
		Vector2i(16, 10), Vector2i(20, 10),
	]
	for i in range(points.size() - 1):
		_paint_line(points[i], points[i + 1])


func _paint_line(a: Vector2i, b: Vector2i) -> void:
	var pos := a
	while pos != b:
		ground.set_cell(pos, 0, PATH)
		if pos.x != b.x:
			pos.x += signi(b.x - pos.x)
		elif pos.y != b.y:
			pos.y += signi(b.y - pos.y)
	ground.set_cell(b, 0, PATH)


func _paint_groves() -> void:
	# grupos irregulares de 6-7 arboles/arbustos: un pequeño bosque infranqueable
	var grove_shapes := [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(-1, 1)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, -1), Vector2i(0, -1)],
	]
	var origins := [
		Vector2i(13, 6), Vector2i(27, 19), Vector2i(32, 6), Vector2i(9, 23), Vector2i(24, 22), Vector2i(30, 16),
	]

	for i in origins.size():
		var shape: Array = grove_shapes[i % grove_shapes.size()]
		var origin: Vector2i = origins[i]
		for j in shape.size():
			var pos: Vector2i = origin + shape[j]
			var tile: Vector2i = OBSTACLE_VARIETY[(pos.x + pos.y + j) % OBSTACLE_VARIETY.size()]
			decoration.set_cell(pos, 0, tile)


func _paint_accents() -> void:
	# arbolitos y rocas sueltas, de adorno, sueltos por el claro
	var pines := [Vector2i(8, 8), Vector2i(21, 4), Vector2i(6, 18), Vector2i(33, 10), Vector2i(18, 26)]
	for pos in pines:
		decoration.set_cell(pos, 0, PINE_TRUNK)

	var trees := [Vector2i(23, 15), Vector2i(14, 20), Vector2i(37, 20), Vector2i(4, 24)]
	for pos in trees:
		decoration.set_cell(pos, 0, TREE_TRUNK)

	var bushes := [Vector2i(9, 9), Vector2i(20, 6), Vector2i(28, 9), Vector2i(13, 17), Vector2i(35, 24), Vector2i(6, 12)]
	for pos in bushes:
		decoration.set_cell(pos, 0, BUSH_DECO)

	var rocks := [Vector2i(22, 13), Vector2i(31, 22), Vector2i(7, 26), Vector2i(37, 14)]
	for pos in rocks:
		decoration.set_cell(pos, 0, ROCK)


func _on_abuela_interact() -> void:
	Dialogue.start_conversation([
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "¿Abuela? ¿Qué hacés tan lejos de casa, con este frío?"},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Buscando el murmullo del agua, muchacho. Hace tiempo que no la escuchaba cantar tan cerca."},
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "¿El agua… púrpura? Siempre me dijiste que no me acercara a los manantiales."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Y hice bien en decírtelo, hasta que tuvieras edad de entenderlo."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Dicen los viejos relatos que nace donde los Cristales duermen bajo la tierra."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Y que se lleva su color al despertar."},
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "¿Cristales? Nunca vi ninguno."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Pocos los ven, y menos los que viven para contarlo con la mente entera."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Pero el agua que ellos tiñen sí se puede tocar."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Cura heridas que ni el tiempo cierra, y calma fiebres que ningún médico entiende."},
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "¿Entonces por qué nadie la usa?"},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Porque toda cura tiene su precio."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Bebida sin cuidado, la misma agua que sana también reclama algo a cambio."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Por eso los antiguos la trataban con respeto, no con codicia."},
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "Tendré cuidado, abuela. Lo prometo."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Lo sé. Por eso te lo cuento a vos y no a otro. Ahora andá, que el bosque se pone hablador cuando cae la tarde."},
	])
	await Dialogue.dialogue_closed
	_talked_to_abuela = true


func _on_pond_interact() -> void:
	Dialogue.start_conversation([
		{"speaker": "", "portrait": null, "text": WATER_FLAVOR_TEXT},
	])
	await Dialogue.dialogue_closed

	if not _talked_to_abuela or _water_event_played:
		return

	_water_event_played = true
	await _play_stranger_scene()


func _play_stranger_scene() -> void:
	player.movement_locked = true

	await _attention_grabber()
	await get_tree().create_timer(0.5).timeout

	stranger.visible = true
	await stranger.walk_to(STRANGER_ARRIVAL_POS, 1.4)

	Dialogue.start_conversation([
		{"speaker": "Extraño", "portrait": STRANGER_PORTRAIT,
			"text": "El planeta es nuestro. Ríndanse o tendrán el mismo fin que los demás."},
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "¿Qué?"},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Tranquilo, Ryan. Haceles caso."},
		{"speaker": "Ryan", "portrait": RYAN_PORTRAIT,
			"text": "Mirá si voy a rendirme con estos bobos."},
		{"speaker": "Extraño", "portrait": STRANGER_PORTRAIT,
			"text": "Qué mal me caen los intentos de héroe."},
	])
	await Dialogue.dialogue_closed

	get_tree().change_scene_to_file("res://scenes/Battle.tscn")


## Se corre al volver de una batalla perdida contra el Extraño (ver
## GameState.returning_from_battle_defeat). La abuela intercede.
func _play_post_battle_scene() -> void:
	for i in range(4):
		await get_tree().process_frame

	player.movement_locked = true
	player.global_position = pond.global_position + Vector2(-32, 30)
	stranger.visible = true
	stranger.position = STRANGER_ARRIVAL_POS

	var cam := player.get_node("Camera2D") as Camera2D
	cam.global_position = player.global_position

	Dialogue.start_conversation([
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT, "text": "Dejame a mí."},
	])
	await Dialogue.dialogue_closed

	await _screen_shake(cam, 0.4, 3.5)

	# algo concreto le pasa al Extraño: cambia la cara (sorpresa/dolor/bronca)
	# y tiembla un ratito, aparte del temblor general de la pantalla.
	stranger.set_sprite_texture(STRANGER_SHOCKED_TEX)
	await stranger.shake(0.5, 2.5)

	Dialogue.start_conversation([
		{"speaker": "Extraño", "portrait": STRANGER_SHOCKED_PORTRAIT,
			"text": "Nunca me imaginé que esta vieja sería tan poderosa."},
		{"speaker": "Abuela Catta", "portrait": ABUELA_PORTRAIT,
			"text": "Ryan, rápido, vamos."},
	])
	await Dialogue.dialogue_closed

	player.movement_locked = false


## Llama la atencion del jugador: un "!" arriba de Ryan y un temblor corto
## de camara. En el futuro esto lo va a reemplazar (o acompañar) un sonido.
func _attention_grabber() -> void:
	var cam := player.get_node("Camera2D") as Camera2D
	_spawn_exclamation()
	await _screen_shake(cam, 0.35, 3.0)


func _spawn_exclamation() -> void:
	var label := Label.new()
	label.text = "!"
	label.z_index = 100
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 0.42, 0.29))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	label.pivot_offset = Vector2(6, 14)
	label.global_position = player.global_position + Vector2(-6, -30)
	label.scale = Vector2(0.1, 0.1)
	label.modulate.a = 0.0

	var tw := create_tween()
	tw.tween_property(label, "scale", Vector2(1, 1), 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(label, "modulate:a", 1.0, 0.1)
	tw.tween_interval(0.5)
	tw.tween_property(label, "modulate:a", 0.0, 0.3)
	tw.tween_callback(label.queue_free)


func _screen_shake(cam: Camera2D, duration: float, strength: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		var pct := 1.0 - (elapsed / duration)
		cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * pct
		await get_tree().create_timer(0.03).timeout
		elapsed += 0.03
	cam.offset = Vector2.ZERO
