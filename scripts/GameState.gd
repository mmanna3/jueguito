extends Node

## Estado que necesita sobrevivir un cambio de escena (Forest -> Battle ->
## Forest de nuevo). Godot reinstancia la escena desde cero en cada cambio,
## así que esto es lo único que "recuerda" lo que pasó.

## Se pone en true justo antes de volver al bosque tras perder la batalla
## contra el Extraño. Forest.gd lo lee una vez en _ready(), lo apaga, y
## dispara el diálogo posterior (interviene la Abuela).
var returning_from_battle_defeat := false
