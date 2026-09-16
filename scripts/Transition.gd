extends CanvasLayer

@onready var rect: ColorRect = $Rect


func _ready() -> void:
	layer = 20
	rect.color = Color(0, 0, 0, 0)


## Funde la pantalla a negro. Usar antes de cambiar de escena.
func fade_out(duration: float = 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(rect, "color:a", 1.0, duration)
	await tw.finished


## Funde la pantalla de negro a transparente. Usar apenas arranca la
## escena nueva, despues de ubicar todo en su lugar.
func fade_in(duration: float = 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(rect, "color:a", 0.0, duration)
	await tw.finished
