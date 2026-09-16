extends CharacterBody2D

const TILE_SIZE := 16
const MOVE_DURATION := 0.15
const INTERACT_DISTANCE := 4.0

var is_moving := false
var move_tween: Tween
var facing := Vector2.DOWN


func _physics_process(_delta: float) -> void:
	if Dialogue.is_active:
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
	if Dialogue.is_active:
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
	var target := position + motion

	move_tween = create_tween()
	move_tween.tween_property(self, "position", target, MOVE_DURATION)
	move_tween.finished.connect(_on_move_finished)


func _on_move_finished() -> void:
	is_moving = false


func _interact() -> void:
	var target_pos := global_position + facing * TILE_SIZE
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.global_position.distance_to(target_pos) < INTERACT_DISTANCE:
			npc.interact()
			return
