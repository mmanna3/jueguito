extends CanvasLayer

var is_active := false

## Array de Dictionary: {"speaker": String, "portrait": Texture2D (opcional), "text": String}
var _entries: Array = []
var _index := 0

@onready var root: Control = $Root
@onready var name_label: Label = $Root/Panel/NameLabel
@onready var body_label: Label = $Root/Panel/BodyLabel
@onready var portrait_rect: TextureRect = $Root/Panel/PortraitFrame/Portrait
@onready var portrait_frame: Panel = $Root/Panel/PortraitFrame

const TEXT_LEFT_WITH_PORTRAIT := 66.0
const TEXT_LEFT_NO_PORTRAIT := 12.0


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
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
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
		portrait_frame.visible = true
		name_label.offset_left = TEXT_LEFT_WITH_PORTRAIT
		body_label.offset_left = TEXT_LEFT_WITH_PORTRAIT
	else:
		portrait_frame.visible = false
		name_label.offset_left = TEXT_LEFT_NO_PORTRAIT
		body_label.offset_left = TEXT_LEFT_NO_PORTRAIT


func _advance() -> void:
	_index += 1
	if _index >= _entries.size():
		_close()
	else:
		_show_current_entry()


func _close() -> void:
	is_active = false
	root.visible = false
