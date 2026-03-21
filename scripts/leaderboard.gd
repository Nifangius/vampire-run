## leaderboard.gd — таблица рекордов
extends Control

signal closed  # эмитируется при возврате из паузы

var from_pause := false

@onready var rows_container = $VBox/ScrollContainer/RowsContainer

func _ready():
	$VBox/BackBtn.pressed.connect(_on_back)
	_populate()

func _populate():
	# Очищаем старые строки
	for child in rows_container.get_children():
		child.queue_free()

	var scores = ScoresManager.scores
	if scores.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Пока нет записей"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rows_container.add_child(empty_label)
		return

	for i in scores.size():
		var row = HBoxContainer.new()
		var lbl_name  = Label.new()
		var lbl_score = Label.new()
		lbl_name.text  = scores[i]["name"]
		lbl_score.text = str(scores[i]["score"])
		lbl_name.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
		lbl_score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_score.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(lbl_name)
		row.add_child(lbl_score)
		rows_container.add_child(row)

func _on_back():
	if from_pause:
		closed.emit()
		queue_free()
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
