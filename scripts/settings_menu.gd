## settings_menu.gd — экран настроек
extends Control

signal closed  # эмитируется при возврате из паузы (вместо смены сцены)

var from_pause := false

func _ready():
	# Заполняем разрешения
	var opt: OptionButton = $VBox/ResRow/OptionButton
	for res in SettingsManager.RESOLUTIONS:
		opt.add_item("%d × %d" % [res.x, res.y])

	# Выставляем текущие значения
	$VBox/MasterRow/HSlider.value    = SettingsManager.master_volume
	$VBox/MusicRow/HSlider.value     = SettingsManager.music_volume
	$VBox/SFXRow/HSlider.value       = SettingsManager.sfx_volume
	opt.selected                      = SettingsManager.resolution_idx
	$VBox/WindowRow/CheckBox.button_pressed = SettingsManager.windowed

	$VBox/MasterRow/HSlider.grab_focus()

	# Подключаем сигналы
	$VBox/MasterRow/HSlider.value_changed.connect(_on_master_changed)
	$VBox/MusicRow/HSlider.value_changed.connect(_on_music_changed)
	$VBox/SFXRow/HSlider.value_changed.connect(_on_sfx_changed)
	opt.item_selected.connect(_on_resolution_changed)
	$VBox/WindowRow/CheckBox.toggled.connect(_on_windowed_toggled)
	$VBox/BackBtn.pressed.connect(_on_back)

func _on_master_changed(value: float):
	SettingsManager.master_volume = value
	SettingsManager.apply_settings()

func _on_music_changed(value: float):
	SettingsManager.music_volume = value
	SettingsManager.apply_settings()

func _on_sfx_changed(value: float):
	SettingsManager.sfx_volume = value
	SettingsManager.apply_settings()

func _on_resolution_changed(idx: int):
	SettingsManager.resolution_idx = idx
	SettingsManager.apply_settings()

func _on_windowed_toggled(toggled: bool):
	SettingsManager.windowed = toggled
	SettingsManager.apply_settings()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("back") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()

func _on_back():
	SettingsManager.save_settings()
	if from_pause:
		closed.emit()
		queue_free()
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
