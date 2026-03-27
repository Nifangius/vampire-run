extends Node2D
var pixel_font = preload("res://assets/fonts/ThaleahFat.ttf")

# ============================================================
# РЕСУРСЫ — предзагрузка сцен
# ============================================================
const ObstacleScene     = preload("res://scenes/obstacle.tscn")
const Obstacle2Scene    = preload("res://scenes/obstacle_2.tscn")
const ObstacleSafeScene = preload("res://scenes/obstacle_safe.tscn")
const EnemyScene        = preload("res://scenes/enemy.tscn")
const FlyingEnemyScene  = preload("res://scenes/flying_enemy.tscn")
const BloodDropScene    = preload("res://scenes/blood_drop.tscn")
const HealthDropScene   = preload("res://scenes/heart.tscn")

# ============================================================
# UI УЗЛЫ
# ============================================================
@onready var hearts = [
	$UI/Health/Hrt1,
	$UI/Health/Hrt2,
	$UI/Health/Hrt3,
	$UI/Health/Hrt4,
	$UI/Health/Hrt5
]
@onready var blood_label     = $UI/BloodCounter/BloodLabel
@onready var transform_label = $UI/TransformLabel
@onready var flash_overlay   = $UI/FlashOverlay
@onready var game_over_screen = $GameOver
@onready var pause_screen     = $Pause
@onready var score_label     = $UI/ScoreLabel
@onready var main_music = $MainBG
@onready var transform_music = $TransformBG

# ============================================================
# СОСТОЯНИЕ ИГРЫ
# ============================================================
var score: int          # текущий счёт
var score_accumulator: float  # накопитель дробных очков
var difficulty: float   # множитель сложности, растёт со временем
var is_transformed: bool  # активна ли трансформация игрока

# ============================================================
# ТАЙМЕРЫ СПАВНА
# ============================================================
var spawn_timer: float
var spawn_interval: float

var safe_obstacle_spawn_timer: float
var safe_obstacle_spawn_interval: float

var enemy_spawn_timer: float
var enemy_spawn_interval: float

var flying_spawn_timer: float
var flying_spawn_interval: float

var blood_spawn_timer: float
var blood_spawn_interval: float

var health_spawn_timer: float
var health_spawn_interval: float

func _ready():
	# Начальные значения
	difficulty = 1.0
	spawn_interval                = GameConfig.SPAWN_OBSTACLE_MAX
	safe_obstacle_spawn_interval  = GameConfig.SPAWN_SAFE_OBSTACLE_MAX
	enemy_spawn_interval  = GameConfig.SPAWN_ENEMY_MAX
	flying_spawn_interval = GameConfig.SPAWN_FLYING_MAX
	blood_spawn_interval  = GameConfig.SPAWN_BLOOD_MAX
	health_spawn_interval = GameConfig.SPAWN_HEALTH_MAX
	
	# Назначаем аудио шины
	$MainBG.bus = "Music"
	$TransformBG.bus = "Music"

	# Подключаем сигналы паузы и игрока
	pause_screen.resumed.connect(_on_pause_resumed)
	$Player.hit.connect(_on_player_hit)
	$Player.died.connect(_on_player_died)
	$Player.blood_collected.connect(_on_blood_collected)
	$Player.transform_ready.connect(_on_transform_ready)
	$Player.transformed.connect(_on_transformed)
	$Player.transform_ended.connect(_on_transform_ended)

# ============================================================
# ИГРОВОЙ ЦИКЛ
# ============================================================
func _process(delta):
	_update_score(delta)
	_update_difficulty(delta)
	_update_background(delta)
	_update_spawners(delta)

func _on_pause_resumed():
	if is_transformed:
		transform_music.stream_paused = false
	else:
		main_music.stream_paused = false

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel") and not get_tree().paused:
		_toggle_pause()

func _toggle_pause():
	if get_tree().paused:
		pause_screen.hide_pause()
		main_music.stream_paused = false
		get_tree().paused = false
	else:
		pause_screen.show_pause(score)
		main_music.stream_paused = true
		get_tree().paused = true

## Обновление счёта — накапливаем дробное значение
func _update_score(delta):
	score_accumulator += delta * GameConfig.SCORE_RATE * difficulty
	if score_accumulator >= 1.0:
		score += int(score_accumulator)
		score_accumulator -= int(score_accumulator)
	score_label.text = str(score)

## Сложность постепенно растёт
func _update_difficulty(delta):
	difficulty += delta * GameConfig.DIFFICULTY_RATE

## Скролл параллакс фона
func _update_background(delta):
	scroll_two_layers($Background/Sky1,  $Background/Sky2,  GameConfig.SKY_SPEED  * GameConfig.WORLD_SPEED * delta)
	scroll_two_layers($Background/Mid1,  $Background/Mid2,  GameConfig.MID_SPEED  * GameConfig.WORLD_SPEED * delta)
	scroll_two_layers($Background/Fore1, $Background/Fore2, GameConfig.FORE_SPEED * GameConfig.WORLD_SPEED * delta)

## Управление всеми спавнерами
func _update_spawners(delta):
	# Препятствия всегда
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_obstacle()

	# Безопасные препятствия — реже
	safe_obstacle_spawn_timer += delta
	if safe_obstacle_spawn_timer >= safe_obstacle_spawn_interval:
		safe_obstacle_spawn_timer = 0.0
		spawn_safe_obstacle()
	
	# Враги всегда
	enemy_spawn_timer += delta
	if enemy_spawn_timer >= enemy_spawn_interval:
		enemy_spawn_timer = 0.0
		spawn_enemy()
	
	# Летающие враги всегда
	flying_spawn_timer += delta
	if flying_spawn_timer >= flying_spawn_interval:
		flying_spawn_timer = 0.0
		spawn_flying_enemy()
	
	# Капли крови — только в обычном режиме
	if not is_transformed:
		blood_spawn_timer += delta
		if blood_spawn_timer >= blood_spawn_interval:
			blood_spawn_timer = 0.0
			spawn_blood_drop()
	
	# Сердца — только во время трансформации
	if is_transformed:
		health_spawn_timer += delta
		if health_spawn_timer >= health_spawn_interval:
			health_spawn_timer = 0.0
			spawn_health_drop()

# ============================================================
# ПАРАЛЛАКС — бесконечный скролл двух слоёв
# ============================================================
func scroll_two_layers(layer1: Sprite2D, layer2: Sprite2D, speed: float):
	layer1.position.x -= speed
	layer2.position.x -= speed
	if layer1.position.x <= -GameConfig.BG_WIDTH:
		layer1.position.x = layer2.position.x + GameConfig.BG_WIDTH
	if layer2.position.x <= -GameConfig.BG_WIDTH:
		layer2.position.x = layer1.position.x + GameConfig.BG_WIDTH

# ============================================================
# СПАВН ОБЪЕКТОВ
# ============================================================
func spawn_obstacle():
	# Не спавним опасное препятствие рядом с безопасным
	for safe in get_tree().get_nodes_in_group("safe_obstacle"):
		if abs(safe.position.x - GameConfig.SPAWN_X) < GameConfig.SPAWN_SAFE_OBSTACLE_MIN_GAP:
			return
	var scene = ObstacleScene if randi() % 2 == 0 else Obstacle2Scene
	var obstacle = scene.instantiate()
	obstacle.position = Vector2(GameConfig.SPAWN_X, GameConfig.SPAWN_FLOOR_Y)
	add_child(obstacle)
	spawn_interval = randf_range(GameConfig.SPAWN_OBSTACLE_MIN, GameConfig.SPAWN_OBSTACLE_MAX) / difficulty

func spawn_safe_obstacle():
	for obstacle in get_tree().get_nodes_in_group("obstacle"):
		if abs(obstacle.position.x - GameConfig.SPAWN_X) < GameConfig.SPAWN_SAFE_OBSTACLE_MIN_GAP:
			return
	var obstacle = ObstacleSafeScene.instantiate()
	obstacle.position = Vector2(GameConfig.SPAWN_X, GameConfig.SPAWN_FLOOR_Y)
	add_child(obstacle)
	if (!is_transformed):
		# Спавним каплю крови прямо на платформу — Y берём из реальной геометрии препятствия
		var drop = BloodDropScene.instantiate()
		drop.position = Vector2(GameConfig.SPAWN_X, obstacle.get_platform_top_y()-50)
		add_child(drop)
	safe_obstacle_spawn_interval = randf_range(GameConfig.SPAWN_SAFE_OBSTACLE_MIN, GameConfig.SPAWN_SAFE_OBSTACLE_MAX) / difficulty

func spawn_enemy():
	var enemy = EnemyScene.instantiate()
	enemy.position = Vector2(GameConfig.SPAWN_X, GameConfig.SPAWN_FLOOR_Y)
	add_child(enemy)
	enemy_spawn_interval = randf_range(GameConfig.SPAWN_ENEMY_MIN, GameConfig.SPAWN_ENEMY_MAX) / difficulty

func spawn_flying_enemy():
	var enemy = FlyingEnemyScene.instantiate()
	enemy.position = Vector2(GameConfig.SPAWN_X, randf_range(GameConfig.SPAWN_FLY_Y_MIN, GameConfig.SPAWN_FLY_Y_MAX))
	add_child(enemy)
	flying_spawn_interval = randf_range(GameConfig.SPAWN_FLYING_MIN, GameConfig.SPAWN_FLYING_MAX) / difficulty

# Возвращает тип ближайшего препятствия в радиусе: "dangerous", "safe" или "none"
# Опасное препятствие имеет приоритет над безопасным
func _nearest_obstacle_type(radius: float) -> String:
	var has_safe := false
	for obstacle in get_tree().get_nodes_in_group("obstacle"):
		if abs(obstacle.position.x - GameConfig.SPAWN_X) < radius:
			if obstacle.is_in_group("safe_obstacle"):
				has_safe = true
			else:
				return "dangerous"
	return "safe" if has_safe else "none"

func spawn_blood_drop():
	blood_spawn_interval = randf_range(GameConfig.SPAWN_BLOOD_MIN, GameConfig.SPAWN_BLOOD_MAX) / difficulty
	var nearby := _nearest_obstacle_type(GameConfig.SPAWN_BLOOD_OBSTACLE_CHECK)
	# Рядом с safe_obstacle — там уже есть капля (спавнится вместе с платформой), пропускаем
	if nearby == "safe":
		return
	var drop = BloodDropScene.instantiate()
	if nearby == "dangerous":
		# Поднимаем каплю выше DamageArea — reward за прыжок через препятствие
		drop.position = Vector2(GameConfig.SPAWN_X, randf_range(GameConfig.SPAWN_BLOOD_Y_SAFE_MIN, GameConfig.SPAWN_BLOOD_Y_SAFE_MAX))
	else:
		# Чистая зона — обычная высота у земли
		drop.position = Vector2(GameConfig.SPAWN_X, randf_range(GameConfig.SPAWN_BLOOD_Y_MIN, GameConfig.SPAWN_BLOOD_Y_MAX))
	add_child(drop)

func spawn_health_drop():
	var nearby := _nearest_obstacle_type(GameConfig.SPAWN_BLOOD_OBSTACLE_CHECK)
	var drop = HealthDropScene.instantiate()
	if nearby == "dangerous":
		# Поднимаем сердечко выше DamageArea
		drop.position = Vector2(GameConfig.SPAWN_X, randf_range(GameConfig.SPAWN_BLOOD_Y_SAFE_MIN, GameConfig.SPAWN_BLOOD_Y_SAFE_MAX))
	else:
		drop.position = Vector2(GameConfig.SPAWN_X, randf_range(GameConfig.SPAWN_BLOOD_Y_MIN, GameConfig.SPAWN_BLOOD_Y_MAX))
	add_child(drop)
	health_spawn_interval = randf_range(GameConfig.SPAWN_HEALTH_MIN, GameConfig.SPAWN_HEALTH_MAX) / difficulty

# ============================================================
# ОБРАБОТЧИКИ СИГНАЛОВ ИГРОКА
# ============================================================
func _on_player_hit(lives_remaining):
	# Скрываем иконки жизней слева направо
	for i in hearts.size():
		hearts[i].visible = i < lives_remaining

func _on_player_died():
	game_over_screen.show_game_over(score)

func _on_blood_collected(count):
	if count <= GameConfig.BLOOD_TO_TRANSFORM:
		blood_label.text = str(count) + "/" + str(GameConfig.BLOOD_TO_TRANSFORM)
	if count < GameConfig.BLOOD_TO_TRANSFORM:
		transform_label.visible = false 

func _on_transform_ready():
	transform_label.visible = true

func _on_transformed():
	is_transformed = true
	health_spawn_timer = 0.0
	
	main_music.stream_paused = true
	transform_music.play()
	
	# Убираем капли крови с экрана
	for drop in get_tree().get_nodes_in_group("blood_drop"):
		drop.queue_free()
	flash_and_pause()

func _on_transform_ended():
	is_transformed = false
	
	transform_music.stop()
	main_music.stream_paused = false
	# Убираем сердца с экрана
	for heart in get_tree().get_nodes_in_group("health_drop"):
		heart.queue_free()
	flash_and_pause()

# ============================================================
# ЭФФЕКТ ТРАНСФОРМАЦИИ — вспышка и пауза
# ============================================================
func flash_and_pause():
	$Player/TransformSound.play()
	flash_overlay.visible = true
	get_tree().paused = true
	await get_tree().create_timer(GameConfig.TRANSFORM_PAUSE).timeout
	get_tree().paused = false
	$Player.activate_invincibility(GameConfig.PLAYER_INVINCIBILITY)
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.0, GameConfig.TRANSFORM_FLASH_FADE)
	await tween.finished
	flash_overlay.visible = false
	flash_overlay.modulate.a = 1.0
	
# ============================================================
# НАКОПЛЕНИЕ ОЧКОВ
# ============================================================
	
func add_score(points: int, position: Vector2):
	score += points
	spawn_score_popup(points, position)

func spawn_score_popup(points: int, pos: Vector2):
	var label = Label.new()
	label.text = "+" + str(points)
	label.position = pos
	label.z_index = 100  # поверх всего
	label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))
	add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 60, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	await tween.finished
	label.queue_free()
