extends CanvasLayer

var is_active := false

## Array de Dictionary: {"speaker": String, "portrait": Texture2D (opcional), "text": String}
var _entries: Array = []
var _index := 0

@onready var root: Control = $Root
@onready var name_label: Label = $Root/Panel/NameLabel
@onready var body_label: Label = $Root/Panel/BodyLabel
@onready var portrait_rect: TextureRect = $Root/Panel/Portrait


func start_conversation(entries: Array) -> void:
	if entries.is_empty():
		return

	_entries = entries
	_index = 0
	is_active = true

	root.visible = true
	_show_current_entry()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()


func _show_current_entry() -> void:
	var entry: Dictionary = _entries[_index]
	name_label.text = entry.get("speaker", "")
	body_label.text = entry.get("text", "")

	var tex = entry.get("portrait")
	if tex:
		portrait_rect.texture = tex
		portrait_rect.visible = true
	else:
		portrait_rect.visible = false


func _advance() -> void:
	_index += 1
	if _index >= _entries.size():
		_close()
	else:
		_show_current_entry()


func _close() -> void:
	is_active = false
	root.visible = false
