## game_over.gd — экран окончания игры
extends CanvasLayer

var _pending_score: int = 0

func _ready():
	visible = false
	$NameInput/VBox/OKBtn.pressed.connect(_on_ok)
	$NameInput/VBox/NameEdit.text_submitted.connect(_on_name_submitted)
	$GameOverPanel/VBoxContainer/TryAgain.pressed.connect(_on_restart)
	$GameOverPanel/VBoxContainer/MainMenu.pressed.connect(_on_main_menu)

func show_game_over(score: int):
	_pending_score = score
	$GameOverPanel/VBoxContainer/Score.text = "Счёт: " + str(score)
	visible = true
	get_tree().paused = true

	if ScoresManager.session_name != "":
		# Имя уже известно — сразу сохраняем и показываем итог
		ScoresManager.add_score(ScoresManager.session_name, score)
		_show_result()
	else:
		# Первая смерть в сессии — просим имя
		$NameInput.visible = true
		$GameOverPanel.visible = false
		$NameInput/VBox/NameEdit.grab_focus()

# Перехватываем пробел как подтверждение ввода имени
func _input(event: InputEvent):
	if not visible or not $NameInput.visible:
		return
	if event.is_action_pressed("jump"):
		get_viewport().set_input_as_handled()
		_on_ok()

func _on_name_submitted(_text: String):
	_on_ok()

func _on_ok():
	var name = $NameInput/VBox/NameEdit.text.strip_edges()
	if name.is_empty():
		name = "Игрок"
	ScoresManager.session_name = name
	ScoresManager.add_score(name, _pending_score)
	_show_result()

func _show_result():
	$NameInput.visible = false
	$GameOverPanel.visible = true
	$GameOverPanel/VBoxContainer/TryAgain.grab_focus()

func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
