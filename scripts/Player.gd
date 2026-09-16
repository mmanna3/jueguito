extends CharacterBody2D

const TILE_SIZE := 16
const MOVE_DURATION := 0.15
const DEFAULT_INTERACT_SIZE := Vector2(16, 16)
const INTERACT_PADDING := 2.0

var is_moving := false
var move_tween: Tween
var facing := Vector2.DOWN

## Congela al jugador durante cutscenes (mientras camina un NPC, etc.),
## sin depender de que haya un dialogo abierto.
var movement_locked := false

## Se emite cada vez que termina un paso (tile a tile). Lo usa Forest.gd
## para que un personaje (la abuela) pueda seguir a Ryan un paso atras.
signal move_finished(from_pos: Vector2, to_pos: Vector2)

var _move_start := Vector2.ZERO


func _physics_process(_delta: float) -> void:
	if Dialogue.is_active or movement_locked:
		return

	if is_moving:
		return

	var dir := _get_input_direction()
	if dir != Vector2.ZERO:
		facing = dir
		_try_move(dir)


func _unhandled_input(event: InputEvent) -> void:
	# Manejado como evento (no polling) para que un mismo Enter no pueda
	# ser leido dos veces en el mismo frame por Player y por Dialogue
	# (eso causaba que el dialogo se reabriera solo al llegar a la ultima
	# linea, en vez de cerrarse).
	if Dialogue.is_active or movement_locked:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_interact()


func _get_input_direction() -> Vector2:
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		return Vector2.UP
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		return Vector2.DOWN
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		return Vector2.LEFT
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		return Vector2.RIGHT
	return Vector2.ZERO


func _try_move(dir: Vector2) -> void:
	var motion := dir * TILE_SIZE

	# test_move solo chequea colisiones (TileMap + NPCs), no mueve el cuerpo.
	if test_move(global_transform, motion):
		return

	is_moving = true
	_move_start = position
	var target := position + motion

	move_tween = create_tween()
	move_tween.tween_property(self, "position", target, MOVE_DURATION)
	move_tween.finished.connect(_on_move_finished.bind(target))


func _on_move_finished(target: Vector2) -> void:
	is_moving = false
	move_finished.emit(_move_start, target)


func _interact() -> void:
	# Chequea si la celda de enfrente cae dentro del area del interactuable
	# (no solo "cerca de su centro"): un NPC mide un tile, pero el
	# manantial mide 3x3 tiles, y su centro nunca queda a un tile exacto de
	# ninguna celda donde el jugador pueda pararse.
	var target_pos := global_position + facing * TILE_SIZE
	for thing in get_tree().get_nodes_in_group("interactable"):
		var size: Vector2 = thing.interact_size if "interact_size" in thing else DEFAULT_INTERACT_SIZE
		var area := Rect2(thing.global_position - size / 2.0, size).grow(INTERACT_PADDING)
		if area.has_point(target_pos):
			thing.interact()
			return
