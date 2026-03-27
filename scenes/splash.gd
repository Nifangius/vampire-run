extends Control

func _ready():
	$AnimatedSprite2D.animation_finished.connect(_on_finished)
	$AnimatedSprite2D.play("default")
	$AudioStreamPlayer2D.play()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_on_finished()

func _on_finished():
	set_process_input(false)
	$AudioStreamPlayer2D.stop()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
