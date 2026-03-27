## game_over.gd — экран окончания игры
extends CanvasLayer

const VirtualKeyboard = preload("res://scripts/virtual_keyboard.gd")

var _pending_score: int = 0
var _virtual_keyboard = null

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

func _show_virtual_keyboard():
	$NameInput/VBox/NameEdit.visible = false
	$NameInput/VBox/OKBtn.visible = false
	_virtual_keyboard = VirtualKeyboard.new()
	_virtual_keyboard.text_confirmed.connect(_on_virtual_keyboard_confirmed)
	$NameInput/VBox.add_child(_virtual_keyboard)

func _on_virtual_keyboard_confirmed(text: String):
	_virtual_keyboard.queue_free()
	_virtual_keyboard = null
	$NameInput/VBox/NameEdit.visible = true
	$NameInput/VBox/OKBtn.visible = true
	$NameInput/VBox/NameEdit.text = text
	_on_ok()

# Перехватываем ввод на экране имени
func _input(event: InputEvent):
	if not visible or not $NameInput.visible:
		return
	if event.is_action_pressed("pause"):
		# Кнопка Меню — подтверждение имени (с VK или без)
		get_viewport().set_input_as_handled()
		if _virtual_keyboard != null:
			_virtual_keyboard.confirm()
		else:
			_on_ok()
		return
	if _virtual_keyboard != null:
		return  # виртуальная клавиатура обрабатывает ввод сама
	if event.is_action_pressed("jump"):
		if event is InputEventJoypadButton:
			# Геймпад A: открываем виртуальную клавиатуру
			get_viewport().set_input_as_handled()
			_show_virtual_keyboard()
		else:
			# Пробел: подтверждаем имя
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
	ScoresManager.session_name = ""
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
