## scores_manager.gd — AutoLoad синглтон таблицы рекордов
extends Node

const SAVE_PATH = "user://scores.cfg"
const MAX_SCORES = 10

var scores: Array = []   # [{name: String, score: int}]
var session_name: String = ""  # имя игрока в текущей сессии (сбрасывается только при выходе)

func _ready():
	load_scores()

func add_score(player_name: String, score: int):
	# Ищем существующую запись с таким именем
	for entry in scores:
		if entry["name"] == player_name:
			# Обновляем только если новый счёт лучше
			if score > entry["score"]:
				entry["score"] = score
				scores.sort_custom(func(a, b): return a["score"] > b["score"])
				save_scores()
			return
	# Имя новое — добавляем
	scores.append({"name": player_name, "score": score})
	scores.sort_custom(func(a, b): return a["score"] > b["score"])
	if scores.size() > MAX_SCORES:
		scores.resize(MAX_SCORES)
	save_scores()

func save_scores():
	var cfg = ConfigFile.new()
	cfg.set_value("meta", "count", scores.size())
	for i in scores.size():
		cfg.set_value("scores", str(i) + "_name",  scores[i]["name"])
		cfg.set_value("scores", str(i) + "_score", scores[i]["score"])
	cfg.save(SAVE_PATH)

func load_scores():
	scores.clear()
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var count = cfg.get_value("meta", "count", 0)
	for i in count:
		var n = cfg.get_value("scores", str(i) + "_name",  "")
		var s = cfg.get_value("scores", str(i) + "_score", 0)
		if n != "":
			scores.append({"name": n, "score": s})
