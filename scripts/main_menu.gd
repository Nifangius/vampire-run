## main_menu.gd — начальный экран
extends Control

func _ready():
	$BtnVBox/StartBtn.pressed.connect(_on_start)
	$BtnVBox/SettingsBtn.pressed.connect(_on_settings)
	$BtnVBox/RecordsBtn.pressed.connect(_on_leaderboard)
	$BtnVBox/ExitBtn.pressed.connect(_on_exit)

func _on_start():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings():
	get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")

func _on_leaderboard():
	get_tree().change_scene_to_file("res://scenes/leaderboard.tscn")

func _on_exit():
	get_tree().quit()
