## virtual_keyboard.gd — экранная клавиатура для управления геймпадом
extends Panel

signal text_confirmed(text: String)

const ROWS: Array = [
	["A","B","C","D","E","F","G","H","I","J"],
	["K","L","M","N","O","P","Q","R","S","T"],
	["U","V","W","X","Y","Z","0","1","2","3"],
	["4","5","6","7","8","9","SPC","⌫","ОК"],
]

var _text := ""
var _cur_row := 0
var _cur_col := 0
var _label: Label
var _buttons: Array = []

var _font = preload("res://assets/fonts/ThaleahFat.ttf")

func _ready():
	# Явно Always чтобы работало при get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_highlight(_cur_row, _cur_col)

func _build_ui():
	custom_minimum_size = Vector2(580, 320)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Дисплей текущего ввода
	_label = Label.new()
	_label.text = "_"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(0, 44)
	_label.add_theme_font_override("font", _font)
	_label.add_theme_font_size_override("font_size", 30)
	_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9))
	vbox.add_child(_label)

	# Ряды кнопок
	for r in range(ROWS.size()):
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 3)
		vbox.add_child(hbox)
		var row: Array = []
		for c in range(ROWS[r].size()):
			var btn = Button.new()
			var char_val: String = ROWS[r][c]
			btn.text = char_val
			var min_w: int = 52 if char_val.length() <= 2 else 70
			btn.custom_minimum_size = Vector2(min_w, 44)
			btn.focus_mode = Control.FOCUS_NONE
			btn.add_theme_font_override("font", _font)
			btn.add_theme_font_size_override("font_size", 20)
			hbox.add_child(btn)
			row.append(btn)
		_buttons.append(row)

func _update_label():
	_label.text = _text + "_"

func _highlight(row: int, col: int):
	for r_arr in _buttons:
		for btn in r_arr:
			btn.modulate = Color.WHITE
	if row < _buttons.size() and col < _buttons[row].size():
		_buttons[row][col].modulate = Color(1.0, 0.75, 0.0)

func confirm():
	text_confirmed.emit(_text)

func _input(event: InputEvent):
	if event.is_action_pressed("pause"):
		confirm()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_right"):
		_move(_cur_row, _cur_col + 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_move(_cur_row, _cur_col - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move(_cur_row + 1, _cur_col)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move(_cur_row - 1, _cur_col)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_press(_cur_row, _cur_col)
		get_viewport().set_input_as_handled()

func _move(new_row: int, new_col: int):
	new_row = posmod(new_row, _buttons.size())
	new_col = clampi(new_col, 0, _buttons[new_row].size() - 1)
	_cur_row = new_row
	_cur_col = new_col
	_highlight(_cur_row, _cur_col)

func _press(row: int, col: int):
	var char_val: String = ROWS[row][col]
	if char_val == "⌫":
		if _text.length() > 0:
			_text = _text.substr(0, _text.length() - 1)
		_update_label()
	elif char_val == "ОК":
		text_confirmed.emit(_text)
	elif char_val == "SPC":
		if _text.length() < GameConfig.PLAYER_NAME_MAX_LEN:
			_text += " "
		_update_label()
	else:
		if _text.length() < GameConfig.PLAYER_NAME_MAX_LEN:
			_text += char_val
		_update_label()
