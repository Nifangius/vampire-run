extends CharacterBody2D

# ============================================================
# СИГНАЛЫ
# ============================================================
signal hit              # игрок получил урон, передаёт количество оставшихся жизней
signal died             # жизни закончились
signal blood_collected  # собрана капля крови, передаёт текущий счётчик
signal transformed      # трансформация активирована
signal transform_ready  # накоплено достаточно крови для трансформации
signal transform_ended  # трансформация завершена

# ============================================================
# РЕСУРСЫ
# ============================================================
const BatScene = preload("res://scenes/bat.tscn")

# ============================================================
# СОСТОЯНИЕ ИГРОКА
# ============================================================
var lives         # текущее количество жизней
var blood_count: int    # текущий счётчик капель крови
var is_invincible: bool # неуязвим ли игрок
var is_transformed: bool # активна ли трансформация в мышь
var can_transform: bool  # доступна ли трансформация
var is_shooting: bool    # проигрывается ли анимация стрельбы
var is_jumping: bool     # находится ли игрок в прыжке
var is_dashing: bool     # выполняется ли воздушный дэш вниз
var near_miss_scored = false
var scored_projectiles = []

var initial_position: Vector2  # начальная позиция для сброса после урона
var velocity_y_before: float   # скорость по Y до move_and_slide() для определения стомпа
var coyote_timer: float = 0.0  # таймер для coyote time (прыжок сразу после потери опоры)

func _ready():
	lives = GameConfig.PLAYER_LIVES
	initial_position = position
	$HitBox.body_entered.connect(_on_hitbox_body_entered)
	$HitBox.area_entered.connect(_on_hitbox_area_entered)
	$AnimatedSprite2D.play("run")

# ============================================================
# ФИЗИКА — вызывается каждый физический кадр
# ============================================================
func _physics_process(delta):
	if is_transformed:
		_handle_fly(delta)
	else:
		_handle_move(delta)

## Управление в режиме трансформированной мыши
func _handle_fly(delta):
	if Input.is_action_pressed("jump"):
		velocity.y = GameConfig.PLAYER_FLY_SPEED
	else:
		velocity.y += GameConfig.PLAYER_GRAVITY * delta
		
	if position.x < 0:  
		position = initial_position
		take_damage()

	check_near_miss()
	# Ограничиваем полёт в пределах экрана
	position.y = clamp(position.y, GameConfig.PLAYER_FLY_MIN_Y, GameConfig.PLAYER_FLY_MAX_Y)
	velocity_y_before = velocity.y
	move_and_slide()

## Управление в обычном режиме
func _handle_move(delta):
	if not is_on_floor():
		# Асимметричная гравитация: при падении тяжелее — приземление снаппи
		if velocity.y > 0:
			velocity.y += GameConfig.PLAYER_FALL_GRAVITY * delta
		else:
			velocity.y += GameConfig.PLAYER_GRAVITY * delta

		# Coyote time: уменьшаем таймер пока в воздухе
		coyote_timer -= delta

		# В воздухе пробел активирует воздушный дэш вниз (только если coyote время истекло)
		if Input.is_action_just_pressed("jump"):
			if coyote_timer > 0:
				# Coyote прыжок — ещё не слетели с платформы
				coyote_timer = 0.0
				velocity.y = GameConfig.PLAYER_JUMP_VELOCITY
				is_jumping = true
				$AnimatedSprite2D.play("jump")
			else:
				is_dashing = true
				velocity.y = GameConfig.PLAYER_DASH_SPEED
	else:
		# На земле сбрасываем дэш, обновляем coyote timer и обрабатываем прыжок
		is_dashing = false
		coyote_timer = GameConfig.PLAYER_COYOTE_TIME
		if Input.is_action_just_pressed("jump"):
			velocity.y = GameConfig.PLAYER_JUMP_VELOCITY
			is_jumping = true
			$AnimatedSprite2D.play("jump")
	
	# Короткое нажатие = низкий прыжок
	if Input.is_action_just_released("jump") and velocity.y < GameConfig.PLAYER_MIN_JUMP and not is_dashing:
		velocity.y = GameConfig.PLAYER_MIN_JUMP
	
	velocity_y_before = velocity.y
	
	# Возврат к анимации бега после приземления
	if is_jumping and is_on_floor():
		is_jumping = false
		$AnimatedSprite2D.play("run")
	
	# Если препятствие вытолкнуло за левый край — сброс позиции и урон
	if position.x < 0:
		position = initial_position
		take_damage()
		
	check_near_miss()
	move_and_slide()


func check_near_miss():
	scored_projectiles = scored_projectiles.filter(func(p): return is_instance_valid(p))
	
	for projectile in get_tree().get_nodes_in_group("enemy_projectile"):
		if projectile in scored_projectiles:
			continue
		
		var distance = abs(position.x - projectile.position.x)
		var height_diff = projectile.position.y - position.y
		
		if distance < GameConfig.NEAR_MISS_DISTANCE and \
		   height_diff > GameConfig.NEAR_MISS_HEIGHT_MIN and \
		   height_diff < GameConfig.NEAR_MISS_HEIGHT_MAX:
			scored_projectiles.append(projectile)  # запоминаем снаряд
			get_parent().add_score(GameConfig.SCORE_NEAR_MISS, position)
	
	# Сбрасываем флаг при приземлении
	if is_on_floor():
		near_miss_scored = false

# ============================================================
# ВВОД — вызывается каждый кадр
# ============================================================
func _process(_delta):
	if Input.is_action_just_pressed("shoot") and not is_shooting:
		shoot()
	
	if Input.is_action_just_pressed("transform") and can_transform:
		activate_transform()

# ============================================================
# СТРЕЛЬБА
# ============================================================
func shoot():
	is_shooting = true
	
	if is_transformed:
		$AnimatedSprite2D.play("trans_shoot")
		await get_tree().create_timer(GameConfig.PLAYER_SHOOT_DELAY_TRANSFORMED).timeout
		shoot_triple()
	else:
		$AnimatedSprite2D.play("shoot")
		await get_tree().create_timer(GameConfig.PLAYER_SHOOT_DELAY).timeout
		shoot_single()
	
	is_shooting = false
	
	# Возвращаем анимацию в зависимости от текущего состояния
	if is_transformed:
		$AnimatedSprite2D.play("fly")
	elif is_jumping:
		$AnimatedSprite2D.play("jump")
	else:
		$AnimatedSprite2D.play("run")

## Одиночный выстрел — обычный режим
func shoot_single():
	var bat = BatScene.instantiate()
	bat.position = Vector2(position.x + 50, position.y)
	get_parent().add_child(bat)

## Тройной выстрел — режим трансформации
func shoot_triple():
	for angle in GameConfig.TRIPLE_SHOT_ANGLES:
		var bat = BatScene.instantiate()
		bat.position = Vector2(position.x + 50, position.y)
		bat.direction = Vector2(1, tan(deg_to_rad(angle))).normalized()
		get_parent().add_child(bat)

# ============================================================
# ТРАНСФОРМАЦИЯ
# ============================================================
func activate_transform():
	can_transform = false
	is_transformed = true
	blood_count = 0
	position = initial_position
	emit_signal("blood_collected", 0)  # сбрасываем UI счётчика
	emit_signal("transformed")
	$AnimatedSprite2D.play("fly")
	await get_tree().create_timer(GameConfig.TRANSFORM_DURATION).timeout
	deactivate_transform()

func deactivate_transform():
	position = initial_position
	is_transformed = false
	emit_signal("transform_ended")
	$AnimatedSprite2D.play("run")

# ============================================================
# КОЛЛЕКТАБЛЫ
# ============================================================
func collect_blood():
	if is_transformed:
		return  # во время трансформации капли крови не собираются
	blood_count += 1
	emit_signal("blood_collected", blood_count)
	if blood_count >= GameConfig.BLOOD_TO_TRANSFORM:
		can_transform = true
		emit_signal("transform_ready")

func collect_health():
	if lives < GameConfig.PLAYER_LIVES:
		lives += 1
		emit_signal("hit", lives)  # обновляем UI жизней

# ============================================================
# УРОН И НЕУЯЗВИМОСТЬ
# ============================================================
func take_damage():
	if is_invincible:
		return
	lives -= 1
	position = initial_position
	emit_signal("hit", lives)
	if lives <= 0:
		emit_signal("died")
	else:
		activate_invincibility(GameConfig.PLAYER_INVINCIBILITY)

func activate_invincibility(duration: float):
	is_invincible = true
	$HitBox.monitoring = false
	set_collision_mask_value(3, false)  # отключаем коллизию с препятствиями
	_start_blinking()
	await get_tree().create_timer(duration).timeout
	is_invincible = false
	$HitBox.monitoring = true
	set_collision_mask_value(3, true)
	$AnimatedSprite2D.visible = true  # гарантируем видимость после моргания

## Мигание спрайта во время неуязвимости
func _start_blinking():
	while is_invincible:
		$AnimatedSprite2D.visible = false
		await get_tree().create_timer(GameConfig.PLAYER_BLINK_INTERVAL).timeout
		$AnimatedSprite2D.visible = true
		await get_tree().create_timer(GameConfig.PLAYER_BLINK_INTERVAL).timeout

# ============================================================
# КОЛЛИЗИИ
# ============================================================
func _on_hitbox_body_entered(body):
	if body.is_in_group("enemy"):
		if velocity_y_before > 0:
			body.die()     # обычный стомп — отскок вверх
			velocity.y = GameConfig.PLAYER_STOMP_BOUNCE
			
			# Начисляем очки в зависимости от типа врага
			var points = 0
			if body.is_in_group("flying_enemy"):
				points = GameConfig.SCORE_KILL_FLYING  
			else: points = GameConfig.SCORE_KILL_GROUND
			get_parent().add_score(points, body.position)
			print('score stomp'+str(points))
		else:
			take_damage() 

func _on_hitbox_area_entered(area):
	if area.is_in_group("enemy_projectile"):
		take_damage()
