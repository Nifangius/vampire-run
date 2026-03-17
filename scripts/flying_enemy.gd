## flying_enemy.gd — летающий враг, движется волной и стреляет в игрока
extends CharacterBody2D

const ProjectileScene = preload("res://scenes/enemy_projectile.tscn")

var initial_y: float  # начальная высота для волнового движения
var time: float       # накопитель времени для sin()
var shoot_timer: float

func _ready():
	initial_y = position.y
	$AnimatedSprite2D.play("fly")

func _physics_process(delta):
	time += delta
	shoot_timer += delta
	
	# Движение влево
	velocity.x = -GameConfig.FLYING_ENEMY_SPEED
	
	# Волнообразное движение по Y через sin()
	position.y = initial_y + sin(time * GameConfig.FLYING_ENEMY_WAVE_FREQ) * GameConfig.FLYING_ENEMY_WAVE_AMP
	
	move_and_slide()
	
	if shoot_timer >= GameConfig.FLYING_ENEMY_SHOOT_INT:
		shoot_timer = 0.0
		shoot()
	
	if position.x < GameConfig.SCREEN_LEFT_BOUND:
		queue_free()

func shoot():
	var player = get_parent().get_node("Player")
	
	# Стреляем только если игрок слева от врага
	if player.position.x > position.x-200:
		return
	
	$AnimatedSprite2D.play("shoot")
	
	var projectile = ProjectileScene.instantiate()
	projectile.position = position
	
	# Направление к игроку с небольшим случайным разбросом
	var direction = (player.position - position).normalized()
	direction.y += randf_range(-GameConfig.PROJECTILE_SPREAD, GameConfig.PROJECTILE_SPREAD * 2)
	projectile.direction = direction.normalized()
	
	get_parent().add_child(projectile)
	
	# Возврат к анимации полёта после выстрела
	await get_tree().create_timer(0.3).timeout
	$AnimatedSprite2D.play("fly")

func die():
	set_physics_process(false)
	$AnimatedSprite2D.play("die")
	
	# Физическое падение вниз после смерти
	var fall_speed = 0.0
	while position.y < GameConfig.SCREEN_BOTTOM_BOUND:
		fall_speed += GameConfig.FLYING_ENEMY_FALL_ACC
		position.y += fall_speed * get_process_delta_time()
		await get_tree().process_frame
	
	queue_free()
