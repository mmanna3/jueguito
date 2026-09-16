extends Node2D

# Por ahora hay un solo enfrentamiento posible en todo el juego (Ryan vs.
# Extraño), así que los datos van hardcodeados acá. El día que haya más de
# una batalla, esto pasa a ser algo que le llega a la escena desde afuera
# (por ejemplo, guardado en GameState antes de cambiar de escena).

const PLAYER_NAME := "Ryan"
const PLAYER_LEVEL := 1
const PLAYER_MAX_HP := 12

const ENEMY_NAME := "Extraño"
const ENEMY_LEVEL := 50
const ENEMY_MAX_HP := 1000
const ENEMY_ATTACK := {"name": "Sombra Extraña", "damage": 110}

# Slot 0 es el único ataque real que tiene Ryan hoy; los otros 3 quedan
# reservados (null) para cuando aprenda más.
const PLAYER_ATTACKS := [
	{"name": "Golpear", "damage": 5},
	null,
	null,
	null,
]

const RYAN_TEX := preload("res://assets/characters_custom/ryan.png")
const STRANGER_TEX := preload("res://assets/characters_custom/stranger.png")

enum State { INTRO, PLAYER_MENU, BUSY }

var _state: State = State.INTRO
var _menu_index := 0

var player_hp := PLAYER_MAX_HP
var enemy_hp := ENEMY_MAX_HP

@onready var player_sprite: TextureRect = $UI/PlayerSprite
@onready var enemy_sprite: TextureRect = $UI/EnemySprite
@onready var player_name_label: Label = $UI/PlayerPanel/NameLabel
@onready var player_hp_label: Label = $UI/PlayerPanel/HPLabel
@onready var player_hp_bar: ProgressBar = $UI/PlayerPanel/HPBar
@onready var enemy_name_label: Label = $UI/EnemyPanel/NameLabel
@onready var enemy_hp_label: Label = $UI/EnemyPanel/HPLabel
@onready var enemy_hp_bar: ProgressBar = $UI/EnemyPanel/HPBar
@onready var menu: Control = $UI/AttackMenu
@onready var menu_slots: Array = [
	$UI/AttackMenu/Slot0, $UI/AttackMenu/Slot1, $UI/AttackMenu/Slot2, $UI/AttackMenu/Slot3,
]

const COLOR_SELECTED := Color(1, 0.844, 0.369, 1)
const COLOR_NORMAL := Color(0.929, 0.906, 0.965, 1)
const COLOR_LOCKED := Color(0.45, 0.4, 0.5, 1)


func _ready() -> void:
	player_sprite.texture = RYAN_TEX
	enemy_sprite.texture = STRANGER_TEX

	player_name_label.text = "%s  Nv.%d" % [PLAYER_NAME, PLAYER_LEVEL]
	enemy_name_label.text = "%s  Nv.%d" % [ENEMY_NAME, ENEMY_LEVEL]

	player_hp_bar.max_value = PLAYER_MAX_HP
	enemy_hp_bar.max_value = ENEMY_MAX_HP

	for i in menu_slots.size():
		var atk = PLAYER_ATTACKS[i]
		menu_slots[i].text = atk.name if atk else "—"

	_update_bars()
	_update_menu_highlight()
	menu.visible = false

	_start_battle()


func _update_bars() -> void:
	player_hp_bar.value = player_hp
	player_hp_label.text = "%d / %d" % [player_hp, PLAYER_MAX_HP]
	enemy_hp_bar.value = enemy_hp
	enemy_hp_label.text = "%d / %d" % [enemy_hp, ENEMY_MAX_HP]


func _update_menu_highlight() -> void:
	for i in menu_slots.size():
		var locked: bool = PLAYER_ATTACKS[i] == null
		if locked:
			menu_slots[i].add_theme_color_override("font_color", COLOR_LOCKED)
		elif i == _menu_index:
			menu_slots[i].add_theme_color_override("font_color", COLOR_SELECTED)
		else:
			menu_slots[i].add_theme_color_override("font_color", COLOR_NORMAL)


func _unhandled_input(event: InputEvent) -> void:
	if _state != State.PLAYER_MENU:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_UP or event.keycode == KEY_W:
			get_viewport().set_input_as_handled()
			_move_cursor(-1)
			return
		if event.keycode == KEY_DOWN or event.keycode == KEY_S:
			get_viewport().set_input_as_handled()
			_move_cursor(1)
			return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_confirm_selection()


func _move_cursor(delta: int) -> void:
	# Salta los slots vacios (todavia no aprendidos) en vez de pasar por
	# ellos -- si son todos vacios menos uno, el cursor simplemente no se
	# mueve.
	var idx := _menu_index
	for i in menu_slots.size():
		idx = wrapi(idx + delta, 0, menu_slots.size())
		if PLAYER_ATTACKS[idx] != null:
			_menu_index = idx
			break
	_update_menu_highlight()


func _confirm_selection() -> void:
	var atk = PLAYER_ATTACKS[_menu_index]
	if atk == null:
		return
	menu.visible = false
	_state = State.BUSY
	_player_attacks(atk)


func _start_battle() -> void:
	_state = State.BUSY
	await _say("¡El Extraño te bloquea el paso!")
	_state = State.PLAYER_MENU
	menu.visible = true


func _player_attacks(atk: Dictionary) -> void:
	await _say("%s usa %s." % [PLAYER_NAME, atk.name])
	enemy_hp = maxi(0, enemy_hp - atk.damage)
	_update_bars()
	await _say("¡%s perdió %d PS!" % [ENEMY_NAME, atk.damage])

	if enemy_hp <= 0:
		await _victory()
		return

	await _enemy_turn()


func _enemy_turn() -> void:
	await _say("%s usa %s." % [ENEMY_NAME, ENEMY_ATTACK.name])
	player_hp = maxi(0, player_hp - ENEMY_ATTACK.damage)
	_update_bars()
	await _say("¡%s perdió %d PS!" % [PLAYER_NAME, ENEMY_ATTACK.damage])

	if player_hp <= 0:
		await _defeat()
		return

	_state = State.PLAYER_MENU
	menu.visible = true


func _victory() -> void:
	await _say("¡%s fue derrotado!" % ENEMY_NAME)
	_state = State.BUSY


func _defeat() -> void:
	await _say("%s fue derrotado..." % PLAYER_NAME)
	GameState.returning_from_battle_defeat = true
	get_tree().change_scene_to_file("res://scenes/Forest.tscn")


func _say(text: String) -> void:
	Dialogue.start_conversation([{"speaker": "", "portrait": null, "text": text}])
	await Dialogue.dialogue_closed
