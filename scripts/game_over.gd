## game_over.gd — экран окончания игры
## Важно: Process Mode этого узла должен быть Always (работает на паузе)
extends CanvasLayer

func _ready():
	visible = false
	$CenterContainer/VBoxContainer/TryAgain.pressed.connect(_on_restart)

func show_game_over(score: int):
	$CenterContainer/VBoxContainer/Score.text = "Score: " + str(score)
	visible = true
	get_tree().paused = true

func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()
