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

## Tamaño del area que Player.gd usa para saber si lo esta encarando.
@export var interact_size := Vector2(16, 16)

const CHAR_SHEET := preload("res://assets/characters/roguelikeChar_transparent.png")
const TILE_PITCH := 17
const TILE_SIZE := 16

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("interactable")

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


var _walk_tween: Tween

## Desliza al personaje hasta target_pos (posicion global) en duration
## segundos. Pensado para que un personaje "entre en escena" caminando (o
## para que siga a otro personaje paso a paso). Si ya habia un desliz en
## curso, lo corta -- evita que dos tweens compitan por la misma posicion.
func walk_to(target_pos: Vector2, duration: float) -> void:
	if _walk_tween and _walk_tween.is_valid():
		_walk_tween.kill()
	_walk_tween = create_tween()
	_walk_tween.tween_property(self, "global_position", target_pos, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _walk_tween.finished


## Cambia el sprite en el momento (por ejemplo, a una expresion distinta
## tras algo que le pasa en una cutscene).
func set_sprite_texture(tex: Texture2D) -> void:
	sprite.texture = tex


## Prende/apaga la colision fisica del personaje (para NPCs ya vencidos,
## que se quedan en el mapa como decorado interactuable pero no tienen por
## que seguir bloqueando el paso).
func set_solid(solid: bool) -> void:
	collision_shape.disabled = not solid


## Sacude al personaje en el lugar (sin moverlo de verdad al terminar).
func shake(duration: float, strength: float) -> void:
	var original := position
	var elapsed := 0.0
	while elapsed < duration:
		var pct := 1.0 - (elapsed / duration)
		position = original + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * pct
		await get_tree().create_timer(0.03).timeout
		elapsed += 0.03
	position = original
