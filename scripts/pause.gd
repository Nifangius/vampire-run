## pause.gd — экран паузы
## Важно: Process Mode этого узла должен быть Always (работает на паузе)
extends CanvasLayer

signal resumed

const SettingsMenuScene  = preload("res://scenes/settings_menu.tscn")
const LeaderboardScene   = preload("res://scenes/leaderboard.tscn")

var _buttons: Array
var _focused_index := 0

func _ready():
	visible = false
	_rebuild_buttons()
	$CenterContainer/VBoxContainer/Continue.pressed.connect(_on_continue)
	$CenterContainer/VBoxContainer/Settings.pressed.connect(_on_settings)
	$CenterContainer/VBoxContainer/Records.pressed.connect(_on_leaderboard)
	$CenterContainer/VBoxContainer/Exit.pressed.connect(_on_exit)

func show_pause(score: int):
	$CenterContainer/VBoxContainer/Score.text = "Счёт: " + str(score)
	_focused_index = 0
	_buttons[0].grab_focus()
	visible = true

func hide_pause():
	visible = false

func _rebuild_buttons():
	_buttons = [
		$CenterContainer/VBoxContainer/Continue,
		$CenterContainer/VBoxContainer/Settings,
		$CenterContainer/VBoxContainer/Records,
		$CenterContainer/VBoxContainer/Exit,
	]

func _unhandled_input(event: InputEvent):
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_continue()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_W:
			_focused_index = (_focused_index - 1 + _buttons.size()) % _buttons.size()
			_buttons[_focused_index].grab_focus()
		elif event.keycode == KEY_S:
			_focused_index = (_focused_index + 1) % _buttons.size()
			_buttons[_focused_index].grab_focus()

func _on_continue():
	hide_pause()
	resumed.emit()
	get_tree().paused = false

func _on_settings():
	$CenterContainer.visible = false
	var settings = SettingsMenuScene.instantiate()
	settings.from_pause = true
	settings.closed.connect(_on_overlay_closed)
	add_child(settings)

func _on_leaderboard():
	$CenterContainer.visible = false
	var lb = LeaderboardScene.instantiate()
	lb.from_pause = true
	lb.closed.connect(_on_overlay_closed)
	add_child(lb)

func _on_overlay_closed():
	$CenterContainer.visible = true
	_focused_index = 0
	_buttons[0].grab_focus()

func _on_exit():
	get_tree().paused = false
	get_tree().quit()
