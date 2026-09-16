extends StaticBody2D

## Coordenadas (columna, fila) del personaje dentro del spritesheet
## res://assets/characters/roguelikeChar_transparent.png (celdas de 16x16 con 1px de separación).
## Se ignora si "custom_texture" tiene algo asignado.
@export var atlas_coords: Vector2i = Vector2i(0, 6)

## Textura propia (dibujada a mano), en vez de una pieza del spritesheet de Kenney.
@export var custom_texture: Texture2D

## Retrato para el recuadro de diálogo (opcional).
@export var portrait: Texture2D

## Nombre y frases que dice al hablarle (una por una, se avanza con ui_accept).
## Se usa solo si nada está conectado a "interact_requested" (ver más abajo).
@export var npc_name: String = "Aldeano"
@export var dialogue_lines: PackedStringArray = ["¡Hola!"]

## Gancho para que una escena defina una conversación a medida (con varios
## hablantes, por ejemplo) en vez del diálogo genérico de un solo hablante.
signal interact_requested

const CHAR_SHEET := preload("res://assets/characters/roguelikeChar_transparent.png")
const TILE_PITCH := 17
const TILE_SIZE := 16

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("npc")

	if custom_texture:
		sprite.texture = custom_texture
		return

	var tex := AtlasTexture.new()
	tex.atlas = CHAR_SHEET
	tex.region = Rect2(
		atlas_coords.x * TILE_PITCH,
		atlas_coords.y * TILE_PITCH,
		TILE_SIZE,
		TILE_SIZE
	)
	sprite.texture = tex


func interact() -> void:
	if interact_requested.get_connections().size() > 0:
		interact_requested.emit()
		return

	var entries: Array = []
	for line in dialogue_lines:
		entries.append({"speaker": npc_name, "portrait": portrait, "text": line})
	Dialogue.start_conversation(entries)
