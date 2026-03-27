## main_menu.gd — начальный экран
extends Control

const SettingsMenuScene = preload("res://scenes/settings_menu.tscn")
const LeaderboardScene  = preload("res://scenes/leaderboard.tscn")

func _ready():
	$BtnVBox/StartBtn.pressed.connect(_on_start)
	$BtnVBox/SettingsBtn.pressed.connect(_on_settings)
	$BtnVBox/RecordsBtn.pressed.connect(_on_leaderboard)
	$BtnVBox/ExitBtn.pressed.connect(_on_exit)
	$BtnVBox/StartBtn.grab_focus()

func _on_start():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings():
	$BtnVBox.visible = false
	var settings = SettingsMenuScene.instantiate()
	settings.from_pause = true
	settings.closed.connect(_on_overlay_closed)
	add_child(settings)

func _on_leaderboard():
	$BtnVBox.visible = false
	var lb = LeaderboardScene.instantiate()
	lb.from_pause = true
	lb.closed.connect(_on_overlay_closed)
	add_child(lb)

func _on_overlay_closed():
	$BtnVBox.visible = true
	$BtnVBox/StartBtn.grab_focus()

func _on_exit():
	get_tree().quit()
