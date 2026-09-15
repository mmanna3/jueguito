extends CharacterBody2D

const TILE_SIZE := 16
const MOVE_DURATION := 0.15

var is_moving := false
var move_tween: Tween


func _physics_process(_delta: float) -> void:
	if is_moving:
		return

	var dir := _get_input_direction()
	if dir != Vector2.ZERO:
		_try_move(dir)


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
	var target := position + motion

	move_tween = create_tween()
	move_tween.tween_property(self, "position", target, MOVE_DURATION)
	move_tween.finished.connect(_on_move_finished)


func _on_move_finished() -> void:
	is_moving = false
