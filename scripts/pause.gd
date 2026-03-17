## pause.gd — экран паузы
## Важно: Process Mode этого узла должен быть Always (работает на паузе)
extends CanvasLayer

func _ready():
	visible = false
	$CenterContainer/VBoxContainer/Continue.pressed.connect(_on_continue)
	$CenterContainer/VBoxContainer/Exit.pressed.connect(_on_exit)

func show_pause(score: int):
	$CenterContainer/VBoxContainer/Score.text = "Счёт: " + str(score)
	visible = true

func hide_pause():
	visible = false

func _on_continue():
	hide_pause()
	get_tree().paused = false

func _on_exit():
	get_tree().paused = false
	get_tree().quit()
